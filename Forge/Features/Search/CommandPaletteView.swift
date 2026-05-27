import SwiftUI

struct CommandPaletteView: View {
    @Environment(AppEnvironment.self) private var env
    @FocusState private var isFocused: Bool
    let onDismiss: () -> Void

    @State private var selectedIndex: Int = 0

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
                            SearchResultRow(hit: hit, isSelected: selectedIndex == index)
                                .tag(index)
                                .id(index)
                                .onTapGesture {
                                    handleSelection(hit)
                                }
                        }
                    }
                }
                .listStyle(.plain)
                .onChange(of: selectedIndex) { _, newValue in
                    proxy.scrollTo(newValue, anchor: .center)
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
                    onDismiss()
                    return .handled
                }
            }
        }
        .frame(width: 560, height: 400)
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

    private func handleSelection(_ hit: SearchHit) {
        if !hit.isInstalled {
            Task { await env.searchService.install(hit.name, manager: hit.manager) }
        }
    }

    private func confirmSelection() {
        guard selectedIndex < allHits.count else { return }
        handleSelection(allHits[selectedIndex])
    }
}
