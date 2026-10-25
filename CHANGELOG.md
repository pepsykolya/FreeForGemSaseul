# Changelog

## Unreleased / 0.5.0
- **Fee 2% = 1% dev + 1% referral.** Two 60 s windows per 100 min, both on your own pool: 1% referral for
  `--referrer ADDRESS` (solo: on Kavatar), 1% dev (old per-pool rule); no `--referrer` = both minutes for the dev.
  **Your own wallet as referrer = no referral switch, total fee 1%, and the dev minute is mined on Kavatar SL Pool**
  (`sl.kasplay.online:3333`; fallback: your pool). `--referrer` is still also the saseulmine
  referrer. Windows: `REFERRER=` in the start scripts. Status line: `ref sub/acc/rej` next to `fee`.
- **Faster kernel on RTX 30 (sm_86)**: the 40-hex layout (Kavatar SL Pool, saseulmine, solo) hashes 4 nonces per loop
  pass at 2 blocks/SM: RTX 3070 at 1400/810 MHz, `--coffset 325`: **5.05 GH/s at 74 W, 68 MH/W** (0.4.0: 4.63 GH/s,
  65 MH/W; +9% GH/s, +4% MH/W); stock +6.6%. `--eco` +2%. 16-hex (rabbitminer, saseulpool) unchanged; other GPU
  generations unchanged (not measured). Details: docs/JOURNAL.md.
- **HiveOS: AMD and mixed rigs** — h-run.sh detects NVIDIA / AMD cards (HiveOS gpu-stats, lspci fallback), checks the
  AMD OpenCL runtime, runs a CUDA and an AMD process on mixed rigs; h-stats.sh reports AMD bus numbers, temperatures
  and fans (fixes 0.4.0 losing AMD bus ids on long runs). AMD OC for SASEUL in HiveOS (core, VDD, VDDCI, MVDD, SoC):
  HIVEOS.md. The flight sheet for Kavatar can be imported from the clipboard (JSON on https://kavatar.kasplay.online).
- **Kavatar SL Pool — our pool — is the default** (`sl.kasplay.online:3333`, also `--pool kavatar`; site
  https://kavatar.kasplay.online): PPLNS over 2 network difficulties, 2% fee, automatic payouts every 6 h from 10 SL,
  its own SASEUL node. The dev fee minute is mined on the same pool; the console's `pool` line shows the pool's view of
  the wallet (10-min hashrate, balance, paid, immature blocks). Windows: `start.bat` mines there, the former rabbitminer
  script is `start-rabbitminer.bat`. A pool list without Kavatar or rabbitminer.cc hosts is still treated as solo.
- **Console colors, one meaning per color** (MANUAL 3a): block found = bold bright white on magenta (the loudest
  style), accepted / delivered shares and connects green, hashrate values bold bright white and MH/W bold bright blue
  (10 s status line, table, `--bench`), GPU temperature green / yellow / red (< 70, 70–79, ≥ 80 °C), totals bold,
  stale / dropped / low-diff yellow, rejected / errors / hardware errors / connection lost red, new block height and
  difficulty changes cyan, dev fee dim, timestamps and column titles gray. Presentation only: the text is unchanged.
- `--color auto|always|never` (`--no-color` = never; `NO_COLOR` / `FORCE_COLOR` honored under auto). `auto` now also
  colors a pipe watched from a terminal (stdin is a terminal or inside GNU screen): HiveOS `ffgs | tee` in the `miner`
  screen and its web miner log are colored; `h-stats.sh` parses the colored log unchanged (colors only around whole
  tokens). Files, services (systemd) and `--log FILE` stay plain text unless `--color always`. Windows: VT mode on the
  Windows 10+ console, plain text on older consoles and on redirected output.

## 0.4.0 — 2026-10-23
- **saseulpool.com pool support** (the third SL pool): `--pool saseulpool` (= `nats://nats.saseulpool.com:4222`; any
  `nats://HOST[:PORT]` selects this protocol, several = failover, the other servers of the pool's NATS cluster are
  learned from the server). Native NATS client over plain TCP (no new libraries). Templates from the pool's nodes,
  shares and blocks published the way the pool's own miner does, a heartbeat every 10 s with the rig's hashrate (shown
  on the pool's site per worker; `--worker` / `.WORKER`, default the host name). The pool answers no single share:
  ffgs counts a share as **delivered** when the server confirmed it (PING/PONG), and the table's `pool` line shows
  what the pool credited from its API (PPLNS work of the address over 90 min → GH/s, share of the pool, next payout,
  site hashrate). Dev fee on the same pool (second connection, dev wallet, same 1% schedule). `--pool-test` works for
  saseulpool (connect, wait for a job). Windows `start-saseulpool.bat`; HiveOS: Pool URL `nats://nats.saseulpool.com:4222`.
  Test (RTX 4070 Laptop, 26 min): 16 shares delivered, 16 credited by the pool (PPLNS work = 16 × share difficulty),
  0 rejected / stale / dropped; dev fee test minute 4/4 credited.
- **GPU clock control** (same model as FreeForGemPear): `--lock-cclock`, `--lock-mclock`, `--coffset` (alias
  `--uv-offset`, core clock V/F offset = undervolt), `--moffset`, `--plimit`. One value for all GPUs or a comma list in
  `--devices` order (empty / `-` / 0 = leave that GPU alone). NVML is loaded at run time (the miner still runs without it),
  GPUs are matched by PCI bus id, only the mining GPUs are touched. Newer NVML calls (`nvmlDeviceSetClockOffsets`) with
  a fallback to `nvmlDeviceSetGpcClkVfOffset` / `SetMemClkVfOffset`. Every value is logged with its read-back.
  Restored on exit (Ctrl-C, SIGTERM/SIGHUP, console window closed, `--minutes`, fatal errors); after kill -9 / a crash
  the per-GPU marker `ffgs-oc-<bus>.restore` makes the next start put everything back. Without root / Administrator:
  one clear message, mining continues. `--oc-info` shows the current values (read only).
- **Readable console**: colors (green accepted, yellow stale/dropped, red rejected/errors/hardware errors/connection
  lost, cyan new block and difficulty changes, magenta block found, dim dev fee; only on an interactive console,
  `--no-color`), one line per accepted share with the round trip, a table every 60 s (10 s and 5 min hashrate, power,
  MH/W, clocks, temperature, fan %/rpm, offsets, what ffgs set, shares with percent) and the pool-side view of the
  wallet every 5 min (saseulmine `/account`: hashrate 1h/24h, round shares and ratio, paid; rabbitminer.cc wallet API:
  hashrate now/3h/24h, shares, pending, paid). Stale shares are counted apart from rejects.
- The 10 s status line adds board power and MH/W per GPU and for the rig, in parentheses after the hashrate:
  `hiveos/h-stats.sh` reads it unchanged.
- `--log FILE` (plain text, 50 MB rotation to `FILE.old`), `--minutes N`.
- Console output can no longer stall mining: lines go to the console through a writer thread (a Windows console
  selection / QuickEdit pause or a stuck pipe reader used to block the pool threads), the `--log` file is written
  directly. QuickEdit is switched off for the miner's console on Windows.
- **Windows: no more GPU starvation in the background**: power throttling (EcoQoS) is turned off for ffgs and its GPU
  threads, GPU threads run at above-normal priority, 1 ms timer; every GPU keeps two launches queued, so it never waits
  for the host. RTX 4070 Laptop, window minimized, 6 min: 4.4–5.6 GH/s at 63–68 W, GPU 100% busy, ffgs CPU ~0.7% of one
  core (0.3.0 on the same laptop dropped to ~0.8–1.8 GH/s at ~20 W).
- saseulmine, several rigs on one address: the pool's vardiff is per address, so a share found just before another
  rig raised it is refused (`Hash does not meet pool difficulty`). Now shown as `low-diff` (yellow, own counter, not a
  reject), the job/difficulty is fetched again at once, a difficulty in any reply is applied immediately, queued shares
  are re-checked before sending. A `Timestamp out of range` reject logs the share time vs the pool time.
  A share answered while the pool switches blocks (HTTP 200, `"job":[]`) is counted as stale and the new job is
  fetched at once.
- `--quick-edit` keeps the Windows console QuickEdit mode (switched off by default).
- Windows start scripts: `LOCK_CCLOCK`, `LOCK_MCLOCK`, `COFFSET`, `MOFFSET`, `PLIMIT`, `DEVICES`, `EXTRA`; with clock
  settings they ask for Administrator (`AUTO_ELEVATE`); log in `logs\ffgs.log`.
- **AMD GPUs (OpenCL)**: the same `ffgs` binary mines on AMD Radeon (RDNA2 tuned: RX 6800 XT 9.0 GH/s pool layout /
  9.86 GH/s saseulmine layout at stock, 9.7 GH/s at 164 W with 2300 MHz / 881 mV). `--backend auto|cuda|amd`; auto =
  CUDA if an NVIDIA GPU is present, else AMD. Windows: the Adrenalin driver's OpenCL; Linux: libOpenCL.so.1 (ROCm /
  amdgpu-pro; untested). Integrated GPUs are skipped. The clock options and the power / temperature / fan columns are
  NVIDIA only (with `--backend amd` the clock options are ignored with a warning). Details: `docs/amd.md`.
- `--bench` re-verifies every candidate on the CPU (stability check: hardware errors, candidate count vs expected).
- HiveOS `h-stats.sh`: bus/temp/fan of AMD GPUs from HiveOS gpu-stats.
- **Solo mining** documented and shipped in the source: `solo/sl_solo_proxy.py` (your SASEUL node's `run/mining_job`
  / `run/mining_result` served to ffgs over the rabbitminer protocol, login token, rotation of payout addresses,
  jobs only while the node is in sync, 40-hex nonce jobs), sample systemd unit, env and address list. MANUAL section 8.
- **Solo dev fee**: with a solo proxy / own node (a `HOST:PORT` pool list without any rabbitminer.cc host) the 1% dev
  fee minute is mined on saseulmine.com (HTTPS) for the dev wallet, not on the user's node; fallback rabbitminer.cc.
  Same schedule; both fee connections stay open, the GPUs switch only to a ready fee job, and the fee window is a hard
  60 s of wall time including connecting/fallback (neither fee pool ready = no fee in that window, logged). The fee
  scheduler now runs every second (was every 10 s) for all pools.

## 0.3.0 — 2026-10-22
- **saseulmine.com pool support**: `--pool saseulmine` (= `https://pool.saseulmine.com`; any `https://` URL selects this
  protocol, several URLs = failover). HTTPS with keep-alive (Linux: static mbedTLS + system CA bundle, Windows: WinHTTP),
  requests signed with a per-rig Ed25519 client key (`ffgs-client.key` next to the binary), pool clock offset used for
  signatures and block timestamps, job polling every second, shares sent by a separate thread (hashing never waits).
  Shares that the pool would reject (stale round, below a just-raised vardiff difficulty) are dropped, not sent.
- `--referrer ADDRESS|none` (saseulmine only). Default: the ffgs dev wallet. Per the pool, the referral 10% comes from
  the pool's part and your share is unchanged with or without a referrer; `--referrer none` turns it off.
- Dev fee on saseulmine goes to the dev wallet on saseulmine (a second signed session), rabbitminer users unchanged.
- saseulmine has no worker names (its account page shows `default`); `.WORKER` / `--worker` are ignored there.
- `--pool-test`: one signed saseulmine job request + account stats, no GPU needed.
- Self-test also checks Ed25519 (RFC 8032), RIPEMD-160 and the SASEUL address derivation.
- Windows package: `start-saseulmine.bat`.

## 0.2.0 — 2026-10-22
- **Faster kernel: +8% hashrate per clock** (RTX 3070 at 1560 MHz: 5.16 GH/s, was 4.78). All round additions incl. K+W
  on the FMA pipe, a constant table for the inner nonce word, two independent hashes per loop iteration.
- **Windows x64 build** (`ffgs-0.2.0-windows-x64.zip`): only the NVIDIA driver is needed; `start.bat` included.
- Solo-mining support: `--pass` (pool password / proxy token), jobs may ask for a 40-hex nonce (`"nonce_len":40`), served by
  a dedicated kernel with rounds 0–12 precomputed.
- Pool messages are parsed with any JSON spacing.

## 0.1.1 — 2026-10-22
- Fix: a pool template refreshed under the same job id (new main block / job digest) is now picked up at once;
  0.1.0 kept hashing the old template and could get "blockhash mismatch" rejects.

## 0.1.0 — 2026-10-22
First release.
- CUDA kernel for SASEUL resource-chain PoW: per-job midstate, rounds 0–6 precomputed, 256 nonces per thread.
- Default kernel runs the SHA-256 additions on the FMA pipe (+13% hashrate per clock); `--eco` for the best H/W.
- rabbitminer.cc pool protocol, pool failover, vardiff, CPU re-check of every share.
- Self-test at start (real mainnet block + GPU kernel against CPU brute force).
- GPUs numbered in PCI bus order (as in nvidia-smi / HiveOS).
- HiveOS custom miner package; Linux x86_64 build (glibc 2.17+), Pascal … Blackwell.
- Dev fee 1.0%.
