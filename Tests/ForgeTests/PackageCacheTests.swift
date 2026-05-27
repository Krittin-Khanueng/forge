import Foundation
import SwiftData
import Testing
@testable import Forge

@Suite("Package Cache Tests")
@MainActor
struct PackageCacheTests {
    func makeContainer() throws -> ModelContainer {
        let schema = Schema([CachedPackage.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    @Test func upsertAndReadBack() async throws {
        let container = try await makeContainer()
        let cache = PackageCache(container: container)

        let pkgs = [
            Package(name: "foo", installedVersion: "1.0", latestVersion: "1.1", manager: .brew),
            Package(name: "bar", installedVersion: "2.0", latestVersion: "2.0", manager: .brew),
        ]

        try cache.upsert(pkgs)

        let all = try cache.all(manager: nil)
        #expect(all.count == 2)
        #expect(all.contains(where: { $0.name == "foo" && $0.installedVersion == "1.0" }))
        #expect(all.contains(where: { $0.name == "bar" && $0.installedVersion == "2.0" }))
    }

    @Test func upsertOverwritesExisting() async throws {
        let container = try await makeContainer()
        let cache = PackageCache(container: container)

        let initial = [Package(name: "foo", installedVersion: "1.0", latestVersion: "1.0", manager: .brew)]
        try cache.upsert(initial)

        let updated = [Package(name: "foo", installedVersion: "1.0", latestVersion: "1.1", manager: .brew)]
        try cache.upsert(updated)

        let all = try cache.all(manager: nil)
        #expect(all.count == 1)
        #expect(all[0].latestVersion == "1.1")
    }

    @Test func clearByManager() async throws {
        let container = try await makeContainer()
        let cache = PackageCache(container: container)

        let brewPkgs = [Package(name: "foo", installedVersion: "1.0", manager: .brew)]
        let npmPkgs = [Package(name: "bar", installedVersion: "2.0", manager: .npm)]
        try cache.upsert(brewPkgs + npmPkgs)

        try cache.clear(manager: .brew)

        let remaining = try cache.all(manager: nil)
        #expect(remaining.count == 1)
        #expect(remaining[0].manager == .npm)
    }

    @Test func clearAll() async throws {
        let container = try await makeContainer()
        let cache = PackageCache(container: container)

        try cache.upsert([
            Package(name: "foo", installedVersion: "1.0", manager: .brew),
            Package(name: "bar", installedVersion: "2.0", manager: .npm),
        ])

        try cache.clear(manager: nil)

        let all = try cache.all(manager: nil)
        #expect(all.isEmpty)
    }
}
