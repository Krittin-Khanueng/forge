import Foundation
import OSLog

actor RustupDriver: EnvironmentDriverProtocol {
    nonisolated let kind: RuntimeKind = .rust
    nonisolated let source: String = "rustup"

    private let runner = ProcessRunner()
    private let logger = Logger(subsystem: "com.forge.app", category: "rust")
    private var cachedURL: URL?

    func isAvailable() async -> Bool {
        return (try? await resolveRustup()) != nil
    }

    func list() async throws -> [RuntimeInfo] {
        let rustupURL = try await resolveRustup()

        let listResult = try await runner.run(rustupURL, arguments: ["toolchain", "list"])
        let activeResult = try? await runner.run(rustupURL, arguments: ["show", "active-toolchain"])
        let activeLine = activeResult?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let lines = listResult.stdout.split(separator: "\n", omittingEmptySubsequences: true)
        var runtimes: [RuntimeInfo] = []

        for line in lines {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let isDefault = trimmed.hasSuffix("(default)")
            let isActive = activeLine.hasPrefix(trimmed.replacingOccurrences(of: "-x86_64", with: "-aarch64"))

            var version = trimmed
                .replacingOccurrences(of: "(default)", with: "")
                .replacingOccurrences(of: "(override)", with: "")
                .trimmingCharacters(in: .whitespaces)
            if version.hasPrefix("stable-") {
                version.removeFirst(7)
            } else if version.hasPrefix("nightly-") {
                version.removeFirst(8)
            } else if version.hasPrefix("beta-") {
                version.removeFirst(5)
            }

            runtimes.append(RuntimeInfo(
                id: "rust:\(version)",
                kind: .rust,
                version: version,
                path: nil,
                isActive: isDefault || isActive,
                source: "rustup"
            ))
        }

        return runtimes
    }

    func setActive(_ version: String) async throws {
        let rustupURL = try await resolveRustup()
        _ = try await runner.run(rustupURL, arguments: ["default", version])
    }

    func install(_ version: String) async throws {
        let rustupURL = try await resolveRustup()
        _ = try await runner.run(rustupURL, arguments: ["toolchain", "install", version])
    }

    func uninstall(_ version: String) async throws {
        let rustupURL = try await resolveRustup()
        _ = try await runner.run(rustupURL, arguments: ["toolchain", "uninstall", version])
    }

    private func resolveRustup() async throws -> URL {
        if let cached = cachedURL { return cached }
        let url = try await BinaryResolver.shared.resolve("rustup")
        cachedURL = url
        return url
    }
}
