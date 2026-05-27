# Task 1.5 — Design System + SwiftData Persistence

## Scope
Add reusable design components used across features + set up SwiftData for cache,
settings, activity log.

## Design System

### `Shared/DesignSystem/ForgeTheme.swift`
```swift
enum ForgeTheme {
    enum Spacing { static let xs: CGFloat = 4, s = 8, m = 12, l = 16, xl = 24, xxl = 32 }
    enum Radius  { static let s: CGFloat = 6, m = 10, l = 14 }
    enum Font {
        static let mono = SwiftUI.Font.system(.body, design: .monospaced)
        static let stat = SwiftUI.Font.system(size: 32, weight: .semibold, design: .rounded)
    }
}
```

### `Shared/Components/` — add these (one file each)
- `Card.swift` — generic container with padding, background, corner radius, shadow
- `PrimaryButton.swift` — filled accent button with `isLoading` state
- `SecondaryButton.swift` — bordered
- `IconButton.swift` — SF Symbol only
- `LoadingState.swift` — `ProgressView` + caption, centered
- `EmptyState.swift` — icon + title + subtitle + optional CTA
- `ErrorState.swift` — error message + retry button
- `SectionHeader.swift` — used in inspector / forms

### `Shared/Components/StatusBadge.swift` (if not done in 1.4)
Enum of states; pill with color.

### Refactor existing views to use the design system where it makes sense
- `DashboardView` cards → use `Card`
- Empty / loading / error states across `PackagesView` → use the new components

## SwiftData

### `Core/Storage/Models/CachedPackage.swift`
```swift
@Model
final class CachedPackage {
    @Attribute(.unique) var id: String   // "<manager>:<name>"
    var name: String
    var installedVersion: String
    var latestVersion: String?
    var managerRaw: String
    var lastSeen: Date

    init(...) { ... }
    var manager: PackageManagerKind { PackageManagerKind(rawValue: managerRaw) ?? .brew }
}
```

### `Core/Storage/Models/ActivityLogEntry.swift`
```swift
@Model
final class ActivityLogEntry {
    var id: UUID
    var timestamp: Date
    var kind: String      // "install", "uninstall", "update", "refresh"
    var title: String
    var subtitle: String?
    var manager: String?
}
```

### `Core/Storage/Models/AppSettings.swift`
```swift
@Model
final class AppSettings {
    var autoRefreshEnabled: Bool = false
    var autoRefreshIntervalMinutes: Int = 30
    var preferredTerminal: String = "Terminal"   // "Terminal" | "iTerm" | "Warp" | "Ghostty"
    var theme: String = "system"                 // "system" | "light" | "dark"
    var lastRefresh: Date?
    init() {}
}
```

### `Core/Storage/StorageStack.swift`
```swift
@MainActor
final class StorageStack {
    static let shared = StorageStack()
    let container: ModelContainer

    private init() {
        let schema = Schema([CachedPackage.self, ActivityLogEntry.self, AppSettings.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        container = try! ModelContainer(for: schema, configurations: config)
    }
}
```

### `Core/Storage/Repositories/PackageCache.swift`
```swift
@MainActor
final class PackageCache {
    private let context: ModelContext
    init(container: ModelContainer) { self.context = container.mainContext }

    // Use FetchDescriptor — NEVER @Query outside SwiftUI views
    func upsert(_ packages: [Package]) throws
    func all(manager: PackageManagerKind?) throws -> [Package]  // uses context.fetch(FetchDescriptor)
    func clear(manager: PackageManagerKind?) throws
}
```

### `Core/Storage/Repositories/ActivityRepository.swift`
```swift
@MainActor
final class ActivityRepository {
    private let context: ModelContext
    init(container: ModelContainer) { self.context = container.mainContext }

    func record(kind: String, title: String, subtitle: String?, manager: PackageManagerKind?)
    func recent(limit: Int) -> [ActivityLogEntry]  // uses FetchDescriptor with sortBy + fetchLimit
}
```

### `Core/Storage/Repositories/SettingsRepository.swift`
```swift
@MainActor
final class SettingsRepository {
    private let context: ModelContext
    init(container: ModelContainer) { self.context = container.mainContext }

    func current() -> AppSettings   // uses FetchDescriptor; creates + inserts + saves if not exists
    func update(_ mutation: (AppSettings) -> Void)  // fetch, mutate, try context.save()
}
```

**SwiftData cross-actor rule**: If any repository method needs to return model IDs to another actor, return `PersistentIdentifier` only AFTER calling `context.save()`. Model objects themselves must NOT cross actor boundaries.

## Wire Into App

- `ForgeApp.swift` → attach `.modelContainer(StorageStack.shared.container)` to the WindowGroup
- `PackagesViewModel.load()` flow:
  1. Show cached packages immediately from `PackageCache`
  2. Then refresh from `BrewManager`
  3. Upsert into cache
- Dashboard "Recent Activity" reads from `ActivityRepository.recent(limit: 10)`

## Tests

### `Tests/ForgeTests/PackageCacheTests.swift`
- In-memory ModelContainer
- Upsert + read back
- Clear by manager

### `Tests/ForgeTests/SettingsRepositoryTests.swift`
- Default values on first read
- Mutations persist

## Verification
1. Launch app, see packages load
2. Quit, relaunch — packages appear instantly from cache before refresh completes
3. Activity log records a "refresh" entry; visible in Dashboard

## Anti-scope
- No background scheduling yet (phase 3)
- Don't add an entire Settings UI — just the model + repository (Settings screen lives in task 3.4)
- Don't add migration helpers — first schema
