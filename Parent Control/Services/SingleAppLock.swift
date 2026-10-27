import Foundation

/// The one app a student is locked to, with a name the teacher can read.
struct SingleAppLock: Equatable {
    let bundleId: String
    let appName: String
}
