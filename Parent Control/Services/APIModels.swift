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
struct DeviceDTO: Codable {
    let udid: String  // Using UDID as the unique identifier
    let name: String
    let serialNumber: String?
    let assetTag: String?
    let deviceClass: String?  // "ipad", "iphone", etc.
    let model: DeviceModel?
    let os: DeviceOS?
    let owner: DeviceOwner?
    let batteryLevel: Double?
    let totalCapacity: Int?
    let availableCapacity: Double?
    let isManaged: Bool?
    let isSupervised: Bool?
    let lastCheckin: String?
    let groupIds: [String]?
    let groups: [String]?
    let apps: [DeviceAppDTO]?  // Apps installed on this device
    
    enum CodingKeys: String, CodingKey {
        case udid = "UDID"
        case name
        case serialNumber
        case assetTag
        case deviceClass = "class"
        case model
        case os
        case owner
        case batteryLevel
        case totalCapacity
        case availableCapacity
        case isManaged
        case isSupervised
        case lastCheckin
        case groupIds
        case groups
        case apps
    }
}

/// App information within device response
struct DeviceAppDTO: Codable {
    let name: String?
    let identifier: String?  // This is the bundleId
    let vendor: String?
    let version: String?
    let icon: String?
}

/// Device model information
struct DeviceModel: Codable {
    let name: String?
    let identifier: String?
    let type: String?
}

/// Device OS information
struct DeviceOS: Codable {
    let prefix: String?  // "iOS", "iPadOS", etc.
    let version: String?
}

/// Device owner information
struct DeviceOwner: Codable {
    let id: Int?
    let username: String?
    let email: String?
    let firstName: String?
    let lastName: String?
    let name: String?
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

