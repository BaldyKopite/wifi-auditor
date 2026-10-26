# GLOSSARY.md — Wi-Fi & Mobile Threat Model

Domain vocabulary and technical definitions used throughout Wi-Fi Auditor.

---

## 1. Threat & Attack Terminology

### Evil Twin (Rogue Access Point)
A cyberattack where an adversary configures a portable Wi-Fi access point (e.g. Wi-Fi Pineapple) broadcasting the exact same SSID (network name) as a legitimate venue (such as `"Starbucks_Guest"` or `"Hilton_Honors"`). Because devices often auto-connect to known SSIDs, unsuspecting devices attach to the attacker's router instead of the venue's router.

### Captive Portal & CNA
- **Captive Portal:** A web page intercepting client traffic on a public network requiring user interaction (acceptance of Terms of Service, room number, or email login) before granting outbound Internet access.
- **CNA (Captive Network Assistant):** An operating system feature (such as iOS's sheet popup) triggered when a device makes a plaintext probe (e.g., `http://captive.apple.com/hotspot-detect.html`) and receives a redirect instead of expected HTTP 200/204.

### Man-in-the-Middle (MITM) & TLS Interception
An attack where the local router or proxy intercepts HTTPS traffic between the client and destination server. To read plaintext data, rogue networks attempt to present self-signed or forged root certificates. Wi-Fi Auditor uses a strict TLS 1.3 canary probe with Root CA validation to detect active certificate manipulation.

### DNS Poisoning / Hijacking
When a local DNS server deliberately returns false IP addresses for domain queries, redirecting users to phishing clones or tracking servers. Wi-Fi Auditor cross-references standard system resolution against encrypted DNS-over-HTTPS (RFC 8484) to catch discrepancies.

---

## 2. Networking Identifiers & Telemetry

### SSID (Service Set Identifier)
The human-readable name of a Wi-Fi network (e.g., `"CoffeeShop_Guest"`). SSIDs are unauthenticated and can be broadcast by any router.

### BSSID (Basic Service Set Identifier)
The unique hardware MAC address of the specific radio chip in an access point (e.g., `AA:BB:CC:DD:EE:01`). While large venues have multiple access points under the same SSID, tracking BSSID and gateway changes helps detect rogue access points pretending to be home or office networks.

### Default Gateway
The local router IP address (typically `192.168.1.1`, `10.0.0.1`, or `172.16.0.1`) that routes local packets out to the wider Internet. Sudden subnet shifts for a familiar network can indicate an attacker-controlled router.

### DoH (DNS-over-HTTPS / RFC 8484)
A protocol for performing remote Domain Name System resolution via the encrypted HTTPS protocol. It prevents eavesdropping and tampering of DNS data by local router intermediaries.

---

## 3. Apple Platform Architecture

### ActivityKit & Dynamic Island
The iOS framework that presents live, glanceable updates on the iPhone Lock Screen and inside the Dynamic Island pill without requiring the user to open the application.

### NWPathMonitor & NEHotspotNetwork
- **NWPathMonitor:** System framework for observing network interface state transitions (Wi-Fi vs Cellular, reachable vs unreachable).
- **NEHotspotNetwork:** Apple NetworkExtension API used to query the current connected Wi-Fi SSID and BSSID. Apple requires explicit location permission (`NSLocationWhenInUseUsageDescription`) and the `com.apple.developer.networking.wifi-info` entitlement to read this data.
