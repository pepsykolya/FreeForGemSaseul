# FreeForGemSaseul (ffgs) — SASEUL (SL) GPU miner for NVIDIA and AMD

Fast CUDA / OpenCL miner for **SASEUL (SL)** — the resource-chain PoW of [saseul.com](https://saseul.com)
(single SHA-256 over `previous_blockhash + header + nonce`).

- Linux x86_64, **HiveOS** and **Windows x64**; NVIDIA Pascal … Blackwell (GTX 10xx – RTX 50xx), driver 525+
- **AMD Radeon** (new in 0.4.0, OpenCL, tuned for RDNA2: RX 6800 XT 9.0–9.9 GH/s) — the same binary picks the
  backend itself (`--backend auto|cuda|amd`); tested on Windows, Linux AMD not tested yet ([MANUAL 5b](MANUAL.md#5b-amd-gpus-new-in-040))
- **Undervolt auto-tuner** `--auto-uv` (NVIDIA, new in 0.5.1; coarse-to-fine since 0.5.4, typically ~3.5–11.5 min): finds the highest stable core offset itself, checks it while mining (MANUAL 5c)
- **Automatic core clock lock** `--auto-lock` (NVIDIA, new in 0.5.4): measures several locks per GPU, each at its own undervolt, and keeps the most efficient one ([MANUAL 5e](MANUAL.md#5e-automatic-core-clock-lock---auto-lock-new-in-054))
- **GPU clock control** built in (NVIDIA): `--lock-cclock`, `--lock-mclock`, `--coffset`, `--moffset`, `--plimit` — one value or a per-GPU list for mixed rigs (0.5.4: a shorter list repeats its last value, `x` = leave alone, `=0` = offset 0, `--dry-run` shows what would be set)
- **Watchdogs** (new in 0.5.4): a GPU that hangs or slows down without an Xid is restarted ([MANUAL 5g](MANUAL.md#5g-gpu-stall-watchdog-new-in-054)); back to the primary pool and a no-accepted-shares watchdog ([MANUAL 3c](MANUAL.md#3c-pool-health-back-to-the-primary-pool-no-accepted-shares-watchdog-new-in-054))
- **`--temp-limit`** (new in 0.5.4, mainly for laptops / mobile GPUs): keeps the GPU at or below a temperature by giving it less work ([MANUAL 5f](MANUAL.md#5f-temperature-protection---temp-limit-new-in-054-mainly-for-laptops))
- **Local read-only API** `--api` (new in 0.5.4): `/summary`, `/gpus`, `/metrics` (Prometheus) ([MANUAL 3d](MANUAL.md#3d-local-api---api-new-in-054)); Windows autostart and a new-version notice ([MANUAL 3e](MANUAL.md#3e-windows-autostart-new-version-notice-new-in-054))
- Pools: **Kavatar SL Pool** — ours, the default (`sl.kasplay.online:3333`, PPLNS, 2% fee, payouts every 6 h from
  10 SL, [kavatar.kasplay.online](https://kavatar.kasplay.online), [MANUAL 3b](MANUAL.md#3b-kavatar-sl-pool-default-since-050));
  **rabbitminer.cc** (TCP), **saseulmine.com** (HTTPS, `--pool saseulmine`), **saseulpool.com** (NATS,
  `--pool saseulpool`); **solo** through your own node with the bundled solo proxy ([MANUAL 8](MANUAL.md#8-solo-mining-own-node))
- **Fee 2% = 1% dev + 1% referral** (two 60 s windows every 100 min, the first after 15 min). The referral minute
  goes to the wallet in `--referrer ADDRESS` (whoever recommended ffgs to you), the dev minute to the dev — both on your
  pool. **Put your own wallet as referrer and the total fee is 1%** (the dev minute is then mined on Kavatar SL Pool);
  without `--referrer` both minutes go to the dev ([details](MANUAL.md#6-dev-fee-and-referral-2--1-dev--1-referral))
- Every share is re-checked on the CPU before it is sent; a self-test against a real mainnet block runs at every start

🎬 **Video tutorials (0.5.0, two hosts):** [Russian](https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.5.0/ffgs-0.5.0-tutorial-RU.mp4) · [English](https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.5.0/ffgs-0.5.0-tutorial-EN.mp4) — the coin, wallet, our Kavatar SL Pool, setup on Windows / Linux / HiveOS (NVIDIA and AMD), the referral fee, undervolt and hashrates

📖 **Manual (EN / RU / 中文):** [MANUAL.md](MANUAL.md) · HiveOS: [HIVEOS.md](HIVEOS.md) · Changes: [CHANGELOG.md](CHANGELOG.md)

## Download

[Releases](https://github.com/pepsykolya/FreeForGemSaseul/releases):
- `ffgs-<version>.tar.gz` — HiveOS custom miner package
- `ffgs-<version>-linux-x86_64.tar.gz` — plain Linux
- `ffgs-<version>-windows-x64.zip` — Windows
- `SHA256SUMS`

## Quick start (Linux)

    tar xzf ffgs-0.5.4-linux-x86_64.tar.gz && cd ffgs-0.5.4
    ./ffgs --wallet <your SASEUL address>.<worker>                        # Kavatar SL Pool (default)
    ./ffgs --pool nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931 --wallet <your SASEUL address>.<worker>
    ./ffgs --pool saseulmine --wallet <your SASEUL address>.<worker>      # saseulmine.com
    ./ffgs --pool saseulpool --wallet <your SASEUL address>.<worker>      # saseulpool.com (= nats://nats.saseulpool.com:4222)
    sudo ./ffgs --wallet <address>.<worker> --lock-cclock 1500 --lock-mclock 810 --auto-uv       # RTX 3070: best MH/W, undervolt found per GPU
    sudo ./ffgs --wallet <address>.<worker> --lock-mclock 810 --auto-lock                        # lock + undervolt chosen per GPU
    ./ffgs --wallet <address>.<worker> --lock-cclock 1500,1600 --coffset 325,x --dry-run          # show the per-GPU settings only

## Quick start (Windows)

Unzip `ffgs-0.5.4-windows-x64.zip`, put your address into `start.bat` (Kavatar SL Pool), `start-rabbitminer.bat`,
`start-saseulmine.bat` or `start-saseulpool.bat` and run it (or `ffgs.exe --wallet <address>.<worker>`). Only the GPU driver is needed (NVIDIA, or AMD Adrenalin). Optional clock settings:
`LOCK_CCLOCK` / `LOCK_MCLOCK` / `COFFSET` / `MOFFSET` / `PLIMIT` / `AUTO_UV` / `AUTO_LOCK` in the same file (the script then asks for Administrator);
`TEMP_LIMIT` (laptops, no Administrator needed) and `API` (stats API port).
The log is also written to `logs\ffgs.log`. `install-autostart.bat` starts it at every logon (Task Scheduler); `remove-autostart.bat` undoes that.

## HiveOS quick start

Flight sheet: Miner **Custom** → *Setup Miner Config*:

| Field | Value |
|---|---|
| Installation URL | `https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.5.4/ffgs-0.5.4.tar.gz` |
| Hash algorithm | `saseul` |
| Wallet and worker template | `%WAL%.%WORKER_NAME%` |
| Pool URL | `sl.kasplay.online:3333` (Kavatar SL Pool); or `nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931`, `https://pool.saseulmine.com`, `nats://nats.saseulpool.com:4222` |
| Extra config arguments | *(empty)*, or `--referrer ADDRESS` (1% referral; your own wallet = total fee 1%), `--lock-cclock 1500 --lock-mclock 810 --auto-uv` (RTX 3070, best MH/W; no core lock / offset in the OC profile), `--auto-lock --lock-mclock 810` (lock chosen per GPU), `--devices 0,2`, `--api 4068` (lists without spaces) |

## GPU clock control (0.4.0)

`--lock-cclock`, `--lock-mclock`, `--coffset` (alias `--uv-offset`), `--moffset`, `--plimit`: one value for all GPUs or a
comma list in `--devices` order (empty / 0 / x = leave that GPU alone; since 0.5.4 a shorter list repeats its last
value and `=0` sets an offset to exactly 0; `--dry-run` prints the per-GPU settings and exits). Needs root /
Administrator; everything is put back when ffgs exits (also after a crash: the next start undoes it). `--oc-info` shows
the current values. Details:
[MANUAL.md, 5a](MANUAL.md#5a-gpu-clock-control-new-in-040). If these options set clocks, ffgs keeps them even if the HiveOS OC
profile (or another OC tool) has other values (0.5.4: set again within 10 s, logged in orange).

**Recommended settings** (measured with 0.5.3 / 0.5.4, default kernel, memory locked 810, Kavatar SL Pool; full tables:
[MANUAL 5](MANUAL.md#5-tuning)):

| GPU | Goal | Settings | Result per GPU |
|---|---|---|---|
| **RTX 3070** | **best MH/W** | `--lock-cclock 1500 --lock-mclock 810 --auto-uv` | **5.62 GH/s, 76 W, 73.9 MH/W** (auto-uv +330 … +435) |
| RTX 3070 | balance | `--lock-cclock 1700 --lock-mclock 810 --auto-uv` | 6.40 GH/s, 106 W, 60.4 MH/W |
| RTX 3070 | max hashrate | `--lock-cclock 1800 --lock-mclock 810 --auto-uv` | 6.74 GH/s, 121 W, 55.7 MH/W |
| **RTX 3080 Ti** | **best MH/W** | `--lock-cclock 1600 --lock-mclock 810 --auto-uv` | **10.32 GH/s, 180 W, 57.4 MH/W** (+240) |
| RTX 3080 Ti | balance | `--lock-cclock 1700 --lock-mclock 810 --auto-uv` | 10.98 GH/s, 212 W, 51.9 MH/W (+240) |
| RTX 3080 Ti | max hashrate | `--lock-mclock 810` (core not locked) | 11.54 GH/s, 332 W, 34.8 MH/W |
| any NVIDIA | let ffgs choose | `--lock-mclock 810 --auto-lock` | best MH/W within 10 % of the GPU's top GH/s (3080 Ti: it chose 1700 +240) |

- **Lock the memory at 810:** SL needs no memory bandwidth; the stock memory clock only adds watts (RTX 3070 at 1400:
  +27 W, RTX 3080 Ti at 1400: +57 W for the same hashrate).
- **Undervolt pays off from ~1500 MHz up:** at 1800 auto-uv takes an RTX 3070 from 186 W to 121 W at the same GH/s.
  Below 1400 the core voltage is already at its floor: the watts hardly drop, the hashrate does — 1100–1300 are not
  worth it. A fixed manual offset without a check is not recommended at high clocks (RTX 3070 edges at 1700–1800:
  +345 … +375, so +300 leaves little margin).
- Every card differs (RTX 3070: up to 25 % in watts at the same clock): if `hardware error (bad candidate)` lines or
  rejects appear, lower the offset or the core clock.

## Console

    2026-10-23 01:37:13 [user] share accepted #2, share diff 163209176362, 330 ms
    2026-10-23 01:37:36 [   30s] GPU0 4.374 (75 W, 58.2 MH/W) | total 4.374 GH/s (75 W, 58.2 MH/W) | user sub 2 acc 2 rej 0 | fee sub 0 acc 0 rej 0
    2026-10-23 01:37:36 == ffgs 0.4.0 | up 0h 00m | saseulmine | online | height 2357031 | share diff 163209176362 ==
      GPU  name                  GH/s 10s   5 min      W   MH/W   core    mem  temp  fan          offsets     set by ffgs
        0  RTX 3070                4.629   4.631     75   61.6   1410    810  55 C  0%           +200/-500     lock 1400/810, core +200, mem -500, 120 W
      rig  1 GPU                   4.629   4.631     75   61.6
      shares  accepted 2 (100.0%)  stale 0 (0.0%)  low-diff 0 (0.0%)  rejected 0 (0.0%)  dropped 0  blocks 0  round trip 330 ms  | dev fee acc 0/0
      pool    saseulmine: hashrate 1h 9.01 GH/s, 24h 0.73 GH/s | round shares 823 (0.364% of the pool) | paid 0 (0 payouts) (0 min ago)

Colors (`--color auto|always|never`, default auto: terminal, HiveOS `miner` screen and its web log; `--log` files plain):
block found = bold white on magenta, accepted green, hashrate bold white, MH/W bold blue, temperature green/yellow/red,
stale/dropped yellow, rejected/errors red, new block / difficulty cyan, dev fee dim. Details: MANUAL 3a.

## Kernels

The default kernel moves the integer additions of SHA-256 to the FMA pipe (the integer pipe is the bottleneck):
+13% hashrate per clock for more power. `--eco` keeps the shortest instruction stream for the best H/W at low clocks.

## Pools

| Pool | Address | Notes |
|---|---|---|
| **Kavatar SL Pool** (ours, default) | `sl.kasplay.online:3333` (TCP, = `--pool kavatar`) | PPLNS (2 × network difficulty), pool fee 2%, payouts every 6 h from 10 SL, own SASEUL node, vardiff; site + wallet lookup [kavatar.kasplay.online](https://kavatar.kasplay.online) — [MANUAL 3b](MANUAL.md#3b-kavatar-sl-pool-default-since-050) |
| rabbitminer.cc | `nl.rabbitminer.cc:1931`, `fi.rabbitminer.cc:1931` (TCP) | pool fee 10%, payout from 100 SL |
| saseulmine.com | `saseulmine` = `https://pool.saseulmine.com` (HTTPS) | miners 80% / referrers 10% / pool 10% ("no referrer — your share is unchanged"), daily payouts, vardiff |
| saseulpool.com | `saseulpool` = `nats://nats.saseulpool.com:4222` (NATS) | PPLNS 90 min, pool fee 5%, payouts every 6 h from 10 SL, fixed share difficulty (network / 4096); the pool answers no single share — see [MANUAL 6b](MANUAL.md#6b-saseulpoolcom-details) |
| Solo (own node) | `NODE_IP:19310` + `--pass <token>` (solo proxy `solo/sl_solo_proxy.py` next to your synced SASEUL node) | no pool fee, the whole block reward; pays only when you find a block (average time = network difficulty / hashrate) — [MANUAL 8](MANUAL.md#8-solo-mining-own-node) |

## License

Free to use and redistribute unmodified, see [LICENSE](LICENSE). The GPU kernel is distributed as a binary.
