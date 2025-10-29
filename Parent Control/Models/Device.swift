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
    let name: String
    let iconName: String
    let ringColor: String // Stored as string for Codable, converted to Color in UI
    let appIds: [UUID] // IDs of apps associated with this device
    
    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        ringColor: String,
        appIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.ringColor = ringColor
        self.appIds = appIds
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
}

// MARK: - Mock Data for Previews
#if DEBUG
extension Device {
    /// Sample device for previews and testing
    static let sample = Device(
        name: "Living Room iPad",
        iconName: "ipad.gen1",
        ringColor: "blue",
        appIds: []
    )
    
    /// Collection of sample devices for previews
    static let samples: [Device] = [
        Device(
            name: "Living Room iPad",
            iconName: "ipad.gen1",
            ringColor: "blue",
            appIds: []
        ),
        Device(
            name: "Bedroom iPad",
            iconName: "ipad.gen2",
            ringColor: "green",
            appIds: []
        ),
        Device(
            name: "Kids Room iPad",
            iconName: "ipad.landscape",
            ringColor: "purple",
            appIds: []
        )
    ]
}
#endif

