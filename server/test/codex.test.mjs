// The Codex (§7.6, §14.2): laws met and their pages, the study a heist
// allows, the floor, restorations and tiers, and their experience.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { brokenLaws, restorePrice } from "../src/codex.mjs";
import { lawsOf } from "../src/telemetry.mjs";
import { openPlan, play, server, twoPlayers } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const LAWS = JSON.parse(readFileSync(new URL("../../content/laws.json", import.meta.url), "utf8"));
const DAY = 24 * 60 * 60 * 1000;

function refused(fn, reason, detail) {
  assert.throws(fn, (err) => {
    assert.equal(err.reason, reason);
    if (detail) assert.deepEqual(err.detail, detail);
    return true;
  });
}

const law = (view, id) => view.laws.find((l) => l.law === id);

/** A raid by the raider on the defender's island, settled. */
function raid(t, plan = openPlan()) {
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan }));
  t.clock.now += 2 * DAY;
  return { token: lease.token, out };
}

test("the Codex starts with Half gravity, Slow rivers and Bloom restored at tier I (7.6)", () => {
  const t = server();
  const me = t.service.session("gc:keeper").account;
  const v = t.service.codex.show(me);
  assert.deepEqual(v.laws.map((l) => [l.law, l.tier]).sort(), facts.STARTING_LAWS.map((l) => [l, 1]).sort());
  assert.deepEqual(law(v, "half_gravity").next, { pages: 20, aether: 2_000, spire: 4 }, "tier II next");
});

test("a heist meets the island's laws, a page each, and a broken pylon gives a page of its law (7.6)", () => {
  const t = twoPlayers(false);                         // an island running Brittle stone and Haste
  const me = t.raider.account;
  const crossed = lawsOf(t.service.store.get(t.bundle)).filter((l) => !facts.STARTING_LAWS.includes(l));
  assert.ok(crossed.length > 0, "the island runs a law the raider has not met");
  const { out } = raid(t);
  assert.ok(out.validated);
  const v = t.service.codex.show(me);
  for (const l of crossed) assert.equal(law(v, l).pages, facts.MEET_PAGES + (brokenLaws(out.verdict.broken).includes(l) ? 1 : 0));
  // A pylon's page, read from the re-simulation's own `broken` bits.
  const target = LAWS.findIndex((l) => l.id === crossed[0]);
  const before = law(t.service.codex.view(me), crossed[0]).pages;
  t.service.codex.afterHeist({ attacker: me, bundle: t.bundle, mode: "raid" }, { broken: 2 ** target, caught: 0 }, t.clock.now);
  assert.equal(law(t.service.codex.view(me), crossed[0]).pages, before + 1, "met already: the pylon's page only");
  assert.deepEqual(brokenLaws(2 ** 0 + 2 ** 47), [LAWS[0].id, LAWS[47].id]);
});

test("a heist allows one study of a law it crossed: 3 pages if clean, 1 if foiled, 2 otherwise (7.6)", () => {
  const t = twoPlayers(false);
  const me = t.raider.account;
  const { token, out } = raid(t);
  const crossed = lawsOf(t.service.store.get(t.bundle));
  const grade = out.verdict.grade;
  const want = grade === "clean" ? 3 : grade === "foiled" ? 1 : 2;
  const before = law(t.service.codex.view(me), crossed[0])?.pages ?? 0;
  refused(() => t.service.codex.study(me, { heist: token, law: "inward_pull" === crossed[0] ? "bounce" : "inward_pull" }),
          "law_not_crossed");
  const s = t.service.codex.study(me, { heist: token, law: crossed[0] });
  assert.equal(s.pages, want, `a ${grade} heist`);
  assert.equal(law(s.codex, crossed[0]).pages, before + want);
  assert.equal(t.service.codex.study(me, { heist: token, law: crossed[0] }).repeated, true, "a retry is answered");
  if (crossed[1]) refused(() => t.service.codex.study(me, { heist: token, law: crossed[1] }), "already_studied");
  refused(() => t.service.codex.study(t.defender.account, { heist: token, law: crossed[0] }), "no_such_heist");
});

test("every eighth paying heist gives a page of the law worked on (7.6)", () => {
  const t = twoPlayers();
  const me = t.raider.account;
  t.service.codex.workOn(me, "haste");
  for (let i = 0; i < facts.FLOOR_HEISTS - 1; i++) raid(t);
  assert.equal(law(t.service.codex.view(me), "haste")?.pages ?? 0, 0, "nothing for seven");
  raid(t);
  assert.equal(law(t.service.codex.view(me), "haste").pages, 1, "the eighth heist's page");
});

test("restoring a law costs its rank's pages, waits for its chapter, and pays 60 + 10 × level experience (7.6, 14.2)", () => {
  const t = server();
  const me = t.service.session("gc:keeper").account;
  const cx = t.service.codex;
  cx.show(me);
  assert.deepEqual(["bounce", "aurora", "haste", "inward_pull"].map(restorePrice), [10, 20, 35, 60],
                   "common, uncommon, rare, deep");
  refused(() => cx.restore(me, "bounce"), "not_enough_pages", { cost: 10 });
  cx.add(me, "bounce", 12, t.clock.now);
  const r = cx.restore(me, "bounce");
  assert.equal(law(r.codex, "bounce").tier, 1);
  assert.equal(law(r.codex, "bounce").pages, 2);
  assert.equal(r.keeper.gained, 60 + 10 * 1, "§14.2 at Keeper level 1");
  assert.equal(cx.restore(me, "bounce").repeated, true);
  cx.add(me, "haste", 35, t.clock.now);
  refused(() => cx.restore(me, "haste"), "chapter_closed", { keeper: 6 });
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6 WHERE id = ?").run(me);
  assert.equal(cx.restore(me, "haste").keeper.gained, 60 + 10 * 6, "chapter 2 from Keeper level 6");
  const late = LAWS.find((l) => !l.launch).id;
  cx.add(me, late, 100, t.clock.now);
  refused(() => cx.restore(me, late), "chapter_closed");  // a law after launch has no chapter open yet
});

test("tiers II and III cost their pages, their Aether and a Spire level (7.6)", () => {
  const t = server();
  const me = t.service.session("gc:keeper").account;
  const cx = t.service.codex;
  cx.show(me);
  refused(() => cx.tier(me, "half_gravity", 3), "not_the_next_tier");
  refused(() => cx.tier(me, "half_gravity", 2), "needs_spire_level", { needs: 4 });
  t.service.universe.ensure(me, t.clock.now);
  t.service.db.prepare("UPDATE buildings SET level = 7 WHERE owner = ? AND kind = 'keeper_s_spire'").run(me);
  refused(() => cx.tier(me, "half_gravity", 2), "not_enough_pages", { cost: 20 });
  cx.add(me, "half_gravity", 60, t.clock.now);
  refused(() => cx.tier(me, "half_gravity", 2), "not_enough_aether", { cost: 2_000 });
  t.service.book(me, "aether", 10_000, "a test's grant");
  assert.equal(law(cx.tier(me, "half_gravity", 2).codex, "half_gravity").tier, 2);
  assert.equal(t.service.aether(me), 8_000);
  const three = cx.tier(me, "half_gravity", 3);
  assert.equal(law(three.codex, "half_gravity").tier, 3);
  assert.equal(law(three.codex, "half_gravity").pages, 0, "20 and 40 pages");
  assert.equal(t.service.aether(me), 0);
  assert.equal(law(three.codex, "half_gravity").next, null, "tier III is the top");
});

test("a friendly heist pays its owner a page of their worked-on law for each raider caught, and its raider no study (12.11, 7.6)", () => {
  const t = twoPlayers();
  const owner = t.defender.account;
  t.service.codex.workOn(owner, "glass");
  t.service.codex.afterHeist({ attacker: t.raider.account, bundle: t.bundle, mode: "friendly" },
                             { broken: 1, caught: 2 }, t.clock.now);
  assert.equal(law(t.service.codex.view(owner), "glass").pages, 2, "a page for each raider caught");
  assert.equal(law(t.service.codex.view(t.raider.account), LAWS[0].id)?.pages ?? 0,
               lawsOf(t.service.store.get(t.bundle)).includes(LAWS[0].id) ? facts.MEET_PAGES : 0,
               "no pylon page for a friendly heist's raider");
});

test("the Codex over HTTP: read, worked on, restored, and refused with the reason (7.6)", async () => {
  const t = server();
  const call = async (method, path, token, json) => {
    const r = await t.handle(new Request(`https://edge.example${path}`, {
      method, headers: { authorization: `Bearer ${token}`, ...(json ? { "content-type": "application/json" } : {}) },
      body: json ? JSON.stringify(json) : undefined }));
    return { status: r.status, body: await r.json() };
  };
  const { account, token } = t.service.session("gc:keeper");
  const read = await call("GET", "/v1/codex", token);
  assert.equal(read.status, 200);
  assert.equal(read.body.laws.length, 3);
  const marked = await call("POST", "/v1/codex/working", token, { law: "glass" });
  assert.equal(marked.body.working_on, "glass");
  const poor = await call("POST", "/v1/codex/restore", token, { law: "glass" });
  assert.equal(poor.status, 409);
  assert.equal(poor.body.error, "not_enough_pages");
  t.service.codex.add(account, "glass", 10, t.clock.now);
  const done = await call("POST", "/v1/codex/restore", token, { law: "glass" });
  assert.equal(done.status, 200);
  assert.equal(done.body.keeper.gained, 70);
});
