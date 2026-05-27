import Foundation
import Testing
@testable import Forge

@Suite("NPM JSON Tests")
struct NPMJSONTests {
    let decoder = JSONDecoder()

    @Test("Decodes npm list -g --json response")
    func decodesNPMListResponse() throws {
        let json = #"""
        {
            "dependencies": {
                "typescript": {
                    "version": "5.4.5"
                },
                "prettier": {
                    "version": "3.2.5"
                }
            }
        }
        """#

        let data = Data(json.utf8)
        let response = try decoder.decode(NPMListResponse.self, from: data)

        let deps = try #require(response.dependencies)
        #expect(deps.count == 2)
        #expect(deps["typescript"]?.version == "5.4.5")
        #expect(deps["prettier"]?.version == "3.2.5")
    }

    @Test("NPMListEntry maps to Package")
    func mapsListEntryToPackage() throws {
        let entry = NPMListEntry(version: "5.4.5")
        let pkg = entry.toPackage(name: "typescript")

        #expect(pkg.name == "typescript")
        #expect(pkg.id == "npm:typescript")
        #expect(pkg.installedVersion == "5.4.5")
        #expect(pkg.latestVersion == nil)
        #expect(pkg.manager == .npm)
    }

    @Test("Decodes npm outdated -g --json response (object keyed by name)")
    func decodesNPMOutdatedResponse() throws {
        let json = #"""
        {
            "typescript": {
                "current": "5.4.5",
                "wanted": "5.4.5",
                "latest": "5.5.0",
                "location": "/opt/homebrew/lib/node_modules/typescript"
            },
            "prettier": {
                "current": "3.2.1",
                "wanted": "3.2.5",
                "latest": "3.3.0",
                "location": "/opt/homebrew/lib/node_modules/prettier"
            }
        }
        """#

        let data = Data(json.utf8)
        let entries = try decoder.decode([String: NPMOutdatedEntry].self, from: data)

        #expect(entries.count == 2)
        #expect(entries["typescript"]?.current == "5.4.5")
        #expect(entries["typescript"]?.latest == "5.5.0")
        #expect(entries["prettier"]?.wanted == "3.2.5")
    }

    @Test("NPMOutdatedEntry maps to Package")
    func mapsOutdatedEntryToPackage() throws {
        let entry = NPMOutdatedEntry(
            current: "5.4.5",
            wanted: "5.4.5",
            latest: "5.5.0",
            location: "/opt/homebrew/lib/node_modules/typescript"
        )
        let pkg = entry.toPackage(name: "typescript")

        #expect(pkg.name == "typescript")
        #expect(pkg.installedVersion == "5.4.5")
        #expect(pkg.latestVersion == "5.5.0")
        #expect(pkg.manager == .npm)
        #expect(pkg.isOutdated == true)
    }

    @Test("Decodes npm list -g --json with empty dependencies")
    func decodesEmptyDependencies() throws {
        let json = #"{ "dependencies": {} }"#

        let data = Data(json.utf8)
        let response = try decoder.decode(NPMListResponse.self, from: data)

        #expect(response.dependencies?.isEmpty == true)
    }

    @Test("Decodes npm outdated -g --json empty object")
    func decodesEmptyOutdated() throws {
        let json = "{}"

        let data = Data(json.utf8)
        let entries = try decoder.decode([String: NPMOutdatedEntry].self, from: data)

        #expect(entries.isEmpty)
    }
}
