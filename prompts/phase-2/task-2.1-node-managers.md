# Task 2.1 — Node Ecosystem Managers (npm / pnpm / yarn / bun)

## Scope
Implement four `PackageManagerProtocol` conformances for the Node ecosystem.
These manage **global** packages (`-g`), not project-local — keeps scope small.

## Prerequisite Context
- `PackageManagerProtocol` exists from task 1.3
- `ProcessRunner` + `BinaryResolver` exist from task 1.2
- `Package` model + `PackageManagerKind` enum exist
- `PackageManagerRegistry` exists — you'll register new managers in `detectAll()`

## Files to Create

### `Core/PackageManagers/NPM/NPMManager.swift`
Commands:
- Detect: `BinaryResolver.shared.resolve("npm")`
- Installed (global): `npm list -g --depth=0 --json`
- Outdated (global): `npm outdated -g --json` (note: returns object keyed by name, NOT array)
- Search: `npm search <query> --json`
- Install: `npm install -g <name>`
- Uninstall: `npm uninstall -g <name>`
- Update: `npm update -g <name>`
- Update all: `npm update -g`

### `Core/PackageManagers/NPM/NPMJSON.swift`
Decodable models for `npm list -g --json` and `npm outdated -g --json`.
Reference (current npm v10):
```json
// npm list -g --depth=0 --json
{ "dependencies": { "typescript": { "version": "5.4.5" } } }
// npm outdated -g --json — OBJECT keyed by name, not array
{ "typescript": { "current": "5.4.5", "wanted": "5.4.5", "latest": "5.5.0", "location": "/opt/homebrew/lib/node_modules/typescript" } }
```
Decoding tip: outdated is `[String: NPMOutdatedEntry]` — use `[String: NPMOutdatedEntry](from:)`.

**npm outdated exit code**: npm outdated exits with code 1 if any packages are outdated — this is NOT an error.
In ProcessRunner, treat exit code 1 from `npm outdated` as success and parse stdout normally.

### `Core/PackageManagers/PNPM/PNPMManager.swift`
Commands:
- Detect: `BinaryResolver.shared.resolve("pnpm")`
- Installed (global): `pnpm list -g --depth=0 --json` (array of `{name, version, path}`)
- Outdated (global): `pnpm outdated -g --json` (use `--json`, NOT `--format json` — that flag doesn't exist on `pnpm outdated`)
- Install/Uninstall/Update: `pnpm add -g <name>`, `pnpm remove -g <name>`, `pnpm update -g <name>`

**pnpm 11 note**: `pnpm link --global` was removed in pnpm 11 — use `pnpm add -g .` instead for linking local dirs.

**pnpm 9+ architecture note**: pnpm stores global packages in isolated directories under
`{pnpmHomeDir}/global/v11/` — each package has its own node_modules to prevent peer dep conflicts.
`pnpm list -g --json` still works as the public API despite the different internal layout — don't
try to parse the internal directory structure directly.

### `Core/PackageManagers/Yarn/YarnManager.swift`
Yarn has two majors with VERY different command surfaces. Detect first:
- `yarn --version` — if starts with `1.` → classic, else berry (v2/v3/v4+)
- **Classic (v1.x)**: `yarn global list --json` (newline-delimited JSON objects)
- **Berry (v2+, now default for new projects)**: `yarn global` was **REMOVED ENTIRELY**.
  Yarn berry has no concept of globally installed packages — workflows moved to:
    - `yarn dlx <pkg>` for one-off execution (like `npx`)
    - Per-project tool installs only
  → For berry: `installedPackages()` returns empty + UI banner explaining "Yarn Berry doesn't support global packages — use `yarn dlx` for one-off tools"
- Install/Uninstall (classic only): `yarn global add/remove <name>`
- For berry installs: throw `ManagerError.unsupported(reason: "Yarn Berry has no global install — use yarn dlx")`

### `Core/PackageManagers/Bun/BunManager.swift`
- Detect: `BinaryResolver.shared.resolve("bun")`
- Installed (global): `bun pm ls -g` (output is plain text, no JSON yet — parse line-by-line, format: `<name>@<version>`)
- Outdated: Bun doesn't have native outdated for globals yet — return empty + TODO comment
- Install: `bun install -g <name>`
- Uninstall: `bun remove -g <name>`
- Update: `bun update -g <name>`

### Shared helper: `Core/PackageManagers/Helpers/JSONOutputDecoder.swift`
```swift
enum JSONOutputDecoder {
    static func decode<T: Decodable>(_ type: T.Type, from string: String) throws -> T
    // Strips warning prefix lines that some npm/pnpm commands prepend before JSON
}
```

### Update `PackageManagerRegistry`
Register all five (including Brew) — `detectAll()` runs detect on each in parallel,
adds only the ones that return a non-nil URL.

## UI Integration

### `Features/Packages/PackagesView.swift`
- Filter picker now shows ALL detected managers
- Table groups optionally by manager (use a `Section` or sort)

### `Features/Dashboard/DashboardViewModel.swift`
- `detectedManagers` now reflects all real-detected managers

## Tests

### `Tests/ForgeTests/NPMJSONTests.swift` etc.
- One test file per manager
- Fixture decoding tests for the JSON shapes
- Integration tests marked `@Test(.disabled(...))` to skip in CI unless explicitly enabled

## Verification
1. Run `npm i -g typescript` in terminal (if not installed)
2. Refresh Packages view in Forge
3. Filter to npm → typescript visible with version
4. Run `npm i -g typescript@5.0.0` to downgrade, refresh
5. Outdated badge shows in row

## Anti-scope
- No project-local package management (Forge is for global tools)
- No install/uninstall actions in UI yet (task 2.3 binds the buttons)
- Don't try to unify yarn classic/berry into one model — surface as detection metadata
- Don't fix Bun's missing outdated — wait until Bun ships it
