import Foundation
import Testing
@testable import Forge

@Suite("AI Tool Executor Tests")
@MainActor
struct AIToolExecutorTests {

    let executor = AIToolExecutor(
        registry: PackageManagerRegistry.shared,
        docker: DockerClient(),
        environments: EnvironmentService()
    )

    @Test("list_packages tool returns JSON with packages key")
    func listPackagesTool() async throws {
        let result = try await executor.execute(
            toolName: "list_packages",
            input: [:]
        )
        #expect(result.isError == false)
        #expect(result.content.contains("packages") || result.content.contains("count"))
    }

    @Test("list_containers tool handles Docker unavailable")
    func listContainersWhenDockerUnavailable() async throws {
        let result = try await executor.execute(
            toolName: "list_containers",
            input: [:]
        )
        #expect(result.content.contains("Docker") || result.content.contains("containers"))
    }

    @Test("install_package rejects missing manager")
    func installPackageMissingManager() async throws {
        let result = try await executor.execute(
            toolName: "install_package",
            input: ["name": AnyCodable("test")]
        )
        #expect(result.isError == true)
        #expect(result.content.contains("missing"))
    }

    @Test("install_package rejects missing name")
    func installPackageMissingName() async throws {
        let result = try await executor.execute(
            toolName: "install_package",
            input: ["manager": AnyCodable("brew")]
        )
        #expect(result.isError == true)
        #expect(result.content.contains("missing"))
    }

    @Test("unknown tool returns error")
    func unknownTool() async throws {
        let result = try await executor.execute(
            toolName: "nonexistent_tool",
            input: [:]
        )
        #expect(result.isError == true)
        #expect(result.content.contains("unknown"))
    }

    @Test("search_packages rejects missing query")
    func searchPackagesMissingQuery() async throws {
        let result = try await executor.execute(
            toolName: "search_packages",
            input: [:]
        )
        #expect(result.isError == true)
        #expect(result.content.contains("missing"))
    }

    @Test("ForgeTool definitions have names and descriptions")
    func forgeToolDefinitions() {
        for tool in ForgeTool.allCases {
            let def = tool.definition
            #expect(!def.name.isEmpty)
            #expect(!def.description.isEmpty)
        }
    }
}
