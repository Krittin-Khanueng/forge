import Foundation
import OSLog

actor PNPMManager: PackageManagerProtocol {
    nonisolated let kind: PackageManagerKind = .pnpm

    private let runner = ProcessRunner()
    private let logger = Logger.pnpm
    private var cachedURL: URL?

    struct PNPMListEntry: Decodable, Sendable {
        let name: String
        let version: String?
        let path: String?
    }

    struct PNPMOutdatedEntry: Decodable, Sendable {
        let current: String?
        let wanted: String?
        let latest: String?
    }

    func detect() async -> URL? {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("pnpm") else {
            logger.warning("pnpm not found on this system")
            return nil
        }
        cachedURL = url
        return url
    }

    func installedPackages() async throws -> [Package] {
        let pnpmURL = try await requirePNPM()
        let result = try await runner.run(pnpmURL, arguments: ["list", "-g", "--depth=0", "--json"])

        guard !result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let items = try JSONOutputDecoder.decode([PNPMListEntry].self, from: result.stdout)
        return items.map { entry in
            Package(
                name: entry.name,
                installedVersion: entry.version,
                latestVersion: nil,
                manager: .pnpm,
                installPath: entry.path,
                description: nil,
                homepage: nil
            )
        }
    }

    func outdatedPackages() async throws -> [Package] {
        let pnpmURL = try await requirePNPM()
        let result = try await runner.run(pnpmURL, arguments: ["outdated", "-g", "--json"])

        let stdout = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if stdout.isEmpty || stdout == "{}" {
            return []
        }

        let entries = try JSONOutputDecoder.decode([String: PNPMOutdatedEntry].self, from: stdout)
        return entries.map { name, entry in
            Package(
                name: name,
                installedVersion: entry.current,
                latestVersion: entry.latest,
                manager: .pnpm,
                installPath: nil,
                description: nil,
                homepage: nil
            )
        }
    }

    func search(query: String) async throws -> [Package] {
        let pnpmURL = try await requirePNPM()
        let result = try await runner.run(pnpmURL, arguments: ["search", query, "--json"])

        guard !result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        struct PNPMSearchResult: Decodable, Sendable {
            let name: String?
            let version: String?
            let description: String?

            var packageName: String { name ?? version ?? "unknown" }
        }

        let items = try JSONOutputDecoder.decode([PNPMSearchResult].self, from: result.stdout)
        return items.map { item in
            Package(
                name: item.packageName,
                installedVersion: nil,
                latestVersion: item.version,
                manager: .pnpm,
                installPath: nil,
                description: item.description,
                homepage: nil
            )
        }
    }

    func install(_ name: String) async throws {
        let pnpmURL = try await requirePNPM()
        _ = try await runner.run(pnpmURL, arguments: ["add", "-g", name])
    }

    func uninstall(_ name: String) async throws {
        let pnpmURL = try await requirePNPM()
        _ = try await runner.run(pnpmURL, arguments: ["remove", "-g", name])
    }

    func update(_ name: String) async throws {
        let pnpmURL = try await requirePNPM()
        _ = try await runner.run(pnpmURL, arguments: ["update", "-g", name])
    }

    func updateAll() async throws {
        let pnpmURL = try await requirePNPM()
        _ = try await runner.run(pnpmURL, arguments: ["update", "-g"])
    }

    private func requirePNPM() async throws -> URL {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("pnpm") else {
            throw ProcessError.binaryNotFound("pnpm")
        }
        cachedURL = url
        return url
    }
}
