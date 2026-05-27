import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    var accentColor: Color = .accentColor
    var systemImage: String? = nil

    var body: some View {
        Card(padding: ForgeTheme.Spacing.m) {
            HStack(alignment: .top, spacing: ForgeTheme.Spacing.m) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 34, height: 34)
                        .background(accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))
                }

                VStack(alignment: .leading, spacing: ForgeTheme.Spacing.xs) {
                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(ForgeTheme.Palette.inkMuted)
                    Text(value)
                        .font(ForgeTheme.Font.metric)
                        .foregroundStyle(accentColor)
                        .contentTransition(.numericText())
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}
