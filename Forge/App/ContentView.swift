import SwiftUI
import AppKit

struct ContentView: View {
    @State private var appEnv = AppEnvironment()
    @State private var selection: SidebarItem? = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            ZStack {
                ForgeTheme.Palette.appBackground
                    .ignoresSafeArea()
                if let item = selection {
                    item.detailView(env: appEnv)
                } else {
                    ContentUnavailableView("Select an item", systemImage: "sidebar.left")
                }
            }
        }
        .frame(minWidth: 1100, minHeight: 700)
        .environment(appEnv)
        .preferredColorScheme(appEnv.preferredColorScheme)
        .task {
            await appEnv.bootstrap()
            BackgroundScheduler.shared.start()
        }
        .onReceive(NotificationCenter.default.publisher(for: .forgeSettingsChanged)) { _ in
            appEnv.reloadAppearance()
            BackgroundScheduler.shared.restart()
        }
        .onAppear {
            guard appEnv.paletteMonitor == nil else { return }
            appEnv.paletteMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                let isCommandK = event.modifierFlags.contains(.command)
                    && event.charactersIgnoringModifiers?.lowercased() == "k"
                if isCommandK {
                    appEnv.togglePalette()
                    return nil
                }
                return event
            }
        }
        .onDisappear {
            if let monitor = appEnv.paletteMonitor {
                NSEvent.removeMonitor(monitor)
                appEnv.paletteMonitor = nil
            }
        }
    }
}
