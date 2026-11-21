// FX2-4-purge-notify: the November bug report's edge-purge and notification
// entries (docs/security/bug-report-2026-11.md): RB-33 (a bundle served at a
// URL the under-13 purge never names), RB-34 (an under-13 deletion that
// never purges the cached target lists naming the child), RB-46 (the raid
// notification listing refused submissions), RB-47 (a friendly heist after
// the day's first raid never notified) and RB-48 (a raid pushed twice after
// a push retry). Each test was written to fail on main before its fix.

import assert from "node:assert/strict";
import { test } from "node:test";

import { bundlePath } from "../src/edge.mjs";
import { RETRY_MS } from "../src/notifications.mjs";
import { openPlan, play, submitCrewed, twoPlayers } from "./setup.mjs";

const HOUR = 60 * 60 * 1000;

const call = (t, method, path, { token, json } = {}) => t.handle(new Request(`https://edge.example${path}`, {
  method,
  headers: { ...(token ? { authorization: `Bearer ${token}` } : {}),
             ...(json ? { "content-type": "application/json" } : {}) },
  body: json ? JSON.stringify(json) : undefined,
}));

/** An edge that confirms every purge, and keeps every path it was asked. */
function fakeEdge() {
  const asked = [];
  return { asked, purge: async (paths) => { asked.push(...paths); return { ok: true }; } };
}

/** A raid on the defender, clean or foiled, submitted. */
function raid(t, clean = true) {
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: clean ? openPlan() : [] }));
  return lease.token;
}

// -- RB-33 -------------------------------------------------------------------

test("RB-33: a bundle is served only at the one URL the under-13 purge names", async () => {
  const t = twoPlayers(true);
  const plain = await call(t, "GET", bundlePath(t.bundle));
  assert.equal(plain.status, 200);
  assert.match(plain.headers.get("cache-control"), /immutable/);
  for (const variant of [`${bundlePath(t.bundle)}?v=2`, `${bundlePath(t.bundle)}/x`, `${bundlePath(t.bundle)}/`,
                         `${bundlePath(t.bundle)}?`]) {
    const res = await call(t, "GET", variant);
    assert.equal(res.status, 404, `${variant} is not a URL the edge would ever be asked to purge`);
    assert.doesNotMatch(res.headers.get("cache-control") ?? "", /immutable/, variant);
  }
});

// -- RB-34 -------------------------------------------------------------------

test("RB-34: an under-13 deletion asks the edge to purge the target lists that named the child", async () => {
  const t = twoPlayers(true);
  const named = Object.values(t.service.targetLists());
  assert.ok(named.length > 0, "the child's island is on a current target list");
  t.service.edge = fakeEdge();
  const res = await call(t, "PUT", "/v1/age", { token: t.defender.token, json: { band: "under-13" } });
  assert.deepEqual(await res.json(), { deleted: true, reason: "under-13" });
  await new Promise(setImmediate);
  for (const list of named) {
    assert.equal(t.service.bundle(list), null, "the list is gone at the origin");
    assert.ok(t.service.edge.asked.includes(bundlePath(list)),
              `the edge was asked to purge the list; asked=${JSON.stringify(t.service.edge.asked)}`);
  }
  assert.ok(t.service.edge.asked.includes(bundlePath(t.bundle)), "and the island's bundle, as before");
});

// -- RB-46 -------------------------------------------------------------------

test("RB-46: the raid notification lists only validated heists, never a refused submission", async () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  n.set(t.defender.account, { pushToken: "device-46", timeZone: "UTC" });
  t.clock.now = Date.UTC(2026, 8, 24, 12, 0);
  const real = raid(t, true);
  t.clock.now += HOUR;
  const junk = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, junk.token, new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8]));
  assert.equal(out.validated, false);
  t.clock.now = Date.UTC(2026, 8, 25, 8, 0);
  const pushed = [];
  await n.deliver((_, m) => pushed.push(m));
  assert.deepEqual(pushed, [{ kind: "raided", heists: [{ heist: real, grade: "clean" }] }]);
});

// -- RB-47 -------------------------------------------------------------------

test("RB-47: a friendly heist after the day's first raid is told in the same message", async () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  n.set(t.defender.account, { pushToken: "device-47", timeZone: "UTC" });
  t.clock.now = Date.UTC(2026, 8, 24, 12, 0);
  const first = raid(t, true);
  const { invite } = t.service.friends.invite(t.defender.account);
  t.service.friends.accept(t.raider.account, invite);
  t.clock.now += HOUR;
  const lease = t.service.lease(t.raider.account, t.bundle, null, { mode: "friendly" });
  const game = submitCrewed(t, t.raider.account, lease, { plan: [] });
  assert.equal(game.verdict.grade, "foiled");
  t.clock.now = Date.UTC(2026, 8, 25, 8, 0);
  const pushed = [];
  await n.deliver((_, m) => pushed.push(m));
  assert.deepEqual(pushed, [{ kind: "raided", heists: [
    { heist: first, grade: "clean" }, { heist: lease.token, grade: "foiled" }] }]);
});

// -- RB-48 -------------------------------------------------------------------

test("RB-48: a raid that lands while a push is in flight is told once, after the push is retried", async () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  n.set(t.defender.account, { pushToken: "device-48", timeZone: "UTC" });
  t.clock.now = Date.UTC(2026, 8, 24, 12, 0);
  const x1 = raid(t, true);
  t.clock.now = Date.UTC(2026, 8, 25, 8, 0);
  const pushed = [];
  let x2 = null;
  await n.deliver((_, m) => {
    pushed.push(m);
    // N1 is claimed; x2 lands while its push is in flight, which then
    // answers "try again".
    t.clock.now += 60 * 1000;
    x2 = raid(t, false);
    return { retry: true };
  });
  assert.deepEqual(pushed, [{ kind: "raided", heists: [{ heist: x1, grade: "clean" }] }]);
  // x3 lands while N1 waits for its retry and N2 (x2's) waits too.
  t.clock.now += 60 * 1000;
  const x3 = raid(t, true);
  // Both are due by the next day's turn: N1 after its retry, N2 at it.
  t.clock.now = Date.UTC(2026, 8, 26, 8, 0) + RETRY_MS;
  const after = [];
  await n.deliver((_, m) => after.push(m));
  const told = after.flatMap((m) => m.heists.map((h) => h.heist)).sort();
  assert.deepEqual(told, [x1, x2, x3].sort(), `each raid told once: ${JSON.stringify(after)}`);
  assert.equal(after.length, 2, "N1 retried and N2 sent");
  assert.deepEqual(after.find((m) => m.heists.some((h) => h.heist === x1)).heists,
                   [{ heist: x1, grade: "clean" }], "N1 retries with what it was claimed with");
});
