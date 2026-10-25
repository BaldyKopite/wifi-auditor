import Foundation

/// Specific network anomalies and cyber risks detected during an audit
public enum NetworkThreat: Identifiable, Codable, Hashable {
    case rogueCaptivePortal(url: String, reason: String)
    case unencryptedCaptivePortal(url: String)
    case tlsInterception(details: String)
    case dnsPoisoning(expectedDoH: String, localDNS: String)
    case openUnencryptedNetwork
    case suspiciousGateway(ip: String)

    public var id: String {
        switch self {
        case .rogueCaptivePortal(let url, _): return "rogue_\(url)"
        case .unencryptedCaptivePortal(let url): return "http_\(url)"
        case .tlsInterception: return "tls_interception"
        case .dnsPoisoning: return "dns_poisoning"
        case .openUnencryptedNetwork: return "open_unencrypted"
        case .suspiciousGateway(let ip): return "gateway_\(ip)"
        }
    }

    public var title: String {
        switch self {
        case .rogueCaptivePortal: return "Suspicious Captive Portal"
        case .unencryptedCaptivePortal: return "Plaintext HTTP Captive Portal"
        case .tlsInterception: return "Active TLS / SSL Interception"
        case .dnsPoisoning: return "DNS Spoofing / Poisoning"
        case .openUnencryptedNetwork: return "Unencrypted Wi-Fi Network"
        case .suspiciousGateway: return "Suspicious Gateway Address"
        }
    }

    public var severity: WiFiSafetyAttributes.ThreatLevel {
        switch self {
        case .tlsInterception, .dnsPoisoning: return .critical
        case .rogueCaptivePortal: return .high
        case .unencryptedCaptivePortal: return .medium
        case .openUnencryptedNetwork: return .medium
        case .suspiciousGateway: return .low
        }
    }

    public var description: String {
        switch self {
        case .rogueCaptivePortal(let url, let reason):
            return "The login page redirected to an unrecognized or untrusted domain (\(url)). Reason: \(reason)"
        case .unencryptedCaptivePortal(let url):
            return "The captive portal login page uses unencrypted HTTP (\(url)). Any entered credentials or room numbers can be intercepted."
        case .tlsInterception(let details):
            return "The secure TLS canary handshake failed or a custom proxy root certificate is inspecting your HTTPS traffic. \(details)"
        case .dnsPoisoning(let expected, let local):
            return "The local router's DNS server returned '\(local)', which differs from the verified DNS-over-HTTPS resolution '\(expected)'."
        case .openUnencryptedNetwork:
            return "This network does not use WPA2 or WPA3 encryption. Anyone nearby can observe plaintext broadcast frames."
        case .suspiciousGateway(let ip):
            return "The default gateway (\(ip)) is utilizing a non-standard local routing subnet."
        }
    }
}

/// The aggregated result of a Wi-Fi security audit
public struct SecurityAuditResult: Identifiable, Codable {
    public let id: UUID
    public let ssid: String
    public let timestamp: Date
    public let isSecure: Bool
    public let threats: [NetworkThreat]
    public let captivePortalURL: URL?
    public let tlsHandshakeLatencyMs: Double
    public let dnsLatencyMs: Double

    public init(
        id: UUID = UUID(),
        ssid: String,
        timestamp: Date = Date(),
        isSecure: Bool,
        threats: [NetworkThreat] = [],
        captivePortalURL: URL? = nil,
        tlsHandshakeLatencyMs: Double = 0.0,
        dnsLatencyMs: Double = 0.0
    ) {
        self.id = id
        self.ssid = ssid
        self.timestamp = timestamp
        self.isSecure = isSecure
        self.threats = threats
        self.captivePortalURL = captivePortalURL
        self.tlsHandshakeLatencyMs = tlsHandshakeLatencyMs
        self.dnsLatencyMs = dnsLatencyMs
    }

    public var summaryHeadline: String {
        if isSecure {
            return "Wi-Fi Verified Secure"
        } else if let critical = threats.first(where: { $0.severity == .critical }) {
            return critical.title
        } else if captivePortalURL != nil {
            return "Captive Portal Detected"
        } else {
            return "Security Warnings Detected"
        }
    }
}
