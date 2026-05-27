import Foundation
import Testing
@testable import Forge

@Suite("PNPM Manager Integration Tests")
struct PNPMManagerIntegrationTests {
    let pnpmManager = PNPMManager()

    @Test(.disabled("integration — requires pnpm installed on host"))
    func detectPNPM() async throws {
        let url = await pnpmManager.detect()
        let resolved = try #require(url)
        #expect(resolved.path.contains("pnpm"))
    }

    @Test(.disabled("integration — requires pnpm installed on host"))
    func installedPackagesReturnsResults() async throws {
        let packages = try await pnpmManager.installedPackages()
        for pkg in packages {
            #expect(pkg.manager == .pnpm)
            #expect(pkg.id.hasPrefix("pnpm:"))
        }
    }

    @Test(.disabled("integration — requires pnpm installed on host"))
    func outdatedPackagesRunsWithoutError() async throws {
        let packages = try await pnpmManager.outdatedPackages()
        for pkg in packages {
            #expect(pkg.manager == .pnpm)
        }
    }

    @Test(.disabled("integration — requires pnpm installed on host"))
    func kindIsCorrect() async {
        #expect(pnpmManager.kind == .pnpm)
    }
}
