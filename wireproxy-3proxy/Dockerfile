# Wireproxy + optional 3proxy-auth wrapper
# - Base: Alpine
# - Runs wgcf+wireproxy to produce a local socks5 (127.0.0.1:1080 by default)
# - If SOCKS_USER/SOCKS_PASS set: expose authenticated socks5 via 3proxy

FROM alpine:3.20 AS build-3proxy
RUN apk add --no-cache git build-base make openssl-dev linux-headers
RUN git clone --depth 1 https://github.com/z3APA3A/3proxy.git /src/3proxy \
  && cd /src/3proxy \
  && ln -sf Makefile.Linux Makefile \
  && make -j"$(nproc)" \
  && cp -v bin/3proxy /out_3proxy \
  && chmod +x /out_3proxy

FROM alpine:3.20
RUN apk add --no-cache curl bash ca-certificates

# Download wgcf + wireproxy
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then \
        WGCF_URL="https://github.com/ViRb3/wgcf/releases/download/v2.2.22/wgcf_2.2.22_linux_arm64"; \
        WP_URL="https://github.com/windtf/wireproxy/releases/download/v1.1.2/wireproxy_linux_arm64.tar.gz"; \
    elif [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then \
        WGCF_URL="https://github.com/ViRb3/wgcf/releases/download/v2.2.22/wgcf_2.2.22_linux_amd64"; \
        WP_URL="https://github.com/windtf/wireproxy/releases/download/v1.1.2/wireproxy_linux_amd64.tar.gz"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    curl -L -o /usr/local/bin/wgcf $WGCF_URL && \
    chmod +x /usr/local/bin/wgcf && \
    curl -L -o /tmp/wp.tar.gz $WP_URL && \
    tar -xzf /tmp/wp.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/wireproxy && \
    rm /tmp/wp.tar.gz

COPY --from=build-3proxy /out_3proxy /usr/local/bin/3proxy

COPY entrypoint.sh /entrypoint.sh
COPY rotate_ip.sh /rotate_ip.sh
COPY healthcheck.sh /healthcheck.sh
COPY 3proxy.cfg.template /3proxy.cfg.template
RUN chmod +x /*.sh

ENV ROTATE_INTERVAL=3600
ENV WIREPROXY_PORT=1080
ENV SOCKS_PORT=1080

ENTRYPOINT ["/entrypoint.sh"]
