import Foundation
import OSLog

actor NNodeDriver: EnvironmentDriverProtocol {
    nonisolated let kind: RuntimeKind = .node
    nonisolated let source: String = "n"

    private let runner = ProcessRunner()
    private let logger = Logger(subsystem: "com.forge.app", category: "node")
    private var cachedURL: URL?

    func isAvailable() async -> Bool {
        return (try? await resolveN()) != nil
    }

    func list() async throws -> [RuntimeInfo] {
        let nURL = try await resolveN()

        let listResult = try await runner.run(nURL, arguments: ["ls", "--json"])
        let currentResult = try? await runner.run(nURL, arguments: ["which"])
        let currentPath = currentResult?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        struct NEntry: Decodable {
            let version: String
            let path: String?
        }

        let entries: [NEntry] = try JSONOutputDecoder.decode([NEntry].self, from: listResult.stdout)
        var runtimes: [RuntimeInfo] = []

        for entry in entries {
            let ver = entry.version.hasPrefix("node/") ? String(entry.version.dropFirst(5)) : entry.version
            let isActive = currentPath.contains(ver)

            runtimes.append(RuntimeInfo(
                id: "node:\(ver)",
                kind: .node,
                version: ver,
                path: entry.path,
                isActive: isActive,
                source: "n"
            ))
        }

        return runtimes
    }

    func setActive(_ version: String) async throws {
        let nURL = try await resolveN()
        _ = try await runner.run(nURL, arguments: ["use", version])
    }

    func install(_ version: String) async throws {
        let nURL = try await resolveN()
        _ = try await runner.run(nURL, arguments: ["install", version])
    }

    func uninstall(_ version: String) async throws {
        let nURL = try await resolveN()
        _ = try await runner.run(nURL, arguments: ["rm", version])
    }

    private func resolveN() async throws -> URL {
        if let cached = cachedURL { return cached }
        let url = try await BinaryResolver.shared.resolve("n")
        cachedURL = url
        return url
    }
}
