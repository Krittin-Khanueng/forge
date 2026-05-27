import Foundation
import Testing
@testable import Forge

@Suite("Background Scheduler Tests")
@MainActor
struct BackgroundSchedulerTests {

    @Test("Scheduler starts and stops cleanly")
    func startAndStop() async throws {
        let settings = SettingsRepository(container: StorageStack.shared.container)
        settings.update { $0.autoRefreshEnabled = true }
        settings.update { $0.autoRefreshIntervalMinutes = 1 }

        BackgroundScheduler.shared.start()
        #expect(BackgroundScheduler.shared.isRunning == true)

        BackgroundScheduler.shared.stop()
        #expect(BackgroundScheduler.shared.isRunning == false)
    }

    @Test("Scheduler does not start when auto-refresh disabled")
    func doesNotStartWhenDisabled() async throws {
        BackgroundScheduler.shared.stop()
        let settings = SettingsRepository(container: StorageStack.shared.container)
        settings.update { $0.autoRefreshEnabled = false }

        BackgroundScheduler.shared.start()
        #expect(BackgroundScheduler.shared.isRunning == false)
    }

    @Test("Refresh now updates lastRefresh timestamp")
    func refreshNowUpdatesTimestamp() async throws {
        await BackgroundScheduler.shared.refreshNow()
        #expect(BackgroundScheduler.shared.lastRefresh != nil)
    }

    @Test("Notification name constants are correct")
    func notificationNames() throws {
        let refresh = Notification.Name.forgeRefreshCompleted
        #expect(refresh.rawValue == "forgeRefreshCompleted")

        let outdated = Notification.Name.forgeOutdatedCountChanged
        #expect(outdated.rawValue == "forgeOutdatedCountChanged")
    }

    @Test("Restart calls start")
    func restartCallsStart() async throws {
        BackgroundScheduler.shared.stop()
        let settings = SettingsRepository(container: StorageStack.shared.container)
        settings.update { $0.autoRefreshEnabled = true }
        settings.update { $0.autoRefreshIntervalMinutes = 5 }

        BackgroundScheduler.shared.restart()
        #expect(BackgroundScheduler.shared.isRunning == true)
        BackgroundScheduler.shared.stop()
    }
}
