import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    enum Tab: String, CaseIterable { case general, managers, updates, ai, about
        var title: String {
            switch self {
            case .general: "General"
            case .managers: "Package Managers"
            case .updates: "Updates"
            case .ai: "AI"
            case .about: "About"
            }
        }
    }

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem { Label("General", systemImage: "gearshape") }
                .tag(Tab.general)
            PackageManagersSettingsView()
                .tabItem { Label("Package Managers", systemImage: "shippingbox") }
                .tag(Tab.managers)
            UpdatesSettingsView(viewModel: viewModel)
                .tabItem { Label("Updates", systemImage: "arrow.triangle.2.circlepath") }
                .tag(Tab.updates)
            AISettingsView(viewModel: viewModel)
                .tabItem { Label("AI", systemImage: "sparkles") }
                .tag(Tab.ai)
            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
                .tag(Tab.about)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

@MainActor
@Observable
final class SettingsViewModel {
    let repo = SettingsRepository(container: StorageStack.shared.container)
    let settings: AppSettings

    var aiKeyInput: String = ""

    init() {
        settings = repo.current()
        if let key = SecureStorage.apiKey(for: settings.aiProvider) {
            aiKeyInput = key
        }
    }

    func update(_ mutation: (AppSettings) -> Void) {
        repo.update(mutation)
    }

    func saveAIKey() {
        guard !aiKeyInput.isEmpty else {
            try? SecureStorage.deleteAPIKey(for: settings.aiProvider)
            return
        }
        try? SecureStorage.setAPIKey(aiKeyInput, for: settings.aiProvider)
    }
}
