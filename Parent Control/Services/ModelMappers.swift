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
        AppItem(
            title: name,
            description: "\(vendor) - \(platform)",
            iconName: mapToIconName(),
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
    /// - Parameter appMapping: Dictionary mapping app API IDs to AppItem UUIDs
    /// - Returns: Device for use in the app
    func toDevice(appMapping: [Int: UUID]) -> Device {
        // Map app IDs from API to AppItem UUIDs
        let mappedAppIds = (apps ?? []).compactMap { apiId in
            appMapping[apiId]
        }
        
        return Device(
            name: name,
            iconName: mapToIconName(),
            ringColor: mapToRingColor(),
            appIds: mappedAppIds
        )
    }
    
    /// Map device type/model to SF Symbol icon name
    private func mapToIconName() -> String {
        let deviceTypeLower = (deviceType ?? "").lowercased()
        let modelLower = (model ?? "").lowercased()
        let nameLower = name.lowercased()
        
        switch true {
        case deviceTypeLower.contains("ipad") || modelLower.contains("ipad") || nameLower.contains("ipad"):
            // Try to determine iPad generation/style from model or name
            if modelLower.contains("pro") || nameLower.contains("pro") {
                return "ipad.gen2"
            } else if modelLower.contains("air") || nameLower.contains("air") {
                return "ipad.gen1"
            } else if modelLower.contains("mini") || nameLower.contains("mini") {
                return "ipad"
            } else {
                return "ipad.landscape"
            }
        case deviceTypeLower.contains("iphone") || modelLower.contains("iphone"):
            return "iphone"
        case deviceTypeLower.contains("mac") || modelLower.contains("mac"):
            return "laptopcomputer"
        case deviceTypeLower.contains("tv") || modelLower.contains("appletv"):
            return "appletv.fill"
        default:
            return "ipad"
        }
    }
    
    /// Assign a ring color based on device ID (for consistent coloring)
    private func mapToRingColor() -> String {
        let colors = ["blue", "green", "purple", "orange", "red", "pink", "cyan", "yellow"]
        let index = abs(id) % colors.count
        return colors[index]
    }
}

// MARK: - Collection Mappers

extension Array where Element == AppDTO {
    /// Convert array of API DTOs to domain models
    /// - Returns: Tuple with array of AppItems and mapping dictionary
    func toAppItems() -> (items: [AppItem], mapping: [Int: UUID]) {
        var items: [AppItem] = []
        var mapping: [Int: UUID] = [:]
        
        for dto in self {
            let appItem = dto.toAppItem()
            items.append(appItem)
            mapping[dto.id] = appItem.id
        }
        
        return (items, mapping)
    }
}

extension Array where Element == DeviceDTO {
    /// Convert array of API DTOs to domain models
    /// - Parameter appMapping: Dictionary mapping app API IDs to AppItem UUIDs
    /// - Returns: Array of Device objects
    func toDevices(appMapping: [Int: UUID]) -> [Device] {
        self.map { $0.toDevice(appMapping: appMapping) }
    }
}

