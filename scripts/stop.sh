#!/usr/bin/env bash
# Stop everything (data is kept).  Add --reset to also delete workflows, models and the database.
cd "$(dirname "$0")/.."
if [ "${1:-}" = "--reset" ]; then docker compose --profile cpu --profile gpu-nvidia down -v; echo "Stopped and wiped all data."; else docker compose --profile cpu --profile gpu-nvidia down; echo "Stopped (data kept)."; fi
