//
//  Parent_ControlApp.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import SwiftUI

@main
struct Parent_ControlApp: App {
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .sheet(isPresented: Binding(
                    get: { !authManager.isAuthenticated || authManager.isVoluntaryLogout },
                    set: { newValue in
                        // If sheet is dismissed during voluntary logout, restore previous auth
                        if !newValue && authManager.isVoluntaryLogout && !authManager.isAuthenticated {
                            authManager.restorePreviousAuth()
                        }
                        // Don't manually set showAuthSheet - let the binding handle it
                    }
                )) {
                    AuthenticationView()
                        .environmentObject(authManager)
                        .interactiveDismissDisabled(!authManager.isVoluntaryLogout)
                        .onDisappear {
                            // If sheet disappears during voluntary logout and user didn't authenticate
                            if authManager.isVoluntaryLogout && !authManager.isAuthenticated {
                                authManager.restorePreviousAuth()
                            }
                        }
                }
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        // If voluntary logout, show nothing (sheet will appear immediately)
        if authManager.isVoluntaryLogout {
            Color.clear  // Transparent - sheet will cover it
        } else if authManager.isValidating {
            // Show animated loading during token validation
            LoadingView(message: "Validating credentials...")
        } else if authManager.isAuthenticated {
            DeviceSelectionView()
            // Uncomment below for testing API directly
            // TestingView()
        } else {
            // Placeholder while authentication sheet is shown
            LoadingView(message: "Authenticating...")
        }
    }
}

// MARK: - Authentication View

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isAuthenticating = false
    @State private var errorMessage: String?
    
    private var showCancel: Bool {
        authManager.isVoluntaryLogout
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // App logo/title
                VStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                    
                    Text("Parent Control")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Teacher Authentication Required")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Input fields
                VStack(spacing: 20) {
                    // Username field
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        TextField("Username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .disabled(isAuthenticating)
                    }
                    
                    // Password field
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(isAuthenticating)
                    }
                }
                .padding(.horizontal, 40)
                
                // Error message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Authenticate button
                Button {
                    Task {
                        await authenticate()
                    }
                } label: {
                    if isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    } else {
                        Text("Sign In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .background(username.isEmpty || password.isEmpty || isAuthenticating ? Color.gray : Color.pink)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(username.isEmpty || password.isEmpty || isAuthenticating)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showCancel {
                    ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        // Restore previous authentication state
                        authManager.restorePreviousAuth()
                    }
                        .disabled(isAuthenticating)
                    }
                }
            }
        }
    }
    
    private func authenticate() async {
        isAuthenticating = true
        errorMessage = nil
        
        do {
            try await authManager.authenticate(
                company: "2001128",
                username: username,
                password: password
            )
            
            // Clear password for security
            password = ""
            // Clear voluntary logout flag after successful authentication
            authManager.isVoluntaryLogout = false
            
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
        }
        
        isAuthenticating = false
    }
}
