import Foundation

public enum AssessmentConfidence: String, Codable, Hashable {
    case high = "HIGH"
    case medium = "MEDIUM"
    case low = "LOW"
}

public enum RiskLevel: String, Codable, Hashable {
    case nominal = "NOMINAL"
    case moderate = "MODERATE"
    case elevated = "ELEVATED"
    case critical = "CRITICAL"
}

public struct ThreatScoringEngine {
    public struct Evaluation {
        public let riskLevel: RiskLevel
        public let confidence: AssessmentConfidence
        public let headline: String
        public let confidenceExplanation: String
        public let threats: [NetworkThreat]
    }

    public static func evaluate(
        captive: CaptiveState,
        tls: TLSProbeState,
        dns: DNSProbeState,
        discrepancy: TrustedNetworkStore.ProfileDiscrepancy,
        isUserTrusted: Bool
    ) -> Evaluation {
        var threats: [NetworkThreat] = []
        var confidenceSignals = 0
        var totalSignals = 4

        // 1. Process TLS Probe
        switch tls {
        case .valid:
            confidenceSignals += 1
        case .intercepted(let reason):
            threats.append(.tlsInterception(details: reason))
        case .timeoutOrUnreachable:
            // Network dropped or actively suppressing outbound TLS
            break
        }

        // 2. Process DNS Probe
        switch dns {
        case .uncompromised:
            confidenceSignals += 1
        case .poisoned(let expected, let actual):
            threats.append(.dnsPoisoning(expectedDoH: expected, localDNS: actual))
        case .dohBlockedOrFiltered:
            // DoH blocked is typical before authenticating at captive portals
            break
        case .unreachable:
            break
        }

        // 3. Process Captive State
        switch captive {
        case .notDetected:
            confidenceSignals += 1
        case .portalDetected(let url, let isEncrypted):
            if !isEncrypted {
                threats.append(.unencryptedCaptivePortal(url: url.absoluteString))
            }
            if let host = url.host, host.contains(".tk") || host.contains(".xyz") {
                threats.append(.rogueCaptivePortal(url: url.absoluteString, reason: "Host domain uses a high-risk disposable TLD"))
            }
        case .unreachable:
            break
        }

        // 4. Process Historical Discrepancy
        switch discrepancy {
        case .none:
            confidenceSignals += 1
        case .newNetworkFirstSeen:
            // First time seeing this network - confidence is naturally limited
            break
        case .gatewaySubnetShift(let expected, let actual):
            threats.append(.suspiciousGateway(ip: "Router gateway changed from \(expected.joined(separator: ", ")) to \(actual)"))
        case .bssidMismatch(let expected, let actual):
            threats.append(.possibleEvilTwin(expected: expected.joined(separator: ", "), actual: actual))
        }

        // Compute Confidence
        let confidence: AssessmentConfidence
        let explanation: String
        if confidenceSignals >= 3 {
            confidence = .high
            explanation = "Multiple independent probes (TLS canary, DNS integrity, captive detection) confirmed signal consistency."
        } else if confidenceSignals >= 2 {
            confidence = .medium
            explanation = "Some probes were inconclusive or blocked by the local router/portal."
        } else {
            confidence = .low
            explanation = "Network blocked outbound verification probes or is awaiting captive portal authentication."
        }

        // Compute Risk Level
        let hasCritical = threats.contains(where: { $0.severity == .critical })
        let hasHigh = threats.contains(where: { $0.severity == .high })
        let hasMedium = threats.contains(where: { $0.severity == .medium })

        let riskLevel: RiskLevel
        let headline: String

        if hasCritical {
            riskLevel = .critical
            headline = "Critical Threat Detected"
        } else if hasHigh {
            riskLevel = .elevated
            headline = "Suspicious Network Activity"
        } else if hasMedium || caseCaptiveDetected(captive) {
            riskLevel = .moderate
            headline = "Captive Portal / Incomplete Auth"
        } else {
            riskLevel = .nominal
            headline = isUserTrusted ? "Trusted Network (Nominal)" : "No Obvious Anomalies Observed"
        }

        return Evaluation(
            riskLevel: riskLevel,
            confidence: confidence,
            headline: headline,
            confidenceExplanation: explanation,
            threats: threats
        )
    }

    private static func caseCaptiveDetected(_ captive: CaptiveState) -> Bool {
        if case .portalDetected = captive { return true }
        return false
    }
}
