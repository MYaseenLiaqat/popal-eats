# Start FastAPI backend. Usage: .\scripts\start_backend.ps1
Set-Location (Join-Path (Split-Path $PSScriptRoot -Parent) "backend")

if (-not (Test-Path ".\venv\Scripts\python.exe")) {
    Write-Error "Backend venv not found. Run: cd backend; python -m venv venv; .\venv\Scripts\activate; pip install -r requirements.txt"
    exit 1
}

Write-Host "Starting backend at http://127.0.0.1:8000 ..."
& ".\venv\Scripts\python.exe" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
