# PRODUCT.md — Wi-Fi Auditor

Durable product context, target audience, operating constraints, voice, and non-goals.

---

## 1. Executive Summary & Core Truth
Wi-Fi Auditor is an on-device, privacy-first iOS cybersecurity utility designed to detect public Wi-Fi anomalies and captive portal risks in real-time. It replaces expensive \$15–\$35/month remote VPN subscriptions (such as Glacier App) with lightweight, local cryptographic probes and instant status updates in the **Dynamic Island** and **Live Activities**.

---

## 2. Target Audience
- **Frequent Travelers & Digital Nomads:** Regularly connect to unverified hotel, airport, and train Wi-Fi networks.
- **Remote Workers & Students:** Work from cafes, libraries, and co-working spaces with open or shared captive portals.
- **Privacy-Conscious Everyday Users:** Want immediate reassurance without having to understand networking protocols or route all device traffic through third-party VPN servers.

---

## 3. The Core Problem
1. **Blind Trust on Connection:** When a smartphone connects to a public network, users have no immediate feedback on whether the network's gateway, DNS resolver, or captive portal login form is legitimate or malicious.
2. **Subscription Fatigue & High Overhead:** Existing solutions require continuous VPN tunnels that route multi-gigabyte video/audio traffic through remote datacenters, causing battery drain, connection latency, and high recurring fees.
3. **Phishing via Captive Portals:** Attackers use portable rogue access points (Wi-Fi Pineapples) to stage Evil Twin attacks, broadcasting venue names (e.g., `"Starbucks_Guest"`) with plaintext HTTP login forms to harvest credentials.

---

## 4. Value Proposition
- **Zero-Cloud Data Routing:** Direct on-device probes evaluate TLS 1.3 canary certificates and DNS-over-HTTPS (RFC 8484) without funneling user traffic through proprietary servers.
- **Instant Dynamic Island Feedback:** Visual confirmation (`[ 🛡️ Safe ]` or `[ ⚠️ Alert ]`) appears within 500ms of connecting, before users enter captive portal credentials.
- **Access Point Fingerprinting:** Caches BSSIDs and default gateway subnets to catch "same SSID, different router" rogue attacks.
- **Honest Confidence Scoring:** Never overpromises "unhackable" guarantees; surfaces transparent confidence levels (`HIGH`, `MEDIUM`, `LOW`) and risk tiers.

---

## 5. Voice & Tone
- **Calm & Objective:** Never uses alarmist fear-mongering (e.g., avoid *"YOUR PHONE IS BEING HACKED!"*).
- **Technically Grounded:** Explains *why* an anomaly was flagged (e.g., *"DNS resolution differed from verified DoH mapping"*).
- **Transparent About Limits:** Clearly communicates that heuristic checks are not an enterprise Security Operations Center (SOC) or a replacement for encrypted VPN tunnels.

---

## 6. Explicit Non-Goals
- **Not a Full-Traffic VPN:** Does not tunnel YouTube, Netflix, or game traffic.
- **Not a Password Manager:** Does not store or autofill credentials.
- **Not an Enterprise EDR:** Does not inspect internal iOS kernel integrity or jailbreak root filesystems.
