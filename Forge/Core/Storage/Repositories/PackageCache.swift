import Foundation
import SwiftData

@MainActor
final class PackageCache {
    private let context: ModelContext

    init(container: ModelContainer) {
        context = container.mainContext
    }

    func upsert(_ packages: [Package]) throws {
        guard !packages.isEmpty else { return }

        let existing = try context.fetch(FetchDescriptor<CachedPackage>())
        var byID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let now = Date()

        for pkg in packages {
            if let cached = byID[pkg.id] {
                cached.name = pkg.name
                cached.installedVersion = pkg.installedVersion
                cached.latestVersion = pkg.latestVersion
                cached.managerRaw = pkg.manager.rawValue
                cached.lastSeen = now
            } else {
                let cached = CachedPackage(from: pkg, lastSeen: now)
                context.insert(cached)
                byID[pkg.id] = cached
            }
        }
        try context.save()
    }

    func all(manager: PackageManagerKind?) throws -> [Package] {
        var descriptor: FetchDescriptor<CachedPackage>
        if let manager {
            descriptor = FetchDescriptor<CachedPackage>(
                predicate: #Predicate { $0.managerRaw == manager.rawValue }
            )
        } else {
            descriptor = FetchDescriptor<CachedPackage>()
        }
        let results = try context.fetch(descriptor)
        return results.map { $0.toPackage() }
    }

    func clear(manager: PackageManagerKind?) throws {
        var descriptor: FetchDescriptor<CachedPackage>
        if let manager {
            descriptor = FetchDescriptor<CachedPackage>(
                predicate: #Predicate { $0.managerRaw == manager.rawValue }
            )
        } else {
            descriptor = FetchDescriptor<CachedPackage>()
        }
        let results = try context.fetch(descriptor)
        for item in results {
            context.delete(item)
        }
        try context.save()
    }

    func remove(_ package: Package) throws {
        let id = package.id
        var descriptor = FetchDescriptor<CachedPackage>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            context.delete(existing)
            try context.save()
        }
    }

    func removeStale(olderThan interval: TimeInterval = 7 * 24 * 3600) throws {
        let cutoff = Date(timeIntervalSinceNow: -interval)
        let descriptor = FetchDescriptor<CachedPackage>(
            predicate: #Predicate { $0.lastSeen < cutoff }
        )
        let stale = try context.fetch(descriptor)
        guard !stale.isEmpty else { return }
        for item in stale { context.delete(item) }
        try context.save()
    }

    func removePackages(forRemovedManagers activeKinds: Set<String>) throws {
        let descriptor = FetchDescriptor<CachedPackage>()
        let all = try context.fetch(descriptor)
        let toRemove = all.filter { !activeKinds.contains($0.managerRaw) }
        guard !toRemove.isEmpty else { return }
        for item in toRemove { context.delete(item) }
        try context.save()
    }
}
