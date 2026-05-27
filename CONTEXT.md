# Forge — Context

**Unified package & environment manager for macOS**

Swift 6.3+, macOS 26+ (Tahoe), Xcode 26+, SwiftUI, SwiftData, swift-testing (SPM)

## Quick Reference

| Concept | Pattern |
|---|---|
| UI Observation | `@Observable @MainActor final class` |
| I/O Services | `actor` (ProcessRunner, BinaryResolver, all package managers) |
| DI | Manual construction, no container |
| Navigation | `NavigationSplitView` + `SidebarItem` enum |
| Tests | `swift-testing` only (@Test, @Suite, #expect, #require) |
| JSON Parsing | `--json` flags preferred, `JSONOutputDecoder` helper for mixed output |
| App Sandbox | **Disabled** (needed to run CLI tools) |
| Hardened Runtime | **Enabled** |

## Key Files

```
Package.swift           # swift-tools 6.3, macOS 26 min, strict concurrency, swift-testing SPM
Forge/App/
├── ForgeApp.swift      # @main entry, WindowGroup + NavigationSplitView
├── ContentView.swift   # SidebarItem enum, Cmd+K palette
├── AppEnvironment.swift # @Observable @MainActor, shared env
└── MenuBarContentView.swift

Forge/Core/
├── Models/             # Package, ActivityEntry, PackageStatus
├── PackageManagers/    # Protocol + 7 managers (Brew, NPM, PNPM, Yarn, Bun, UV, Cargo)
│   └── Helpers/        # JSONOutputDecoder
├── Process/            # ProcessRunner (actor), BinaryResolver (actor), ShellEscape, ProcessError
├── Services/
│   ├── Environments/   # EnvironmentService, drivers (Fnm, Volta, N, Rustup, Uv, Bun, System)
│   ├── Notifications/  # SystemNotifier
│   ├── SearchService.swift
│   ├── PackageRefreshService.swift
│   └── BackgroundScheduler.swift
├── Storage/
│   ├── Models/         # CachedPackage, ActivityLogEntry, AppSettings (@Model)
│   ├── Repositories/   # PackageCache, ActivityRepository, SettingsRepository
│   └── StorageStack.swift  # Singleton ModelContainer
└── Utilities/          # Logger+Forge

Forge/Features/         # UI per feature: Dashboard, Packages, Search, Updates, Environments, Settings
Forge/Shared/
├── Components/         # Card, StatCard, StatusBadge, SectionHeader, IconButton, PrimaryButton, etc.
├── DesignSystem/       # ForgeTheme (spacing, radius, fonts)
└── Layouts/            # SidebarView, CommandPaletteWindow (NSPanel)
```

## Naming Conventions

- Manager files: `<Name>Manager.swift` (BrewManager, NPMManager, etc.)
- Driver files: `<Name>Driver.swift` (FnmNodeDriver, UvPythonDriver, etc.)
- View files: `<Name>View.swift` or `<Name>ViewModel.swift`
- Test files: `<Name>Tests.swift` or `<Name>IntegrationTests.swift`
- JSON parsing: `<Name>JSON.swift` (BrewJSON, NPMJSON) or `<Name>Parser.swift` (CargoParser, UVParser)

## Concurrency Rules

1. **@MainActor classes** own **actor** references privately → call with `await`
2. **Never** use `DispatchQueue.main.async` in feature code
3. **Never** use `@StateObject`/`@ObservedObject` — only `@Observable` + `@State`
4. `ProcessRunner.run()` supports cancellation via `withTaskCancellationHandler` + `process.terminate()`

## Process Execution

```swift
// Fire-and-collect (timeout: 120s)
let result = try await runner.run(url, arguments: ["--json", "list"])
// result.stdout, result.stderr, result.exitCode, result.isSuccess

// Streaming
let events = runner.stream(url, arguments: ["logs", "--follow", id])
for try await event in events { /* .stdout, .stderr */ }
```

## SwiftData Patterns

- All repos are `@MainActor`
- `StorageStack.shared.container` — single source for `modelContainer`
- `PackageCache.upsert()` not `insert()` — handles duplicates
- `SettingsRepository` uses singleton row pattern (single AppSettings)

## Testing

```swift
@Suite struct BrewManagerTests {
    @Test func detectsBrew() async throws {
        let manager = BrewManager()
        let url = try #require(await manager.detect())
        #expect(url.path.contains("brew"))
    }
}
```

- Integration tests disabled by default: `@Test(.disabled("integration — requires Homebrew installed"))`
- No XCTest imports anywhere

## Gotchas

- `@Model` and `@Observable` are mutually exclusive — SwiftData models use `@Model` only, ViewModels use `@Observable`
- `@Query` only works inside SwiftUI Views, never in ViewModels
- Homebrew `--json=v2` returns wrapped `{ "formulae": [...], "casks": [...] }`
- NPM/pnpm may emit warnings before JSON — use `JSONOutputDecoder` to trim
