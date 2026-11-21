// FX1-1-workshop-pairs: the fail-first tests for RB-30, RB-05 and RB-06 of
// docs/security/bug-report-2026-11.md, each reproducing the entry's Input.

import assert from "node:assert/strict";
import { test } from "node:test";

import { GENERATOR } from "../src/generator.mjs";
import { ratingFor } from "../src/glicko.mjs";
import { offer } from "../src/matchmaking.mjs";
import { Refused, clockTicks } from "../src/service.mjs";
import { Workshop } from "../src/workshop.mjs";
import { openPlan, play, server, twoPlayers } from "./setup.mjs";

const refusal = (fn, status, reason) =>
  assert.throws(fn, (e) => e instanceof Refused && e.status === status && e.reason === reason);

// -- RB-30 -------------------------------------------------------------------

test("RB-30: a creator cannot republish, byte for byte, an island a moderator removed (18.7)", () => {
  const t = server();
  const w = new Workshop(t.service);
  const island = t.build.exampleIsland(true);
  const cleared = t.build.record(island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  const creator = t.service.session("gc:creator").account;
  const player = t.service.session("gc:player").account;
  const person = t.service.session("gc:moderator").account;
  t.service.db.prepare("UPDATE accounts SET moderator = 1 WHERE id = ?").run(person);

  const x = w.publish(creator, island, cleared, { adjective: 1, noun: 9 });
  const { report } = w.report(player, x.id, "offensive");
  w.resolve(person, report, "remove", "offensive");
  assert.deepEqual(w.browse(player, "top"), [], "the removal takes it out of the Workshop");

  refusal(() => w.publish(creator, island, cleared, { adjective: 2, noun: 3 }), 409, "taken_down");
  assert.deepEqual(w.browse(player, "top"), [], "and it stays out");
});

// -- RB-05 -------------------------------------------------------------------

/** The defender's island X made another island Y by its loot exposed: the
 *  defender publishes Y over X, and X becomes an echo (12.3). */
function moveOn(t) {
  const y = Uint8Array.from(t.island);
  y[6] = (y[6] + 1) & 0xff;
  const { bundle } = t.service.publish(t.defender.account, y);
  assert.notEqual(bundle, t.bundle);
  return bundle;
}

test("RB-05: an echo raid does not use up the pair's daily scoring (12.3, G30, G37)", () => {
  const t = twoPlayers(true);
  const y = moveOn(t);
  const echo = t.service.lease(t.raider.account, t.bundle);
  assert.equal(echo.echo, true);
  const first = t.service.submit(t.raider.account, echo.token, play(t, echo, { plan: openPlan() }));
  assert.equal(first.validated, true);
  t.clock.now += 60_000;                                // the same UTC day
  const real = t.service.lease(t.raider.account, y);
  assert.equal(Boolean(real.echo), false);
  const out = t.service.submit(t.raider.account, real.token, play(t, real, { plan: openPlan() }));
  assert.equal(out.validated, true);
  assert.equal(out.renownCounted, true, "the pair's first real raid of the day scores");
  assert.ok(out.renown.raider > 0, `Renown moves: ${JSON.stringify(out.renown)}`);
  assert.ok(out.stars.raider > 0, `stars move: ${JSON.stringify(out.stars)}`);
  assert.notEqual(out.rating ?? null, null, "and the raid is rated");
});

test("RB-05: a foiled echo does not keep a later real foil's fee from the defender (9.4, G30, G37)", () => {
  const t = twoPlayers(false);
  t.service.db.prepare("INSERT INTO ledger (account, starlight, reason, at) VALUES (?, 50000, 'grant', 0)")
    .run(t.raider.account);
  const y = moveOn(t);
  const echo = t.service.lease(t.raider.account, t.bundle);
  assert.equal(echo.echo, true);
  const foiledEcho = t.service.submit(t.raider.account, echo.token, play(t, echo, { crew: 3 }));
  assert.equal(foiledEcho.verdict.grade, "foiled");
  const before = t.service.balance(t.defender.account).starlight;
  t.clock.now += 60_000;
  const real = t.service.lease(t.raider.account, y);
  const out = t.service.submit(t.raider.account, real.token, play(t, real, { crew: 3 }));
  assert.equal(out.verdict.grade, "foiled");
  assert.ok(out.fee > 0);
  assert.equal(t.service.balance(t.defender.account).starlight - before >= out.fee, true,
               "the pair's first real foil of the day passes the fee on");
});

// -- RB-06 -------------------------------------------------------------------

/** A candidate a raider at 1500 beats with probability `p`. */
function candidate(id, p, extra = {}) {
  return { bundle: id, owner: `owner-${id}`, realm: "heart", realmLevel: 1, keeperLevel: 5, renown: 100,
           rating: ratingFor(p), deviation: 0, origin: "authored", echo: false, ...extra };
}
const RAIDER = { account: "me", rating: 1500, deviation: 0, renown: 100, keeperLevel: 5, recent: 0.625 };

test("RB-06: players' live curated islands are in the live pool, offered before echoes (12.22, 13.3)", () => {
  // A player's kept curated layout is published with origin "generated"
  // (curation.mjs layout); only the game's own islands are owned by GENERATOR.
  const curated = [candidate("c1", 0.63, { origin: "generated" }),
                   candidate("c2", 0.6, { origin: "generated" }),
                   candidate("c3", 0.66, { origin: "generated" })];
  const echoes = [candidate("e1", 0.62, { echo: true }), candidate("e2", 0.61, { echo: true }),
                  candidate("e3", 0.64, { echo: true })];
  const game = [candidate("g1", 0.62, { origin: "generated", owner: GENERATOR, realm: "outer-1" })];
  const out = offer(RAIDER, [...curated, ...echoes, ...game]);
  assert.deepEqual([out.echoes, out.generated], [false, false],
                   "three live islands of players sit in the band: no echoes, nothing of the game's");
  assert.deepEqual(out.targets.map((c) => c.bundle).sort(), ["c1", "c2", "c3"]);
});
