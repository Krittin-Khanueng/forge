import SwiftUI

struct DockerDaemonHealthView: View {
    let viewModel: DockerViewModel

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.dockerAvailable ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            Text(viewModel.dockerAvailable ? "Docker running" : "Docker unavailable")
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewModel.dockerAvailable {
                if let version = viewModel.dockerVersion {
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(version)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }

                HStack(spacing: 4) {
                    if viewModel.runningCount > 0 {
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundStyle(.green)
                        Text("\(viewModel.runningCount) running")
                            .font(.caption2)
                    }
                    Text("\(viewModel.totalCount) total containers")
                        .font(.caption2)
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text("\(viewModel.imageCount) images")
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/Applications/Docker.app"),
                                                   configuration: NSWorkspace.OpenConfiguration())
            } label: {
                Image(systemName: "arrow.up.forward.app")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .disabled(!FileManager.default.fileExists(atPath: "/Applications/Docker.app"))
            .help("Open Docker Desktop")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}
