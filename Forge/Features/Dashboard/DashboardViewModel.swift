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

    // Docker
    var dockerAvailable = false
    var dockerRunningContainers = 0
    var dockerTotalContainers = 0
    var dockerImageCount = 0

    private let registry = PackageManagerRegistry.shared
    private let cache = PackageCache(container: StorageStack.shared.container)
    private let activityRepo = ActivityRepository(container: StorageStack.shared.container)
    private let dockerClient = DockerClient()
    private let logger = Logger.ui

    func load() async {
        isLoading = true
        defer { isLoading = false }

        let cachedActivity = activityRepo.recent(limit: 10)
        recentActivity = cachedActivity.map { entry in
            ActivityEntry(
                id: entry.id,
                timestamp: entry.timestamp,
                title: entry.title,
                subtitle: entry.subtitle
            )
        }

        let cachedPackages = (try? cache.all(manager: nil)) ?? []
        totalPackages = cachedPackages.count
        outdatedCount = cachedPackages.filter { $0.isOutdated }.count
        detectedManagers = registry.detectedKinds

        var all: [Package] = []
        for kind in registry.detectedKinds {
            guard let manager = registry.manager(kind) else { continue }
            if let pkgs = try? await manager.installedPackages() {
                all.append(contentsOf: pkgs)
            }
        }

        for kind in registry.detectedKinds {
            guard let manager = registry.manager(kind) else { continue }
            guard let outdated = try? await manager.outdatedPackages() else { continue }
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

        await loadDockerStats()
    }

    func refresh() async {
        await load()
    }

    private func loadDockerStats() async {
        dockerAvailable = await dockerClient.isAvailable()
        guard dockerAvailable else { return }

        if let containers = try? await dockerClient.containers(all: true) {
            dockerRunningContainers = containers.filter(\.isRunning).count
            dockerTotalContainers = containers.count
        }
        if let images = try? await dockerClient.images() {
            dockerImageCount = images.count
        }
    }
}
