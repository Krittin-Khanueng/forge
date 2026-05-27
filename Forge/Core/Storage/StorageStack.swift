import SwiftData

@MainActor
final class StorageStack {
    static let shared = StorageStack()

    let container: ModelContainer

    private init() {
        let schema = Schema([CachedPackage.self, ActivityLogEntry.self, AppSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        container = try! ModelContainer(for: schema, configurations: config)
    }
}
