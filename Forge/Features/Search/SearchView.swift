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
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)

            Divider()

            if env.searchService.query.isEmpty {
                ContentUnavailableView(
                    "Search Packages",
                    systemImage: "magnifyingglass",
                    description: Text("Search installed and available packages across all package managers")
                )
            } else {
                List {
                    if !env.searchService.localResults.isEmpty {
                        Section("Installed") {
                            ForEach(env.searchService.localResults) { hit in
                                SearchHitRow(hit: hit, service: env.searchService)
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
                                SearchHitRow(hit: hit, service: env.searchService)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }

            if let error = env.searchService.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
        }
        .onAppear { isFocused = true }
    }
}

private struct SearchHitRow: View {
    let hit: SearchHit
    let service: SearchService

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: hit.manager.systemImage)
                .frame(width: 24)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(hit.name)
                        .fontWeight(.medium)
                    if hit.isInstalled, let version = hit.installedVersion {
                        Text(version)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
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
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))

            if !hit.isInstalled {
                Button("Install") {
                    Task { await service.install(hit.name, manager: hit.manager) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
}
