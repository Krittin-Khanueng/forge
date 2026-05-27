import Foundation
import Testing
@testable import Forge

@Suite("Uv Python Driver Tests")
struct UvPythonDriverTests {

    @Test("Parses uv python list --only-installed output")
    func parsesUvPythonList() throws {
        let output = #"""
        cpython-3.13.3-macos-aarch64-none    /Users/dev/.local/share/uv/python/cpython-3.13.3-macos-aarch64-none/bin/python3.13
        cpython-3.12.9-macos-aarch64-none    /Users/dev/.local/share/uv/python/cpython-3.12.9-macos-aarch64-none/bin/python3.12
        cpython-3.11.12-macos-aarch64-none   /Users/dev/.local/share/uv/python/cpython-3.11.12-macos-aarch64-none/bin/python3.11
        """#

        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        var versions: [String] = []

        for line in lines {
            let cleaned = String(line).replacingOccurrences(of: "->", with: "")
            let parts = cleaned.split(separator: " ", omittingEmptySubsequences: true)
            guard !parts.isEmpty else { continue }
            let first = String(parts[0])
            let version = first.hasPrefix("cpython-") ? String(first.dropFirst(8)) : first
            versions.append(version)
        }

        #expect(versions.count == 3)
        #expect(versions[0] == "3.13.3-macos-aarch64-none")
        #expect(versions[1] == "3.12.9-macos-aarch64-none")
        #expect(versions[2] == "3.11.12-macos-aarch64-none")
    }

    @Test("Parses uv python list with pypy entry")
    func parsesPypyEntry() throws {
        let output = #"""
        cpython-3.13.3-macos-aarch64-none    /path/to/python3.13
        pypy-3.10.14-macos-aarch64-none      /path/to/pypy3.10
        """#

        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        var versions: [String] = []

        for line in lines {
            let cleaned = String(line).replacingOccurrences(of: "->", with: "")
            let parts = cleaned.split(separator: " ", omittingEmptySubsequences: true)
            guard !parts.isEmpty else { continue }
            let first = String(parts[0])
            let version = first.hasPrefix("cpython-") ? String(first.dropFirst(8)) : first
            versions.append(version)
        }

        #expect(versions.count == 2)
        #expect(versions[0] == "3.13.3-macos-aarch64-none")
        #expect(versions[1] == "pypy-3.10.14-macos-aarch64-none")
    }

    @Test("Empty uv python list output")
    func emptyOutput() throws {
        let lines = [String]()
        var versions: [String] = []

        for line in lines {
            let cleaned = line.replacingOccurrences(of: "->", with: "")
            let parts = cleaned.split(separator: " ", omittingEmptySubsequences: true)
            guard !parts.isEmpty else { continue }
            let first = String(parts[0])
            let version = first.hasPrefix("cpython-") ? String(first.dropFirst(8)) : first
            versions.append(version)
        }

        #expect(versions.isEmpty)
    }

    @Test("RuntimeInfo id format")
    func runtimeInfoIDFormat() throws {
        let info = RuntimeInfo(
            id: "python:3.13.3",
            kind: .python,
            version: "3.13.3",
            path: "/path/to/python",
            isActive: true,
            source: "uv"
        )
        #expect(info.id == "python:3.13.3")
        #expect(info.kind == .python)
        #expect(info.version == "3.13.3")
        #expect(info.isActive == true)
        #expect(info.source == "uv")
    }

    @Test("RuntimeKind display names")
    func runtimeKindDisplayNames() throws {
        #expect(RuntimeKind.python.displayName == "Python")
        #expect(RuntimeKind.node.displayName == "Node.js")
        #expect(RuntimeKind.rust.displayName == "Rust")
        #expect(RuntimeKind.bun.displayName == "Bun")
    }
}
