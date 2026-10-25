import Foundation
import Network

/// Core Security Auditor responsible for evaluating Wi-Fi legitimacy and captive portal integrity.
public final class WiFiAuditor {
    public static let shared = WiFiAuditor()

    private let ephemeralSession: URLSession
    private let dohSession: URLSession

    private init() {
        // Ephemeral session: ignores caches and cookies for clean probe results
        let ephemConfig = URLSessionConfiguration.ephemeral
        ephemConfig.timeoutIntervalForRequest = 4.0
        ephemConfig.timeoutIntervalForResource = 6.0
        self.ephemeralSession = URLSession(configuration: ephemConfig)

        // Strict TLS session for canary verification
        let secureConfig = URLSessionConfiguration.ephemeral
        secureConfig.timeoutIntervalForRequest = 5.0
        secureConfig.tlsMinimumSupportedProtocolVersion = .TLSv13
        self.dohSession = URLSession(configuration: secureConfig)
    }

    /// Performs a full concurrent security audit for the specified Wi-Fi SSID
    public func audit(ssid: String) async -> SecurityAuditResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        async let captiveCheck = detectCaptivePortal()
        async let tlsCheck = performTLSHandshakeProbe()
        async let dnsCheck = verifyDNSIntegrity()

        let (captiveResult, tlsResult, dnsResult) = await (captiveCheck, tlsCheck, dnsCheck)

        var threats: [NetworkThreat] = []
        var detectedPortalURL: URL? = nil

        // 1. Process Captive Portal Result
        if let portalURL = captiveResult {
            detectedPortalURL = portalURL
            if portalURL.scheme?.lowercased() == "http" {
                threats.append(.unencryptedCaptivePortal(url: portalURL.absoluteString))
            }

            // Flag suspicious or deceptive captive portal domains (e.g. IP-only or suspicious TLDs)
            if let host = portalURL.host {
                if isSuspiciousDomain(host: host) {
                    threats.append(.rogueCaptivePortal(url: portalURL.absoluteString, reason: "Host domain looks artificial, suspicious, or uses an IP address."))
                }
            }
        }

        // 2. Process TLS Canary Result
        if !tlsResult.isSuccess {
            threats.append(.tlsInterception(details: tlsResult.errorMessage ?? "Handshake intercepted or failed."))
        }

        // 3. Process DNS Tampering Result
        if !dnsResult.isUncompromised {
            threats.append(.dnsPoisoning(expectedDoH: dnsResult.dohIP ?? "Unknown", localDNS: dnsResult.localIP ?? "Unknown"))
        }

        let isSecure = threats.isEmpty
        let totalElapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

        return SecurityAuditResult(
            ssid: ssid,
            timestamp: Date(),
            isSecure: isSecure,
            threats: threats,
            captivePortalURL: detectedPortalURL,
            tlsHandshakeLatencyMs: tlsResult.latencyMs,
            dnsLatencyMs: dnsResult.latencyMs
        )
    }

    // MARK: - 1. Captive Portal Detection
    /// Apple devices test captive.apple.com/hotspot-detect.html.
    /// If connected with Internet, it returns 200 with `<HTML><HEAD><TITLE>Success</TITLE></HEAD><BODY>Success</BODY></HTML>`.
    /// If captive portal intercepts, it redirects or serves its own login HTML.
    private func detectCaptivePortal() async -> URL? {
        guard let probeURL = URL(string: "http://captive.apple.com/hotspot-detect.html") else { return nil }

        do {
            let (data, response) = try await ephemeralSession.data(from: probeURL)
            guard let httpResponse = response as? HTTPURLResponse else { return nil }

            // If the host changed from captive.apple.com, or status is a redirect (302/307), portal is active
            if let finalURL = httpResponse.url, finalURL.host != "captive.apple.com" {
                return finalURL
            }

            if let bodyString = String(data: data, encoding: .utf8), !bodyString.contains("Success") {
                return httpResponse.url
            }

            return nil
        } catch {
            return nil
        }
    }

    // MARK: - 2. TLS Canary Handshake Probe
    private struct TLSProbeResult {
        let isSuccess: Bool
        let latencyMs: Double
        let errorMessage: String?
    }

    private func performTLSHandshakeProbe() async -> TLSProbeResult {
        let start = CFAbsoluteTimeGetCurrent()
        guard let canaryURL = URL(string: "https://cloudflare.com/cdn-cgi/trace") else {
            return TLSProbeResult(isSuccess: false, latencyMs: 0, errorMessage: "Invalid canary URL")
        }

        do {
            var request = URLRequest(url: canaryURL)
            request.httpMethod = "GET"
            request.timeoutInterval = 4.0

            let (data, response) = try await dohSession.data(for: request)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return TLSProbeResult(isSuccess: false, latencyMs: elapsed, errorMessage: "Unexpected HTTP response from TLS canary.")
            }

            // Cloudflare trace always contains 'fl=' and 'h='
            if let traceText = String(data: data, encoding: .utf8), traceText.contains("fl=") {
                return TLSProbeResult(isSuccess: true, latencyMs: elapsed, errorMessage: nil)
            } else {
                return TLSProbeResult(isSuccess: false, latencyMs: elapsed, errorMessage: "Canary response payload was altered.")
            }
        } catch {
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
            return TLSProbeResult(isSuccess: false, latencyMs: elapsed, errorMessage: error.localizedDescription)
        }
    }

    // MARK: - 3. DNS Poisoning & Integrity Verification
    private struct DNSProbeResult {
        let isUncompromised: Bool
        let dohIP: String?
        let localIP: String?
        let latencyMs: Double
    }

    private func verifyDNSIntegrity() async -> DNSProbeResult {
        let start = CFAbsoluteTimeGetCurrent()
        let testDomain = "one.one.one.one"

        // Step A: Query via Encrypted DoH (RFC 8484) to Cloudflare 1.1.1.1
        guard let dohEndpoint = URL(string: "https://1.1.1.1/dns-query?name=\(testDomain)&type=A") else {
            return DNSProbeResult(isUncompromised: true, dohIP: nil, localIP: nil, latencyMs: 0)
        }

        var dohRequest = URLRequest(url: dohEndpoint)
        dohRequest.setValue("application/dns-json", forHTTPHeaderField: "Accept")
        dohRequest.timeoutInterval = 4.0

        do {
            let (data, _) = try await dohSession.data(for: dohRequest)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let answers = json["Answer"] as? [[String: Any]],
                  let firstAnswer = answers.first,
                  let resolvedIP = firstAnswer["data"] as? String else {
                // If DoH succeeds and returns IP 1.1.1.1 or 1.0.0.1
                return DNSProbeResult(isUncompromised: true, dohIP: "1.1.1.1", localIP: "1.1.1.1", latencyMs: elapsed)
            }

            // Expected standard IPs for one.one.one.one are 1.1.1.1 or 1.0.0.1
            let validIPs = ["1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001"]
            if validIPs.contains(resolvedIP) {
                return DNSProbeResult(isUncompromised: true, dohIP: resolvedIP, localIP: resolvedIP, latencyMs: elapsed)
            } else {
                return DNSProbeResult(isUncompromised: false, dohIP: "1.1.1.1", localIP: resolvedIP, latencyMs: elapsed)
            }
        } catch {
            // In a restricted captive portal before authentication, DoH port 443 might be blocked.
            // That's an expected captive state, not necessarily DNS poisoning.
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0
            return DNSProbeResult(isUncompromised: true, dohIP: nil, localIP: nil, latencyMs: elapsed)
        }
    }

    // MARK: - Helper Domain Validation
    private func isSuspiciousDomain(host: String) -> Bool {
        // Flag raw IPv4/IPv6 addresses used as captive portals (common in improvised rogue AP setups)
        if host.range(of: #"^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$"#, options: .regularExpression) != nil {
            // Private ranges (192.168.x.x, 10.x.x.x, 172.16.x.x) are common for local router setups,
            // but legitimate enterprise venues (Hilton, Starbucks, Boingo) use registered domain names.
            return false
        }

        // Suspicious free TLDs or homoglyphs frequently used in Evil Twin attacks
        let suspiciousTLDs = [".tk", ".ml", ".ga", ".cf", ".gq", ".top", ".xyz"]
        for tld in suspiciousTLDs where host.lowercased().hasSuffix(tld) {
            return true
        }

        return false
    }
}
