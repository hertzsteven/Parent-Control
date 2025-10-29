//
//  ViewModifiers.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import SwiftUI

// MARK: - Card Style Modifier
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.Layout.cornerRadius)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Navigation Bar Style Modifier
struct NavigationBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.cardBackground)
    }
}

// MARK: - Child Profile Section Style Modifier
struct ChildProfileModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.sm)
    }
}

// MARK: - View Extensions
extension View {
    /// Applies card styling with background, corner radius, and shadow
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
    
    /// Applies navigation bar styling
    func navigationBarStyle() -> some View {
        modifier(NavigationBarModifier())
    }
    
    /// Applies child profile section styling
    func childProfileStyle() -> some View {
        modifier(ChildProfileModifier())
    }
}

