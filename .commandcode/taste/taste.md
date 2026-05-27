# swift
- Use Swift 6 with strict concurrency checking enabled in Package.swift. Confidence: 0.90
- Deploy to macOS 26.0 minimum (Tahoe) and use Xcode 26+. Confidence: 0.90

# swiftui
- Use @Observable + @State exclusively; never use @StateObject, @ObservedObject, or @EnvironmentObject (deprecated). Confidence: 0.90
- Use NavigationSplitView for sidebar-based navigation layouts. Confidence: 0.70
- Use ContentUnavailableView for empty detail states. Confidence: 0.60
- Use .inspector(isPresented:) with .inspectorColumnWidth(min:ideal:max:) for detail inspector panels. Confidence: 0.70

# concurrency
- Mark all @Sendable closures explicitly — non-@Sendable closures silently inherit wrong actor isolation. Confidence: 0.90
- Never use DispatchQueue.main.async — use await MainActor.run or @MainActor annotation. Confidence: 0.90
- Services touching UI state: @MainActor final class; I/O services: actor; cross-boundary models: Sendable. Confidence: 0.80

# testing
- Use Swift Testing framework exclusively; no XCTest imports anywhere. Confidence: 0.90
- Use @Test, @Suite, #expect, #require; for nil checks use try #require(optionalValue). Confidence: 0.80
- Mark integration tests with @Test(.disabled("integration — requires X installed")) when they depend on external tools. Confidence: 0.70
- Use @Test(.enabled(if: condition)) for conditionally-enabled tests. Confidence: 0.70

# architecture
See [architecture/taste.md](architecture/taste.md)
# process-execution
- Always use ProcessRunner from Core/Process; never use raw Foundation.Process in feature code. Confidence: 0.90

# cli-integration
- Use --json flags on CLI tools when available; never parse free-form terminal text if JSON output is possible. Confidence: 0.85

# security
- App Sandbox is disabled; Hardened Runtime is enabled. Confidence: 0.80

# path-resolution
- Resolve binary paths by trying hardcoded Homebrew paths first, fallback to /bin/zsh -lc 'command -v <bin>', then cache result in BinaryResolver actor. Confidence: 0.75

# json-decoding
- Use unknownDefault: true in JSONDecoder or define optional properties for external service JSON payloads (e.g., Homebrew may add fields without version bumps). Confidence: 0.70
