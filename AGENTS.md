# Memory

## Project Overview
See @README.md for project overview, features, requirements, and build commands.

## Code Style Guidelines
- Use descriptive variable names
- Follow existing patterns in the codebase
- Extract complex conditions into meaningful boolean variables

## Architecture Notes

### Concurrency
- **I/O & process execution**: `actor` — `ProcessRunner`, `BinaryResolver`, all package managers (BrewManager, NPMManager, etc.)
- **UI state, ViewModels, repositories**: `@MainActor final class` — `AppEnvironment`, `DashboardViewModel`, `PackagesViewModel`, `SearchService`, `EnvironmentService`
- **Singletons**: `static let shared` on `@MainActor` types — `StorageStack`, `PackageManagerRegistry`, `BackgroundScheduler`, `SystemNotifier`
- Bridge pattern: `@MainActor` types own `actor` references privately, call with `await`

### Service Initialization
- No DI container; manual construction
- `AppEnvironment` owns `SearchService`, provides via SwiftUI `.environment()`
- ViewModels own their own dependencies (e.g., `DashboardViewModel` creates `PackageCache(container:)`)
- Views create ViewModels via `@State private var viewModel = XYZViewModel()`

### Navigation
- `NavigationSplitView` with `SidebarItem` enum
- Each case provides `title`, `systemImage`, `@ViewBuilder var detailView`
- Cmd+K opens `CommandPaletteWindow` (NSPanel, borderless, floating)
- `MenuBarExtra` secondary scene for menu bar popover

### Package Manager Protocol
- `PackageManagerProtocol: Sendable` with `kind`, `detect()`, `installedPackages()`, `outdatedPackages()`, `search()`, `install/uninstall/update/updateAll`
- 7 managers in `PackageManagerRegistry`: Brew, NPM, PNPM, Yarn, Bun, UV, Cargo
- Each manager: `actor` + private `ProcessRunner` instance + cached binary URL

### SwiftData
- `StorageStack.shared` singleton with `ModelContainer` (disk-backed)
- 3 models: `CachedPackage`, `ActivityLogEntry`, `AppSettings`
- 3 repositories: `SettingsRepository`, `PackageCache`, `ActivityRepository`
- All repositories are `@MainActor`

### Definitions
- Replace `<state>` with appropriate state components for each feature

## Common Workflows

### Build & Test
```bash
swift build          # Build the app
swift test           # Run all tests
```

### Adding a New Package Manager
1. Create manager file in `Forge/Core/PackageManagers/<Name>/`
2. Implement `PackageManagerProtocol` as an `actor`
3. Add JSON parsing structs if needed
4. Register in `PackageManagerRegistry.detectAll()`
5. Add tests in `Tests/ForgeTests/`

### Adding a New Feature
1. Create directory in `Forge/Features/<Name>/`
2. Add `SidebarItem` case with detail view
3. Create ViewModel (`@MainActor @Observable final class`) if stateful
4. Add Settings section if configurable

### Testing Conventions
- Framework: `swift-testing` (never XCTest)
- `@Test`, `@Suite`, `#expect`, `#require`
- Integration tests: `@Test(.disabled("integration — requires X installed"))`
- Use `try #require(optionalValue)` for nil checks
