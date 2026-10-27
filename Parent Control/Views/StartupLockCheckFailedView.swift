import SwiftUI

/// Shown after the startup lock check stops trying.
/// The checking cover is already gone. Try again starts a fresh wait.
struct StartupLockCheckFailedView: View {
    let onTryAgain: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("The lock could not be checked.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Button("Try again", action: onTryAgain)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.sm)
        .accessibilityIdentifier("startupLockCheckFailed")
    }
}
