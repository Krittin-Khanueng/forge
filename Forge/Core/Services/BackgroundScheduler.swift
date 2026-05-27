import Foundation
import OSLog

extension Notification.Name {
    static let forgeRefreshCompleted = Notification.Name("forgeRefreshCompleted")
    static let forgeOutdatedCountChanged = Notification.Name("forgeOutdatedCountChanged")
    static let forgeSettingsChanged = Notification.Name("forgeSettingsChanged")
}

@MainActor
final class BackgroundScheduler {
    static let shared = BackgroundScheduler()

    private var refreshTask: Task<Void, Never>?
    private(set) var lastRefresh: Date?
    private(set) var outdatedCount: Int = 0

    private let refreshService = PackageRefreshService.shared
    private let repo = SettingsRepository(container: StorageStack.shared.container)
    private let logger = Logger(subsystem: "com.forge.app", category: "scheduler")

    private static let initialRefreshDelaySeconds: UInt64 = 45

    private init() {}

    var isRunning: Bool { refreshTask != nil }

    func start() {
        stop()
        let settings = repo.current()
        guard settings.autoRefreshEnabled else { return }

        logger.info("Starting background scheduler: interval=\(settings.autoRefreshIntervalMinutes)min")

        refreshTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(Self.initialRefreshDelaySeconds))
            } catch {
                return
            }

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

        let previousCount = outdatedCount
        await refreshService.refresh(force: true)

        outdatedCount = refreshService.outdatedCount
        repo.update { $0.lastRefresh = Date() }

        NotificationCenter.default.post(name: .forgeRefreshCompleted, object: nil)

        if outdatedCount > previousCount, repo.current().notifyOnOutdated {
            let added = outdatedCount - previousCount
            NotificationCenter.default.post(
                name: .forgeOutdatedCountChanged,
                object: nil,
                userInfo: ["count": outdatedCount, "added": added]
            )
        }

        logger.info("Refresh complete: \(self.refreshService.packages.count) packages, \(self.outdatedCount) outdated")
    }
}
