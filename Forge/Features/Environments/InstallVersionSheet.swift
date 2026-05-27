import SwiftUI

struct InstallVersionSheet: View {
    let kind: RuntimeKind
    let onInstall: (String) -> Void

    @State private var version: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Install \(kind.displayName)")
                .font(.title2)
                .fontWeight(.semibold)

            HStack {
                Image(systemName: kind.systemImage)
                    .font(.title)
                    .foregroundStyle(.secondary)
                TextField("Version (e.g. 3.13, 22.0.0)", text: $version)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
            }
            .padding(.horizontal)

            Text(kind == .python ? "Examples: 3.13, 3.12.0, 3.11.9" : kind == .node ? "Examples: 22.0.0, 20.15.0" : kind == .rust ? "Examples: stable, nightly, 1.80.0" : "Current only")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                SecondaryButton(label: "Cancel") {
                    dismiss()
                }
                PrimaryButton(label: "Install", systemImage: "arrow.down.circle") {
                    guard !version.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onInstall(version.trimmingCharacters(in: .whitespaces))
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 30)
        .frame(width: 400)
    }
}
