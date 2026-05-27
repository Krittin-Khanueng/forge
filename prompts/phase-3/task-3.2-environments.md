# Task 3.2 — Environment Management

## Scope
Manage developer runtimes/toolchains: Python (uv-managed Pythons), Node (via `n`/`fnm`/`volta` if present, or pure detect), Rust (rustup), Bun versions.

## Files to Create

### `Core/Services/Environments/EnvironmentService.swift`
```swift
@MainActor
@Observable
final class EnvironmentService {
    var pythonRuntimes: [RuntimeInfo] = []
    var nodeRuntimes: [RuntimeInfo] = []
    var rustToolchains: [RuntimeInfo] = []
    var bunVersions: [RuntimeInfo] = []
    var isLoading: Bool = false

    func refresh() async
    func setActive(_ runtime: RuntimeInfo) async throws
    func install(version: String, kind: RuntimeKind) async throws
    func uninstall(_ runtime: RuntimeInfo) async throws
}

struct RuntimeInfo: Identifiable, Hashable, Sendable {
    let id: String              // "<kind>:<version>"
    let kind: RuntimeKind
    let version: String
    let path: String?
    let isActive: Bool
    let source: String          // "uv", "fnm", "rustup", "system", ...
}

enum RuntimeKind: String, CaseIterable, Sendable { case python, node, rust, bun }
```

### Python
- Use `uv python list` to enumerate installed Python interpreters
  - **`uv python list` has NO `--output-format json` flag** — output is plain text
  - Format: `cpython-3.13.3-macos-aarch64-none   /Users/.../python3.13`
  - `--only-installed` flag filters to only installed versions
- Active = first entry in PATH or whatever `uv python find` returns
- Install: `uv python install <version>` (e.g. `3.13`, `3.12.0`)
- Uninstall: `uv python uninstall <version>`

### Node
Detect first available version manager in this order:
1. `fnm` — `fnm list --json`
2. `volta` — `volta list node --format=plain` (no JSON; parse text)
3. `n` — `n ls --json` (n v9+) or `n ls`
4. None — show only system node from `which node` + `node --version`

Wrap in a `NodeVersionDriver` protocol so we can plug in others.

### Rust
- `rustup toolchain list` (text — easy to parse)
- Active toolchain: `rustup show active-toolchain`
- Install: `rustup toolchain install <version>`
- Default: `rustup default <version>`
- Uninstall: `rustup toolchain uninstall <version>`

### Bun
- Bun doesn't have native multi-version yet → show only current via `bun --version`
- Mark as "single version" in UI

### `Core/Services/Environments/Drivers/*` — one file per driver
- `UvPythonDriver.swift`
- `FnmNodeDriver.swift`
- `VoltaNodeDriver.swift`
- `NNodeDriver.swift`
- `RustupDriver.swift`
- `BunDriver.swift`

Each conforms to `EnvironmentDriverProtocol`:
```swift
protocol EnvironmentDriverProtocol: Sendable {
    var kind: RuntimeKind { get }
    var source: String { get }
    func isAvailable() async -> Bool
    func list() async throws -> [RuntimeInfo]
    func setActive(_ version: String) async throws
    func install(_ version: String) async throws
    func uninstall(_ version: String) async throws
}
```

### `Features/Environments/EnvironmentsView.swift` (replace placeholder)
- Tab/segmented control: Python | Node | Rust | Bun
- Each tab shows:
  - Active version banner (highlighted)
  - List of installed versions with "Make Active" / "Uninstall" actions
  - "Install Version..." button → sheet with version input
  - Empty state if driver not available, with install instructions ("Install uv: `brew install uv`")

### `Features/Environments/InstallVersionSheet.swift`
Modal sheet to install a specific version. Text field + Install button.
Streams output during install (reuse `JobConsoleView` from task 2.3).

## Tests

### `Tests/ForgeTests/UvPythonDriverTests.swift`
- Decode `uv python list --output-format json` sample

### `Tests/ForgeTests/RustupDriverTests.swift`
- Parse `rustup toolchain list` and `rustup show active-toolchain` samples

(Integration tests disabled by default)

## Verification
1. Open Environments → Python: see all installed Pythons via uv with active marked
2. Install Python 3.13.0 from sheet → stream output, list refreshes
3. Switch to Node: see versions from fnm/volta/n or just system
4. Make different Rust toolchain active → `rustc --version` in terminal reflects change

## Anti-scope
- No project-specific runtime pinning (no .nvmrc / .python-version writing)
- No JDK / Ruby / Go management (out of scope, structure can extend later)
- Don't install version managers automatically — surface install hint
