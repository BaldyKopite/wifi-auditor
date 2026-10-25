import ActivityKit
import Foundation

/// Shared ActivityAttributes for ActivityKit (Dynamic Island & Lock Screen Live Activity)
public struct WiFiSafetyAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var ssid: String
        public var statusMessage: String
        public var isSecure: Bool
        public var threatLevel: ThreatLevel
        public var timestamp: Date

        public init(ssid: String, statusMessage: String, isSecure: Bool, threatLevel: ThreatLevel = .low, timestamp: Date = Date()) {
            self.ssid = ssid
            self.statusMessage = statusMessage
            self.isSecure = isSecure
            self.threatLevel = threatLevel
            self.timestamp = timestamp
        }
    }

    public enum ThreatLevel: String, Codable, Hashable {
        case low = "LOW"
        case medium = "MEDIUM"
        case high = "HIGH"
        case critical = "CRITICAL"
    }

    public init() {}
}
