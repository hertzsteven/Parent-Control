//
//  DeviceSelectionView.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/29/25.
//

import SwiftUI

/// View for selecting which device to manage parental controls for
struct DeviceSelectionView: View {
    @State private var viewModel = ParentalControlViewModel()
    
    let columns = [
        GridItem(.flexible(), spacing: AppTheme.Spacing.lg),
        GridItem(.flexible(), spacing: AppTheme.Spacing.lg)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    navigationBar
                    deviceGridSection
                }
            }
            .navigationDestination(for: Device.self) { device in
                ContentView(device: device, viewModel: viewModel)
            }
        }
    }
    
    // MARK: - View Components
    
    /// Top navigation bar with title
    @ViewBuilder
    private var navigationBar: some View {
        HStack {
            Text("Select Device")
                .font(AppTheme.Typography.navigationTitle)
            
            Spacer()
            
            Button(action: { /* TODO: Add menu functionality */ }) {
                Image(systemName: "ellipsis")
                    .font(AppTheme.Typography.navigationTitle)
            }
        }
        .navigationBarStyle()
    }
    
    /// Grid layout of device cards
    @ViewBuilder
    private var deviceGridSection: some View {
        if viewModel.devices.isEmpty {
            emptyStateView
        } else {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Header text
                    Text("Choose an iPad to manage")
                        .font(AppTheme.Typography.childName)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .padding(.top, AppTheme.Spacing.lg)
                    
                    // Device grid
                    LazyVGrid(columns: columns, spacing: AppTheme.Spacing.lg) {
                        ForEach(viewModel.devices) { device in
                            NavigationLink(value: device) {
                                DeviceCardView(device: device)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
            }
        }
    }
    
    /// Empty state view when no devices are configured
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "ipad")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("No Devices")
                .font(AppTheme.Typography.childName)
            
            Text("Add devices to start managing parental controls")
                .font(AppTheme.Typography.deviceInfo)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
    }
}

// MARK: - Previews
#Preview("Default") {
    DeviceSelectionView()
}

#Preview("Empty State") {
    let viewModel = ParentalControlViewModel()
    viewModel.devices = []
    
    return DeviceSelectionView()
}

