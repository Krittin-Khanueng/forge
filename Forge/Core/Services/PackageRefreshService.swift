import Foundation
import OSLog

@MainActor
@Observable
final class PackageRefreshService {
    static let shared = PackageRefreshService()

    private(set) var packages: [Package] = []
    private(set) var isRefreshing = false
    private(set) var lastRefreshedAt: Date?
    var error: String?

    var outdatedCount: Int {
        packages.filter(\.isOutdated).count
    }

    private let registry = PackageManagerRegistry.shared
    private let cache = PackageCache(container: StorageStack.shared.container)
    private let activityRepo = ActivityRepository(container: StorageStack.shared.container)
    private let logger = Logger(subsystem: "com.forge.app", category: "refresh")
    private var inFlightRefresh: Task<Void, Never>?
    private let minimumRefreshInterval: TimeInterval = 30

    private init() {}

    func applyCachedPackages() {
        guard let cached = try? cache.all(manager: nil), !cached.isEmpty else { return }
        packages = PackageMergeHelpers.sortedByName(cached)
    }

    func refreshIfNeeded() async {
        if isRefreshing { return }
        if let lastRefreshedAt,
           Date().timeIntervalSince(lastRefreshedAt) < minimumRefreshInterval {
            return
        }
        await refresh(force: false)
    }

    func refresh(force: Bool = true) async {
        if isRefreshing {
            if force {
                await inFlightRefresh?.value
            }
            return
        }

        if !force,
           let lastRefreshedAt,
           Date().timeIntervalSince(lastRefreshedAt) < minimumRefreshInterval {
            return
        }

        let task = Task { @MainActor in
            await performRefresh()
        }
        inFlightRefresh = task
        await task.value
        inFlightRefresh = nil
    }

    func refreshManager(_ kind: PackageManagerKind) async {
        guard let manager = registry.manager(kind) else { return }

        isRefreshing = true
        error = nil
        defer { isRefreshing = false }

        var working = packages

        do {
            let installed = try await manager.installedPackages()
            working.removeAll { $0.manager == kind }
            working.append(contentsOf: installed)

            let outdated = try await manager.outdatedPackages()
            PackageMergeHelpers.mergeOutdated(outdated, into: &working)
            packages = PackageMergeHelpers.sortedByName(working)
            try? cache.upsert(packages)
            lastRefreshedAt = Date()
        } catch {
            self.error = "Failed to refresh \(kind.displayName): \(error.localizedDescription)"
            logger.warning("Partial refresh failed: \(kind.displayName), error=\(error.localizedDescription)")
        }
    }

    private func performRefresh() async {
        isRefreshing = true
        error = nil
        defer { isRefreshing = false }

        var all: [Package] = []
        var failedManagers: [String] = []

        let kinds = registry.detectedKinds

        await withTaskGroup(of: (PackageManagerKind, Result<[Package], Error>).self) { group in
            for kind in kinds {
                guard let manager = registry.manager(kind) else { continue }
                group.addTask {
                    do {
                        let pkgs = try await manager.installedPackages()
                        return (kind, .success(pkgs))
                    } catch {
                        return (kind, .failure(error))
                    }
                }
            }
            for await (kind, result) in group {
                switch result {
                case .success(let pkgs):
                    all.append(contentsOf: pkgs)
                case .failure(let error):
                    failedManagers.append(kind.displayName)
                    logger.error("Failed loading installed: \(kind.displayName), error=\(error.localizedDescription)")
                }
            }
        }

        await withTaskGroup(of: (PackageManagerKind, Result<[Package], Error>).self) { group in
            for kind in kinds {
                guard registry.manager(kind) != nil else { continue }
                guard let manager = registry.manager(kind) else { continue }
                group.addTask {
                    do {
                        let outdated = try await manager.outdatedPackages()
                        return (kind, .success(outdated))
                    } catch {
                        return (kind, .failure(error))
                    }
                }
            }
            for await (kind, result) in group {
                switch result {
                case .success(let outdated):
                    PackageMergeHelpers.mergeOutdated(outdated, into: &all)
                case .failure(let error):
                    if !failedManagers.contains(kind.displayName) {
                        failedManagers.append(kind.displayName)
                    }
                    logger.warning("Failed loading outdated: \(kind.displayName), error=\(error.localizedDescription)")
                }
            }
        }

        packages = PackageMergeHelpers.sortedByName(all)
        try? cache.upsert(packages)
        let activeKinds = Set(kinds.map(\.rawValue))
        try? cache.removePackages(forRemovedManagers: activeKinds)
        try? cache.removeStale()
        lastRefreshedAt = Date()

        activityRepo.record(
            kind: "refresh",
            title: "Packages refreshed",
            subtitle: "\(packages.count) packages from \(kinds.count) managers",
            manager: nil
        )

        if !failedManagers.isEmpty {
            error = "Some package managers failed: \(failedManagers.joined(separator: ", "))"
        } else {
            error = nil
        }

        NotificationCenter.default.post(name: .forgeRefreshCompleted, object: nil)

        logger.info("Refresh complete: \(self.packages.count) packages, \(self.outdatedCount) outdated")
    }
}
