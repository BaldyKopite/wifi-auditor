# Developing & Building iOS on Windows (Zero-Mac Setup)

You do **not** need a physical Mac computer. This guide explains how to edit code on Windows, push to GitHub, and let Apple Silicon M2 macOS runners compile and test the app in the cloud.

---

## 1. How It Works

```
[Windows PC]
  │  1. Edit Swift files in VS Code / Cursor
  │  2. git commit & git push
  ▼
[GitHub Cloud Repository]
  │  3. GitHub Actions triggers automatically
  ▼
[Cloud Mac Runner (Apple Silicon M2 / macOS 14)]
  │  4. Runs XcodeGen to generate .xcodeproj
  │  5. Runs unit tests on iOS Simulator
  │  6. Compiles WiFiAuditor app + Dynamic Island Widget
  ▼
[Output Artifacts]
  │  7. Download compiled .zip directly from GitHub
  │  8. (Optional) Auto-deploy to Apple TestFlight on your iPhone
```

---

## 2. Pushing Your Code to GitHub from Windows

Open PowerShell or terminal in this folder (`amazing-franklin`):

```powershell
# 1. Add all files to git
git add .

# 2. Commit the codebase
git commit -m "Initial commit: WiFi Auditor iOS app + cloud build pipeline"

# 3. Create a repository on GitHub (e.g. https://github.com/your-username/wifi-auditor)
# Link your local repo to GitHub:
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

---

## 3. Watching the Cloud Build

1. Open your repository on **GitHub.com**.
2. Click the **Actions** tab at the top.
3. You will see the **iOS Cloud Build & Test (macOS)** workflow running.
4. Click into the run to watch the live compilation logs from the cloud Mac.
5. Once complete (~2–3 minutes), scroll to the **Artifacts** section at the bottom of the page and download `WiFiAuditor-iOS-Build.zip`.

---

## 4. Installing on a Physical iPhone (Apple TestFlight)

When you're ready to test directly on your real iPhone without a Mac:

1. Enroll in the [Apple Developer Program](https://developer.apple.com/) ($99/year).
2. Generate an **App Store Connect API Key** in your Apple Developer account (`Users and Access` > `Integrations`).
3. Add these three secrets in your GitHub repository (`Settings` > `Secrets and variables` > `Actions`):
   - `APP_STORE_CONNECT_KEY_ID`
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_PRIVATE_KEY`
4. The workflow will automatically sign the build with Apple's official certificate and upload it straight to **TestFlight**.
5. You open the **TestFlight** app on your iPhone and tap **Install**!

---

## 5. Editing the Code on Windows

You can open this folder in **VS Code** on Windows. Recommended extensions:
- **Swift** (by the Swift Server Work Group) – provides syntax highlighting and autocompletion for Swift files.
- **GitLens** – for easy git management.
