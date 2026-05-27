import SwiftUI

struct PackageRowDetail: View {
    let package: Package

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
                    Button {
                    } label: {
                        Label("Update", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(true)

                    Button(role: .destructive) {
                    } label: {
                        Label("Uninstall", systemImage: "trash")
                    }
                    .disabled(true)
                }
            }
            .padding()
        }
    }
}
