//
//  ChildData.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import Foundation

/// Represents a child's profile and device information
struct ChildData: Identifiable, Codable, Equatable {
    let id: UUID
    let childImage: String
    let name: String
    let deviceInfo: String
    
    init(
        id: UUID = UUID(),
        childImage: String,
        name: String,
        deviceInfo: String
    ) {
        self.id = id
        self.childImage = childImage
        self.name = name
        self.deviceInfo = deviceInfo
    }
}

// MARK: - Mock Data for Previews
#if DEBUG
extension ChildData {
    /// Sample child data for previews and testing
    static let sample = ChildData(
        childImage: "person.crop.circle.fill",
        name: "David Grossman",
        deviceInfo: "iPad (A16) Wi-Fi"
    )
}
#endif

