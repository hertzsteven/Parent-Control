//
//  DetailView.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import SwiftUI

/// Detailed view for a specific controlled app showing full information
struct DetailView: View {
    @Environment(\.dismiss) var dismiss
    let item: AppItem
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Back button bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .font(AppTheme.Typography.backButton)
                            Text("Back")
                        }
                    }
                    .buttonStyle(.navigationLink)
                    
                    Spacer()
                }
                .navigationBarStyle()
                .foregroundColor(AppTheme.Colors.primary)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        // Header with icon and title
                        HStack(spacing: AppTheme.Spacing.lg) {
                            AppIconView(
                                iconName: item.iconName,
                                size: AppTheme.Layout.detailIconSize
                            )
                            .frame(
                                width: AppTheme.Layout.detailIconFrame,
                                height: AppTheme.Layout.detailIconFrame
                            )
                            .background(AppTheme.Colors.cardBackground)
                            .cornerRadius(AppTheme.Layout.cornerRadius)
                            
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text(item.title)
                                    .font(AppTheme.Typography.detailTitle)
                                
                                Text(item.description)
                                    .font(AppTheme.Typography.detailDescription)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding(AppTheme.Spacing.lg)
                        .cardStyle()
                        
                        // Information section
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                            Text("Details")
                                .font(AppTheme.Typography.sectionHeader)
                                .padding(.horizontal, AppTheme.Spacing.lg)
                            
                            Text(item.additionalInfo)
                                .font(AppTheme.Typography.detailDescription)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .lineLimit(nil)
                                .padding(AppTheme.Spacing.lg)
                                .cardStyle()
                                .padding(.horizontal, AppTheme.Spacing.lg)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.lg)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview
#Preview {
    DetailView(
        item: AppItem(
            title: "YouTube",
            description: "Video streaming platform",
            iconName: "play.rectangle.fill",
            additionalInfo: "Allowed video streaming platform. User has access to YouTube content with parental controls enabled."
        )
    )
}

