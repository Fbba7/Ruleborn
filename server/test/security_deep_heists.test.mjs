// The deep security run's fixes on heist submission (SEC-18 part A, SEC-31).

import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, readdirSync, rmSync, statfsSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { Store } from "../src/store.mjs";
import { openPlan, play, twoPlayers } from "./setup.mjs";

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
