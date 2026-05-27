import Foundation
import Testing
@testable import Forge

@Suite("Binary Resolver Tests")
struct BinaryResolverTests {
    let resolver = BinaryResolver.shared

    @Test("Resolves /bin/sh")
    func resolvesSh() async throws {
        let url = try await resolver.resolve("sh")
        #expect(url.path == "/bin/sh")
    }

    @Test("Returns error for nonexistent binary")
    func failsForBogusBinary() async throws {
        await #expect(throws: BinaryResolverError.self) {
            _ = try await resolver.resolve("nonexistent_binary_xyzzy_12345")
        }
    }

    @Test("Caches successful resolutions")
    func cachesResolutions() async throws {
        await resolver.invalidateCache()

        let url1 = try await resolver.resolve("sh")
        let url2 = try await resolver.resolve("sh")

        #expect(url1 == url2)
        #expect(url1.path == "/bin/sh")
    }

    @Test("resolveAll returns results for multiple binaries")
    func resolveAllMultiple() async throws {
        let results = await resolver.resolveAll(["sh", "echo"])
        #expect(results["sh"]??.path == "/bin/sh")
        #expect(results["echo"]??.path == "/bin/echo")
    }

    @Test("invalidates cache correctly")
    func invalidatesCache() async throws {
        await resolver.invalidateCache()
        let url1 = try await resolver.resolve("sh")
        #expect(url1.path == "/bin/sh")

        await resolver.invalidateCache()
        let url2 = try await resolver.resolve("sh")
        #expect(url2.path == "/bin/sh")
    }
}
