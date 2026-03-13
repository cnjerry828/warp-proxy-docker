#!/bin/bash
set -e

echo "[INFO] Running healthcheck..."
# probe via local wireproxy
IP=$(curl -s --socks5-hostname 127.0.0.1:${WIREPROXY_PORT:-10080} --connect-timeout 5 https://api.ipify.org || true)

if [ -z "$IP" ]; then
  echo "[ERROR] Proxy dead or unreachable, restarting wireproxy..."
  pkill wireproxy || true
  cd /etc/wireguard
  wireproxy -c wireproxy.conf > /var/log/wireproxy.log 2>&1 &
else
  echo "[INFO] Healthcheck passed. Current IP: $IP"
fi
