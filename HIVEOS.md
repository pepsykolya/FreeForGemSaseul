# FreeForGemSaseul (ffgs) on HiveOS

[English](#english) · [Русский](#русский)

## English

1. **Wallets** → add a wallet: coin `SL` (create the coin name if HiveOS does not know it), your SASEUL address (44 hex).
2. **Flight sheets** → new flight sheet: Coin `SL`, Wallet: yours, Pool: *Configure in miner*, Miner: **Custom** →
   *Setup Miner Config*:

| Field | Value |
|---|---|
| Miner name | `ffgs` (filled in automatically from the URL) |
| Installation URL | `https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.4.0/ffgs-0.4.0.tar.gz` |
| Hash algorithm | `saseul` |
| Wallet and worker template | `%WAL%.%WORKER_NAME%` |
| Pool URL | rabbitminer: `nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931`; saseulmine: `https://pool.saseulmine.com`; saseulpool: `nats://nats.saseulpool.com:4222` |
| Extra config arguments | empty, or e.g. `--eco` / `--devices 0,2` / `--referrer none` |

saseulmine: the ffgs dev wallet is sent as your referrer by default (the pool says your share is unchanged with or
without a referrer); add `--referrer none` to the extra arguments to turn that off. The rig's client key is kept in
`/hive/miners/custom/ffgs/ffgs-client.key`.

saseulpool: the worker name from the template is shown on the pool's site; the pool gives no answer per share, so
the HiveOS share counters show shares *delivered* to the pool's server (what the pool credited: the `pool` line in the
miner log, see [MANUAL 6b](MANUAL.md#6b-saseulpoolcom-details)).

3. Apply the flight sheet. The miner log: `miner log` in the HiveOS shell, or `/var/log/miner/ffgs/ffgs.log`.
4. Overclocking: SL is pure compute — set the **memory clock to the minimum** (e.g. `-1000` / `405`), lock the core
   (RTX 3070: 1400 MHz for the best H/W, up to 1560 MHz for more hashrate) and use `--eco` on undervolted rigs.
   Normally set the clocks in the HiveOS **Overclocking** profile. Alternatively ffgs can set them itself (0.4.0):
   put e.g. `--lock-cclock 1400 --lock-mclock 810 --coffset 225` into *Extra config arguments* (HiveOS runs miners as
   root; a comma list sets one value per GPU). **Use one or the other per card, not both**: when the miner stops, ffgs
   resets the locks it set, which also removes the HiveOS lock until HiveOS applies its OC again. For cards that should
   keep the HiveOS OC, leave their entry empty (`--lock-cclock 1400,,1400`) or do not use the ffgs options.

The dashboard shows the hashrate per GPU (GH/s), temperatures, fans and accepted/rejected shares.

**AMD rigs** (0.4.0): the same package; ffgs picks the AMD (OpenCL) backend when there is no NVIDIA GPU (needs the
OpenCL runtime of the HiveOS AMD driver; not tested on a HiveOS AMD rig yet). Set AMD clocks in the HiveOS OC
profile — the ffgs clock options are NVIDIA only. Temperatures and fans of AMD GPUs come from HiveOS gpu-stats.

**Solo** (own SASEUL node + the solo proxy, see MANUAL.md section 8): Pool URL `NODE_IP:19310`, Wallet and worker
template `%WAL%.%WORKER_NAME%`, Extra config arguments `--pass YOUR_SL_TOKEN`. The reward goes to the proxy's
`addresses.txt`, not to the flight sheet wallet.

## Русский

1. **Wallets** → новый кошелёк: монета `SL` (если HiveOS её не знает — создайте), ваш адрес SASEUL (44 hex).
2. **Flight sheets** → новый полётный лист: Coin `SL`, кошелёк ваш, Pool: *Configure in miner*, Miner: **Custom** →
   *Setup Miner Config* — значения из таблицы выше (Pool URL для saseulmine: `https://pool.saseulmine.com`, для saseulpool:
   `nats://nats.saseulpool.com:4222`).
   saseulpool: пул не отвечает на отдельные шары, поэтому счётчики шар в HiveOS — это шары, *доставленные* на сервер пула
   (что пул засчитал — строка `pool` в логе майнера, см. MANUAL 6b).
   saseulmine: по умолчанию реферером указан кошелёк разработчика ffgs (по словам пула, ваша доля от этого не меняется);
   отключить — `--referrer none` в Extra config arguments.
3. Примените лист. Лог майнера: `miner log` в консоли HiveOS или `/var/log/miner/ffgs/ffgs.log`.
4. Разгон: SL — чистые вычисления, **память в минимум** (`-1000` / `405`), ядро зафиксировать
   (RTX 3070: 1400 МГц — лучший H/W, до 1560 МГц — больше хешрейта), на андервольте — `--eco`.
   Обычно частоты задают в OC-профиле HiveOS (**Overclocking**). Либо ffgs выставляет их сам (0.4.0): в *Extra config
   arguments*, например, `--lock-cclock 1400 --lock-mclock 810 --coffset 225` (HiveOS запускает майнер от root; список
   через запятую — по значению на карту). **На одной карте — что-то одно, не оба**: при остановке майнера ffgs снимает
   свои фиксации, а с ними и фиксацию HiveOS, пока HiveOS снова не применит OC. Картам, которые должны остаться на OC
   HiveOS, оставьте пустое значение (`--lock-cclock 1400,,1400`) или не используйте опции ffgs.

В панели HiveOS видны хешрейт по картам (GH/s), температуры, вентиляторы и принятые/отклонённые шары.

**Риги AMD** (0.4.0): тот же пакет; без карт NVIDIA ffgs сам выбирает бэкенд AMD (OpenCL; нужен OpenCL-рантайм
драйвера AMD в HiveOS; на HiveOS-риге с AMD ещё не проверено). Частоты AMD — в OC-профиле HiveOS, опции частот ffgs
только для NVIDIA. Температуры и вентиляторы карт AMD берутся из gpu-stats HiveOS.

**Соло** (своя нода SASEUL + соло-прокси, см. MANUAL.md раздел 8): Pool URL `IP_НОДЫ:19310`, Wallet and worker
template `%WAL%.%WORKER_NAME%`, Extra config arguments `--pass ВАШ_SL_TOKEN`. Награда идёт на адреса из
`addresses.txt` прокси, а не на кошелёк полётного листа.
