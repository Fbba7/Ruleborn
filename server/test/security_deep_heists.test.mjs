// The deep security run's fixes on heist submission (SEC-18 part A, SEC-25
// part A, SEC-31).

import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdtempSync, readFileSync, readdirSync, rmSync, statfsSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { Build, Builds } from "../src/sim.mjs";
import { Store } from "../src/store.mjs";
import { WASM, openPlan, play, twoPlayers } from "./setup.mjs";

const files = (dir) => readdirSync(dir, { recursive: true }).filter((f) => /[0-9a-f]{64}$/.test(f));

// SEC-18: replays were written with no check on the volume's free space, so
// refused submissions could fill the disk under the database and the
// deletions journal. Now a floor refuses a new replay while the volume has
// less free than it, and the lease is kept for a later submission.
test("SEC-18: below the replays' free-space floor a heist is refused 503 storage_low, nothing is written, and the lease is kept", async () => {
  const dir = mkdtempSync(join(tmpdir(), "rb-sec18-"));
  try {
    const t = twoPlayers(true);
    const fs = statfsSync(dir);
    const free = fs.bavail * fs.bsize;
    t.service.replays = new Store(dir, { minFreeBytes: free + 2 ** 30 });
    const { token } = t.service.session("gc:raider");
    const lease = t.service.lease(t.raider.account, t.bundle);
    const replay = play(t, lease, { plan: openPlan() });
    const res = await t.handle(new Request(`https://edge.example/v1/heists/${lease.token}`, {
      method: "POST", headers: { authorization: `Bearer ${token}` }, body: replay }));
    assert.equal(res.status, 503);
    assert.equal((await res.json()).error, "storage_low");
    assert.deepEqual(files(dir), [], "no replay written");
    assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM heists").get().n, 0, "nothing settled");
    // Space returns: the same lease is played.
    t.service.replays.minFreeBytes = 1;
    assert.equal(t.service.submit(t.raider.account, lease.token, replay).validated, true);
    assert.equal(files(dir).length, 1);
    // A store already holding the bytes answers with their hash whatever the
    // floor: a retry of what was stored never fails on it.
    t.service.replays.minFreeBytes = free + 2 ** 30;
    assert.equal(t.service.replays.put(replay).length, 64);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("SEC-18: the deployed server puts the floor on the replays only, 512 MiB unless told", () => {
  const main = readFileSync(new URL("../src/main.mjs", import.meta.url), "utf8");
  assert.match(main, /replays: new Store\(join\(data, "replays"\),\s*\{ minFreeBytes: Number\(process\.env\.RULEBORN_REPLAYS_MIN_FREE_MB \?\? 512\) \* 2 \*\* 20 \}\)/);
  assert.match(main, /store: new Store\(join\(data, "bundles"\)\),/, "published islands keep being written");
  assert.match(main, /deletions: new Journal\(new Store\(process\.env\.RULEBORN_DELETIONS \?\? join\(data, "deletions"\)\)\)/,
               "the deletions journal never refuses");
});

// SEC-31: the lease keeps the rules it was issued under, but the replay's
// header chose the build that judged it: any other build held would do.
test("SEC-31: a replay is judged under its lease's rules; one naming another held build is refused wrong_rules", () => {
  const t = twoPlayers(true);
  const old = t.service.builds.current;
  // A second build: the same wasm under another version, as a rules upgrade
  // leaves the old build held beside the new.
  const newer = Build.load(WASM);
  newer.rulesVersion = "f".repeat(64);
  t.service.builds = new Builds([old, newer]);
  const lease = t.service.lease(t.raider.account, t.bundle);
  assert.equal(t.service.db.prepare("SELECT rules FROM leases WHERE token = ?").get(lease.token).rules, newer.rulesVersion);
  // Recorded by the old build, so its header names the old rules.
  const replay = play(t, lease, { plan: openPlan() });
  const out = t.service.submit(t.raider.account, lease.token, replay);
  assert.deepEqual([out.validated, out.reason], [false, "wrong_rules"]);
  // A lease issued under the old rules, before the upgrade, still plays.
  t.service.builds = new Builds([old]);
  const before = t.service.lease(t.raider.account, t.bundle);
  t.service.builds = new Builds([old, newer]);
  assert.equal(t.service.submit(t.raider.account, before.token, play(t, before, { plan: openPlan() })).validated, true);
});

// SEC-25 part A: a heist's stray was rolled from the account and the lease's
// token alone, both known to the device, so a client could tell before it
// submitted whether the heist would find a stray, and drop the ones that
// would not. The roll is now keyed with a secret the device never holds.
test("SEC-25: the stray roll cannot be worked out from the account and the token", () => {
  const t = twoPlayers(false);
  const me = t.raider.account;
  const dice = (seed) => { let i = 0; return (n) => createHash("sha256").update(`${seed}:${i++}`).digest().readUInt32BE(0) % n; };
  const db = t.service.db;
  let predicted = 0, found = 0, agree = 0;
  db.exec("SAVEPOINT sec25");
  try {
    for (let n = 0; n < 64; n++) {
      const token = createHash("sha256").update(`sec25-${n}`).digest("hex").slice(0, 32);
      const guess = dice(`${me}:stray:${token}`)(8) === 0;
      const got = t.service.home.findStray(me, token, [], t.clock.now) !== null;
      predicted += guess; found += got; agree += guess === got;
    }
  } finally {
    db.exec("ROLLBACK TO sec25"); db.exec("RELEASE sec25");
  }
  assert.ok(predicted > 0 && found > 0, `both find strays (${predicted}, ${found})`);
  assert.ok(agree < 64, "the device's prediction misses");
  // The same key after a restart: it comes from the server's secret.
  assert.deepEqual(t.service.home.strayKey, twoPlayers(false).service.home.strayKey);
});
