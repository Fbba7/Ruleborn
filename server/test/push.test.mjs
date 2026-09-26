// Push through Firebase Cloud Messaging (§14.6, §24.1; D68): the message a
// device is sent, what each of FCM's answers does to the outbox, and a raid
// that lands while a notification is on its way.

import assert from "node:assert/strict";
import { generateKeyPairSync } from "node:crypto";
import { test } from "node:test";

import { ServiceAccount } from "../src/googleapi.mjs";
import { RETRY_ATTEMPTS, RETRY_MS } from "../src/notifications.mjs";
import { FCM_SCOPE, Fcm } from "../src/push.mjs";
import { twoPlayers } from "./setup.mjs";

const KEY = generateKeyPairSync("rsa", { modulusLength: 2048 });
const serviceAccount = { client_email: "push@ruleborn.iam.gserviceaccount.com", project_id: "ruleborn-live",
  private_key: KEY.privateKey.export({ type: "pkcs8", format: "pem" }), token_uri: "https://oauth2.googleapis.com/token" };

/** FCM as a fetch: answers in turn, and every call made. */
function fcmServer(answers = []) {
  const calls = [];
  const fetch = async (url, init = {}) => {
    if (url === "https://oauth2.googleapis.com/token") {
      calls.push({ url, scope: new URLSearchParams(init.body).get("assertion") ? "token" : null });
      return Response.json({ access_token: "at", expires_in: 3600 });
    }
    calls.push({ url, auth: init.headers.authorization, body: JSON.parse(init.body) });
    const next = answers.length ? answers.shift() : { status: 200, json: { name: "projects/x/messages/1" } };
    if (next === "throw") throw new Error("network down");
    return Response.json(next.json ?? {}, { status: next.status });
  };
  return { fetch, calls };
}
const fcmWith = (server) => new Fcm({ account: new ServiceAccount({ serviceAccount, fetch: server.fetch }), projectId: "ruleborn-live" });

test("a device is sent localisation keys to show and the notification as data, as the project's service account (14.6, D68)", async () => {
  const server = fcmServer();
  const fcm = fcmWith(server);
  const m = { kind: "raided", heists: [{ heist: "h1", grade: "clean" }, { heist: "h2", grade: "foiled" }] };
  assert.deepEqual(await fcm.send("device-1", m), { ok: true });
  const sent = server.calls.find((c) => c.url.includes("fcm.googleapis.com"));
  assert.equal(sent.url, "https://fcm.googleapis.com/v1/projects/ruleborn-live/messages:send");
  assert.equal(sent.auth, "Bearer at");
  const { message } = sent.body;
  assert.equal(message.token, "device-1");
  assert.ok(Object.values(message.data).every((v) => typeof v === "string"), "FCM data values are strings");
  assert.deepEqual(message.data, { kind: "raided", count: "2", latest: "h2" });
  assert.deepEqual([message.android.priority, message.android.collapse_key, message.apns.headers["apns-collapse-id"]],
                   ["high", "raided", "raided"], "a reminder never replaces a raid");
  assert.deepEqual([message.android.notification.body_loc_key, message.android.notification.body_loc_args],
                   ["ruleborn_raided_body", ["2"]]);
  assert.equal(message.apns.payload.aps.alert["loc-key"], "ruleborn_raided_body");
  assert.equal(FCM_SCOPE, "https://www.googleapis.com/auth/firebase.messaging");
  assert.throws(() => new Fcm({ account: null, projectId: "../evil" }));
});

test("each of FCM's answers is sent, gone, tried again or refused for good (D68)", async () => {
  const cases = [
    [{ status: 200 }, { ok: true }],
    [{ status: 404, json: { error: { status: "NOT_FOUND" } } }, { gone: true }],
    [{ status: 400, json: { error: { status: "INVALID_ARGUMENT",
      details: [{ "@type": "type.googleapis.com/google.firebase.fcm.v1.FcmError", errorCode: "UNREGISTERED" }] } } }, { gone: true }],
    [{ status: 400, json: { error: { status: "INVALID_ARGUMENT", details: [{ "@type": "type.googleapis.com/google.rpc.BadRequest",
      fieldViolations: [{ field: "message.token", description: "Invalid registration token" }] }] } } }, { gone: true }],
    [{ status: 429 }, { retry: true, status: 429, code: null }],
    [{ status: 503, json: { error: { status: "UNAVAILABLE" } } }, { retry: true, status: 503, code: "UNAVAILABLE" }],
    [{ status: 403, json: { error: { status: "PERMISSION_DENIED" } } }, { retry: true, status: 403, code: "PERMISSION_DENIED" }],
    ["throw", { retry: true, reason: "network" }],
    [{ status: 400, json: { error: { status: "INVALID_ARGUMENT" } } }, { dropped: true, status: 400, code: "INVALID_ARGUMENT" }],
  ];
  for (const [answer, want] of cases) {
    const fcm = fcmWith(fcmServer([answer]));
    assert.deepEqual(await fcm.send("device-1", { kind: "reminder", day: "2026-09-24" }), want, JSON.stringify(answer));
  }
});

/** A defender with a device and one raid waiting to be sent. */
function waiting() {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  n.set(t.defender.account, { pushToken: "device-1", timeZone: "UTC" });
  t.clock.now = Date.UTC(2026, 8, 24, 12, 0);
  n.raided({ defender: t.defender.account, token: "h1" }, { grade: "clean" }, t.clock.now);
  // The day's raids are told when the night ends (G34).
  t.clock.now = Date.UTC(2026, 8, 25, 8, 0);
  const row = () => ({ ...t.service.db.prepare("SELECT * FROM notifications WHERE account = ? ORDER BY id").get(t.defender.account) });
  const token = () => t.service.db.prepare("SELECT push_token FROM accounts WHERE id = ?").get(t.defender.account).push_token;
  return { t, n, row, token };
}

test("a token FCM no longer knows is cleared, and nothing is sent to it again (D68)", async () => {
  const { n, row, token } = waiting();
  assert.deepEqual(await n.deliver(async () => ({ gone: true })), []);
  assert.equal(token(), null);
  assert.ok(row().sent_at, "done with: there is nobody to send it to");
});

test("a notification FCM cannot take now is tried again later, and given up after six tries (D68)", async () => {
  const { t, n, row } = waiting();
  let tries = 0;
  const busy = async () => { tries++; return { retry: true }; };
  await n.deliver(busy);
  assert.deepEqual([tries, row().sent_at, row().attempts, row().due_at], [1, null, 1, t.clock.now + RETRY_MS]);
  await n.deliver(busy);
  assert.equal(tries, 1, "not before its time");
  for (let i = 1; i < RETRY_ATTEMPTS; i++) {
    t.clock.now = row().due_at;
    await n.deliver(busy);
  }
  assert.equal(tries, RETRY_ATTEMPTS);
  assert.ok(row().sent_at, "given up");
  t.clock.now += 24 * 60 * 60 * 1000;
  await n.deliver(busy);
  assert.equal(tries, RETRY_ATTEMPTS);
});

test("a notification FCM refuses for good is not sent twice, and the token stays (D68)", async () => {
  const { n, row, token } = waiting();
  let tries = 0;
  assert.deepEqual(await n.deliver(async () => { tries++; return { dropped: true }; }), []);
  await n.deliver(async () => { tries++; });
  assert.deepEqual([tries, Boolean(row().sent_at), token()], [1, true, "device-1"]);
});

test("a raid that lands while a notification is on its way gets its own, and ticks do not overlap (13, 14.6)", async () => {
  const { t, n } = waiting();
  const pushed = [];
  let during;
  const slow = async (_, m) => {
    // Another heist settles, and another tick fires, before FCM answers.
    n.raided({ defender: t.defender.account, token: "h2" }, { grade: "foiled" }, t.clock.now);
    during = await n.deliver(() => assert.fail("a second tick sends nothing while one is sending"));
    pushed.push(m.heists.map((h) => h.heist));
  };
  await n.deliver(slow);
  assert.deepEqual(during, []);
  await n.deliver(async (_, m) => { pushed.push(m.heists.map((h) => h.heist)); });
  assert.deepEqual(pushed, [["h1"], ["h2"]], "h2 is sent, not lost in the one already sent");
});

test("a notification expires when the player's night begins, so an asleep phone never shows it in the night (20.2, D68)", async () => {
  const { t, n } = waiting();
  const me = t.defender.account;
  t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(me);
  const at = Date.UTC(2026, 8, 24, 20, 50);
  assert.equal(n.expires(me, "reminder", at), Date.UTC(2026, 8, 24, 21, 0), "a minor's night at 21:00");
  assert.equal(n.expires(me, "raided", Date.UTC(2026, 8, 24, 9, 0)), Date.UTC(2026, 8, 24, 21, 0));
  n.set(me, { timeZone: "America/Sao_Paulo" });
  assert.equal(n.expires(me, "raided", at), Date.UTC(2026, 8, 25, 0, 0), "21:00 in Brasília is midnight UTC");
  t.service.db.prepare("UPDATE accounts SET age_band = '18+', night_quiet = 0 WHERE id = ?").run(me);
  n.set(me, { timeZone: "UTC" });
  assert.equal(n.expires(me, "reminder", at), Date.UTC(2026, 8, 25, 0, 0), "an adult's open night: the day's end");
  assert.equal(n.expires(me, "raided", at), at + 24 * 60 * 60 * 1000, "a day at most");
  // On the wire: FCM's ttl and Apple's expiration.
  const server = fcmServer();
  await fcmWith(server).send("d", { kind: "reminder", day: "2026-09-24" }, { expiresAt: Date.UTC(2026, 8, 24, 21, 0), now: at });
  const { message } = server.calls.find((c) => c.url.includes("fcm")).body;
  assert.deepEqual([message.android.ttl, message.apns.headers["apns-expiration"]],
                   ["600s", String(Date.UTC(2026, 8, 24, 21, 0) / 1000)]);
});

test("a night of raids stays one small message, whatever the count (D68)", () => {
  const fcm = new Fcm({ account: null, projectId: "ruleborn-live" });
  const heists = Array.from({ length: 500 }, (_, i) => ({ heist: i.toString(16).padStart(32, "0"), grade: "clean" }));
  const m = fcm.message("device-1", { kind: "raided", heists });
  assert.ok(Buffer.byteLength(JSON.stringify(m.message.data)) < 200);
  assert.equal(m.message.data.count, "500");
});

test("each send reads the clock and the token as they are then, not as the tick began (20.2, D68)", async () => {
  const t = twoPlayers(true);
  const n = t.service.notifications;
  const a = t.defender.account;
  const b = t.raider.account;
  for (const p of [a, b]) {
    t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(p);
    n.set(p, { pushToken: `device-${p}`, timeZone: "UTC", reminder: 20 * 60 + 59 });
  }
  // Both reminders fall due a minute before a minor's night.
  t.clock.now = Date.UTC(2026, 8, 24, 20, 59);
  const to = [];
  // FCM answers slowly: the first push takes two minutes, into the night.
  await n.deliver(async (token) => { to.push(token); t.clock.now += 2 * 60 * 1000; });
  assert.deepEqual(to, [`device-${a}`], "the second waits for the morning");
  const held = t.service.db.prepare("SELECT due_at FROM notifications WHERE account = ?").get(b).due_at;
  assert.equal(held, Date.UTC(2026, 8, 25, 8, 0));
  // A token turned off while an earlier push is on its way is not used.
  // Two are due in the tick: b's held reminder, and a notification for a.
  t.clock.now = Date.UTC(2026, 8, 25, 8, 0);
  const dueForA = () => t.service.db.prepare(
    "INSERT INTO notifications (account, kind, data, due_at) VALUES (?, 'raided', ?, ?)")
    .run(a, JSON.stringify({ heists: [{ heist: "h3", grade: "clean" }] }), t.clock.now);
  dueForA();
  const used = [];
  await n.deliver(async (token) => {
    used.push(token);
    if (used.length === 1) n.set(token === `device-${a}` ? b : a, { pushToken: null });
  });
  assert.equal(used.length, 1, "the second's token was turned off meanwhile");
  // And with nothing turned off, both go in the one tick.
  n.set(a, { pushToken: `device-${a}` });
  n.set(b, { pushToken: `device-${b}` });
  t.clock.now = Date.UTC(2026, 8, 25, 9, 0);
  dueForA();
  t.service.db.prepare("INSERT INTO notifications (account, kind, data, due_at) VALUES (?, 'raided', ?, ?)")
    .run(b, JSON.stringify({ heists: [{ heist: "h4", grade: "clean" }] }), t.clock.now);
  const both = [];
  await n.deliver(async (token) => { both.push(token); });
  assert.deepEqual(both.sort(), [`device-${a}`, `device-${b}`].sort());
});

test("a reminder carrying the day's raids says so, and a plain one does not (G34, D68)", () => {
  const fcm = new Fcm({ account: null, projectId: "ruleborn-live" });
  const merged = fcm.message("d", { kind: "reminder", day: "2026-09-24",
                                    heists: [{ heist: "h1", grade: "clean" }, { heist: "h2", grade: "foiled" }] });
  assert.deepEqual([merged.message.android.notification.title_loc_key, merged.message.android.notification.body_loc_key,
                    merged.message.android.notification.body_loc_args],
                   ["ruleborn_reminder_raided_title", "ruleborn_reminder_raided_body", ["2"]]);
  assert.deepEqual(merged.message.data, { kind: "reminder", count: "2", latest: "h2", day: "2026-09-24" });
  const plain = fcm.message("d", { kind: "reminder", day: "2026-09-24" });
  assert.deepEqual([plain.message.android.notification.body_loc_key, plain.message.apns.payload.aps.alert["loc-args"]],
                   ["ruleborn_reminder_body", []]);
});

test("a tick says why pushes were tried again or given up, never naming a token (D68)", async () => {
  const { t, n } = waiting();
  await n.deliver(async () => ({ retry: true, status: 403, code: "PERMISSION_DENIED" }));
  assert.deepEqual(n.tick.retried, { "403 PERMISSION_DENIED": 1 });
  const main = (await import("node:fs")).readFileSync(new URL("../src/main.mjs", import.meta.url), "utf8");
  assert.match(main, /push \$\{label\}: \$\{tally\(map\)\}/);
  assert.ok(t);
});
