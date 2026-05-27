import Foundation
import SwiftData

@Model
final class AppSettings {
    var autoRefreshEnabled: Bool = false
    var autoRefreshIntervalMinutes: Int = 30
    var preferredTerminal: String = "Terminal"
    var theme: String = "system"
    var lastRefresh: Date? = nil
    var aiProvider: String = "mock"
    var aiModel: String = "claude-sonnet-4-6"
    var showMenuBarIcon: Bool = true
    var showInDock: Bool = true
    var notifyOnOutdated: Bool = true

    init() {}
}
