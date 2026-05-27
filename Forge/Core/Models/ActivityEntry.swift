import Foundation

struct ActivityEntry: Identifiable, Hashable, Sendable {
    let id: UUID
    let timestamp: Date
    let title: String
    let subtitle: String?
}
