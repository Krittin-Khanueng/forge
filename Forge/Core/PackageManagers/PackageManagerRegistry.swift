import Foundation

@MainActor
final class PackageManagerRegistry {
    static let shared = PackageManagerRegistry()

    private(set) var available: [PackageManagerKind: any PackageManagerProtocol] = [:]

    var detectedKinds: [PackageManagerKind] {
        available.keys.sorted { $0.displayName < $1.displayName }
    }

    private init() {}

    func detectAll() async {
        let managers: [(PackageManagerKind, any PackageManagerProtocol)] = [
            (.brew, BrewManager()),
            (.npm, NPMManager()),
            (.pnpm, PNPMManager()),
            (.yarn, YarnManager()),
            (.bun, BunManager()),
            (.uv, UVManager()),
            (.cargo, CargoManager()),
        ]

        await withTaskGroup(of: (PackageManagerKind, (any PackageManagerProtocol)?).self) { group in
            for (kind, mgr) in managers {
                group.addTask { @Sendable in
                    if await mgr.detect() != nil {
                        return (kind, mgr)
                    }
                    return (kind, nil)
                }
            }
            for await (kind, mgr) in group {
                if let mgr {
                    available[kind] = mgr
                }
            }
        }
    }

    func manager(_ kind: PackageManagerKind) -> (any PackageManagerProtocol)? {
        available[kind]
    }
}
