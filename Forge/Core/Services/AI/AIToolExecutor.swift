import Foundation

struct AIToolResult: Sendable {
    let content: String
    let isError: Bool
}

@MainActor
final class AIToolExecutor {
    private let registry: PackageManagerRegistry
    private let docker: DockerClient
    private let environments: EnvironmentService

    init(registry: PackageManagerRegistry, docker: DockerClient, environments: EnvironmentService) {
        self.registry = registry
        self.docker = docker
        self.environments = environments
    }

    func execute(toolName: String, input: [String: AnyCodable]) async throws -> AIToolResult {
        switch toolName {
        case "list_packages":
            let manager = string(from: input, key: "manager")
            return try await listPackages(manager: manager)
        case "outdated_packages":
            let manager = string(from: input, key: "manager")
            return try await listOutdatedPackages(manager: manager)
        case "search_packages":
            guard let query = string(from: input, key: "query") else {
                return AIToolResult(content: #"{"error":"missing query parameter"}"#, isError: true)
            }
            return try await searchPackages(query: query)
        case "install_package":
            guard let manager = string(from: input, key: "manager"),
                  let name = string(from: input, key: "name") else {
                return AIToolResult(content: #"{"error":"missing manager or name"}"#, isError: true)
            }
            return try await installPackage(manager: manager, name: name)
        case "uninstall_package":
            guard let manager = string(from: input, key: "manager"),
                  let name = string(from: input, key: "name") else {
                return AIToolResult(content: #"{"error":"missing manager or name"}"#, isError: true)
            }
            return try await uninstallPackage(manager: manager, name: name)
        case "update_package":
            guard let manager = string(from: input, key: "manager"),
                  let name = string(from: input, key: "name") else {
                return AIToolResult(content: #"{"error":"missing manager or name"}"#, isError: true)
            }
            return try await updatePackage(manager: manager, name: name)
        case "list_containers":
            return try await listContainers()
        case "list_environments":
            let kind = string(from: input, key: "kind")
            return try await listEnvironments(kind: kind)
        default:
            return AIToolResult(content: #"{"error":"unknown tool: \#(toolName)"}"#, isError: true)
        }
    }

    private func string(from input: [String: AnyCodable], key: String) -> String? { nil }

    private func listPackages(manager filter: String?) async throws -> AIToolResult {
        var all: [String] = []
        let kinds: [PackageManagerKind]
        if let filter, let kind = PackageManagerKind(rawValue: filter) {
            kinds = [kind]
        } else {
            kinds = registry.detectedKinds
        }
        for kind in kinds {
            guard let mgr = registry.manager(kind) else { continue }
            if let pkgs = try? await mgr.installedPackages() {
                all.append(contentsOf: pkgs.map { "\(kind.rawValue):\($0.name)@\($0.installedVersion ?? "?")" })
            }
        }
        return AIToolResult(content: jsonDictString(["packages": all, "count": all.count]), isError: false)
    }

    private func listOutdatedPackages(manager filter: String?) async throws -> AIToolResult {
        var all: [String] = []
        let kinds: [PackageManagerKind]
        if let filter, let kind = PackageManagerKind(rawValue: filter) {
            kinds = [kind]
        } else {
            kinds = registry.detectedKinds
        }
        for kind in kinds {
            guard let mgr = registry.manager(kind) else { continue }
            if let outdated = try? await mgr.outdatedPackages() {
                all.append(contentsOf: outdated.map { "\(kind.rawValue):\($0.name) \($0.installedVersion ?? "?") → \($0.latestVersion ?? "?")" })
            }
        }
        return AIToolResult(content: jsonDictString(["outdated": all, "count": all.count]), isError: false)
    }

    private func searchPackages(query: String) async throws -> AIToolResult {
        var results: [String] = []
        for kind in registry.detectedKinds {
            guard let mgr = registry.manager(kind) else { continue }
            if let pkgs = try? await mgr.search(query: query) {
                results.append(contentsOf: pkgs.map { "\(kind.rawValue):\($0.name)" })
            }
        }
        return AIToolResult(content: jsonDictString(["results": results, "count": results.count]), isError: false)
    }

    private func installPackage(manager: String, name: String) async throws -> AIToolResult {
        guard let kind = PackageManagerKind(rawValue: manager),
              let mgr = registry.manager(kind) else {
            return AIToolResult(content: #"{"error":"unknown manager: \#(manager)"}"#, isError: true)
        }
        try await mgr.install(name)
        return AIToolResult(content: #"{"installed":"\#(manager):\#(name)","status":"success"}"#, isError: false)
    }

    private func uninstallPackage(manager: String, name: String) async throws -> AIToolResult {
        guard let kind = PackageManagerKind(rawValue: manager),
              let mgr = registry.manager(kind) else {
            return AIToolResult(content: #"{"error":"unknown manager: \#(manager)"}"#, isError: true)
        }
        try await mgr.uninstall(name)
        return AIToolResult(content: #"{"removed":"\#(manager):\#(name)","status":"success"}"#, isError: false)
    }

    private func updatePackage(manager: String, name: String) async throws -> AIToolResult {
        guard let kind = PackageManagerKind(rawValue: manager),
              let mgr = registry.manager(kind) else {
            return AIToolResult(content: #"{"error":"unknown manager: \#(manager)"}"#, isError: true)
        }
        try await mgr.update(name)
        return AIToolResult(content: #"{"updated":"\#(manager):\#(name)","status":"success"}"#, isError: false)
    }

    private func listContainers() async throws -> AIToolResult {
        guard await docker.isAvailable() else {
            return AIToolResult(content: #"{"error":"Docker not available"}"#, isError: true)
        }
        let containers = try await docker.containers(all: true)
        let names = containers.map { "\($0.displayName) [\($0.state)]" }
        return AIToolResult(content: jsonDictString(["containers": names, "count": names.count]), isError: false)
    }

    private func listEnvironments(kind: String?) async throws -> AIToolResult {
        var envs: [String] = []
        if kind == nil || kind == "python" {
            envs.append(contentsOf: environments.pythonRuntimes.map { "python \($0.version)" + ($0.isActive ? " (active)" : "") })
        }
        if kind == nil || kind == "node" {
            envs.append(contentsOf: environments.nodeRuntimes.map { "node \($0.version)" + ($0.isActive ? " (active)" : "") })
        }
        if kind == nil || kind == "rust" {
            envs.append(contentsOf: environments.rustToolchains.map { "rust \($0.version)" + ($0.isActive ? " (active)" : "") })
        }
        if kind == nil || kind == "bun" {
            envs.append(contentsOf: environments.bunVersions.map { "bun \($0.version)" + ($0.isActive ? " (active)" : "") })
        }
        let json = try JSONEncoder().encode(["environments": envs])
        return AIToolResult(content: String(data: json, encoding: .utf8) ?? "{}", isError: false)
    }

    private func jsonDictString(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }
}
