import SwiftUI

struct MenuBarContentView: View {
    @State private var outdatedCount: Int = BackgroundScheduler.shared.outdatedCount
    @State private var lastRefresh: Date? = BackgroundScheduler.shared.lastRefresh

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "hammer.fill")
                    .foregroundStyle(ForgeTheme.Palette.forgeOrange)
                Text("Forge")
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.bottom, 4)

            if outdatedCount > 0 {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openMainWindow()
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(ForgeTheme.Palette.forgeOrange)
                        Text("\(outdatedCount) outdated packages")
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openMainWindow()
                } label: {
                    Label("Open Updates", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.plain)
            } else {
                Text("All packages up to date")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button {
                Task { await BackgroundScheduler.shared.refreshNow() }
            } label: {
                Label("Refresh Now", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)

            if let last = lastRefresh {
                Text("Last refresh: \(last, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            Button {
                NSApp.activate(ignoringOtherApps: true)
                openMainWindow()
            } label: {
                Label("Open Forge", systemImage: "arrow.up.forward.app")
            }
            .buttonStyle(.plain)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit", systemImage: "xmark.square")
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(width: 240)
        .onReceive(NotificationCenter.default.publisher(for: .forgeRefreshCompleted)) { _ in
            outdatedCount = PackageRefreshService.shared.outdatedCount
            lastRefresh = BackgroundScheduler.shared.lastRefresh
        }
    }

    private func openMainWindow() {
        if let window = NSApp.windows.first(where: { $0.isVisible || $0.title.contains("Forge") }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
    }
}
