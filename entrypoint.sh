#!/bin/bash
set -euo pipefail

WARP_LOCAL_PORT=${WARP_LOCAL_PORT:-10080}
SOCKS_PORT=${SOCKS_PORT:-1080}
SOCKS_USER=${SOCKS_USER:-}
SOCKS_PASS=${SOCKS_PASS:-}

# 1) Start WARP daemon
warp-svc > /dev/null 2>&1 &
WARP_PID=$!

# Wait until warp-cli is ready
echo "Waiting for warp-svc to initialize..."
sleep 3
while ! warp-cli --accept-tos status > /dev/null 2>&1; do
  sleep 1
done
echo "warp-svc is running."

# 2) Initialize WARP local proxy on 127.0.0.1:${WARP_LOCAL_PORT}
warp-cli --accept-tos registration new || true
warp-cli --accept-tos mode proxy
warp-cli --accept-tos proxy port ${WARP_LOCAL_PORT}
warp-cli --accept-tos connect

# Wait a bit for WARP to reach Connected
sleep 3

# 3) Expose SOCKS5
# If SOCKS_USER/PASS are provided, use 3proxy for username/password auth.
# Otherwise fallback to socat port forward (no auth).
if [[ -n "${SOCKS_USER}" && -n "${SOCKS_PASS}" ]]; then
  echo "Starting authenticated SOCKS5 via 3proxy on 0.0.0.0:${SOCKS_PORT} (upstream=WARP 127.0.0.1:${WARP_LOCAL_PORT})"
  # Render config from template
  sed \
    -e "s/\${SOCKS_USER}/${SOCKS_USER}/g" \
    -e "s/\${SOCKS_PASS}/${SOCKS_PASS}/g" \
    -e "s/\${SOCKS_PORT}/${SOCKS_PORT}/g" \
    -e "s/\${WARP_LOCAL_PORT}/${WARP_LOCAL_PORT}/g" \
    /3proxy.cfg.template > /etc/3proxy.cfg

  /usr/local/bin/3proxy /etc/3proxy.cfg &
else
  echo "Starting unauthenticated SOCKS5 via socat on 0.0.0.0:${SOCKS_PORT} -> 127.0.0.1:${WARP_LOCAL_PORT}"
  socat TCP-LISTEN:${SOCKS_PORT},fork,reuseaddr TCP:127.0.0.1:${WARP_LOCAL_PORT} &
fi

# 4) Start IP changer
/ip_changer.sh &

# Keep container running
wait $WARP_PID
