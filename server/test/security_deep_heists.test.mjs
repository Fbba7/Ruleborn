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

// SEC-18 part B (decided): bytes were stored before any check, so junk that
// was no heist at all was kept the full retention and handed back to its
// sender. Now nothing is stored until the header checks pass; a submission
// refused after them is kept 7 days at most (review evidence); and an
// account stores at most REPLAY_BYTES_A_DAY of replays a day, past which a
// refusal stores nothing (a validated heist is always stored).
const DAY = 24 * 60 * 60 * 1000;
const replayOf = (t, token) => t.service.db.prepare(
  "SELECT log_hash, replay_gone, validated FROM heists WHERE token = ?").get(token);
// The replay's answer to `who`, by the service itself: a session's token
// would lapse as these tests move the clock on by days.
const fetchReplay = async (t, who, token) => {
  try { t.service.replay(who.account, token); return 200; } catch (e) { return e.status; }
};
// A played replay whose final state hash is wrong: it passes the header
// checks and the simulation refuses it.
const tampered = (bytes) => { const b = Uint8Array.from(bytes); b[b.length - 1] ^= 0xff; return b; };

test("SEC-18 B: a submission refused before its header checks pass stores no bytes, and its sender gets 410", async () => {
  const t = twoPlayers(true);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const junk = new Uint8Array(4096).fill(7);
  const out = t.service.submit(t.raider.account, lease.token, junk);
  assert.deepEqual([out.validated, out.reason], [false, "replay_malformed"]);
  const row = replayOf(t, lease.token);
  assert.equal(t.service.replays.get(row.log_hash), null, "junk is never written");
  assert.equal(row.replay_gone, 1);
  assert.equal(await fetchReplay(t, t.raider, lease.token), 410);
  // A wrong seed is refused by the header too.
  const other = t.service.lease(t.raider.account, t.bundle);
  const otherSeed = { ...other, seed: (BigInt(other.seed) + 1n).toString() };
  const wrong = t.service.submit(t.raider.account, other.token, play(t, otherSeed, { plan: openPlan() }));
  assert.equal(wrong.reason, "wrong_seed");
  assert.equal(t.service.replays.get(replayOf(t, other.token).log_hash), null);
});

test("SEC-18 B: a submission refused after the header checks is kept 7 days, a validated one the full retention", async () => {
  const t = twoPlayers(true);
  const bad = t.service.lease(t.raider.account, t.bundle);
  const refused = t.service.submit(t.raider.account, bad.token, tampered(play(t, bad, { plan: openPlan() })));
  assert.equal(refused.validated, false);
  assert.notEqual(refused.reason, "replay_malformed");
  assert.equal(await fetchReplay(t, t.raider, bad.token), 200, "kept for review and its sender");
  const good = t.service.lease(t.raider.account, t.bundle);
  assert.equal(t.service.submit(t.raider.account, good.token, play(t, good, { plan: openPlan() })).validated, true);
  t.clock.now += 6 * DAY;
  t.service.expireReplays();
  assert.equal(await fetchReplay(t, t.raider, bad.token), 200, "six days on, still kept");
  t.clock.now += 1 * DAY + 1000;
  t.service.expireReplays();
  assert.equal(await fetchReplay(t, t.raider, bad.token), 410, "past seven days, gone");
  assert.equal(t.service.replays.get(replayOf(t, bad.token).log_hash), null, "and its bytes deleted");
  assert.equal(await fetchReplay(t, t.raider, good.token), 200, "the played heist stays");
});

test("SEC-18 B: past 2 MiB of replays a day a refusal stores nothing, a validated heist is still stored", async () => {
  const { REPLAY_BYTES_A_DAY } = await import("../src/service.mjs");
  assert.equal(REPLAY_BYTES_A_DAY, 2 * 2 ** 20);
  const t = twoPlayers(true);
  const first = t.service.lease(t.raider.account, t.bundle);
  assert.equal(t.service.submit(t.raider.account, first.token, play(t, first, { plan: openPlan() })).validated, true);
  // The day's uploads stand just under the quota.
  t.service.db.prepare("UPDATE heists SET log_bytes = ? WHERE token = ?").run(REPLAY_BYTES_A_DAY - 100, first.token);
  const bad = t.service.lease(t.raider.account, t.bundle);
  assert.equal(t.service.submit(t.raider.account, bad.token, tampered(play(t, bad, { plan: openPlan() }))).validated, false);
  assert.equal(replayOf(t, bad.token).replay_gone, 1);
  assert.equal(await fetchReplay(t, t.raider, bad.token), 410);
  const good = t.service.lease(t.raider.account, t.bundle);
  assert.equal(t.service.submit(t.raider.account, good.token, play(t, good, { plan: openPlan() })).validated, true);
  assert.equal(await fetchReplay(t, t.defender, good.token), 200, "a raid played is always kept");
  // The next day the quota is new.
  t.clock.now += DAY;
  const next = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, next.token, tampered(play(t, next, { plan: openPlan() })));
  assert.equal(replayOf(t, next.token).replay_gone, 0);
});

// SEC-25 part B (decided): a refused submission freed its lease at once and
// the next lease drew a fresh seed, so a client could send junk until it
// was handed a seed it liked. Now the next lease on the target keeps the
// refused lease's seed while that lease would have been live, and an
// account is leased nothing more on a day it has had MAX_REFUSALS_A_DAY
// refusals.
test("SEC-25 B: a refused lease's seed is kept by the next lease on the target, until it would have expired", () => {
  const t = twoPlayers(true);
  const first = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, first.token, new Uint8Array(8));
  const second = t.service.lease(t.raider.account, t.bundle);
  assert.notEqual(second.token, first.token);
  assert.equal(second.seed, first.seed, "no fresh seed for a refusal");
  // The kept seed plays: the device may send the same heist again.
  assert.equal(t.service.submit(t.raider.account, second.token, play(t, second, { plan: openPlan() })).validated, true);
  // A played lease frees the seed, as it always did.
  const third = t.service.lease(t.raider.account, t.bundle);
  assert.notEqual(third.seed, first.seed);
  // Refused, then leased again after the refused lease's day ran out: fresh.
  t.service.submit(t.raider.account, third.token, new Uint8Array(8));
  t.clock.now += 24 * 60 * 60 * 1000 + 1;
  assert.notEqual(t.service.lease(t.raider.account, t.bundle).seed, third.seed);
});

test("SEC-25 B: after 10 refused submissions in a UTC day, leasing is refused 429 too_many_refusals until the next", async () => {
  const { MAX_REFUSALS_A_DAY } = await import("../src/service.mjs");
  assert.equal(MAX_REFUSALS_A_DAY, 10);
  const t = twoPlayers(true);
  for (let i = 0; i < MAX_REFUSALS_A_DAY; i++) {
    const lease = t.service.lease(t.raider.account, t.bundle);
    assert.equal(t.service.submit(t.raider.account, lease.token, new Uint8Array(8)).validated, false);
  }
  assert.throws(() => t.service.lease(t.raider.account, t.bundle),
                (e) => e.status === 429 && e.reason === "too_many_refusals");
  // Another player is not held by it.
  const other = t.service.session("gc:other");
  assert.ok(t.service.lease(other.account, t.bundle).token);
  t.clock.now += 24 * 60 * 60 * 1000;
  assert.ok(t.service.lease(t.raider.account, t.bundle).token, "a new day");
});
