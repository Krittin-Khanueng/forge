import SwiftUI

struct PackagesView: View {
    @State private var viewModel = PackagesViewModel()
    @State private var showInspector = false
    @State private var selectedPackageID: String?
    @State private var selectedPackage: Package?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.packages.isEmpty {
                loadingView
            } else if let _ = viewModel.error, viewModel.packages.isEmpty {
                errorView
            } else if viewModel.filteredPackages.isEmpty {
                emptyView
            } else {
                packagesTable
            }
        }
        .inspector(isPresented: $showInspector) {
            if let selectedPackage {
                PackageRowDetail(package: selectedPackage)
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
        .searchable(text: $viewModel.searchText, prompt: "Search packages...")
        .task {
            await viewModel.load()
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
                subtitle: "No packages found. Install some via Homebrew."
            )
        } else {
            EmptyState(
                icon: "magnifyingglass",
                title: "No Results",
                subtitle: "No packages match \"\(viewModel.searchText)\""
            )
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
            selectedPackage = viewModel.filteredPackages.first { $0.id == newID }
            showInspector = newID != nil
        }
    }
}
