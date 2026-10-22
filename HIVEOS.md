# FreeForGemSaseul (ffgs) on HiveOS

[English](#english) · [Русский](#русский)

## English

1. **Wallets** → add a wallet: coin `SL` (create the coin name if HiveOS does not know it), your SASEUL address (44 hex).
2. **Flight sheets** → new flight sheet: Coin `SL`, Wallet: yours, Pool: *Configure in miner*, Miner: **Custom** →
   *Setup Miner Config*:

| Field | Value |
|---|---|
| Miner name | `ffgs` (filled in automatically from the URL) |
| Installation URL | `https://github.com/pepsykolya/FreeForGemSaseul/releases/download/v0.3.0/ffgs-0.3.0.tar.gz` |
| Hash algorithm | `saseul` |
| Wallet and worker template | `%WAL%.%WORKER_NAME%` |
| Pool URL | rabbitminer: `nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931`; saseulmine: `https://pool.saseulmine.com` |
| Extra config arguments | empty, or e.g. `--eco` / `--devices 0,2` / `--referrer none` |

saseulmine: the ffgs dev wallet is sent as your referrer by default (the pool says your share is unchanged with or
without a referrer); add `--referrer none` to the extra arguments to turn that off. The rig's client key is kept in
`/hive/miners/custom/ffgs/ffgs-client.key`.

3. Apply the flight sheet. The miner log: `miner log` in the HiveOS shell, or `/var/log/miner/ffgs/ffgs.log`.
4. Overclocking: SL is pure compute — set the **memory clock to the minimum** (e.g. `-1000` / `405`), lock the core
   (RTX 3070: 1400 MHz for the best H/W, up to 1560 MHz for more hashrate) and use `--eco` on undervolted rigs.

The dashboard shows the hashrate per GPU (GH/s), temperatures, fans and accepted/rejected shares.

## Русский

1. **Wallets** → новый кошелёк: монета `SL` (если HiveOS её не знает — создайте), ваш адрес SASEUL (44 hex).
2. **Flight sheets** → новый полётный лист: Coin `SL`, кошелёк ваш, Pool: *Configure in miner*, Miner: **Custom** →
   *Setup Miner Config* — значения из таблицы выше (Pool URL для saseulmine: `https://pool.saseulmine.com`).
   saseulmine: по умолчанию реферером указан кошелёк разработчика ffgs (по словам пула, ваша доля от этого не меняется);
   отключить — `--referrer none` в Extra config arguments.
3. Примените лист. Лог майнера: `miner log` в консоли HiveOS или `/var/log/miner/ffgs/ffgs.log`.
4. Разгон: SL — чистые вычисления, **память в минимум** (`-1000` / `405`), ядро зафиксировать
   (RTX 3070: 1400 МГц — лучший H/W, до 1560 МГц — больше хешрейта), на андервольте — `--eco`.

В панели HiveOS видны хешрейт по картам (GH/s), температуры, вентиляторы и принятые/отклонённые шары.
