import Foundation

enum PackageManagerKind: String, CaseIterable, Codable, Sendable, Hashable {
    case brew
    case npm
    case pnpm
    case yarn
    case bun
    case uv
    case cargo

    var displayName: String {
        switch self {
        case .brew:  return "Homebrew"
        case .npm:   return "npm"
        case .pnpm:  return "pnpm"
        case .yarn:  return "Yarn"
        case .bun:   return "Bun"
        case .uv:    return "uv"
        case .cargo: return "Cargo"
        }
    }

    var systemImage: String {
        switch self {
        case .brew:  return "mug.fill"
        case .npm:   return "cube.box"
        case .pnpm:  return "shippingbox"
        case .yarn:  return "circle.hexagongrid"
        case .bun:   return "takeoutbag.and.cup.and.straw"
        case .uv:    return "sun.max"
        case .cargo: return "box.truck"
        }
    }
}

struct Package: Identifiable, Hashable, Sendable, Codable {
    let name: String
    let installedVersion: String?
    let latestVersion: String?
    let manager: PackageManagerKind
    let installPath: String?
    let description: String?
    let homepage: URL?

    var id: String { "\(manager.rawValue):\(name)" }

    var isOutdated: Bool {
        guard let installed = installedVersion,
              let latest = latestVersion else { return false }
        return latest != installed
    }

    var status: PackageStatus {
        if installedVersion == nil {
            return latestVersion != nil ? .notInstalled : .unknown
        }
        if latestVersion == nil {
            return .upToDate
        }
        return isOutdated ? .outdated : .upToDate
    }

    enum CodingKeys: String, CodingKey {
        case name
        case installedVersion
        case latestVersion
        case manager
        case installPath
        case description
        case homepage
    }

    init(
        name: String,
        installedVersion: String? = nil,
        latestVersion: String? = nil,
        manager: PackageManagerKind,
        installPath: String? = nil,
        description: String? = nil,
        homepage: URL? = nil
    ) {
        self.name = name
        self.installedVersion = installedVersion
        self.latestVersion = latestVersion
        self.manager = manager
        self.installPath = installPath
        self.description = description
        self.homepage = homepage
    }
}
