//
//  TileView.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import SwiftUI

/// Card view displaying app information with access control buttons
struct TileView: View {
    let item: AppItem
    let onIncrease: () -> Void
    let onDecrease: () -> Void
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            AppIconView(iconName: item.iconName)
                .frame(width: AppTheme.Layout.appIconWidth)
            
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
            
            HStack(spacing: AppTheme.Spacing.md) {
                Button(action: onIncrease) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: AppTheme.Layout.controlButtonSize))
                        .foregroundColor(AppTheme.Colors.primary)
                }
                .buttonStyle(.accessControl)
                
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle")
                        .font(.system(size: AppTheme.Layout.controlButtonSize))
                        .foregroundColor(AppTheme.Colors.primary)
                }
                .buttonStyle(.accessControl)
            }
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
            ),
            onIncrease: {},
            onDecrease: {}
        )
        .previewLayout(.sizeThatFits)
        .padding()
        .background(AppTheme.Colors.background)
    }
}

