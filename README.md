# Forge

Unified package & environment manager for macOS — จัดการทุก package manager ในที่เดียว

**macOS 26+ · Swift 6 · SwiftUI**

---

## Features

- **Package Managers** — Homebrew, npm, pnpm, yarn, bun, uv (Python), cargo (Rust)
- **Docker** — containers, images, daemon health monitoring
- **Environments** — Python venvs, Node versions, Rust toolchains
- **Updates** — ตรวจจับ outdated packages + bulk update
- **Search** — unified search ทุก package manager
- **AI Assistant** — AI-powered help & tool calling

## Requirements

- macOS 26.0+ (Tahoe)
- Xcode 26+
- Swift 6.3+ (Strict Concurrency)

## Build

```bash
swift build
```

### Run Tests

```bash
swift test
```

## Architecture

```
Forge/
├── App/           # Entry point, navigation
├── Core/
│   ├── Models/         # Docker, Package, etc.
│   ├── PackageManagers/ # Brew, npm, pnpm, yarn, bun, uv, cargo
│   ├── Process/        # ProcessRunner, BinaryResolver, ShellEscape
│   ├── Services/       # AI, Docker, Environments, Search, Notifications
│   ├── Storage/        # SwiftData models & repositories
│   └── Utilities/      # Logger
├── Features/       # UI per feature (Dashboard, Packages, Docker, AI, etc.)
├── Shared/         # Reusable components, layout, design system
└── Resources/      # Assets, Info.plist, entitlements
```

## Conventions

- **Swift Testing** (ไม่ใช้ XCTest)
- `@Observable` + `@State` สำหรับ UI state
- Services: `actor` หรือ `@MainActor final class`
- App Sandbox: **disabled** (จำเป็นสำหรับรัน CLI tools)
- Hardened Runtime: enabled
- JSON-first: ใช้ `--json` flag ทุกครั้งที่มี

## License

MIT
