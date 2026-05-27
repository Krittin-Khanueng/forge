import SwiftUI

struct ErrorState: View {
    let message: String
    var retryAction: (@MainActor () -> Void)? = nil

    var body: some View {
        VStack(spacing: ForgeTheme.Spacing.m) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let retryAction {
                SecondaryButton(
                    label: "Retry",
                    systemImage: "arrow.clockwise",
                    action: retryAction
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
