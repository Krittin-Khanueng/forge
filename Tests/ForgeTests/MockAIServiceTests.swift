import Foundation
import Testing
@testable import Forge

@Suite("Mock AI Service Tests")
struct MockAIServiceTests {

    @Test("MockAIService send returns canned response")
    func sendReturnsCannedResponse() async throws {
        let service = MockAIService()
        let request = AIRequest(
            messages: [AIMessage.user("Hello")],
            tools: []
        )

        let response = try await service.send(request)
        #expect(!response.messages.isEmpty)
        #expect(response.messages[0].role == .assistant)
    }

    @Test("MockAIService send with tools triggers tool-call response")
    func sendWithToolsTriggersToolCall() async throws {
        let service = MockAIService()
        let tool = ForgeTool.listPackages.definition
        let request = AIRequest(
            messages: [AIMessage.user("list my packages")],
            tools: [tool]
        )

        let response = try await service.send(request)
        #expect(response.messages.count >= 1)
        if let first = response.messages.first {
            #expect(first.role == .assistant)
        }
    }

    @Test("MockAIService stream yields text deltas")
    func streamYieldsTextDeltas() async throws {
        let service = MockAIService()
        let request = AIRequest(
            messages: [AIMessage.user("hello")],
            tools: []
        )

        var events: [AIStreamEvent] = []
        let stream = service.stream(request)
        for try await event in stream {
            events.append(event)
        }

        let hasTextDelta = events.contains { event in
            if case .textDelta = event { return true }
            return false
        }
        #expect(hasTextDelta)

        let hasDone = events.contains { event in
            if case .done = event { return true }
            return false
        }
        #expect(hasDone)
    }

    @Test("MockAIService capabilities match expected")
    func capabilities() {
        let service = MockAIService()
        #expect(service.capabilities.supportsTools == true)
        #expect(service.capabilities.supportsStreaming == true)
        #expect(service.capabilities.maxTokens == 4096)
    }
}
