# FreeForGemSaseul (ffgs) — Manual

[English](#english) · [Русский](#русский) · [中文](#中文)

---

## English

### 1. What it mines
SASEUL (SL) has two chains: the *main chain* (transactions, validators) and the *resource chain* — a PoW chain that
selects validators and pays the miners. A resource block is valid when

    sha256(previous_blockhash + sha256(header_json) + nonce)  <=  2^256 / difficulty

The reward is 2000 "resource" per block, converted to SL by the `Refine` contract (multiplier 0.4276 in October 2026,
×27/32 every season of ~1 billion SL). On a pool you simply receive SL.

### 2. Wallet
A SASEUL address is 44 hex characters (`5a00b883bd62…94ea`). Get one in the official **Guardee** wallet
(Android / iOS) — it creates the wallet from a **seed phrase**; write the phrase down and keep it offline. A SASEUL node
(`saseul-script wallet create`) uses a raw 32-byte private key instead — back that key up. The miner needs only the address.

### 3. Running

    ./ffgs --wallet ADDRESS.WORKER                      # Kavatar SL Pool (default, = --pool kavatar), see 3b
    ./ffgs --pool nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931 --wallet ADDRESS.WORKER
    ./ffgs --pool saseulmine --wallet ADDRESS.WORKER
    ./ffgs --pool saseulpool --wallet ADDRESS.WORKER

| Option | Meaning |
|---|---|
| `--pool HOST:PORT[,HOST:PORT…]` | rabbitminer-protocol pool list (Kavatar SL Pool, rabbitminer.cc, own node); the next one is used when a pool is unreachable; default `sl.kasplay.online:3333` |
| `--pool kavatar` | Kavatar SL Pool (`sl.kasplay.online:3333`), see 3b |
| `--pool saseulmine` | saseulmine.com; the same as `--pool https://pool.saseulmine.com` (any `https://` URL selects this protocol, several URLs = failover list; do not mix with `HOST:PORT` entries) |
| `--pool saseulpool` | saseulpool.com; the same as `--pool nats://nats.saseulpool.com:4222` (any `nats://HOST[:PORT]` selects this protocol, several = failover list; the other servers of the pool's cluster are learned from the server and used too; see 6b) |
| `--wallet ADDRESS[.WORKER]`, `--worker NAME` | payout address and worker name (saseulpool: default worker = the host name) |
| `--referrer ADDRESS` / `--referrer none` | who gets the 1% referral minute (whoever recommended ffgs to you); **your own wallet = total fee 1%**; none / not set = the dev gets it; also sent as the saseulmine referrer (see 6) |
| `--pass PASSWORD` | pool password (default `x`; the token of a solo proxy) |
| `--devices 0,1,…` | GPUs to use, numbered as in `nvidia-smi` / HiveOS (default: all; AMD: see 5b) |
| `--backend auto\|cuda\|amd` | GPU backend: `auto` (default) = NVIDIA CUDA if an NVIDIA GPU is present, else AMD OpenCL |
| `--eco` | efficiency kernel (see 5) |
| `--blocks N`, `--threads N` | launch geometry (default: SM count × 64 blocks × 256 threads) |
| `--bench SECONDS` | hashrate of every selected GPU, no pool |
| `--selftest` | PoW check against a real mainnet block + GPU kernel against a CPU brute force + request-signing check |
| `--pool-test` | saseulmine: one signed job request and your account stats; saseulpool: connect and wait for a job; then exit (no GPU needed) |
| `--lock-cclock MHz[,MHz…]` | lock the core clock (like `nvidia-smi -lgc N,N`); see 5a |
| `--lock-mclock MHz[,MHz…]` | lock the memory clock (like `nvidia-smi -lmc N,N`) |
| `--coffset MHz[,MHz…]` (alias `--uv-offset`) | core clock V/F offset = undervolt at the locked clock |
| `--moffset MHz[,MHz…]` | memory clock offset, may be negative (NVIDIA driver 555+) |
| `--plimit W[,W…]` | power limit |
| `--dry-run` | print the per-GPU settings the options give and exit; nothing is changed (5a, new in 0.5.4) |
| `--oc-info` | clocks, offsets and power limits of the selected GPUs, then exit (no root needed) |
| `--auto-uv`, `--uv-min/--uv-max/--uv-step MHz[,…]`, `--uv-coarse MHz`, `--uv-reset`, `--uv-reset-all`, `--uv-reval-hours H` | undervolt auto-tuner, see 5c |
| `--auto-lock`, `--auto-lock-range`, `--auto-lock-max-loss PCT`, `--auto-lock-goal eff\|speed`, `--auto-lock-reset` | core clock lock chosen per GPU, see 5e (new in 0.5.4) |
| `--temp-limit C[,C…]`, `--temp-stop`, `--temp-mem`, `--temp-hotspot`, `--temp-no-clocks` | temperature protection, mainly for laptops, see 5f (new in 0.5.4) |
| `--watchdog-hang S`, `--watchdog-drop PCT`, `--watchdog-minutes M`, `--no-watchdog` | GPU stall watchdog, see 5g (new in 0.5.4) |
| `--failback-minutes N`, `--noshare-minutes M`, `--reject-minutes K` | pool health: back to the primary pool, no-accepted-shares watchdog, see 3c (new in 0.5.4) |
| `--api [HOST:]PORT`, `--api-hosts NAME[,…]` | local read-only HTTP/JSON API, see 3d (new in 0.5.4) |
| `--install-autostart` (`--task-name`, `--autostart-delay`, `--autostart-bat`, `--autostart-ac-only`, `--task-user`, `--autostart-limited`), `--remove-autostart` | Windows: start `start.bat` at logon, see 3e (new in 0.5.4) |
| `--no-update-check`, `--check-update` | the new-version notice off / check once and exit, see 3e (new in 0.5.4) |
| `--log FILE` | also append the log to FILE (plain text unless `--color always`; the Windows start scripts use `logs\ffgs.log`) |
| `--color auto\|always\|never` | console colors, see 3a (default `auto`) |
| `--no-color` | = `--color never` |
| `--minutes N` | stop after N minutes of mining (tests) |
| `--quick-edit` | Windows: keep the console's QuickEdit mode (ffgs switches it off: a click into the window would pause the output) |

**Console.** Every 10 s a one-line status (hashrate per GPU with board power and efficiency, the rig total, shares of
your wallet and of the dev fee; HiveOS reads this line), every 60 s a table with the 10 s and 5 min hashrate, power,
MH/W, clocks, temperature, fan, the current core/memory offsets, what ffgs set on that GPU, the share counts with percent
and the pool's own view of your wallet (saseulmine `/account`, rabbitminer.cc wallet API, saseulpool.com API; refreshed
every 5 min):

    2026-10-23 01:37:36 [   30s] GPU0 4.374 (75 W, 58.2 MH/W) | total 4.374 GH/s (75 W, 58.2 MH/W) | user sub 2 acc 2 rej 0 | fee sub 0 acc 0 rej 0
    2026-10-23 01:37:36 == ffgs 0.4.0 | up 0h 00m | saseulmine | online | height 2357031 | share diff 163209176362 ==
      GPU  name                  GH/s 10s   5 min      W   MH/W   core    mem  temp  fan          offsets     set by ffgs
        0  RTX 3070                4.629   4.631     75   61.6   1410    810  55 C  0%           +200/-500     lock 1400/810, core +200, mem -500, 120 W
      rig  1 GPU                   4.629   4.631     75   61.6
      shares  accepted 2 (100.0%)  stale 0 (0.0%)  low-diff 0 (0.0%)  rejected 0 (0.0%)  dropped 0  blocks 0  round trip 330 ms  | dev fee acc 0/0
      pool    saseulmine: hashrate 1h 9.01 GH/s, 24h 0.73 GH/s | round shares 823 (0.364% of the pool) | paid 0 (0 payouts) (0 min ago)

Power, temperature and fans come from NVML (read only, no root needed); without NVML they show `-`. Colors: see 3a.

### 3a. Console colors (new in 0.5.0)
One meaning per color, the same in the log lines, the 10 s status line and the 60 s table:

| Message / value | Color |
|---|---|
| **block found** (`*** BLOCK FOUND ***`, `blocks N` in the table when N > 0) | bold bright white on magenta (the loudest style, used for nothing else) |
| accepted / delivered share, connected, `online`, self-test / pool test `ok` | green |
| hashrate values: `GPUn 4.611` and `total … GH/s` in the status line, the GH/s columns of the table, `--bench` | bold bright white |
| energy efficiency `MH/W` (status line and table) | bold bright blue |
| GPU temperature (table) | green below 70 °C, yellow 70–79 °C, red from 80 °C |
| totals: the `rig` row, the table title | bold |
| stale / dropped / low-diff share, waiting for a job, switching server, pool stats not updated | yellow |
| expected outcomes of auto-uv / auto-lock (0.5.4): a failed tuning step or quick check (`step +360 (3/7): FAILED (...)`), `edge found`, `tuning again`, a lock whose tuning failed; clocks changed by another tool and set again (`... by another tool (HiveOS OC profile?) - ffgs's lock 1500 MHz wins, re-applied`, 5a) | orange (256-colour 208; yellow on the Linux text console and terminals without 256 colours) |
| what needs your attention: rejected share, errors, hardware errors, connection lost, `OFFLINE` / `pool offline`, a GPU that crashed while mining, is left out or cannot be opened, a final auto-uv `RESULT: FAILED` | red |
| new block height, share difficulty / divisor changes | cyan |
| dev fee minute (its share lines and status lines) | dim |
| timestamps, the table's column titles | gray |

When colors are used (`--color`, default `auto`):
- `auto`: on a terminal; and on a pipe that is watched from a terminal (stdin is a terminal or the miner runs inside
  GNU screen), e.g. `./ffgs … | tee ffgs.log`. Never for a file redirect, a service (systemd: stdin is `/dev/null`) or
  the `--log` file. `NO_COLOR` (non-empty) turns `auto` off, `FORCE_COLOR` (non-empty, not `0`) turns it into `always`.
- `always`: escape codes on every output, the `--log` file included. `never` (or `--no-color`): plain text everywhere.
- **HiveOS**: `h-run.sh` runs `ffgs … | tee ffgs.log` inside the `miner` screen, so `auto` colors it: `miner` and the
  web "miner log" view (it shows the ANSI colors of `/var/log/miner/ffgs/ffgs.log`) are colored. `h-stats.sh` reads
  the colored log unchanged (colors sit only around whole tokens). Extra config `--color never` gives a plain log,
  `--color always` forces colors should a HiveOS version start the miner without a terminal.
- **Windows**: the Windows 10+ console (ANSI / VT mode, switched on by ffgs); an older console gets plain text.
  Redirected output (`> file`, `| Tee-Object`) is plain unless `--color always`; `logs\ffgs.log` stays plain.
- A terminal with a light background: bright white may be hard to read there, use `--color never`.

### 3b. Kavatar SL Pool (default since 0.5.0)

ffgs mines on **Kavatar SL Pool**, the pool of the ffgs authors, when `--pool` is not given (`--pool kavatar` is the
same): `sl.kasplay.online:3333`, statistics and wallet lookup at **https://kavatar.kasplay.online** (EN / RU / 中文).

- **PPLNS**: a block is shared by the shares of the last 2 network difficulties of work before it, weighted by their
  difficulty — steady miners are not hurt by pool hoppers. **Pool fee 2%.**
- **Automatic payouts every 6 hours from 10 SL**, straight to your address. A payout counts as paid only when the
  transaction is in the chain; one that does not get in within 30 min goes back to your balance.
- The pool runs its own SASEUL node; its reward (resource) is refined to SL and credited when all 9 reward windows of
  the block are confirmed (~15 min after the block). Credits, payouts and blocks are listed on the site.
- Variable share difficulty per connection (about one share every 15 s), 40-hex nonces, no password; the worker name is
  the part after the dot of `--wallet ADDRESS.WORKER` (or `--worker`).
- The console's `pool` line shows the pool's view of your wallet: 10-min hashrate, balance, paid, immature blocks.
- The dev fee minute is mined on the same pool for the ffgs dev wallet (no second connection to another pool).

### 3c. Pool health: back to the primary pool, no-accepted-shares watchdog (new in 0.5.4)
`--pool` with several entries of one protocol is a failover list; **the first entry is the primary pool**:

    ./ffgs --pool sl.kasplay.online:3333,nl.rabbitminer.cc:1931 --wallet ADDRESS.WORKER

Up to 0.5.3 ffgs moved to the next entry when a pool could not be reached, but stayed on the backup until that one
failed too (saseulmine, saseulpool), and a pool that took the connection but credited nothing was never left.

**Back to the primary (failback).** While ffgs mines on a backup entry, the primary is checked every
`--failback-minutes` (default **10**) on a *separate* connection; mining is not touched and nothing is submitted:

| protocol | check |
|---|---|
| rabbitminer (`HOST:PORT`: Kavatar, rabbitminer.cc, solo proxy) | connect, login (same wallet.worker), one `getjob` with a usable job |
| saseulmine (`https://`) | one signed `GET /mine` (the request the miner polls with anyway) with a usable job |
| saseulpool (`nats://`) | connect, subscribe, one block template within 25 s; servers learned from the cluster count as the same pool |

After **2 good checks in a row** (the second one 60 s after the first) ffgs switches back: the job is withdrawn, the GPUs
finish their current launches, the shares found meanwhile are sent to the backup (saseulpool: until the server confirmed
them), then the connection goes to the primary. The GPUs wait about 1–2 s during the switch. Log:

    [user] failback: the primary pool answers again (check 1 of 2), checking again in 60 s
    [user] the primary pool answered 2 checks in a row: switching back to it (from nl.rabbitminer.cc:1931)

`--failback-minutes 0` turns it off. A failed check is logged (`the primary pool is still not usable (...)`).

**No accepted shares (watchdog).** Connected, hashing, but the pool accepts nothing:
- no accepted share for **max(`--noshare-minutes` (15), 10 × the expected share interval)** — the expected number of
  shares comes from the measured hashrate and the pool's share difficulty, so at 15 s per share the window is 15 min,
  at 5 min per share 50 min;
- or **only rejects for `--reject-minutes` (5)** (at least 5 rejected, none accepted);
- or connected but **no usable job for 5 min**.

The first time ffgs reconnects to the same pool; if it happens again on the new connection, it moves to the **next
entry** of `--pool` (after the last one: the first). The reason is logged (`[user] watchdog: no accepted share for 15.0
min while ~60 were expected (...): reconnecting`). `--noshare-minutes 0` / `--reject-minutes 0` turn the parts off.

The watchdog does **not** act: while the GPUs do not hash for your pool (auto-uv tuning / checks — only the measured
hashrate counts —, no job, disconnected, switching); during the dev fee / referral minute and the 10 s after it; in
**solo / own node** mode (a `HOST:PORT` list without Kavatar / rabbitminer.cc); when the GPUs found **no share at all**
although ~10 were expected (a GPU problem, not the pool's: a warning, the pool stays). A primary that the watchdog left
is checked less often each time: ×2 up to ×16 of `--failback-minutes`, back to normal after 2 h on it. On saseulpool
"accepted" means *delivered* (6b), so the watchdog sees a dead server, not a pool that silently ignores shares.

- The fee and referral sessions that mine on your own pool list **follow your session** to the entry it uses (at most
  once per minute, never inside their own minute); the fee minute itself is unchanged. Their other sessions (Kavatar for
  an own-wallet referrer; saseulmine / rabbitminer.cc / Kavatar for solo) fail back on their own.
- A rabbitminer pool that takes the connection but **refuses the login** now makes the next attempt start with the next
  entry. The 60 s table title shows `…, backup pool 2 of 2` while on a backup. saseulpool: a lost server is replaced by
  another server of the same cluster first, the next `--pool` entry after.

### 3d. Local API `--api` (new in 0.5.4)
A read-only HTTP/JSON API for your own monitoring:

    ffgs --wallet ADDRESS ... --api 4068               # http://127.0.0.1:4068 (this machine only)
    ffgs --wallet ADDRESS ... --api 0.0.0.0:4068       # every interface: other machines on the LAN can read it
    ffgs --wallet ADDRESS ... --api 192.168.1.20:4068  # one interface
    ffgs --wallet ADDRESS ... --api [::1]:4068         # IPv6

- Default host `127.0.0.1`. Another address must be written explicitly; a non-loopback one gets a yellow warning
  (anyone who can reach it can read the rig's stats: firewall it). The log shows
  `API: listening on http://127.0.0.1:4068 (read-only: /summary, /gpus, /metrics)`.
- A bad `--api` value stops ffgs at once (exit 1). A busy port does **not** stop mining (`... - mining without the API`).
- **Security:** only `GET` and `HEAD` (anything else `405`), no write or control endpoints, no authentication. Never in
  a reply: pool passwords, the saseulmine client key, the solo proxy token; shown: wallet, worker, referrer (public
  addresses). One small thread (at most 16 connections, 4 KiB request head, 5 s per connection) serves a copy of the
  stats refreshed every 10 s; it never touches a GPU, NVML or a pool. No CORS headers.
- **Host-header whitelist** (DNS rebinding: a web page whose name points at the rig must not read it): allowed Host =
  `localhost`, `127.0.0.1`, `[::1]`, the bound address, any IP literal when bound to `0.0.0.0` / `[::]`, plus the names
  given with **`--api-hosts NAME[,NAME…]`**. Other Host headers get `403`; a request without a Host header is served.

| Path | Type | What |
|---|---|---|
| `GET /`, `GET /summary` | JSON | rig summary |
| `GET /gpus` | JSON | one object per GPU |
| `GET /metrics` | Prometheus text 0.0.4 | rig + per-GPU metrics (hashrates in H/s) |

Values are refreshed every 10 s; `updated_s_ago` tells their age; unknown values are `null` (temperature on AMD, watts
without NVML). Errors are JSON (`{"api_version":1,"error":{"code":404,"message":"..."}}`); before the first stats:
`503` with `Retry-After: 10`. `api_version` changes only on an incompatible change; new fields can be added.

- `/summary`: `version`, `uptime_s`, `pool` (`protocol` `rabbitminer` / `saseulmine` / `saseulpool`; `url` the host the
  session is connected to now; `index` the position of the current failback entry in your `--pool` list (0-based),
  `count`; `connected`, `height`, difficulties, `latency_ms`; `pool_side` the pool's own view of your wallet;
  `failback` below), `wallet` / `worker` / `referrer`, `hashrate` (`ghs_10s`, `ghs_5min`, `ghs_smooth` = the status
  line / HiveOS value), `power_w` / `mhs_per_w` (only when every GPU reports power), `shares` (your session; on
  saseulpool `accepted` = delivered, `shares_delivered_only: true`), `fee` (`phase` `user` / `dev` / `referral`, the
  next fee minute), `gpu_count`.
- `pool.failback`: `{"enabled":true,"entry":1,"entries":2,"on_backup":true,"next_check_s":540,"good_checks":0,
  "interval_x":1,"watchdog":{"enabled":true,"mined_s":600,"expected_shares":40.0,"strikes":0}}` (`next_check_s` null
  when no check is due) — see 3c.
- `/gpus`: per GPU `index` (ffgs / nvidia-smi / HiveOS number), `bus`, `name`, `state` (`mining`; `auto-uv` = paused
  for its own tuning / check; `stopped` = its worker stopped on a GPU error, `error` says why; `left_out`), `hashrate`,
  `power_w`, `mhs_per_w`, `temp_c`, `fan_pct`, `fan_rpm`, `core_mhz`, `mem_mhz`, `offsets` (NVML: NVIDIA only),
  `set_by_ffgs`, `auto_uv` (`null` unless auto-uv manages the GPU; `phase` `tuning` / `check` / `mining`, `status`,
  `step` / `steps`, `offset`, `eta_s`, `result`), `hw_errors`, `shares.found`, and:
  - `throttle`: `{"reasons":["power_cap","hw_thermal"],"hw":true}` (NVIDIA, `null` otherwise); reasons `idle`,
    `app_clocks`, `power_cap`, `hw_slowdown`, `sync_boost`, `sw_thermal`, `hw_thermal`, `hw_power_brake`,
    `display_clock`; `hw` = HW slowdown / SW or HW thermal slowdown / power brake;
  - `watchdog` (5g): `{"on":true,"hangs":0,"slowdowns":0,"worker_restarts":0,"slow_under_hw_throttle":0,"held":false,
    "baseline_ghs":5.3}` or `{"on":false}`;
  - `auto_lock` (5e): `null` without `--auto-lock`, else `{"swept":true,"phase":"sweeping","note":...,"lock":1700,
    "choice":1700,"status":"auto-lock 1700, 2/7: measuring"}` — `phase` one of `sweeping`, `done`, `saved`, `fallback`,
    `aborted`, `skipped`; `lock`, `choice`, `status` may be `null`;
  - `temp_limit` (5f): `null` or `{"limit_c":80,"stop_c":90,"state":"limited","work_pct":72,"clock_mhz":null,
    "temp_c":78,"throttled_s":750,"stops":1}` — `state` `full`, `limited` or `stopped`.
- `/metrics`: `ffgs_info{version,backend,pool,protocol,wallet,worker}`, `ffgs_uptime_seconds`, `ffgs_stats_age_seconds`,
  `ffgs_pool_connected`, `ffgs_hashrate_hs{window}`, `ffgs_power_watts`, `ffgs_shares_total{session,result}`,
  `ffgs_blocks_total`, `ffgs_fee_active{kind}`, and per GPU (`gpu`, `bus`, `name` labels) `ffgs_gpu_up`,
  `ffgs_gpu_hashrate_hs{window}`, `ffgs_gpu_power_watts`, `ffgs_gpu_temperature_celsius`, `ffgs_gpu_fan_percent`,
  `ffgs_gpu_clock_mhz{clock}`, `ffgs_gpu_hw_errors_total`, `ffgs_gpu_shares_found_total`.

Examples:

    curl -s http://127.0.0.1:4068/summary | jq '.hashrate, .shares'
    curl -s http://127.0.0.1:4068/gpus | jq -r '.gpus[] | "\(.index) \(.name) \(.hashrate.ghs_5min) GH/s \(.temp_c) C \(.state)"'

PowerShell: `Invoke-RestMethod http://127.0.0.1:4068/summary`. Prometheus, scraping the rigs by name:

    scrape_configs:
      - job_name: ffgs
        scrape_interval: 15s
        static_configs: [{targets: ["rig1:4068", "rig2:4068"]}]
    # rig1 runs ffgs ... --api 0.0.0.0:4068 --api-hosts rig1 (rig2 the same with rig2); IP targets need no --api-hosts

- **HiveOS:** add `--api 4068` to *Extra config arguments*; `h-stats.sh` then reads hashrates, uptime, shares and watts
  from the API (it finds the address in the log; without an answer within 2 s or with stats older than 60 s it reads
  the log as before). On a mixed NVIDIA + AMD rig `h-run.sh` gives the AMD process `--api PORT+1` (the host is kept) and
  h-stats reads both.
- **Windows:** `set API=4068` in the start scripts.

### 3e. Windows autostart, new-version notice (new in 0.5.4)
**Autostart.** Double-click **`install-autostart.bat`** in the ffgs folder (after setting up `start.bat`); Windows asks
for Administrator once. It creates the Task Scheduler task `ffgs`, which runs the `start.bat` of this folder at **your**
logon, 30 s after it, in the usual miner window on your desktop, with the highest privileges (`LOCK_CCLOCK` /
`COFFSET` / `AUTO_UV` / `AUTO_LOCK` work without a UAC prompt). A second start while it runs is ignored; it starts on
battery too and keeps running when the cable is pulled; no time limit (Task Scheduler's default is 72 h); normal
priority. Settings at the top of `install-autostart.bat`: `TASK` (task name), `DELAY` (seconds after logon, 0 = at
once), `AC_ONLY=1` (laptops: do not start on battery). Run it again after changing them or moving the folder (the ffgs
task is replaced). **`remove-autostart.bat`** removes it (an open miner window keeps running).

From an Administrator console:

    ffgs --install-autostart [--task-name NAME] [--autostart-delay S] [--autostart-bat PATH] [--autostart-ac-only]
                             [--task-user DOMAIN\USER] [--autostart-limited]
    ffgs --remove-autostart [--task-name NAME]

- `--autostart-bat`: default `start.bat` next to `ffgs.exe` (use it for `start-saseulmine.bat` etc.). `--task-user`:
  whose logon starts it (default: the user running ffgs; the .bat passes the user who double-clicked it).
  `--autostart-limited`: without Administrator and without the highest privileges (`start.bat` with clock settings and
  `AUTO_ELEVATE=1` then asks for Administrator at each logon).
- Only a task created by ffgs is replaced or removed; a task of the same name made otherwise is left alone with a
  message. Do not also put `start.bat` in the Startup folder (two miners).
- Laptops: mining on battery drains it fast, but stopping the task when the cable is pulled would not reliably stop the
  miner and Task Scheduler would not start it again; so it never stops; `AC_ONLY=1` only skips a start on battery.
- Linux: `--install-autostart` prints a hint. HiveOS starts and restarts the miner itself; plain Linux: a systemd
  service with `Restart=always` (example in `docs/0.5.4-winauto-update.md` of the source repository).

**Start script settings (0.5.4).** Besides `AUTO_UV`: `AUTO_LOCK=1` (`--auto-lock`, 5e; counts as a clock setting for
`AUTO_ELEVATE`), `TEMP_LIMIT=80` (`--temp-limit`, 5f; no Administrator needed), `API=4068` (`--api`, 3d).

**New-version notice.** While mining, about a minute after the start and then about every 12 h (random spread), ffgs
asks GitHub for the latest release of `pepsykolya/FreeForGemSaseul` and, when it is newer, logs (yellow)
`ffgs 0.5.5 is available: https://github.com/pepsykolya/FreeForGemSaseul/releases/tag/v0.5.5 (this is 0.5.4; ...)`.
- One plain `GET https://api.github.com/repos/pepsykolya/FreeForGemSaseul/releases/latest` with `User-Agent:
  ffgs/<version>`; no wallet, worker, GPU or other identifier is sent. Nothing is downloaded or installed.
- In its own thread: GitHub unreachable or slow (or its rate limit of 60 requests an hour per IP) → nothing is logged,
  mining is not affected. Not done in `--selftest`, `--bench`, `--oc-info`, `--pool-test`.
- `--no-update-check` turns it off (HiveOS: Extra config arguments; Windows: `EXTRA`). `ffgs --check-update` checks
  once and exits: exit code 0 up to date, 10 newer release, 1 check failed.

### 4. HiveOS
See [HIVEOS.md](HIVEOS.md).

### 5. Tuning
- The PoW is pure compute (no memory traffic): the **memory clock can be lowered** to the minimum to save power.
- **Default kernel** — highest hashrate per clock. Best when the card is power-limited or the core clock is locked high.
- **`--eco`** — about 12% fewer GH/s per clock but ~17% less power; best H/W on undervolted cards.
- **Measured (0.5.3 / 0.5.4, default kernel, Kavatar SL Pool, 40-hex nonces).** GH/s = median of the 10 s status
  lines after 60 s of mining (≥ 4 min per point), W = NVML board power; the auto-uv offset is what `--auto-uv` found on
  that card at that lock (voltage floor or edge minus one step). Recommended settings in **bold**.

  **RTX 3070** (HiveOS, driver 580.82.07; Rig01 8 cards, 2–4 cards per lock, median; Rig02 4 cards at 1500: the same
  5.62 GH/s, 76 W per card):

  | Core lock | Memory | auto-uv offset | GH/s | W | MH/W | W at offset 0 | |
  |---|---|---|---|---|---|---|---|
  | 1200 | 810 | +240 … +255 | 4.51 | 65 | 69 | 71 | |
  | 1300 | 810 | +240 … +255 | 4.90 | 73 | 67 | 84 | |
  | 1400 | 810 | +255 … +330 | 5.29 | 75 | 70.5 | 88 | |
  | **1500** | **810** | +330 … +435 | **5.62** | **76** | **73.9** | 98 | **best MH/W** |
  | 1600 | 810 | +330 … +390 | 6.01 | 89 | 67.5 | 119 | |
  | **1700** | **810** | +315 … +345 | **6.40** | **106** | **60.4** | 151 | **balance** (best MH/W within −10 % of the top GH/s) |
  | **1800** | **810** | +330 … +345 | **6.74** | **121** | **55.7** | 186 | **max hashrate** |
  | 1400 | stock | +300 | 5.29 | 104 | 50.9 | — | memory 810 saves 27 W |

  `--lock-cclock 1500 --lock-mclock 810 --auto-uv` (best MH/W), `1700` (balance), `1800` (max). Cards differ by up to
  25 % in watts at the same lock (1400: 67–79 W); the hashrate is the same (≈ 3.74 GH/s per 1000 MHz).

  **RTX 3080 Ti** (Windows 10, driver 591.59, PL 350 W, one card; `auto-lock` rows: ffgs's own 120 s measurement):

  | Core lock | Memory | Offset | GH/s | W | MH/W | |
  |---|---|---|---|---|---|---|
  | 1200 | 810 | 0 | 7.73 | 137 | 56.5 | |
  | 1400 | 810 | +120 (auto-uv, floor) | 9.07 | 160 | 56.9 | offset 0: 164 W |
  | 1500 | 810 | 0 | 9.65 | 184 | 52.3 | |
  | 1560 | 810 | +210 (auto-uv) | 10.03 | 177 | 56.6 | offset 0: 206 W |
  | **1600** | **810** | +240 (auto-uv) | **10.32** | **180** | **57.4** | **best MH/W** |
  | 1650 | 810 | 0 | 10.60 | 240 | 44.2 | |
  | **1700** | **810** | +240 (auto-uv) | **10.98** | **212** | **51.9** | **balance** (`--auto-lock` chose it too) |
  | 1750 | 810 | 0 | 11.27 | 299 | 37.7 | |
  | 1800 | 810 | +150 (auto-uv, edge +180) | 11.49 | 268 | 42.9 | |
  | **not locked** | **810** | 0 | **11.54** | **332** | **34.8** | **max hashrate** (~1800 MHz) |
  | 1400 | stock | 0 | 9.13 | 221 | 41.3 | memory 810 saves 57 W |
  | not locked | stock | 0 | 11.13 | 349 | 31.9 | power-limited: slower than with memory 810 |

  `--lock-cclock 1600 --lock-mclock 810 --auto-uv` (best MH/W), `1700` (balance), `--lock-mclock 810` without a core lock
  (max). Up to 1400 the core voltage is already at its floor (auto-uv: +120, −4 W); the undervolt pays off from ~1500 up.

  **RTX 4070 Laptop** (Windows 11, on AC, no Administrator: no clock control): without a limit 4.80 GH/s, 63 W,
  **77 MH/W** — the driver itself holds the GPU at 86–87 °C (its thermal slowdown, ~1700 MHz). `--temp-limit` keeps it
  cooler at a cost (5f): limit 75 → 1.78 GH/s, 38 W, 47 MH/W; limit 70 → 1.5 GH/s, 32 W, 46 MH/W; limit 80 is no use on
  this laptop (it runs at 86–87 °C anyway, the bursts go hotter). Measured before the 0.5.4 controller retune (soft
  start, 3-reading stop); the retune is tested on a model of this laptop, not yet on the laptop itself.
- **Memory clock:** lock it at 810 (`--lock-mclock 810`; CMP 50HX: 5001, 5a). SL needs no memory bandwidth; the stock
  memory clock only adds watts.

### 5a. GPU clock control (new in 0.4.0)
ffgs can set the clocks of the GPUs it mines on:

| Option | What it does |
|---|---|
| `--lock-cclock N` | core clock locked to N MHz (`nvidia-smi -lgc N,N`) |
| `--lock-mclock N` | memory clock locked to N MHz (`nvidia-smi -lmc N,N`); SL needs no memory bandwidth, use the lowest (810 on RTX 30/40). A clock the GPU does not support becomes its lowest supported clock above it (0.5.3; CMP 50HX has no 810: `memory clock 810 not supported, using 5001 (lowest supported)`) |
| `--coffset N` / `--uv-offset N` | core clock V/F offset in MHz: at a locked core clock a positive offset means the same clock at a lower voltage (undervolt) |
| `--moffset N` | memory clock offset in MHz, may be negative (driver 555+) |
| `--plimit W` | power limit in W |

- One value applies to every mining GPU; a comma list gives one value per GPU in `--devices` order (without
  `--devices`: every GPU in nvidia-smi / HiveOS order; with `--devices 2,0` the first value is for GPU2). An empty entry,
  `-`, `0` or `x` (also `X`, `skip`) leaves that GPU's setting alone: `--devices 0,1,2 --lock-cclock 1400,,1560`.
- **A shorter list repeats its last value** for the remaining GPUs (the HiveOS OC rule, 0.5.4; a log line says so:
  `--lock-cclock: 2 values for 3 GPUs: the last one (1500) also applies to the remaining 1 GPU (HiveOS rule)`). More
  values than GPUs, a value that is not a number or out of range: an error at start (exit 1, nothing changed). Write
  lists **without spaces** (HiveOS and the start scripts split arguments at spaces).
- **`=0` sets an offset to exactly 0** (`--coffset`, `--moffset` only; 0.5.4): `--coffset 325,=0`. A plain `0` keeps
  meaning "leave alone" (in a HiveOS OC profile `0` means "set 0"; here write `=0`). Without `--coffset` the offset is
  not touched at all.
- The same list rule holds for `--uv-min` / `--uv-max` / `--uv-step` (5c) and `--temp-limit` (5f).
- **Start-up lines (0.5.4):** one line per GPU with what this run sets on it (core / memory lock, offsets, power limit,
  auto-uv range, and with `--auto-lock` whether that GPU's lock is swept):

      per-GPU settings (--devices order; applied below, each with its read-back):
        GPU0 (RTX 3070): core lock 1500 MHz, memory lock 810 MHz, core offset +325 MHz, auto-uv from auto up to +400, step 15
        GPU1 (CMP 50HX): core lock 1600 MHz, memory lock 810 MHz, auto-uv from auto up to +495, step 15

  (`--lock-cclock 1500,1600 --lock-mclock 810 --coffset 325,x --auto-uv --uv-max 400,495` on a mixed rig.)
- **`--dry-run`** prints these lines and exits; nothing is changed (no root needed; no GPU needed with `--devices`). On
  the rig it also shows the memory clock fallback of each GPU (`memory lock 810 MHz (not supported here: 5001)`).
- Needs **root** (Linux) / **Administrator** (Windows). Without it ffgs prints one line
  (`needs root …` / `needs Administrator …`) and mines at the current clocks.
- Applied before the start-up self-test (so the kernel is checked at the new clocks); every value is logged with its
  read-back, and ~30 s into mining a line shows the clocks the card actually runs at.
- **Restored on exit**: Ctrl-C, SIGTERM/SIGHUP, closing the console window, `--minutes`, a fatal error. Clock locks are
  reset to the driver default (the driver cannot report a previous lock), offsets and the power limit go back to the
  values read before the change. If ffgs is killed (kill -9, crash, power cut while the driver keeps running), the
  marker file `ffgs-oc-<bus>.restore` next to the binary makes the next ffgs start put everything back, even without
  clock options. A marker of another running ffgs is respected (that GPU is left alone), a marker from before a reboot
  is discarded.
- Only GPUs in `--devices` are touched; GPUs are matched to NVML by PCI bus id. NVML is loaded at run time
  (`libnvidia-ml.so.1` / `nvml.dll`); without it ffgs still mines.
- `--oc-info` prints the current clocks, offsets (with the allowed range) and power limits, without changing anything.
- **ffgs's clock options win over other OC tools (0.5.4).** A value ffgs sets on a GPU (`--lock-cclock`,
  `--lock-mclock`, `--coffset`, `--moffset`, `--plimit`, the offset of `--auto-uv`, the lock of `--auto-lock`) is kept
  **even if the HiveOS OC profile has other values** (HiveOS applies its OC after a reboot or an OC change, possibly
  after ffgs started; MSI Afterburner / `nvidia-smi` the same). In its 10 s status tick ffgs compares the clocks,
  offsets and power limit it reads anyway for the status line with its own values; on a difference it sets its own
  again (lock first, then the offset; a higher clock or offset than ours first pauses that GPU's work for a moment).
  One orange line per event, at most one per 10 min per GPU with the count in between:
  `GPU0: core clock changed to 1680 MHz by another tool (HiveOS OC profile?) - ffgs's lock 1500 MHz wins, re-applied
  with the GPU paused`; the clocks table shows `re-applied Nx`. An auto-uv check or auto-lock measurement that ran
  across such a change is discarded and repeated. A GPU that crashes (Xid) while another tool changes its clocks
  (within 30 s of such an event on it, 15 s on any GPU of the rig, or with an offset / clock different from ffgs's at
  the crash) is not counted against its undervolt: orange line `... crashed (Xid 43) while another tool changed its
  clocks (HiveOS OC?): ... - not counted against the undervolt`, ffgs restarts as usual. When only an offset is seen
  changed, ffgs also sets its lock again first (the other tool's lock may already be on). A lock cannot be read back, so it is seen from the clock: above our
  lock, or clearly below it while hashing without a power / thermal reason and not slowed down by `--temp-limit`
  (2 readings in a row). GPUs and values ffgs does not set (`x`, no option) are left to HiveOS / the other tool.
  The table and HiveOS h-stats show the clocks the GPU really runs at. Cost: a few µs per GPU and tick (no extra
  thread; with `--plimit` one power-limit read).
- **On exit** ffgs puts back what it found at **its** start (offsets, power limit) and resets the locks it set. If
  HiveOS applied its OC after ffgs started, that is the state before HiveOS's OC, not the OC profile; HiveOS applies its
  OC again at the next miner start.
- Windows: set `LOCK_CCLOCK`, `LOCK_MCLOCK`, `COFFSET`, `MOFFSET`, `PLIMIT` in `start.bat` / `start-saseulmine.bat` /
  `start-saseulpool.bat` (lists as above, e.g. `set COFFSET=325,x`; `--uv-*` lists go into `EXTRA`).
  With any of them set, the script asks Windows to reopen itself as Administrator (`AUTO_ELEVATE=1`, the default).

**Measured settings per GPU** (RTX 3070, RTX 3080 Ti, RTX 4070 Laptop): the tables in section 5 above. RTX 3070:
`--lock-cclock 1500 --lock-mclock 810 --auto-uv` for the best MH/W.

### 5c. Undervolt auto-tuner `--auto-uv` (new in 0.5.1, per clock lock since 0.5.3)
ffgs finds the undervolt itself: it raises the core V/F offset of each NVIDIA GPU,
checks every step and keeps the last good offset minus one 15 MHz step of margin.

    sudo ./ffgs --wallet <address>.<worker> --lock-cclock 1500 --lock-mclock 810 --auto-uv

- **Use it at a locked core clock** (`--lock-cclock`, or the lock of the HiveOS OC profile, or `--auto-lock`, 5e): then
  a higher offset means the same clock at a lower voltage. NVIDIA only, needs root / Administrator.
- **Coarse to fine (0.5.4):** the offset climbs in **30 MHz** steps (`--uv-coarse`). When a step fails, the tuner goes
  back to the last good offset and checks the **15 MHz** point inside that one 30 MHz interval (one extra step), then
  keeps one 15 MHz step of margin. The result is the same 15 MHz edge a 15 MHz climb finds, with about half the steps.
  (Starting at the top and going down was rejected: the first steps would be the ones most likely to crash the GPU.)
- **A new clock lock starts near a known profile (0.5.4):** when the GPU has a verified profile of a higher (or the
  same) core clock lock with the same memory lock, the start is **that profile's offset minus 30** instead of +120 (the
  nearest such lock counts; lower locks hold higher offsets). The warm-up checks that start as always. Not used with
  `--uv-min`, after a crash, when it would not raise the start, or when that profile ended on the **voltage floor** or
  at its own start (a lower clock reaches the floor even sooner: carrying that offset down only eats margin; logged:
  `profile 1560/mem810 +210 of a higher clock ended on the voltage floor: not starting from it`).
- **Tuning:** a warm-up check at the start offset (2 min), then ~30 s per step, then a 2 min confirmation: typically
  **~3.5–11.5 min** (the fixed part, warm-up + confirmation, is ~4.3 min; a second lock with a known profile of a higher
  lock ~6.5 min; 0.5.3 needed up to ~16.5 min). **Only the GPU being tuned waits; the other GPUs mine meanwhile**, and
  each GPU mines as soon as its own tuning is over (0.5.3; before, every GPU waited for all). The log shows the progress
  (`step +340 (2/12): ok`), the status line a tag after that GPU's hashrate (`GPU1 0.000 [tuning +340, step 2/12]`),
  and about once a minute a summary (`auto-uv: tuning 2 GPU(s) (GPU1, GPU3), ~6 min left`). The tuning ends with a
  `RESULT:` line. Colours (with `--color`): progress cyan, passed checks / results green, step-backs yellow, failures red.
- **The voltage floor:** when two steps in a row each save too little (0.5 W per 15 MHz, i.e. < 1 W for a 30 MHz step),
  the search stops below them instead of climbing to `--uv-max` (the voltage is at its floor; more offset only eats the
  margin; the result is the good offset before the two flat steps). If the search reaches
  `--uv-max` without a failure, the log says so with the power saved.
- **A start offset that fails** its check is never kept: ffgs goes down in 30 MHz steps to the first offset that passes
  and mines there (also below your own offset).
- **Profiles per clock lock (0.5.3):** the result is saved per GPU, board, driver **and core clock lock** (`1400/mem810`
  = `--lock-cclock 1400 --lock-mclock 810`; without a ffgs lock, the core clock under mining load picks the profile,
  `~1410`). Switching the lock and back reuses each lock's profile. A profile verified within `--uv-reval-hours` is
  **applied at once** (the GPU mines immediately); an older one, one from another ffgs version, or one lowered after a
  crash gets a 20 s check first (only that GPU waits). A profile without check counts of this ffgs version (from 0.5.1 /
  0.5.2, another ffgs version, another `--blocks` / `--threads`) first gets a new 60 s reference at its floor, then the
  20 s check: ~85 s; the status tag shows `[reference +240]`, then `[check +300]`, and the log says so. Results of 0.5.1 /
  0.5.2 become the profile of the clock they were tuned at and are used for a lock close to it after a check.
- **The check** runs the mining kernel at full load in a separate process on fixed test jobs: the number of candidates of
  every launch must be exactly the reference (a GPU that computes even one hash wrong changes it within seconds) and every
  stored candidate is re-hashed on the CPU. A crash or hang of the GPU only kills that process.
- **While mining:** a hardware error (bad candidate) steps the GPU back by 15 MHz (saved, checked again at the next
  start); every 6 h a 20 s re-check (that GPU pauses for it). If something else changes the offset (HiveOS OC), ffgs sets
  its own again (5a; since 0.5.4, before: auto-uv let that GPU go). A GPU fault (Xid): see 5d.
- Saved in `ffgs-uv-results.txt` next to the binary (HiveOS: `/hive-config/ffgs`, kept over miner updates). If ffgs dies
  during a step (kill, Xid, power), the next start puts the offset back and tunes below that step; stopping ffgs (Ctrl-C,
  HiveOS miner stop) during a check is not counted as a failure. The original offset is restored on exit like with
  `--coffset`.
- Options: `--uv-min MHz` (search start; default: the current offset, else +120, RTX 40/50 at least +200; or the
  higher-lock hint above), `--uv-max MHz` (default +495), `--uv-step MHz` (15: the **fine** step = precision and margin
  of the result, confirmation and hardware-error step-backs; an explicit `--uv-step 15` keeps the speed-up),
  `--uv-coarse MHz` (new in 0.5.4, the climbing step, default 2 × `--uv-step`; `--uv-coarse 15` or anything ≤ the fine
  step = the 0.5.3 climb), `--uv-reset` (forget the profile of this run's clocks and tune again; the profiles of other
  locks stay), `--uv-reset-all` (forget every profile of **this run's GPUs**, all locks; since 0.5.4 the lines of other
  GPUs in the file stay — a mixed rig or two ffgs processes sharing `/hive-config/ffgs` keep each other's profiles),
  `--uv-reval-hours H` (6, 0 = never). A tuning stopped before its result leaves no line in the file.
  `--uv-min`, `--uv-max`, `--uv-step` take **per-GPU lists** (0.5.4, the rule of 5a): `auto` = the default, empty / `-` /
  `x` = **no auto-uv on that GPU** (`--uv-max 400,x`; log: `auto-uv: GPU1 left alone (empty / - / x in a --uv-* list)`).
  Windows: `AUTO_UV=1` in the start scripts. `--coffset` together with `--auto-uv` = the search starts from that offset.
  `--uv-reset` / `--uv-reset-all` act once: an own restart after a GPU fault (5d) does not repeat them.
- Apart from the higher-lock hint the start is not chosen by the lock: the edges differ too much between cards of one
  type (RTX 3070 at 1700: +345 … +375). The start stays your current offset (e.g. `--coffset 325`); a start that fails
  costs a few checks, not the tuning. Measured results per lock: the tables in section 5.

### 5d. GPU faults (new in 0.5.3)
A GPU fault (driver Xid 13 / 43, "an illegal memory access") used to end ffgs, and HiveOS restarted it into the same
fault. Now:
- the failing GPU is found from the driver's Xid events and logged: `faults: GPU4 (bus 0000:04:00.0, RTX 3070) FAILED:
  Xid 43 reported by the driver for this GPU`; it is remembered with its offset in `ffgs-gpu-faults.txt` (next to the
  binary; HiveOS: `/hive-config/ffgs`);
- the other GPUs keep mining when they can; when no worker is left (or a GPU hangs, 5g), ffgs puts the clocks back and
  **restarts itself**, at most 12 times an hour:
  - Linux: the same process and log (exec); past the limit it exits and HiveOS restarts it as before;
  - Windows (0.5.4): ffgs exits with code 2 and `start.bat` starts it again in 10 s (all GPUs back in ~20 s). The
    restart times are kept in `ffgs-restarts.txt` in the state directory (next to `ffgs-uv-results.txt`); a start within
    120 s of the last one counts as that restart, so the 12-per-hour limit holds: past it ffgs waits until the oldest
    restart of the hour has aged out, then exits. A start by hand later begins a new count;
  - `--uv-reset`, `--uv-reset-all` and `--auto-lock-reset` are not repeated on such restarts;
- **with `--auto-uv`:** a GPU that crashed at its undervolt comes back **30 MHz lower** after a 20 s check (no tuning from
  scratch; profile updated). A GPU that crashes 2 starts in a row at its own (kept) offset is lowered by 60 MHz per
  2 crashes, down to 0, then left out;
- **without `--auto-uv`:** ffgs does not change offsets; a GPU that crashes 2 starts in a row is **left out of mining for
  an hour** (`... is LEFT OUT of mining ...`), the others mine; when every GPU is left out ffgs waits instead of exiting
  (no restart loop);
- **A GPU that cannot be opened (0.5.4)** — `CUDA-capable device(s) is/are busy or unavailable`, often with an Xid 38 at
  every attempt, e.g. after a fault of the previous miner when it was stopped — is **not** an undervolt or offset fault:
  nothing is recorded, its offset and auto-uv profile stay. ffgs logs it once (`GPU1 ... cannot be opened (...): likely
  needs a GPU reset or a reboot; left out, the other GPUs mine ...`), shows `[unavailable]` in the status line
  (API: `"state":"unavailable"`) and tries again after 1, 5 and 15 min, then every 15 min; it mines as soon as it opens.
  A tuning or check of that GPU waits the same way and goes on at the same offset. Usually only a reboot frees it.
- 30 min of mining without a fault clears the count. Deleting `ffgs-gpu-faults.txt` forgets everything at once.

### 5e. Automatic core clock lock `--auto-lock` (new in 0.5.4)
ffgs picks the core clock lock of each NVIDIA GPU itself: it mines at several locks, each at its own undervolt
(auto-uv, 5c), measures hashrate and power, and keeps the most efficient lock that loses at most 10 % of the top hashrate.

    sudo ./ffgs --wallet <address>.<worker> --lock-mclock 810 --auto-lock

- **NVIDIA only, root / Administrator.** `--auto-lock` turns on `--auto-uv`. `--lock-mclock`, `--moffset`, `--plimit`
  work as before (the memory lock is part of the saved key: a different memory lock is swept anew).
- **`--lock-cclock` together with `--auto-lock`:** a GPU with its own `--lock-cclock` value (one value = every GPU; a
  per-GPU list = those GPUs) keeps that lock and is **not swept**; the others are. `--lock-cclock 1400,x --auto-lock`
  sweeps GPU1 only. If every GPU has a value, nothing is swept (a warning; auto-uv tunes each at its lock). A GPU with
  `x` in a `--uv-*` list (no auto-uv) is not swept either. The start-up per-GPU lines (5a) show it in the `auto-lock`
  column (`sweeps the core lock`, `off (own --lock-cclock)`, `off (no auto-uv)`).
- **Locks tried:** by default 1800, 1700 … 1200 MHz, nothing above the card's maximum graphics clock (a card that cannot
  reach 1600 gets the 5 locks below its maximum). `--auto-lock-range 1200-1700:100` (from-to[:step], step 100 by
  default) or a list `--auto-lock-range 1300,1450,1600`.
- **The sweep, highest lock first, per GPU:** set the lock → auto-uv applies the saved profile of that lock at once, or
  checks / tunes it (a new lock starts from the higher lock's profile minus 30, 5c: **~5–12 min**; **only this GPU
  pauses**) → the GPU **mines** at it: 45 s to settle, then 120 s measured (GH/s from the GPU's own hash counter,
  average NVML watts, median core clock). **Shares found while measuring go to the pool as usual.** The other GPUs mine
  all the time; all GPUs sweep in parallel.
- **Early stop:** once a lock is more than the allowed loss below the top GH/s, the lower locks are not measured.
- **Choice:** `--auto-lock-goal eff` (default) = the best MH/W among the locks within `--auto-lock-max-loss` % (10, 0..90)
  of the highest GH/s measured; `--auto-lock-goal speed` = the highest GH/s.
- **Points that do not count:** the clock did not hold the lock (median more than max(45 MHz, 3 %) below it: power /
  thermal limit) → `not valid`; hardware errors while measuring → `not valid` (and auto-uv steps that profile back);
  no steady mining (no job, pool offline) → measured again up to 3 times, then `not valid`. A lock the driver refuses,
  a lock where auto-uv finds no passing offset, or a GPU fault (Xid) while mining at it → `FAILED`, next lock lower. If
  ffgs dies during a lock (Xid, freeze, power cut), the next start marks that lock `crashed` and never tries it again
  (until `--auto-lock-reset`).
- **No lock control** (some laptops, old cards): `core clock lock ... not supported on this GPU: fallback to auto-uv at
  the current clocks`; the GPU mines as with `--auto-uv` alone. No valid lock at all: back to the driver default clocks.
- **The result** is a table in the log (simulated numbers):

      auto-lock: GPU0 (bus 0000:0D:00.0, RTX 3070) RESULT (goal eff, max loss 10%, top 6.480 GH/s):
      auto-lock:   lock  offset    GH/s       W   MH/W
      auto-lock:   1800    +210   6.480   118.4   54.7
      auto-lock:   1700    +225   6.120   106.2   57.6  ★ chosen
      auto-lock:   1600    +240   5.760    95.1   60.6
      auto-lock:   1500       -       -       -      -  skipped: below the cut, not measured
      auto-lock: GPU0 (bus 0000:0D:00.0, RTX 3070) mining at lock 1700 ★ (saved; --auto-lock-reset to sweep again)

  While it runs, the status line shows a tag after that GPU's hashrate: `GPU0 6.120 [auto-lock 1700, 2/7: measuring]`.
- **Saved** per GPU, board, driver and memory lock in `ffgs-autolock.txt`, next to `ffgs-uv-results.txt` (HiveOS:
  `/hive-config/ffgs`). **The next start applies the saved lock at once** (with its auto-uv profile). A changed
  `--auto-lock-goal` / `--auto-lock-max-loss` is re-chosen from the saved points without measuring; a wider range or a
  larger loss measures only the missing locks. `--auto-lock-reset` forgets the points and sweeps again (the auto-uv
  profiles stay; add `--uv-reset` to re-tune every lock of the sweep once). A new driver = a new sweep. An own restart
  (5d) does not repeat `--auto-lock-reset`.
- **Time:** the first sweep of a GPU costs, per lock, the auto-uv tuning of a new lock (GPU paused) plus ~3 min of
  measured mining; with the early stop typically 3–5 locks per GPU, in parallel on all GPUs. Later starts: nothing.
- **With `--temp-limit`** (5f) the lock auto-lock owns is never lowered (idle gaps / pauses only). The stall watchdog
  (5g) is held while the lock changes and starts a new baseline at the new lock.
- **HiveOS:** add `--auto-lock` (and e.g. `--lock-mclock 810`) to *Extra config arguments* and leave the **core clock
  lock empty in the HiveOS OC profile** (ffgs sets and on exit resets the lock). **Windows:** `set AUTO_LOCK=1` in the
  start script (it counts as a clock setting for `AUTO_ELEVATE`).

### 5f. Temperature protection `--temp-limit` (new in 0.5.4; mainly for laptops)
**Meant mainly for laptops and mobile GPUs.** A laptop GPU shares its cooling with the CPU and its fans cannot be set,
so a long mining run sits at the GPU's own throttle point (~87 °C). `--temp-limit` keeps it cooler by giving it less
work. Desktop rigs normally keep their temperatures with fans (HiveOS autofan) and do not need this.

| Option | Meaning | Default |
|---|---|---|
| `--temp-limit C[,C…]` | keep the GPU at or below C (40..100); one value or a per-GPU list (5a), `0` / empty = off for that GPU | off |
| `--temp-stop C2[,…]` | hard stop: at C2 (3 readings in a row) the GPU stops mining until it is 6 °C below the limit | min(C+10, 90), at least C+3 |
| `--temp-mem C[,…]` | memory junction limit, where the driver reports it (stop = it + 10) | C+15 |
| `--temp-hotspot C[,…]` | hotspot (AMD "junction") limit, where reported (stop = it + 10) | C+15 |
| `--temp-no-clocks` | never lower the core clock lock, idle gaps only | — |

Example (laptop, Windows, no Administrator): `ffgs.exe --wallet ... --temp-limit 80`, or `set TEMP_LIMIT=80` in the
start script.

- **Soft start:** mining starts at a work fraction of 30 % and ramps up (no log line unless the GPU gets near its
  limit; a GPU that stays cool reaches full speed within ~15–30 s). A laptop core sensor follows the power within about
  a second: a start at 100 % used to overshoot the limit by 15–25 °C.
- At **C-3** (filtered reading) the GPU enters the limit state; a controller sets the *work fraction* (10–100 %) so the
  temperature stays at **C-2 .. C-1**. It works on a reading filtered over a few seconds and changes the work fraction
  slowly (at most +5 % / −20 % per second), so a fast laptop sensor does not make it swing. The work fraction is applied
  as idle gaps between launches: no admin rights needed, works on laptops whose clocks cannot be set and on AMD.
- Where ffgs itself locked the core clock (`--lock-cclock`, root / Administrator, NVIDIA) and no core offset of ffgs or
  auto-uv is on that GPU, it **lowers that lock first** (15 MHz steps, down to 60 % of the lock / at least 800 MHz) and
  adds idle gaps only below that (a lower clock runs at a lower voltage: less energy per hash than idling). With
  `--auto-uv` / `--coffset` the lock is never lowered (that offset was found at that lock), nor with `--auto-lock` (5e).
- **Full speed again** (one log line) after 30 s at full speed with the GPU at or below **C-5**.
  **Hard stop:** any sensor at its stop temperature for 3 readings in a row (or 5 °C above it at once) → no launches
  until every sensor is 6 °C below its limit (or 3 °C below once it has been stopped for 60 s: a warm laptop may idle
  near C-6), then mining resumes at 30 % and ramps up. A single 1-second spike does not stop it.
- **What it costs — honestly.** Without Administrator rights the only tool is idle gaps, and in its launches the GPU
  runs at its full boost clock (the driver's own thermal slowdown lets go in the gaps). So the limit lowers the
  temperature and the noise at the cost of hashrate **and** efficiency. Measured on an RTX 4070 Laptop (Windows, on AC,
  no admin): no limit 4.80 GH/s, 63 W, **77 MH/W** with the driver holding 86–87 °C itself; `--temp-limit 75` / `70`
  1.5–1.8 GH/s, 32–38 W, **~47 MH/W** (measured before the 0.5.4 retune of the controller described here; the retune
  was tested on a model of that laptop). Use it to keep a laptop cooler and quieter, not to mine more per watt. With
  Administrator / root and `--lock-cclock`, ffgs lowers the clock lock first (next point), which keeps the efficiency
  much better than idle gaps.
- **Log:** one line per state change only. The status line shows `GPU0 3.100 [temp-limit 72%]`,
  `[temp-limit 1290 MHz]` / `[temp-limit 840 MHz 60%]` (lowered lock, + idle gaps) or `[temp-stop 91 C]`; the 60 s table
  adds `temp-limit 80 C: 72% now, throttled 12m 30s, 1 stop(s)`. HiveOS `h-stats.sh` reads past these tags. The shown
  and reported hashrate is the real one; while the GPU does not hash (temp-stop, pool offline) it shows 0 and 0.0 MH/W
  (the table: `-`).
- **Test hook** `FFGS_TEST_TEMP` (developers only) replaces the temperature *reading*: the real GPU is then not
  protected at all (it heats up as without a limit). Use it only for short runs on a cool GPU.
- **Sensors:** NVIDIA (NVML, no root): the core; memory where the card reports it (HBM cards; GeForce usually not); no
  hotspot in NVML. AMD Linux (amdgpu hwmon): edge, junction (hotspot), mem. AMD Windows: no sensor in this version
  (`--temp-limit` is off there, logged). The hottest sensor relative to its own limit counts; a GPU with no readable
  sensor is not limited (logged at start).
- **With auto-uv:** a check starts only when the paused GPU has cooled to C-10; a check that reaches `--temp-stop` is
  repeated after cooling; a tuning step that stays too hot ends the search at the last good step (not counted as an
  edge). The stall watchdog (5g) never judges a GPU that `--temp-limit` throttles or stops. `--bench` and `--selftest`
  ignore `--temp-limit`.

### 5g. GPU stall watchdog (new in 0.5.4)
5d acts when a GPU worker **stops** on a CUDA error and the driver reports an Xid. A GPU can also fail quietly: its
launch never returns (**hang**: no error, no Xid) or it keeps working at a fraction of its speed (**slowdown**).

- **Hang** — a mining worker makes no progress for `--watchdog-hang` seconds (default 60; 180 while it opens the GPU).
  The GPU is stopped as a fault without an Xid (recorded in `ffgs-gpu-faults.txt` with its offset, as in 5d) and ffgs
  **restarts itself** even though other GPUs still mine (5d: Linux exec, Windows exit 2 + `start.bat`; at most 12 per
  hour). The next start acts on the record as for an Xid (with `--auto-uv` 30 MHz lower; without it a GPU that does it
  2 starts in a row is left out for an hour). Past the 12-per-hour limit the other GPUs keep mining and the hung GPU
  waits for the next start. AMD: ffgs exits (2) and the start script / HiveOS restarts it.
- **Slowdown** — the GPU's 10 s hashrate stays below `--watchdog-drop` % (default 30) of its **own** baseline for
  `--watchdog-minutes` (default 3). Baseline = the median of its last 60 normal 10 s samples (10 min), judged after 5 min
  of them; low samples never enter it. Action: on an auto-uv tuned offset the offset goes 30 MHz down (re-checked within
  a minute); that GPU's worker stops, its CUDA context is reset (AMD: the OpenCL context is created again) and a new
  worker starts; the other GPUs mine on. The 3rd slowdown of a GPU within an hour, a worker that does not stop within
  30 s, or a GPU that cannot be opened again: handled as a hang.
- **Not judged** (and 30 s after; 60 s after a worker start): the worker idles (auto-uv check / tuning, no job, pool
  offline), the dev fee / referral minute, a worker restart; while auto-uv changes an offset or auto-lock changes a lock
  (a lock change starts a new baseline); a GPU that `--temp-limit` throttles or stops. A slowdown while NVML reports
  hardware / driver throttling (HW slowdown, thermal, power brake) is **only logged** (once per 10 min): a restart would
  not help. A slowdown of more than half of the GPUs at once (at least 2) is the rig (CPU, power, host): logged once per
  10 min, nothing restarted.
- Options: `--watchdog-hang S` (≥ 10), `--watchdog-drop PCT` (1..95), `--watchdog-minutes M` (≥ 0.5), `--no-watchdog`.
- Log lines start with `watchdog:` (`HANG`, `SLOW` in red, with the clocks, W and temperature at that moment). The status
  line shows ` [wd 1h 2s]` after the GPU's hashrate when the watchdog acted on it in this run (h = hangs, s =
  slowdowns); HiveOS h-stats is unaffected. The API (3d) shows the counters in `watchdog`.

### 5b. AMD GPUs (new in 0.4.0)
The same `ffgs` / `ffgs.exe` also mines on AMD Radeon GPUs through OpenCL (tuned for RDNA2):
- `--backend auto` (default) uses CUDA when an NVIDIA GPU is present, otherwise AMD; `--backend amd` forces AMD.
  At start the log lists the AMD devices (`AMD0: …`); `--devices` uses that numbering (discrete AMD GPUs in PCI bus
  order, integrated GPUs are skipped).
- Windows: only the Adrenalin driver is needed (its `OpenCL.dll`). Linux / HiveOS: an OpenCL runtime
  (`libOpenCL.so.1`, ROCm or amdgpu-pro) — **not tested yet on a Linux AMD rig**.
- Measured, RX 6800 XT (Windows): 9.0 GH/s rabbitminer / 9.86 GH/s saseulmine layout at stock (~239 W ASIC);
  2300 MHz at 881 mV in Adrenalin: 9.7 GH/s at ~164 W.
- The clock options of 5a and the power / clock / temperature / fan columns are **NVIDIA only**; with the AMD backend
  the clock options are ignored (one warning) — set AMD clocks and voltage in Adrenalin / HiveOS OC.
- `--bench` re-checks every candidate on the CPU and prints the hardware-error count: use it to verify an undervolt.
- Developer notes and measurements: `docs/amd.md` in the source repository.

### 6. Dev fee and referral: 2% = 1% dev + 1% referral
The fee is **2%: two separate 60-second windows in every 100 minutes** (the first one after 15 minutes of mining):

- **1% referral** — mined for the wallet given with **`--referrer ADDRESS`** (whoever recommended ffgs to you), on your
  own pool. Without `--referrer` (or with `--referrer none`) the referral minute goes to the ffgs dev. Solo / own node:
  the referral minute is mined on Kavatar SL Pool (your node would not pay that address).
- **1% ffgs dev** — for the ffgs dev wallet (`a750e196…a624`) on your own pool (solo / own node: saseulmine.com, then
  rabbitminer.cc).
- **Your own wallet as referrer = total fee 1%**: there is no referral switch at all, and the remaining dev minute is
  mined on **Kavatar SL Pool** (`sl.kasplay.online:3333`, the pool of the ffgs authors); if Kavatar cannot be reached,
  on your own pool. If you mine on Kavatar anyway, nothing switches pools at all.
- Both fee connections are opened in advance and kept open, the GPUs switch only to a ready fee job and keep hashing
  for you while a fee pool connects, and each window is a hard **60 s of wall time**: if no fee pool is ready in it, that
  window is skipped. The start-up log names the referrer; the status line counts the dev (`fee …`) and referral
  (`ref …`) shares separately.
- Windows: `REFERRER=` in the start `.bat`; HiveOS: `--referrer ADDRESS` in *Extra config arguments*.

**saseulmine referrer.** saseulmine.com itself also has referrers: it splits a block 80% miners / 10% referrers / 10%
pool and states *"No referrer? Your share is unchanged."* — the referral 10% comes from the pool's part. ffgs sends your
`--referrer` address there as well (default: the ffgs dev wallet; `--referrer none` sends none).

### 6a. saseulmine.com details
- HTTPS (`pool.saseulmine.com:443`); every request is signed with an Ed25519 *client key*. ffgs creates it once and keeps
  it next to the binary in `ffgs-client.key` (if that folder is read-only, a new key is made at every start). The key is
  only a rig identity for the pool — it holds no coins. Do not copy it between rigs.
- The pool has no worker names (its account page shows one worker, `default`); `.WORKER` / `--worker` are ignored there.
- **Several rigs on one address work**, but the pool's share difficulty (vardiff) belongs to the *address*: when one rig
  raises it, a share another rig found a moment earlier at the lower difficulty is refused
  (`HTTP 400 Hash does not meet pool difficulty`). ffgs shows these as `low-diff` (yellow, counted apart from rejects),
  fetches the new difficulty at once and re-checks queued shares before sending. A few low-diff shares per hour with
  two or more rigs on one address are normal; they cost a little hashrate, not payout accounting.
- The pool sets the share difficulty per address (vardiff) and changes it after almost every share: a few shares per
  minute per rig are normal. Shares found just before a new block or before a difficulty raise would be rejected by the
  pool, so ffgs drops them (`share dropped: …` in the log) instead of sending them.
- Clock: the pool sends its time with every answer; ffgs uses it for the request signatures and the block timestamps,
  so a wrong PC clock does not matter.
- Linux: the CA certificates are read from `/etc/ssl/certs/ca-certificates.crt` (or the other usual places; `SSL_CERT_FILE`
  overrides). Windows uses the system certificate store and proxy settings.
- Account and payouts: the pool's web site (saseulmine.com) with your address; `--pool-test` prints the same account
  data in the console.

### 6b. saseulpool.com details
- Connection examples:

      ./ffgs --pool saseulpool --wallet ADDRESS.WORKER                              # Linux
      ./ffgs --pool nats://nats.saseulpool.com:4222 --wallet ADDRESS --worker rig1  # the same, full URL

  Windows: put your address into `start-saseulpool.bat` (`set WALLET=…`, optionally `set WORKER=…`) and double-click it.
  HiveOS flight sheet (Custom miner, see [HIVEOS.md](HIVEOS.md)): *Pool URL* `nats://nats.saseulpool.com:4222`,
  *Wallet and worker template* `%WAL%.%WORKER_NAME%`, *Installation URL* the ffgs release package.
- Protocol: NATS (plain TCP port 4222, no login, no TLS). The pool's mining nodes publish the block template every
  ~10 s; the share difficulty is fixed: network difficulty / 4096 (about 2.2·10^11, ~1 share per minute per 4 GH/s).
- **The pool answers no single share.** ffgs counts a share as `delivered` when the NATS server has confirmed that it got
  it (the status line `acc` and the table show delivered shares). Whether the pool credited them is shown in the
  `pool` line of the table every 5 min from the pool's API: the PPLNS *work* of your address over the last 90 min
  (the sum of the share difficulties the pool accepted) converted to GH/s, your percentage of the pool and the next
  payout, and the hashrate the pool's site shows for your address. Over a few minutes the work-based number scatters
  a lot (one share ≈ 2.2·10^11 hashes); compare it over an hour or more.
- The hashrate on the pool's site is the one the miner reports (every 10 s, per worker), not measured by the pool.
- Worker names: `.WORKER` / `--worker`, otherwise the host name; characters other than letters, digits, `-` and `_`
  become `-`. Several rigs on one address are fine (give them different worker names).
- Pool fee 5%, PPLNS window 90 min, payouts every 6 h from 10 SL (as of October 2026). Account and payouts:
  [saseulpool.com](https://saseulpool.com) with your address; pool chat t.me/poolSaseul.
- Block timestamps use the PC clock: keep it synchronized (NTP / Windows time sync).

### 7. Troubleshooting
| Message | Meaning / fix |
|---|---|
| `hardware error (bad candidate)` | the GPU returned a wrong hash: lower the core overclock |
| `share rejected: … stale` | the block changed while the share was in flight; occasional ones are normal |
| `cannot connect to any pool` | check the pool address / network; the miner retries with backoff |
| `self-test failed` | wrong results on this GPU/driver — the miner refuses to mine; report your GPU and driver |
| `share dropped: stale (new block)` / `below the raised share difficulty` | saseulmine: the share would be rejected, so it is not sent; occasional ones are normal |
| `share stale: … Stale share` | saseulmine: the block changed while the share was in flight (HTTP 409); not counted as a reject; occasional ones are normal |
| `TLS connect … certificate not trusted` / `no CA certificates found` | Linux: install the `ca-certificates` package or set `SSL_CERT_FILE` |
| `HTTP 401` | the request signature was refused — check that you run an unmodified ffgs; the clock is corrected automatically |
| `clocks: GPU clock settings skipped: needs root …` / `needs Administrator …` | clock options need root / an elevated window; mining continues at the current clocks |
| `clocks: … held by another running ffgs` | another ffgs controls this GPU's clocks; this one does not touch them |
| `clocks: … an earlier ffgs run left clock settings changed` | an ffgs was killed with clocks set; start ffgs once as root / Administrator to put them back |
| `… console lines skipped (output was blocked)` | the console / pipe did not read the output for a long time; mining went on, the `--log` file has every line |
| `share below the pool's current difficulty …` (low-diff) | saseulmine: another rig on the same address raised the per-address difficulty; see 6a |
| `share delivered #N` | saseulpool: the share reached the pool's server (the pool gives no per-share answer; see 6b) |
| `connection lost (… no job for 60 s)` / `(… no answer to PING for 15 s)` | saseulpool: the server stopped sending templates or answering; ffgs reconnects, to the next server of the cluster if needed |
| `saseulpool: no credited shares of this wallet in the 90 min PPLNS window yet` | normal in the first minutes; if it stays so for 30+ min while shares are delivered, check the address and the PC clock |
| `share rejected: HTTP 400 … Timestamp out of range (share timestamp … vs pool time, found … ago)` | the share reached the pool too late or with a bad time; the numbers show by how much. Occasional ones after network hiccups are normal |


### 8. Solo mining (own node)
Solo = no pool and no pool fee: your rigs mine directly for your own SASEUL node, and a found block pays the whole
block reward to your address. The bridge between the node and ffgs is the **solo proxy** `solo/sl_solo_proxy.py`
(Python 3, standard library only; in the Linux package and the source repository).

**Solo pays only when you find a block.** The expected time to a block is `network difficulty / your hashrate` seconds:
at a network difficulty of 8.95e14 (October 2026) one RTX 3070 (4.6 GH/s) needs on average 8.95e14 / 4.6e9 ≈ 195,000 s
≈ **54 hours** per block, a 6800 XT (9.8 GH/s) ≈ 25 hours — and the real time varies a lot (exponential distribution:
going twice the average without a block happens in ~14% of cases). Mine solo with enough hashrate or patience; a pool
pays small amounts steadily instead.

**Requirements**
- A **synced SASEUL node** (2.2.x; e.g. the official Docker image) running 24/7, with external mining switched on:
  `saseul-script mining external on` and `saseul-script mining start` (inside the container: `docker exec <container> …`).
- The node's **`run` directory** on the host: the node writes the current block template to `run/mining_job` and reads
  found blocks from `run/mining_result`. With Docker, mount the node's run directory as a volume (e.g. host
  `/var/saseul-run`) so the proxy can read and write it.
- Python 3.8+ on the node machine, and a TCP port (default 19310) reachable from your rigs (open it only for them).

**Installing the proxy (Linux, systemd)**

    sudo mkdir -p /opt/sl-solo /etc/sl-solo /var/lib/sl-solo
    sudo cp solo/sl_solo_proxy.py /opt/sl-solo/
    sudo cp solo/env.example /etc/sl-solo/env && sudo chmod 600 /etc/sl-solo/env     # edit: SL_RUN, SL_TOKEN, ...
    sudo cp solo/addresses.txt.example /etc/sl-solo/addresses.txt                    # edit: your address(es)
    sudo cp solo/sl-solo-proxy.service /etc/systemd/system/
    sudo systemctl daemon-reload && sudo systemctl enable --now sl-solo-proxy
    journalctl -u sl-solo-proxy -f

Settings (environment, `/etc/sl-solo/env`): `SL_RUN` (node run directory), `SL_PORT` (19310), `SL_TOKEN` (the miners'
login password — use a long random one; empty = no check), `SL_SHARE_DIFF` (share difficulty for hashrate monitoring,
default 1e11), `SL_ADDRESSES` (address list file), `SL_STATE` (counters), `SL_PUBLIC` (public node used for the sync
check, default `http://main.saseul.net/info`), `SL_NONCE_LEN` (40). The proxy serves jobs **only while your node is in
sync** with the public network; until then ffgs waits.

**Rotation addresses.** `addresses.txt` holds one or more payout addresses (44 hex each, keys that *you* hold); the
proxy puts the next one into every new block template. Why: SASEUL pays the miners of the last 9 blocks `total/32`
each and splits the remaining **23/32 equally among the unique addresses** among them — the same address on several
of those blocks gets that part only once. With a different address per block the gain is ≈ +2.5% at 1% of the network
hashrate and ≈ +25% at 10%; for a few GPUs it is close to zero, so **one address is fine**. Rewards arrive as
*resource* on these addresses: convert them with `Refine` and move them with `Send` (normal transactions with a fee,
so the address needs a little SL first), e.g. in the Guardee wallet.

**Connecting ffgs**

    ./ffgs --pool NODE_IP:19310 --wallet ADDRESS.WORKER --pass SL_TOKEN

The address in `--wallet` is only a label in the proxy log — **the reward goes to the addresses of `addresses.txt`**.
The proxy sends 40-hex nonce jobs; ffgs switches to its solo kernel automatically (no option). Several rigs can use one
proxy. ffgs treats a `HOST:PORT` pool list without any rabbitminer.cc host as solo: its 1% dev fee minute is then
mined on saseulmine.com for the dev wallet (fallback rabbitminer.cc), not on your node (see 6); the rig therefore also
needs internet access to pool.saseulmine.com or rabbitminer.cc (without it the fee window is skipped and you keep mining).
- Windows: in `start.bat` set `POOL=NODE_IP:19310`, `WALLET=` your address, `WORKER=` a name and `EXTRA=--pass SL_TOKEN`.
- HiveOS flight sheet: Pool URL `NODE_IP:19310`, Wallet template `%WAL%.%WORKER_NAME%`, Extra config arguments
  `--pass SL_TOKEN` (see HIVEOS.md).

**Checking that it works**
- Proxy log: `node IN SYNC: job height …`, `job height … diff … miner #N …` on every block, `login WORKER from IP: ok`,
  `stats: … shares_total=… blocks=… active={…}` every 5 min, `reject WORKER: …` for refused shares.
- ffgs log: `connected NODE_IP:19310`, `new block height …`, accepted shares (these are proxy shares at `SL_SHARE_DIFF`,
  for monitoring). A found block: `*** BLOCK FOUND (block) ***` in ffgs and `*** BLOCK <height> by WORKER miner <address>` in the
  proxy log; the proxy then writes it to `run/mining_result` and the node broadcasts it. Check the block on the
  explorer / `saseul-script info` and the resource balance of that address.
- `login …: denied` = wrong `--pass`; `node syncing` = the node is not in sync yet (or `SL_PUBLIC` is unreachable).

---

## Русский

### 1. Что майнит
У SASEUL (SL) две цепи: *main chain* (транзакции, валидаторы) и *resource chain* — PoW-цепь, которая выбирает
валидаторов и платит майнерам. Resource-блок валиден, если

    sha256(previous_blockhash + sha256(header_json) + nonce)  <=  2^256 / difficulty

Награда — 2000 «ресурса» за блок, контракт `Refine` переводит его в SL (множитель 0.4276 на октябрь 2026,
×27/32 каждый сезон ~1 млрд SL). В пуле вы просто получаете SL.

### 2. Кошелёк
Адрес SASEUL — 44 hex-символа (`5a00b883bd62…94ea`). Завести: официальный кошелёк **Guardee** (Android / iOS) или
нода SASEUL (`saseul-script wallet create`). Guardee создаёт кошелёк из **сид-фразы** — запишите её и храните офлайн;
нода использует «сырой» приватный ключ (32 байта) — сохраните его. Майнеру нужен только адрес.

### 3. Запуск

    ./ffgs --wallet АДРЕС.ВОРКЕР                        # Kavatar SL Pool (по умолчанию, = --pool kavatar), см. 3b
    ./ffgs --pool nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931 --wallet АДРЕС.ВОРКЕР
    ./ffgs --pool saseulmine --wallet АДРЕС.ВОРКЕР
    ./ffgs --pool saseulpool --wallet АДРЕС.ВОРКЕР

| Опция | Что делает |
|---|---|
| `--pool ХОСТ:ПОРТ[,ХОСТ:ПОРТ…]` | список пулов с протоколом rabbitminer (Kavatar SL Pool, rabbitminer.cc, своя нода); при недоступности берётся следующий; по умолчанию `sl.kasplay.online:3333` |
| `--pool kavatar` | Kavatar SL Pool (`sl.kasplay.online:3333`), см. 3b |
| `--pool saseulmine` | saseulmine.com; то же, что `--pool https://pool.saseulmine.com` (любой `https://` URL — этот протокол, несколько URL — резервные; не смешивать с `ХОСТ:ПОРТ`) |
| `--pool saseulpool` | saseulpool.com; то же, что `--pool nats://nats.saseulpool.com:4222` (любой `nats://ХОСТ[:ПОРТ]` — этот протокол, несколько — резервный список; остальные серверы кластера пула ffgs узнаёт от сервера и тоже использует; см. 6b) |
| `--wallet АДРЕС[.ВОРКЕР]`, `--worker ИМЯ` | адрес выплат и имя воркера (saseulpool: по умолчанию воркер = имя компьютера) |
| `--referrer АДРЕС` / `--referrer none` | кому идёт реферальная минута 1% (тому, кто посоветовал вам ffgs); **свой кошелёк = комиссия 1%**; none / не задан — её получает разработчик; заодно это реферер saseulmine (см. 6) |
| `--pass ПАРОЛЬ` | пароль пула (по умолчанию `x`; токен соло-прокси) |
| `--devices 0,1,…` | какие GPU, нумерация как в `nvidia-smi` / HiveOS (по умолчанию все; AMD — см. 5b) |
| `--backend auto\|cuda\|amd` | GPU-бэкенд: `auto` (по умолчанию) = NVIDIA CUDA, если есть карта NVIDIA, иначе AMD OpenCL |
| `--eco` | экономичное ядро (см. 5) |
| `--blocks N`, `--threads N` | геометрия запуска (по умолчанию SM × 64 блоков × 256 потоков) |
| `--bench СЕКУНДЫ` | замер хешрейта каждой GPU без пула |
| `--selftest` | проверка PoW на реальном блоке сети, ядра против перебора на CPU и подписи запросов |
| `--pool-test` | saseulmine: один подписанный запрос задания и статистика аккаунта; saseulpool: подключиться и дождаться задания; затем выход (GPU не нужна) |
| `--lock-cclock МГц[,МГц…]` | зафиксировать частоту ядра (как `nvidia-smi -lgc N,N`); см. 5a |
| `--lock-mclock МГц[,МГц…]` | зафиксировать частоту памяти (как `nvidia-smi -lmc N,N`) |
| `--coffset МГц[,МГц…]` (синоним `--uv-offset`) | V/F-оффсет частоты ядра = андервольт при зафиксированной частоте |
| `--moffset МГц[,МГц…]` | оффсет частоты памяти, может быть отрицательным (драйвер 555+) |
| `--plimit Вт[,Вт…]` | лимит мощности |
| `--dry-run` | напечатать, что опции выставят на каждой GPU, и выйти; ничего не меняется (5a, новое в 0.5.4) |
| `--oc-info` | частоты, оффсеты и лимиты мощности выбранных GPU, затем выход (root не нужен) |
| `--auto-uv`, `--uv-min/--uv-max/--uv-step МГц[,…]`, `--uv-coarse МГц`, `--uv-reset`, `--uv-reset-all`, `--uv-reval-hours Ч` | автоподбор андервольта, см. 5c |
| `--auto-lock`, `--auto-lock-range`, `--auto-lock-max-loss ПРОЦ`, `--auto-lock-goal eff\|speed`, `--auto-lock-reset` | автовыбор фиксации частоты ядра по каждой карте, см. 5e (новое в 0.5.4) |
| `--temp-limit C[,C…]`, `--temp-stop`, `--temp-mem`, `--temp-hotspot`, `--temp-no-clocks` | защита по температуре, в первую очередь для ноутбуков, см. 5f (новое в 0.5.4) |
| `--watchdog-hang С`, `--watchdog-drop ПРОЦ`, `--watchdog-minutes М`, `--no-watchdog` | сторож зависания GPU, см. 5g (новое в 0.5.4) |
| `--failback-minutes N`, `--noshare-minutes M`, `--reject-minutes K` | здоровье пула: возврат на основной пул, сторож «нет принятых шар», см. 3c (новое в 0.5.4) |
| `--api [ХОСТ:]ПОРТ`, `--api-hosts ИМЯ[,…]` | локальный HTTP/JSON API только для чтения, см. 3d (новое в 0.5.4) |
| `--install-autostart` (`--task-name`, `--autostart-delay`, `--autostart-bat`, `--autostart-ac-only`, `--task-user`, `--autostart-limited`), `--remove-autostart` | Windows: запуск `start.bat` при входе в систему, см. 3e (новое в 0.5.4) |
| `--no-update-check`, `--check-update` | выключить уведомление о новой версии / проверить один раз и выйти, см. 3e (новое в 0.5.4) |
| `--log ФАЙЛ` | дополнительно писать лог в ФАЙЛ (обычный текст, если не `--color always`; bat-файлы Windows пишут в `logs\ffgs.log`) |
| `--color auto\|always\|never` | цвета в консоли, см. 3a (по умолчанию `auto`) |
| `--no-color` | = `--color never` |
| `--minutes N` | остановиться через N минут майнинга (для тестов) |
| `--quick-edit` | Windows: не выключать QuickEdit консоли (ffgs его выключает: клик в окно ставит вывод на паузу) |

**Консоль.** Каждые 10 с — строка статуса (хешрейт по картам с мощностью и эффективностью, итог рига, шары вашего
кошелька и комиссии; эту строку читает HiveOS), каждые 60 с — таблица: хешрейт за 10 с и за 5 мин, ватты, MH/W, частоты,
температура, вентилятор, текущие оффсеты ядра/памяти, что выставил ffgs, шары с процентами и данные самого пула по вашему
кошельку (saseulmine `/account`, API кошелька rabbitminer.cc, API saseulpool.com; обновляются раз в 5 мин) — пример в английском разделе.

Мощность, температура и вентиляторы — из NVML (только чтение, root не нужен); без NVML — `-`. Цвета — см. 3a.

### 3a. Цвета консоли (новое в 0.5.0)
У каждого цвета одно значение — одинаково в строках лога, в строке статуса раз в 10 с и в таблице раз в 60 с:

| Сообщение / значение | Цвет |
|---|---|
| **найден блок** (`*** BLOCK FOUND ***`, `blocks N` в таблице при N > 0) | жирный ярко-белый на пурпурном фоне (самый заметный стиль, больше нигде) |
| принятая / доставленная шара, подключение, `online`, `ok` самотеста / теста пула | зелёный |
| хешрейт: `GPUn 4.611` и `total … GH/s` в строке статуса, колонки GH/s таблицы, `--bench` | жирный ярко-белый |
| энергоэффективность `MH/W` (строка статуса и таблица) | жирный ярко-синий |
| температура GPU (таблица) | зелёный ниже 70 °C, жёлтый 70–79 °C, красный от 80 °C |
| итоги: строка `rig`, заголовок таблицы | жирный |
| stale / отброшенная / low-diff шара, ожидание задания, смена сервера, статистика пула не обновилась | жёлтый |
| ожидаемые исходы auto-uv / auto-lock (0.5.4): неудачный шаг подбора или быстрой проверки (`step +360 (3/7): FAILED (...)`), `edge found`, `tuning again`, фиксация, подбор на которой не удался; частоты, изменённые другой программой и выставленные снова (`... by another tool (HiveOS OC profile?) - ffgs's lock 1500 MHz wins, re-applied`, 5a) | оранжевый (256-цветный 208; жёлтый в текстовой консоли Linux и терминалах без 256 цветов) |
| то, что требует внимания: отклонённая шара, ошибки, hardware error, потеря связи, `OFFLINE` / `pool offline`, GPU упал во время майнинга, исключён или не открывается, итоговый `RESULT: FAILED` auto-uv | красный |
| новая высота блока, смена сложности / делителя шары | голубой |
| минута комиссии (её шары и строки статуса) | тусклый |
| время, названия колонок таблицы | серый |

Когда цвета включены (`--color`, по умолчанию `auto`):
- `auto`: в терминале; и в pipe, за которым смотрят из терминала (stdin — терминал или майнер запущен внутри GNU
  screen), например `./ffgs … | tee ffgs.log`. Никогда — при перенаправлении в файл, под сервисом (systemd: stdin —
  `/dev/null`) и в файле `--log`. `NO_COLOR` (непустой) выключает `auto`, `FORCE_COLOR` (непустой, не `0`) делает его `always`.
- `always`: escape-коды везде, включая файл `--log`. `never` (или `--no-color`): везде обычный текст.
- **HiveOS**: `h-run.sh` запускает `ffgs … | tee ffgs.log` внутри screen `miner`, `auto` его раскрашивает: цветные и
  `miner`, и веб-просмотр «miner log» (он показывает ANSI-цвета из `/var/log/miner/ffgs/ffgs.log`). `h-stats.sh` читает
  цветной лог как раньше (цвета стоят только вокруг целых значений). В Extra config `--color never` — лог без цветов,
  `--color always` — цвета принудительно, если какая-то версия HiveOS запустит майнер без терминала.
- **Windows**: консоль Windows 10+ (режим ANSI / VT, ffgs его включает); старая консоль — обычный текст.
  Перенаправленный вывод (`> file`, `| Tee-Object`) — без цветов, если не `--color always`; `logs\ffgs.log` — без цветов.
- Терминал со светлым фоном: ярко-белый там плохо читается — `--color never`.

### 3b. Пул Kavatar SL (по умолчанию с 0.5.0)

Без `--pool` ffgs майнит на **Kavatar SL Pool**, пуле авторов ffgs (`--pool kavatar` — то же самое):
`sl.kasplay.online:3333`, статистика и поиск по кошельку — **https://kavatar.kasplay.online** (EN / RU / 中文).

- **PPLNS**: блок делится по шарам за последние 2 сложности сети работы до него, с весом по сложности шары —
  постоянные майнеры не страдают от «прыгунов» между пулами. **Комиссия пула 2%.**
- **Автоматические выплаты каждые 6 часов от 10 SL** прямо на ваш адрес. Выплата считается сделанной, только когда
  транзакция попала в цепочку; не попавшая за 30 минут возвращается на баланс.
- У пула своя нода SASEUL; награда (resource) переводится в SL и начисляется, когда подтверждены все 9 окон награды
  блока (~15 минут после блока). Начисления, выплаты и блоки видны на сайте.
- Сложность шары подбирается под каждое подключение (примерно шара раз в 15 с), nonce 40 hex, пароль не нужен; имя
  воркера — часть после точки в `--wallet АДРЕС.ВОРКЕР` (или `--worker`).
- Строка `pool` в консоли показывает данные пула по вашему кошельку: хэшрейт за 10 мин, баланс, выплачено, несозревшие блоки.
- Минута комиссии разработчика майнится на том же пуле на dev-кошелёк ffgs (без второго подключения к другому пулу).

### 3c. Здоровье пула: возврат на основной пул, сторож «нет принятых шар» (новое в 0.5.4)
`--pool` с несколькими адресами одного протокола — список резервных пулов; **первый — основной**:

    ./ffgs --pool sl.kasplay.online:3333,nl.rabbitminer.cc:1931 --wallet АДРЕС.ВОРКЕР

До 0.5.3 ffgs уходил на следующий пул, когда текущий недоступен, но не возвращался (saseulmine, saseulpool), а пул,
который принимает соединение, но ничего не засчитывает, не покидал никогда.

**Возврат на основной пул.** Пока ffgs майнит на резервном, основной проверяется каждые `--failback-minutes`
(по умолчанию **10**) *отдельным* соединением; майнинг не трогается, шары не отправляются: rabbitminer — подключение,
login (тот же wallet.worker), один `getjob` с годным заданием; saseulmine — один подписанный `GET /mine`; saseulpool —
подключение, подписка, один шаблон блока за 25 с (серверы, узнанные из кластера, — тот же пул). После **2 удачных
проверок подряд** (вторая через 60 с) — переключение: задание снимается, GPU доделывают текущие запуски, найденные шары
уходят на резервный (saseulpool — до подтверждения сервером), затем подключение к основному. GPU стоят ~1–2 с. В логе:
`failback: the primary pool answers again (check 1 of 2) ...`, `the primary pool answered 2 checks in a row: switching
back to it ...`. `--failback-minutes 0` — выключить.

**Нет принятых шар (сторож).** Подключён, хеширует, но пул ничего не принимает:
- нет принятой шары **max(`--noshare-minutes` (15), 10 × ожидаемый интервал)** — ожидаемое число шар считается по
  измеренному хешрейту и сложности шары пула (15 с на шару → окно 15 мин, 5 мин на шару → 50 мин);
- или **только отказы `--reject-minutes` (5)** мин (не меньше 5 отказов и ни одной принятой);
- или подключён, но **нет годного задания 5 мин**.

Первый раз — переподключение к тому же пулу; повторилось на новом соединении — **следующий пул** списка (после
последнего — первый). Причина пишется в лог (`watchdog: …`). `--noshare-minutes 0` / `--reject-minutes 0` — выключить.

Сторож **не срабатывает**: пока GPU не хешируют на ваш пул (подбор / проверка auto-uv — считается только измеренный
хешрейт; нет задания; нет соединения; переключение); в минуту комиссии / реферала и 10 с после; в режиме **соло / своя
нода** (список `ХОСТ:ПОРТ` без Kavatar / rabbitminer.cc); если GPU **вообще не нашли шар**, хотя ждали ~10 — это
проблема GPU, а не пула: предупреждение, пул не меняется. Основной пул, с которого ушёл сторож, проверяется всё реже:
×2 до ×16 от `--failback-minutes`; после 2 ч на нём — как обычно. На saseulpool «принята» = *доставлена* (6b).

- Сессии комиссии и реферала на вашем же списке пулов **следуют за вашей сессией** на её пул (не чаще раза в минуту и
  никогда внутри своей минуты); сама минута не меняется. Остальные сессии комиссии (Kavatar при своём кошельке-реферере;
  saseulmine / rabbitminer.cc / Kavatar для соло) возвращаются на свой основной сами.
- Пул rabbitminer, принимающий соединение, но **отказывающий в login**, теперь сдвигает следующую попытку на следующий
  адрес. В таблице раз в 60 с — `…, backup pool 2 of 2`, пока ffgs на резервном. saseulpool: при потере сервера сначала
  другие серверы того же кластера, потом следующий `--pool`.

### 3d. Локальный API `--api` (новое в 0.5.4)
HTTP/JSON API только для чтения — для своего мониторинга:

    ffgs --wallet АДРЕС ... --api 4068               # http://127.0.0.1:4068 (только эта машина)
    ffgs --wallet АДРЕС ... --api 0.0.0.0:4068       # все интерфейсы: читать смогут машины локальной сети
    ffgs --wallet АДРЕС ... --api 192.168.1.20:4068  # один интерфейс
    ffgs --wallet АДРЕС ... --api [::1]:4068         # IPv6

- Хост по умолчанию — `127.0.0.1`. Другой адрес — только явно; для не-loopback в логе жёлтое предупреждение (кто
  достучится до адреса, тот прочитает статистику рига: закройте файрволом). В логе:
  `API: listening on http://127.0.0.1:4068 (read-only: /summary, /gpus, /metrics)`.
- Неверное значение `--api` — ffgs сразу выходит (код 1). Занятый порт майнинг **не** останавливает
  (`... - mining without the API`).
- **Безопасность:** только `GET` и `HEAD` (остальное — `405`), ни одного эндпоинта записи / управления, без
  авторизации. В ответах никогда нет паролей пула, ключа клиента saseulmine, токена соло-прокси; есть кошелёк, воркер,
  реферер (публичные адреса). Один маленький поток (до 16 соединений, 4 КиБ заголовков, 5 с на соединение) отдаёт копию
  статистики, обновляемую раз в 10 с; к GPU, NVML и пулу не прикасается. Без CORS-заголовков.
- **Белый список заголовка Host** (защита от DNS rebinding: веб-страница, чьё имя указывает на риг, не должна его
  читать): разрешены `localhost`, `127.0.0.1`, `[::1]`, адрес, на котором слушает API, любой IP-адрес при `0.0.0.0` /
  `[::]`, плюс имена из **`--api-hosts ИМЯ[,ИМЯ…]`**. Иной Host — `403`; запрос без заголовка Host обслуживается.

| Путь | Формат | Что |
|---|---|---|
| `GET /`, `GET /summary` | JSON | сводка рига |
| `GET /gpus` | JSON | объект на каждую карту |
| `GET /metrics` | Prometheus text 0.0.4 | метрики рига и карт (хешрейт в H/s) |

Значения обновляются раз в 10 с; `updated_s_ago` — их возраст; неизвестное — `null` (температура на AMD, ватты без
NVML). Ошибки — JSON; до первой статистики — `503` с `Retry-After: 10`. `api_version` меняется только при несовместимых
изменениях. Имена полей — в английском разделе; коротко:

- `/summary`: версия, аптайм, пул (`protocol`, `url` — к какому хосту подключена сессия сейчас, `index` — номер текущего
  адреса failback в списке `--pool` с 0, `count`, `connected`, высота, сложности, задержка, `pool_side` — данные пула
  по кошельку), кошелёк / воркер / реферер, хешрейт 10 с / 5 мин / сглаженный, ватты и MH/W, шары вашей сессии
  (saseulpool: `accepted` = доставлено), комиссия. `pool.failback` — состояние 3c: `enabled`, `entry`, `entries`,
  `on_backup`, `next_check_s`, `good_checks`, `interval_x`, `watchdog` (`enabled`, `mined_s`, `expected_shares`,
  `strikes`).
- `/gpus`: `index`, `bus`, имя, `state` (`mining`, `auto-uv`, `stopped`, `left_out`), хешрейт, W, MH/W, температура,
  вентилятор, частоты, оффсеты, `set_by_ffgs`, `auto_uv`, `hw_errors`, `shares.found`, а также:
  - `throttle` — причины троттлинга NVIDIA (`{"reasons":["power_cap","hw_thermal"],"hw":true}`, иначе `null`; причины
    `idle`, `app_clocks`, `power_cap`, `hw_slowdown`, `sync_boost`, `sw_thermal`, `hw_thermal`, `hw_power_brake`,
    `display_clock`; `hw` = HW slowdown / SW или HW thermal slowdown / power brake);
  - `watchdog` (5g) — `{"on":true,"hangs":0,"slowdowns":0,"worker_restarts":0,"slow_under_hw_throttle":0,"held":false,
    "baseline_ghs":5.3}` или `{"on":false}`;
  - `auto_lock` (5e) — `null` без `--auto-lock`, иначе `swept`, `phase` (`sweeping` / `done` / `saved` / `fallback` /
    `aborted` / `skipped`), `note`, `lock`, `choice`, `status` (`"auto-lock 1700, 2/7: measuring"` или `null`);
  - `temp_limit` (5f) — `null` или `limit_c`, `stop_c`, `state` (`full` / `limited` / `stopped`), `work_pct`,
    `clock_mhz`, `temp_c`, `throttled_s`, `stops`.
- `/metrics`: формат Prometheus, список метрик — в английском разделе.

Примеры: `curl -s http://127.0.0.1:4068/summary | jq '.hashrate, .shares'`; PowerShell:
`Invoke-RestMethod http://127.0.0.1:4068/summary`. Prometheus с целями по имени (`targets: ["rig1:4068"]`): на rig1
нужен `--api 0.0.0.0:4068 --api-hosts rig1` (или цели по IP-адресу — тогда `--api-hosts` не нужен).

- **HiveOS:** `--api 4068` в *Extra config arguments*; `h-stats.sh` тогда берёт хешрейты, аптайм, шары и ватты из API
  (адрес находит в логе; без ответа за 2 с или при статистике старше 60 с — читает лог, как раньше). На смешанном
  NVIDIA + AMD риге `h-run.sh` даёт AMD-процессу `--api ПОРТ+1` (хост тот же), h-stats читает оба.
- **Windows:** `set API=4068` в стартовых скриптах.

### 3e. Автозапуск на Windows, уведомление о новой версии (новое в 0.5.4)
**Автозапуск.** Двойной щелчок по **`install-autostart.bat`** в папке ffgs (после настройки `start.bat`); Windows один
раз спросит права администратора. Создаётся задача Планировщика `ffgs`: запускает `start.bat` этой папки при **вашем**
входе, через 30 с, в обычном окне майнера на вашем рабочем столе, с наивысшими правами (`LOCK_CCLOCK` / `COFFSET` /
`AUTO_UV` / `AUTO_LOCK` без запроса UAC). Повторный запуск, пока задача идёт, игнорируется; запускается и от батареи и
не останавливается при отключении кабеля; без ограничения времени (по умолчанию Планировщик снимает задачу через
72 ч); обычный приоритет. Настройки в начале `install-autostart.bat`: `TASK` (имя задачи), `DELAY` (секунд после
входа, 0 — сразу), `AC_ONLY=1` (ноутбуки: не запускать от батареи). После изменения или переноса папки — запустить ещё
раз (задача ffgs заменится). **`remove-autostart.bat`** удаляет её (открытое окно майнера продолжает работать).

Из консоли администратора: `ffgs --install-autostart [--task-name ИМЯ] [--autostart-delay С] [--autostart-bat ПУТЬ]
[--autostart-ac-only] [--task-user ДОМЕН\ПОЛЬЗОВАТЕЛЬ] [--autostart-limited]`, `ffgs --remove-autostart [--task-name ИМЯ]`.
`--autostart-bat` — по умолчанию `start.bat` рядом с `ffgs.exe`. `--task-user` — чей вход запускает задачу (по
умолчанию тот, кто запустил ffgs; .bat передаёт пользователя, который его открыл). `--autostart-limited` — без
администратора и без наивысших прав (тогда `start.bat` с настройками частот при `AUTO_ELEVATE=1` спрашивает права при
каждом входе). Заменяется и удаляется только задача, созданная ffgs. Не кладите `start.bat` ещё и в «Автозагрузку» —
будет два майнера. Linux: `--install-autostart` печатает подсказку; HiveOS запускает майнер сам; на обычном Linux —
сервис systemd с `Restart=always`.

**Настройки стартовых скриптов (0.5.4).** Кроме `AUTO_UV`: `AUTO_LOCK=1` (`--auto-lock`, 5e; считается настройкой
частот для `AUTO_ELEVATE`), `TEMP_LIMIT=80` (`--temp-limit`, 5f; права администратора не нужны), `API=4068` (`--api`, 3d).

**Уведомление о новой версии.** Во время майнинга, примерно через минуту после старта и затем примерно каждые 12 ч (со
случайным разбросом), ffgs спрашивает у GitHub последний релиз `pepsykolya/FreeForGemSaseul` и, если он новее, пишет
в лог жёлтым `ffgs 0.5.5 is available: <ссылка> (this is 0.5.4; ...)`. Один простой GET с `User-Agent: ffgs/<версия>`,
никаких кошельков, воркеров и идентификаторов; ничего не скачивается и не ставится. В отдельном потоке: GitHub
недоступен (или лимит 60 запросов в час на IP) — тишина, майнинг не затрагивается. Не делается в `--selftest`,
`--bench`, `--oc-info`, `--pool-test`. `--no-update-check` — выключить; `ffgs --check-update` — проверить сейчас и выйти
(код 0 — актуальна, 10 — есть новее, 1 — не удалось проверить).

### 4. HiveOS
См. [HIVEOS.md](HIVEOS.md).

### 5. Настройка
- PoW — чистые вычисления без работы с памятью: **частоту памяти можно опустить** до минимума, это экономит ватты.
- **Ядро по умолчанию** — максимум хешей на такт; лучше, когда карта упирается в лимит мощности или ядро зафиксировано высоко.
- **`--eco`** — примерно на 12% меньше GH/s на такт, но ~17% меньше мощность; лучший H/W на андервольте.
- **Замеры (0.5.3 / 0.5.4, ядро по умолчанию, пул Kavatar SL, nonce 40 hex).** GH/s — медиана 10-секундных строк
  статуса после 60 с майнинга (≥ 4 мин на точку), Вт — мощность платы по NVML; оффсет auto-uv — то, что `--auto-uv`
  нашёл на этой карте на этой фиксации (пол напряжения или край минус шаг). Рекомендуемое — **жирным**.

  **RTX 3070** (HiveOS, драйвер 580.82.07; Rig01 8 карт, 2–4 карты на частоту, медиана; Rig02 4 карты на 1500 — те же
  5,62 GH/s, 76 Вт на карту):

  | Фиксация ядра | Память | Оффсет auto-uv | GH/s | Вт | MH/W | Вт при оффсете 0 | |
  |---|---|---|---|---|---|---|---|
  | 1200 | 810 | +240 … +255 | 4,51 | 65 | 69 | 71 | |
  | 1300 | 810 | +240 … +255 | 4,90 | 73 | 67 | 84 | |
  | 1400 | 810 | +255 … +330 | 5,29 | 75 | 70,5 | 88 | |
  | **1500** | **810** | +330 … +435 | **5,62** | **76** | **73,9** | 98 | **лучший MH/W** |
  | 1600 | 810 | +330 … +390 | 6,01 | 89 | 67,5 | 119 | |
  | **1700** | **810** | +315 … +345 | **6,40** | **106** | **60,4** | 151 | **баланс** (лучший MH/W в пределах −10 % от макс. GH/s) |
  | **1800** | **810** | +330 … +345 | **6,74** | **121** | **55,7** | 186 | **максимум хешрейта** |
  | 1400 | сток | +300 | 5,29 | 104 | 50,9 | — | память 810 экономит 27 Вт |

  `--lock-cclock 1500 --lock-mclock 810 --auto-uv` (лучший MH/W), `1700` (баланс), `1800` (максимум). Карты различаются
  по ваттам до 25 % на одной частоте (1400: 67–79 Вт); хешрейт одинаковый (≈ 3,74 GH/s на 1000 МГц).

  **RTX 3080 Ti** (Windows 10, драйвер 591.59, PL 350 Вт, одна карта; строки `auto-lock` — собственный 120-с замер ffgs):

  | Фиксация ядра | Память | Оффсет | GH/s | Вт | MH/W | |
  |---|---|---|---|---|---|---|
  | 1200 | 810 | 0 | 7,73 | 137 | 56,5 | |
  | 1400 | 810 | +120 (auto-uv, пол) | 9,07 | 160 | 56,9 | оффсет 0: 164 Вт |
  | 1500 | 810 | 0 | 9,65 | 184 | 52,3 | |
  | 1560 | 810 | +210 (auto-uv) | 10,03 | 177 | 56,6 | оффсет 0: 206 Вт |
  | **1600** | **810** | +240 (auto-uv) | **10,32** | **180** | **57,4** | **лучший MH/W** |
  | 1650 | 810 | 0 | 10,60 | 240 | 44,2 | |
  | **1700** | **810** | +240 (auto-uv) | **10,98** | **212** | **51,9** | **баланс** (`--auto-lock` выбрал её же) |
  | 1750 | 810 | 0 | 11,27 | 299 | 37,7 | |
  | 1800 | 810 | +150 (auto-uv, край +180) | 11,49 | 268 | 42,9 | |
  | **без фиксации** | **810** | 0 | **11,54** | **332** | **34,8** | **максимум хешрейта** (~1800 МГц) |
  | 1400 | сток | 0 | 9,13 | 221 | 41,3 | память 810 экономит 57 Вт |
  | без фиксации | сток | 0 | 11,13 | 349 | 31,9 | упирается в лимит мощности: медленнее, чем с памятью 810 |

  `--lock-cclock 1600 --lock-mclock 810 --auto-uv` (лучший MH/W), `1700` (баланс), `--lock-mclock 810` без фиксации ядра
  (максимум). До 1400 напряжение ядра уже на полу (auto-uv: +120, −4 Вт); андервольт окупается примерно с 1500.

  **RTX 4070 Laptop** (Windows 11, от сети, без администратора — частотами не управлять): без лимита 4,80 GH/s, 63 Вт,
  **77 MH/W** — драйвер сам держит 86–87 °C (свой термотроттлинг, ~1700 МГц). `--temp-limit` охлаждает ценой
  хешрейта (5f): лимит 75 → 1,78 GH/s, 38 Вт, 47 MH/W; лимит 70 → 1,5 GH/s, 32 Вт, 46 MH/W; лимит 80 на этом ноутбуке
  бесполезен (он и так на 86–87 °C, а пачки горячее). Замер до перенастройки регулятора в 0.5.4 (мягкий старт, стоп по
  3 показаниям); перенастройка проверена на модели этого ноутбука, на самом ноутбуке — ещё нет.
- **Частота памяти:** фиксируйте 810 (`--lock-mclock 810`; CMP 50HX: 5001, 5a). SL не нужна пропускная способность
  памяти; стоковая частота памяти только добавляет ватты.

### 5a. Управление частотами GPU (новое в 0.4.0)
ffgs умеет выставлять частоты карт, на которых майнит:

| Опция | Что делает |
|---|---|
| `--lock-cclock N` | фиксирует частоту ядра на N МГц (`nvidia-smi -lgc N,N`) |
| `--lock-mclock N` | фиксирует частоту памяти на N МГц (`nvidia-smi -lmc N,N`); SL не нужна пропускная способность памяти — ставьте минимум (810 на RTX 30/40). Частота, которую карта не поддерживает, заменяется наименьшей поддерживаемой выше неё (0.5.3; у CMP 50HX нет 810: `memory clock 810 not supported, using 5001 (lowest supported)`) |
| `--coffset N` / `--uv-offset N` | V/F-оффсет частоты ядра в МГц: при зафиксированной частоте положительный оффсет = та же частота при меньшем напряжении (андервольт) |
| `--moffset N` | оффсет частоты памяти в МГц, может быть отрицательным (драйвер 555+) |
| `--plimit W` | лимит мощности, Вт |

- Одно значение — для всех карт майнинга; список через запятую — по значению на карту в порядке `--devices` (без
  `--devices` — все GPU в порядке nvidia-smi / HiveOS; при `--devices 2,0` первое значение — для GPU2). Пустое значение,
  `-`, `0` или `x` (и `X`, `skip`) — эту настройку на этой карте не трогать: `--devices 0,1,2 --lock-cclock 1400,,1560`.
- **Короткий список — последнее значение повторяется** на остальные карты (правило OC HiveOS, 0.5.4; в логе строка
  `... 2 values for 3 GPUs: the last one (1500) also applies to the remaining 1 GPU (HiveOS rule)`). Значений больше,
  чем карт, не число, вне диапазона — ошибка на старте (код 1, ничего не меняется). Списки — **без пробелов** (HiveOS и
  стартовые скрипты делят аргументы по пробелам).
- **`=0` ставит оффсет ровно 0** (только `--coffset`, `--moffset`; 0.5.4): `--coffset 325,=0`. Просто `0` по-прежнему
  значит «не трогать» (в OC-профиле HiveOS `0` = «поставить 0»; здесь пишите `=0`). Без `--coffset` оффсет вообще не
  трогается.
- То же правило списков — у `--uv-min` / `--uv-max` / `--uv-step` (5c) и `--temp-limit` (5f).
- **Строки на старте (0.5.4):** по строке на каждую карту с тем, что этот запуск на ней выставит (фиксации, оффсеты,
  лимит мощности, диапазон auto-uv, а с `--auto-lock` — перебирается ли фиксация этой карты); пример — в английском
  разделе.
- **`--dry-run`** печатает эти строки и выходит, ничего не меняя (root не нужен; с `--devices` не нужна и GPU). На
  самом риге показывает и замену частоты памяти по картам (`memory lock 810 MHz (not supported here: 5001)`).
- Нужны права **root** (Linux) / **администратора** (Windows). Без них ffgs пишет одну строку (`needs root …` /
  `needs Administrator …`) и майнит на текущих частотах.
- Применяется до стартового самотеста (ядро проверяется уже на новых частотах); каждое значение пишется в лог вместе с
  прочитанным обратно, а через ~30 с майнинга — строка с фактическими частотами карты.
- **Возвращается при выходе**: Ctrl-C, SIGTERM/SIGHUP, закрытие окна консоли, `--minutes`, фатальная ошибка. Фиксации
  частот сбрасываются на значения драйвера по умолчанию (прежнюю фиксацию драйвер прочитать не даёт), оффсеты и лимит
  мощности возвращаются к значениям, прочитанным до изменения. Если ffgs убит (kill -9, падение, отключение питания при
  работающем драйвере), файл-метка `ffgs-oc-<bus>.restore` рядом с программой заставит следующий запуск ffgs всё вернуть,
  даже без опций частот. Метку другого работающего ffgs он не трогает (эту карту оставляет в покое), метку до
  перезагрузки — выбрасывает.
- Трогаются только карты из `--devices`; сопоставление с NVML — по PCI bus id. NVML загружается при запуске
  (`libnvidia-ml.so.1` / `nvml.dll`); без неё ffgs всё равно майнит.
- `--oc-info` показывает текущие частоты, оффсеты (с допустимым диапазоном) и лимиты мощности, ничего не меняя.
- **Настройки частот ffgs главнее других средств разгона (0.5.4).** Значение, которое ffgs ставит на карту
  (`--lock-cclock`, `--lock-mclock`, `--coffset`, `--moffset`, `--plimit`, оффсет `--auto-uv`, фиксация `--auto-lock`),
  ffgs держит, **даже если в OC-профиле HiveOS другие значения** (HiveOS применяет OC после перезагрузки или смены OC,
  возможно уже после старта ffgs; MSI Afterburner / `nvidia-smi` — так же). Раз в 10 с, в своём такте строки состояния,
  ffgs сравнивает частоты, оффсеты и лимит мощности, которые и так читает для этой строки, со своими; при расхождении
  ставит свои снова (сначала фиксацию, потом оффсет; если частота или оффсет выше наших — работа этой карты на миг
  встаёт). Одна оранжевая строка на событие, не чаще раза в 10 мин на карту, со счётчиком пропущенных:
  `GPU0: core clock changed to 1680 MHz by another tool (HiveOS OC profile?) - ffgs's lock 1500 MHz wins, re-applied
  with the GPU paused`; в таблице частот — `re-applied Nx`. Проверка auto-uv или замер auto-lock, на время которых
  пришлась такая смена, выбрасываются и повторяются. Сбой карты (Xid) в момент, когда другая программа меняет её
  частоты (до 30 с после такого события на ней, до 15 с — на любой карте рига, или оффсет / частота при сбое не
  ffgs-овские), андервольту не засчитывается: оранжевая строка `... crashed (Xid 43) while another tool changed its
  clocks (HiveOS OC?): ... - not counted against the undervolt`, ffgs перезапускается как обычно. Если замечен только
  чужой оффсет, ffgs сначала ставит заново и свою фиксацию (фиксация другой программы может уже стоять). Фиксацию прочитать нельзя, поэтому она видна по частоте: выше
  нашей фиксации или заметно ниже при майнинге без причины по мощности / температуре и без снижения `--temp-limit`
  (2 замера подряд). Карты и значения, которые ffgs не ставит (`x`, нет опции), остаются за HiveOS / другой программой.
  Таблица и h-stats HiveOS показывают реальные частоты карты. Цена: единицы мкс на карту за такт (без отдельного
  потока; с `--plimit` — одно чтение лимита мощности).
- **При выходе** ffgs возвращает то, что застал при **своём** старте (оффсеты, лимит мощности), и снимает свои
  фиксации. Если HiveOS применил OC после старта ffgs, это состояние до OC HiveOS, а не OC-профиль; HiveOS снова
  применит OC при следующем запуске майнера.
- Windows: переменные `LOCK_CCLOCK`, `LOCK_MCLOCK`, `COFFSET`, `MOFFSET`, `PLIMIT` в `start.bat` / `start-saseulmine.bat` /
  `start-saseulpool.bat` (списки как выше, например `set COFFSET=325,x`; списки `--uv-*` — через `EXTRA`).
  Если задана хоть одна, скрипт просит Windows перезапустить его от администратора (`AUTO_ELEVATE=1` по умолчанию).

**Замеренные настройки по картам** (RTX 3070, RTX 3080 Ti, RTX 4070 Laptop) — таблицы в разделе 5 выше. RTX 3070:
`--lock-cclock 1500 --lock-mclock 810 --auto-uv` — лучший MH/W.

### 5c. Автоподбор андервольта `--auto-uv` (новое в 0.5.1, по фиксации частоты с 0.5.3)
ffgs сам подбирает андервольт: поднимает V/F-оффсет ядра каждой карты NVIDIA,
проверяет каждый шаг и оставляет последний удачный оффсет минус один шаг 15 МГц запаса.

    sudo ./ffgs --wallet <адрес>.<воркер> --lock-cclock 1500 --lock-mclock 810 --auto-uv

- **Нужна зафиксированная частота ядра** (`--lock-cclock`, фиксация в OC-профиле HiveOS или `--auto-lock`, 5e): тогда
  больший оффсет = та же частота при меньшем напряжении. Только NVIDIA, нужны права root / администратора.
- **От крупного шага к мелкому (0.5.4):** оффсет поднимается шагами по **30 МГц** (`--uv-coarse`). Когда шаг падает,
  тюнер возвращается к последнему хорошему оффсету и проверяет точку **+15 МГц** внутри этого интервала 30 МГц (один
  лишний шаг), затем оставляет 15 МГц запаса. Результат — тот же край с точностью 15 МГц, что и у подъёма по 15,
  примерно за половину шагов. (Сверху вниз — отклонено: первыми шли бы шаги, вероятнее всего роняющие карту.)
- **Новая фиксация стартует от известного профиля (0.5.4):** если у карты есть проверенный профиль более высокой (или
  той же) фиксации ядра с той же фиксацией памяти, старт = **оффсет этого профиля минус 30** вместо +120 (берётся
  ближайшая такая фиксация; на более низкой частоте держатся более высокие оффсеты). Прогрев проверяет старт как всегда.
  Не используется с `--uv-min`, после падения, когда не поднимает старт и когда тот профиль закончился на **полу
  напряжения** или на своём старте (более низкая частота выходит на пол ещё раньше — перенос оффсета вниз только съел бы
  запас; в логе `... ended on the voltage floor: not starting from it`).
- **Подбор:** проверка-прогрев на стартовом оффсете (2 мин), затем ~30 с на шаг, затем подтверждение 2 мин: обычно
  **~3,5–11,5 мин** (постоянная часть — прогрев + подтверждение — ~4,3 мин; вторая фиксация при известном профиле более
  высокой — ~6,5 мин; в 0.5.3 — до ~16,5 мин). **Ждёт только подбираемая карта, остальные в это время майнят**, и
  каждая карта начинает майнить сразу после своего подбора (0.5.3; раньше все карты ждали всех). В логе — прогресс (`step +340 (2/12): ok`), в строке
  статистики — метка после хешрейта карты (`GPU1 0.000 [tuning +340, step 2/12]`), примерно раз в минуту — сводка
  (`auto-uv: tuning 2 GPU(s) (GPU1, GPU3), ~6 min left`). Подбор заканчивается строкой `RESULT:`. Цвета (`--color`):
  прогресс — голубой, пройденные проверки и результат — зелёный, шаги назад — жёлтый, сбои — красный.
- **Порог напряжения:** если два шага подряд экономят слишком мало каждый (0,5 Вт на 15 МГц, т.е. < 1 Вт на шаг 30),
  поиск останавливается ниже них, а не идёт до `--uv-max` (напряжение уже на минимуме, больший оффсет только съедает
  запас; результат — хороший оффсет перед двумя плоскими шагами). Если поиск дошёл до `--uv-max` без
  сбоя, лог сообщает об этом и о сэкономленной мощности.
- **Стартовый оффсет, не прошедший проверку,** не остаётся: ffgs спускается шагами по 30 МГц до первого прошедшего и
  майнит на нём (в том числе ниже вашего оффсета).
- **Профили по фиксации частоты (0.5.3):** результат хранится по карте, модели, драйверу **и фиксации частоты ядра**
  (`1400/mem810` = `--lock-cclock 1400 --lock-mclock 810`; без фиксации от ffgs профиль выбирает частота ядра под
  нагрузкой майнинга, `~1410`). При смене фиксации и возврате каждый профиль используется снова. Профиль, проверенный
  в пределах `--uv-reval-hours`, **применяется сразу** (карта майнит немедленно); более старый, от другой версии ffgs
  или пониженный после сбоя — после проверки 20 с (ждёт только эта карта). Профиль без эталона этой версии ffgs (из 0.5.1 /
  0.5.2, от другой версии ffgs, при других `--blocks` / `--threads`) сначала получает новый эталон — 60 с на своём нижнем
  оффсете, затем проверку 20 с: ~85 с; тег статуса — `[reference +240]`, затем `[check +300]`, в логе это написано.
  Результаты 0.5.1 / 0.5.2 становятся профилем той частоты, на которой подбирались, и используются для близкой фиксации
  после проверки.
- **Проверка** гоняет ядро майнинга на полной нагрузке в отдельном процессе на фиксированных тестовых заданиях: число
  кандидатов каждого запуска должно точно совпасть с эталоном (если карта хоть один хеш посчитала неверно, это видно за
  секунды), каждый сохранённый кандидат пересчитывается на CPU. Падение или зависание карты убивает только этот процесс.
- **Во время майнинга:** аппаратная ошибка (bad candidate) — шаг назад на 15 МГц (сохраняется, при следующем запуске
  проверяется); каждые 6 ч перепроверка 20 с (карта на это время встаёт). Если оффсет поменял кто-то другой (OC HiveOS), ffgs
  ставит свой снова (5a; с 0.5.4, раньше auto-uv карту отпускал). Сбой GPU (Xid) — см. 5d.
- Результаты — `ffgs-uv-results.txt` рядом с программой (HiveOS: `/hive-config/ffgs`, переживает обновления майнера).
  Если ffgs упал на шаге (kill, Xid, питание), следующий запуск вернёт оффсет и будет подбирать ниже этого шага;
  остановка ffgs (Ctrl-C, остановка майнера в HiveOS) во время проверки сбоем не считается. При выходе исходный оффсет
  возвращается, как с `--coffset`.
- Опции: `--uv-min МГц` (начало поиска; по умолчанию текущий оффсет, иначе +120, RTX 40/50 — минимум +200; или
  подсказка от более высокой фиксации, см. выше), `--uv-max МГц` (по умолчанию +495), `--uv-step МГц` (15: **мелкий**
  шаг — точность и запас результата, откат подтверждения и по аппаратным ошибкам; явный `--uv-step 15` ускорение
  сохраняет), `--uv-coarse МГц` (новое в 0.5.4, шаг подъёма, по умолчанию 2 × `--uv-step`; `--uv-coarse 15` или любое
  ≤ мелкого шага — подъём как в 0.5.3), `--uv-reset` (забыть профиль текущей фиксации и подобрать заново; профили других
  фиксаций остаются), `--uv-reset-all` (забыть все профили **карт этого запуска**, всех фиксаций; с 0.5.4 строки других
  карт в файле остаются — на смешанном риге или при двух процессах ffgs с общим `/hive-config/ffgs` чужие профили не
  стираются), `--uv-reval-hours Ч` (6, 0 = никогда). Подбор, остановленный до результата, строки в файле не оставляет.
  `--uv-min`, `--uv-max`, `--uv-step` принимают **списки по картам** (0.5.4, правило из 5a): `auto` — по умолчанию,
  пусто / `-` / `x` — **на этой карте auto-uv нет** (`--uv-max 400,x`; в логе
  `auto-uv: GPU1 left alone (empty / - / x in a --uv-* list)`).
  Windows: `AUTO_UV=1` в батниках. `--coffset` вместе с `--auto-uv` — поиск начинается с этого оффсета.
  `--uv-reset` / `--uv-reset-all` действуют один раз: собственный перезапуск после сбоя GPU (5d) их не повторяет.
- Кроме подсказки от более высокой фиксации, старт по фиксации не выбирается: края у карт одного типа слишком разные
  (RTX 3070 на 1700: +345 … +375). Старт — ваш текущий оффсет (например `--coffset 325`); если он не проходит, это стоит
  нескольких проверок, а не подбора. Замеры по частотам — таблицы в разделе 5.

### 5d. Сбои GPU (новое в 0.5.3)
Сбой GPU (Xid 13 / 43 драйвера, "an illegal memory access") раньше завершал ffgs, и HiveOS перезапускал его в тот же
сбой. Теперь:
- сбойная карта определяется по событиям Xid драйвера и пишется в лог: `faults: GPU4 (bus 0000:04:00.0, RTX 3070)
  FAILED: Xid 43 reported by the driver for this GPU`; она запоминается с оффсетом в `ffgs-gpu-faults.txt` (рядом с
  программой; HiveOS: `/hive-config/ffgs`);
- остальные карты продолжают майнить, если могут; если не осталось ни одного воркера (или карта зависла, 5g), ffgs
  возвращает частоты и **перезапускает себя сам**, не больше 12 раз в час:
  - Linux: тот же процесс и лог (exec); сверх лимита выходит, и HiveOS перезапускает его как раньше;
  - Windows (0.5.4): ffgs выходит с кодом 2, и `start.bat` запускает его снова через 10 с (все карты снова майнят через
    ~20 с). Времена перезапусков хранятся в `ffgs-restarts.txt` в папке состояния (рядом с `ffgs-uv-results.txt`);
    старт в пределах 120 с после последнего считается этим перезапуском, поэтому лимит 12 в час соблюдается: сверх него
    ffgs ждёт, пока самый старый перезапуск этого часа не устареет, и только тогда выходит. Позднейший запуск вручную
    начинает счёт заново;
  - `--uv-reset`, `--uv-reset-all` и `--auto-lock-reset` при таких перезапусках не повторяются;
- **с `--auto-uv`:** карта, упавшая на своём андервольте, возвращается **на 30 МГц ниже** после проверки 20 с (без
  подбора с нуля; профиль обновляется). Карта, падающая 2 запуска подряд на своём (сохранённом) оффсете, понижается на
  60 МГц за каждые 2 сбоя до 0, затем исключается;
- **без `--auto-uv`:** ffgs оффсеты не меняет; карта, упавшая 2 запуска подряд, **исключается из майнинга на час**
  (`... is LEFT OUT of mining ...`), остальные майнят; если исключены все карты, ffgs ждёт, а не выходит (нет цикла
  перезапусков);
- **GPU, который не открывается (0.5.4)** — `CUDA-capable device(s) is/are busy or unavailable`, часто с Xid 38 на каждой
  попытке, например после сбоя предыдущего майнера при его остановке, — это **не** сбой андервольта или оффсета: ничего
  не записывается, оффсет и профиль auto-uv остаются. ffgs пишет об этом один раз (`GPU1 ... cannot be opened (...):
  likely needs a GPU reset or a reboot; left out, the other GPUs mine ...`), показывает `[unavailable]` в строке статуса
  (API: `"state":"unavailable"`) и пробует снова через 1, 5 и 15 мин, дальше каждые 15 мин; как только карта открылась —
  она майнит. Подбор или проверка этой карты ждёт так же и продолжается на том же оффсете. Обычно помогает только
  перезагрузка.
- 30 мин майнинга без сбоя обнуляют счётчик. Удаление `ffgs-gpu-faults.txt` забывает всё сразу.

### 5e. Автовыбор фиксации частоты ядра `--auto-lock` (новое в 0.5.4)
ffgs сам выбирает фиксацию частоты ядра каждой NVIDIA-карты: майнит на нескольких частотах, каждую — со своим
андервольтом (auto-uv, 5c), меряет хешрейт и мощность и оставляет самую экономичную частоту, теряющую не более 10 %
от максимального хешрейта.

    sudo ./ffgs --wallet <адрес>.<воркер> --lock-mclock 810 --auto-lock

- **Только NVIDIA, root / администратор.** `--auto-lock` включает `--auto-uv`. `--lock-mclock`, `--moffset`, `--plimit`
  работают как раньше (фиксация памяти входит в ключ сохранения: другая — новый перебор).
- **`--lock-cclock` вместе с `--auto-lock`:** карта со своим значением `--lock-cclock` (одно значение — все карты; список
  по картам — эти карты) сохраняет эту фиксацию и **не перебирается**; остальные перебираются. `--lock-cclock 1400,x
  --auto-lock` перебирает только GPU1. Если значение есть у всех карт, перебирать нечего (предупреждение; auto-uv
  подбирает каждую на её фиксации). Карта с `x` в списке `--uv-*` (без auto-uv) тоже не перебирается. Стартовые строки по
  картам (5a) показывают это в колонке `auto-lock` (`sweeps the core lock`, `off (own --lock-cclock)`, `off (no auto-uv)`).
- **Какие частоты:** по умолчанию 1800, 1700 … 1200 МГц, не выше максимальной частоты карты (карта, не достающая
  1600, получает 5 частот ниже своего максимума). `--auto-lock-range 1200-1700:100` (от-до[:шаг], шаг по умолчанию 100)
  или список `--auto-lock-range 1300,1450,1600`.
- **Перебор, сверху вниз, по каждой карте:** ставится частота → auto-uv сразу применяет сохранённый профиль этой
  частоты или проверяет / подбирает его (новая частота стартует от профиля более высокой минус 30, 5c: **~5–12 мин**;
  **ждёт только эта карта**) → карта **майнит**: 45 с на установление, затем 120 с замера (GH/s по собственному счётчику
  хешей карты, средние ватты NVML, медиана частоты ядра). **Шары, найденные во время замера, уходят в пул как обычно.**
  Остальные карты майнят всё время; все карты перебираются параллельно.
- **Ранний останов:** как только частота ниже максимума больше допустимой потери, ниже не меряется.
- **Выбор:** `--auto-lock-goal eff` (по умолчанию) — лучший MH/W среди частот в пределах `--auto-lock-max-loss` % (10,
  0..90) от максимального GH/s; `--auto-lock-goal speed` — максимальный GH/s.
- **Не в зачёт:** частота не удержалась (медиана ниже фиксации больше чем на max(45 МГц, 3 %): лимит мощности /
  температуры) → `not valid`; аппаратные ошибки во время замера → `not valid` (и auto-uv откатывает профиль на шаг);
  майнинг рвался (нет задания, пул офлайн) → до 3 повторов, затем `not valid`. Частоту отверг драйвер, auto-uv не
  нашёл рабочего оффсета, сбой GPU (Xid) на ней → `FAILED`, дальше частота ниже. Если ffgs умер во время частоты
  (Xid, зависание, питание), следующий старт помечает её `crashed` и больше не пробует (до `--auto-lock-reset`).
- **Нет управления фиксацией** (часть ноутбуков, старые карты): строка `... not supported on this GPU: fallback to
  auto-uv at the current clocks`, карта майнит как с одним `--auto-uv`. Ни одной годной частоты — возврат к частотам
  драйвера по умолчанию.
- **Итог** — таблица в логе (частота, оффсет, GH/s, Вт, MH/W, ★ у выбранной; пример — в английском разделе), строка
  `mining at lock 1700 ★`. Во время перебора в строке статуса после хешрейта карты — метка
  `[auto-lock 1700, 2/7: measuring]`.
- **Сохраняется** по карте, модели, драйверу и фиксации памяти в `ffgs-autolock.txt` рядом с `ffgs-uv-results.txt`
  (HiveOS: `/hive-config/ffgs`). **Следующий старт сразу ставит сохранённую частоту** (с её профилем auto-uv). Смена
  `--auto-lock-goal` / `--auto-lock-max-loss` — перевыбор из сохранённых точек без замеров; более широкий диапазон или
  большая потеря — меряются только недостающие частоты. `--auto-lock-reset` забывает точки и перебирает заново (профили
  auto-uv остаются; `--uv-reset` вдобавок переподберёт каждую частоту). Новый драйвер = новый перебор. Собственный
  перезапуск (5d) `--auto-lock-reset` не повторяет.
- **Время:** первый перебор карты — на каждую частоту подбор auto-uv новой частоты (карта на паузе) плюс ~3 мин замера
  в майнинге; с ранним остановом обычно 3–5 частот на карту, параллельно по всем картам. Последующие старты — ничего.
- **С `--temp-limit`** (5f) фиксацию, которой владеет auto-lock, он никогда не снижает (только паузы / стоп). Сторож
  зависания (5g) на время смены частоты придерживается и на новой частоте начинает новую базу.
- **HiveOS:** `--auto-lock` (и, например, `--lock-mclock 810`) — в *Extra config arguments*; **фиксацию ядра в
  OC-профиле HiveOS оставьте пустой** (ffgs ставит фиксацию и сбрасывает её на выходе). **Windows:** `set AUTO_LOCK=1` в
  стартовом скрипте (считается настройкой частот для `AUTO_ELEVATE`).

### 5f. Защита по температуре `--temp-limit` (новое в 0.5.4; в первую очередь для ноутбуков)
**Предназначено в первую очередь для ноутбуков и мобильных GPU.** У ноутбука охлаждение общее с CPU, а вентиляторами не
управлять, поэтому при долгом майнинге GPU сидит на собственном пороге троттлинга (~87 °C). `--temp-limit` держит его
холоднее, давая меньше работы. Десктопные риги обычно держат температуру вентиляторами (HiveOS autofan), им это не нужно.

| Опция | Смысл | По умолчанию |
|---|---|---|
| `--temp-limit C[,C…]` | держать GPU не выше C (40..100); одно значение или список по картам (5a), `0` / пусто — выключено для этой карты | выкл |
| `--temp-stop C2[,…]` | жёсткий стоп: при C2 (3 замера подряд) GPU не майнит, пока не остынет на 6 °C ниже лимита | min(C+10, 90), не меньше C+3 |
| `--temp-mem C[,…]` | лимит памяти (junction), если драйвер его даёт (стоп = он + 10) | C+15 |
| `--temp-hotspot C[,…]` | лимит hotspot (AMD «junction»), если есть (стоп = он + 10) | C+15 |
| `--temp-no-clocks` | никогда не снижать фиксацию ядра, только паузы | — |

Пример (ноутбук, Windows, без администратора): `ffgs.exe --wallet ... --temp-limit 80` или `set TEMP_LIMIT=80` в
стартовом скрипте.

- **Мягкий старт:** майнинг начинается с доли работы 30 % и плавно разгоняется (строки в логе нет, если GPU не дошёл до
  лимита; холодная карта выходит на полную скорость за ~15–30 с). Датчик ядра ноутбука реагирует на мощность примерно за
  секунду: старт сразу со 100 % давал выброс на 15–25 °C выше лимита.
- С **C-3** (по сглаженному замеру) GPU в режиме лимита; регулятор задаёт *долю работы* (10–100 %), чтобы температура
  держалась в **C-2 .. C-1**. Он смотрит на замер, сглаженный за несколько секунд, и меняет долю работы медленно (не
  больше +5 % / −20 % в секунду), поэтому быстрый датчик ноутбука его не раскачивает. Доля работы — это паузы между
  запусками: права админа не нужны, работает на ноутбуках без управления частотами и на AMD.
- Если ffgs сам зафиксировал частоту ядра (`--lock-cclock`, root / администратор, NVIDIA) и на этой карте нет оффсета
  ffgs или auto-uv, **сначала снижается эта фиксация** (шаг 15 МГц, до 60 % фиксации / не ниже 800 МГц), паузы — только
  ниже (ниже частота — ниже напряжение, энергия на хеш меньше, чем при простое). С `--auto-uv` / `--coffset` фиксация не
  снижается (оффсет найден именно на ней), с `--auto-lock` (5e) — тоже.
- **Полная скорость** (одна строка в логе) после 30 с на полной скорости при температуре не выше **C-5**. **Жёсткий
  стоп:** любой датчик на своей температуре стопа 3 замера подряд (или сразу, если на 5 °C выше) → запусков нет, пока
  все датчики не станут на 6 °C ниже своих лимитов (или на 3 °C ниже, если стоп длится уже 60 с: тёплый ноутбук может
  простаивать около C-6), затем майнинг с 30 % и плавный разгон. Односекундный пик стопа не вызывает.
- **Чего это стоит — честно.** Без прав администратора остаются только паузы, а в своих запусках GPU работает на полном
  бусте (термотроттлинг драйвера в паузах отпускает). Поэтому лимит снижает температуру и шум ценой хешрейта **и**
  эффективности. Замер на RTX 4070 Laptop (Windows, от сети, без админа): без лимита 4,80 GH/s, 63 Вт, **77 MH/W** —
  драйвер сам держит 86–87 °C; `--temp-limit 75` / `70` — 1,5–1,8 GH/s, 32–38 Вт, **~47 MH/W** (замер до перенастройки
  регулятора в 0.5.4, описанной здесь; перенастройка проверена на модели этого ноутбука). Это способ держать
  ноутбук холоднее и тише, а не намайнить больше на ватт. С правами администратора / root и `--lock-cclock` ffgs сначала
  снижает фиксацию частоты (следующий пункт) — с ней эффективность заметно лучше, чем с паузами.
- **Лог:** строка только на смену состояния. В строке статуса `GPU0 3.100 [temp-limit 72%]`, `[temp-limit 1290 MHz]` /
  `[temp-limit 840 MHz 60%]` или `[temp-stop 91 C]`; в минутной таблице `temp-limit 80 C: 72% now, throttled 12m 30s,
  1 stop(s)`. HiveOS `h-stats.sh` эти метки пропускает. Показывается и отдаётся реальный хешрейт; пока GPU не майнит
  (temp-stop, пул офлайн), в строке 0 и 0.0 MH/W (в таблице `-`).
- **Тестовый хук** `FFGS_TEST_TEMP` (только для разработки) подменяет *замер* температуры: настоящий GPU при этом ничем
  не защищён (греется как без лимита). Только короткие прогоны на холодной карте.
- **Датчики:** NVIDIA (NVML, без root) — ядро; память — где карта её отдаёт (HBM; GeForce обычно нет); hotspot в NVML
  нет. AMD Linux (amdgpu hwmon) — edge, junction (hotspot), mem. AMD Windows — в этой версии датчиков нет (`--temp-limit`
  там выключен, пишется в лог). Учитывается самый горячий датчик относительно своего лимита; карта без датчика не
  ограничивается (лог при старте).
- **С auto-uv:** проверка начинается, только когда карта на паузе остыла до C-10; проверка, дошедшая до `--temp-stop`,
  повторяется после остывания; шаг подбора, который всё время слишком горячий, завершает поиск на последнем хорошем (не
  считается краем). Сторож зависания (5g) никогда не оценивает карту, которую `--temp-limit` притормаживает или
  остановил. `--bench` и `--selftest` `--temp-limit` не учитывают.

### 5g. Сторож зависания GPU (новое в 0.5.4)
5d реагирует, когда воркер **останавливается** с ошибкой CUDA и драйвер сообщает Xid. Но карта может сломаться тихо:
запуск ядра не возвращается (**зависание**: ни ошибки, ни Xid) или карта работает в разы медленнее (**просадка**).

- **Зависание** — у майнящего воркера нет прогресса `--watchdog-hang` с (по умолчанию 60; 180, пока воркер открывает
  GPU). Карта останавливается как сбой без Xid (запись в `ffgs-gpu-faults.txt` с её оффсетом, как в 5d), и ffgs
  **перезапускает себя**, даже если другие карты майнят (5d: Linux — exec, Windows — выход 2 + `start.bat`; не больше 12
  в час). Следующий старт действует по записи, как при Xid (с `--auto-uv` на 30 МГц ниже; без него карта, зависшая 2
  старта подряд, исключается на час). Сверх лимита 12 в час остальные карты майнят, а зависшая ждёт следующего старта.
  AMD: ffgs выходит (2), перезапускает стартовый скрипт / HiveOS.
- **Просадка** — хешрейт карты за 10 с держится ниже `--watchdog-drop` % (30) её **собственной** базы
  `--watchdog-minutes` (3) минут. База = медиана последних 60 нормальных 10-с замеров (10 мин), оценка — после 5 мин
  замеров; низкие замеры в базу не попадают. Действие: на тюненом оффсете auto-uv оффсет сразу −30 МГц (перепроверка в
  течение минуты); воркер этой карты останавливается, CUDA-контекст сбрасывается (AMD — OpenCL-контекст создаётся
  заново), стартует новый воркер; остальные карты майнят. 3-я просадка карты за час, воркер, не остановившийся за 30 с,
  или карта, которую не удалось открыть снова, — как зависание.
- **Не оценивается** (и 30 с после; 60 с после старта воркера): воркер простаивает (проверка / подбор auto-uv, нет
  задания, пул офлайн), минута комиссии / реферала, перезапуск воркера; пока auto-uv меняет оффсет или auto-lock меняет
  фиксацию (смена фиксации начинает новую базу); карта, которую `--temp-limit` притормаживает или остановил. Просадка,
  пока NVML сообщает аппаратный / драйверный троттлинг (HW slowdown, thermal, power brake), **только пишется в лог** (раз
  в 10 мин): перезапуск не поможет. Просадка больше половины карт сразу (минимум 2) — это риг (CPU, питание, хост):
  пишется раз в 10 мин, ничего не перезапускается.
- Опции: `--watchdog-hang С` (≥ 10), `--watchdog-drop ПРОЦ` (1..95), `--watchdog-minutes М` (≥ 0,5), `--no-watchdog`.
- Строки лога начинаются с `watchdog:` (`HANG`, `SLOW` красным, с частотами, ваттами и температурой в этот момент). В
  строке статуса после хешрейта карты — ` [wd 1h 2s]`, если сторож действовал на неё в этом запуске (h — зависания, s —
  просадки); h-stats HiveOS не затронут. Счётчики — в поле `watchdog` API (3d).

### 5b. Видеокарты AMD (новое в 0.4.0)
Тот же `ffgs` / `ffgs.exe` майнит и на AMD Radeon через OpenCL (оптимизировано под RDNA2):
- `--backend auto` (по умолчанию) берёт CUDA, если есть карта NVIDIA, иначе AMD; `--backend amd` — принудительно AMD.
  При старте в логе список AMD-устройств (`AMD0: …`); `--devices` — в этой нумерации (дискретные AMD по порядку шины
  PCI, встроенная графика пропускается).
- Windows: нужен только драйвер Adrenalin (его `OpenCL.dll`). Linux / HiveOS: OpenCL-рантайм (`libOpenCL.so.1`, ROCm
  или amdgpu-pro) — **на Linux-риге с AMD ещё не проверено**.
- Замеры RX 6800 XT (Windows): 9.0 GH/s rabbitminer / 9.86 GH/s saseulmine на стоке (~239 Вт ASIC);
  2300 МГц при 881 мВ в Adrenalin: 9.7 GH/s при ~164 Вт.
- Опции частот из 5a и столбцы мощности / частот / температуры / вентилятора — **только NVIDIA**; с бэкендом AMD опции
  частот игнорируются (одно предупреждение) — частоты и напряжение AMD задавайте в Adrenalin / OC HiveOS.
- `--bench` перепроверяет на CPU каждого кандидата и печатает число аппаратных ошибок — так проверяется андервольт.
- Заметки разработчика и замеры: `docs/amd.md` в репозитории исходников.

### 6. Комиссия разработчика и реферал: 2% = 1% разработчику + 1% рефереру
Комиссия — **2%: два отдельных окна по 60 секунд в каждые 100 минут** (первое — через 15 минут майнинга):

- **1% рефереру** — майнится на кошелёк из **`--referrer АДРЕС`** (того, кто посоветовал вам ffgs), на вашем же пуле.
  Без `--referrer` (или с `--referrer none`) реферальная минута идёт разработчику. Соло / своя нода: реферальная минута
  майнится на Kavatar SL Pool (ваша нода этому адресу не заплатит).
- **1% разработчику ffgs** — на кошелёк разработчика (`a750e196…a624`) на вашем же пуле (соло / своя нода:
  saseulmine.com, затем rabbitminer.cc).
- **Свой кошелёк рефером = комиссия 1%**: переключения на реферала нет вовсе, а оставшаяся минута разработчика майнится
  на **Kavatar SL Pool** (`sl.kasplay.online:3333`, пул авторов ffgs); если Kavatar недоступен — на вашем пуле. Если вы и
  так майните на Kavatar, пул вообще не меняется.
- Оба соединения комиссии открываются заранее и держатся постоянно, GPU переключаются только на готовое задание и, пока
  пул комиссии подключается, считают на вас; каждое окно — жёстко **60 с реального времени**: если пул комиссии не готов,
  окно пропускается. Реферер печатается в логе при старте; в строке статуса шары разработчика (`fee …`) и реферала
  (`ref …`) считаются отдельно.
- Windows: `REFERRER=` в стартовом `.bat`; HiveOS: `--referrer АДРЕС` в *Extra config arguments*.

**Реферер saseulmine.** У самого saseulmine.com тоже есть рефереры: блок делится 80% майнерам / 10% реферерам / 10% пулу,
и пул пишет *«No referrer? Your share is unchanged»* — реферальные 10% идут из части пула. ffgs отправляет туда ваш
`--referrer` (по умолчанию — кошелёк разработчика; `--referrer none` — без реферера).

### 6a. Особенности saseulmine.com
- HTTPS (`pool.saseulmine.com:443`); каждый запрос подписан Ed25519-*ключом клиента*. ffgs создаёт его один раз и хранит
  рядом с программой в `ffgs-client.key` (если папка только для чтения — новый ключ при каждом запуске). Ключ — лишь
  «паспорт» рига для пула, монет на нём нет. Не копируйте его между ригами.
- Имён воркеров у пула нет (в аккаунте один воркер `default`); `.ВОРКЕР` / `--worker` для него игнорируются.
- **Несколько ригов на один адрес работают**, но сложность шары (vardiff) у пула привязана к *адресу*: когда один риг её
  поднимает, шару, найденную другим ригом мгновением раньше на прежней сложности, пул отклоняет
  (`HTTP 400 Hash does not meet pool difficulty`). ffgs показывает такие шары как `low-diff` (жёлтым, отдельно от
  отклонённых), сразу запрашивает новую сложность и перепроверяет шары в очереди перед отправкой. Несколько low-diff в час
  при двух и более ригах на адрес — норма; это немного хешрейта впустую, на учёт выплат не влияет.
- Сложность шары пул задаёт по адресу (vardiff) и меняет почти после каждой шары: несколько шар в минуту на риг — норма.
  Шары, найденные прямо перед новым блоком или перед повышением сложности, пул бы отклонил, поэтому ffgs их не отправляет
  (`share dropped: …` в логе).
- Часы: пул присылает своё время в каждом ответе; ffgs берёт его для подписи и для времени блока — неверные часы ПК не мешают.
- Linux: сертификаты CA читаются из `/etc/ssl/certs/ca-certificates.crt` (или других обычных мест; `SSL_CERT_FILE`
  переопределяет). Windows использует системное хранилище сертификатов и прокси.
- Аккаунт и выплаты — на сайте пула (saseulmine.com) по адресу; `--pool-test` печатает те же данные в консоль.

### 6b. Особенности saseulpool.com
- Примеры подключения:

      ./ffgs --pool saseulpool --wallet АДРЕС.ВОРКЕР                              # Linux
      ./ffgs --pool nats://nats.saseulpool.com:4222 --wallet АДРЕС --worker rig1  # то же, полный URL

  Windows: впишите адрес в `start-saseulpool.bat` (`set WALLET=…`, при желании `set WORKER=…`) и запустите его.
  Полётный лист HiveOS (Custom miner, см. [HIVEOS.md](HIVEOS.md)): *Pool URL* `nats://nats.saseulpool.com:4222`,
  *Wallet and worker template* `%WAL%.%WORKER_NAME%`, *Installation URL* — пакет релиза ffgs.
- Протокол: NATS (обычный TCP, порт 4222, без логина и TLS). Узлы пула публикуют шаблон блока примерно раз в 10 с;
  сложность шары фиксированная: сложность сети / 4096 (около 2.2·10^11, ~1 шара в минуту на 4 GH/s).
- **Пул не отвечает на отдельные шары.** ffgs считает шару `delivered` (доставленной), когда NATS-сервер подтвердил, что
  получил её (в строке статуса `acc` и в таблице — доставленные). Засчитал ли их пул, показывает строка `pool` в
  таблице раз в 5 мин по API пула: PPLNS-*работа* адреса за последние 90 мин (сумма сложностей принятых пулом шар) в
  пересчёте на GH/s, ваша доля пула и следующая выплата, а также хешрейт адреса на сайте пула. На коротком отрезке
  оценка по работе сильно скачет (одна шара ≈ 2.2·10^11 хешей) — сравнивайте за час и больше.
- Хешрейт на сайте пула — тот, что сообщает сам майнер (раз в 10 с, по воркеру), а не измеренный пулом.
- Имя воркера: `.ВОРКЕР` / `--worker`, иначе имя компьютера; символы кроме букв, цифр, `-` и `_` заменяются на `-`.
  Несколько ригов на одном адресе — можно (с разными именами воркеров).
- Комиссия пула 5%, окно PPLNS 90 мин, выплаты раз в 6 ч от 10 SL (на октябрь 2026). Аккаунт и выплаты —
  [saseulpool.com](https://saseulpool.com) по адресу; чат пула t.me/poolSaseul.
- Время блока берётся из часов компьютера: держите их синхронизированными (NTP / синхронизация времени Windows).

### 7. Если что-то не так
| Сообщение | Что значит / что делать |
|---|---|
| `hardware error (bad candidate)` | GPU посчитала неверный хеш — снизьте разгон ядра |
| `share rejected: … stale` | блок сменился, пока шара летела; единичные — норма |
| `cannot connect to any pool` | проверьте адрес пула / сеть; майнер переподключается сам |
| `self-test failed` | неверные результаты на этой GPU/драйвере — майнер не запускается; сообщите модель и драйвер |
| `share dropped: stale (new block)` / `below the raised share difficulty` | saseulmine: пул отклонил бы шару, поэтому она не отправляется; единичные — норма |
| `share stale: … Stale share` | saseulmine: блок сменился, пока шара летела (HTTP 409); в rej не считается; единичные — норма |
| `TLS connect … certificate not trusted` / `no CA certificates found` | Linux: установите пакет `ca-certificates` или задайте `SSL_CERT_FILE` |
| `HTTP 401` | пул не принял подпись запроса — проверьте, что ffgs не изменён; часы корректируются автоматически |
| `clocks: GPU clock settings skipped: needs root …` / `needs Administrator …` | опциям частот нужны root / окно администратора; майнинг идёт на текущих частотах |
| `clocks: … held by another running ffgs` | частотами этой карты управляет другой ffgs; этот их не трогает |
| `clocks: … an earlier ffgs run left clock settings changed` | ffgs был убит с выставленными частотами; запустите ffgs один раз от root / администратора, он всё вернёт |
| `… console lines skipped (output was blocked)` | консоль / pipe долго не читали вывод; майнинг шёл, в файле `--log` есть все строки |
| `share below the pool's current difficulty …` (low-diff) | saseulmine: другой риг на том же адресе поднял сложность адреса; см. 6a |
| `share delivered #N` | saseulpool: шара дошла до сервера пула (пул не отвечает на отдельные шары; см. 6b) |
| `connection lost (… no job for 60 s)` / `(… no answer to PING for 15 s)` | saseulpool: сервер перестал присылать задания или отвечать; ffgs переподключается, при необходимости — к следующему серверу кластера |
| `saseulpool: no credited shares of this wallet in the 90 min PPLNS window yet` | норма в первые минуты; если держится 30+ мин при доставленных шарах — проверьте адрес и часы компьютера |
| `share rejected: HTTP 400 … Timestamp out of range (share timestamp … vs pool time, found … ago)` | шара пришла на пул слишком поздно или с неверным временем; числа показывают, насколько. Единичные после сбоев сети — норма |


### 8. Соло-майнинг (своя нода)
Соло — без пула и комиссии пула: риги майнят прямо на вашу ноду SASEUL, найденный блок целиком платит награду на ваш
адрес. Мост между нодой и ffgs — **соло-прокси** `solo/sl_solo_proxy.py` (Python 3, только стандартная библиотека; в Linux-пакете и
репозитории исходников).

**Соло платит только за найденный блок.** Среднее время до блока = `сложность сети / ваш хешрейт` секунд: при
сложности 8.95e14 (октябрь 2026) одной RTX 3070 (4.6 GH/s) нужно в среднем 8.95e14 / 4.6e9 ≈ 195 000 с ≈ **54 часа**
на блок, 6800 XT (9.8 GH/s) — ≈ 25 часов, и реальное время сильно гуляет (экспоненциальное распределение: вдвое дольше
среднего без блока — в ~14% случаев). Соло — при достаточном хешрейте или терпении; пул платит понемногу, но ровно.

**Что нужно**
- **Синхронизированная нода SASEUL** (2.2.x; например, официальный Docker-образ), работающая 24/7, с включённым внешним
  майнингом: `saseul-script mining external on` и `saseul-script mining start` (в контейнере: `docker exec <контейнер> …`).
- **Каталог `run`** ноды на хосте: нода пишет текущий шаблон блока в `run/mining_job` и забирает найденные блоки из
  `run/mining_result`. В Docker смонтируйте run-каталог ноды томом (например, на хосте `/var/saseul-run`), чтобы прокси
  мог его читать и писать.
- Python 3.8+ на машине с нодой и TCP-порт (по умолчанию 19310), доступный ригам (открывайте только для них).

**Установка прокси (Linux, systemd)**

    sudo mkdir -p /opt/sl-solo /etc/sl-solo /var/lib/sl-solo
    sudo cp solo/sl_solo_proxy.py /opt/sl-solo/
    sudo cp solo/env.example /etc/sl-solo/env && sudo chmod 600 /etc/sl-solo/env     # правка: SL_RUN, SL_TOKEN, ...
    sudo cp solo/addresses.txt.example /etc/sl-solo/addresses.txt                    # правка: ваш(и) адрес(а)
    sudo cp solo/sl-solo-proxy.service /etc/systemd/system/
    sudo systemctl daemon-reload && sudo systemctl enable --now sl-solo-proxy
    journalctl -u sl-solo-proxy -f

Настройки (переменные окружения, `/etc/sl-solo/env`): `SL_RUN` (run-каталог ноды), `SL_PORT` (19310), `SL_TOKEN`
(пароль входа майнеров — длинный случайный; пусто = без проверки), `SL_SHARE_DIFF` (сложность шары для контроля
хешрейта, по умолчанию 1e11), `SL_ADDRESSES` (файл адресов), `SL_STATE` (счётчики), `SL_PUBLIC` (публичная нода для
проверки синхронизации, по умолчанию `http://main.saseul.net/info`), `SL_NONCE_LEN` (40). Прокси раздаёт задания
**только пока нода в синхроне** с сетью; до тех пор ffgs ждёт.

**Ротация адресов.** В `addresses.txt` — один или несколько адресов выплаты (по 44 hex, ключи от которых у *вас*);
прокси ставит в каждый новый шаблон блока следующий. Зачем: SASEUL платит майнерам последних 9 блоков по `total/32`, а
оставшиеся **23/32 делит поровну между уникальными адресами** среди них — один и тот же адрес на нескольких из этих
блоков получает эту часть один раз. С разными адресами выигрыш ≈ +2.5% при 1% хешрейта сети и ≈ +25% при 10%; для
нескольких GPU он близок к нулю, так что **одного адреса достаточно**. Награда приходит на эти адреса как *resource*:
переведите её в SL через `Refine` и перешлите через `Send` (обычные транзакции с комиссией — на адресе нужно немного
SL), например в кошельке Guardee.

**Подключение ffgs**

    ./ffgs --pool IP_НОДЫ:19310 --wallet АДРЕС.ВОРКЕР --pass SL_TOKEN

Адрес в `--wallet` — только метка в логе прокси, **награда идёт на адреса из `addresses.txt`**. Прокси отдаёт задания с
nonce 40 hex; ffgs сам переключается на соло-ядро (опций не нужно). Несколько ригов могут работать через один прокси.
Список пулов `ХОСТ:ПОРТ` без хоста rabbitminer.cc ffgs считает соло: минута комиссии 1% тогда майнится на
saseulmine.com на кошелёк разработчика (запасной — rabbitminer.cc), а не на вашу ноду (см. 6); поэтому ригу нужен и
доступ в интернет к pool.saseulmine.com или rabbitminer.cc (без него окно комиссии пропускается, майнинг идёт на вас).
- Windows: в `start.bat` задайте `POOL=IP_НОДЫ:19310`, `WALLET=` ваш адрес, `WORKER=` имя и `EXTRA=--pass SL_TOKEN`.
- Полётный лист HiveOS: Pool URL `IP_НОДЫ:19310`, Wallet template `%WAL%.%WORKER_NAME%`, Extra config arguments
  `--pass SL_TOKEN` (см. HIVEOS.md).

**Как проверить**
- Лог прокси: `node IN SYNC: job height …`, `job height … diff … miner #N …` на каждом блоке, `login ВОРКЕР from IP: ok`,
  `stats: … shares_total=… blocks=… active={…}` раз в 5 мин, `reject ВОРКЕР: …` на отклонённые шары.
- Лог ffgs: `connected IP_НОДЫ:19310`, `new block height …`, принятые шары (это шары прокси на `SL_SHARE_DIFF`, для
  контроля). Найденный блок: `*** BLOCK FOUND (block) ***` в ffgs и `*** BLOCK <высота> by ВОРКЕР miner <адрес>` в логе прокси;
  прокси пишет его в `run/mining_result`, нода рассылает. Проверьте блок в эксплорере / `saseul-script info` и баланс
  resource этого адреса.
- `login …: denied` — неверный `--pass`; `node syncing` — нода ещё не в синхроне (или недоступен `SL_PUBLIC`).

---

## 中文

### 1. 挖什么
SASEUL (SL) 有两条链：*主链*（交易、验证者）和 *资源链*——一条 PoW 链，用于选出验证者并向矿工支付奖励。
资源区块有效的条件：

    sha256(previous_blockhash + sha256(header_json) + nonce)  <=  2^256 / difficulty

每个区块奖励 2000 “资源”，通过 `Refine` 合约兑换为 SL（2026 年 10 月倍率 0.4276，每个约 10 亿 SL 的周期乘以 27/32）。
在矿池挖矿时直接获得 SL。

### 2. 钱包
SASEUL 地址为 44 个十六进制字符（`5a00b883bd62…94ea`）。可使用官方 **Guardee** 钱包（Android / iOS）或 SASEUL 节点
（`saseul-script wallet create`）创建。Guardee 使用**助记词**创建钱包，请抄写并离线保存；节点使用 32 字节原始私钥，请妥善备份。挖矿只需要地址。

### 3. 运行

    ./ffgs --wallet 地址.矿工名                          # Kavatar SL Pool（默认，= --pool kavatar），见 3b
    ./ffgs --pool nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931 --wallet 地址.矿工名
    ./ffgs --pool saseulmine --wallet 地址.矿工名
    ./ffgs --pool saseulpool --wallet 地址.矿工名

| 参数 | 说明 |
|---|---|
| `--pool 主机:端口[,主机:端口…]` | rabbitminer 协议矿池列表（Kavatar SL Pool、rabbitminer.cc、自建节点），不可用时自动切换到下一个；默认 `sl.kasplay.online:3333` |
| `--pool kavatar` | Kavatar SL Pool（`sl.kasplay.online:3333`），见 3b |
| `--pool saseulmine` | saseulmine.com，等同于 `--pool https://pool.saseulmine.com`（任何 `https://` 地址都使用该协议，多个地址为备用列表；不要与 `主机:端口` 混用） |
| `--pool saseulpool` | saseulpool.com，等同于 `--pool nats://nats.saseulpool.com:4222`（任何 `nats://主机[:端口]` 都使用该协议，多个地址为备用列表；矿池集群的其他服务器由服务器告知并自动使用；见第 6b 节） |
| `--wallet 地址[.矿工名]`、`--worker 名称` | 收款地址和矿工名（saseulpool：默认矿工名为主机名） |
| `--referrer 地址` / `--referrer none` | 1% 推荐分钟的接收者（向您推荐 ffgs 的人）；**填写自己的钱包 = 总费用 1%**；none / 未设置 = 归开发者；同时作为 saseulmine 推荐人发送（见第 6 节） |
| `--devices 0,1,…` | 使用的 GPU，编号与 `nvidia-smi` / HiveOS 一致（默认全部；AMD 见 5b） |
| `--backend auto\|cuda\|amd` | GPU 后端：`auto`（默认）= 有 NVIDIA 显卡时用 CUDA，否则用 AMD OpenCL |
| `--eco` | 节能内核（见第 5 节） |
| `--bench 秒数` | 不连接矿池，测试每张显卡的算力 |
| `--selftest` | 用真实主网区块校验 PoW，用 CPU 穷举校验 GPU 内核，并校验请求签名 |
| `--pool-test` | saseulmine：发送一次签名的任务请求并显示账户统计；saseulpool：连接并等待一个任务；然后退出（无需 GPU） |
| `--lock-cclock MHz[,MHz…]` | 锁定核心频率（同 `nvidia-smi -lgc N,N`），见第 5a 节 |
| `--lock-mclock MHz[,MHz…]` | 锁定显存频率（同 `nvidia-smi -lmc N,N`） |
| `--coffset MHz[,MHz…]`（别名 `--uv-offset`） | 核心频率 V/F 偏移 = 锁定频率下的降压 |
| `--moffset MHz[,MHz…]` | 显存频率偏移，可为负（驱动 555+） |
| `--plimit W[,W…]` | 功耗上限 |
| `--dry-run` | 打印各参数在每张 GPU 上的设置后退出，不做任何修改（见 5a，0.5.4 新增） |
| `--oc-info` | 显示所选 GPU 的频率、偏移和功耗上限后退出（无需 root） |
| `--auto-uv`、`--uv-min/--uv-max/--uv-step MHz[,…]`、`--uv-coarse MHz`、`--uv-reset`、`--uv-reset-all`、`--uv-reval-hours H` | 自动降压，见 5c |
| `--auto-lock`、`--auto-lock-range`、`--auto-lock-max-loss PCT`、`--auto-lock-goal eff\|speed`、`--auto-lock-reset` | 每张卡自动选择核心锁频，见 5e（0.5.4 新增） |
| `--temp-limit C[,C…]`、`--temp-stop`、`--temp-mem`、`--temp-hotspot`、`--temp-no-clocks` | 温度保护，主要用于笔记本，见 5f（0.5.4 新增） |
| `--watchdog-hang S`、`--watchdog-drop PCT`、`--watchdog-minutes M`、`--no-watchdog` | GPU 卡死看门狗，见 5g（0.5.4 新增） |
| `--failback-minutes N`、`--noshare-minutes M`、`--reject-minutes K` | 矿池健康：回到主矿池、无接受份额看门狗，见 3c（0.5.4 新增） |
| `--api [主机:]端口`、`--api-hosts 名称[,…]` | 本地只读 HTTP/JSON API，见 3d（0.5.4 新增） |
| `--install-autostart`（`--task-name`、`--autostart-delay`、`--autostart-bat`、`--autostart-ac-only`、`--task-user`、`--autostart-limited`）、`--remove-autostart` | Windows：登录时自动运行 `start.bat`，见 3e（0.5.4 新增） |
| `--no-update-check`、`--check-update` | 关闭新版本提示 / 检查一次后退出，见 3e（0.5.4 新增） |
| `--log 文件` | 同时把日志追加写入文件（纯文本，除非 `--color always`；Windows 启动脚本写入 `logs\ffgs.log`） |
| `--color auto\|always\|never` | 控制台颜色，见第 3a 节（默认 `auto`） |
| `--no-color` | 等同 `--color never` |
| `--minutes N` | 挖矿 N 分钟后退出（测试用） |
| `--quick-edit` | Windows：保留控制台的快速编辑模式（ffgs 默认关闭它：在窗口中点击会暂停输出） |

**控制台。** 每 10 秒输出一行状态（每张显卡的算力、功耗与能效、整机合计、您的钱包和开发者费用的份额；HiveOS 读取这一行），
每 60 秒输出一张表：10 秒与 5 分钟算力、功耗、MH/W、频率、温度、风扇、当前核心/显存偏移、ffgs 设置的值、份额及百分比，以及矿池
对您钱包的统计（saseulmine `/account`、rabbitminer.cc 钱包 API、saseulpool.com API，每 5 分钟刷新）——示例见英文部分。颜色见第 3a 节。

### 3a. 控制台颜色（0.5.0 新增）
每种颜色只有一种含义，日志行、每 10 秒的状态行和每 60 秒的表格中一致：

| 消息 / 数值 | 颜色 |
|---|---|
| **找到区块**（`*** BLOCK FOUND ***`，表格中 N > 0 时的 `blocks N`） | 品红底粗体亮白（最醒目的样式，不用于其他内容） |
| 接受 / 已送达的份额、已连接、`online`、自检 / 矿池测试 `ok` | 绿色 |
| 算力数值：状态行中的 `GPUn 4.611` 与 `total … GH/s`、表格的 GH/s 列、`--bench` | 粗体亮白 |
| 能效 `MH/W`（状态行与表格） | 粗体亮蓝 |
| GPU 温度（表格） | 低于 70 °C 绿色，70–79 °C 黄色，80 °C 起红色 |
| 合计：`rig` 行、表格标题 | 粗体 |
| 过期 / 丢弃 / low-diff 份额、等待任务、切换服务器、矿池统计未更新 | 黄色 |
| auto-uv / auto-lock 的预期结果（0.5.4）：调优步骤或快速校验失败（`step +360 (3/7): FAILED (...)`）、`edge found`、`tuning again`、调优失败的锁频；被其他工具修改后重新设置的频率（`... by another tool (HiveOS OC profile?) - ffgs's lock 1500 MHz wins, re-applied`，见 5a） | 橙色（256 色 208；Linux 文本控制台及不支持 256 色的终端为黄色） |
| 需要注意的问题：被拒绝的份额、错误、硬件错误、断线、`OFFLINE` / `pool offline`、挖矿时崩溃 / 被排除 / 无法打开的显卡、auto-uv 最终 `RESULT: FAILED` | 红色 |
| 新区块高度、份额难度 / 除数变化 | 青色 |
| 开发者费用时段（其份额行与状态行） | 暗色 |
| 时间戳、表格列名 | 灰色 |

何时使用颜色（`--color`，默认 `auto`）：
- `auto`：终端；以及从终端观看的管道（stdin 是终端，或矿工运行在 GNU screen 中），例如 `./ffgs … | tee ffgs.log`。
  重定向到文件、作为服务运行（systemd：stdin 为 `/dev/null`）以及 `--log` 文件均不带颜色。`NO_COLOR`（非空）关闭 `auto`，
  `FORCE_COLOR`（非空且不为 `0`）使其等同 `always`。
- `always`：所有输出都带转义码，包括 `--log` 文件。`never`（或 `--no-color`）：全部为纯文本。
- **HiveOS**：`h-run.sh` 在 `miner` screen 中运行 `ffgs … | tee ffgs.log`，`auto` 会为其着色：`miner` 与网页 “miner log”
  （显示 `/var/log/miner/ffgs/ffgs.log` 中的 ANSI 颜色）均有颜色。`h-stats.sh` 照常解析带颜色的日志（颜色只包围完整的字段）。
  Extra config 中 `--color never` 得到纯文本日志，`--color always` 在某个 HiveOS 版本不经终端启动矿工时强制着色。
- **Windows**：Windows 10+ 控制台（ffgs 开启 ANSI / VT 模式）；旧控制台为纯文本。重定向输出（`> file`、`| Tee-Object`）
  除非 `--color always` 否则不带颜色；`logs\ffgs.log` 始终为纯文本。
- 浅色背景的终端中亮白色不易阅读，请使用 `--color never`。

### 3b. Kavatar SL 矿池（0.5.0 起默认）

未指定 `--pool` 时，ffgs 在 ffgs 作者的 **Kavatar SL Pool** 挖矿（`--pool kavatar` 相同）：`sl.kasplay.online:3333`，
统计与钱包查询：**https://kavatar.kasplay.online**（EN / RU / 中文）。

- **PPLNS**：区块奖励按出块前 2 倍全网难度工作量内的份额分配（按份额难度加权），长期矿工不受跳池者影响。**矿池手续费 2%。**
- **每 6 小时自动支付，满 10 SL 起付**，直接到您的地址。交易上链后才算已支付；30 分钟内未上链的支付会退回余额。
- 矿池运行自己的 SASEUL 节点；区块的 9 个奖励窗口全部确认后（出块后约 15 分钟），奖励（resource）精炼为 SL 并入账。入账、支付和区块均可在网站查看。
- 每个连接的份额难度自动调整（约每 15 秒一个份额），nonce 40 位十六进制，无需密码；矿工名为 `--wallet 地址.矿工名` 中点号后的部分（或 `--worker`）。
- 控制台的 `pool` 行显示矿池对您钱包的统计：10 分钟算力、余额、已支付、未成熟区块。
- 开发者费用的那一分钟在同一矿池为 ffgs 开发者钱包挖矿（不连接其他矿池）。

### 3c. 矿池健康：回到主矿池、无接受份额看门狗（0.5.4 新增）
`--pool` 填写同一协议的多个地址即为备用列表，**第一个为主矿池**（例如 `--pool sl.kasplay.online:3333,nl.rabbitminer.cc:1931`）。
- **回到主矿池**：在备用矿池上挖矿时，每 `--failback-minutes`（默认 10）分钟用*单独的连接*检查主矿池（不影响挖矿、
  不提交份额）：rabbitminer 连接+登录（同一 wallet.worker）+一次 `getjob`；saseulmine 一次签名的 `GET /mine`；saseulpool
  连接+订阅+25 秒内收到一个区块模板（集群中学到的服务器算作同一矿池）。连续 **2 次**检查成功（第二次在 60 秒后）后切回：
  先把正在计算和已找到的份额发往备用矿池，再连接主矿池，GPU 约停 1–2 秒。`--failback-minutes 0` = 关闭。
- **无接受份额看门狗**：已连接并在计算，但 max(`--noshare-minutes`（15），10 × 预期份额间隔）分钟内无接受份额，
  或 `--reject-minutes`（5）分钟内全部被拒（至少 5 个），或 5 分钟无可用任务 → 先重连同一矿池，再次发生则切换到列表中的
  下一个矿池（最后一个之后回到第一个）。`0` = 关闭该项。
- 不触发的情况：GPU 未为你的矿池计算（auto-uv 调优/校验、无任务、断线、切换中）、开发者费用/推荐分钟及其后 10 秒、
  单人/自建节点模式（不含 Kavatar / rabbitminer.cc 的 `主机:端口` 列表）；GPU 根本没找到份额时只警告（GPU 问题，不是矿池问题）。
  被看门狗离开的主矿池检查间隔逐次加倍（最多 ×16），在其上稳定 2 小时后恢复。saseulpool 上“接受” = 已送达（见 6b）。
- 同一矿池列表上的开发者费用/推荐会话跟随用户会话切换（每分钟最多一次，不在其自身的那一分钟内）；费用分钟本身不变。
  拒绝登录的 rabbitminer 矿池会使下一次尝试从下一个地址开始；在备用矿池上时，60 秒表格标题显示 `…, backup pool 2 of 2`。

### 3d. 本地 API `--api`（0.5.4 新增）
只读的 HTTP/JSON API，供您自己监控使用：

    ffgs --wallet 地址 ... --api 4068               # http://127.0.0.1:4068（仅本机）
    ffgs --wallet 地址 ... --api 0.0.0.0:4068       # 所有网卡：局域网内其他机器可读取
    ffgs --wallet 地址 ... --api [::1]:4068         # IPv6

- 默认只监听 `127.0.0.1`。其他地址必须显式写出；非回环地址会在日志中给出黄色警告（能访问该地址的人都能读取矿机统计，请用防火墙限制）。
  日志：`API: listening on http://127.0.0.1:4068 (read-only: /summary, /gpus, /metrics)`。`--api` 参数错误：立即退出（代码 1）；
  端口被占用不会停止挖矿（`mining without the API`）。
- **安全：** 只接受 `GET` 和 `HEAD`（其他返回 `405`），没有写入或控制接口，无认证；回复中绝不包含矿池密码、saseulmine 客户端密钥、
  solo 代理令牌；单个小线程（最多 16 个连接、请求头 4 KiB、每连接 5 秒）只读取每 10 秒刷新的统计副本，不接触 GPU、NVML 或矿池；不发送 CORS 头。
- **Host 头白名单**（防 DNS rebinding）：允许 `localhost`、`127.0.0.1`、`[::1]`、绑定地址、绑定 `0.0.0.0` / `[::]` 时的任意 IP，
  以及 **`--api-hosts 名称[,名称…]`** 给出的名称；其他 Host 返回 `403`；没有 Host 头的请求照常响应。

| 路径 | 格式 | 内容 |
|---|---|---|
| `GET /`、`GET /summary` | JSON | 矿机概要：版本、运行时间、矿池（协议、当前地址、`index` = 当前备用列表序号、连接状态、`failback`）、钱包/矿工、算力、份额、功耗与 MH/W、抽水状态 |
| `GET /gpus` | JSON | 每张显卡：序号、总线、名称、状态、算力、功耗、温度、风扇、频率、偏移、`auto_uv`、`throttle`、`watchdog`、`auto_lock`、`temp_limit`、份额 |
| `GET /metrics` | Prometheus 文本 | 矿机与每张显卡的指标（算力单位 H/s） |

字段名与格式见英文部分；未知值为 `null`；每 10 秒刷新（`updated_s_ago` 为数据年龄）。`throttle`：NVIDIA 降频原因
（`{"reasons":[...],"hw":bool}`，其他为 `null`）；`watchdog`：看门狗计数（5g）；`auto_lock`：未用 `--auto-lock` 时为 `null`（5e）；
`temp_limit`：温度限制状态（5f）；`pool.failback`：3c 的状态。Prometheus 按主机名抓取（`targets: ["rig1:4068"]`）时，
rig1 需要 `--api 0.0.0.0:4068 --api-hosts rig1`（或改用 IP 目标）。
- HiveOS：在 Extra config arguments 中加入 `--api 4068`，`h-stats.sh` 从 API 读取算力、运行时间、份额与功耗（API 无响应或数据过旧时
  照旧解析日志）。NVIDIA + AMD 混合矿机上，`h-run.sh` 给 AMD 进程 `--api 端口+1`（主机不变），h-stats 读取两者。
- Windows：启动脚本中 `set API=4068`。

### 3e. Windows 开机自启、新版本提示（0.5.4 新增）
- **开机自启：** 配置好 `start.bat` 后，双击 **`install-autostart.bat`**（Windows 会请求一次管理员权限）。它创建任务计划
  任务 `ffgs`：在**您**登录后 30 秒运行本文件夹的 `start.bat`，窗口显示在您的桌面，以最高权限运行（`LOCK_CCLOCK` / `COFFSET` /
  `AUTO_UV` / `AUTO_LOCK` 无需 UAC 确认），使用电池时也会启动且拔掉电源不停止，无运行时间限制，普通优先级。
  `install-autostart.bat` 开头可设置 `TASK`、`DELAY`、`AC_ONLY=1`（笔记本：使用电池时不启动）。**`remove-autostart.bat`** 删除该任务。
  命令行（管理员）：`ffgs --install-autostart [--task-name 名称] [--autostart-delay 秒] [--autostart-bat 路径] [--autostart-ac-only]
  [--task-user 域\用户] [--autostart-limited]`、`ffgs --remove-autostart [--task-name 名称]`。只会替换或删除由 ffgs 创建的任务。
  不要同时把 `start.bat` 放进“启动”文件夹（会启动两个矿工）。Linux：HiveOS 自行启动矿工；普通 Linux 使用 systemd 服务（`Restart=always`）。
- **启动脚本新设置（0.5.4）：** 除 `AUTO_UV` 外，`AUTO_LOCK=1`（`--auto-lock`，5e；对 `AUTO_ELEVATE` 算作频率设置）、
  `TEMP_LIMIT=80`（`--temp-limit`，5f；无需管理员）、`API=4068`（`--api`，3d）。
- **新版本提示：** 挖矿时，启动约 1 分钟后及之后约每 12 小时（随机分散），ffgs 向 GitHub 查询 `pepsykolya/FreeForGemSaseul`
  的最新发布版本，如有更新则在日志中黄色提示 `ffgs X.Y.Z is available: <链接>`。仅发送一个普通 GET 请求（`User-Agent: ffgs/<版本>`），
  不发送钱包或任何标识，不会自动下载或安装；无网络时不影响挖矿。`--no-update-check` 关闭；`ffgs --check-update` 立即检查一次后退出
  （退出码 0 = 已是最新，10 = 有新版本，1 = 检查失败）。

### 4. HiveOS
见 [HIVEOS.md](HIVEOS.md)。

### 5. 调优
- 该 PoW 只做计算、不访问显存：**显存频率可以降到最低**以节省功耗。
- **默认内核**：每个时钟周期算力最高，适合功耗墙受限或核心频率锁定较高的情况。
- **`--eco`**：每时钟算力约低 12%，功耗约低 17%，降压显卡上能效最佳。
- **实测（0.5.3 / 0.5.4，默认内核，Kavatar SL 矿池，40 位十六进制 nonce）。** GH/s = 挖矿 60 秒后 10 秒状态行的中位数（每点 ≥ 4 分钟），
  W = NVML 板卡功耗；auto-uv 偏移 = `--auto-uv` 在该卡、该锁频下找到的值（电压下限或边界减一步）。**粗体**为推荐设置。

  **RTX 3070**（HiveOS，驱动 580.82.07；Rig01 8 张卡，每个锁频 2–4 张，取中位数；Rig02 4 张卡在 1500：同样每卡 5.62 GH/s、76 W）：

  | 核心锁频 | 显存 | auto-uv 偏移 | GH/s | W | MH/W | 偏移 0 时 W | |
  |---|---|---|---|---|---|---|---|
  | 1200 | 810 | +240 … +255 | 4.51 | 65 | 69 | 71 | |
  | 1300 | 810 | +240 … +255 | 4.90 | 73 | 67 | 84 | |
  | 1400 | 810 | +255 … +330 | 5.29 | 75 | 70.5 | 88 | |
  | **1500** | **810** | +330 … +435 | **5.62** | **76** | **73.9** | 98 | **能效最佳** |
  | 1600 | 810 | +330 … +390 | 6.01 | 89 | 67.5 | 119 | |
  | **1700** | **810** | +315 … +345 | **6.40** | **106** | **60.4** | 151 | **平衡**（最高 GH/s 的 −10 % 以内能效最佳） |
  | **1800** | **810** | +330 … +345 | **6.74** | **121** | **55.7** | 186 | **最高算力** |
  | 1400 | 默认 | +300 | 5.29 | 104 | 50.9 | — | 显存 810 省 27 W |

  `--lock-cclock 1500 --lock-mclock 810 --auto-uv`（能效最佳），`1700`（平衡），`1800`（最高）。同一锁频下各卡功耗差异可达 25 %
  （1400：67–79 W）；算力相同（约每 1000 MHz 3.74 GH/s）。

  **RTX 3080 Ti**（Windows 10，驱动 591.59，功耗墙 350 W，一张卡；`auto-lock` 行为 ffgs 自己的 120 秒测量）：

  | 核心锁频 | 显存 | 偏移 | GH/s | W | MH/W | |
  |---|---|---|---|---|---|---|
  | 1200 | 810 | 0 | 7.73 | 137 | 56.5 | |
  | 1400 | 810 | +120（auto-uv，下限） | 9.07 | 160 | 56.9 | 偏移 0：164 W |
  | 1500 | 810 | 0 | 9.65 | 184 | 52.3 | |
  | 1560 | 810 | +210（auto-uv） | 10.03 | 177 | 56.6 | 偏移 0：206 W |
  | **1600** | **810** | +240（auto-uv） | **10.32** | **180** | **57.4** | **能效最佳** |
  | 1650 | 810 | 0 | 10.60 | 240 | 44.2 | |
  | **1700** | **810** | +240（auto-uv） | **10.98** | **212** | **51.9** | **平衡**（`--auto-lock` 也选了它） |
  | 1750 | 810 | 0 | 11.27 | 299 | 37.7 | |
  | 1800 | 810 | +150（auto-uv，边界 +180） | 11.49 | 268 | 42.9 | |
  | **不锁定** | **810** | 0 | **11.54** | **332** | **34.8** | **最高算力**（约 1800 MHz） |
  | 1400 | 默认 | 0 | 9.13 | 221 | 41.3 | 显存 810 省 57 W |
  | 不锁定 | 默认 | 0 | 11.13 | 349 | 31.9 | 受功耗墙限制：比显存 810 更慢 |

  `--lock-cclock 1600 --lock-mclock 810 --auto-uv`（能效最佳），`1700`（平衡），只用 `--lock-mclock 810` 不锁核心（最高）。
  1400 及以下核心电压已在下限（auto-uv：+120，−4 W）；约 1500 起降压才有明显收益。

  **RTX 4070 Laptop**（Windows 11，接电源，无管理员：不能控制频率）：不限温 4.80 GH/s、63 W、**77 MH/W**，驱动自己把温度维持在
  86–87 °C（自身温控降频，约 1700 MHz）。`--temp-limit` 以算力为代价降温（5f）：限 75 → 1.78 GH/s、38 W、47 MH/W；限 70 →
  1.5 GH/s、32 W、46 MH/W；在这台笔记本上限 80 没有用处（它本来就在 86–87 °C，突发更热）。以上为 0.5.4 控制器重新调整（软启动、
  连续 3 次读数才停止）之前的测量；重新调整在该笔记本的模型上测试过，尚未在笔记本本身上测试。
- **显存频率：** 锁定 810（`--lock-mclock 810`；CMP 50HX：5001，见 5a）。SL 不需要显存带宽，默认显存频率只会增加功耗。

### 5a. GPU 频率控制（0.4.0 新增）
ffgs 可以设置挖矿显卡的频率：

| 参数 | 作用 |
|---|---|
| `--lock-cclock N` | 将核心频率锁定为 N MHz（`nvidia-smi -lgc N,N`） |
| `--lock-mclock N` | 将显存频率锁定为 N MHz（`nvidia-smi -lmc N,N`）；SL 不需要显存带宽，设为最低（RTX 30/40 为 810）。显卡不支持的频率会改用高于它的最低支持频率（0.5.3；CMP 50HX 没有 810：`memory clock 810 not supported, using 5001 (lowest supported)`） |
| `--coffset N` / `--uv-offset N` | 核心 V/F 偏移（MHz）：锁定核心频率时，正偏移 = 同频率更低电压（降压） |
| `--moffset N` | 显存频率偏移（MHz），可为负（驱动 555+） |
| `--plimit W` | 功耗上限（瓦） |

- 一个值适用于所有挖矿显卡；逗号分隔的列表按 `--devices` 顺序为每张卡指定（无 `--devices` 时按 nvidia-smi / HiveOS 顺序）。
  空值、`-`、`0` 或 `x`（以及 `X`、`skip`）表示该卡的该项不变：`--devices 0,1,2 --lock-cclock 1400,,1560`。
- **列表比 GPU 少时，最后一个值用于其余 GPU**（与 HiveOS 超频规则相同，0.5.4，日志会提示）；比 GPU 多、不是数字或超出范围
  则启动时报错（代码 1，不做任何修改）。列表中**不要加空格**。
- **`=0` 将偏移设为恰好 0**（仅 `--coffset`、`--moffset`；0.5.4）：`--coffset 325,=0`。单独的 `0` 仍表示“不修改”
  （HiveOS 超频配置中 `0` 表示“设为 0”，此处请写 `=0`）。
- 同样的列表规则也适用于 `--uv-min` / `--uv-max` / `--uv-step`（5c）和 `--temp-limit`（5f）。
- **启动时每张 GPU 输出一行**（0.5.4），列出本次运行对其设置的内容（锁频、偏移、功耗上限、auto-uv 范围，使用 `--auto-lock`
  时还有该卡是否参与锁频扫描）。**`--dry-run`** 只打印这些行后退出，不做任何修改（无需 root；指定 `--devices` 时无需 GPU）。
- 需要 **root**（Linux）/ **管理员**（Windows）权限；否则 ffgs 输出一行提示并以当前频率继续挖矿。
- 在启动自检之前应用（内核在新频率下校验）；每个值都会记录并回读，挖矿约 30 秒后输出显卡实际运行的频率。
- **退出时恢复**：Ctrl-C、SIGTERM/SIGHUP、关闭控制台窗口、`--minutes`、致命错误。频率锁定恢复为驱动默认值，偏移和功耗上限恢复为修改前读取的值。
  若 ffgs 被强制结束（kill -9、崩溃），程序旁的标记文件 `ffgs-oc-<bus>.restore` 会让下一次启动的 ffgs 自动恢复（即使不带频率参数）。
  其他正在运行的 ffgs 的标记会被尊重，重启之前的标记会被丢弃。
- 只修改 `--devices` 中的显卡，通过 PCI 总线号与 NVML 对应。NVML 在运行时加载，缺少它 ffgs 仍可挖矿。
- `--oc-info` 只显示当前频率、偏移（及允许范围）和功耗上限，不做任何修改。
- **ffgs 的频率参数优先于其他超频工具（0.5.4）。** ffgs 在某张卡上设置的值（`--lock-cclock`、`--lock-mclock`、`--coffset`、
  `--moffset`、`--plimit`、`--auto-uv` 的偏移、`--auto-lock` 的锁频）**即使 HiveOS 超频配置中是其他值也会保持**（HiveOS 在重启或修改超频后
  应用其超频，可能晚于 ffgs 启动；MSI Afterburner / `nvidia-smi` 同理）。ffgs 每 10 秒在状态行的节拍中，把本来就为状态行读取的频率、偏移和功耗上限
  与自己的值比较；不一致时重新设置自己的值（先锁频，后偏移；若频率或偏移高于 ffgs 的值，先短暂暂停该卡的计算）。每次事件一行橙色日志，
  每张卡最多每 10 分钟一行（附中间次数）：`GPU0: core clock changed to 1680 MHz by another tool (HiveOS OC profile?) - ffgs's lock
  1500 MHz wins, re-applied with the GPU paused`；频率表显示 `re-applied Nx`。跨越此类变化的 auto-uv 检查或 auto-lock 测量会被丢弃并重做。
  在其他工具修改频率期间显卡崩溃（Xid）（该卡此类事件后 30 秒内、矿机任一卡 15 秒内，或崩溃时偏移 / 频率与 ffgs 的值不同）不计入降压失败：
  橙色日志 `... crashed (Xid 43) while another tool changed its clocks (HiveOS OC?): ... - not counted against the undervolt`，
  ffgs 照常重启。仅发现偏移被改时，ffgs 也会先重新设置自己的锁频（其他工具的锁频可能已生效）。
  锁频无法读回，因此按频率判断：高于 ffgs 的锁频，或在挖矿时无功耗 / 温度原因且非 `--temp-limit` 降频却明显低于锁频（连续 2 次读数）。
  ffgs 不设置的卡和值（`x`、未给参数）交给 HiveOS / 其他工具。表格和 HiveOS h-stats 显示显卡的实际频率。开销：每卡每节拍几微秒
  （无额外线程；使用 `--plimit` 时多一次功耗上限读取）。
- **退出时** ffgs 恢复**它自己**启动时看到的值（偏移、功耗上限），并重置它设置的锁频。若 HiveOS 在 ffgs 启动后才应用超频，恢复的是
  HiveOS 超频之前的状态，而不是超频配置；下次矿工启动时 HiveOS 会再次应用其超频。
- Windows：在 `start.bat` / `start-saseulmine.bat` / `start-saseulpool.bat` 中设置 `LOCK_CCLOCK`、`LOCK_MCLOCK`、`COFFSET`、`MOFFSET`、`PLIMIT`；设置任一项时，
  脚本会请求以管理员身份重新打开（默认 `AUTO_ELEVATE=1`）。

**各显卡实测设置**（RTX 3070、RTX 3080 Ti、RTX 4070 Laptop）：见上方第 5 节的表格。RTX 3070 能效最佳：
`--lock-cclock 1500 --lock-mclock 810 --auto-uv`。

### 5c. 自动降压 `--auto-uv`（0.5.1 新增，0.5.3 起按锁频分别保存）
ffgs 可以自动寻找降压值：提高每张 NVIDIA 显卡的核心 V/F 偏移，逐步校验，
最终保留最后一个通过的偏移再减去 15 MHz 作为余量。

    sudo ./ffgs --wallet <地址>.<矿机名> --lock-cclock 1500 --lock-mclock 810 --auto-uv

- **需要锁定核心频率**（`--lock-cclock`、HiveOS 超频配置中的锁定或 `--auto-lock`，见 5e）：这时偏移越高 = 同频率下电压越低。仅 NVIDIA，需要 root / 管理员权限。
- **粗到细（0.5.4）：** 偏移以 **30 MHz** 步长上升（`--uv-coarse`）；某一步失败时，回到最后一个通过的偏移，只在该 30 MHz 区间内
  测试 **+15 MHz** 一点（多一步），再留 15 MHz 余量。结果与 15 MHz 逐步搜索相同，步数约减半。（不采用自上而下：最先测试的正是最容易让显卡崩溃的偏移。）
- **新锁频从已知配置开始（0.5.4）：** 若该卡有更高（或相同）核心锁频、相同显存锁频的已验证配置，起点 = **该配置偏移 - 30**（而非 +120，
  取最近的锁频）。预热照常校验起点。使用 `--uv-min`、崩溃后、不能提高起点时，或该配置结束于**电压下限**或其自身起点时不启用
  （更低的频率更早到达下限，沿用该偏移只会减少余量；日志：`... ended on the voltage floor: not starting from it`）。
- **调优：** 在起始偏移上预热校验 2 分钟，之后每步约 30 秒，再确认 2 分钟：通常 **约 3.5–11.5 分钟**（固定部分即预热 + 确认约 4.3 分钟；
  已知更高锁频配置的第二个锁频约 6.5 分钟；0.5.3 最多约 16.5 分钟）。**只有正在调优的显卡等待，
  其他显卡同时挖矿**，每张卡在自己的调优结束后立即开始挖矿（0.5.3；之前所有卡都要等全部完成）。日志显示进度（`step +340 (2/12): ok`），
  状态行在该卡算力后显示标记（`GPU1 0.000 [tuning +340, step 2/12]`），约每分钟一行汇总（`auto-uv: tuning 2 GPU(s) (GPU1, GPU3), ~6 min left`）。
  调优以 `RESULT:` 行结束。颜色（`--color`）：进度青色，通过的校验和结果绿色，回退黄色，失败红色。
- **电压下限：** 若连续两步每步节省过少（每 15 MHz 0.5 W，即 30 MHz 步 < 1 W），搜索在它们之下停止，而不是一直升到 `--uv-max`（电压已到最低，更高的偏移只会吃掉余量）。
  若搜索到达 `--uv-max` 仍未失败，日志会说明并给出节省的功耗。
- **起始偏移校验失败**时不会保留：ffgs 以 30 MHz 为步长向下，直到第一个通过的偏移并在其上挖矿（也可能低于您自己的偏移）。
- **按锁频分别保存（0.5.3）：** 结果按显卡、型号、驱动 **和核心锁频** 保存（`1400/mem810` = `--lock-cclock 1400 --lock-mclock 810`；
  若 ffgs 未锁频，则由挖矿负载下的核心频率选择配置，`~1410`）。切换锁频再切回时，各自的配置会被重用。在 `--uv-reval-hours` 内校验过的配置
  **立即应用**（该卡立即挖矿）；更早的、来自其他 ffgs 版本的或崩溃后降低的配置先校验 20 秒（只有该卡等待）。没有本版本 ffgs 校验基准的配置（来自 0.5.1 / 0.5.2、
  其他 ffgs 版本或不同的 `--blocks` / `--threads`）先在其下限偏移上用 60 秒建立新基准，再校验 20 秒：约 85 秒；状态标签先显示
  `[reference +240]`，再显示 `[check +300]`，日志中也有说明。0.5.1 / 0.5.2 的结果成为其调优时
  频率的配置，经校验后用于相近的锁频。
- **校验**在独立进程中以满负载运行挖矿内核、使用固定测试任务：每次启动的候选数必须与基准完全一致（显卡哪怕算错一个哈希也会在几秒内暴露），
  每个保存的候选都在 CPU 上重新计算。显卡崩溃或卡死只会结束该进程。
- **挖矿过程中：** 出现硬件错误（bad candidate）时回退 15 MHz（保存，下次启动时校验）；每 6 小时复查 20 秒（期间该卡暂停）。若偏移被其他程序修改
  （HiveOS 超频），ffgs 会重新设置自己的值（见 5a；0.5.4 起，之前 auto-uv 会放弃该卡）。GPU 故障（Xid）：见 5d。
- 结果保存在程序旁的 `ffgs-uv-results.txt`（HiveOS：`/hive-config/ffgs`，矿工更新后仍保留）。若 ffgs 在某一步崩溃（kill、Xid、断电），
  下次启动会恢复偏移并在该步以下重新调优；校验期间停止 ffgs（Ctrl-C、HiveOS 停止矿工）不算失败。退出时与 `--coffset` 一样恢复原偏移。
- 参数：`--uv-min MHz`（起点；默认当前偏移，否则 +120，RTX 40/50 至少 +200；或上述更高锁频的提示），`--uv-max MHz`（默认 +495），
  `--uv-step MHz`（15：**细步长**，即结果精度、余量与回退），`--uv-coarse MHz`（0.5.4 新增，上升步长，默认 2 × `--uv-step`；
  `--uv-coarse 15` 或不大于细步长 = 0.5.3 的单一步长），`--uv-reset`（清除当前锁频的配置并重新调优；其他锁频的配置保留），
  `--uv-reset-all`（清除**本次运行的显卡**的所有配置，所有锁频；自 0.5.4 起文件中其他显卡的行保留——混合矿机或两个 ffgs 进程共用
  `/hive-config/ffgs` 时不会互相清除），`--uv-reval-hours H`（6，0 = 不复查）。在得出结果前停止的调优不会在文件中留下行。`--uv-min`、`--uv-max`、`--uv-step` 支持**按 GPU 的列表**
  （0.5.4，规则见 5a）：`auto` = 默认值，空项 / `-` / `x` = **该卡不做自动降压**（例如 `--uv-max 400,x`）。
  Windows：启动脚本中 `AUTO_UV=1`。`--uv-reset` / `--uv-reset-all` 只作用一次：GPU 故障后的自动重启（5d）不会重复执行。
- 除了更高锁频的提示外，起点不按锁频选择：同型号显卡的边界差异太大（RTX 3070 在 1700：+345 … +375）。起点仍是您当前的偏移
  （例如 `--coffset 325`）；起点失败只多花几次校验。各锁频实测结果见第 5 节的表格。

### 5d. GPU 故障（0.5.3 新增）
以前 GPU 故障（驱动 Xid 13 / 43，"an illegal memory access"）会使 ffgs 退出，HiveOS 又把它重启到同样的故障中。现在：
- 通过驱动的 Xid 事件找出出错的显卡并记录：`faults: GPU4 (bus 0000:04:00.0, RTX 3070) FAILED: Xid 43 reported by the driver for this GPU`；
  它与当时的偏移一起记入 `ffgs-gpu-faults.txt`（程序旁；HiveOS：`/hive-config/ffgs`）；
- 其他显卡尽可能继续挖矿；若没有工作线程剩下（或 GPU 卡死，见 5g），ffgs 恢复频率并**自行重启**，每小时最多 12 次：
  Linux 为同一进程和日志（exec），超过上限后退出，由 HiveOS 照常重启；Windows（0.5.4）为以代码 2 退出、由 `start.bat` 在 10 秒后重新启动
  （约 20 秒后所有显卡恢复挖矿），重启时间记录在状态目录的 `ffgs-restarts.txt`（与 `ffgs-uv-results.txt` 同目录），距上次 120 秒内的启动
  视为该次重启，因此每小时 12 次的上限有效：超过后 ffgs 等到本小时最早的一次重启过期再退出。`--uv-reset`、`--uv-reset-all`、
  `--auto-lock-reset` 在这类重启中不会重复执行；
- **使用 `--auto-uv` 时：** 在降压偏移上崩溃的显卡校验 20 秒后以**低 30 MHz** 的偏移恢复（不从头调优；配置更新）。在自身（保留的）偏移上连续
  2 次启动都崩溃的显卡，每 2 次崩溃降低 60 MHz，直到 0，然后被排除；
- **不使用 `--auto-uv` 时：** ffgs 不修改偏移；连续 2 次启动都崩溃的显卡**被排除挖矿一小时**（`... is LEFT OUT of mining ...`），其他显卡继续；
  若所有显卡都被排除，ffgs 等待而不是退出（不会循环重启）；
- **无法打开的显卡（0.5.4）**：`CUDA-capable device(s) is/are busy or unavailable`，常伴随每次尝试都出现 Xid 38（例如上一个矿工
  停止时出错之后）——这**不是**降压或偏移故障：不记录，偏移和 auto-uv 配置保持不变。ffgs 只记录一次日志（`GPU1 ... cannot be
  opened (...): likely needs a GPU reset or a reboot; left out, the other GPUs mine ...`），状态行显示 `[unavailable]`
  （API：`"state":"unavailable"`），1、5、15 分钟后重试，之后每 15 分钟一次；能打开后立即挖矿。该卡的调优或校验同样等待，并在同一偏移继续。
  通常只有重启才能恢复。
- 无故障挖矿 30 分钟后计数清零。删除 `ffgs-gpu-faults.txt` 会立即清除所有记录。

### 5e. 自动选择核心锁频 `--auto-lock`（0.5.4 新增）
ffgs 为每张 NVIDIA 显卡自行选择核心锁频：在多个锁频下挖矿（每个锁频使用自己的降压配置，见 5c），测量算力与功耗，
保留算力损失不超过最高值 10 % 的最节能锁频。

    sudo ./ffgs --wallet <地址>.<矿机名> --lock-mclock 810 --auto-lock

- 仅 NVIDIA，需 root / 管理员。`--auto-lock` 自动开启 `--auto-uv`；`--lock-mclock`、`--moffset`、`--plimit` 照常有效（显存锁频是保存键的一部分）。
- **与 `--lock-cclock` 同时使用：** 有自己 `--lock-cclock` 值的显卡（一个值 = 所有卡；按 GPU 列表 = 这些卡）保持该锁频、**不参与扫描**，
  其余显卡参与。例如 `--lock-cclock 1400,x --auto-lock` 只扫描 GPU1。所有卡都有值时不扫描（警告）。`--uv-*` 列表中为 `x`（不做自动降压）
  的显卡也不扫描。启动时的每卡设置行（5a）在 `auto-lock` 列中显示。
- 每张卡从高到低依次尝试锁频（默认 1800…1200 MHz，步长 100，不超过显卡最高频率；`--auto-lock-range 1200-1700:100` 或列表 `1300,1450,1600`）。
  每个锁频先由 auto-uv 应用/调校该频率的降压配置（新锁频从更高锁频配置 - 30 开始，约 5–12 分钟；只有该卡暂停），然后该卡**正常挖矿**
  45 秒稳定 + 120 秒测量（份额照常提交），记录 GH/s、功耗、核心频率。其他显卡始终在挖矿，所有卡并行扫描。
- 选择：`--auto-lock-goal eff`（默认）= 在最高 GH/s 的 `--auto-lock-max-loss`（10 %）范围内 MH/W 最好的锁频；`speed` = 最高 GH/s。
  低于阈值后不再测更低的锁频。
- 频率未能保持（功耗/温度限制）、硬件错误、挖矿不稳定的点无效；驱动拒绝、auto-uv 失败、GPU 故障的锁频记为 `FAILED`；
  在某锁频期间 ffgs 崩溃，则下次启动将其标记为 `crashed` 不再尝试。不支持锁频的显卡（部分笔记本）：回退为当前频率下的 auto-uv。
- 日志中以表格给出结果，扫描期间状态行显示 `[auto-lock 1700, 2/7: measuring]`。结果按显卡、型号、驱动、显存锁频保存在 `ffgs-autolock.txt`
  （HiveOS：`/hive-config/ffgs`），下次启动直接应用；修改 goal / max-loss 时从已保存的点重新选择；`--auto-lock-reset` 重新测量（自动重启不会重复）。
- 与 `--temp-limit`（5f）同时使用时，auto-lock 管理的锁频不会被降低（只用空闲间隔/停止）；锁频变化期间卡死看门狗（5g）暂停判定，并在新锁频下重新建立基线。
- HiveOS：在 Extra config arguments 中加入 `--auto-lock`，OC 配置中核心锁频留空。Windows：启动脚本中 `set AUTO_LOCK=1`（对 `AUTO_ELEVATE` 算作频率设置）。

### 5f. 温度保护 `--temp-limit`（0.5.4 新增；主要用于笔记本）
**主要用于笔记本和移动 GPU。** 笔记本 GPU 与 CPU 共用散热、风扇不可调，长时间挖矿会一直停在 GPU 自身的降频点（约 87 °C）。
`--temp-limit` 通过减少工作量让它更凉。台式矿机通常靠风扇（HiveOS autofan）控温，不需要此功能。
- `--temp-limit C[,C...]`：保持 GPU 不高于 C（40..100；一个值或按 GPU 列表，`0` / 空 = 该卡关闭）。软启动：以 30% 工作比例开始并逐步提高
  （笔记本核心温度传感器约 1 秒就跟随功率变化，直接 100% 启动曾超出限制 15–25 °C）。在 C-3（滤波后读数）进入限制状态，控制器调整工作比例
  （10–100 %，每秒最多 +5% / −20%，读数经过数秒滤波），让温度稳定在 C-2..C-1。工作比例以启动之间的空闲间隔实现，无需管理员权限，笔记本和 AMD 都可用。示例：`ffgs.exe --wallet ... --temp-limit 80`，
  或启动脚本中 `set TEMP_LIMIT=80`。
- 若 ffgs 自己锁定了核心频率（`--lock-cclock`，root / 管理员，NVIDIA）且该 GPU 上没有 ffgs / auto-uv 的偏移，则先降低该锁定频率
  （最低为锁定值的 60%、不低于 800 MHz），更低时才加空闲间隔。使用 `--auto-uv` / `--coffset` 或 `--auto-lock`（5e）时不降低锁频。
- 回差：全速且温度 ≤ C-5 持续 30 秒后恢复全速（日志一行）。`--temp-stop C2`（默认 min(C+10, 90)，至少 C+3）：任一传感器连续 3 次读数达到停止温度
  （或一次高出 5 °C）即停止挖矿，所有传感器降到各自限制以下 6 °C（或停止 60 秒后降到以下 3 °C）后以 30% 恢复并逐步提高。单次 1 秒尖峰不会触发停止。
- 代价（如实说明）：没有管理员权限时只能用空闲间隔，而 GPU 在运行的瞬间仍处于满加速频率（驱动自身的温控降频在间隔中被解除），因此限温以算力**和**能效为代价换取更低的温度和噪音。
  RTX 4070 Laptop 实测（Windows、接电源、无管理员）：不限温 4.80 GH/s、63 W、**77 MH/W**（驱动自己维持 86–87 °C）；`--temp-limit 75` / `70`：1.5–1.8 GH/s、32–38 W、**约 47 MH/W**（为本节所述 0.5.4 控制器重新调整之前的测量；重新调整在该笔记本的模型上测试过）。
  它用于让笔记本更凉更安静，而不是提高每瓦产出。有管理员 / root 权限并使用 `--lock-cclock` 时，ffgs 会先降低锁定频率，能效明显好于空闲间隔。
- `--temp-mem` / `--temp-hotspot`：驱动提供时的显存 / 热点限制（默认 C+15）；`--temp-no-clocks`：只用空闲间隔。
- 传感器：NVIDIA 用 NVML 核心温度（显存温度仅部分卡提供，NVML 无热点）；AMD Linux 用 amdgpu hwmon（edge / junction / mem）；AMD Windows 本版本无传感器（该卡不启用）。
- 状态行显示 `[temp-limit 72%]` / `[temp-limit 1290 MHz]` / `[temp-stop 91 C]`，日志只记录状态变化；显示和上报的是真实算力；GPU 不挖矿时（temp-stop、矿池离线）显示 0 和 0.0 MH/W（表格中为 `-`）。
- 测试钩子 `FFGS_TEST_TEMP`（仅供开发）替换的是温度*读数*：此时真实 GPU 完全不受保护（与不限温一样发热），只能在冷卡上短时间使用。
- 与 auto-uv 配合：检查前等待降温，检查中达到停止温度会在降温后重试。卡死看门狗（5g）不会判定被 `--temp-limit` 限速或停止的显卡。

### 5g. GPU 卡死看门狗（0.5.4 新增）
5d 只在 GPU 工作线程因 CUDA 错误**停止**且驱动报告 Xid 时处理。GPU 也可能“安静地”失效：内核启动不返回（**挂起**：无错误、无 Xid），
或只以很低的速度工作（**掉速**）。
- **挂起**：工作线程 `--watchdog-hang` 秒（默认 60；打开 GPU 时 180）没有进展 → 作为无 Xid 故障记录（含核心偏移），即使其他显卡仍在挖矿，
  ffgs 也会自行重启（见 5d：Linux exec，Windows 退出码 2 + `start.bat`；每小时最多 12 次）；下次启动按记录处理：`--auto-uv` 下偏移降低 30 MHz，
  否则连续 2 次则排除 1 小时。超过上限时其他 GPU 继续挖矿，挂起的显卡等待下次启动。
- **掉速**：10 秒算力低于自身基线（最近 10 分钟正常样本的中位数）的 `--watchdog-drop`%（默认 30）持续 `--watchdog-minutes` 分钟（默认 3）
  → 重启该 GPU 的工作线程并重置 CUDA 上下文（auto-uv 已调偏移先降低 30 MHz），其他显卡继续；一小时内第 3 次按挂起处理。
- **不判定**：调优/检查暂停、无任务、矿池离线、开发费/推荐分钟、工作线程重启；auto-uv 修改偏移或 auto-lock 修改锁频期间（锁频变化后重新建立基线）；
  被 `--temp-limit` 限速或停止的显卡。NVML 报告硬件/驱动降频（HW slowdown、thermal、power brake）期间的掉速**只记录日志**（每 10 分钟一次），不重启。
  超过半数 GPU（至少 2 张）同时掉速视为整机问题，只记录日志。
- 选项：`--watchdog-hang`、`--watchdog-drop`、`--watchdog-minutes`、`--no-watchdog`。日志行以 `watchdog:` 开头；状态行显示 ` [wd 1h 2s]`；
  API（3d）的 `watchdog` 字段给出计数。

### 5b. AMD 显卡（0.4.0 新增）
同一个 `ffgs` / `ffgs.exe` 也可通过 OpenCL 在 AMD Radeon 显卡上挖矿（针对 RDNA2 优化）：
- `--backend auto`（默认）有 NVIDIA 显卡时用 CUDA，否则用 AMD；`--backend amd` 强制使用 AMD。启动时日志列出 AMD 设备
  （`AMD0: …`），`--devices` 使用该编号（独立 AMD 显卡按 PCI 总线顺序，跳过集成显卡）。
- Windows：只需 Adrenalin 驱动（其 `OpenCL.dll`）。Linux / HiveOS：需要 OpenCL 运行库（`libOpenCL.so.1`，ROCm 或
  amdgpu-pro）——**尚未在 Linux AMD 矿机上测试**。
- 实测 RX 6800 XT（Windows）：默认设置 9.0 GH/s（rabbitminer）/ 9.86 GH/s（saseulmine），约 239 W（ASIC）；
  Adrenalin 中 2300 MHz / 881 mV：9.7 GH/s，约 164 W。
- 5a 中的频率参数以及功耗 / 频率 / 温度 / 风扇列**仅适用于 NVIDIA**；AMD 后端会忽略频率参数（给出一条警告）——
  请在 Adrenalin / HiveOS 超频中设置 AMD 的频率和电压。
- `--bench` 会在 CPU 上复核每个候选结果并打印硬件错误数，可用于验证降压是否稳定。
- 开发说明与测试数据：源代码仓库中的 `docs/amd.md`。

### 6. 开发者费用与推荐：2% = 1% 开发者 + 1% 推荐人
费用为 **2%：每 100 分钟中有两个独立的 60 秒窗口**（首次在挖矿 15 分钟后）：

- **1% 给推荐人**——在您自己的矿池为 **`--referrer 地址`**（向您推荐 ffgs 的人）挖矿。未指定 `--referrer`（或 `--referrer none`）
  时，推荐分钟归开发者。单人 / 自建节点：推荐分钟在 Kavatar SL Pool 挖矿（您的节点不会付给该地址）。
- **1% 给 ffgs 开发者**——在您自己的矿池为开发者钱包（`a750e196…a624`）挖矿（单人 / 自建节点：saseulmine.com，然后 rabbitminer.cc）。
- **推荐人填写自己的钱包 = 总费用 1%**：完全不切换到推荐人，剩下的开发者分钟在 **Kavatar SL Pool**（`sl.kasplay.online:3333`，
  ffgs 作者的矿池）挖矿；若无法连接 Kavatar，则在您自己的矿池。如果您本来就在 Kavatar 挖矿，则完全不切换矿池。
- 两条费用连接提前建立并始终保持，GPU 只切换到已就绪的费用任务，费用矿池连接期间继续为您计算；每个窗口严格为
  **60 秒实际时间**：若费用矿池未就绪，则跳过该窗口。启动日志显示推荐人；状态行分别统计开发者（`fee …`）和推荐（`ref …`）份额。
- Windows：启动 `.bat` 中的 `REFERRER=`；HiveOS：在 *Extra config arguments* 中填写 `--referrer 地址`。

**saseulmine 推荐人。** saseulmine.com 本身也有推荐机制：区块按 80% 矿工 / 10% 推荐人 / 10% 矿池分配，并说明
*"No referrer? Your share is unchanged."*——推荐人的 10% 来自矿池部分。ffgs 也会把您的 `--referrer` 发送给它（默认：开发者钱包；
`--referrer none` 则不发送）。

### 6a. saseulmine.com 说明
- 使用 HTTPS（`pool.saseulmine.com:443`），每个请求都用 Ed25519 *客户端密钥* 签名。ffgs 首次运行时生成该密钥并保存在程序旁的
  `ffgs-client.key`（若目录只读，则每次启动生成新密钥）。该密钥只是矿机在矿池中的身份，不持有任何币；请勿在矿机之间复制。
- 该矿池没有矿工名（账户页面只显示一个 `default`），`.矿工名` / `--worker` 对其无效。
- **多台矿机使用同一地址可以工作**，但份额难度（vardiff）按*地址*计算：一台矿机使难度升高后，另一台稍早按旧难度找到的份额会被拒绝
  （`HTTP 400 Hash does not meet pool difficulty`）。ffgs 将其显示为 `low-diff`（黄色，与拒绝分开计数），立即获取新难度，并在发送前
  重新检查队列中的份额。同一地址两台以上矿机时每小时出现几个 low-diff 属正常。
- 矿池按地址动态调整份额难度（vardiff），几乎每个份额后都会变化：每台矿机每分钟几个份额属正常。新区块到来前或难度提高前找到的份额
  会被矿池拒绝，因此 ffgs 不再发送它们（日志中的 `share dropped: …`）。
- 时钟：矿池每次应答都附带服务器时间，ffgs 用它进行签名和设置区块时间戳，本机时钟不准也没有影响。
- Linux：CA 证书从 `/etc/ssl/certs/ca-certificates.crt`（或其他常见位置）读取，可用 `SSL_CERT_FILE` 指定。Windows 使用系统证书库和代理设置。
- 账户与支付：在矿池网站（saseulmine.com）输入地址查看；`--pool-test` 会在控制台打印相同的账户数据。

### 6b. saseulpool.com 说明
- 连接示例：

      ./ffgs --pool saseulpool --wallet 地址.矿工名                              # Linux
      ./ffgs --pool nats://nats.saseulpool.com:4222 --wallet 地址 --worker rig1  # 同上，完整地址

  Windows：在 `start-saseulpool.bat` 中填入地址（`set WALLET=…`，可选 `set WORKER=…`）后双击运行。
  HiveOS 飞行表（Custom miner，见 [HIVEOS.md](HIVEOS.md)）：*Pool URL* `nats://nats.saseulpool.com:4222`，
  *Wallet and worker template* `%WAL%.%WORKER_NAME%`，*Installation URL* 为 ffgs 发布包。
- 协议：NATS（普通 TCP 端口 4222，无需登录，无 TLS）。矿池节点约每 10 秒发布一次区块模板；份额难度固定为
  全网难度 / 4096（约 2.2·10^11，每 4 GH/s 约每分钟 1 个份额）。
- **矿池不会对单个份额作出应答。** 当 NATS 服务器确认已收到份额时，ffgs 将其计为 `delivered`（已送达；状态行的
  `acc` 和表格中显示的是已送达份额）。矿池是否计入，由表格中每 5 分钟更新的 `pool` 行根据矿池 API 显示：您的地址在
  最近 90 分钟内的 PPLNS *工作量*（矿池接受的份额难度之和）换算成的 GH/s、您在矿池中的占比、下次支付金额，以及
  矿池网站上显示的该地址算力。短时间内按工作量估算的数值波动很大（一个份额 ≈ 2.2·10^11 次哈希），请按一小时以上比较。
- 矿池网站上的算力是矿工程序自己上报的（每个矿工每 10 秒一次），不是矿池测得的。
- 矿工名：`.矿工名` / `--worker`，否则为主机名；字母、数字、`-`、`_` 以外的字符会替换为 `-`。同一地址可以有多台矿机（请使用不同的矿工名）。
- 矿池费 5%，PPLNS 窗口 90 分钟，每 6 小时支付一次，最低 10 SL（2026 年 10 月）。账户与支付：在
  [saseulpool.com](https://saseulpool.com) 输入地址查看；矿池群组 t.me/poolSaseul。
- 区块时间戳使用电脑时钟：请保持时间同步（NTP / Windows 时间同步）。

### 7. 常见问题
| 信息 | 含义 / 处理 |
|---|---|
| `hardware error (bad candidate)` | GPU 计算出错误哈希：降低核心超频 |
| `share rejected: … stale` | 份额提交途中区块已更新，偶尔出现属正常 |
| `cannot connect to any pool` | 检查矿池地址与网络，矿工会自动重试 |
| `self-test failed` | 该 GPU/驱动结果错误，矿工拒绝运行；请反馈显卡型号和驱动版本 |
| `share dropped: stale (new block)` / `below the raised share difficulty` | saseulmine：该份额会被矿池拒绝，因此不发送；偶尔出现属正常 |
| `share stale: … Stale share` | saseulmine：份额提交途中区块已更新（HTTP 409），不计入拒绝，偶尔出现属正常 |
| `TLS connect … certificate not trusted` / `no CA certificates found` | Linux：安装 `ca-certificates` 软件包或设置 `SSL_CERT_FILE` |
| `HTTP 401` | 矿池拒绝了请求签名——请确认使用的是未修改的 ffgs；时钟会自动校正 |
| `clocks: GPU clock settings skipped: needs root …` / `needs Administrator …` | 频率参数需要 root / 管理员窗口；以当前频率继续挖矿 |
| `clocks: … held by another running ffgs` | 该卡的频率由另一个 ffgs 控制，本进程不修改 |
| `clocks: … an earlier ffgs run left clock settings changed` | 之前的 ffgs 在设置频率后被强制结束；以 root / 管理员运行一次 ffgs 即可恢复 |
| `share delivered #N` | saseulpool：份额已送达矿池服务器（矿池不对单个份额应答；见第 6b 节） |
| `connection lost (… no job for 60 s)` / `(… no answer to PING for 15 s)` | saseulpool：服务器停止发送任务或不再应答；ffgs 会重连，必要时连接集群中的下一台服务器 |
| `saseulpool: no credited shares of this wallet in the 90 min PPLNS window yet` | 最初几分钟属正常；若份额已送达但 30 分钟以上仍如此，请检查地址和电脑时钟 |

### 8. 单人挖矿（自建节点）
单人挖矿 = 不经过矿池、不付矿池费：矿机直接为您自己的 SASEUL 节点挖矿，找到的区块的全部奖励归您的地址。节点与 ffgs 之间由
**单人代理** `solo/sl_solo_proxy.py` 连接（Python 3，仅标准库；位于 Linux 安装包和源代码仓库）。

**单人挖矿只有找到区块才有收益。** 平均出块时间 = `全网难度 / 您的算力`（秒）：按 2026 年 10 月的全网难度 8.95e14，一张
RTX 3070（4.6 GH/s）平均需要 8.95e14 / 4.6e9 ≈ 195,000 秒 ≈ **54 小时**出一个块，6800 XT（9.8 GH/s）约 25 小时，而实际时间
波动很大（指数分布：约 14% 的情况会超过平均值的两倍仍未出块）。算力足够或有耐心时再选单人；矿池则是小额而稳定地支付。

**要求**
- 一个**已同步的 SASEUL 节点**（2.2.x，例如官方 Docker 镜像），24 小时运行，并开启外部挖矿：
  `saseul-script mining external on` 和 `saseul-script mining start`（容器内：`docker exec <容器> …`）。
- 节点在主机上的 **`run` 目录**：节点把当前区块模板写入 `run/mining_job`，并从 `run/mining_result` 读取找到的区块。
  使用 Docker 时把节点的 run 目录挂载为卷（例如主机 `/var/saseul-run`），以便代理读写。
- 节点机器上安装 Python 3.8+，并开放一个矿机可访问的 TCP 端口（默认 19310，只对您的矿机开放）。

**安装代理（Linux，systemd）**

    sudo mkdir -p /opt/sl-solo /etc/sl-solo /var/lib/sl-solo
    sudo cp solo/sl_solo_proxy.py /opt/sl-solo/
    sudo cp solo/env.example /etc/sl-solo/env && sudo chmod 600 /etc/sl-solo/env     # 修改：SL_RUN、SL_TOKEN 等
    sudo cp solo/addresses.txt.example /etc/sl-solo/addresses.txt                    # 修改：您的地址
    sudo cp solo/sl-solo-proxy.service /etc/systemd/system/
    sudo systemctl daemon-reload && sudo systemctl enable --now sl-solo-proxy
    journalctl -u sl-solo-proxy -f

设置（环境变量，`/etc/sl-solo/env`）：`SL_RUN`（节点 run 目录）、`SL_PORT`（19310）、`SL_TOKEN`（矿机登录密码，请用长随机串；
留空 = 不检查）、`SL_SHARE_DIFF`（用于监控算力的份额难度，默认 1e11）、`SL_ADDRESSES`（地址列表文件）、`SL_STATE`（计数器）、
`SL_PUBLIC`（用于检查同步的公共节点，默认 `http://main.saseul.net/info`）、`SL_NONCE_LEN`（40）。代理**仅在节点与全网同步时**
下发任务，在此之前 ffgs 会等待。

**轮换地址。** `addresses.txt` 中写一个或多个收款地址（每个 44 位十六进制，私钥由*您*持有），代理在每个新区块模板中依次
填入下一个。原因：SASEUL 给最近 9 个区块的矿工各付 `total/32`，剩余的 **23/32 在其中的不同地址之间平分**——同一地址在这些
区块中出现多次也只得一份。每个区块用不同地址时，在占全网算力 1% 时收益约 +2.5%，10% 时约 +25%；几张显卡时几乎为零，
所以**一个地址就够了**。奖励以 *resource* 形式到账：用 `Refine` 转换为 SL，再用 `Send` 转出（均为需手续费的普通交易，
地址上需先有少量 SL），例如在 Guardee 钱包中操作。

**连接 ffgs**

    ./ffgs --pool 节点IP:19310 --wallet 地址.矿机名 --pass SL_TOKEN

`--wallet` 中的地址只是代理日志里的标识——**奖励发往 `addresses.txt` 中的地址**。代理下发 40 位十六进制 nonce 的任务，ffgs
自动切换到单人内核（无需参数）。多台矿机可共用一个代理。`主机:端口` 矿池列表中没有 rabbitminer.cc 主机时，ffgs 视为单人挖矿：
1% 开发者费用的那一分钟改在 saseulmine.com 上为开发者钱包挖矿（备用 rabbitminer.cc），而不是在您的节点上（见第 6 节）；因此矿机
还需要能访问 pool.saseulmine.com 或 rabbitminer.cc（否则跳过本次费用窗口，继续为您挖矿）。
- Windows：在 `start.bat` 中设置 `POOL=节点IP:19310`、`WALLET=` 您的地址、`WORKER=` 名称、`EXTRA=--pass SL_TOKEN`。
- HiveOS 飞行表：Pool URL `节点IP:19310`，Wallet template `%WAL%.%WORKER_NAME%`，Extra config arguments `--pass SL_TOKEN`
  （见 HIVEOS.md）。

**如何确认正常工作**
- 代理日志：`node IN SYNC: job height …`、每个区块一行 `job height … diff … miner #N …`、`login 矿机名 from IP: ok`、每 5 分钟
  `stats: … shares_total=… blocks=… active={…}`、被拒份额 `reject 矿机名: …`。
- ffgs 日志：`connected 节点IP:19310`、`new block height …`、已接受的份额（这是代理按 `SL_SHARE_DIFF` 计的份额，用于监控）。
  找到区块时：ffgs 中出现 `*** BLOCK FOUND (block) ***`，代理日志中出现 `*** BLOCK <高度> by 矿机名 miner <地址>`；代理将其写入
  `run/mining_result`，由节点广播。可在浏览器 / `saseul-script info` 中核对区块以及该地址的 resource 余额。
- `login …: denied` = `--pass` 错误；`node syncing` = 节点尚未同步（或 `SL_PUBLIC` 无法访问）。
