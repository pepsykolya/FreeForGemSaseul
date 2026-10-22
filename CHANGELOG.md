# Changelog

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
