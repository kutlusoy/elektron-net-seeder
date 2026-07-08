############################
# Build stage              #
############################
FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libboost-all-dev \
        libssl-dev \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . .
RUN make

############################
# Runtime stage            #
############################
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        libboost-system1.74.0 \
        libboost-filesystem1.74.0 \
        libboost-thread1.74.0 \
        libssl3 \
        libcap2-bin \
        ca-certificates gosu \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --create-home --home-dir /data --shell /usr/sbin/nologin seeder

COPY --from=build /build/dnsseed /usr/local/bin/dnsseed
# Lets the "seeder" user (below) bind port 53 without running as root.
RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/dnsseed

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME ["/data"]
WORKDIR /data

# 53 = DNS. No P2P port -- the seeder only makes outbound connections.
EXPOSE 53/udp 53/tcp

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["dnsseed"]
