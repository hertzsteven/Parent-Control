//
//  DeviceAppPreferences.swift
//  Parent Control
//
//  Manages per-device app visibility preferences
//

import Foundation

/// Manages which apps should be hidden from the device app list
final class DeviceAppPreferences: ObservableObject {
    static let shared = DeviceAppPreferences()
    
    private let userDefaults = UserDefaults.standard
    private let hiddenAppsKey = "hiddenAppsByDevice"
    
    /// Dictionary mapping device UDID to set of hidden app IDs
    @Published private(set) var hiddenAppsByDevice: [String: Set<UUID>] = [:]
    
    private init() {
        loadPreferences()
    }
    
    // MARK: - Public Methods
    
    /// Get hidden app IDs for a specific device
    func hiddenApps(for deviceUDID: String) -> Set<UUID> {
        return hiddenAppsByDevice[deviceUDID] ?? []
    }
    
    /// Check if an app is hidden for a specific device
    func isAppHidden(_ appId: UUID, for deviceUDID: String) -> Bool {
        return hiddenAppsByDevice[deviceUDID]?.contains(appId) ?? false
    }
    
    /// Hide an app for a specific device
    func hideApp(_ appId: UUID, for deviceUDID: String) {
        var hiddenApps = hiddenAppsByDevice[deviceUDID] ?? []
        hiddenApps.insert(appId)
        hiddenAppsByDevice[deviceUDID] = hiddenApps
        savePreferences()
    }
    
    /// Show an app for a specific device (remove from hidden list)
    func showApp(_ appId: UUID, for deviceUDID: String) {
        guard var hiddenApps = hiddenAppsByDevice[deviceUDID] else { return }
        hiddenApps.remove(appId)
        if hiddenApps.isEmpty {
            hiddenAppsByDevice.removeValue(forKey: deviceUDID)
        } else {
            hiddenAppsByDevice[deviceUDID] = hiddenApps
        }
        savePreferences()
    }
    
    /// Toggle app visibility for a specific device
    func toggleAppVisibility(_ appId: UUID, for deviceUDID: String) {
        if isAppHidden(appId, for: deviceUDID) {
            showApp(appId, for: deviceUDID)
        } else {
            hideApp(appId, for: deviceUDID)
        }
    }
    
    /// Clear all hidden apps for a specific device
    func clearHiddenApps(for deviceUDID: String) {
        hiddenAppsByDevice.removeValue(forKey: deviceUDID)
        savePreferences()
    }
    
    /// Clean up orphaned hidden app IDs that no longer match any current apps
    /// - Parameters:
    ///   - deviceUDID: The device UDID to clean up
    ///   - validAppIds: Set of valid app IDs currently on the device
    func cleanupOrphanedPreferences(for deviceUDID: String, validAppIds: Set<UUID>) {
        guard var hiddenApps = hiddenAppsByDevice[deviceUDID], !hiddenApps.isEmpty else { return }
        
        let orphanedApps = hiddenApps.subtracting(validAppIds)
        
        if !orphanedApps.isEmpty {
            print("🧹 Cleaning up \(orphanedApps.count) orphaned hidden app IDs for device \(deviceUDID.prefix(8))...")
            hiddenApps = hiddenApps.intersection(validAppIds)
            
            if hiddenApps.isEmpty {
                hiddenAppsByDevice.removeValue(forKey: deviceUDID)
            } else {
                hiddenAppsByDevice[deviceUDID] = hiddenApps
            }
            
            savePreferences()
        }
    }
    
    // MARK: - Persistence
    
    private func loadPreferences() {
        guard let data = userDefaults.data(forKey: hiddenAppsKey) else {
            print("📦 No hidden app preferences found - starting fresh")
            hiddenAppsByDevice = [:]
            return
        }
        
        do {
            let decoder = JSONDecoder()
            // Decode as [String: [String]] then convert to [String: Set<UUID>]
            let stringDict = try decoder.decode([String: [String]].self, from: data)
            hiddenAppsByDevice = stringDict.mapValues { uuidStrings in
                Set(uuidStrings.compactMap { UUID(uuidString: $0) })
            }
            
            let totalHidden = hiddenAppsByDevice.values.reduce(0) { $0 + $1.count }
            print("✅ Loaded hidden app preferences: \(hiddenAppsByDevice.count) device(s), \(totalHidden) hidden app(s)")
            
            #if DEBUG
            for (udid, hiddenApps) in hiddenAppsByDevice {
                print("   Device \(udid.prefix(8))...: \(hiddenApps.count) hidden apps")
                for appId in hiddenApps {
                    print("      - \(appId.uuidString.prefix(8))...")
                }
            }
            #endif
        } catch {
            print("❌ Failed to load hidden apps preferences: \(error)")
            hiddenAppsByDevice = [:]
        }
    }
    
    private func savePreferences() {
        do {
            let encoder = JSONEncoder()
            // Convert [String: Set<UUID>] to [String: [String]] for encoding
            let stringDict = hiddenAppsByDevice.mapValues { uuidSet in
                uuidSet.map { $0.uuidString }
            }
            let data = try encoder.encode(stringDict)
            userDefaults.set(data, forKey: hiddenAppsKey)
            
            let totalHidden = hiddenAppsByDevice.values.reduce(0) { $0 + $1.count }
            print("💾 Saved hidden app preferences: \(hiddenAppsByDevice.count) device(s), \(totalHidden) hidden app(s)")
            
            #if DEBUG
            for (udid, hiddenApps) in hiddenAppsByDevice {
                print("   Device \(udid.prefix(8))...: \(hiddenApps.count) hidden apps")
            }
            #endif
        } catch {
            print("❌ Failed to save hidden apps preferences: \(error)")
        }
    }
}

