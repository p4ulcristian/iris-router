#!/usr/bin/env bash
set -euo pipefail

VPS="root@10.99.0.1"
KEY="$HOME/.ssh/vultr_iris_router_ed25519"
SSH="ssh -i $KEY"
SCP="scp -i $KEY"

echo "→ Copying Caddyfile to VPS..."
$SCP vps/Caddyfile "$VPS:/etc/caddy/Caddyfile"

echo "→ Reloading Caddy on VPS..."
$SSH "$VPS" "caddy reload --config /etc/caddy/Caddyfile --force"

echo "✓ Done"
