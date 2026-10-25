import SwiftUI

public struct DashboardView: View {
    @ObservedObject var networkObserver = NetworkObserver.shared
    @ObservedObject var trustedStore = TrustedNetworkStore.shared
    @State private var showingSettings = false
    @State private var showingPortalDetails = false

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Network Identity
                    VStack(spacing: 6) {
                        Text(networkObserver.currentSSID)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        HStack(spacing: 8) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)
                            Text(statusSubtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if let bssid = networkObserver.currentBSSID {
                                Text("• \(bssid)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 6)

                    // Hero Shield Indicator
                    ZStack {
                        Circle()
                            .fill(statusColor.opacity(0.12))
                            .frame(width: 160, height: 160)

                        Circle()
                            .stroke(statusColor.opacity(0.3), lineWidth: 3)
                            .frame(width: 140, height: 140)

                        if networkObserver.isAuditing {
                            ProgressView()
                                .scaleEffect(1.6)
                                .tint(statusColor)
                        } else {
                            Image(systemName: shieldIconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .foregroundColor(statusColor)
                        }
                    }

                    // Primary Headline & Confidence Pill
                    VStack(spacing: 8) {
                        Text(statusHeadline)
                            .font(.title3.bold())
                            .foregroundColor(.primary)

                        if let result = networkObserver.currentResult {
                            HStack(spacing: 6) {
                                Text("Confidence:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(result.confidence.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(confidenceColor(result.confidence).opacity(0.15))
                                    .foregroundColor(confidenceColor(result.confidence))
                                    .cornerRadius(4)
                            }

                            Text(result.confidenceExplanation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                        }
                    }

                    // Disclaimer Notice
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text("Heuristic Assessment: This utility performs automated on-device checks. It provides best-effort risk detection and is not an enterprise guarantee.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding(.horizontal)

                    // Action: Re-Audit Button & Trust Toggle
                    HStack(spacing: 12) {
                        Button(action: {
                            networkObserver.reAuditCurrentNetwork()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(networkObserver.isAuditing ? "Auditing..." : "Re-Scan")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(networkObserver.isAuditing)

                        Button(action: {
                            let current = isCurrentNetworkTrusted
                            trustedStore.setUserTrust(ssid: networkObserver.currentSSID, isTrusted: !current)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: isCurrentNetworkTrusted ? "star.fill" : "star")
                                Text(isCurrentNetworkTrusted ? "Trusted" : "Mark Trust")
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(isCurrentNetworkTrusted ? Color.yellow.opacity(0.2) : Color(.secondarySystemBackground))
                            .foregroundColor(isCurrentNetworkTrusted ? .orange : .primary)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)

                    // Captive Portal Alert Banner (if applicable)
                    if let portalURL = networkObserver.currentResult?.captivePortalURL {
                        Button(action: { showingPortalDetails = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "network")
                                    .font(.title2)
                                    .foregroundColor(.orange)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Captive Portal Detected")
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
                        HStack(spacing: 14) {
                            MetricPill(
                                title: "TLS Canary",
                                value: result.tlsHandshakeLatencyMs > 0 ? String(format: "%.0f ms", result.tlsHandshakeLatencyMs) : "N/A",
                                icon: "lock.fill",
                                color: .green
                            )

                            MetricPill(
                                title: "DNS Integrity",
                                value: result.dnsLatencyMs > 0 ? String(format: "%.0f ms", result.dnsLatencyMs) : "Filtered",
                                icon: "globe",
                                color: .blue
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Threats & Warnings List (if any)
                    if let threats = networkObserver.currentResult?.threats, !threats.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Identified Signals (\(threats.count))")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(threats) { threat in
                                AuditResultCard(threat: threat)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Recent History
                    if !networkObserver.auditHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Observations")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(networkObserver.auditHistory.prefix(3)) { item in
                                HStack {
                                    Image(systemName: item.riskLevel == .nominal ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                        .foregroundColor(item.riskLevel == .nominal ? .green : .orange)
                                    VStack(alignment: .leading) {
                                        Text(item.ssid)
                                            .font(.subheadline.bold())
                                        Text(item.timestamp, style: .time)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(item.summaryHeadline)
                                        .font(.caption2)
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
                .padding(.bottom, 24)
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

    // MARK: - Helpers
    private var isCurrentNetworkTrusted: Bool {
        trustedStore.profiles[networkObserver.currentSSID]?.isUserTrusted ?? false
    }

    private var statusColor: Color {
        if networkObserver.isAuditing { return .blue }
        guard let result = networkObserver.currentResult else { return .secondary }
        switch result.riskLevel {
        case .nominal: return .green
        case .moderate: return .yellow
        case .elevated: return .orange
        case .critical: return .red
        }
    }

    private var shieldIconName: String {
        guard let result = networkObserver.currentResult else { return "shield" }
        switch result.riskLevel {
        case .nominal: return "checkmark.shield.fill"
        case .moderate: return "shield.lefthalf.filled"
        case .elevated: return "exclamationmark.shield.fill"
        case .critical: return "xmark.shield.fill"
        }
    }

    private var statusHeadline: String {
        if networkObserver.isAuditing { return "Evaluating Signals..." }
        guard let result = networkObserver.currentResult else { return "Ready to Assess" }
        return result.summaryHeadline
    }

    private var statusSubtitle: String {
        if networkObserver.isAuditing { return "Probing TLS canary and DNS mapping" }
        if networkObserver.currentSSID == "Disconnected" { return "Interface offline" }
        return "Connected interface"
    }

    private func confidenceColor(_ conf: AssessmentConfidence) -> Color {
        switch conf {
        case .high: return .green
        case .medium: return .yellow
        case .low: return .orange
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
