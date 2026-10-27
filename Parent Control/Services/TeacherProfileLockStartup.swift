import Foundation

/// Holds the device screen until `TeacherProfileLockClient.currentLock` returns,
/// or until the check has failed enough times to stop.
///
/// Startup waits for that version 4 `GET /teacher/profiles` read because the
/// result may take a moment and may show the device is locked. If startup did
/// not wait, that locked state would be missed.
///
/// Each ask has its own cutoff. A missing token, a failed read, or a cutoff
/// with no reply is one failed try. After `failedAttemptLimit` failed tries the
/// wait stops. The 400 ms pause still sits between tries. Leaving the screen
/// still cancels the wait. A reply that arrives after the cutoff, or after that
/// cancellation, is ignored.
@MainActor
struct TeacherProfileLockStartup {
    nonisolated static let failedAttemptLimit = 8
    nonisolated static let profilesRequestTimeout: Duration = .seconds(15)

    enum Failure: Error {
        /// Jamf did not answer this ask before the cutoff.
        case timedOut
        /// Missing token or failed read reached `failedAttemptLimit`.
        case couldNotCheck
    }

    private let read: @MainActor (String, String) async throws -> TeacherProfileLockStatus
    var retryDelay: Duration
    let requestTimeout: Duration
    let attemptLimit: Int

    init(
        client: TeacherProfileLockClient = TeacherProfileLockClient(),
        retryDelay: Duration = .milliseconds(400),
        requestTimeout: Duration = TeacherProfileLockStartup.profilesRequestTimeout,
        attemptLimit: Int = TeacherProfileLockStartup.failedAttemptLimit
    ) {
        self.retryDelay = retryDelay
        self.requestTimeout = requestTimeout
        self.attemptLimit = attemptLimit
        self.read = { ownerId, token in
            try await client.currentLock(ownerId: ownerId, token: token)
        }
    }

    init(
        retryDelay: Duration = .milliseconds(400),
        requestTimeout: Duration = TeacherProfileLockStartup.profilesRequestTimeout,
        attemptLimit: Int = TeacherProfileLockStartup.failedAttemptLimit,
        read: @escaping @MainActor (String, String) async throws -> TeacherProfileLockStatus
    ) {
        self.retryDelay = retryDelay
        self.requestTimeout = requestTimeout
        self.attemptLimit = attemptLimit
        self.read = read
    }

    /// `true` means this try did not produce an answer. The attempt limit is applied by the wait.
    static func shouldRetry(token: String?, result: Result<TeacherProfileLockStatus, Error>?) -> Bool {
        let trimmed = token?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return true }
        guard let result else { return true }
        if case .success = result { return false }
        return true
    }

    @MainActor
    func waitUntilAnswer(
        ownerId: String,
        token: @MainActor () -> String?
    ) async throws -> TeacherProfileLockStatus {
        var failures = 0
        while !Task.isCancelled {
            let currentToken = token()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if currentToken.isEmpty {
                failures = try await failedTry(count: failures)
                continue
            }
            do {
                let status = try await readWithinCutoff(ownerId: ownerId, token: currentToken)
                if !Self.shouldRetry(token: currentToken, result: .success(status)) {
                    try Task.checkCancellation()
                    return status
                }
                failures = try await failedTry(count: failures)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                try Task.checkCancellation()
                if Self.shouldRetry(token: currentToken, result: .failure(error)) {
                    failures = try await failedTry(count: failures)
                } else {
                    throw error
                }
            }
        }
        throw CancellationError()
    }

    /// Counts one missed try. Sleeps before the next try, and stops once the limit is reached.
    private func failedTry(count: Int) async throws -> Int {
        let updated = count + 1
        if updated >= attemptLimit {
            throw Failure.couldNotCheck
        }
        try await Task.sleep(for: retryDelay)
        return updated
    }

    /// Asks once. The ask fails at the cutoff even if Jamf answers later.
    private func readWithinCutoff(ownerId: String, token: String) async throws -> TeacherProfileLockStatus {
        try Task.checkCancellation()
        let read = self.read
        let timeout = requestTimeout
        let gate = StartupLockReplyGate()
        let reader = Task { @MainActor () throws -> TeacherProfileLockStatus in
            try await read(ownerId, token)
        }

        let status = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                gate.arm(continuation)
                let timer = Task { @MainActor in
                    do {
                        try await Task.sleep(for: timeout)
                    } catch {
                        return
                    }
                    // Settle first so a reply that lands after the cutoff cannot win the race.
                    gate.fail(Failure.timedOut)
                    reader.cancel()
                }
                Task { @MainActor in
                    let outcome = await reader.result
                    timer.cancel()
                    switch outcome {
                    case .success(let status):
                        gate.succeed(status)
                    case .failure(let error):
                        // Cancelling the reader at the cutoff throws this.
                        // The timer, or the screen task, already settled the gate.
                        if error is CancellationError {
                            return
                        }
                        gate.fail(error)
                    }
                }
            }
        } onCancel: {
            reader.cancel()
            gate.fail(CancellationError())
        }
        try Task.checkCancellation()
        return status
    }
}
