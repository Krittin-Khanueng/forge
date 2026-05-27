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
                    item.detailView
                } else {
                    ContentUnavailableView("Select an item", systemImage: "sidebar.left")
                }
            }
        }
        .frame(minWidth: 1100, minHeight: 700)
        .environment(appEnv)
        .task {
            await appEnv.bootstrap()
            BackgroundScheduler.shared.start()
        }
        .onAppear {
            appEnv.paletteMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command), event.keyCode == 40 {
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
