#!/usr/bin/env sh
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

case "${1:-}" in
  dev)
    cp .env.dev .env
    echo "Using .env.dev → .env"
    ;;
  prod)
    cp .env.prod .env
    echo "Using .env.prod → .env"
    echo "Review .env and update secrets before deploying."
    ;;
  *)
    echo "Usage: ./scripts/env-use.sh dev|prod"
    echo "  Copies .env.dev or .env.prod to .env"
    exit 1
    ;;
esac
