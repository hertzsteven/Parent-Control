import Foundation

/// Accepts one result from a startup profiles read and drops anything later.
///
/// The cutoff and a cancelled screen both finish without waiting for Jamf.
/// A reply that shows up after that must not become `startupLock`.
final class StartupLockReplyGate: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<TeacherProfileLockStatus, Error>?
    private var result: Result<TeacherProfileLockStatus, Error>?

    func arm(_ continuation: CheckedContinuation<TeacherProfileLockStatus, Error>) {
        lock.lock()
        if let result {
            lock.unlock()
            continuation.resume(with: result)
            return
        }
        self.continuation = continuation
        lock.unlock()
    }

    func succeed(_ status: TeacherProfileLockStatus) {
        finish(.success(status))
    }

    func fail(_ error: Error) {
        finish(.failure(error))
    }

    private func finish(_ result: Result<TeacherProfileLockStatus, Error>) {
        lock.lock()
        if self.result != nil {
            lock.unlock()
            return
        }
        self.result = result
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        continuation?.resume(with: result)
    }
}
