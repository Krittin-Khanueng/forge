import Foundation
import OSLog

actor SystemNodeDriver: EnvironmentDriverProtocol {
    nonisolated let kind: RuntimeKind = .node
    nonisolated let source: String = "system"

    private let runner = ProcessRunner()
    private let logger = Logger(subsystem: "com.forge.app", category: "node")

    func isAvailable() async -> Bool {
        return (try? await BinaryResolver.shared.resolve("node")) != nil
    }

    func list() async throws -> [RuntimeInfo] {
        let nodeURL = try await BinaryResolver.shared.resolve("node")
        let result = try await runner.run(nodeURL, arguments: ["--version"])
        let version = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let ver = version.hasPrefix("v") ? String(version.dropFirst()) : version

        return [RuntimeInfo(
            id: "node:\(ver)",
            kind: .node,
            version: ver,
            path: nodeURL.path,
            isActive: true,
            source: "system"
        )]
    }

    func setActive(_ version: String) async throws {
        logger.warning("System Node doesn't support multi-version management")
    }

    func install(_ version: String) async throws {
        logger.warning("System Node doesn't support version installation")
    }

    func uninstall(_ version: String) async throws {
        logger.warning("System Node doesn't support version uninstallation")
    }
}
