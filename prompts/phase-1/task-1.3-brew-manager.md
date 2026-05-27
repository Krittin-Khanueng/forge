# Task 1.3 — PackageManagerProtocol + BrewManager (Real Integration)

## Scope
Define the abstraction every package manager will implement, then build BrewManager
that talks to real `brew` on the user's machine.

## Files to Create

### `Core/Models/Package.swift`
```swift
struct Package: Identifiable, Hashable, Sendable {
    let id: String              // "<manager>:<name>" e.g. "brew:ripgrep"
    let name: String
    let installedVersion: String
    let latestVersion: String?  // nil if unknown
    let manager: PackageManagerKind
    let installPath: String?
    let description: String?
    let homepage: URL?

    var isOutdated: Bool {
        guard let latest = latestVersion else { return false }
        return latest != installedVersion
    }
}

enum PackageManagerKind: String, CaseIterable, Codable, Sendable, Hashable {
    case brew, npm, pnpm, yarn, bun, uv, cargo
    var displayName: String { /* "Homebrew", "npm", ... */ }
    var systemImage: String   { /* SF Symbol per manager */ }
}
```

### `Core/PackageManagers/PackageManagerProtocol.swift`
```swift
protocol PackageManagerProtocol: Sendable {
    var kind: PackageManagerKind { get }

    /// Returns nil if the manager is not installed on this machine.
    func detect() async -> URL?

    func installedPackages() async throws -> [Package]
    func outdatedPackages() async throws -> [Package]
    func search(query: String) async throws -> [Package]
    func install(_ name: String) async throws
    func uninstall(_ name: String) async throws
    func update(_ name: String) async throws
    func updateAll() async throws
}
```

### `Core/PackageManagers/Brew/BrewManager.swift`
Real implementation. Use `actor`.

Commands to use (JSON-first):
- Detect: `BinaryResolver.shared.resolve("brew")`
- Installed: `brew info --json=v2 --installed`
- Outdated: `brew outdated --json=v2`
- Search: `brew search --formula <query>` (text output, but list of names is OK to parse)
- Install/Uninstall/Update: standard `brew install/uninstall/upgrade <name>`
- Update all: `brew upgrade`

### `Core/PackageManagers/Brew/BrewJSON.swift`
Decodable types for `brew info --json=v2` and `brew outdated --json=v2`.

Reference shape for `info --json=v2` (IMPORTANT — wrap is `formulae` array, not root array):
```json
{
  "formulae": [
    {
      "name": "ripgrep",
      "desc": "Search tool like grep and The Silver Searcher",
      "homepage": "https://github.com/BurntSushi/ripgrep",
      "installed": [
        { "version": "14.1.0", "installed_as_dependency": false }
      ],
      "versions": { "stable": "14.1.1" },
      "outdated": true
    }
  ],
  "casks": []
}
```
Key mapping:
- installedVersion = `formula.installed.first?.version`
- latestVersion = `formula.versions.stable`
- isOutdated = `formula.outdated`
- description = `formula.desc`
- homepage = `formula.homepage`

**NOTE**: `brew info --json=v2` wraps in `{ "formulae": [...], "casks": [...] }`.
`brew info --json=v1` wraps in a root JSON array `[...]`. Use v2 — includes casks too.
Homebrew may add new fields to v2 without incrementing the version — use `unknownDefault: true` in decoder or use optional properties.

Reference for `outdated --json=v2`:
```json
{
  "formulae": [
    {
      "name": "ripgrep",
      "installed_versions": ["14.1.0"],
      "current_version": "14.1.1",
      "pinned": false,
      "pinned_version": null
    }
  ],
  "casks": []
}
```

### `Core/PackageManagers/PackageManagerRegistry.swift`
```swift
@MainActor
final class PackageManagerRegistry {
    static let shared = PackageManagerRegistry()
    private(set) var available: [PackageManagerKind: any PackageManagerProtocol] = [:]

    func detectAll() async  // populates `available` by calling detect() on each
    func manager(_ kind: PackageManagerKind) -> (any PackageManagerProtocol)?
}
```
For now, register only `BrewManager`. Others come in phase 2.

## Tests

### `Tests/ForgeTests/BrewJSONTests.swift`
- Decode fixture JSON from real brew output (paste samples as string literals)
- Verify Package mapping is correct

### `Tests/ForgeTests/BrewManagerIntegrationTests.swift`
- Marked with `@Test(.disabled("integration — requires brew installed on host"))` by default
- When enabled, hits real brew and asserts non-empty results

## Verification
- In a scratch view or test: `BrewManager().installedPackages()` returns real packages
- `outdatedPackages()` returns the same set as `brew outdated` in terminal
- App still builds and runs

## Anti-scope
- Don't implement npm/pnpm/yarn/bun/uv/cargo (phase 2)
- Don't build UI yet (next task)
- Don't add SwiftData persistence yet (task 1.5)
- Don't implement search beyond brew's basic search
- Don't worry about caps/taps — formulae only for now
