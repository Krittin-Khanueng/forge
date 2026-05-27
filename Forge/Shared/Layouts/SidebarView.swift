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
            SidebarBrandHeader()
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.vertical, ForgeTheme.Spacing.s)

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

            Section {
                DockerSidebarStatus(runningCount: env.dockerMonitor.runningCount)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(ForgeTheme.Palette.panelFill.opacity(0.58))
        .navigationSplitViewColumnWidth(min: 180, ideal: 220)
    }
}

private struct SidebarBrandHeader: View {
    var body: some View {
        HStack(spacing: ForgeTheme.Spacing.m) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(ForgeTheme.Palette.forgeOrange, in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))

            VStack(alignment: .leading, spacing: 1) {
                Text("Forge")
                    .font(.headline.weight(.semibold))
                Text("Local toolchain")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct DockerSidebarStatus: View {
    let runningCount: Int

    var body: some View {
        HStack(spacing: ForgeTheme.Spacing.s) {
            Circle()
                .fill(runningCount > 0 ? ForgeTheme.Palette.forgeGreen : Color.secondary.opacity(0.45))
                .frame(width: 7, height: 7)
            Text(runningCount > 0 ? "\(runningCount) Docker running" : "Docker idle")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, ForgeTheme.Spacing.s)
        .padding(.vertical, ForgeTheme.Spacing.s)
        .background(ForgeTheme.Palette.panelElevated.opacity(0.55), in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))
        .overlay {
            RoundedRectangle(cornerRadius: ForgeTheme.Radius.m)
                .stroke(ForgeTheme.Palette.hairline, lineWidth: 1)
        }
    }
}
