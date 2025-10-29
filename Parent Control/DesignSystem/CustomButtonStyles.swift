//
//  CustomButtonStyles.swift
//  Parent Control
//
//  Created by Steven Hertz on 10/28/25.
//

import SwiftUI

// MARK: - Access Control Button Style
/// Button style for the +/- access control buttons with smooth press animation
struct AccessControlButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.85 : 1.0)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Navigation Link Button Style
/// Button style for navigation links with subtle press feedback
struct NavigationLinkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions
extension ButtonStyle where Self == AccessControlButtonStyle {
    /// Access control button style for +/- buttons
    static var accessControl: AccessControlButtonStyle {
        AccessControlButtonStyle()
    }
}

extension ButtonStyle where Self == NavigationLinkButtonStyle {
    /// Navigation link button style for card taps
    static var navigationLink: NavigationLinkButtonStyle {
        NavigationLinkButtonStyle()
    }
}

