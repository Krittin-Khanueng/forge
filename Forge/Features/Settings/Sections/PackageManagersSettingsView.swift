import SwiftUI

struct PackageManagersSettingsView: View {
    @State private var isDetecting = false

    private let registry = PackageManagerRegistry.shared

    var body: some View {
        Form {
            Section {
                ForEach(PackageManagerKind.allCases, id: \.self) { kind in
                    HStack {
                        Image(systemName: kind.systemImage)
                            .frame(width: 24)
                        Text(kind.displayName)
                        Spacer()
                        if registry.detectedKinds.contains(kind) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Installed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Not installed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Detected Managers")
            }

            Section {
                HStack {
                    PrimaryButton(label: "Re-detect Package Managers", systemImage: "arrow.triangle.2.circlepath", isLoading: isDetecting) {
                        Task {
                            isDetecting = true
                            await PackageManagerRegistry.shared.detectAll()
                            isDetecting = false
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}
