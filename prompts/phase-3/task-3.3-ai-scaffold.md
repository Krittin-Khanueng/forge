# Task 3.3 — AI Assistant Scaffold (Architecture Only, No LLM Calls)

## Scope
Lay down the architecture for future AI integration. No real LLM calls yet.
The point is: when we plug in a provider (Anthropic / OpenAI / local) later,
no feature code changes — only the AIService implementation.

## Files to Create

### `Core/Services/AI/AIService.swift`
```swift
protocol AIService: Sendable {
    var capabilities: AICapabilities { get }
    func send(_ request: AIRequest) async throws -> AIResponse
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AIStreamEvent, Error>
}

struct AICapabilities: Sendable {
    let supportsTools: Bool
    let supportsStreaming: Bool
    let maxTokens: Int
}

struct AIRequest: Sendable {
    let messages: [AIMessage]
    let tools: [AITool]
    let temperature: Double?
    let maxTokens: Int?
}

struct AIMessage: Sendable {
    let role: Role
    let content: [Content]
    enum Role: String, Sendable { case system, user, assistant, tool }
    enum Content: Sendable {
        case text(String)
        case toolUse(id: String, name: String, input: [String: AnyCodable])
        case toolResult(toolUseID: String, content: String, isError: Bool)
    }
}

struct AIResponse: Sendable {
    let messages: [AIMessage]
    let usage: AIUsage?
    let stopReason: String?
}

enum AIStreamEvent: Sendable {
    case textDelta(String)
    case toolUseStarted(id: String, name: String)
    case toolUseInputDelta(id: String, partial: String)
    case toolUseCompleted(id: String, finalInput: [String: AnyCodable])
    case done(AIUsage?)
    case error(String)
}

struct AIUsage: Sendable {
    let inputTokens: Int
    let outputTokens: Int
}

struct AnyCodable: Codable, Sendable, Hashable { /* type-erased JSON value */ }
```

### `Core/Services/AI/AITool.swift`
```swift
struct AITool: Sendable {
    let name: String
    let description: String
    let inputSchema: [String: AnyCodable]   // JSON schema
}
```

### `Core/Services/AI/Tools/ForgeTools.swift`
Catalog of built-in tools the AI can call. Each tool is a thin wrapper around
existing services.

```swift
enum ForgeTool: String, CaseIterable, Sendable {
    case listPackages
    case outdatedPackages
    case searchPackages
    case installPackage
    case uninstallPackage
    case updatePackage
    case listContainers
    case listEnvironments
}

extension ForgeTool {
    var definition: AITool { /* name + description + JSON schema */ }
}
```

### `Core/Services/AI/AIToolExecutor.swift`
```swift
@MainActor
final class AIToolExecutor {
    init(registry: PackageManagerRegistry,
         docker: DockerClient,
         environments: EnvironmentService) { ... }

    func execute(toolName: String, input: [String: AnyCodable]) async throws -> AIToolResult
}

struct AIToolResult: Sendable {
    let content: String          // JSON-serialized result
    let isError: Bool
}
```

Mapping example:
- `listPackages(manager?: String)` → calls `PackageManagerRegistry.manager(...).installedPackages()` → JSON-encodes
- `installPackage(manager: String, name: String)` → enqueues an `UpdateJob`-style install + returns job ID

### `Core/Services/AI/Providers/MockAIService.swift`
Default implementation used until a real provider is configured.
- Returns canned responses
- Demonstrates the tool-call loop with one round trip
- Used in previews + tests

### `Core/Services/AI/AIController.swift`
```swift
@Observable
@MainActor
final class AIController {
    var conversation: [AIMessage] = []
    var isStreaming: Bool = false
    var currentService: any AIService
    let executor: AIToolExecutor

    func send(userMessage: String) async  // runs the full tool-call loop
}
```

Tool-call loop:
1. Append user message
2. Request from service with `tools = ForgeTool.allCases.map { $0.definition }`
3. Stream → render text
4. If assistant emits tool use → executor.execute → append tool result → loop
5. Stop when assistant returns text without tool use

### `Features/AI/AIView.swift` (replace placeholder)
- Chat-style view: message bubbles, system prompt header, input box at bottom
- Tool calls render inline as collapsible blocks ("Called listPackages → 47 results")
- Streaming text renders incrementally
- "Send" disabled while streaming
- "Stop" button to cancel

### `Features/AI/MessageBubble.swift`
Rendering for user / assistant / tool / system messages.

### `Features/AI/ToolCallView.swift`
Disclosure group showing tool name, input JSON, result JSON.

## Settings Hook
Add (just the data — UI in task 3.4):
```swift
// In AppSettings model (extend from task 1.5)
var aiProvider: String = "mock"        // "mock" | "anthropic" | "openai"
var aiModel: String = "claude-sonnet-4-6"
// API keys go in Keychain — define accessor:
```

### `Core/Storage/SecureStorage.swift`
Keychain wrapper for API keys:
```swift
@MainActor
enum SecureStorage {
    static func setAPIKey(_ key: String, for provider: String) throws
    static func apiKey(for provider: String) -> String?
    static func deleteAPIKey(for provider: String) throws
}
```

## Tests

### `Tests/ForgeTests/AIToolExecutorTests.swift`
- Inject mock registry/docker/env
- Execute each tool definition with sample input
- Assert correct service method called + JSON result shape

### `Tests/ForgeTests/MockAIServiceTests.swift`
- Send a message → assert canned response
- Stream → assert events arrive in expected order

## Verification
1. Open AI view → see chat UI
2. Send "list my packages" → mock service responds with canned tool-call sequence → real `listPackages` runs → real result rendered
3. Real package data appears in the assistant response

## Future Provider Implementation Notes (for task 3.4+)
When wiring up a real provider later, use **SwiftAnthropic** (community Swift package, high quality):
```swift
// Tool definition matches AITool shape:
MessageParameter.Tool.function(
    name: "list_packages",
    description: "...",
    inputSchema: .init(type: .object, properties: [...], required: [...])
)

// Streaming events to map to AIStreamEvent:
// contentBlockDelta + delta.type == "text_delta"     → .textDelta(delta.text)
// contentBlockStart + block.type == "tool_use"       → .toolUseStarted(id:name:)
// contentBlockDelta + delta.type == "input_json_delta" → .toolUseInputDelta(id:partial:)
// contentBlockStop after tool_use                    → .toolUseCompleted(id:finalInput:)
// message_stop                                       → .done(usage)

// Prompt caching — cache_control at system level:
// MessageParameter.Cache(type: .text, text: "...", cacheControl: .init(type: "ephemeral"))

// Extended thinking (budgetTokens > 0):
// MessageParameter(... thinking: .init(budgetTokens: 16000))
// Response includes .thinking(ThinkingContent) blocks — must be sent back in multi-turn history

// Model IDs for Forge (use these constants — no official SDK enum yet):
let claudeOpus47   = "claude-opus-4-7"      // most capable
let claudeSonnet46 = "claude-sonnet-4-6"    // recommended for tool use
let claudeHaiku45  = "claude-haiku-4-5"     // cost-efficient
```

## Anti-scope
- DO NOT implement Anthropic or OpenAI providers — just leave the notes above as comments
- No conversation persistence (in-memory only)
- No system prompt customization UI
- No streaming token counting display
