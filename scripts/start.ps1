# Start n8n + Ollama on Windows (PowerShell).  Usage: .\scripts\start.ps1 [-Mode cpu|gpu|host]   (default: cpu)
param([ValidateSet("cpu","gpu","host")][string]$Mode = "cpu")
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { Write-Host "Docker is not installed. See README > Prerequisites."; exit 1 }
docker info *> $null
if ($LASTEXITCODE -ne 0) { Write-Host "Docker is not running. Start Docker Desktop first."; exit 1 }

function New-Secret { -join ((1..32) | ForEach-Object { '{0:x2}' -f (Get-Random -Maximum 256) }) }
if (-not (Test-Path .env)) {
  (Get-Content .env.example -Raw) `
    -replace 'change-me-postgres', (New-Secret) `
    -replace 'change-me-encryption-key', (New-Secret) `
    -replace 'change-me-jwt-secret', (New-Secret) | Set-Content .env -NoNewline
  Write-Host "Created .env with random secrets."
}

switch ($Mode) {
  "cpu"  { $profile = "cpu";        $url = "http://ollama:11434" }
  "gpu"  { $profile = "gpu-nvidia"; $url = "http://ollama:11434" }
  "host" { $profile = "";           $url = "http://host.docker.internal:11434" }
}
(Get-Content .env -Raw) -replace '(?m)^COMPOSE_PROFILES=.*$', "COMPOSE_PROFILES=$profile" `
                        -replace '(?m)^OLLAMA_BASE_URL=.*$', "OLLAMA_BASE_URL=$url" | Set-Content .env -NoNewline

Write-Host "Starting (mode: $Mode)..."
docker compose up -d
if ($LASTEXITCODE -ne 0) { exit 1 }

if ($Mode -ne "host") {
  Write-Host "Downloading the AI models (first run only, ~2.3 GB)..."
  do { Start-Sleep 3; $log = docker logs ollama-pull 2>&1 | Out-String } until ($log -match "MODELS READY|Error")
  Write-Host ($log -split "`n" | Select-String "MODELS READY|Error" | Select-Object -Last 1)
} else {
  Write-Host "Host mode: make sure you ran  ollama pull llama3.2  and  ollama pull nomic-embed-text  in Windows."
}

Write-Host -NoNewline "Waiting for n8n"
for ($i = 0; $i -lt 90; $i++) {
  try { Invoke-WebRequest http://localhost:5678/healthz -UseBasicParsing -TimeoutSec 2 *> $null; Write-Host ""; Write-Host "n8n is ready: http://localhost:5678"; Start-Process "http://localhost:5678"; exit 0 } catch { Write-Host -NoNewline "."; Start-Sleep 2 }
}
Write-Host ""; Write-Host "n8n did not answer yet. Check: docker compose logs n8n"; exit 1
