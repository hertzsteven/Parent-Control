//
//  NetworkWaitingView.swift
//  Parent Control
//
//  View displayed while waiting for network connectivity during app startup.
//

import SwiftUI

/// A view that shows a waiting indicator while the app waits for network connectivity
struct NetworkWaitingView: View {
    @ObservedObject private var reachability = NetworkReachabilityService.shared
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Network icon with animation
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .symbolEffect(.pulse, options: .repeating)
            
            // Title
            Text("Waiting for Network")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Status message
            Text("Connecting to the internet...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Progress indicator
            ProgressView()
                .scaleEffect(1.2)
                .padding(.top, 8)
            
            // Attempt counter (if available)
            if reachability.maxAttempts > 0 {
                Text("Attempt \(reachability.currentAttempt) of \(reachability.maxAttempts)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            // Info text at bottom
            Text("The app will continue automatically\nonce connected to the internet.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    NetworkWaitingView()
}
