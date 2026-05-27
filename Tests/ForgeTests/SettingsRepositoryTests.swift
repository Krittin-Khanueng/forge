import Foundation
import SwiftData
import Testing
@testable import Forge

@Suite("Settings Repository Tests")
@MainActor
struct SettingsRepositoryTests {
    func makeContainer() throws -> ModelContainer {
        let schema = Schema([AppSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    @Test func defaultValuesOnFirstRead() async throws {
        let container = try await makeContainer()
        let repo = SettingsRepository(container: container)

        let settings = repo.current()
        #expect(settings.autoRefreshEnabled == false)
        #expect(settings.autoRefreshIntervalMinutes == 30)
        #expect(settings.preferredTerminal == "Terminal")
        #expect(settings.theme == "system")
        #expect(settings.lastRefresh == nil)
    }

    @Test func mutationsPersist() async throws {
        let container = try await makeContainer()
        let repo = SettingsRepository(container: container)

        repo.update { settings in
            settings.autoRefreshEnabled = true
            settings.autoRefreshIntervalMinutes = 60
            settings.preferredTerminal = "iTerm"
            settings.theme = "dark"
            settings.lastRefresh = Date.distantPast
        }

        let updated = repo.current()
        #expect(updated.autoRefreshEnabled == true)
        #expect(updated.autoRefreshIntervalMinutes == 60)
        #expect(updated.preferredTerminal == "iTerm")
        #expect(updated.theme == "dark")
        #expect(updated.lastRefresh != nil)
    }

    @Test func currentReturnsSameInstance() async throws {
        let container = try await makeContainer()
        let repo = SettingsRepository(container: container)

        let first = repo.current()
        repo.update { $0.autoRefreshEnabled = true }

        let second = repo.current()
        #expect(second.autoRefreshEnabled == true)
        #expect(first.id == second.id)
    }
}
