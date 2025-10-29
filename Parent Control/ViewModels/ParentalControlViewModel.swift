//
//  ParentalControlViewModel.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import Foundation
import Observation

@Observable
final class ParentalControlViewModel {
    var profileData: ProfileData
    var tileItems: [TileItem]
    var selectedItem: TileItem?
    
    init() {
        // Initialize profile data
        self.profileData = ProfileData(
            profileImage: "person.crop.circle.fill",
            name: "David Grossman",
            deviceInfo: "iPad (A16) Wi-Fi"
        )
        
        // Initialize tile items
        self.tileItems = [
            TileItem(
                title: "YouTube",
                description: "https://youtu.be/mm8cn53_pdU",
                iconName: "play.rectangle.fill",
                additionalInfo: "Allowed video streaming platform. User has access to YouTube content with parental controls enabled."
            ),
            TileItem(
                title: "Safari",
                description: "Web browser application",
                iconName: "safari",
                additionalInfo: "Default web browser. Configured with content filtering and restricted access to certain websites."
            ),
            TileItem(
                title: "Music",
                description: "Audio streaming service",
                iconName: "music.note",
                additionalInfo: "Music app with curated playlists. Explicit content is blocked by parental controls."
            ),
            TileItem(
                title: "App Store",
                description: "Application marketplace",
                iconName: "square.stack.fill",
                additionalInfo: "Limited access to App Store. Only approved apps can be downloaded and installed."
            ),
            TileItem(
                title: "Books",
                description: "Digital reading platform",
                iconName: "book.fill",
                additionalInfo: "Access to age-appropriate books and educational content. Restricted from mature publications."
            ),
            TileItem(
                title: "Photos",
                description: "Photo and video library",
                iconName: "photo.fill",
                additionalInfo: "Full access to photo library. Can view, organize, and edit photos taken on device."
            )
        ]
    }
    
    // MARK: - Actions
    
    /// Increase access level for a specific item
    func increaseAccess(for item: TileItem) {
        // TODO: Implement access level logic in future steps
        print("Increasing access for: \(item.title)")
    }
    
    /// Decrease access level for a specific item
    func decreaseAccess(for item: TileItem) {
        // TODO: Implement access level logic in future steps
        print("Decreasing access for: \(item.title)")
    }
}

