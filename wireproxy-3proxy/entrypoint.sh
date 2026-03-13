#!/bin/bash
set -euo pipefail
set -x

echo "[INFO] Starting wireproxy+3proxy entrypoint"

ROTATE_INTERVAL=${ROTATE_INTERVAL:-3600}
WIREPROXY_PORT=${WIREPROXY_PORT:-1080}
SOCKS_PORT=${SOCKS_PORT:-1080}
SOCKS_USER=${SOCKS_USER:-}
SOCKS_PASS=${SOCKS_PASS:-}

mkdir -p /etc/wireguard
cd /etc/wireguard

# Generate identity if missing
if [ ! -f "wgcf-profile.conf" ] || [ ! -f "wgcf-account.toml" ]; then
  echo "[INFO] Generating new WARP identity..."
  wgcf register --accept-tos
  wgcf generate
fi

# Build wireproxy config
cat wgcf-profile.conf > wireproxy.conf
{
  echo ""
  echo "[Socks5]"
  echo "BindAddress = 127.0.0.1:${WIREPROXY_PORT}"
} >> wireproxy.conf
sed -i 's/DNS = .*/DNS = 1.1.1.1, 1.0.0.1, 2606:4700:4700::1111, 2606:4700:4700::1001/g' wireproxy.conf

# Start wireproxy
wireproxy -c /etc/wireguard/wireproxy.conf > /var/log/wireproxy.log 2>&1 &
WP_PID=$!

# Start rotate + healthcheck
bash /rotate_ip.sh > /var/log/rotate.log 2>&1 &

# Expose external SOCKS5
if [[ -n "${SOCKS_USER}" && -n "${SOCKS_PASS}" ]]; then
  echo "[INFO] Starting authenticated SOCKS5 via 3proxy on 0.0.0.0:${SOCKS_PORT} (upstream=wireproxy 127.0.0.1:${WIREPROXY_PORT})"
  sed \
    -e "s/\${SOCKS_USER}/${SOCKS_USER}/g" \
    -e "s/\${SOCKS_PASS}/${SOCKS_PASS}/g" \
    -e "s/\${SOCKS_PORT}/${SOCKS_PORT}/g" \
    -e "s/\${WIREPROXY_PORT}/${WIREPROXY_PORT}/g" \
    /3proxy.cfg.template > /etc/3proxy.cfg
  /usr/local/bin/3proxy /etc/3proxy.cfg &
else
  echo "[INFO] WARNING: SOCKS_USER/SOCKS_PASS not set, exposing UNAUTHENTICATED SOCKS5 on 0.0.0.0:${SOCKS_PORT}"
  # fall back to wireproxy binding 0.0.0.0 (less safe)
  # we do it by starting a second wireproxy instance that binds 0.0.0.0
  # simplest: use busybox socat is not present; so just re-render config and restart wireproxy
  pkill wireproxy || true
  sed -i "s/BindAddress = .*/BindAddress = 0.0.0.0:${SOCKS_PORT}/" /etc/wireguard/wireproxy.conf
  wireproxy -c /etc/wireguard/wireproxy.conf > /var/log/wireproxy.log 2>&1 &
fi

# Healthcheck loop
while true; do
  bash /healthcheck.sh
  tail -n 10 /var/log/wireproxy.log || true
  sleep 60
done
