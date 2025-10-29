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
        return response.devices
    }
    
    // MARK: - Private Methods
    
    /// Generic request method for API calls
    /// - Parameters:
    ///   - endpoint: API endpoint path (e.g., "/apps/")
    ///   - method: HTTP method (GET, POST, etc.)
    ///   - body: Optional request body data
    /// - Returns: Decoded response of type T
    /// - Throws: NetworkError if request fails
    private func request<T: Decodable>(
        endpoint: String,
        method: String,
        body: Data? = nil
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
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.apiVersion, forHTTPHeaderField: "X-Server-Protocol-Version")
        
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

