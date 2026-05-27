import Foundation

struct AITool: Sendable {
    let name: String
    let description: String
    let inputSchema: [String: AnyCodable]
}
