import Foundation

/// Local single-app lock state, keyed by student/owner id.
/// Profile reads and lock/unlock results both go through this store.
/// A newer lock or unlock result invalidates an in-flight profile read.
struct SingleAppLockStore {
    private(set) var locksByOwnerId: [String: SingleAppLock] = [:]
    private var generations: [String: Int] = [:]

    func lock(forOwnerId ownerId: String) -> SingleAppLock? {
        locksByOwnerId[ownerId]
    }

    mutating func beginProfileFetch(ownerId: String) -> Int {
        let next = (generations[ownerId] ?? 0) + 1
        generations[ownerId] = next
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
        return true
    }

    mutating func noteAppLockApplied(ownerId: String, bundleId: String, appName: String) {
        generations[ownerId] = (generations[ownerId] ?? 0) + 1
        locksByOwnerId[ownerId] = SingleAppLock(bundleId: bundleId, appName: appName)
    }

    mutating func noteLessonsStopped(ownerId: String) {
        generations[ownerId] = (generations[ownerId] ?? 0) + 1
        locksByOwnerId[ownerId] = nil
    }
}
