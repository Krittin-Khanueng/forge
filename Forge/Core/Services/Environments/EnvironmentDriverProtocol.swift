import Foundation

struct RuntimeInfo: Identifiable, Hashable, Sendable {
    let id: String
    let kind: RuntimeKind
    let version: String
    let path: String?
    let isActive: Bool
    let source: String
}

enum RuntimeKind: String, CaseIterable, Sendable {
    case python
    case node
    case rust
    case bun

    var displayName: String {
        switch self {
        case .python: "Python"
        case .node: "Node.js"
        case .rust: "Rust"
        case .bun: "Bun"
        }
    }

    var systemImage: String {
        switch self {
        case .python: "snake"
        case .node: "circle.hexagongrid"
        case .rust: "gearshape.2"
        case .bun: "takeoutbag.and.cup.and.straw"
        }
    }
}

protocol EnvironmentDriverProtocol: Sendable {
    var kind: RuntimeKind { get }
    var source: String { get }
    func isAvailable() async -> Bool
    func list() async throws -> [RuntimeInfo]
    func setActive(_ version: String) async throws
    func install(_ version: String) async throws
    func uninstall(_ version: String) async throws
}
