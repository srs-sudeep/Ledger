#!/usr/bin/env bash
# Deploy Lyari prod stack (API + web). Intended for the home server or CI.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

COMPOSE=(docker compose -f docker-compose.prod.yml)

if [[ ! -f .env ]]; then
  echo "Missing .env — copy from .env.prod and set secrets first." >&2
  exit 1
fi

# Load WEB_PORT for health check (ignore comments / blank lines)
WEB_PORT=80
while IFS= read -r line || [[ -n "$line" ]]; do
  case "$line" in
    WEB_PORT=*) WEB_PORT="${line#WEB_PORT=}" ;;
  esac
done < .env

mkdir -p artifacts/apk

echo "==> Building api + web"
"${COMPOSE[@]}" build api web

echo "==> Starting db (if needed) + api + web"
"${COMPOSE[@]}" up -d db
"${COMPOSE[@]}" up -d api web

echo "==> Waiting for health"
for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${WEB_PORT}/api/health" >/dev/null 2>&1; then
    echo "Healthy: /api/health"
    exit 0
  fi
  sleep 2
done

echo "Health check failed after ~60s" >&2
"${COMPOSE[@]}" ps
exit 1
