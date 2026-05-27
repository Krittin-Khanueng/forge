# Task 2.4 — Unified Search (Local + Remote)

## Scope
Build a global search experience: searches across installed packages AND remote
registries of all detected managers, with a fast keyboard-first UI.

## Files to Create

### `Core/Services/SearchService.swift`
```swift
@Observable
@MainActor
final class SearchService {
    var query: String = ""
    var localResults: [SearchHit] = []
    var remoteResults: [SearchHit] = []
    var isSearchingRemote: Bool = false
    var error: String?

    func updateQuery(_ q: String) async  // debounced; cancels previous remote tasks
}

struct SearchHit: Identifiable, Hashable, Sendable {
    let id: String              // "<manager>:<name>"
    let name: String
    let manager: PackageManagerKind
    let description: String?
    let isInstalled: Bool
    let installedVersion: String?
}
```

Debouncing:
- Use `Task.sleep(for: .milliseconds(250))` + `Task.isCancelled` check after typing
- Cancel previous remote search task when query changes

Local search:
- Filter the cached package list (from `PackageCache`)
- Fuzzy or substring match (simple `localizedCaseInsensitiveContains` is fine)

Remote search:
- Run `search(query:)` on each detected manager in parallel
- Merge results; deduplicate when local installed shows the same name (mark `isInstalled = true`)

### `Features/Search/SearchView.swift` (replace placeholder)
- Big search field at top (focus on appear with `@FocusState`)
- Two-section list:
  1. **Installed** — `localResults`
  2. **Available** — `remoteResults` (with loading indicator while searching)
- Per-row: name, manager icon, description, "Install" or "Open" button
- Keyboard: `↑/↓` to move, `↩` to install/open selected, `⌘W` to close

### `Features/Search/CommandPaletteView.swift`
A Raycast-style modal version of search.
- Triggered by `⌘K` from anywhere
- Uses AppKit bridge for a borderless floating panel:
  - `NSPanel` subclass with `.nonactivatingPanel`, `.titled` minus title bar
  - SwiftUI content hosted via `NSHostingView`
- File: `Shared/Layouts/CommandPaletteWindow.swift` for the NSPanel host
- Pressing `Esc` dismisses

### Hooking Up Global Hotkey
- Use AppKit local event monitor in `ForgeApp` `.onAppear` (NOT a global hotkey — keep within-app for now)
- `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` → match `⌘K`
- Toggle palette window

### Update `SearchService` callers
- Sidebar item "Search" → opens the same view inline (not the palette)
- Both share the same `SearchService` instance from `AppEnvironment`

## Tests

### `Tests/ForgeTests/SearchServiceTests.swift`
- Debounce: rapid query updates only fire one remote search after settle
- Cancellation: changing query while remote search running cancels it
- Dedup: installed local + matching remote → single entry with `isInstalled = true`

## Verification
1. ⌘K from anywhere → palette appears at center, focused
2. Type "ripgrep" → installed match shows immediately, remote results stream in
3. ↑/↓ navigates, ↩ on installed → opens package detail
4. ↩ on remote → starts install job (reuses `UpdateOrchestrator` install path — wire briefly)
5. Esc closes; ⌘K reopens
6. Sidebar Search shows same data without the modal chrome

## Anti-scope
- No fuzzy ranking algorithm — substring match is enough
- No system-wide global hotkey (would need accessibility permissions)
- No search history yet (could add to ActivityRepository later)
- No filters in palette (just text query)
