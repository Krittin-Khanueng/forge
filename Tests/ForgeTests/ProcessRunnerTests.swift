import Foundation
import Testing
@testable import Forge

@Suite("Process Runner Tests")
struct ProcessRunnerTests {
    let runner = ProcessRunner()

    @Test("Runs echo command")
    func runsEchoCommand() async throws {
        let result = try await runner.run(
            URL(fileURLWithPath: "/bin/echo"),
            arguments: ["hello"]
        )
        #expect(result.stdout == "hello\n")
        #expect(result.exitCode == 0)
        #expect(result.isSuccess)
    }

    @Test("Captures stderr separately")
    func capturesStderrSeparately() async throws {
        let shURL = URL(fileURLWithPath: "/bin/sh")
        let result = try await runner.run(
            shURL,
            arguments: ["-c", "echo stdout; echo stderr >&2"]
        )
        #expect(result.stdout == "stdout\n")
        #expect(result.stderr == "stderr\n")
        #expect(result.isSuccess)
    }

    @Test("Non-zero exit throws")
    func nonZeroExitThrows() async throws {
        do {
            _ = try await runner.run(
                URL(fileURLWithPath: "/bin/sh"),
                arguments: ["-c", "exit 42"]
            )
            Issue.record("Expected nonZeroExit error")
        } catch let error as ProcessError {
            guard case .nonZeroExit(_, let code, _) = error else {
                Issue.record("Expected nonZeroExit, got \(error)")
                return
            }
            #expect(code == 42)
        }
    }

    @Test("Timeout fires and terminates process")
    func timeoutFiresAndTerminates() async throws {
        do {
            _ = try await runner.run(
                URL(fileURLWithPath: "/bin/sleep"),
                arguments: ["10"],
                options: ProcessRunner.Options(timeout: .milliseconds(500))
            )
            Issue.record("Expected timeout error")
        } catch let error as ProcessError {
            guard case .timeout = error else {
                Issue.record("Expected timeout, got \(error)")
                return
            }
        }
    }

    @Test("Cancellation terminates process")
    func cancellationTerminatesProcess() async throws {
        let task = Task {
            try await runner.run(
                URL(fileURLWithPath: "/bin/sleep"),
                arguments: ["10"]
            )
        }

        try await Task.sleep(for: .milliseconds(100))
        task.cancel()

        let result = await task.result
        switch result {
        case .failure(let error as ProcessError):
            guard case .cancelled = error else {
                Issue.record("Expected ProcessError.cancelled, got \(error)")
                return
            }
        case .failure(let error):
            Issue.record("Expected ProcessError, got \(error)")
        case .success(let output):
            Issue.record("Expected cancellation, got exitCode \(output.exitCode)")
        }
    }

    @Test(.disabled("Timeout test under 30s — already tested in run()"))
    func timeoutFiresAndTerminatesViaStream() async throws {
        // This test is covered by timeoutFiresAndTerminates
    }

    @Test("Streaming yields lines incrementally")
    func streamingYieldsLinesIncrementally() async throws {
        let events = try await runner.stream(
            URL(fileURLWithPath: "/bin/sh"),
            arguments: ["-c", "echo line1 && sleep 0.1 && echo line2 && sleep 0.1 && echo line3"]
        )
        .reduce(into: [ProcessRunner.StreamEvent]()) { $0.append($1) }

        let lines = events.compactMap { event -> String? in
            if case .stdoutLine(let line) = event { return line }
            return nil
        }
        #expect(lines == ["line1", "line2", "line3"])

        let hasExited = events.contains { event in
            if case .exited = event { return true }
            return false
        }
        #expect(hasExited)
    }

    @Test("Binary not found throws error")
    func binaryNotFound() async throws {
        do {
            _ = try await runner.run(
                URL(fileURLWithPath: "/nonexistent/path/xyzzy"),
                arguments: []
            )
            Issue.record("Expected error")
        } catch {
            // Foundation.Process throws NSError when executableURL doesn't exist
            #expect(error is NSError)
        }
    }
}
