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
    
    /// List of all available apps
    var appItems: [AppItem]
    
    /// List of available devices
    var devices: [Device]
    
    /// Currently selected device (if any)
    var selectedDevice: Device?
    
    /// Currently selected app item (if any)
    var selectedItem: AppItem?
    
    /// Loading state for network requests
    var isLoading: Bool = false
    
    /// Error message from last failed operation
    var errorMessage: String?
    
    /// Network service for API calls
    private let networkService: NetworkService
    
    // MARK: - Initialization
    
    init(
        childData: ChildData? = nil,
        appItems: [AppItem]? = nil,
        devices: [Device]? = nil,
        networkService: NetworkService = NetworkService()
    ) {
        self.networkService = networkService
        // Store app items in local variable first
        let initialAppItems = appItems ?? Self.defaultAppItems
        
        // Initialize child data
        self.childData = childData ?? ChildData(
            childImage: "person.crop.circle.fill",
            name: "David Grossman",
            deviceInfo: "iPad (A16) Wi-Fi"
        )
        
        // Initialize app items
        self.appItems = initialAppItems
        
        // Initialize devices with app associations
        self.devices = devices ?? Self.createDefaultDevices(appItems: initialAppItems)
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
    
    /// Create default devices with app associations
    private static func createDefaultDevices(appItems: [AppItem]) -> [Device] {
        // Get specific app IDs
        let youtubeId = appItems.first { $0.title == "YouTube" }?.id
        let safariId = appItems.first { $0.title == "Safari" }?.id
        let musicId = appItems.first { $0.title == "Music" }?.id
        let appStoreId = appItems.first { $0.title == "App Store" }?.id
        let booksId = appItems.first { $0.title == "Books" }?.id
        let photosId = appItems.first { $0.title == "Photos" }?.id
        
        return [
            Device(
                name: "Living Room iPad",
                iconName: "ipad.gen1",
                ringColor: "blue",
                appIds: [youtubeId, safariId, musicId].compactMap { $0 }
            ),
            Device(
                name: "Bedroom iPad",
                iconName: "ipad.gen2",
                ringColor: "green",
                appIds: [youtubeId, booksId, photosId, musicId].compactMap { $0 }
            ),
            Device(
                name: "Kids Room iPad",
                iconName: "ipad.landscape",
                ringColor: "purple",
                appIds: [youtubeId, appStoreId, booksId, photosId].compactMap { $0 }
            ),
            Device(
                name: "Study iPad",
                iconName: "ipad",
                ringColor: "orange",
                appIds: [safariId, booksId, photosId].compactMap { $0 }
            )
        ]
    }
    
    // MARK: - Computed Properties
    
    /// Get apps filtered by selected device
    func appsForDevice(_ device: Device) -> [AppItem] {
        appItems.filter { app in
            device.appIds.contains(app.id)
        }
    }
    
    // MARK: - Actions
    
    /// Select a device and update filtered apps
    func selectDevice(_ device: Device) {
        selectedDevice = device
    }
    
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
    
    // MARK: - Network Operations
    
    /// Load data from Zuludesk API
    /// Fetches apps and devices, then updates the view model state
    /// Falls back to default data if network request fails
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch apps from API
            let appDTOs = try await networkService.fetchApps()
            
            // Convert to domain models and get mapping
            let (fetchedApps, appMapping) = appDTOs.toAppItems()
            
            // Fetch devices from API
            let deviceDTOs = try await networkService.fetchDevices()
            
            // Convert to domain models using app mapping
            let fetchedDevices = deviceDTOs.toDevices(appMapping: appMapping)
            
            // Update observable properties
            self.appItems = fetchedApps
            self.devices = fetchedDevices
            
            // Clear any previous errors
            self.errorMessage = nil
            
            print("✅ Successfully loaded \(fetchedApps.count) apps and \(fetchedDevices.count) devices from API")
            
        } catch let error as NetworkError {
            // Handle network errors and fall back to default data
            self.errorMessage = error.localizedDescription
            print("⚠️ Network error: \(error.localizedDescription). Using default data.")
            loadDefaultData()
            
        } catch {
            // Handle unexpected errors
            self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            print("⚠️ Unexpected error: \(error.localizedDescription). Using default data.")
            loadDefaultData()
        }
        
        isLoading = false
    }
    
    /// Load data from API without blocking UI
    /// Convenience method for calling from SwiftUI views
    func loadDataInBackground() {
        Task {
            await loadData()
        }
    }
    
    /// Load default mock data
    /// Used as fallback when network requests fail
    private func loadDefaultData() {
        self.appItems = Self.defaultAppItems
        self.devices = Self.createDefaultDevices(appItems: Self.defaultAppItems)
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

