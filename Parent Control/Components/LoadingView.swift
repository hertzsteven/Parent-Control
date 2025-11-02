//
//  LoadingView.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/29/25.
//

import SwiftUI

/// Animated loading view with app icon pulse animation
struct LoadingView: View {
    let message: String
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    
    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated app icon
                Image("appIconImage")
//                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .shadow(color: .pink.opacity(0.3), radius: 20)
                
                Text(message)
                    .font(AppTheme.Typography.childName)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                scale = 1.15
                opacity = 1.0
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LoadingView(message: "Loading devices...")
}

