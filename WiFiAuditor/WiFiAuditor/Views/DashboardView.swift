import SwiftUI

public struct DashboardView: View {
    @ObservedObject var networkObserver = NetworkObserver.shared
    @State private var showingSettings = false
    @State private var showingPortalDetails = false

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Network Identity
                    VStack(spacing: 4) {
                        Text(networkObserver.currentSSID)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            Text(statusSubtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 10)

                    // Hero Shield Indicator
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.12))
                            .frame(width: 170, height: 170)

                        Circle()
                            .stroke(statusColor.opacity(0.3), lineWidth: 3)
                            .frame(width: 150, height: 150)

                        if networkObserver.isAuditing {
                            ProgressView()
                                .scaleEffect(1.8)
                                .tint(statusColor)
                        } else {
                            Image(systemName: shieldIconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .foregroundColor(statusColor)
                        }
                    }
                    .padding(.vertical, 8)

                    // Primary Headline
                    VStack(spacing: 6) {
                        Text(statusHeadline)
                            .font(.title3.bold())
                            .foregroundColor(.primary)

                        Text(statusDescription)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Action: Re-Audit Button
                    Button(action: {
                        networkObserver.reAuditCurrentNetwork()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .rotationEffect(.degrees(networkObserver.isAuditing ? 360 : 0))
                                .animation(networkObserver.isAuditing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: networkObserver.isAuditing)
                            Text(networkObserver.isAuditing ? "Auditing Network..." : "Re-Scan Network")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(networkObserver.isAuditing)
                    .padding(.horizontal)

                    // Captive Portal Alert Banner (if applicable)
                    if let portalURL = networkObserver.currentResult?.captivePortalURL {
                        Button(action: { showingPortalDetails = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "network")
                                    .font(.title2)
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Captive Portal Active")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.primary)
                                    Text("Hosted at \(portalURL.host ?? "local router")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(14)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }

                    // Telemetry Probe Metrics
                    if let result = networkObserver.currentResult {
                        HStack(spacing: 16) {
                            MetricPill(
                                title: "TLS Handshake",
                                value: String(format: "%.0f ms", result.tlsHandshakeLatencyMs),
                                icon: "lock.fill",
                                color: .green
                            )

                            MetricPill(
                                title: "DNS Integrity",
                                value: String(format: "%.0f ms", result.dnsLatencyMs),
                                icon: "globe",
                                color: .blue
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Threats & Warnings List (if any)
                    if let threats = networkObserver.currentResult?.threats, !threats.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Detected Threats (\(threats.count))")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(threats) { threat in
                                AuditResultCard(threat: threat)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Recent Audit History
                    if !networkObserver.auditHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Network Audits")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(networkObserver.auditHistory.prefix(4)) { item in
                                HStack {
                                    Image(systemName: item.isSecure ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .foregroundColor(item.isSecure ? .green : .red)
                                    VStack(alignment: .leading) {
                                        Text(item.ssid)
                                            .font(.subheadline.bold())
                                        Text(item.timestamp, style: .time)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(item.summaryHeadline)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Wi-Fi Auditor")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingPortalDetails) {
                CaptivePortalDetailView(
                    portalURL: networkObserver.currentResult?.captivePortalURL,
                    ssid: networkObserver.currentSSID
                )
            }
        }
    }

    // MARK: - Status Visual Helpers
    private var statusColor: Color {
        if networkObserver.isAuditing { return .blue }
        guard let result = networkObserver.currentResult else { return .secondary }
        if result.isSecure { return .green }
        if result.captivePortalURL != nil && result.threats.isEmpty { return .orange }
        return .red
    }

    private var shieldIconName: String {
        guard let result = networkObserver.currentResult else { return "shield" }
        if result.isSecure { return "checkmark.shield.fill" }
        if result.captivePortalURL != nil && result.threats.isEmpty { return "shield.lefthalf.filled" }
        return "exclamationmark.shield.fill"
    }

    private var statusHeadline: String {
        if networkObserver.isAuditing { return "Auditing Connection..." }
        guard let result = networkObserver.currentResult else { return "Ready to Scan" }
        return result.summaryHeadline
    }

    private var statusSubtitle: String {
        if networkObserver.isAuditing { return "Running cryptographic probes" }
        if networkObserver.currentSSID == "Disconnected" { return "No Wi-Fi interface connected" }
        return "Active interface"
    }

    private var statusDescription: String {
        if networkObserver.isAuditing {
            return "Sending TLS 1.3 canaries and querying DNS-over-HTTPS resolvers."
        }
        guard let result = networkObserver.currentResult else {
            return "Connect to a Wi-Fi network to automatically verify its safety."
        }
        if result.isSecure {
            return "No rogue access point, captive portal interception, or DNS spoofing was detected."
        } else {
            return "Review the flagged items above before entering any credentials or sensitive data."
        }
    }
}

private struct MetricPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.footnote.bold())
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
