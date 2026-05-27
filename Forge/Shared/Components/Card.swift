import SwiftUI

struct Card<Content: View>: View {
    let content: Content
    var padding: CGFloat = ForgeTheme.Spacing.l

    init(padding: CGFloat = ForgeTheme.Spacing.l, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(ForgeTheme.Palette.panelFill, in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))
            .overlay {
                RoundedRectangle(cornerRadius: ForgeTheme.Radius.m)
                    .stroke(ForgeTheme.Palette.hairline, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}
