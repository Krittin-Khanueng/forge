import Foundation
import Testing
@testable import Forge

@Suite("Bun Manager Tests")
struct BunManagerTests {

    @Test("Parses bun pm ls -g output")
    func parsesBunGlobalList() throws {
        let output = #"""
        /opt/homebrew/lib/node_modules:
        bun@1.2.0
        typescript@5.4.5
        prettier@3.2.5
        """#

        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        var packages: [(String, String)] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let atIndex = trimmed.lastIndex(of: "@") else { continue }
            let name = String(trimmed[..<atIndex]).trimmingCharacters(in: .whitespaces)
            let version = String(trimmed[trimmed.index(after: atIndex)...]).trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, !version.isEmpty else { continue }
            packages.append((name, version))
        }

        #expect(packages.count == 3)
        #expect(packages[0].0 == "bun")
        #expect(packages[0].1 == "1.2.0")
        #expect(packages[1].0 == "typescript")
        #expect(packages[1].1 == "5.4.5")
    }

    @Test("Skips lines without @ in bun output")
    func skipsNonPackageLines() throws {
        let output = #"""
        /opt/homebrew/lib/node_modules:
        some-header-line
        typescript@5.4.5
        """#

        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        var names: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.contains("@") else { continue }
            guard let atIndex = trimmed.lastIndex(of: "@") else { continue }
            let name = String(trimmed[..<atIndex]).trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            names.append(name)
        }

        #expect(names.count == 1)
        #expect(names[0] == "typescript")
    }

    @Test("Empty bun output returns empty")
    func emptyBunOutput() throws {
        let output = ""

        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        #expect(lines.isEmpty)
    }

    @Test("Bun outdatedPackages returns empty list")
    func outdatedReturnsEmpty() async throws {
        let manager = BunManager()
        let url = await manager.detect()
        if url != nil {
            let packages = try await manager.outdatedPackages()
            #expect(packages.isEmpty)
        }
    }
}
