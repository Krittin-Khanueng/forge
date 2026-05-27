import Foundation
import SwiftData

@MainActor
final class ActivityRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        context = container.mainContext
    }

    func record(kind: String, title: String, subtitle: String?, manager: PackageManagerKind?) {
        let entry = ActivityLogEntry(
            kind: kind,
            title: title,
            subtitle: subtitle,
            manager: manager?.rawValue
        )
        context.insert(entry)
        try? context.save()
    }

    func recent(limit: Int) -> [ActivityLogEntry] {
        var descriptor = FetchDescriptor<ActivityLogEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }
}
