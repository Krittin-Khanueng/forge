import SwiftUI

struct ToolCallView: View {
    let state: AIToolCallState

    var body: some View {
        DisclosureGroup(isExpanded: .constant(true)) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Input")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Text(state.input)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .textSelection(.enabled)

                if let result = state.result {
                    Divider()
                    HStack {
                        Text(state.status == .error ? "Error" : "Result")
                            .font(.caption)
                            .foregroundStyle(state.status == .error ? .red : .secondary)
                        Spacer()
                    }
                    Text(result)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                        .textSelection(.enabled)
                }
            }
            .padding(.top, 4)
        } label: {
            HStack(spacing: 6) {
                switch state.status {
                case .running:
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)
                case .executing:
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.7)
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                case .error:
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Text(state.name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
        .padding(8)
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
