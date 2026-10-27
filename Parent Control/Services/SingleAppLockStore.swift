import Foundation

/// Local single-app lock state, keyed by student/owner id.
/// Profile reads and lock/unlock results both go through this store.
/// A newer lock or unlock result invalidates an in-flight profile read.
struct SingleAppLockStore {
    private(set) var locksByOwnerId: [String: SingleAppLock] = [:]
    private(set) var queryByOwnerId: [String: SingleAppLockQuery] = [:]
    private var generations: [String: Int] = [:]

    func lock(forOwnerId ownerId: String) -> SingleAppLock? {
        locksByOwnerId[ownerId]
    }

    func query(forOwnerId ownerId: String) -> SingleAppLockQuery? {
        queryByOwnerId[ownerId]
    }

    mutating func beginProfileFetch(ownerId: String) -> Int {
        let next = (generations[ownerId] ?? 0) + 1
        generations[ownerId] = next
        if queryByOwnerId[ownerId] != .settled {
            queryByOwnerId[ownerId] = .loading
        }
        return next
    }

    /// Applies a profile snapshot only when no newer lock or unlock happened.
    @discardableResult
    mutating func replaceFromProfile(
        ownerId: String,
        bundleIds: [String],
        generation: Int,
        appName: (String) -> String
    ) -> Bool {
        guard generations[ownerId] == generation else { return false }
        switch SingleAppLockVisibility.decide(bundleIds: bundleIds) {
        case .hidden:
            locksByOwnerId[ownerId] = nil
        case .shown(let bundleId):
            locksByOwnerId[ownerId] = SingleAppLock(
                bundleId: bundleId,
                appName: appName(bundleId)
            )
        }
        queryByOwnerId[ownerId] = .settled
        return true
    }

    /// A dropped generation belongs to an older read. Leave the newer query alone.
    mutating func noteProfileFetchFailed(ownerId: String, generation: Int) {
        guard generations[ownerId] == generation else { return }
        queryByOwnerId[ownerId] = .failed
    }

    /// The token never arrived. That is a failed read, not an unlocked device.
    mutating func noteProfileFetchUnavailable(ownerId: String) {
        guard queryByOwnerId[ownerId] != .settled else { return }
        queryByOwnerId[ownerId] = .failed
    }

    mutating func noteAppLockApplied(ownerId: String, bundleId: String, appName: String) {
        generations[ownerId] = (generations[ownerId] ?? 0) + 1
        locksByOwnerId[ownerId] = SingleAppLock(bundleId: bundleId, appName: appName)
        queryByOwnerId[ownerId] = .settled
    }

    mutating func noteLessonsStopped(ownerId: String) {
        generations[ownerId] = (generations[ownerId] ?? 0) + 1
        locksByOwnerId[ownerId] = nil
        queryByOwnerId[ownerId] = .settled
    }
}
