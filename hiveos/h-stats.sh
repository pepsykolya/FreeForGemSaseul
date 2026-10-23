#!/usr/bin/env bash
# FreeForGemSaseul (ffgs) — SASEUL (SL) GPU miner
# Sourced by the HiveOS agent: sets $khs (total, kH/s) and $stats (JSON) from the miner's periodic log line
#   2026-10-22 18:00:10 [   20s] GPU0 4.611 | GPU1 4.70 | total 9.31 GH/s | user sub 6 acc 6 rej 0 | fee sub 0 acc 0 rej 0
_ffgs_dir=$(dirname "${BASH_SOURCE[0]}")
. "$_ffgs_dir/h-manifest.conf"
_log="${CUSTOM_LOG_BASENAME}.log"
_line=$(tail -n 200 "$_log" 2>/dev/null | grep -aE ' total [0-9.]+ GH/s' | tail -n 1)
_age=$(( $(date +%s) - $(stat -c %Y "$_log" 2>/dev/null || echo 0) ))

if [[ -z $_line || $_age -gt 60 ]]; then
  khs=0
  stats=null
else
  mapfile -t _ids < <(grep -oP 'GPU\K[0-9]+(?= [0-9.]+)' <<< "$_line")
  mapfile -t _ghs < <(grep -oP 'GPU[0-9]+ \K[0-9.]+' <<< "$_line")
  _total=$(grep -oP 'total \K[0-9.]+' <<< "$_line")
  _up=$(grep -oP '\[\s*\K[0-9]+(?=s\])' <<< "$_line")
  _acc=$(grep -oP 'user sub [0-9]+ acc \K[0-9]+' <<< "$_line")
  _rej=$(grep -oP 'user sub [0-9]+ acc [0-9]+ rej \K[0-9]+' <<< "$_line")
  if grep -q 'AMD OpenCL devices' <(tail -n 2000 "$_log" 2>/dev/null); then
    # AMD backend: ffgs numbers the AMD GPUs in PCI bus order; HiveOS gpu-stats.json has bus/temp/fan of every GPU
    _gs=${GPU_STATS_JSON:-/run/hive/gpu-stats.json}
    _sel='[.brand, .busids, .temp, .fan] | transpose | map(select(.[0] == "amd")) | sort_by(.[1])'
    mapfile -t _bus  < <(jq -r "$_sel | .[][1] | split(\":\")[0] | \"0x\" + ." "$_gs" 2>/dev/null)
    mapfile -t _temp < <(jq -r "$_sel | .[][2]" "$_gs" 2>/dev/null)
    mapfile -t _fan  < <(jq -r "$_sel | .[][3]" "$_gs" 2>/dev/null)
  else
    mapfile -t _bus  < <(nvidia-smi --query-gpu=pci.bus --format=csv,noheader 2>/dev/null)
    mapfile -t _temp < <(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null)
    mapfile -t _fan  < <(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits 2>/dev/null)
  fi
  _hs=(); _b=(); _t=(); _f=()
  for i in "${!_ids[@]}"; do
    d=${_ids[$i]}
    _hs+=("$(awk -v x="${_ghs[$i]}" 'BEGIN{printf "%.0f", x*1e6}')")   # GH/s -> kH/s
    _b+=("$(( ${_bus[$d]:-0} ))")
    _t+=("${_temp[$d]:-0}")
    f=${_fan[$d]:-0}; [[ $f =~ ^[0-9]+$ ]] || f=0; _f+=("$f")
  done
  khs=$(awk -v x="${_total:-0}" 'BEGIN{printf "%.0f", x*1e6}')
  stats=$(jq -nc \
    --argjson hs "$(printf '%s\n' "${_hs[@]}" | jq -sc .)" \
    --argjson temp "$(printf '%s\n' "${_t[@]}" | jq -sc .)" \
    --argjson fan "$(printf '%s\n' "${_f[@]}" | jq -sc .)" \
    --argjson bus "$(printf '%s\n' "${_b[@]}" | jq -sc .)" \
    --arg ver "$CUSTOM_VERSION" --arg algo "$CUSTOM_ALGO" \
    --argjson up "${_up:-0}" --argjson acc "${_acc:-0}" --argjson rej "${_rej:-0}" \
    '{hs: $hs, hs_units: "khs", temp: $temp, fan: $fan, uptime: $up, ver: $ver, ar: [$acc, $rej], algo: $algo, bus_numbers: $bus}')
fi
