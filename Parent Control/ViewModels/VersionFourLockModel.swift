import Foundation
import Observation

/// Coordinates the version 4 lock button and the version 4 lock check.
@MainActor
@Observable
final class VersionFourLockModel {
    private let client: TeacherProfileLockClient

    private(set) var statusMessage = ""
    private(set) var isWorking = false

    init(client: TeacherProfileLockClient = TeacherProfileLockClient()) {
        self.client = client
    }

    func lock(ownerId: String, bundleId: String, appName: String, token: String?) async {
        guard let token, !token.isEmpty else {
            statusMessage = "Sign in before locking with version 4."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            try await client.lockToApp(ownerId: ownerId, bundleId: bundleId, token: token)
            statusMessage = "Version 4 lock sent for \(appName). Check lock to read it back."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    /// Same profiles read a later screen-start check would call.
    func check(ownerId: String, token: String?) async {
        guard let token, !token.isEmpty else {
            statusMessage = "Sign in before checking the lock."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            let status = try await client.currentLock(ownerId: ownerId, token: token)
            statusMessage = status.summary
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
