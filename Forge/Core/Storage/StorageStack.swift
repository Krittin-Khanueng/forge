import SwiftData
import OSLog

@MainActor
final class StorageStack {
    static let shared = StorageStack()

    let container: ModelContainer

    private init() {
        let schema = Schema([CachedPackage.self, ActivityLogEntry.self, AppSettings.self])
        let logger = Logger(subsystem: "com.forge.app", category: "storage")

        let diskConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        if let disk = try? ModelContainer(for: schema, configurations: diskConfig) {
            container = disk
            return
        }

        // Disk store unreadable (corruption / failed migration). Fall back to an
        // in-memory store so the app still launches — the cache is rebuildable.
        logger.error("Disk model store failed to open; falling back to in-memory store")
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            container = try ModelContainer(for: schema, configurations: memoryConfig)
        } catch {
            fatalError("Failed to create in-memory model container: \(error)")
        }
    }
}
