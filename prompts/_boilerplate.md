# Shared Boilerplate — Prepend at top of EVERY task prompt

```
You are a senior macOS engineer building "Forge" — a native developer-ops app.

NON-NEGOTIABLE CONSTRAINTS (apply to all code you write):
- Language: Swift 6 with strict concurrency checking enabled
  * Enable in Package.swift: .enableUpcomingFeature("StrictConcurrency") or set swiftLanguageVersion: .v6
  * Mark ALL @Sendable closures explicitly — non-@Sendable closures silently inherit wrong actor isolation
- Min deployment: macOS 15.0
- Xcode: 16+
- UI: SwiftUI only (NavigationSplitView, Table, @Observable, async tasks)

SWIFTUI STATE MANAGEMENT (iOS/macOS 17+ rules — no exceptions):
- @Observable class + @MainActor → store in parent with @State, receive in child with @Bindable
- @StateObject / @ObservedObject / @EnvironmentObject are DEPRECATED — do NOT use them
- @Observable classes must be marked @MainActor unless they have no UI-touching state
- Do NOT add @Observable to SwiftData @Model classes — @Model already has observation built in

SWIFTDATA RULES (mistakes here break the app silently):
- @Model classes: do NOT add @Observable — already observed via @Model macro
- @Query: ONLY valid inside SwiftUI View — never in services, repositories, or view models
- Outside views: use ModelContext.fetch(FetchDescriptor<T>()) instead
- Cross-actor communication: use PersistentIdentifier (only stable AFTER context.save())
- Relationships must declare explicit deleteRule: @Relationship(deleteRule: .cascade, inverse: \.field)
- FetchDescriptor supports relationshipKeyPathsForPrefetching and propertiesToFetch for performance

CONCURRENCY:
- Services that touch UI state → @MainActor final class
- Services that do I/O → actor
- Model types crossing actor boundaries → Sendable
- Never use DispatchQueue.main.async — use await MainActor.run or @MainActor annotation
- @Sendable on all closures that cross isolation boundaries

PERSISTENCE: SwiftData (see rules above)
TESTING: Swift Testing framework ONLY
- import Testing; use @Test, @Suite, #expect, #require
- Disable integration tests: @Test(.disabled("integration — requires X installed"))
- Conditional enable: @Test(.enabled(if: condition))
- Stop test on nil: let value = try #require(optionalValue)
- NO XCTest imports anywhere

App Sandbox: DISABLED in Forge.entitlements (we run system binaries)
Hardened Runtime: ENABLED

PATH discovery — GUI apps on macOS don't source shell config:
  1. Try hardcoded paths: /opt/homebrew/bin/<bin>, /usr/local/bin/<bin>, /usr/bin/<bin>
  2. Fallback: /bin/zsh -lc 'command -v <bin>' (login shell, not just `which`)
  3. Cache resolved URL in BinaryResolver actor

JSON-first: never parse free-form terminal text if the tool has a --json flag.
  Known JSON-capable: brew --json=v2, npm --json, pnpm --json, uv pip list --format json
  No JSON available: uv tool list (text only), cargo install --list (text only), bun pm ls -g (text only)

File size: no Swift file over ~250 lines. Split aggressively into focused files.

NO Combine. NO storyboards. NO AppDelegate-heavy patterns.
Process execution: ALWAYS use ProcessRunner from Core/Process. Never use raw Foundation.Process in feature code.

OUTPUT RULES:
- Produce complete, compile-ready Swift code
- DO NOT write // TODO: implement for anything in this task's scope
- DO write // TODO(forge): <feature> — phase N for things explicitly deferred
- Match existing project structure exactly — do not reorganize folders
- If a file already exists from a previous task, list changes clearly

ACCEPTANCE CRITERIA FOR THIS TASK:
- xcodebuild -scheme Forge -destination 'platform=macOS' build exits 0
- Zero Swift 6 strict concurrency errors
- The behavior in the "Verification" section works when running the app

Now read the task-specific instructions below.

================================================================
```
