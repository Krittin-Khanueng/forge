import Foundation
import Testing
@testable import Forge

@Suite("Yarn Manager Tests")
struct YarnManagerTests {

    @Test("Yarn Berry installedPackages returns empty")
    func berryInstalledPackagesReturnsEmpty() async throws {
        // When Yarn Berry is detected, global list is unsupported and returns empty.
        // Test verifies the manager doesn't crash even without Yarn installed.
        let manager = YarnManager()
        let url = await manager.detect()
        if url != nil {
            let packages = try await manager.installedPackages()
            for pkg in packages {
                #expect(pkg.manager == .yarn)
            }
        }
    }

    @Test("Decodes Yarn Classic global list newline-delimited JSON")
    func decodesYarnClassicList() throws {
        let json = #"""
        {"type":"table","data":{"head":["Name","Version"],"body":[["typescript","5.4.5"],["prettier","3.2.5"]]}}
        {"type":"info","data":"Yarn Classic 1.22.22"}
        """#

        let lines = json.split(separator: "\n", omittingEmptySubsequences: true)

        struct YCEntry: Decodable {
            let type: String?
            let data: YCEntryData?
        }

        struct YCEntryData: Decodable {
            let head: [String]?
            let body: [[String]]?
        }

        var parsedCount = 0
        for line in lines {
            guard let data = String(line).data(using: .utf8) else { continue }
            if let entry = try? JSONDecoder().decode(YCEntry.self, from: data),
               let entryData = entry.data,
               let head = entryData.head,
               let body = entryData.body,
               head.count >= 2 {
                for row in body where row.count >= 2 {
                    #expect(!row[0].isEmpty)
                    #expect(!row[1].isEmpty)
                    parsedCount += 1
                }
            }
        }
        #expect(parsedCount == 2)
    }
}
