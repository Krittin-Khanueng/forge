import Foundation
import OSLog

actor BrewManager: PackageManagerProtocol {
    nonisolated let kind: PackageManagerKind = .brew

    private let runner = ProcessRunner()
    private let logger = Logger.brew
    private let decoder: JSONDecoder = .init()

    private var cachedURL: URL?

    func detect() async -> URL? {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("brew") else {
            logger.warning("Homebrew not found on this system")
            return nil
        }
        cachedURL = url
        return url
    }

    func installedPackages() async throws -> [Package] {
        let brewURL = try await requireBrew()
        let result = try await runner.run(brewURL, arguments: ["info", "--json=v2", "--installed"])
        let response = try decoder.decode(BrewInfoResponse.self, from: result.stdoutData)

        let formulaPackages = response.formulae.map { $0.toPackage() }
        let caskPackages = response.casks.map { cask in
            Package(
                name: cask.token,
                installedVersion: cask.version ?? cask.installed,
                latestVersion: nil,
                manager: .brew,
                installPath: nil,
                description: cask.desc,
                homepage: cask.homepage.flatMap(URL.init(string:))
            )
        }

        return formulaPackages + caskPackages
    }

    func outdatedPackages() async throws -> [Package] {
        let brewURL = try await requireBrew()
        let result = try await runner.run(brewURL, arguments: ["outdated", "--json=v2"])
        let response = try decoder.decode(BrewOutdatedResponse.self, from: result.stdoutData)

        let formulaPackages = response.formulae.map { $0.toPackage() }
        let caskPackages = response.casks.map { $0.toPackage() }

        return formulaPackages + caskPackages
    }

    func search(query: String) async throws -> [Package] {
        let brewURL = try await requireBrew()
        let result = try await runner.run(brewURL, arguments: ["search", "--formula", query])

        let lines = result.stdout
            .split(separator: "\n", omittingEmptySubsequences: true)
            .filter { !$0.hasPrefix("==>") }

        return lines.map { line in
            let name = line.trimmingCharacters(in: .whitespaces)
            return Package(
                name: name,
                installedVersion: nil,
                latestVersion: nil,
                manager: .brew,
                installPath: nil,
                description: nil,
                homepage: nil
            )
        }
    }

    func install(_ name: String) async throws {
        let brewURL = try await requireBrew()
        _ = try await runner.run(brewURL, arguments: ["install", name])
    }

    func uninstall(_ name: String) async throws {
        let brewURL = try await requireBrew()
        _ = try await runner.run(brewURL, arguments: ["uninstall", name])
    }

    func update(_ name: String) async throws {
        let brewURL = try await requireBrew()
        _ = try await runner.run(brewURL, arguments: ["upgrade", name])
    }

    func updateAll() async throws {
        let brewURL = try await requireBrew()
        _ = try await runner.run(brewURL, arguments: ["upgrade"])
    }

    private func requireBrew() async throws -> URL {
        guard let url = try? await resolveBrew() else {
            throw ProcessError.binaryNotFound("brew")
        }
        return url
    }

    private func resolveBrew() async throws -> URL {
        if let cached = cachedURL { return cached }
        let url = try await BinaryResolver.shared.resolve("brew")
        cachedURL = url
        return url
    }
}
