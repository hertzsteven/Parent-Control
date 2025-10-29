//
//  ProfileData.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import Foundation

struct ProfileData: Identifiable, Codable, Equatable {
    let id: UUID
    let profileImage: String
    let name: String
    let deviceInfo: String
    
    init(
        id: UUID = UUID(),
        profileImage: String,
        name: String,
        deviceInfo: String
    ) {
        self.id = id
        self.profileImage = profileImage
        self.name = name
        self.deviceInfo = deviceInfo
    }
}

