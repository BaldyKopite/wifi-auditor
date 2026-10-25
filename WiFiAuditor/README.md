# Wi-Fi Auditor (iOS)

> A lightweight, privacy-first cybersecurity utility for iOS that audits public Wi-Fi networks and captive portals in real-time, giving users instant Dynamic Island & Live Activity verification.

---

## Features
- **Instant Wi-Fi Verification**: Automatically probes network safety the moment your device connects to any Wi-Fi hotspot.
- **Captive Portal Integrity**: Detects rogue login pages, unencrypted plaintext HTTP login forms, and suspicious domains.
- **TLS Canary Probe**: Validates strict TLS 1.3 certificate chains to catch active Man-in-the-Middle (MITM) proxies and Wi-Fi Pineapple attacks.
- **DNS Poisoning Detection**: Cross-references local router DNS resolutions with encrypted DNS-over-HTTPS (DoH) to prevent domain hijacking.
- **Dynamic Island & Live Activity**: Real-time visual confirmation (`[ 🛡️ Safe ]` or `[ ⚠️ Alert ]`) without needing to unlock or open the app.
- **Zero-Cloud Architecture**: No expensive VPN server routing or user data logging. Operational costs are virtually $0.

---

## Project Structure

```
WiFiAuditor/
├── WiFiAuditor/                   # Main iOS Application Target
│   ├── App/
│   │   ├── WiFiAuditorApp.swift    # App entry point
│   │   └── AppDelegate.swift       # Lifecycle & notifications setup
│   ├── Models/
│   │   ├── SecurityAuditResult.swift
│   │   ├── NetworkThreat.swift
│   │   └── WiFiSafetyAttributes.swift # Shared with Widget Extension
│   ├── Services/
│   │   ├── WiFiAuditor.swift       # Cryptographic probes & captive detector
│   │   ├── NetworkObserver.swift   # NWPathMonitor & Wi-Fi state listener
│   │   ├── LiveActivityManager.swift # ActivityKit controller
│   │   └── NotificationManager.swift # Local alerts
│   ├── Views/
│   │   ├── DashboardView.swift     # Primary UI & telemetry metrics
│   │   ├── AuditResultCard.swift   # Threat presentation
│   │   ├── CaptivePortalDetailView.swift
│   │   └── SettingsView.swift      # Configuration & DoH providers
│   └── Resources/
│       ├── Info.plist
│       └── WiFiAuditorApp.entitlements
├── WiFiSafetyWidget/              # Widget Extension (ActivityKit)
│   ├── WiFiSafetyWidgetBundle.swift
│   ├── WiFiSafetyWidget.swift     # Dynamic Island & Lock Screen views
│   └── Info.plist
├── Tests/
│   └── WiFiAuditorTests/
│       └── WiFiAuditorTests.swift
├── PROJECT_REVIEW.md              # Engineering, security, & business review
└── README.md
```

---

## Opening and Running in Xcode

1. Open **Xcode** on your Mac.
2. Select **File > New > Project...** (or import the `WiFiAuditor` directory).
   - Target 1: **App** (Name: `WiFiAuditor`)
   - Target 2: **Widget Extension** with Live Activities enabled (Name: `WiFiSafetyWidget`).
3. Ensure both targets include `WiFiSafetyAttributes.swift` in their **Target Membership**.
4. In **Signing & Capabilities** for `WiFiAuditor`:
   - Add **Access Wi-Fi Information**.
   - Add **Push Notifications** (for local alert triggers).
   - Add **Background Modes** (`Background fetch`, `Background processing`).
5. Build & run on a physical iPhone or Simulator with iOS 16.2+.

---

## Documentation
See [PROJECT_REVIEW.md](PROJECT_REVIEW.md) for a detailed technical analysis of the threat model, performance benchmarks, and economic comparison against Glacier.
