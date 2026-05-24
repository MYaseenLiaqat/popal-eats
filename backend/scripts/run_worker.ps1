# Start RQ worker for review AI pipeline
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

if (-not (Test-Path ".\venv\Scripts\python.exe")) {
    Write-Error "Run from backend with venv: pip install -r requirements.txt"
}

$env:PYTHONPATH = "."
Write-Host "RQ worker for queue: popal_eats"
Write-Host "Requires Redis at REDIS_URL in .env"
.\venv\Scripts\rq.exe worker popal_eats --url redis://127.0.0.1:6379/0
