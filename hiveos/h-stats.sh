#!/usr/bin/env bash
# FreeForGemSaseul (ffgs) — SASEUL (SL) GPU miner
# Sourced by the HiveOS agent: sets $khs (total, kH/s) and $stats (JSON) from the miner's periodic log line
#   2026-10-22 18:00:10 [   20s] GPU0 4.611 | GPU1 4.70 | total 9.31 GH/s | user sub 6 acc 6 rej 0 | fee sub 0 acc 0 rej 0
# h-run.sh writes "<backend> <log>" per ffgs process to ${CUSTOM_LOG_BASENAME}.runs (2 lines on a mixed NVIDIA+AMD rig).
# Bus numbers: NVIDIA from nvidia-smi; AMD from ffgs' own device list in the log ("AMD0: ... bus 03"), else the AMD
# entries of HiveOS gpu-stats.json in bus order. AMD temperatures / fans come from gpu-stats.json (matched by bus).
_ffgs_dir=$(dirname "${BASH_SOURCE[0]}")
. "$_ffgs_dir/h-manifest.conf"
_gs=${GPU_STATS_JSON:-/run/hive/gpu-stats.json}
_runs_f="${CUSTOM_LOG_BASENAME}.runs"
if [[ -s $_runs_f ]]; then mapfile -t _runs < "$_runs_f"; else _runs=("auto ${CUSTOM_LOG_BASENAME}.log"); fi

_all=()   # "bus khs temp fan" per GPU
_tot=0; _upmax=0; _acc_s=0; _rej_s=0
for _r in "${_runs[@]}"; do
  _be=${_r%% *}; _log=${_r#* }
  _line=$(tail -n 200 "$_log" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep -aE ' total [0-9.]+ GH/s' | tail -n 1)
  _age=$(( $(date +%s) - $(stat -c %Y "$_log" 2>/dev/null || echo 0) ))
  [[ -z $_line || $_age -gt 60 ]] && continue
  mapfile -t _ids < <(grep -oP 'GPU\K[0-9]+(?= [0-9.]+)' <<< "$_line")
  mapfile -t _ghs < <(grep -oP 'GPU[0-9]+ \K[0-9.]+' <<< "$_line")
  _total=$(grep -oP 'total \K[0-9.]+' <<< "$_line")
  _up=$(grep -oP '\[\s*\K[0-9]+(?=s\])' <<< "$_line")
  _acc=$(grep -oP 'user sub [0-9]+ acc \K[0-9]+' <<< "$_line")
  _rej=$(grep -oP 'user sub [0-9]+ acc [0-9]+ rej \K[0-9]+' <<< "$_line")
  # an older h-run.sh / "auto": AMD when there is no NVIDIA GPU
  [[ $_be == auto ]] && { [[ -n $(nvidia-smi -L 2>/dev/null) ]] && _be=cuda || _be=amd; }
  _bus=(); _temp=(); _fan=()
  if [[ $_be == amd ]]; then
    # the most recent AMD device list of this log (read backwards up to its header): "n bus" per AMD GPU
    _amdl=$(tac "$_log" 2>/dev/null | awk '/AMD OpenCL devices:/ { exit } match($0, /AMD[0-9]+: .* bus [0-9a-f]+, driver/) {
            s = substr($0, RSTART, RLENGTH); split(s, a, ":"); n = substr(a[1], 4); sub(/.* bus /, "", s); sub(/,.*/, "", s); print n, s }')
    _sel='[.brand, (.busids | map(ascii_downcase))] | transpose | map(select(.[0] == "amd")) | sort_by(.[1])'
    mapfile -t _gsb < <(jq -r "$_sel | .[][1] | split(\":\")[0]" "$_gs" 2>/dev/null)
    while read -r n b; do [[ $n =~ ^[0-9]+$ && $b =~ ^[0-9a-f]+$ && $b != 00 ]] && _bus[n]=$b; done <<< "$_amdl"
    for i in "${!_gsb[@]}"; do [[ -n ${_bus[i]:-} ]] || _bus[i]=${_gsb[i]}; done   # bus unknown to ffgs: gpu-stats order
    for i in "${!_bus[@]}"; do
      b=${_bus[i]}
      _temp[i]=$(jq -r --arg b "$b" '[.brand, .busids, .temp] | transpose | map(select(.[1] | ascii_downcase | startswith($b + ":"))) | .[0][2] // 0' "$_gs" 2>/dev/null)
      _fan[i]=$(jq -r --arg b "$b" '[.brand, .busids, .fan] | transpose | map(select(.[1] | ascii_downcase | startswith($b + ":"))) | .[0][2] // 0' "$_gs" 2>/dev/null)
      _bus[i]="0x$b"
    done
  else
    mapfile -t _bus  < <(nvidia-smi --query-gpu=pci.bus --format=csv,noheader 2>/dev/null)
    mapfile -t _temp < <(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null)
    mapfile -t _fan  < <(nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits 2>/dev/null)
  fi
  for i in "${!_ids[@]}"; do
    d=${_ids[$i]}
    h=$(awk -v x="${_ghs[$i]}" 'BEGIN{printf "%.0f", x*1e6}')   # GH/s -> kH/s
    b=${_bus[$d]:-0}; [[ $b =~ ^(0x)?[0-9a-fA-F]+$ ]] || b=0
    t=${_temp[$d]:-0}; [[ $t =~ ^[0-9]+$ ]] || t=0
    f=${_fan[$d]:-0}; [[ $f =~ ^[0-9]+$ ]] || f=0
    _all+=("$(( b )) $h $t $f")
  done
  _tot=$(awk -v a="$_tot" -v x="${_total:-0}" 'BEGIN{printf "%.0f", a + x*1e6}')
  (( ${_up:-0} > _upmax )) && _upmax=${_up:-0}
  _acc_s=$(( _acc_s + ${_acc:-0} )); _rej_s=$(( _rej_s + ${_rej:-0} ))
done

if (( ${#_all[@]} == 0 )); then
  khs=0
  stats=null
else
  khs=$_tot
  stats=$(printf '%s\n' "${_all[@]}" | sort -n -k1,1 | jq -Rn \
    --arg ver "$CUSTOM_VERSION" --arg algo "$CUSTOM_ALGO" \
    --argjson up "$_upmax" --argjson acc "$_acc_s" --argjson rej "$_rej_s" \
    '[inputs | split(" ") | map(tonumber)] as $g |
     {hs: [$g[][1]], hs_units: "khs", temp: [$g[][2]], fan: [$g[][3]], uptime: $up, ver: $ver, ar: [$acc, $rej],
      algo: $algo, bus_numbers: [$g[][0]]}' -c)
fi
