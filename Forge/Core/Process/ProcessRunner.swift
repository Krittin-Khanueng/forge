import Foundation
import OSLog

actor ProcessRunner {
    struct Options: Sendable {
        var workingDirectory: URL?
        var environment: [String: String]?
        var timeout: Duration?
        var inheritParentPATH: Bool = true
        var silenceErrorLog: Bool = false

        static let `default` = Options()
    }

    struct Result: Sendable {
        let exitCode: Int32
        let stdout: String
        let stderr: String
        var isSuccess: Bool { exitCode == 0 }
    }

    enum StreamEvent: Sendable {
        case stdoutLine(String)
        case stderrLine(String)
        case exited(Int32)
    }

    private let logger = Logger(subsystem: "com.forge.app", category: "process")

    func run(
        _ executable: URL,
        arguments: [String] = [],
        options: Options = .default
    ) async throws -> Result {
        let commandLabel = ShellEscape.command(executable.path, arguments)
        logger.debug("Running: \(commandLabel)")

        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = options.workingDirectory
        process.environment = buildEnvironment(options.environment, inheritPATH: options.inheritParentPATH)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        let pid = process.processIdentifier
        let silenceErrorLog = options.silenceErrorLog

        return try await withTaskCancellationHandler {
            try await withProcessTimeout(options.timeout, commandLabel: commandLabel, pid: pid) {
                async let stdoutData = Self.drain(stdoutPipe.fileHandleForReading)
                async let stderrData = Self.drain(stderrPipe.fileHandleForReading)
                async let exitCode = Self.waitForExit(process)
                let (out, err, status) = await (stdoutData, stderrData, exitCode)

                if Task.isCancelled {
                    throw ProcessError.cancelled
                }

                let stdout = String(data: out, encoding: .utf8) ?? ""
                let stderr = String(data: err, encoding: .utf8) ?? ""

                guard status == 0 else {
                    if !silenceErrorLog {
                        self.logger.error("Non-zero exit (\(status)): \(commandLabel)\n\(stderr)")
                    } else {
                        self.logger.debug("Non-zero exit (\(status)): \(commandLabel)")
                    }
                    throw ProcessError.nonZeroExit(
                        command: commandLabel,
                        code: status,
                        stderr: stderr
                    )
                }

                self.logger.debug("Completed (0): \(commandLabel)")
                return Result(
                    exitCode: status,
                    stdout: stdout,
                    stderr: stderr
                )
            }
        } onCancel: {
            kill(pid, SIGTERM)
        }
    }

    func stream(
        _ executable: URL,
        arguments: [String] = [],
        options: Options = .default
    ) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let commandLabel = ShellEscape.command(executable.path, arguments)

            Task {
                await self._runStream(
                    executable: executable,
                    arguments: arguments,
                    options: options,
                    commandLabel: commandLabel,
                    continuation: continuation
                )
            }
        }
    }

    // MARK: - Private

    private func _runStream(
        executable: URL,
        arguments: [String],
        options: Options,
        commandLabel: String,
        continuation: AsyncThrowingStream<StreamEvent, Error>.Continuation
    ) async {
        logger.debug("Streaming: \(commandLabel)")

        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = options.workingDirectory
        process.environment = buildEnvironment(options.environment, inheritPATH: options.inheritParentPATH)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            logger.error("Stream failed to launch: \(commandLabel) — \(error.localizedDescription)")
            continuation.finish(throwing: error)
            return
        }
        let pid = process.processIdentifier

        var timeoutTask: Task<Void, Never>?
        if let timeout = options.timeout {
            timeoutTask = Task {
                try? await Task.sleep(for: timeout)
                guard !Task.isCancelled else { return }
                kill(pid, SIGTERM)
                continuation.finish(
                    throwing: ProcessError.timeout(command: commandLabel, after: timeout)
                )
            }
        }

        let _timeoutTask = timeoutTask
        continuation.onTermination = { @Sendable _ in
            _timeoutTask?.cancel()
            kill(pid, SIGTERM)
        }

        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    for try await line in stdoutPipe.fileHandleForReading.bytes.lines {
                        continuation.yield(.stdoutLine(line))
                    }
                }

                group.addTask {
                    for try await line in stderrPipe.fileHandleForReading.bytes.lines {
                        continuation.yield(.stderrLine(line))
                    }
                }

                try await group.waitForAll()
            }

            timeoutTask?.cancel()
            process.waitUntilExit()

            let stderrData = readRemaining(stderrPipe.fileHandleForReading)
            let fullStderr = String(data: stderrData, encoding: .utf8) ?? ""
            let status = process.terminationStatus

            if status == 0 {
                continuation.yield(.exited(status))
                continuation.finish()
            } else {
                logger.error("Non-zero exit (\(status)): \(commandLabel)")
                continuation.finish(
                    throwing: ProcessError.nonZeroExit(
                        command: commandLabel,
                        code: status,
                        stderr: fullStderr
                    )
                )
            }
        } catch is CancellationError {
            kill(pid, SIGTERM)
            timeoutTask?.cancel()
            continuation.finish(throwing: ProcessError.cancelled)
        } catch {
            logger.error("Stream failed: \(commandLabel) — \(error.localizedDescription)")
            kill(pid, SIGTERM)
            timeoutTask?.cancel()
            continuation.finish(throwing: error)
        }
    }

    private static func drain(_ handle: FileHandle) async -> Data {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let data = handle.readDataToEndOfFile()
                continuation.resume(returning: data)
            }
        }
    }

    private static func waitForExit(_ process: Process) async -> Int32 {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                process.waitUntilExit()
                continuation.resume(returning: process.terminationStatus)
            }
        }
    }

    private func readRemaining(_ handle: FileHandle) -> Data {
        var data = Data()
        var chunk: Data
        repeat {
            chunk = handle.availableData
            data.append(chunk)
        } while !chunk.isEmpty
        return data
    }

    private func buildEnvironment(
        _ custom: [String: String]?,
        inheritPATH: Bool
    ) -> [String: String] {
        let knownPath = knownBinPaths.joined(separator: ":")

        var env: [String: String]
        if inheritPATH {
            env = ProcessInfo.processInfo.environment
            if let existingPath = env["PATH"] {
                env["PATH"] = "\(knownPath):\(existingPath)"
            } else {
                env["PATH"] = knownPath
            }
        } else {
            env = [:]
            env["PATH"] = knownPath
        }
        if let custom {
            for (key, value) in custom {
                env[key] = value
            }
        }
        return env
    }

    private var knownBinPaths: [String] { KnownPaths.all }

    private func withProcessTimeout<T: Sendable>(
        _ timeout: Duration?,
        commandLabel: String,
        pid: Int32,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        guard let timeout else {
            return try await operation()
        }

        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await Task.sleep(for: timeout)
                kill(pid, SIGTERM)
                throw ProcessError.timeout(command: commandLabel, after: timeout)
            }

            group.addTask {
                try await operation()
            }

            guard let value = try await group.next() else {
                throw ProcessError.cancelled
            }
            group.cancelAll()
            return value
        }
    }
}
