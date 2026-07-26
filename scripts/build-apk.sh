#!/usr/bin/env bash
# Build release APK and publish to artifacts/apk for nginx /downloads/
# Uses capped Docker resources so the self-hosted runner stays responsive.
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

export GRADLE_OPTS="${GRADLE_OPTS:--Xmx2g -XX:MaxMetaspaceSize=512m -Dorg.gradle.daemon=false -Dorg.gradle.workers.max=2}"
export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:--Xmx2g}"

echo "==> Building APK image (API_BASE_URL=${API_BASE_URL:-unset})"
"${COMPOSE[@]}" --profile mobile-build build mobile-build

echo "==> Running APK build (outputs volume mounted)"
# Prefer docker run with resource caps; fall back to compose run
IMAGE=$("${COMPOSE[@]}" --profile mobile-build images -q mobile-build | head -1)
if [[ -z "$IMAGE" ]]; then
  IMAGE=lyari-mobile-build
fi

if docker run --help 2>&1 | grep -q -- '--memory'; then
  docker run --rm \
    --memory=6g \
    --cpus=3 \
    -e API_BASE_URL="${API_BASE_URL}" \
    -e GRADLE_OPTS \
    -e JAVA_TOOL_OPTIONS \
    -v "$(pwd)/mobile/build/app/outputs:/app/build/app/outputs" \
    "$IMAGE"
else
  "${COMPOSE[@]}" --profile mobile-build run --rm \
    -e API_BASE_URL="${API_BASE_URL}" \
    -e GRADLE_OPTS \
    -e JAVA_TOOL_OPTIONS \
    mobile-build
fi

SRC="mobile/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$SRC" ]]; then
  echo "APK not found at $SRC" >&2
  find mobile/build -name '*.apk' 2>/dev/null || true
  exit 1
fi

cp -f "$SRC" artifacts/apk/ledger.apk
cp -f "$SRC" artifacts/apk/app-release.apk
# Keep legacy filename as a copy for old links
cp -f "$SRC" artifacts/apk/lyari.apk
echo "Published: artifacts/apk/ledger.apk ($(du -h artifacts/apk/ledger.apk | cut -f1))"
