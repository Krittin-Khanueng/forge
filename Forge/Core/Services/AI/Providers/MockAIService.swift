import Foundation

final class MockAIService: AIService, @unchecked Sendable {
    let capabilities = AICapabilities(supportsTools: true, supportsStreaming: true, maxTokens: 4096)

    func send(_ request: AIRequest) async throws -> AIResponse {
        let lastUserMessage = request.messages.filter { $0.role == .user }.last

        let toolDefs = ForgeTool.allCases.map { $0.definition }
        let hasTools = !request.tools.isEmpty

        if hasTools, let msg = lastUserMessage,
           let text = msg.content.first,
           case .text(let userText) = text {
            return cannedToolResponse(for: userText, tools: request.tools)
        }

        return AIResponse(
            messages: [AIMessage.assistant("I'm the mock AI assistant. Configure a real provider to get live responses.")],
            usage: AIUsage(inputTokens: 10, outputTokens: 15),
            stopReason: "end_turn"
        )
    }

    func stream(_ request: AIRequest) -> AsyncThrowingStream<AIStreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let lastUser = request.messages.filter { $0.role == .user }.last
            let text = lastUser.flatMap { msg in
                if case .text(let t) = msg.content.first { return t } else { return nil }
            } ?? ""

            let hasTools = !request.tools.isEmpty

            if hasTools, text.localizedCaseInsensitiveContains("package") || text.localizedCaseInsensitiveContains("install") || text.localizedCaseInsensitiveContains("list") {
                let tool = request.tools[0]
                let toolID = "mock_\(UUID().uuidString.prefix(8))"

                let responseText = "Let me check that for you."
                for word in responseText.split(separator: " ") {
                    continuation.yield(.textDelta(String(word) + " "))
                }

                continuation.yield(.toolUseStarted(id: toolID, name: tool.name))
                continuation.yield(.toolUseInputDelta(id: toolID, partial: "{"))

                var inputJSON: [String: AnyCodable] = [:]
                if tool.name.contains("package") || tool.name.contains("search") {
                    inputJSON["query"] = AnyCodable(text)
                }
                if tool.name == "list_packages" {
                    inputJSON["manager"] = AnyCodable("brew")
                }

                // TODO(forge): placeholder — real JSON streaming would come from LLM
                continuation.yield(.toolUseCompleted(id: toolID, finalInput: inputJSON))

                continuation.yield(.textDelta("Here are the results."))
            } else {
                let response = "Hello! I'm the mock AI. How can I help with your packages?"
                for char in response {
                    continuation.yield(.textDelta(String(char)))
                }
            }

            continuation.yield(.done(AIUsage(inputTokens: 10, outputTokens: 20)))
            continuation.finish()
        }
    }

    private func cannedToolResponse(for text: String, tools: [AITool]) -> AIResponse {
        let tool = tools[0]
        let toolID = "mock_tool_\(UUID().uuidString.prefix(6))"

        var input: [String: AnyCodable] = [:]
        if text.localizedCaseInsensitiveContains("brew") || tool.name.contains("package") {
            input["manager"] = AnyCodable("brew")
        }
        if tool.name.contains("search") {
            input["query"] = AnyCodable(text)
        }

        let toolUseMsg = AIMessage(
            id: toolID,
            role: .assistant,
            content: [.toolUse(id: toolID, name: tool.name, input: input)]
        )

        let textMsg = AIMessage.assistant("I called \(tool.name) and got the results above.")

        return AIResponse(messages: [toolUseMsg, textMsg], usage: AIUsage(inputTokens: 20, outputTokens: 30), stopReason: "tool_use")
    }
}
