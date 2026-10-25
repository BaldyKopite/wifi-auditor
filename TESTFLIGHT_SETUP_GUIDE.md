# Apple TestFlight Deployment Guide (Zero-Mac CI/CD)

This guide walks you through setting up automated over-the-air deployment to **Apple TestFlight** directly from GitHub Actions.

---

## 1. Prerequisites
- An active [Apple Developer Account](https://developer.apple.com/) ($99/year).
- Access to [App Store Connect](https://appstoreconnect.apple.com/).

---

## 2. Generate App Store Connect API Key
This allows GitHub Actions to securely upload `.ipa` builds to Apple servers without needing 2-Factor Authentication prompts.

1. Go to **App Store Connect > Users and Access > Integrations > API Keys**.
2. Click **+** (Generate API Key).
   - Name: `GitHub CI Deploy`
   - Access: `App Manager` or `Developer`
3. Download the private key file (`AuthKey_XXXXXXXXXX.p8`). *(Note: You can only download this file once!)*
4. Note your:
   - **Key ID** (e.g., `2X9R4HXF34`)
   - **Issuer ID** (e.g., `69a6de70-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

---

## 3. Obtain Distribution Certificate & Profiles

In **developer.apple.com > Certificates, Identifiers & Profiles**:

1. **Apple Distribution Certificate:**
   - Create an **Apple Distribution** certificate and export it as a `.p12` file with a secure password.
2. **Identifiers:**
   - App: `com.wifiauditor.app` (Enable `Access Wi-Fi Information` and `Push Notifications`).
   - Widget: `com.wifiauditor.app.widget`.
3. **Provisioning Profiles:**
   - Create an **App Store** distribution profile for `com.wifiauditor.app`.
   - Create an **App Store** distribution profile for `com.wifiauditor.app.widget`.

---

## 4. Convert Files to Base64 (on Windows PowerShell)

Run these quick commands in PowerShell on your files to encode them into text for GitHub Secrets:

```powershell
# Certificate .p12
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificate.p12")) | Set-Clipboard
# Paste into secret: APPLE_CERTIFICATE_BASE64

# API Key .p8
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXXXXXXXX.p8")) | Set-Clipboard
# Paste into secret: APP_STORE_CONNECT_PRIVATE_KEY_BASE64

# App Provisioning Profile
[Convert]::ToBase64String([IO.File]::ReadAllBytes("WiFiAuditor_AppStore.mobileprovision")) | Set-Clipboard
# Paste into secret: APPLE_APP_PROFILE_BASE64

# Widget Provisioning Profile
[Convert]::ToBase64String([IO.File]::ReadAllBytes("WiFiAuditorWidget_AppStore.mobileprovision")) | Set-Clipboard
# Paste into secret: APPLE_WIDGET_PROFILE_BASE64
```

---

## 5. Add Secrets to Your GitHub Repository

In your repository on GitHub:
1. Go to **Settings > Secrets and variables > Actions > New repository secret**.
2. Add the following 6 secrets:

| Secret Name | Description |
| :--- | :--- |
| `APP_STORE_CONNECT_KEY_ID` | Your 10-character Key ID from Step 2 |
| `APP_STORE_CONNECT_ISSUER_ID` | Your UUID Issuer ID from Step 2 |
| `APP_STORE_CONNECT_PRIVATE_KEY_BASE64` | Base64 content of `AuthKey_XXXXXXXXXX.p8` |
| `APPLE_CERTIFICATE_BASE64` | Base64 content of your `.p12` certificate |
| `APPLE_CERTIFICATE_PASSWORD` | Password you set when exporting the `.p12` |
| `APPLE_APP_PROFILE_BASE64` | Base64 content of App Provisioning Profile |
| `APPLE_WIDGET_PROFILE_BASE64` | Base64 content of Widget Provisioning Profile |

---

## 6. Triggering a TestFlight Release

### Option A: One-Click Manual Deploy
1. Go to your repository's **Actions** tab on GitHub.
2. Select **"Deploy to Apple TestFlight"** in the left sidebar.
3. Click **Run workflow**, enter optional release notes, and press the green button.

### Option B: Git Tag Deploy
Push a version tag from your Windows terminal:
```powershell
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will automatically compile, sign, package, and upload the build. Within 5–10 minutes, you will receive an email from Apple and a notification in the **TestFlight app on your iPhone**!
