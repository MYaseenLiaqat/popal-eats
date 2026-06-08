# Run Flutter with SDK on PATH. Usage: .\scripts\flutter.ps1 pub get
# From frontend/: ..\scripts\flutter.ps1 run -d chrome

. "$PSScriptRoot\env_paths.ps1"

if (-not $FlutterExe -or -not (Test-Path $FlutterExe)) {
    Write-Error @"
Flutter SDK not found.
Install Flutter or set FLUTTER_ROOT, e.g.:
  `$env:FLUTTER_ROOT = 'C:\Users\user\flutter'
Expected: C:\Users\user\flutter\bin\flutter.bat
"@
    exit 1
}

& $FlutterExe @args
exit $LASTEXITCODE
