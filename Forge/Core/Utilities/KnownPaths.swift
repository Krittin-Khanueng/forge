import Foundation

enum KnownPaths {
    /// Resolved once at first access. Scanning version-manager directories
    /// (nvm/fnm) hits the filesystem, and this is read on every process spawn,
    /// so the result is cached. New runtime versions are picked up on relaunch.
    static let all: [String] = {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var paths = base(home: home)
        paths.append(contentsOf: nvmPaths() ?? [])
        paths.append(contentsOf: fnmPaths(home: home) ?? [])
        return paths
    }()

    static func base(home: String) -> [String] {
        [
            "/opt/homebrew/bin",
            home + "/.bun/bin",
            home + "/.local/bin",
            home + "/.cargo/bin",
            home + "/Library/pnpm/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
        ]
    }

    static func nvmPaths() -> [String]? {
        guard let nvmDir = ProcessInfo.processInfo.environment["NVM_DIR"] else { return nil }
        let versionsPath = nvmDir + "/versions/node"
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: versionsPath) else { return nil }
        return entries.filter { $0.hasPrefix("v") }.map { "\(nvmDir)/versions/node/\($0)/bin" }
    }

    static func fnmPaths(home: String) -> [String]? {
        let fnmDefault = home + "/Library/Application Support/fnm/node-versions"
        guard FileManager.default.fileExists(atPath: fnmDefault),
              let entries = try? FileManager.default.contentsOfDirectory(atPath: fnmDefault),
              let latest = entries.sorted().last else { return nil }
        return ["\(fnmDefault)/\(latest)/installation/bin"]
    }
}
