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
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 20)
                
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

