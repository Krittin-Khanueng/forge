import SwiftUI

struct AIView: View {
    @State private var controller = AIController(
        executor: AIToolExecutor(
            registry: PackageManagerRegistry.shared,
            docker: DockerClient(),
            environments: EnvironmentService()
        )
    )
    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool
    @State private var scrollID: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(controller.conversation) { message in
                            MessageBubble(message: message,
                                          streamedText: controller.streamedText,
                                          toolCalls: controller.activeToolCalls)
                        }
                        if controller.isStreaming, !controller.streamedText.isEmpty {
                            MessageBubble(streaming: controller.streamedText,
                                          toolCalls: controller.activeToolCalls)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .onChange(of: controller.conversation.count) { _, _ in
                    if let last = controller.conversation.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
                .onChange(of: controller.streamedText) { _, _ in
                    if let last = controller.conversation.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }

            Divider()

            HStack(spacing: 10) {
                TextField("Ask about packages, containers, environments...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .onSubmit { sendMessage() }

                if controller.isStreaming {
                    Button("Stop") { controller.stop() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                } else {
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .onAppear { isInputFocused = true }
    }

    private func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !controller.isStreaming else { return }
        let text = trimmed
        inputText = ""
        Task { await controller.send(userMessage: text) }
    }
}
