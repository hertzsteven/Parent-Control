import Foundation

/// Decides whether a lock-status read can start, must wait, or has given up.
/// An empty token on the first look is a wait, not a skipped read.
enum SingleAppLockTokenReadiness: Equatable {
    case ready(String)
    case wait
    case unavailable

    static func decide(token: String?, attempt: Int, maxAttempts: Int) -> SingleAppLockTokenReadiness {
        if let token {
            let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return .ready(trimmed)
            }
        }
        if attempt >= maxAttempts {
            return .unavailable
        }
        return .wait
    }
}
