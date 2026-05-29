import SwiftUI

struct PackagesView: View {
    @Bindable var viewModel: PackagesViewModel
    @State private var showInspector = false
    @State private var selectedPackageID: String?
    @State private var selectedPackage: Package?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.packages.isEmpty {
                SkeletonTable()
            } else if let _ = viewModel.error, viewModel.packages.isEmpty {
                errorView
            } else if viewModel.filteredPackages.isEmpty {
                emptyView
            } else {
                packagesTable
                    .overlay(alignment: .top) {
                        if viewModel.isLoading && !viewModel.packages.isEmpty {
                            ProgressView()
                                .controlSize(.small)
                                .padding(.top, ForgeTheme.Spacing.s)
                                .accessibilityLabel("Refreshing packages")
                        }
                    }
            }
        }
        .inspector(isPresented: $showInspector) {
            if let selectedPackage {
                PackageRowDetail(
                    package: selectedPackage,
                    isUpdating: viewModel.isUpdating(selectedPackage),
                    isUninstalling: viewModel.isUninstalling(selectedPackage),
                    canUpdate: viewModel.canUpdate(selectedPackage),
                    canUninstall: viewModel.canUninstall(selectedPackage),
                    updateError: viewModel.updateError,
                    onUpdate: {
                        Task {
                            await viewModel.update(selectedPackage)
                            syncSelectedPackage()
                        }
                    },
                    onUninstall: {
                        Task {
                            await viewModel.uninstall(selectedPackage)
                            syncSelectedPackage()
                        }
                    }
                )
            }
        }
        .inspectorColumnWidth(min: 240, ideal: 280, max: 360)
        .toolbar {
            ToolbarItemGroup {
                Picker("Manager", selection: $viewModel.selectedManager) {
                    Text("All").tag(PackageManagerKind?.none)
                    ForEach(PackageManagerRegistry.shared.detectedKinds, id: \.self) { kind in
                        Label(kind.displayName, systemImage: kind.systemImage)
                            .tag(PackageManagerKind?.some(kind))
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .searchable(text: Binding(
            get: { viewModel.searchText },
            set: { viewModel.setSearchText($0) }
        ), prompt: "Search packages")
        .navigationTitle("Packages")
        .task {
            await viewModel.loadIfNeeded()
        }
        .onChange(of: viewModel.packageCount) { _, _ in
            syncSelectedPackage()
        }
    }

    @ViewBuilder
    private var loadingView: some View {
        LoadingState("Loading packages...")
    }

    @ViewBuilder
    private var errorView: some View {
        ErrorState(message: viewModel.error ?? "An unknown error occurred") {
            Task { await viewModel.refresh() }
        }
    }

    @ViewBuilder
    private var emptyView: some View {
        if viewModel.searchText.isEmpty {
            EmptyState(
                icon: "shippingbox",
                title: "No Packages",
                subtitle: "No packages were found. Install a package manager like Homebrew, npm, or Cargo to get started.",
                actionLabel: "Refresh"
            ) {
                Task { await viewModel.refresh() }
            }
        } else {
            EmptyState(
                icon: "magnifyingglass",
                title: "No Results",
                subtitle: "No packages match \"\(viewModel.searchText)\". Try a different search term.",
                actionLabel: "Clear Search"
            ) {
                viewModel.setSearchText("")
            }
        }
    }

    @ViewBuilder
    private var packagesTable: some View {
        Table(viewModel.filteredPackages, selection: $selectedPackageID) {
            TableColumn("Name") { pkg in
                HStack(spacing: 6) {
                    Image(systemName: pkg.manager.systemImage)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    Text(pkg.name)
                        .fontWeight(.medium)
                }
            }
            TableColumn("Version") { pkg in
                Text(pkg.installedVersion ?? "—")
                    .foregroundStyle(pkg.installedVersion != nil ? .primary : .secondary)
            }
            .width(100)
            TableColumn("Latest") { pkg in
                Text(pkg.latestVersion ?? "—")
            }
            .width(100)
            TableColumn("Manager") { pkg in
                Label(pkg.manager.displayName, systemImage: pkg.manager.systemImage)
                    .labelStyle(.titleAndIcon)
            }
            .width(110)
            TableColumn("Status") { pkg in
                StatusBadge(status: pkg.status)
            }
            .width(100)
        }
        .onChange(of: selectedPackageID) { _, newID in
            syncSelectedPackage()
            showInspector = newID != nil
        }
    }

    private func syncSelectedPackage() {
        guard let selectedPackageID else {
            selectedPackage = nil
            return
        }
        selectedPackage = viewModel.filteredPackages.first { $0.id == selectedPackageID }
        if selectedPackage == nil {
            showInspector = false
            self.selectedPackageID = nil
        }
    }
}
