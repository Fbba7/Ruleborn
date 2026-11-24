// FX1-3-workshop: the fail-first tests for RB-35, RB-37, RB-38 and RB-39 of
// docs/security/bug-report-2026-11.md, each reproducing the entry's Input.

import assert from "node:assert/strict";
import { test } from "node:test";

import { quarterOf } from "../src/fund.mjs";
import { TICKS_PER_SECOND, clockTicks } from "../src/service.mjs";
import { Build, Builds } from "../src/sim.mjs";
import { SLOTS, SPIKE_MIN, Workshop } from "../src/workshop.mjs";
import { WASM, counting, openPlan, server } from "./setup.mjs";

const DAY = 24 * 60 * 60 * 1000;

function workshop() {
  const t = server();
  const w = new Workshop(t.service);
  const island = t.build.exampleIsland(true);
  const cleared = t.build.record(island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  return { ...t, w, island, cleared };
}

/** A play of `id`, recorded as the device would: the planned clear. */
function clear(t, player, id) {
  const p = t.w.play(player, id);
  const replay = t.build.record(t.service.bundle(p.bundle),
    { seed: BigInt(p.seed), ticks: p.ticks, crew: 3, commands: openPlan() });
  return t.w.submitPlay(player, p.token, replay);
}

const moderator = (t, account) =>
  t.service.db.prepare("UPDATE accounts SET moderator = 1 WHERE id = ?").run(account);

// -- RB-35 -------------------------------------------------------------------

test("RB-35: a Workshop play recorded under an older rules build the server still holds is refused wrong_rules (SEC-31)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const { id } = t.w.publish(me, t.island, t.cleared, { adjective: 1, noun: 9 });
  const fan = t.service.session("gc:fan").account;
  // A rules upgrade: the old build is held beside the new one.
  const old = t.service.builds.current;
  const newer = Build.load(WASM);
  newer.rulesVersion = "f".repeat(64);
  t.service.builds = new Builds([old, newer]);
  // Recorded by the old build, so its header names the old rules.
  const out = clear(t, fan, id);
  assert.deepEqual([out.validated, out.reason], [false, "wrong_rules"]);
  assert.equal(t.w.ladder(me).completions, 0, "nothing counted on the creator's ladder");
});

// -- RB-37 -------------------------------------------------------------------

test("RB-37: one fan clearing three listings of the same island is one completion (18.7)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const ids = [1, 2, 3].map((noun) => t.w.publish(me, t.island, t.cleared, { adjective: 1, noun }).id);
  const fan = t.service.session("gc:fan").account;
  counting(t, fan);
  const counted = ids.map((id) => clear(t, fan, id).counted);
  assert.deepEqual(counted, [true, false, false], "only the first copy's clear is a completion");
  assert.equal(t.w.ladder(me).completions, 1);
});

test("RB-37: one fan's Island Fund time on three listings of the same island is capped once (18.9, SR-12)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const ids = [1, 2, 3].map((noun) => t.w.publish(me, t.island, t.cleared, { adjective: 1, noun }).id);
  const fan = t.service.session("gc:fan").account;
  const q = quarterOf(t.clock.now);
  // 3000 s on each copy, written as submitPlay writes a counted play.
  ids.forEach((id, n) => t.service.db.prepare(
    `INSERT INTO workshop_plays (token, player, item, seed, ticks, issued_at, submitted_at, outcome, counted)
     VALUES (?, ?, ?, '1', ?, ?, ?, ?, 1)`).run(`rb37-${n}`, fan, id, 3000 * TICKS_PER_SECOND, t.clock.now,
    t.clock.now, JSON.stringify({ validated: true })));
  assert.equal(t.service.fund.played(q.starts_at, q.ends_at)[me], 3600, "at most 3600 s a quarter from that fan");
});

// -- RB-38 -------------------------------------------------------------------

test("RB-38: featured islands removed by moderation no longer count on the creator ladder (18.7)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const person = t.service.session("gc:moderator").account;
  moderator(t, person);
  const reporter = t.service.session("gc:reporter").account;
  const ids = [1, 2, 3].map((noun) => t.w.publish(me, t.island, t.cleared, { adjective: 1, noun }).id);
  for (const id of ids) t.w.feature(person, id);
  assert.equal(t.w.ladder(me).level, "loremaker", "three featured islands");
  for (const id of ids) {
    const { report } = t.w.report(reporter, id, "unfair");
    t.w.resolve(person, report, "remove", "copied");
  }
  assert.deepEqual([t.w.ladder(me).level, t.w.slots(me)], [null, SLOTS]);
});

// -- RB-39 -------------------------------------------------------------------

test("RB-39: dismissing a player's report leaves spike review on for the island's later spikes (18.7)", () => {
  const t = workshop();
  const me = t.service.session("gc:creator").account;
  const { id } = t.w.publish(me, t.island, t.cleared, { adjective: 1, noun: 9 });
  const person = t.service.session("gc:moderator").account;
  moderator(t, person);
  const reporter = t.service.session("gc:reporter").account;
  const { report } = t.w.report(reporter, id, "unfair");
  let n = 0;
  const spike = () => {
    for (let i = 0; i < SPIKE_MIN; i++) clear(t, t.service.session(`gc:p${n++}`).account, id);
  };
  spike();
  assert.deepEqual(t.w.queue(person).map((r) => r.reason).sort(), ["completion_spike", "unfair"]);
  // The moderator dismisses the player's report; the spike's is closed with it.
  t.w.resolve(person, report, "dismiss");
  assert.deepEqual(t.w.queue(person), []);
  t.clock.now += 30 * DAY;
  spike();
  assert.deepEqual(t.w.queue(person).map((r) => r.reason), ["completion_spike"]);
});
