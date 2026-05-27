import Foundation
import Testing
@testable import Forge

@Suite("Cargo Parser Tests")
struct CargoParserTests {

    @Test("Parses cargo install --list output")
    func parsesInstallList() throws {
        let output = #"""
        ripgrep v14.1.0:
            rg
        bat v0.24.0:
            bat
        cargo-outdated v0.15.0:
            cargo-outdated
        """#

        let entries = CargoParser.parseInstallList(output)
        #expect(entries.count == 3)

        #expect(entries[0].name == "ripgrep")
        #expect(entries[0].version == "14.1.0")
        #expect(entries[0].binaries == ["rg"])

        #expect(entries[1].name == "bat")
        #expect(entries[1].version == "0.24.0")
        #expect(entries[1].binaries == ["bat"])

        #expect(entries[2].name == "cargo-outdated")
        #expect(entries[2].version == "0.15.0")
        #expect(entries[2].binaries == ["cargo-outdated"])
    }

    @Test("Parses cargo install --list with multiple binaries")
    func parsesMultipleBinaries() throws {
        let output = #"""
        some-crate v1.0.0:
            binary-a
            binary-b
            binary-c
        """#

        let entries = CargoParser.parseInstallList(output)
        #expect(entries.count == 1)
        #expect(entries[0].name == "some-crate")
        #expect(entries[0].version == "1.0.0")
        #expect(entries[0].binaries == ["binary-a", "binary-b", "binary-c"])
    }

    @Test("Empty cargo install --list returns empty")
    func emptyInstallList() throws {
        let entries = CargoParser.parseInstallList("")
        #expect(entries.isEmpty)
    }

    @Test("Parses cargo search output")
    func parsesCargoSearch() throws {
        let output = #"""
        ripgrep = "ripgrep recursively searches directories with a regex pattern" # 14.1.0
        bat = "A cat(1) clone with wings" # 0.24.0
        cargo-outdated = "Display when Rust dependencies are out of date" # 0.15.0
        """#

        let entries = CargoParser.parseSearch(output)
        #expect(entries.count == 3)

        #expect(entries[0].name == "ripgrep")
        #expect(entries[0].description == "ripgrep recursively searches directories with a regex pattern")
        #expect(entries[0].version == "14.1.0")

        #expect(entries[1].name == "bat")
        #expect(entries[1].description == "A cat(1) clone with wings")
        #expect(entries[1].version == "0.24.0")

        #expect(entries[2].name == "cargo-outdated")
        #expect(entries[2].description == "Display when Rust dependencies are out of date")
        #expect(entries[2].version == "0.15.0")
    }

    @Test("Empty cargo search returns empty")
    func emptyCargoSearch() throws {
        let entries = CargoParser.parseSearch("")
        #expect(entries.isEmpty)
    }

    @Test("Skips malformed cargo search lines")
    func skipsMalformedSearch() throws {
        let output = #"""
        some-garbage-without-equals
        ripgrep = "search tool" # 14.1.0
        """#

        let entries = CargoParser.parseSearch(output)
        #expect(entries.count == 1)
        #expect(entries[0].name == "ripgrep")
    }
}
