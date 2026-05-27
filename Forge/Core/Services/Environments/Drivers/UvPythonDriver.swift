import Foundation
import OSLog

actor UvPythonDriver: EnvironmentDriverProtocol {
    nonisolated let kind: RuntimeKind = .python
    nonisolated let source: String = "uv"

    private let runner = ProcessRunner()
    private let logger = Logger(subsystem: "com.forge.app", category: "python")
    private var cachedURL: URL?

    func isAvailable() async -> Bool {
        return (try? await resolveUV()) != nil
    }

    func list() async throws -> [RuntimeInfo] {
        let uvURL = try await resolveUV()
        let result = try await runner.run(uvURL, arguments: ["python", "list", "--only-installed"])

        let lines = result.stdout.split(separator: "\n", omittingEmptySubsequences: true)
        var runtimes: [RuntimeInfo] = []

        for line in lines {
            guard let entry = parseListLine(String(line)) else { continue }
            runtimes.append(entry)
        }

        let activeResult = try? await runner.run(uvURL, arguments: ["python", "find"])
        let activePath = activeResult?.stdout.trimmingCharacters(in: .whitespacesAndNewlines)

        for i in runtimes.indices {
            if let activePath, let path = runtimes[i].path, activePath.hasPrefix(path) {
                runtimes[i] = RuntimeInfo(
                    id: runtimes[i].id,
                    kind: .python,
                    version: runtimes[i].version,
                    path: runtimes[i].path,
                    isActive: true,
                    source: "uv"
                )
            }
        }

        return runtimes
    }

    func setActive(_ version: String) async throws {
        // uv python doesn't support "default" — use pin API or skip
        logger.warning("uv python setActive not supported — use uv python pin")
    }

    func install(_ version: String) async throws {
        let uvURL = try await resolveUV()
        _ = try await runner.run(uvURL, arguments: ["python", "install", version])
    }

    func uninstall(_ version: String) async throws {
        let uvURL = try await resolveUV()
        _ = try await runner.run(uvURL, arguments: ["python", "uninstall", version])
    }

    private func resolveUV() async throws -> URL {
        if let cached = cachedURL { return cached }
        let url = try await BinaryResolver.shared.resolve("uv")
        cachedURL = url
        return url
    }

    private func parseListLine(_ line: String) -> RuntimeInfo? {
        let cleaned = line.replacingOccurrences(of: "->", with: "")
        let parts = cleaned.split(separator: " ", omittingEmptySubsequences: true)
        guard !parts.isEmpty else { return nil }

        let first = String(parts[0])
        let version = first.hasPrefix("cpython-") ? String(first.dropFirst(8)) : first
        guard !version.isEmpty else { return nil }

        let path = parts.count >= 2 ? String(parts[1]) : nil

        return RuntimeInfo(
            id: "python:\(version)",
            kind: .python,
            version: version,
            path: path,
            isActive: false,
            source: "uv"
        )
    }
}
