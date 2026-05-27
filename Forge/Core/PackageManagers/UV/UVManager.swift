import Foundation
import OSLog

actor UVManager: PackageManagerProtocol {
    nonisolated let kind: PackageManagerKind = .uv

    private let runner = ProcessRunner()
    private let logger = Logger.uv
    private var cachedURL: URL?

    func detect() async -> URL? {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("uv") else {
            logger.warning("uv not found on this system")
            return nil
        }
        cachedURL = url
        return url
    }

    func installedPackages() async throws -> [Package] {
        let uvURL = try await requireUV()
        let result = try await runner.run(uvURL, arguments: ["tool", "list", "--show-python"])

        let entries = UVParser.parseToolList(result.stdout)
        return entries.map { entry in
            Package(
                name: entry.name,
                installedVersion: entry.version,
                latestVersion: nil,
                manager: .uv,
                installPath: nil,
                description: nil,
                homepage: nil
            )
        }
    }

    func outdatedPackages() async throws -> [Package] {
        // TODO(forge): phase 3 — query PyPI for outdated info
        return []
    }

    nonisolated func featureStatus(_ feature: ManagerFeature) -> FeatureStatus {
        switch feature {
        case .outdated:
            return .missing(reason: "uv tool has no outdated command — PyPI query planned for phase 3")
        case .search:
            return .missing(reason: "uv pip search was deprecated/removed by PyPI")
        }
    }

    func search(query: String) async throws -> [Package] {
        logger.info("uv pip search is deprecated/removed by PyPI — returning empty results")
        return []
    }

    func install(_ name: String) async throws {
        let uvURL = try await requireUV()
        _ = try await runner.run(uvURL, arguments: ["tool", "install", name])
    }

    func uninstall(_ name: String) async throws {
        let uvURL = try await requireUV()
        _ = try await runner.run(uvURL, arguments: ["tool", "uninstall", name])
    }

    func update(_ name: String) async throws {
        let uvURL = try await requireUV()
        _ = try await runner.run(uvURL, arguments: ["tool", "upgrade", name])
    }

    func updateAll() async throws {
        let uvURL = try await requireUV()
        _ = try await runner.run(uvURL, arguments: ["tool", "upgrade", "--all"])
    }

    private func requireUV() async throws -> URL {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("uv") else {
            throw ProcessError.binaryNotFound("uv")
        }
        cachedURL = url
        return url
    }
}
