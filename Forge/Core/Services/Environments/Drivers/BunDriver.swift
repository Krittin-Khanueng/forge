import Foundation
import OSLog

actor BunDriver: EnvironmentDriverProtocol {
    nonisolated let kind: RuntimeKind = .bun
    nonisolated let source: String = "bun"

    private let runner = ProcessRunner()
    private let logger = Logger(subsystem: "com.forge.app", category: "bun")
    private var cachedURL: URL?

    func isAvailable() async -> Bool {
        return (try? await resolveBun()) != nil
    }

    func list() async throws -> [RuntimeInfo] {
        let bunURL = try await resolveBun()
        let result = try await runner.run(bunURL, arguments: ["--version"])
        let version = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

        return [RuntimeInfo(
            id: "bun:\(version)",
            kind: .bun,
            version: version,
            path: bunURL.path,
            isActive: true,
            source: "bun"
        )]
    }

    func setActive(_ version: String) async throws {
        logger.warning("Bun doesn't support multi-version management yet")
    }

    func install(_ version: String) async throws {
        logger.warning("Bun version install not supported — use 'bun upgrade'")
    }

    func uninstall(_ version: String) async throws {
        logger.warning("Bun doesn't support multi-version management yet")
    }

    private func resolveBun() async throws -> URL {
        if let cached = cachedURL { return cached }
        let url = try await BinaryResolver.shared.resolve("bun")
        cachedURL = url
        return url
    }
}
