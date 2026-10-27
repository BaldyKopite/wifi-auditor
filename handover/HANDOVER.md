# Project Handover — Wi-Fi Auditor (v1.0.0 iOS)

> Last Updated: 2026-10-27  
> Status: **100% CI Green & TestFlight Lane Configured**  
> Repository: `https://github.com/BaldyKopite/wifi-auditor`  
> Branch: `main`  
> Target Platform: iOS 16.2+ (iPhone, Dynamic Island & Lock Screen Live Activities)  
> Workspace: `c:\Users\Dallas\Documents\antigravity\amazing-franklin`  

---

## 1. Executive Summary

Wi-Fi Auditor is an on-device, privacy-first iOS cybersecurity utility that audits public Wi-Fi networks and captive portals in real-time. Built as a lean, low-overhead alternative to heavy VPN suites like Glacier App ($14.99–$34.98/mo), Wi-Fi Auditor eliminates remote cloud traffic routing, achieving near **$0/user operational infrastructure cost**.

The app evaluates network safety within 500ms of connecting, surfacing confidence-scored risk ratings (`NOMINAL`, `MODERATE`, `ELEVATED`, `CRITICAL`) and instant visual alerts directly inside the **Dynamic Island** and **Lock Screen Live Activities** before the user inputs sensitive credentials into a captive portal.

---

## 2. Core Architecture & Component Mapping

```
WiFiAuditor/
├── WiFiAuditor/                     # Main iOS Application Target
│   ├── App/
│   │   ├── WiFiAuditorApp.swift     # SwiftUI app lifecycle entry point
│   │   └── AppDelegate.swift        # Background notifications & lifecycle
│   ├── Models/
│   │   ├── SecurityAuditResult.swift# Audit data models & threat definitions
│   │   └── WiFiSafetyAttributes.swift# ActivityKit shared attributes
│   ├── Services/
│   │   ├── NetworkProbing.swift     # Protocols: Captive, TLS 1.3, & DoH probes
│   │   ├── WiFiAuditor.swift        # Injected audit orchestrator
│   │   ├── ThreatScoringEngine.swift# Adversarial vs. Benign consensus engine
│   │   ├── TrustedNetworkStore.swift# Persistent BSSID & gateway cache (Evil Twin detection)
│   │   ├── NetworkObserver.swift    # NWPathMonitor & NEHotspotNetwork listener
│   │   ├── LiveActivityManager.swift# ActivityKit Dynamic Island controller
│   │   └── NotificationManager.swift# Instant local notification dispatcher
│   ├── Views/
│   │   ├── DashboardView.swift      # Modern SwiftUI telemetry dashboard
│   │   ├── AuditResultCard.swift    # Severity-coded threat presentation
│   │   ├── CaptivePortalDetailView.swift# Captive portal SSL & URL inspector
│   │   └── SettingsView.swift       # DoH provider selection & preferences
│   └── Resources/
│       ├── Info.plist               # Permissions (Location, Background fetch, Live Activities)
│       ├── WiFiAuditorApp.entitlements# com.apple.developer.networking.wifi-info
│       └── PrivacyInfo.xcprivacy    # Mandatory Apple Privacy Manifest (Spring 2024+)
├── WiFiSafetyWidget/                # Widget Extension Target (ActivityKit)
│   ├── WiFiSafetyWidgetBundle.swift # Extension entry point
│   ├── WiFiSafetyWidget.swift       # Dynamic Island (Compact, Minimal, Expanded) & Lock Screen
│   └── Info.plist
├── Tests/WiFiAuditorTests/          # Deterministic Offline Unit Test Suite
│   └── WiFiAuditorTests.swift       # Mock probe client tests (MITM, DNS spoofing, Evil Twin)
├── scripts/
│   ├── setup-testflight.ps1         # Interactive Windows PowerShell credential wizard
│   └── security-lint.ps1            # AgentShield security, privacy manifest, & key leak linter
├── .github/workflows/
│   ├── ios-cloud-build.yml          # Automated macOS Apple Silicon M2 CI pipeline (100% Green)
│   └── deploy-testflight.yml        # Automated production archive, signing, & TestFlight upload
├── project.yml                      # Declarative XcodeGen configuration
├── ExportOptions.plist              # App Store Connect distribution export options
├── AGENTS.md                        # Non-negotiable AI agent steering guidelines
├── PRODUCT.md                       # Durable product context, voice, & non-goals
├── DESIGN.md                        # Impeccable design system tokens & accessibility rules
├── GLOSSARY.md                      # Networking & threat model vocabulary
├── WINDOWS_DEVELOPER_GUIDE.md       # Zero-Mac development walkthrough
├── TESTFLIGHT_SETUP_GUIDE.md        # 10-step Apple credentials setup guide
└── README.md                        # Official repository documentation & badges
```

---

## 3. Key Technical Milestones & CI/CD Resolutions

During this engineering cycle, the project resolved several real-world macOS / iOS continuous integration challenges:

1. **Xcode Project Format Compatibility (`objectVersion = 77` $\rightarrow$ `60`)**:
   - *Problem*: XcodeGen on macOS 14 runners generated Xcode 16 format (`objectVersion = 77`), which Xcode 15.4 refused to open (Exit code 74).
   - *Fix*: Integrated a deterministic Ruby post-processing hook in CI that rewrites `objectVersion = 77` to `objectVersion = 60`, ensuring compatibility with Xcode 15.4.
2. **ActivityKit API Alignment (iOS 16.2+)**:
   - *Problem*: `ActivityContent`, `request`, and `update` APIs require iOS 16.2+. Initial build targeted 16.1.
   - *Fix*: Aligned all target deployment settings in `project.yml` to iOS 16.2 and added `#available(iOS 16.2, *)` defensive API guards in `LiveActivityManager.swift`.
3. **CoreSimulator App Extension Placeholder Isolation (Exit Code 65)**:
   - *Problem*: When `WiFiAuditor` depended on `WiFiSafetyWidget` in the test scheme, `xcodebuild test` copied the unsigned `.appex` into `PlugIns/`, causing CoreSimulator to crash with `"Invalid placeholder attributes"`.
   - *Fix*: Decoupled the widget extension dependency from the testing scheme and added `-only-testing:WiFiAuditorTests -parallel-testing-enabled NO ONLY_ACTIVE_ARCH=YES`. The widget is now dynamically re-embedded only during the production archive step in the TestFlight lane.
4. **Current CI Status**:
   - Workflow run `40176538322` **PASSED (100% Green)** on Apple Silicon M2 cloud Mac runners.

---

## 4. Advanced Threat Model & Heuristics (Consensus Engine)

Inspired by *TauricResearch/TradingAgents* and *affaan-m/ECC*:
- **Adversarial vs. Benign Consensus Engine**:
  Synthesizes competing signals (benign canary passes vs adversarial anomalies like BSSID hardware shifts or unencrypted HTTP portals) into a normalized **Risk Score (0–100)**.
- **Trusted Network Fingerprinting**:
  `TrustedNetworkStore` caches BSSIDs and default gateway subnets in local sandboxed storage, detecting "Same SSID, Different Hardware" rogue access point (Evil Twin) attacks.
- **Apple Privacy Manifest Compliance**:
  Full `PrivacyInfo.xcprivacy` implemented declaring `NSPrivacyTracking = false` and `NSPrivacyAccessedAPICategoryUserDefaults` reason code `CA92.1`.
- **Pre-Commit Security Linter**:
  `scripts/security-lint.ps1` runs automated AgentShield policy checks preventing credential leakage.

---

## 5. Deployment Checklist (Apple TestFlight)

The automated TestFlight lane (`.github/workflows/deploy-testflight.yml`) is completely wired with pre-flight secret validation.

To deploy over-the-air to a physical iPhone:
1. Export Apple Distribution Certificate (`.p12`), App Profile (`WiFiAuditor_AppStore.mobileprovision`), Widget Profile (`WiFiAuditorWidget_AppStore.mobileprovision`), and App Store Connect API Key (`AuthKey_*.p8`).
2. Run `.\scripts\setup-testflight.ps1` in PowerShell to convert files to Base64 and populate GitHub Secrets.
3. Trigger the **Deploy to Apple TestFlight** workflow in GitHub Actions.
