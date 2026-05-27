import Foundation
import Testing
@testable import Forge

@Suite("Brew Manager Integration Tests")
struct BrewManagerIntegrationTests {
    let brewManager = BrewManager()

    @Test(.disabled("integration — requires brew installed on host"))
    func detectBrew() async throws {
        let url = await brewManager.detect()
        let resolved = try #require(url)
        #expect(resolved.path.contains("brew"))
    }

    @Test(.disabled("integration — requires brew installed on host"))
    func installedPackagesReturnsResults() async throws {
        let packages = try await brewManager.installedPackages()
        #expect(!packages.isEmpty, "Expected at least one installed package")

        if let first = packages.first {
            #expect(!first.name.isEmpty)
            #expect(first.manager == .brew)
            #expect(first.id.hasPrefix("brew:"))
        }
    }

    @Test(.disabled("integration — requires brew installed on host"))
    func outdatedPackagesRunsWithoutError() async throws {
        let packages = try await brewManager.outdatedPackages()
        for pkg in packages {
            #expect(pkg.manager == .brew)
            #expect(pkg.isOutdated == true)
        }
    }

    @Test(.disabled("integration — requires brew installed on host"))
    func searchReturnsResults() async throws {
        let packages = try await brewManager.search(query: "ripgrep")
        let hasRipgrep = packages.contains { $0.name == "ripgrep" }
        #expect(hasRipgrep, "Search for 'ripgrep' should include 'ripgrep' itself")
    }

    @Test(.disabled("integration — requires brew installed on host"))
    func installedAndOutdatedCorrelate() async throws {
        let installed = try await brewManager.installedPackages()
        let outdated = try await brewManager.outdatedPackages()

        let outdatedNames = Set(outdated.map(\.name))
        let installedNames = Set(installed.map(\.name))

        for name in outdatedNames {
            #expect(installedNames.contains(name), "Outdated package '\(name)' should be in installed list")
        }
    }
}
