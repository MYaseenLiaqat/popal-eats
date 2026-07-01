# Build Flutter web for admin dashboard and prepare Vercel deploy folder.
# Run from frontend:  .\scripts\deploy_admin_web.ps1
#
# After this script finishes, deploy:
#   cd build\web
#   vercel --prod

param(
    [string]$ApiBaseUrl = "https://popal-eats-production.up.railway.app",
    [switch]$SkipBuild,
    [switch]$CreateZip
)

$ErrorActionPreference = "Stop"
$frontend = Resolve-Path (Join-Path $PSScriptRoot "..")
$webOut = Join-Path $frontend "build\web"
$vercelJson = Join-Path $frontend "vercel.json"

Write-Host "=== Popal Eats admin web build ===" -ForegroundColor Cyan
Write-Host "Frontend: $frontend"
Write-Host "API URL:  $ApiBaseUrl"
Write-Host ""

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Flutter not in PATH." -ForegroundColor Red
    exit 1
}

Set-Location $frontend
flutter pub get

if (-not $SkipBuild) {
    Write-Host "Building Flutter web (release)..." -ForegroundColor Cyan
    flutter build web --release --dart-define=API_BASE_URL=$ApiBaseUrl
}

if (-not (Test-Path $webOut)) {
    Write-Host "ERROR: build\web not found. Build may have failed." -ForegroundColor Red
    exit 1
}

Copy-Item $vercelJson (Join-Path $webOut "vercel.json") -Force

$zipPath = Join-Path $frontend "build\popal-eats-admin-web.zip"
if ($CreateZip) {
    if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
    Compress-Archive -Path (Join-Path $webOut "*") -DestinationPath $zipPath
    Write-Host "Zip for upload: $zipPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Build ready at: $webOut" -ForegroundColor Green
Write-Host ""
Write-Host "Upload via Vercel website (no CLI):" -ForegroundColor Yellow
Write-Host "  1. Open https://vercel.com/drop"
Write-Host "  2. Drag the folder build\web (or the .zip if you used -CreateZip)"
Write-Host "  3. Project name: popal-eats-admin → Deploy"
Write-Host "  4. Copy the live URL → add it to Railway CORS_ORIGINS"
Write-Host ""
Write-Host "See docs/ADMIN_WEB_VERCEL.md for full steps."
