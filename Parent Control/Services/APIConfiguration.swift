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
        baseURL: String? = nil,
        networkID: String? = nil,
        apiKey: String? = nil,
        apiVersion: String? = nil,
        teacherToken: String? = nil,
        classId: String? = nil
    ) {
        // Load configuration from Config.plist
        let config = Self.loadConfig()
        
        // Use provided values, fallback to config file, then to empty string
        self.baseURL = baseURL ?? config["API_BASE_URL"] as? String ?? ""
        self.networkID = networkID ?? config["NETWORK_ID"] as? String ?? ""
        self.apiKey = apiKey ?? config["API_KEY"] as? String ?? ""
        self.apiVersion = apiVersion ?? config["API_VERSION"] as? String ?? "1"
        self.teacherToken = teacherToken ?? config["TEACHER_TOKEN"] as? String ?? ""
        self.classId = classId ?? config["CLASS_ID"] as? String ?? ""
        
        // Print warning if config is missing critical values
        #if DEBUG
        if self.baseURL.isEmpty || self.networkID.isEmpty || self.apiKey.isEmpty {
            print("⚠️ WARNING: API Configuration is incomplete!")
            print("   Please ensure Config.plist exists and contains valid credentials.")
            print("   Copy Config.plist.template to Config.plist and fill in your credentials.")
        }
        #endif
    }
    
    // MARK: - Private Methods
    
    /// Load configuration from Config.plist file
    /// - Returns: Dictionary with configuration values, or empty dictionary if file not found
    private static func loadConfig() -> [String: Any] {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            #if DEBUG
            print("⚠️ Config.plist not found in bundle.")
            print("   Expected location: Bundle.main (Parent Control target)")
            print("   Make sure Config.plist is added to the Xcode target's 'Copy Bundle Resources'")
            #endif
            return [:]
        }
        
        guard let config = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            #if DEBUG
            print("⚠️ Failed to read Config.plist")
            print("   The file may be malformed or have invalid XML")
            #endif
            return [:]
        }
        
        #if DEBUG
        print("✅ Loaded configuration from Config.plist")
        #endif
        
        return config
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
    /// Default configuration - loads from Config.plist
    /// Ensure Config.plist exists with your credentials before using
    static let `default` = APIConfiguration()
    
    /// Create configuration with custom values (bypasses Config.plist)
    /// Use this when you need to provide credentials programmatically
    static func custom(
        baseURL: String,
        networkID: String,
        apiKey: String,
        apiVersion: String = "1",
        teacherToken: String = "",
        classId: String = ""
    ) -> APIConfiguration {
        APIConfiguration(
            baseURL: baseURL,
            networkID: networkID,
            apiKey: apiKey,
            apiVersion: apiVersion,
            teacherToken: teacherToken,
            classId: classId
        )
    }
}

