import Foundation
import UserNotifications

@MainActor
final class SystemNotifier {
    static let shared = SystemNotifier()

    private var authorized = false

    private init() {}

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            authorized = granted
        } catch {
            authorized = false
        }
    }

    func notifyOutdatedAvailable(count: Int) async {
        guard authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Updates Available"
        content.body = count == 1
            ? "1 package has a new version available."
            : "\(count) packages have new versions available."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "forge-outdated-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // silently fail — notifications are best-effort
        }
    }
}
