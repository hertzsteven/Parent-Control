//
//  NetworkService.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/29/25.
//

import Foundation

// MARK: - Network Error

/// Custom error types for network operations
enum NetworkError: LocalizedError {
    case invalidURL
    case authenticationFailed
    case networkUnavailable
    case invalidResponse
    case decodingFailed(Error)
    case serverError(statusCode: Int, message: String?)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid"
        case .authenticationFailed:
            return "Authentication failed. Please check your Network ID and API Key"
        case .networkUnavailable:
            return "Network is unavailable. Please check your connection"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message ?? "Unknown error")"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Network Service

/// Service class for handling Zuludesk API network requests
final class NetworkService {
    // MARK: - Properties
    
    private let configuration: APIConfiguration
    private let session: URLSession
    
    // MARK: - Initialization
    
    init(configuration: APIConfiguration = .default, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }
    
    // MARK: - Public Methods
    
    /// Fetch all apps from Zuludesk API
    /// - Returns: Array of AppDTO objects
    /// - Throws: NetworkError if request fails
    func fetchApps() async throws -> [AppDTO] {
        let endpoint = "/apps/"
        let response: AppsResponse = try await request(endpoint: endpoint, method: "GET")
        return response.apps
    }
    
    /// Fetch all devices from Zuludesk API
    /// - Parameter includeApps: Include installed apps in response (default: true)
    /// - Returns: Array of DeviceDTO objects
    /// - Throws: NetworkError if request fails
    func fetchDevices(includeApps: Bool = true) async throws -> [DeviceDTO] {
        let endpoint = "/devices/?includeApps=\(includeApps)"
        let response: DevicesResponse = try await request(endpoint: endpoint, method: "GET")
        let devices = response.devices
        print("fetchDevices(includeApps: \(includeApps)) returned \(devices.count) devices:", devices)
        return devices
    }
    
    /// Fetch all classes from Zuludesk API
    /// - Returns: ClassesListResponse with list of all classes
    /// - Throws: NetworkError if request fails
    func fetchClasses() async throws -> ClassesListResponse {
        let endpoint = "/classes"
        let response: ClassesListResponse = try await request(
            endpoint: endpoint,
            method: "GET",
            protocolVersion: "3",
            additionalHeaders: ["Cookie": "hash=c683a60c07d2f6e4b1fd4e385d034954"]
        )
        return response
    }
    
    /// Fetch teacher groups from Zuludesk API
    /// - Parameter token: Teacher API token
    /// - Returns: TeacherGroupsResponse with list of teacher groups
    /// - Throws: NetworkError if request fails
    func fetchTeacherGroups(token: String) async throws -> TeacherGroupsResponse {
        let endpoint = "/teacher/groups?token=\(token)"
        let response: TeacherGroupsResponse = try await request(
            endpoint: endpoint,
            method: "GET",
            protocolVersion: "2",
            additionalHeaders: ["Cookie": "hash=c683a60c07d2f6e4b1fd4e385d034954"]
        )
        return response
    }
    
    /// Fetch class details from Zuludesk API
    /// - Parameter classId: The UUID of the class to fetch
    /// - Returns: ClassResponse with class details and students
    /// - Throws: NetworkError if request fails
    func fetchClass(classId: String) async throws -> ClassResponse {
        let endpoint = "/classes/\(classId)"
        let response: ClassResponse = try await request(
            endpoint: endpoint,
            method: "GET",
            protocolVersion: "3",
            additionalHeaders: ["Cookie": "hash=c683a60c07d2f6e4b1fd4e385d034954"]
        )
        return response
    }
    
    /// Set device owner
    /// - Parameters:
    ///   - deviceUDID: The UDID of the device
    ///   - userId: The user ID to set as owner
    /// - Returns: SetDeviceOwnerResponse
    /// - Throws: NetworkError if request fails
    func setDeviceOwner(
        deviceUDID: String,
        userId: String
    ) async throws -> SetDeviceOwnerResponse {
        let endpoint = "/devices/\(deviceUDID)/owner"
        
        let requestBody = SetDeviceOwnerRequest(user: userId)
        let bodyData = try JSONEncoder().encode(requestBody)
        
        // Use custom request method with text/plain content type and cookie
        let response: SetDeviceOwnerResponse = try await request(
            endpoint: endpoint,
            method: "PUT",
            body: bodyData,
            contentType: "text/plain; charset=utf-8",
            additionalHeaders: ["Cookie": "hash=c683a60c07d2f6e4b1fd4e385d034954"]
        )
        
        return response
    }
    
    /// Apply app lock (whitelist) to specific students
    /// - Parameters:
    ///   - bundleId: Bundle ID of the app to whitelist (e.g., "com.thup.MonkeyMath")
    ///   - clearAfterSeconds: Duration in seconds before clearing the lock
    ///   - studentIds: Array of student IDs to apply the lock to
    ///   - token: Authentication token for the teacher API
    /// - Returns: AppLockResponse
    /// - Throws: NetworkError if request fails
    func applyAppLock(
        bundleId: String,
        clearAfterSeconds: Int,
        studentIds: [String],
        token: String
    ) async throws -> AppLockResponse {
        let endpoint = "/teacher/apply/applock?token=\(token)"
        
        let requestBody = AppLockRequest(
            apps: bundleId,
            clearAfter: String(clearAfterSeconds),
            students: studentIds.joined(separator: ",")
        )
        
        let bodyData = try JSONEncoder().encode(requestBody)
        
        // Use custom request method with protocol version 2 and cookie
        let response: AppLockResponse = try await request(
            endpoint: endpoint,
            method: "POST",
            body: bodyData,
            protocolVersion: "2",
            additionalHeaders: ["Cookie": "hash=c683a60c07d2f6e4b1fd4e385d034954"]
        )
        
        return response
    }
    
    /// Stop app lock (unlock) for a specific student
    /// - Parameters:
    ///   - studentId: The student ID to unlock (e.g., "143")
    ///   - token: Authentication token for the teacher API
    /// - Returns: StopAppLockResponse
    /// - Throws: NetworkError if request fails
    func stopAppLock(
        studentId: String,
        token: String
    ) async throws -> StopAppLockResponse {
        let endpoint = "/teacher/lessons/stop?token=\(token)"
        
        let requestBody = StopAppLockRequest(
            scope: "student",
            scopeId: studentId
        )
        
        // Convert to form URL-encoded format
        let bodyString = "scope=\(requestBody.scope)&scopeId=\(requestBody.scopeId)"
        let bodyData = bodyString.data(using: .utf8)
        
        // Use custom request method with protocol version 4 and cookie
        let response: StopAppLockResponse = try await request(
            endpoint: endpoint,
            method: "POST",
            body: bodyData,
            contentType: "application/x-www-form-urlencoded; charset=utf-8",
            protocolVersion: "4",
            additionalHeaders: ["Cookie": "hash=c683a60c07d2f6e4b1fd4e385d034954"]
        )
        
        return response
    }
    
    /// Authenticate teacher and retrieve API token
    /// - Parameters:
    ///   - company: Company ID (e.g., "2001128")
    ///   - username: Teacher username (e.g., "gmteacher")
    ///   - password: Teacher password
    /// - Returns: TeacherAuthResponse containing token and authenticated user info
    /// - Throws: NetworkError if request fails
    func authenticateTeacher(
        company: String,
        username: String,
        password: String
    ) async throws -> TeacherAuthResponse {
        let endpoint = "/teacher/authenticate"
        
        let requestBody = TeacherAuthRequest(
            company: company,
            username: username,
            password: password
        )
        
        let bodyData = try JSONEncoder().encode(requestBody)
        
        // Use custom request method with protocol version 2 and cookie
        let response: TeacherAuthResponse = try await request(
            endpoint: endpoint,
            method: "POST",
            body: bodyData,
            protocolVersion: "2",
            additionalHeaders: ["Cookie": "hash=c683a60c07d2f6e4b1fd4e385d034954"]
        )
        
        return response
    }
    
    /// Validate an existing teacher token
    /// - Parameter token: The teacher token to validate
    /// - Returns: TokenValidationResponse indicating if token is valid
    /// - Throws: NetworkError if request fails
    func validateToken(_ token: String) async throws -> TokenValidationResponse {
        let endpoint = "/teacher/validate?token=\(token)"
        
        // Use custom request method with protocol version 2 and cookie
        let response: TokenValidationResponse = try await request(
            endpoint: endpoint,
            method: "GET",
            protocolVersion: "2",
            additionalHeaders: ["Cookie": "hash=c683a60c07d2f6e4b1fd4e385d034954"]
        )
        
        return response
    }
    
    // MARK: - Private Methods
    
    /// Generic request method for API calls
    /// - Parameters:
    ///   - endpoint: API endpoint path (e.g., "/apps/")
    ///   - method: HTTP method (GET, POST, etc.)
    ///   - body: Optional request body data
    ///   - contentType: Optional content type override (default: "application/json")
    ///   - protocolVersion: Optional protocol version override (default: uses config value)
    ///   - additionalHeaders: Optional additional headers to include
    /// - Returns: Decoded response of type T
    /// - Throws: NetworkError if request fails
    private func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: Data? = nil,
        contentType: String? = nil,
        protocolVersion: String? = nil,
        additionalHeaders: [String: String]? = nil
    ) async throws -> T {
        // Construct URL
        guard let url = URL(string: "\(configuration.fullBaseURL)\(endpoint)") else {
            throw NetworkError.invalidURL
        }
        
        print("\n🌐 API REQUEST")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📍 URL: \(url.absoluteString)")
        print("🔧 Method: \(method)")
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(configuration.authorizationHeader, forHTTPHeaderField: "Authorization")
        request.setValue(contentType ?? "application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(protocolVersion ?? configuration.apiVersion, forHTTPHeaderField: "X-Server-Protocol-Version")
        
        // Add any additional headers
        if let additionalHeaders = additionalHeaders {
            for (key, value) in additionalHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        // Perform request
        let (data, response) = try await session.data(for: request)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP Response")
            throw NetworkError.invalidResponse
        }
        
        print("📊 Status Code: \(httpResponse.statusCode)")
        print("📦 Response Size: \(data.count) bytes")
        
        // Print raw response for debugging
        if let jsonString = String(data: data, encoding: .utf8) {
            print("📄 Raw Response:")
            print(jsonString.prefix(1000)) // First 1000 characters
            if jsonString.count > 1000 {
                print("... (\(jsonString.count - 1000) more characters)")
            }
        }
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
        
        // Handle HTTP status codes
        switch httpResponse.statusCode {
        case 200...299:
            // Success - decode response
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(T.self, from: data)
                print("✅ Successfully decoded \(T.self)")
                return decoded
            } catch {
                print("❌ DECODING ERROR for \(T.self):")
                print("   \(error)")
                
                // Try to print more detailed decoding error
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("   Missing key: '\(key.stringValue)' - \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("   Type mismatch: expected \(type) - \(context.debugDescription)")
                        print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    case .valueNotFound(let type, let context):
                        print("   Value not found: \(type) - \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("   Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("   Unknown decoding error")
                    }
                }
                
                throw NetworkError.decodingFailed(error)
            }
            
        case 401:
            print("🔐 Authentication Failed (401)")
            throw NetworkError.authenticationFailed
            
        case 400...499, 500...599:
            // Try to decode error response
            let errorMessage = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            print("⚠️ Server Error: \(httpResponse.statusCode)")
            if let errorMessage = errorMessage {
                print("   Message: \(errorMessage.message ?? "No message")")
            }
            throw NetworkError.serverError(
                statusCode: httpResponse.statusCode,
                message: errorMessage?.message
            )
            
        default:
            print("⚠️ Unexpected Status Code: \(httpResponse.statusCode)")
            throw NetworkError.serverError(
                statusCode: httpResponse.statusCode,
                message: "Unexpected status code"
            )
        }
    }
}

// MARK: - URLSession Error Handling Extension

extension NetworkService {
    /// Helper to convert URLError to NetworkError
    private func handleURLError(_ error: Error) -> NetworkError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            default:
                return .unknown(error)
            }
        }
        return .unknown(error)
    }
}

