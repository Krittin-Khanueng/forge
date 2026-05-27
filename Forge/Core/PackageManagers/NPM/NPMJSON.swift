import Foundation

struct NPMListResponse: Decodable, Sendable {
    let dependencies: [String: NPMListEntry]?
}

struct NPMListEntry: Decodable, Sendable {
    let version: String
}

extension NPMListEntry {
    func toPackage(name: String) -> Package {
        Package(
            name: name,
            installedVersion: version,
            latestVersion: nil,
            manager: .npm,
            installPath: nil,
            description: nil,
            homepage: nil
        )
    }
}

struct NPMOutdatedEntry: Decodable, Sendable {
    let current: String?
    let wanted: String?
    let latest: String?
    let location: String?
}

extension NPMOutdatedEntry {
    func toPackage(name: String) -> Package {
        Package(
            name: name,
            installedVersion: current,
            latestVersion: latest,
            manager: .npm,
            installPath: location,
            description: nil,
            homepage: nil
        )
    }
}
