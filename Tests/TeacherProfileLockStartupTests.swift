import Foundation

/// Standalone stand-in so this file can compile `TeacherProfileLockClient` without the app target.
/// The app's real `NetworkError` lives in `NetworkService.swift`.
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
}

@main
enum TeacherProfileLockStartupTests {
    static func main() async {
        await Runner.run()
    }
}

@MainActor
private enum Runner {
    static func run() async {
        var failures: [String] = []

        func check(_ name: String, _ condition: Bool) {
            if condition {
                print("PASS \(name)")
            } else {
                print("FAIL \(name)")
                failures.append(name)
            }
        }

        check(
            "a missing token keeps startup waiting",
            TeacherProfileLockStartup.shouldRetry(token: nil, result: nil)
        )
        check(
            "a blank token keeps startup waiting",
            TeacherProfileLockStartup.shouldRetry(token: "  ", result: nil)
        )
        check(
            "a failed read is retried",
            TeacherProfileLockStartup.shouldRetry(
                token: "token",
                result: .failure(TeacherProfileLockError.unexpectedBody)
            )
        )
        check(
            "not locked is an answer, so startup can continue",
            !TeacherProfileLockStartup.shouldRetry(token: "token", result: .success(.notLocked))
        )
        check(
            "locked is an answer, so startup can show it",
            !TeacherProfileLockStartup.shouldRetry(
                token: "token",
                result: .success(.locked(bundleIds: ["com.example.onthefarm"]))
            )
        )
        check(
            "startup stops after 8 failed tries",
            TeacherProfileLockStartup.failedAttemptLimit == 8
        )

        await checkFastAnswer(check)
        await checkLateReplyIsIgnored(check)
        await checkEightFailedReads(check)
        await checkEighthAskCanSucceed(check)
        await checkEightMissingTokens(check)
        await checkEightTimeouts(check)
        await checkReplyAfterCancelIsIgnored(check)

        if !failures.isEmpty {
            print("\(failures.count) failed")
            exit(1)
        }
        print("All startup lock tests passed")
    }

    static func checkFastAnswer(_ check: (String, Bool) -> Void) async {
        let reads = Tally()
        let seenToken = Note()
        let startup = TeacherProfileLockStartup(retryDelay: .milliseconds(1)) { _, token in
            reads.add()
            seenToken.text = token
            return .notLocked
        }
        let task = Task {
            try await startup.waitUntilAnswer(ownerId: "143") { "  abc  " }
        }
        let outcome = await outcome(of: task, within: .seconds(2))
        check("a reply inside the cutoff is kept", outcome == .status(.notLocked))
        check("a fast reply does not wait out the cutoff", reads.count == 1)
        check("the token is trimmed before the ask", seenToken.text == "abc")
    }

    static func checkLateReplyIsIgnored(_ check: (String, Bool) -> Void) async {
        let held = HeldReads()
        let startup = TeacherProfileLockStartup(
            retryDelay: .milliseconds(1),
            requestTimeout: .milliseconds(400)
        ) { _, _ in
            try await held.read()
        }
        let task = Task {
            try await startup.waitUntilAnswer(ownerId: "143") { "token" }
        }
        let retried = await waitUntil { held.count >= 2 }
        check("a cutoff starts the next ask while the first reply is still out", retried)

        held.resume(at: 0, .locked(bundleIds: ["late.app"]))
        let early = await outcome(of: task, within: .milliseconds(100))
        check("a reply after the cutoff is ignored", early == .stillWaiting)

        held.resume(at: 1, .notLocked)
        let finished = await outcome(of: task, within: .seconds(2))
        check("the ask after the cutoff is the one that is kept", finished == .status(.notLocked))
        held.cancelRemaining()
        task.cancel()
    }

    static func checkEightFailedReads(_ check: (String, Bool) -> Void) async {
        let reads = Tally()
        let startup = TeacherProfileLockStartup(retryDelay: .milliseconds(1)) { _, _ in
            reads.add()
            throw TeacherProfileLockError.unexpectedBody
        }
        let task = Task {
            try await startup.waitUntilAnswer(ownerId: "143") { "token" }
        }
        let outcome = await outcome(of: task, within: .seconds(2))
        task.cancel()
        check("eight failed reads stop the wait", outcome == .couldNotCheck)
        check("a ninth read is not started", reads.count == 8)
    }

    static func checkEighthAskCanSucceed(_ check: (String, Bool) -> Void) async {
        let reads = Tally()
        let startup = TeacherProfileLockStartup(retryDelay: .milliseconds(1)) { _, _ in
            let count = reads.add()
            if count < 8 {
                throw TeacherProfileLockError.unexpectedBody
            }
            return .locked(bundleIds: ["com.example.kept"])
        }
        let task = Task {
            try await startup.waitUntilAnswer(ownerId: "143") { "token" }
        }
        let outcome = await outcome(of: task, within: .seconds(2))
        task.cancel()
        check(
            "the eighth ask can still be the answer",
            outcome == .status(.locked(bundleIds: ["com.example.kept"]))
        )
    }

    static func checkEightMissingTokens(_ check: (String, Bool) -> Void) async {
        let reads = Tally()
        let tokenLooks = Tally()
        let startup = TeacherProfileLockStartup(retryDelay: .milliseconds(1)) { _, _ in
            reads.add()
            return .notLocked
        }
        let task = Task {
            try await startup.waitUntilAnswer(ownerId: "143") {
                tokenLooks.add()
                return "   "
            }
        }
        let outcome = await outcome(of: task, within: .seconds(2))
        task.cancel()
        check("eight missing tokens stop the wait", outcome == .couldNotCheck)
        check("a missing token does not ask Jamf", reads.count == 0)
        check("the token is checked eight times", tokenLooks.count == 8)
    }

    static func checkEightTimeouts(_ check: (String, Bool) -> Void) async {
        let reads = Tally()
        let startup = TeacherProfileLockStartup(
            retryDelay: .milliseconds(1),
            requestTimeout: .milliseconds(30)
        ) { _, _ in
            reads.add()
            try await Task.sleep(for: .seconds(30))
            return .locked(bundleIds: ["late.app"])
        }
        let task = Task {
            try await startup.waitUntilAnswer(ownerId: "143") { "token" }
        }
        let outcome = await outcome(of: task, within: .seconds(3))
        task.cancel()
        check("eight timed-out reads stop the wait", outcome == .couldNotCheck)
        check("each cutoff counts as one try", reads.count == 8)
    }

    static func checkReplyAfterCancelIsIgnored(_ check: (String, Bool) -> Void) async {
        let held = HeldReads()
        let startup = TeacherProfileLockStartup(
            retryDelay: .milliseconds(1),
            requestTimeout: .seconds(5)
        ) { _, _ in
            try await held.read()
        }
        let task = Task {
            try await startup.waitUntilAnswer(ownerId: "143") { "token" }
        }
        let started = await waitUntil { held.count >= 1 }
        check("cancel is tested after the ask has started", started)
        task.cancel()
        let early = await outcome(of: task, within: .seconds(1))
        held.resume(at: 0, .locked(bundleIds: ["late.app"]))
        let late = await outcome(of: task, within: .milliseconds(200))
        held.cancelRemaining()
        task.cancel()
        check("leaving the screen cancels the wait", early == .cancelled)
        check(
            "a reply after the screen is gone is ignored",
            late != .status(.locked(bundleIds: ["late.app"]))
        )
    }

    static func waitUntil(for limit: Duration = .seconds(2), _ ready: () -> Bool) async -> Bool {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: limit)
        while clock.now < deadline {
            if ready() { return true }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return ready()
    }

    static func outcome(
        of task: Task<TeacherProfileLockStatus, Error>,
        within limit: Duration
    ) async -> WaitOutcome {
        let gate = FirstWin<WaitOutcome>()
        let watcher = Task {
            let mapped: WaitOutcome
            do {
                mapped = .status(try await task.value)
            } catch is CancellationError {
                mapped = .cancelled
            } catch TeacherProfileLockStartup.Failure.couldNotCheck {
                mapped = .couldNotCheck
            } catch {
                mapped = .other
            }
            gate.win(mapped)
        }
        let timer = Task {
            try? await Task.sleep(for: limit)
            gate.win(.stillWaiting)
        }
        let value = await withCheckedContinuation { continuation in
            gate.arm(continuation)
        }
        watcher.cancel()
        timer.cancel()
        return value
    }
}

private enum WaitOutcome: Equatable {
    case status(TeacherProfileLockStatus)
    case couldNotCheck
    case cancelled
    case other
    case stillWaiting
}

private final class Tally: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    @discardableResult
    func add() -> Int {
        lock.lock()
        defer { lock.unlock() }
        value += 1
        return value
    }
}

private final class Note: @unchecked Sendable {
    private let lock = NSLock()
    private var value = ""

    var text: String {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            value = newValue
            lock.unlock()
        }
    }
}

private final class HeldReads: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations: [Int: CheckedContinuation<TeacherProfileLockStatus, Error>] = [:]
    private var nextIndex = 0
    private var started = 0

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return started
    }

    func read() async throws -> TeacherProfileLockStatus {
        let index: Int = {
            lock.lock()
            defer { lock.unlock() }
            let index = nextIndex
            nextIndex += 1
            started += 1
            return index
        }()
        return try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            continuations[index] = continuation
            lock.unlock()
        }
    }

    func resume(at index: Int, _ status: TeacherProfileLockStatus) {
        lock.lock()
        let continuation = continuations.removeValue(forKey: index)
        lock.unlock()
        continuation?.resume(returning: status)
    }

    func cancelRemaining() {
        lock.lock()
        let pending = Array(continuations.values)
        continuations.removeAll()
        lock.unlock()
        for continuation in pending {
            continuation.resume(throwing: CancellationError())
        }
    }
}

private final class FirstWin<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Never>?
    private var value: T?

    func arm(_ continuation: CheckedContinuation<T, Never>) {
        lock.lock()
        if let value {
            lock.unlock()
            continuation.resume(returning: value)
            return
        }
        self.continuation = continuation
        lock.unlock()
    }

    func win(_ value: T) {
        lock.lock()
        if self.value != nil {
            lock.unlock()
            return
        }
        self.value = value
        let pending = self.continuation
        self.continuation = nil
        lock.unlock()
        pending?.resume(returning: value)
    }
}
