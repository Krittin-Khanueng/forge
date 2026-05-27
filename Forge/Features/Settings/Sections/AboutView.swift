import SwiftUI

struct AboutView: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    Text("Forge")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Native macOS Developer Operations")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Version \(version) (\(build))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
            }

            Section("Links") {
                Link("Source Code", destination: URL(string: "https://github.com/forge/forge")!)
                    .foregroundStyle(.blue)
                Link("Documentation", destination: URL(string: "https://docs.forge.dev")!)
                    .foregroundStyle(.blue)
                Link("Report an Issue", destination: URL(string: "https://github.com/forge/forge/issues")!)
                    .foregroundStyle(.blue)
            }

            Section("Credits") {
                Text("Built with SwiftUI, SwiftData, and Swift Testing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Copyright © 2026 Forge")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
    }
}
