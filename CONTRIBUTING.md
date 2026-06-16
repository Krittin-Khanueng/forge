# Contributing to Forge

Thanks for your interest in improving Forge!

## Prerequisites

- macOS 26 (Tahoe) or later
- Xcode 26+ (Swift 6.3+)

## Development

```bash
swift build            # build
swift test             # run all tests
Scripts/build-app.sh   # produce a runnable dist/Forge.app
```

Or open `Package.swift` in Xcode 26+ and press `Cmd+R`.

## Conventions

- **Tests** — swift-testing only (`@Test`, `@Suite`, `#expect`, `#require`); never XCTest. Integration tests are `.disabled(...)` and need the real tool installed.
- **Concurrency** — strict concurrency is on. Actors for I/O and process execution, `@MainActor` for UI/ViewModels/repositories. No `DispatchQueue.main.async`, no `@StateObject`/`@ObservedObject`.
- **Style** — run `swiftformat .` and `swiftlint` before pushing; match existing patterns.
- See `AGENTS.md` and `CONTEXT.md` for architecture and naming conventions.

## Pull requests

1. Fork and branch off `main`.
2. Keep changes focused; add tests for behavior changes.
3. Make sure `swift build` and `swift test` pass.
4. Open a PR describing what changed and why.
