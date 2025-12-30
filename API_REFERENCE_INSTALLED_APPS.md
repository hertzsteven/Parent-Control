# Parent Control App - API Reference: Retrieving Installed Applications

## Overview

This document explains how the **Parent Control** iOS app retrieves the list of applications installed on managed iPad devices. The app integrates with the **Zuludesk/Jamf School MDM (Mobile Device Management) API** to fetch device and application data.

---

## API Provider

- **Service**: Zuludesk / Jamf School API
- **Base URL**: `https://apiv6.zuludesk.com` (configurable)
- **API Documentation**: https://api.zuludesk.com/docs/

---

## Authentication

The API uses **HTTP Basic Authentication** with two credentials:

| Credential | Description | How to Obtain |
|------------|-------------|---------------|
| **Network ID** | Organization identifier | Found in Zuludesk: `Devices > Enroll Device(s)` |
| **API Key** | API access key | Generate from: `Organization > Settings > API` |

### Authorization Header Format

```
Authorization: Basic <base64(networkID:apiKey)>
```

The credentials are combined as `networkID:apiKey`, then Base64 encoded.

### Additional Request Headers

```
Content-Type: application/json
X-Server-Protocol-Version: 1  (or version 2, 3, 4 depending on endpoint)
Cookie: hash=c683a60c07d2f6e4b1fd4e385d034954  (required for most endpoints)
```

---

## Key Endpoints for Retrieving Installed Apps

### 1. Fetch All Devices with Installed Apps

**Endpoint**: `GET /devices/?includeApps=true`

**Purpose**: Retrieves all MDM-enrolled devices along with the list of apps installed on each device.

**Request**:
```http
GET https://apiv6.zuludesk.com/devices/?includeApps=true
Authorization: Basic <base64(networkID:apiKey)>
Content-Type: application/json
X-Server-Protocol-Version: 1
```

**Response Structure**:
```json
{
  "devices": [
    {
      "UDID": "00008030-001A312A3C80C02E",
      "name": "iPad-Blue-5",
      "serialNumber": "DMPH3N2HL0VC",
      "assetTag": "5th-Grade-iPad-Blue",
      "class": "ipad",
      "model": {
        "name": "iPad Pro (11-inch)",
        "identifier": "iPad11,1",
        "type": "iPad"
      },
      "os": {
        "prefix": "iPadOS",
        "version": "17.2"
      },
      "owner": {
        "id": 143,
        "username": "jdoe",
        "email": "jdoe@school.edu",
        "firstName": "John",
        "lastName": "Doe",
        "name": "John Doe"
      },
      "batteryLevel": 85.5,
      "totalCapacity": 64000,
      "availableCapacity": 42000.5,
      "isManaged": true,
      "isSupervised": true,
      "lastCheckin": "2024-12-11T15:00:00Z",
      "groupIds": ["group-123", "group-456"],
      "groups": ["5th Grade", "Math Class"],
      "apps": [
        {
          "name": "Pages",
          "identifier": "com.apple.pages",
          "vendor": "Apple",
          "version": "13.2",
          "icon": "https://is1-ssl.mzstatic.com/image/thumb/Purple.../60x60bb.png"
        },
        {
          "name": "Keynote",
          "identifier": "com.apple.keynote",
          "vendor": "Apple",
          "version": "13.2",
          "icon": "https://is1-ssl.mzstatic.com/image/thumb/Purple.../60x60bb.png"
        },
        {
          "name": "MathMonsters",
          "identifier": "com.thup.MonkeyMath",
          "vendor": "Thup Games",
          "version": "2.1",
          "icon": "https://is1-ssl.mzstatic.com/image/thumb/Purple.../60x60bb.png"
        }
      ]
    }
  ]
}
```

### 2. Fetch All Available MDM Apps (Master App Catalog)

**Endpoint**: `GET /apps/`

**Purpose**: Retrieves the master list of all apps available in the organization's MDM catalog (apps that CAN be installed on devices).

**Request**:
```http
GET https://apiv6.zuludesk.com/apps/
Authorization: Basic <base64(networkID:apiKey)>
Content-Type: application/json
X-Server-Protocol-Version: 1
```

**Response Structure**:
```json
{
  "apps": [
    {
      "id": 25769,
      "bundleId": "com.apple.pages",
      "adamId": 335493278,
      "name": "Pages",
      "vendor": "Apple",
      "platform": "iOS"
    },
    {
      "id": 25770,
      "bundleId": "com.apple.keynote",
      "adamId": 361285480,
      "name": "Keynote",
      "vendor": "Apple",
      "platform": "iOS"
    }
  ]
}
```

---

## Data Flow in the Application

```
┌─────────────────────┐
│   SwiftUI View      │
│ (DeviceSelectionView)│
└─────────┬───────────┘
          │ .task { await viewModel.loadData() }
          ▼
┌─────────────────────────┐
│ ParentalControlViewModel│
└─────────┬───────────────┘
          │ loadData()
          ▼
┌─────────────────────────┐
│    NetworkService       │
├─────────────────────────┤
│ • fetchApps()           │
│ • fetchDevices(         │
│     includeApps: true)  │
└─────────┬───────────────┘
          │
          ▼
┌─────────────────────────┐
│   Zuludesk/Jamf API     │
│   /apps/ & /devices/    │
└─────────┬───────────────┘
          │ JSON Response
          ▼
┌─────────────────────────┐
│     API DTOs            │
│ (AppDTO, DeviceDTO,     │
│  DeviceAppDTO)          │
└─────────┬───────────────┘
          │ ModelMappers.swift
          ▼
┌─────────────────────────┐
│    Domain Models        │
│ (AppItem, Device)       │
└─────────────────────────┘
```

---

## Swift Code Implementation

### NetworkService.swift - Fetching Devices with Apps

```swift
/// Fetch all devices from Zuludesk API
/// - Parameter includeApps: Include installed apps in response (default: true)
/// - Returns: Array of DeviceDTO objects
/// - Throws: NetworkError if request fails
func fetchDevices(includeApps: Bool = true) async throws -> [DeviceDTO] {
    let endpoint = "/devices/?includeApps=\(includeApps)"
    let response: DevicesResponse = try await request(endpoint: endpoint, method: "GET")
    return response.devices
}

/// Fetch all apps from Zuludesk API
/// - Returns: Array of AppDTO objects
/// - Throws: NetworkError if request fails
func fetchApps() async throws -> [AppDTO] {
    let endpoint = "/apps/"
    let response: AppsResponse = try await request(endpoint: endpoint, method: "GET")
    return response.apps
}
```

### APIModels.swift - Data Transfer Objects

```swift
/// Data Transfer Object for device from Zuludesk API
struct DeviceDTO: Codable {
    let udid: String           // Device unique identifier
    let name: String           // Device display name
    let serialNumber: String?
    let assetTag: String?
    let deviceClass: String?   // "ipad", "iphone", etc.
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
}

/// App information within device response
struct DeviceAppDTO: Codable {
    let name: String?          // Display name (e.g., "Pages")
    let identifier: String?    // Bundle ID (e.g., "com.apple.pages")
    let vendor: String?        // Publisher (e.g., "Apple")
    let version: String?       // App version
    let icon: String?          // URL to app icon image
}

/// Data Transfer Object for app from master catalog
struct AppDTO: Codable {
    let id: Int                // Internal app ID
    let bundleId: String       // Bundle identifier (e.g., "com.apple.pages")
    let adamId: Int?           // App Store ID (nil for enterprise apps)
    let name: String           // Display name
    let vendor: String         // Publisher
    let platform: String       // Platform (iOS, iPadOS, macOS)
}
```

### ParentalControlViewModel.swift - Loading Data

```swift
@MainActor
func loadData() async {
    isLoading = true
    
    do {
        // Step 1: Fetch master app catalog
        let appDTOs = try await networkService.fetchApps()
        let (fetchedApps, bundleIdMapping) = appDTOs.toAppItems()
        
        // Step 2: Fetch all devices with their installed apps
        let deviceDTOs = try await networkService.fetchDevices(includeApps: true)
        
        // Store for UI access
        self.deviceDTOs = deviceDTOs
        
        // Step 3: Build mapping of bundleId to icon URLs from device apps
        var bundleIdToIconURL: [String: String] = [:]
        for deviceDTO in deviceDTOs {
            if let apps = deviceDTO.apps {
                for app in apps {
                    if let bundleId = app.identifier, 
                       let iconURL = app.icon, 
                       !iconURL.isEmpty {
                        bundleIdToIconURL[bundleId] = iconURL
                    }
                }
            }
        }
        
        // Step 4: Convert DTOs to domain models
        let allDevices = deviceDTOs.toDevices(bundleIdMapping: bundleIdMapping)
        
        // Step 5: Update UI with fetched data
        self.appItems = fetchedApps
        self.devices = allDevices
        
    } catch let error as NetworkError {
        self.errorMessage = error.localizedDescription
    }
    
    isLoading = false
}
```

---

## Key Points Summary

| Aspect | Details |
|--------|---------|
| **MDM Platform** | Zuludesk / Jamf School |
| **Protocol** | HTTPS REST API with JSON responses |
| **Authentication** | HTTP Basic Auth (Network ID + API Key) |
| **Primary Endpoint for Installed Apps** | `GET /devices/?includeApps=true` |
| **App Info Includes** | Name, Bundle ID, Vendor, Version, Icon URL |
| **Device Info Includes** | UDID, Name, Serial, Owner, OS, Battery, Managed Status |
| **Swift Framework** | async/await with URLSession |

---

## Error Handling

The app handles the following network error cases:

| Error Type | Description |
|------------|-------------|
| `invalidURL` | URL construction failed |
| `authenticationFailed` | 401 - Invalid Network ID or API Key |
| `networkUnavailable` | No internet connection |
| `invalidResponse` | Unexpected response format |
| `decodingFailed` | JSON parsing error |
| `serverError` | 4xx or 5xx HTTP status codes |

---

## Configuration File

API credentials are stored in `Config.plist` (excluded from version control):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>ZULUDESK_BASE_URL</key>
    <string>apiv6.zuludesk.com</string>
    <key>NETWORK_ID</key>
    <string>YOUR_NETWORK_ID</string>
    <key>API_KEY</key>
    <string>YOUR_API_KEY</string>
</dict>
</plist>
```

---

## Related Files in Codebase

| File | Purpose |
|------|---------|
| `Parent Control/Services/NetworkService.swift` | API request handling |
| `Parent Control/Services/APIModels.swift` | Data Transfer Objects (DTOs) |
| `Parent Control/Services/APIConfiguration.swift` | API credentials & URL configuration |
| `Parent Control/Services/ModelMappers.swift` | DTO to domain model conversion |
| `Parent Control/ViewModels/ParentalControlViewModel.swift` | Business logic & state management |

---

## Additional Resources

- **Existing Docs in Repo**: 
  - `NETWORK_INTEGRATION_SUMMARY.md` - Full integration overview
  - `AUTHENTICATION_IMPLEMENTATION.md` - Teacher authentication flow
  - `Parent Control/Services/README.md` - Services folder documentation
