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
    /// True when the device is currently locked into this app
    let isLocked: Bool
    /// True while a lock into this app is being sent
    let isLocking: Bool

    init(item: AppItem, count: Int? = nil, isLocked: Bool = false, isLocking: Bool = false) {
        self.item = item
        self.count = count
        self.isLocked = isLocked
        self.isLocking = isLocking
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
            
            HStack(spacing: AppTheme.Spacing.xs) {
                // Locking spinner, replaced by the Locked badge once the lock is sent
                if isLocking {
                    HStack(spacing: 4) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Locking…")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.horizontal, 8)
                    .frame(minHeight: 20)
                    .padding(.vertical, 2)
                    .background(AppTheme.Colors.background)
                    .clipShape(Capsule())
                } else if isLocked {
                    Label("Locked", systemImage: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 20)
                        .padding(.vertical, 2)
                        .background(AppTheme.Colors.primary)
                        .clipShape(Capsule())
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                }

                // Count badge, grey so it does not read as part of the Locked badge
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .frame(minWidth: 20, minHeight: 20)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppTheme.Colors.background)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, AppTheme.Spacing.sm)
            .padding(.trailing, AppTheme.Spacing.sm)
        }
        .cardStyle()
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.cornerRadius)
                .strokeBorder(AppTheme.Colors.primary, lineWidth: 2)
                .opacity(isLocked ? 1 : 0)
        )
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

            TileView(
                item: AppItem(
                    title: "Locked App",
                    description: "The device is locked into this app.",
                    iconName: "star.fill",
                    additionalInfo: "Additional Info"
                ),
                count: 2,
                isLocked: true
            )
        }
        .previewLayout(.sizeThatFits)
        .padding()
        .background(AppTheme.Colors.background)
    }
}

