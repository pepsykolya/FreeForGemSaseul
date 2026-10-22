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
    ./ffgs --pool saseulmine --wallet ADDRESS.WORKER

| Option | Meaning |
|---|---|
| `--pool HOST:PORT[,HOST:PORT…]` | rabbitminer pool list; the next one is used when a pool is unreachable |
| `--pool saseulmine` | saseulmine.com; the same as `--pool https://pool.saseulmine.com` (any `https://` URL selects this protocol, several URLs = failover list; do not mix with `HOST:PORT` entries) |
| `--wallet ADDRESS[.WORKER]`, `--worker NAME` | payout address and worker name |
| `--referrer ADDRESS` / `--referrer none` | saseulmine only: referrer address sent with your shares; default: the ffgs dev wallet (see 6) |
| `--pass PASSWORD` | pool password (default `x`; the token of a solo proxy) |
| `--devices 0,1,…` | GPUs to use, numbered as in `nvidia-smi` / HiveOS (default: all) |
| `--eco` | efficiency kernel (see 5) |
| `--blocks N`, `--threads N` | launch geometry (default: SM count × 64 blocks × 256 threads) |
| `--bench SECONDS` | hashrate of every selected GPU, no pool |
| `--selftest` | PoW check against a real mainnet block + GPU kernel against a CPU brute force + request-signing check |
| `--pool-test` | saseulmine: one signed job request and your account stats, then exit (no GPU needed) |

Every 10 s the miner prints a status line:

    [  120s] GPU0 4.749 | GPU1 4.751 | total 9.500 GH/s | user sub 3 acc 3 rej 0 | fee sub 0 acc 0 rej 0

### 4. HiveOS
See [HIVEOS.md](HIVEOS.md).

### 5. Tuning
- The PoW is pure compute (no memory traffic): the **memory clock can be lowered** to the minimum to save power.
- **Default kernel** — highest hashrate per clock. Best when the card is power-limited or the core clock is locked high.
- **`--eco`** — about 12% fewer GH/s per clock but ~17% less power; best H/W on undervolted cards.
- RTX 3070 reference points: lock 1560 MHz → 4.78 GH/s at 108 W (default) / 4.21 GH/s at 90 W (`--eco`).

### 6. Dev fee and the saseulmine referrer
1.0%: 60 seconds every 100 minutes (first one after 15 minutes) the miner submits to the dev wallet on a second,
already logged-in pool connection of the same pool type (rabbitminer or saseulmine), so there is no reconnect gap.
Shares of that minute are shown as `fee …` in the status line.

**Referrer (saseulmine only).** saseulmine.com splits a found block 80% to miners, 10% to referrers and 10% to the pool,
and states on its site: *"No referrer? Your share is unchanged."* — i.e. the referral 10% is taken from the pool's part,
not from yours. By default ffgs sends the ffgs dev wallet (`a750e196…a624`) as your referrer; this does not change what
you are paid (according to the pool — we cannot audit its accounting). To send no referrer use `--referrer none`, to
credit someone else use `--referrer ADDRESS`. The referrer is printed at start.

### 6a. saseulmine.com details
- HTTPS (`pool.saseulmine.com:443`); every request is signed with an Ed25519 *client key*. ffgs creates it once and keeps
  it next to the binary in `ffgs-client.key` (if that folder is read-only, a new key is made at every start). The key is
  only a rig identity for the pool — it holds no coins. Do not copy it between rigs.
- The pool has no worker names (its account page shows one worker, `default`); `.WORKER` / `--worker` are ignored there.
- The pool sets the share difficulty per address (vardiff) and changes it after almost every share: a few shares per
  minute per rig are normal. Shares found just before a new block or before a difficulty raise would be rejected by the
  pool, so ffgs drops them (`share dropped: …` in the log) instead of sending them.
- Clock: the pool sends its time with every answer; ffgs uses it for the request signatures and the block timestamps,
  so a wrong PC clock does not matter.
- Linux: the CA certificates are read from `/etc/ssl/certs/ca-certificates.crt` (or the other usual places; `SSL_CERT_FILE`
  overrides). Windows uses the system certificate store and proxy settings.
- Account and payouts: the pool's web site (saseulmine.com) with your address; `--pool-test` prints the same account
  data in the console.

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
    ./ffgs --pool saseulmine --wallet АДРЕС.ВОРКЕР

| Опция | Что делает |
|---|---|
| `--pool ХОСТ:ПОРТ[,ХОСТ:ПОРТ…]` | список пулов rabbitminer; при недоступности берётся следующий |
| `--pool saseulmine` | saseulmine.com; то же, что `--pool https://pool.saseulmine.com` (любой `https://` URL — этот протокол, несколько URL — резервные; не смешивать с `ХОСТ:ПОРТ`) |
| `--wallet АДРЕС[.ВОРКЕР]`, `--worker ИМЯ` | адрес выплат и имя воркера |
| `--referrer АДРЕС` / `--referrer none` | только saseulmine: адрес реферера, который уходит вместе с шарами; по умолчанию — кошелёк разработчика ffgs (см. 6) |
| `--pass ПАРОЛЬ` | пароль пула (по умолчанию `x`; токен соло-прокси) |
| `--devices 0,1,…` | какие GPU, нумерация как в `nvidia-smi` / HiveOS (по умолчанию все) |
| `--eco` | экономичное ядро (см. 5) |
| `--blocks N`, `--threads N` | геометрия запуска (по умолчанию SM × 64 блоков × 256 потоков) |
| `--bench СЕКУНДЫ` | замер хешрейта каждой GPU без пула |
| `--selftest` | проверка PoW на реальном блоке сети, ядра против перебора на CPU и подписи запросов |
| `--pool-test` | saseulmine: один подписанный запрос задания и статистика аккаунта, затем выход (GPU не нужна) |

Каждые 10 с — строка статуса (хешрейт по картам, шары пользователя и комиссии).

### 4. HiveOS
См. [HIVEOS.md](HIVEOS.md).

### 5. Настройка
- PoW — чистые вычисления без работы с памятью: **частоту памяти можно опустить** до минимума, это экономит ватты.
- **Ядро по умолчанию** — максимум хешей на такт; лучше, когда карта упирается в лимит мощности или ядро зафиксировано высоко.
- **`--eco`** — примерно на 12% меньше GH/s на такт, но ~17% меньше мощность; лучший H/W на андервольте.
- RTX 3070: фиксация 1560 МГц → 4.78 GH/s при 108 Вт (по умолчанию) / 4.21 GH/s при 90 Вт (`--eco`).

### 6. Комиссия разработчика и реферер saseulmine
1.0%: 60 секунд из каждых 100 минут (первый раз через 15 минут) майнер отправляет шары на кошелёк разработчика
по второму, заранее авторизованному соединению с пулом того же типа (rabbitminer или saseulmine) — без переподключений.
Эти шары видны как `fee …` в строке статуса.

**Реферер (только saseulmine).** saseulmine.com делит найденный блок так: 80% майнерам, 10% реферерам, 10% пулу, и пишет
на своём сайте: *«No referrer? Your share is unchanged»* — «нет реферера — ваша доля та же», т.е. реферальные 10% идут
из части пула, а не из вашей. По умолчанию ffgs указывает реферером кошелёк разработчика ffgs (`a750e196…a624`); на ваши
выплаты это не влияет (по словам пула — проверить его учёт мы не можем). Без реферера: `--referrer none`, другой
реферер: `--referrer АДРЕС`. Реферер печатается в логе при старте.

### 6a. Особенности saseulmine.com
- HTTPS (`pool.saseulmine.com:443`); каждый запрос подписан Ed25519-*ключом клиента*. ffgs создаёт его один раз и хранит
  рядом с программой в `ffgs-client.key` (если папка только для чтения — новый ключ при каждом запуске). Ключ — лишь
  «паспорт» рига для пула, монет на нём нет. Не копируйте его между ригами.
- Имён воркеров у пула нет (в аккаунте один воркер `default`); `.ВОРКЕР` / `--worker` для него игнорируются.
- Сложность шары пул задаёт по адресу (vardiff) и меняет почти после каждой шары: несколько шар в минуту на риг — норма.
  Шары, найденные прямо перед новым блоком или перед повышением сложности, пул бы отклонил, поэтому ffgs их не отправляет
  (`share dropped: …` в логе).
- Часы: пул присылает своё время в каждом ответе; ffgs берёт его для подписи и для времени блока — неверные часы ПК не мешают.
- Linux: сертификаты CA читаются из `/etc/ssl/certs/ca-certificates.crt` (или других обычных мест; `SSL_CERT_FILE`
  переопределяет). Windows использует системное хранилище сертификатов и прокси.
- Аккаунт и выплаты — на сайте пула (saseulmine.com) по адресу; `--pool-test` печатает те же данные в консоль.

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
    ./ffgs --pool saseulmine --wallet 地址.矿工名

| 参数 | 说明 |
|---|---|
| `--pool 主机:端口[,主机:端口…]` | rabbitminer 矿池列表，不可用时自动切换到下一个 |
| `--pool saseulmine` | saseulmine.com，等同于 `--pool https://pool.saseulmine.com`（任何 `https://` 地址都使用该协议，多个地址为备用列表；不要与 `主机:端口` 混用） |
| `--wallet 地址[.矿工名]`、`--worker 名称` | 收款地址和矿工名 |
| `--referrer 地址` / `--referrer none` | 仅 saseulmine：随份额发送的推荐人地址；默认为 ffgs 开发者钱包（见第 6 节） |
| `--devices 0,1,…` | 使用的 GPU，编号与 `nvidia-smi` / HiveOS 一致（默认全部） |
| `--eco` | 节能内核（见第 5 节） |
| `--bench 秒数` | 不连接矿池，测试每张显卡的算力 |
| `--selftest` | 用真实主网区块校验 PoW，用 CPU 穷举校验 GPU 内核，并校验请求签名 |
| `--pool-test` | saseulmine：发送一次签名的任务请求并显示账户统计后退出（无需 GPU） |

### 4. HiveOS
见 [HIVEOS.md](HIVEOS.md)。

### 5. 调优
- 该 PoW 只做计算、不访问显存：**显存频率可以降到最低**以节省功耗。
- **默认内核**：每个时钟周期算力最高，适合功耗墙受限或核心频率锁定较高的情况。
- **`--eco`**：每时钟算力约低 12%，功耗约低 17%，降压显卡上能效最佳。
- RTX 3070 参考：锁定 1560 MHz → 4.78 GH/s / 108 W（默认），4.21 GH/s / 90 W（`--eco`）。

### 6. 开发者费用与 saseulmine 推荐人
1.0%：每 100 分钟中有 60 秒（首次在 15 分钟后）通过第二条已登录的、同类型（rabbitminer 或 saseulmine）的矿池连接向开发者钱包提交份额，无需重连。

**推荐人（仅 saseulmine）。** saseulmine.com 将区块收益分为：矿工 80%、推荐人 10%、矿池 10%，并在其网站上说明：
*"No referrer? Your share is unchanged."*（没有推荐人，您的份额也不变）——即推荐人的 10% 来自矿池的部分，而不是您的部分。
ffgs 默认把 ffgs 开发者钱包（`a750e196…a624`）作为您的推荐人发送；这不会改变您的收益（依据矿池的说明，我们无法审计其账目）。
不发送推荐人：`--referrer none`；指定其他推荐人：`--referrer 地址`。启动时日志会显示推荐人。

### 6a. saseulmine.com 说明
- 使用 HTTPS（`pool.saseulmine.com:443`），每个请求都用 Ed25519 *客户端密钥* 签名。ffgs 首次运行时生成该密钥并保存在程序旁的
  `ffgs-client.key`（若目录只读，则每次启动生成新密钥）。该密钥只是矿机在矿池中的身份，不持有任何币；请勿在矿机之间复制。
- 该矿池没有矿工名（账户页面只显示一个 `default`），`.矿工名` / `--worker` 对其无效。
- 矿池按地址动态调整份额难度（vardiff），几乎每个份额后都会变化：每台矿机每分钟几个份额属正常。新区块到来前或难度提高前找到的份额
  会被矿池拒绝，因此 ffgs 不再发送它们（日志中的 `share dropped: …`）。
- 时钟：矿池每次应答都附带服务器时间，ffgs 用它进行签名和设置区块时间戳，本机时钟不准也没有影响。
- Linux：CA 证书从 `/etc/ssl/certs/ca-certificates.crt`（或其他常见位置）读取，可用 `SSL_CERT_FILE` 指定。Windows 使用系统证书库和代理设置。
- 账户与支付：在矿池网站（saseulmine.com）输入地址查看；`--pool-test` 会在控制台打印相同的账户数据。

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
