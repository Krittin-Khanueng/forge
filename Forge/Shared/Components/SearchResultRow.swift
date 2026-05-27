import SwiftUI

struct SearchResultRow: View {
    let hit: SearchHit
    var isSelected: Bool = false
    var showsInstallButton: Bool = false
    var onInstall: (@MainActor () -> Void)?

    var body: some View {
        HStack(spacing: ForgeTheme.Spacing.m) {
            Image(systemName: hit.manager.systemImage)
                .frame(width: 24)
                .foregroundStyle(hit.isInstalled ? ForgeTheme.Palette.forgeGreen : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(hit.name)
                        .fontWeight(.medium)
                    if hit.isInstalled, let version = hit.installedVersion {
                        Text(version)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.s))
                    }
                }
                if let description = hit.description {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(hit.manager.displayName)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.s))

            if hit.isInstalled {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(ForgeTheme.Palette.forgeGreen)
            } else if showsInstallButton, let onInstall {
                Button("Install", action: onInstall)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, showsInstallButton ? 0 : ForgeTheme.Spacing.l)
        .padding(.vertical, ForgeTheme.Spacing.s)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
    }
}
