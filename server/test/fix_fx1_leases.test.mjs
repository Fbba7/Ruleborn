// FX1-2-leases: the fail-first tests for RB-12, RB-14, RB-16 and RB-17 of
// docs/security/bug-report-2026-11.md, each reproducing the entry's Input.

import assert from "node:assert/strict";
import { test } from "node:test";

import { GENERATOR } from "../src/generator.mjs";
import { ratingFor } from "../src/glicko.mjs";
import { offer, successBand } from "../src/matchmaking.mjs";
import { Refused } from "../src/service.mjs";
import { established, openPlan, play, server, twoPlayers } from "./setup.mjs";

const DAY = 24 * 60 * 60 * 1000;

const refusal = (fn, status, reason) =>
  assert.throws(fn, (e) => e instanceof Refused && e.status === status && e.reason === reason,
                `refused ${status} ${reason}`);

/** Another island of the example's, told apart by its vault level. */
function another(t, open, vaultLevel) {
  const island = t.build.exampleIsland(open);
  island[5] = vaultLevel;
  return island;
}

// -- RB-12 -------------------------------------------------------------------

test("RB-12: yesterday's generated island is not leased as an echo (12.22, generator.mjs)", () => {
  const t = server();
  const raider = t.service.session("gc:raider").account;
  const yesterday = t.service.generator.stock()[1];
  t.clock.now += DAY;
  const today = t.service.generator.stock()[1];
  assert.notEqual(today, yesterday, "the daily rotation published a new level-1 island");
  // Named by its hash in POST /v1/leases.
  refusal(() => t.service.lease(raider, yesterday), 410, "superseded");
  // Today's is a target as before.
  assert.equal(Boolean(t.service.lease(raider, today).echo), false);
});

test("RB-12: an hourly list made before the rotation does not hand out yesterday's generated island (12.22)", () => {
  const t = server();
  const yesterday = t.service.generator.stock()[1];
  const card = { bundle: yesterday, owner: GENERATOR, realm: "outer-1", realmLevel: 1, keeperLevel: 1,
                 renown: 0, origin: "generated", echo: false };
  t.clock.now += DAY;
  const today = t.service.generator.stock()[1];
  const out = t.service.matchmaking.current([card]);
  assert.ok(out.every((c) => c.bundle !== yesterday), `no stale card: ${JSON.stringify(out.map((c) => c.bundle))}`);
  assert.deepEqual(out.map((c) => c.bundle), [today], "the card is brought up to today's island");
});

// -- RB-14 -------------------------------------------------------------------

test("RB-14: asking again for a held Trace hands back the same lease (12.3, 24.13)", () => {
  const t = twoPlayers(true);
  established(t, t.raider.account);
  const home = t.service.publish(t.raider.account, another(t, true, 2)).bundle;
  const lease = t.service.lease(t.raider.account, t.bundle);
  const robbed = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.equal(robbed.validated, true);
  assert.notEqual(robbed.verdict.grade, "foiled", "B was robbed");
  const first = t.service.lease(t.defender.account, home, null, { trace: true });
  assert.equal(first.trace, true);
  t.clock.now += 1_000;                                // a retry after a dropped response
  let second;
  assert.doesNotThrow(() => { second = t.service.lease(t.defender.account, home, null, { trace: true }); },
                      "the second ask is not refused");
  assert.equal(second.token, first.token, "T1 is handed back");
  assert.equal(second.trace, true);
});

// -- RB-16 -------------------------------------------------------------------

test("RB-16: a refused upload does not use up a challenge link (17.6)", () => {
  const t = twoPlayers(true);
  const { challenge } = t.service.friends.challenge(t.defender.account);
  const ask = () => t.service.lease(t.raider.account, t.bundle, null, { mode: "challenge", challenge });
  const lease = ask();
  const junk = t.service.submit(t.raider.account, lease.token, new Uint8Array(10));
  assert.deepEqual([junk.validated, junk.reason], [false, "replay_malformed"]);
  let again;
  assert.doesNotThrow(() => { again = ask(); }, "a refused submission is not a play");
  assert.equal(again.mode, "challenge");
  assert.notEqual(again.token, lease.token, "a new challenge lease");
  // Played for real, the link is used up as before.
  const out = t.service.submit(t.raider.account, again.token, play(t, again, { plan: openPlan() }));
  assert.equal(out.validated, true);
  refusal(ask, 409, "challenge_already_played");
});

// -- RB-17 -------------------------------------------------------------------

/** A candidate a raider at 1500 beats with probability `p`. */
function candidate(id, p) {
  return { bundle: id, owner: `owner-${id}`, realm: "heart", realmLevel: 1, keeperLevel: 5, renown: 100,
           rating: ratingFor(p), deviation: 0, origin: "authored", echo: false };
}
const RAIDER = { account: "me", rating: 1500, deviation: 0, renown: 100, keeperLevel: 5, recent: 0.625 };

test("RB-17: an offer of size 1 is the band's middle, guaranteed (12.22)", () => {
  assert.deepEqual(successBand(1, "authored"), [0.55, 0.7], "the entry's band");
  const pool = [candidate("a", 0.75), candidate("b", 0.72), candidate("c", 0.625), candidate("d", 0.6),
                candidate("e", 0.56)];
  const one = offer(RAIDER, pool, { size: 1 });
  assert.deepEqual(one.targets.map((c) => c.bundle), ["c"], "the in-band middle");
  assert.equal(one.guaranteed, true);
  // The sizes the device asks for keep the middle in the middle.
  const three = offer(RAIDER, pool, { size: 3 });
  assert.deepEqual(three.targets.map((c) => c.bundle), ["b", "c", "d"]);
  assert.equal(three.guaranteed, true);
});
