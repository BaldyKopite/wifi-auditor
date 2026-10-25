import ActivityKit
import Foundation

/// Manages ActivityKit Live Activities and Dynamic Island states
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    private var currentActivity: Activity<WiFiSafetyAttributes>?

    private init() {}

    /// Starts a new Live Activity or updates the active one if already present
    public func startOrUpdateActivity(
        ssid: String,
        statusText: String,
        isSecure: Bool,
        threatLevel: WiFiSafetyAttributes.ThreatLevel = .low
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }

        let contentState = WiFiSafetyAttributes.ContentState(
            ssid: ssid,
            statusMessage: statusText,
            isSecure: isSecure,
            threatLevel: threatLevel,
            timestamp: Date()
        )

        if let existing = currentActivity {
            let updatedContent = ActivityContent(state: contentState, staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date()))
            await existing.update(updatedContent)
        } else {
            do {
                let attributes = WiFiSafetyAttributes()
                let initialContent = ActivityContent(state: contentState, staleDate: Calendar.current.date(byAdding: .minute, value: 30, to: Date()))
                currentActivity = try Activity.request(
                    attributes: attributes,
                    content: initialContent,
                    pushType: nil
                )
            } catch {
                print("[LiveActivityManager] Failed to launch Live Activity: \(error.localizedDescription)")
            }
        }
    }

    /// Ends and clears the active Live Activity from the Lock Screen and Dynamic Island
    public func endActivity() async {
        guard let activity = currentActivity else { return }
        let finalContent = ActivityContent(state: activity.content.state, staleDate: nil)
        await activity.end(finalContent, dismissalPolicy: .immediate)
        currentActivity = nil
    }
}
