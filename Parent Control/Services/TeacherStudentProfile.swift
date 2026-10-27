import Foundation

/// One student row from GET /teacher/profiles.
struct TeacherStudentProfile: Decodable, Equatable {
    let studentId: String
    let appWhitelist: [String]

    init(studentId: String, appWhitelist: [String]) {
        self.studentId = studentId
        self.appWhitelist = appWhitelist
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        studentId = try Self.decodeStudentId(from: container)
        if let whitelist = try container.decodeIfPresent(AppWhitelistValue.self, forKey: .appWhitelist) {
            appWhitelist = whitelist.bundleIds
        } else {
            appWhitelist = []
        }
    }

    static func bundleIds(forOwnerId ownerId: String, in profiles: [TeacherStudentProfile]) -> [String] {
        profiles.first { $0.studentId == ownerId }?.appWhitelist ?? []
    }

    static func decodeList(from data: Data) throws -> [TeacherStudentProfile] {
        try JSONDecoder().decode([TeacherStudentProfile].self, from: data)
    }

    private static func decodeStudentId(from container: KeyedDecodingContainer<CodingKeys>) throws -> String {
        if let id = try? container.decode(Int.self, forKey: .studentId) {
            return String(id)
        }
        return try container.decode(String.self, forKey: .studentId)
    }

    private enum CodingKeys: String, CodingKey {
        case studentId
        case appWhitelist
    }
}
