import SwiftUI

struct ContainerLogsView: View {
    let container: DockerContainer
    @State private var client = DockerClient()
    @State private var logLines: [String] = []
    @State private var isStreaming = false
    @State private var autoScroll = true
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredLines: [String] {
        guard !searchText.isEmpty else { return logLines }
        return logLines.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label(container.displayName, systemImage: "text.alignleft")
                    .font(.headline)
                Spacer()
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Filter logs...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.quaternary)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(filteredLines.enumerated()), id: \.offset) { index, line in
                            Text(line)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .id(index)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onChange(of: logLines.count) { _, _ in
                    if autoScroll, let last = logLines.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
            .background(Color.black.opacity(0.05))
        }
        .frame(minWidth: 600, minHeight: 400)
        .task {
            isStreaming = true
            do {
                for try await line in try await client.logs(containerID: container.id, follow: true) {
                    logLines.append(line)
                }
            } catch {
                logLines.append("[Error] \(error.localizedDescription)")
            }
            isStreaming = false
        }
    }
}
