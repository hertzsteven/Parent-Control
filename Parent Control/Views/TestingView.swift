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
    @State private var appLockResult: String?
    @State private var isTestingAppLock = false
    @State private var unlockResult: String?
    @State private var isTestingUnlock = false
    
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
                
                // Test App Lock button
                Button {
                    Task {
                        isTestingAppLock = true
                        appLockResult = nil
                        await testAppLock()
                        isTestingAppLock = false
                    }
                } label: {
                    Label("Test App Lock", systemImage: "lock.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isTestingAppLock)
                .padding(.horizontal)
                
                // Test Unlock button
                Button {
                    Task {
                        isTestingUnlock = true
                        unlockResult = nil
                        await testUnlock()
                        isTestingUnlock = false
                    }
                } label: {
                    Label("Test Unlock", systemImage: "lock.open.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(isTestingUnlock)
                .padding(.horizontal)
                
                // App Lock result display
                if let appLockResult = appLockResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(appLockResult.contains("✅") ? "Success" : "Result", 
                              systemImage: appLockResult.contains("✅") ? "checkmark.circle.fill" : "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(appLockResult.contains("✅") ? .green : .blue)
                        Text(appLockResult)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background((appLockResult.contains("✅") ? Color.green : Color.blue).opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Loading indicator for app lock
                if isTestingAppLock {
                    ProgressView("Testing App Lock...")
                        .padding()
                }
                
                // Unlock result display
                if let unlockResult = unlockResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(unlockResult.contains("✅") ? "Success" : "Result", 
                              systemImage: unlockResult.contains("✅") ? "checkmark.circle.fill" : "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(unlockResult.contains("✅") ? .green : .blue)
                        Text(unlockResult)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background((unlockResult.contains("✅") ? Color.green : Color.blue).opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Loading indicator for unlock
                if isTestingUnlock {
                    ProgressView("Testing Unlock...")
                        .padding()
                }
                
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
    
    // Test app lock API call (with device owner setup first)
    private func testAppLock() async {
        print("\n" + String(repeating: "=", count: 80))
        print("🔒 TESTING TWO-STEP APP LOCK PROCESS")
        print(String(repeating: "=", count: 80))
        
        let networkService = NetworkService()
        
        do {
            // Test parameters
            let deviceUDID = "00008120-0012391420214032"
            let userId = "143"
            let bundleId = "com.thup.MonkeyMath"
            let clearAfter = 60 // seconds
            let token = "1fac4ce4ddbe4d1c984432aedd02c59f"
            
            // STEP 1: Set Device Owner
            print("\n📍 STEP 1: Setting Device Owner")
            print(String(repeating: "-", count: 80))
            print("🔧 Device UDID: \(deviceUDID)")
            print("👤 User ID: \(userId)")
            
            let ownerResponse = try await networkService.setDeviceOwner(
                deviceUDID: deviceUDID,
                userId: userId
            )
            
            print("✅ Device Owner Set Successfully!")
            if let message = ownerResponse.message {
                print("📄 Response: \(message)")
            }
            
            // STEP 2: Apply App Lock (only if step 1 succeeded)
            print("\n📍 STEP 2: Applying App Lock")
            print(String(repeating: "-", count: 80))
            print("📱 Bundle ID: \(bundleId)")
            print("⏱️ Clear After: \(clearAfter) seconds")
            print("👨‍🎓 Student IDs: \(userId)")
            print("🔑 Token: \(token)")
            
            let lockResponse = try await networkService.applyAppLock(
                bundleId: bundleId,
                clearAfterSeconds: clearAfter,
                studentIds: [userId],
                token: token
            )
            
            print("\n✅ App Lock Applied Successfully!")
            if let message = lockResponse.message {
                print("📄 Response: \(message)")
            }
            print(String(repeating: "=", count: 80) + "\n")
            
            appLockResult = "✅ SUCCESS!\n\nStep 1: Device owner set to user \(userId)\nStep 2: App lock applied\n\nApp: \(bundleId)\nDuration: \(clearAfter) seconds\nStudent: \(userId)"
            
        } catch let error as NetworkError {
            print("\n❌ Process Failed!")
            print("⚠️ Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            
            appLockResult = "❌ Failed: \(error.localizedDescription)"
            
        } catch {
            print("\n❌ Process Failed!")
            print("⚠️ Unknown Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            
            appLockResult = "❌ Failed: \(error.localizedDescription)"
        }
    }
    
    // Test unlock API call
    private func testUnlock() async {
        print("\n" + String(repeating: "=", count: 80))
        print("🔓 TESTING UNLOCK/STOP APP LOCK")
        print(String(repeating: "=", count: 80))
        
        let networkService = NetworkService()
        
        do {
            let studentId = "143"
            let token = "1fac4ce4ddbe4d1c984432aedd02c59f"
            
            print("👤 Student ID: \(studentId)")
            print("🔑 Token: \(token)")
            
            let response = try await networkService.stopAppLock(
                studentId: studentId,
                token: token
            )
            
            print("\n✅ Unlock Successful!")
            print("Success: \(response.success ?? false)")
            if let tasks = response.tasks {
                print("Tasks: \(tasks.count)")
                for task in tasks {
                    print("  - Student: \(task.student)")
                    print("    UUID: \(task.UUID)")
                    print("    Status: \(task.status)")
                }
            }
            print(String(repeating: "=", count: 80) + "\n")
            
            let taskInfo = response.tasks?.first.map { 
                "\nStudent: \($0.student)\nStatus: \($0.status)" 
            } ?? ""
            unlockResult = "✅ SUCCESS!\n\nApp lock removed for student \(studentId)\(taskInfo)"
            
        } catch let error as NetworkError {
            print("\n❌ Unlock Failed!")
            print("⚠️ Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            unlockResult = "❌ Failed: \(error.localizedDescription)"
            
        } catch {
            print("\n❌ Unlock Failed!")
            print("⚠️ Unknown Error: \(error.localizedDescription)")
            print(String(repeating: "=", count: 80) + "\n")
            unlockResult = "❌ Failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    TestingView()
}

