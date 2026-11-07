#!/usr/bin/env bash
# Start n8n + Ollama.  Usage: ./scripts/start.sh [cpu|gpu|host]   (default: cpu)
set -euo pipefail
cd "$(dirname "$0")/.."
MODE="${1:-cpu}"

command -v docker >/dev/null || { echo "Docker is not installed. See README > Prerequisites."; exit 1; }
docker info >/dev/null 2>&1 || { echo "Docker is not running. Start Docker Desktop (or: sudo service docker start)."; exit 1; }

if [ ! -f .env ]; then
  cp .env.example .env
  rnd() { head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n'; }
  sed -i.bak -e "s/change-me-postgres/$(rnd)/" -e "s/change-me-encryption-key/$(rnd)/" -e "s/change-me-jwt-secret/$(rnd)/" .env && rm -f .env.bak
  echo "Created .env with random secrets."
fi

case "$MODE" in
  cpu)  PROFILE=cpu;        URL=http://ollama:11434 ;;
  gpu)  PROFILE=gpu-nvidia; URL=http://ollama:11434 ;;
  host) PROFILE=;           URL=http://host.docker.internal:11434 ;;
  *) echo "Unknown mode '$MODE' (use cpu, gpu or host)"; exit 1 ;;
esac
sed -i.bak -e "s#^COMPOSE_PROFILES=.*#COMPOSE_PROFILES=${PROFILE}#" -e "s#^OLLAMA_BASE_URL=.*#OLLAMA_BASE_URL=${URL}#" .env && rm -f .env.bak

echo "Starting (mode: $MODE)..."
docker compose up -d

if [ "$MODE" != "host" ]; then
  echo "Downloading the AI models (first run only, ~2.3 GB)..."
  docker logs -f ollama-pull 2>&1 | sed '/MODELS READY/q' | grep -E "Pulling|success|MODELS READY|error" || true
else
  echo "Host mode: make sure you ran  ollama pull llama3.2  and  ollama pull nomic-embed-text  on this computer."
fi

printf "Waiting for n8n"
for i in $(seq 1 90); do
  if curl -fsS http://localhost:5678/healthz >/dev/null 2>&1; then echo; echo "n8n is ready: http://localhost:5678"; exit 0; fi
  printf "."; sleep 2
done
echo; echo "n8n did not answer yet. Check: docker compose logs n8n"; exit 1
