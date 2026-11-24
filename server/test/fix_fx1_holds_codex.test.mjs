// FX1-4-holds-codex: the fail-first tests for RB-15, RB-18, RB-36, RB-53 and
// RB-56 of docs/security/bug-report-2026-11.md, each reproducing the entry's
// Input.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { deleteAccount } from "../src/accounts.mjs";
import { clockTicks } from "../src/service.mjs";
import { Workshop } from "../src/workshop.mjs";
import { established, openPlan, play, server, twoPlayers } from "./setup.mjs";

const HOUR = 60 * 60 * 1000;
const content = (name) => JSON.parse(readFileSync(new URL(`../../content/${name}.json`, import.meta.url), "utf8"));
const KINDS = content("ruleborn").map((k) => k.id);
const TRAITS = content("traits").map((x) => x.id);
const LAWS = content("laws");
const at = (tile) => tile * 256 + 128;

// -- RB-15 -------------------------------------------------------------------

/** `fn` with the current build's hold measurement replaced by `hold`. */
function withHold(t, hold, fn) {
  const build = t.service.builds.current;
  const had = Object.getOwnPropertyDescriptor(build, "hold");
  build.hold = hold;
  try { return fn(); } finally {
    if (had) Object.defineProperty(build, "hold", had);
    else delete build.hold;
  }
}

test("RB-15: a hold measurement that throws is no measured figure, and a republish of its bundle keeps the default prior (13.3, SEC-20)", (ctx) => {
  const t = twoPlayers(false);
  ctx.mock.method(console, "error", () => {});
  t.service.db.prepare("UPDATE island_holds SET raids = 30").run();
  withHold(t, () => { throw new Error("a trap in the simulation"); }, () => t.service.holds.work(2));
  assert.equal(t.service.holds.status(t.bundle), null, "no measured figure from a failed measurement");
  assert.equal(t.service.curation.view(t.defender.account, "heart").hold, null, "curation shows none");
  // Any player publishes the same bundle later.
  const prior = t.service.matchmaking.islandRating(t.defender.account, "heart").rating;
  const other = t.service.session("gc:copy").account;
  t.service.publish(other, t.island);
  assert.equal(t.service.matchmaking.islandRating(other, "heart").rating, prior, "the default prior, not a hold of 0");
});

test("RB-15: a hold measurement whose bytes are gone from the store is no measured figure (13.3)", () => {
  const t = twoPlayers(false);
  t.service.db.prepare("UPDATE island_holds SET raids = 30").run();
  t.service.store.delete(t.bundle);
  t.service.holds.work(2);
  assert.equal(t.service.holds.status(t.bundle), null, "no measured figure without the island's bytes");
});

// -- RB-18 -------------------------------------------------------------------

test("RB-18: a universe with no link rows is raided as a universe: its links are made at the lease (5.4)", () => {
  const t = server();
  const defender = t.service.session("gc:defender").account;
  established(t, defender);
  const { bundle } = t.service.publish(defender, t.build.exampleIsland(false));
  t.service.publish(defender, t.build.generate(2, 1), "outer-1");
  // A universe opened before links were kept.
  t.service.db.prepare("DELETE FROM links WHERE owner = ?").run(defender);
  assert.equal(t.service.links.rows(defender).length, 0, "no link rows");
  const digest = t.service.crossings.of(defender, bundle);
  assert.notEqual(digest, null, "a universe digest, its missing links made");
  const raider = t.service.session("gc:raider").account;
  const lease = t.service.lease(raider, bundle, null, { universe: true });
  assert.deepEqual(lease.universe?.realms.map((r) => r.realm), ["heart", "outer-1"]);
});

// -- RB-36 -------------------------------------------------------------------

test("RB-36: five foiled friendly heists in one day, each casting a law, pay the defender at most one page of it (SEC-24, 7.6)", () => {
  const t = twoPlayers(true);
  const alice = t.raider.account;
  const dave = t.defender.account;
  const { invite } = t.service.friends.invite(dave);
  t.service.friends.accept(alice, invite);
  established(t, alice);
  t.service.book(alice, "aether", 10_000, "a test's grant");
  const pages = () => t.service.codex.row(dave, "bloom")?.pages ?? 0;
  const before = pages();
  // The day's first hour, so every heist below falls on one UTC day.
  t.clock.now = (Math.floor(t.clock.now / (24 * HOUR)) + 1) * 24 * HOUR + HOUR;
  const land = [{ tick: 0, member: 0, kind: "Land", x: at(0), y: at(0) }];
  const cast = { tick: 30, member: 0, kind: "Cast", x: at(2), y: at(2) };
  for (let i = 0; i < 5; i++) {
    const crew = t.service.home.show(alice).characters.filter((c) => c.state !== "resting").slice(0, 3);
    const lease = t.service.lease(alice, t.bundle, null, { mode: "friendly" });
    const manifest = { members: crew.map((c) => ({ kind: KINDS.indexOf(c.kind), form: c.wire.form, level: c.level,
                                                   traits: c.traits.map((x) => TRAITS.indexOf(x)) })),
                       sage: 0, casts: [LAWS.findIndex((l) => l.id === "bloom")] };
    const replay = play(t, lease, { plan: [...land, cast], manifest });
    const out = t.service.submit(alice, lease.token, replay, crew.map((c) => c.id));
    assert.equal(out.validated, true, out.reason);
    assert.equal(out.verdict.grade, "foiled", "nobody loads: nothing out");
    assert.deepEqual(out.cast?.laws, ["bloom"], "the cast was used");
    t.clock.now += 5 * HOUR;                           // the crew rested
  }
  assert.ok(pages() - before <= 1, `dave got ${pages() - before} bloom pages`);
});

// -- RB-53 -------------------------------------------------------------------

test("RB-53: studying a heist whose island was erased by an under-13 deletion is refused 409 nothing_to_study, not a 500 (7.6, 20.11)", () => {
  const t = twoPlayers(true);
  const alice = t.raider.account;
  const lease = t.service.lease(alice, t.bundle);
  const out = t.service.submit(alice, lease.token, play(t, lease, { plan: openPlan() }));
  assert.equal(out.validated, true, out.reason);
  deleteAccount(t.service, t.defender.account, "under-13");
  assert.equal(t.service.store.get(t.bundle) ?? null, null, "the island's bytes are erased");
  assert.throws(() => t.service.codex.study(alice, { heist: lease.token, law: "bloom" }),
                (e) => e.status === 409 && e.reason === "nothing_to_study", "a 4xx refusal");
});

// -- RB-56 -------------------------------------------------------------------

test("RB-56: a player's report, after the player is deleted as under-13, is not shown as the server's, and its dismissal leaves the spike flag (18.7, 20.11)", () => {
  const t = server();
  const w = new Workshop(t.service);
  const island = t.build.exampleIsland(true);
  const cleared = t.build.record(island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  const me = t.service.session("gc:creator").account;
  const { id } = w.publish(me, island, cleared, { adjective: 1, noun: 9 });
  const person = t.service.session("gc:moderator").account;
  t.service.db.prepare("UPDATE accounts SET moderator = 1 WHERE id = ?").run(person);
  const reporter = t.service.session("gc:reporter").account;
  const { report } = w.report(reporter, id, "unfair");
  deleteAccount(t.service, reporter, "under-13");
  const queue = w.queue(person);
  assert.deepEqual(queue.map((r) => [r.report, r.reason, r.server]), [[report, "unfair", false]]);
  // The island is under spike review for a flag this report did not raise:
  // dismissing the player's report leaves it on.
  t.service.db.prepare("UPDATE workshop_items SET review = 1 WHERE id = ?").run(id);
  w.resolve(person, report, "dismiss");
  assert.equal(t.service.db.prepare("SELECT review FROM workshop_items WHERE id = ?").get(id).review, 1);
});
