# Install / refresh Flutter packages for frontend.
# Usage (from anywhere): .\scripts\flutter_pub_get.ps1

Set-Location (Join-Path (Split-Path $PSScriptRoot -Parent) "frontend")
& "$PSScriptRoot\flutter.ps1" pub get
exit $LASTEXITCODE
