import SwiftUI

/// Covers the device screen until the version 4 lock check answers.
///
/// Startup waits for `TeacherProfileLockClient.currentLock` (`GET /teacher/profiles`)
/// before continuing not because of a hang concern, but because the result may
/// take a moment and may show the device is locked. If startup did not wait,
/// that locked state would be missed. The wait is what makes the correct answer visible.
struct StartupLockGateView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ProgressView()
            Text("Checking whether this device is locked")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
    }
}
