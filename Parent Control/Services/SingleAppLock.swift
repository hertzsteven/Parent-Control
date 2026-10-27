import Foundation

/// The one app a student is locked to, with a name the teacher can read.
struct SingleAppLock: Equatable {
    /// Blue unlock control. The title does not include the locked app's name.
    static let unlockButtonTitle = "Unlock"

    let bundleId: String
    let appName: String

    /// The card lock icon uses the same single-app lock as the blue unlock button.
    func showsLockIcon(on appBundleId: String?) -> Bool {
        guard let appBundleId else { return false }
        return appBundleId == bundleId
    }
}
