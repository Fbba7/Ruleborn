// §12.5's crew manifest, against the real simulation build: the replay
// carries the crew, and the server's re-simulation plays each member by its
// kind and ability (12.5, 12.6).

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { readHeader } from "../src/sim.mjs";
import { openPlan, play, twoPlayers } from "./setup.mjs";

const KINDS = JSON.parse(readFileSync(new URL("../../content/ruleborn.json", import.meta.url)))
  .map((k) => k.id);
const crew = (...ids) => ({ members: ids.map((id) => ({ kind: KINDS.indexOf(id) })), sage: 0, casts: [] });

/** Roster characters of a manifest's kinds, level 1 and no traits, as the
 *  manifest says: §12.5's manifest is checked against the roster, so a
 *  heist carrying one names them (SR-02). */
const roster = (t, account, manifest) => manifest.members.map(({ kind }) => Number(t.service.db.prepare(
  "INSERT INTO characters (owner, kind, traits, home, via, joined_at) VALUES (?, ?, '[]', 'spire', 'woke', ?)")
  .run(account, KINDS[kind], t.clock.now).lastInsertRowid));

test("a heist carrying its crew manifest is re-simulated with each member's ability (12.5, 12.6)", () => {
  const t = twoPlayers(true);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const s = (seconds) => seconds * 30;
  const plan = [
    ...openPlan(),
    { tick: s(15), member: 1, kind: "Ability", x: 0, y: 0 },     // the Quarryback pounds
    { tick: s(50), member: 2, kind: "Ability", x: 0, y: 0 },     // the Skyskipper's satchel
  ].sort((a, b) => a.tick - b.tick);
  const manifest = crew("stormhound", "quarryback", "skyskipper");
  const replay = play(t, lease, { plan, manifest });
  assert.equal(readHeader(replay).manifest, true, "an RBH3 replay");
  const out = t.service.submit(t.raider.account, lease.token, replay, roster(t, t.raider.account, manifest));
  assert.equal(out.validated, true, "the server plays the same crew the device did");
  assert.equal(out.verdict.grade, "clean");
  assert.equal(out.verdict.banked, 508, "a Scout's, a Breaker's and a Carrier's bags: 104 + 104 + 300");
});

test("a manifest naming a kind past the eighteen does not record (12.5)", () => {
  const t = twoPlayers(true);
  const lease = t.service.lease(t.raider.account, t.bundle);
  const manifest = { members: [{ kind: 18 }, { kind: 0 }, { kind: 1 }], sage: 0, casts: [] };
  assert.throws(() => play(t, lease, { plan: openPlan(), manifest }), /manifest/);
});

test("§12.5's planning holds by Keeper level: a crew of 3, 4 from level 8 and 5 from 16; a Sage from level 2, unlocked and not the Heart's guardian; one cast slot, two from level 12 (12.5, 11.7)", () => {
  const t = twoPlayers(true);
  const me = t.raider.account;
  const level = (n) => t.service.db.prepare("UPDATE accounts SET keeper_level = ? WHERE id = ?").run(n, me);
  const tryWith = (manifest, n = 3) => {
    t.clock.now += 60 * 60 * 1000;
    const lease = t.service.lease(me, t.bundle);
    const out = t.service.submit(me, lease.token, play(t, lease, { plan: openPlan(), crew: n, manifest }),
                                 manifest ? roster(t, me, manifest) : null);
    return out.validated ? "ok" : out.reason;
  };
  assert.equal(tryWith(null, 4), "crew_too_large", "4 only from level 8");
  level(8);
  assert.equal(tryWith(null, 4), "ok");
  assert.equal(tryWith(null, 5), "crew_too_large", "5 only from level 16");
  level(1);
  const withSage = { ...crew("featherkin", "emberling", "tidewalker"), sage: 1 };
  assert.equal(tryWith(withSage), "sage_locked", "a Sage from Keeper level 2");
  level(2);
  t.service.keeper.setGuardian(me, "the_archivist");
  assert.equal(tryWith(withSage), "sage_on_guard", "the Archivist guards or goes, not both (11.7)");
  t.service.keeper.setGuardian(me, null);
  assert.equal(tryWith(withSage), "ok");
  const twoCasts = { ...crew("featherkin", "emberling", "tidewalker"), casts: [0, 1] };
  assert.equal(tryWith(twoCasts), "too_many_casts", "one slot before level 12");
});

test("the planner reads §12.5's limits from GET /v1/keeper, each roster member's manifest fields from the home, and each target's clock from the Observatory (12.5, 5.4)", async () => {
  const t = twoPlayers(true);
  const me = t.raider.account;
  t.service.db.prepare("UPDATE accounts SET keeper_level = 12 WHERE id = ?").run(me);
  const { token } = t.service.session("gc:raider");
  const keeper = await (await t.handle(new Request("https://edge.example/v1/keeper",
    { headers: { authorization: `Bearer ${token}` } }))).json();
  assert.deepEqual(keeper.plan, { crew: 4, casts: 2, sage: true, load: [50, 100, 10] });
  const c = t.service.home.show(me).characters[0];
  const traits = JSON.parse(readFileSync(new URL("../../content/traits.json", import.meta.url))).map((x) => x.id);
  assert.deepEqual(c.wire, { kind: KINDS.indexOf(c.kind), form: c.wire.form, level: c.level,
                             traits: c.traits.map((x) => traits.indexOf(x)) });
  assert.ok(c.form ? c.wire.form >= 1 && c.wire.form <= 3 : c.wire.form === 0, "a form numbered 1 to 3, else 0");
  const card = t.service.observatory.view(me, t.clock.now).targets[0];
  assert.equal(card.clock, 150, "§5.4's clock for the Heart alone");
});
