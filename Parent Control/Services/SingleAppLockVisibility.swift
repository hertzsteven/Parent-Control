import Foundation

/// Whether the single-app unlock button should appear.
/// Exactly one bundle id is a lock. Any other count is not.
enum SingleAppLockVisibility: Equatable {
    case hidden
    case shown(bundleId: String)

    static func decide(bundleIds: [String]) -> SingleAppLockVisibility {
        let ids = AppWhitelistParser.clean(bundleIds)
        guard ids.count == 1, let bundleId = ids.first else {
            return .hidden
        }
        return .shown(bundleId: bundleId)
    }
}
