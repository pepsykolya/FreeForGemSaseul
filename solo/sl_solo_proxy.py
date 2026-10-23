#!/usr/bin/env python3
"""SASEUL solo proxy: our node's file IPC (run/mining_job -> run/mining_result) exposed to ffgs over the
rabbitminer-compatible JSON-lines protocol (login / getjob / submit).

- every new block template gets the next miner address of the rotation list (reward rule 9/32 + 23/32:
  one address per block keeps the full share of the remainder);
- shares below the network target are only counted (hashrate monitoring), a share that meets the network
  difficulty is written to run/mining_result for the node;
- jobs are served only while our node is in sync with the public network.
"""
import asyncio, hashlib, json, os, sys, time, urllib.request, logging

RUN = os.environ.get("SL_RUN", "/var/saseul-run")
PORT = int(os.environ.get("SL_PORT", "19310"))
TOKEN = os.environ.get("SL_TOKEN", "")                 # login password; empty = no auth
SHARE_DIFF = int(os.environ.get("SL_SHARE_DIFF", "100000000000"))
ADDR_FILE = os.environ.get("SL_ADDRESSES", "/etc/sl-solo/addresses.txt")
STATE = os.environ.get("SL_STATE", "/var/lib/sl-solo/state.json")
PUBLIC = os.environ.get("SL_PUBLIC", "http://main.saseul.net/info")
NONCE_LEN = int(os.environ.get("SL_NONCE_LEN", "40"))  # older miners ignore it and send 16 hex, both are accepted
EMPTY_ROOT = hashlib.sha256(b"").hexdigest()

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(message)s", stream=sys.stdout)
log = logging.info
H = lambda s: hashlib.sha256(s.encode()).hexdigest()


def header(j, ts):
    # ResourceBlockCompute::blockHeader: PHP json_encode, fixed key order, no spaces
    return H(json.dumps({"height": j["height"], "timestamp": ts, "receipt_root": EMPTY_ROOT,
                         "main_height": j["main_height"], "main_blockhash": j["main_blockhash"],
                         "validator": j["validator"], "miner": j["miner"]}, separators=(",", ":")))


class Proxy:
    def __init__(self):
        hexd = set("0123456789abcdef")
        self.addrs = [a.strip().lower() for a in open(ADDR_FILE) if len(a.strip()) == 44 and set(a.strip().lower()) <= hexd]
        assert self.addrs, f"no miner addresses (44 hex per line) in {ADDR_FILE}"
        self.state = {"rot": 0, "blocks": [], "shares": 0}
        try:
            self.state.update(json.load(open(STATE)))
        except Exception:
            pass
        self.jobs = {}          # job_id -> template (last few)
        self.cur = None
        self.net_height = 0
        self.synced = False
        self.workers = {}       # name -> [shares, last_ts]

    def save(self):
        os.makedirs(os.path.dirname(STATE), exist_ok=True)
        tmp = STATE + ".tmp"
        json.dump(self.state, open(tmp, "w"))
        os.replace(tmp, STATE)

    def read_job(self):
        try:
            j = json.load(open(os.path.join(RUN, "mining_job")))
        except Exception:
            return None
        return j if j.get("previous_blockhash") else None

    async def watch(self):
        last_pub = 0
        while True:
            if time.time() - last_pub > 30:
                last_pub = time.time()
                try:
                    d = json.loads(urllib.request.urlopen(PUBLIC, timeout=10).read())["data"]
                    self.net_height = d["last_resource_block"]["height"]
                except Exception as e:
                    log(f"public node unreachable: {e}")
            j = self.read_job()
            synced = bool(j) and self.net_height and j["height"] >= self.net_height + 1
            if synced != self.synced:
                self.synced = synced
                log(f"node {'IN SYNC' if synced else 'not in sync'}: job height {j and j['height']}, network {self.net_height}")
            if j and synced and (self.cur is None or j["previous_blockhash"] != self.cur["previous_blockhash"]
                      or j["main_blockhash"] != self.cur["main_blockhash"]):
                if self.cur is None or j["previous_blockhash"] != self.cur["previous_blockhash"]:
                    self.state["rot"] = (self.state["rot"] + 1) % len(self.addrs)
                    self.save()
                t = dict(j)
                t["miner"] = self.addrs[self.state["rot"]]
                self.cur = t
                self.jobs[t["previous_blockhash"]] = t
                for k in list(self.jobs)[:-4]:
                    del self.jobs[k]
                log(f"job height {t['height']} diff {t['difficulty']} miner #{self.state['rot']} {t['miner'][:8]}")
            await asyncio.sleep(0.3)

    def job_msg(self):
        t = self.cur
        return {"blockhash": "", "difficulty": str(SHARE_DIFF), "height": t["height"], "job_digest": t["main_blockhash"][-16:],
                "job_id": t["previous_blockhash"], "main_blockhash": t["main_blockhash"], "main_height": t["main_height"],
                "miner": t["miner"], "network_difficulty": str(t["difficulty"]), "nonce": "",
                "previous_blockhash": t["previous_blockhash"], "receipts": [], "share_difficulty": SHARE_DIFF,
                "timestamp": 0, "validator": t["validator"], "vardiff": False,
                "nonce_len": NONCE_LEN}  # ffgs >= 0.2.0: 40 hex = solo kernel (rounds 0..12 precomputed)

    def submit(self, worker, p):
        job_id, nonce, ts, bh = p[0], p[1], int(p[2]), p[3]
        t = self.jobs.get(job_id)
        if not t:
            return False, "stale job"
        if not (len(nonce) % 2 == 0 and 0 < len(nonce) <= 64 and all(c in "0123456789abcdef" for c in nonce)):
            return False, "bad nonce"
        prev_ts = int(t["previous_blockhash"][:14], 16)
        if ts <= prev_ts + 1_000_000 or ts >= int(time.time() * 1e6) + 4_000_000:
            return False, "bad timestamp"
        root = H(t["previous_blockhash"] + header(t, ts) + nonce)
        if "%014x" % ts + H(root) != bh:
            return False, "blockhash mismatch"
        r = int(root, 16)
        if r > (1 << 256) // SHARE_DIFF:
            return False, "low difficulty"
        self.state["shares"] += 1
        w = self.workers.setdefault(worker, [0, 0])
        w[0] += 1; w[1] = time.time()
        if r <= (1 << 256) // int(t["difficulty"]):
            block = {"height": t["height"], "blockhash": bh, "previous_blockhash": t["previous_blockhash"], "nonce": nonce,
                     "timestamp": ts, "difficulty": str(t["difficulty"]), "main_height": t["main_height"],
                     "main_blockhash": t["main_blockhash"], "validator": t["validator"], "miner": t["miner"], "receipts": []}
            path = os.path.join(RUN, "mining_result")
            try:
                res = json.load(open(path))
                if not isinstance(res, dict):
                    res = {}
            except Exception:
                res = {}
            res[t["previous_blockhash"]] = block
            tmp = path + ".proxy.tmp"
            json.dump(res, open(tmp, "w"))
            os.chmod(tmp, 0o666)
            os.replace(tmp, path)
            self.state["blocks"].append({"height": t["height"], "miner": t["miner"], "ts": ts, "worker": worker})
            self.save()
            log(f"*** BLOCK {t['height']} by {worker} miner {t['miner']} root {root[:20]}")
            return True, "block"
        return True, "share"

    async def client(self, reader, writer):
        peer = writer.get_extra_info("peername")
        worker, ok = "?", False
        try:
            while True:
                line = await reader.readline()
                if not line:
                    break
                m = json.loads(line)
                mid, meth, p = m.get("id"), m.get("method"), m.get("params") or []
                if meth == "login":
                    user = str(p[0]) if p else ""
                    worker = user.split(".", 1)[1] if "." in user else user[:8]
                    ok = not TOKEN or (len(p) > 2 and p[2] == TOKEN)
                    resp = {"id": mid, "result": ok, "ok": ok} if ok else {"id": mid, "result": False, "error": "bad password"}
                    log(f"login {worker} from {peer[0]}: {'ok' if ok else 'denied'}")
                elif not ok:
                    resp = {"id": mid, "result": False, "error": "not logged in"}
                elif meth == "getjob":
                    if self.cur and self.synced:
                        resp = {"id": mid, "result": self.job_msg(), "ok": True}
                    else:
                        resp = {"id": mid, "result": None, "ok": False, "error": "node syncing"}
                elif meth == "submit":
                    good, st = self.submit(worker, p)
                    resp = {"id": mid, "result": good, "ok": good, "status": st} if good else {"id": mid, "result": False, "error": st}
                    if not good:
                        log(f"reject {worker}: {st}")
                else:
                    resp = {"id": mid, "result": False, "error": "unknown method"}
                writer.write((json.dumps(resp, separators=(",", ":")) + "\n").encode())  # compact, like rabbitminer
                await writer.drain()
        except Exception as e:
            log(f"client {peer} error: {e}")
        finally:
            writer.close()

    async def stats(self):
        while True:
            await asyncio.sleep(300)
            now = time.time()
            act = {k: v[0] for k, v in self.workers.items() if now - v[1] < 600}
            log(f"stats: synced={self.synced} height={self.cur and self.cur['height']} shares_total={self.state['shares']} "
                f"blocks={len(self.state['blocks'])} active={act}")

    async def main(self):
        srv = await asyncio.start_server(self.client, "0.0.0.0", PORT)
        log(f"SASEUL solo proxy on :{PORT}, {len(self.addrs)} rotation addresses, share diff {SHARE_DIFF}")
        await asyncio.gather(srv.serve_forever(), self.watch(), self.stats())


if __name__ == "__main__":
    asyncio.run(Proxy().main())
