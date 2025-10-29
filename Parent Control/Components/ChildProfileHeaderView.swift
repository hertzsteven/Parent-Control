//
//  ChildProfileHeaderView.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import SwiftUI

/// Reusable child profile header component displaying child's avatar, name, and device info
struct ChildProfileHeaderView: View {
    let childData: ChildData
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: childData.childImage)
                .font(.system(size: AppTheme.Layout.childIconSize))
                .foregroundColor(AppTheme.Colors.primary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(childData.name)
                    .font(AppTheme.Typography.childName)
                
                Text(childData.deviceInfo)
                    .font(AppTheme.Typography.deviceInfo)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .childProfileStyle()
    }
}

// MARK: - Preview
#Preview {
    ChildProfileHeaderView(
        childData: ChildData(
            childImage: "person.crop.circle.fill",
            name: "David Grossman",
            deviceInfo: "iPad (A16) Wi-Fi"
        )
    )
    .background(AppTheme.Colors.background)
}

