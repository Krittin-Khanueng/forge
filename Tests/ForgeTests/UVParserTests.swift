import Foundation
import Testing
@testable import Forge

@Suite("UV Parser Tests")
struct UVParserTests {

    @Test("Parses uv tool list output with multiple tools")
    func parsesMultipleTools() throws {
        let output = #"""
        ruff v0.9.1
        - ruff
        black v24.4.2
        - black
        - blackd
        """#

        let entries = UVParser.parseToolList(output)
        #expect(entries.count == 2)

        #expect(entries[0].name == "ruff")
        #expect(entries[0].version == "0.9.1")
        #expect(entries[0].latestVersion == nil)
        #expect(entries[0].binaries == ["ruff"])
        #expect(entries[0].pythonVersion == nil)

        #expect(entries[1].name == "black")
        #expect(entries[1].version == "24.4.2")
        #expect(entries[1].latestVersion == nil)
        #expect(entries[1].binaries == ["black", "blackd"])
        #expect(entries[1].pythonVersion == nil)
    }

    @Test("Parses uv tool list with --show-python flag")
    func parsesWithPythonVersion() throws {
        let output = #"""
        ruff v0.9.1 (python3.13)
        - ruff
        """#

        let entries = UVParser.parseToolList(output)
        #expect(entries.count == 1)

        #expect(entries[0].name == "ruff")
        #expect(entries[0].version == "0.9.1")
        #expect(entries[0].latestVersion == nil)
        #expect(entries[0].pythonVersion == "python3.13")
    }

    @Test("Parses uv tool list outdated latest version")
    func parsesOutdatedLatestVersion() throws {
        let output = #"""
        desloppify v0.9.15 [CPython 3.14.3] [latest: 1.0]
        - desloppify
        """#

        let entries = UVParser.parseToolList(output)
        #expect(entries.count == 1)

        #expect(entries[0].name == "desloppify")
        #expect(entries[0].version == "0.9.15")
        #expect(entries[0].latestVersion == "1.0")
        #expect(entries[0].pythonVersion == "CPython 3.14.3")
        #expect(entries[0].binaries == ["desloppify"])
    }

    @Test("Parses uv tool list with poetry")
    func parsesPoetry() throws {
        let output = #"""
        poetry v2.1.3
        - poetry
        """#

        let entries = UVParser.parseToolList(output)
        #expect(entries.count == 1)

        #expect(entries[0].name == "poetry")
        #expect(entries[0].version == "2.1.3")
        #expect(entries[0].binaries == ["poetry"])
    }

    @Test("Empty output returns empty array")
    func emptyOutput() throws {
        let entries = UVParser.parseToolList("")
        #expect(entries.isEmpty)
    }

    @Test("Skips lines with no version separator")
    func skipsInvalidLines() throws {
        let output = #"""
        no-version-here
        pipx v1.0.0
        - pipx
        """#

        let entries = UVParser.parseToolList(output)
        #expect(entries.count == 1)
        #expect(entries[0].name == "pipx")
        #expect(entries[0].version == "1.0.0")
    }
}
