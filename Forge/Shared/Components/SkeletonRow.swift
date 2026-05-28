import SwiftUI

struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: ForgeTheme.Spacing.m) {
            RoundedRectangle(cornerRadius: ForgeTheme.Radius.s)
                .fill(.quaternary)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(width: 140, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary.opacity(0.6))
                    .frame(width: 90, height: 10)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(.quaternary)
                .frame(width: 60, height: 10)
        }
        .padding(.vertical, ForgeTheme.Spacing.s)
        .shimmer()
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.Spacing.m) {
            HStack(spacing: ForgeTheme.Spacing.m) {
                RoundedRectangle(cornerRadius: ForgeTheme.Radius.s)
                    .fill(.quaternary)
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary)
                        .frame(width: 100, height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.quaternary.opacity(0.6))
                        .frame(width: 70, height: 10)
                }
                Spacer()
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(.quaternary.opacity(0.5))
                .frame(height: 8)
        }
        .padding(ForgeTheme.Spacing.l)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(ForgeTheme.Palette.panelFill, in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.l))
        .overlay {
            RoundedRectangle(cornerRadius: ForgeTheme.Radius.l)
                .stroke(ForgeTheme.Palette.hairline, lineWidth: 1)
        }
        .shimmer()
    }
}

struct SkeletonDashboard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: ForgeTheme.Spacing.xl) {
            SkeletonCard()

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: ForgeTheme.Spacing.l)], spacing: ForgeTheme.Spacing.l) {
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonCard()
                }
            }

            VStack(alignment: .leading, spacing: ForgeTheme.Spacing.m) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonRow()
                }
            }
            .padding(ForgeTheme.Spacing.l)
            .background(ForgeTheme.Palette.panelFill, in: RoundedRectangle(cornerRadius: ForgeTheme.Radius.l))
        }
        .padding(ForgeTheme.Spacing.xxl)
    }
}

struct SkeletonTable: View {
    var rowCount: Int = 8

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { index in
                SkeletonRow()
                    .padding(.horizontal, ForgeTheme.Spacing.l)
                if index < rowCount - 1 {
                    Divider()
                }
            }
        }
        .shimmer()
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: max(0, phase - 0.3)),
                            .init(color: .white.opacity(0.12), location: phase),
                            .init(color: .clear, location: min(1, phase + 0.3)),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.plusLighter)
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            phase = 2
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: ForgeTheme.Radius.m))
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
