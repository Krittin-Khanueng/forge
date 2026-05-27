import Testing
@testable import Forge

@Suite("App Shell Tests")
struct AppShellTests {
    @Test("SidebarItem enum has all expected cases")
    func sidebarItemCases() {
        #expect(SidebarItem.allCases.count == 8)
        #expect(SidebarItem.dashboard.title == "Dashboard")
        #expect(SidebarItem.packages.title == "Packages")
    }

    @Test("SidebarItem conforms to Identifiable")
    func sidebarItemIdentifiable() {
        #expect(SidebarItem.dashboard.id == "dashboard")
    }

    @Test("AppEnvironment initializes") @MainActor
    func appEnvironmentInit() {
        _ = AppEnvironment()
    }
}
