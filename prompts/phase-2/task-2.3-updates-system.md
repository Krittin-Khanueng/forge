# Task 2.3 — Updates System (Bulk Operations + Live Output)

## Scope
Build the Updates feature: aggregate outdated packages across all managers,
support single + bulk updates, stream output, log to activity.

## Files to Create

### `Core/Services/UpdateOrchestrator.swift`
Coordinates multiple manager update operations.

```swift
// @Observable + @MainActor: store in parent via @State, pass to children via @Bindable
@Observable
@MainActor
final class UpdateOrchestrator {
    var jobs: [UpdateJob] = []
    var isRunning: Bool { jobs.contains { $0.state == .running } }

    func enqueueUpdate(_ package: Package)
    func enqueueUpdateAll(for manager: PackageManagerKind)
    func cancel(_ jobID: UUID)
    func cancelAll()
    func clearFinished()
}

struct UpdateJob: Identifiable, Sendable {
    let id: UUID
    let package: Package?  // nil = "update all" for the manager
    let manager: PackageManagerKind
    var state: State
    var outputLines: [String]  // captured stdout/stderr lines
    var startedAt: Date?
    var finishedAt: Date?
    var exitCode: Int32?
    enum State: Sendable { case pending, running, succeeded, failed, cancelled }
}
```

Job execution:
- Concurrent jobs allowed, BUT serialize per-manager (e.g. don't run two `brew upgrade` in parallel)
- Use `ProcessRunner.stream(...)` and pipe events into the job's `outputLines`
- On finish, log to `ActivityRepository`

### Extend `PackageManagerProtocol`
Add streaming variants:
```swift
protocol PackageManagerProtocol: Sendable {
    // ...existing methods stay
    func updateStreaming(_ name: String) -> AsyncThrowingStream<ProcessRunner.StreamEvent, Error>
    func updateAllStreaming() -> AsyncThrowingStream<ProcessRunner.StreamEvent, Error>
}
```
Provide a default implementation that runs `update(name)` / `updateAll()` and emits a single event with the final result. Override in BrewManager + Node managers for real streaming.

### `Features/Updates/UpdatesViewModel.swift`
```swift
@Observable
@MainActor
final class UpdatesViewModel {
    var outdatedByManager: [PackageManagerKind: [Package]] = [:]
    var isLoading: Bool = false
    var selectedPackages: Set<Package.ID> = []
    let orchestrator: UpdateOrchestrator

    func load() async                  // queries outdated across all detected managers in parallel
    func updateSelected()
    func updateAll(for manager: PackageManagerKind)
}
```

### `Features/Updates/UpdatesView.swift` (replace placeholder)
Layout:
- Top: total outdated badge, "Refresh" button, "Update All" button per manager (section header action)
- Middle: list grouped by manager, each row with checkbox + name + current → latest + per-row "Update" button
- Bottom split: live job output pane (read-only console view, monospaced, auto-scroll)

### `Features/Updates/JobConsoleView.swift`
Read-only stream of `UpdateJob.outputLines` for the selected job.
- Monospaced font from `ForgeTheme.Font.mono`
- Auto-scrolls to bottom as new lines arrive
- Tab bar at top to switch between active jobs

### `Features/Updates/JobRowView.swift`
Status pill + package name + duration + cancel button.

## Wire-Up

### `PackagesView` — enable action buttons
- `PackageRowDetail` "Update" button → `orchestrator.enqueueUpdate(package)` then switch to Updates view
- Add `@Environment` or shared singleton for orchestrator

### `DashboardViewModel`
- `outdatedCount` now real, summed across managers

## Tests

### `Tests/ForgeTests/UpdateOrchestratorTests.swift`
- Mock manager that yields predictable stream events
- Test: serial per manager, parallel across managers
- Test: cancellation stops the underlying process
- Test: activity log entries written on completion

## Verification
1. Have at least one outdated brew package (`brew install ripgrep@13` if needed)
2. Dashboard shows correct outdated count
3. Updates view groups by manager
4. Select a package → Update → live output streams
5. Cancel mid-run → process terminates, job marked `cancelled`
6. Activity log shows entry after completion

## Anti-scope
- No retry UI (just leave failed jobs in the list)
- No notifications (phase 3)
- No batch install (only updates)
- Don't try to estimate update duration
