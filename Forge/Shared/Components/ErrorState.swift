import SwiftUI

struct ErrorState: View {
    let message: String
    var retryAction: (@MainActor () -> Void)? = nil

    var body: some View {
        VStack(spacing: ForgeTheme.Spacing.l) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(ForgeTheme.Palette.forgeOrange)
                .frame(width: 56, height: 56)
                .background(ForgeTheme.Palette.forgeOrange.opacity(0.12), in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))

            Text("Something went wrong")
                .font(ForgeTheme.Font.compactTitle)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            if let retryAction {
                SecondaryButton(
                    label: "Retry",
                    systemImage: "arrow.clockwise",
                    action: retryAction
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(ForgeTheme.Spacing.xxl)
    }
}
