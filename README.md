# FreeForGemSaseul (ffgs) — SASEUL (SL) GPU miner for NVIDIA

Fast CUDA miner for **SASEUL (SL)** — the resource-chain PoW of [saseul.com](https://saseul.com)
(single SHA-256 over `previous_blockhash + header + nonce`).

- Linux x86_64 and **HiveOS**; NVIDIA Pascal … Blackwell (GTX 10xx – RTX 50xx), driver 525+
- **Dev fee 1.0%** (60 s every 100 min, the first one after 15 min of mining)
- Every share is re-checked on the CPU before it is sent; a self-test against a real mainnet block runs at every start

📖 **Manual (EN / RU / 中文):** [MANUAL.md](MANUAL.md) · HiveOS: [HIVEOS.md](HIVEOS.md) · Changes: [CHANGELOG.md](CHANGELOG.md)

## Download

[Releases](https://github.com/pepsykolya/FreeForGemSaseul/releases):
- `ffgs-<version>.tar.gz` — HiveOS custom miner package
- `ffgs-<version>-linux-x86_64.tar.gz` — plain Linux
- `SHA256SUMS`

## Quick start (Linux)

    tar xzf ffgs-0.1.0-linux-x86_64.tar.gz && cd ffgs-0.1.0
    ./ffgs --pool nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931 --wallet <your SASEUL address>.<worker>

## HiveOS quick start

Flight sheet: Miner **Custom** → *Setup Miner Config*:

| Field | Value |
|---|---|
| Installation URL | `https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.1.0/ffgs-0.1.0.tar.gz` |
| Hash algorithm | `saseul` |
| Wallet and worker template | `%WAL%.%WORKER_NAME%` |
| Pool URL | `nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931` |
| Extra config arguments | *(empty)*, or `--eco`, `--devices 0,2` |

## Performance (RTX 3070, same card, same settings)

| Card settings | **ffgs** | ffgs `--eco` | rabbitminer cuda-miner-12 |
|---|---|---|---|
| core locked 1560 MHz | **4.78 GH/s**, 108 W | 4.21 GH/s, 90 W (47 MH/W) | 4.21–4.26 GH/s, 92 W (46 MH/W) |
| stock, power limit 135 W | **5.35 GH/s** | 5.02 GH/s | 4.99 GH/s |

The default kernel moves the integer additions of SHA-256 to the FMA pipe (the integer pipe is the bottleneck):
+13% hashrate per clock for more power. `--eco` keeps the shortest instruction stream for the best H/W at low clocks.

## Pools

| Pool | Address | Notes |
|---|---|---|
| rabbitminer.cc | `nl.rabbitminer.cc:1931`, `fi.rabbitminer.cc:1931` (TCP) | pool fee 10%, payout from 100 SL |

## License

Free to use and redistribute unmodified, see [LICENSE](LICENSE). The GPU kernel is distributed as a binary.
