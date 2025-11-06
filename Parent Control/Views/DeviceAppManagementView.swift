//
//  DeviceAppManagementView.swift
//  Parent Control
//
//  Manage which apps are visible for each device
//

import SwiftUI

/// Settings view for managing which apps appear for each device
struct DeviceAppManagementView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: ParentalControlViewModel
    @ObservedObject var appPreferences: DeviceAppPreferences
    @ObservedObject private var appCounter = AppSelectionCounter.shared
    
    @State private var selectedDevice: Device?
    
    var body: some View {
        NavigationStack {
            Group {
                if selectedDevice == nil {
                    deviceSelectionView
                } else {
                    appManagementView
                }
            }
            .navigationTitle(selectedDevice == nil ? "Select Device" : selectedDevice!.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedDevice != nil {
                        Button {
                            selectedDevice = nil
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Devices")
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Device Selection View
    
    @ViewBuilder
    private var deviceSelectionView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                // Instructions
                instructionCard
                
                // Device list
                ForEach(viewModel.devices) { device in
                    deviceSelectionRow(device: device)
                }
            }
            .padding(AppTheme.Spacing.lg)
        }
        .background(AppTheme.Colors.background)
    }
    
    @ViewBuilder
    private var instructionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.headline)
                    .foregroundColor(.blue)
                Text("Manage App Visibility")
                    .font(.headline)
            }
            
            Text("Select a device to choose which apps should appear when you tap on it. Hidden apps won't be available for locking.")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func deviceSelectionRow(device: Device) -> some View {
        Button {
            selectedDevice = device
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                // Device icon with colored ring
                ZStack {
                    Circle()
                        .strokeBorder(device.color, lineWidth: 3)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: device.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    // Get stored hidden apps and actual app IDs
                    let storedHiddenApps = appPreferences.hiddenApps(for: device.udid)
                    let actualApps = viewModel.allAppsForDevice(device)
                    let actualAppIds = Set(actualApps.map { $0.id })
                    
                    // Only count hidden apps that actually exist
                    let hiddenCount = storedHiddenApps.intersection(actualAppIds).count
                    let totalCount = actualApps.count
                    let visibleCount = totalCount - hiddenCount
                    
                    Text("\(visibleCount) of \(totalCount) apps visible")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(AppTheme.Spacing.lg)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - App Management View
    
    @ViewBuilder
    private var appManagementView: some View {
        if let device = selectedDevice {
            let allApps = viewModel.allAppsForDevice(device)
            let validAppIds = Set(allApps.map { $0.id })
            
            ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                // Summary card
                summaryCard(device: device, totalApps: allApps.count)
                
                // Apps list
                if allApps.isEmpty {
                    emptyAppsView
                } else {
                    ForEach(allApps) { app in
                        appToggleRow(app: app, device: device)
                    }
                }
            }
            .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .onAppear {
                // Clean up any orphaned hidden app IDs when view appears
                appPreferences.cleanupOrphanedPreferences(for: device.udid, validAppIds: validAppIds)
            }
        }
    }
    
    @ViewBuilder
    private func summaryCard(device: Device, totalApps: Int) -> some View {
        // Get all stored hidden app IDs
        let storedHiddenApps = appPreferences.hiddenApps(for: device.udid)
        
        // Get actual app IDs for this device
        let actualAppIds = Set(viewModel.allAppsForDevice(device).map { $0.id })
        
        // Only count hidden apps that actually exist in the current app list
        let hiddenCount = storedHiddenApps.intersection(actualAppIds).count
        let visibleCount = totalApps - hiddenCount
        
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "eye.fill")
                    .font(.headline)
                    .foregroundColor(device.color)
                Text("App Visibility")
                    .font(.headline)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(visibleCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Visible")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(hiddenCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Hidden")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            if hiddenCount > 0 {
                Button {
                    appPreferences.clearHiddenApps(for: device.udid)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                        Text("Show All Apps")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(device.color.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func appToggleRow(app: AppItem, device: Device) -> some View {
        let isHidden = appPreferences.isAppHidden(app.id, for: device.udid)
        let count = appCounter.getCount(for: app.id, deviceUDID: device.udid)
        
        Button {
            appPreferences.toggleAppVisibility(app.id, for: device.udid)
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                // App icon
                AppIconView(iconName: app.iconName, iconURL: app.iconURL)
                    .opacity(isHidden ? 0.5 : 1.0)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: 8) {
                        Text(app.title)
                            .font(AppTheme.Typography.appTitle)
                            .foregroundColor(isHidden ? AppTheme.Colors.textSecondary : AppTheme.Colors.textPrimary)
                        
                        // Count badge
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(minWidth: 18, minHeight: 18)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(device.color)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(app.description)
                        .font(AppTheme.Typography.appDescription)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                .opacity(isHidden ? 0.5 : 1.0)
                
                Spacer()
                
                // Toggle indicator
                ZStack {
                    Circle()
                        .strokeBorder(isHidden ? Color.gray : device.color, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    
                    if !isHidden {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(device.color)
                    }
                }
            }
            .padding(AppTheme.Spacing.lg)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var emptyAppsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "app.dashed")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("No Apps Found")
                .font(.headline)
            
            Text("This device has no apps installed yet.")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ParentalControlViewModel()
    DeviceAppManagementView(
        viewModel: viewModel,
        appPreferences: .shared
    )
}

