import Foundation

/// Holds the device screen until `TeacherProfileLockClient.currentLock` returns.
///
/// Startup waits for that version 4 `GET /teacher/profiles` read before continuing
/// not because of a hang concern, but because the result may take a moment and
/// may show the device is locked. If startup did not wait, that locked state
/// would be missed. The wait is what makes the correct answer visible.
/// A missing token or a failed read is retried until an answer arrives.
struct TeacherProfileLockStartup {
    private let client: TeacherProfileLockClient
    var retryDelay: Duration

    init(client: TeacherProfileLockClient = TeacherProfileLockClient(), retryDelay: Duration = .milliseconds(400)) {
        self.client = client
        self.retryDelay = retryDelay
    }

    /// `true` means keep waiting. A parsed status, locked or not, is the answer.
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
        while !Task.isCancelled {
            let currentToken = token()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if currentToken.isEmpty {
                try await Task.sleep(for: retryDelay)
                continue
            }
            do {
                return try await client.currentLock(ownerId: ownerId, token: currentToken)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                try await Task.sleep(for: retryDelay)
            }
        }
        throw CancellationError()
    }
}
