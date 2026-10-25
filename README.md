# 🛡️ Wi-Fi Auditor (iOS)

[![iOS 16.1+](https://img.shields.io/badge/iOS-16.1%2B-blue.svg?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg?logo=swift&logoColor=white)](https://swift.org)
[![Dynamic Island](https://img.shields.io/badge/Dynamic_Island-Supported-purple.svg)](https://developer.apple.com/design/human-interface-guidelines/live-activities)
[![Cloud Mac CI](https://github.com/BaldyKopite/wifi-auditor/actions/workflows/ios-cloud-build.yml/badge.svg)](https://github.com/BaldyKopite/wifi-auditor/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> A lightweight, privacy-first mobile cybersecurity utility for iOS that audits public Wi-Fi networks and captive portals in real-time, giving users instant Dynamic Island & Live Activity verification without expensive monthly VPN subscriptions.

---

## 🌟 Why Wi-Fi Auditor?

Connecting to public Wi-Fi at airports, hotels, and cafes often exposes everyday people to **rogue access points (Evil Twin attacks)**, **fake captive portals**, and **DNS spoofing**. 

Apps like **Glacier App** charge **$14.99 to $34.98 every month** because they route all user traffic through expensive remote VPN servers. 

**Wi-Fi Auditor is designed to be the lean, accessible alternative:**
- **Zero-Cloud Data Routing:** Direct on-device cryptographic audits test connection integrity.
- **Instant Status in Dynamic Island:** See `[ 🛡️ Safe ]` or `[ ⚠️ Alert ]` the second you join a network.
- **No Monthly VPN Subscriptions:** Near $0 server infrastructure means users get cybersecurity for a fraction of the price.

---

## 🚀 Key Features

```
[Phone connects to Wi-Fi]
          │
          ▼
┌────────────────────────────────────────────────────────┐
│           Security Audit Engine (<500ms)               │
├────────────────────────────────────────────────────────┤
│ 1. TLS 1.3 Canary Probe (Strict Handshake Check)      │
│ 2. Captive Portal Safety & SSL Validation              │
│ 3. DNS Poisoning Detection (Local DNS vs Encrypted DoH)│
│ 4. Disposable Domain & Phishing Pattern Detection      │
└────────────────────────────────────────────────────────┘
          │
    ┌─────┴─────┐
    ▼           ▼
🟢 "Verified    🔴 "Threat Detected"
   Secure"         (Instant Push Alert & Dynamic Island)
```

- **🟢 Real-Time Wi-Fi Legitimacy:** Automatic background audit triggers when switching between cellular and Wi-Fi networks.
- **🏝️ Dynamic Island & Lock Screen Live Activity:** Monitor network status right from the Dynamic Island while completing hotel/airport login forms.
- **🔒 TLS 1.3 Canary Probe:** Verifies certificate chains to catch active Man-in-the-Middle (MITM) proxies and Wi-Fi Pineapple attacks.
- **🌐 DNS Tampering Detection:** Cross-references the router's DNS resolver against encrypted **DNS-over-HTTPS (RFC 8484)** via Cloudflare (1.1.1.1) or Quad9 (9.9.9.9).
- **📝 Captive Portal Inspector:** Flags unencrypted plaintext HTTP login pages, non-standard router gateways, and suspicious disposable domains (`.tk`, `.xyz`).

---

## ⚖️ Product Comparison: Glacier vs. Wi-Fi Auditor

| Feature | Glacier App | Wi-Fi Auditor |
| :--- | :--- | :--- |
| **Price** | **$14.99 – $34.98 / month** | **$1.99 / mo** (or $19.99 one-time) |
| **Wi-Fi / Captive Portal Verification** | Hidden inside heavy VPN suite | **Instant Dynamic Island & Push Alert** |
| **Server Bandwidth Costs** | High (All user streaming/browsing passes through VPN) | **$0.00** (Direct client-to-canary probes) |
| **Battery Consumption** | High (Continuous VPN tunneling & encryption) | **Negligible (<0.1% daily)** (Event-driven background audits) |
| **User Privacy** | Centralized VPN operator handles your traffic | **100% On-Device & Decentralized** |

---

## 🏗️ Technical Architecture

The application is built in native **Swift** with **SwiftUI** and **ActivityKit**:

```
WiFiAuditor/
├── WiFiAuditor/                 # Main App Target
│   ├── App/                     # SwiftUI App lifecycle & AppDelegate
│   ├── Models/                  # Threat models, AuditResult, WiFiSafetyAttributes
│   ├── Services/                # WiFiAuditor, NetworkObserver, LiveActivityManager
│   ├── Views/                   # DashboardView, AuditResultCard, CaptivePortalDetailView
│   └── Resources/               # Info.plist & WiFiAuditorApp.entitlements
├── WiFiSafetyWidget/            # Widget Extension (ActivityKit Dynamic Island)
├── Tests/WiFiAuditorTests/      # Unit testing suite
├── project.yml                  # XcodeGen declarative project configuration
└── .github/workflows/           # Automated Cloud Mac build & test pipeline
```

---

## 💻 Building Without a Mac (Windows Development)

This repository includes a pre-configured **GitHub Actions Cloud Mac Pipeline**. You can write and edit code on Windows without ever owning an Apple computer:

1. **Push your code from Windows:**
   ```powershell
   git add .
   git commit -m "Update code"
   git push origin main
   ```
2. **Watch the Cloud Mac Build:**
   Go to the [Actions Tab](https://github.com/BaldyKopite/wifi-auditor/actions). GitHub automatically starts an **Apple Silicon M2 macOS runner** that runs unit tests, compiles the app, and outputs a downloadable `.zip` package.
3. **Deploying to iPhone:**
   Follow our [Windows Developer Guide](WINDOWS_DEVELOPER_GUIDE.md) to set up automatic, over-the-air installation straight to **Apple TestFlight** on your physical iPhone.

---

## 📄 License
This project is open-source under the [MIT License](LICENSE).
