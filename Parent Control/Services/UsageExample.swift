//
//  UsageExample.swift
//  Parent Control
//
//  Example of how to use the Zuludesk API integration
//  This file is for reference only - adapt the patterns to your actual views
//

import SwiftUI

// MARK: - Example 1: Basic Usage in ContentView

/*
struct ContentView: View {
    @State private var viewModel = ParentalControlViewModel()
    
    var body: some View {
        VStack {
            // Show loading indicator
            if viewModel.isLoading {
                ProgressView("Loading from Zuludesk...")
                    .padding()
            }
            
            // Show error if any
            if let error = viewModel.errorMessage {
                Text("⚠️ \(error)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Your existing UI
            DeviceListView(viewModel: viewModel)
        }
        .task {
            // Load data when view appears
            await viewModel.loadData()
        }
    }
}
*/

// MARK: - Example 2: Manual Refresh

/*
struct ContentView: View {
    @State private var viewModel = ParentalControlViewModel()
    
    var body: some View {
        VStack {
            // Manual refresh button
            Button("Refresh from API") {
                viewModel.loadDataInBackground()
            }
            .disabled(viewModel.isLoading)
            
            if viewModel.isLoading {
                ProgressView()
            }
            
            // Your content
            DeviceGrid(devices: viewModel.devices)
        }
    }
}
*/

// MARK: - Example 3: Custom Configuration

/*
struct ContentView: View {
    @State private var viewModel: ParentalControlViewModel
    
    init() {
        // Create custom API configuration
        let config = APIConfiguration(
            baseURL: "yourDomain.jamfcloud.com",
            networkID: "10482058",
            apiKey: "YOUR_API_KEY_HERE",
            apiVersion: "1"
        )
        
        // Create network service with custom config
        let networkService = NetworkService(configuration: config)
        
        // Initialize view model with custom network service
        _viewModel = State(initialValue: ParentalControlViewModel(
            networkService: networkService
        ))
    }
    
    var body: some View {
        // Your UI
        Text("Connected to: \(viewModel.devices.count) devices")
            .task {
                await viewModel.loadData()
            }
    }
}
*/

// MARK: - Example 4: Error Handling with Retry

/*
struct ContentView: View {
    @State private var viewModel = ParentalControlViewModel()
    @State private var showErrorAlert = false
    
    var body: some View {
        VStack {
            DeviceListView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadData()
            
            // Show alert if there was an error
            if viewModel.errorMessage != nil {
                showErrorAlert = true
            }
        }
        .alert("Connection Error", isPresented: $showErrorAlert) {
            Button("Retry") {
                Task {
                    await viewModel.loadData()
                }
            }
            Button("Use Offline Data") {
                // Continue with default data
                showErrorAlert = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }
}
*/

// MARK: - Example 5: Pull to Refresh

/*
struct DeviceListView: View {
    @Bindable var viewModel: ParentalControlViewModel
    
    var body: some View {
        List(viewModel.devices) { device in
            DeviceRow(device: device)
        }
        .refreshable {
            await viewModel.loadData()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
*/

// MARK: - Example 6: Combining with Child Data

/*
struct ParentView: View {
    @State private var viewModel = ParentalControlViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                // Child profile header
                ChildProfileHeaderView(childData: viewModel.childData)
                
                // Device selection
                DeviceSelectionView(
                    devices: viewModel.devices,
                    selectedDevice: $viewModel.selectedDevice
                )
                
                // App tiles
                if let device = viewModel.selectedDevice {
                    AppTileGrid(apps: viewModel.appsForDevice(device))
                }
            }
            .navigationTitle("Parent Control")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.loadDataInBackground()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .task {
            // Initial load
            await viewModel.loadData()
        }
    }
}
*/

// MARK: - Example 7: Direct Network Service Usage

/*
// If you need to make custom API calls outside the ViewModel

func fetchSpecificDevice(deviceId: Int) async throws -> Device {
    let config = APIConfiguration.default
    let networkService = NetworkService(configuration: config)
    
    // Fetch all devices
    let devices = try await networkService.fetchDevices()
    
    // Find specific device
    guard let deviceDTO = devices.first(where: { $0.id == deviceId }) else {
        throw NetworkError.invalidResponse
    }
    
    // Convert to domain model
    return deviceDTO.toDevice(appMapping: [:])
}
*/

// MARK: - Example 8: Environment-based Configuration

/*
enum Environment {
    case development
    case staging
    case production
    
    var apiConfig: APIConfiguration {
        switch self {
        case .development:
            return APIConfiguration(
                baseURL: "dev.jamfcloud.com",
                networkID: "DEV_NETWORK_ID",
                apiKey: "DEV_API_KEY"
            )
        case .staging:
            return APIConfiguration(
                baseURL: "staging.jamfcloud.com",
                networkID: "STAGING_NETWORK_ID",
                apiKey: "STAGING_API_KEY"
            )
        case .production:
            return APIConfiguration(
                baseURL: "apiv6.zuludesk.com",
                networkID: "PROD_NETWORK_ID",
                apiKey: "PROD_API_KEY"
            )
        }
    }
}

struct ContentView: View {
    @State private var viewModel: ParentalControlViewModel
    
    init() {
        let env = Environment.development
        let networkService = NetworkService(configuration: env.apiConfig)
        _viewModel = State(initialValue: ParentalControlViewModel(
            networkService: networkService
        ))
    }
    
    var body: some View {
        // Your UI
        Text("Ready")
    }
}
*/

