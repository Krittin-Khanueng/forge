import Testing
@testable import Forge

@Suite struct BinaryResolverTests {
    @Test func resolvesHomebrewBinaries() async throws {
        let url = try await BinaryResolver.shared.resolve("brew")
        #expect(url.path.contains("brew"))
    }

    @Test func resolvesUserBinaries() async throws {
        let resolver = BinaryResolver.shared
        await resolver.invalidateCache()

        let url1 = try? await resolver.resolve("cargo")
        let url2 = try? await resolver.resolve("uv")
        let url3 = try? await resolver.resolve("bun")

        #expect(url1 != nil, "cargo should be found")
        #expect(url2 != nil, "uv should be found")
        #expect(url3 != nil, "bun should be found")
    }
}
