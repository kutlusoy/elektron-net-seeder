#!/bin/sh
set -eu

: "${SEEDER_HOST:?SEEDER_HOST must be set (hostname of this DNS seed, e.g. seed.elektron-net.org)}"
: "${SEEDER_NS:?SEEDER_NS must be set (hostname of the authoritative nameserver for SEEDER_HOST)}"
: "${SEEDER_MBOX:?SEEDER_MBOX must be set (e-mail for SOA records, @ written as ., e.g. admin.elektron-net.org)}"

set -- -h "$SEEDER_HOST" -n "$SEEDER_NS" -m "$SEEDER_MBOX"

[ -n "${SEEDER_DNS_PORT:-}" ]     && set -- "$@" -p "$SEEDER_DNS_PORT"
[ -n "${SEEDER_BIND_ADDRESS:-}" ] && set -- "$@" -a "$SEEDER_BIND_ADDRESS"
[ -n "${SEEDER_THREADS:-}" ]      && set -- "$@" -t "$SEEDER_THREADS"
[ -n "${SEEDER_DNS_THREADS:-}" ]  && set -- "$@" -d "$SEEDER_DNS_THREADS"
[ -n "${SEEDER_P2P_PORT:-}" ]     && set -- "$@" --p2port "$SEEDER_P2P_PORT"
[ -n "${SEEDER_MAGIC:-}" ]        && set -- "$@" --magic "$SEEDER_MAGIC"
[ -n "${SEEDER_MIN_HEIGHT:-}" ]   && set -- "$@" --minheight "$SEEDER_MIN_HEIGHT"
[ -n "${SEEDER_TOR_PROXY:-}" ]    && set -- "$@" -o "$SEEDER_TOR_PROXY"
[ -n "${SEEDER_IPV4_PROXY:-}" ]   && set -- "$@" -i "$SEEDER_IPV4_PROXY"
[ -n "${SEEDER_IPV6_PROXY:-}" ]   && set -- "$@" -k "$SEEDER_IPV6_PROXY"
[ "${SEEDER_TESTNET:-false}" = "true" ]     && set -- "$@" --testnet
[ "${SEEDER_WIPE_BAN:-false}" = "true" ]    && set -- "$@" --wipeban
[ "${SEEDER_WIPE_IGNORE:-false}" = "true" ] && set -- "$@" --wipeignore

# -s/--seed can be repeated to override the built-in default seed peers.
if [ -n "${SEEDER_EXTRA_SEEDS:-}" ]; then
    OLDIFS=$IFS
    IFS=','
    for seed in $SEEDER_EXTRA_SEEDS; do
        [ -n "$seed" ] && set -- "$@" -s "$seed"
    done
    IFS=$OLDIFS
fi

# -w/--filter can be repeated to allow additional service-flag combinations.
if [ -n "${SEEDER_FILTERS:-}" ]; then
    OLDIFS=$IFS
    IFS=','
    for flt in $SEEDER_FILTERS; do
        [ -n "$flt" ] && set -- "$@" -w "$flt"
    done
    IFS=$OLDIFS
fi

# /data is bind-mounted from the host (dnsseed.dat/dnsseed.dump persist
# here); fix ownership on every start in case it was created as root by
# Docker on first run.
chown -R seeder:seeder /data
cd /data

echo "Starting: dnsseed $*"
exec gosu seeder /usr/local/bin/dnsseed "$@"
