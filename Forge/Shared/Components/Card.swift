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
            .background(.quaternary, in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))
    }
}
