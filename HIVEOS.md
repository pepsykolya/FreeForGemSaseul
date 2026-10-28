# FreeForGemSaseul (ffgs) on HiveOS

[English](#english) · [Русский](#русский)

### Referral (fee 2% = 1% + 1%)
Put `--referrer ADDRESS` into *Extra config arguments*: that wallet (whoever recommended ffgs to you) gets the 1% referral
minute. **Your own wallet there = total fee 1%.** Without it the referral minute goes to the ffgs dev. MANUAL §6.

## English

### Pools

| Pool | Pool URL in the flight sheet | Notes |
|---|---|---|
| **Kavatar SL Pool** (recommended), https://kavatar.kasplay.online | `sl.kasplay.online:3333` | PPLNS, 2% fee, payouts from 10 SL every 6 h; login `<SL address>.<worker>`, no password |
| rabbitminer | `nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931` | several URLs = failover |
| saseulmine | `https://pool.saseulmine.com` | no worker names; your `--referrer` is also sent as the saseulmine referrer |
| saseulpool | `nats://nats.saseulpool.com:4222` | share counters = shares delivered (see [MANUAL 6b](MANUAL.md#6b-saseulpoolcom-details)) |

### Flight sheet: quick way (Import from Clipboard)

1. **Wallets** → add a wallet: coin `SL` (type the name if HiveOS does not know the coin), your SASEUL address
   (44 hex, the bare address, without a worker name).
2. **Flight Sheets** → **Import from Clipboard** (below the flight sheet name) and paste:

```json
{"name":"ffgs SL Kavatar","isFavorite":false,"items":[{"coin":"SL","pool_ssl":false,"pool_urls":["sl.kasplay.online:3333"],"dpool_ssl":false,"miner":"custom","miner_alt":"ffgs","miner_config":{"url":"sl.kasplay.online:3333","algo":"saseul","pass":"","miner":"ffgs","template":"%WAL%.%WORKER_NAME%","install_url":"https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.5.4/ffgs-0.5.4.tar.gz","user_config":""},"pool_geo":[]}]}
```

3. The imported sheet has no wallet (the format carries none): pick your `SL` wallet in the red-marked field, then
   **Create flight sheet** and apply it to the rig. `%WAL%` becomes your address and `%WORKER_NAME%` the rig's name in
   HiveOS, so the pool sees `<address>.<rig name>`.

The format is the plain JSON (not base64) that HiveOS's *Import from Clipboard* takes. If HiveOS refuses it, use the
manual way below — the result is the same.

### Flight sheet: manual way

1. **Wallets** → add a wallet as above.
2. **Flight Sheets** → new flight sheet: Coin `SL`, Wallet: yours, Pool: *Configure in miner*, Miner: **Custom** →
   *Setup Miner Config*:

| Field | Value |
|---|---|
| Miner name | `ffgs` (filled in automatically from the URL) |
| Installation URL | `https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.5.4/ffgs-0.5.4.tar.gz` |
| Hash algorithm | `saseul` |
| Wallet and worker template | `%WAL%.%WORKER_NAME%` |
| Pool URL | `sl.kasplay.online:3333` (or another pool from the table) |
| Pass | empty |
| Extra config arguments | empty, or e.g. `--eco` / `--devices 0,2` / `--backend amd` |

3. Apply the flight sheet. The miner log: `miner log` in the HiveOS shell, or `/var/log/miner/ffgs/ffgs.log`
   (mixed rigs: also `/var/log/miner/ffgs/ffgs-amd.log`).

The dashboard shows the hashrate per GPU (GH/s), temperatures, fans and accepted/rejected shares.

### NVIDIA overclocking

SL is pure compute: lock the **memory at 810** (CMP 50HX: 5001) and lock the core. **Recommended (measured, MANUAL 5):**

| GPU | Best MH/W | Balance | Max hashrate |
|---|---|---|---|
| RTX 3070 | **1500** + `--auto-uv`: 5.62 GH/s, 76 W, 73.9 MH/W | 1700 + `--auto-uv`: 6.40 GH/s, 106 W | 1800 + `--auto-uv`: 6.74 GH/s, 121 W |
| RTX 3080 Ti | **1600** + `--auto-uv`: 10.32 GH/s, 180 W, 57.4 MH/W | 1700 + `--auto-uv`: 10.98 GH/s, 212 W | core not locked: 11.54 GH/s, 332 W |

The simplest way: let ffgs set the clocks and find the undervolt — *Extra config arguments*
`--lock-cclock 1500 --lock-mclock 810 --auto-uv` (RTX 3070) with **no core lock, core offset or memory clock for these
cards in the HiveOS OC profile** (HiveOS runs miners as root; a comma list sets one value per GPU, e.g.
`--lock-cclock 1500,1600` for a 3070 + 3080 Ti rig), or `--lock-mclock 810 --auto-lock` to let ffgs choose the lock
per card. **If the extra config arguments set clocks, ffgs keeps them even if the HiveOS OC profile has other
values** (0.5.4: HiveOS may apply its OC after the miner started; ffgs then sets its own lock / offset / power limit
again within 10 s and logs it in orange, `... by another tool (HiveOS OC profile?) - ffgs's lock 1500 MHz wins,
re-applied`). You do not have to clear the OC profile, but its clock values are not used on those cards. When the miner
stops, ffgs resets the locks it set and puts back the offsets it found at its start; HiveOS applies its OC again at the
next start. For cards that should keep the HiveOS OC, leave their entry empty or `x` (`--lock-cclock 1500,x,1500`) or
do not use the ffgs options. If you keep the clocks in the OC profile instead,
use the same values (core lock 1500, memory 810) and add only `--auto-uv`.

**Updating from 0.5.2 (or older) with an undervolt:** 0.5.2 resets the clocks while the GPUs still mine; stopping it at
a high offset can cause an Xid / a hung GPU (seen once on a 3070 at the switch: that card stayed "busy or unavailable"
until a reboot). That last stop is still done by 0.5.2 itself; if a card then shows `[unavailable]` or does not mine,
reboot the rig (0.5.4 keeps its undervolt profiles and does not lower them for it).

**Auto undervolt (0.5.1):** add `--auto-uv` to *Extra config arguments* (with the core clock locked by the HiveOS OC
profile or `--lock-cclock`; leave the OC profile's core offset as the starting point). Since 0.5.3 only the card being
tuned (0.5.4: typically ~3.5–11.5 min) waits, the other cards mine meanwhile; the result is kept per core clock lock in `/hive-config/ffgs`
and applied at once after reboots and miner updates (a 20 s check of that card when it is older than
`--uv-reval-hours`). `--uv-reset` forgets the profile of the current lock, `--uv-reset-all` every profile of this miner's cards (0.5.4: the
profiles of other cards in `/hive-config/ffgs` stay). Example:
`--referrer <your address> --lock-cclock 1500 --lock-mclock 810 --auto-uv`. MANUAL 5c.

**Efficiency in the dashboard (0.5.3):** the miner version column shows the rig's MH/W next to the version
(`0.5.4 64.7 MH/W`), from the total hashrate and the NVIDIA board power ffgs reads (not shown when a process has no power
reading, e.g. AMD).

**GPU faults (0.5.3):** a card that faults (Xid) is named in the log (`faults: GPU4 ... FAILED: Xid 43`), and ffgs
restarts itself instead of leaving it to HiveOS; with `--auto-uv` that card comes back 30 MHz lower, without it a card
that keeps crashing is left out for an hour while the others mine (MANUAL 5d). The record is `/hive-config/ffgs/ffgs-gpu-faults.txt`.

**CMP cards:** `--lock-mclock 810` is not supported on CMP 50HX (its memory clocks are 7001 / 5001 / 405); since 0.5.3
ffgs then locks 5001, the lowest supported clock above 810, and says so in the log.

**New in 0.5.4 (Extra config arguments):**
- **Several lines** in *Extra config arguments* are fine since 0.5.4 (they are joined into one line; before, everything
  after the first line was dropped, e.g. `--referrer`).
- **Lists without spaces:** `--lock-cclock 1500,1600 --coffset 325,x` (HiveOS splits the arguments at spaces;
  `1500, 1600` would become two arguments). A shorter list repeats its last value, as in the HiveOS OC profile, but an
  offset of `0` means "leave alone" in ffgs; write `=0` to set exactly 0. `--dry-run` in the HiveOS shell
  (`/hive/miners/custom/ffgs/ffgs --lock-cclock ... --dry-run`) shows what would be set per card. MANUAL 5a.
- **`--auto-lock`** (e.g. `--auto-lock --lock-mclock 810`): ffgs chooses the core lock per card. Leave the **core clock
  lock empty in the HiveOS OC profile** (ffgs sets the lock and resets it on exit). A card with its own `--lock-cclock`
  value keeps it and is not swept. The result is kept in `/hive-config/ffgs/ffgs-autolock.txt`. MANUAL 5e.
- **`--api 4068`**: h-stats.sh then reads hashrates, uptime, shares and watts from the local API (log parsing stays the
  fallback). On a mixed NVIDIA + AMD rig `h-run.sh` gives the AMD process `--api 4069` (PORT+1, the host is kept) and
  h-stats reads both. MANUAL 3d.
- **`--temp-limit`** is meant for laptops / mobile GPUs; desktop rigs keep their temperatures with fans (HiveOS
  autofan) and do not need it. MANUAL 5f.
- The GPU stall watchdog (MANUAL 5g) and the pool failback / no-accepted-shares watchdog (MANUAL 3c, with several Pool
  URLs) are on by default; `--no-watchdog`, `--failback-minutes 0`, `--noshare-minutes 0` turn them off.
  `--no-update-check` turns off the new-version log line.

### AMD rigs

- **Same package, same flight sheet.** Without NVIDIA GPUs ffgs uses its AMD backend (OpenCL). It needs the AMD OpenCL
  runtime of the HiveOS AMD driver (`libOpenCL.so.1` + an AMD ICD in `/etc/OpenCL/vendors`); ffgs loads it at run time,
  there is no CUDA requirement. At start the miner log lists the cards (`AMD0: ... bus 03`). If it says *no usable
  AMD OpenCL device*, the log also shows the OpenCL loader and ICDs found; check the driver with `amd-info` and
  reinstall OpenCL with `amd-ocl-install <version>`, then `miner restart`.
- GPU numbers (`--devices`) = AMD cards in PCI bus order, as on the HiveOS dashboard (integrated GPUs are skipped).
- **Mixed NVIDIA + AMD rigs**: the package starts two ffgs processes (CUDA and AMD) with the same pool and worker, and
  the dashboard shows all cards. With `--backend cuda|amd` or `--devices` in *Extra config arguments* there is only one
  process (that backend / those GPUs).
- The ffgs clock options are NVIDIA only: set AMD clocks in the HiveOS OC profile (below). Temperatures and fans of
  AMD GPUs come from HiveOS gpu-stats.
- Tested: the OpenCL backend and this package end-to-end (h-config → h-run → h-stats, Kavatar pool, shares accepted)
  on Linux with NVIDIA's OpenCL, and the AMD kernel on an RX 6800 XT under Windows. **Not yet run on a HiveOS AMD rig.**

#### AMD OC for SASEUL

SASEUL is core-bound (SHA-256-like integer work, no memory traffic): hashrate ∝ compute units × core clock, so the
goal is the core clock you want at the **lowest stable core voltage**; memory can stay low.

What the HiveOS AMD OC fields do (from the HiveOS scripts
[`amd-oc`, `amd-oc.navi.sh`, `amd-oc.polaris.sh`, `amd-oc.vega.sh`](https://github.com/minershive/hiveos-linux/tree/master/hive/sbin)
— public copy last updated 2021, current HiveOS may differ — and the
[kernel amdgpu docs](https://docs.kernel.org/gpu/amdgpu/thermal.html)):

| Field | What it does | Generations | SASEUL |
|---|---|---|---|
| Core clock (MHz) | max core clock (`pp_od_clk_voltage` `s 1`) | all | the speed knob: RX 6800 XT 2200–2300 |
| Core voltage, VDD (mV) | absolute mV, not an offset. RDNA1 / Radeon VII: V/F point (`vc`); RDNA2: PowerPlay table (HiveOS sets `MinVoltageGfx` 600 mV); Polaris: voltage table | all | the efficiency knob: lowest stable |
| Memory clock (MHz) | max memory clock (`m 1`). **RDNA2: half the Windows number** (1000 here = 2000 in Adrenalin) | all | not needed by SL; stock or lower |
| Core state / Memory state (MDPM) | DPM state index | Polaris, Vega only (not read for RDNA) | RDNA: empty |
| VDDCI (mV) | memory controller voltage (PowerPlay `MemVddciVoltage`), accepted 650–850 | RDNA1/RDNA2 | 750 (saves a few W) |
| MVDD (mV) | memory voltage (`MemMvddVoltage`), accepted 1200–1350 | RDNA1/RDNA2 | 1250 |
| SoC VDD max (mV) | SoC voltage cap (`MaxVoltageSoc`), accepted 650–1200 | RDNA1/RDNA2 | empty first; try 900 |
| SoC frequency | SoC clock table; commented out for RDNA in the public script | Vega (RDNA: no effect seen) | empty |
| Power limit (W) | `power1_cap` | all | 0 / empty, or a cap ~10% above the measured draw |
| Aggressive undervolting | one voltage for all DPM states | Polaris/Vega path only | RDNA: ignored |
| Fan / target temp | fan control | all | as usual |

Values outside the accepted ranges are silently ignored by HiveOS — if the dashboard voltage does not change, check the
range.

Starting values (enter per card in the OC profile; then lower the voltage in 12–25 mV steps):

| Card | Core MHz | VDD mV | Mem | VDDCI / MVDD | Expected | Status |
|---|---|---|---|---|---|---|
| RX 6800 XT | 2300 (or 2200) | 881 | stock (1000) | 750 / 1250 | 9.69 GH/s at ~164 W ASIC (2200: 9.27 GH/s, 157 W) | **our measurement, Windows ADLX** (core clock/voltage; VDDCI/MVDD there untested, values from the HiveOS ranges); stock 2324/1150 = 9.86 GH/s at 238 W; 2400/881 **fails** (hardware errors) |
| RX 6800 XT | 2200–2300 | below 881 (e.g. 850, 825…) | stock | 750 / 1250 | less power, same GH/s while stable | **untested**: HiveOS sets the RDNA2 floor to 600 mV (script) and users report Linux values below the Windows floor — but also that the applied voltage can be higher than set ([forum](https://hiveon.com/forum/t/6000-series-undervolt-enabled-in-0-6-205-210715/43390)) |
| RX 6800 | 2200–2300 | 881, then lower | stock | 750 / 1250 | ≈ 60/72 of the 6800 XT ≈ 8.1 GH/s at 2300 | **estimate** (CU scaling), untested |
| RX 6900 XT | 2200–2300 | 881, then lower | stock | 750 / 1250 | ≈ 80/72 ≈ 10.8 GH/s at 2300 | **estimate**, untested |
| RX 6700 XT / 6600 XT / 6600 | 2300–2400 | 900, then lower | stock | 750 / 1250 | ≈ 40 / 32 / 28 CU × 0.06 GH/s per CU·GHz | **estimate**, untested (gfx1031/1032; kernel built for any RDNA) |
| Polaris RX 470–590, Vega 56/64, RX 5700 (XT) | stock clock, then undervolt | — | minimum / lowest MDPM | — | — | **untested** (portable OpenCL kernel; on GCN use Core state + VDD, Aggressive undervolting, lowest Memory state) |

Procedure (safe): change one card at a time; after each step run `miner stop`, then in the HiveOS shell
`/hive/miners/custom/ffgs/ffgs --bench 60 --devices N` (N = the card's ffgs number; it re-checks the candidates on the
CPU and must show `hardware errors 0`), then `miner start`. Keep one step (≥ 25 mV or 50 MHz) of margin above the first
failing point: on our 6800 XT at 881 mV, 2350 MHz still passed and 2400 MHz produced garbage at once. Hardware errors in
the miner log (`hardware error`) during mining mean the same: raise the voltage or lower the clock.

### Solo

Own SASEUL node + the solo proxy (MANUAL.md section 8): Pool URL `NODE_IP:19310`, Wallet and worker template
`%WAL%.%WORKER_NAME%`, Extra config arguments `--pass YOUR_SL_TOKEN`. The reward goes to the proxy's
`addresses.txt`, not to the flight sheet wallet.

## Русский

### Пулы

| Пул | Pool URL в полётном листе | Заметки |
|---|---|---|
| **Kavatar SL Pool** (рекомендуем), https://kavatar.kasplay.online | `sl.kasplay.online:3333` | PPLNS, комиссия 2%, выплаты от 10 SL каждые 6 ч; логин `<адрес SL>.<воркер>`, без пароля |
| rabbitminer | `nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931` | несколько адресов = резерв |
| saseulmine | `https://pool.saseulmine.com` | без имён воркеров; реферер по умолчанию — кошелёк разработчика ffgs (`--referrer none` — отключить) |
| saseulpool | `nats://nats.saseulpool.com:4222` | счётчики шар = шары, доставленные на сервер пула (MANUAL 6b) |

### Полётный лист: быстрый способ (Import from Clipboard)

1. **Wallets** → новый кошелёк: монета `SL` (если HiveOS её не знает — впишите имя), ваш адрес SASEUL (44 hex, только
   адрес, без имени воркера).
2. **Flight Sheets** → **Import from Clipboard** (под полем имени листа) и вставьте JSON из английского раздела выше.
3. В импортированном листе нет кошелька (формат его не содержит): выберите свой кошелёк `SL` в подсвеченном красным поле,
   **Create flight sheet** и примените лист к ригу. Пул увидит `<адрес>.<имя рига в HiveOS>`.

Формат — обычный JSON (не base64), который принимает *Import from Clipboard* в HiveOS. Если HiveOS его не примет —
ручной способ ниже, результат тот же.

### Полётный лист: вручную

Coin `SL`, кошелёк ваш, Pool: *Configure in miner*, Miner: **Custom** → *Setup Miner Config* — значения из таблицы в
английском разделе (Pool URL `sl.kasplay.online:3333`, шаблон `%WAL%.%WORKER_NAME%`, алгоритм `saseul`, Pass и Extra
config arguments пустые). Лог майнера: `miner log` или `/var/log/miner/ffgs/ffgs.log` (смешанный риг — ещё
`ffgs-amd.log`).

### Разгон NVIDIA

SL — чистые вычисления: **память фиксировать на 810** (CMP 50HX: 5001), ядро зафиксировать. **Рекомендуем (замеры,
MANUAL 5):**

| Карта | Лучший MH/W | Баланс | Максимум хешрейта |
|---|---|---|---|
| RTX 3070 | **1500** + `--auto-uv`: 5,62 GH/s, 76 Вт, 73,9 MH/W | 1700 + `--auto-uv`: 6,40 GH/s, 106 Вт | 1800 + `--auto-uv`: 6,74 GH/s, 121 Вт |
| RTX 3080 Ti | **1600** + `--auto-uv`: 10,32 GH/s, 180 Вт, 57,4 MH/W | 1700 + `--auto-uv`: 10,98 GH/s, 212 Вт | без фиксации ядра: 11,54 GH/s, 332 Вт |

Проще всего — пусть ffgs выставит частоты и подберёт андервольт сам: *Extra config arguments*
`--lock-cclock 1500 --lock-mclock 810 --auto-uv` (RTX 3070), а **в OC-профиле HiveOS для этих карт — без фиксации ядра,
оффсета ядра и частоты памяти** (список через запятую — значение на каждую карту, например `--lock-cclock 1500,1600` для
рига 3070 + 3080 Ti), либо `--lock-mclock 810 --auto-lock` — ffgs сам выберет фиксацию каждой карты. **Если частоты заданы
в Extra config arguments, ffgs держит их, даже если в OC-профиле HiveOS другие значения** (0.5.4: HiveOS может
применить OC уже после старта майнера; ffgs тогда в течение 10 с ставит свою фиксацию / оффсет / лимит мощности снова
и пишет оранжевую строку `... by another tool (HiveOS OC profile?) - ffgs's lock 1500 MHz wins, re-applied`). Очищать
OC-профиль не обязательно, но его частоты на этих картах не действуют. При остановке майнера ffgs снимает свои фиксации
и возвращает оффсеты, которые застал при старте; HiveOS снова применит OC при следующем запуске. Картам, которые должны
остаться на OC HiveOS, оставьте пустое значение или `x` (`--lock-cclock 1500,x,1500`) либо не задавайте опции ffgs. Если частоты остаются в
OC-профиле — те же значения (ядро 1500, память 810) и только `--auto-uv`.

**Обновление с 0.5.2 (и старше) с андервольтом:** 0.5.2 сбрасывает частоты, пока карты ещё майнят; остановка на высоком
оффсете может дать Xid / зависшую карту (один раз видели на 3070 при переходе: карта осталась «busy or unavailable» до
перезагрузки). Эту последнюю остановку делает ещё сам 0.5.2; если после неё карта показывает `[unavailable]` или не
майнит — перезагрузите риг (0.5.4 сохраняет свои профили андервольта и не снижает их из-за этого).

**Автоподбор андервольта (0.5.1):** добавьте `--auto-uv` в *Extra config arguments* (ядро зафиксировано OC-профилем
HiveOS или `--lock-cclock`; оффсет ядра из OC-профиля станет стартовой точкой). С 0.5.3 ждёт только подбираемая карта
(0.5.4: обычно ~3,5–11,5 мин), остальные в это время майнят; результат хранится по фиксации частоты ядра в `/hive-config/ffgs` и
применяется сразу после перезагрузок и обновлений майнера (проверка этой карты 20 с, если он старше `--uv-reval-hours`).
`--uv-reset` забывает профиль текущей фиксации, `--uv-reset-all` — все профили карт этого майнера (0.5.4: профили других
карт в `/hive-config/ffgs` остаются). Пример:
`--referrer <ваш адрес> --lock-cclock 1500 --lock-mclock 810 --auto-uv`. MANUAL 5c.

**Эффективность в панели (0.5.3):** в колонке версии майнера рядом с версией показывается MH/W рига (`0.5.4 64.7 MH/W`)
— из общего хешрейта и мощности карт NVIDIA, которую читает ffgs (не показывается, если у процесса нет данных о
мощности, например AMD).

**Сбои GPU (0.5.3):** карта со сбоем (Xid) называется в логе (`faults: GPU4 ... FAILED: Xid 43`), и ffgs перезапускает
себя сам, а не оставляет это HiveOS; с `--auto-uv` карта возвращается на 30 МГц ниже, без него карта, которая падает
снова и снова, исключается на час, остальные майнят (MANUAL 5d). Запись — `/hive-config/ffgs/ffgs-gpu-faults.txt`.

**Карты CMP:** `--lock-mclock 810` на CMP 50HX не поддерживается (её частоты памяти 7001 / 5001 / 405); с 0.5.3 ffgs
тогда фиксирует 5001 — наименьшую поддерживаемую выше 810 — и пишет об этом в лог.

**Новое в 0.5.4 (Extra config arguments):**
- **Несколько строк** в *Extra config arguments* с 0.5.4 допустимы (склеиваются в одну; раньше всё после первой строки
  терялось, например `--referrer`).
- **Списки без пробелов:** `--lock-cclock 1500,1600 --coffset 325,x` (HiveOS делит аргументы по пробелам; `1500, 1600`
  станет двумя аргументами). Короткий список повторяет последнее значение, как в OC-профиле HiveOS, но оффсет `0` в ffgs
  значит «не трогать»; ровно 0 — `=0`. `--dry-run` в консоли HiveOS (`/hive/miners/custom/ffgs/ffgs --lock-cclock ...
  --dry-run`) покажет, что будет выставлено на каждой карте. MANUAL 5a.
- **`--auto-lock`** (например `--auto-lock --lock-mclock 810`): ffgs сам выбирает фиксацию ядра каждой карты.
  **Фиксацию ядра в OC-профиле HiveOS оставьте пустой** (ffgs ставит фиксацию и сбрасывает её на выходе). Карта со
  своим значением `--lock-cclock` сохраняет его и не перебирается. Результат — `/hive-config/ffgs/ffgs-autolock.txt`.
  MANUAL 5e.
- **`--api 4068`**: h-stats.sh берёт хешрейты, аптайм, шары и ватты из локального API (разбор лога остаётся запасным).
  На смешанном NVIDIA + AMD риге `h-run.sh` даёт AMD-процессу `--api 4069` (ПОРТ+1, хост тот же), h-stats читает оба.
  MANUAL 3d.
- **`--temp-limit`** — для ноутбуков / мобильных GPU; десктопные риги держат температуру вентиляторами (HiveOS
  autofan), им это не нужно. MANUAL 5f.
- Сторож зависания GPU (MANUAL 5g) и возврат на основной пул / сторож «нет принятых шар» (MANUAL 3c, при нескольких
  Pool URL) включены по умолчанию; `--no-watchdog`, `--failback-minutes 0`, `--noshare-minutes 0` их выключают.
  `--no-update-check` выключает строку о новой версии в логе.

### Риги AMD

- Тот же пакет и тот же лист. Без карт NVIDIA ffgs работает через OpenCL (нужен OpenCL-рантайм драйвера AMD HiveOS:
  `libOpenCL.so.1` + ICD AMD в `/etc/OpenCL/vendors`; CUDA не нужна). В начале лога — список карт (`AMD0: ... bus 03`).
  Если там *no usable AMD OpenCL device* — в логе видно, какие загрузчик и ICD найдены; проверьте драйвер `amd-info`,
  переустановите OpenCL `amd-ocl-install <версия>`, затем `miner restart`.
- Номера карт (`--devices`) — карты AMD по порядку PCI-шины, как в панели HiveOS (встроенная графика пропускается).
- **Смешанный риг NVIDIA + AMD**: пакет запускает два процесса ffgs (CUDA и AMD) с тем же пулом и воркером, в панели
  видны все карты. С `--backend cuda|amd` или `--devices` — один процесс.
- Частоты AMD — только в OC-профиле HiveOS. Проверено: OpenCL-бэкенд и пакет целиком (h-config → h-run → h-stats,
  пул Kavatar, шары приняты) на Linux через OpenCL NVIDIA, ядро AMD — на RX 6800 XT под Windows. **На HiveOS-риге с AMD
  ещё не запускали.**

#### Разгон AMD для SASEUL

SASEUL упирается в ядро: хешрейт ∝ число CU × частота ядра. Цель — нужная частота ядра при **минимальном стабильном
напряжении**, память можно не трогать или опустить. Поля OC-профиля HiveOS (по скриптам `amd-oc*` HiveOS, см. таблицу
в английском разделе):

- **Core clock** — частота ядра (главный регулятор хешрейта); **Core voltage (VDD)** — напряжение ядра в мВ (абсолютное,
  не смещение), главный регулятор эффективности; на RDNA2 HiveOS опускает нижний предел таблицы PowerPlay до 600 мВ.
- **Memory clock** — на RDNA2 вдвое меньше числа из Windows (1000 = 2000 в Adrenalin); SL память не нужна.
- **Memory state (MDPM) / Core state / Aggressive undervolting** — только Polaris/Vega; на RX 6000 оставить пустыми.
- **VDDCI** (650–850) 750, **MVDD** (1200–1350) 1250 — RDNA1/RDNA2; **SoC VDD max** (650–1200) — сначала пусто, потом
  900; **SoC frequency** — на RDNA в публичном скрипте не применяется, пусто. Значения вне диапазона HiveOS молча
  игнорирует.

Стартовые значения: **RX 6800 XT 2300 МГц / 881 мВ** (9,69 GH/s, ~164 Вт ASIC; 2200/881 — 9,27 GH/s, 157 Вт; сток
2324/1150 — 9,86 GH/s, 238 Вт; 2400/881 — **сбой**) — наши замеры под Windows (ADLX, его минимум — 881 мВ). Ниже 881 мВ
под HiveOS, по сообщениям пользователей, напряжение опускается, но выставленное может отличаться от фактического — **нами
не проверено**. RX 6800 / 6900 XT — те же частоты, ≈ 8,1 / 10,8 GH/s при 2300 (оценка по числу CU); RX 6700 XT / 6600
(XT) — 2300–2400 МГц, 900 мВ и ниже (оценка, не проверено); Polaris/Vega/RX 5700 — не проверено.

Порядок: по одной карте; после каждого шага `miner stop`, `/hive/miners/custom/ffgs/ffgs --bench 60 --devices N` (должно
быть `hardware errors 0`), `miner start`. Оставляйте запас в один шаг (≥ 25 мВ или 50 МГц) от первой неудачной точки.
Строки `hardware error` в логе при майнинге — то же самое: поднять напряжение или снизить частоту.

### Соло

Своя нода SASEUL + соло-прокси (MANUAL.md раздел 8): Pool URL `IP_НОДЫ:19310`, шаблон `%WAL%.%WORKER_NAME%`, Extra
config arguments `--pass ВАШ_SL_TOKEN`. Награда идёт на адреса из `addresses.txt` прокси.
