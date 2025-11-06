//
//  AllDevicesUsageStatisticsView.swift
//  Parent Control
//
//  View showing statistics for all devices
//

import SwiftUI

/// View displaying app selection statistics for all devices
struct AllDevicesUsageStatisticsView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: ParentalControlViewModel
    @ObservedObject private var appCounter = AppSelectionCounter.shared
    
    @State private var selectedDevice: Device?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        // Overall summary card - always show
                        overallSummaryCard
                        
                        // Devices list
                        if devicesWithStats.isEmpty {
                            emptyStateView
                                .padding(.top, 20)
                        } else {
                            ForEach(devicesWithStats) { device in
                                deviceStatisticsRow(device: device)
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.lg)
                    .frame(minHeight: 200) // Ensure minimum height so view is never blank
                }
            }
            .navigationTitle("All Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $selectedDevice) { device in
                DeviceUsageStatisticsView(
                    device: device,
                    viewModel: viewModel
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var devicesWithStats: [Device] {
        viewModel.devices.filter { device in
            appCounter.getTotalSelections(for: device.udid) > 0
        }
    }
    
    private var totalSelectionsAcrossAllDevices: Int {
        appCounter.getTotalSelections()
    }
    
    private var totalDevicesWithStats: Int {
        devicesWithStats.count
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var overallSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.headline)
                    .foregroundColor(.blue)
                Text("Overall Statistics")
                    .font(.headline)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalSelectionsAcrossAllDevices)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Total Selections")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalDevicesWithStats)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Devices Active")
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func deviceStatisticsRow(device: Device) -> some View {
        let deviceTotal = appCounter.getTotalSelections(for: device.udid)
        let deviceAppsCount = appCounter.getAllCounts(for: device.udid).count
        
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
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text("\(deviceTotal)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(device.color)
                            Text("selections")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        HStack(spacing: 4) {
                            Text("\(deviceAppsCount)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Text("apps")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                    }
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
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("No Usage Data")
                .font(.headline)
            
            Text("No devices have app selection history yet.")
                .font(.subheadline)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Preview

#Preview {
    AllDevicesUsageStatisticsView(viewModel: ParentalControlViewModel())
}

