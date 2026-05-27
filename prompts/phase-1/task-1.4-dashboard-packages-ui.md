# Task 1.4 — Dashboard + Packages List (Real Brew Data)

## Scope
Wire BrewManager into actual SwiftUI views. Show real installed Homebrew packages.

## Files to Modify/Create

### `Features/Packages/PackagesViewModel.swift`
```swift
@MainActor
@Observable
final class PackagesViewModel {
    var packages: [Package] = []
    var isLoading: Bool = false
    var error: String?
    var selectedManager: PackageManagerKind? = .brew  // filter
    var searchText: String = ""

    var filteredPackages: [Package] { /* filter by manager + search */ }

    func load() async
    func refresh() async
}
```

### `Features/Packages/PackagesView.swift` (replace placeholder)
- `NavigationStack` or direct content (sidebar is parent)
- Top toolbar: refresh button, manager filter picker, search field
- Body: SwiftUI `Table<Package>` with columns:
  - Name
  - Version (installed)
  - Latest
  - Manager (icon + name)
  - Status (badge: "up-to-date" / "outdated")
- Empty state when 0 packages
- Loading state with `ProgressView`
- Error state with retry button
- `task { await viewModel.load() }` on appear

### `Features/Packages/PackageRowDetail.swift` (inspector)
- Shown when a row is selected
- Wire via `.inspector(isPresented: $showInspector) { PackageRowDetail(package: selected) }`
  - Use `.inspectorColumnWidth(min: 240, ideal: 280, max: 360)` for sizing
- Shows: description, homepage link, install path, full version info
- Buttons: Update, Uninstall (disabled — wired in task 2.3)
- In parent PackagesView: `@State private var showInspector = false` and `@State private var selectedPackage: Package?`

### `Features/Dashboard/DashboardViewModel.swift`
```swift
@MainActor
@Observable
final class DashboardViewModel {
    var totalPackages: Int = 0
    var outdatedCount: Int = 0
    var detectedManagers: [PackageManagerKind] = []
    var recentActivity: [ActivityEntry] = []  // empty for now
    var isLoading: Bool = false

    func load() async
}

struct ActivityEntry: Identifiable, Hashable, Sendable {
    let id: UUID
    let timestamp: Date
    let title: String
    let subtitle: String?
}
```

### `Features/Dashboard/DashboardView.swift` (replace placeholder)
Grid of cards (use `LazyVGrid` with adaptive columns ~280pt):
- "Installed Packages" — big number, breakdown per manager
- "Outdated" — number + "Review updates" link
- "Detected Managers" — list of icons for detected managers
- "Recent Activity" — list (empty placeholder OK)
- "Quick Actions" — buttons: Refresh All, Open Search, Open Settings

### `Shared/Components/StatCard.swift`
Generic card with: title, big value, optional subtitle, optional accent color.
Used by Dashboard.

### `Shared/Components/StatusBadge.swift`
Small pill: `.upToDate`, `.outdated`, `.unknown` with colors.

## Hooking Up
- Update `AppEnvironment` to lazy-create `PackageManagerRegistry.shared` and trigger `detectAll()` on app launch
- `ContentView` injects shared state where needed via `.environment(...)`

## Verification
1. Launch app
2. Sidebar → Packages → Table populates with real `brew` packages
3. Filter by manager works (only Brew shown now)
4. Search filters live as you type
5. Sidebar → Dashboard shows real counts matching the Packages view
6. Refresh button re-runs without freezing the UI

## Anti-scope
- No install/uninstall/update actions yet (task 2.3)
- No real activity log (just empty list with the type defined)
- Don't add other managers (phase 2)
- Don't persist anything yet (task 1.5)
