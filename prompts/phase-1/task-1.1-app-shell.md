# Task 1.1 — App Shell + Sidebar Navigation

## Scope (DO ONLY THIS)
Create the Xcode project + app shell + sidebar. No real package manager logic yet.

## Project Setup
- Xcode project name: `Forge`
- Bundle ID: `com.forge.app`
- macOS deployment target: 15.0
- Swift version: 6.0
- Enable strict concurrency checking
- Create `Forge.entitlements`:
  - `com.apple.security.app-sandbox` = NO
  - `com.apple.security.cs.allow-unsigned-executable-memory` = YES
- Code signing: "Sign to Run Locally" (no team needed)

## Folder Structure (create empty folders + .gitkeep)
```
Forge/
├── App/
│   ├── ForgeApp.swift
│   ├── ContentView.swift
│   └── AppEnvironment.swift
├── Core/
│   ├── Models/
│   ├── Services/
│   ├── PackageManagers/
│   ├── Process/
│   ├── Storage/
│   ├── Utilities/
│   └── Extensions/
├── Features/
│   ├── Dashboard/
│   ├── Packages/
│   ├── Updates/
│   ├── Environments/
│   ├── Docker/
│   ├── Search/
│   ├── Settings/
│   └── AI/
├── Shared/
│   ├── Components/
│   ├── DesignSystem/
│   └── Layouts/
├── Resources/
│   └── Assets.xcassets
└── Tests/
    └── ForgeTests/
```

## Files to Implement

### `App/ForgeApp.swift`
- `@main struct ForgeApp: App`
- Window scene with `WindowGroup`
- Sets window min size 1100x700, default 1280x800
- Hosts `ContentView`

### `App/ContentView.swift`
- `NavigationSplitView` with sidebar + detail
- Sidebar uses `SidebarView`
- Detail switches on selected `SidebarItem`

### `App/AppEnvironment.swift`
- `@Observable @MainActor final class` holding shared singletons (will grow over time)
- For now: empty placeholders
- In ContentView: `@State private var appEnv = AppEnvironment()` — use @State, not @StateObject (deprecated)

### `Features/.../*View.swift` (placeholder views — ONE FILE EACH)
- `Features/Dashboard/DashboardView.swift` — shows "Dashboard" centered
- `Features/Packages/PackagesView.swift` — shows "Packages" centered
- `Features/Updates/UpdatesView.swift`
- `Features/Environments/EnvironmentsView.swift`
- `Features/Docker/DockerView.swift`
- `Features/Search/SearchView.swift`
- `Features/Settings/SettingsView.swift`
- `Features/AI/AIView.swift`

### `Shared/Layouts/SidebarView.swift`
- Enum `SidebarItem: String, CaseIterable, Identifiable, Hashable` with cases:
  `dashboard, packages, updates, environments, docker, search, settings, ai`
- Each case has `title: String` and `systemImage: String`
- `List(selection:)` binding to `SidebarItem?`
- Section grouping: "Overview" (dashboard), "Manage" (packages, updates, environments, docker), "Tools" (search, ai), "App" (settings)

## SwiftUI notes for this task
- Use `ContentUnavailableView("Select an item", systemImage: "sidebar.left")` for empty detail state
- `NavigationSplitView` selection binding: `@State private var selection: SidebarItem? = .dashboard`
- Do NOT use `@StateObject` — that's deprecated. Use `@State` for all @Observable instances.

## Verification
- App launches
- Sidebar shows 8 items grouped in 4 sections
- Clicking each item swaps the detail pane to the matching placeholder view
- Window resizes correctly

## Anti-scope (DO NOT do these in this task)
- No process execution
- No package manager logic
- No SwiftData
- No design system components yet (just plain SwiftUI)
- No real data
