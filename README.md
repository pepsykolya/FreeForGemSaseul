# FreeForGemSaseul (ffgs) — SASEUL (SL) GPU miner for NVIDIA and AMD

Fast CUDA / OpenCL miner for **SASEUL (SL)** — the resource-chain PoW of [saseul.com](https://saseul.com)
(single SHA-256 over `previous_blockhash + header + nonce`).

- Linux x86_64, **HiveOS** and **Windows x64**; NVIDIA Pascal … Blackwell (GTX 10xx – RTX 50xx), driver 525+
- **AMD Radeon** (new in 0.4.0, OpenCL, tuned for RDNA2: RX 6800 XT 9.0–9.9 GH/s) — the same binary picks the
  backend itself (`--backend auto|cuda|amd`); tested on Windows, Linux AMD not tested yet ([MANUAL 5b](MANUAL.md#5b-amd-gpus-new-in-040))
- **GPU clock control** built in (NVIDIA): `--lock-cclock`, `--lock-mclock`, `--coffset`, `--moffset`, `--plimit`
- Pools: **rabbitminer.cc** (TCP), **saseulmine.com** (HTTPS, `--pool saseulmine`), **saseulpool.com** (NATS,
  `--pool saseulpool`); **solo** through your own node with the bundled solo proxy ([MANUAL 8](MANUAL.md#8-solo-mining-own-node))
- **Dev fee 1.0%** (60 s every 100 min, the first one after 15 min of mining). On saseulmine the ffgs dev wallet is also
  sent as your *referrer* by default — per the pool this does not reduce your payout; `--referrer none` turns it off
  ([details](MANUAL.md#6-dev-fee-and-the-saseulmine-referrer))
- Every share is re-checked on the CPU before it is sent; a self-test against a real mainnet block runs at every start

🎬 **Video tutorials (0.4.0):** [Russian, interview](https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.4.0/ffgs-0.4.0-tutorial-RU.mp4) · [English](https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.4.0/ffgs-0.4.0-tutorial-EN.mp4) — the coin, Guardee wallet, pools, setup, undervolt and hashrates

📖 **Manual (EN / RU / 中文):** [MANUAL.md](MANUAL.md) · HiveOS: [HIVEOS.md](HIVEOS.md) · Changes: [CHANGELOG.md](CHANGELOG.md)

## Download

[Releases](https://github.com/pepsykolya/FreeForGemSaseul/releases):
- `ffgs-<version>.tar.gz` — HiveOS custom miner package
- `ffgs-<version>-linux-x86_64.tar.gz` — plain Linux
- `ffgs-<version>-windows-x64.zip` — Windows
- `SHA256SUMS`

## Quick start (Linux)

    tar xzf ffgs-0.4.0-linux-x86_64.tar.gz && cd ffgs-0.4.0
    ./ffgs --pool nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931 --wallet <your SASEUL address>.<worker>
    ./ffgs --pool saseulmine --wallet <your SASEUL address>.<worker>      # saseulmine.com
    ./ffgs --pool saseulpool --wallet <your SASEUL address>.<worker>      # saseulpool.com (= nats://nats.saseulpool.com:4222)
    sudo ./ffgs --pool saseulmine --wallet <address> --lock-cclock 1400 --lock-mclock 810 --coffset 225   # with clock control

## Quick start (Windows)

Unzip `ffgs-0.4.0-windows-x64.zip`, put your address into `start.bat` (rabbitminer), `start-saseulmine.bat` or
`start-saseulpool.bat` and run it (or `ffgs.exe --pool saseulpool --wallet <address>.<worker>`). Only the GPU driver is needed (NVIDIA, or AMD Adrenalin). Optional clock settings:
`LOCK_CCLOCK` / `LOCK_MCLOCK` / `COFFSET` / `MOFFSET` / `PLIMIT` in the same file (the script then asks for Administrator).
The log is also written to `logs\ffgs.log`.

## HiveOS quick start

Flight sheet: Miner **Custom** → *Setup Miner Config*:

| Field | Value |
|---|---|
| Installation URL | `https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.4.0/ffgs-0.4.0.tar.gz` |
| Hash algorithm | `saseul` |
| Wallet and worker template | `%WAL%.%WORKER_NAME%` |
| Pool URL | `nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931`, `https://pool.saseulmine.com` or `nats://nats.saseulpool.com:4222` |
| Extra config arguments | *(empty)*, or `--eco`, `--devices 0,2`, `--referrer none` |

## GPU clock control (0.4.0)

`--lock-cclock`, `--lock-mclock`, `--coffset` (alias `--uv-offset`), `--moffset`, `--plimit`: one value for all GPUs or a
comma list in `--devices` order (empty / 0 = leave that GPU alone). Needs root / Administrator; everything is put back
when ffgs exits (also after a crash: the next start undoes it). `--oc-info` shows the current values. Details:
[MANUAL.md, 5a](MANUAL.md#5a-gpu-clock-control-new-in-040). Do not use it together with a HiveOS OC profile or another
OC tool on the same GPU.

**Recommended settings, RTX 3070** (measured on our rig, default kernel):

| Goal | `--lock-cclock` | `--lock-mclock` | `--coffset` | Result |
|---|---|---|---|---|
| **best efficiency** | **1400** | **810** | **225** | **~4.6 GH/s at 73–75 W, ~62 MH/W** (0.3.0: 80 min at 4.61 GH/s / 73 W; 0.4.0 with `--coffset 200`: 4.63 GH/s / 75 W) |
| more hashrate | 1560 | 810 | 175 | 5.16 GH/s at ~113 W, ~46 MH/W (0.2.0 bench) |

Every card differs: if `hardware error (bad candidate)` lines or rejects appear, lower the offset or the core clock.

## Console

    2026-10-23 01:37:13 [user] share accepted #2, share diff 163209176362, 330 ms
    2026-10-23 01:37:36 [   30s] GPU0 4.374 (75 W, 58.2 MH/W) | total 4.374 GH/s (75 W, 58.2 MH/W) | user sub 2 acc 2 rej 0 | fee sub 0 acc 0 rej 0
    2026-10-23 01:37:36 == ffgs 0.4.0 | up 0h 00m | saseulmine | online | height 2357031 | share diff 163209176362 ==
      GPU  name                  GH/s 10s   5 min      W   MH/W   core    mem  temp  fan          offsets     set by ffgs
        0  RTX 3070                4.629   4.631     75   61.6   1410    810  55 C  0%           +200/-500     lock 1400/810, core +200, mem -500, 120 W
      rig  1 GPU                   4.629   4.631     75   61.6
      shares  accepted 2 (100.0%)  stale 0 (0.0%)  low-diff 0 (0.0%)  rejected 0 (0.0%)  dropped 0  blocks 0  round trip 330 ms  | dev fee acc 0/0
      pool    saseulmine: hashrate 1h 9.01 GH/s, 24h 0.73 GH/s | round shares 823 (0.364% of the pool) | paid 0 (0 payouts) (0 min ago)

Colors on the console (green accepted, yellow stale/dropped, red rejected/errors, cyan new block / difficulty, magenta
block found, dim dev fee); log files and HiveOS get plain text.

## Performance (RTX 3070, same card, same settings)

| Card settings | **ffgs** | ffgs `--eco` | rabbitminer cuda-miner-12 |
|---|---|---|---|
| core locked 1560 MHz | **5.16 GH/s**, 113 W | 4.21 GH/s, 90 W (47 MH/W) | 4.21–4.26 GH/s, 92 W (46 MH/W) |
| stock, power limit 135 W | **5.35 GH/s** | 5.02 GH/s | 4.99 GH/s |

### Tuning sweep (RTX 3070, kernel 0.1.1 — 0.2.0 is ~8% faster per clock; VF offset = undervolt at the locked clock)

| Kernel | Core | VF offset | Memory | GH/s | W | MH/W |
|---|---|---|---|---|---|---|
| default | stock (PL 135 W) | +225 | max | 5.38 | 135 | 39.9 |
| default | 1700 | +150 | max | 5.21 | 122 | 42.6 |
| default | 1560 | +225 | max | 4.79 | 98 | 48.6 |
| default | 1560 | +225 | 810 | 4.70 | 90 | 52.1 |
| **default** | **1400** | **+225** | **810** | **4.31** | **74** | **58.1** |
| `--eco` | 1560 | +225 | 810 | 4.11 | 78 | 52.8 |
| `--eco` | 1400 | +225 | 810 | 3.80 | 64 | 59.4 |

Same RTX 3070 at a locked 1400 MHz on saseulmine.com: **ffgs 0.3.0 4.56 GH/s at 76 W** vs the pool's own
miner 0.9.2.18 2.51 GH/s at 87 W (gpu_percent 100; its default of 25% gives ~0.2 GH/s).

No hardware errors in any of these settings. Memory clock does not matter for the hashrate — lock it low.

The default kernel moves the integer additions of SHA-256 to the FMA pipe (the integer pipe is the bottleneck):
+13% hashrate per clock for more power. `--eco` keeps the shortest instruction stream for the best H/W at low clocks.

## Pools

| Pool | Address | Notes |
|---|---|---|
| rabbitminer.cc | `nl.rabbitminer.cc:1931`, `fi.rabbitminer.cc:1931` (TCP) | pool fee 10%, payout from 100 SL |
| saseulmine.com | `saseulmine` = `https://pool.saseulmine.com` (HTTPS) | miners 80% / referrers 10% / pool 10% ("no referrer — your share is unchanged"), daily payouts, vardiff |
| saseulpool.com | `saseulpool` = `nats://nats.saseulpool.com:4222` (NATS) | PPLNS 90 min, pool fee 5%, payouts every 6 h from 10 SL, fixed share difficulty (network / 4096); the pool answers no single share — see [MANUAL 6b](MANUAL.md#6b-saseulpoolcom-details) |
| Solo (own node) | `NODE_IP:19310` + `--pass <token>` (solo proxy `solo/sl_solo_proxy.py` next to your synced SASEUL node) | no pool fee, the whole block reward; pays only when you find a block (average time = network difficulty / hashrate) — [MANUAL 8](MANUAL.md#8-solo-mining-own-node) |

## License

Free to use and redistribute unmodified, see [LICENSE](LICENSE). The GPU kernel is distributed as a binary.
