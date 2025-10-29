//
//  ParentalControlViewModel.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import Foundation
import Observation

/// ViewModel managing parental control state and business logic
@Observable
final class ParentalControlViewModel {
    // MARK: - Properties
    
    /// Current child's profile information
    var childData: ChildData
    
    /// List of apps under parental control
    var appItems: [AppItem]
    
    /// Currently selected app item (if any)
    var selectedItem: AppItem?
    
    // MARK: - Initialization
    
    init(childData: ChildData? = nil, appItems: [AppItem]? = nil) {
        // Initialize child data
        self.childData = childData ?? ChildData(
            childImage: "person.crop.circle.fill",
            name: "David Grossman",
            deviceInfo: "iPad (A16) Wi-Fi"
        )
        
        // Initialize app items
        self.appItems = appItems ?? Self.defaultAppItems
    }
    
    // MARK: - Default Data
    
    private static let defaultAppItems: [AppItem] = [
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
        ),
        AppItem(
            title: "App Store",
            description: "Application marketplace",
            iconName: "square.stack.fill",
            additionalInfo: "Limited access to App Store. Only approved apps can be downloaded and installed."
        ),
        AppItem(
            title: "Books",
            description: "Digital reading platform",
            iconName: "book.fill",
            additionalInfo: "Access to age-appropriate books and educational content. Restricted from mature publications."
        ),
        AppItem(
            title: "Photos",
            description: "Photo and video library",
            iconName: "photo.fill",
            additionalInfo: "Full access to photo library. Can view, organize, and edit photos taken on device."
        )
    ]
    
    // MARK: - Actions
    
    /// Increase access level for a specific app
    /// - Parameter item: The app to modify access for
    /// - Note: Future implementation will update access levels and persist changes
    func increaseAccess(for item: AppItem) {
        // TODO: Implement access level logic
        // - Update app's access level
        // - Persist changes
        // - Notify user of change
        print("Increasing access for: \(item.title)")
    }
    
    /// Decrease access level for a specific app
    /// - Parameter item: The app to modify access for
    /// - Note: Future implementation will update access levels and persist changes
    func decreaseAccess(for item: AppItem) {
        // TODO: Implement access level logic
        // - Update app's access level
        // - Persist changes
        // - Notify user of change
        print("Decreasing access for: \(item.title)")
    }
    
    // MARK: - Future Features
    
    // TODO: Add time limit functionality
    // func setTimeLimit(for item: AppItem, minutes: Int)
    
    // TODO: Add schedule functionality
    // func setSchedule(for item: AppItem, schedule: AppSchedule)
    
    // TODO: Add persistence
    // func saveChanges() async throws
    // func loadSavedState() async throws
}

// MARK: - Future Data Structures
/*
 Potential future additions:
 
 enum AccessLevel: Int, Codable {
     case blocked = 0
     case restricted = 1
     case allowed = 2
     case unrestricted = 3
 }
 
 struct AppSchedule: Codable {
     var allowedDays: Set<Weekday>
     var startTime: Date
     var endTime: Date
     var dailyTimeLimit: TimeInterval?
 }
 
 struct TimeLimit: Codable {
     var dailyMinutes: Int
     var weeklyMinutes: Int
     var warningThreshold: Int
 }
 */

