import Foundation
import OSLog

actor YarnManager: PackageManagerProtocol {
    nonisolated let kind: PackageManagerKind = .yarn

    private let runner = ProcessRunner()
    private let logger = Logger.yarn
    private var cachedURL: URL?
    private var versionChecked = false
    private var _isClassic = false

    private var isClassic: Bool {
        get async {
            if !versionChecked {
                await detectVersion()
            }
            return _isClassic
        }
    }

    func detect() async -> URL? {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("yarn") else {
            logger.warning("Yarn not found on this system")
            return nil
        }
        cachedURL = url
        await detectVersion()
        return url
    }

    private func detectVersion() async {
        guard let yarnURL = cachedURL else { return }
        do {
            let result = try await runner.run(yarnURL, arguments: ["--version"])
            let version = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            _isClassic = version.hasPrefix("1.")
            let classic = _isClassic
        logger.info("Detected Yarn \(classic ? "Classic" : "Berry") (\(version))")
        } catch {
            logger.warning("Could not detect Yarn version, assuming Berry: \(error.localizedDescription)")
            _isClassic = false
        }
        versionChecked = true
    }

    func installedPackages() async throws -> [Package] {
        let yarnURL = try await requireYarn()

        guard await isClassic else {
            return []
        }

        let result = try await runner.run(yarnURL, arguments: ["global", "list", "--json"])
        let lines = result.stdout
            .split(separator: "\n", omittingEmptySubsequences: true)

        struct YarnClassicEntry: Decodable, Sendable {
            let type: String?
            let data: YarnClassicEntryData?
        }

        struct YarnClassicEntryData: Decodable, Sendable {
            let name: String?
            let version: String?
        }

        var packages: [Package] = []
        for line in lines {
            guard let data = String(line).data(using: .utf8) else { continue }
            guard let entry = try? JSONDecoder().decode(YarnClassicEntry.self, from: data) else {
                continue
            }
            guard let entryData = entry.data, let name = entryData.name else { continue }
            packages.append(Package(
                name: name,
                installedVersion: entryData.version,
                latestVersion: nil,
                manager: .yarn,
                installPath: nil,
                description: nil,
                homepage: nil
            ))
        }
        return packages
    }

    func outdatedPackages() async throws -> [Package] {
        guard await isClassic else { return [] }

        let yarnURL = try await requireYarn()
        let result = try await runner.run(yarnURL, arguments: ["global", "outdated", "--json"])

        let lines = result.stdout
            .split(separator: "\n", omittingEmptySubsequences: true)

        struct YarnOutdatedEntry: Decodable, Sendable {
            let type: String?
            let data: YarnOutdatedEntryData?
        }

        struct YarnOutdatedEntryData: Decodable, Sendable {
            let name: String?
            let current: String?
            let latest: String?
        }

        var packages: [Package] = []
        for line in lines {
            guard let data = String(line).data(using: .utf8) else { continue }
            guard let entry = try? JSONDecoder().decode(YarnOutdatedEntry.self, from: data) else {
                continue
            }
            guard let entryData = entry.data, let name = entryData.name else { continue }
            packages.append(Package(
                name: name,
                installedVersion: entryData.current,
                latestVersion: entryData.latest,
                manager: .yarn,
                installPath: nil,
                description: nil,
                homepage: nil
            ))
        }
        return packages
    }

    func search(query: String) async throws -> [Package] {
        guard await isClassic else { return [] }
        let yarnURL = try await requireYarn()
        let result = try await runner.run(yarnURL, arguments: ["search", query])

        let lines = result.stdout
            .split(separator: "\n", omittingEmptySubsequences: true)
            .dropFirst()

        return lines.compactMap { line in
            let parts = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard parts.count >= 2 else { return nil }
            let name = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let version = String(parts[1]).trimmingCharacters(in: .whitespaces)
            let description = parts.count >= 3
                ? String(parts[2]).trimmingCharacters(in: .whitespaces)
                : nil
            guard !name.isEmpty else { return nil }
            return Package(
                name: name,
                installedVersion: nil,
                latestVersion: version,
                manager: .yarn,
                installPath: nil,
                description: description,
                homepage: nil
            )
        }
    }

    func install(_ name: String) async throws {
        let yarnURL = try await requireYarn()

        guard await isClassic else {
            throw ManagerError.unsupported(reason: "Yarn Berry has no global install — use yarn dlx")
        }

        _ = try await runner.run(yarnURL, arguments: ["global", "add", name])
    }

    func uninstall(_ name: String) async throws {
        let yarnURL = try await requireYarn()

        guard await isClassic else {
            throw ManagerError.unsupported(reason: "Yarn Berry has no global uninstall — use yarn dlx")
        }

        _ = try await runner.run(yarnURL, arguments: ["global", "remove", name])
    }

    func update(_ name: String) async throws {
        let yarnURL = try await requireYarn()

        guard await isClassic else {
            throw ManagerError.unsupported(reason: "Yarn Berry has no global update — use yarn dlx")
        }

        _ = try await runner.run(yarnURL, arguments: ["global", "upgrade", name])
    }

    func updateAll() async throws {
        let yarnURL = try await requireYarn()

        guard await isClassic else {
            throw ManagerError.unsupported(reason: "Yarn Berry has no global upgrade — use yarn dlx")
        }

        _ = try await runner.run(yarnURL, arguments: ["global", "upgrade"])
    }

    private func requireYarn() async throws -> URL {
        if let cached = cachedURL { return cached }
        guard let url = try? await BinaryResolver.shared.resolve("yarn") else {
            throw ProcessError.binaryNotFound("yarn")
        }
        cachedURL = url
        return url
    }
}
