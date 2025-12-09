//
//  DeviceUsageStatisticsView.swift
//  Parent Control
//
//  View showing per-device app selection statistics with reset functionality
//

import SwiftUI

/// View displaying app selection statistics for a specific device
struct DeviceUsageStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    let device: Device
    var viewModel: ParentalControlViewModel
    @ObservedObject private var appCounter = AppSelectionCounter.shared
    
    @State private var showResetConfirmation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Summary card
                    summaryCard
                    
                    // Apps list with counts
                    if let appsWithCounts = getAppsWithCounts(), !appsWithCounts.isEmpty {
                        ForEach(appsWithCounts, id: \.app.id) { appCount in
                            appCountRow(app: appCount.app, count: appCount.count)
                        }
                    } else {
                        emptyStateView
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .background(AppTheme.Colors.background)
            .navigationTitle(device.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Reset Counters", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    appCounter.resetCounts(for: device.udid)
                }
            } message: {
                Text("This will reset all selection counters for \(device.name). This action cannot be undone.")
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var summaryCard: some View {
        let totalSelections = appCounter.getTotalSelections(for: device.udid)
        let appsWithCounts = getAppsWithCounts() ?? []
        let uniqueApps = appsWithCounts.count
        
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.headline)
                    .foregroundColor(device.color)
                Text("Usage Statistics")
                    .font(.headline)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalSelections)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(device.color)
                    Text("Total Selections")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(uniqueApps)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Apps Used")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            if totalSelections > 0 {
                Button {
                    showResetConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset Counters")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(device.color.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func appCountRow(app: AppItem, count: Int) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // App icon
            AppIconView(iconName: app.iconName, iconURL: app.iconURL)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(app.title)
                    .font(AppTheme.Typography.appTitle)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(app.description)
                    .font(AppTheme.Typography.appDescription)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Count badge
            Text("\(count)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(minWidth: 32, minHeight: 32)
                .background(device.color)
                .clipShape(Circle())
        }
        .padding(AppTheme.Spacing.lg)
        .cardStyle()
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("No Usage Data")
                .font(.headline)
            
            Text("This device has no app selection history yet.")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Helper Methods
    
    private struct AppCount {
        let app: AppItem
        let count: Int
    }
    
    private func getAppsWithCounts() -> [AppCount]? {
        let allApps = viewModel.allAppsForDevice(device)
        let counts = appCounter.getAllCounts(for: device.udid)
        
        let appsWithCounts = allApps.compactMap { app -> AppCount? in
            if let count = counts[app.id], count > 0 {
                return AppCount(app: app, count: count)
            }
            return nil
        }
        
        return appsWithCounts.isEmpty ? nil : appsWithCounts.sorted { $0.count > $1.count }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ParentalControlViewModel()
    let fallbackDevice = Device(
        udid: "00008120-0000000000000000",
        name: "Preview iPad",
        iconName: "ipad.gen1",
        ringColor: "blue",
        appIds: [],
        ownerId: "143",
        batteryLevel: 0.73,
        modelName: "iPad (A16)",
        deviceClass: "ipad"
    )
    let device = viewModel.devices.first ?? fallbackDevice
    
    DeviceUsageStatisticsView(
        device: device,
        viewModel: viewModel
    )
}

