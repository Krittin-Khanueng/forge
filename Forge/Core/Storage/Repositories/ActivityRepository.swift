import Foundation
import SwiftData

@MainActor
final class ActivityRepository {
    private let context: ModelContext
    private var pendingSave: Task<Void, Never>?
    private let saveDelay: Duration = .milliseconds(500)
    private let maxEntries = 200

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
        trimToCap()
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

    private func trimToCap() {
        var descriptor = FetchDescriptor<ActivityLogEntry>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchOffset = maxEntries
        let stale = (try? context.fetch(descriptor)) ?? []
        for entry in stale {
            context.delete(entry)
        }
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
