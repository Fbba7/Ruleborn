// §12.3's Observatory and §12.4's target cards (observatory.mjs).

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { faults, realmFacts, rough, targetsAt, WANDERER_EXTRA, WANDERER_FROM } from "../src/observatory.mjs";
import { established, openPlan, play, twoPlayers } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const HOUR = 60 * 60 * 1000;

function keeper6(t) {
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6 WHERE id = ?").run(t.raider.account);
}

test("the Observatory's cards carry §12.4's free facts, counted from the bundle, the lease's own fee and why each was offered, and no rating, deviation or position reaches the device (12.4, 12.22, TD.18)", async () => {
  const t = twoPlayers(false);
  keeper6(t);
  t.service.book(t.raider.account, "starlight", 20_000, "a test's grant");
  const v = t.service.observatory.view(t.raider.account);
  assert.equal(v.targets.length, 1);
  const card = v.targets[0];
  const island = realmFacts(t.service.store.get(t.bundle));
  assert.deepEqual(card.realm.laws, ["brittle_stone", "haste"]);
  assert.deepEqual(card.realm.guards, island.guards);
  assert.deepEqual(card.realm.wards, island.wards);
  assert.deepEqual(card.realm.watch, facts.REALM_WATCH[card.realm.realm_level - 1], "the realm's watch (5.2)");
  assert.equal(card.kind, "player");
  assert.ok(["easier", "fair", "harder"].includes(card.reason));
  const lease = t.service.lease(t.raider.account, t.bundle);
  assert.ok(card.fee > 0);
  assert.equal(card.fee, lease.fee, "the fee shown is the lease's");
  const text = JSON.stringify(v);
  for (const hidden of ["rating", "deviation", "predicted", "\"x\"", "\"y\"", t.defender.account]) {
    assert.ok(!text.includes(hidden), `${hidden} stays on the server`);
  }
  const token = t.service.session("gc:raider").token;
  const r = await t.handle(new Request("https://edge.example/v1/offer", { headers: { authorization: `Bearer ${token}` } }));
  const body = await r.json();
  assert.equal(r.status, 200);
  assert.ok(body.targets.length && body.targets.every((c) => !("rating" in c) && !("deviation" in c) && !("predicted" in c)),
            JSON.stringify(body));
});

test("each card says how many realms its universe's longest shortest route to the Heart crosses, and where its faults open (12.22, 5.4)", () => {
  const t = twoPlayers(false);
  keeper6(t);
  const d = t.service.defender ?? t.defender.account;
  for (const [i, type] of [[1, "Skyfield"], [2, "Crystalline"]]) {
    t.service.db.prepare("INSERT INTO realms (owner, realm, type, level, opened_at) VALUES (?, ?, ?, 1, 0)")
      .run(d, `outer-${i}`, type);
  }
  t.service.book(d, "starlight", 10_000, "a test's grant");
  t.service.links.build(d, { a: "outer-2", b: "outer-1", kind: "stone_bridge" });
  const own = t.service.db.prepare("SELECT n FROM links WHERE owner = ? AND a = 'outer-2' AND b = 'heart'").get(d).n;
  t.service.links.remove(d, own);
  const real = t.service.weaving.stability.bind(t.service.weaving);
  t.service.weaving.stability = (...args) => ({ ...real(...args), strain: 1.12, band: 5 });
  const card = t.service.observatory.view(t.raider.account).targets[0];
  t.service.weaving.stability = real;
  assert.equal(card.realms, 3, "the Heart and two outer realms (12.4)");
  assert.equal(card.depth, 2, "\"up to 2 realms to the Heart\"");
  assert.equal(card.faults, 2, "two faults from 110% (5.5)");
  assert.deepEqual(card.fault_realms, ["outer-2", "outer-1"], "the deepest first (5.4)");
});

test("the Observatory offers 3 targets, 4 from level 3 and 5 at level 5, and a new player is told raiding a player ends their protection (12.3, 10.2)", () => {
  assert.deepEqual([0, 1, 2, 3, 4, 5].map(targetsAt), [3, 3, 3, 4, 4, 5]);
  const t = twoPlayers(false);
  keeper6(t);
  assert.equal(t.service.observatory.view(t.raider.account).size, 3);
  assert.equal(t.service.observatory.view(t.raider.account).protected, true);
  established(t, t.raider.account);
  assert.equal(t.service.observatory.view(t.raider.account).protected, false);
});

test("one more target while the Wanderer is at home, from the Keeper level that brings it (12.3, 11.7)", () => {
  assert.deepEqual([WANDERER_FROM, WANDERER_EXTRA], [20, 1], "§11.7: Keeper level 20, one more target");
  const t = twoPlayers(false);
  keeper6(t);
  const before = t.service.observatory.view(t.raider.account);
  assert.deepEqual([before.size, before.wanderer], [3, false]);
  t.service.db.prepare("UPDATE accounts SET keeper_level = ? WHERE id = ?").run(WANDERER_FROM, t.raider.account);
  const after = t.service.observatory.view(t.raider.account);
  assert.deepEqual([after.size, after.wanderer], [4, true], "3 from an unbuilt Observatory, and the Wanderer's");
});

test("a refresh costs 50 Aether, doubling with each refresh in the same hour, and buys a list without the targets on show (12.3)", () => {
  const t = twoPlayers(false);
  keeper6(t);
  const o = t.service.observatory;
  const me = t.raider.account;
  assert.throws(() => o.refresh(me), (e) => e.reason === "not_enough_aether" && e.detail.cost === 50);
  t.service.book(me, "aether", 1_000, "a test's grant");
  assert.equal(o.view(me).targets.length, 1);
  const after = o.refresh(me);
  assert.equal(t.service.aether(me), 950);
  assert.deepEqual(after.targets.map((c) => c.bundle).includes(t.bundle), false, "the shown island is set aside");
  assert.equal(after.refresh.aether, 100, "doubled within the hour");
  o.refresh(me);
  assert.equal(t.service.aether(me), 850);
  t.clock.now += HOUR + 1;
  assert.equal(o.view(me).refresh.aether, facts.OBSERVATORY_REFRESH_AETHER, "a new hour starts at 50 again");
});

test("a Trace is shown apart from the list and first, with no fee, and only while it can be answered (12.3)", () => {
  const t = twoPlayers(true);
  established(t, t.raider.account);
  keeper6(t);
  const home = t.service.publish(t.raider.account, (() => { const i = t.build.exampleIsland(true); i[5] = 2; return i; })()).bundle;
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.notEqual(out.verdict.grade, "foiled");
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6 WHERE id = ?").run(t.defender.account);
  const v = t.service.observatory.view(t.defender.account);
  assert.equal(v.trace.bundle, home);
  assert.equal(v.trace.kind, "trace");
  assert.equal(v.trace.fee, 0);
  assert.ok(!v.targets.some((c) => c.kind === "trace"), "apart from the list");
  t.clock.now += (facts.TRACE_HOURS + 1) * HOUR;
  assert.equal(t.service.observatory.view(t.defender.account).trace, null, "past its hours");
});

test("open faults follow §5.5's strain, never more than the outer realms, and a loot estimate is rough (5.5, 12.4)", () => {
  assert.deepEqual([0.99, 1.0, 1.1, 1.18, 1.25].map((s) => faults(s, 5)), [0, 1, 2, 3, 4]);
  assert.equal(faults(1.3, 2), 2, "one per outer realm if there are fewer");
  assert.equal(faults(1.3, 0), 0, "none in a universe of the Heart alone");
  assert.deepEqual([47, 750, 1234, 98_765].map(rough), [47, 750, 1200, 99_000]);
});

test("the Observatory and its refresh are served over HTTP (12.3)", async () => {
  const t = twoPlayers(false);
  const { token } = t.service.session("gc:raider");
  const call = (method, path) => t.handle(new Request(`https://edge.example${path}`,
    { method, headers: { authorization: `Bearer ${token}` } }));
  const view = await call("GET", "/v1/observatory");
  assert.equal(view.status, 200);
  assert.equal((await view.json()).refresh.aether, 50);
  const refused = await call("POST", "/v1/observatory/refresh");
  assert.equal(refused.status, 409);
  assert.deepEqual(await refused.json(), { error: "not_enough_aether", cost: 50 });
});
