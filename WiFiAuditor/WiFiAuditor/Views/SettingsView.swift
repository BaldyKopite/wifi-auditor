import SwiftUI

public struct SettingsView: View {
    @AppStorage("doh_provider") private var selectedDoHProvider: String = "Cloudflare"
    @AppStorage("notify_on_secure") private var notifyOnSecure: Bool = true
    @AppStorage("notify_on_threat") private var notifyOnThreat: Bool = true
    @AppStorage("auto_audit_wifi") private var autoAuditWiFi: Bool = true
    @Environment(\.dismiss) private var dismiss

    private let providers = ["Cloudflare (1.1.1.1)", "Quad9 (9.9.9.9)", "Google (8.8.8.8)"]

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Audit Automation")) {
                    Toggle("Auto-Audit on Wi-Fi Connect", isOn: $autoAuditWiFi)
                    Text("Automatically initiates cryptographic TLS and DNS probes whenever an iOS Wi-Fi interface transition is detected.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("DNS-over-HTTPS (DoH) Provider")) {
                    Picker("Verification Resolver", selection: $selectedDoHProvider) {
                        ForEach(providers, id: \.self) { provider in
                            Text(provider).tag(provider)
                        }
                    }
                    Text("Used as the trusted baseline to detect if the local Wi-Fi router is spoofing or intercepting DNS queries.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Instant Alerts & Dynamic Island")) {
                    Toggle("Notify on Verified Safe", isOn: $notifyOnSecure)
                    Toggle("Notify on Threats & Anomalies", isOn: $notifyOnThreat)
                }

                Section(header: Text("About & Security Principles")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0 (Build 1)").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Privacy Architecture")
                        Spacer()
                        Text("100% On-Device").foregroundColor(.green)
                    }
                    Text("This app does not relay your browsing traffic through expensive proxy servers. Probes occur directly between your device and verified public canaries.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Auditor Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
