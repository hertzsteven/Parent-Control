import Foundation

/// Version 4 teacher-profile reads and writes.
/// Jamf School documents no version 4 `POST /teacher/apply/applock`.
/// `PUT /teacher/profiles` is the version 4 call that sets `appWhitelist`,
/// which is the field `GET /teacher/profiles` reads back.
struct TeacherProfileLockClient {
    private let configuration: APIConfiguration
    private let session: URLSession

    init(configuration: APIConfiguration = .default, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    /// The launch-time check: current restrictions for one student.
    func currentLock(ownerId: String, token: String) async throws -> TeacherProfileLockStatus {
        let data = try await send(
            method: "GET",
            query: [
                URLQueryItem(name: "token", value: token),
                URLQueryItem(name: "scope", value: "student"),
                URLQueryItem(name: "scopeId", value: ownerId)
            ],
            body: nil
        )
        return try TeacherProfileLockStatus.interpret(ownerId: ownerId, responseBody: data)
    }

    /// Locks one student to one app by writing `appWhitelist` with protocol version 4.
    func lockToApp(ownerId: String, bundleId: String, token: String) async throws {
        let scopeId: Any = Int(ownerId) ?? ownerId
        let payload: [String: Any] = [
            "scope": "student",
            "scopeId": scopeId,
            "appWhitelist": [bundleId],
            "clearAfter": 86_400
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        _ = try await send(
            method: "PUT",
            query: [URLQueryItem(name: "token", value: token)],
            body: body
        )
    }

    private func send(method: String, query: [URLQueryItem], body: Data?) async throws -> Data {
        var components = URLComponents(string: "\(configuration.fullBaseURL)/teacher/profiles")
        components?.queryItems = query
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(configuration.authorizationHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("4", forHTTPHeaderField: "X-Server-Protocol-Version")
        request.setValue(
            "hash=c683a60c07d2f6e4b1fd4e385d034954",
            forHTTPHeaderField: "Cookie"
        )
        request.httpBody = body

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let message = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["message"] as? String
            throw TeacherProfileLockError.requestFailed(statusCode: http.statusCode, message: message)
        }
        return data
    }
}
