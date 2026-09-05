#!/usr/bin/env bash
# Wipe Postgres volume and re-seed demo data (prod or dev compose).
# Usage: ./scripts/reset-and-seed.sh [prod|dev]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MODE="${1:-prod}"
if [[ "$MODE" == "dev" ]]; then
  COMPOSE=(docker compose -f docker-compose.dev.yml)
else
  COMPOSE=(docker compose -f docker-compose.prod.yml)
fi

echo "WARNING: This deletes the Ledger database volume and re-seeds demo data."
"${COMPOSE[@]}" down
# Remove only the Postgres volume for this project (keep Portainer data)
if [[ "$MODE" == "dev" ]]; then
  docker volume rm ledger_pgdata_dev 2>/dev/null || true
else
  docker volume rm ledger_pgdata 2>/dev/null || true
fi

"${COMPOSE[@]}" up -d --build db api web
echo "Waiting for API…"
for i in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1${WEB_PORT:+:${WEB_PORT}}/api/health" >/dev/null 2>&1 \
    || curl -fsS "http://127.0.0.1/api/health" >/dev/null 2>&1 \
    || curl -fsS "http://127.0.0.1:8000/api/health" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

"${COMPOSE[@]}" exec -T api python -m app.seed --reset
echo "Done."
