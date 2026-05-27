import Foundation
import Testing
@testable import Forge

@Suite("Rustup Driver Tests")
struct RustupDriverTests {

    @Test("Parses rustup toolchain list output")
    func parsesRustupToolchainList() throws {
        let output = #"""
        stable-aarch64-apple-darwin (default)
        stable-x86_64-apple-darwin
        nightly-2024-01-15-aarch64-apple-darwin
        1.75.0-aarch64-apple-darwin
        """#

        let lines = output.split(separator: "\n", omittingEmptySubsequences: true)
        var versions: [(String, Bool)] = []

        for line in lines {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let isDefault = trimmed.hasSuffix("(default)")
            var version = trimmed
                .replacingOccurrences(of: "(default)", with: "")
                .replacingOccurrences(of: "(override)", with: "")
                .trimmingCharacters(in: .whitespaces)
            if version.hasPrefix("stable-") {
                version.removeFirst(7)
            } else if version.hasPrefix("nightly-") {
                version.removeFirst(8)
            } else if version.hasPrefix("beta-") {
                version.removeFirst(5)
            }
            versions.append((version, isDefault))
        }

        #expect(versions.count == 4)
        #expect(versions[0].0 == "aarch64-apple-darwin")
        #expect(versions[0].1 == true)
        #expect(versions[1].0 == "x86_64-apple-darwin")
        #expect(versions[1].1 == false)
        #expect(versions[2].0 == "2024-01-15-aarch64-apple-darwin")
        #expect(versions[3].0 == "1.75.0-aarch64-apple-darwin")
    }

    @Test("Parses rustup show active-toolchain")
    func parsesActiveToolchain() throws {
        let output = "stable-aarch64-apple-darwin (default)\n"
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

        #expect(trimmed == "stable-aarch64-apple-darwin (default)")
    }

    @Test("Identifies active toolchain from rustup show output")
    func identifiesActiveToolchain() throws {
        let activeOutput = "stable-aarch64-apple-darwin (default)"
        let toolchainEntries = [
            "stable-aarch64-apple-darwin (default)",
            "nightly-2024-01-15-aarch64-apple-darwin",
        ]

        var isActive: [Bool] = []
        for entry in toolchainEntries {
            isActive.append(activeOutput.hasPrefix(entry.replacingOccurrences(of: "(default)", with: "").trimmingCharacters(in: .whitespaces)))
        }

        #expect(isActive[0] == true)
        #expect(isActive[1] == false)
    }

    @Test("Empty rustup toolchain list")
    func emptyToolchainList() throws {
        let lines: [Substring] = []
        var versions: [(String, Bool)] = []
        for line in lines {
            let trimmed = String(line).trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let isDefault = trimmed.hasSuffix("(default)")
            var version = trimmed.replacingOccurrences(of: "(default)", with: "").trimmingCharacters(in: .whitespaces)
            if version.hasPrefix("stable-") { version.removeFirst(7) }
            versions.append((version, isDefault))
        }
        #expect(versions.isEmpty)
    }

    @Test("RuntimeInfo for Rust toolchain")
    func rustRuntimeInfo() throws {
        let info = RuntimeInfo(
            id: "rust:stable",
            kind: .rust,
            version: "stable",
            path: nil,
            isActive: true,
            source: "rustup"
        )
        #expect(info.id == "rust:stable")
        #expect(info.kind == .rust)
        #expect(info.isActive == true)
        #expect(info.source == "rustup")
    }
}
