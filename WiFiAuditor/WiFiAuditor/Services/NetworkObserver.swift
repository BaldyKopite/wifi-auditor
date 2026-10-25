import Foundation
import Network
import NetworkExtension
import CoreLocation
import Combine

/// Monitors Wi-Fi interface transitions and coordinates automatic background security audits.
public final class NetworkObserver: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = NetworkObserver()

    @Published public private(set) var currentSSID: String = "Not Connected"
    @Published public private(set) var currentBSSID: String? = nil
    @Published public private(set) var isAuditing: Bool = false
    @Published public private(set) var currentResult: SecurityAuditResult?
    @Published public private(set) var auditHistory: [SecurityAuditResult] = []

    private let pathMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
    private let monitorQueue = DispatchQueue(label: "com.wifiauditor.networkmonitor")
    private let locationManager = CLLocationManager()
    private var lastAuditedSSID: String?

    private override init() {
        super.init()
        locationManager.delegate = self
    }

    /// Initializes background path monitoring and requests necessary Wi-Fi info authorizations
    public func start() {
        requestPermissions()

        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if path.status == .satisfied && path.usesInterfaceType(.wifi) {
                    Task {
                        await self.handleWiFiConnected()
                    }
                } else {
                    self.handleWiFiDisconnected()
                }
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    /// Manually triggers an audit (e.g. from pull-to-refresh or Re-audit button)
    public func reAuditCurrentNetwork() {
        Task {
            await handleWiFiConnected(force: true)
        }
    }

    private func requestPermissions() {
        // iOS requires location authorization to access the connected Wi-Fi SSID name
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        NotificationManager.shared.requestAuthorization()
    }

    // MARK: - Core Event Handlers
    private func handleWiFiConnected(force: Bool = false) async {
        let (ssid, bssid) = await fetchCurrentWiFiInfo()
        let activeSSID = ssid ?? "Public Wi-Fi"

        if !force && activeSSID == lastAuditedSSID && currentResult != nil {
            return
        }
        self.lastAuditedSSID = activeSSID
        self.currentSSID = activeSSID
        self.currentBSSID = bssid
        self.isAuditing = true

        // 1. Activate Live Activity / Dynamic Island into "Auditing..." state
        await LiveActivityManager.shared.startOrUpdateActivity(
            ssid: activeSSID,
            statusText: "Analyzing network signals...",
            isSecure: false,
            threatLevel: .low
        )

        // 2. Execute Audit with BSSID and Gateway resolution
        let result = await WiFiAuditor.shared.audit(ssid: activeSSID, bssid: bssid, gatewayIP: nil)

        self.currentResult = result
        self.isAuditing = false
        self.auditHistory.insert(result, at: 0)
        if self.auditHistory.count > 20 {
            self.auditHistory.removeLast()
        }

        // 3. Update Dynamic Island & Push Local Notification
        let threatLevel = result.threats.map { $0.severity }.max(by: { $0.hashValue < $1.hashValue }) ?? .low

        await LiveActivityManager.shared.startOrUpdateActivity(
            ssid: activeSSID,
            statusText: result.summaryHeadline,
            isSecure: result.isSecure,
            threatLevel: threatLevel
        )

        if result.riskLevel == .nominal {
            NotificationManager.shared.sendAlert(
                title: "Network Assessed (Nominal)",
                body: "\(activeSSID): Probes completed with \(result.confidence.rawValue) confidence."
            )
        } else if let captiveURL = result.captivePortalURL {
            NotificationManager.shared.sendAlert(
                title: "Captive Portal Detected",
                body: "Login required for \(activeSSID) via \(captiveURL.host ?? "browser")."
            )
        } else {
            let topThreat = result.threats.first?.title ?? "Security alert"
            NotificationManager.shared.sendAlert(
                title: "⚠️ Network Alert",
                body: "\(topThreat) detected on \(activeSSID)."
            )
        }
    }

    private func handleWiFiDisconnected() {
        self.currentSSID = "Disconnected"
        self.currentBSSID = nil
        self.lastAuditedSSID = nil
        self.isAuditing = false
        self.currentResult = nil

        Task {
            await LiveActivityManager.shared.endActivity()
        }
    }

    // MARK: - SSID & BSSID Resolution
    private func fetchCurrentWiFiInfo() async -> (ssid: String?, bssid: String?) {
        if #available(iOS 14.0, *) {
            let network = await NEHotspotNetwork.fetchCurrent()
            return (network?.ssid, network?.bssid)
        }
        return (nil, nil)
    }

    // MARK: - CLLocationManagerDelegate
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            Task {
                await self.handleWiFiConnected(force: true)
            }
        }
    }
}
