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

    ./ffgs --pool nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931 --wallet ADDRESS.WORKER

| Option | Meaning |
|---|---|
| `--pool HOST:PORT[,HOST:PORT…]` | pool list; the next one is used when a pool is unreachable |
| `--wallet ADDRESS[.WORKER]`, `--worker NAME` | payout address and worker name |
| `--devices 0,1,…` | GPUs to use, numbered as in `nvidia-smi` / HiveOS (default: all) |
| `--eco` | efficiency kernel (see 5) |
| `--blocks N`, `--threads N` | launch geometry (default: SM count × 64 blocks × 256 threads) |
| `--bench SECONDS` | hashrate of every selected GPU, no pool |
| `--selftest` | PoW check against a real mainnet block + GPU kernel against a CPU brute force |

Every 10 s the miner prints a status line:

    [  120s] GPU0 4.749 | GPU1 4.751 | total 9.500 GH/s | user sub 3 acc 3 rej 0 | fee sub 0 acc 0 rej 0

### 4. HiveOS
See [HIVEOS.md](HIVEOS.md).

### 5. Tuning
- The PoW is pure compute (no memory traffic): the **memory clock can be lowered** to the minimum to save power.
- **Default kernel** — highest hashrate per clock. Best when the card is power-limited or the core clock is locked high.
- **`--eco`** — about 12% fewer GH/s per clock but ~17% less power; best H/W on undervolted cards.
- RTX 3070 reference points: lock 1560 MHz → 4.78 GH/s at 108 W (default) / 4.21 GH/s at 90 W (`--eco`).

### 6. Dev fee
1.0%: 60 seconds every 100 minutes (first one after 15 minutes) the miner submits to the dev wallet on a second,
already logged-in pool connection, so there is no reconnect gap. Shares of that minute are shown as `fee …` in the status line.

### 7. Troubleshooting
| Message | Meaning / fix |
|---|---|
| `hardware error (bad candidate)` | the GPU returned a wrong hash: lower the core overclock |
| `share rejected: … stale` | the block changed while the share was in flight; occasional ones are normal |
| `cannot connect to any pool` | check the pool address / network; the miner retries with backoff |
| `self-test failed` | wrong results on this GPU/driver — the miner refuses to mine; report your GPU and driver |

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

    ./ffgs --pool nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931 --wallet АДРЕС.ВОРКЕР

| Опция | Что делает |
|---|---|
| `--pool ХОСТ:ПОРТ[,ХОСТ:ПОРТ…]` | список пулов; при недоступности берётся следующий |
| `--wallet АДРЕС[.ВОРКЕР]`, `--worker ИМЯ` | адрес выплат и имя воркера |
| `--devices 0,1,…` | какие GPU, нумерация как в `nvidia-smi` / HiveOS (по умолчанию все) |
| `--eco` | экономичное ядро (см. 5) |
| `--blocks N`, `--threads N` | геометрия запуска (по умолчанию SM × 64 блоков × 256 потоков) |
| `--bench СЕКУНДЫ` | замер хешрейта каждой GPU без пула |
| `--selftest` | проверка PoW на реальном блоке сети и ядра против перебора на CPU |

Каждые 10 с — строка статуса (хешрейт по картам, шары пользователя и комиссии).

### 4. HiveOS
См. [HIVEOS.md](HIVEOS.md).

### 5. Настройка
- PoW — чистые вычисления без работы с памятью: **частоту памяти можно опустить** до минимума, это экономит ватты.
- **Ядро по умолчанию** — максимум хешей на такт; лучше, когда карта упирается в лимит мощности или ядро зафиксировано высоко.
- **`--eco`** — примерно на 12% меньше GH/s на такт, но ~17% меньше мощность; лучший H/W на андервольте.
- RTX 3070: фиксация 1560 МГц → 4.78 GH/s при 108 Вт (по умолчанию) / 4.21 GH/s при 90 Вт (`--eco`).

### 6. Комиссия разработчика
1.0%: 60 секунд из каждых 100 минут (первый раз через 15 минут) майнер отправляет шары на кошелёк разработчика
по второму, заранее авторизованному соединению с пулом — без переподключений. Эти шары видны как `fee …` в строке статуса.

### 7. Если что-то не так
| Сообщение | Что значит / что делать |
|---|---|
| `hardware error (bad candidate)` | GPU посчитала неверный хеш — снизьте разгон ядра |
| `share rejected: … stale` | блок сменился, пока шара летела; единичные — норма |
| `cannot connect to any pool` | проверьте адрес пула / сеть; майнер переподключается сам |
| `self-test failed` | неверные результаты на этой GPU/драйвере — майнер не запускается; сообщите модель и драйвер |

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

    ./ffgs --pool nl.rabbitminer.cc:1931,fi.rabbitminer.cc:1931 --wallet 地址.矿工名

| 参数 | 说明 |
|---|---|
| `--pool 主机:端口[,主机:端口…]` | 矿池列表，不可用时自动切换到下一个 |
| `--wallet 地址[.矿工名]`、`--worker 名称` | 收款地址和矿工名 |
| `--devices 0,1,…` | 使用的 GPU，编号与 `nvidia-smi` / HiveOS 一致（默认全部） |
| `--eco` | 节能内核（见第 5 节） |
| `--bench 秒数` | 不连接矿池，测试每张显卡的算力 |
| `--selftest` | 用真实主网区块校验 PoW，并用 CPU 穷举校验 GPU 内核 |

### 4. HiveOS
见 [HIVEOS.md](HIVEOS.md)。

### 5. 调优
- 该 PoW 只做计算、不访问显存：**显存频率可以降到最低**以节省功耗。
- **默认内核**：每个时钟周期算力最高，适合功耗墙受限或核心频率锁定较高的情况。
- **`--eco`**：每时钟算力约低 12%，功耗约低 17%，降压显卡上能效最佳。
- RTX 3070 参考：锁定 1560 MHz → 4.78 GH/s / 108 W（默认），4.21 GH/s / 90 W（`--eco`）。

### 6. 开发者费用
1.0%：每 100 分钟中有 60 秒（首次在 15 分钟后）通过第二条已登录的矿池连接向开发者钱包提交份额，无需重连。

### 7. 常见问题
| 信息 | 含义 / 处理 |
|---|---|
| `hardware error (bad candidate)` | GPU 计算出错误哈希：降低核心超频 |
| `share rejected: … stale` | 份额提交途中区块已更新，偶尔出现属正常 |
| `cannot connect to any pool` | 检查矿池地址与网络，矿工会自动重试 |
| `self-test failed` | 该 GPU/驱动结果错误，矿工拒绝运行；请反馈显卡型号和驱动版本 |
