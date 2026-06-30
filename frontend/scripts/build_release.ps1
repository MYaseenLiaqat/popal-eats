# Release build script (Windows PowerShell)
# Prerequisites: Android SDK, Flutter, key.properties (optional)

param(
    [string]$ApiBaseUrl = "https://YOUR_API_URL",
    [switch]$SkipBundle
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$defines = @(
    "API_BASE_URL=$ApiBaseUrl"
)

Write-Host "Building release APK..."
flutter build apk --release @(
    foreach ($d in $defines) { "--dart-define=$d" }
)

if (-not $SkipBundle) {
    Write-Host "Building release App Bundle..."
    flutter build appbundle --release @(
        foreach ($d in $defines) { "--dart-define=$d" }
    )
}

Write-Host ""
Write-Host "Outputs:"
Write-Host "  APK: build\app\outputs\flutter-apk\app-release.apk"
if (-not $SkipBundle) {
    Write-Host "  AAB: build\app\outputs\bundle\release\app-release.aab"
}
