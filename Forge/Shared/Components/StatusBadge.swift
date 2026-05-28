import SwiftUI

struct StatusBadge: View {
    let status: PackageStatus

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(foregroundColor)
                .frame(width: 5, height: 5)
            Text(status.label)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor, in: Capsule())
        .foregroundStyle(foregroundColor)
        .accessibilityLabel(status.label)
    }

    private var backgroundColor: Color {
        switch status {
        case .upToDate:     return ForgeTheme.Palette.forgeGreen.opacity(0.14)
        case .outdated:     return ForgeTheme.Palette.forgeOrange.opacity(0.16)
        case .notInstalled:  return ForgeTheme.Palette.forgeBlue.opacity(0.12)
        case .unknown:      return .secondary.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .upToDate:     return ForgeTheme.Palette.forgeGreen
        case .outdated:     return ForgeTheme.Palette.forgeOrange
        case .notInstalled:  return ForgeTheme.Palette.forgeBlue
        case .unknown:      return .secondary
        }
    }
}
