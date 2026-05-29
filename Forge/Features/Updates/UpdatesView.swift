import SwiftUI

struct UpdatesView: View {
    @Bindable var viewModel: UpdatesViewModel
    @State private var isConfirmingUpdateAll = false
    @State private var confirmingManager: PackageManagerKind?

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, ForgeTheme.Spacing.xl)
                .padding(.vertical, ForgeTheme.Spacing.l)

            Divider()

            Group {
                if viewModel.isLoading && viewModel.totalOutdated == 0 {
                    LoadingState("Checking for updates...")
                } else if viewModel.totalOutdated == 0 {
                    emptyView
                } else {
                    updatesList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if let error = viewModel.error, viewModel.totalOutdated > 0 {
                ErrorState(message: error) {
                    Task { await viewModel.refresh() }
                }
                .padding(ForgeTheme.Spacing.l)
            }
        }
        .navigationTitle("Updates")
        .task {
            await viewModel.loadIfNeeded()
        }
        .confirmationDialog(
            "Update All Outdated Packages?",
            isPresented: $isConfirmingUpdateAll,
            titleVisibility: .visible
        ) {
            Button("Update All \(viewModel.totalOutdated) Packages") {
                Task { await viewModel.updateAllOutdated() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will update \(viewModel.totalOutdated) outdated packages across all detected package managers.")
        }
        .confirmationDialog(
            "Update All \(confirmingManager?.displayName ?? "") Packages?",
            isPresented: Binding(
                get: { confirmingManager != nil },
                set: { if !$0 { confirmingManager = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let kind = confirmingManager {
                let count = viewModel.outdatedByManager[kind]?.count ?? 0
                Button("Update All \(count) Packages") {
                    Task { await viewModel.updateAll(for: kind) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let kind = confirmingManager {
                Text("This will update all outdated \(kind.displayName) packages.")
            }
        }
    }

    private var header: some View {
        HStack(spacing: ForgeTheme.Spacing.m) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Updates")
                    .font(.title2.weight(.semibold))
                Text("\(viewModel.totalOutdated) packages available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let error = viewModel.error, viewModel.totalOutdated == 0 {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(ForgeTheme.Palette.forgeRed)
                    .lineLimit(2)
                    .frame(maxWidth: 360, alignment: .trailing)
            }

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading || viewModel.isRefreshing || viewModel.isUpdating)

            Button {
                isConfirmingUpdateAll = true
            } label: {
                Label("Update All", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.totalOutdated == 0 || viewModel.isUpdating)
        }
    }

    private var emptyView: some View {
        VStack(spacing: ForgeTheme.Spacing.l) {
            if let error = viewModel.error {
                ErrorState(message: error) {
                    Task { await viewModel.refresh() }
                }
            } else {
                EmptyState(
                    icon: "checkmark.seal",
                    title: "Everything Updated",
                    subtitle: "No outdated packages were found.",
                    actionLabel: "Refresh"
                ) {
                    Task { await viewModel.refresh() }
                }
            }
        }
    }

    private var updatesList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: ForgeTheme.Spacing.xl) {
                ForEach(viewModel.managerSections, id: \.kind) { section in
                    managerSection(kind: section.kind, packages: section.packages)
                }
            }
            .padding(ForgeTheme.Spacing.xxl)
            .animation(.easeInOut(duration: 0.25), value: viewModel.totalOutdated)
        }
    }

    private func managerSection(kind: PackageManagerKind, packages: [Package]) -> some View {
        VStack(alignment: .leading, spacing: ForgeTheme.Spacing.m) {
            HStack {
                Label(kind.displayName, systemImage: kind.systemImage)
                    .font(.headline)

                Text("\(packages.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: Capsule())

                Spacer()

                Button {
                    confirmingManager = kind
                } label: {
                    HStack(spacing: ForgeTheme.Spacing.s) {
                        if viewModel.updatingManagers.contains(kind) {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        }
                        Text(viewModel.updatingManagers.contains(kind) ? "Updating" : "Update All")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isUpdating)
            }

            LazyVStack(spacing: ForgeTheme.Spacing.s) {
                ForEach(packages) { package in
                    updateRow(package)
                }
            }
        }
    }

    private func updateRow(_ package: Package) -> some View {
        Card(padding: ForgeTheme.Spacing.m) {
            HStack(spacing: ForgeTheme.Spacing.m) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.name)
                        .font(.body.weight(.medium))
                    HStack(spacing: 6) {
                        Text(package.installedVersion ?? "Unknown")
                        Image(systemName: "arrow.right")
                            .font(.caption)
                        Text(package.latestVersion ?? "Latest")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task { await viewModel.update(package) }
                } label: {
                    HStack(spacing: ForgeTheme.Spacing.s) {
                        if viewModel.isUpdating(package) {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        }
                        Text(viewModel.isUpdating(package) ? "Updating" : "Update")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isUpdating)
            }
        }
    }
}
