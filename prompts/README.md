# Forge — Prompt Pack for CommandCode

แบ่ง prompt เป็น **3 phase / 13 task** เพื่อหลีกเลี่ยงปัญหา one-shot generation
ที่ทำให้ได้ skeleton compile ไม่ผ่าน

## วิธีใช้

1. รัน task ตามลำดับเลขในไฟล์ (1.1 → 1.2 → 1.3 ...)
2. **อย่าข้าม phase** — phase 2/3 พึ่งโครงจาก phase 1
3. หลังจบแต่ละ task: รัน `xcodebuild -scheme Forge build` ก่อนไปต่อ
4. ถ้า task ไหนได้ผลไม่ตามคาด ให้ retry task เดิมก่อน อย่ารีบไปต่อ

## ลำดับ Task

### Phase 1 — Foundation (compile + Brew ทำงานจริง)
- `phase-1/task-1.1-app-shell.md` — Xcode project + sidebar + navigation skeleton
- `phase-1/task-1.2-process-layer.md` — Async process execution + PATH discovery
- `phase-1/task-1.3-brew-manager.md` — PackageManagerProtocol + Brew real integration
- `phase-1/task-1.4-dashboard-packages-ui.md` — Dashboard + Packages list (Brew data)
- `phase-1/task-1.5-design-system-storage.md` — Components + SwiftData persistence

### Phase 2 — Multi-Manager + Updates + Search
- `phase-2/task-2.1-node-managers.md` — npm / pnpm / yarn / bun
- `phase-2/task-2.2-python-rust-managers.md` — uv + cargo
- `phase-2/task-2.3-updates-system.md` — outdated + bulk updates
- `phase-2/task-2.4-unified-search.md` — global search

### Phase 3 — Docker + Environments + AI + Background
- `phase-3/task-3.1-docker.md` — containers + images
- `phase-3/task-3.2-environments.md` — Python venvs / Node versions / Rust toolchains
- `phase-3/task-3.3-ai-scaffold.md` — AIService protocol + tool calling
- `phase-3/task-3.4-background-settings.md` — auto refresh + settings UI

## หลักการสำคัญที่ใช้ทุก task

- **macOS 26 (Tahoe)**, **Xcode 26**, **Swift 6.3** strict concurrency
- **App Sandbox: DISABLED** (จำเป็นเพื่อรัน brew/npm/docker)
- **Hardened Runtime: ENABLED**
- **PATH discovery**: ลอง `/opt/homebrew/bin` แล้ว `/usr/local/bin` ก่อน fallback `/bin/zsh -lc 'command -v <bin>'`
- **JSON-first**: ห้าม parse terminal text ถ้ามี `--json` flag
  - มี JSON: `brew --json=v2`, `npm --json`, `pnpm --json`, `uv pip list --format json`
  - ไม่มี JSON: `uv tool list`, `cargo install --list`, `bun pm ls -g` → parse text
- **Swift Testing** (ไม่ใช่ XCTest): `@Test(.disabled("reason"))`, `try #require(optional)`
- **SwiftData**: `@Model` ห้าม `@Observable`; `@Query` ใช้แค่ใน SwiftUI View เท่านั้น
- **Observation**: `@Observable` + `@MainActor`; ใน parent ใช้ `@State`; ใน child ใช้ `@Bindable`
- ทุก service เป็น `actor` หรือ `@MainActor final class` ระบุชัด
- **SwiftAnthropic** สำหรับ AI integration (task 3.3) — ไม่มี official Apple Swift SDK จาก Anthropic

## Tips

- ถ้า commandcode ถาม clarifying — ตอบ "follow the prompt as written, don't ask, make reasonable defaults"
- เก็บ output ของแต่ละ task เป็น git commit แยก รอลบ task ที่ทำพลาดได้ง่าย
- ถ้า task ใหญ่เกินไป ให้แตกครึ่งเอง (เช่น 1.3 อาจแตกเป็น protocol-only ก่อน แล้ว brew-impl)
