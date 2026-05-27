import Foundation
import OSLog

actor CargoManager: PackageManagerProtocol {
    nonisolated let kind: PackageManagerKind = .cargo

    private let runner = ProcessRunner()
    private let logger = Logger.cargo
    private var cachedURL: URL?

    func detect() async -> URL? {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("cargo") else {
            logger.warning("Cargo not found on this system")
            return nil
        }
        cachedURL = url
        return url
    }

    func installedPackages() async throws -> [Package] {
        let cargoURL = try await requireCargo()
        let result = try await runner.run(cargoURL, arguments: ["install", "--list"])

        let entries = CargoParser.parseInstallList(result.stdout)
        return entries.map { entry in
            Package(
                name: entry.name,
                installedVersion: entry.version,
                latestVersion: nil,
                manager: .cargo,
                installPath: nil,
                description: nil,
                homepage: nil
            )
        }
    }

    func outdatedPackages() async throws -> [Package] {
        let cargoURL = try await requireCargo()

        let probe = try? await runner.run(cargoURL, arguments: ["outdated", "--help"])
        if probe == nil {
            logger.info("cargo-outdated subcommand not installed — install with: cargo install cargo-outdated")
            return []
        }

        let result = try await runner.run(cargoURL, arguments: ["outdated", "--format", "json"])
        let items = try JSONOutputDecoder.decode([CargoOutdatedItem].self, from: result.stdout)

        return items.map { item in
            Package(
                name: item.name,
                installedVersion: item.project,
                latestVersion: item.latest,
                manager: .cargo,
                installPath: nil,
                description: nil,
                homepage: nil
            )
        }
    }

    nonisolated func featureStatus(_ feature: ManagerFeature) -> FeatureStatus {
        switch feature {
        case .outdated:
            return .missing(reason: "Install cargo-outdated for update info (cargo install cargo-outdated)")
        case .search:
            return .available
        }
    }

    func search(query: String) async throws -> [Package] {
        let cargoURL = try await requireCargo()
        let result = try await runner.run(cargoURL, arguments: ["search", query, "--limit", "25"])

        let entries = CargoParser.parseSearch(result.stdout)
        return entries.map { entry in
            Package(
                name: entry.name,
                installedVersion: nil,
                latestVersion: entry.version,
                manager: .cargo,
                installPath: nil,
                description: entry.description,
                homepage: nil
            )
        }
    }

    func install(_ name: String) async throws {
        let cargoURL = try await requireCargo()
        _ = try await runner.run(cargoURL, arguments: ["install", name])
    }

    func uninstall(_ name: String) async throws {
        let cargoURL = try await requireCargo()
        _ = try await runner.run(cargoURL, arguments: ["uninstall", name])
    }

    func update(_ name: String) async throws {
        let cargoURL = try await requireCargo()
        _ = try await runner.run(cargoURL, arguments: ["install", name, "--force"])
    }

    func updateAll() async throws {
        let cargoURL = try await requireCargo()
        let result = try await installedPackages()
        for pkg in result {
            _ = try? await runner.run(cargoURL, arguments: ["install", pkg.name, "--force"])
        }
    }

    private func requireCargo() async throws -> URL {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("cargo") else {
            throw ProcessError.binaryNotFound("cargo")
        }
        cachedURL = url
        return url
    }
}

private struct CargoOutdatedItem: Decodable, Sendable {
    let name: String
    let project: String
    let latest: String
}
