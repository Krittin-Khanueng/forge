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

    var manager: PackageManagerKind {
        PackageManagerKind(rawValue: managerRaw) ?? .brew
    }

    init(
        name: String,
        installedVersion: String?,
        latestVersion: String?,
        manager: PackageManagerKind,
        lastSeen: Date = Date()
    ) {
        self.id = "\(manager.rawValue):\(name)"
        self.name = name
        self.installedVersion = installedVersion
        self.latestVersion = latestVersion
        self.managerRaw = manager.rawValue
        self.lastSeen = lastSeen
    }

    convenience init(from package: Package, lastSeen: Date = Date()) {
        self.init(
            name: package.name,
            installedVersion: package.installedVersion,
            latestVersion: package.latestVersion,
            manager: package.manager,
            lastSeen: lastSeen
        )
    }

    func toPackage() -> Package {
        Package(
            name: name,
            installedVersion: installedVersion,
            latestVersion: latestVersion,
            manager: manager,
            installPath: nil,
            description: nil,
            homepage: nil
        )
    }
}
