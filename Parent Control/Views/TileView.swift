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
    let count: Int?
    
    init(item: AppItem, count: Int? = nil) {
        self.item = item
        self.count = count
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            
            // Count badge
            if let count = count, count > 0 {
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(minWidth: 20, minHeight: 20)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppTheme.Colors.primary)
                    .clipShape(Capsule())
                    .padding(.top, AppTheme.Spacing.sm)
                    .padding(.trailing, AppTheme.Spacing.sm)
            }
        }
        .cardStyle()
    }
}

// MARK: - Preview
struct TileView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            TileView(
                item: AppItem(
                    title: "Sample App",
                    description: "This is a description for the app item to preview the layout and style.",
                    iconName: "star.fill",
                    additionalInfo: "Additional Info"
                )
            )
            
            TileView(
                item: AppItem(
                    title: "App with Count",
                    description: "This app has been selected multiple times.",
                    iconName: "star.fill",
                    additionalInfo: "Additional Info"
                ),
                count: 5
            )
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(AppTheme.Colors.background)
    }
}

