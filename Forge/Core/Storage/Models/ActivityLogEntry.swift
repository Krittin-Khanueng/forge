import Foundation
import SwiftData

@Model
final class ActivityLogEntry {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var kind: String
    var title: String
    var subtitle: String?
    var manager: String?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        kind: String,
        title: String,
        subtitle: String? = nil,
        manager: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.manager = manager
    }
}
