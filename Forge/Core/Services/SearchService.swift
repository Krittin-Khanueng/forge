import Foundation
import OSLog

@Observable
@MainActor
final class SearchService {
    var query: String = ""
    var localResults: [SearchHit] = []
    var remoteResults: [SearchHit] = []
    var isSearchingRemote: Bool = false
    var error: String?

    private let registry = PackageManagerRegistry.shared
    private let cache = PackageCache(container: StorageStack.shared.container)
    private let logger = Logger.ui
    private var remoteTask: Task<Void, Never>?

    func updateQuery(_ q: String) async {
        query = q

        guard !q.trimmingCharacters(in: .whitespaces).isEmpty else {
            localResults = []
            remoteResults = []
            isSearchingRemote = false
            error = nil
            remoteTask?.cancel()
            return
        }

        let installed = (try? cache.all(manager: nil)) ?? []
        localResults = installed
            .filter { $0.name.localizedCaseInsensitiveContains(q) }
            .map { SearchHit(package: $0, isInstalled: true) }

        remoteTask?.cancel()

        let capturedQuery = q
        let installedForDedup = installed
        remoteTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .milliseconds(250))
                try Task.checkCancellation()

                isSearchingRemote = true
                error = nil

                let results = await performRemoteSearch(capturedQuery, installed: installedForDedup)

                try Task.checkCancellation()

                remoteResults = results
                isSearchingRemote = false
            } catch is CancellationError {
                return
            } catch {
                self.error = error.localizedDescription
                isSearchingRemote = false
                logger.error("Remote search failed: \(error.localizedDescription)")
            }
        }
    }

    func install(_ name: String, manager kind: PackageManagerKind) async {
        guard let manager = registry.manager(kind) else { return }
        do {
            try await manager.install(name)
            logger.info("Installed \(name) via \(kind.displayName)")
        } catch {
            self.error = error.localizedDescription
            logger.error("Install failed for \(name): \(error.localizedDescription)")
        }
    }

    private func performRemoteSearch(_ q: String, installed: [Package]) async -> [SearchHit] {
        let installedNames = Set(installed.map { $0.name.lowercased() })
        var hits: [SearchHit] = []

        await withTaskGroup(of: [(PackageManagerKind, [Package])].self) { group in
            for kind in registry.detectedKinds {
                guard let manager = registry.manager(kind) else { continue }
                group.addTask { @Sendable in
                    if let results = try? await manager.search(query: q) {
                        return [(kind, results)]
                    }
                    return []
                }
            }

            for await pairs in group {
                for (kind, packages) in pairs {
                    for pkg in packages {
                        let isInstalled = installedNames.contains(pkg.name.lowercased())
                        let installedVersion = isInstalled
                            ? installed.first(where: { $0.name.lowercased() == pkg.name.lowercased() })?.installedVersion
                            : nil
                        hits.append(SearchHit(
                            id: pkg.id,
                            name: pkg.name,
                            manager: kind,
                            description: pkg.description,
                            isInstalled: isInstalled,
                            installedVersion: installedVersion
                        ))
                    }
                }
            }
        }

        hits.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        return hits
    }
}

struct SearchHit: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let manager: PackageManagerKind
    let description: String?
    let isInstalled: Bool
    let installedVersion: String?

    init(
        id: String,
        name: String,
        manager: PackageManagerKind,
        description: String? = nil,
        isInstalled: Bool,
        installedVersion: String? = nil
    ) {
        self.id = id
        self.name = name
        self.manager = manager
        self.description = description
        self.isInstalled = isInstalled
        self.installedVersion = installedVersion
    }
}

extension SearchHit {
    init(package: Package, isInstalled: Bool) {
        self.id = package.id
        self.name = package.name
        self.manager = package.manager
        self.description = package.description
        self.isInstalled = isInstalled
        self.installedVersion = package.installedVersion
    }
}
