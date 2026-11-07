#!/usr/bin/env bash
# Quick health check: containers, Ollama models, a test answer from the local model, n8n.
cd "$(dirname "$0")/.."
echo "== containers"; docker compose ps --format "table {{.Name}}\t{{.State}}\t{{.Status}}"
echo "== ollama models"; curl -fsS http://localhost:11434/api/tags | grep -o '"name":"[^"]*"' || echo "Ollama not reachable on :11434"
echo "== test answer"; curl -fsS http://localhost:11434/api/generate -d '{"model":"llama3.2","prompt":"Say hello in five words.","stream":false}' | grep -o '"response":"[^"]*"' || echo "model test failed"
echo "== n8n"; curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:5678/healthz
