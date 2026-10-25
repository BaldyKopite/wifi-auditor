import Foundation
import UserNotifications

/// Handles instant local notification alerts when security threats or captive portals are detected.
public final class NotificationManager {
    public static let shared = NotificationManager()

    private init() {}

    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[NotificationManager] Authorization error: \(error.localizedDescription)")
            }
        }
    }

    public func sendAlert(title: String, body: String, badgeCount: NSNumber? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        if let badge = badgeCount {
            content.badge = badge
        }

        // Deliver practically immediately (0.2s delay to allow iOS scheduler to register)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.2, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[NotificationManager] Error queuing alert: \(error.localizedDescription)")
            }
        }
    }
}
