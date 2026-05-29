import Foundation
import SwiftData

@Model
final class CachedPackage {
    @Attribute(.unique) var id: String
    var name: String
    var installedVersion: String?
    var latestVersion: String?
    var managerRaw: String
    var lastSeen: Date
    var installPath: String?
    var desc: String?
    var homepageURL: String?

    var manager: PackageManagerKind {
        PackageManagerKind(rawValue: managerRaw) ?? .brew
    }

    init(
        name: String,
        installedVersion: String?,
        latestVersion: String?,
        manager: PackageManagerKind,
        installPath: String? = nil,
        description: String? = nil,
        homepageURL: String? = nil,
        lastSeen: Date = Date()
    ) {
        self.id = "\(manager.rawValue):\(name)"
        self.name = name
        self.installedVersion = installedVersion
        self.latestVersion = latestVersion
        self.managerRaw = manager.rawValue
        self.installPath = installPath
        self.desc = description
        self.homepageURL = homepageURL
        self.lastSeen = lastSeen
    }

    convenience init(from package: Package, lastSeen: Date = Date()) {
        self.init(
            name: package.name,
            installedVersion: package.installedVersion,
            latestVersion: package.latestVersion,
            manager: package.manager,
            installPath: package.installPath,
            description: package.description,
            homepageURL: package.homepage?.absoluteString,
            lastSeen: lastSeen
        )
    }

    func toPackage() -> Package {
        Package(
            name: name,
            installedVersion: installedVersion,
            latestVersion: latestVersion,
            manager: manager,
            installPath: installPath,
            description: desc,
            homepage: homepageURL.flatMap(URL.init)
        )
    }
}
