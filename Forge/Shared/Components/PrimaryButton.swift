import SwiftUI

struct PrimaryButton: View {
    let label: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    var action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ForgeTheme.Spacing.s) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(label)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
    }
}
