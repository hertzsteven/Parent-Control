////
////  DeviceSelectionView.swift
////  Parent Control
////
////  Created by Steven Hertz on 10/29/25.
////
//

//
//  DeviceSelectionView.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/29/25.
//

import SwiftUI

/// View for selecting which device to manage parental controls for
struct DeviceSelectionView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var viewModel: ParentalControlViewModel
    @State private var showSettings = false
    @State private var loadingTask: Task<Void, Never>? = nil
    
    let columns = [
        GridItem(.flexible(), spacing: AppTheme.Spacing.lg),
        GridItem(.flexible(), spacing: AppTheme.Spacing.lg)
    ]
    
    init() {
        _viewModel = State(initialValue: ParentalControlViewModel())
    }
    
    var body: some View {
        // Only render if authenticated
        if !authManager.isAuthenticated {
            // Return empty view if not authenticated (shouldn't happen, but safety check)
            EmptyView()
        } else {
            NavigationStack {
                ZStack {
                    AppTheme.Colors.background
                        .ignoresSafeArea()
                    
                    // Show loading state while fetching data OR if data hasn't been loaded yet
                    if viewModel.isLoading || !viewModel.hasLoadedData {
                        LoadingView(message: "Loading devices...")
                    } else {
                        VStack(spacing: 0) {
                            navigationBar
                            deviceGridSection
                        }
                    }
                }
                .navigationDestination(for: Device.self) { device in
                    DeviceAppsView(device: device, viewModel: viewModel)
                }
                // REPLACE .task WITH .onAppear AND .onDisappear
                .onAppear {
                    startLoadingIfNeeded()
                }
                .onDisappear {
                    // Cancel the task if view disappears
                    loadingTask?.cancel()
                    loadingTask = nil
                }
                // REMOVE THE OLD .task MODIFIER COMPLETELY
                .alert("Error Loading Data", isPresented: .constant(viewModel.errorMessage != nil)) {
                    Button("OK") {
                        viewModel.errorMessage = nil
                    }
                } message: {
                    if let error = viewModel.errorMessage {
                        Text(error)
                    }
                }
                .sheet(isPresented: $showSettings) {
                    SettingsView(viewModel: viewModel)
                        .environmentObject(authManager)
                }
            }
        }
    }
    
    // ADD THIS NEW FUNCTION
    private func startLoadingIfNeeded() {
        // Only start loading if:
        // 1. We're authenticated
        // 2. Not in voluntary logout
        // 3. Haven't loaded data yet
        // 4. Not currently loading
        guard authManager.isAuthenticated,
              !authManager.isVoluntaryLogout,
              !viewModel.hasLoadedData,
              loadingTask == nil else {
            return
        }
        
        // Cancel any existing task (shouldn't happen, but just in case)
        loadingTask?.cancel()
        
        // Start new loading task
        loadingTask = Task {
            // Check for cancellation
            guard !Task.isCancelled else { return }
            
            // Set auth manager on view model
            viewModel.authManager = authManager
            
            // Load data from API
            await viewModel.loadData()
            
            // Clear task reference when done
            if !Task.isCancelled {
                loadingTask = nil
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
            
            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
                    .font(.system(size: 22, weight: .medium))
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
            .refreshable {
                await viewModel.refreshData()
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
        .environmentObject(AuthenticationManager())
}

#Preview("Empty State") {
    DeviceSelectionView()
        .environmentObject(AuthenticationManager())
}


//import SwiftUI
//
///// View for selecting which device to manage parental controls for
//struct DeviceSelectionView: View {
//    @EnvironmentObject var authManager: AuthenticationManager
//    @State private var viewModel: ParentalControlViewModel
//    @State private var showAccountMenu = false
//    
//    let columns = [
//        GridItem(.flexible(), spacing: AppTheme.Spacing.lg),
//        GridItem(.flexible(), spacing: AppTheme.Spacing.lg)
//    ]
//    
//    init() {
//        _viewModel = State(initialValue: ParentalControlViewModel())
//    }
//    
//    var body: some View {
//        // Only render if authenticated
//        if !authManager.isAuthenticated {
//            // Return empty view if not authenticated (shouldn't happen, but safety check)
//            EmptyView()
//        } else {
//            NavigationStack {
//                ZStack {
//                    AppTheme.Colors.background
//                        .ignoresSafeArea()
//                    
//                    // Show loading state while fetching data OR if data hasn't been loaded yet
//                    if viewModel.isLoading || !viewModel.hasLoadedData {
//                        LoadingView(message: "Loading devices...")
//                    } else {
//                        VStack(spacing: 0) {
//                            navigationBar
//                            deviceGridSection
//                        }
//                    }
//                }
//                .navigationDestination(for: Device.self) { device in
//                    DeviceAppsView(device: device, viewModel: viewModel)
//                }
//                .task(id: authManager.isAuthenticated) {
//                    // Only load data if authenticated
//                    guard authManager.isAuthenticated && !authManager.isVoluntaryLogout else { 
//                        // Reset loading state if not authenticated
//                        viewModel.isLoading = false
//                        return 
//                    }
//                    
//                    // Set auth manager on view model
//                    viewModel.authManager = authManager
//                    
//                    // Load data from API when view appears
//                    await viewModel.loadData()
//                }
//                .alert("Error Loading Data", isPresented: .constant(viewModel.errorMessage != nil)) {
//                Button("OK") {
//                    viewModel.errorMessage = nil
//                }
//            } message: {
//                if let error = viewModel.errorMessage {
//                    Text(error)
//                }
//            }
//            .confirmationDialog("Account", isPresented: $showAccountMenu) {
//                Button("Switch User") {
//                    authManager.logout(isVoluntary: true)
//                }
//                Button("Cancel", role: .cancel) { }
//            } message: {
//                if let user = authManager.authenticatedUser {
//                    Text("Logged in as \(user.name)")
//                }
//            }
//            }
//        }
//    }
//    
//    // MARK: - View Components
//    
//    /// Top navigation bar with title
//    @ViewBuilder
//    private var navigationBar: some View {
//        HStack {
//            Text("Select Device")
//                .font(AppTheme.Typography.navigationTitle)
//            
//            Spacer()
//            
//            Button(action: { showAccountMenu = true }) {
//                Image(systemName: "ellipsis")
//                    .font(AppTheme.Typography.navigationTitle)
//            }
//        }
//        .navigationBarStyle()
//    }
//    
//    /// Grid layout of device cards
//    @ViewBuilder
//    private var deviceGridSection: some View {
//        if viewModel.devices.isEmpty {
//            emptyStateView
//        } else {
//            ScrollView {
//                VStack(spacing: AppTheme.Spacing.xl) {
//                    // Header text
//                    Text("Choose an iPad to manage")
//                        .font(AppTheme.Typography.childName)
//                        .foregroundColor(AppTheme.Colors.textPrimary)
//                        .padding(.top, AppTheme.Spacing.lg)
//                    
//                    // Device grid
//                    LazyVGrid(columns: columns, spacing: AppTheme.Spacing.lg) {
//                        ForEach(viewModel.devices) { device in
//                            NavigationLink(value: device) {
//                                DeviceCardView(device: device)
//                            }
//                            .buttonStyle(.plain)
//                        }
//                    }
//                    .padding(.horizontal, AppTheme.Spacing.lg)
//                    .padding(.bottom, AppTheme.Spacing.lg)
//                }
//            }
//            .refreshable {
//                await viewModel.refreshData()
//            }
//        }
//    }
//    
//    /// Empty state view when no devices are configured
//    @ViewBuilder
//    private var emptyStateView: some View {
//        VStack(spacing: AppTheme.Spacing.lg) {
//            Spacer()
//            
//            Image(systemName: "ipad")
//                .font(.system(size: 60))
//                .foregroundColor(AppTheme.Colors.textSecondary)
//            
//            Text("No Devices")
//                .font(AppTheme.Typography.childName)
//            
//            Text("Add devices to start managing parental controls")
//                .font(AppTheme.Typography.deviceInfo)
//                .foregroundColor(AppTheme.Colors.textSecondary)
//                .multilineTextAlignment(.center)
//            
//            Spacer()
//        }
//        .padding(AppTheme.Spacing.lg)
//    }
//}
//
//// MARK: - Previews
//#Preview("Default") {
//    DeviceSelectionView()
//        .environmentObject(AuthenticationManager())
//}
//
//#Preview("Empty State") {
//    DeviceSelectionView()
//        .environmentObject(AuthenticationManager())
//}
//
