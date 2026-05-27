import Foundation

enum ForgeTool: String, CaseIterable, Sendable {
    case listPackages
    case outdatedPackages
    case searchPackages
    case installPackage
    case uninstallPackage
    case updatePackage
    case listContainers
    case listEnvironments

    var definition: AITool {
        switch self {
        case .listPackages:
            return AITool(
                name: "list_packages",
                description: "List all installed packages from all detected package managers",
                inputSchema: [
                    "manager": AnyCodable(["type": AnyCodable("string"), "description": AnyCodable("Optional: filter by manager (brew, npm, cargo, etc)")])
                ]
            )
        case .outdatedPackages:
            return AITool(
                name: "outdated_packages",
                description: "List packages that have available updates",
                inputSchema: [
                    "manager": AnyCodable(["type": AnyCodable("string"), "description": AnyCodable("Optional: filter by manager")])
                ]
            )
        case .searchPackages:
            return AITool(
                name: "search_packages",
                description: "Search for packages across all registries",
                inputSchema: [
                    "query": AnyCodable(["type": AnyCodable("string"), "description": AnyCodable("Search query string")])
                ]
            )
        case .installPackage:
            return AITool(
                name: "install_package",
                description: "Install a package using the specified package manager",
                inputSchema: [
                    "manager": AnyCodable(["type": AnyCodable("string"), "description": AnyCodable("Package manager to use")]),
                    "name": AnyCodable(["type": AnyCodable("string"), "description": AnyCodable("Package name to install")])
                ]
            )
        case .uninstallPackage:
            return AITool(
                name: "uninstall_package",
                description: "Uninstall a package",
                inputSchema: [
                    "manager": AnyCodable(["type": AnyCodable("string"), "description": AnyCodable("Package manager")]),
                    "name": AnyCodable(["type": AnyCodable("string"), "description": AnyCodable("Package name")])
                ]
            )
        case .updatePackage:
            return AITool(
                name: "update_package",
                description: "Update a package to the latest version",
                inputSchema: [
                    "manager": AnyCodable(["type": AnyCodable("string"), "description": AnyCodable("Package manager")]),
                    "name": AnyCodable(["type": AnyCodable("string"), "description": AnyCodable("Package name")])
                ]
            )
        case .listContainers:
            return AITool(
                name: "list_containers",
                description: "List all Docker containers and their status",
                inputSchema: [
                    "all": AnyCodable(["type": AnyCodable("boolean"), "description": AnyCodable("Include stopped containers")])
                ]
            )
        case .listEnvironments:
            return AITool(
                name: "list_environments",
                description: "List installed development runtimes (Python, Node, Rust, Bun)",
                inputSchema: [
                    "kind": AnyCodable(["type": AnyCodable("string"), "description": AnyCodable("Runtime kind: python, node, rust, bun")])
                ]
            )
        }
    }
}
