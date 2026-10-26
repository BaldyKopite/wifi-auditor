# DESIGN.md — Wi-Fi Auditor Design System

Aesthetic foundations, design tokens, typography, component rules, and anti-patterns.

---

## 1. Aesthetic Foundations & Theme Direction

Wi-Fi Auditor uses a **Refined Cyber-Tactical** visual direction:
- Clean, high-legibility telemetry combined with Apple Human Interface Guidelines.
- **Dark Mode First:** Tinted deep slate/navy backgrounds instead of harsh, un-tinted pure `#000000`.
- **Purposeful Semantic Color:** Color carries critical security meaning and must never be used purely decoratively.

---

## 2. Color Palette & Semantic Tokens

### Primary Status Colors
| Semantic State | Hex Value | Usage |
| :--- | :--- | :--- |
| **Nominal (Safe)** | `#10B981` (Emerald 500) | No obvious anomalies observed, high confidence |
| **Moderate (Caution)** | `#F59E0B` (Amber 500) | Captive portal detected, unauthenticated state |
| **Elevated (Warning)** | `#F97316` (Orange 500) | Gateway subnet shift, unexpected BSSID |
| **Critical (Threat)** | `#EF4444` (Rose 500) | Active TLS interception, DNS spoofing detected |
| **Auditing / Scanning**| `#3B82F6` (Blue 500) | Running cryptographic canary probes |

### Dark Mode Tinting Tokens
- **Background Root:** `#0B0F19` (Slate 950 - deep blue-gray tint)
- **Secondary Surface:** `#1E293B` (Slate 800)
- **Elevated Card:** `#334155` (Slate 700 with 1px border)
- **Subtle Border:** `rgba(255, 255, 255, 0.08)`

---

## 3. Typography Hierarchy

- **Network Identity Title:** `.system(size: 26, weight: .bold, design: .rounded)` — Prominent, welcoming, clear.
- **Section Headlines:** `.headline` / `.system(size: 17, weight: .semibold, design: .default)`
- **Body & Threat Descriptions:** `.subheadline` with `lineSpacing(3)` for readability.
- **Hardware Telemetry (BSSID, IP, Latency):** `.system(size: 13, weight: .medium, design: .monospaced)` for precision.
- **Status Badges & Tags:** `.system(size: 11, weight: .bold, design: .rounded)` with generous horizontal padding.

---

## 4. Spacing, Rhythm & Touch Targets

- **Touch Target Rule (Apple HIG):** All interactive buttons, toggles, and disclosure links must have a minimum clickable area of **44x44pt**.
- **Card Padding:** Consistent `14pt` padding with `12pt` corner radius.
- **Border Treatment:** Use subtle `1pt` border strokes matching the semantic threat color at `20%` opacity rather than heavy drop shadows.

---

## 5. Motion & Animation Principles

- **Rotation:** Linear, smooth rotation for the re-scan icon (`Animation.linear(duration: 1).repeatForever()`).
- **State Transitions:** `.easeInOut(duration: 0.25)` when expanding threat details or updating confidence pills.
- **Anti-Pattern:** Avoid aggressive spring/elastic bounce easing that feels game-like or outdated.

---

## 6. Impeccable Anti-Patterns (Strictly Avoided)

- ❌ **No Pure Black / Gray:** Do not use `#000000` or neutral `#808080`. Always use cool slate/blue undertones.
- ❌ **No Nested Cards in Cards:** Do not place cards inside parent cards; use clear vertical spacing and section headers.
- ❌ **No Low-Contrast Colored Text:** Do not put gray text over colored backgrounds. On colored banners (e.g. orange captive alert), text must be dark gray/black or white for maximum WCAG AAA contrast.
- ❌ **No Vague "Secure" Hyperbole:** Avoid claiming 100% invulnerability; use objective assessment terminology.
