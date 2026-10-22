# FreeForGemSaseul (ffgs) — SASEUL (SL) GPU miner for NVIDIA

Fast CUDA miner for **SASEUL (SL)** — the resource-chain PoW of [saseul.com](https://saseul.com)
(single SHA-256 over `previous_blockhash + header + nonce`).

- Linux x86_64, **HiveOS** and **Windows x64**; NVIDIA Pascal … Blackwell (GTX 10xx – RTX 50xx), driver 525+
- Pools: **rabbitminer.cc** (TCP) and **saseulmine.com** (HTTPS, `--pool saseulmine`)
- **Dev fee 1.0%** (60 s every 100 min, the first one after 15 min of mining). On saseulmine the ffgs dev wallet is also
  sent as your *referrer* by default — per the pool this does not reduce your payout; `--referrer none` turns it off
  ([details](MANUAL.md#6-dev-fee-and-the-saseulmine-referrer))
- Every share is re-checked on the CPU before it is sent; a self-test against a real mainnet block runs at every start

📖 **Manual (EN / RU / 中文):** [MANUAL.md](MANUAL.md) · HiveOS: [HIVEOS.md](HIVEOS.md) · Changes: [CHANGELOG.md](CHANGELOG.md)

## Download

[Releases](https://github.com/pepsykolya/FreeForGemSaseul/releases):
- `ffgs-<version>.tar.gz` — HiveOS custom miner package
- `ffgs-<version>-linux-x86_64.tar.gz` — plain Linux
- `ffgs-<version>-windows-x64.zip` — Windows
- `SHA256SUMS`

## Quick start (Linux)

    tar xzf ffgs-0.3.0-linux-x86_64.tar.gz && cd ffgs-0.3.0
    ./ffgs --pool nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931 --wallet <your SASEUL address>.<worker>
    ./ffgs --pool saseulmine --wallet <your SASEUL address>.<worker>      # saseulmine.com

## Quick start (Windows)

Unzip `ffgs-0.3.0-windows-x64.zip`, put your address into `start.bat` (rabbitminer) or `start-saseulmine.bat` and run it
(or `ffgs.exe --pool saseulmine --wallet <address>.<worker>`). Only the NVIDIA driver is needed.

## HiveOS quick start

Flight sheet: Miner **Custom** → *Setup Miner Config*:

| Field | Value |
|---|---|
| Installation URL | `https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.3.0/ffgs-0.3.0.tar.gz` |
| Hash algorithm | `saseul` |
| Wallet and worker template | `%WAL%.%WORKER_NAME%` |
| Pool URL | `nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931` or `https://pool.saseulmine.com` |
| Extra config arguments | *(empty)*, or `--eco`, `--devices 0,2`, `--referrer none` |

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

## License

Free to use and redistribute unmodified, see [LICENSE](LICENSE). The GPU kernel is distributed as a binary.
