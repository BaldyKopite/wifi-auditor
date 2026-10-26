import Foundation

/// Specific network anomalies and cyber risks detected during an audit
public enum NetworkThreat: Identifiable, Codable, Hashable {
    case rogueCaptivePortal(url: String, reason: String)
    case unencryptedCaptivePortal(url: String)
    case tlsInterception(details: String)
    case dnsPoisoning(expectedDoH: String, localDNS: String)
    case openUnencryptedNetwork
    case suspiciousGateway(ip: String)
    case possibleEvilTwin(expected: String, actual: String)

    public var id: String {
        switch self {
        case .rogueCaptivePortal(let url, _): return "rogue_\(url)"
        case .unencryptedCaptivePortal(let url): return "http_\(url)"
        case .tlsInterception: return "tls_interception"
        case .dnsPoisoning: return "dns_poisoning"
        case .openUnencryptedNetwork: return "open_unencrypted"
        case .suspiciousGateway(let ip): return "gateway_\(ip)"
        case .possibleEvilTwin(let expected, let actual): return "eviltwin_\(expected)_\(actual)"
        }
    }

    public var title: String {
        switch self {
        case .rogueCaptivePortal: return "Suspicious Captive Portal Domain"
        case .unencryptedCaptivePortal: return "Plaintext HTTP Captive Portal"
        case .tlsInterception: return "Active TLS / SSL Interception"
        case .dnsPoisoning: return "DNS Spoofing / Inconsistent Mapping"
        case .openUnencryptedNetwork: return "Unencrypted Wi-Fi Network"
        case .suspiciousGateway: return "Gateway Subnet Altered"
        case .possibleEvilTwin: return "Potential Rogue / Evil Twin Access Point"
        }
    }

    public var severity: WiFiSafetyAttributes.ThreatLevel {
        switch self {
        case .tlsInterception, .dnsPoisoning, .possibleEvilTwin: return .critical
        case .rogueCaptivePortal: return .high
        case .unencryptedCaptivePortal: return .medium
        case .openUnencryptedNetwork: return .medium
        case .suspiciousGateway: return .low
        }
    }

    public var description: String {
        switch self {
        case .rogueCaptivePortal(let url, let reason):
            return "The login page redirected to an unexpected or suspicious domain (\(url)). Reason: \(reason)"
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
        case .possibleEvilTwin(let expected, let actual):
            return "The BSSID or access point hardware identifier for this SSID differs from previous connections (Historical: \(expected), Current: \(actual))."
        }
    }
}

/// The aggregated result of a Wi-Fi security audit with confidence and multi-agent risk scoring
public struct SecurityAuditResult: Identifiable, Codable {
    public let id: UUID
    public let ssid: String
    public let timestamp: Date
    public let isSecure: Bool
    public let riskLevel: RiskLevel
    public let riskScore: Int
    public let confidence: AssessmentConfidence
    public let confidenceExplanation: String
    public let threats: [NetworkThreat]
    public let captivePortalURL: URL?
    public let tlsHandshakeLatencyMs: Double
    public let dnsLatencyMs: Double

    public init(
        id: UUID = UUID(),
        ssid: String,
        timestamp: Date = Date(),
        isSecure: Bool,
        riskLevel: RiskLevel = .nominal,
        riskScore: Int = 0,
        confidence: AssessmentConfidence = .medium,
        confidenceExplanation: String = "",
        threats: [NetworkThreat] = [],
        captivePortalURL: URL? = nil,
        tlsHandshakeLatencyMs: Double = 0.0,
        dnsLatencyMs: Double = 0.0
    ) {
        self.id = id
        self.ssid = ssid
        self.timestamp = timestamp
        self.isSecure = isSecure
        self.riskLevel = riskLevel
        self.riskScore = riskScore
        self.confidence = confidence
        self.confidenceExplanation = confidenceExplanation
        self.threats = threats
        self.captivePortalURL = captivePortalURL
        self.tlsHandshakeLatencyMs = tlsHandshakeLatencyMs
        self.dnsLatencyMs = dnsLatencyMs
    }

    public var summaryHeadline: String {
        switch riskLevel {
        case .nominal:
            return "No Obvious Anomalies Observed"
        case .moderate:
            return captivePortalURL != nil ? "Captive Portal Detected" : "Incomplete Verification"
        case .elevated:
            return "Suspicious Network Signals"
        case .critical:
            return threats.first(where: { $0.severity == .critical })?.title ?? "Critical Security Warning"
        }
    }
}
