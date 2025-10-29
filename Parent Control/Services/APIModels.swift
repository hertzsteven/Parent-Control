//
//  APIModels.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/29/25.
//

import Foundation

// MARK: - Apps Response

/// Response structure for apps endpoint
struct AppsResponse: Codable {
    let apps: [AppDTO]
}

/// Data Transfer Object for app from Zuludesk API
struct AppDTO: Codable {
    let id: Int
    let bundleId: String
    let adamId: Int?  // Optional because enterprise apps don't include this
    let name: String
    let vendor: String
    let platform: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case bundleId
        case adamId
        case name
        case vendor
        case platform
    }
}

// MARK: - Devices Response

/// Response structure for devices endpoint
struct DevicesResponse: Codable {
    let devices: [DeviceDTO]
}

/// Data Transfer Object for device from Zuludesk API
/// Note: Adjust fields based on actual API response structure
struct DeviceDTO: Codable {
    let id: Int
    let name: String
    let deviceType: String?
    let model: String?
    let osVersion: String?
    let serialNumber: String?
    let apps: [Int]?  // Array of app IDs associated with this device
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case deviceType = "device_type"
        case model
        case osVersion = "os_version"
        case serialNumber = "serial_number"
        case apps
    }
}

// MARK: - Error Response

/// Error response from Zuludesk API
struct APIErrorResponse: Codable {
    let error: String?
    let message: String?
    let statusCode: Int?
    
    enum CodingKeys: String, CodingKey {
        case error
        case message
        case statusCode = "status_code"
    }
}

