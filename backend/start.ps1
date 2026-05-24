# Start Popal Eats API (always uses backend venv)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path ".\venv\Scripts\python.exe")) {
    Write-Host "Creating virtual environment..."
    python -m venv venv
    .\venv\Scripts\pip.exe install -r requirements.txt
}

Write-Host "Starting server at http://127.0.0.1:8000"
Write-Host "Swagger docs: http://127.0.0.1:8000/docs"
.\venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
