#!/usr/bin/env bash
# FreeForGemSaseul (ffgs) — SASEUL (SL) GPU miner
# Called by HiveOS with the flight sheet variables; writes the miner arguments to $CUSTOM_CONFIG_FILENAME.
#   Pool URL       (CUSTOM_URL)          host:port[,host2:port2], e.g. sl.kasplay.online:3333 (Kavatar SL Pool),
#                                        nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931,
#                                        or https://pool.saseulmine.com (saseulmine protocol, passed as is)
#                                        or nats://nats.saseulpool.com:4222 (saseulpool protocol, passed as is)
#   Wallet/worker  (CUSTOM_TEMPLATE)     %WAL%.%WORKER_NAME%  (or just %WAL%)
#   Extra config   (CUSTOM_USER_CONFIG)  extra arguments, e.g. --devices 0,1, --eco, --referrer none
cd "$(dirname "$0")"
. ./h-manifest.conf

url=$(echo "${CUSTOM_URL:-}" | tr ' ' ',')     # several URLs in the flight sheet = failover list
tpl=${CUSTOM_TEMPLATE:-}
tpl=${tpl//%WORKER_NAME%/${WORKER_NAME:-rig}}   # normally already substituted by HiveOS
wallet=${tpl%%.*}
worker=${WORKER_NAME:-rig}
[[ $tpl == *.* ]] && worker=${tpl#*.}

[[ -z $wallet ]] && echo "ffgs: Wallet template is empty in the flight sheet" >&2

args="--wallet $wallet --worker $worker"
[[ -n $url ]] && args="--pool $url $args"
# Extra config arguments typed over several lines (HiveOS keeps the newlines): one line of arguments, or h-run.sh / ffgs
# would see only the first one (0.5.2: "--auto-uv" on line 1, "--referrer ..." on line 2 -> fee 2%)
user=$(printf '%s' "${CUSTOM_USER_CONFIG:-}" | tr '\r\n\t' '   ')
echo "$args $user" > "$CUSTOM_CONFIG_FILENAME"
