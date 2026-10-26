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

/// Evaluates network telemetry using an Adversarial vs Benign consensus model,
/// synthesizing competing signals into an explicit risk score (0-100) and confidence rating.
public struct ThreatScoringEngine {
    public struct Evaluation {
        public let riskLevel: RiskLevel
        public let riskScore: Int
        public let confidence: AssessmentConfidence
        public let headline: String
        public let confidenceExplanation: String
        public let threats: [NetworkThreat]
        public let benignEvidence: [String]
        public let adversarialEvidence: [String]
    }

    public static func evaluate(
        captive: CaptiveState,
        tls: TLSProbeState,
        dns: DNSProbeState,
        discrepancy: TrustedNetworkStore.ProfileDiscrepancy,
        isUserTrusted: Bool
    ) -> Evaluation {
        var threats: [NetworkThreat] = []
        var benignEvidence: [String] = []
        var adversarialEvidence: [String] = []
        var computedRisk = 0
        var confidenceSignals = 0

        // 1. Defender / Benign Assessment vs TLS Probe
        switch tls {
        case .valid(let lat):
            confidenceSignals += 1
            benignEvidence.append("TLS 1.3 cryptographic canary handshake succeeded (\(Int(lat))ms).")
        case .intercepted(let reason):
            computedRisk += 50
            adversarialEvidence.append("Active TLS certificate interception: \(reason)")
            threats.append(.tlsInterception(details: reason))
        case .timeoutOrUnreachable:
            computedRisk += 10
            adversarialEvidence.append("Outbound TLS canary was dropped or timed out.")
        }

        // 2. Defender / Benign Assessment vs DNS Integrity
        switch dns {
        case .uncompromised(let ip, let lat):
            confidenceSignals += 1
            benignEvidence.append("DNS-over-HTTPS (DoH) matched authoritative resolver (\(ip), \(Int(lat))ms).")
        case .poisoned(let expected, let actual):
            computedRisk += 45
            adversarialEvidence.append("DNS query poisoned: local resolver returned '\(actual)' instead of '\(expected)'.")
            threats.append(.dnsPoisoning(expectedDoH: expected, localDNS: actual))
        case .dohBlockedOrFiltered:
            computedRisk += 15
            adversarialEvidence.append("Encrypted DoH queries are actively filtered or blocked by local router.")
        case .unreachable:
            computedRisk += 10
            adversarialEvidence.append("DNS resolver was unreachable.")
        }

        // 3. Captive Portal Assessment
        switch captive {
        case .notDetected:
            confidenceSignals += 1
            benignEvidence.append("No captive network interception detected.")
        case .portalDetected(let url, let isEncrypted):
            if !isEncrypted {
                computedRisk += 30
                adversarialEvidence.append("Captive portal login page uses unencrypted plaintext HTTP.")
                threats.append(.unencryptedCaptivePortal(url: url.absoluteString))
            } else {
                computedRisk += 15
                benignEvidence.append("Captive portal enforces HTTPS encryption (\(url.host ?? "gateway")).")
            }
            if let host = url.host, host.contains(".tk") || host.contains(".xyz") {
                computedRisk += 35
                adversarialEvidence.append("Captive portal host '\(host)' uses a high-risk disposable TLD.")
                threats.append(.rogueCaptivePortal(url: url.absoluteString, reason: "Host domain uses a high-risk disposable TLD"))
            }
        case .unreachable:
            break
        }

        // 4. Historical Access Point Discrepancy
        switch discrepancy {
        case .none:
            confidenceSignals += 1
            benignEvidence.append("Access point BSSID and gateway subnet match historical observations.")
        case .newNetworkFirstSeen:
            benignEvidence.append("First time encountering this network profile.")
        case .gatewaySubnetShift(let expected, let actual):
            computedRisk += 20
            adversarialEvidence.append("Gateway subnet shifted from \(expected.joined(separator: ", ")) to \(actual).")
            threats.append(.suspiciousGateway(ip: "Router gateway changed from \(expected.joined(separator: ", ")) to \(actual)"))
        case .bssidMismatch(let expected, let actual):
            computedRisk += 40
            adversarialEvidence.append("BSSID hardware mismatch (expected: \(expected), actual: \(actual)). Potential Evil Twin.")
            threats.append(.possibleEvilTwin(expected: expected.joined(separator: ", "), actual: actual))
        }

        // If user explicitly marked network as trusted (e.g. Home), soften minor heuristics
        if isUserTrusted && computedRisk < 30 {
            computedRisk = 0
            benignEvidence.append("User marked this network as trusted home/office profile.")
        }

        var finalScore = min(100, max(0, computedRisk))
        let hasCriticalThreat = threats.contains(where: { $0.severity == .critical })
        if hasCriticalThreat {
            finalScore = max(finalScore, 85)
        }

        // Confidence calculation
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

        // Risk Level mapping from synthesized score
        let riskLevel: RiskLevel
        let headline: String

        if finalScore >= 75 || hasCriticalThreat {
            riskLevel = .critical
            headline = "Critical Threat Detected"
        } else if finalScore >= 40 {
            riskLevel = .elevated
            headline = "Suspicious Network Activity"
        } else if finalScore >= 15 || caseCaptiveDetected(captive) {
            riskLevel = .moderate
            headline = "Captive Portal / Incomplete Auth"
        } else {
            riskLevel = .nominal
            headline = isUserTrusted ? "Trusted Network (Nominal)" : "No Obvious Anomalies Observed"
        }

        return Evaluation(
            riskLevel: riskLevel,
            riskScore: finalScore,
            confidence: confidence,
            headline: headline,
            confidenceExplanation: explanation,
            threats: threats,
            benignEvidence: benignEvidence,
            adversarialEvidence: adversarialEvidence
        )
    }

    private static func caseCaptiveDetected(_ captive: CaptiveState) -> Bool {
        if case .portalDetected = captive { return true }
        return false
    }
}
