import Foundation
import OSLog

@Observable
@MainActor
final class AIController {
    var conversation: [AIMessage] = [
        AIMessage.system("You are Forge AI, a developer operations assistant. You can manage packages, Docker containers, and development environments.")
    ]
    var isStreaming = false
    var streamedText: [String: String] = [:]
    var activeToolCalls: [AIToolCallState] = []

    let executor: AIToolExecutor
    private var streamTask: Task<Void, Never>?
    private let logger = Logger.ui

    var currentService: any AIService = MockAIService()

    init(executor: AIToolExecutor) {
        self.executor = executor
    }

    func send(userMessage: String) async {
        guard !isStreaming else { return }

        let userMsg = AIMessage.user(userMessage)
        conversation.append(userMsg)
        isStreaming = true
        streamedText = [:]
        activeToolCalls = []

        let request = AIRequest(
            messages: conversation,
            tools: ForgeTool.allCases.map { $0.definition },
            temperature: 0.7,
            maxTokens: 4096
        )

        streamTask = Task { @MainActor in
            do {
                let stream = currentService.stream(request)
                var assistantContent: [AIMessage.Content] = []
                var currentTextID = ""
                var currentText = ""

                for try await event in stream {
                    guard !Task.isCancelled else { return }

                    switch event {
                    case .textDelta(let delta):
                        if currentTextID.isEmpty { currentTextID = UUID().uuidString }
                        currentText += delta
                        streamedText[currentTextID] = currentText

                    case .toolUseStarted(let id, let name):
                        if !currentText.isEmpty {
                            assistantContent.append(.text(currentText))
                            currentText = ""
                            currentTextID = ""
                        }
                        activeToolCalls.append(AIToolCallState(id: id, name: name, input: "{}", result: nil, status: .running))

                    case .toolUseInputDelta(let id, let partial):
                        if let idx = activeToolCalls.firstIndex(where: { $0.id == id }) {
                            activeToolCalls[idx].input = partial
                        }

                    case .toolUseCompleted(let id, let finalInput):
                        if let idx = activeToolCalls.firstIndex(where: { $0.id == id }) {
                            activeToolCalls[idx].status = .executing
                            let result = try? await executor.execute(toolName: activeToolCalls[idx].name, input: finalInput)
                            activeToolCalls[idx].result = result?.content
                            activeToolCalls[idx].status = result?.isError == true ? .error : .completed
                            let toolContent = AIMessage.Content.toolResult(
                                toolUseID: id,
                                content: result?.content ?? "error",
                                isError: result?.isError ?? true
                            )
                            assistantContent.append(toolContent)
                        }

                    case .done:
                        if !currentText.isEmpty {
                            assistantContent.append(.text(currentText))
                        }

                        let assistantMsg = AIMessage(role: .assistant, content: assistantContent)
                        conversation.append(assistantMsg)
                        isStreaming = false

                    case .error(let msg):
                        conversation.append(AIMessage.assistant("Error: \(msg)"))
                        isStreaming = false
                        return
                    }
                }
            } catch {
                conversation.append(AIMessage.assistant("Error: \(error.localizedDescription)"))
                isStreaming = false
            }
        }
    }

    func stop() {
        streamTask?.cancel()
        streamTask = nil
        isStreaming = false
    }
}

struct AIToolCallState: Identifiable, Sendable {
    let id: String
    let name: String
    var input: String
    var result: String?
    var status: AIToolCallStatus

    enum AIToolCallStatus: Sendable { case running, executing, completed, error }
}
