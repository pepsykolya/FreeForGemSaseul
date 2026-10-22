# Changelog

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
