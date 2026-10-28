# Changelog

## 0.5.4 — 2026-10-28
**0.5.4 replaces 0.5.3, which was never released: it contains everything of 0.5.3 (below) plus the 0.5.4 features.
Updating is recommended for everyone who uses an undervolt** (`--coffset`, `--auto-uv`, a HiveOS OC offset): 0.5.2 and
older put the clocks back while the GPUs were still mining, and stopping them at a high offset can cause driver errors
(Xid 13 / 31 / 43, a GSP error), a GPU that stays unavailable until a reboot, or a hang of the rig / PC. 0.5.3 / 0.5.4
stop the GPU work first (see 0.5.3). The stop of the old version during the update is still done by the old version:
if a GPU does not mine after the update (`[unavailable]`), reboot (0.5.4 keeps its profiles).

- **Tested on GPUs** (Linux / HiveOS 8× and 4× RTX 3070, Windows RTX 3080 Ti, Windows RTX 4070 Laptop): stop, per-lock
  profiles, auto-uv, auto-lock, the watchdog, autostart, the API; 0 driver errors at 30+ stops at offsets up to +495.
  Measured tables: MANUAL 5 / README. The next five changes (from those tests) are covered by host-side tests only.
- **A GPU that cannot be opened is not an undervolt failure** (RTX 3070 after the stop fault of the previous miner:
  `CUDA-capable device(s) is/are busy or unavailable`, an Xid 38 at every attempt, until a reset / reboot): before,
  auto-uv took each attempt for a failed check and walked the offset down 30 MHz per try (+315 → 0) and the Xid of the
  open attempt was recorded as a crash at its offset. Now: no record, the offset and the profile stay, one clear log line
  (`GPU1 ... cannot be opened (...): likely needs a GPU reset or a reboot; left out, the other GPUs mine ...`), new
  attempts after 1, 5, 15 min, then every 15 min; it mines as soon as it opens. Status tag `[unavailable]`, API state
  `unavailable`. MANUAL 5d.
- auto-uv: the start from a higher lock's profile is not used when that profile ended on the voltage floor (or at its
  own start): a lower clock reaches the floor even sooner, so carrying that offset down only ate margin (RTX 3080 Ti:
  1400 got +180 from 1560's +210 instead of +120, the same 160 W). The profile file marks such results `vfloor=1`.
- **Log colours:** the expected outcomes of auto-uv / auto-lock (a failed tuning step or quick check, `edge found`,
  `tuning again`, a lock whose tuning failed) are **orange** now (256-colour 208, yellow where that is not supported),
  not red; red stays for what needs attention (a GPU that crashed while mining, is left out or cannot be opened, a final
  `RESULT: FAILED`, pool / connection errors). A check that failed in this run no longer reads "the previous run
  crashed at +495": `the check at +495 failed: tuning again up to +480` (a run that really died during a check:
  `the previous run stopped during its check at ...`). MANUAL 3a.
- **RTX 20 (Turing): auto-uv did nothing** (12× RTX 2060 SUPER, HiveOS OC `CLOCK=200`): the driver reported the
  minimum of the core offset range as `4293967` (an unsigned wrap of −1000 MHz in kHz), so the start became
  `+4293967` ("leaves no room below the cap +495; nothing to do"), auto-uv never owned the offset, and a GPU that kept
  crashing at HiveOS's +200 was never stepped down (HiveOS restart loop). The range is made sane now (unwrapped, kHz
  → MHz, else −1000…+1000; one orange line per GPU): auto-uv tunes from the current offset and a crash steps the GPU
  down as on other GPUs.
- **HiveOS: Extra config arguments over several lines** were cut after the first line (`--auto-uv` on line 1,
  `--referrer X` on line 2 → the referrer was dropped, fee 2 %). h-config.sh joins the lines, h-run.sh reads the whole
  config file.
- Windows: file paths in the log use `\` only (`C:\ffgs\ffgs-gpu-faults.txt`, not `C:\ffgs/ffgs-gpu-faults.txt`).
- **ffgs's clock options win over the HiveOS OC profile** (Rig02: HiveOS applied `LCLOCK=1680` after ffgs had locked
  1500, the GPUs ran 1680 MHz with offsets tuned for 1500 while ffgs's table still said 1500). In the existing 10 s
  status tick (its own clock / offset readings, no extra thread) ffgs compares the core / memory lock, the offsets and
  the power limit with what it set and sets its own again (lock first, then the offset; a raised clock or offset pauses
  that GPU's work for a moment); one orange line per event, at most one per 10 min per GPU
  (`GPU0: core clock changed to 1680 MHz by another tool (HiveOS OC profile?) - ffgs's lock 1500 MHz wins, re-applied`).
  An auto-uv check or auto-lock measurement that ran across it is repeated. GPUs ffgs sets nothing on (`x`, no option)
  stay with HiveOS. Before: auto-uv let a GPU go whose offset someone else changed. A GPU crash (Xid) while another
  tool changes the clocks (Rig02 test: HiveOS `nvidia-oc` set lock 1680 while +330 was on, Xid 43) is not counted
  against the undervolt (orange line; the restart is as usual); when only an offset is seen changed, ffgs sets its lock
  again first. MANUAL 5a, HIVEOS.
- **Per-GPU lists for mixed rigs.** `--lock-cclock`, `--lock-mclock`, `--coffset`, `--moffset`, `--plimit` and now also
  `--uv-min` / `--uv-max` / `--uv-step` and `--temp-limit`: one value for all GPUs or a list in `--devices` order; a
  shorter list repeats its last value (HiveOS OC rule, logged); `x` / `skip` (like empty, `-`, `0`) = leave that GPU
  alone, `x` in a `--uv-*` list = no auto-uv on that GPU; new `=0` sets an offset (`--coffset`, `--moffset`) to exactly 0
  (a plain `0` still means "leave alone"). One start-up line per GPU with what is set on it; new `--dry-run` prints those
  lines and exits without changing anything. MANUAL 5a.
- **auto-uv about twice as fast:** the offset climbs in 30 MHz steps and checks the 15 MHz point only inside the
  interval of a failing step (same 15 MHz result, about half the steps); new `--uv-coarse` (default 2 × `--uv-step`;
  `--uv-coarse 15` = the 0.5.3 climb). A new clock lock starts from the profile of a higher lock minus 30 MHz instead of
  +120. Typically ~3.5–11.5 min per tuning (0.5.3: up to ~16.5 min). MANUAL 5c.
- **`--auto-lock`: the core clock lock chosen per GPU** (NVIDIA, root / Administrator; turns on `--auto-uv`). Each GPU
  mines at several locks (default 1800 … 1200), each at its own undervolt, measures GH/s and W and keeps the best MH/W
  within `--auto-lock-max-loss` % (10) of the top GH/s (`--auto-lock-goal speed`: the top GH/s); saved in
  `ffgs-autolock.txt`, the next start applies it at once. A GPU with its own `--lock-cclock` value keeps it and is not
  swept. MANUAL 5e.
- **GPU stall watchdog:** a GPU whose worker hangs without an Xid (no progress for `--watchdog-hang` s, 60) is stopped
  as a fault and ffgs restarts itself; a GPU below `--watchdog-drop` % (30) of its own hashrate for `--watchdog-minutes`
  (3) gets its worker restarted (on an auto-uv offset 30 MHz lower), the 3rd time within an hour it is a fault.
  `--no-watchdog` turns it off. MANUAL 5g.
- **`--temp-limit` — temperature protection, mainly for laptops / mobile GPUs** (desktop rigs keep their temperature
  with fans): less work (idle gaps between launches, no admin needed; with a ffgs core lock and no offset the lock is
  lowered first) so the GPU stays at or below the limit; `--temp-stop` hard stop, `--temp-mem` / `--temp-hotspot`,
  `--temp-no-clocks`. The real hashrate is shown. After the first real laptop run (RTX 4070 Laptop, a core sensor that
  follows the power within ~1 s): a soft start / resume at 30 % with a ramp, a slower filtered controller with
  rate-limited changes (it swung 10 % ↔ 57 % and ±6–8 °C), `--temp-stop` on 3 readings in a row instead of a single
  spike, resume at C-6 (or C-3 after 60 s) instead of C-10. Honest cost: without admin rights the idle gaps keep the
  GPU at full boost in its launches, so it costs hashrate and MH/W (4070 Laptop: 77 → ~47 MH/W); with `--lock-cclock` as
  Administrator / root the lock is lowered first. MANUAL 5f.
- The status line shows 0 GH/s and 0.0 MH/W for a GPU that does not hash (temp-stop, pool offline) instead of a decaying
  average over idle watts; the 60 s table's MH/W is from the last 10 s (`-` while not hashing).
- Windows: Ctrl+C works even when ffgs was started by a parent that ignores it (scripts, Task Scheduler):
  `SetConsoleCtrlHandler(NULL, FALSE)` at start.
- **Pool health:** on a backup pool the primary (the first `--pool` entry) is checked every `--failback-minutes` (10) on
  a separate connection; after 2 good checks ffgs switches back. A no-accepted-shares watchdog (`--noshare-minutes` 15,
  `--reject-minutes` 5, no usable job for 5 min) reconnects, then moves to the next pool; not in solo mode. MANUAL 3c.
- **`--api [HOST:]PORT`: local read-only HTTP/JSON API** — `/summary`, `/gpus`, `/metrics` (Prometheus); default host
  127.0.0.1, only GET / HEAD, no secrets in the replies; a Host-header whitelist against DNS rebinding (extra names with
  `--api-hosts`). HiveOS h-stats reads the API when `--api` is set (mixed NVIDIA + AMD rig: the AMD process gets
  PORT+1). MANUAL 3d.
- **Windows autostart and new-version notice:** `install-autostart.bat` / `remove-autostart.bat` (or
  `--install-autostart` / `--remove-autostart`) run `start.bat` at logon through Task Scheduler with the highest
  privileges. ffgs checks GitHub for a newer release ~1 min after the start and about every 12 h and logs a line (nothing
  sent, nothing downloaded; `--no-update-check`, `--check-update`). The start scripts have new `AUTO_LOCK`, `TEMP_LIMIT`
  and `API` settings. MANUAL 3e.
- **Merged together:** each new auto-lock lock is tuned from the higher lock's profile minus 30 (~5–12 min per new
  lock); `--temp-limit` never lowers a lock that auto-lock owns (idle gaps / pauses only); the stall watchdog is held
  while auto-uv changes an offset or auto-lock changes a lock (a lock change starts a new baseline), never judges a GPU
  that `--temp-limit` throttles or stops, and only logs a slowdown while NVML reports hardware / driver throttling (HW
  slowdown, thermal, power brake); the API fills `throttle`, `watchdog`, `auto_lock`, `temp_limit` per GPU and
  `pool.failback`. **Windows now restarts itself too** (5d): ffgs exits with code 2 and `start.bat` starts it again in
  10 s; the 12-per-hour limit is kept in `ffgs-restarts.txt`.
- **auto-uv profile file (Rig01 test of 0.5.3):** `--uv-reset-all` forgets only the profiles of the GPUs this ffgs runs
  auto-uv on (by PCI bus; before: the whole file, also the profiles of another ffgs process sharing `/hive-config/ffgs`
  or of the other vendor's ffgs on a mixed rig); `--uv-reset` and `--auto-lock-reset` already acted on this run's GPUs
  only. A tuning stopped before its result (e.g. right after `--uv-reset`) no longer leaves an empty
  `offset=0 … tested=0` line. A profile from another ffgs version (0.5.1 / 0.5.2 / 0.5.3, so after every update) is
  checked with a new 60 s reference at its floor first: the status tag now shows `[reference +240]`, then
  `[check +300]` (it showed `[check +300]` while the card ran at +240), and the log explains the ~85 s.

## 0.5.3 (not released; included in 0.5.4)
- **Safe stop: the GPU work stops first, then the clocks go back.** Every clean exit (Ctrl+C, SIGINT / SIGTERM / SIGHUP,
  closing the console window, `--minutes`, an own restart) used to reset the clock locks and offsets while the GPUs
  still ran kernels at full load; at an undervolt offset that caused Xid 13 / 43, a GSP error on CMP 50HX and a crash of
  a Windows PC (RTX 3080 Ti, 0.5.2 at +495). Now the workers finish their launches (log: `GPU work stopped (N worker(s)
  idle after X ms)`), a running auto-uv check is ended and waited for, and only then the offsets, the locks and the
  power limit go back (`restored: ...`), in that order. A GPU that does not get idle within 3 s is logged and restored
  anyway.
- **`--auto-uv`: the other GPUs mine during a tuning.** Only the GPU being tuned or checked pauses (its own thread); a
  GPU with a verified profile mines at once, and each tuned GPU starts mining as soon as its own tuning ends (0.5.2: all
  GPUs waited ~10–15 min for all).
- **Profiles per core clock lock:** `ffgs-uv-results.txt` keeps one result per GPU, board, driver
  and lock (`1400/mem810`; without a ffgs lock the core clock under mining load picks it, `~1410`). Switching locks
  reuses each lock's profile. A profile verified within `--uv-reval-hours` is applied without a start check; older /
  other-version / lowered ones get a 20 s check of that GPU. 0.5.1 / 0.5.2 results migrate to the profile of the clock
  they were tuned at (used after a check). `--uv-reset` now forgets only the current lock's profile; new `--uv-reset-all`
  forgets all.
- **Voltage floor:** the search stops when two steps in a row each save < 0.5 W (no more climbing to `--uv-max` for
  1–3 W, as on CMP 50HX); reaching `--uv-max` without a failure is logged with the power saved. A start offset that fails
  its check is no longer kept: 30 MHz steps down to the first that passes.
- **Tuning progress and colours:** `step +340 (2/12)`, a tag in the status line (`GPU1 0.000 [tuning +340, step 2/12]`),
  a summary about once a minute with the time left, a `RESULT:` line; auto-uv lines coloured by meaning (progress cyan,
  ok / result green, step-backs yellow, failures red).
- **GPU faults:** the failing GPU is told from the driver's Xid events and remembered
  (`ffgs-gpu-faults.txt`); when no worker is left ffgs restores the clocks and restarts itself (Linux, ≤ 12 per hour).
  With auto-uv the crashed GPU comes back 30 MHz lower after a quick check (a crash at its kept offset: 60 MHz lower per
  2 crashes); without auto-uv a GPU that crashes 2 starts in a row is left out for an hour while the others mine; no
  restart loop. Stopping ffgs during a check no longer counts as a failed step. MANUAL 5d.
- **`--lock-mclock` fallback:** a memory clock the GPU does not list (CMP 50HX: 7001 / 5001 / 405, no 810) becomes the
  lowest supported clock above it, per GPU: `memory clock 810 not supported, using 5001 (lowest supported)`.
- **HiveOS:** the rig efficiency (MH/W) is shown next to the miner version (`0.5.3 64.7 MH/W`).

## 0.5.2
- **Faster CUDA kernel** (same results, every share still re-checked on the CPU). Kavatar SL Pool, saseulmine and solo
  (40-hex nonces), measured on our pool: RTX 3070 5.045 -> 5.306 GH/s (+5.2%, 68.4 -> 73.4 MH/W), RTX 3080 Ti
  8.60 -> 9.05 GH/s (+5.2%), RTX 3070 Laptop 4.38 -> 4.60 GH/s (+5.1%), RTX 4070 Ti 10.71 -> 11.98 GH/s (+11.8%).
  rabbitminer / saseulpool (16-hex): RTX 30 +2.5%, RTX 40 as in 0.5.1. --eco: RTX 3070 +7.4% (40 hex) / +3.3% (16 hex).
- How: loop-invariant work moved out of the hot loop (rotations the compiler could not hoist, rounds 7/13 folded,
  constant schedule terms and K+W pre-added), a per-block shared-memory table of the schedule terms that are the same
  for all threads of a block (40 hex: 6 sigma functions fewer per hash), a different grouping of the additions;
  settings per GPU architecture (RTX 30 / RTX 40 measured separately).

## 0.5.1
- **`--auto-uv`: undervolt auto-tuner** (NVIDIA, root; the FreeForGemPear tuner ported). Raises the core V/F offset in
  15 MHz steps at the locked core clock; every step is checked in a child process running the mining kernel at full
  load (candidate count of every launch against a reference + CPU re-hash). Result = last good step - 15, confirmed,
  saved per GPU/board/driver (`ffgs-uv-results.txt`, HiveOS `/hive-config/ffgs`), reused after a 20 s check. While
  mining: a hardware error steps back 15 MHz, a 20 s re-check every 6 h, hands off if the offset is changed by someone
  else; a crash during a step makes the next start tune below it. `--uv-min/--uv-max/--uv-step/--uv-reset/
  --uv-reval-hours`; Windows `AUTO_UV=1`. RTX 3070 at 1400/810: +370 (edge +400), 73 W, 5.04 GH/s, 0 rejects. MANUAL 5c.
- The console table shows the core offset that is really set (also when auto-uv changed it).
- Kavatar / rabbitminer: the log says why a connection was lost or could not be made (`no answer to getjob for 10 s`,
  `closed by the pool`, `Connection refused`, DNS) instead of only `connection lost`.

## 0.5.0
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
