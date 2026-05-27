import SwiftUI
import OSLog

@MainActor
@Observable
final class PackagesViewModel {
    var packages: [Package] = []
    var isLoading = false
    var error: String?
    var selectedManager: PackageManagerKind? = nil
    var searchText = ""

    var filteredPackages: [Package] {
        packages.filter { pkg in
            if let manager = selectedManager, pkg.manager != manager {
                return false
            }
            if !searchText.isEmpty {
                return pkg.name.localizedCaseInsensitiveContains(searchText)
            }
            return true
        }
    }

    private let registry = PackageManagerRegistry.shared
    private let cache = PackageCache(container: StorageStack.shared.container)
    private let activityRepo = ActivityRepository(container: StorageStack.shared.container)
    private let logger = Logger.ui

    func load() async {
        if let cached = try? cache.all(manager: nil), !cached.isEmpty {
            packages = cached
        }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        var all: [Package] = []
        var failedManagers: [String] = []

        for kind in registry.detectedKinds {
            guard let manager = registry.manager(kind) else { continue }
            do {
                logger.info("Loading installed packages: \(kind.displayName)")
                let pkgs = try await manager.installedPackages()
                logger.info("Loaded installed packages: \(kind.displayName), count=\(pkgs.count)")
                all.append(contentsOf: pkgs)
            } catch {
                failedManagers.append(kind.displayName)
                logger.error("Failed loading installed packages: \(kind.displayName), error=\(error.localizedDescription)")
            }
        }

        for kind in registry.detectedKinds {
            guard let manager = registry.manager(kind) else { continue }
            do {
                logger.info("Loading outdated packages: \(kind.displayName)")
                let outdated = try await manager.outdatedPackages()
                logger.info("Loaded outdated packages: \(kind.displayName), count=\(outdated.count)")
                for outdatedPkg in outdated {
                    if let idx = all.firstIndex(where: { $0.id == outdatedPkg.id }) {
                        all[idx] = Package(
                            name: all[idx].name,
                            installedVersion: all[idx].installedVersion,
                            latestVersion: outdatedPkg.latestVersion,
                            manager: all[idx].manager,
                            installPath: all[idx].installPath,
                            description: all[idx].description,
                            homepage: all[idx].homepage
                        )
                    }
                }
            } catch {
                logger.warning("Failed loading outdated packages: \(kind.displayName), error=\(error.localizedDescription)")
            }
        }

        packages = all.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        try? cache.upsert(packages)
        activityRepo.record(
            kind: "refresh",
            title: "Packages refreshed",
            subtitle: "\(packages.count) packages from \(registry.detectedKinds.count) managers",
            manager: nil
        )

        if !failedManagers.isEmpty {
            self.error = "Some package managers failed: \(failedManagers.joined(separator: ", "))"
        }
    }
}
