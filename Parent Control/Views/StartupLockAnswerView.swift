import SwiftUI

/// Shows the startup lock answer once `GET /teacher/profiles` has returned.
/// This is separate from the Check lock button, which still runs its own read.
struct StartupLockAnswerView: View {
    let status: TeacherProfileLockStatus

    var body: some View {
        Text(status.summary)
            .font(.subheadline)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.sm)
            .accessibilityIdentifier("startupLockAnswer")
    }
}
