# AGENTS.md — Steering Guidelines for AI Coding Agents

Instructions, architectural invariants, and non-negotiable constraints for any AI assistant (Antigravity, Cursor, Claude Code, Copilot, Codex) modifying this repository.

---

## 1. Architectural Invariants (Non-Negotiable)

1. **Zero-Cloud Traffic Routing:**
   - This app NEVER tunnels user web or app traffic through a remote VPN server.
   - All network audits occur strictly on-device using local cryptographic probes (TLS 1.3 canaries and DoH RFC 8484 queries).
2. **iOS Deployment Target & Compatibility:**
   - The project target is strictly **iOS 16.2+**.
   - Do NOT lower the deployment target below 16.2 without wrapping all `ActivityKit` APIs (`ActivityContent`, `Activity.request`) in `#available(iOS 16.2, *)`.
3. **Xcode Project Format (`objectVersion = 60`):**
   - GitHub Actions cloud runners use Xcode 15.4.
   - XcodeGen generates `objectVersion = 77` (Xcode 16 format). The CI workflow includes a Ruby downgrade script converting `objectVersion = 77` to `objectVersion = 60`. Do not remove this hook.
4. **Simulator Test Isolation:**
   - The test target `WiFiAuditorTests` must remain decoupled from `WiFiSafetyWidget` in the test scheme.
   - Never re-add `dependencies: - target: WiFiSafetyWidget` to `WiFiAuditor` in `project.yml` for testing schemes, as CoreSimulator will crash on un-signed app extension placeholders (`Invalid placeholder attributes`, exit code 65).
   - The widget extension is embedded strictly in the production archive step for TestFlight.

---

## 2. Design System Adherence (`DESIGN.md` & `PRODUCT.md`)

- **Color:** Always use the semantic palette in `DESIGN.md`. Never use pure `#000000` or `#808080`; always use tinted slate/navy backgrounds.
- **Accessibility:** All interactive buttons and touch targets must maintain a minimum frame height of **44pt** (`.frame(minHeight: 44)`).
- **Typography:** Use Monospaced font for technical hardware metrics (IPs, BSSIDs, latencies) and San Francisco Rounded for headlines.
- **Tone:** Objective, calm, technically precise. Never use fear-mongering security alerts.

---

## 3. Dependency Injection & Testing

- All network probing logic in `WiFiAuditor.swift` must accept an injected `NetworkProbing` protocol client.
- Never write tests that depend on a live Internet connection. All unit tests in `Tests/WiFiAuditorTests/` must use `MockNetworkProbeClient` to ensure 100% deterministic, offline execution.

---

## 4. Security & Compliance Checklist (AgentShield)

Before staging any commit:
- [ ] No `.p12`, `.p8`, `.mobileprovision`, or plaintext secrets are committed to Git.
- [ ] `PrivacyInfo.xcprivacy` is preserved with required Apple category keys.
- [ ] Unit tests pass cleanly on simulator targets.
- [ ] Run `.\scripts\security-lint.ps1` to verify compliance.
