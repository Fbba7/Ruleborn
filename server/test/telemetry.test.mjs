// First-party telemetry (§20.5, §24, §24.3, §25.3), against the real
// simulation build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { Refused } from "../src/service.mjs";
import { CLOCK_SKEW_MS, ROW_EVENTS, SESSION_ENDS_A_DAY, WORTH_A_DAY, lawsOf } from "../src/telemetry.mjs";
import { T0, openPlan, play, server, twoPlayers } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);
const DAY = 24 * 60 * 60 * 1000;
const plusDays = (d, n) => new Date(Date.parse(d) + n * DAY).toISOString().slice(0, 10);
/** A player signed in with the app in the foreground: the device's session (G29). */
const open = (t, credential) => {
  const { account } = t.service.session(credential);
  t.service.telemetry.batch(account, [{ kind: "session_start", data: {} }]);
  return account;
};
const events = (t, kind) => t.service.db.prepare("SELECT * FROM events WHERE kind = ? ORDER BY batch").all(kind);

test("the server records sign-ins, heists and purchases under a pseudonym, never the account (24, 20.5)", () => {
  const t = twoPlayers(true);
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  t.service.verifyReceipt = (store, receipt) => ({ transaction: receipt, product: "premium.1" });
  t.service.shop.redeem(t.raider.account, "app-store", "r1");
  assert.equal(events(t, "sign_in").length, 2);
  assert.equal(events(t, "session_start").length, 0, "a sign-in is not a session (G29)");
  const [heist] = events(t, "heist");
  assert.deepEqual(JSON.parse(heist.data),
                   { validated: true, grade: "clean", crew: 3, laws: lawsOf(t.island) });
  assert.deepEqual(JSON.parse(events(t, "purchase")[0].data), { product: "premium.1", cents: 600 });
  const rows = JSON.stringify(t.service.db.prepare("SELECT * FROM events").all());
  for (const account of [t.raider.account, t.defender.account]) {
    assert.ok(!rows.includes(account), "no event names an account");
  }
  assert.equal(heist.who, t.service.telemetry.pseudonym(t.raider.account));
});

test("an island's laws are read from its bundle", () => {
  const t = server();
  const bare = t.build.exampleIsland(true);
  assert.deepEqual(lawsOf(bare), []);
  // The example weaves nothing: weave Tilt at (1, 1), as the builder would,
  // by the bundle's own encoding — its last byte is the law count.
  const tilt = new TextEncoder().encode("tilt");
  const woven = new Uint8Array([...bare.subarray(0, bare.length - 1), 1, tilt.length, ...tilt, 1, 1]);
  assert.equal(t.service.builds.current.island(woven).error, undefined, "the simulation reads it too");
  assert.deepEqual(lawsOf(woven), ["tilt"]);
});

test("a device's batch is checked whole: known events, known fields, no positions, sensible times (24.3)", () => {
  const t = server();
  const me = t.service.session("gc:device").account;
  const tel = t.service.telemetry;
  assert.deepEqual(tel.batch(me, [
    { kind: "weave", data: { law: "tilt", realm: "heart" } },
    { kind: "birth", data: { form: "sprig-hush" }, at: T0 - DAY },
    { kind: "worth", data: { rating: 5 } },
    { kind: "session_end", data: { seconds: 300, crashed: false } },
  ]), { recorded: 4 });
  refusal(() => tel.batch(me, [{ kind: "weave", data: { law: "tilt", x: 3 } }]), "positions_are_never_sent");
  refusal(() => tel.batch(me, [{ kind: "heist", data: {} }]), "no_such_event");
  refusal(() => tel.batch(me, [{ kind: "worth", data: { rating: 6 } }]), "bad_field");
  refusal(() => tel.batch(me, [{ kind: "worth", data: { mood: 1 } }]), "no_such_field");
  // A device clock a little ahead is taken (AUD-B-04); one past that is refused.
  refusal(() => tel.batch(me, [{ kind: "worth", data: { rating: 4 }, at: T0 + CLOCK_SKEW_MS + 1 }]), "bad_time");
  refusal(() => tel.batch(me, [{ kind: "worth", data: { rating: 4 }, at: T0 - 8 * DAY }]), "bad_time");
  refusal(() => tel.batch(me, Array(101).fill({ kind: "worth", data: { rating: 4 } })), "batch_too_large");
  // One bad event and none of the batch is written.
  refusal(() => tel.batch(me, [{ kind: "worth", data: { rating: 4 } }, { kind: "worth", data: { rating: 0 } }]),
          "bad_field");
  assert.equal(events(t, "worth").length, 1);
});

test("an event's data is an object holding every field of its kind, and a kind is only its own (24.3)", () => {
  const t = server();
  const me = t.service.session("gc:strict").account;
  const tel = t.service.telemetry;
  for (const data of ["", 7, true, null, [], ["x"]]) {
    refusal(() => tel.batch(me, [{ kind: "session_end", data }]), "bad_data");
  }
  refusal(() => tel.batch(me, [{ kind: "worth" }]), "bad_data");
  refusal(() => tel.batch(me, [{ kind: "worth", data: {} }]), "missing_field");
  refusal(() => tel.batch(me, [{ kind: "session_end", data: { seconds: 60 } }]), "missing_field");
  for (const kind of ["constructor", "toString", "hasOwnProperty", "__proto__"]) {
    refusal(() => tel.batch(me, [{ kind, data: {} }]), "no_such_event");
  }
  refusal(() => tel.batch(me, [{ kind: "worth", data: { rating: 4, toString: 1 } }]), "no_such_field");
  refusal(() => tel.batch(me, JSON.parse('[{"kind":"worth","data":{"rating":4,"__proto__":1}}]')), "no_such_field");
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM events WHERE who = ? AND kind != 'sign_in'")
    .get(tel.pseudonym(me)).n, 0, "none of it was written");
  const day = new Date(T0).toISOString().slice(0, 10);
  assert.doesNotThrow(() => tel.report({ from: day, to: day }));
});

test("a player rates every session, weighs once in the report, and a day's ratings and session ends are bounded (20.3, 25.3)", () => {
  const t = server();
  const tel = t.service.telemetry;
  const honest = ["a", "b", "c"].map((n) => t.service.session(`gc:${n}`).account);
  for (const p of honest) tel.batch(p, [{ kind: "worth", data: { rating: 2 } }]);
  const me = t.service.session("gc:loud").account;
  const worth = (rating, at) => ({ kind: "worth", data: { rating }, ...(at ? { at } : {}) });
  refusal(() => tel.batch(me, Array(100).fill(worth(5))), "worth_too_often");
  // An honest player's second session of the day rates again (§20.3).
  tel.batch(me, [worth(5)]);
  tel.batch(me, [worth(5)]);
  tel.batch(me, Array(WORTH_A_DAY - 2).fill(worth(5)));
  refusal(() => tel.batch(me, [worth(5)]), "worth_too_often");
  // A queued rating for another day is that day's.
  assert.deepEqual(tel.batch(me, [worth(5, T0 - DAY)]), { recorded: 1 });
  const day = new Date(T0).toISOString().slice(0, 10);
  assert.equal(tel.report({ from: day, to: day }).worth, (2 + 2 + 2 + 5) / 4);
  t.clock.now += DAY;
  assert.deepEqual(tel.batch(me, [worth(5)]), { recorded: 1 });

  const end = { kind: "session_end", data: { seconds: 60, crashed: false } };
  refusal(() => tel.batch(me, Array(SESSION_ENDS_A_DAY + 1).fill(end)), "too_many_session_ends");
  assert.deepEqual(tel.batch(me, Array(SESSION_ENDS_A_DAY).fill(end)), { recorded: SESSION_ENDS_A_DAY });
  refusal(() => tel.batch(me, [end]), "too_many_session_ends");
  t.clock.now += DAY;
  assert.deepEqual(tel.batch(me, [end]), { recorded: 1 });

  // Starts are held to the same count, each against its own day.
  const start = (at) => ({ kind: "session_start", data: {}, ...(at ? { at } : {}) });
  refusal(() => tel.batch(me, Array(SESSION_ENDS_A_DAY + 1).fill(start())), "too_many_session_starts");
  assert.deepEqual(tel.batch(me, Array(SESSION_ENDS_A_DAY).fill(start())), { recorded: SESSION_ENDS_A_DAY });
  refusal(() => tel.batch(me, [start()]), "too_many_session_starts");
  assert.deepEqual(tel.batch(me, [start(t.clock.now - DAY)]), { recorded: 1 }, "yesterday's is yesterday's");
});

test("a player's first day is their earliest session, whatever order the device sends them in (G29)", () => {
  const t = server();
  const tel = t.service.telemetry;
  const me = t.service.session("gc:late").account;
  t.clock.now = T0 + 5 * DAY;
  tel.batch(me, [{ kind: "session_start", data: {} }]);
  tel.batch(me, [{ kind: "session_start", data: {}, at: T0 + 2 * DAY }, { kind: "session_start", data: {}, at: T0 + 3 * DAY }]);
  const first = () => t.service.db.prepare("SELECT day FROM first_seen WHERE who = ?").get(tel.pseudonym(me)).day;
  assert.equal(first(), new Date(T0 + 2 * DAY).toISOString().slice(0, 10));
  tel.batch(me, [{ kind: "session_start", data: {}, at: T0 + 4 * DAY }]);
  assert.equal(first(), new Date(T0 + 2 * DAY).toISOString().slice(0, 10), "a later one moves nothing");
});

test("the month's survey is offered once a quarter, answered or declined (25.4, G29)", () => {
  const t = server();
  const tel = t.service.telemetry;
  const me = t.service.session("gc:asked").account;
  assert.equal(tel.surveyDue(me), true);
  assert.equal(tel.surveyDue(me), false, "declined: not asked again this quarter");
  // An offer is no answer: the survey can still be answered.
  assert.deepEqual(tel.batch(me, [{ kind: "survey", data: { answers: Array(11).fill(4), chore: false } }]),
                   { recorded: 1 });
  t.clock.now += 91 * DAY;
  assert.equal(tel.surveyDue(me), true);
});

test("the survey's quarter runs from when the server received it, however the device dates it (25.4)", () => {
  const t = server();
  const tel = t.service.telemetry;
  const answers = Array(11).fill(4);
  const survey = (at) => ({ kind: "survey", data: { answers, chore: false }, at });
  // Dated as far back as a queue may, or sent behind a week-old event.
  const late = t.service.session("gc:late").account;
  const queued = t.service.session("gc:queued").account;
  tel.batch(late, [survey(T0 - 7 * DAY)]);
  tel.batch(queued, [{ kind: "weave", data: { law: "tilt", realm: "heart" }, at: T0 - 7 * DAY + 1 }, survey(T0)]);
  for (let d = 1; d < 90; d++) {
    t.clock.now = T0 + d * DAY;
    tel.compact();
    for (const p of [late, queued]) {
      refusal(() => tel.batch(p, [survey(t.clock.now - 7 * DAY)]), "survey_once_a_quarter");
    }
  }
  t.clock.now = T0 + 90 * DAY + 1;
  tel.compact();
  for (const p of [late, queued]) assert.deepEqual(tel.batch(p, [survey(t.clock.now)]), { recorded: 1 });
});

test("compaction keeps a day whole, however a batch spans midnight (24.3)", () => {
  const t = server();
  const tel = t.service.telemetry;
  const [a, b] = ["a", "b"].map((n) => t.service.session(`gc:${n}`).account);
  const D = new Date(T0).toISOString().slice(0, 10);
  const midnight = Date.parse(D);
  t.clock.now = midnight + 2 * 60 * 60 * 1000;
  tel.batch(a, [{ kind: "worth", data: { rating: 5 }, at: midnight - 60 * 60 * 1000 },
                { kind: "worth", data: { rating: 1 }, at: midnight + 60 * 60 * 1000 }]);
  tel.batch(b, [{ kind: "worth", data: { rating: 3 } }]);
  assert.equal(tel.report({ from: D, to: D }).worth, 2);
  // Day D - 1 is past the raw window, day D is not: D's raw events are all still there.
  t.clock.now = midnight + 90 * DAY + 60 * 60 * 1000;
  tel.compact();
  assert.equal(tel.report({ from: D, to: D }).worth, 2);
  const counted = (d) => t.service.db.prepare("SELECT events, players FROM event_days WHERE day = ? AND kind = 'worth'").get(d);
  assert.deepEqual({ ...counted(plusDays(D, -1)) }, { events: 1, players: 1 });
  assert.equal(counted(D), undefined);
  t.clock.now += DAY;
  tel.compact();
  assert.deepEqual({ ...counted(D) }, { events: 2, players: 2 }, "both of D's raters, counted together");
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM events WHERE kind = 'worth'").get().n, 0);
});

test("a player answers the survey at most once a quarter (25.4)", () => {
  const t = server();
  const me = t.service.session("gc:asked").account;
  const answers = Array(11).fill(4);
  t.service.telemetry.batch(me, [{ kind: "survey", data: { answers, chore: false } }]);
  t.clock.now += 60 * DAY;
  refusal(() => t.service.telemetry.batch(me, [{ kind: "survey", data: { answers, chore: false } }]), "survey_once_a_quarter");
  t.clock.now += 31 * DAY;
  assert.deepEqual(t.service.telemetry.batch(me, [{ kind: "survey", data: { answers, chore: false } }]), { recorded: 1 });
  refusal(() => t.service.telemetry.batch(me, [{ kind: "survey", data: { answers: [4], chore: false } }]), "bad_field");
  t.clock.now += 91 * DAY;
  refusal(() => t.service.telemetry.batch(me, [{ kind: "survey", data: { answers } }]), "missing_field");
});

test("the launch gates' figures: players, crash-free sessions, heists, worth-your-time, buyers (22.2, 25.3)", () => {
  const t = twoPlayers(true);
  const tel = t.service.telemetry;
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: [] }));
  tel.batch(t.raider.account, [{ kind: "session_start", data: {} }, { kind: "worth", data: { rating: 5 } },
                               { kind: "session_end", data: { seconds: 200, crashed: false } },
                               { kind: "session_start", data: {} },
                               { kind: "session_end", data: { seconds: 50, crashed: false } },
                               { kind: "survey", data: { answers: Array(11).fill(4), chore: true } }]);
  tel.batch(t.defender.account, [{ kind: "session_start", data: {} }, { kind: "worth", data: { rating: 3 } },
                                 { kind: "session_end", data: { seconds: 100, crashed: true } },
                                 { kind: "survey", data: { answers: Array(11).fill(6), chore: false } }]);
  t.service.verifyReceipt = (store, receipt) => ({ transaction: receipt, product: "premium.1" });
  t.service.shop.redeem(t.defender.account, "app-store", "r1");
  const day = new Date(T0).toISOString().slice(0, 10);
  const r = tel.report({ from: day, to: day });
  assert.deepEqual({ players: r.players, sessions: r.sessions, crashFree: r.crashFree, heists: r.heists,
                     worth: r.worth, buyers: r.buyers },
                   { players: 2, sessions: 3, crashFree: 2 / 3, heists: { foiled: 1 }, worth: 4, buyers: 0.5 });
  // G29: the device's sessions, their median length, and the chore question.
  assert.deepEqual([r.medianSessionSeconds, r.sessionsPerPlayerDay, r.chore], [100, 1.5, 0.5]);
});

test("retention by cohort, day 1, 7, 30 and 60, outlives the raw events discarded after 90 days (24.3, G29)", () => {
  const t = server();
  const tel = t.service.telemetry;
  const players = ["a", "b", "c", "d"].map((n) => open(t, `gc:${n}`));
  const at = (d) => { t.clock.now = T0 + d * DAY; };
  assert.equal(players.length, 4);
  at(1); for (const n of ["a", "b", "c"]) open(t, `gc:${n}`);
  at(7); open(t, "gc:a"); open(t, "gc:b");
  at(30); open(t, "gc:a"); open(t, "gc:b");
  at(60); open(t, "gc:a");
  // A sign-in alone is no return.
  t.service.session("gc:c");
  at(62);
  const day = new Date(T0).toISOString().slice(0, 10);
  const live = tel.retention(day, day);
  assert.deepEqual(live, { players: 4, day1: 0.75, day7: 0.5, day30: 0.5, day60: 0.25 });
  // Not before its day 60 has passed, and the week a device may send late.
  at(62); assert.equal(tel.compact().cohorts, 0, "a day 60 session may still be on its way");
  at(68); assert.equal(tel.compact().cohorts, 1);
  at(200); assert.ok(tel.compact().discarded > 0);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM events WHERE day = ?").get(day).n, 0);
  assert.deepEqual(tel.retention(day, day), live, "the cohort was written down before its events went");
  const kept = t.service.db.prepare("SELECT * FROM event_days WHERE day = ? AND kind = 'session_start'").get(day);
  assert.deepEqual([kept.events, kept.players], [4, 4], "and the day's counts stay");
});

test("recency of absence, the churn early warning, in bands (25.3)", () => {
  const t = server();
  open(t, "gc:here");
  t.clock.now = T0 + 10 * DAY;
  open(t, "gc:back");
  t.clock.now = T0 + 12 * DAY;
  assert.deepEqual(t.service.telemetry.absence(), { "0-1": 0, "2-3": 1, "4-7": 0, "8-14": 1, "15+": 0 });
});

test("telemetry over HTTP: a batch from the device, and the report for analysts only", async () => {
  const t = server();
  const call = (method, path, { token, json } = {}) => t.handle(new Request(`https://edge.example${path}`, {
    method,
    headers: { ...(token ? { authorization: `Bearer ${token}` } : {}),
               ...(json ? { "content-type": "application/json" } : {}) },
    body: json ? JSON.stringify(json) : undefined,
  }));
  const me = await (await call("POST", "/v1/session", { json: { credential: "gc:phone" } })).json();
  const sent = await call("POST", "/v1/events", { token: me.token,
                                                  json: [{ kind: "session_start", data: {} },
                                                         { kind: "worth", data: { rating: 4 } }] });
  assert.equal(sent.status, 202);
  const day = new Date(T0).toISOString().slice(0, 10);
  assert.equal((await call("GET", `/v1/metrics?from=${day}&to=${day}`, { token: me.token })).status, 403);
  t.service.db.prepare("UPDATE accounts SET analyst = 1 WHERE id = ?").run(me.account);
  const report = await (await call("GET", `/v1/metrics?from=${day}&to=${day}`, { token: me.token })).json();
  assert.deepEqual([report.players, report.worth], [1, 4]);
  // G29's rotating sample: this player is asked once, then not for a
  // quarter, answered or not.
  assert.deepEqual(await (await call("GET", "/v1/survey", { token: me.token })).json(), { due: true });
  await call("POST", "/v1/events", { token: me.token,
                                     json: [{ kind: "survey", data: { answers: Array(11).fill(5), chore: false } }] });
  assert.deepEqual(await (await call("GET", "/v1/survey", { token: me.token })).json(), { due: false });
  const absence = await (await call("GET", "/v1/metrics/absence", { token: me.token })).json();
  assert.equal(absence["0-1"], 1);
});

test("a player's day of events is one row: the first write makes it, every later one appends to it in one written row (24.1, F47)", () => {
  const t = server();
  const db = t.service.db;
  const me = t.service.session("gc:frugal").account;            // the day's sign-in makes the row
  const rows = () => db.prepare("SELECT COUNT(*) AS n FROM event_batches").get().n;
  const changes = () => Number(db.prepare("SELECT total_changes() AS n").get().n);
  const before = [rows(), changes()];
  t.service.telemetry.batch(me, [{ kind: "worth", data: { rating: 5 } },
                                 { kind: "weave", data: { law: "tilt", realm: "heart" } },
                                 { kind: "session_end", data: { seconds: 60, crashed: false } }]);
  assert.deepEqual([rows() - before[0], changes() - before[1]], [0, 1], "a batch appended: no new row, one row written");
  assert.equal(events(t, "weave").length, 1, "and read back event by event");
  assert.equal(events(t, "sign_in").length, 1, "beside the sign-in it joined");
  // Another player's events never join this one's row.
  t.service.session("gc:other");
  assert.equal(rows() - before[0], 1);
  // The next day starts a row of its own.
  t.clock.now += 24 * 60 * 60 * 1000;
  t.service.telemetry.batch(me, [{ kind: "worth", data: { rating: 4 } }]);
  assert.equal(rows() - before[0], 2);
  // An event queued from the day before, appended today, moves the row's day
  // back to it, so compaction still finds every event by its row's day.
  t.service.telemetry.batch(me, [{ kind: "weave", data: { law: "tilt", realm: "heart" }, at: t.clock.now - 20 * 60 * 60 * 1000 }]);
  const days = db.prepare("SELECT day FROM event_batches WHERE who = ? ORDER BY id").all(t.service.telemetry.pseudonym(me))
    .map((r) => r.day);
  assert.equal(days[1], days[0], "the second row's day is its earliest event's");
  // A full row is not added to: the next write starts another.
  const full = Array.from({ length: ROW_EVENTS }, () => ({ kind: "weave", data: { law: "tilt", realm: "heart" } }));
  db.prepare("UPDATE event_batches SET events = ? WHERE id = (SELECT MAX(id) FROM event_batches)").run(
    JSON.stringify(full.map((e) => ({ ...e, at: t.clock.now }))));
  t.service.telemetry.batch(me, [{ kind: "weave", data: { law: "tilt", realm: "heart" } }]);
  assert.equal(rows() - before[0], 3);
});

test("compaction counts and discards an appended row's old events and keeps its newer ones (24.3)", () => {
  const t = server();
  const db = t.service.db;
  const me = t.service.session("gc:long").account;

  // A day's row, and an event from six days before it appended to it.
  t.clock.now += 100 * DAY;
  t.service.telemetry.batch(me, [{ kind: "worth", data: { rating: 5 }, at: t.clock.now - 6 * DAY }]);
  t.service.telemetry.batch(me, [{ kind: "worth", data: { rating: 4 } }]);
  // Ninety days and three later, the old event is past the window and the new one is not.
  t.clock.now += 87 * DAY;
  const out = t.service.telemetry.compact();
  assert.ok(out.discarded >= 1);
  const left = events(t, "worth").map((e) => JSON.parse(e.data).rating);
  assert.deepEqual(left, [4], "the newer event stays, in its row");
});

test("telemetry written a row an event, before batching, is kept as batches of one (24.1)", async () => {
  const { mkdtempSync, rmSync } = await import("node:fs");
  const { tmpdir } = await import("node:os");
  const { join } = await import("node:path");
  const { DatabaseSync } = await import("node:sqlite");
  const { open } = await import("../src/db.mjs");
  const dir = mkdtempSync(join(tmpdir(), "ruleborn-"));
  try {
    const path = join(dir, "old.db");
    const old = new DatabaseSync(path);
    old.exec(`CREATE TABLE events (id INTEGER PRIMARY KEY AUTOINCREMENT, who TEXT NOT NULL, kind TEXT NOT NULL,
                data TEXT NOT NULL, at INTEGER NOT NULL, day TEXT NOT NULL);
              CREATE INDEX events_by_day ON events (kind, day);
              INSERT INTO events (who, kind, data, at, day) VALUES ('w', 'worth', '{"rating":3}', ${T0}, '2026-09-23');`);
    old.close();
    const db = open(path);
    const [row] = db.prepare("SELECT who, kind, data, at, day FROM events").all();
    assert.deepEqual({ ...row }, { who: "w", kind: "worth", data: '{"rating":3}', at: T0, day: "2026-09-23" });
    db.close();
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("an event kind is a string: an array naming one is refused, not counted past the caps", () => {
  const t = server();
  const me = t.service.session("gc:sly").account;
  refusal(() => t.service.telemetry.batch(me, [{ kind: ["survey"], data: { answers: Array(11).fill(1) } }]),
          "no_such_event");
  refusal(() => t.service.telemetry.batch(me, [{ kind: ["worth"], data: { rating: 5 } }]), "no_such_event");
});
