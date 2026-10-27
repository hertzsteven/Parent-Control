import Foundation

/// Turns Jamf School `appWhitelist` values into bundle ids.
/// Accepts a JSON array string, a comma-separated list, and loose quoted ids.
enum AppWhitelistParser {
    static func bundleIds(from text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if let decoded = jsonStringArray(from: trimmed) {
            return clean(decoded)
        }

        let wrapped = "[\(trimmed)]"
        if let decoded = jsonStringArray(from: wrapped) {
            return clean(decoded)
        }

        let withoutBrackets = stripSurroundingBrackets(trimmed)
        return clean(withoutBrackets.split(separator: ",").map(String.init))
    }

    static func clean(_ rawIds: [String]) -> [String] {
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

    private static func jsonStringArray(from text: String) -> [String]? {
        guard let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode([String].self, from: data)
    }

    private static func stripSurroundingBrackets(_ text: String) -> String {
        var value = text
        if value.hasPrefix("[") {
            value.removeFirst()
        }
        if value.hasSuffix("]") {
            value.removeLast()
        }
        return value
    }
}
