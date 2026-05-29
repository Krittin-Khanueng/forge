import SwiftUI
import OSLog
import AppKit

@Observable @MainActor
final class AppEnvironment {
    let registry = PackageManagerRegistry.shared
    let searchService = SearchService()
    let packageRefresh = PackageRefreshService.shared

    let dashboardViewModel: DashboardViewModel
    let packagesViewModel: PackagesViewModel
    let updatesViewModel: UpdatesViewModel
    let environmentService = EnvironmentService()

    private let settingsRepo = SettingsRepository(container: StorageStack.shared.container)
    private let logger = Logger.ui

    var isReady = false
    var isPaletteOpen = false
    var appearanceTheme: String

    var paletteWindow: CommandPaletteWindow?
    var paletteMonitor: Any?
    var paletteObserver: NSObjectProtocol? 

    var preferredColorScheme: ColorScheme? {
        switch appearanceTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    init() {
        appearanceTheme = settingsRepo.current().theme
        dashboardViewModel = DashboardViewModel(refreshService: packageRefresh)
        packagesViewModel = PackagesViewModel(refreshService: packageRefresh)
        updatesViewModel = UpdatesViewModel(refreshService: packageRefresh)
    }

    func reloadAppearance() {
        appearanceTheme = settingsRepo.current().theme
    }

    var showMenuBarIcon: Bool {
        settingsRepo.current().showMenuBarIcon
    }

    func bootstrap() async {
        logger.info("Detecting package managers...")
        await registry.detectAll()
        packageRefresh.applyCachedPackages()
        await SystemNotifier.shared.requestAuthorizationIfNeeded()
        isReady = true
        logger.info("Package manager detection complete. Found: \(self.registry.detectedKinds.map(\.displayName))")
    }

    func togglePalette() {
        if let window = paletteWindow {
            window.close()
            dismissPalette()
        } else {
            let view = CommandPaletteView(onDismiss: { [weak self] in
                self?.dismissPalette()
            })
            .environment(self)
            paletteWindow = CommandPaletteWindow.open(hosting: view)
            isPaletteOpen = true

            paletteObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: paletteWindow,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.dismissPalette()
                }
            }
        }
    }

    func dismissPalette() {
        if let observer = paletteObserver {
            NotificationCenter.default.removeObserver(observer)
            paletteObserver = nil
        }
        paletteWindow?.close()
        paletteWindow = nil
        isPaletteOpen = false
    }
}
