import Foundation

/// Matches a lock bundle id to an app name the app already has.
enum AppNameMatcher {
    static func name(forBundleId bundleId: String, apps: [AppItem]) -> String {
        apps.first { $0.bundleId == bundleId }?.title ?? bundleId
    }
}
