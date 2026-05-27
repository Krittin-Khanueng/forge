import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: DashboardViewModel

    private var summaryColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 220), spacing: ForgeTheme.Spacing.l)]
    }

    private var packageHealthRatio: CGFloat {
        guard viewModel.totalPackages > 0 else { return 1 }
        let healthy = max(viewModel.totalPackages - viewModel.outdatedCount, 0)
        return CGFloat(healthy) / CGFloat(viewModel.totalPackages)
    }

    var body: some View {
        ScrollView {
            if viewModel.isLoading {
                LoadingState("Loading dashboard...")
                    .padding(.top, 80)
            } else {
                VStack(alignment: .leading, spacing: ForgeTheme.Spacing.xl) {
                    dashboardHeader
                    summaryGrid
                    managerSection
                    activitySection
                }
                .padding(ForgeTheme.Spacing.xxl)
            }
        }
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await viewModel.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading || viewModel.isRefreshing)
            }
        }
        .navigationTitle("Dashboard")
        .task { await viewModel.loadIfNeeded() }
    }

    private var dashboardHeader: some View {
        HStack(alignment: .center, spacing: ForgeTheme.Spacing.xl) {
            HStack(spacing: ForgeTheme.Spacing.l) {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(ForgeTheme.Palette.forgeOrange, in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))

                VStack(alignment: .leading, spacing: ForgeTheme.Spacing.xs) {
                    Text("Toolchain Status")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    headerStatusText
                }
            }

            Spacer(minLength: ForgeTheme.Spacing.xl)

            healthDial
        }
        .padding(ForgeTheme.Spacing.xl)
        .background(ForgeTheme.Palette.panelElevated, in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.l))
        .overlay {
            RoundedRectangle(cornerRadius: ForgeTheme.Radius.l)
                .stroke(ForgeTheme.panelStroke(isActive: viewModel.outdatedCount > 0), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.07), radius: 16, x: 0, y: 8)
    }

    @ViewBuilder
    private var headerStatusText: some View {
        HStack(spacing: ForgeTheme.Spacing.s) {
            Text("\(viewModel.detectedManagers.count) managers")
            Text("·")
                .foregroundStyle(.tertiary)
            Text(viewModel.outdatedCount == 0 ? "All current" : "\(viewModel.outdatedCount) updates")
                .foregroundStyle(viewModel.outdatedCount == 0 ? ForgeTheme.Palette.forgeGreen : ForgeTheme.Palette.forgeOrange)
            if let lastLoadedAt = viewModel.lastLoadedAt {
                Text("·")
                    .foregroundStyle(.tertiary)
                Text("Updated \(lastLoadedAt, style: .relative) ago")
            }
            if viewModel.isRefreshing {
                ProgressView()
                    .controlSize(.small)
                    .padding(.leading, ForgeTheme.Spacing.xs)
            }
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(.secondary)
    }

    private var healthDial: some View {
        HStack(spacing: ForgeTheme.Spacing.m) {
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.14), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: packageHealthRatio)
                    .stroke(healthColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int((packageHealthRatio * 100).rounded()))%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .frame(width: 68, height: 68)

            VStack(alignment: .leading, spacing: 2) {
                Text("Health")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(viewModel.outdatedCount == 0 ? "Clean" : "Needs attention")
                    .font(.headline.weight(.semibold))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Package health \(Int((packageHealthRatio * 100).rounded())) percent")
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: summaryColumns, alignment: .leading, spacing: ForgeTheme.Spacing.l) {
            summaryTile(
                title: "Installed",
                value: "\(viewModel.totalPackages)",
                footnote: "packages indexed",
                icon: "shippingbox.fill",
                tint: ForgeTheme.Palette.forgeBlue
            )

            summaryTile(
                title: "Updates",
                value: "\(viewModel.outdatedCount)",
                footnote: viewModel.outdatedCount == 0 ? "nothing pending" : "ready to review",
                icon: "arrow.triangle.2.circlepath",
                tint: viewModel.outdatedCount == 0 ? ForgeTheme.Palette.forgeGreen : ForgeTheme.Palette.forgeOrange
            )

            summaryTile(
                title: "Managers",
                value: "\(viewModel.detectedManagers.count)",
                footnote: topManagerLabel,
                icon: "square.grid.2x2.fill",
                tint: ForgeTheme.Palette.forgeTeal
            )
        }
    }

    private func summaryTile(title: String, value: String, footnote: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: ForgeTheme.Spacing.l) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))
                Spacer()
            }

            VStack(alignment: .leading, spacing: ForgeTheme.Spacing.xs) {
                Text(value)
                    .font(ForgeTheme.Font.metric)
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(footnote)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(ForgeTheme.Spacing.l)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(ForgeTheme.Palette.panelFill, in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.l))
        .overlay {
            RoundedRectangle(cornerRadius: ForgeTheme.Radius.l)
                .stroke(ForgeTheme.Palette.hairline, lineWidth: 1)
        }
    }

    private var managerSection: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.Spacing.m) {
            SectionHeader("Package Managers") {
                Text("\(viewModel.totalPackages)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if viewModel.detectedManagers.isEmpty {
                inlineEmptyState(icon: "magnifyingglass", title: "No managers detected")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.detectedManagers.enumerated()), id: \.element) { index, kind in
                        managerRow(kind: kind, count: viewModel.managerCounts[kind] ?? 0)
                        if index < viewModel.detectedManagers.count - 1 {
                            Divider().padding(.leading, 58)
                        }
                    }
                }
            }
        }
        .panelStyle()
    }

    private func managerRow(kind: PackageManagerKind, count: Int) -> some View {
        let tint = ForgeTheme.managerColor(kind)

        return HStack(spacing: ForgeTheme.Spacing.m) {
            Image(systemName: kind.systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))

            VStack(alignment: .leading, spacing: ForgeTheme.Spacing.xs) {
                Text(kind.displayName)
                    .font(.callout.weight(.semibold))
                ProgressView(value: managerShare(count), total: 1)
                    .tint(tint)
            }

            Text("\(count)")
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
        .padding(.vertical, ForgeTheme.Spacing.m)
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.Spacing.m) {
            SectionHeader("Recent Activity") {
                Text("\(viewModel.recentActivity.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            if viewModel.recentActivity.isEmpty {
                inlineEmptyState(icon: "clock", title: "No recent activity")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.recentActivity.enumerated()), id: \.element.id) { index, entry in
                        activityRow(entry: entry)
                        if index < viewModel.recentActivity.count - 1 {
                            Divider().padding(.leading, 42)
                        }
                    }
                }
            }
        }
        .panelStyle()
    }

    private func activityRow(entry: ActivityEntry) -> some View {
        HStack(spacing: ForgeTheme.Spacing.m) {
            Circle()
                .fill(ForgeTheme.Palette.forgeTeal.opacity(0.14))
                .frame(width: 30, height: 30)
                .overlay {
                    Circle()
                        .fill(ForgeTheme.Palette.forgeTeal)
                        .frame(width: 7, height: 7)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                if let subtitle = entry.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(entry.timestamp, style: .relative)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
        .padding(.vertical, ForgeTheme.Spacing.m)
    }

    private func inlineEmptyState(icon: String, title: String) -> some View {
        HStack(spacing: ForgeTheme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 34, height: 34)
                .background(.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))
            Text(title)
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, ForgeTheme.Spacing.m)
    }

    private func statusPill(_ text: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(tint)
                .frame(width: 5, height: 5)
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.12), in: Capsule())
    }

    private func managerShare(_ count: Int) -> Double {
        guard viewModel.totalPackages > 0 else { return 0 }
        return Double(count) / Double(viewModel.totalPackages)
    }

    private var healthColor: Color {
        viewModel.outdatedCount == 0 ? ForgeTheme.Palette.forgeGreen : ForgeTheme.Palette.forgeOrange
    }

    private var topManagerLabel: String {
        guard let top = viewModel.detectedManagers.first else { return "none detected" }
        return "\(top.displayName) leads"
    }
}

private extension View {
    func panelStyle() -> some View {
        self
            .padding(ForgeTheme.Spacing.l)
            .frame(maxWidth: .infinity, minHeight: 230, alignment: .topLeading)
            .background(ForgeTheme.Palette.panelFill, in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.l))
            .overlay {
                RoundedRectangle(cornerRadius: ForgeTheme.Radius.l)
                    .stroke(ForgeTheme.Palette.hairline, lineWidth: 1)
            }
    }
}
