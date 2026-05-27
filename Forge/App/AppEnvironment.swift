import SwiftUI
import OSLog

@Observable @MainActor
final class AppEnvironment {
    let registry = PackageManagerRegistry.shared
    let searchService = SearchService()
    private let logger = Logger.ui

    var isReady = false
    var isPaletteOpen = false

    var paletteWindow: CommandPaletteWindow?
    var paletteMonitor: Any?

    func bootstrap() async {
        logger.info("Detecting package managers...")
        await registry.detectAll()
        isReady = true
        logger.info("Package manager detection complete. Found: \(self.registry.detectedKinds.map(\.displayName))")
    }

    func togglePalette() {
        if let window = paletteWindow {
            window.close()
            paletteWindow = nil
            isPaletteOpen = false
        } else {
            let view = CommandPaletteView(onDismiss: { [weak self] in
                self?.dismissPalette()
            })
            .environment(self)
            paletteWindow = CommandPaletteWindow.open(hosting: view)
            isPaletteOpen = true
        }
    }

    func dismissPalette() {
        paletteWindow?.close()
        paletteWindow = nil
        isPaletteOpen = false
    }
}
