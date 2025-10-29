//
//  TestingView.swift
//  Parent Control
//
//  Temporary testing screen for API exploration
//

import SwiftUI

struct TestingView: View {
    @State private var viewModel = ParentalControlViewModel()
    @State private var showResults = false
    @State private var firstDeviceApps: [(name: String, bundleId: String, vendor: String, version: String, iconURL: String)] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("API Testing Screen")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Temporary screen for exploring Zuludesk API")
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding()
                
                // Loading indicator
                if viewModel.isLoading {
                    ProgressView("Fetching from Zuludesk API...")
                        .padding()
                }
                
                // Fetch button
                Button {
                    showResults = false
                    firstDeviceApps = []
                    Task {
                        await viewModel.loadData()
                        showResults = true
                        
                        // Extract first device apps for display
                        if let firstDevice = viewModel.deviceDTOs.first,
                           let apps = firstDevice.apps {
                            firstDeviceApps = apps.map { app in
                                (
                                    name: app.name ?? "Unknown",
                                    bundleId: app.identifier ?? "no bundle ID",
                                    vendor: app.vendor ?? "Unknown",
                                    version: app.version ?? "N/A",
                                    iconURL: app.icon ?? ""
                                )
                            }
                        }
                        
                        printResults()
                    }
                } label: {
                    Label("Fetch Devices & Apps", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
                
                // Error message
                if let error = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Error", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Results display
                if showResults {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Results", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        HStack {
                            Text("Apps:")
                                .fontWeight(.semibold)
                            Text("\(viewModel.appItems.count)")
                                .foregroundColor(.blue)
                        }
                        
                        HStack {
                            Text("Devices:")
                                .fontWeight(.semibold)
                            Text("\(viewModel.devices.count)")
                                .foregroundColor(.blue)
                        }
                        
                        Text("Check console for detailed output ↓")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // First Device Apps Display
                if !firstDeviceApps.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📱 \(viewModel.deviceDTOs.first?.name ?? "Device") Apps (\(firstDeviceApps.count))")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(firstDeviceApps, id: \.bundleId) { app in
                                    HStack(spacing: 12) {
                                        // App icon from URL
                                        AsyncImage(url: URL(string: app.iconURL)) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                        } placeholder: {
                                            Image(systemName: "app.fill")
                                                .foregroundColor(.gray)
                                        }
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(10)
                                        
                                        // App info
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(app.name)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                            Text(app.vendor)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(app.bundleId)
                                                .font(.caption2)
                                                .foregroundColor(.blue)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(app.version)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(12)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 600)
                    }
                }
                
                Spacer()
                
                // Detailed results section
                if showResults {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Devices section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Devices:")
                                    .font(.headline)
                                
                                ForEach(viewModel.devices) { device in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Image(systemName: device.iconName)
                                                .foregroundColor(device.color)
                                            Text(device.name)
                                                .fontWeight(.medium)
                                        }
                                        Text("\(device.appIds.count) apps")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                            
                            Divider()
                            
                            // Apps section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Apps:")
                                    .font(.headline)
                                
                                ForEach(viewModel.appItems) { app in
                                    HStack {
                                        Image(systemName: app.iconName)
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading) {
                                            Text(app.title)
                                                .fontWeight(.medium)
                                            Text(app.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color.gray.opacity(0.05))
                }
            }
            .navigationTitle("🧪 Testing")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // Print detailed results to console
    private func printResults() {
        print("\n" + String(repeating: "=", count: 60))
        print("📊 ZULUDESK API TEST RESULTS")
        print(String(repeating: "=", count: 60))
        
        print("\n📱 DEVICES (\(viewModel.devices.count)):")
        print(String(repeating: "-", count: 60))
        for (index, device) in viewModel.devices.enumerated() {
            print("\n[\(index + 1)] \(device.name)")
            print("    ID: \(device.id)")
            print("    Icon: \(device.iconName)")
            print("    Color: \(device.ringColor)")
            print("    Apps on device: \(device.appIds.count)")
            print("    App IDs: \(device.appIds.map { $0.uuidString.prefix(8) }.joined(separator: ", "))")
        }
        
        print("\n\n📲 APPS (\(viewModel.appItems.count)):")
        print(String(repeating: "-", count: 60))
        for (index, app) in viewModel.appItems.enumerated() {
            print("\n[\(index + 1)] \(app.title)")
            print("    ID: \(app.id.uuidString.prefix(8))...")
            print("    Description: \(app.description)")
            print("    Icon: \(app.iconName)")
            print("    Info: \(app.additionalInfo.components(separatedBy: "\n").first ?? "")")
        }
        
        print("\n" + String(repeating: "=", count: 60))
        print("✅ Test completed!")
        print(String(repeating: "=", count: 60) + "\n")
    }
}

#Preview {
    TestingView()
}

