import Foundation

// MARK: - Probe Results

public enum CaptiveState: Equatable, Codable {
    case notDetected
    case portalDetected(url: URL, isEncrypted: Bool)
    case unreachable(String)
}

public enum TLSProbeState: Equatable, Codable {
    case valid(latencyMs: Double)
    case intercepted(reason: String)
    case timeoutOrUnreachable
}

public enum DNSProbeState: Equatable, Codable {
    case uncompromised(resolvedIP: String, latencyMs: Double)
    case poisoned(expected: String, actual: String)
    case dohBlockedOrFiltered
    case unreachable
}

// MARK: - Protocols for Dependency Injection & Testing

public protocol CaptivePortalProbing: Sendable {
    func probeCaptivePortal() async -> CaptiveState
}

public protocol TLSHandshakeProbing: Sendable {
    func probeTLSHandshake() async -> TLSProbeState
}

public protocol DNSIntegrityProbing: Sendable {
    func probeDNSIntegrity(domain: String, providerURL: URL) async -> DNSProbeState
}

public protocol NetworkProbing: CaptivePortalProbing, TLSHandshakeProbing, DNSIntegrityProbing, Sendable {}

// MARK: - Production URLSession Probe Client

public final class URLSessionProbeClient: NetworkProbing, @unchecked Sendable {
    private let ephemeralSession: URLSession
    private let strictTLSSession: URLSession

    public init(
        ephemeralSession: URLSession = {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 4.0
            config.timeoutIntervalForResource = 6.0
            return URLSession(configuration: config)
        }(),
        strictTLSSession: URLSession = {
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForRequest = 5.0
            config.tlsMinimumSupportedProtocolVersion = .TLSv13
            return URLSession(configuration: config)
        }()
    ) {
        self.ephemeralSession = ephemeralSession
        self.strictTLSSession = strictTLSSession
    }

    public func probeCaptivePortal() async -> CaptiveState {
        guard let probeURL = URL(string: "http://captive.apple.com/hotspot-detect.html") else {
            return .unreachable("Malformed captive probe URL")
        }

        do {
            let (data, response) = try await ephemeralSession.data(from: probeURL)
            guard let http = response as? HTTPURLResponse else {
                return .unreachable("Invalid HTTP response")
            }

            if let finalURL = http.url, finalURL.host != "captive.apple.com" {
                let isHTTPS = finalURL.scheme?.lowercased() == "https"
                return .portalDetected(url: finalURL, isEncrypted: isHTTPS)
            }

            if let body = String(data: data, encoding: .utf8), !body.contains("Success") {
                return .portalDetected(url: http.url ?? probeURL, isEncrypted: false)
            }

            return .notDetected
        } catch {
            return .unreachable(error.localizedDescription)
        }
    }

    public func probeTLSHandshake() async -> TLSProbeState {
        let start = CFAbsoluteTimeGetCurrent()
        guard let canaryURL = URL(string: "https://cloudflare.com/cdn-cgi/trace") else {
            return .timeoutOrUnreachable
        }

        do {
            var request = URLRequest(url: canaryURL)
            request.timeoutInterval = 4.0

            let (data, response) = try await strictTLSSession.data(for: request)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .intercepted(reason: "Non-200 HTTP response received from TLS canary")
            }

            if let body = String(data: data, encoding: .utf8), body.contains("fl=") {
                return .valid(latencyMs: elapsed)
            } else {
                return .intercepted(reason: "Canary payload failed integrity signature")
            }
        } catch {
            return .timeoutOrUnreachable
        }
    }

    public func probeDNSIntegrity(domain: String, providerURL: URL) async -> DNSProbeState {
        let start = CFAbsoluteTimeGetCurrent()
        var request = URLRequest(url: providerURL)
        request.setValue("application/dns-json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 4.0

        do {
            let (data, response) = try await strictTLSSession.data(for: request)
            let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000.0

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .dohBlockedOrFiltered
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let answers = json["Answer"] as? [[String: Any]],
                  let first = answers.first,
                  let resolvedIP = first["data"] as? String else {
                return .dohBlockedOrFiltered
            }

            let trustedIPs = ["1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001", "9.9.9.9", "8.8.8.8"]
            if trustedIPs.contains(resolvedIP) || domain != "one.one.one.one" {
                return .uncompromised(resolvedIP: resolvedIP, latencyMs: elapsed)
            } else {
                return .poisoned(expected: "1.1.1.1", actual: resolvedIP)
            }
        } catch {
            return .dohBlockedOrFiltered
        }
    }
}
