// FX2-2's fixes, each test first failing on main: RB-31 and RB-49 (the
// Trace and the Observatory's offer), RB-32 (telemetry refusals the device
// can drop), RB-21 (full_at while a worker rests), and the report's
// unproven candidate 21 (a banned raider's island as a Trace).

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { SESSION_ENDS_A_DAY } from "../src/telemetry.mjs";
import { Workshop } from "../src/workshop.mjs";
import { T0, established, openPlan, play, server, twoPlayers } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const MINUTE = 60_000;
const HOUR = 60 * MINUTE;

const keeper6 = (t, account) => t.service.db.prepare("UPDATE accounts SET keeper_level = 6 WHERE id = ?").run(account);
const islandOf = (t) => { const i = t.build.exampleIsland(true); i[5] = 2; return i; };

/** `account` robs the defender's island, with an open plan: a raid that is
 *  not foiled, so the defender may Trace them. */
function rob(t, account) {
  const lease = t.service.lease(account, t.bundle);
  const out = t.service.submit(account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.notEqual(out.verdict.grade, "foiled");
  return out;
}

/** A raider with a home of their own, who robs the defender. */
function robbed() {
  const t = twoPlayers(true);
  established(t, t.raider.account);
  keeper6(t, t.raider.account);
  const home = t.service.publish(t.raider.account, islandOf(t)).bundle;
  rob(t, t.raider.account);
  keeper6(t, t.defender.account);
  return { t, home };
}

test("RB-31: the Trace's island is not also offered as a paid target, so tapping the Trace leases it free", () => {
  const { t, home } = robbed();
  const v = t.service.observatory.view(t.defender.account);
  assert.equal(v.trace?.bundle, home, "the raider's island is the Trace");
  assert.deepEqual(v.targets.filter((c) => c.bundle === v.trace.bundle).map((c) => c.kind), [],
                   "and not among the targets the device matches the Trace's bundle against");
  const lease = t.service.lease(t.defender.account, v.trace.bundle, null, { trace: true });
  assert.deepEqual([lease.trace, lease.fee], [true, 0], "a free Trace lease");
});

test("RB-49: the Trace points at the most recent raider, not at one ordered by an older heist of theirs", () => {
  const t = twoPlayers(true);
  const [a, b] = ["gc:a", "gc:b"].map((c) => t.service.session(c).account);
  const homes = {};
  for (const who of [a, b]) {
    established(t, who);
    keeper6(t, who);
    homes[who] = t.service.publish(who, islandOf(t)).bundle;
  }
  keeper6(t, t.defender.account);
  // Within 24 hours: A robs D at -3 h, B at -2 h, and A again at -1 h.
  rob(t, a);
  t.clock.now += HOUR;
  rob(t, b);
  t.clock.now += HOUR;
  rob(t, a);
  t.clock.now += HOUR;
  const raids = t.service.db.prepare("SELECT attacker FROM heists WHERE defender = ? ORDER BY submitted_at")
    .all(t.defender.account).map((r) => r.attacker);
  assert.deepEqual(raids, [a, b, a], "the three raids, in order");
  const db = t.service.db;
  const trace = () => t.service.observatory.view(t.defender.account).trace?.bundle;
  assert.equal(trace(), homes[a], "A, the most recent raider");
  // SELECT DISTINCT with an ORDER BY on a column it does not select leaves
  // which of A's heists orders A to the plan SQLite picks. This build's
  // plans happen to put A first; the query must not lean on them. Without
  // the defender's index the planner reads the heists in the table's order,
  // and SQLite's reverse_unordered_selects, made for finding queries that
  // lean on such an order, reads them the other way. A is the most recent
  // raider in every order.
  db.exec("DROP INDEX heists_by_defender");
  for (const reverse of [0, 1]) {
    db.exec(`PRAGMA reverse_unordered_selects = ${reverse}`);
    assert.equal(trace(), homes[a], `A, the most recent raider, whatever order the heists are read in (${reverse})`);
  }
});

test("RB-21: full_at counts a resting worker from the end of its rest, never null while the store can still fill", () => {
  const t = server();
  const me = t.service.session("gc:keeper").account;
  const h = t.service.home;
  t.service.db.prepare("UPDATE characters SET traits = '[]' WHERE owner = ?").run(me);
  const worker = h.show(me).characters.find((c) => c.kind === "tidewalker").id;
  const star = () => h.show(me).producers.find((p) => p.realm === "heart" && p.kind === "star_well");
  const start = t.clock.now;
  h.work(me, worker, { realm: "heart", kind: "star_well" });
  const full = start + facts.PRODUCTION_START_MINUTES * MINUTE + facts.PRODUCER_HOLD_HOURS * HOUR;
  t.clock.now += HOUR;
  assert.equal(star().full_at, full, "working: twelve hours after it started counting");
  // The worker goes on a heist and rests for two hours; the store waits.
  t.service.db.prepare("UPDATE characters SET away_from = ?, away_until = ? WHERE id = ?")
    .run(t.clock.now, t.clock.now + 2 * HOUR, worker);
  assert.equal(h.show(me).characters.find((c) => c.id === worker).state, "resting");
  assert.equal(star().full_at, full + 2 * HOUR, "resting: the same fill, two hours later");
  assert.deepEqual(star().workers, [], "and the worker is not counted as working now");
});

test("RB-32: a device that drops a chunk the server will never take, and retries the rest, drains a queue of 60 offline sessions", async () => {
  const t = server();
  const call = (path, { token, json }) => t.handle(new Request(`https://edge.example${path}`, {
    method: "POST",
    headers: { ...(token ? { authorization: `Bearer ${token}` } : {}), "content-type": "application/json" },
    body: JSON.stringify(json),
  }));
  // Sixty sessions played offline earlier today: 120 events queued.
  t.clock.now = T0 + 12 * HOUR;
  const me = await (await call("/v1/session", { json: { credential: "gc:offline" } })).json();
  const queue = [];
  for (let i = 0; i < 60; i++) {
    const at = T0 + i * 5 * MINUTE;
    queue.push({ kind: "session_start", data: {}, at },
               { kind: "session_end", data: { seconds: 120, crashed: false }, at: at + 2 * MINUTE });
  }
  // The device's rule (FX4-2-trace-events): chunks of at most 100; a chunk
  // refused with a 4xx other than 429 is dropped, as it will never be taken;
  // 429 and 5xx keep it to retry.
  const statuses = [];
  for (let attempt = 0; attempt < 5 && queue.length; attempt++) {
    const chunk = queue.slice(0, 100);
    const r = await call("/v1/events", { token: me.token, json: chunk });
    statuses.push(`${r.status} ${r.status === 202 ? "" : (await r.json()).error}`.trim());
    const transient = r.status === 429 || r.status >= 500;
    if (!transient) queue.splice(0, chunk.length);
  }
  assert.deepEqual(queue.length, 0, `the queue drains: ${statuses.join(", ")}`);
  // The day's cap still holds: what it took is within it.
  const kept = t.service.db.prepare("SELECT COUNT(*) AS n FROM events WHERE kind = 'session_start'").get().n;
  assert.ok(kept > 0 && kept <= SESSION_ENDS_A_DAY, `some sessions kept, at most a day's: ${kept}`);
});

test("RB-32: a refusal the same batch can never get past is not a 429, which the device reads as 'wait and send it again'", () => {
  const t = server();
  const me = t.service.session("gc:caps").account;
  const tel = t.service.telemetry;
  const status = (events) => { try { tel.batch(me, events); return 202; } catch (e) { return `${e.status} ${e.reason}`; } };
  const many = (kind, data, n) => Array.from({ length: n }, () => ({ kind, data }));
  assert.equal(status(many("session_start", {}, 25)), "422 too_many_session_starts");
  assert.equal(status(many("session_end", { seconds: 1, crashed: false }, 25)), "422 too_many_session_ends");
  assert.equal(status(many("worth", { rating: 3 }, 25)), "422 worth_too_often");
  const survey = { kind: "survey", data: { answers: Array(11).fill(4), chore: false } };
  assert.equal(status([survey, survey]), "422 survey_once_a_quarter");
  assert.equal(status([survey]), 202);
  assert.equal(status([survey]), "422 survey_once_a_quarter");
  for (let i = 0; i < 3; i++) assert.equal(status(many("weave", { law: "tilt", realm: "heart" }, 100)), 202);
  assert.equal(status(many("weave", { law: "tilt", realm: "heart" }, 100)), "422 too_many_events");
});

test("candidate 21: a banned raider's island is not offered as a Trace the lease would refuse", () => {
  const { t } = robbed();
  assert.ok(t.service.observatory.view(t.defender.account).trace, "a Trace before the ban");
  new Workshop(t.service).ban(t.raider.account, "cheating");
  const v = t.service.observatory.view(t.defender.account);
  assert.equal(v.trace, null, "no Trace to a banned raider");
});
