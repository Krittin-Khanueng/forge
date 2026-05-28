import SwiftUI

struct CommandPaletteView: View {
    @Environment(AppEnvironment.self) private var env
    @FocusState private var isFocused: Bool
    let onDismiss: () -> Void

    @State private var selectedIndex: Int = 0
    @State private var pendingInstall: SearchHit?

    private var allHits: [SearchHit] {
        let installed = env.searchService.localResults
        let remoteNotInstalled = env.searchService.remoteResults.filter { !$0.isInstalled }
        return installed + remoteNotInstalled
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: ForgeTheme.Spacing.m) {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                TextField("Search packages...", text: Binding(
                    get: { env.searchService.query },
                    set: { newValue in
                        Task { await env.searchService.updateQuery(newValue) }
                        selectedIndex = 0
                        pendingInstall = nil
                    }
                ))
                .textFieldStyle(.plain)
                .font(.title3)
                .focused($isFocused)
            }
            .padding(.horizontal, ForgeTheme.Spacing.xl)
            .padding(.vertical, ForgeTheme.Spacing.l)

            Divider()

            ScrollViewReader { proxy in
                List(selection: $selectedIndex) {
                    if env.searchService.isSearchingRemote && env.searchService.localResults.isEmpty && env.searchService.remoteResults.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                                .controlSize(.small)
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                        .padding()
                    } else if env.searchService.query.isEmpty {
                        VStack(spacing: ForgeTheme.Spacing.m) {
                            Text("Search across all package managers")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: ForgeTheme.Spacing.l) {
                                ForEach(env.registry.detectedKinds, id: \.self) { kind in
                                    Label(kind.displayName, systemImage: kind.systemImage)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ForgeTheme.Spacing.xxl)
                        .listRowSeparator(.hidden)
                    } else if allHits.isEmpty {
                        Text("No results found")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, ForgeTheme.Spacing.xxl)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(Array(allHits.enumerated()), id: \.element.id) { index, hit in
                            VStack(spacing: 0) {
                                SearchResultRow(hit: hit, isSelected: selectedIndex == index)
                                    .tag(index)
                                    .id(index)
                                    .onTapGesture {
                                        handleTap(hit)
                                    }

                                if let pending = pendingInstall, pending.id == hit.id {
                                    installConfirmationRow(pending)
                                        .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .animation(.easeInOut(duration: 0.15), value: pendingInstall?.id)
                .onChange(of: selectedIndex) { _, newValue in
                    proxy.scrollTo(newValue, anchor: .center)
                    pendingInstall = nil
                }
                .onKeyPress(.downArrow) {
                    let max = max(0, allHits.count - 1)
                    selectedIndex = min(selectedIndex + 1, max)
                    return .handled
                }
                .onKeyPress(.upArrow) {
                    selectedIndex = max(0, selectedIndex - 1)
                    return .handled
                }
                .onKeyPress(.return) {
                    confirmSelection()
                    return .handled
                }
                .onKeyPress(.escape) {
                    if pendingInstall != nil {
                        pendingInstall = nil
                    } else {
                        onDismiss()
                    }
                    return .handled
                }
            }
        }
        .frame(width: 560, height: 420)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.l))
        .overlay(
            RoundedRectangle(cornerRadius: ForgeTheme.Radius.l)
                .stroke(.quaternary, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        .onAppear {
            isFocused = true
            selectedIndex = 0
        }
    }

    private func installConfirmationRow(_ hit: SearchHit) -> some View {
        HStack(spacing: ForgeTheme.Spacing.m) {
            Image(systemName: "arrow.down.circle.fill")
                .foregroundStyle(ForgeTheme.Palette.forgeBlue)
            Text("Install **\(hit.name)** via \(hit.manager.displayName)?")
                .font(.callout)
            Spacer()
            Button("Cancel") {
                pendingInstall = nil
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            Button("Install") {
                Task { await env.searchService.install(hit.name, manager: hit.manager) }
                pendingInstall = nil
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, ForgeTheme.Spacing.l)
        .padding(.vertical, ForgeTheme.Spacing.s)
        .background(ForgeTheme.Palette.forgeBlue.opacity(0.06))
    }

    private func handleTap(_ hit: SearchHit) {
        if hit.isInstalled {
            NSApp.activate(ignoringOtherApps: true)
            onDismiss()
        } else if pendingInstall?.id == hit.id {
            Task { await env.searchService.install(hit.name, manager: hit.manager) }
            pendingInstall = nil
            onDismiss()
        } else {
            pendingInstall = hit
        }
    }

    private func confirmSelection() {
        guard selectedIndex < allHits.count else { return }
        let hit = allHits[selectedIndex]
        if hit.isInstalled {
            onDismiss()
        } else if pendingInstall?.id == hit.id {
            Task { await env.searchService.install(hit.name, manager: hit.manager) }
            pendingInstall = nil
            onDismiss()
        } else {
            pendingInstall = hit
        }
    }
}
