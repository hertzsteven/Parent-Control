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
    
    /// Teacher API token for app lock operations
    let teacherToken: String
    
    /// Hardcoded class ID for testing (will be dynamic later)
    let classId: String
    
    // MARK: - Initialization
    
    init(
        baseURL: String = "developitsnfrEDU.jamfcloud.com/api",
        networkID: String = "65319076",
        apiKey: String = "MCSMD6VC7MCKUNN8MJ5CDA96R1HZBGAV",
        apiVersion: String = "1",
        teacherToken: String = "1fac4ce4ddbe4d1c984432aedd02c59f",
        classId: String = "62743db3-2001-4568-8cbc-d415f4f3f939"
    ) {
        self.baseURL = baseURL
        self.networkID = networkID
        self.apiKey = apiKey
        self.apiVersion = apiVersion
        self.teacherToken = teacherToken
        self.classId = classId
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

