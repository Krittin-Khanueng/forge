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
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(package.manager.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                if let description = package.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.headline)
                        Text(description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Version")
                        .font(.headline)
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
                }

                if let homepage = package.homepage {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Homepage")
                            .font(.headline)
                        Link(destination: homepage) {
                            Label(homepage.absoluteString, systemImage: "arrow.up.forward")
                                .font(.body)
                                .lineLimit(1)
                        }
                    }
                }

                if let installPath = package.installPath {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Install Path")
                            .font(.headline)
                        Text(installPath)
                            .font(.body.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                HStack(spacing: 12) {
                    Button(action: onUpdate) {
                        if isUpdating {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        }
                        Label(isUpdating ? "Updating" : "Update", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(!canUpdate || isUpdating)

                    Button(role: .destructive) {
                        isConfirmingUninstall = true
                    } label: {
                        if isUninstalling {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        }
                        Label(isUninstalling ? "Uninstalling" : "Uninstall", systemImage: "trash")
                    }
                    .disabled(!canUninstall || isUpdating || isUninstalling)
                }

                if !canUpdate || !canUninstall {
                    Text("This package manager is not currently available.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let updateError {
                    Text(updateError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .padding()
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
