import Foundation

/// Flexible `appWhitelist` payload from GET /teacher/profiles.
struct AppWhitelistValue: Decodable {
    let bundleIds: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            bundleIds = []
            return
        }
        if let ids = try? container.decode([String].self) {
            bundleIds = AppWhitelistParser.clean(ids)
            return
        }
        if let entries = try? container.decode([AppWhitelistEntry].self) {
            bundleIds = AppWhitelistParser.clean(entries.compactMap(\.bundleId))
            return
        }
        if let text = try? container.decode(String.self) {
            bundleIds = AppWhitelistParser.bundleIds(from: text)
            return
        }
        bundleIds = []
    }
}
