import SwiftUI

struct SecondaryButton: View {
    let label: String
    var systemImage: String? = nil
    var action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: ForgeTheme.Spacing.s) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(label)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}
