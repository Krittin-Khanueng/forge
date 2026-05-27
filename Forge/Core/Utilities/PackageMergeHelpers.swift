import Foundation

enum PackageMergeHelpers {
    static func indexByID(_ packages: [Package]) -> [Package.ID: Int] {
        Dictionary(uniqueKeysWithValues: packages.enumerated().map { ($0.element.id, $0.offset) })
    }

    static func mergeOutdated(_ outdated: [Package], into all: inout [Package]) {
        let index = indexByID(all)
        for outdatedPkg in outdated {
            guard let idx = index[outdatedPkg.id] else { continue }
            let existing = all[idx]
            all[idx] = Package(
                name: existing.name,
                installedVersion: existing.installedVersion,
                latestVersion: outdatedPkg.latestVersion,
                manager: existing.manager,
                installPath: existing.installPath,
                description: existing.description,
                homepage: existing.homepage
            )
        }
    }

    static func outdatedByManager(from packages: [Package]) -> [PackageManagerKind: [Package]] {
        Dictionary(grouping: packages.filter(\.isOutdated), by: \.manager)
            .mapValues { packages in
                packages.sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
            }
    }

    static func managerCounts(from packages: [Package]) -> [PackageManagerKind: Int] {
        Dictionary(grouping: packages, by: \.manager).mapValues(\.count)
    }

    static func sortedByName(_ packages: [Package]) -> [Package] {
        packages.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}
