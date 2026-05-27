import SwiftUI

struct UpdatesView: View {
    @Bindable var viewModel: UpdatesViewModel

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
                    .foregroundStyle(.red)
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
                Task { await viewModel.updateAllOutdated() }
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
            .padding(ForgeTheme.Spacing.xl)
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
                    Task { await viewModel.updateAll(for: kind) }
                } label: {
                    if viewModel.updatingManagers.contains(kind) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    }
                    Text(viewModel.updatingManagers.contains(kind) ? "Updating" : "Update All")
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
                    if viewModel.isUpdating(package) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    }
                    Text(viewModel.isUpdating(package) ? "Updating" : "Update")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isUpdating)
            }
        }
    }
}
