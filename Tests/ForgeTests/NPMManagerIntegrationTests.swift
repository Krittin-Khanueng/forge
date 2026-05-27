import Foundation
import Testing
@testable import Forge

@Suite("NPM Manager Integration Tests")
struct NPMManagerIntegrationTests {
    let npmManager = NPMManager()

    @Test(.disabled("integration — requires npm installed on host"))
    func detectNPM() async throws {
        let url = await npmManager.detect()
        let resolved = try #require(url)
        #expect(resolved.path.contains("npm"))
    }

    @Test(.disabled("integration — requires npm installed on host"))
    func installedPackagesReturnsResults() async throws {
        let packages = try await npmManager.installedPackages()
        for pkg in packages {
            #expect(pkg.manager == .npm)
            #expect(pkg.id.hasPrefix("npm:"))
        }
    }

    @Test(.disabled("integration — requires npm installed on host"))
    func outdatedPackagesHandlesNoOutdated() async throws {
        let packages = try await npmManager.outdatedPackages()
        for pkg in packages {
            #expect(pkg.manager == .npm)
            #expect(pkg.latestVersion != nil)
        }
    }

    @Test(.disabled("integration — requires npm installed on host"))
    func searchReturnsResults() async throws {
        let packages = try await npmManager.search(query: "typescript")
        let hasTypeScript = packages.contains { $0.name == "typescript" }
        #expect(hasTypeScript, "Search for 'typescript' should include 'typescript'")
    }

    @Test(.disabled("integration — requires npm installed on host"))
    func kindIsCorrect() async {
        #expect(npmManager.kind == .npm)
    }
}
