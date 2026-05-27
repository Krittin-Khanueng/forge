import Foundation
import Testing
@testable import Forge

@Suite("PNPM Manager Tests")
struct PNPMManagerTests {

    @Test("Decodes pnpm list -g --json array response")
    func decodesPNPMListResponse() throws {
        let json = #"""
        [
            { "name": "typescript", "version": "5.4.5", "path": "/Users/test/.local/share/pnpm/global/5/node_modules/typescript" },
            { "name": "prettier", "version": "3.2.5", "path": "/Users/test/.local/share/pnpm/global/5/node_modules/prettier" }
        ]
        """#

        let data = Data(json.utf8)
        let entries = try JSONDecoder().decode([PNPMManager.PNPMListEntry].self, from: data)

        #expect(entries.count == 2)
        #expect(entries[0].name == "typescript")
        #expect(entries[0].version == "5.4.5")
        #expect(entries[1].name == "prettier")
    }

    @Test("Decodes pnpm list root dependencies response")
    func decodesPNPMListRootDependenciesResponse() throws {
        let json = #"""
        [
            {
                "path": "/Users/test/Library/pnpm/global/5",
                "dependencies": {
                    "typescript": {
                        "from": "typescript",
                        "version": "5.4.5",
                        "path": "/Users/test/Library/pnpm/global/5/node_modules/typescript"
                    },
                    "prettier": {
                        "from": "prettier",
                        "version": "3.2.5",
                        "path": "/Users/test/Library/pnpm/global/5/node_modules/prettier"
                    }
                }
            }
        ]
        """#

        let projects = try JSONOutputDecoder.decode(
            [PNPMManager.PNPMListProject].self,
            from: json,
            context: "test pnpm list"
        )
        let entries = projects.flatMap { project in
            project.dependencies?.map { name, dependency in
                PNPMManager.PNPMListEntry(
                    name: dependency.from ?? name,
                    version: dependency.version,
                    path: dependency.path
                )
            } ?? []
        }

        #expect(entries.count == 2)
        #expect(entries.contains { $0.name == "typescript" && $0.version == "5.4.5" })
        #expect(entries.contains { $0.name == "prettier" && $0.version == "3.2.5" })
    }

    @Test("Decodes pnpm outdated -g --json object response")
    func decodesPNPMOutdatedResponse() throws {
        let json = #"""
        {
            "typescript": {
                "current": "5.4.5",
                "wanted": "5.4.5",
                "latest": "5.5.0"
            }
        }
        """#

        let data = Data(json.utf8)
        let entries = try JSONDecoder().decode([String: PNPMManager.PNPMOutdatedEntry].self, from: data)

        #expect(entries.count == 1)
        #expect(entries["typescript"]?.current == "5.4.5")
        #expect(entries["typescript"]?.latest == "5.5.0")
    }

    @Test("PNPM list empty array")
    func decodesEmptyPNPMList() throws {
        let json = "[]"

        let data = Data(json.utf8)
        let entries = try JSONDecoder().decode([PNPMManager.PNPMListEntry].self, from: data)

        #expect(entries.isEmpty)
    }

    @Test("PNPM outdated empty object")
    func decodesEmptyPNPMOutdated() throws {
        let json = "{}"

        let data = Data(json.utf8)
        let entries = try JSONDecoder().decode([String: PNPMManager.PNPMOutdatedEntry].self, from: data)

        #expect(entries.isEmpty)
    }
}
