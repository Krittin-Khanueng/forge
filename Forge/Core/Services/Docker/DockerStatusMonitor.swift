import Foundation

@MainActor
@Observable
final class DockerStatusMonitor {
    var runningCount: Int = 0

    private let client = DockerClient()

    func refresh() async {
        guard await client.isAvailable() else {
            runningCount = 0
            return
        }
        if let containers = try? await client.containers(all: true) {
            runningCount = containers.filter(\.isRunning).count
        }
    }
}
