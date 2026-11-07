# Quick health check (PowerShell): containers, Ollama models, a test answer, n8n.
Set-Location (Join-Path $PSScriptRoot "..")
Write-Host "== containers"; docker compose ps
Write-Host "== ollama models"
try { (Invoke-RestMethod http://localhost:11434/api/tags).models.name } catch { Write-Host "Ollama not reachable on :11434" }
Write-Host "== test answer"
try { (Invoke-RestMethod http://localhost:11434/api/generate -Method Post -Body '{"model":"llama3.2","prompt":"Say hello in five words.","stream":false}').response } catch { Write-Host "model test failed" }
Write-Host "== n8n"
try { (Invoke-WebRequest http://localhost:5678/healthz -UseBasicParsing).StatusCode } catch { Write-Host "n8n not reachable" }
