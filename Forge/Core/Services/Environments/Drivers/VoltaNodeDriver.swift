import Foundation
import OSLog

actor VoltaNodeDriver: EnvironmentDriverProtocol {
    nonisolated let kind: RuntimeKind = .node
    nonisolated let source: String = "volta"

    private let runner = ProcessRunner()
    private let logger = Logger(subsystem: "com.forge.app", category: "node")
    private var cachedURL: URL?

    func isAvailable() async -> Bool {
        return (try? await resolveVolta()) != nil
    }

    func list() async throws -> [RuntimeInfo] {
        let voltaURL = try await resolveVolta()

        let listResult = try await runner.run(voltaURL, arguments: ["list", "node", "--format=plain"])
        let currentResult = try? await runner.run(voltaURL, arguments: ["which", "node"])

        let currentPath = currentResult?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let lines = listResult.stdout.split(separator: "\n", omittingEmptySubsequences: true)
        var runtimes: [RuntimeInfo] = []

        for line in lines {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let version = trimmed.hasPrefix("v") ? String(trimmed.dropFirst()) : trimmed
            let isActive = currentPath.contains(version)

            runtimes.append(RuntimeInfo(
                id: "node:\(version)",
                kind: .node,
                version: version,
                path: nil,
                isActive: isActive,
                source: "volta"
            ))
        }

        return runtimes
    }

    func setActive(_ version: String) async throws {
        let voltaURL = try await resolveVolta()
        _ = try await runner.run(voltaURL, arguments: ["install", "node@\(version)"])
    }

    func install(_ version: String) async throws {
        let voltaURL = try await resolveVolta()
        _ = try await runner.run(voltaURL, arguments: ["install", "node@\(version)"])
    }

    func uninstall(_ version: String) async throws {
        let voltaURL = try await resolveVolta()
        _ = try await runner.run(voltaURL, arguments: ["uninstall", "node@\(version)"])
    }

    private func resolveVolta() async throws -> URL {
        if let cached = cachedURL { return cached }
        let url = try await BinaryResolver.shared.resolve("volta")
        cachedURL = url
        return url
    }
}
