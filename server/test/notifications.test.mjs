// Replays kept and watched (§13, §24.3), and notifications (§14.6, §20.2),
// against the real simulation build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { canonicalZone, instant } from "../src/notifications.mjs";
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

test("a day's raids are one message, sent when the night ends if no reminder is chosen (13, 14.6, G34)", async () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  n.set(t.defender.account, { pushToken: "device-1", timeZone: "UTC" });
  t.clock.now = Date.UTC(2026, 8, 24, 12, 0);
  const first = raid(t, true);
  t.clock.now += 3 * HOUR;
  const second = raid(t, false);
  const pushed = [];
  assert.deepEqual(await n.deliver(() => assert.fail("not before the day's turn")), []);
  t.clock.now = Date.UTC(2026, 8, 25, 7, 59);
  assert.deepEqual(await n.deliver(() => assert.fail("still night")), []);
  t.clock.now = Date.UTC(2026, 8, 25, 8, 0);
  const sent = await n.deliver((token, m) => pushed.push([token, m]));
  assert.equal(sent.length, 1);
  assert.deepEqual(pushed, [["device-1", { kind: "raided", heists: [
    { heist: first.token, grade: "clean" }, { heist: second.token, grade: "foiled" }] }]]);
  assert.deepEqual(await n.deliver(() => assert.fail("sent twice")), []);
});

test("with a reminder chosen, the day's raids come inside it, and a later raid waits for the next (G34)", async () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  n.set(t.defender.account, { pushToken: "device-4", timeZone: "UTC", reminder: 18 * 60 });
  t.clock.now = Date.UTC(2026, 8, 24, 10, 0);
  const morning = raid(t, true);
  t.clock.now = Date.UTC(2026, 8, 24, 15, 0);
  const afternoon = raid(t, false);
  const pushed = [];
  t.clock.now = Date.UTC(2026, 8, 24, 18, 0);
  await n.deliver((_, m) => pushed.push(m));
  assert.deepEqual(pushed, [{ kind: "reminder", day: "2026-09-24", heists: [
    { heist: morning.token, grade: "clean" }, { heist: afternoon.token, grade: "foiled" }] }]);
  t.clock.now = Date.UTC(2026, 8, 24, 19, 0);
  const evening = raid(t, true);
  assert.deepEqual(await n.deliver(() => assert.fail("not until tomorrow's reminder")), []);
  t.clock.now = Date.UTC(2026, 8, 25, 18, 0);
  await n.deliver((_, m) => pushed.push(m));
  assert.deepEqual(pushed.at(-1), { kind: "reminder", day: "2026-09-25",
                                    heists: [{ heist: evening.token, grade: "clean" }] });
});

test("no push goes to a device that has not reported its time zone (G34)", async () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  n.set(t.defender.account, { pushToken: "device-5" });
  t.clock.now = Date.UTC(2026, 8, 24, 12, 0);
  raid(t, true);
  t.clock.now = Date.UTC(2026, 8, 25, 12, 0);
  assert.deepEqual(await n.deliver(() => assert.fail("no zone, no push")), []);
  refusal(() => n.set(t.defender.account, { timeZone: "Mars/Olympus" }), "bad_time_zone");
  refusal(() => n.set(t.defender.account, { timeZone: 60 }), "bad_time_zone");
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
  n.set(d, { timeZone: "America/Sao_Paulo" });
  assert.equal(n.due(d, at(21)), at(21));
  // And follows the zone's clock through daylight saving: 20:30 UTC is 21:30
  // in Lisbon in September, night until 08:00 there, 07:00 UTC; in January
  // it is 20:30 there, still day.
  n.set(d, { timeZone: "Europe/Lisbon" });
  assert.equal(n.due(d, at(20)), Date.UTC(2026, 8, 25, 7));
  assert.equal(n.due(d, Date.UTC(2026, 0, 14, 20, 30)), Date.UTC(2026, 0, 14, 20, 30));
});

test("a daily reminder at the time the player chose, or none (14.6)", async () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  const me = t.defender.account;
  n.set(me, { pushToken: "device-2", timeZone: "UTC", reminder: 18 * 60 });
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
  // A reminder inside the night is refused (G34); an adult who quiets the
  // night keeps no reminder inside it either.
  n.set(me, { timeZone: "UTC", pushToken: "device-3" });
  refusal(() => n.set(me, { reminder: 7 * 60 }), "reminder_at_night");
  refusal(() => n.set(me, { reminder: 21 * 60 }), "reminder_at_night");
  // A 20:55 reminder, with the raid of 20:50 inside it, not sent before the
  // night began (a late tick), waits for the night's end, once.
  n.set(me, { reminder: 20 * 60 + 55 });
  t.clock.now = Date.UTC(2026, 8, 24, 20, 50);
  n.raided({ defender: me, token: "h1" }, { grade: "clean" }, t.clock.now);
  t.clock.now = Date.UTC(2026, 8, 24, 21, 30);
  assert.deepEqual(await n.deliver(() => assert.fail("sent at night")), []);
  t.clock.now = Date.UTC(2026, 8, 25, 7, 59);
  assert.deepEqual(await n.deliver(() => assert.fail("sent at night")), []);
  t.clock.now = Date.UTC(2026, 8, 25, 8, 0);
  await n.deliver(send);
  t.clock.now = Date.UTC(2026, 8, 25, 8, 1);
  await n.deliver(send);
  assert.deepEqual(pushed, [{ kind: "reminder", day: "2026-09-24", heists: [{ heist: "h1", grade: "clean" }] }]);
});

test("the day's reminders read the outbox once a tick, however many players chose one (14.6)", () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  const players = [t.defender.account, t.raider.account];
  for (let i = 0; i < 6; i++) players.push(t.service.session(`gc:reminded-${i}`).account);
  for (const p of players) n.set(p, { timeZone: "UTC", reminder: 9 * 60 });
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
  const set = await (await call("PUT", "/v1/notifications", t.raider,
                                 { timeZone: "Europe/Lisbon", reminder: 540 })).json();
  assert.deepEqual([set.timeZone, set.reminder, set.nightQuiet], ["Europe/Lisbon", 540, true]);
});

test("a time zone is kept by its IANA name, however the device spells it, and a bare offset is refused (G34)", () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  const me = t.defender.account;
  assert.equal(canonicalZone("america/sao_paulo"), "America/Sao_Paulo");
  assert.equal(canonicalZone("UTC"), "UTC");
  for (const bad of ["+05:30", "Etc/GMT+5", "", "x".repeat(65), null]) assert.equal(canonicalZone(bad), null, String(bad));
  assert.equal(n.set(me, { timeZone: "europe/LISBON" }).timeZone, "Europe/Lisbon");
  refusal(() => n.set(me, { timeZone: "+05:30" }), "bad_time_zone");
});

test("a wall time a daylight-saving change skips lands after the gap (G34)", () => {
  // Lisbon springs forward at 01:00 UTC on 29 March 2026: 01:00 local is 02:00.
  const gap = instant("Europe/Lisbon", Date.UTC(2026, 2, 29, 1, 30));
  assert.ok(gap >= Date.UTC(2026, 2, 29, 1, 0), new Date(gap).toISOString());
  assert.equal(instant("Europe/Lisbon", Date.UTC(2026, 2, 29, 0, 30)), Date.UTC(2026, 2, 29, 0, 30));
  assert.equal(instant("Europe/Lisbon", Date.UTC(2026, 2, 29, 12, 0)), Date.UTC(2026, 2, 29, 11, 0));
});

test("a stored reminder the night comes to cover is cleared, and never blocks the rest (G34)", () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  const me = t.defender.account;
  n.set(me, { timeZone: "UTC", nightQuiet: false, reminder: 23 * 60 });
  // The adult quietens the night again: the 23:00 reminder goes, and they are told.
  const quiet = n.set(me, { nightQuiet: true });
  assert.deepEqual([quiet.reminder, quiet.nightQuiet, quiet.reminderCleared], [null, true, true]);
  // One left inside the night from before the rule does not refuse a zone or token.
  t.service.db.prepare("UPDATE accounts SET reminder_at = ? WHERE id = ?").run(22 * 60 + 30, me);
  const after = n.set(me, { timeZone: "Europe/Lisbon", pushToken: "device-9" });
  assert.deepEqual([after.timeZone, after.push, after.reminder, after.reminderCleared],
                   ["Europe/Lisbon", true, null, true]);
  // A reminder asked for inside the night is still refused.
  refusal(() => n.set(me, { reminder: 23 * 60 }), "reminder_at_night");
});

test("a changed reminder moves the day's waiting raids, and a reminder takes every raid waiting (G34)", async () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  const me = t.defender.account;
  n.set(me, { pushToken: "device-6", timeZone: "UTC" });
  t.clock.now = Date.UTC(2026, 8, 24, 10, 0);
  n.raided({ defender: me, token: "h1" }, { grade: "clean" }, t.clock.now);
  const due = () => t.service.db.prepare(
    "SELECT due_at FROM notifications WHERE account = ? AND kind = 'raided' AND sent_at IS NULL").get(me)?.due_at;
  assert.equal(due(), Date.UTC(2026, 8, 25, 8, 0), "no reminder: the night's end");
  n.set(me, { reminder: 18 * 60 });
  assert.equal(due(), Date.UTC(2026, 8, 24, 18, 0), "moved to the reminder");
  // A raid due later than the reminder still goes inside it: one message.
  t.service.db.prepare("UPDATE notifications SET due_at = ? WHERE account = ? AND kind = 'raided'")
    .run(Date.UTC(2026, 8, 25, 8, 0), me);
  const pushed = [];
  t.clock.now = Date.UTC(2026, 8, 24, 18, 0);
  await n.deliver((_, m) => pushed.push(m));
  assert.deepEqual(pushed, [{ kind: "reminder", day: "2026-09-24", heists: [{ heist: "h1", grade: "clean" }] }]);
  t.clock.now = Date.UTC(2026, 8, 25, 8, 0);
  assert.deepEqual(await n.deliver(() => assert.fail("already told")), []);
});

test("the day's raids are listed by reference: a later raid on record writes nothing, and the message still names every one (DB-4)", async () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  n.set(t.defender.account, { pushToken: "device-9", timeZone: "UTC" });
  t.clock.now = Date.UTC(2026, 8, 24, 12, 0);
  const first = raid(t, true);
  const rows = () => t.service.db.prepare("SELECT id, data FROM notifications WHERE kind = 'raided'").all();
  const stored = rows();
  t.clock.now += 3 * HOUR;
  const second = raid(t, false);
  assert.deepEqual(rows().map((r) => ({ ...r })), stored.map((r) => ({ ...r })), "the second raid wrote nothing");
  t.clock.now = Date.UTC(2026, 8, 25, 8, 0);
  const pushed = [];
  await n.deliver((_, m) => pushed.push(m));
  assert.deepEqual(pushed, [{ kind: "raided", heists: [
    { heist: first.token, grade: "clean" }, { heist: second.token, grade: "foiled" }] }]);
});
