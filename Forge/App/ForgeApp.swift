import SwiftUI
import SwiftData

@main
struct ForgeApp: App {
    @State private var repo = SettingsRepository(container: StorageStack.shared.container)

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(StorageStack.shared.container)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1280, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra("Forge", systemImage: "hammer.fill") {
            MenuBarContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
