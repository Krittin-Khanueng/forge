# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Forge is a native macOS 26 (Tahoe) SwiftUI app — a unified package & environment manager. Swift 6.3, strict concurrency, pure SwiftPM (no hand-authored `.xcodeproj`; open `Package.swift` in Xcode 26+).

Detailed architecture, concurrency model, naming conventions, and SwiftData/testing patterns live in the imported files below — read them rather than rediscovering from code.

@AGENTS.md
@CONTEXT.md

## Build & test

- Build: `swift build`
- Test (all): `swift test`
- Test (single): `swift test --filter <Name>` (swift-testing), e.g. `swift test --filter BrewJSONTests`
- Integration tests are marked `.disabled("integration — requires X installed")` and skip by default; they need the real tool (brew/npm/pnpm/…) on the machine.
- If the Xcode MCP server is connected, `BuildProject` / `RunAllTests` build and test through the open `Package.swift` workspace.
- Format: `swiftformat .` · Lint: `swiftlint` (configs in `.swiftformat` / `.swiftlint.yml`; install with `brew install swiftformat swiftlint`). A `PostToolUse` hook auto-formats edited Swift files when SwiftFormat is installed.

## Critical constraints

- **Do not remove the `swift-testing` SPM dependency**, and do not pin it to 6.3.x: toolchain-only `import Testing` fails without `_TestingInternals`, and 6.3.x pins currently break macro builds (see @AGENTS.md).
- Strict concurrency is enabled via `.enableUpcomingFeature("StrictConcurrency")` on both targets. Honor the concurrency rules in @CONTEXT.md — actors for I/O and process execution, `@MainActor` for UI/ViewModels/repositories, no `DispatchQueue.main.async`, no `@StateObject`/`@ObservedObject`.
- `UNUserNotificationCenter` raises an uncatchable Objective-C exception when there is no bundle identifier (running outside a packaged `.app`); guard `Bundle.main.bundleIdentifier != nil` before touching it.

## Commits

- **Never include AI attribution** in commit messages — no `Co-Authored-By: Claude`, no "Generated with Claude", no 🤖. A repo hook rejects commits containing it.
- The default branch is `main`. Commit and push only when asked.
