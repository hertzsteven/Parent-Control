import Foundation

/// One app inside an `appWhitelist` array of objects.
struct AppWhitelistEntry: Decodable {
    let bundleId: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let identifier = try container.decodeIfPresent(String.self, forKey: .identifier) {
            bundleId = identifier
        } else if let bundle = try container.decodeIfPresent(String.self, forKey: .bundleId) {
            bundleId = bundle
        } else {
            bundleId = try container.decodeIfPresent(String.self, forKey: .id)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case identifier
        case bundleId
        case id
    }
}
