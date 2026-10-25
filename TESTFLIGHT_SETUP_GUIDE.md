# Complete Apple TestFlight Deployment Guide (Zero-Mac CI/CD)

This comprehensive guide details the exact setup path on Apple Developer, App Store Connect, and Windows PowerShell to deliver automated TestFlight builds directly to your physical iPhone via GitHub Actions.

---

## 1. Set Up App Bundle IDs in Apple Developer

In [Apple Developer Identifiers](https://developer.apple.com/account/resources/identifiers/list):
1. Click **+** to register two App IDs:
   - **Main App:** `com.wifiauditor.app`
   - **Widget Extension:** `com.wifiauditor.app.widget`
2. For `com.wifiauditor.app`, enable:
   - **Access Wi-Fi Information**
   - **Push Notifications**

---

## 2. Create Provisioning Profiles

In [Apple Developer Profiles](https://developer.apple.com/account/resources/profiles/list):
1. Create an **App Store** distribution profile for `com.wifiauditor.app`:
   - Name: `WiFiAuditor_AppStore`
   - Download as: `WiFiAuditor_AppStore.mobileprovision`
2. Create an **App Store** distribution profile for `com.wifiauditor.app.widget`:
   - Name: `WiFiAuditorWidget_AppStore`
   - Download as: `WiFiAuditorWidget_AppStore.mobileprovision`

---

## 3. Create the App Store Connect API Key

In [App Store Connect API Keys](https://appstoreconnect.apple.com/access/api):
1. Click **Keys** > **+** (Generate API Key).
   - Name: `GitHub Actions WiFi Auditor`
   - Access: `Developer` or `App Manager`
2. Save and download the `.p8` private key file (`AuthKey_XXXXXXXXXX.p8`). *(Note: Apple only permits downloading this file once!)*
3. Note your:
   - **Key ID** (10 characters, e.g., `2X9R4HXF34`)
   - **Issuer ID** (UUID at the top of the page, e.g., `69a6de70-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

---

## 4. Export Distribution Certificate (.p12)

From Keychain Access (or Apple Developer portal):
1. Export your **Apple Distribution** certificate as a `.p12` file.
   *(Important: Ensure it is a Distribution certificate, not Development).*
2. Save as: `certificate.p12`
3. Enter a secure export password when prompted and remember it.

---

## 5. Local File Organization (Windows)

Place your 4 downloaded files in a convenient folder on your Windows PC:
- `certificate.p12`
- `WiFiAuditor_AppStore.mobileprovision`
- `WiFiAuditorWidget_AppStore.mobileprovision`
- `AuthKey_XXXXXXXXXX.p8`

---

## 6. Encode Files to Base64 via Windows PowerShell

Open PowerShell in that folder and run these commands to copy the base64 text directly to your clipboard:

```powershell
# 1. Distribution Certificate (.p12)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("certificate.p12")) | Set-Clipboard
# (Paste into secret: APPLE_CERTIFICATE_BASE64)

# 2. Main App Provisioning Profile
[Convert]::ToBase64String([IO.File]::ReadAllBytes("WiFiAuditor_AppStore.mobileprovision")) | Set-Clipboard
# (Paste into secret: APPLE_APP_PROFILE_BASE64)

# 3. Widget Provisioning Profile
[Convert]::ToBase64String([IO.File]::ReadAllBytes("WiFiAuditorWidget_AppStore.mobileprovision")) | Set-Clipboard
# (Paste into secret: APPLE_WIDGET_PROFILE_BASE64)

# 4. App Store Connect API Key (.p8)
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXXXXXXXX.p8")) | Set-Clipboard
# (Paste into secret: APP_STORE_CONNECT_PRIVATE_KEY_BASE64)
```

---

## 7. Add Secrets to GitHub

In your GitHub repository:
👉 **Settings > Secrets and variables > Actions > New repository secret**

Add these exact secret names:

| Secret Name | Source File / Value |
| :--- | :--- |
| `APPLE_CERTIFICATE_BASE64` | Output from `certificate.p12` base64 command |
| `APPLE_CERTIFICATE_PASSWORD` | Password you set when exporting the `.p12` |
| `APPLE_APP_PROFILE_BASE64` | Output from `WiFiAuditor_AppStore.mobileprovision` command |
| `APPLE_WIDGET_PROFILE_BASE64` | Output from `WiFiAuditorWidget_AppStore.mobileprovision` command |
| `APP_STORE_CONNECT_KEY_ID` | 10-character Key ID from Step 3 |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer UUID from Step 3 |
| `APP_STORE_CONNECT_PRIVATE_KEY_BASE64` | Output from `AuthKey_XXXXXXXXXX.p8` command |
| `KEYCHAIN_PASSWORD` *(optional)* | Custom temporary password (defaults to `temporary_ci_password`) |

---

## 8. Final Verification Checklist

Before triggering the deployment run, verify:
- [x] The certificate is an **Apple Distribution** `.p12`, not Development.
- [x] `APPLE_CERTIFICATE_PASSWORD` matches the export password.
- [x] App profile matches `com.wifiauditor.app`.
- [x] Widget profile matches `com.wifiauditor.app.widget`.
- [x] Key ID and Issuer ID match the active key in App Store Connect.
- [x] `.p8` file was downloaded fresh from Apple.

---

## 9. Run the TestFlight Deployment

In your repository on GitHub:
1. Click the **Actions** tab.
2. Select **"Deploy to Apple TestFlight"** from the left sidebar.
3. Click **Run workflow**.

The workflow will:
1. Validate all secrets.
2. Generate the Xcode 15-compatible project.
3. Run the isolated unit test suite.
4. Re-embed the Dynamic Island widget extension for production.
5. Archive and sign the application with your Apple certificate.
6. Export the `.ipa` and upload it directly to **Apple TestFlight**.

---

## 10. Install on Your iPhone

Within 5–10 minutes of workflow completion:
1. Apple will process the build in App Store Connect.
2. You will receive an email and notification on your iPhone.
3. Open the **TestFlight** app and tap **Update / Install**!
