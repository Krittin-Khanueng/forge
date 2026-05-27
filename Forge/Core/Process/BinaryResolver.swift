import Foundation
import OSLog

actor BinaryResolver {
    static let shared = BinaryResolver()

    private var cache: [String: URL] = [:]

    private var hardcodedPrefixes: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [
            "/opt/homebrew/bin",
            home + "/.bun/bin",
            home + "/.local/bin",
            home + "/.cargo/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
        ]
    }

    private let logger = Logger(subsystem: "com.forge.app", category: "process")

    func resolve(_ name: String) async throws -> URL {
        if let cached = cache[name] {
            logger.debug("BinaryResolver cache hit: \(name) → \(cached.path)")
            return cached
        }

        for prefix in hardcodedPrefixes {
            let url = URL(fileURLWithPath: "\(prefix)/\(name)")
            if FileManager.default.isExecutableFile(atPath: url.path) {
                cache[name] = url
                logger.debug("BinaryResolver found: \(name) → \(url.path)")
                return url
            }
        }

        do {
            let path = try await resolveViaShell(name)
            let url = URL(fileURLWithPath: path)
            cache[name] = url
            logger.debug("BinaryResolver shell resolved: \(name) → \(path)")
            return url
        } catch {
            logger.warning("BinaryResolver not found: \(name)")
            throw BinaryResolverError.notFound(name)
        }
    }

    func resolveAll(_ names: [String]) async -> [String: URL?] {
        await withTaskGroup(of: (String, URL?).self) { group in
            for name in names {
                group.addTask {
                    let url = try? await self.resolve(name)
                    return (name, url)
                }
            }
            var result: [String: URL?] = [:]
            for await (name, url) in group {
                result[name] = url
            }
            return result
        }
    }

    func invalidateCache() {
        cache.removeAll()
        logger.debug("BinaryResolver cache cleared")
    }

    private func resolveViaShell(_ name: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lc", "command -v \(name)"]
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            process.environment = [
                "PATH": "/opt/homebrew/bin:\(home)/.bun/bin:\(home)/.local/bin:\(home)/.cargo/bin:/usr/local/bin:/usr/bin:/bin"
            ]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice

            process.terminationHandler = { proc in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if proc.terminationStatus == 0 && !output.isEmpty {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(
                        throwing: BinaryResolverError.lookupFailed(
                            name,
                            underlying: NSError(
                                domain: "BinaryResolver",
                                code: Int(proc.terminationStatus),
                                userInfo: [NSLocalizedDescriptionKey: "command -v failed"]
                            )
                        )
                    )
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(
                    throwing: BinaryResolverError.lookupFailed(name, underlying: error)
                )
            }
        }
    }
}

enum BinaryResolverError: Error, Sendable {
    case notFound(String)
    case lookupFailed(String, underlying: Error)
}
