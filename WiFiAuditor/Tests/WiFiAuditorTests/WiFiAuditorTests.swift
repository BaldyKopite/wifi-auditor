import XCTest
@testable import WiFiAuditor

final class WiFiAuditorTests: XCTestCase {

    func testThreatSeverityHierarchy() {
        let criticalThreat = NetworkThreat.tlsInterception(details: "Certificate untrusted")
        let mediumThreat = NetworkThreat.openUnencryptedNetwork
        let lowThreat = NetworkThreat.suspiciousGateway(ip: "10.0.0.1")

        XCTAssertEqual(criticalThreat.severity, .critical)
        XCTAssertEqual(mediumThreat.severity, .medium)
        XCTAssertEqual(lowThreat.severity, .low)
    }

    func testSecurityAuditResultSummaryHeadline() {
        let secureResult = SecurityAuditResult(
            ssid: "Home_WiFi",
            isSecure: true,
            threats: []
        )
        XCTAssertEqual(secureResult.summaryHeadline, "Wi-Fi Verified Secure")

        let captiveResult = SecurityAuditResult(
            ssid: "Hotel_WiFi",
            isSecure: false,
            threats: [],
            captivePortalURL: URL(string: "https://portal.hotel.com/login")
        )
        XCTAssertEqual(captiveResult.summaryHeadline, "Captive Portal Detected")

        let compromisedResult = SecurityAuditResult(
            ssid: "Free_Airport_WiFi",
            isSecure: false,
            threats: [.tlsInterception(details: "Proxy detected")]
        )
        XCTAssertEqual(compromisedResult.summaryHeadline, "Active TLS / SSL Interception")
    }

    func testLiveActivityAttributesSerialization() {
        let state = WiFiSafetyAttributes.ContentState(
            ssid: "Starbucks_Guest",
            statusMessage: "Verified Safe",
            isSecure: true,
            threatLevel: .low
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let data = try encoder.encode(state)
            let decoded = try decoder.decode(WiFiSafetyAttributes.ContentState.self, from: data)
            XCTAssertEqual(decoded.ssid, "Starbucks_Guest")
            XCTAssertEqual(decoded.isSecure, true)
            XCTAssertEqual(decoded.threatLevel, .low)
        } catch {
            XCTFail("Serialization failed: \(error.localizedDescription)")
        }
    }
}
