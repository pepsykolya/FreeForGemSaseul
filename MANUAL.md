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
| `--oc-info` | clocks, offsets and power limits of the selected GPUs, then exit (no root needed) |
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
| rejected share, errors, hardware errors, connection lost, `OFFLINE` / `pool offline` | red |
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

### 4. HiveOS
See [HIVEOS.md](HIVEOS.md).

### 5. Tuning
- The PoW is pure compute (no memory traffic): the **memory clock can be lowered** to the minimum to save power.
- **Default kernel** — highest hashrate per clock. Best when the card is power-limited or the core clock is locked high.
- **`--eco`** — about 12% fewer GH/s per clock but ~17% less power; best H/W on undervolted cards.
- RTX 3070 reference points: lock 1560 MHz → 4.78 GH/s at 108 W (default) / 4.21 GH/s at 90 W (`--eco`).

### 5a. GPU clock control (new in 0.4.0)
ffgs can set the clocks of the GPUs it mines on, the same way as FreeForGemPear:

| Option | What it does |
|---|---|
| `--lock-cclock N` | core clock locked to N MHz (`nvidia-smi -lgc N,N`) |
| `--lock-mclock N` | memory clock locked to N MHz (`nvidia-smi -lmc N,N`); SL needs no memory bandwidth, use the lowest (810 on RTX 30/40) |
| `--coffset N` / `--uv-offset N` | core clock V/F offset in MHz: at a locked core clock a positive offset means the same clock at a lower voltage (undervolt) |
| `--moffset N` | memory clock offset in MHz, may be negative (driver 555+) |
| `--plimit W` | power limit in W |

- One value applies to every mining GPU; a comma list gives one value per GPU in `--devices` order. An empty entry,
  `-` or `0` leaves that GPU's setting alone: `--devices 0,1,2 --lock-cclock 1400,,1560`. (So `0` cannot be used to
  set an offset of exactly 0; without `--coffset` the offset is simply not touched.)
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
- **Do not combine with other OC tools on the same GPU** (HiveOS OC profile, MSI Afterburner, `nvidia-smi` in a
  service): on exit ffgs resets the locks it set, which also removes a lock that the other tool had set before.
- Windows: set `LOCK_CCLOCK`, `LOCK_MCLOCK`, `COFFSET`, `MOFFSET`, `PLIMIT` in `start.bat` / `start-saseulmine.bat` /
  `start-saseulpool.bat`.
  With any of them set, the script asks Windows to reopen itself as Administrator (`AUTO_ELEVATE=1`, the default).

**RTX 3070, measured (0.5.0):** `--lock-cclock 1400 --lock-mclock 810 --coffset 325` → **5.05 GH/s at 74 W (68 MH/W)** on 40-hex pools (Kavatar, saseulmine, solo), 4.65 GH/s on 16-hex pools;
`--lock-cclock 1560` gives ~5.1 GH/s at ~110 W. See the README tuning table.

### 5c. Undervolt auto-tuner `--auto-uv` (new in 0.5.1)
ffgs finds the undervolt itself (the same tuner as FreeForGemPear): it raises the core V/F offset of each NVIDIA GPU in
15 MHz steps, checks every step and keeps the last good step minus one step of margin.

    sudo ./ffgs --wallet <address>.<worker> --lock-cclock 1400 --lock-mclock 810 --auto-uv

- **Use it at a locked core clock** (`--lock-cclock`, or the lock of the HiveOS OC profile): then a higher offset means
  the same clock at a lower voltage. NVIDIA only, needs root / Administrator.
- **First start:** a warm-up check at the start offset (2 min), then 30 s per step up to `--uv-max`, then a 2 min
  confirmation; all GPUs at once, mining starts after (~10–15 min). **Later starts:** the saved offset after a 20 s check.
- **The check** runs the mining kernel at full load in a separate process on fixed test jobs: the number of candidates of
  every launch must be exactly the reference (a GPU that computes even one hash wrong changes it within seconds) and every
  stored candidate is re-hashed on the CPU. A crash or hang of the GPU only kills that process.
- **While mining:** a hardware error (bad candidate) steps the GPU back by 15 MHz (saved); every 6 h a 20 s re-check
  (that GPU pauses for it). If something else changes the offset (HiveOS OC), auto-uv leaves that GPU alone.
- Saved in `ffgs-uv-results.txt` next to the binary (HiveOS: `/hive-config/ffgs`, kept over miner updates), per GPU, board
  and driver. If ffgs dies during a step (kill, Xid, power), the next start puts the offset back and tunes below that step.
  The original offset is restored on exit like with `--coffset`.
- Options: `--uv-min MHz` (search start; default: the current offset, else +120, RTX 40/50 at least +200),
  `--uv-max MHz` (default +495), `--uv-step MHz` (15), `--uv-reset` (forget the results, tune again),
  `--uv-reval-hours H` (6, 0 = never). Windows: `AUTO_UV=1` in the start scripts. `--coffset` together with
  `--auto-uv` = the search starts from that offset.
- **RTX 3070, measured** (lock 1400/810, start +250): steps up to +385 ok, +400 failed (one candidate missing) →
  **+370**, 73 W instead of 76 W at +250; on Kavatar 5.04 GH/s, 69 MH/W, 0 rejects.

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
| `--oc-info` | частоты, оффсеты и лимиты мощности выбранных GPU, затем выход (root не нужен) |
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
| отклонённая шара, ошибки, hardware error, потеря связи, `OFFLINE` / `pool offline` | красный |
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

### 4. HiveOS
См. [HIVEOS.md](HIVEOS.md).

### 5. Настройка
- PoW — чистые вычисления без работы с памятью: **частоту памяти можно опустить** до минимума, это экономит ватты.
- **Ядро по умолчанию** — максимум хешей на такт; лучше, когда карта упирается в лимит мощности или ядро зафиксировано высоко.
- **`--eco`** — примерно на 12% меньше GH/s на такт, но ~17% меньше мощность; лучший H/W на андервольте.
- RTX 3070: фиксация 1560 МГц → 4.78 GH/s при 108 Вт (по умолчанию) / 4.21 GH/s при 90 Вт (`--eco`).

### 5a. Управление частотами GPU (новое в 0.4.0)
ffgs умеет выставлять частоты карт, на которых майнит, так же, как FreeForGemPear:

| Опция | Что делает |
|---|---|
| `--lock-cclock N` | фиксирует частоту ядра на N МГц (`nvidia-smi -lgc N,N`) |
| `--lock-mclock N` | фиксирует частоту памяти на N МГц (`nvidia-smi -lmc N,N`); SL не нужна пропускная способность памяти — ставьте минимум (810 на RTX 30/40) |
| `--coffset N` / `--uv-offset N` | V/F-оффсет частоты ядра в МГц: при зафиксированной частоте положительный оффсет = та же частота при меньшем напряжении (андервольт) |
| `--moffset N` | оффсет частоты памяти в МГц, может быть отрицательным (драйвер 555+) |
| `--plimit W` | лимит мощности, Вт |

- Одно значение — для всех карт майнинга; список через запятую — по значению на карту в порядке `--devices`. Пустое
  значение, `-` или `0` — эту настройку на этой карте не трогать: `--devices 0,1,2 --lock-cclock 1400,,1560`. (Поэтому
  оффсет ровно 0 через `0` не задать; без `--coffset` оффсет просто не трогается.)
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
- **Не совмещайте с другими средствами разгона на той же карте** (OC-профиль HiveOS, MSI Afterburner, `nvidia-smi` в
  сервисе): при выходе ffgs сбрасывает свои фиксации, а с ними и фиксацию, которую до этого поставила другая программа.
- Windows: переменные `LOCK_CCLOCK`, `LOCK_MCLOCK`, `COFFSET`, `MOFFSET`, `PLIMIT` в `start.bat` / `start-saseulmine.bat` /
  `start-saseulpool.bat`.
  Если задана хоть одна, скрипт просит Windows перезапустить его от администратора (`AUTO_ELEVATE=1` по умолчанию).

**RTX 3070, замер (0.5.0):** `--lock-cclock 1400 --lock-mclock 810 --coffset 325` → **5,05 GH/s при 74 Вт (68 MH/W)** на пулах с 40 hex (Kavatar, saseulmine, соло), 4,65 GH/s на пулах с 16 hex;
`--lock-cclock 1560` — ~5.1 GH/s при ~110 Вт. Подробнее — таблица в README.

### 5c. Автоподбор андервольта `--auto-uv` (новое в 0.5.1)
ffgs сам подбирает андервольт (тот же тюнер, что в FreeForGemPear): поднимает V/F-оффсет ядра каждой карты NVIDIA
шагами по 15 МГц, проверяет каждый шаг и оставляет последний удачный минус один шаг запаса.

    sudo ./ffgs --wallet <адрес>.<воркер> --lock-cclock 1400 --lock-mclock 810 --auto-uv

- **Нужна зафиксированная частота ядра** (`--lock-cclock` или фиксация в OC-профиле HiveOS): тогда больший оффсет =
  та же частота при меньшем напряжении. Только NVIDIA, нужны права root / администратора.
- **Первый запуск:** проверка-прогрев на стартовом оффсете (2 мин), затем по 30 с на шаг до `--uv-max`, затем
  подтверждение 2 мин; все карты одновременно, майнинг начинается после (~10–15 мин). **Следующие запуски:**
  сохранённый оффсет после проверки 20 с.
- **Проверка** гоняет ядро майнинга на полной нагрузке в отдельном процессе на фиксированных тестовых заданиях: число
  кандидатов каждого запуска должно точно совпасть с эталоном (если карта хоть один хеш посчитала неверно, это видно за
  секунды), каждый сохранённый кандидат пересчитывается на CPU. Падение или зависание карты убивает только этот процесс.
- **Во время майнинга:** аппаратная ошибка (bad candidate) — шаг назад на 15 МГц (сохраняется); каждые 6 ч
  перепроверка 20 с (карта на это время встаёт). Если оффсет поменял кто-то другой (OC HiveOS), auto-uv карту отпускает.
- Результаты — `ffgs-uv-results.txt` рядом с программой (HiveOS: `/hive-config/ffgs`, переживает обновления майнера), по
  карте, модели и драйверу. Если ffgs упал на шаге (kill, Xid, питание), следующий запуск вернёт оффсет и будет
  подбирать ниже этого шага. При выходе исходный оффсет возвращается, как с `--coffset`.
- Опции: `--uv-min МГц` (начало поиска; по умолчанию текущий оффсет, иначе +120, RTX 40/50 — минимум +200),
  `--uv-max МГц` (по умолчанию +495), `--uv-step МГц` (15), `--uv-reset` (забыть результаты и подобрать заново),
  `--uv-reval-hours Ч` (6, 0 = никогда). Windows: `AUTO_UV=1` в батниках. `--coffset` вместе с `--auto-uv` — поиск
  начинается с этого оффсета.
- **RTX 3070, замер** (фиксация 1400/810, старт +250): шаги до +385 ok, +400 — сбой (недосчитан один кандидат) →
  **+370**, 73 Вт вместо 76 Вт на +250; на Kavatar 5,04 GH/s, 69 MH/W, 0 реджектов.

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
| `--oc-info` | 显示所选 GPU 的频率、偏移和功耗上限后退出（无需 root） |
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
| 被拒绝的份额、错误、硬件错误、断线、`OFFLINE` / `pool offline` | 红色 |
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

### 4. HiveOS
见 [HIVEOS.md](HIVEOS.md)。

### 5. 调优
- 该 PoW 只做计算、不访问显存：**显存频率可以降到最低**以节省功耗。
- **默认内核**：每个时钟周期算力最高，适合功耗墙受限或核心频率锁定较高的情况。
- **`--eco`**：每时钟算力约低 12%，功耗约低 17%，降压显卡上能效最佳。
- RTX 3070 参考：锁定 1560 MHz → 4.78 GH/s / 108 W（默认），4.21 GH/s / 90 W（`--eco`）。

### 5a. GPU 频率控制（0.4.0 新增）
ffgs 可以像 FreeForGemPear 一样设置挖矿显卡的频率：

| 参数 | 作用 |
|---|---|
| `--lock-cclock N` | 将核心频率锁定为 N MHz（`nvidia-smi -lgc N,N`） |
| `--lock-mclock N` | 将显存频率锁定为 N MHz（`nvidia-smi -lmc N,N`）；SL 不需要显存带宽，设为最低（RTX 30/40 为 810） |
| `--coffset N` / `--uv-offset N` | 核心 V/F 偏移（MHz）：锁定核心频率时，正偏移 = 同频率更低电压（降压） |
| `--moffset N` | 显存频率偏移（MHz），可为负（驱动 555+） |
| `--plimit W` | 功耗上限（瓦） |

- 一个值适用于所有挖矿显卡；逗号分隔的列表按 `--devices` 顺序为每张卡指定。空值、`-` 或 `0` 表示该卡的该项不变：
  `--devices 0,1,2 --lock-cclock 1400,,1560`。
- 需要 **root**（Linux）/ **管理员**（Windows）权限；否则 ffgs 输出一行提示并以当前频率继续挖矿。
- 在启动自检之前应用（内核在新频率下校验）；每个值都会记录并回读，挖矿约 30 秒后输出显卡实际运行的频率。
- **退出时恢复**：Ctrl-C、SIGTERM/SIGHUP、关闭控制台窗口、`--minutes`、致命错误。频率锁定恢复为驱动默认值，偏移和功耗上限恢复为修改前读取的值。
  若 ffgs 被强制结束（kill -9、崩溃），程序旁的标记文件 `ffgs-oc-<bus>.restore` 会让下一次启动的 ffgs 自动恢复（即使不带频率参数）。
  其他正在运行的 ffgs 的标记会被尊重，重启之前的标记会被丢弃。
- 只修改 `--devices` 中的显卡，通过 PCI 总线号与 NVML 对应。NVML 在运行时加载，缺少它 ffgs 仍可挖矿。
- `--oc-info` 只显示当前频率、偏移（及允许范围）和功耗上限，不做任何修改。
- **不要与其他超频工具同时作用于同一张卡**（HiveOS 超频配置、MSI Afterburner、服务中的 `nvidia-smi`）：退出时 ffgs 会重置它设置的锁定，
  也会清除其他工具先前设置的锁定。
- Windows：在 `start.bat` / `start-saseulmine.bat` / `start-saseulpool.bat` 中设置 `LOCK_CCLOCK`、`LOCK_MCLOCK`、`COFFSET`、`MOFFSET`、`PLIMIT`；设置任一项时，
  脚本会请求以管理员身份重新打开（默认 `AUTO_ELEVATE=1`）。

**RTX 3070 实测（0.5.0）：** `--lock-cclock 1400 --lock-mclock 810 --coffset 325` → 在 40 位十六进制矿池（Kavatar、saseulmine、单人）**5.05 GH/s，74 W（68 MH/W）**，16 位矿池 4.65 GH/s；
`--lock-cclock 1560` 约 5.1 GH/s，约 110 W。详见 README 调优表。

### 5c. 自动降压 `--auto-uv`（0.5.1 新增）
ffgs 可以自动寻找降压值（与 FreeForGemPear 相同的调优器）：以 15 MHz 为步长提高每张 NVIDIA 显卡的核心 V/F 偏移，
逐步校验，最终保留最后一个通过的步长再减去一步作为余量。

    sudo ./ffgs --wallet <地址>.<矿机名> --lock-cclock 1400 --lock-mclock 810 --auto-uv

- **需要锁定核心频率**（`--lock-cclock` 或 HiveOS 超频配置中的锁定）：这时偏移越高 = 同频率下电压越低。仅 NVIDIA，需要 root / 管理员权限。
- **首次启动：** 在起始偏移上预热校验 2 分钟，之后每步 30 秒直到 `--uv-max`，再确认 2 分钟；所有显卡同时进行，完成后才开始挖矿（约 10–15 分钟）。
  **之后的启动：** 校验 20 秒后直接使用保存的偏移。
- **校验**在独立进程中以满负载运行挖矿内核、使用固定测试任务：每次启动的候选数必须与基准完全一致（显卡哪怕算错一个哈希也会在几秒内暴露），
  每个保存的候选都在 CPU 上重新计算。显卡崩溃或卡死只会结束该进程。
- **挖矿过程中：** 出现硬件错误（bad candidate）时回退 15 MHz（并保存）；每 6 小时复查 20 秒（期间该卡暂停）。若偏移被其他程序修改（HiveOS 超频），auto-uv 不再管理该卡。
- 结果保存在程序旁的 `ffgs-uv-results.txt`（HiveOS：`/hive-config/ffgs`，矿工更新后仍保留），按显卡、型号和驱动区分。若 ffgs 在某一步崩溃（kill、Xid、断电），
  下次启动会恢复偏移并在该步以下重新调优。退出时与 `--coffset` 一样恢复原偏移。
- 参数：`--uv-min MHz`（起点；默认当前偏移，否则 +120，RTX 40/50 至少 +200），`--uv-max MHz`（默认 +495），`--uv-step MHz`（15），
  `--uv-reset`（清除结果重新调优），`--uv-reval-hours H`（6，0 = 不复查）。Windows：启动脚本中 `AUTO_UV=1`。
- **RTX 3070 实测**（锁定 1400/810，起点 +250）：+385 以内全部通过，+400 失败（少一个候选）→ **+370**，功耗 73 W（+250 时 76 W）；Kavatar 上 5.04 GH/s、69 MH/W、0 拒绝。

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
