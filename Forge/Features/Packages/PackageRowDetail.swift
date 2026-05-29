import SwiftUI

struct PackageRowDetail: View {
    let package: Package
    var isUpdating = false
    var isUninstalling = false
    var canUpdate = true
    var canUninstall = true
    var updateError: String?
    var onUpdate: @MainActor () -> Void = {}
    var onUninstall: @MainActor () -> Void = {}

    @State private var isConfirmingUninstall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ForgeTheme.Spacing.l) {
                VStack(alignment: .leading, spacing: ForgeTheme.Spacing.xs) {
                    Text(package.name)
                        .font(ForgeTheme.Font.compactTitle)
                    Label(package.manager.displayName, systemImage: package.manager.systemImage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                if let description = package.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: ForgeTheme.Spacing.xs) {
                        Text("Description")
                            .font(ForgeTheme.Font.section)
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                Card {
                    VStack(alignment: .leading, spacing: ForgeTheme.Spacing.s) {
                        Text("Version")
                            .font(ForgeTheme.Font.section)
                        HStack {
                            Text("Installed:")
                                .foregroundStyle(.secondary)
                            Text(package.installedVersion ?? "—")
                        }
                        .font(.body)
                        HStack {
                            Text("Latest:")
                                .foregroundStyle(.secondary)
                            Text(package.latestVersion ?? "—")
                        }
                        .font(.body)
                        StatusBadge(status: package.status)
                    }
                }

                if let homepage = package.homepage {
                    VStack(alignment: .leading, spacing: ForgeTheme.Spacing.xs) {
                        Text("Homepage")
                            .font(ForgeTheme.Font.section)
                        Link(destination: homepage) {
                            Label(homepage.absoluteString, systemImage: "arrow.up.forward")
                                .font(.body)
                                .lineLimit(1)
                        }
                    }
                }

                if let installPath = package.installPath {
                    VStack(alignment: .leading, spacing: ForgeTheme.Spacing.xs) {
                        Text("Install Path")
                            .font(ForgeTheme.Font.section)
                        Text(installPath)
                            .font(ForgeTheme.Font.mono)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                VStack(spacing: ForgeTheme.Spacing.s) {
                    PrimaryButton(
                        label: isUpdating ? "Updating" : "Update",
                        systemImage: "arrow.triangle.2.circlepath",
                        isLoading: isUpdating,
                        action: onUpdate
                    )
                    .disabled(!canUpdate || !package.isOutdated || isUpdating || isUninstalling)

                    SecondaryButton(
                        label: isUninstalling ? "Uninstalling" : "Uninstall",
                        systemImage: "trash",
                        action: { isConfirmingUninstall = true }
                    )
                    .disabled(!canUninstall || isUpdating || isUninstalling)
                }

                if !canUpdate || !canUninstall {
                    Text("This package manager is not currently available.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let updateError {
                    ErrorState(message: updateError, retryAction: nil)
                }
            }
            .padding(ForgeTheme.Spacing.l)
        }
        .confirmationDialog(
            "Uninstall \(package.name)?",
            isPresented: $isConfirmingUninstall,
            titleVisibility: .visible
        ) {
            Button("Uninstall", role: .destructive, action: onUninstall)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove the package using \(package.manager.displayName).")
        }
    }
}
