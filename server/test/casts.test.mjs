// §12.5's casts on the server: a cast is one of the raider's own restored
// laws, and "costs 30 Aether per point of the law's base cost, paid at
// validation and only if it was used"; a foiled heist gives the defender a
// page of what was cast (§7.6). Against the real simulation build.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { openPlan, play, twoPlayers } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const content = (name) => JSON.parse(readFileSync(new URL(`../../content/${name}.json`, import.meta.url), "utf8"));
const KINDS = content("ruleborn").map((k) => k.id);
const TRAITS = content("traits").map((t) => t.id);
const LAWS = content("laws");
const row = (id) => LAWS.findIndex((l) => l.id === id);
const at = (tile) => tile * 256 + 128;

/** The raider's crew, a lease, and the replay its three play carrying
 *  `casts`, with `extra` commands beside `plan`. */
function heist(t, casts, extra = [], plan = openPlan()) {
  // Three on their feet: the first heist brings two strays home (§11.5).
  const crew = t.service.home.show(t.raider.account).characters
    .filter((c) => c.state !== "resting").slice(0, 3);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const manifest = { members: crew.map((c) => ({ kind: KINDS.indexOf(c.kind), level: c.level,
                                                 traits: c.traits.map((x) => TRAITS.indexOf(x)) })),
                     sage: 0, casts: casts.map(row) };
  // The input log is in tick order (§24.10); a stable sort keeps each
  // tick's commands as the plan gives them.
  const commands = [...plan, ...extra].sort((a, b) => a.tick - b.tick);
  const replay = play(t, lease, { plan: commands, manifest });
  return t.service.submit(t.raider.account, lease.token, replay, crew.map((c) => c.id));
}

const castAt = (tick, x, y, i = 0) => ({ tick, member: i, kind: "Cast", x: at(x), y: at(y) });

test("a cast used is paid at validation, 30 Aether a point of its law's base cost, and one carried and never used costs nothing (12.5)", () => {
  const t = twoPlayers(true);
  const me = t.raider.account;
  t.service.book(me, "aether", 1_000, "a test's grant");
  const price = Math.round(LAWS[row("half_gravity")].stability_cost * facts.CAST_AETHER_PER_POINT);
  assert.equal(price, 360, "Half gravity: 12 points");
  const before = t.service.aether(me);
  const used = heist(t, ["half_gravity"], [castAt(30, 6, 8)]);
  assert.equal(used.validated, true);
  assert.equal(used.verdict.castsUsed, 0b1, "the verdict says it was used");
  assert.deepEqual(used.cast, { laws: ["half_gravity"], aether: price });
  assert.equal(before - t.service.aether(me), price);
  const rows = t.service.db.prepare("SELECT COUNT(*) AS n FROM ledger WHERE account = ? AND aether < 0").get(me).n;
  assert.equal(rows, 1, "on the heist's one ledger row");
  t.clock.now += 60 * 60_000;
  const carried = heist(t, ["half_gravity"]);
  assert.equal(carried.validated, true);
  assert.deepEqual(carried.cast, { laws: [], aether: 0 }, "carried and never placed: never billed");
  assert.equal(before - t.service.aether(me), price);
});

test("a cast must be the raider's own restored law, and paid for, or the heist does not record (12.5)", () => {
  const t = twoPlayers(true);
  t.service.book(t.raider.account, "aether", 1_000, "a test's grant");
  assert.equal(heist(t, ["haste"]).reason, "cast_not_restored", "Haste is not one of the starting three");
  t.clock.now += 60 * 60_000;
  const poor = twoPlayers(true);
  const refused = heist(poor, ["half_gravity"], [castAt(30, 6, 8)]);
  assert.deepEqual([refused.validated, refused.reason], [false, "not_enough_aether"]);
});

test("a law cast in a foiled heist gives the defender a page of it (7.6)", () => {
  const t = twoPlayers(true);
  t.service.book(t.raider.account, "aether", 1_000, "a test's grant");
  const pages = () => t.service.codex.row(t.defender.account, "bloom")?.pages ?? 0;
  const before = pages();
  const plan = [{ tick: 0, member: 0, kind: "Land", x: at(0), y: at(0) }];
  const out = heist(t, ["bloom"], [castAt(30, 2, 2)], plan);
  assert.equal(out.verdict.grade, "foiled", "nobody loads: nothing out");
  assert.equal(pages() - before, 1);
});
