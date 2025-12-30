//
//  Device.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/29/25.
//

import SwiftUI

/// Represents a physical device (iPad) with associated apps
struct Device: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let udid: String // Device UDID for API calls
    let name: String
    let iconName: String
    let ringColor: String // Stored as string for Codable, converted to Color in UI
    let appIds: [UUID] // IDs of apps associated with this device
    let ownerId: String? // Owner/Student ID from API (nil if not assigned)
    
    // Device status information
    let batteryLevel: Double? // Battery level (0.0 to 1.0)
    let modelName: String? // e.g., "iPad (A16)"
    let deviceClass: String? // e.g., "ipad", "iphone"
    
    init(
        id: UUID = UUID(),
        udid: String,
        name: String,
        iconName: String,
        ringColor: String,
        appIds: [UUID] = [],
        ownerId: String? = nil,
        batteryLevel: Double? = nil,
        modelName: String? = nil,
        deviceClass: String? = nil
    ) {
        self.id = id
        self.udid = udid
        self.name = name
        self.iconName = iconName
        self.ringColor = ringColor
        self.appIds = appIds
        self.ownerId = ownerId
        self.batteryLevel = batteryLevel
        self.modelName = modelName
        self.deviceClass = deviceClass
    }
    
    /// Convert stored color string to SwiftUI Color
    var color: Color {
        switch ringColor.lowercased() {
        case "blue":
            return .blue
        case "green":
            return .green
        case "purple":
            return .purple
        case "orange":
            return .orange
        case "red":
            return .red
        case "pink":
            return .pink
        case "yellow":
            return .yellow
        case "cyan":
            return .cyan
        case "silver", "gray", "grey":
            return Color(white: 0.7) // Silver/gray color
        case "black":
            return .black
        default:
            return .blue
        }
    }
    
    /// Whether this device has a valid owner assigned
    var hasOwner: Bool {
        return ownerId != nil && !ownerId!.isEmpty
    }
    
    /// Get battery icon based on level
    func batteryIcon(isCharging: Bool = false) -> String {
        guard let level = batteryLevel else { return "battery.0" }
        
        if isCharging {
            return "battery.100.bolt"
        }
        
        let percentage = Int(level * 100)
        switch percentage {
        case 90...100:
            return "battery.100"
        case 60..<90:
            return "battery.75"
        case 30..<60:
            return "battery.50"
        case 10..<30:
            return "battery.25"
        default:
            return "battery.0"
        }
    }
    
    /// Get battery color based on level
    func batteryColor() -> Color {
        guard let level = batteryLevel else { return .gray }
        
        let percentage = Int(level * 100)
        switch percentage {
        case 30...100:
            return .green
        case 10..<30:
            return .orange
        default:
            return .red
        }
    }
    
    /// Formatted battery percentage string
    var batteryPercentage: String? {
        guard let level = batteryLevel else { return nil }
        return "\(Int(level * 100))%"
    }
    
    /// User-friendly message explaining why owner is needed
    var ownerRequirementMessage: String {
        return "This device has no owner assigned. Please assign an owner in Zuludesk before managing app locks."
    }
}

// MARK: - Mock Data for Previews
#if DEBUG
extension Device {
    /// Sample device for previews and testing
    static let sample = Device(
        udid: "00008120-0000000000000000",
        name: "Living Room iPad",
        iconName: "ipad.gen1",
        ringColor: "blue",
        appIds: [],
        ownerId: "143",
        batteryLevel: 0.73,
        modelName: "iPad (A16)",
        deviceClass: "ipad"
    )
    
    /// Collection of sample devices for previews
    static let samples: [Device] = [
        Device(
            udid: "00008120-0000000000000001",
            name: "Living Room iPad",
            iconName: "ipad.gen1",
            ringColor: "blue",
            appIds: [],
            ownerId: "143",
            batteryLevel: 0.85,
            modelName: "iPad Pro (M1)",
            deviceClass: "ipad"
        ),
        Device(
            udid: "00008120-0000000000000002",
            name: "Bedroom iPad",
            iconName: "ipad.gen2",
            ringColor: "green",
            appIds: [],
            ownerId: "143",
            batteryLevel: 0.42,
            modelName: "iPad Air (A14)",
            deviceClass: "ipad"
        ),
        Device(
            udid: "00008120-0000000000000003",
            name: "Kids Room iPad",
            iconName: "ipad.landscape",
            ringColor: "purple",
            appIds: [],
            ownerId: "143",
            batteryLevel: 0.15,
            modelName: "iPad (A13)",
            deviceClass: "ipad"
        )
    ]
}
#endif

