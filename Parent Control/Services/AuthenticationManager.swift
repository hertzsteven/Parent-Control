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
    
    /// Logout and clear stored credentials
    func logout() {
        token = nil
        authenticatedUser = nil
        isAuthenticated = false
        clearKeychain()
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
    
    /// Load authentication data from Keychain
    private func loadPersistedAuth() {
        // Load token
        guard let token = loadFromKeychain(key: tokenKey) else {
            isAuthenticated = false
            return
        }
        
        // Load user data
        if let userString = loadFromKeychain(key: userKey),
           let userData = userString.data(using: .utf8),
           let user = try? JSONDecoder().decode(AuthenticatedUser.self, from: userData) {
            self.token = token
            self.authenticatedUser = user
            self.isAuthenticated = true
            
            #if DEBUG
            print("✅ Loaded persisted authentication for: \(user.name)")
            #endif
        } else {
            // Token exists but user data is corrupted, clear everything
            clearKeychain()
            isAuthenticated = false
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

