import Foundation
import Network

/// Core Security Auditor responsible for evaluating Wi-Fi legitimacy and captive portal integrity.
public final class WiFiAuditor {
    public static let shared = WiFiAuditor()

    private let probeClient: NetworkProbing
    private let networkStore: TrustedNetworkStore

    public init(
        probeClient: NetworkProbing = URLSessionProbeClient(),
        networkStore: TrustedNetworkStore = .shared
    ) {
        self.probeClient = probeClient
        self.networkStore = networkStore
    }

    /// Performs a full concurrent security audit for the specified Wi-Fi connection
    public func audit(ssid: String, bssid: String? = nil, gatewayIP: String? = nil) async -> SecurityAuditResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        // 1. Evaluate historical access point consistency
        let discrepancy = networkStore.evaluateAccessPoint(ssid: ssid, bssid: bssid, gatewayIP: gatewayIP)
        let isUserTrusted = networkStore.profiles[ssid]?.isUserTrusted ?? false

        // 2. Run probes concurrently
        let defaultDoHURL = URL(string: "https://1.1.1.1/dns-query?name=one.one.one.one&type=A")!

        async let captiveCheck = probeClient.probeCaptivePortal()
        async let tlsCheck = probeClient.probeTLSHandshake()
        async let dnsCheck = probeClient.probeDNSIntegrity(domain: "one.one.one.one", providerURL: defaultDoHURL)

        let (captiveResult, tlsResult, dnsResult) = await (captiveCheck, tlsCheck, dnsCheck)

        // 3. Record network observation in local store
        networkStore.recordNetwork(ssid: ssid, bssid: bssid, gatewayIP: gatewayIP)

        // 4. Score signals via ThreatScoringEngine
        let eval = ThreatScoringEngine.evaluate(
            captive: captiveResult,
            tls: tlsResult,
            dns: dnsResult,
            discrepancy: discrepancy,
            isUserTrusted: isUserTrusted
        )

        var detectedPortalURL: URL? = nil
        if case .portalDetected(let url, _) = captiveResult {
            detectedPortalURL = url
        }

        var tlsLatency = 0.0
        if case .valid(let lat) = tlsResult {
            tlsLatency = lat
        }

        var dnsLatency = 0.0
        if case .uncompromised(_, let lat) = dnsResult {
            dnsLatency = lat
        }

        return SecurityAuditResult(
            ssid: ssid,
            timestamp: Date(),
            isSecure: eval.riskLevel == .nominal,
            riskLevel: eval.riskLevel,
            confidence: eval.confidence,
            confidenceExplanation: eval.confidenceExplanation,
            threats: eval.threats,
            captivePortalURL: detectedPortalURL,
            tlsHandshakeLatencyMs: tlsLatency,
            dnsLatencyMs: dnsLatency
        )
    }
}
