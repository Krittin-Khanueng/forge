import Foundation
import SwiftData
import Testing
@testable import Forge

@Suite("Settings ViewModel Tests")
@MainActor
struct SettingsViewModelTests {

    @Test("Settings view model reads defaults from repo")
    func readsDefaults() async throws {
        let container = try await makeContainer()
        let repo = SettingsRepository(container: container)
        let settings = repo.current()

        #expect(settings.autoRefreshEnabled == false)
        #expect(settings.autoRefreshIntervalMinutes == 30)
        #expect(settings.showMenuBarIcon == true)
        #expect(settings.showInDock == true)
        #expect(settings.notifyOnOutdated == true)
        #expect(settings.theme == "system")
        #expect(settings.aiProvider == "mock")
    }

    @Test("Persistence of auto-refresh settings")
    func persistAutoRefreshSettings() async throws {
        let container = try await makeContainer()
        let repo = SettingsRepository(container: container)

        repo.update { $0.autoRefreshEnabled = true }
        repo.update { $0.autoRefreshIntervalMinutes = 10 }

        let read = repo.current()
        #expect(read.autoRefreshEnabled == true)
        #expect(read.autoRefreshIntervalMinutes == 10)
    }

    @Test("Persistence of menu bar and dock settings")
    func persistMenuBarAndDock() async throws {
        let container = try await makeContainer()
        let repo = SettingsRepository(container: container)

        repo.update { $0.showMenuBarIcon = false }
        repo.update { $0.showInDock = false }

        let read = repo.current()
        #expect(read.showMenuBarIcon == false)
        #expect(read.showInDock == false)
    }

    @Test("Persistence of notification setting")
    func persistNotificationSetting() async throws {
        let container = try await makeContainer()
        let repo = SettingsRepository(container: container)

        repo.update { $0.notifyOnOutdated = false }
        #expect(repo.current().notifyOnOutdated == false)

        repo.update { $0.notifyOnOutdated = true }
        #expect(repo.current().notifyOnOutdated == true)
    }

    private func makeContainer() async throws -> ModelContainer {
        let schema = Schema([AppSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }
}
