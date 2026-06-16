# Forge

**Unified package & environment manager for macOS**

Manage all your package managers from a single, beautiful native app. Forge detects and monitors Homebrew, npm, pnpm, Yarn, Bun, uv, and Cargo — giving you a unified view of your entire development toolchain.

**macOS 26+ (Tahoe) · Swift 6.3 · SwiftUI · Strict Concurrency**

---

## Features

### Package Management
- **7 Package Managers** — Homebrew, npm, pnpm, Yarn, Bun, uv (Python), Cargo (Rust)
- **Auto-detection** — Automatically finds installed package managers on launch
- **Unified Package Table** — Browse all installed packages across every manager
- **Outdated Detection** — See which packages have updates available at a glance
- **Bulk Updates** — Update all outdated packages per-manager or across all managers
- **Install & Uninstall** — Manage packages directly from the app

### Search
- **Unified Search** — Search across all detected package managers simultaneously
- **Command Palette** — Press `Cmd+K` to search and install packages from anywhere
- **Local + Remote** — Shows installed packages first, then available packages
- **Debounced Queries** — 250ms debounce prevents unnecessary remote searches

### Environments
- **Python** — Manage uv-managed Python versions
- **Node.js** — Manage fnm, volta, or n Node versions
- **Rust** — Manage rustup toolchains
- **Bun** — Manage Bun runtime versions
- **Install & Switch** — Install new versions and set active runtimes

### Dashboard
- **Health Overview** — Visual health dial showing package freshness
- **Summary Grid** — Installed count, outdated count, active managers
- **Manager Breakdown** — See package distribution across managers
- **Activity Feed** — Recent install, update, and uninstall activity

### Background Refresh
- **Auto-Refresh** — Configurable background refresh (5–120 minute intervals)
- **Menu Bar** — Quick access to outdated count and refresh from the menu bar
- **Notifications** — Get notified when new outdated packages are detected

### Settings
- **Theme** — System, Light, or Dark mode
- **Terminal** — Choose your preferred terminal (Terminal, iTerm, Warp, Ghostty)
- **Menu Bar** — Toggle menu bar icon visibility
- **Dock** — Toggle dock icon visibility
- **Login Item** — Launch Forge at login

---

## Requirements

| Requirement | Version |
|---|---|
| macOS | 26.0+ (Tahoe) |
| Xcode | 26+ |
| Swift | 6.3+ |

---

## Build & Run

### Build
```bash
swift build
```

### Run Tests
```bash
swift test
```

### Run in Xcode
Open `Package.swift` in Xcode 26+ and press `Cmd+R`.

### Build a runnable app (release)
`swift build` only produces a bare executable with no bundle identifier — the
login item and notifications won't work. To get a real, double-clickable app:

```bash
Scripts/build-app.sh        # → dist/Forge.app (version 1.0)
Scripts/build-app.sh 1.2    # override the version
open dist/Forge.app
```

The script builds in release mode, wraps the binary in `Forge.app` with a
proper `Info.plist` (bundle id `com.forge.app`), bundles the compiled
resources, and ad-hoc signs it with the hardened runtime + entitlements.

---

## Architecture

```
Forge/
├── App/
│   ├── ForgeApp.swift           # App entry point, scene configuration
│   ├── ContentView.swift        # Main NavigationSplitView
│   ├── AppEnvironment.swift     # Central environment & DI
│   └── MenuBarContentView.swift # Menu bar popover
├── Core/
│   ├── Models/
│   │   ├── Package.swift            # Package value type
│   │   ├── PackageStatus.swift      # Status enum (upToDate, outdated, notInstalled)
│   │   └── ActivityEntry.swift      # Activity log entry
│   ├── PackageManagers/
│   │   ├── PackageManagerProtocol.swift  # Protocol all managers implement
│   │   ├── PackageManagerRegistry.swift  # Registry & auto-detection
│   │   ├── Brew/                      # Homebrew manager
│   │   ├── NPM/                       # npm manager
│   │   ├── PNPM/                      # pnpm manager
│   │   ├── Yarn/                      # Yarn manager (Classic + Berry)
│   │   ├── Bun/                       # Bun manager
│   │   ├── UV/                        # uv (Python) manager
│   │   └── Cargo/                     # Cargo (Rust) manager
│   ├── Process/
│   │   ├── ProcessRunner.swift    # Actor-based process execution
│   │   ├── BinaryResolver.swift   # Binary path resolution with caching
│   │   ├── ProcessError.swift     # Rich error types
│   │   └── ShellEscape.swift      # Shell argument escaping
│   ├── Services/
│   │   ├── PackageRefreshService.swift  # Central refresh coordinator
│   │   ├── BackgroundScheduler.swift    # Background refresh scheduling
│   │   ├── SearchService.swift          # Unified search service
│   │   ├── Environments/                # Runtime environment management
│   │   └── Notifications/               # System notifications
│   ├── Storage/
│   │   ├── StorageStack.swift          # SwiftData container singleton
│   │   ├── Models/
│   │   │   ├── CachedPackage.swift     # SwiftData package cache
│   │   │   ├── ActivityLogEntry.swift  # SwiftData activity log
│   │   │   └── AppSettings.swift       # SwiftData settings
│   │   └── Repositories/
│   │       ├── PackageCache.swift      # Package cache with TTL cleanup
│   │       ├── ActivityRepository.swift # Activity logging with batched saves
│   │       └── SettingsRepository.swift # Settings persistence
│   └── Utilities/
│       ├── PackageMergeHelpers.swift   # Package merging & sorting
│       └── Logger+*.swift              # Logging extensions
├── Features/
│   ├── Dashboard/
│   │   ├── DashboardView.swift         # Dashboard UI
│   │   └── DashboardViewModel.swift    # Dashboard state
│   ├── Packages/
│   │   ├── PackagesView.swift          # Package table with inspector
│   │   ├── PackagesViewModel.swift     # Package list state
│   │   └── PackageRowDetail.swift      # Package detail inspector
│   ├── Updates/
│   │   ├── UpdatesView.swift           # Outdated packages grouped by manager
│   │   └── UpdatesViewModel.swift      # Update state & operations
│   ├── Environments/
│   │   ├── EnvironmentsView.swift      # Runtime environment management
│   │   ├── EnvironmentService.swift    # Environment state
│   │   └── InstallVersionSheet.swift   # Version install sheet
│   ├── Search/
│   │   ├── SearchView.swift            # Full search view
│   │   └── CommandPaletteView.swift    # Cmd+K command palette
│   └── Settings/
│       ├── SettingsView.swift          # Settings tab view
│       └── Sections/                   # Individual settings tabs
├── Shared/
│   ├── Components/
│   │   ├── Card.swift              # Card container
│   │   ├── EmptyState.swift        # Empty state with optional action
│   │   ├── ErrorState.swift        # Error state with retry
│   │   ├── LoadingState.swift      # Loading spinner
│   │   ├── SkeletonRow.swift       # Skeleton loading placeholders
│   │   ├── StatusBadge.swift       # Package status badge
│   │   ├── PrimaryButton.swift     # Primary action button
│   │   ├── SecondaryButton.swift   # Secondary action button
│   │   ├── IconButton.swift        # Icon-only button
│   │   ├── SectionHeader.swift     # Section header with count
│   │   ├── StatCard.swift          # Statistics card
│   │   └── SearchResultRow.swift   # Search result row
│   ├── DesignSystem/
│   │   └── ForgeTheme.swift        # Colors, fonts, spacing, radius, animations
│   └── Layouts/
│       ├── SidebarView.swift       # Navigation sidebar
│       └── CommandPaletteWindow.swift # NSPanel for command palette
└── Resources/
    ├── Assets.xcassets/            # App icons & colors
    ├── Info.plist                  # App configuration
    └── Forge.entitlements          # Entitlements
```

---

## Key Design Patterns

### Concurrency Model
- **I/O Services** — `actor` isolation (ProcessRunner, BinaryResolver, all package managers)
- **UI State** — `@MainActor final class` (ViewModels, repositories, AppEnvironment)
- **Cross-boundary** — `Sendable` value types bridge actor boundaries
- **Never** — No `DispatchQueue.main.async`, no `@StateObject`/`@ObservedObject`

### Caching Strategy
1. **Binary Cache** — `BinaryResolver` caches resolved binary paths in memory
2. **Package Cache** — `PackageRefreshService` holds the in-memory package list
3. **Persistent Cache** — `PackageCache` (SwiftData) persists packages to disk
4. **Cache Cleanup** — Stale entries (>7 days) and removed managers are cleaned up automatically
5. **Activity Logging** — Batched saves with 500ms debounce for non-blocking writes

### Data Flow
```
App Start → Bootstrap → Detect Managers → Load Cache → Background Refresh

Refresh Cycle:
  PackageRefreshService.refresh()
    → Parallel: installedPackages() per manager
    → Parallel: outdatedPackages() per manager
    → Merge outdated into installed list
    → Persist to SwiftData cache
    → Clean stale cache entries
    → Log activity
    → Notify UI

UI Updates:
  ViewModels observe PackageRefreshService.packages
  → Stats computed on change
  → SwiftUI automatically re-renders
```

---

## Package Manager Support

| Manager | Install | Uninstall | Update | Update All | Search | Outdated | JSON |
|---------|---------|-----------|--------|------------|--------|----------|------|
| Homebrew | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| npm | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| pnpm | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Yarn | ✅ | ✅ | ✅ | ✅ | ✅ | ✅* | ⚠️ |
| Bun | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| uv | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | ❌ |
| Cargo | ✅ | ✅ | ✅ | ✅ | ✅ | ✅** | ✅ |

\* Yarn: Classic only. Berry returns empty for global operations.
\** Cargo: Requires `cargo-outdated` subcommand.

---

## Conventions

### Testing
- **Framework** — Swift Testing (never XCTest)
- **Assertions** — `@Test`, `@Suite`, `#expect`, `#require`
- **Integration Tests** — Marked with `@Test(.disabled("integration — requires X installed"))`
- **Optional Checks** — Use `try #require(optionalValue)` for nil checks

### Code Style
- Descriptive variable names
- Extract complex conditions into meaningful boolean variables
- Follow existing patterns in the codebase
- JSON-first: use `--json` flag on CLI tools when available

### Security
- **App Sandbox** — Disabled (required for CLI tool execution)
- **Hardened Runtime** — Enabled
- **Binary Resolution** — Tries hardcoded paths first, then `command -v` fallback

---

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Cmd+K` | Open Command Palette |
| `↑/↓` | Navigate results |
| `Return` | Select / Confirm |
| `Escape` | Dismiss palette |

---

## License

MIT
