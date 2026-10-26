<#
.SYNOPSIS
    Interactive TestFlight Secrets Setup Wizard for Windows.
    Inspired by Matt Pocock's `wizard` skill.
.DESCRIPTION
    Scans the current directory for Apple Developer credentials (.p12, .mobileprovision, .p8),
    validates them, generates Base64 strings, and either uploads them via GitHub CLI (`gh`)
    or copies them sequentially to your Windows clipboard for easy web pasting.
#>

param(
    [string]$Repo = "BaldyKopite/wifi-auditor"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   Wi-Fi Auditor — TestFlight Credentials Setup Wizard    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check for expected files in current working directory
$p12Files = Get-ChildItem -Filter "*.p12"
$appProvisionFiles = Get-ChildItem -Filter "*AppStore*.mobileprovision" | Where-Object { $_.Name -notmatch "Widget" }
$widgetProvisionFiles = Get-ChildItem -Filter "*Widget*.mobileprovision"
$p8Files = Get-ChildItem -Filter "AuthKey_*.p8"

Write-Host "🔍 Scanning for Apple Developer files in current directory..." -ForegroundColor Yellow

$certFile = $p12Files | Select-Object -First 1
$appProf = $appProvisionFiles | Select-Object -First 1
$widgetProf = $widgetProvisionFiles | Select-Object -First 1
$p8File = $p8Files | Select-Object -First 1

if ($certFile) {
    Write-Host "  ✅ Certificate found: $($certFile.Name)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Missing: certificate.p12 (Export Apple Distribution certificate from Keychain)" -ForegroundColor Yellow
}

if ($appProf) {
    Write-Host "  ✅ App Provisioning Profile found: $($appProf.Name)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Missing: WiFiAuditor_AppStore.mobileprovision" -ForegroundColor Yellow
}

if ($widgetProf) {
    Write-Host "  ✅ Widget Provisioning Profile found: $($widgetProf.Name)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Missing: WiFiAuditorWidget_AppStore.mobileprovision" -ForegroundColor Yellow
}

if ($p8File) {
    Write-Host "  ✅ App Store Connect API Key found: $($p8File.Name)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Missing: AuthKey_XXXXXXXXXX.p8" -ForegroundColor Yellow
}

Write-Host ""

# 2. Check for GitHub CLI
$hasGH = $null -ne (Get-Command "gh" -ErrorAction SilentlyContinue)

if ($hasGH) {
    Write-Host "💡 GitHub CLI ('gh') is detected on your system!" -ForegroundColor Cyan
    $uploadDirectly = Read-Host "Would you like to automatically upload detected secrets to $Repo via GitHub CLI? (Y/N)"
} else {
    $uploadDirectly = "N"
}

# 3. Helper to process and upload/copy secret
function Process-Secret {
    param(
        [string]$SecretName,
        [string]$Description,
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        Write-Host "  ⏭️  Skipping $SecretName (no value provided)" -ForegroundColor DarkGray
        return
    }

    if ($uploadDirectly -eq "Y" -or $uploadDirectly -eq "y") {
        Write-Host "  Uploading $SecretName to GitHub..." -NoNewline
        $Value | gh secret set $SecretName --repo $Repo
        Write-Host " Done! ✅" -ForegroundColor Green
    } else {
        Set-Clipboard -Value $Value
        Write-Host "📋 Copied '$SecretName' ($Description) to your clipboard!" -ForegroundColor Green
        Write-Host "   👉 Paste into GitHub: Settings > Secrets and variables > Actions" -ForegroundColor DarkCyan
        Read-Host "   Press [Enter] when saved to move to next secret..."
    }
}

# 4. Interactive Secret Generation Loop
Write-Host "----------------------------------------------------------" -ForegroundColor Gray
Write-Host "Step 1: Apple Distribution Certificate (.p12)" -ForegroundColor White
if ($certFile) {
    $p12Base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($certFile.FullName))
    Process-Secret -SecretName "APPLE_CERTIFICATE_BASE64" -Description "Certificate Base64" -Value $p12Base64

    $p12Pass = Read-Host "Enter the password you used when exporting $($certFile.Name)"
    if (![string]::IsNullOrWhiteSpace($p12Pass)) {
        Process-Secret -SecretName "APPLE_CERTIFICATE_PASSWORD" -Description "Certificate Password" -Value $p12Pass
    }
}

Write-Host "----------------------------------------------------------" -ForegroundColor Gray
Write-Host "Step 2: Provisioning Profiles" -ForegroundColor White
if ($appProf) {
    $appBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($appProf.FullName))
    Process-Secret -SecretName "APPLE_APP_PROFILE_BASE64" -Description "App Profile Base64" -Value $appBase64
}

if ($widgetProf) {
    $widgetBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($widgetProf.FullName))
    Process-Secret -SecretName "APPLE_WIDGET_PROFILE_BASE64" -Description "Widget Profile Base64" -Value $widgetBase64
}

Write-Host "----------------------------------------------------------" -ForegroundColor Gray
Write-Host "Step 3: App Store Connect API Credentials" -ForegroundColor White
if ($p8File) {
    $p8Base64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($p8File.FullName))
    Process-Secret -SecretName "APP_STORE_CONNECT_PRIVATE_KEY_BASE64" -Description "API Key Base64" -Value $p8Base64
}

$keyId = Read-Host "Enter your 10-character App Store Connect Key ID (e.g. 2X9R4HXF34)"
if (![string]::IsNullOrWhiteSpace($keyId)) {
    Process-Secret -SecretName "APP_STORE_CONNECT_KEY_ID" -Description "Key ID" -Value $keyId.Trim()
}

$issuerId = Read-Host "Enter your App Store Connect Issuer UUID (e.g. 69a6de70-xxxx-xxxx-xxxx-xxxxxxxxxxxx)"
if (![string]::IsNullOrWhiteSpace($issuerId)) {
    Process-Secret -SecretName "APP_STORE_CONNECT_ISSUER_ID" -Description "Issuer UUID" -Value $issuerId.Trim()
}

Write-Host "==========================================================" -ForegroundColor Green
Write-Host "🎉 Setup Wizard Complete! All credentials processed." -ForegroundColor Green
Write-Host "You are now ready to trigger: Deploy to Apple TestFlight" -ForegroundColor White
Write-Host "==========================================================" -ForegroundColor Green
