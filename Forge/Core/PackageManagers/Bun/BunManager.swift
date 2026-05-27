import Foundation
import OSLog

actor BunManager: PackageManagerProtocol {
    nonisolated let kind: PackageManagerKind = .bun

    private let runner = ProcessRunner()
    private let logger = Logger.bun
    private var cachedURL: URL?

    func detect() async -> URL? {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("bun") else {
            logger.warning("Bun not found on this system")
            return nil
        }
        cachedURL = url
        return url
    }

    func installedPackages() async throws -> [Package] {
        let bunURL = try await requireBun()
        let result = try await runner.run(bunURL, arguments: ["pm", "ls", "-g"])

        let lines = result.stdout.split(separator: "\n", omittingEmptySubsequences: true)
        var packages: [Package] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let atIndex = trimmed.lastIndex(of: "@") else { continue }

            let name = String(trimmed[..<atIndex]).trimmingCharacters(in: .whitespaces)
            let version = String(trimmed[trimmed.index(after: atIndex)...]).trimmingCharacters(in: .whitespaces)

            guard !name.isEmpty, !version.isEmpty else { continue }

            packages.append(Package(
                name: name,
                installedVersion: version,
                latestVersion: nil,
                manager: .bun,
                installPath: nil,
                description: nil,
                homepage: nil
            ))
        }

        return packages
    }

    func outdatedPackages() async throws -> [Package] {
        // TODO(forge): bun outdated global — wait for Bun to ship native outdated for global packages
        return []
    }

    func search(query: String) async throws -> [Package] {
        // TODO(forge): bun search — Bun has no npm-style search yet
        return []
    }

    func install(_ name: String) async throws {
        let bunURL = try await requireBun()
        _ = try await runner.run(bunURL, arguments: ["install", "-g", name])
    }

    func uninstall(_ name: String) async throws {
        let bunURL = try await requireBun()
        _ = try await runner.run(bunURL, arguments: ["remove", "-g", name])
    }

    func update(_ name: String) async throws {
        let bunURL = try await requireBun()
        _ = try await runner.run(bunURL, arguments: ["update", "-g", name])
    }

    func updateAll() async throws {
        // TODO(forge): bun update-all global — Bun doesn't have update-all for globals yet
        throw ManagerError.unsupported(reason: "Bun doesn't support update-all for global packages yet")
    }

    private func requireBun() async throws -> URL {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("bun") else {
            throw ProcessError.binaryNotFound("bun")
        }
        cachedURL = url
        return url
    }
}
