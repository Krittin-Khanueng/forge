import SwiftUI

struct AISettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var testResult: String?
    @State private var isTesting = false

    var body: some View {
        Form {
            Section("Provider") {
                Picker("AI Provider", selection: Binding(
                    get: { viewModel.settings.aiProvider },
                    set: { newValue in
                        viewModel.update { $0.aiProvider = newValue }
                        viewModel.aiKeyInput = SecureStorage.apiKey(for: newValue) ?? ""
                    }
                )) {
                    Text("Mock (No key needed)").tag("mock")
                    // TODO(forge): wire Anthropic provider — phase 4
                    // Text("Anthropic").tag("anthropic")
                    // TODO(forge): wire OpenAI provider — phase 4
                    // Text("OpenAI").tag("openai")
                }
            }

            if viewModel.settings.aiProvider != "mock" {
                Section("Model") {
                    Picker("Model", selection: Binding(
                        get: { viewModel.settings.aiModel },
                        set: { newValue in viewModel.update { $0.aiModel = newValue } }
                    )) {
                        Text("Claude Opus 4.7").tag("claude-opus-4-7")
                        Text("Claude Sonnet 4.6 (Recommended)").tag("claude-sonnet-4-6")
                        Text("Claude Haiku 4.5").tag("claude-haiku-4-5")
                    }
                }

                Section("API Key") {
                    SecureField("Enter API Key", text: $viewModel.aiKeyInput)
                        .onSubmit { viewModel.saveAIKey() }
                    Text("Key stored securely in Keychain.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                HStack {
                    PrimaryButton(label: "Test Connection", isLoading: isTesting) {
                        Task {
                            isTesting = true
                            testResult = "Mock service active — real provider not wired."
                            isTesting = false
                        }
                    }
                }
                if let result = testResult {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}
