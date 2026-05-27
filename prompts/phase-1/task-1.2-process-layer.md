# Task 1.2 — Async Process Execution Layer

## Scope
Build the foundation that every package manager will use to run shell commands.
This is THE critical layer — invest in correctness here.

## Files to Create

### `Core/Process/ProcessRunner.swift`
An `actor` that runs external binaries with async/await.

```swift
actor ProcessRunner {
    struct Options: Sendable {
        var workingDirectory: URL?
        var environment: [String: String]?
        var timeout: Duration?
        var inheritParentPATH: Bool = true
    }

    struct Result: Sendable {
        let exitCode: Int32
        let stdout: String
        let stderr: String
        var isSuccess: Bool { exitCode == 0 }
    }

    // One-shot: run + collect full output
    func run(_ executable: URL, arguments: [String], options: Options = .init()) async throws -> Result

    // Streaming: async sequence of stdout lines while process runs
    func stream(_ executable: URL, arguments: [String], options: Options = .init())
        -> AsyncThrowingStream<StreamEvent, Error>

    enum StreamEvent: Sendable {
        case stdoutLine(String)
        case stderrLine(String)
        case exited(Int32)
    }
}
```

### `Core/Process/BinaryResolver.swift`
Resolves binary paths. GUI apps don't have user shell PATH — this matters.

```swift
actor BinaryResolver {
    static let shared = BinaryResolver()

    // Lookup order:
    // 1. Cached resolution
    // 2. Hardcoded common paths: /opt/homebrew/bin/<name>, /usr/local/bin/<name>, /usr/bin/<name>
    // 3. /bin/zsh -lc 'command -v <name>' (login shell)
    // Returns URL or throws BinaryResolverError.notFound
    func resolve(_ name: String) async throws -> URL

    func resolveAll(_ names: [String]) async -> [String: URL?]
}

enum BinaryResolverError: Error, Sendable {
    case notFound(String)
    case lookupFailed(String, underlying: Error)
}
```

### `Core/Process/ProcessError.swift`
Typed errors with user-readable messages.

```swift
enum ProcessError: LocalizedError, Sendable {
    case binaryNotFound(String)
    case nonZeroExit(command: String, code: Int32, stderr: String)
    case timeout(command: String, after: Duration)
    case cancelled
    case decodingFailed(String)

    var errorDescription: String? { /* friendly text */ }
    var recoverySuggestion: String? { /* actionable hint */ }
}
```

### `Core/Process/ShellEscape.swift`
- `static func escape(_ argument: String) -> String`
- Safe POSIX quoting for displaying commands (we don't pass through shell — we use Process directly — but we log the equivalent command)

### `Core/Utilities/Logger+Forge.swift`
- `extension Logger` with subsystem `com.forge.app`
- Categories: `process`, `brew`, `npm`, `ui`, `storage`, `ai`

## Implementation Notes

- Use `Foundation.Process` + `Pipe` under the hood
- For streaming: use `FileHandle.readabilityHandler` → bridge to `AsyncStream`
- For timeout: race the process await against `Task.sleep`; terminate on timeout
- For cancellation: respond to `Task.isCancelled` → call `process.terminate()`
- Environment: start from `ProcessInfo.processInfo.environment` if `inheritParentPATH`, merge custom
- Always set PATH explicitly to include `/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin`
- Capture stdout AND stderr separately (use 2 pipes)
- Decode output as UTF-8, ignore invalid bytes

## Tests

### `Tests/ForgeTests/ProcessRunnerTests.swift` (Swift Testing)
```swift
@Test func runsEchoCommand() async throws { ... }
@Test func capturesStderrSeparately() async throws { ... }
@Test func nonZeroExitThrows() async throws { ... }
@Test func timeoutFiresAndTerminates() async throws { ... }
@Test func cancellationTerminatesProcess() async throws { ... }
@Test func streamingYieldsLinesIncrementally() async throws { ... }
```

### `Tests/ForgeTests/BinaryResolverTests.swift`
```swift
@Test func resolvesSh() async throws { ... }  // /bin/sh always exists
@Test func returnsErrorForBogusBinary() async throws { ... }
@Test func cachesResolutions() async throws { ... }
```

## Verification
- All tests pass
- Open Xcode console; in a debug View or temporary scratch test, call:
  ```swift
  let runner = ProcessRunner()
  let result = try await runner.run(URL(fileURLWithPath: "/bin/echo"), arguments: ["hello"])
  print(result.stdout)  // "hello\n"
  ```

## Anti-scope
- No package manager protocol yet (next task)
- No UI work
- Don't add interactive stdin support (not needed)
- Don't reinvent shell — we run binaries directly, never through `sh -c`
