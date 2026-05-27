import SwiftUI

struct UpdatesSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    private static let intervals: [Int] = [5, 10, 15, 30, 60, 120]

    var body: some View {
        Form {
            Section("Auto-Refresh") {
                Toggle("Enable Auto-Refresh", isOn: Binding(
                    get: { viewModel.settings.autoRefreshEnabled },
                    set: { newValue in
                        viewModel.update { $0.autoRefreshEnabled = newValue }
                        BackgroundScheduler.shared.restart()
                    }
                ))

                Picker("Interval", selection: Binding(
                    get: { viewModel.settings.autoRefreshIntervalMinutes },
                    set: { newValue in
                        viewModel.update { $0.autoRefreshIntervalMinutes = newValue }
                        BackgroundScheduler.shared.restart()
                    }
                )) {
                    ForEach(Self.intervals, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .disabled(!viewModel.settings.autoRefreshEnabled)
            }

            Section("Notifications") {
                Toggle("Notify on New Outdated Packages", isOn: Binding(
                    get: { viewModel.settings.notifyOnOutdated },
                    set: { newValue in viewModel.update { $0.notifyOnOutdated = newValue } }
                ))
            }

            Section("Status") {
                HStack {
                    Text("Last Refresh")
                    Spacer()
                    if let last = BackgroundScheduler.shared.lastRefresh {
                        Text(last, style: .relative) + Text(" ago")
                    } else {
                        Text("Never")
                    }
                    Text("• \(BackgroundScheduler.shared.outdatedCount) outdated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                PrimaryButton(label: "Refresh Now", systemImage: "arrow.clockwise") {
                    Task { await BackgroundScheduler.shared.refreshNow() }
                }
            }
        }
        .formStyle(.grouped)
    }
}
