import SwiftUI

public struct AuditResultCard: View {
    public let threat: NetworkThreat

    public init(threat: NetworkThreat) {
        self.threat = threat
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(colorForSeverity)
                    .font(.title3)

                Text(threat.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(threat.severity.rawValue)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(colorForSeverity.opacity(0.15))
                    .foregroundColor(colorForSeverity)
                    .cornerRadius(6)
            }

            Text(threat.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(nil)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorForSeverity.opacity(0.2), lineWidth: 1)
        )
    }

    private var iconName: String {
        switch threat.severity {
        case .critical: return "xmark.octagon.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "exclamationmark.shield.fill"
        case .low: return "info.circle.fill"
        }
    }

    private var colorForSeverity: Color {
        switch threat.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}
