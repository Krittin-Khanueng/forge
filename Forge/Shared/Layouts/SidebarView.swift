import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case packages
    case updates
    case environments
    case docker
    case search
    case settings
    case ai

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:    return "Dashboard"
        case .packages:     return "Packages"
        case .updates:      return "Updates"
        case .environments: return "Environments"
        case .docker:       return "Docker"
        case .search:       return "Search"
        case .settings:     return "Settings"
        case .ai:           return "AI Assistant"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:    return "house"
        case .packages:     return "shippingbox"
        case .updates:      return "arrow.triangle.2.circlepath"
        case .environments: return "externaldrive"
        case .docker:       return "square.stack.3d.up"
        case .search:       return "magnifyingglass"
        case .settings:     return "gearshape"
        case .ai:           return "sparkles"
        }
    }

    @MainActor
    @ViewBuilder
    var detailView: some View {
        switch self {
        case .dashboard:    DashboardView()
        case .packages:     PackagesView()
        case .updates:      UpdatesView()
        case .environments: EnvironmentsView()
        case .docker:       DockerView()
        case .search:       SearchView()
        case .settings:     SettingsView()
        case .ai:           AIView()
        }
    }
}

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        List(selection: $selection) {
            Section("Overview") {
                Label(SidebarItem.dashboard.title, systemImage: SidebarItem.dashboard.systemImage)
                    .tag(SidebarItem.dashboard)
            }

            Section("Manage") {
                ForEach([SidebarItem.packages, .updates, .environments, .docker]) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .badge(item == .docker && env.dockerMonitor.runningCount > 0 ? env.dockerMonitor.runningCount : 0)
                        .tag(item)
                }
            }

            Section("Tools") {
                ForEach([SidebarItem.search, .ai]) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .tag(item)
                }
            }

            Section("App") {
                Label(SidebarItem.settings.title, systemImage: SidebarItem.settings.systemImage)
                    .tag(SidebarItem.settings)
            }
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
    }
}
