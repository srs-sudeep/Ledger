#!/usr/bin/env bash
# One-time install of the GitHub Actions self-hosted runner on hp.
# Run on the server as user srs (with docker group). Requires RUNNER_TOKEN.
set -euo pipefail

RUNNER_DIR="${RUNNER_DIR:-$HOME/actions-runner}"
REPO="${REPO:-srs-sudeep/Lyari}"
LABELS="${LABELS:-self-hosted,linux,lyari}"

if [[ -z "${RUNNER_TOKEN:-}" ]]; then
  echo "Set RUNNER_TOKEN to a registration token from:" >&2
  echo "  gh api -X POST repos/${REPO}/actions/runners/registration-token --jq .token" >&2
  exit 1
fi

mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

if [[ ! -f ./config.sh ]]; then
  curl -fsSL -o actions-runner-linux-x64.tar.gz \
    https://github.com/actions/runner/releases/download/v2.329.0/actions-runner-linux-x64-2.329.0.tar.gz
  tar xzf ./actions-runner-linux-x64.tar.gz
  rm -f ./actions-runner-linux-x64.tar.gz
fi

if [[ ! -f .runner ]]; then
  ./config.sh --unattended \
    --url "https://github.com/${REPO}" \
    --token "$RUNNER_TOKEN" \
    --labels "$LABELS" \
    --name "${RUNNER_NAME:-hp-lyari}" \
    --work _work \
    --replace
fi

# Install and start systemd user service when possible; else use svc.sh
if [[ -x ./svc.sh ]]; then
  sudo ./svc.sh install srs || true
  sudo ./svc.sh start || ./run.sh &
else
  nohup ./run.sh >/tmp/actions-runner.log 2>&1 &
fi

echo "Runner installed in $RUNNER_DIR"
