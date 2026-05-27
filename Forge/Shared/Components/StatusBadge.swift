import SwiftUI

struct StatusBadge: View {
    let status: PackageStatus

    var body: some View {
        Text(status.label)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .upToDate: return .green.opacity(0.15)
        case .outdated: return .orange.opacity(0.15)
        case .unknown:  return .secondary.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .upToDate: return .green
        case .outdated: return .orange
        case .unknown:  return .secondary
        }
    }
}
