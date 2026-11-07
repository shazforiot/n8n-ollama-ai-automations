# Stop everything (data is kept).  .\scripts\stop.ps1 -Reset  also deletes workflows, models and the database.
param([switch]$Reset)
Set-Location (Join-Path $PSScriptRoot "..")
if ($Reset) { docker compose --profile cpu --profile gpu-nvidia down -v; Write-Host "Stopped and wiped all data." }
else { docker compose --profile cpu --profile gpu-nvidia down; Write-Host "Stopped (data kept)." }
