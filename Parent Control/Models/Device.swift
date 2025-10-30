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
    
    init(
        id: UUID = UUID(),
        udid: String,
        name: String,
        iconName: String,
        ringColor: String,
        appIds: [UUID] = [],
        ownerId: String? = nil
    ) {
        self.id = id
        self.udid = udid
        self.name = name
        self.iconName = iconName
        self.ringColor = ringColor
        self.appIds = appIds
        self.ownerId = ownerId
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
        default:
            return .blue
        }
    }
    
    /// Whether this device has a valid owner assigned
    var hasOwner: Bool {
        return ownerId != nil && !ownerId!.isEmpty
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
        ownerId: "143"
    )
    
    /// Collection of sample devices for previews
    static let samples: [Device] = [
        Device(
            udid: "00008120-0000000000000001",
            name: "Living Room iPad",
            iconName: "ipad.gen1",
            ringColor: "blue",
            appIds: [],
            ownerId: "143"
        ),
        Device(
            udid: "00008120-0000000000000002",
            name: "Bedroom iPad",
            iconName: "ipad.gen2",
            ringColor: "green",
            appIds: [],
            ownerId: "143"
        ),
        Device(
            udid: "00008120-0000000000000003",
            name: "Kids Room iPad",
            iconName: "ipad.landscape",
            ringColor: "purple",
            appIds: [],
            ownerId: "143"
        )
    ]
}
#endif

