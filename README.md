# 🛡️ Wi-Fi Auditor (iOS)

[![iOS 16.2+](https://img.shields.io/badge/iOS-16.2%2B-blue.svg?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange.svg?logo=swift&logoColor=white)](https://swift.org)
[![Dynamic Island](https://img.shields.io/badge/Dynamic_Island-Supported-purple.svg)](https://developer.apple.com/design/human-interface-guidelines/live-activities)
[![Cloud Mac CI](https://github.com/BaldyKopite/wifi-auditor/actions/workflows/ios-cloud-build.yml/badge.svg)](https://github.com/BaldyKopite/wifi-auditor/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> A lightweight, privacy-first mobile utility for iOS that performs automated on-device heuristic risk checks on public Wi-Fi networks and captive portals, surfacing confidence-scored alerts via the Dynamic Island and Live Activities.

---

> [!NOTE]
> **Heuristic Assessment & Security Scope**
> Wi-Fi Auditor is designed as a **lightweight, on-device risk assessment utility**. It performs best-effort heuristic signal checks (TLS canary verification, DoH cross-referencing, captive portal inspection, and local access point fingerprinting). It is **not** an enterprise Security Operations Center (SOC) or a substitute for an encrypted end-to-end VPN tunnel.

---

## 🌟 Why Wi-Fi Auditor?

Connecting to public Wi-Fi at airports, hotels, and cafes often exposes everyday people to **rogue access points (Evil Twin attacks)**, **fake captive portals**, and **DNS spoofing**.

Apps like **Glacier App** charge **$14.99 to $34.98 every month** because they route all user traffic through expensive remote VPN servers. 

**Wi-Fi Auditor is designed to be the lean, accessible alternative:**
- **Zero-Cloud Data Routing:** Direct on-device cryptographic probes test connection integrity.
- **Confidence-Based Scoring:** Replaces vague claims with transparent confidence levels (`HIGH`, `MEDIUM`, `LOW`) and explicit risk grading.
- **Local Access Point Fingerprinting:** Remembers BSSIDs and router gateways to detect "same SSID, different router" Evil Twin attacks.
- **Instant Status in Dynamic Island:** See `[ 🛡️ Safe ]` or `[ ⚠️ Alert ]` the second you join a network.
- **No Monthly VPN Subscriptions:** Near $0 server infrastructure means users get cybersecurity for a fraction of the price.

---

## 🚀 Threat Evaluation Engine

```
[Phone connects to Wi-Fi]
          │
          ▼
┌────────────────────────────────────────────────────────┐
│           Heuristic Evaluation Engine (<500ms)         │
├────────────────────────────────────────────────────────┤
│ 1. TLS 1.3 Canary Probe (Strict Handshake Check)      │
│ 2. Captive Portal Safety & SSL Validation              │
│ 3. DNS Poisoning Detection (Local DNS vs Encrypted DoH)│
│ 4. Access Point Fingerprint (BSSID / Gateway Shift)   │
└────────────────────────────────────────────────────────┘
          │
    ┌─────┴─────┐
    ▼           ▼
🟢 "No Obvious    🔴 "Suspicious Signals Detected"
   Anomalies"        (Confidence-Scored Dynamic Island Alert)
```

- **🟢 Confidence-Scored Risk Detection:** Categorizes network conditions into `NOMINAL`, `MODERATE`, `ELEVATED`, and `CRITICAL` with transparent confidence metrics.
- **🏝️ Dynamic Island & Lock Screen Live Activity:** Monitor network status right from the Dynamic Island while completing hotel/airport login forms.
- **🔒 TLS 1.3 Canary Probe:** Verifies certificate chains to catch active Man-in-the-Middle (MITM) proxies and Wi-Fi Pineapple attacks.
- **🌐 DNS Tampering Detection:** Cross-references the router's DNS resolver against encrypted **DNS-over-HTTPS (RFC 8484)** via Cloudflare (1.1.1.1) or Quad9 (9.9.9.9).
- **📝 Captive Portal Inspector:** Flags unencrypted plaintext HTTP login pages, non-standard router gateways, and suspicious disposable domains (`.tk`, `.xyz`).
- **🏠 Trusted Network Store:** Cache known-good BSSIDs and default gateway subnets. Detects when an attacker attempts to spoof your home or office SSID with a rogue access point.

---

## 🏗️ Architecture & Dependency Injection

The application is built with clean architectural boundaries for 100% deterministic testability:

```
WiFiAuditor/
├── Services/
│   ├── NetworkProbing.swift       # Protocols (CaptivePortalProbing, TLSHandshakeProbing, DNSIntegrityProbing)
│   ├── WiFiAuditor.swift          # Injectable orchestrator
│   ├── ThreatScoringEngine.swift  # Deterministic multi-signal risk evaluator
│   ├── TrustedNetworkStore.swift  # Persistent BSSID & gateway history
│   ├── NetworkObserver.swift      # NWPathMonitor & NEHotspotNetwork listener
│   ├── LiveActivityManager.swift  # ActivityKit Dynamic Island controller
│   └── NotificationManager.swift  # Local alerts
├── Tests/WiFiAuditorTests/        # Mock probe client testing TLS interception, DNS poisoning & captive states
├── project.yml                    # XcodeGen declarative project configuration
└── .github/workflows/             # Automated Cloud Mac build & test pipeline
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
