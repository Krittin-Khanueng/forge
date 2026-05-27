import SwiftUI

struct IconButton: View {
    let systemImage: String
    var tooltip: String? = nil
    var action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.plain)
        .help(tooltip ?? "")
    }
}
