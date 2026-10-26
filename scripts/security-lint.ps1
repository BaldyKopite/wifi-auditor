<#
.SYNOPSIS
    Automated Security, Compliance & Secrets Policy Linter.
    Inspired by AgentShield from affaan-m/ECC.
.DESCRIPTION
    Scans the repository to prevent accidental credential leaks, verify Apple Privacy
    Manifest compliance, and enforce architectural invariants.
#>

$ErrorCount = 0

Write-Host "🛡️  Running Security & Architecture Linter (AgentShield Policy)..." -ForegroundColor Cyan
Write-Host ""

# 1. Secret & Key Leak Detection
Write-Host "1. Scanning for committed certificates, keys, and provisioning profiles..." -NoNewline
$forbiddenExtensions = @("*.p12", "*.p8", "*.mobileprovision", "*.pem", "*.key", "id_rsa*")
$leakedFiles = @()

foreach ($ext in $forbiddenExtensions) {
    $found = git ls-files $ext
    if ($found) {
        $leakedFiles += $found
    }
}

if ($leakedFiles.Count -gt 0) {
    Write-Host " FAILED ❌" -ForegroundColor Red
    Write-Host "  🚨 CRITICAL: The following private credential files are tracked by Git:" -ForegroundColor Red
    $leakedFiles | ForEach-Object { Write-Host "     - $_" -ForegroundColor Red }
    $ErrorCount++
} else {
    Write-Host " PASSED ✅" -ForegroundColor Green
}

# 2. Privacy Manifest Validation
Write-Host "2. Verifying Apple Privacy Manifest (PrivacyInfo.xcprivacy)..." -NoNewline
$privacyPath = "WiFiAuditor/WiFiAuditor/Resources/PrivacyInfo.xcprivacy"
if (Test-Path $privacyPath) {
    $content = Get-Content $privacyPath -Raw
    if ($content -match "NSPrivacyAccessedAPICategoryUserDefaults" -and $content -match "NSPrivacyTracking") {
        Write-Host " PASSED ✅" -ForegroundColor Green
    } else {
        Write-Host " WARNING ⚠️" -ForegroundColor Yellow
        Write-Host "  Privacy manifest missing standard category keys." -ForegroundColor Yellow
    }
} else {
    Write-Host " FAILED ❌" -ForegroundColor Red
    Write-Host "  Missing required PrivacyInfo.xcprivacy at $privacyPath" -ForegroundColor Red
    $ErrorCount++
}

# 3. Minimum iOS Deployment Target Check
Write-Host "3. Verifying iOS 16.2+ Deployment Target in project.yml..." -NoNewline
if (Test-Path "project.yml") {
    $projContent = Get-Content "project.yml" -Raw
    if ($projContent -match "deploymentTarget:\s*iOS:\s*`"16\.2`"") {
        Write-Host " PASSED ✅" -ForegroundColor Green
    } else {
        Write-Host " WARNING ⚠️" -ForegroundColor Yellow
        Write-Host "  Deployment target may not match iOS 16.2." -ForegroundColor Yellow
    }
} else {
    Write-Host " FAILED ❌" -ForegroundColor Red
    $ErrorCount++
}

# 4. Insecure HTTP Hardcoding in Swift
Write-Host "4. Scanning Swift source code for unapproved plaintext HTTP URLs..." -NoNewline
$swiftFiles = Get-ChildItem -Recurse -Filter "*.swift"
$httpLeaks = @()

foreach ($file in $swiftFiles) {
    # Allow captive portal detection probes (captive.apple.com / generate_204 requires HTTP)
    $lines = Get-Content $file.FullName | Select-String -Pattern "http://" | Where-Object {
        $_ -notmatch "captive\.apple\.com" -and
        $_ -notmatch "connectivitycheck\.gstatic\.com" -and
        $_ -notmatch "login\.hotel\.local" -and
        $_ -notmatch "///"
    }
    if ($lines) {
        $httpLeaks += "$($file.Name): $($lines.Line.Trim())"
    }
}

if ($httpLeaks.Count -gt 0) {
    Write-Host " WARNING ⚠️" -ForegroundColor Yellow
    $httpLeaks | ForEach-Object { Write-Host "     - $_" -ForegroundColor Yellow }
} else {
    Write-Host " PASSED ✅" -ForegroundColor Green
}

Write-Host ""
if ($ErrorCount -eq 0) {
    Write-Host "🎉 All AgentShield security and compliance policy checks passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ $ErrorCount policy check(s) failed. Please resolve before committing." -ForegroundColor Red
    exit 1
}
