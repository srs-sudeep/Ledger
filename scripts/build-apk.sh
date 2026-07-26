#!/usr/bin/env bash
# Build release APK and publish to artifacts/apk for nginx /downloads/
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

COMPOSE=(docker compose -f docker-compose.prod.yml)

if [[ ! -f .env ]]; then
  echo "Missing .env — set API_BASE_URL before building the APK." >&2
  exit 1
fi

API_BASE_URL=""
while IFS= read -r line || [[ -n "$line" ]]; do
  case "$line" in
    API_BASE_URL=*) API_BASE_URL="${line#API_BASE_URL=}" ;;
  esac
done < .env

mkdir -p artifacts/apk mobile/build/app/outputs

echo "==> Building APK (API_BASE_URL=${API_BASE_URL:-unset})"
"${COMPOSE[@]}" --profile mobile-build build mobile-build
"${COMPOSE[@]}" --profile mobile-build run --rm mobile-build

SRC="mobile/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$SRC" ]]; then
  echo "APK not found at $SRC" >&2
  find mobile/build -name '*.apk' 2>/dev/null || true
  exit 1
fi

cp -f "$SRC" artifacts/apk/lyari.apk
cp -f "$SRC" artifacts/apk/app-release.apk
echo "Published: artifacts/apk/lyari.apk ($(du -h artifacts/apk/lyari.apk | cut -f1))"
