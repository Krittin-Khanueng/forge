import Foundation
import SwiftData

@MainActor
final class SettingsRepository {
    private let context: ModelContext

    init(container: ModelContainer) {
        context = container.mainContext
    }

    func current() -> AppSettings {
        var descriptor = FetchDescriptor<AppSettings>()
        descriptor.fetchLimit = 1

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let settings = AppSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }

    func update(_ mutation: (AppSettings) -> Void) {
        let settings = current()
        mutation(settings)
        try? context.save()
    }
}
