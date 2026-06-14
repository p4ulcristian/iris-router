#!/usr/bin/env bash
set -euo pipefail

VPS="root@10.99.0.1"
KEY="$HOME/.ssh/vultr_iris_router_ed25519"
SSH="ssh -i $KEY"
SCP="scp -i $KEY"

# Cloudflare zone for irisdoes.work and the public VPS IP every subdomain points at.
ZONE_ID="0860e721335a49cf6afc2b85e8cc29b9"
PUBLIC_IP="136.244.88.99"

echo "→ Copying Caddyfile to VPS..."
$SCP vps/Caddyfile "$VPS:/etc/caddy/Caddyfile"

echo "→ Ensuring Cloudflare DNS records for every subdomain in the Caddyfile..."
# Runs on the VPS so it can read the API token from /etc/caddy/cf.env.
# For each <name>.irisdoes.work site block, create a DNS-only A record if missing.
$SSH "$VPS" ZONE_ID="$ZONE_ID" PUBLIC_IP="$PUBLIC_IP" bash -s <<'REMOTE'
set -euo pipefail
source /etc/caddy/cf.env  # provides CLOUDFLARE_API_TOKEN
api="https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records"

# Pull site addresses like "vitals.irisdoes.work {" from the Caddyfile.
hosts=$(grep -oE '^[A-Za-z0-9*_-]+\.irisdoes\.work' /etc/caddy/Caddyfile | sort -u)

for h in $hosts; do
  # Skip the wildcard catch-all — DNS is per-subdomain here, not wildcard.
  [ "$h" = "*.irisdoes.work" ] && continue

  existing=$(curl -s -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    "${api}?type=A&name=${h}")
  if echo "$existing" | grep -q "\"name\":\"${h}\""; then
    echo "  = ${h} (record exists)"
    continue
  fi

  resp=$(curl -s -X POST -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
    -H "Content-Type: application/json" \
    "${api}" \
    --data "{\"type\":\"A\",\"name\":\"${h}\",\"content\":\"${PUBLIC_IP}\",\"ttl\":1,\"proxied\":false}")
  if echo "$resp" | grep -q '"success":true'; then
    echo "  + ${h} (created → ${PUBLIC_IP}, DNS-only)"
  else
    echo "  ! ${h} FAILED: $resp"
  fi
done
REMOTE

echo "→ Reloading Caddy on VPS..."
$SSH "$VPS" "caddy reload --config /etc/caddy/Caddyfile --force"

echo "✓ Done"
