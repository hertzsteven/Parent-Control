//
//  AppIconView.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import SwiftUI

/// Standardized app icon display component with consistent styling
struct AppIconView: View {
    let iconName: String
    let size: CGFloat
    
    init(iconName: String, size: CGFloat = AppTheme.Layout.appIconSize) {
        self.iconName = iconName
        self.size = size
    }
    
    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: size))
            .foregroundColor(AppTheme.Colors.primary)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AppIconView(iconName: "star.fill")
        AppIconView(iconName: "play.rectangle.fill", size: 40)
        AppIconView(iconName: "safari", size: 60)
    }
    .padding()
    .background(AppTheme.Colors.background)
}

