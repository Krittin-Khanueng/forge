import SwiftUI

struct LoadingState: View {
    let message: String

    init(_ message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: ForgeTheme.Spacing.m) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.callout.weight(.medium))
                .foregroundStyle(ForgeTheme.Palette.inkMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(ForgeTheme.Spacing.xxl)
    }
}
