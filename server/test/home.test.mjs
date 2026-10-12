// The home economy's second part (§5.8, §9.3, §9.5, §11.3 to §11.6, §15.6):
// the roster, its places and births, its work, and what the producers make.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { PRODUCERS, RULEBORN, birthPrice, levelPrice } from "../src/home.mjs";
import { openPlan, play, server, twoPlayers } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const MINUTE = 60_000;
const HOUR = 60 * MINUTE;

function fresh() {
  const t = server();
  const me = t.service.session("gc:keeper").account;
  const h = t.service.home;
  const v = h.show(me);
  // Traits are drawn; these tests set them, so a rate reads plainly.
  t.service.db.prepare("UPDATE characters SET traits = '[]' WHERE owner = ?").run(me);
  const id = (kind) => v.characters.find((c) => c.kind === kind).id;
  const grant = (currency, n) => t.service.book(me, currency, n, "a test's grant");
  const later = (ms) => { t.clock.now += ms; };
  const keeper = (level) => t.service.db.prepare("UPDATE accounts SET keeper_level = ? WHERE id = ?").run(level, me);
  return { t, me, h, id, grant, later, keeper };
}

function refused(fn, reason, detail) {
  assert.throws(fn, (err) => {
    assert.equal(err.reason, reason);
    if (detail) assert.deepEqual(err.detail, detail);
    return true;
  });
}

const producer = (view, realm, kind) => view.producers.find((p) => p.realm === realm && p.kind === kind);

test("the roster starts with the three who wake, two traits each, and the first heist brings two strays home free (11.5, 15.6)", () => {
  const t = twoPlayers();
  const me = t.raider.account;
  const v = t.service.home.show(me);
  assert.deepEqual(v.characters.map((c) => c.kind), [...facts.STARTING_CREW],
                   "§15.6: a Featherkin, an Emberling and a Tidewalker");
  assert.ok(v.characters.every((c) => c.traits.length === 2 && new Set(c.traits).size === 2 && c.via === "woke"),
            "§11.3: every ruleborn is born with two traits");
  assert.ok(v.characters.every((c) => c.home === "spire"), "the Spire's three places first");
  const lease = t.service.lease(me, t.bundle);
  const out = t.service.submit(me, lease.token, play(t, lease, { plan: openPlan() }));
  assert.ok(out.validated);
  const after = t.service.home.show(me);
  const strays = after.characters.filter((c) => c.via === "stray");
  assert.equal(strays.length, 2, "two strays follow the crew home");
  assert.ok(strays.every((c) => c.traits.length === 3 && c.home === "heart"),
            "with three traits, to the starting Hearth that waits for them");
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM ledger WHERE account = ? AND reason LIKE 'a birth%'")
    .get(me).n, 0, "free: nothing paid for them");
  const second = t.service.lease(me, t.bundle);
  t.clock.now += 24 * HOUR;
  t.service.submit(me, second.token, play(t, second, { plan: openPlan() }));
  assert.equal(t.service.home.show(me).characters.length, 5, "once: the second heist brings none");
});

test("a producer runs at the share of its slots filled, from five minutes after assignment, and holds twelve hours (5.8, 9.3, 11.6)", () => {
  const { t, me, h, id, later } = fresh();
  h.work(me, id("tidewalker"), { realm: "heart", kind: "star_well" });
  later(5 * MINUTE);
  assert.equal(producer(h.show(me), "heart", "star_well").stored, 0, "nothing in the first five minutes");
  assert.equal(producer(h.show(me), "heart", "star_well").per_hour, 80, "§10.2's Star Well 1: 80 an hour");
  later(HOUR);
  assert.equal(producer(h.show(me), "heart", "star_well").stored, 80);
  later(24 * HOUR);
  assert.equal(producer(h.show(me), "heart", "star_well").stored, 12 * 80, "it holds 12 hours of output");
  // A level 4 Well has two slots: one filled earns half (§5.8's pro-rata).
  t.service.db.prepare("UPDATE buildings SET level = 4 WHERE owner = ? AND kind = 'star_well'").run(me);
  assert.equal(producer(h.show(me), "heart", "star_well").per_hour, Math.round(PRODUCERS.star_well[3].hourly / 2));
  h.work(me, id("emberling"), { realm: "heart", kind: "star_well" });
  later(10 * MINUTE);
  assert.equal(producer(h.show(me), "heart", "star_well").per_hour, PRODUCERS.star_well[3].hourly, "both slots filled");
});

test("a worker of the resource's schools earns 15% more, and a work trait its share (9.2, 11.3)", () => {
  const { t, me, h, id, later } = fresh();
  assert.equal(RULEBORN.featherkin.school, "Motion");
  h.work(me, id("featherkin"), { realm: "heart", kind: "star_well" });
  later(5 * MINUTE);
  assert.equal(producer(h.show(me), "heart", "star_well").per_hour, Math.round(80 * 1.15),
               "Motion and Matter ruleborn (+15%) at a Star Well");
  t.service.db.prepare(`UPDATE characters SET traits = '["well_digger"]' WHERE id = ?`).run(id("featherkin"));
  assert.equal(producer(h.show(me), "heart", "star_well").per_hour, Math.round(80 * 1.4), "and Well-digger's +25%");
  h.work(me, id("tidewalker"), { realm: "heart", kind: "garden" });
  t.service.db.prepare(`UPDATE characters SET traits = '["well_digger"]' WHERE id = ?`).run(id("tidewalker"));
  later(5 * MINUTE);
  assert.equal(producer(h.show(me), "heart", "garden").per_hour, 40, "a Well-digger is no better in a Garden");
});

test("a realm of the resource's school produces 10% more (5.2, 9.3)", () => {
  const { t, me, h, id, grant, later, keeper } = fresh();
  keeper(3);
  grant("starlight", 5_000);
  t.service.universe.open(me, "Skyfield");
  t.service.universe.build(me, { realm: "outer-1", kind: "star_well", n: 1, to: 1 });
  h.work(me, id("tidewalker"), { realm: "outer-1", kind: "star_well" });
  later(5 * MINUTE);
  assert.equal(producer(h.show(me), "outer-1", "star_well").per_hour, 88, "Skyfield boosts Starlight: 80 × 1.1");
});

test("collecting pays what a producer made into the ledger, a Garden's less the roster's 25% keep (9.3, 9.5)", () => {
  const { t, me, h, id, later } = fresh();
  h.work(me, id("tidewalker"), { realm: "heart", kind: "garden" });
  h.work(me, id("emberling"), { realm: "heart", kind: "aether_spring" });
  later(5 * MINUTE + HOUR);
  const got = h.collect(me, { realm: "heart", kind: "garden" });
  assert.deepEqual(got.collected, { resource: "essence", made: 40, kept: 10, paid: 30 });
  assert.equal(t.service.balance(me).essence, 30);
  assert.equal(h.collect(me, { realm: "heart", kind: "garden" }).collected.made, 0, "a second collection finds nothing");
  h.collect(me, { realm: "heart", kind: "aether_spring" });
  assert.equal(t.service.aether(me), Math.round(60 * 1.15), "an Emberling's Aether: Energy (+15%), the whole of it");
  refused(() => h.collect(me, { realm: "heart", kind: "vault" }), "not_a_producer");
});

test("a worker goes only into a free slot or Guardian Post, and what it made where it was is kept when it moves (5.8)", () => {
  const { t, me, h, id, grant, later } = fresh();
  h.work(me, id("tidewalker"), { realm: "heart", kind: "star_well" });
  refused(() => h.work(me, id("emberling"), { realm: "heart", kind: "star_well" }), "slots_full", { slots: 1 });
  refused(() => h.work(me, id("emberling"), { realm: "heart", kind: "hearth" }), "not_a_workplace");
  refused(() => h.work(me, id("emberling"), { realm: "heart", kind: "guardian_post" }), "no_such_building");
  assert.equal(h.work(me, id("tidewalker"), { realm: "heart", kind: "star_well" }).repeated, true, "a retry changes nothing");
  later(5 * MINUTE + HOUR);
  h.work(me, id("tidewalker"), { realm: "heart", kind: "garden" });
  later(2 * HOUR);
  const v = h.show(me);
  assert.equal(producer(v, "heart", "star_well").stored, 80, "the hour it worked the Well is kept");
  assert.equal(producer(v, "heart", "star_well").per_hour, 0);
  grant("starlight", 1_000);
  t.service.universe.build(me, { realm: "heart", kind: "guardian_post", n: 1, to: 1 });
  h.work(me, id("emberling"), { realm: "heart", kind: "guardian_post" });
  assert.equal(h.show(me).characters.find((c) => c.kind === "emberling").state, "guarding");
  h.work(me, id("emberling"), {});
  assert.equal(h.show(me).characters.find((c) => c.kind === "emberling").state, "idle", "recalled");
});

test("a producer raised a level is paid at the old level for the time before (9.3, 10.2)", () => {
  const { t, me, h, id, grant, later } = fresh();
  h.work(me, id("tidewalker"), { realm: "heart", kind: "star_well" });
  later(5 * MINUTE + HOUR);
  t.service.db.prepare("UPDATE buildings SET level = 2 WHERE owner = ? AND kind = 'keeper_s_spire'").run(me);
  grant("starlight", 900);
  t.service.universe.build(me, { realm: "heart", kind: "star_well", n: 1, to: 2 });
  later(HOUR);
  assert.equal(producer(h.show(me), "heart", "star_well").stored, 80 + PRODUCERS.star_well[1].hourly);
});

test("a birth at a Nursery costs 100 × 1.3455^owned Essence, waits for a ready birth, and is of the realm's school (9.5, 10.2, 11.5)", () => {
  const { t, me, h, grant, later, keeper } = fresh();
  keeper(3);
  grant("starlight", 5_000);
  t.service.universe.open(me, "Verdant");
  refused(() => h.birth(me, { realm: "outer-1", n: 4 }), "no_nursery");
  t.service.universe.build(me, { realm: "outer-1", kind: "nursery", n: 1, to: 1 });
  refused(() => h.birth(me, { realm: "outer-1", n: 4 }), "no_birth_ready", { next_at: t.clock.now + 6 * HOUR });
  later(6 * HOUR);
  const price = birthPrice(3);
  assert.equal(price, Math.round(100 * 1.3455 ** 3));
  refused(() => h.birth(me, { realm: "outer-1", n: 4 }), "not_enough_essence", { cost: price });
  grant("essence", 10_000);
  refused(() => h.birth(me, { realm: "outer-1", n: 5 }), "not_the_next_birth");
  const born = h.birth(me, { realm: "outer-1", n: 4 });
  const c = born.home.characters.find((x) => x.id === born.born);
  assert.equal(c.school, "Life", "Verdant's Nursery favours Life ruleborn (§5.2)");
  assert.equal(c.traits.length, 2);
  assert.equal(t.service.balance(me).essence, 10_000 - price);
  assert.equal(h.birth(me, { realm: "outer-1", n: 4 }).repeated, true, "a retry is answered as born");
  assert.equal(t.service.balance(me).essence, 10_000 - price, "and charged once");
  refused(() => h.birth(me, { realm: "outer-1", n: 5 }), "no_birth_ready");
  later(3 * 6 * HOUR);
  assert.equal(h.show(me).nurseries[0].ready, 3, "a Nursery holds 3");
});

test("the roster lives in the Spire's three places and each Hearth's homes, and a birth needs a free one (11.4, 11.5)", () => {
  const { t, me, h, grant, later, keeper } = fresh();
  const places = h.show(me).places;
  assert.deepEqual(places.map((p) => [p.home, p.room]), [["spire", 3], ["heart", 3]]);
  keeper(3);
  grant("starlight", 5_000);
  grant("essence", 100_000);
  t.service.universe.open(me, "Verdant");
  t.service.universe.build(me, { realm: "outer-1", kind: "nursery", n: 1, to: 1 });
  later(18 * HOUR);
  for (const n of [4, 5, 6]) h.birth(me, { realm: "outer-1", n });
  later(18 * HOUR);
  refused(() => h.birth(me, { realm: "outer-1", n: 7 }), "no_place");
  t.service.universe.build(me, { realm: "outer-1", kind: "hearth", n: 1, to: 1 });
  assert.equal(h.birth(me, { realm: "outer-1", n: 7 }).home.characters.at(-1).home, "outer-1", "a new Hearth's homes");
});

test("a character rises a level for 150 × 1.55^(level − 2) Essence, no higher than its home allows (9.5, 11.4)", () => {
  const { t, me, h, id, grant } = fresh();
  grant("essence", 1_000);
  refused(() => h.level(me, id("featherkin"), 3), "not_the_next_level");
  h.level(me, id("featherkin"), 2);
  assert.equal(t.service.balance(me).essence, 1_000 - levelPrice(2));
  assert.equal(levelPrice(2), 150);
  assert.equal(levelPrice(10), Math.round(150 * 1.55 ** 8), "about 5,000 for level 10");
  refused(() => h.level(me, id("featherkin"), 3), "home_too_low", { top: 2 });
  assert.equal(h.move(me, id("featherkin"), "heart").home.characters.find((c) => c.kind === "featherkin").home, "heart",
               "a character moves between free places at no cost");
  assert.equal(t.service.balance(me).essence, 1_000 - levelPrice(2));
});

test("the home over HTTP: read, set to work, collected, and refused with the reason (9.3, 11.5)", async () => {
  const t = server();
  const call = async (method, path, token, json) => {
    const r = await t.handle(new Request(`https://edge.example${path}`, {
      method, headers: { authorization: `Bearer ${token}`, ...(json ? { "content-type": "application/json" } : {}) },
      body: json ? JSON.stringify(json) : undefined }));
    return { status: r.status, body: await r.json() };
  };
  const { token } = t.service.session("gc:keeper");
  const read = await call("GET", "/v1/home", token);
  assert.equal(read.status, 200);
  assert.equal(read.body.characters.length, 3);
  const id = read.body.characters[0].id;
  const set = await call("POST", `/v1/home/characters/${id}/work`, token, { realm: "heart", kind: "garden", n: 1 });
  assert.equal(set.status, 200);
  assert.equal(set.body.home.characters[0].state, "working");
  t.clock.now += 50 * MINUTE;                       // inside the session's life
  const got = await call("POST", "/v1/home/collect", token, { realm: "heart", kind: "garden" });
  assert.equal(got.status, 200, JSON.stringify(got.body));
  assert.equal(got.body.collected.resource, "essence");
  assert.ok(got.body.collected.made > 0);
  const birth = await call("POST", "/v1/home/births", token, { realm: "heart", n: 4 });
  assert.equal(birth.status, 404);
  assert.equal(birth.body.error, "no_nursery");
});
