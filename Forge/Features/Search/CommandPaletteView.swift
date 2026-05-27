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
            HStack(spacing: 10) {
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

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
                        VStack(spacing: 12) {
                            Text("Search across all package managers")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 16) {
                                ForEach(env.registry.detectedKinds, id: \.self) { kind in
                                    Label(kind.displayName, systemImage: kind.systemImage)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .listRowSeparator(.hidden)
                    } else if allHits.isEmpty {
                        Text("No results found")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .listRowSeparator(.hidden)
                    } else {
                        ForEach(Array(allHits.enumerated()), id: \.element.id) { index, hit in
                            CommandPaletteRow(hit: hit, isSelected: selectedIndex == index)
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
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

private struct CommandPaletteRow: View {
    let hit: SearchHit
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: hit.manager.systemImage)
                .frame(width: 24)
                .foregroundStyle(hit.isInstalled ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(hit.name)
                        .fontWeight(.medium)
                    if hit.isInstalled, let version = hit.installedVersion {
                        Text(version)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                    }
                }
                if let description = hit.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(hit.manager.displayName)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))

            if hit.isInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}
