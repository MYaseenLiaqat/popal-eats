# Popal Eats - Play Store build preparation (Windows)
# Run from frontend folder:  .\scripts\prepare_play_store.ps1 -ApiBaseUrl https://YOUR_API

param(
    [Parameter(Mandatory = $true)]
    [string]$ApiBaseUrl,
    [switch]$SkipBundle,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"
$frontend = Resolve-Path (Join-Path $PSScriptRoot "..")
$android = Join-Path $frontend "android"
$keyProps = Join-Path $android "key.properties"
$definesExample = Join-Path $frontend "dart_defines.production.example.json"
$definesProd = Join-Path $frontend "dart_defines.production.json"

Write-Host "=== Popal Eats Play Store prep ===" -ForegroundColor Cyan
Write-Host "Frontend: $frontend"
Write-Host "API URL:  $ApiBaseUrl"
Write-Host ""

$issues = @()

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    $issues += "Flutter SDK not in PATH"
}

if (-not (Test-Path $keyProps)) {
    $issues += "Missing android/key.properties (copy key.properties.example and create upload-keystore.jks)"
} else {
    Write-Host "[OK] key.properties found" -ForegroundColor Green
}

$gradle = Join-Path $android "app\build.gradle.kts"
$gradleText = Get-Content $gradle -Raw
if ($gradleText -match 'com\.example\.') {
    $issues += "applicationId still com.example.* - change before Play Store (see docs/PLAY_STORE_HANDOFF.md)"
}

if ($ApiBaseUrl -notmatch '^https://') {
    $issues += "API_BASE_URL should be HTTPS for production"
}

if ($issues.Count -gt 0) {
    Write-Host "Issues to resolve:" -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host "  - $_" }
    Write-Host ""
}

if ($CheckOnly) {
    if ($issues.Count -eq 0) {
        Write-Host "All checks passed." -ForegroundColor Green
    }
    exit $(if ($issues.Count -eq 0) { 0 } else { 1 })
}

if (-not (Test-Path $definesProd)) {
    Write-Host "Creating dart_defines.production.json from example..." -ForegroundColor Yellow
    Copy-Item $definesExample $definesProd
    $json = Get-Content $definesProd -Raw | ConvertFrom-Json
    $json.API_BASE_URL = $ApiBaseUrl
    $json | ConvertTo-Json | Set-Content $definesProd -Encoding UTF8
}

Set-Location $frontend
flutter pub get

Write-Host "Building release app bundle..." -ForegroundColor Cyan
flutter build appbundle --release --dart-define=API_BASE_URL=$ApiBaseUrl

if (-not $SkipBundle) {
    $aab = Join-Path $frontend "build\app\outputs\bundle\release\app-release.aab"
    if (Test-Path $aab) {
        $sizeMb = [math]::Round((Get-Item $aab).Length / 1MB, 1)
        Write-Host ""
        Write-Host "SUCCESS - send this file to your Play Console manager:" -ForegroundColor Green
        Write-Host "  $aab"
        Write-Host "  Size: $sizeMb MB"
        Write-Host ""
        Write-Host "Also send securely (if they need it):" -ForegroundColor Yellow
        Write-Host "  - upload-keystore.jks and passwords"
        Write-Host "  - Package name from build.gradle.kts"
        Write-Host "  - Privacy policy URL"
    }
}
