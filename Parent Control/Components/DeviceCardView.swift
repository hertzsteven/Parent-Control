//
//  DeviceCardView.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/29/25.
//

import SwiftUI

/// Card view displaying a device with icon and colored ring
struct DeviceCardView: View {
    let device: Device
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Device icon with colored ring
            ZStack {
                // Colored ring background
                Circle()
                    .strokeBorder(device.color, lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                // Device icon
                Image(systemName: device.iconName)
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            // Device name
            Text(device.name)
                .font(AppTheme.Typography.appTitle)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(width: 140, height: 160)
        .cardStyle()
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: AppTheme.Spacing.lg) {
        DeviceCardView(device: Device.sample)
        
        HStack(spacing: AppTheme.Spacing.lg) {
            ForEach(Device.samples) { device in
                DeviceCardView(device: device)
            }
        }
    }
    .padding()
    .background(AppTheme.Colors.background)
}

