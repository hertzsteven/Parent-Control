import SwiftUI

// MARK: - Main Content View
/// Main parental control view displaying child profile and controlled apps
struct DeviceAppsView: View {
    let device: Device
    var viewModel: ParentalControlViewModel
    
    @State private var filteredApps: [AppItem] = []
    @State private var isLocking: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                navigationBar
//                deviceHeaderView
                appListSection
            }
            
            // Loading overlay
            if isLocking {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Locking device...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding(40)
                .background(Color.gray.opacity(0.9))
                .cornerRadius(16)
            }
        }
        .navigationDestination(for: AppItem.self) { item in
            DetailView(item: item)
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
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
//            Text(device.name)
//                .font(AppTheme.Typography.navigationTitle)
            
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
                    Text(device.name)
                        .font(AppTheme.Typography.childName)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                }
            }
            
            Spacer()
            
            Button(action: { /* TODO: Add menu functionality */ }) {
                Image(systemName: "ellipsis")
                    .font(AppTheme.Typography.navigationTitle)
            }
        }
        .navigationBarStyle()
        .padding(.bottom, AppTheme.Spacing.md)
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
                Text(device.name)
                    .font(AppTheme.Typography.childName)
                    .foregroundColor(AppTheme.Colors.textPrimary)

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
    
    /// Individual app row with lock functionality
    @ViewBuilder
    private func appItemRow(for item: AppItem) -> some View {
        Button {
            lockDeviceToApp(item)
        } label: {
            TileView(
                item: item,
                onIncrease: { viewModel.increaseAccess(for: item) },
                onDecrease: { viewModel.decreaseAccess(for: item) }
            )
        }
        .buttonStyle(.plain)
        .disabled(isLocking)
    }
    
    /// Lock device to the selected app
    private func lockDeviceToApp(_ app: AppItem) {
        guard !isLocking else { return }
        
        Task {
            isLocking = true
            
            let result = await viewModel.lockDeviceToApp(device: device, app: app)
            
            isLocking = false
            
            switch result {
            case .success(let message):
                alertTitle = "Success"
                alertMessage = message
                showAlert = true
                
            case .failure(let error):
                alertTitle = "Error"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
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
        DeviceAppsView(device: device, viewModel: viewModel)
    }
}

#Preview("Empty State") {
    let viewModel = ParentalControlViewModel()
    let device = Device(
        udid: "00008120-0000000000000000",
        name: "Test iPad",
        iconName: "ipad",
        ringColor: "blue",
        appIds: []
    )
    
    return NavigationStack {
        DeviceAppsView(device: device, viewModel: viewModel)
    }
}

#Preview("Single App") {
    let viewModel = ParentalControlViewModel()
    let youtubeId = viewModel.appItems.first { $0.title == "YouTube" }?.id ?? UUID()
    let device = Device(
        udid: "00008120-0000000000000000",
        name: "Test iPad",
        iconName: "ipad",
        ringColor: "green",
        appIds: [youtubeId]
    )
    
    return NavigationStack {
        DeviceAppsView(device: device, viewModel: viewModel)
    }
}
