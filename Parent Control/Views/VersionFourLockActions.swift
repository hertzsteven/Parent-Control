import SwiftUI

/// Version 4 lock and lock-check controls. They do not replace tap-to-lock or Unlock.
struct VersionFourLockActions: View {
    let device: Device
    let apps: [AppItem]
    let token: () -> String?
    var onOwnerMissing: () -> Void

    @State private var model = VersionFourLockModel()

    private var lockableApps: [AppItem] {
        apps.filter { $0.bundleId?.isEmpty == false }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Menu("Lock with v4", systemImage: "lock.fill") {
                    if lockableApps.isEmpty {
                        Button("No app with a bundle id") {}
                            .disabled(true)
                    } else {
                        ForEach(lockableApps) { app in
                            Button(app.title) {
                                lock(app)
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.isWorking)

                Button("Check lock", systemImage: "lock.shield", action: checkLock)
                    .buttonStyle(.bordered)
                    .disabled(model.isWorking)
            }
            if model.isWorking {
                ProgressView("Contacting Jamf School")
            }
            if !model.statusMessage.isEmpty {
                Text(model.statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    private func lock(_ app: AppItem) {
        guard let ownerId = device.ownerId, device.hasOwner else {
            onOwnerMissing()
            return
        }
        guard let bundleId = app.bundleId else { return }
        Task {
            await model.lock(
                ownerId: ownerId,
                bundleId: bundleId,
                appName: app.title,
                token: token()
            )
        }
    }

    private func checkLock() {
        guard let ownerId = device.ownerId, device.hasOwner else {
            onOwnerMissing()
            return
        }
        Task {
            await model.check(ownerId: ownerId, token: token())
        }
    }
}
