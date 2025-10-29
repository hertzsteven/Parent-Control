//
//  APIConfiguration.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/29/25.
//

import Foundation

/// Configuration for Zuludesk/Jamf School API
struct APIConfiguration {
    // MARK: - Properties
    
    /// Base URL for the API (e.g., "yourDomain.jamfcloud.com" or "apiv6.zuludesk.com")
    let baseURL: String
    
    /// Network ID used as username for Basic Auth
    let networkID: String
    
    /// API Key used as password for Basic Auth
    let apiKey: String
    
    /// API version (defaults to 1)
    let apiVersion: String
    
    // MARK: - Initialization
    
    init(
        baseURL: String = "apiv6.zuludesk.com",
        networkID: String = "YOUR_NETWORK_ID",
        apiKey: String = "YOUR_API_KEY",
        apiVersion: String = "1"
    ) {
        self.baseURL = baseURL
        self.networkID = networkID
        self.apiKey = apiKey
        self.apiVersion = apiVersion
    }
    
    // MARK: - Computed Properties
    
    /// Full base URL with protocol
    var fullBaseURL: String {
        if baseURL.hasPrefix("http://") || baseURL.hasPrefix("https://") {
            return baseURL
        }
        return "https://\(baseURL)"
    }
    
    /// Generate Basic Authorization header value
    var authorizationHeader: String {
        let credentials = "\(networkID):\(apiKey)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            return ""
        }
        let base64Credentials = credentialsData.base64EncodedString()
        return "Basic \(base64Credentials)"
    }
}

// MARK: - Default Configuration
extension APIConfiguration {
    /// Default configuration for development/testing
    /// Replace these values with your actual Zuludesk credentials
    static let `default` = APIConfiguration()
    
    /// Create configuration with custom values
    static func custom(
        baseURL: String,
        networkID: String,
        apiKey: String
    ) -> APIConfiguration {
        APIConfiguration(
            baseURL: baseURL,
            networkID: networkID,
            apiKey: apiKey
        )
    }
}

