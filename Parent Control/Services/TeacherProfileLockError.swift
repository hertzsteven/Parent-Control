import Foundation

enum TeacherProfileLockError: LocalizedError {
    case unexpectedBody
    case requestFailed(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .unexpectedBody:
            return "Profiles response was not a list of students."
        case .requestFailed(let statusCode, let message):
            return "Server error (\(statusCode)): \(message ?? "Unknown error")"
        }
    }
}
