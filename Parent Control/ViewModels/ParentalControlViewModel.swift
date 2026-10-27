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
    
    /// Flag to track if data has been loaded from API
    var hasLoadedData: Bool = false
    
    /// Network service for API calls
    private let networkService: NetworkService
    
    /// API configuration for accessing tokens and settings
    private let configuration: APIConfiguration
    
    /// Raw device DTOs with app info (for debugging/display)
    var deviceDTOs: [DeviceDTO] = []
    
    /// Authentication manager for accessing current token
    var authManager: AuthenticationManager?
    
    /// Device app preferences for managing hidden apps
    let appPreferences: DeviceAppPreferences

    /// Single-app locks keyed by owner id. Drives the named unlock button.
    var singleAppLocksByOwnerId: [String: SingleAppLock] = [:]

    private var singleAppLockStore = SingleAppLockStore()
    
    // MARK: - Initialization
    
    init(
        childData: ChildData? = nil,
        appItems: [AppItem]? = nil,
        devices: [Device]? = nil,
        networkService: NetworkService = NetworkService(),
        configuration: APIConfiguration = .default,
        authManager: AuthenticationManager? = nil,
        appPreferences: DeviceAppPreferences = .shared
    ) {
        self.networkService = networkService
        self.configuration = configuration
        self.authManager = authManager
        self.appPreferences = appPreferences
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
        
        // Initialize devices as empty - will be populated from API
        self.devices = devices ?? []
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
                udid: "00008120-0000000000000001",
                name: "Living Room iPad",
                iconName: "ipad.gen1",
                ringColor: "blue",
                appIds: [youtubeId, safariId, musicId].compactMap { $0 },
                ownerId: "143"
            ),
            Device(
                udid: "00008120-0000000000000002",
                name: "Bedroom iPad",
                iconName: "ipad.gen2",
                ringColor: "green",
                appIds: [youtubeId, booksId, photosId, musicId].compactMap { $0 },
                ownerId: "143"
            ),
            Device(
                udid: "00008120-0000000000000003",
                name: "Kids Room iPad",
                iconName: "ipad.landscape",
                ringColor: "purple",
                appIds: [youtubeId, appStoreId, booksId, photosId].compactMap { $0 },
                ownerId: "143"
            ),
            Device(
                udid: "00008120-0000000000000004",
                name: "Study iPad",
                iconName: "ipad",
                ringColor: "orange",
                appIds: [safariId, booksId, photosId].compactMap { $0 },
                ownerId: "143"
            )
        ]
    }
    
    // MARK: - Computed Properties
    
    /// Get apps filtered by selected device, excluding hidden apps
    func appsForDevice(_ device: Device) -> [AppItem] {
        let hiddenApps = appPreferences.hiddenApps(for: device.udid)
        return appItems.filter { app in
            device.appIds.contains(app.id) && !hiddenApps.contains(app.id)
        }
    }
    
    /// Get ALL apps for a device (including hidden ones) - used in settings
    func allAppsForDevice(_ device: Device) -> [AppItem] {
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
    
    /// Lock device to a specific app (two-step process)
    /// - Parameters:
    ///   - device: The device to lock
    ///   - app: The app to lock the device to
    /// - Returns: Result with success message or error
    func lockDeviceToApp(device: Device, app: AppItem) async -> Result<String, Error> {
        print("\n" + String(repeating: "=", count: 80))
        print("🔒 LOCKING DEVICE TO APP")
        print(String(repeating: "=", count: 80))
        
        // Validate bundle ID
        guard let bundleId = app.bundleId else {
            let errorMessage = "App \(app.title) has no bundle ID"
            print("❌ Error: \(errorMessage)")
            print(String(repeating: "=", count: 80) + "\n")
            return .failure(NSError(domain: "ParentalControl", code: -1, 
                                  userInfo: [NSLocalizedDescriptionKey: errorMessage]))
        }
        
        // STRICT REQUIREMENT: Must have owner, no fallback
        guard let userId = device.ownerId else {
            let errorMessage = "Device \(device.name) has no owner assigned"
            print("❌ Error: \(errorMessage)")
            print(String(repeating: "=", count: 80) + "\n")
            return .failure(NSError(domain: "ParentalControl", code: -2,
                                  userInfo: [NSLocalizedDescriptionKey: errorMessage]))
        }
        
        let clearAfter = 86400 // seconds
        
        do {
            // Get token from AuthenticationManager
            guard let token = authManager?.token else {
                let errorMessage = "No authentication token available. Please log in."
                print("❌ Error: \(errorMessage)")
                print(String(repeating: "=", count: 80) + "\n")
                return .failure(NSError(domain: "ParentalControl", code: -3,
                                      userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            }
            
            // STEP 1: Unlock Device (clear any existing app lock)
            print("\n📍 STEP 1: Unlocking Device")
            print(String(repeating: "-", count: 80))
            print("🔓 Clearing any existing app locks...")
            print("👤 Student ID: \(userId)")
            print("🔑 Token: \(token)")
            
            let unlockResponse = try await networkService.stopAppLock(
                studentId: userId,
                token: token
            )
            
            print("✅ Device Unlocked Successfully!")
            if let tasks = unlockResponse.tasks, !tasks.isEmpty {
                print("📄 Removed \(tasks.count) existing lock(s)")
            }
            if unlockResponse.success != false {
                recordLessonsStopped(ownerId: userId)
            }
            
            // STEP 2: Apply App Lock
            print("\n📍 STEP 2: Applying App Lock")
            print(String(repeating: "-", count: 80))
            print("📱 Bundle ID: \(bundleId)")
            print("⏱️ Clear After: \(clearAfter) seconds")
            print("👨‍🎓 Student IDs: \(userId)")
            print("🔑 Token: \(token)")
            
            let lockResponse = try await networkService.applyAppLock(
                bundleId: bundleId,
                clearAfterSeconds: clearAfter,
                studentIds: [userId],
                token: token
            )
            
            print("\n✅ App Lock Applied Successfully!")
            if let message = lockResponse.message {
                print("📄 Response: \(message)")
            }
            if lockResponse.success != false {
                recordAppLockApplied(ownerId: userId, bundleId: bundleId, appName: app.title)
            }
            print(String(repeating: "=", count: 80) + "\n")
            
            let successMessage = "In a few seconds, the device will be locked to \(app.title)."
            return .success(successMessage)
            
        } catch let error as NetworkError {
            print("\n❌ Process Failed!")
            print("⚠️ Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            return .failure(error)
            
        } catch {
            print("\n❌ Process Failed!")
            print("⚠️ Unknown Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            return .failure(error)
        }
    }
    
    /// Unlock device by stopping any active app locks
    /// - Parameter device: The device to unlock
    /// - Returns: Result with success message or error
    func unlockDevice(device: Device) async -> Result<String, Error> {
        print("\n" + String(repeating: "=", count: 80))
        print("🔓 UNLOCKING DEVICE")
        print(String(repeating: "=", count: 80))
        
        // STRICT REQUIREMENT: Must have owner, no fallback
        guard let userId = device.ownerId else {
            let errorMessage = "Device \(device.name) has no owner assigned"
            print("❌ Error: \(errorMessage)")
            print(String(repeating: "=", count: 80) + "\n")
            return .failure(NSError(domain: "ParentalControl", code: -2,
                                  userInfo: [NSLocalizedDescriptionKey: errorMessage]))
        }
        
        // Get token from AuthenticationManager
        guard let token = authManager?.token else {
            let errorMessage = "No authentication token available. Please log in."
            print("❌ Error: \(errorMessage)")
            print(String(repeating: "=", count: 80) + "\n")
            return .failure(NSError(domain: "ParentalControl", code: -3,
                                  userInfo: [NSLocalizedDescriptionKey: errorMessage]))
        }
        
        do {
            print("\n📍 Removing App Locks")
            print(String(repeating: "-", count: 80))
            print("🔧 Device: \(device.name)")
            print("👤 Student ID: \(userId)")
            print("🔑 Token: \(token)")
            
            let unlockResponse = try await networkService.stopAppLock(
                studentId: userId,
                token: token
            )
            
            print("\n✅ Device Unlocked Successfully!")
            if let tasks = unlockResponse.tasks, !tasks.isEmpty {
                print("📄 Removed \(tasks.count) app lock(s)")
                for task in tasks {
                    print("   - Student: \(task.student), Status: \(task.status)")
                }
            } else {
                print("📄 No active locks found (device was already unlocked)")
            }
            print(String(repeating: "=", count: 80) + "\n")

            if unlockResponse.success != false {
                recordLessonsStopped(ownerId: userId)
            }
            
            let successMessage = "\(device.name)  unlocked"
            return .success(successMessage)
            
        } catch let error as NetworkError {
            print("\n❌ Unlock Failed!")
            print("⚠️ Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            return .failure(error)
            
        } catch {
            print("\n❌ Unlock Failed!")
            print("⚠️ Unknown Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            return .failure(error)
        }
    }
    
    // MARK: - Single-app lock

    /// The app this device's owner is locked to, when that lock is exactly one app.
    func singleAppLock(for device: Device) -> SingleAppLock? {
        guard let ownerId = device.ownerId else { return nil }
        return singleAppLocksByOwnerId[ownerId]
    }

    /// One sanity read of GET /teacher/profiles when the teacher screen opens.
    /// Lock and unlock results update `singleAppLocksByOwnerId` themselves.
    func loadSingleAppLock(for device: Device) async {
        guard let ownerId = device.ownerId else { return }
        guard let token = authManager?.token, !token.isEmpty else { return }

        let generation = beginProfileFetch(ownerId: ownerId)
        do {
            let profiles = try await networkService.fetchTeacherProfiles(scopeId: ownerId, token: token)
            let bundleIds = TeacherStudentProfile.bundleIds(forOwnerId: ownerId, in: profiles)
            let apps = appsForDevice(device) + appItems
            let applied = singleAppLockStore.replaceFromProfile(
                ownerId: ownerId,
                bundleIds: bundleIds,
                generation: generation
            ) { bundleId in
                AppNameMatcher.name(forBundleId: bundleId, apps: apps)
            }
            if applied {
                publishSingleAppLocks()
            }
        } catch {
            print("Single-app lock check failed: \(error.localizedDescription)")
        }
    }

    private func beginProfileFetch(ownerId: String) -> Int {
        singleAppLockStore.beginProfileFetch(ownerId: ownerId)
    }

    private func recordAppLockApplied(ownerId: String, bundleId: String, appName: String) {
        singleAppLockStore.noteAppLockApplied(ownerId: ownerId, bundleId: bundleId, appName: appName)
        publishSingleAppLocks()
    }

    private func recordLessonsStopped(ownerId: String) {
        singleAppLockStore.noteLessonsStopped(ownerId: ownerId)
        publishSingleAppLocks()
    }

    private func publishSingleAppLocks() {
        singleAppLocksByOwnerId = singleAppLockStore.locksByOwnerId
    }

    // MARK: - Network Operations
    
    /// Load data from Zuludesk API
    /// Fetches apps and devices, then updates the view model state
    /// Falls back to default data if network request fails
    func loadData() async {
        // Skip if data already loaded
        if hasLoadedData && !devices.isEmpty {
            print("📦 Using cached data - skipping API reload")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("\n🚀 Starting API data load...")
        
        // Wait for network connectivity before making API calls
        // This is critical for Single App Mode where app launches before network is ready
        let reachability = NetworkReachabilityService.shared
        let hasNetwork = await reachability.waitForConnectivity(timeout: 30, retryInterval: 2)
        
        guard hasNetwork else {
            print("⚠️ No network available - cannot load data from API")
            errorMessage = "No internet connection. Please check your network and try again."
            isLoading = false
            return
        }
        
        print("🌐 Network available - proceeding with API calls...")
        
        do {
            // Get token from AuthenticationManager
            guard let token = authManager?.token else {
                throw NSError(domain: "ParentalControl", code: -3,
                              userInfo: [NSLocalizedDescriptionKey: "No authentication token available. Please log in."])
            }
            
            // STEP 1: Fetch teacher groups to determine which class to use
            print("\n👥 Fetching teacher groups...")
            let groupsResponse = try await networkService.fetchTeacherGroups(token: token)
            print("✅ Fetched \(groupsResponse.results.count) teacher group(s)")
            
            // STEP 2: Fetch all classes
            print("\n📚 Fetching classes list...")
            let classesResponse = try await networkService.fetchClasses()
            print("✅ Fetched \(classesResponse.classes.count) class(es)")
            
            // STEP 3: Match teacher group with class by ID
            print("\n🔗 Matching teacher group with class...")
            guard let teacherGroup = groupsResponse.results.first else {
                throw NSError(domain: "ParentalControl", code: -3, 
                              userInfo: [NSLocalizedDescriptionKey: "No teacher groups found"])
            }
            
            guard let matchedClass = classesResponse.classes.first(where: { $0.userGroupId == teacherGroup.id }) else {
                throw NSError(domain: "ParentalControl", code: -4,
                              userInfo: [NSLocalizedDescriptionKey: "No class found matching teacher group ID \(teacherGroup.id)"])
            }
            
            print("✅ Matched class: \(matchedClass.name) (UUID: \(matchedClass.uuid))")
            print("   Teacher Group: \(teacherGroup.name) (ID: \(teacherGroup.id))")
            print("\n" + String(repeating: "━", count: 80))
            print("🎯 USING CLASS UUID: \(matchedClass.uuid)")
            print(String(repeating: "━", count: 80))
            
            // STEP 4: Fetch detailed class information using the matched UUID
            print("\n🏫 Fetching class details for: \(matchedClass.name)...")
            let classResponse = try await networkService.fetchClass(classId: matchedClass.uuid)
            let classDetails = classResponse.classDetails
            
            // Extract student IDs from class
            let studentIds: Set<String> = Set(classDetails.students.map { String($0.id) })
            
            print("✅ Class fetched successfully: \"\(classDetails.name)\"")
            print("   📊 Student count: \(classDetails.studentCount)")
            print("   👥 Students in class:")
            for student in classDetails.students {
                print("      - ID: \(student.id) | Name: \(student.name)")
            }
            print("   🔑 Student IDs for filtering: \(studentIds.sorted())")
            
            // Fetch devices from API (with apps included)
            print("\n📱 Fetching devices with installed apps...")
            let deviceDTOs = try await networkService.fetchDevices(includeApps: true)
            
            // Store deviceDTOs for UI access
            self.deviceDTOs = deviceDTOs
            
            // Extract apps directly from device-installed apps (no catalog needed)
            print("\n📲 Extracting apps from device data...")
            let (fetchedApps, bundleIdMapping) = deviceDTOs.extractAllApps()
            print("✅ Apps extracted: \(fetchedApps.count) unique apps")
            
            // Print device apps for debugging
            print("\n📋 DEVICE APPS BREAKDOWN:")
            print(String(repeating: "━", count: 60))
            for deviceDTO in deviceDTOs {
                print("\n🔷 \(deviceDTO.name) (\(deviceDTO.udid.prefix(8))...)")
                if let apps = deviceDTO.apps, !apps.isEmpty {
                    print("   Apps installed: \(apps.count)")
                    print("")
                    for app in apps.prefix(5) {  // Show first 5 apps
                        let bundleId = app.identifier ?? "no bundle ID"
                        let vendor = app.vendor ?? "unknown vendor"
                        print("   • \(app.name ?? "Unknown")")
                        print("     Bundle ID: \(bundleId)")
                        print("     Vendor: \(vendor) | Version: \(app.version ?? "N/A")")
                    }
                    if apps.count > 5 {
                        print("\n   ... and \(apps.count - 5) more apps")
                    }
                } else {
                    print("   ⚠️ No apps reported")
                }
            }
            print(String(repeating: "━", count: 60))
            
            // Convert to domain models using bundleId mapping
            let allDevices = deviceDTOs.toDevices(bundleIdMapping: bundleIdMapping)
            print("\n✅ All devices fetched: \(allDevices.count)")
            
            // Filter devices to only show those owned by students in the class
            let fetchedDevices = allDevices.filter { device in
                if let ownerId = device.ownerId {
                    return studentIds.contains(ownerId)
                }
                return false  // Exclude devices with no owner
            }
            
            print("\n🔍 DEVICE FILTERING:")
            print("   📊 Total devices from API: \(allDevices.count)")
            print("   ✅ Devices matching class students: \(fetchedDevices.count)")
            print("   ❌ Devices filtered out: \(allDevices.count - fetchedDevices.count)")
            print("\n   📱 Devices shown for class \"\(classDetails.name)\":")
            for device in fetchedDevices {
                print("      - \(device.name) (Owner ID: \(device.ownerId ?? "none"))")
            }
            
            // Print device-app associations
            print("\n🔗 DEVICE-APP ASSOCIATIONS:")
            print(String(repeating: "━", count: 60))
            for device in fetchedDevices {
                print("\n📱 \(device.name): \(device.appIds.count) apps mapped")
            }
            print(String(repeating: "━", count: 60))
            
            // Debug: Print sample app with icon
            let appsWithIcons = fetchedApps.filter { $0.iconURL != nil }.count
            print("\n🎨 Apps with icon URLs: \(appsWithIcons)/\(fetchedApps.count)")
            if let sampleApp = fetchedApps.first(where: { $0.iconURL != nil }) {
                print("   Sample: \(sampleApp.title) - \(sampleApp.iconURL ?? "none")")
            }
            
            // Update observable properties
            self.appItems = fetchedApps
            self.devices = fetchedDevices
            
            // Clear any previous errors
            self.errorMessage = nil
            
            // Set flag to prevent reloading
            hasLoadedData = true
            
            print("\n✅ Successfully loaded \(fetchedApps.count) apps and \(fetchedDevices.count) devices from API\n")
            
        } catch let error as NetworkError {
            // Handle network errors and fall back to default data
            print("\n❌ Network error occurred: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            print("⚠️ Falling back to default data.\n")
            loadDefaultData()
            
        } catch {
            // Handle unexpected errors
            print("\n❌ Unexpected error: \(error)")
            self.errorMessage = "Failed to decode response: \(error.localizedDescription)"
            print("⚠️ Falling back to default data.\n")
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
    
    /// Refresh data from API (forces reload)
    func refreshData() async {
        hasLoadedData = false
        await loadData()
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

