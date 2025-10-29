//
//  ProfileData.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import Foundation

struct ChildData: Identifiable, Codable, Equatable {
    let id: UUID
    let childImage: String
    let name: String
    let deviceInfo: String
    
    init(
        id: UUID = UUID(),
        childImage: String,
        name: String,
        deviceInfo: String
    ) {
        self.id = id
        self.childImage = childImage
        self.name = name
        self.deviceInfo = deviceInfo
    }
}

