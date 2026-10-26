import XCTest
@testable import WiFiAuditor

// MARK: - Mock Network Probe Client for Deterministic Unit Testing

final class MockNetworkProbeClient: NetworkProbing, @unchecked Sendable {
    var captiveStateToReturn: CaptiveState = .notDetected
    var tlsStateToReturn: TLSProbeState = .valid(latencyMs: 45.0)
    var dnsStateToReturn: DNSProbeState = .uncompromised(resolvedIP: "1.1.1.1", latencyMs: 25.0)

    func probeCaptivePortal() async -> CaptiveState {
        return captiveStateToReturn
    }

    func probeTLSHandshake() async -> TLSProbeState {
        return tlsStateToReturn
    }

    func probeDNSIntegrity(domain: String, providerURL: URL) async -> DNSProbeState {
        return dnsStateToReturn
    }
}

// MARK: - Unit Test Suite

final class WiFiAuditorTests: XCTestCase {

    var mockProbe: MockNetworkProbeClient!
    var mockStore: TrustedNetworkStore!
    var auditor: WiFiAuditor!

    override func setUp() {
        super.setUp()
        mockProbe = MockNetworkProbeClient()
        let testDefaults = UserDefaults(suiteName: "WiFiAuditorUnitTestSuite_\(UUID().uuidString)")!
        mockStore = TrustedNetworkStore(defaults: testDefaults)
        auditor = WiFiAuditor(probeClient: mockProbe, networkStore: mockStore)
    }

    func testCleanNetworkEvaluationProducesNominalRisk() async {
        mockProbe.captiveStateToReturn = .notDetected
        mockProbe.tlsStateToReturn = .valid(latencyMs: 50.0)
        mockProbe.dnsStateToReturn = .uncompromised(resolvedIP: "1.1.1.1", latencyMs: 30.0)

        let result = await auditor.audit(ssid: "Home_Secure_WiFi", bssid: "AA:BB:CC:DD:EE:01", gatewayIP: "192.168.1.1")

        XCTAssertTrue(result.isSecure)
        XCTAssertEqual(result.riskLevel, .nominal)
        XCTAssertTrue(result.threats.isEmpty)
        XCTAssertEqual(result.summaryHeadline, "No Obvious Anomalies Observed")
    }

    func testTLSInterceptionTriggersCriticalRisk() async {
        mockProbe.tlsStateToReturn = .intercepted(reason: "Self-signed proxy certificate detected in chain")

        let result = await auditor.audit(ssid: "Suspicious_Cafe_WiFi")

        XCTAssertFalse(result.isSecure)
        XCTAssertEqual(result.riskLevel, .critical)
        XCTAssertTrue(result.threats.contains(where: {
            if case .tlsInterception = $0 { return true }
            return false
        }))
    }

    func testDNSPoisoningTriggersCriticalRisk() async {
        mockProbe.dnsStateToReturn = .poisoned(expected: "1.1.1.1", actual: "198.51.100.99")

        let result = await auditor.audit(ssid: "Airport_WiFi")

        XCTAssertFalse(result.isSecure)
        XCTAssertEqual(result.riskLevel, .critical)
        XCTAssertTrue(result.threats.contains(where: {
            if case .dnsPoisoning = $0 { return true }
            return false
        }))
    }

    func testUnencryptedCaptivePortalTriggersModerateRisk() async {
        let portalURL = URL(string: "http://login.hotel.local/portal")!
        mockProbe.captiveStateToReturn = .portalDetected(url: portalURL, isEncrypted: false)

        let result = await auditor.audit(ssid: "Hotel_Guest")

        XCTAssertFalse(result.isSecure)
        XCTAssertEqual(result.riskLevel, .moderate)
        XCTAssertEqual(result.captivePortalURL, portalURL)
        XCTAssertTrue(result.threats.contains(where: {
            if case .unencryptedCaptivePortal = $0 { return true }
            return false
        }))
    }

    func testBlockedDoHDegradesConfidenceToLow() async {
        mockProbe.captiveStateToReturn = .unreachable("Blocked")
        mockProbe.tlsStateToReturn = .timeoutOrUnreachable
        mockProbe.dnsStateToReturn = .dohBlockedOrFiltered

        let result = await auditor.audit(ssid: "Restricted_Hotspot")

        XCTAssertEqual(result.confidence, .low)
        XCTAssertTrue(result.confidenceExplanation.contains("blocked outbound verification"))
    }

    func testBSSIDMismatchTriggersEvilTwinWarning() async {
        // First connection records initial BSSID
        _ = await auditor.audit(ssid: "Corporate_HQ", bssid: "AA:11:22:33:44:55", gatewayIP: "10.0.0.1")

        // Second connection on same SSID has a different rogue BSSID
        let result2 = await auditor.audit(ssid: "Corporate_HQ", bssid: "BB:99:88:77:66:55", gatewayIP: "10.0.0.1")

        XCTAssertFalse(result2.isSecure)
        XCTAssertTrue(result2.threats.contains(where: {
            if case .possibleEvilTwin = $0 { return true }
            return false
        }))
    }

    func testThreatSeverityHierarchy() {
        let critical = NetworkThreat.tlsInterception(details: "Proxy")
        let medium = NetworkThreat.openUnencryptedNetwork
        let low = NetworkThreat.suspiciousGateway(ip: "10.0.0.1")

        XCTAssertEqual(critical.severity, .critical)
        XCTAssertEqual(medium.severity, .medium)
        XCTAssertEqual(low.severity, .low)
    }

    func testConsensusRiskScoreSynthesis() async {
        mockProbe.captiveStateToReturn = .notDetected
        mockProbe.tlsStateToReturn = .valid(latencyMs: 35.0)
        mockProbe.dnsStateToReturn = .uncompromised(resolvedIP: "1.1.1.1", latencyMs: 20.0)

        let cleanResult = await auditor.audit(ssid: "CleanWiFi")
        XCTAssertEqual(cleanResult.riskScore, 0)
        XCTAssertEqual(cleanResult.riskLevel, .nominal)

        mockProbe.tlsStateToReturn = .intercepted(reason: "MITM Proxy")
        let compromisedResult = await auditor.audit(ssid: "RogueWiFi")
        XCTAssertGreaterThanOrEqual(compromisedResult.riskScore, 75)
        XCTAssertEqual(compromisedResult.riskLevel, .critical)
    }
}
