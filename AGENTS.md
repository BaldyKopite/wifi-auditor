# AGENTS.md — Steering Guidelines & Superpowers Protocol

Instructions, architectural invariants, and non-negotiable constraints for any AI assistant modifying this repository.

---

## 1. Superpowers Engineering Protocol

This repository follows the Superpowers engineering methodology:

### A. Initial Step: Skill Invocation & Methodology (`using-superpowers`)
- **Always invoke skills before action:** Check and activate the appropriate Superpowers skill before executing tasks, writing code, or proposing solutions:
  - **New Features / Architecture:** Use `brainstorming` before entering planning or implementation.
  - **Planning:** Use `writing-plans` once specifications and design are aligned.
  - **Debugging / Issues:** Use `systematic-debugging` to trace and reproduce root causes before modifying files.
  - **Implementation:** Use `test-driven-development` (write failing tests before implementation code).
  - **Complex Tasks:** Use `writing-plans` and `subagent-driven-development`.
  - **Code Review:** Use `requesting-code-review` and `receiving-code-review`.
  - **Branch Integration:** Use `finishing-a-development-branch`.
- **Task Tracking:** For multi-step tasks, create and maintain an explicit task checklist, updating progress systematically.

### B. Final Step: Verification Before Completion (`verification-before-completion`)
- **Strict Evidence Requirement:** NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE.
- Before claiming work is finished, resolved, or passing:
  1. Determine the exact command or test that proves the change works.
  2. Run the full command fresh and inspect the output and exit status.
  3. Confirm the output verifies the claim with tangible evidence.
  4. Only after providing the evidence, mark the task as complete.

---

## 2. Architectural Invariants (Non-Negotiable)

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

## 3. Design System Adherence (`DESIGN.md` & `PRODUCT.md`)

- **Color:** Always use the semantic palette in `DESIGN.md`. Never use pure `#000000` or `#808080`; always use tinted slate/navy backgrounds.
- **Accessibility:** All interactive buttons and touch targets must maintain a minimum frame height of **44pt** (`.frame(minHeight: 44)`).
- **Typography:** Use Monospaced font for technical hardware metrics (IPs, BSSIDs, latencies) and San Francisco Rounded for headlines.
- **Tone:** Objective, calm, technically precise. Never use fear-mongering security alerts.

---

## 4. Dependency Injection & Testing

- All network probing logic in `WiFiAuditor.swift` must accept an injected `NetworkProbing` protocol client.
- Never write tests that depend on a live Internet connection. All unit tests in `Tests/WiFiAuditorTests/` must use `MockNetworkProbeClient` to ensure 100% deterministic, offline execution.

---

## 5. Security & Compliance Checklist (AgentShield)

Before staging any commit:
- [ ] No `.p12`, `.p8`, `.mobileprovision`, or plaintext secrets are committed to Git.
- [ ] `PrivacyInfo.xcprivacy` is preserved with required Apple category keys.
- [ ] Unit tests pass cleanly on simulator targets.
- [ ] Run `.\scripts\security-lint.ps1` to verify compliance.
