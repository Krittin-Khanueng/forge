import Foundation
import OSLog

actor DockerClient {
    private let runner = ProcessRunner()
    private let logger = Logger(subsystem: "com.forge.app", category: "docker")
    private var cachedURL: URL?

    func isAvailable() async -> Bool {
        do {
            let dockerURL = try await resolveDocker()
            _ = try await runner.run(dockerURL, arguments: ["version", "--format", "json"])
            return true
        } catch {
            logger.warning("Docker daemon not available: \(error.localizedDescription)")
            return false
        }
    }

    func dockerVersion() async -> String? {
        guard let dockerURL = try? await resolveDocker() else { return nil }
        let result = try? await runner.run(dockerURL, arguments: ["version", "--format", "json"])
        return result?.stdout
    }

    func containers(all: Bool) async throws -> [DockerContainer] {
        let dockerURL = try await resolveDocker()
        var args = ["ps", "--format", "json"]
        if all { args.append("--all") }
        let result = try await runner.run(dockerURL, arguments: args)
        return decodeNDJSON(result.stdout)
    }

    func images() async throws -> [DockerImage] {
        let dockerURL = try await resolveDocker()
        let result = try await runner.run(dockerURL, arguments: ["image", "ls", "--format", "json"])
        return decodeImagesNDJSON(result.stdout)
    }

    func start(containerID: String) async throws {
        let dockerURL = try await resolveDocker()
        _ = try await runner.run(dockerURL, arguments: ["start", containerID])
    }

    func stop(containerID: String) async throws {
        let dockerURL = try await resolveDocker()
        _ = try await runner.run(dockerURL, arguments: ["stop", containerID])
    }

    func restart(containerID: String) async throws {
        let dockerURL = try await resolveDocker()
        _ = try await runner.run(dockerURL, arguments: ["restart", containerID])
    }

    func removeContainer(_ id: String, force: Bool) async throws {
        let dockerURL = try await resolveDocker()
        var args = ["rm", id]
        if force { args.append("--force") }
        _ = try await runner.run(dockerURL, arguments: args)
    }

    func removeImage(_ id: String, force: Bool) async throws {
        let dockerURL = try await resolveDocker()
        var args = ["rmi", id]
        if force { args.append("--force") }
        _ = try await runner.run(dockerURL, arguments: args)
    }

    func logs(containerID: String, follow: Bool) async throws -> AsyncThrowingStream<String, Error> {
        let dockerURL = try await resolveDocker()
        var args = ["logs"]
        if follow { args.append("--follow") }
        args.append(containerID)
        let events = await runner.stream(dockerURL, arguments: args)

        return AsyncThrowingStream { continuation in
            let task = Task { @Sendable in
                do {
                    for try await event in events {
                        switch event {
                        case .stdoutLine(let line):
                            continuation.yield(line)
                        case .stderrLine(let line):
                            continuation.yield(line)
                        case .exited:
                            continuation.finish()
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }

    private func resolveDocker() async throws -> URL {
        if let cached = cachedURL { return cached }
        let url = try await BinaryResolver.shared.resolve("docker")
        cachedURL = url
        return url
    }

    private func decodeNDJSON<T: Decodable>(_ output: String) -> [T] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line in
                try? decoder.decode(T.self, from: Data(line.utf8))
            }
    }

    private func decodeImagesNDJSON(_ output: String) -> [DockerImage] {
        decodeNDJSON(output)
    }
}
