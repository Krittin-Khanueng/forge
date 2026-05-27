import SwiftUI
import OSLog

@MainActor
@Observable
final class DockerViewModel {
    var containers: [DockerContainer] = []
    var images: [DockerImage] = []
    var isLoading = false
    var error: String?
    var dockerAvailable = true
    var dockerVersion: String?

    var selectedTab: DockerTab = .containers

    var runningCount: Int { containers.filter(\.isRunning).count }
    var totalCount: Int { containers.count }
    var imageCount: Int { images.count }

    private let client = DockerClient()
    private let logger = Logger.ui

    func load() async {
        isLoading = true
        defer { isLoading = false }

        dockerAvailable = await client.isAvailable()
        if !dockerAvailable {
            error = nil
            containers = []
            images = []
            return
        }

        error = nil
        dockerVersion = await client.dockerVersion()

        do {
            containers = try await client.containers(all: true)
            images = try await client.images()
        } catch {
            self.error = error.localizedDescription
            logger.error("Docker load failed: \(error.localizedDescription)")
        }
    }

    func start(_ id: String) async {
        do {
            try await client.start(containerID: id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func stop(_ id: String) async {
        do {
            try await client.stop(containerID: id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func restart(_ id: String) async {
        do {
            try await client.restart(containerID: id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func remove(container id: String) async {
        do {
            try await client.removeContainer(id, force: true)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func remove(image id: String) async {
        do {
            try await client.removeImage(id, force: true)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

enum DockerTab: String, CaseIterable, Sendable {
    case containers
    case images

    var title: String {
        switch self {
        case .containers: "Containers"
        case .images: "Images"
        }
    }
}
