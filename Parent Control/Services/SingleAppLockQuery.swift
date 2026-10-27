import Foundation

/// Whether a startup profile read has finished for one student.
/// Missing and `.loading` are not "unlocked." Only `.settled` is.
enum SingleAppLockQuery: Equatable {
    case loading
    case settled
    case failed
}
