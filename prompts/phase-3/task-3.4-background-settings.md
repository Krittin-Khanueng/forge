# Task 3.4 — Background Tasks + Settings UI + Menu Bar

## Scope
Add the auto-refresh background loop, a real Settings screen, and a menu bar
extra. This is the "finishing" task that ties UX polish together.

## Files to Create

### `Core/Services/BackgroundScheduler.swift`
```swift
@MainActor
final class BackgroundScheduler {
    static let shared = BackgroundScheduler()

    private var refreshTask: Task<Void, Never>?
    private(set) var lastRefresh: Date?

    func start()       // reads AppSettings.autoRefreshIntervalMinutes
    func stop()
    func restart()     // call after settings change
    func refreshNow() async
}
```

Implementation:
- Use a single long-lived `Task` that loops:
  ```swift
  while !Task.isCancelled {
      await runRefresh()
      try? await Task.sleep(for: .seconds(intervalSeconds))
  }
  ```
- `runRefresh()` calls each detected package manager's `outdatedPackages()` in parallel
- Updates `PackageCache` and notifies an observable count
- Posts a `Notification.Name.forgeRefreshCompleted` for UI to react

### `Core/Services/Notifications/SystemNotifier.swift`
Local notifications via `UNUserNotificationCenter` (UserNotifications.framework).
```swift
@MainActor
final class SystemNotifier {
    static let shared = SystemNotifier()
    func requestAuthorizationIfNeeded() async
    func notifyOutdatedAvailable(count: Int) async
}
```
Add `NSUserNotificationAlertStyle = "alert"` in Info.plist.
Only notify if `outdatedCount` increased since last run.

## Settings UI

### `Features/Settings/SettingsView.swift` (replace placeholder)
Native macOS `Form` style with tabs:
- General
- Package Managers
- Updates
- AI
- About

### `Features/Settings/Sections/GeneralSettingsView.swift`
- Theme: System / Light / Dark
- Preferred terminal: Terminal / iTerm / Warp / Ghostty
- Open Forge at login (use `SMAppService.mainApp` if available)

### `Features/Settings/Sections/PackageManagersSettingsView.swift`
- List of all known managers with detected status (green check or "Not installed")
- "Re-detect" button → `PackageManagerRegistry.shared.detectAll()`
- For each detected manager: show resolved binary path

### `Features/Settings/Sections/UpdatesSettingsView.swift`
- Auto-refresh toggle
- Interval slider (5, 10, 15, 30, 60, 120 min)
- Notify on new outdated: toggle
- Last refresh: timestamp + "Refresh Now" button

### `Features/Settings/Sections/AISettingsView.swift`
- Provider picker: Mock (default) / Anthropic / OpenAI
- Model picker for Anthropic: `claude-opus-4-7`, `claude-sonnet-4-6` (recommended), `claude-haiku-4-5`
- API key field with `SecureField` (masks input) → stores via `SecureStorage` in Keychain
- "Test connection" button (calls `currentService.send` with a tiny "say hi" prompt)
- Note: Anthropic has no official Swift SDK — future wiring uses `SwiftAnthropic` package

### `Features/Settings/Sections/AboutView.swift`
- Forge version (from `CFBundleShortVersionString`)
- Build number
- Links: source, docs, report issue
- Credits

## Menu Bar Extra

### `App/MenuBarExtraContent.swift`
Using SwiftUI's `MenuBarExtra` (macOS 13+) — two styles available:
```swift
// Style 1: custom SwiftUI popover panel (use this)
MenuBarExtra("Forge", systemImage: "hammer.fill") {
    MenuBarContentView()
}
.menuBarExtraStyle(.window)   // → renders as a floating SwiftUI panel

// Style 2: standard dropdown menu (simpler, fewer capabilities)
// .menuBarExtraStyle(.menu)
```
Use `.menuBarExtraStyle(.window)` for the rich popover with outdated counts.

### `App/MenuBarContentView.swift`
Compact popover:
- "Forge" header
- "X outdated packages" with chevron → opens main window to Updates
- "Refresh now" button
- Last refresh timestamp
- Separator
- "Open Forge" / "Quit"

### Enable / Disable
- Setting in General: "Show menu bar icon" (default on)
- Use `Settings`-driven `.menuBarExtraVisibility` if supported, else conditional `MenuBarExtra`

## Dock Icon

- Setting in General: "Show in Dock" (default on)
- When off: change `NSApp.setActivationPolicy(.accessory)`

## Wire-Up

### `ForgeApp.swift`
- On `.onAppear` of the main window: `BackgroundScheduler.shared.start()`
- On `Settings` change for interval/enabled: `BackgroundScheduler.shared.restart()`

### `DashboardView`
- "Last refreshed" text reads `BackgroundScheduler.shared.lastRefresh`

## Tests

### `Tests/ForgeTests/BackgroundSchedulerTests.swift`
- Mock managers, fast interval (100ms)
- Assert: refresh runs N times in M time
- Assert: stop cancels cleanly
- Assert: notification posted when outdated count increases

### `Tests/ForgeTests/SettingsViewModelTests.swift`
- Change interval → scheduler restarts
- Toggle off menu bar → policy applied

## Verification
1. Set auto-refresh to 5 min, leave app running 5 min → packages re-fetched, last refresh updates
2. Install an outdated brew formula → next refresh fires a system notification
3. Quit & relaunch — settings persist
4. Menu bar icon shows; clicking → popover with outdated count
5. "Open at login" enabled, restart Mac → Forge launches
6. Turn off Dock icon → Forge runs as menu-bar-only

## Anti-scope
- No iCloud sync of settings
- No multi-window support
- No Spotlight integration
- No URL scheme handling (could be future for `forge://install/<pkg>`)
- No actual Anthropic/OpenAI HTTP calls (still mock from task 3.3)
