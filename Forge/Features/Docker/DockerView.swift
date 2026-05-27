import SwiftUI

struct DockerView: View {
    @State private var viewModel = DockerViewModel()
    @State private var selectedContainer: DockerContainer?
    @State private var showLogs = false

    var body: some View {
        VStack(spacing: 0) {
            DockerDaemonHealthView(viewModel: viewModel)

            if viewModel.isLoading {
                LoadingState("Loading Docker...")
                    .padding(.top, 80)
            } else if !viewModel.dockerAvailable {
                dockerUnavailableView
            } else {
                Picker("View", selection: $viewModel.selectedTab) {
                    ForEach(DockerTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 12)

                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text(error)
                            .font(.caption)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                }

                switch viewModel.selectedTab {
                case .containers:
                    containersTable
                case .images:
                    imagesTable
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showLogs) {
            if let container = selectedContainer {
                ContainerLogsView(container: container)
            }
        }
        .onChange(of: selectedContainer) { _, container in
            if container != nil { showLogs = true }
        }
    }

    private var dockerUnavailableView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Docker Not Detected")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Docker daemon is not running or Docker is not installed.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Open Docker Desktop") {
                NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/Applications/Docker.app"),
                                                   configuration: NSWorkspace.OpenConfiguration())
            }
            .buttonStyle(.borderedProminent)
            .disabled(!FileManager.default.fileExists(atPath: "/Applications/Docker.app"))
            Spacer()
        }
        .padding()
    }

    private var containersTable: some View {
        Group {
            if viewModel.containers.isEmpty {
                ContentUnavailableView("No Containers", systemImage: "square.dashed", description: Text("No containers found on this system"))
            } else {
                Table(viewModel.containers) {
                    TableColumn("") { container in
                        Circle()
                            .fill(container.isRunning ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                    }
                    .width(20)
                    TableColumn("Name", value: \.displayName)
                    TableColumn("Image", value: \.image)
                    TableColumn("Status", value: \.status)
                    TableColumn("Ports") { container in
                        Text(container.ports.isEmpty ? "—" : container.ports)
                    }
                    TableColumn("") { container in
                        HStack(spacing: 8) {
                            if container.isRunning {
                                IconButton(systemImage: "stop.circle", tooltip: "Stop") {
                                    Task { await viewModel.stop(container.id) }
                                }
                                IconButton(systemImage: "arrow.triangle.2.circlepath", tooltip: "Restart") {
                                    Task { await viewModel.restart(container.id) }
                                }
                            } else {
                                IconButton(systemImage: "play.circle", tooltip: "Start") {
                                    Task { await viewModel.start(container.id) }
                                }
                            }
                            IconButton(systemImage: "text.alignleft", tooltip: "Logs") {
                                selectedContainer = container
                            }
                            IconButton(systemImage: "trash", tooltip: "Remove") {
                                Task { await viewModel.remove(container: container.id) }
                            }
                        }
                    }
                    .width(180)
                }
            }
        }
    }

    private var imagesTable: some View {
        Group {
            if viewModel.images.isEmpty {
                ContentUnavailableView("No Images", systemImage: "opticaldisc", description: Text("No Docker images found"))
            } else {
                Table(viewModel.images) {
                    TableColumn("Repository", value: \.repository)
                    TableColumn("Tag", value: \.tag)
                    TableColumn("Size", value: \.size)
                    TableColumn("Created") { image in
                        if let date = image.createdAt {
                            Text(date, style: .date)
                        } else {
                            Text("—")
                        }
                    }
                    TableColumn("") { image in
                        IconButton(systemImage: "trash", tooltip: "Remove") {
                            Task { await viewModel.remove(image: image.id) }
                        }
                    }
                    .width(50)
                }
            }
        }
    }
}
