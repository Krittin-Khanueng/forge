import Foundation

protocol AIService: Sendable {
    var capabilities: AICapabilities { get }
    func send(_ request: AIRequest) async throws -> AIResponse
    func stream(_ request: AIRequest) -> AsyncThrowingStream<AIStreamEvent, Error>
}

struct AICapabilities: Sendable {
    let supportsTools: Bool
    let supportsStreaming: Bool
    let maxTokens: Int

    static let mock = AICapabilities(supportsTools: true, supportsStreaming: true, maxTokens: 4096)
}

struct AIRequest: Sendable {
    let messages: [AIMessage]
    let tools: [AITool]
    let temperature: Double?
    let maxTokens: Int?

    init(messages: [AIMessage], tools: [AITool] = [], temperature: Double? = nil, maxTokens: Int? = nil) {
        self.messages = messages
        self.tools = tools
        self.temperature = temperature
        self.maxTokens = maxTokens
    }
}

struct AIMessage: Identifiable, Sendable {
    let id: String
    let role: Role
    let content: [Content]

    enum Role: String, Sendable { case system, user, assistant, tool }

    enum Content: Sendable {
        case text(String)
        case toolUse(id: String, name: String, input: [String: AnyCodable])
        case toolResult(toolUseID: String, content: String, isError: Bool)
    }

    init(id: String = UUID().uuidString, role: Role, content: [Content]) {
        self.id = id
        self.role = role
        self.content = content
    }

    static func user(_ text: String) -> AIMessage {
        AIMessage(role: .user, content: [.text(text)])
    }

    static func assistant(_ text: String) -> AIMessage {
        AIMessage(role: .assistant, content: [.text(text)])
    }

    static func system(_ text: String) -> AIMessage {
        AIMessage(role: .system, content: [.text(text)])
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
