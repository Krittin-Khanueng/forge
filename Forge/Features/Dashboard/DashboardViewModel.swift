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

    private let refreshService: PackageRefreshService
    private let registry = PackageManagerRegistry.shared
    private let activityRepo = ActivityRepository(container: StorageStack.shared.container)
    private var hasLoadedOnce = false

    init(refreshService: PackageRefreshService = .shared) {
        self.refreshService = refreshService
    }

    func loadIfNeeded() async {
        applyStats(from: refreshService.packages)
        guard !hasLoadedOnce else { return }
        await load()
    }

    func load() async {
        let hasExistingDashboard = totalPackages > 0 || !managerCounts.isEmpty || !recentActivity.isEmpty
        isLoading = !hasExistingDashboard
        isRefreshing = hasExistingDashboard

        loadActivity()
        detectedManagers = registry.detectedKinds

        refreshService.applyCachedPackages()
        applyStats(from: refreshService.packages)

        defer {
            isLoading = false
            isRefreshing = false
        }

        await refreshService.refreshIfNeeded()
        applyStats(from: refreshService.packages)
        lastLoadedAt = refreshService.lastRefreshedAt ?? Date()
        hasLoadedOnce = true
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        loadActivity()
        await refreshService.refresh(force: true)
        applyStats(from: refreshService.packages)
        lastLoadedAt = refreshService.lastRefreshedAt ?? Date()
    }

    private func loadActivity() {
        let cachedActivity = activityRepo.recent(limit: 5)
        recentActivity = cachedActivity.map { entry in
            ActivityEntry(
                id: entry.id,
                timestamp: entry.timestamp,
                title: entry.title,
                subtitle: entry.subtitle
            )
        }
    }

    private func applyStats(from packages: [Package]) {
        let counts = PackageMergeHelpers.managerCounts(from: packages)
        managerCounts = counts
        totalPackages = packages.count
        outdatedCount = packages.filter(\.isOutdated).count
        let orderedKinds = counts.keys.sorted { counts[$0] ?? 0 > counts[$1] ?? 0 }
        detectedManagers = orderedKinds.isEmpty ? registry.detectedKinds : orderedKinds
    }
}
