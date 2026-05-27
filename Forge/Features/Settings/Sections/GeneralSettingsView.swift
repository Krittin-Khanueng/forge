import SwiftUI
import ServiceManagement

struct GeneralSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: Binding(
                    get: { viewModel.settings.theme },
                    set: { newValue in viewModel.update { $0.theme = newValue } }
                )) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }

                Picker("Preferred Terminal", selection: Binding(
                    get: { viewModel.settings.preferredTerminal },
                    set: { newValue in viewModel.update { $0.preferredTerminal = newValue } }
                )) {
                    Text("Terminal").tag("Terminal")
                    Text("iTerm").tag("iTerm")
                    Text("Warp").tag("Warp")
                    Text("Ghostty").tag("Ghostty")
                }
            }

            Section("Menu Bar") {
                Toggle("Show Menu Bar Icon", isOn: Binding(
                    get: { viewModel.settings.showMenuBarIcon },
                    set: { newValue in viewModel.update { $0.showMenuBarIcon = newValue } }
                ))
                Text("Toggle this off then reopen app to hide the icon.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Dock") {
                Toggle("Show in Dock", isOn: Binding(
                    get: { viewModel.settings.showInDock },
                    set: { newValue in
                        viewModel.update { $0.showInDock = newValue }
                        if newValue {
                            NSApp.setActivationPolicy(.regular)
                        } else {
                            NSApp.setActivationPolicy(.accessory)
                        }
                    }
                ))
            }

            if #available(macOS 15.0, *) {
                Section("Login") {
                    LoginItemToggle()
                }
            }
        }
        .formStyle(.grouped)
    }
}

@available(macOS 15.0, *)
private struct LoginItemToggle: View {
    @State private var isRegistered: Bool = SMAppService.mainApp.status == .enabled

    var body: some View {
        Toggle("Open Forge at Login", isOn: $isRegistered)
            .onChange(of: isRegistered) { _, enabled in
                do {
                    if enabled {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    isRegistered = SMAppService.mainApp.status == .enabled
                }
            }
    }
}
