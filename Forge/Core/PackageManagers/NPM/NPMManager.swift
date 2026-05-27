import Foundation
import OSLog

actor NPMManager: PackageManagerProtocol {
    nonisolated let kind: PackageManagerKind = .npm

    private let runner = ProcessRunner()
    private let logger = Logger.npm
    private var cachedURL: URL?
    private lazy var bashURL = URL(fileURLWithPath: "/bin/bash")

    func detect() async -> URL? {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("npm") else {
            logger.warning("npm not found on this system")
            return nil
        }
        cachedURL = url
        return url
    }

    func installedPackages() async throws -> [Package] {
        let npmURL = try await requireNPM()
        let result = try await runner.run(npmURL, arguments: ["list", "-g", "--depth=0", "--json"])

        guard !result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let response = try JSONOutputDecoder.decode(NPMListResponse.self, from: result.stdout)
        guard let deps = response.dependencies else { return [] }
        return deps.map { name, entry in entry.toPackage(name: name) }
    }

    func outdatedPackages() async throws -> [Package] {
        let npmURL = try await requireNPM()
        let command = ShellEscape.command(npmURL.path, ["outdated", "-g", "--json"]) + " || true"

        let result = try await runner.run(
            bashURL,
            arguments: ["-c", command]
        )

        let stdout = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if stdout.isEmpty || stdout == "{}" {
            return []
        }

        let entries = try JSONOutputDecoder.decode([String: NPMOutdatedEntry].self, from: stdout)
        return entries.map { name, entry in entry.toPackage(name: name) }
    }

    func search(query: String) async throws -> [Package] {
        let npmURL = try await requireNPM()
        let result = try await runner.run(npmURL, arguments: ["search", query, "--json"])

        guard !result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        struct NPMSearchResult: Decodable, Sendable {
            let name: String
            let version: String?
            let description: String?
        }

        let items = try JSONOutputDecoder.decode([NPMSearchResult].self, from: result.stdout)
        return items.map { item in
            Package(
                name: item.name,
                installedVersion: nil,
                latestVersion: item.version,
                manager: .npm,
                installPath: nil,
                description: item.description,
                homepage: nil
            )
        }
    }

    func install(_ name: String) async throws {
        let npmURL = try await requireNPM()
        _ = try await runner.run(npmURL, arguments: ["install", "-g", name])
    }

    func uninstall(_ name: String) async throws {
        let npmURL = try await requireNPM()
        _ = try await runner.run(npmURL, arguments: ["uninstall", "-g", name])
    }

    func update(_ name: String) async throws {
        let npmURL = try await requireNPM()
        _ = try await runner.run(npmURL, arguments: ["update", "-g", name])
    }

    func updateAll() async throws {
        let npmURL = try await requireNPM()
        _ = try await runner.run(npmURL, arguments: ["update", "-g"])
    }

    private func requireNPM() async throws -> URL {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("npm") else {
            throw ProcessError.binaryNotFound("npm")
        }
        cachedURL = url
        return url
    }
}
