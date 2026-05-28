import Foundation
import SwiftData

@MainActor
final class ActivityRepository {
    private let context: ModelContext
    private var pendingSave: Task<Void, Never>?
    private let saveDelay: Duration = .milliseconds(500)

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
        scheduleSave()
    }

    func recent(limit: Int) -> [ActivityLogEntry] {
        var descriptor = FetchDescriptor<ActivityLogEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor)) ?? []
    }

    func flushPendingSave() {
        pendingSave?.cancel()
        pendingSave = nil
        try? context.save()
    }

    private func scheduleSave() {
        pendingSave?.cancel()
        pendingSave = Task { @MainActor in
            try? await Task.sleep(for: saveDelay)
            guard !Task.isCancelled else { return }
            try? context.save()
        }
    }
}
