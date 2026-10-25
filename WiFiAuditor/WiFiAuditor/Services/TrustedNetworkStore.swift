import Foundation

public struct NetworkProfile: Codable, Identifiable {
    public var id: String { ssid }
    public let ssid: String
    public var bssids: Set<String>
    public var gatewayIPs: Set<String>
    public var firstSeen: Date
    public var lastSeen: Date
    public var isUserTrusted: Bool
    public var auditCount: Int

    public init(
        ssid: String,
        bssid: String? = nil,
        gatewayIP: String? = nil,
        firstSeen: Date = Date(),
        lastSeen: Date = Date(),
        isUserTrusted: Bool = false,
        auditCount: Int = 1
    ) {
        self.ssid = ssid
        self.bssids = bssid != nil ? [bssid!] : []
        self.gatewayIPs = gatewayIP != nil ? [gatewayIP!] : []
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
        self.isUserTrusted = isUserTrusted
        self.auditCount = auditCount
    }
}

public final class TrustedNetworkStore: ObservableObject {
    public static let shared = TrustedNetworkStore()

    private let storageKey = "com.wifiauditor.known_networks"
    @Published public private(set) var profiles: [String: NetworkProfile] = [:]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadProfiles()
    }

    private let defaults: UserDefaults

    public enum ProfileDiscrepancy: Equatable {
        case none
        case newNetworkFirstSeen
        case gatewaySubnetShift(expected: [String], actual: String)
        case bssidMismatch(expected: [String], actual: String)
    }

    /// Evaluates if the connecting access point matches historical fingerprints
    public func evaluateAccessPoint(ssid: String, bssid: String?, gatewayIP: String?) -> ProfileDiscrepancy {
        guard let existing = profiles[ssid] else {
            return .newNetworkFirstSeen
        }

        if let gw = gatewayIP, !existing.gatewayIPs.isEmpty && !existing.gatewayIPs.contains(gw) {
            return .gatewaySubnetShift(expected: Array(existing.gatewayIPs), actual: gw)
        }

        if let bssid = bssid, !existing.bssids.isEmpty && !existing.bssids.contains(bssid) {
            return .bssidMismatch(expected: Array(existing.bssids), actual: bssid)
        }

        return .none
    }

    /// Records or updates the access point observation
    public func recordNetwork(ssid: String, bssid: String?, gatewayIP: String?) {
        var profile = profiles[ssid] ?? NetworkProfile(ssid: ssid, bssid: bssid, gatewayIP: gatewayIP)
        profile.lastSeen = Date()
        profile.auditCount += 1
        if let b = bssid { profile.bssids.insert(b) }
        if let g = gatewayIP { profile.gatewayIPs.insert(g) }

        profiles[ssid] = profile
        persist()
    }

    public func setUserTrust(ssid: String, isTrusted: Bool) {
        if var profile = profiles[ssid] {
            profile.isUserTrusted = isTrusted
            profiles[ssid] = profile
            persist()
        }
    }

    private func loadProfiles() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: NetworkProfile].self, from: data) else {
            return
        }
        self.profiles = decoded
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(profiles) {
            defaults.set(data, forKey: storageKey)
        }
    }
}
