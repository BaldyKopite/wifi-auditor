import ActivityKit
import WidgetKit
import SwiftUI

public struct WiFiSafetyWidget: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: WiFiSafetyAttributes.self) { context in
            // MARK: - Lock Screen & Banner View
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(shieldColor(for: context.state).opacity(0.18))
                        .frame(width: 48, height: 48)

                    Image(systemName: shieldIcon(for: context.state))
                        .font(.title2)
                        .foregroundColor(shieldColor(for: context.state))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(context.state.ssid)
                            .font(.headline)
                            .lineLimit(1)

                        Spacer()

                        Text(context.state.isSecure ? "VERIFIED" : context.state.threatLevel.rawValue)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(shieldColor(for: context.state).opacity(0.2))
                            .foregroundColor(shieldColor(for: context.state))
                            .cornerRadius(4)
                    }

                    Text(context.state.statusMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.85))

        } dynamicIsland: { context in
            // MARK: - Dynamic Island Layouts
            DynamicIsland {
                // Expanded View (Long Press)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: shieldIcon(for: context.state))
                            .font(.title2)
                            .foregroundColor(shieldColor(for: context.state))

                        VStack(alignment: .leading) {
                            Text(context.state.ssid)
                                .font(.headline)
                                .lineLimit(1)
                            Text("Wi-Fi Security Status")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.isSecure ? "SAFE" : "ALERT")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(shieldColor(for: context.state).opacity(0.2))
                        .foregroundColor(shieldColor(for: context.state))
                        .cornerRadius(6)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // Compact Leading (Left Pill)
                Image(systemName: shieldIcon(for: context.state))
                    .font(.caption)
                    .foregroundColor(shieldColor(for: context.state))
            } compactTrailing: {
                // Compact Trailing (Right Pill)
                Text(context.state.isSecure ? "Safe" : "Alert")
                    .font(.caption2.bold())
                    .foregroundColor(shieldColor(for: context.state))
            } minimal: {
                // Minimal (Single Icon when shared with another app)
                Image(systemName: shieldIcon(for: context.state))
                    .font(.caption2)
                    .foregroundColor(shieldColor(for: context.state))
            }
        }
    }

    private func shieldColor(for state: WiFiSafetyAttributes.ContentState) -> Color {
        if state.isSecure {
            return .green
        } else if state.threatLevel == .critical || state.threatLevel == .high {
            return .red
        } else {
            return .orange
        }
    }

    private func shieldIcon(for state: WiFiSafetyAttributes.ContentState) -> String {
        if state.isSecure {
            return "checkmark.shield.fill"
        } else if state.threatLevel == .critical || state.threatLevel == .high {
            return "exclamationmark.shield.fill"
        } else {
            return "shield.lefthalf.filled"
        }
    }
}
