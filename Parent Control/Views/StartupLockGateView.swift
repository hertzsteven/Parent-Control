import SwiftUI

/// Covers the device screen while the version 4 lock check is still trying.
///
/// Startup waits for `TeacherProfileLockClient.currentLock` (`GET /teacher/profiles`)
/// before continuing not because of a hang concern, but because the result may
/// take a moment and may show the device is locked. If startup did not wait,
/// that locked state would be missed. The wait is what makes the correct answer visible.
/// Eight failed tries take this cover down.
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
