import SwiftUI
import OSLog

@MainActor
@Observable
final class DashboardViewModel {
    var totalPackages = 0
    var outdatedCount = 0
    var detectedManagers: [PackageManagerKind] = []
    var recentActivity: [ActivityEntry] = []
    var isLoading = false
    var isRefreshing = false
    var lastLoadedAt: Date?
    var managerCounts: [PackageManagerKind: Int] = [:]

    private let registry = PackageManagerRegistry.shared
    private let cache = PackageCache(container: StorageStack.shared.container)
    private let activityRepo = ActivityRepository(container: StorageStack.shared.container)
    private let logger = Logger.ui

    func load() async {
        let hasExistingDashboard = totalPackages > 0 || !managerCounts.isEmpty || !recentActivity.isEmpty
        isLoading = !hasExistingDashboard
        isRefreshing = hasExistingDashboard
        defer {
            isLoading = false
            isRefreshing = false
        }

        let cachedActivity = activityRepo.recent(limit: 5)
        recentActivity = cachedActivity.map { entry in
            ActivityEntry(
                id: entry.id,
                timestamp: entry.timestamp,
                title: entry.title,
                subtitle: entry.subtitle
            )
        }

        detectedManagers = registry.detectedKinds

        var all: [Package] = []
        var counts: [PackageManagerKind: Int] = [:]

        for kind in registry.detectedKinds {
            guard let manager = registry.manager(kind) else { continue }
            do {
                logger.info("Dashboard loading installed packages: \(kind.displayName)")
                let pkgs = try await manager.installedPackages()
                logger.info("Dashboard loaded installed packages: \(kind.displayName), count=\(pkgs.count)")
                all.append(contentsOf: pkgs)
                counts[kind] = pkgs.count
            } catch {
                logger.warning("Dashboard failed loading installed packages: \(kind.displayName), error=\(error.localizedDescription)")
            }
        }

        managerCounts = counts

        for kind in registry.detectedKinds {
            guard let manager = registry.manager(kind) else { continue }
            let outdated: [Package]
            do {
                logger.info("Dashboard loading outdated packages: \(kind.displayName)")
                outdated = try await manager.outdatedPackages()
                logger.info("Dashboard loaded outdated packages: \(kind.displayName), count=\(outdated.count)")
            } catch {
                logger.warning("Dashboard failed loading outdated packages: \(kind.displayName), error=\(error.localizedDescription)")
                continue
            }
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
        }

        totalPackages = all.count
        outdatedCount = all.filter { $0.isOutdated }.count

        let orderedKinds = counts.keys.sorted { counts[$0] ?? 0 > counts[$1] ?? 0 }
        detectedManagers = orderedKinds
        lastLoadedAt = Date()
    }

    func refresh() async {
        await load()
    }
}
