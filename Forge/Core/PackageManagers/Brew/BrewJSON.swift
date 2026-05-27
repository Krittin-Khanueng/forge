import Foundation

struct BrewInfoResponse: Decodable, Sendable {
    let formulae: [BrewFormulaInfo]
    let casks: [BrewCaskInfo]
}

struct BrewFormulaInfo: Decodable, Sendable {
    let name: String
    let desc: String?
    let homepage: String?
    let versions: BrewFormulaVersions?
    let installed: [BrewInstalledEntry]?
    let outdated: Bool?
}

struct BrewFormulaVersions: Decodable, Sendable {
    let stable: String?
}

struct BrewInstalledEntry: Decodable, Sendable {
    let version: String?
    let installedAsDependency: Bool?

    enum CodingKeys: String, CodingKey {
        case version
        case installedAsDependency = "installed_as_dependency"
    }
}

struct BrewCaskInfo: Decodable, Sendable {
    let token: String
    let desc: String?
    let homepage: String?
    let version: String?
    let installed: String?
}

struct BrewOutdatedResponse: Decodable, Sendable {
    let formulae: [BrewOutdatedEntry]
    let casks: [BrewOutdatedEntry]
}

struct BrewOutdatedEntry: Decodable, Sendable {
    let name: String
    let installedVersions: [String]?
    let currentVersion: String?

    enum CodingKeys: String, CodingKey {
        case name
        case installedVersions = "installed_versions"
        case currentVersion = "current_version"
    }
}

extension BrewFormulaInfo {
    func toPackage() -> Package {
        Package(
            name: name,
            installedVersion: installed?.first?.version,
            latestVersion: versions?.stable,
            manager: .brew,
            installPath: nil,
            description: desc,
            homepage: homepage.flatMap(URL.init(string:))
        )
    }
}

extension BrewOutdatedEntry {
    func toPackage() -> Package {
        Package(
            name: name,
            installedVersion: installedVersions?.first,
            latestVersion: currentVersion,
            manager: .brew,
            installPath: nil,
            description: nil,
            homepage: nil
        )
    }
}
