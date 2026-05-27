import SwiftUI

struct EnvironmentsView: View {
    @State private var service = EnvironmentService()
    @State private var showInstallSheet = false
    @State private var installKind: RuntimeKind = .python

    var body: some View {
        VStack(spacing: 0) {
            Picker("Runtime", selection: $service.selectedTab) {
                ForEach(RuntimeKind.allCases, id: \.self) { kind in
                    Label(kind.displayName, systemImage: kind.systemImage).tag(kind)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)

            if service.isLoading {
                LoadingState("Loading environments...")
                    .padding(.top, 80)
            } else {
                switch service.selectedTab {
                case .python:
                    runtimeList(runtimes: service.pythonRuntimes, kind: .python, driverAvailable: !service.pythonRuntimes.isEmpty, driverHint: "Install uv: `brew install uv`")
                case .node:
                    runtimeList(runtimes: service.nodeRuntimes, kind: .node, driverAvailable: service.nodeSource != "none", driverHint: "Install fnm: `brew install fnm`", sourceNote: service.nodeSource != "none" ? "Using \(service.nodeSource)" : nil)
                case .rust:
                    runtimeList(runtimes: service.rustToolchains, kind: .rust, driverAvailable: !service.rustToolchains.isEmpty, driverHint: "Install rustup: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`")
                case .bun:
                    runtimeList(runtimes: service.bunVersions, kind: .bun, driverAvailable: !service.bunVersions.isEmpty, driverHint: "Install Bun: `curl -fsSL https://bun.sh/install | bash`", singleVersion: true)
                }
            }

            if let error = service.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
            }
        }
        .task {
            await service.refresh()
        }
        .sheet(isPresented: $showInstallSheet) {
            InstallVersionSheet(kind: installKind) { version in
                showInstallSheet = false
                Task {
                    try? await service.install(version: version, kind: installKind)
                }
            }
        }
    }

    private func runtimeList(runtimes: [RuntimeInfo], kind: RuntimeKind, driverAvailable: Bool, driverHint: String, sourceNote: String? = nil, singleVersion: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !driverAvailable {
                emptyDriverView(kind: kind, hint: driverHint)
            } else if runtimes.isEmpty {
                ContentUnavailableView("No \(kind.displayName) Versions", systemImage: kind.systemImage, description: Text("No installed versions found"))
                    .padding(.top, 60)
            } else {
                if let active = runtimes.first(where: \.isActive) {
                    activeBanner(runtime: active)
                }

                Table(runtimes) {
                    TableColumn("Version", value: \.version)
                    TableColumn("Source", value: \.source)
                    TableColumn("Path") { runtime in
                        if let path = runtime.path {
                            Text(path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        } else {
                            Text("—")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    TableColumn("") { runtime in
                        HStack(spacing: 8) {
                            if !runtime.isActive {
                                IconButton(systemImage: "checkmark.circle", tooltip: "Make Active") {
                                    Task { try? await service.setActive(runtime) }
                                }
                            }
                            if !singleVersion {
                                IconButton(systemImage: "trash", tooltip: "Uninstall") {
                                    Task { try? await service.uninstall(runtime) }
                                }
                            }
                        }
                    }
                    .width(singleVersion ? 50 : 100)
                }
            }

            if driverAvailable {
                HStack {
                    PrimaryButton(label: "Install \(kind.displayName) Version", systemImage: "plus") {
                        installKind = kind
                        showInstallSheet = true
                    }
                    .frame(width: 220)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }

            if let note = sourceNote {
                HStack {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.leading)
                }
                .padding(.bottom, 4)
            }
        }
    }

    private func activeBanner(runtime: RuntimeInfo) -> some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Text("Active: \(runtime.kind.displayName) \(runtime.version)")
                .fontWeight(.medium)
            if let path = runtime.path {
                Text("• \(path)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.green.opacity(0.08))
    }

    private func emptyDriverView(kind: RuntimeKind, hint: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: kind.systemImage)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No \(kind.displayName) Manager Detected")
                .font(.title3)
                .fontWeight(.semibold)
            Text(hint)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}
