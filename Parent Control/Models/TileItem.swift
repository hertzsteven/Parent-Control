//
//  TileItem.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import Foundation

struct TileItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let description: String
    let iconName: String
    let additionalInfo: String
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        iconName: String,
        additionalInfo: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.additionalInfo = additionalInfo
    }
}

