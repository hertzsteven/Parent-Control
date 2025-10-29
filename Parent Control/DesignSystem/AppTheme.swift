//
//  AppTheme.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import SwiftUI

enum AppTheme {
    // MARK: - Colors
    enum Colors {
        static let primary = Color.blue
        static let background = Color(UIColor.systemGray6)
        static let cardBackground = Color.white
        static let textPrimary = Color.black
        static let textSecondary = Color.gray
    }
    
    // MARK: - Typography
    enum Typography {
        static let navigationTitle = Font.system(size: 16, weight: .semibold)
        static let childName = Font.system(size: 18, weight: .bold)
        static let appTitle = Font.system(size: 16, weight: .semibold)
        static let appDescription = Font.system(size: 13)
        static let deviceInfo = Font.system(size: 14)
        static let detailTitle = Font.system(size: 24, weight: .bold)
        static let detailDescription = Font.system(size: 14)
        static let sectionHeader = Font.system(size: 16, weight: .semibold)
        static let backButton = Font.system(size: 14, weight: .semibold)
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
    
    // MARK: - Layout
    enum Layout {
        static let cornerRadius: CGFloat = 12
        static let appIconSize: CGFloat = 24
        static let appIconWidth: CGFloat = 40
        static let childIconSize: CGFloat = 50
        static let detailIconSize: CGFloat = 40
        static let detailIconFrame: CGFloat = 60
        static let controlButtonSize: CGFloat = 20
    }
}

