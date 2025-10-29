//
//  AppIconView.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import SwiftUI

/// Standardized app icon display component with consistent styling
/// Supports both URL-based icons from API and SF Symbol fallbacks
struct AppIconView: View {
    let iconName: String
    let iconURL: String?
    let size: CGFloat
    
    init(iconName: String, iconURL: String? = nil, size: CGFloat = 50) {
        self.iconName = iconName
        self.iconURL = iconURL
        self.size = size
    }
    
    var body: some View {
        if let iconURL = iconURL, let url = URL(string: iconURL) {
            // Use actual app icon from API
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .cornerRadius(size * 0.2) // Rounded corners like iOS app icons
                case .failure(let error):
                    // Log error and fallback to SF Symbol
                    let _ = print("🖼️ Failed to load icon from \(url): \(error.localizedDescription)")
                    fallbackIcon
                case .empty:
                    // Show placeholder while loading
                    ProgressView()
                        .frame(width: size, height: size)
                @unknown default:
                    fallbackIcon
                }
            }
        } else {
            // Use SF Symbol as fallback
            fallbackIcon
        }
    }
    
    private var fallbackIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(AppTheme.Colors.cardBackground)
                .frame(width: size, height: size)
            
            Image(systemName: iconName)
                .font(.system(size: size * 0.5))
                .foregroundColor(AppTheme.Colors.primary)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        AppIconView(iconName: "star.fill")
        AppIconView(iconName: "play.rectangle.fill", size: 40)
        AppIconView(iconName: "safari", size: 60)
    }
    .padding()
    .background(AppTheme.Colors.background)
}

