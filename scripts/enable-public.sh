#!/usr/bin/env bash
# Expose Ledger on the public internet via Tailscale Funnel (stable URL).
# Prerequisite: enable Funnel once in the admin console:
#   https://login.tailscale.com/f/funnel?node=na8P57XNyw11CNTRL
set -euo pipefail

printf '%s\n' "${SUDO_PASSWORD:-}" | sudo -S true 2>/dev/null || sudo -v

# Stop ephemeral Cloudflare quick tunnel if running
sudo systemctl stop cloudflared-ledger.service 2>/dev/null || true
pkill -f 'cloudflared tunnel --url' 2>/dev/null || true

sudo tailscale funnel --bg 80
echo
tailscale funnel status
echo
echo "Public web:  https://hp.tail936c6d.ts.net"
echo "API docs:    https://hp.tail936c6d.ts.net/docs"
echo "Android APK: https://hp.tail936c6d.ts.net/downloads/ledger.apk"
