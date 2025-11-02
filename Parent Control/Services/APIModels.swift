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

// MARK: - Set Device Owner Request/Response

/// Request body for setting device owner
struct SetDeviceOwnerRequest: Codable {
    let user: String  // User ID to set as owner (e.g., "143")
}

/// Response from set device owner endpoint
struct SetDeviceOwnerResponse: Codable {
    let success: Bool?
    let message: String?
}

// MARK: - App Lock Request/Response

/// Request body for applying app lock (whitelist) to students
struct AppLockRequest: Codable {
    let apps: String  // Bundle ID of the app to whitelist (e.g., "com.thup.MonkeyMath")
    let clearAfter: String  // Duration in seconds before clearing the lock (e.g., "60")
    let students: String  // Comma-separated student IDs (e.g., "143")
}

/// Response from app lock endpoint
struct AppLockResponse: Codable {
    let success: Bool?
    let message: String?
}

// MARK: - Stop App Lock (Unlock) Request/Response

/// Request body for stopping app lock (unlocking)
struct StopAppLockRequest: Codable {
    let scope: String  // "student"
    let scopeId: String  // Student ID (e.g., "143")
}

/// Task in unlock response
struct UnlockTask: Codable {
    let id: String
    let student: String
    let UUID: String
    let status: String
    let errorMessage: String?
    let errorDomain: String?
}

/// Response from stop app lock endpoint
struct StopAppLockResponse: Codable {
    let tasks: [UnlockTask]?
    let success: Bool?
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

// MARK: - Class Response

/// Response structure for class endpoint
struct ClassResponse: Codable {
    let code: Int
    let classDetails: ClassDetails
    
    enum CodingKeys: String, CodingKey {
        case code
        case classDetails = "class"
    }
}

/// Class details including students and teachers
struct ClassDetails: Codable {
    let uuid: String
    let name: String
    let description: String?
    let studentCount: Int
    let students: [StudentDTO]
    let teacherCount: Int
    let teachers: [TeacherDTO]
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, description, studentCount, students, teacherCount, teachers
    }
}

/// Data Transfer Object for student from Zuludesk API
struct StudentDTO: Codable {
    let id: Int
    let name: String
    let email: String?
    let username: String?
    let firstName: String?
    let lastName: String?
    let photo: String?
}

/// Data Transfer Object for teacher from Zuludesk API
struct TeacherDTO: Codable {
    let id: Int
    let name: String
    let email: String?
    let username: String?
    let firstName: String?
    let lastName: String?
    let photo: String?
}

// MARK: - Classes List Response

/// Response structure for classes list endpoint
struct ClassesListResponse: Codable {
    let classes: [ClassListItem]
}

/// Individual class item in the classes list
struct ClassListItem: Codable {
    let uuid: String
    let name: String
    let description: String?
    let studentCount: Int
    let teacherCount: Int
    let userGroupId: Int?
    
    enum CodingKeys: String, CodingKey {
        case uuid, name, description, studentCount, teacherCount, userGroupId
    }
}

// MARK: - Teacher Groups Response

/// Response structure for teacher groups endpoint
struct TeacherGroupsResponse: Codable {
    let code: Int
    let results: [TeacherGroup]
}

/// Individual teacher group
struct TeacherGroup: Codable {
    let id: Int
    let name: String
    let description: String?
    let classNumber: String?
    let photo: String?
    let colorId: Int?
    let isShared: Bool?
    let isEditable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, classNumber, photo, colorId, isShared, isEditable
    }
}

// MARK: - Teacher Authentication Request/Response

/// Request body for teacher authentication
struct TeacherAuthRequest: Codable {
    let company: String
    let username: String
    let password: String
}

/// Authenticated user information from teacher authentication
struct AuthenticatedUser: Codable {
    let id: Int
    let companyId: Int
    let username: String
    let firstName: String
    let lastName: String
    let name: String
}

/// Response from teacher authentication endpoint
struct TeacherAuthResponse: Codable {
    let code: Int
    let token: String
    let feature: String
    let authenticatedAs: AuthenticatedUser
}

/// Response from token validation endpoint
struct TokenValidationResponse: Codable {
    let code: Int
    let message: String
}

