import Foundation
import OSLog

actor FnmNodeDriver: EnvironmentDriverProtocol {
    nonisolated let kind: RuntimeKind = .node
    nonisolated let source: String = "fnm"

    private let runner = ProcessRunner()
    private let logger = Logger(subsystem: "com.forge.app", category: "node")
    private var cachedURL: URL?

    func isAvailable() async -> Bool {
        return (try? await resolveFnm()) != nil
    }

    func list() async throws -> [RuntimeInfo] {
        let fnmURL = try await resolveFnm()

        let listResult = try await runner.run(fnmURL, arguments: ["list", "--json"])
        let activeResult = try? await runner.run(fnmURL, arguments: ["current"])
        let activeVersion = activeResult?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        struct FnmEntry: Decodable {
            let version: String
            let path: String?
        }

        let entries: [FnmEntry] = try JSONOutputDecoder.decode([FnmEntry].self, from: listResult.stdout)

        return entries.map { entry in
            RuntimeInfo(
                id: "node:\(entry.version)",
                kind: .node,
                version: entry.version.hasPrefix("v") ? String(entry.version.dropFirst()) : entry.version,
                path: entry.path,
                isActive: activeVersion == entry.version,
                source: "fnm"
            )
        }
    }

    func setActive(_ version: String) async throws {
        let fnmURL = try await resolveFnm()
        _ = try await runner.run(fnmURL, arguments: ["use", version])
    }

    func install(_ version: String) async throws {
        let fnmURL = try await resolveFnm()
        _ = try await runner.run(fnmURL, arguments: ["install", version])
    }

    func uninstall(_ version: String) async throws {
        let fnmURL = try await resolveFnm()
        _ = try await runner.run(fnmURL, arguments: ["uninstall", version])
    }

    private func resolveFnm() async throws -> URL {
        if let cached = cachedURL { return cached }
        let url = try await BinaryResolver.shared.resolve("fnm")
        cachedURL = url
        return url
    }
}
