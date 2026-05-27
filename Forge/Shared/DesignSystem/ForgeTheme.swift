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
        static let m: CGFloat = 10
        static let l: CGFloat = 14
    }

    enum Font {
        static let mono = SwiftUI.Font.system(.body, design: .monospaced)
        static let stat = SwiftUI.Font.system(size: 32, weight: .semibold, design: .rounded)
    }
}
