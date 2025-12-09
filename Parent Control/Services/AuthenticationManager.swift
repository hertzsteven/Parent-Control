//
//  AuthenticationManager.swift
//  Parent Control
//
//  Manages teacher authentication state and token persistence
//

import Foundation
import Security

/// Manages teacher authentication state and secure token storage
class AuthenticationManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published var token: String?
    @Published var isAuthenticated: Bool = false
    @Published var authenticatedUser: AuthenticatedUser?
    @Published var isValidating: Bool = false
    @Published var isVoluntaryLogout: Bool = false
    
    // Store previous auth state for canceling voluntary logout
    private var previousToken: String?
    private var previousUser: AuthenticatedUser?
    
    // MARK: - Keychain Keys
    
    private let tokenKey = "teacherAuthToken"
    private let userKey = "teacherAuthUser"
    private let keychainService = "com.parentcontrol.teacher"
    
    // MARK: - Initialization
    
    init() {
        loadPersistedAuth()
    }
    
    // MARK: - Public Methods
    
    /// Authenticate teacher and save token
    func authenticate(company: String, username: String, password: String) async throws {
        let networkService = NetworkService()
        let response = try await networkService.authenticateTeacher(
            company: company,
            username: username,
            password: password
        )
        
        // Update state on main thread
        await MainActor.run {
            self.token = response.token
            self.authenticatedUser = response.authenticatedAs
            self.isAuthenticated = true
            
            // Persist to Keychain
            saveToKeychain()
        }
    }
    
    /// Validate the current token with the server
    /// - Returns: True if token is valid, false otherwise
    func validateCurrentToken() async -> Bool {
        guard let token = token else {
            return false
        }
        
        await MainActor.run {
            isValidating = true
        }
        
        defer {
            Task { @MainActor in
                isValidating = false
            }
        }
        
        do {
            let networkService = NetworkService()
            let response = try await networkService.validateToken(token)
            
            // Check if validation was successful
            let isValid = response.code == 200 && response.message == "ValidToken"
            
            #if DEBUG
            print(isValid ? "✅ Token validated successfully" : "❌ Token validation failed: \(response.message)")
            #endif
            
            return isValid
            
        } catch {
            #if DEBUG
            print("⚠️ Token validation error: \(error.localizedDescription)")
            print("   Allowing access with cached token (network may be unavailable)")
            #endif
            // On network error, allow access with cached token (graceful degradation)
            return true
        }
    }
    
    /// Logout and clear stored credentials
    /// - Parameter isVoluntary: True if user manually logged out (e.g., via switch user), false if forced logout
    func logout(isVoluntary: Bool = false) {
        if isVoluntary {
            // Store current auth state for potential restore on cancel
            previousToken = token
            previousUser = authenticatedUser
            isVoluntaryLogout = true  // Set this FIRST so sheet appears immediately
        }
        
        token = nil
        authenticatedUser = nil
        isAuthenticated = false
        isValidating = false
        
        if !isVoluntary {
            isVoluntaryLogout = false
            // Only clear Keychain for forced logout
            clearKeychain()
        }
    }
    
    /// Restore previous authentication state (for canceling voluntary logout)
    func restorePreviousAuth() {
        if let previousToken = previousToken, let previousUser = previousUser {
            token = previousToken
            authenticatedUser = previousUser
            isAuthenticated = true
            isVoluntaryLogout = false
            // Clear stored previous state
            self.previousToken = nil
            self.previousUser = nil
        }
    }
    
    // MARK: - Keychain Methods
    
    /// Save authentication data to Keychain
    private func saveToKeychain() {
        guard let token = token,
              let authenticatedUser = authenticatedUser else { return }
        
        // Save token
        saveToKeychain(key: tokenKey, value: token)
        
        // Save user data as JSON
        if let userData = try? JSONEncoder().encode(authenticatedUser),
           let userString = String(data: userData, encoding: .utf8) {
            saveToKeychain(key: userKey, value: userString)
        }
    }
    
    /// Load authentication data from Keychain and validate token
    private func loadPersistedAuth() {
        // Load token
        guard let token = loadFromKeychain(key: tokenKey) else {
            isAuthenticated = false
            return
        }
        
        // Load user data
        guard let userString = loadFromKeychain(key: userKey),
              let userData = userString.data(using: .utf8),
              let user = try? JSONDecoder().decode(AuthenticatedUser.self, from: userData) else {
            // Token exists but user data is corrupted, clear everything
            clearKeychain()
            isAuthenticated = false
            return
        }
        
        // Set token, user, and authenticated immediately (trust cached credentials)
        self.token = token
        self.authenticatedUser = user
        self.isAuthenticated = true  // Set to true immediately to prevent login screen flash
        
        #if DEBUG
        print("✅ Loaded persisted authentication for: \(user.name)")
        print("🔍 Waiting for network before validating token...")
        #endif
        
        // Validate token asynchronously in background (with network wait)
        Task {
            // Wait for network connectivity before validating token
            // This is critical for Single App Mode where app launches before network is ready
            let reachability = NetworkReachabilityService.shared
            let hasNetwork = await reachability.waitForConnectivity(timeout: 30, retryInterval: 2)
            
            guard hasNetwork else {
                #if DEBUG
                print("⚠️ No network available - using cached credentials without validation")
                #endif
                await MainActor.run {
                    self.isValidating = false
                }
                return  // Keep cached auth, skip validation
            }
            
            #if DEBUG
            print("🌐 Network available - validating token with server...")
            #endif
            
            let isValid = await validateCurrentToken()
            
            await MainActor.run {
                if isValid {
                    // Token is valid, already authenticated
                    #if DEBUG
                    print("✅ Token validation successful - user remains authenticated")
                    #endif
                } else {
                    // Token is invalid, clear everything and force re-login
                    #if DEBUG
                    print("❌ Token validation failed - clearing credentials")
                    #endif
                    self.logout()
                }
            }
        }
    }
    
    /// Clear all authentication data from Keychain
    private func clearKeychain() {
        deleteFromKeychain(key: tokenKey)
        deleteFromKeychain(key: userKey)
    }
    
    // MARK: - Keychain Helper Methods
    
    /// Save a string value to Keychain
    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        // Delete any existing item first
        deleteFromKeychain(key: key)
        
        // Create new keychain item
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        #if DEBUG
        if status != errSecSuccess {
            print("⚠️ Failed to save to Keychain: \(status)")
        }
        #endif
    }
    
    /// Load a string value from Keychain
    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    /// Delete a value from Keychain
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

