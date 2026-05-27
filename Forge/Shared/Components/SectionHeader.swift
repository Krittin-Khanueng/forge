import SwiftUI

struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack {
            Text(title)
                .font(ForgeTheme.Font.section)
                .foregroundStyle(.secondary)
            Spacer()
            trailing()
        }
    }
}
