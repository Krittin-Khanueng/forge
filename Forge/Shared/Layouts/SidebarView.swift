import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case dashboard
    case packages
    case updates
    case environments
    case search
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:    return "Dashboard"
        case .packages:     return "Packages"
        case .updates:      return "Updates"
        case .environments: return "Environments"
        case .search:       return "Search"
        case .settings:     return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:    return "house"
        case .packages:     return "shippingbox"
        case .updates:      return "arrow.triangle.2.circlepath"
        case .environments: return "externaldrive"
        case .search:       return "magnifyingglass"
        case .settings:     return "gearshape"
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
        case .search:       SearchView()
        case .settings:     SettingsView()
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
                ForEach([SidebarItem.packages, .updates, .environments]) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .tag(item)
                }
            }

            Section("Tools") {
                ForEach([SidebarItem.search]) { item in
                    Label(item.title, systemImage: item.systemImage)
                        .tag(item)
                }
            }

            Section("App") {
                Label(SidebarItem.settings.title, systemImage: SidebarItem.settings.systemImage)
                    .tag(SidebarItem.settings)
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
