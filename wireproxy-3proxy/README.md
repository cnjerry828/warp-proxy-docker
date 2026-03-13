# wireproxy + 3proxy (auth) + 3-instance pool

This folder provides a **wireproxy-based** WARP SOCKS5 proxy with optional **username/password authentication** (3proxy), plus a ready-to-use 3-instance compose file.

## Why this variant
- wireproxy is lightweight and stable compared to warp-svc daemon.
- add SOCKS5 auth to avoid running an open proxy on a public VPS.
- run 3 instances to get a "pool" (3 independent WARP identities/exits).

## Quick start

```bash
cd wireproxy-3proxy
cp docker-compose.3.yml docker-compose.yml
# edit docker-compose.yml to set REPLACE_UUID_1/2/3

docker compose up -d --build
```

## Use
- Instance 1: `socks5://warp:<UUID1>@<VPS-IP>:31080`
- Instance 2: `socks5://warp:<UUID2>@<VPS-IP>:31081`
- Instance 3: `socks5://warp:<UUID3>@<VPS-IP>:31082`

Test:
```bash
curl -x socks5://warp:<UUID1>@<VPS-IP>:31080 https://cloudflare.com/cdn-cgi/trace | egrep 'ip=|loc=|colo=|warp='
```

## Notes
- This variant stores wgcf identity/config under the mounted volume (`/etc/wireguard`).
- `SOCKS_USER` and `SOCKS_PASS` must be set to enable authentication. If unset, it falls back to exposing unauthenticated SOCKS5 (not recommended for public VPS).
