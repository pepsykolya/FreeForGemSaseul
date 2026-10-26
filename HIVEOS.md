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
{"name":"ffgs SL Kavatar","isFavorite":false,"items":[{"coin":"SL","pool_ssl":false,"pool_urls":["sl.kasplay.online:3333"],"dpool_ssl":false,"miner":"custom","miner_alt":"ffgs","miner_config":{"url":"sl.kasplay.online:3333","algo":"saseul","pass":"","miner":"ffgs","template":"%WAL%.%WORKER_NAME%","install_url":"https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.5.0/ffgs-0.5.0.tar.gz","user_config":""},"pool_geo":[]}]}
```

3. The imported sheet has no wallet (the format carries none): pick your `SL` wallet in the red-marked field, then
   **Create flight sheet** and apply it to the rig. `%WAL%` becomes your address and `%WORKER_NAME%` the rig's name in
   HiveOS, so the pool sees `<address>.<rig name>`.

The format is the one other custom miners publish for this button (plain JSON, not base64; same field names as in
e.g. https://github.com/derhier/yskar-hiveos and
https://unmineable.com/support/article/how-to-setup-pearl-pow-mining-on-hiveos). We have not imported this exact sheet on
a HiveOS account yet; if HiveOS refuses it, use the manual way below — the result is the same.

### Flight sheet: manual way

1. **Wallets** → add a wallet as above.
2. **Flight Sheets** → new flight sheet: Coin `SL`, Wallet: yours, Pool: *Configure in miner*, Miner: **Custom** →
   *Setup Miner Config*:

| Field | Value |
|---|---|
| Miner name | `ffgs` (filled in automatically from the URL) |
| Installation URL | `https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.5.0/ffgs-0.5.0.tar.gz` |
| Hash algorithm | `saseul` |
| Wallet and worker template | `%WAL%.%WORKER_NAME%` |
| Pool URL | `sl.kasplay.online:3333` (or another pool from the table) |
| Pass | empty |
| Extra config arguments | empty, or e.g. `--eco` / `--devices 0,2` / `--backend amd` |

3. Apply the flight sheet. The miner log: `miner log` in the HiveOS shell, or `/var/log/miner/ffgs/ffgs.log`
   (mixed rigs: also `/var/log/miner/ffgs/ffgs-amd.log`).

The dashboard shows the hashrate per GPU (GH/s), temperatures, fans and accepted/rejected shares.

### NVIDIA overclocking

SL is pure compute — set the **memory clock to the minimum** (e.g. `-1000` / `405`), lock the core (RTX 3070:
1400 MHz for the best H/W, up to 1560 MHz for more hashrate) and use `--eco` on undervolted rigs. Normally set the
clocks in the HiveOS **Overclocking** profile. Alternatively ffgs can set them itself: put e.g.
`--lock-cclock 1400 --lock-mclock 810 --coffset 325` into *Extra config arguments* (HiveOS runs miners as root; a comma
list sets one value per GPU). **Use one or the other per card, not both**: when the miner stops, ffgs resets the locks
it set, which also removes the HiveOS lock until HiveOS applies its OC again. For cards that should keep the HiveOS OC,
leave their entry empty (`--lock-cclock 1400,,1400`) or do not use the ffgs options.

**Auto undervolt (0.5.1):** add `--auto-uv` to *Extra config arguments* (with the core clock locked by the HiveOS OC
profile or `--lock-cclock`; leave the OC profile's core offset as the starting point). The first start tunes
~10–15 min before mining, the result is kept in `/hive-config/ffgs` and reused (20 s check) after reboots and miner
updates. Example: `--referrer <your address> --lock-cclock 1400 --lock-mclock 810 --auto-uv`. MANUAL 5c.

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

Формат тот же, что публикуют другие custom-майнеры для этой кнопки (обычный JSON, не base64). Именно этот лист на
аккаунте HiveOS ещё не импортировали; если HiveOS его не примет — ручной способ ниже, результат тот же.

### Полётный лист: вручную

Coin `SL`, кошелёк ваш, Pool: *Configure in miner*, Miner: **Custom** → *Setup Miner Config* — значения из таблицы в
английском разделе (Pool URL `sl.kasplay.online:3333`, шаблон `%WAL%.%WORKER_NAME%`, алгоритм `saseul`, Pass и Extra
config arguments пустые). Лог майнера: `miner log` или `/var/log/miner/ffgs/ffgs.log` (смешанный риг — ещё
`ffgs-amd.log`).

### Разгон NVIDIA

SL — чистые вычисления, **память в минимум** (`-1000` / `405`), ядро зафиксировать (RTX 3070: 1400 МГц — лучший H/W,
до 1560 МГц — больше хешрейта), на андервольте — `--eco`. Обычно частоты задают в OC-профиле HiveOS. Либо ffgs
выставляет их сам: `--lock-cclock 1400 --lock-mclock 810 --coffset 325` в *Extra config arguments*. **На одной карте —
что-то одно**: при остановке майнера ffgs снимает свои фиксации, а с ними и фиксацию HiveOS.

**Автоподбор андервольта (0.5.1):** добавьте `--auto-uv` в *Extra config arguments* (ядро зафиксировано OC-профилем
HiveOS или `--lock-cclock`; оффсет ядра из OC-профиля станет стартовой точкой). Первый запуск подбирает ~10–15 мин до
начала майнинга, результат хранится в `/hive-config/ffgs` и используется снова (проверка 20 с) после перезагрузок и
обновлений майнера. Пример: `--referrer <ваш адрес> --lock-cclock 1400 --lock-mclock 810 --auto-uv`. MANUAL 5c.

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
