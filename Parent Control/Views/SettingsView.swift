//
//  SettingsView.swift
//  Parent Control
//
//  Settings screen with account management, app info, and support options
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    var viewModel: ParentalControlViewModel
    
    @State private var showAbout = false
    @State private var showDeviceAppManagement = false
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Account Section
                Section {
                    if let user = authManager.authenticatedUser {
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(user.name)
                                        .font(.headline)
                                    Text("@\(user.username)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            } icon: {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.pink)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button {
                        authManager.logout(isVoluntary: true)
                        dismiss()
                    } label: {
                        Label("Log in as Different User", systemImage: "arrow.left.arrow.right.circle")
                    }
                } header: {
                    Text("Account")
                } footer: {
                    Text("Switch to a different teacher account")
                }
                
                // MARK: - Device Management Section
                Section {
                    Button {
                        showDeviceAppManagement = true
                    } label: {
                        Label("Manage Device Apps", systemImage: "apps.ipad")
                            .foregroundColor(.primary)
                    }
                } header: {
                    Text("Device Management")
                } footer: {
                    Text("Choose which apps appear for each device")
                }
                
                // MARK: - App Information Section
                Section("App Information") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Build", systemImage: "hammer")
                        Spacer()
                        Text(buildNumber)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("App Name", systemImage: "app.badge")
                        Spacer()
                        Text(appName)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Support & Help Section
                Section("Support & Help") {
                    Button {
                        showAbout = true
                    } label: {
                        Label("About Parent Control", systemImage: "book.circle")
                            .foregroundColor(.primary)
                    }
                    
                    Link(destination: URL(string: "mailto:support@parentcontrol.com?subject=Parent%20Control%20Support")!) {
                        Label("Contact Support", systemImage: "envelope.circle")
                    }
                    
                    Link(destination: URL(string: "https://parentcontrol.com/help")!) {
                        Label("Help & FAQ", systemImage: "questionmark.circle")
                    }
                    
                    Link(destination: URL(string: "https://parentcontrol.com/feedback")!) {
                        Label("Report an Issue", systemImage: "exclamationmark.bubble")
                    }
                }
                
                // MARK: - Legal Section
                Section("Legal") {
                    Link(destination: URL(string: "https://parentcontrol.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.circle")
                    }
                    
                    Link(destination: URL(string: "https://parentcontrol.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showDeviceAppManagement) {
                DeviceAppManagementView(
                    viewModel: viewModel,
                    appPreferences: .shared
                )
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Parent Control"
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // App Icon
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.pink)
                        .padding(.top, 40)
                    
                    // App Name and Version
                    VStack(spacing: 8) {
                        Text("Parent Control")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version \(appVersion)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.headline)
                        
                        Text("Parent Control is a comprehensive parental control solution that helps teachers and parents manage device usage and app access for children's iPads.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("Features")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureRow(icon: "ipad", text: "Multi-device management")
                            FeatureRow(icon: "app.badge", text: "App-level controls")
                            FeatureRow(icon: "clock", text: "Usage monitoring")
                            FeatureRow(icon: "lock.shield", text: "Secure authentication")
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Copyright
                    Text("© 2025 Parent Control. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 24)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.pink)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
        }
    }
}

// MARK: - Previews

#Preview("Settings") {
    SettingsView(viewModel: ParentalControlViewModel())
        .environmentObject(AuthenticationManager())
}

#Preview("About") {
    AboutView()
}

