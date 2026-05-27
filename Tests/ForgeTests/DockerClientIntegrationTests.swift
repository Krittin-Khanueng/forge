import Foundation
import Testing
@testable import Forge

@Suite("Docker Client Integration Tests")
struct DockerClientIntegrationTests {

    let client = DockerClient()

    @Test(.disabled("integration — requires Docker daemon running"))
    func isAvailableReturnsTrueWhenDockerRunning() async {
        let available = await client.isAvailable()
        #expect(available == true)
    }

    @Test(.disabled("integration — requires Docker daemon running"))
    func containersReturnsResults() async throws {
        let containers = try await client.containers(all: true)
        #expect(!containers.isEmpty)
    }

    @Test(.disabled("integration — requires Docker daemon running"))
    func imagesReturnsResults() async throws {
        let images = try await client.images()
        #expect(!images.isEmpty)
    }
}
