//
//  AppItem.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import Foundation

/// Represents a controlled app with parental control settings
struct AppItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let iconName: String // SF Symbol name (fallback)
    let iconURL: String? // URL to actual app icon from API
    let bundleId: String? // Bundle identifier from API (e.g., "com.apple.Safari")
    let additionalInfo: String
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        iconName: String,
        iconURL: String? = nil,
        bundleId: String? = nil,
        additionalInfo: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.iconURL = iconURL
        self.bundleId = bundleId
        self.additionalInfo = additionalInfo
    }
}

// MARK: - Mock Data for Previews
#if DEBUG
extension AppItem {
    /// Sample app item for previews and testing
    static let sample = AppItem(
        title: "YouTube",
        description: "Video streaming platform",
        iconName: "play.rectangle.fill",
        additionalInfo: "Allowed video streaming platform with parental controls enabled."
    )
    
    /// Collection of sample apps for previews
    static let samples: [AppItem] = [
        AppItem(
            title: "YouTube",
            description: "https://youtu.be/mm8cn53_pdU",
            iconName: "play.rectangle.fill",
            additionalInfo: "Allowed video streaming platform. User has access to YouTube content with parental controls enabled."
        ),
        AppItem(
            title: "Safari",
            description: "Web browser application",
            iconName: "safari",
            additionalInfo: "Default web browser. Configured with content filtering and restricted access to certain websites."
        ),
        AppItem(
            title: "Music",
            description: "Audio streaming service",
            iconName: "music.note",
            additionalInfo: "Music app with curated playlists. Explicit content is blocked by parental controls."
        )
    ]
}
#endif

