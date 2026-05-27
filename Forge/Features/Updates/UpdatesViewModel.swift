import Foundation
import OSLog

@MainActor
@Observable
final class UpdatesViewModel {
    var outdatedByManager: [PackageManagerKind: [Package]] = [:]
    var isLoading = false
    var updatingPackageIDs: Set<Package.ID> = []
    var updatingManagers: Set<PackageManagerKind> = []
    var error: String?

    var totalOutdated: Int {
        outdatedByManager.values.reduce(0) { $0 + $1.count }
    }

    var managerSections: [(kind: PackageManagerKind, packages: [Package])] {
        outdatedByManager
            .map { (kind: $0.key, packages: $0.value) }
            .filter { !$0.packages.isEmpty }
            .sorted { $0.kind.displayName < $1.kind.displayName }
    }

    var isUpdating: Bool {
        !updatingPackageIDs.isEmpty || !updatingManagers.isEmpty
    }

    private let registry = PackageManagerRegistry.shared
    private let cache = PackageCache(container: StorageStack.shared.container)
    private let activityRepo = ActivityRepository(container: StorageStack.shared.container)
    private let logger = Logger.ui

    func load() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        var next: [PackageManagerKind: [Package]] = [:]
        var failedManagers: [String] = []

        for kind in registry.detectedKinds {
            guard let manager = registry.manager(kind) else { continue }
            do {
                logger.info("Loading updates: \(kind.displayName)")
                let packages = try await manager.outdatedPackages()
                    .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                if !packages.isEmpty {
                    next[kind] = packages
                    try? cache.upsert(packages)
                }
            } catch {
                failedManagers.append(kind.displayName)
                logger.warning("Failed loading updates: \(kind.displayName), error=\(error.localizedDescription)")
            }
        }

        outdatedByManager = next
        if !failedManagers.isEmpty {
            error = "Some package managers failed: \(failedManagers.joined(separator: ", "))"
        }
    }

    func isUpdating(_ package: Package) -> Bool {
        updatingPackageIDs.contains(package.id) || updatingManagers.contains(package.manager)
    }

    func update(_ package: Package) async {
        guard let manager = registry.manager(package.manager) else {
            error = "\(package.manager.displayName) is not available."
            return
        }

        updatingPackageIDs.insert(package.id)
        error = nil
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
            await refreshManager(package.manager)
        } catch {
            self.error = "Failed to update \(package.name): \(error.localizedDescription)"
            activityRepo.record(
                kind: "update_failed",
                title: "Update failed: \(package.name)",
                subtitle: error.localizedDescription,
                manager: package.manager
            )
            logger.error("Failed updating package: \(package.name), error=\(error.localizedDescription)")
        }
    }

    func updateAll(for kind: PackageManagerKind) async {
        guard let manager = registry.manager(kind) else {
            error = "\(kind.displayName) is not available."
            return
        }

        updatingManagers.insert(kind)
        error = nil
        defer { updatingManagers.remove(kind) }

        do {
            logger.info("Updating all packages: \(kind.displayName)")
            try await manager.updateAll()
            activityRepo.record(
                kind: "update_all",
                title: "Updated all \(kind.displayName) packages",
                subtitle: nil,
                manager: kind
            )
            await refreshManager(kind)
        } catch {
            self.error = "Failed to update \(kind.displayName): \(error.localizedDescription)"
            activityRepo.record(
                kind: "update_all_failed",
                title: "Update all failed: \(kind.displayName)",
                subtitle: error.localizedDescription,
                manager: kind
            )
            logger.error("Failed updating all packages: \(kind.displayName), error=\(error.localizedDescription)")
        }
    }

    func updateAllOutdated() async {
        for section in managerSections {
            await updateAll(for: section.kind)
        }
    }

    private func refreshManager(_ kind: PackageManagerKind) async {
        guard let manager = registry.manager(kind) else { return }

        do {
            let packages = try await manager.outdatedPackages()
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            if packages.isEmpty {
                outdatedByManager[kind] = nil
            } else {
                outdatedByManager[kind] = packages
                try? cache.upsert(packages)
            }
        } catch {
            self.error = "Updated, but failed to refresh \(kind.displayName): \(error.localizedDescription)"
            logger.warning("Failed refreshing updates after update: \(kind.displayName), error=\(error.localizedDescription)")
        }
    }
}
