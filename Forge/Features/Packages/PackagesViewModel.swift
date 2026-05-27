import SwiftUI
import OSLog

@MainActor
@Observable
final class PackagesViewModel {
    var isLoading = false
    var error: String?
    var selectedManager: PackageManagerKind? = nil
    var searchText = ""
    private(set) var debouncedSearchText = ""
    var updatingPackageIDs: Set<Package.ID> = []
    var uninstallingPackageIDs: Set<Package.ID> = []
    var updateError: String?

    var packages: [Package] {
        refreshService.packages
    }

    var packageCount: Int {
        refreshService.packages.count
    }

    var filteredPackages: [Package] {
        packages.filter { pkg in
            if let manager = selectedManager, pkg.manager != manager {
                return false
            }
            if !debouncedSearchText.isEmpty {
                return pkg.name.localizedCaseInsensitiveContains(debouncedSearchText)
            }
            return true
        }
    }

    private let refreshService: PackageRefreshService
    private let registry = PackageManagerRegistry.shared
    private let cache = PackageCache(container: StorageStack.shared.container)
    private let activityRepo = ActivityRepository(container: StorageStack.shared.container)
    private let logger = Logger.ui
    private var searchDebounceTask: Task<Void, Never>?
    private var hasLoadedOnce = false

    init(refreshService: PackageRefreshService = .shared) {
        self.refreshService = refreshService
    }

    func setSearchText(_ text: String) {
        searchText = text
        searchDebounceTask?.cancel()
        if text.isEmpty {
            debouncedSearchText = ""
            return
        }
        searchDebounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            debouncedSearchText = text
        }
    }

    func loadIfNeeded() async {
        guard !hasLoadedOnce else { return }
        await load()
    }

    func load() async {
        let showFullScreenLoading = !hasLoadedOnce && packages.isEmpty
        isLoading = showFullScreenLoading
        error = nil

        refreshService.applyCachedPackages()

        defer {
            isLoading = false
            hasLoadedOnce = true
        }

        await refreshService.refreshIfNeeded()
        if let refreshError = refreshService.error {
            error = refreshError
        }
    }

    func refresh() async {
        isLoading = packages.isEmpty
        error = nil
        defer { isLoading = false }

        await refreshService.refresh(force: true)
        if let refreshError = refreshService.error {
            error = refreshError
        }
    }

    func canUpdate(_ package: Package) -> Bool {
        registry.manager(package.manager) != nil
    }

    func canUninstall(_ package: Package) -> Bool {
        registry.manager(package.manager) != nil
    }

    func isUpdating(_ package: Package) -> Bool {
        updatingPackageIDs.contains(package.id)
    }

    func isUninstalling(_ package: Package) -> Bool {
        uninstallingPackageIDs.contains(package.id)
    }

    func update(_ package: Package) async {
        guard let manager = registry.manager(package.manager) else {
            updateError = "\(package.manager.displayName) is not available."
            return
        }

        updatingPackageIDs.insert(package.id)
        updateError = nil
        defer { updatingPackageIDs.remove(package.id) }

        do {
            logger.info("Updating package: \(package.name), manager=\(package.manager.displayName)")
            try await manager.update(package.name)
            activityRepo.record(
                kind: "update",
                title: "Updated \(package.name)",
                subtitle: package.manager.displayName,
                manager: package.manager
            )
            await refreshService.refreshManager(package.manager)
        } catch {
            updateError = "Failed to update \(package.name): \(error.localizedDescription)"
            activityRepo.record(
                kind: "update_failed",
                title: "Update failed: \(package.name)",
                subtitle: error.localizedDescription,
                manager: package.manager
            )
            logger.error("Failed updating package: \(package.name), error=\(error.localizedDescription)")
        }
    }

    func uninstall(_ package: Package) async {
        guard let manager = registry.manager(package.manager) else {
            updateError = "\(package.manager.displayName) is not available."
            return
        }

        uninstallingPackageIDs.insert(package.id)
        updateError = nil
        defer { uninstallingPackageIDs.remove(package.id) }

        do {
            logger.info("Uninstalling package: \(package.name), manager=\(package.manager.displayName)")
            try await manager.uninstall(package.name)
            try? cache.remove(package)
            activityRepo.record(
                kind: "uninstall",
                title: "Uninstalled \(package.name)",
                subtitle: package.manager.displayName,
                manager: package.manager
            )
            await refreshService.refreshManager(package.manager)
        } catch {
            updateError = "Failed to uninstall \(package.name): \(error.localizedDescription)"
            activityRepo.record(
                kind: "uninstall_failed",
                title: "Uninstall failed: \(package.name)",
                subtitle: error.localizedDescription,
                manager: package.manager
            )
            logger.error("Failed uninstalling package: \(package.name), error=\(error.localizedDescription)")
        }
    }
}
