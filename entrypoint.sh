#!/bin/sh
set -eu

: "${RATHOLE_TOKEN:?RATHOLE_TOKEN env var is required}"
: "${PORT:?PORT env var is required (Railway injects this)}"
: "${CONTROL_PORT:?CONTROL_PORT env var is required (e.g. 2333)}"
: "${SERVICE_NAME:?SERVICE_NAME env var is required (e.g. web)}"

export RATHOLE_TOKEN PORT CONTROL_PORT SERVICE_NAME

OUT=/tmp/server.toml
envsubst '${RATHOLE_TOKEN} ${PORT} ${CONTROL_PORT} ${SERVICE_NAME}' \
  < /etc/rathole/server.toml.tmpl > "$OUT"

# Sanity check: no unexpanded sentinels left.
if grep -q '\${' "$OUT"; then
  echo "entrypoint: unexpanded variables in $OUT" >&2
  exit 1
fi

# When invoked with arguments (e.g. for render-only smoke tests), run those instead.
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

exec rathole "$OUT"
