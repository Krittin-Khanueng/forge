# Task 3.1 — Docker Integration

## Scope
Show containers + images from local Docker daemon. Read-only first, basic actions next.

## Files to Create

### `Core/Services/Docker/DockerClient.swift`
Wraps the `docker` CLI (NOT the API socket — keeps it simple and entitlement-friendly).

```swift
actor DockerClient {
    func isAvailable() async -> Bool        // resolves `docker` binary + `docker version`
    func containers(all: Bool) async throws -> [DockerContainer]
    func images() async throws -> [DockerImage]
    func start(containerID: String) async throws
    func stop(containerID: String) async throws
    func restart(containerID: String) async throws
    func removeContainer(_ id: String, force: Bool) async throws
    func removeImage(_ id: String, force: Bool) async throws
    func logs(containerID: String, follow: Bool) -> AsyncThrowingStream<String, Error>
}
```

Commands (JSON-first using `--format json` — newer cleaner form, Docker 20.10+):
- Containers: `docker ps --all --format json` (newline-delimited JSON, one per line)
  - Older form `--format '{{json .}}'` also works but `--format json` is preferred
  - Fields per line: `ID, Names, Image, State, Status, Ports, CreatedAt, Command, RunningFor, Size, Labels, Mounts, Networks`
- Images: `docker image ls --format json`
  - Fields: `ID, Repository, Tag, Digest, CreatedSince, CreatedAt, Size`
- Compose (out of scope for this task, future): `docker compose ps --format json`
- Logs streaming: `docker logs -f <id>` → stream via `ProcessRunner.stream`

### `Core/Models/Docker.swift`
```swift
struct DockerContainer: Identifiable, Hashable, Sendable {
    let id: String
    let names: [String]
    let image: String
    let state: String       // "running", "exited", ...
    let status: String      // "Up 3 hours", "Exited (0) 5 minutes ago"
    let ports: String
    let createdAt: Date?
}

struct DockerImage: Identifiable, Hashable, Sendable {
    let id: String
    let repository: String
    let tag: String
    let size: String
    let createdAt: Date?
}
```

### `Features/Docker/DockerViewModel.swift`
```swift
@MainActor
@Observable
final class DockerViewModel {
    var containers: [DockerContainer] = []
    var images: [DockerImage] = []
    var isLoading: Bool = false
    var error: String?
    var dockerAvailable: Bool = true

    func load() async
    func start(_ id: String) async
    func stop(_ id: String) async
    func restart(_ id: String) async
    func remove(container id: String) async
    func remove(image id: String) async
}
```

### `Features/Docker/DockerView.swift` (replace placeholder)
- Top segmented control: "Containers" / "Images"
- Empty state when Docker not running: "Docker daemon not detected. Open Docker Desktop?" + button to launch Docker.app
- Containers table:
  - Status indicator (green/gray dot), Name, Image, Status, Ports, Actions (start/stop/restart/remove)
- Images table:
  - Repo:Tag, Size, Created, Actions (remove)

### `Features/Docker/ContainerLogsView.swift`
Inspector pane for selected container.
- Streams logs via `DockerClient.logs(...)` into a scrolling monospaced view
- Auto-scroll toggle
- Search-in-logs field (filter visible lines)

### `Features/Docker/DockerDaemonHealthView.swift`
Small banner showing daemon status (running/stopped) + version + Docker Desktop link.

## Wire-Up

### `PackageManagerRegistry` is unaffected — Docker is a separate service
### Dashboard
- New stat card: "Containers running" / "Total containers" / "Images"
- Only show if Docker available

### Sidebar
- Docker item should show a small badge with running container count when > 0

## Tests

### `Tests/ForgeTests/DockerClientJSONTests.swift`
- Decode newline-delimited JSON sample from `docker ps --format json`
- Decode image JSON sample
- Use a NDJSON decoder helper: split on `\n`, decode each non-empty line independently

### `Tests/ForgeTests/DockerClientIntegrationTests.swift`
- Skipped by default
- When enabled: requires Docker running; lists containers and images

## Verification
1. With Docker running: Docker view shows real containers + images
2. Start a stopped container from UI → state updates within 2 sec
3. Click a running container → logs stream in inspector
4. Stop Docker → banner shows daemon stopped; UI doesn't crash
5. Dashboard shows accurate counts

## Anti-scope
- No `docker compose` integration
- No build/run from Dockerfile
- No image pull from registry
- No volume/network views
- Don't talk to the Docker socket directly (entitlement headache)
