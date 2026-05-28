import SwiftUI

struct MenuBarContentView: View {
    @State private var outdatedCount: Int = BackgroundScheduler.shared.outdatedCount
    @State private var lastRefresh: Date? = BackgroundScheduler.shared.lastRefresh
    @State private var isRefreshing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: ForgeTheme.Spacing.s) {
                Image(systemName: "hammer.fill")
                    .foregroundStyle(ForgeTheme.Palette.forgeOrange)
                Text("Forge")
                    .fontWeight(.semibold)
                Spacer()
                if isRefreshing {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
            .padding(.bottom, 4)

            if outdatedCount > 0 {
                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openMainWindow()
                } label: {
                    HStack(spacing: ForgeTheme.Spacing.s) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(ForgeTheme.Palette.forgeOrange)
                        Text("\(outdatedCount) outdated packages")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    NSApp.activate(ignoringOtherApps: true)
                    openMainWindow()
                } label: {
                    Label("View Updates", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: ForgeTheme.Spacing.s) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ForgeTheme.Palette.forgeGreen)
                        .font(.caption)
                    Text("All packages up to date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Button {
                isRefreshing = true
                Task {
                    await BackgroundScheduler.shared.refreshNow()
                    isRefreshing = false
                }
            } label: {
                Label(isRefreshing ? "Refreshing..." : "Refresh Now", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .disabled(isRefreshing)

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
                Label("Quit Forge", systemImage: "xmark.square")
            }
            .buttonStyle(.plain)
        }
        .padding()
        .frame(width: 240)
        .onReceive(NotificationCenter.default.publisher(for: .forgeRefreshCompleted)) { _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                outdatedCount = PackageRefreshService.shared.outdatedCount
                lastRefresh = BackgroundScheduler.shared.lastRefresh
            }
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
