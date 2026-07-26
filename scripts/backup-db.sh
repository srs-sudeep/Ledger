#!/usr/bin/env bash
# Backup Ledger Postgres volume data via docker compose.
# Usage: ./scripts/backup-db.sh [dev|prod]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

MODE="${1:-dev}"
COMPOSE="docker-compose.dev.yml"
SERVICE="db"
if [[ "$MODE" == "prod" ]]; then
  COMPOSE="docker-compose.prod.yml"
fi

OUT_DIR="$ROOT/backups"
mkdir -p "$OUT_DIR"
STAMP="$(date +%Y%m%d-%H%M%S)"
FILE="$OUT_DIR/ledger-$STAMP.sql.gz"

# shellcheck disable=SC1091
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1090
  source .env
  set +a
fi

USER_NAME="${POSTGRES_USER:-ledger}"
DB_NAME="${POSTGRES_DB:-ledger}"

echo "Backing up $DB_NAME → $FILE"
docker compose -f "$COMPOSE" exec -T "$SERVICE" \
  pg_dump -U "$USER_NAME" "$DB_NAME" | gzip > "$FILE"
echo "Done: $FILE"
