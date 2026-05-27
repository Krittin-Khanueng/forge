import SwiftUI

struct SearchView: View {
    @Environment(AppEnvironment.self) private var env
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search packages...", text: Binding(
                    get: { env.searchService.query },
                    set: { newValue in
                        Task { await env.searchService.updateQuery(newValue) }
                    }
                ))
                .textFieldStyle(.plain)
                .focused($isFocused)
                if !env.searchService.query.isEmpty {
                    Button(action: {
                        Task { await env.searchService.updateQuery("") }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, ForgeTheme.Spacing.l)
            .padding(.vertical, ForgeTheme.Spacing.m)
            .background(.regularMaterial)

            Divider()

            if env.searchService.query.isEmpty {
                EmptyState(
                    icon: "magnifyingglass",
                    title: "Search Packages",
                    subtitle: "Search installed and available packages across all package managers. Press ⌘K for the command palette."
                )
            } else {
                List {
                    if !env.searchService.localResults.isEmpty {
                        Section("Installed") {
                            ForEach(env.searchService.localResults) { hit in
                                SearchResultRow(
                                    hit: hit,
                                    showsInstallButton: true,
                                    onInstall: {
                                        Task { await env.searchService.install(hit.name, manager: hit.manager) }
                                    }
                                )
                            }
                        }
                    }

                    Section("Available") {
                        if env.searchService.isSearchingRemote && env.searchService.remoteResults.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .controlSize(.small)
                                Text("Searching...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                        } else if env.searchService.remoteResults.isEmpty {
                            Text("No results found")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .listRowSeparator(.hidden)
                        } else {
                            ForEach(env.searchService.remoteResults.filter { !$0.isInstalled }) { hit in
                                SearchResultRow(
                                    hit: hit,
                                    showsInstallButton: true,
                                    onInstall: {
                                        Task { await env.searchService.install(hit.name, manager: hit.manager) }
                                    }
                                )
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }

            if let error = env.searchService.error {
                ErrorState(message: error) {
                    Task { await env.searchService.updateQuery(env.searchService.query) }
                }
                .padding(ForgeTheme.Spacing.m)
            }
        }
        .navigationTitle("Search")
        .onAppear { isFocused = true }
    }
}
