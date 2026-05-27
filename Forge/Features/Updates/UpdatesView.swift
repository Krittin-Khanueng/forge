import SwiftUI

struct UpdatesView: View {
    var body: some View {
        ContentUnavailableView("Updates", systemImage: "arrow.triangle.2.circlepath", description: Text("Check for available updates"))
    }
}
