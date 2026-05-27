import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

    private let columns = [GridItem(.adaptive(minimum: 280))]

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                LoadingState("Loading dashboard...")
                    .padding(.top, 80)
            } else {
                LazyVGrid(columns: columns, spacing: ForgeTheme.Spacing.l) {
                    StatCard(
                        title: "Installed Packages",
                        value: "\(viewModel.totalPackages)",
                        subtitle: viewModel.detectedManagers.map(\.displayName).joined(separator: ", "),
                        accentColor: .blue
                    )
                    StatCard(
                        title: "Outdated",
                        value: "\(viewModel.outdatedCount)",
                        subtitle: viewModel.outdatedCount > 0 ? "Review updates" : "All up to date",
                        accentColor: viewModel.outdatedCount > 0 ? .orange : .green
                    )
                    DetectedManagersCard(managers: viewModel.detectedManagers)
                    ActivityCard(entries: viewModel.recentActivity)

                    if viewModel.dockerAvailable {
                        StatCard(
                            title: "Docker Containers",
                            value: "\(viewModel.dockerRunningContainers)/\(viewModel.dockerTotalContainers)",
                            subtitle: "\(viewModel.dockerImageCount) images",
                            accentColor: viewModel.dockerRunningContainers > 0 ? .green : .gray
                        )
                    }

                    QuickActionsCard()

                    if let lastRefresh = BackgroundScheduler.shared.lastRefresh {
                        HStack {
                            Text("Last refreshed: \(lastRefresh, style: .relative) ago")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .padding()
            }
        }
        .task {
            await viewModel.load()
        }
    }
}

private struct DetectedManagersCard: View {
    let managers: [PackageManagerKind]

    var body: some View {
        Card {
            Text("Detected Managers")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if managers.isEmpty {
                Text("None detected")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: ForgeTheme.Spacing.m) {
                    ForEach(managers, id: \.self) { kind in
                        VStack(spacing: ForgeTheme.Spacing.xs) {
                            Image(systemName: kind.systemImage)
                                .font(.title2)
                            Text(kind.displayName)
                                .font(.caption2)
                        }
                        .frame(width: 60)
                    }
                }
            }
        }
    }
}

private struct ActivityCard: View {
    let entries: [ActivityEntry]

    var body: some View {
        Card {
            Text("Recent Activity")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if entries.isEmpty {
                Text("No recent activity")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(entries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .font(.body)
                            if let subtitle = entry.subtitle {
                                Text(subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(entry.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct QuickActionsCard: View {
    var body: some View {
        Card {
            Text("Quick Actions")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: ForgeTheme.Spacing.s) {
                QuickActionRow(icon: "arrow.triangle.2.circlepath", label: "Refresh All") {
                    Task { await BackgroundScheduler.shared.refreshNow() }
                }
                QuickActionRow(icon: "magnifyingglass", label: "Open Search") {}
                QuickActionRow(icon: "gearshape", label: "Open Settings") {}
            }
        }
    }
}

private struct QuickActionRow: View {
    let icon: String
    let label: String
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(label)
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
