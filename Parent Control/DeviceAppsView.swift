import SwiftUI

// MARK: - Main Content View
/// Main parental control view displaying child profile and controlled apps
struct DeviceAppsView: View {
    let device: Device
    var viewModel: ParentalControlViewModel
    
    @ObservedObject private var appCounter = AppSelectionCounter.shared
    
    @State private var filteredApps: [AppItem] = []
    /// The card being locked right now. It shows a Locking… spinner.
    @State private var lockingAppId: AppItem.ID?
    @State private var isUnlocking: Bool = false
    /// Bumped after each lock or unlock that worked, to play a success haptic.
    @State private var successFeedback = 0
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showOwnerWarning: Bool = false
    /// False while the startup `GET /teacher/profiles` read is still trying. Drives the checking cover.
    @State private var isStartupCheckDone = false
    /// Bumped by Try again so the startup task runs a fresh set of tries.
    @State private var startupLockCycle = 0
    /// Bundle ids the device is locked into. Drives the Locked badge on each card.
    @State private var lockedBundleIds: Set<String> = []
    /// False when the last check could not reach Jamf, so the lock state is not certain.
    @State private var isLockStateKnown = false
    /// Bumped on every lock-state write so an older recheck reply cannot overwrite a newer answer.
    @State private var lockStateVersion = 0
    @Environment(\.scenePhase) private var scenePhase

    private var isLocking: Bool {
        lockingAppId != nil
    }

    /// True only while the checking cover is on screen.
    private var isStartupLockCoverVisible: Bool {
        device.hasOwner && !isStartupCheckDone
    }

    /// Locked into an app that has no card on this screen.
    private var isLockedToHiddenApp: Bool {
        !lockedBundleIds.isEmpty && !filteredApps.contains { app in
            app.bundleId.map(lockedBundleIds.contains) ?? false
        }
    }

    /// Unlock only makes sense when something is locked, or when the lock state is not certain.
    private var canUnlock: Bool {
        device.hasOwner && !isLocking && !isUnlocking
            && (!isLockStateKnown || !lockedBundleIds.isEmpty)
    }
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                navigationBar
                if device.hasOwner && isStartupCheckDone && !isLockStateKnown {
                    StartupLockCheckFailedView(onTryAgain: retryStartupLockCheck)
                }
                appListSection
            }
            
            // Startup waits for TeacherProfileLockClient.currentLock (GET /teacher/profiles)
            // before the rest of this screen continues. Not because of a hang concern:
            // the result may take a moment and may show the device is locked. If startup
            // did not wait, that locked state would be missed. The wait is what makes
            // the correct answer visible. Eight failed tries take this cover down.
            if isStartupLockCoverVisible {
                StartupLockGateView()
            }
        }
        .task(id: StartupLockTaskID(ownerId: device.ownerId, cycle: startupLockCycle)) {
            await waitForStartupLock()
        }
        .sensoryFeedback(.success, trigger: successFeedback)
        .alert("Error", isPresented: $showAlert) {
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
                .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            viewModel.selectDevice(device)
        }
        .onChange(of: scenePhase) { _, phase in
            // The lock may have cleared itself or been changed in Jamf while the app was away.
            if phase == .active {
                Task { await recheckLock() }
            }
        }
    }

    /// Blocks the rest of the device screen on the version 4 lock check.
    /// A lock that arrives a moment later is still shown. Eight missed tries stop the cover.
    private func waitForStartupLock() async {
        guard device.hasOwner, let ownerId = device.ownerId else { return }
        isStartupCheckDone = false
        let startup = TeacherProfileLockStartup()
        do {
            let status = try await startup.waitUntilAnswer(ownerId: ownerId) {
                viewModel.authManager?.token
            }
            guard !Task.isCancelled else { return }
            // No animation: the lock was already in place when the screen opened.
            recordLockState(Self.bundleIds(lockedIn: status))
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            isLockStateKnown = false
        }
        isStartupCheckDone = true
    }

    private func retryStartupLockCheck() {
        isStartupCheckDone = false
        startupLockCycle += 1
    }

    /// One quiet lock read with no cover. Runs on return to the foreground, on pull to refresh,
    /// and after a failed tile lock (its unlock step may already have cleared the old lock).
    private func recheckLock() async {
        guard device.hasOwner, let ownerId = device.ownerId, isStartupCheckDone else { return }
        let version = lockStateVersion
        let check = TeacherProfileLockStartup(attemptLimit: 1)
        do {
            let status = try await check.waitUntilAnswer(ownerId: ownerId) {
                viewModel.authManager?.token
            }
            // A lock or unlock that finished while this read was out is newer than this reply.
            guard version == lockStateVersion else { return }
            withAnimation(.easeInOut(duration: 0.25)) {
                recordLockState(Self.bundleIds(lockedIn: status))
            }
        } catch is CancellationError {
            return
        } catch {
            guard version == lockStateVersion else { return }
            // Keep the badges, but let Unlock work since the state is no longer certain.
            isLockStateKnown = false
        }
    }

    /// Records a confirmed lock state. An empty set means nothing is locked.
    private func recordLockState(_ bundleIds: Set<String>) {
        lockStateVersion += 1
        lockedBundleIds = bundleIds
        isLockStateKnown = true
    }

    private static func bundleIds(lockedIn status: TeacherProfileLockStatus) -> Set<String> {
        if case .locked(let bundleIds) = status {
            return Set(bundleIds)
        }
        return []
    }
    
    // MARK: - View Components
    
    /// Top navigation bar with device name and menu button
    @ViewBuilder
    private var navigationBar: some View {
        HStack {
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
                    
                    if !device.hasOwner {
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

            unlockControl
                .accessibilityHidden(isStartupLockCoverVisible)
        }
        .navigationBarStyle()
        .padding(.bottom, AppTheme.Spacing.md)
    }

    /// A grey Unlocked label when nothing is locked. Otherwise the orange Unlock button,
    /// which stays available when the lock state is not certain.
    @ViewBuilder
    private var unlockControl: some View {
        if device.hasOwner && isLockStateKnown && lockedBundleIds.isEmpty && !isUnlocking {
            Label("Unlocked", systemImage: "lock.open")
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        } else {
            Button(action: unlockDevice) {
                HStack(spacing: 6) {
                    if isUnlocking {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    } else {
                        Image(systemName: "lock.open.fill")
                            .font(.subheadline)
                    }
                    Text(isUnlocking ? "Unlocking…" : "Unlock")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange)
                .cornerRadius(8)
            }
            .disabled(!canUnlock)
            .opacity(canUnlock || isUnlocking ? 1.0 : 0.5)
        }
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
                        Image(systemName: hint.icon)
                            .font(.subheadline)
                            .foregroundColor(hint.color)
                        Text(hint.text)
                            .font(.subheadline)
                            .foregroundColor(hint.color)
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
            .refreshable {
                await recheckLock()
            }
        }
    }

    /// Instruction line above the app cards.
    private var hint: (icon: String, text: String, color: Color) {
        if !device.hasOwner {
            return ("exclamationmark.triangle.fill", "Device has no owner - cannot lock apps", .orange)
        }
        if isLockedToHiddenApp {
            return ("lock.fill", "Locked to an app not shown here", AppTheme.Colors.primary)
        }
        if !lockedBundleIds.isEmpty {
            return ("hand.tap.fill", "Tap another app to switch the lock", AppTheme.Colors.textSecondary)
        }
        return ("hand.tap.fill", "Tap any app to lock the device to it", AppTheme.Colors.textSecondary)
    }
    
    /// Individual app row with lock functionality
    @ViewBuilder
    private func appItemRow(for item: AppItem) -> some View {
        let count = appCounter.getCount(for: item.id, deviceUDID: device.udid)
        
        TileView(
            item: item,
            count: count > 0 ? count : nil,
            isLocked: item.bundleId.map(lockedBundleIds.contains) ?? false,
            isLocking: lockingAppId == item.id
        )
            .contentShape(Rectangle())
            .onTapGesture {
                if device.hasOwner {
                    lockDeviceToApp(item)
                } else {
                    showOwnerWarning = true
                }
            }
            .allowsHitTesting(!isLocking && !isUnlocking && device.hasOwner)
            .opacity(device.hasOwner ? 1.0 : 0.6)
            .accessibilityHidden(isStartupLockCoverVisible)
    }
    
    /// Lock device to the selected app. Success shows as the badge moving, so only errors get an alert.
    private func lockDeviceToApp(_ app: AppItem) {
        guard !isLocking, !isUnlocking else { return }
        // Already locked into just this app: nothing to send.
        if isLockStateKnown, let bundleId = app.bundleId, lockedBundleIds == [bundleId] {
            return
        }

        Task {
            lockingAppId = app.id

            let result = await viewModel.lockDeviceToApp(device: device, app: app)

            lockingAppId = nil

            switch result {
            case .success:
                // Increment counter on successful lock
                appCounter.incrementCount(for: app.id, deviceUDID: device.udid)
                if let bundleId = app.bundleId {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        recordLockState([bundleId])
                    }
                }
                successFeedback += 1

            case .failure(let error):
                alertMessage = error.localizedDescription
                showAlert = true
                await recheckLock()
            }
        }
    }

    /// Unlock device by removing all app locks. Success shows as the badge leaving, so only errors get an alert.
    private func unlockDevice() {
        guard !isUnlocking, !isLocking else { return }

        Task {
            isUnlocking = true

            let result = await viewModel.unlockDevice(device: device)

            isUnlocking = false

            switch result {
            case .success:
                withAnimation(.easeOut(duration: 0.25)) {
                    recordLockState([])
                }
                successFeedback += 1

            case .failure(let error):
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

    private struct StartupLockTaskID: Equatable {
        let ownerId: String?
        let cycle: Int
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
