import SwiftUI
import OSLog

@MainActor
@Observable
final class EnvironmentService {
    var pythonRuntimes: [RuntimeInfo] = []
    var nodeRuntimes: [RuntimeInfo] = []
    var rustToolchains: [RuntimeInfo] = []
    var bunVersions: [RuntimeInfo] = []
    var isLoading = false
    var error: String?

    var selectedTab: RuntimeKind = .python

    private let pythonDriver = UvPythonDriver()
    private let rustupDriver = RustupDriver()
    private let bunDriver = BunDriver()
    private let logger = Logger.ui

    private var nodeDriver: (any EnvironmentDriverProtocol)?
    private var hasLoadedOnce = false

    var nodeSource: String { nodeDriver?.source ?? "none" }

    func loadIfNeeded() async {
        guard !hasLoadedOnce else { return }
        hasLoadedOnce = true
        await refresh()
    }

    func refresh() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        async let python = pythonDriver.isAvailable() ? try? pythonDriver.list() : nil
        async let rust = rustupDriver.isAvailable() ? try? rustupDriver.list() : nil
        async let bun = bunDriver.isAvailable() ? try? bunDriver.list() : nil

        let (pyRes, rustRes, bunRes) = await (python, rust, bun)

        pythonRuntimes = pyRes ?? []
        rustToolchains = rustRes ?? []
        bunVersions = bunRes ?? []

        await detectNodeDriver()
        if let driver = nodeDriver {
            nodeRuntimes = (try? await driver.list()) ?? []
        }
    }

    private func detectNodeDriver() async {
        let candidates: [(any EnvironmentDriverProtocol)] = [
            FnmNodeDriver(),
            VoltaNodeDriver(),
            NNodeDriver(),
            SystemNodeDriver(),
        ]

        for driver in candidates {
            if await driver.isAvailable() {
                nodeDriver = driver
                return
            }
        }
        nodeDriver = nil
    }

    func setActive(_ runtime: RuntimeInfo) async throws {
        switch runtime.kind {
        case .python:
            try await pythonDriver.setActive(runtime.version)
        case .rust:
            try await rustupDriver.setActive(runtime.version)
        case .bun:
            try await bunDriver.setActive(runtime.version)
        case .node:
            try await nodeDriver?.setActive(runtime.version)
        }
        await refresh()
    }

    func install(version: String, kind: RuntimeKind) async throws {
        switch kind {
        case .python:
            try await pythonDriver.install(version)
        case .rust:
            try await rustupDriver.install(version)
        case .bun:
            try await bunDriver.install(version)
        case .node:
            try await nodeDriver?.install(version)
        }
        await refresh()
    }

    func uninstall(_ runtime: RuntimeInfo) async throws {
        switch runtime.kind {
        case .python:
            try await pythonDriver.uninstall(runtime.version)
        case .rust:
            try await rustupDriver.uninstall(runtime.version)
        case .bun:
            try await bunDriver.uninstall(runtime.version)
        case .node:
            try await nodeDriver?.uninstall(runtime.version)
        }
        await refresh()
    }

}
