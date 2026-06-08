# Run Flutter app in Chrome.
# From project root: .\scripts\run_web.ps1
# From frontend/:    .\run_web.ps1  OR  ..\scripts\run_web.ps1

$ProjectRoot = Split-Path $PSScriptRoot -Parent
$FrontendDir = Join-Path $ProjectRoot "frontend"

if (-not (Test-Path (Join-Path $FrontendDir "pubspec.yaml"))) {
    Write-Error "frontend/pubspec.yaml not found. Run from project root: .\scripts\run_web.ps1"
    exit 1
}

Set-Location $FrontendDir
& "$PSScriptRoot\flutter.ps1" run -d chrome
exit $LASTEXITCODE