import SwiftUI

public struct CaptivePortalDetailView: View {
    public let portalURL: URL?
    public let ssid: String
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Portal Connection Details")) {
                    HStack {
                        Text("Connected SSID")
                        Spacer()
                        Text(ssid).foregroundColor(.secondary)
                    }

                    if let url = portalURL {
                        HStack {
                            Text("Protocol")
                            Spacer()
                            Text(url.scheme?.uppercased() ?? "UNKNOWN")
                                .bold()
                                .foregroundColor(url.scheme?.lowercased() == "https" ? .green : .red)
                        }

                        HStack {
                            Text("Host Domain")
                            Spacer()
                            Text(url.host ?? "N/A")
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target URL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(url.absoluteString)
                                .font(.footnote)
                                .foregroundColor(.blue)
                        }
                    } else {
                        Text("No active captive portal detected.")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Security Recommendations")) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("Never reuse critical passwords")
                                .font(.subheadline.bold())
                            Text("Captive portals are managed by local venue operators. Avoid using passwords you use for email, banking, or Apple ID.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "key.fill")
                            .foregroundColor(.orange)
                    }

                    Label {
                        VStack(alignment: .leading) {
                            Text("Ensure HTTPS is active")
                                .font(.subheadline.bold())
                            Text("If a portal login does not display a lock icon in your browser, your entered information is exposed to eavesdroppers on the same network.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .navigationTitle("Captive Portal")
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
