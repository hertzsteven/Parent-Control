import SwiftUI

// MARK: - Main Content View
/// Main parental control view displaying child profile and controlled apps
struct DeviceAppsView: View {
    let device: Device
    var viewModel: ParentalControlViewModel
    
    @ObservedObject private var appCounter = AppSelectionCounter.shared
    
    @State private var filteredApps: [AppItem] = []
    @State private var isLocking: Bool = false
    @State private var isUnlocking: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showOwnerWarning: Bool = false
    
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
            if isLocking || isUnlocking {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text(isUnlocking ? "Unlocking device..." : "Preparing device lock...")
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
        .alert("Owner Required", isPresented: $showOwnerWarning) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(device.ownerRequirementMessage)
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
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(AppTheme.Typography.childName)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    // Device model and battery info
                    HStack(spacing: 8) {
                        // Model name
                        if let modelName = device.modelName {
                            Text(modelName)
                                .font(.caption)
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        
                        // Battery level
                        if device.batteryLevel != nil {
                            HStack(spacing: 3) {
                                Image(systemName: device.batteryIcon())
                                    .font(.caption)
                                if let percentage = device.batteryPercentage {
                                    Text(percentage)
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(device.batteryColor())
                        }
                    }
                    
                    // Show owner info
                    if let ownerId = device.ownerId {
                        Text("Owner ID: \(ownerId)")
                            .font(.caption2)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                            Text("No owner assigned")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Button(action: {
                if device.hasOwner {
                    unlockDevice()
                } else {
                    showOwnerWarning = true
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.open.fill")
                        .font(.subheadline)
                    Text("Unlock")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(8)
            }
            .disabled(isLocking || isUnlocking || !device.hasOwner)
            .opacity((isLocking || isUnlocking || !device.hasOwner) ? 0.5 : 1.0)
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
                    // Instructional header
                    HStack(spacing: 8) {
                        Image(systemName: device.hasOwner ? "hand.tap.fill" : "exclamationmark.triangle.fill")
                            .font(.subheadline)
                            .foregroundColor(device.hasOwner ? AppTheme.Colors.textSecondary : .orange)
                        Text(device.hasOwner 
                            ? "Tap any app to lock the device to it"
                            : "Device has no owner - cannot lock apps")
                            .font(.subheadline)
                            .foregroundColor(device.hasOwner ? AppTheme.Colors.textSecondary : .orange)
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.top, AppTheme.Spacing.sm)
                    .padding(.bottom, AppTheme.Spacing.xs)
                    
                    // App list
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
        let count = appCounter.getCount(for: item.id, deviceUDID: device.udid)
        
        TileView(item: item, count: count > 0 ? count : nil)
            .contentShape(Rectangle())
            .onTapGesture {
                if device.hasOwner {
                    lockDeviceToApp(item)
                } else {
                    showOwnerWarning = true
                }
            }
            .allowsHitTesting(!isLocking && device.hasOwner)
            .opacity(device.hasOwner ? 1.0 : 0.6)
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
                // Increment counter on successful lock
                appCounter.incrementCount(for: app.id, deviceUDID: device.udid)
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
    
    /// Unlock device by removing all app locks
    private func unlockDevice() {
        guard !isUnlocking else { return }
        
        Task {
            isUnlocking = true
            
            let result = await viewModel.unlockDevice(device: device)
            
            isUnlocking = false
            
            switch result {
            case .success(let message):
                alertTitle = "Device Unlocked"
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
    
    NavigationStack {
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
    
    NavigationStack {
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
    
    NavigationStack {
        DeviceAppsView(device: device, viewModel: viewModel)
    }
}
