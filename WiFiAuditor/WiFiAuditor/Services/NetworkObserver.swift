import Foundation
import Network
import NetworkExtension
import CoreLocation
import Combine

/// Monitors Wi-Fi interface transitions and coordinates automatic background security audits.
public final class NetworkObserver: NSObject, ObservableObject, CLLocationManagerDelegate {
    public static let shared = NetworkObserver()

    @Published public private(set) var currentSSID: String = "Not Connected"
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
        let ssid = await fetchCurrentSSID() ?? "Public Wi-Fi"

        if !force && ssid == lastAuditedSSID && currentResult != nil {
            return
        }
        self.lastAuditedSSID = ssid
        self.currentSSID = ssid
        self.isAuditing = true

        // 1. Activate Live Activity / Dynamic Island into "Auditing..." state
        await LiveActivityManager.shared.startOrUpdateActivity(
            ssid: ssid,
            statusText: "Auditing network safety...",
            isSecure: false,
            threatLevel: .low
        )

        // 2. Execute Audit
        let result = await WiFiAuditor.shared.audit(ssid: ssid)

        self.currentResult = result
        self.isAuditing = false
        self.auditHistory.insert(result, at: 0)
        if self.auditHistory.count > 20 {
            self.auditHistory.removeLast()
        }

        // 3. Update Dynamic Island & Push Local Notification
        let threatLevel = result.threats.map { $0.severity }.max(by: { $0.hashValue < $1.hashValue }) ?? .low

        await LiveActivityManager.shared.startOrUpdateActivity(
            ssid: ssid,
            statusText: result.summaryHeadline,
            isSecure: result.isSecure,
            threatLevel: threatLevel
        )

        if result.isSecure {
            NotificationManager.shared.sendAlert(
                title: "Wi-Fi Verified Secure",
                body: "Connected to \(ssid). Encryption, TLS canary, and DNS integrity confirmed."
            )
        } else if let captiveURL = result.captivePortalURL {
            NotificationManager.shared.sendAlert(
                title: "Captive Portal Detected",
                body: "Login required for \(ssid) via \(captiveURL.host ?? "browser")."
            )
        } else {
            let topThreat = result.threats.first?.title ?? "Security issues detected"
            NotificationManager.shared.sendAlert(
                title: "⚠️ Wi-Fi Security Warning",
                body: "\(topThreat) on \(ssid)."
            )
        }
    }

    private func handleWiFiDisconnected() {
        self.currentSSID = "Disconnected"
        self.lastAuditedSSID = nil
        self.isAuditing = false
        self.currentResult = nil

        Task {
            await LiveActivityManager.shared.endActivity()
        }
    }

    // MARK: - SSID Resolution
    private func fetchCurrentSSID() async -> String? {
        if #available(iOS 14.0, *) {
            let network = await NEHotspotNetwork.fetchCurrent()
            return network?.ssid
        }
        return nil
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
