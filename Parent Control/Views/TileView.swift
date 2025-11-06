//
//  TileView.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import SwiftUI

/// Card view displaying app information
struct TileView: View {
    let item: AppItem
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            AppIconView(iconName: item.iconName, iconURL: item.iconURL)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(item.title)
                    .font(AppTheme.Typography.appTitle)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(item.description)
                    .font(AppTheme.Typography.appDescription)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
}

// MARK: - Preview
struct TileView_Previews: PreviewProvider {
    static var previews: some View {
        TileView(
            item: AppItem(
                title: "Sample App",
                description: "This is a description for the app item to preview the layout and style.",
                iconName: "star.fill",
                additionalInfo: "Additional Info"
            )
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(AppTheme.Colors.background)
    }
}

