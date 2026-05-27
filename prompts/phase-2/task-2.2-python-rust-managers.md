# Task 2.2 — Python (uv) + Rust (cargo) Managers

## Scope
Add two more `PackageManagerProtocol` implementations.
These have different semantics than Node — handle them carefully.

## Files to Create

### `Core/PackageManagers/UV/UVManager.swift`
`uv` is Astral's Python package/project manager. We focus on **uv tool** (globally installed Python CLIs) since that maps cleanly to "global packages."

Commands:
- Detect: `BinaryResolver.shared.resolve("uv")`
- Installed: `uv tool list --show-python` (uv 0.9.2+ — adds Python version per tool)
  - **Text output only — NO JSON format flag for `uv tool list`**
  - Typical format:
    ```
    ruff v0.9.1
    - ruff
    black v24.4.2
    - black
    - blackd
    ```
  - With `--show-python`:
    ```
    ruff v0.9.1 (python3.13)
    - ruff
    ```
- Outdated: **uv has no outdated command for tools** — return empty + `// TODO(forge): phase 3 — query PyPI`
- Search: `uv pip search` is **deprecated/removed** by PyPI — always return empty + log info message
- Install: `uv tool install <name>`
- Uninstall: `uv tool uninstall <name>`
- Update single: `uv tool upgrade <name>`
- Update all: `uv tool upgrade --all`

### `Core/PackageManagers/UV/UVParser.swift`
Plain-text parser for `uv tool list` output. Decoupled from manager so it's testable.

### `Core/PackageManagers/Cargo/CargoManager.swift`
Commands:
- Detect: `BinaryResolver.shared.resolve("cargo")`
- Installed: `cargo install --list` (plain text)
  - Format: `<crate> v<version>:\n    <bin1>\n    <bin2>\n`
- Outdated: requires `cargo-outdated` subcommand.
  - Probe with `cargo outdated --help`. If exit != 0 → return empty + surface a friendly note
  - If present: `cargo outdated --format json` (note: cargo-outdated v0.13+ supports `--format json`)
- Search: `cargo search <query> --limit 25` (text, parse)
- Install: `cargo install <name>`
- Uninstall: `cargo uninstall <name>`
- Update: `cargo install <name> --force` (Cargo's update-in-place idiom)

### `Core/PackageManagers/Cargo/CargoParser.swift`
Text parser for `cargo install --list` and `cargo search`.

### Update `PackageManagerRegistry`
Register UVManager and CargoManager.

## UI

Same as 2.1 — managers should now appear in filter automatically once registered + detected.

## Error Handling

When a sub-feature isn't available (e.g. `cargo-outdated` missing), the manager should:
1. Return empty/safe result
2. Expose a `featureStatus(_ feature: ManagerFeature) -> FeatureStatus` method
3. UI can surface "Install cargo-outdated for update info" as a banner (don't implement banner yet — just data)

Add:
```swift
enum ManagerFeature: Sendable { case outdated, search }
enum FeatureStatus: Sendable { case available, missing(reason: String) }
```

Make this an optional method on PackageManagerProtocol with default impl returning `.available`.

## Tests

### `Tests/ForgeTests/UVParserTests.swift`
- Decode realistic `uv tool list` output (ruff, poetry, etc.)

### `Tests/ForgeTests/CargoParserTests.swift`
- Decode `cargo install --list` output
- Decode `cargo search` output

## Verification
1. If you have `uv` installed: `uv tool install ruff` → appears in Packages view filtered to uv
2. If you have `cargo` installed: `cargo install ripgrep` → appears in Packages view filtered to cargo
3. Outdated columns gracefully empty for uv/cargo unless cargo-outdated is installed

## Anti-scope
- No project-local Python venvs here (that's task 3.2 — Environments)
- No rustup toolchain management here (that's task 3.2)
- Don't shell out to PyPI directly to compute outdated — keep network out of phase 2
