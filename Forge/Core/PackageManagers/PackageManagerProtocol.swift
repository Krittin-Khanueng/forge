import Foundation

enum ManagerFeature: Sendable { case outdated, search }
enum FeatureStatus: Sendable { case available, missing(reason: String) }

protocol PackageManagerProtocol: Sendable {
    var kind: PackageManagerKind { get }

    func detect() async -> URL?

    func installedPackages() async throws -> [Package]
    func outdatedPackages() async throws -> [Package]
    func search(query: String) async throws -> [Package]
    func install(_ name: String) async throws
    func uninstall(_ name: String) async throws
    func update(_ name: String) async throws
    func updateAll() async throws

    func featureStatus(_ feature: ManagerFeature) -> FeatureStatus
}

extension PackageManagerProtocol {
    func featureStatus(_ feature: ManagerFeature) -> FeatureStatus { .available }
}
