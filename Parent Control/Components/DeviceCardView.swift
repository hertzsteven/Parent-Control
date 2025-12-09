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
                
                // Battery indicator badge (optional)
                if device.batteryLevel != nil {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: device.batteryIcon())
                                .font(.caption2)
                                .foregroundColor(device.batteryColor())
                                .padding(4)
                                .background(AppTheme.Colors.cardBackground)
                                .clipShape(Circle())
                        }
                    }
                    .frame(width: 80, height: 80)
                }
            }
            
            // Device name
            Text(device.name)
                .font(AppTheme.Typography.appTitle)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Model name (optional, compact display)
            if let modelName = device.modelName {
                Text(modelName)
                    .font(.caption2)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
        }
        .frame(width: 140, height: 180) // Increased height slightly to accommodate new info
        .cardStyle()
    }
}

// MARK: - Preview
#Preview {
    let sampleDevice = Device(
        udid: "00008120-0000000000000000",
        name: "Living Room iPad",
        iconName: "ipad.gen1",
        ringColor: "blue",
        appIds: [],
        ownerId: "143",
        batteryLevel: 0.73,
        modelName: "iPad (A16)",
        deviceClass: "ipad"
    )
    
    let sampleDevices = [
        sampleDevice,
        Device(
            udid: "00008120-0000000000000001",
            name: "Bedroom iPad",
            iconName: "ipad.gen2",
            ringColor: "green",
            appIds: [],
            ownerId: "143",
            batteryLevel: 0.42,
            modelName: "iPad Air",
            deviceClass: "ipad"
        )
    ]
    
    VStack(spacing: AppTheme.Spacing.lg) {
        DeviceCardView(device: sampleDevice)
        
        HStack(spacing: AppTheme.Spacing.lg) {
            ForEach(sampleDevices) { device in
                DeviceCardView(device: device)
            }
        }
    }
    .padding()
    .background(AppTheme.Colors.background)
}

