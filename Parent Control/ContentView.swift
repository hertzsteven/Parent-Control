import SwiftUI

// MARK: - Main Content View
/// Main parental control view displaying child profile and controlled apps
struct ContentView: View {
    let device: Device
    var viewModel: ParentalControlViewModel
    
    @State private var filteredApps: [AppItem] = []
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                navigationBar
                deviceHeaderView
                appListSection
            }
        }
        .navigationDestination(for: AppItem.self) { item in
            DetailView(item: item)
        }
        .onAppear {
            filteredApps = viewModel.appsForDevice(device)
            viewModel.selectDevice(device)
        }
    }
    
    // MARK: - View Components
    
    /// Top navigation bar with device name and menu button
    @ViewBuilder
    private var navigationBar: some View {
        HStack {
            Text(device.name)
                .font(AppTheme.Typography.navigationTitle)
            
            Spacer()
            
            Button(action: { /* TODO: Add menu functionality */ }) {
                Image(systemName: "ellipsis")
                    .font(AppTheme.Typography.navigationTitle)
            }
        }
        .navigationBarStyle()
    }
    
    /// Device header showing device icon and child profile
    @ViewBuilder
    private var deviceHeaderView: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Device icon with colored ring
            ZStack {
                Circle()
                    .strokeBorder(device.color, lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                Image(systemName: device.iconName)
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(viewModel.childData.name)
                    .font(AppTheme.Typography.childName)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(device.name)
                    .font(AppTheme.Typography.deviceInfo)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
        .background(AppTheme.Colors.cardBackground)
        .padding(.bottom, AppTheme.Spacing.md)
    }
    
    /// Scrollable list of controlled apps with access controls
    @ViewBuilder
    private var appListSection: some View {
        if filteredApps.isEmpty {
            emptyStateView
        } else {
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(filteredApps) { item in
                        appItemRow(for: item)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
        }
    }
    
    /// Individual app row with navigation and access controls
    @ViewBuilder
    private func appItemRow(for item: AppItem) -> some View {
        NavigationLink(value: item) {
            TileView(
                item: item,
                onIncrease: { viewModel.increaseAccess(for: item) },
                onDecrease: { viewModel.decreaseAccess(for: item) }
            )
        }
        .buttonStyle(.navigationLink)
    }
    
    /// Empty state view when no apps are being controlled
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            
            Image(systemName: "apps.iphone")
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Text("No Apps to Display")
                .font(AppTheme.Typography.childName)
            
            Text("Add apps to start managing access controls")
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
    let viewModel = ParentalControlViewModel()
    let device = viewModel.devices.first ?? Device.sample
    
    return NavigationStack {
        ContentView(device: device, viewModel: viewModel)
    }
}

#Preview("Empty State") {
    let viewModel = ParentalControlViewModel()
    let device = Device(
        name: "Test iPad",
        iconName: "ipad",
        ringColor: "blue",
        appIds: []
    )
    
    return NavigationStack {
        ContentView(device: device, viewModel: viewModel)
    }
}

#Preview("Single App") {
    let viewModel = ParentalControlViewModel()
    let youtubeId = viewModel.appItems.first { $0.title == "YouTube" }?.id ?? UUID()
    let device = Device(
        name: "Test iPad",
        iconName: "ipad",
        ringColor: "green",
        appIds: [youtubeId]
    )
    
    return NavigationStack {
        ContentView(device: device, viewModel: viewModel)
    }
}
