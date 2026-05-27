import Foundation
import SwiftData

@MainActor
final class PackageCache {
    private let context: ModelContext

    init(container: ModelContainer) {
        context = container.mainContext
    }

    func upsert(_ packages: [Package]) throws {
        for pkg in packages {
            let id = pkg.id
            var descriptor = FetchDescriptor<CachedPackage>(predicate: #Predicate { $0.id == id })
            descriptor.fetchLimit = 1

            if let existing = try context.fetch(descriptor).first {
                existing.name = pkg.name
                existing.installedVersion = pkg.installedVersion
                existing.latestVersion = pkg.latestVersion
                existing.managerRaw = pkg.manager.rawValue
                existing.lastSeen = Date()
            } else {
                let cached = CachedPackage(from: pkg)
                context.insert(cached)
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
}
