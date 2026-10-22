#!/usr/bin/env bash
# FreeForGemSaseul (ffgs) — SASEUL (SL) GPU miner
# Called by HiveOS with the flight sheet variables; writes the miner arguments to $CUSTOM_CONFIG_FILENAME.
#   Pool URL       (CUSTOM_URL)          host:port[,host2:port2], e.g. nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931
#                                        or https://pool.saseulmine.com (saseulmine protocol, passed as is)
#   Wallet/worker  (CUSTOM_TEMPLATE)     %WAL%.%WORKER_NAME%  (or just %WAL%)
#   Extra config   (CUSTOM_USER_CONFIG)  extra arguments, e.g. --devices 0,1, --eco, --referrer none
cd "$(dirname "$0")"
. ./h-manifest.conf

url=$(echo "${CUSTOM_URL:-}" | tr ' ' ',')     # several URLs in the flight sheet = failover list
tpl=${CUSTOM_TEMPLATE:-}
wallet=${tpl%%.*}
worker=${WORKER_NAME:-rig}
[[ $tpl == *.* ]] && worker=${tpl#*.}

[[ -z $wallet ]] && echo "ffgs: Wallet template is empty in the flight sheet" >&2

args="--wallet $wallet --worker $worker"
[[ -n $url ]] && args="--pool $url $args"
echo "$args ${CUSTOM_USER_CONFIG:-}" > "$CUSTOM_CONFIG_FILENAME"
