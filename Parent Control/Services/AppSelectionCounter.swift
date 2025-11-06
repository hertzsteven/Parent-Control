//
//  AppSelectionCounter.swift
//  Parent Control
//
//  Manages per-device app selection counters
//

import Foundation

/// Manages app selection counters per device
final class AppSelectionCounter: ObservableObject {
    static let shared = AppSelectionCounter()
    
    private let userDefaults = UserDefaults.standard
    private let countsKey = "appSelectionCountsByDevice"
    
    /// Dictionary mapping device UDID to dictionary of app ID → count
    @Published private(set) var countsByDevice: [String: [UUID: Int]] = [:]
    
    private init() {
        loadCounts()
    }
    
    // MARK: - Public Methods
    
    /// Increment the selection count for an app on a specific device
    func incrementCount(for appId: UUID, deviceUDID: String) {
        var deviceCounts = countsByDevice[deviceUDID] ?? [:]
        let currentCount = deviceCounts[appId] ?? 0
        deviceCounts[appId] = currentCount + 1
        countsByDevice[deviceUDID] = deviceCounts
        saveCounts()
    }
    
    /// Get the selection count for an app on a specific device
    func getCount(for appId: UUID, deviceUDID: String) -> Int {
        return countsByDevice[deviceUDID]?[appId] ?? 0
    }
    
    /// Reset all counters for a specific device
    func resetCounts(for deviceUDID: String) {
        countsByDevice.removeValue(forKey: deviceUDID)
        saveCounts()
    }
    
    /// Get all counts for a specific device
    func getAllCounts(for deviceUDID: String) -> [UUID: Int] {
        return countsByDevice[deviceUDID] ?? [:]
    }
    
    /// Get total selection count across all devices
    func getTotalSelections() -> Int {
        return countsByDevice.values.reduce(0) { total, deviceCounts in
            total + deviceCounts.values.reduce(0, +)
        }
    }
    
    /// Get total selection count for a specific device
    func getTotalSelections(for deviceUDID: String) -> Int {
        let deviceCounts = countsByDevice[deviceUDID] ?? [:]
        return deviceCounts.values.reduce(0, +)
    }
    
    // MARK: - Persistence
    
    private func loadCounts() {
        guard let data = userDefaults.data(forKey: countsKey) else {
            print("📦 No app selection counts found - starting fresh")
            countsByDevice = [:]
            return
        }
        
        do {
            let decoder = JSONDecoder()
            // Decode as [String: [String: Int]] then convert to [String: [UUID: Int]]
            let stringDict = try decoder.decode([String: [String: Int]].self, from: data)
            countsByDevice = stringDict.mapValues { uuidDict in
                uuidDict.compactMapKeys { UUID(uuidString: $0) }
            }
            
            let totalSelections = getTotalSelections()
            print("✅ Loaded app selection counts: \(countsByDevice.count) device(s), \(totalSelections) total selection(s)")
            
            #if DEBUG
            for (udid, deviceCounts) in countsByDevice {
                let deviceTotal = deviceCounts.values.reduce(0, +)
                print("   Device \(udid.prefix(8))...: \(deviceCounts.count) apps, \(deviceTotal) selections")
            }
            #endif
        } catch {
            print("❌ Failed to load app selection counts: \(error)")
            countsByDevice = [:]
        }
    }
    
    private func saveCounts() {
        do {
            let encoder = JSONEncoder()
            // Convert [String: [UUID: Int]] to [String: [String: Int]] for encoding
            let stringDict = countsByDevice.mapValues { uuidDict in
                uuidDict.mapKeys { $0.uuidString }
            }
            let data = try encoder.encode(stringDict)
            userDefaults.set(data, forKey: countsKey)
            
            let totalSelections = getTotalSelections()
            print("💾 Saved app selection counts: \(countsByDevice.count) device(s), \(totalSelections) total selection(s)")
            
            #if DEBUG
            for (udid, deviceCounts) in countsByDevice {
                let deviceTotal = deviceCounts.values.reduce(0, +)
                print("   Device \(udid.prefix(8))...: \(deviceCounts.count) apps, \(deviceTotal) selections")
            }
            #endif
        } catch {
            print("❌ Failed to save app selection counts: \(error)")
        }
    }
}

// MARK: - Dictionary Extension for UUID Key Mapping

extension Dictionary {
    func compactMapKeys<T>(_ transform: (Key) throws -> T?) rethrows -> [T: Value] {
        return try self.reduce(into: [T: Value]()) { result, element in
            if let key = try transform(element.key) {
                result[key] = element.value
            }
        }
    }
    
    func mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T: Value] {
        return try self.reduce(into: [T: Value]()) { result, element in
            result[try transform(element.key)] = element.value
        }
    }
}

