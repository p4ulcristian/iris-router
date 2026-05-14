FROM debian:12-slim

ARG RATHOLE_VERSION=v0.5.0

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl unzip gettext-base \
 && curl -fsSL -o /tmp/rathole.zip \
      "https://github.com/rathole-org/rathole/releases/download/${RATHOLE_VERSION}/rathole-x86_64-unknown-linux-gnu.zip" \
 && unzip -q /tmp/rathole.zip -d /tmp \
 && install -m 0755 /tmp/rathole /usr/local/bin/rathole \
 && rm -rf /tmp/rathole /tmp/rathole.zip \
 && apt-get purge -y curl unzip \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /etc/rathole/entrypoint.sh
COPY server.toml.tmpl /etc/rathole/server.toml.tmpl
RUN chmod 0755 /etc/rathole/entrypoint.sh

ENTRYPOINT ["/etc/rathole/entrypoint.sh"]
