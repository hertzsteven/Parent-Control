import Foundation

/// What GET /teacher/profiles (protocol 4) says about one student.
/// A missing, null, or empty `appWhitelist` is not a lock.
/// Any bundle id in that list is a current restriction.
enum TeacherProfileLockStatus: Equatable {
    case studentMissing
    case notLocked
    case locked(bundleIds: [String])

    var isLocked: Bool {
        if case .locked = self { return true }
        return false
    }

    var summary: String {
        switch self {
        case .studentMissing:
            return "Not locked. This student was not in the profiles response."
        case .notLocked:
            return "Not locked. appWhitelist is absent, null, or empty."
        case .locked(let bundleIds) where bundleIds.count == 1:
            return "Locked to \(bundleIds[0])."
        case .locked(let bundleIds):
            let names = bundleIds.joined(separator: ", ")
            return "Locked to \(bundleIds.count) apps: \(names)."
        }
    }

    /// Reads the protocol 4 profiles body. The same read can run at screen start.
    static func interpret(ownerId: String, responseBody: Data) throws -> TeacherProfileLockStatus {
        let object = try JSONSerialization.jsonObject(with: responseBody)
        guard let rows = object as? [Any] else {
            throw TeacherProfileLockError.unexpectedBody
        }
        guard let row = rows.compactMap({ $0 as? [String: Any] }).first(where: {
            studentId(in: $0) == ownerId
        }) else {
            return .studentMissing
        }
        guard row.keys.contains("appWhitelist"), let value = row["appWhitelist"] else {
            return .notLocked
        }
        if value is NSNull {
            return .notLocked
        }
        let bundleIds = clean(bundleIds(from: value))
        if bundleIds.isEmpty {
            return .notLocked
        }
        return .locked(bundleIds: bundleIds)
    }

    private static func studentId(in row: [String: Any]) -> String? {
        if let id = row["studentId"] as? Int {
            return String(id)
        }
        if let id = row["studentId"] as? String {
            return id
        }
        return nil
    }

    private static func bundleIds(from value: Any) -> [String] {
        if let ids = value as? [String] {
            return ids
        }
        if let entries = value as? [[String: Any]] {
            return entries.compactMap { entry in
                (entry["identifier"] as? String)
                    ?? (entry["bundleId"] as? String)
            }
        }
        if let text = value as? String {
            return bundleIds(from: text)
        }
        return []
    }

    private static func bundleIds(from text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let data = trimmed.data(using: .utf8) else { return [] }
        if let decoded = try? JSONSerialization.jsonObject(with: data) {
            return bundleIds(from: decoded)
        }
        let wrapped = "[\(trimmed)]"
        if let data = wrapped.data(using: .utf8),
           let decoded = try? JSONSerialization.jsonObject(with: data) {
            return bundleIds(from: decoded)
        }
        return trimmed.split(separator: ",").map(String.init)
    }

    private static func clean(_ rawIds: [String]) -> [String] {
        var seen: Set<String> = []
        var bundleIds: [String] = []
        for raw in rawIds {
            let bundleId = raw
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'[]"))
            guard !bundleId.isEmpty, seen.insert(bundleId).inserted else { continue }
            bundleIds.append(bundleId)
        }
        return bundleIds
    }
}
