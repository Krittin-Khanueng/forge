import SwiftUI

struct EnvironmentsView: View {
    @Bindable var service: EnvironmentService
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
            .padding(.top, ForgeTheme.Spacing.m)

            if service.isLoading {
                LoadingState("Loading environments...")
                    .frame(maxHeight: .infinity)
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
                ErrorState(message: error) {
                    Task { await service.refresh() }
                }
                .padding(ForgeTheme.Spacing.l)
            }
        }
        .navigationTitle("Environments")
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await service.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(service.isLoading)
            }
        }
        .task {
            await service.loadIfNeeded()
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
                EmptyState(
                    icon: kind.systemImage,
                    title: "No \(kind.displayName) Versions",
                    subtitle: "No installed versions found for this runtime."
                )
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
                        HStack(spacing: ForgeTheme.Spacing.s) {
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
                .padding(.vertical, ForgeTheme.Spacing.m)
            }

            if let note = sourceNote {
                HStack {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.leading)
                }
                .padding(.bottom, ForgeTheme.Spacing.xs)
            }
        }
    }

    private func activeBanner(runtime: RuntimeInfo) -> some View {
        HStack {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(ForgeTheme.Palette.forgeGreen)
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
        .padding(.vertical, ForgeTheme.Spacing.m)
        .background(ForgeTheme.Palette.forgeGreen.opacity(0.08))
    }

    private func emptyDriverView(kind: RuntimeKind, hint: String) -> some View {
        EmptyState(
            icon: kind.systemImage,
            title: "No \(kind.displayName) Manager Detected",
            subtitle: hint
        )
    }
}
