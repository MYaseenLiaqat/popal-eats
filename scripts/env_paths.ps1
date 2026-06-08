# Popal Eats dev paths — dot-source from scripts or: . .\scripts\env_paths.ps1

$ErrorActionPreference = "Stop"

# Override with your install location if different.
$script:FlutterRoot = if ($env:FLUTTER_ROOT) {
    $env:FLUTTER_ROOT
} elseif (Test-Path "C:\Users\user\flutter") {
    "C:\Users\user\flutter"
} else {
    $null
}

if ($script:FlutterRoot) {
    $flutterBin = Join-Path $script:FlutterRoot "bin"
    if (Test-Path $flutterBin) {
        if ($env:Path -notlike "*$flutterBin*") {
            $env:Path = "$flutterBin;$env:Path"
        }
        $script:FlutterExe = Join-Path $flutterBin "flutter.bat"
    }
}

$script:ProjectRoot = Split-Path $PSScriptRoot -Parent
$script:FrontendDir = Join-Path $ProjectRoot "frontend"
$script:BackendDir = Join-Path $ProjectRoot "backend"
