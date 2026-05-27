import Foundation
import OSLog

extension Notification.Name {
    static let forgeRefreshCompleted = Notification.Name("forgeRefreshCompleted")
    static let forgeOutdatedCountChanged = Notification.Name("forgeOutdatedCountChanged")
}

@MainActor
final class BackgroundScheduler {
    static let shared = BackgroundScheduler()

    private var refreshTask: Task<Void, Never>?
    private(set) var lastRefresh: Date?
    private(set) var outdatedCount: Int = 0

    private let registry = PackageManagerRegistry.shared
    private let cache = PackageCache(container: StorageStack.shared.container)
    private let repo = SettingsRepository(container: StorageStack.shared.container)
    private let logger = Logger(subsystem: "com.forge.app", category: "scheduler")

    private init() {}

    var isRunning: Bool { refreshTask != nil }

    func start() {
        stop()
        let settings = repo.current()
        guard settings.autoRefreshEnabled else { return }

        logger.info("Starting background scheduler: interval=\(settings.autoRefreshIntervalMinutes)min")

        refreshTask = Task { @MainActor in
            while !Task.isCancelled {
                let currentSettings = repo.current()
                let seconds = currentSettings.autoRefreshIntervalMinutes * 60

                await runRefresh()

                do {
                    try await Task.sleep(for: .seconds(seconds))
                } catch {
                    break
                }
            }
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
        logger.info("Background scheduler stopped")
    }

    func restart() {
        logger.info("Restarting background scheduler")
        start()
    }

    func refreshNow() async {
        await runRefresh()
    }

    private func runRefresh() async {
        logger.info("Running scheduled refresh...")
        lastRefresh = Date()

        var all: [Package] = []
        for kind in registry.detectedKinds {
            guard let manager = registry.manager(kind) else { continue }
            do {
                logger.info("Scheduler loading installed packages: \(kind.displayName)")
                let pkgs = try await manager.installedPackages()
                logger.info("Scheduler loaded installed packages: \(kind.displayName), count=\(pkgs.count)")
                all.append(contentsOf: pkgs)
            } catch {
                logger.warning("Scheduler failed loading installed packages: \(kind.displayName), error=\(error.localizedDescription)")
            }
        }

        var newOutdated = 0
        for kind in registry.detectedKinds {
            guard let manager = registry.manager(kind) else { continue }
            let outdated: [Package]
            do {
                logger.info("Scheduler loading outdated packages: \(kind.displayName)")
                outdated = try await manager.outdatedPackages()
                logger.info("Scheduler loaded outdated packages: \(kind.displayName), count=\(outdated.count)")
            } catch {
                logger.warning("Scheduler failed loading outdated packages: \(kind.displayName), error=\(error.localizedDescription)")
                continue
            }
            newOutdated += outdated.count
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

        try? cache.upsert(all)

        let previousCount = outdatedCount
        outdatedCount = newOutdated
        repo.update { $0.lastRefresh = Date() }

        NotificationCenter.default.post(name: .forgeRefreshCompleted, object: nil)

        if newOutdated > previousCount, repo.current().notifyOnOutdated {
            let added = newOutdated - previousCount
            NotificationCenter.default.post(
                name: .forgeOutdatedCountChanged,
                object: nil,
                userInfo: ["count": newOutdated, "added": added]
            )
        }

        logger.info("Refresh complete: \(all.count) packages, \(newOutdated) outdated")
    }
}
