# ---- build 3proxy (SOCKS5 username/password auth + chaining) ----
FROM ubuntu:22.04 AS build-3proxy
ENV DEBIAN_FRONTEND=noninteractive

# Make apt more robust on some VPS networks (prefer IPv4 + retries/timeouts)
RUN printf 'Acquire::ForceIPv4 "true";\nAcquire::Retries "5";\nAcquire::http::Timeout "30";\nAcquire::https::Timeout "30";\n' > /etc/apt/apt.conf.d/99network

RUN apt-get update && \
    apt-get install -y --no-install-recommends git build-essential ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Build stable 3proxy (master branch is stable 0.9)
RUN git clone --depth 1 https://github.com/z3APA3A/3proxy.git /tmp/3proxy && \
    cd /tmp/3proxy && \
    ln -sf Makefile.Linux Makefile && \
    make -j"$(nproc)" && \
    mkdir -p /out && \
    cp -v bin/3proxy /out/3proxy


# ---- runtime image ----
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Make apt more robust on some VPS networks (prefer IPv4 + retries/timeouts)
RUN printf 'Acquire::ForceIPv4 "true";\nAcquire::Retries "5";\nAcquire::http::Timeout "30";\nAcquire::https::Timeout "30";\n' > /etc/apt/apt.conf.d/99network

# Runtime deps:
# - socat: port forward mode when auth is disabled
# - cloudflare-warp: warp-svc/warp-cli
# - iproute2/iptables: used by WARP + diagnostics
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl gnupg lsb-release socat iproute2 iptables ca-certificates && \
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends cloudflare-warp && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy 3proxy binary
COPY --from=build-3proxy /out/3proxy /usr/local/bin/3proxy

# Copy scripts & templates
COPY entrypoint.sh /entrypoint.sh
COPY ip_changer.sh /ip_changer.sh
COPY 3proxy.cfg.template /3proxy.cfg.template
RUN chmod +x /entrypoint.sh /ip_changer.sh

ENTRYPOINT ["/entrypoint.sh"]
