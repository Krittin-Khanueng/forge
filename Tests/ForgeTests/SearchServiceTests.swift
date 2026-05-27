import Foundation
import Testing
@testable import Forge

@Suite("Search Service Tests")
struct SearchServiceTests {

    @Test("SearchHit from Package marks isInstalled")
    func searchHitFromPackage() throws {
        let pkg = Package(
            name: "ripgrep",
            installedVersion: "14.1.0",
            latestVersion: "15.1.0",
            manager: .brew,
            description: "Search tool"
        )
        let hit = SearchHit(package: pkg, isInstalled: true)
        #expect(hit.id == "brew:ripgrep")
        #expect(hit.name == "ripgrep")
        #expect(hit.manager == .brew)
        #expect(hit.isInstalled == true)
        #expect(hit.installedVersion == "14.1.0")
        #expect(hit.description == "Search tool")
    }

    @Test("SearchHit for uninstalled package")
    func searchHitUninstalled() throws {
        let pkg = Package(
            name: "neovim",
            installedVersion: nil,
            latestVersion: "0.10.0",
            manager: .brew
        )
        let hit = SearchHit(package: pkg, isInstalled: false)
        #expect(hit.isInstalled == false)
        #expect(hit.installedVersion == nil)
    }

    @Test("SearchHit ID format")
    func searchHitIDFormat() throws {
        let hit = SearchHit(
            id: "cargo:ripgrep",
            name: "ripgrep",
            manager: .cargo,
            description: "A search tool",
            isInstalled: true,
            installedVersion: "14.1.0"
        )
        #expect(hit.id == "cargo:ripgrep")
        #expect(hit.name == "ripgrep")
        #expect(hit.manager == .cargo)
    }

    @Test("SearchHit equatable")
    func searchHitEquatable() throws {
        let a = SearchHit(
            id: "brew:foo",
            name: "foo",
            manager: .brew,
            isInstalled: true
        )
        let b = SearchHit(
            id: "brew:foo",
            name: "foo",
            manager: .brew,
            isInstalled: true
        )
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)

        let c = SearchHit(
            id: "brew:bar",
            name: "bar",
            manager: .brew,
            isInstalled: false
        )
        #expect(a != c)
    }

    @Test("SearchHit dedup identification — merged by ID")
    func searchHitDedupByID() throws {
        let installed = SearchHit(
            id: "brew:ripgrep",
            name: "ripgrep",
            manager: .brew,
            description: "search tool",
            isInstalled: true,
            installedVersion: "14.1.0"
        )
        let remote = SearchHit(
            id: "brew:ripgrep",
            name: "ripgrep",
            manager: .brew,
            description: "search tool",
            isInstalled: false,
            installedVersion: nil
        )
        #expect(installed.id == remote.id)
        #expect(installed.isInstalled)
        #expect(!remote.isInstalled)
    }
}
