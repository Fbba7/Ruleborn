// First-party telemetry (§20.5, §24, §24.3, §25.3), against the real
// simulation build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { Refused } from "../src/service.mjs";
import { lawsOf } from "../src/telemetry.mjs";
import { T0, openPlan, play, server, twoPlayers } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);
const DAY = 24 * 60 * 60 * 1000;
const events = (t, kind) => t.service.db.prepare("SELECT * FROM events WHERE kind = ? ORDER BY batch").all(kind);

test("the server records sessions, heists and purchases under a pseudonym, never the account (24, 20.5)", () => {
  const t = twoPlayers(true);
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  t.service.verifyReceipt = (store, receipt) => ({ transaction: receipt, product: "starglass-1" });
  t.service.shop.redeem(t.raider.account, "app-store", "r1");
  assert.equal(events(t, "session").length, 2);
  const [heist] = events(t, "heist");
  assert.deepEqual(JSON.parse(heist.data),
                   { validated: true, grade: "clean", crew: 3, laws: lawsOf(t.island) });
  assert.deepEqual(JSON.parse(events(t, "purchase")[0].data), { product: "starglass-1", cents: 100 });
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
  refusal(() => tel.batch(me, [{ kind: "worth", data: { rating: 4 }, at: T0 + 1 }]), "bad_time");
  refusal(() => tel.batch(me, [{ kind: "worth", data: { rating: 4 }, at: T0 - 8 * DAY }]), "bad_time");
  refusal(() => tel.batch(me, Array(101).fill({ kind: "worth", data: { rating: 4 } })), "batch_too_large");
  // One bad event and none of the batch is written.
  refusal(() => tel.batch(me, [{ kind: "worth", data: { rating: 4 } }, { kind: "worth", data: { rating: 0 } }]),
          "bad_field");
  assert.equal(events(t, "worth").length, 1);
});

test("a player answers the survey at most once a quarter (25.4)", () => {
  const t = server();
  const me = t.service.session("gc:asked").account;
  const answers = Array(11).fill(4);
  t.service.telemetry.batch(me, [{ kind: "survey", data: { answers } }]);
  t.clock.now += 60 * DAY;
  refusal(() => t.service.telemetry.batch(me, [{ kind: "survey", data: { answers } }]), "survey_once_a_quarter");
  t.clock.now += 31 * DAY;
  assert.deepEqual(t.service.telemetry.batch(me, [{ kind: "survey", data: { answers } }]), { recorded: 1 });
  refusal(() => t.service.telemetry.batch(me, [{ kind: "survey", data: { answers: [4] } }]), "bad_field");
});

test("the launch gates' figures: players, crash-free sessions, heists, worth-your-time, buyers (22.2, 25.3)", () => {
  const t = twoPlayers(true);
  const tel = t.service.telemetry;
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: [] }));
  tel.batch(t.raider.account, [{ kind: "worth", data: { rating: 5 } },
                               { kind: "session_end", data: { seconds: 200, crashed: false } }]);
  tel.batch(t.defender.account, [{ kind: "worth", data: { rating: 3 } },
                                 { kind: "session_end", data: { seconds: 100, crashed: true } }]);
  t.service.verifyReceipt = (store, receipt) => ({ transaction: receipt, product: "starglass-5" });
  t.service.shop.redeem(t.defender.account, "app-store", "r1");
  const day = new Date(T0).toISOString().slice(0, 10);
  const r = tel.report({ from: day, to: day });
  assert.deepEqual({ players: r.players, sessions: r.sessions, crashFree: r.crashFree, heists: r.heists,
                     worth: r.worth, buyers: r.buyers },
                   { players: 2, sessions: 2, crashFree: 0.5, heists: { foiled: 1 }, worth: 4, buyers: 0.5 });
});

test("retention by cohort, day 1, 7 and 30, outlives the raw events discarded after 90 days (24.3)", () => {
  const t = server();
  const tel = t.service.telemetry;
  const players = ["a", "b", "c", "d"].map((n) => t.service.session(`gc:${n}`).account);
  const at = (d) => { t.clock.now = T0 + d * DAY; };
  assert.equal(players.length, 4);
  at(1); for (const n of ["a", "b", "c"]) t.service.session(`gc:${n}`);
  at(7); t.service.session("gc:a"); t.service.session("gc:b");
  at(30); t.service.session("gc:a");
  at(40);
  const day = new Date(T0).toISOString().slice(0, 10);
  const live = tel.retention(day, day);
  assert.deepEqual(live, { players: 4, day1: 0.75, day7: 0.5, day30: 0.25 });
  at(40); assert.equal(tel.compact().cohorts, 1);
  at(200); assert.ok(tel.compact().discarded > 0);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM events WHERE day = ?").get(day).n, 0);
  assert.deepEqual(tel.retention(day, day), live, "the cohort was written down before its events went");
  const kept = t.service.db.prepare("SELECT * FROM event_days WHERE day = ? AND kind = 'session'").get(day);
  assert.deepEqual([kept.events, kept.players], [4, 4], "and the day's counts stay");
});

test("recency of absence, the churn early warning, in bands (25.3)", () => {
  const t = server();
  t.service.session("gc:here");
  t.clock.now = T0 + 10 * DAY;
  t.service.session("gc:back");
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
  const sent = await call("POST", "/v1/events", { token: me.token, json: [{ kind: "worth", data: { rating: 4 } }] });
  assert.equal(sent.status, 202);
  const day = new Date(T0).toISOString().slice(0, 10);
  assert.equal((await call("GET", `/v1/metrics?from=${day}&to=${day}`, { token: me.token })).status, 403);
  t.service.db.prepare("UPDATE accounts SET analyst = 1 WHERE id = ?").run(me.account);
  const report = await (await call("GET", `/v1/metrics?from=${day}&to=${day}`, { token: me.token })).json();
  assert.deepEqual([report.players, report.worth], [1, 4]);
  const absence = await (await call("GET", "/v1/metrics/absence", { token: me.token })).json();
  assert.equal(absence["0-1"], 1);
});

test("a device's batch is one row written, however many events it holds (24.1)", () => {
  const t = server();
  const me = t.service.session("gc:frugal").account;
  const rows = () => t.service.db.prepare("SELECT COUNT(*) AS n FROM event_batches").get().n;
  const before = rows();
  t.service.telemetry.batch(me, [{ kind: "worth", data: { rating: 5 } },
                                 { kind: "weave", data: { law: "tilt", realm: "heart" } },
                                 { kind: "session_end", data: { seconds: 60, crashed: false } }]);
  assert.equal(rows() - before, 1);
  assert.equal(events(t, "weave").length, 1, "and read back event by event");
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
