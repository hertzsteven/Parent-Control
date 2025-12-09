//
//  NetworkReachabilityService.swift
//  Parent Control
//
//  Monitors network connectivity and provides async waiting for network availability.
//  Essential for Single App Mode where the app launches before network is ready.
//

import Foundation
import Network
import Combine

/// Service that monitors network reachability using NWPathMonitor
/// Provides async methods to wait for network connectivity with configurable timeouts
@MainActor
final class NetworkReachabilityService: ObservableObject {
    // MARK: - Singleton
    
    /// Shared instance for app-wide network monitoring
    static let shared = NetworkReachabilityService()
    
    // MARK: - Published Properties
    
    /// Current network connectivity status
    @Published private(set) var isConnected: Bool = false
    
    /// Whether we're currently waiting for network (true if any wait is active)
    var isWaitingForNetwork: Bool {
        activeWaitCount > 0
    }
    
    /// Current wait attempt number (for UI feedback)
    @Published private(set) var currentAttempt: Int = 0
    
    /// Maximum number of attempts (for UI feedback)
    @Published private(set) var maxAttempts: Int = 0
    
    // MARK: - Private Properties
    
    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.parentcontrol.networkmonitor")
    private var hasStartedMonitoring = false
    
    /// Count of concurrent wait operations (to prevent flickering)
    @Published private var activeWaitCount: Int = 0
    
    // MARK: - Initialization
    
    private init() {
        self.monitor = NWPathMonitor()
        startMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Wait for network connectivity with retry logic
    /// - Parameters:
    ///   - timeout: Maximum time to wait in seconds (default: 30)
    ///   - retryInterval: Time between connectivity checks in seconds (default: 2)
    /// - Returns: `true` if network became available, `false` if timeout reached
    func waitForConnectivity(
        timeout: TimeInterval = 30,
        retryInterval: TimeInterval = 2
    ) async -> Bool {
        // If already connected, return immediately
        if isConnected {
            #if DEBUG
            print("✅ Network already connected")
            #endif
            return true
        }
        
        let attempts = Int(timeout / retryInterval)
        
        // Only update UI state if this is the first waiter
        if activeWaitCount == 0 {
            maxAttempts = attempts
            currentAttempt = 0
        }
        activeWaitCount += 1
        
        defer {
            activeWaitCount -= 1
            if activeWaitCount == 0 {
                currentAttempt = 0
                maxAttempts = 0
            }
        }
        
        #if DEBUG
        print("🌐 Waiting for network connectivity...")
        print("   Timeout: \(timeout)s, Retry interval: \(retryInterval)s, Max attempts: \(attempts)")
        #endif
        
        for attempt in 1...attempts {
            currentAttempt = attempt
            
            #if DEBUG
            print("   Attempt \(attempt)/\(attempts)...")
            #endif
            
            // Check if connected
            if isConnected {
                #if DEBUG
                print("✅ Network connected on attempt \(attempt)")
                #endif
                return true
            }
            
            // Wait before next check
            try? await Task.sleep(nanoseconds: UInt64(retryInterval * 1_000_000_000))
            
            // Check for task cancellation
            if Task.isCancelled {
                #if DEBUG
                print("⚠️ Network wait cancelled")
                #endif
                return false
            }
        }
        
        #if DEBUG
        print("❌ Network timeout - no connection after \(timeout) seconds")
        #endif
        
        return false
    }
    
    /// Force a network status refresh
    func refresh() {
        // The monitor updates automatically, but we can restart it if needed
        if !hasStartedMonitoring {
            startMonitoring()
        }
    }
    
    // MARK: - Private Methods
    
    private func startMonitoring() {
        guard !hasStartedMonitoring else { return }
        hasStartedMonitoring = true
        
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if self.isConnected != connected {
                    self.isConnected = connected
                    
                    #if DEBUG
                    print(connected ? "🌐 Network: Connected" : "🌐 Network: Disconnected")
                    #endif
                }
            }
        }
        
        monitor.start(queue: monitorQueue)
        
        #if DEBUG
        print("🌐 NetworkReachabilityService: Started monitoring")
        #endif
    }
}
