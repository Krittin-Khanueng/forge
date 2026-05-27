import SwiftUI

enum ForgeTheme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let s: CGFloat = 6
        static let m: CGFloat = 8
        static let l: CGFloat = 8
    }

    enum Font {
        static let mono = SwiftUI.Font.system(.body, design: .monospaced)
        static let stat = SwiftUI.Font.system(size: 32, weight: .semibold, design: .rounded)
        static let metric = SwiftUI.Font.system(size: 30, weight: .bold, design: .rounded)
        static let compactTitle = SwiftUI.Font.system(.title3, design: .rounded).weight(.semibold)
        static let section = SwiftUI.Font.system(.subheadline, design: .rounded).weight(.semibold)
    }

    enum Palette {
        static let appBackground = Color(nsColor: .windowBackgroundColor)
        static let panelFill = Color(nsColor: .controlBackgroundColor)
        static let panelElevated = Color(nsColor: .textBackgroundColor)
        static let hairline = Color.primary.opacity(0.08)
        static let inkMuted = Color.secondary.opacity(0.72)
        static let forgeOrange = Color(red: 0.92, green: 0.38, blue: 0.16)
        static let forgeTeal = Color(red: 0.07, green: 0.52, blue: 0.49)
        static let forgeGreen = Color(red: 0.16, green: 0.58, blue: 0.28)
        static let forgeGold = Color(red: 0.82, green: 0.55, blue: 0.12)
        static let forgeBlue = Color(red: 0.18, green: 0.42, blue: 0.78)
    }

    static func managerColor(_ kind: PackageManagerKind) -> Color {
        switch kind {
        case .brew:  return Palette.forgeOrange
        case .npm:   return Color(red: 0.78, green: 0.13, blue: 0.18)
        case .pnpm:  return Palette.forgeGold
        case .yarn:  return Palette.forgeBlue
        case .bun:   return Color(red: 0.62, green: 0.36, blue: 0.19)
        case .uv:    return Palette.forgeTeal
        case .cargo: return Color(red: 0.50, green: 0.31, blue: 0.23)
        }
    }

    static func panelStroke(isActive: Bool = false) -> some ShapeStyle {
        isActive ? Palette.forgeOrange.opacity(0.28) : Palette.hairline
    }
}
