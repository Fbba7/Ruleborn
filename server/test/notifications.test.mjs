// Replays kept and watched (§13, §24.3), and notifications (§14.6, §20.2),
// against the real simulation build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { Refused } from "../src/service.mjs";
import { T0, openPlan, play, twoPlayers } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);
const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

function raid(t, clean = true) {
  const lease = t.service.lease(t.raider.account, t.bundle);
  const replay = play(t, lease, { plan: clean ? openPlan() : [] });
  t.service.submit(t.raider.account, lease.token, replay);
  return { token: lease.token, replay };
}

test("both sides of a heist can watch its replay, and nobody else can (13)", () => {
  const t = twoPlayers(true);
  const { token, replay } = raid(t);
  assert.deepEqual(t.service.replay(t.defender.account, token), replay);
  assert.deepEqual(t.service.replay(t.raider.account, token), replay);
  const stranger = t.service.session("gc:stranger").account;
  refusal(() => t.service.replay(stranger, token), "no_such_heist");
  // Kept apart from the public store, whose objects anyone may fetch by hash.
  const hash = t.service.db.prepare("SELECT log_hash FROM heists WHERE token = ?").get(token).log_hash;
  assert.equal(t.service.bundle(hash), null);
});

test("a replay is kept 90 days, then goes, and its heist stays (24.3)", () => {
  const t = twoPlayers(true);
  const { token } = raid(t);
  t.clock.now = T0 + 89 * DAY;
  assert.equal(t.service.expireReplays(), 0);
  t.clock.now = T0 + 91 * DAY;
  assert.equal(t.service.expireReplays(), 1);
  assert.equal(t.service.expireReplays(), 0, "once");
  refusal(() => t.service.replay(t.defender.account, token), "replay_no_longer_kept");
  assert.ok(t.service.db.prepare("SELECT 1 FROM heists WHERE token = ?").get(token), "the record stays");
});

test("a heist against you is sent when it lands, and raids while you wait are one notification (13, 14.6)", async () => {
  const t = twoPlayers(true);
  t.service.notifications.set(t.defender.account, { pushToken: "device-1" });
  t.clock.now = T0 + 3 * HOUR;                            // 12:00 UTC
  const first = raid(t, true);
  t.clock.now += DAY + HOUR;
  const second = raid(t, false);
  const pushed = [];
  const sent = await t.service.notifications.deliver((token, m) => pushed.push([token, m]));
  assert.equal(sent.length, 1);
  assert.deepEqual(pushed, [["device-1", { kind: "raided", heists: [
    { heist: first.token, grade: "clean" }, { heist: second.token, grade: "foiled" }] }]]);
  assert.deepEqual(await t.service.notifications.deliver(() => assert.fail("sent twice")), []);
});

test("nothing is sent at night: 21:00 to 08:00 at 13 to 15, 22:00 at 16 and 17, adults by choice (20.2)", () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  const at = (hour) => Date.UTC(2026, 8, 24, hour, 30);
  const setBand = (band) => t.service.db.prepare("UPDATE accounts SET age_band = ? WHERE id = ?")
    .run(band, t.defender.account);
  const d = t.defender.account;
  setBand("13-15");
  assert.equal(n.due(d, at(20)), at(20));
  assert.equal(n.due(d, at(21)), Date.UTC(2026, 8, 25, 8), "held to the morning");
  assert.equal(n.due(d, at(3)), Date.UTC(2026, 8, 24, 8));
  refusal(() => n.set(d, { nightQuiet: false }), "the_night_is_always_quiet_under_18");
  setBand("16-17");
  assert.equal(n.due(d, at(21)), at(21));
  assert.equal(n.due(d, at(22)), Date.UTC(2026, 8, 25, 8));
  setBand("18+");
  assert.equal(n.due(d, at(23)), Date.UTC(2026, 8, 25, 8), "quiet by default");
  n.set(d, { nightQuiet: false });
  assert.equal(n.due(d, at(23)), at(23), "unless the adult opens it");
  // The night is the player's own: 21:30 UTC is 18:30 in Brasília.
  setBand("13-15");
  n.set(d, { utcOffset: -180 });
  assert.equal(n.due(d, at(21)), at(21));
});

test("a daily reminder at the time the player chose, or none (14.6)", async () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  const me = t.defender.account;
  n.set(me, { pushToken: "device-2", reminder: 18 * 60 });
  const pushed = [];
  t.clock.now = Date.UTC(2026, 8, 24, 17, 59);
  assert.deepEqual(await n.deliver((_, m) => pushed.push(m)), []);
  t.clock.now = Date.UTC(2026, 8, 24, 18, 1);
  await n.deliver((_, m) => pushed.push(m));
  t.clock.now = Date.UTC(2026, 8, 24, 20, 0);
  await n.deliver((_, m) => pushed.push(m));
  assert.deepEqual(pushed, [{ kind: "reminder", day: "2026-09-24" }], "once a day");
  n.set(me, { reminder: null });
  t.clock.now = Date.UTC(2026, 8, 25, 18, 1);
  assert.deepEqual(await n.deliver(() => assert.fail("no reminder chosen")), []);
  refusal(() => n.set(me, { reminder: 24 * 60 }), "bad_reminder_time");
});

test("the night holds when a notification is sent, not only when it is queued (20.2)", async () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  const me = t.defender.account;
  t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(me);
  const pushed = [];
  const send = (_, m) => pushed.push(m);
  // A 07:00 reminder chosen at 22:30 comes when the night ends, once.
  t.clock.now = Date.UTC(2026, 8, 23, 22, 30);
  n.set(me, { utcOffset: 0, reminder: 7 * 60, pushToken: "device-3" });
  assert.deepEqual(await n.deliver(send), []);
  t.clock.now = Date.UTC(2026, 8, 24, 7, 59);
  assert.deepEqual(await n.deliver(send), []);
  t.clock.now = Date.UTC(2026, 8, 24, 8, 0);
  await n.deliver(send);
  t.clock.now = Date.UTC(2026, 8, 24, 8, 1);
  await n.deliver(send);
  assert.deepEqual(pushed, [{ kind: "reminder", day: "2026-09-24" }]);
  // A raid due in the evening, not sent before the night began, waits too.
  n.set(me, { reminder: null });
  t.clock.now = Date.UTC(2026, 8, 24, 20, 50);
  n.raided({ defender: me, token: "h1" }, { grade: "clean" }, t.clock.now);
  t.clock.now = Date.UTC(2026, 8, 24, 21, 30);
  assert.deepEqual(await n.deliver(() => assert.fail("sent at night")), []);
  t.clock.now = Date.UTC(2026, 8, 25, 8, 0);
  assert.deepEqual((await n.deliver(send)).map((m) => m.kind), ["raided"]);
});

test("the day's reminders read the outbox once a tick, however many players chose one (14.6)", () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  const players = [t.defender.account, t.raider.account];
  for (let i = 0; i < 6; i++) players.push(t.service.session(`gc:reminded-${i}`).account);
  for (const p of players) n.set(p, { reminder: 60 });
  t.clock.now = Date.UTC(2026, 8, 24, 12, 0);
  assert.equal(n.remind(t.clock.now), players.length);
  const db = t.service.db;
  const read = [];
  const prepare = db.prepare;
  db.prepare = (sql) => {
    if (/FROM notifications/.test(sql)) read.push(sql);
    return prepare.call(db, sql);
  };
  try {
    t.clock.now += 60 * 1000;
    assert.equal(n.remind(t.clock.now), 0, "one a day");
  } finally {
    db.prepare = prepare;
  }
  assert.equal(read.length, 1);
  const plan = db.prepare(`EXPLAIN QUERY PLAN ${read[0]}`).all(0).map((r) => r.detail).join("; ");
  assert.doesNotMatch(plan, /SCAN notifications/, plan);
});

test("replays and notification settings over HTTP", async () => {
  const t = twoPlayers(true);
  const { token, replay } = raid(t);
  const call = (method, path, who, json) => t.handle(new Request(`https://edge.example${path}`, {
    method, headers: { authorization: `Bearer ${who.token}`, ...(json ? { "content-type": "application/json" } : {}) },
    body: json ? JSON.stringify(json) : undefined }));
  const res = await call("GET", `/v1/heists/${token}/replay`, t.defender);
  assert.deepEqual(new Uint8Array(await res.arrayBuffer()), replay);
  const set = await (await call("PUT", "/v1/notifications", t.raider, { utcOffset: 60, reminder: 540 })).json();
  assert.deepEqual([set.utcOffset, set.reminder, set.nightQuiet], [60, 540, true]);
});
