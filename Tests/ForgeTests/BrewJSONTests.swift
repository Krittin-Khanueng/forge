import Foundation
import Testing
@testable import Forge

@Suite("Brew JSON Tests")
struct BrewJSONTests {
    let decoder = JSONDecoder()

    @Test("Decodes brew info --json=v2 response")
    func decodesBrewInfoResponse() throws {
        let json = #"""
        {
            "formulae": [
                {
                    "name": "ripgrep",
                    "full_name": "ripgrep",
                    "tap": "homebrew/core",
                    "oldnames": [],
                    "aliases": ["rg"],
                    "versioned_formulae": [],
                    "desc": "Search tool like grep and The Silver Searcher",
                    "license": "Unlicense",
                    "homepage": "https://github.com/BurntSushi/ripgrep",
                    "versions": {
                        "stable": "15.1.0",
                        "head": "HEAD",
                        "bottle": true
                    },
                    "urls": {},
                    "revision": 0,
                    "version_scheme": 0,
                    "bottle": {
                        "stable": {
                            "rebuild": 0,
                            "root_url": "https://ghcr.io/v2/homebrew/core",
                            "files": {
                                "arm64_tahoe": {
                                    "cellar": ":any",
                                    "url": "https://example.com/bottle.rmp",
                                    "sha256": "abc123"
                                }
                            }
                        }
                    },
                    "keg_only": false,
                    "build_dependencies": [],
                    "dependencies": [],
                    "test_dependencies": [],
                    "recommended_dependencies": [],
                    "optional_dependencies": [],
                    "uses_from_macos": [],
                    "requires": [],
                    "conflicts_with": [],
                    "caveats": null,
                    "installed": [
                        {
                            "version": "14.1.0",
                            "used_options": [],
                            "built_as_bottle": true,
                            "poured_from_bottle": true,
                            "time": 1761228061,
                            "runtime_dependencies": [],
                            "installed_as_dependency": false,
                            "installed_on_request": true
                        }
                    ],
                    "linked_keg": "14.1.0",
                    "pinned": false,
                    "outdated": true,
                    "deprecated": false,
                    "deprecation_date": null,
                    "deprecation_reason": null,
                    "disabled": false,
                    "disable_date": null,
                    "disable_reason": null,
                    "post_install_defined": false,
                    "service": null,
                    "tap_git_head": "570587ac7ac5c9078b43d5f87fd5b774fd0cf277",
                    "ruby_source_path": "Formula/r/ripgrep.rb",
                    "ruby_source_checksum": {
                        "sha256": "477b5ac440bae34815c588a96642f800cb9a7fee236bcdeb7880de7396bdcdf7"
                    }
                }
            ],
            "casks": []
        }
        """#

        let data = Data(json.utf8)
        let response = try decoder.decode(BrewInfoResponse.self, from: data)

        #expect(response.formulae.count == 1)
        #expect(response.casks.isEmpty)

        let formula = try #require(response.formulae.first)
        #expect(formula.name == "ripgrep")
        #expect(formula.desc == "Search tool like grep and The Silver Searcher")
        #expect(formula.homepage == "https://github.com/BurntSushi/ripgrep")
        #expect(formula.versions?.stable == "15.1.0")
        #expect(formula.outdated == true)
        #expect(formula.installed?.first?.version == "14.1.0")
        #expect(formula.installed?.first?.installedAsDependency == false)
    }

    @Test("Maps BrewFormulaInfo to Package")
    func mapsFormulaToPackage() throws {
        let json = #"""
        {
            "formulae": [
                {
                    "name": "ripgrep",
                    "desc": "Search tool",
                    "homepage": "https://github.com/BurntSushi/ripgrep",
                    "versions": { "stable": "15.1.0" },
                    "installed": [{ "version": "14.1.0", "installed_as_dependency": false }],
                    "outdated": true
                }
            ],
            "casks": []
        }
        """#

        let data = Data(json.utf8)
        let response = try decoder.decode(BrewInfoResponse.self, from: data)
        let formula = try #require(response.formulae.first)

        let pkg = formula.toPackage()
        #expect(pkg.name == "ripgrep")
        #expect(pkg.id == "brew:ripgrep")
        #expect(pkg.installedVersion == "14.1.0")
        #expect(pkg.latestVersion == "15.1.0")
        #expect(pkg.manager == .brew)
        #expect(pkg.description == "Search tool")
        #expect(pkg.homepage?.absoluteString == "https://github.com/BurntSushi/ripgrep")
        #expect(pkg.isOutdated == true)
    }

    @Test("Maps formula without installed field to Package")
    func mapsUninstalledFormulaToPackage() throws {
        let json = #"""
        {
            "formulae": [
                {
                    "name": "neovim",
                    "desc": null,
                    "homepage": null,
                    "versions": { "stable": "0.10.0" },
                    "installed": [],
                    "outdated": false
                }
            ],
            "casks": []
        }
        """#

        let data = Data(json.utf8)
        let response = try decoder.decode(BrewInfoResponse.self, from: data)
        let formula = try #require(response.formulae.first)

        let pkg = formula.toPackage()
        #expect(pkg.installedVersion == nil)
        #expect(pkg.latestVersion == "0.10.0")
        #expect(pkg.isOutdated == false)
    }

    @Test("Installed brew revision is not outdated when brew reports current")
    func revisionedFormulaIsNotOutdated() throws {
        let json = #"""
        {
            "formulae": [
                {
                    "name": "openssl",
                    "desc": null,
                    "homepage": null,
                    "versions": { "stable": "1.5.4" },
                    "installed": [{ "version": "1.5.4_1" }],
                    "outdated": false
                }
            ],
            "casks": []
        }
        """#

        let data = Data(json.utf8)
        let response = try decoder.decode(BrewInfoResponse.self, from: data)
        let formula = try #require(response.formulae.first)

        let pkg = formula.toPackage()
        #expect(pkg.installedVersion == "1.5.4_1")
        // A Homebrew revision (_1) is newer than bare stable; honoring brew's
        // own `outdated: false` flag keeps it from reading as outdated.
        #expect(pkg.latestVersion == "1.5.4_1")
        #expect(pkg.isOutdated == false)
    }

    @Test("Decodes brew outdated --json=v2 response")
    func decodesBrewOutdatedResponse() throws {
        let json = #"""
        {
            "formulae": [
                {
                    "name": "libavif",
                    "installed_versions": ["1.4.1"],
                    "current_version": "1.4.2",
                    "pinned": false,
                    "pinned_version": null
                },
                {
                    "name": "prek",
                    "installed_versions": ["0.4.2"],
                    "current_version": "0.4.3",
                    "pinned": false,
                    "pinned_version": null
                }
            ],
            "casks": []
        }
        """#

        let data = Data(json.utf8)
        let response = try decoder.decode(BrewOutdatedResponse.self, from: data)

        #expect(response.formulae.count == 2)
        #expect(response.casks.isEmpty)

        let first = try #require(response.formulae.first)
        #expect(first.name == "libavif")
        #expect(first.installedVersions == ["1.4.1"])
        #expect(first.currentVersion == "1.4.2")
    }

    @Test("Maps BrewOutdatedEntry to Package")
    func mapsOutdatedEntryToPackage() throws {
        let json = #"""
        {
            "formulae": [
                {
                    "name": "node",
                    "installed_versions": ["22.5.0"],
                    "current_version": "22.13.0",
                    "pinned": false,
                    "pinned_version": null
                }
            ],
            "casks": []
        }
        """#

        let data = Data(json.utf8)
        let response = try decoder.decode(BrewOutdatedResponse.self, from: data)
        let entry = try #require(response.formulae.first)

        let pkg = entry.toPackage()
        #expect(pkg.name == "node")
        #expect(pkg.id == "brew:node")
        #expect(pkg.installedVersion == "22.5.0")
        #expect(pkg.latestVersion == "22.13.0")
        #expect(pkg.manager == .brew)
        #expect(pkg.isOutdated == true)
    }

    @Test("Decodes brew info --json=v2 with empty installed")
    func decodesFormulaWithNoInstalled() throws {
        let json = #"""
        {
            "formulae": [
                {
                    "name": "neovim",
                    "desc": "Hyperextensible Vim-based text editor",
                    "homepage": "https://neovim.io/",
                    "versions": { "stable": "0.10.4" },
                    "installed": [],
                    "outdated": false
                }
            ],
            "casks": []
        }
        """#

        let data = Data(json.utf8)
        let response = try decoder.decode(BrewInfoResponse.self, from: data)

        let formula = try #require(response.formulae.first)
        #expect(formula.installed?.isEmpty == true)

        let pkg = formula.toPackage()
        #expect(pkg.installedVersion == nil)
        #expect(pkg.latestVersion == "0.10.4")
    }

    @Test("Package.isOutdated false when versions match")
    func packageNotOutdatedWhenVersionsMatch() {
        let pkg = Package(
            name: "ripgrep",
            installedVersion: "15.1.0",
            latestVersion: "15.1.0",
            manager: .brew
        )
        #expect(pkg.isOutdated == false)
    }

    @Test("Package.isOutdated false when latest is nil")
    func packageNotOutdatedWhenLatestNil() {
        let pkg = Package(
            name: "ripgrep",
            installedVersion: "15.1.0",
            latestVersion: nil,
            manager: .brew
        )
        #expect(pkg.isOutdated == false)
    }

    @Test("PackageManagerKind display names are correct")
    func packageManagerKindDisplayNames() {
        #expect(PackageManagerKind.brew.displayName == "Homebrew")
        #expect(PackageManagerKind.npm.displayName == "npm")
        #expect(PackageManagerKind.pnpm.displayName == "pnpm")
        #expect(PackageManagerKind.yarn.displayName == "Yarn")
        #expect(PackageManagerKind.bun.displayName == "Bun")
        #expect(PackageManagerKind.uv.displayName == "uv")
        #expect(PackageManagerKind.cargo.displayName == "Cargo")
    }
}
