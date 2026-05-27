import SwiftUI

struct MessageBubble: View {
    let role: AIMessage.Role
    let content: [AIMessage.Content]
    let toolCalls: [AIToolCallState]
    let streamedText: [String: String]
    let isStreaming: Bool

    init(message: AIMessage, streamedText: [String: String] = [:], toolCalls: [AIToolCallState] = []) {
        self.role = message.role
        self.content = message.content
        self.toolCalls = toolCalls
        self.streamedText = streamedText
        self.isStreaming = false
    }

    init(streaming streamedText: [String: String], toolCalls: [AIToolCallState]) {
        self.role = .assistant
        self.content = []
        self.toolCalls = toolCalls
        self.streamedText = streamedText
        self.isStreaming = true
    }

    var body: some View {
        HStack(alignment: .top) {
            if role == .user { Spacer(minLength: 60) }

            VStack(alignment: role == .user ? .trailing : .leading, spacing: 6) {
                if role == .system {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.caption)
                        Text("System")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 2)
                }

                ForEach(Array(content.enumerated()), id: \.offset) { _, block in
                    switch block {
                    case .text(let text):
                        Text(text)
                            .font(.body)
                    case .toolUse:
                        EmptyView()
                    case .toolResult:
                        EmptyView()
                    }
                }

                if isStreaming, let firstID = streamedText.keys.first, let text = streamedText[firstID] {
                    Text(text)
                        .font(.body)
                    if toolCalls.isEmpty {
                        ProgressView()
                            .controlSize(.small)
                            .opacity(0.5)
                    }
                }

                ForEach(toolCalls) { call in
                    ToolCallView(state: call)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(role == .user ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))
            .textSelection(.enabled)

            if role == .assistant || role == .system { Spacer(minLength: 60) }
        }
    }
}
