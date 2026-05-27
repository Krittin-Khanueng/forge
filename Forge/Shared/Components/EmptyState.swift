import SwiftUI

struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionLabel: String? = nil
    var action: (@MainActor () -> Void)? = nil

    var body: some View {
        VStack(spacing: ForgeTheme.Spacing.l) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(ForgeTheme.Palette.forgeTeal)
                .frame(width: 60, height: 60)
                .background(ForgeTheme.Palette.forgeTeal.opacity(0.12), in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))

            Text(title)
                .font(ForgeTheme.Font.compactTitle)

            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            if let actionLabel, let action {
                SecondaryButton(label: actionLabel, action: action)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(ForgeTheme.Spacing.xxl)
    }
}
