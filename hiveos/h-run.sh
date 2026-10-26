#!/usr/bin/env bash
# FreeForGemSaseul (ffgs) — SASEUL (SL) GPU miner
# NVIDIA rigs: CUDA backend. AMD rigs: OpenCL backend (the AMD OpenCL runtime of the HiveOS AMD driver).
# Mixed NVIDIA + AMD rigs: two ffgs processes (--backend cuda, --backend amd), one log each; h-stats.sh merges them.
# Set FFGS_MIXED=0 in the environment, or give --backend / --devices in Extra config arguments, for a single process.
cd "$(dirname "$0")" || exit 1
. ./h-manifest.conf
[[ -f $CUSTOM_CONFIG_FILENAME ]] || { echo "No config file $CUSTOM_CONFIG_FILENAME"; exit 1; }
mkdir -p "$(dirname "$CUSTOM_LOG_BASENAME")"
# GPU numbering in PCI bus order, the same as nvidia-smi and the HiveOS dashboard
export CUDA_DEVICE_ORDER=PCI_BUS_ID
read -r -a args < "$CUSTOM_CONFIG_FILENAME"
log=${CUSTOM_LOG_BASENAME}.log
runs=${CUSTOM_LOG_BASENAME}.runs   # "backend log" per ffgs process, read by h-stats.sh

# discrete GPUs of a brand (nvidia | amd): HiveOS gpu-stats (integrated GPUs are brand "cpu" there), else lspci
gpu_count() {
  local gs=${GPU_STATS_JSON:-/run/hive/gpu-stats.json} n v
  if [[ -s $gs ]] && n=$(jq -r --arg b "$1" '[.brand[]? | select(. == $b)] | length' "$gs" 2>/dev/null) && [[ $n =~ ^[0-9]+$ ]]; then
    echo "$n"; return
  fi
  [[ $1 == nvidia ]] && v=10de || v=1002
  lspci -n 2>/dev/null | awk -v v="$v" '$2 ~ /^03/ && $3 ~ "^" v ":" { n++ } END { print n + 0 }'
}

# AMD OpenCL runtime check (no GPU work): lists the AMD OpenCL devices or explains why there are none
amd_probe() {
  local out
  out=$(./ffgs --backend amd --oc-info 2>&1)
  if grep -qaE '^AMD[0-9]+: ' <<< "$out"; then grep -aE '^AMD[0-9]+: ' <<< "$out"; return 0; fi  # not "no AMD OpenCL devices"
  echo "ffgs: no usable AMD OpenCL device. OpenCL loader (libOpenCL.so.1):"
  { ldconfig -p 2>/dev/null | grep -F 'libOpenCL.so' || echo "  not in the ldconfig cache"; } | sed 's/^/  /'
  echo "  ICDs in /etc/OpenCL/vendors: $(ls /etc/OpenCL/vendors 2>/dev/null | tr '\n' ' ')"
  echo "  On HiveOS: check the AMD driver and OpenCL with amd-info (reinstall OpenCL: amd-ocl-install <version>), then miner restart."
  return 1
}

# --auto-uv results (ffgs-uv-results.txt) in /hive-config: they survive miner updates and reinstalls
if [[ -d /hive-config ]]; then export FFGS_STATE_DIR=${FFGS_STATE_DIR:-/hive-config/ffgs}; mkdir -p "$FFGS_STATE_DIR"; fi

nv=$(gpu_count nvidia)
amd=$(gpu_count amd)
single=0
[[ " ${args[*]} " == *" --backend "* || " ${args[*]} " == *" --devices "* || ${FFGS_MIXED:-1} == 0 ]] && single=1

if (( !single && nv > 0 && amd > 0 )) && amd_probe; then
  echo "ffgs: mixed rig ($nv NVIDIA + $amd AMD): CUDA process -> $log, AMD process -> ${CUSTOM_LOG_BASENAME}-amd.log"
  printf 'cuda %s\namd %s\n' "$log" "${CUSTOM_LOG_BASENAME}-amd.log" > "$runs"
  ./ffgs --backend cuda "${args[@]}" > >(exec tee --append "$log") 2>&1 &
  p1=$!
  ./ffgs --backend amd "${args[@]}" > >(exec tee --append "${CUSTOM_LOG_BASENAME}-amd.log") 2>&1 &
  p2=$!
  trap 'kill $p1 $p2 2>/dev/null' EXIT INT TERM HUP   # stopping the miner stops both
  while kill -0 $p1 2>/dev/null && kill -0 $p2 2>/dev/null; do sleep 5; done   # one ended: stop the other too,
  echo "ffgs: one of the two processes ended, stopping the other (HiveOS restarts the miner)"  # HiveOS restarts
  exit 1
fi

be=auto   # --backend from Extra config arguments (h-stats.sh needs to know which GPUs the log is about)
for i in "${!args[@]}"; do [[ ${args[i]} == --backend ]] && be=${args[i+1]:-auto}; done
[[ $be == opencl ]] && be=amd
[[ $be == auto ]] && (( nv == 0 && amd > 0 )) && be=amd
[[ $be == amd ]] && amd_probe
echo "$be $log" > "$runs"
./ffgs "${args[@]}" 2>&1 | tee --append "$log"
