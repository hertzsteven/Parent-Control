//
//  ModelMappers.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/29/25.
//

import Foundation

// MARK: - App Mapping

extension AppDTO {
    /// Convert API DTO to app domain model
    /// - Returns: AppItem for use in the app
    func toAppItem() -> AppItem {
        // Generate deterministic UUID from bundleId so it's consistent across app launches
        let deterministicId = bundleId.deterministicUUID
        
        #if DEBUG
        print("🔑 App '\(name)' -> UUID: \(deterministicId.uuidString.prefix(8))... (from bundleId: \(bundleId))")
        #endif
        
        return AppItem(
            id: deterministicId,
            title: name,
            description: "\(vendor) - \(platform)",
            iconName: mapToIconName(),
            bundleId: bundleId,
            additionalInfo: buildAdditionalInfo()
        )
    }
    
    /// Map app name/bundle ID to SF Symbol icon name
    private func mapToIconName() -> String {
        // Map common apps to SF Symbols
        let bundleLower = bundleId.lowercased()
        let nameLower = name.lowercased()
        
        switch true {
        case bundleLower.contains("youtube") || nameLower.contains("youtube"):
            return "play.rectangle.fill"
        case bundleLower.contains("safari") || nameLower.contains("safari"):
            return "safari"
        case bundleLower.contains("music") || nameLower.contains("music"):
            return "music.note"
        case bundleLower.contains("appstore") || bundleLower.contains("app.store"):
            return "square.stack.fill"
        case bundleLower.contains("books") || nameLower.contains("books"):
            return "book.fill"
        case bundleLower.contains("photos") || nameLower.contains("photos"):
            return "photo.fill"
        case bundleLower.contains("mail") || nameLower.contains("mail"):
            return "envelope.fill"
        case bundleLower.contains("messages") || nameLower.contains("messages"):
            return "message.fill"
        case bundleLower.contains("facetime") || nameLower.contains("facetime"):
            return "video.fill"
        case bundleLower.contains("calendar") || nameLower.contains("calendar"):
            return "calendar"
        case bundleLower.contains("notes") || nameLower.contains("notes"):
            return "note.text"
        case bundleLower.contains("maps") || nameLower.contains("maps"):
            return "map.fill"
        case bundleLower.contains("pages"):
            return "doc.text.fill"
        case bundleLower.contains("numbers"):
            return "tablecells.fill"
        case bundleLower.contains("keynote"):
            return "keynote"
        case bundleLower.contains("classroom") || nameLower.contains("classroom"):
            return "person.3.fill"
        case bundleLower.contains("student") || nameLower.contains("student"):
            return "graduationcap.fill"
        case bundleLower.contains("game") || nameLower.contains("game"):
            return "gamecontroller.fill"
        case platform.lowercased() == "tvos":
            return "tv.fill"
        default:
            return "app.fill"
        }
    }
    
    /// Build additional info string from API data
    private func buildAdditionalInfo() -> String {
        var info = "Bundle ID: \(bundleId)"
        
        if let adamId = adamId {
            info += "\nApp Store ID: \(adamId)"
        } else {
            info += "\nType: Enterprise App"
        }
        
        info += "\nVendor: \(vendor)"
        info += "\nPlatform: \(platform)"
        
        return info
    }
}

// MARK: - Device Mapping

extension DeviceDTO {
    /// Convert API DTO to device domain model
    /// - Parameter bundleIdMapping: Dictionary mapping app bundleIds to AppItem UUIDs
    /// - Returns: Device for use in the app
    func toDevice(bundleIdMapping: [String: UUID]) -> Device {
        // Map device apps by bundleId to AppItem UUIDs
        // Use a Set to automatically deduplicate, then convert back to Array
        let mappedAppIdsSet: Set<UUID> = Set(apps?.compactMap { deviceApp in
            guard let bundleId = deviceApp.identifier else { return nil }
            return bundleIdMapping[bundleId]
        } ?? [])
        let mappedAppIds = Array(mappedAppIdsSet)
        
        // Extract owner ID and convert to String (will be nil if not assigned)
        let ownerIdString = owner?.id.map { String($0) }
        
        // Format model name for display
        let formattedModelName = formatModelName()
        
        // Normalize battery level: API might return 0-1 or 0-100
        let normalizedBatteryLevel: Double? = {
            guard let level = batteryLevel else { return nil }
            // If battery level is > 1.0, assume it's in percentage format (0-100)
            // Convert to decimal format (0.0-1.0)
            let percentage = Int(level > 1.0 ? level : level * 100)
            if level > 1.0 {
                print("⚡️ \(name): \(level)% → \(level/100) (converted from percentage)")
                return level / 100.0
            } else {
                print("⚡️ \(name): \(percentage)% (battery level: \(level))")
                return level
            }
        }()
        
        return Device(
            udid: udid,
            name: name,
            iconName: mapToIconName(),
            ringColor: mapToRingColor(),
            appIds: mappedAppIds,
            ownerId: ownerIdString,
            batteryLevel: normalizedBatteryLevel,
            modelName: formattedModelName,
            deviceClass: deviceClass
        )
    }
    
    /// Format model name for user-friendly display
    private func formatModelName() -> String? {
        guard let model = model else { return nil }
        
        // Try to create a nice display name from model info
        if let modelName = model.name, !modelName.isEmpty {
            // If we have model identifier (like "iPad13,8"), try to extract useful info
            if let identifier = model.identifier, !identifier.isEmpty {
                // Extract generation info from identifier if available
                // e.g., "iPad13,8" -> could map to "iPad (A15)" or similar
                return modelName
            }
            return modelName
        } else if let identifier = model.identifier {
            return identifier
        }
        
        return deviceClass?.capitalized
    }
    
    /// Map device type/model to SF Symbol icon name
    private func mapToIconName() -> String {
        let deviceClassLower = (deviceClass ?? "").lowercased()
        let modelName = (model?.name ?? "").lowercased()
        let modelType = (model?.type ?? "").lowercased()
        let nameLower = name.lowercased()
        
        switch true {
        case deviceClassLower.contains("ipad") || modelType.contains("ipad") || nameLower.contains("ipad"):
            // Try to determine iPad generation/style from model or name
            if modelName.contains("pro") || nameLower.contains("pro") {
                return "ipad.gen2"
            } else if modelName.contains("air") || nameLower.contains("air") {
                return "ipad.gen1"
            } else if modelName.contains("mini") || nameLower.contains("mini") {
                return "ipad"
            } else {
                return "ipad.landscape"
            }
        case deviceClassLower.contains("iphone") || modelType.contains("iphone"):
            return "iphone"
        case deviceClassLower.contains("mac") || modelType.contains("mac"):
            return "laptopcomputer"
        case deviceClassLower.contains("tv") || modelName.contains("appletv"):
            return "appletv.fill"
        default:
            return "ipad"
        }
    }
    
    /// Assign a ring color based on device UDID (for consistent coloring)
    private func mapToRingColor() -> String {
        let colors = ["blue", "green", "purple", "orange", "red", "pink", "cyan", "yellow"]
        let index = abs(udid.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Collection Mappers

extension Array where Element == AppDTO {
    /// Convert array of API DTOs to domain models
    /// - Returns: Tuple with array of AppItems and bundleId-based mapping dictionary
    func toAppItems() -> (items: [AppItem], bundleIdMapping: [String: UUID]) {
        var items: [AppItem] = []
        var bundleIdMapping: [String: UUID] = [:]
        var seenBundleIds = Set<String>() // Track which bundleIds we've already processed
        
        for dto in self {
            // Skip if we've already processed this bundleId (prevents duplicates)
            if seenBundleIds.contains(dto.bundleId) {
                print("⚠️ Skipping duplicate app: \(dto.name) (bundleId: \(dto.bundleId))")
                continue
            }
            
            let appItem = dto.toAppItem()
            items.append(appItem)
            bundleIdMapping[dto.bundleId] = appItem.id
            seenBundleIds.insert(dto.bundleId)
        }
        
        return (items, bundleIdMapping)
    }
}

extension Array where Element == DeviceDTO {
    /// Convert array of API DTOs to domain models
    /// - Parameter bundleIdMapping: Dictionary mapping app bundleIds to AppItem UUIDs
    /// - Returns: Array of Device objects
    func toDevices(bundleIdMapping: [String: UUID]) -> [Device] {
        self.map { $0.toDevice(bundleIdMapping: bundleIdMapping) }
    }
}

// MARK: - Deterministic UUID Generation

extension String {
    /// Generate a deterministic UUID from a string (like bundleId)
    /// This ensures the same string always produces the same UUID across app launches
    var deterministicUUID: UUID {
        // Use a fixed namespace UUID as a seed
        let namespace = "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        
        // Combine namespace and string to create deterministic data
        let combinedString = namespace + self
        let data = combinedString.data(using: .utf8)!
        
        // Generate 16 bytes for UUID using a simple hash algorithm
        var hash = [UInt8](repeating: 0, count: 16)
        for (index, byte) in data.enumerated() {
            let position = index % 16
            hash[position] = hash[position] &+ byte
        }
        
        // Additional mixing to improve distribution
        for i in 0..<16 {
            hash[i] = hash[i] &+ UInt8((i * 17) % 256)
        }
        
        // Format as UUID string
        let uuidString = String(format: "%02X%02X%02X%02X-%02X%02X-%02X%02X-%02X%02X-%02X%02X%02X%02X%02X%02X",
                                hash[0], hash[1], hash[2], hash[3],
                                hash[4], hash[5], hash[6], hash[7],
                                hash[8], hash[9], hash[10], hash[11],
                                hash[12], hash[13], hash[14], hash[15])
        
        return UUID(uuidString: uuidString) ?? UUID()
    }
}

