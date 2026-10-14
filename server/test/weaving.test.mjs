// What is woven, kept on the server (§5.1, §5.5, §5.6), and what it changes
// at home: production's law terms (§9.3) and births (§11.3, §11.5).

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { LAW_TRAITS, birthSchools } from "../src/home.mjs";
import { confirm } from "../src/offline.mjs";
import { CROWN, recommend } from "../src/weaving.mjs";
import { server } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const LAWS = Object.fromEntries(JSON.parse(readFileSync(new URL("../../content/laws.json", import.meta.url), "utf8"))
  .map((l) => [l.id, l]));
const MINUTE = 60_000;

function fresh(aether = 10_000) {
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:weaver").account;
  t.service.book(me, "aether", aether, "a test's grant");
  const w = t.service.weaving;
  const slot = (realm, n) => w.show(me).realms.find((r) => r.realm === realm).slots[n - 1];
  return { t, me, w, slot };
}

function refused(fn, reason) {
  assert.throws(fn, (err) => err.reason === reason, reason);
}

test("a restored law is woven into a realm's slot for 40 Aether a point of its cost, weaving 10 minutes at tier I and working after (5.6)", () => {
  const { t, me, w, slot } = fresh();
  // The tests' first week is Heavy Stars': "Motion laws cost 30% less"
  // (§18.3), priced in the same function as every other term (TD.14).
  assert.equal(t.service.era().id, "heavy_stars");
  const cost = Math.round(LAWS.half_gravity.stability_cost * 0.7 * facts.WEAVE_AETHER_PER_POINT);
  const before = t.service.aether(me);
  assert.equal(w.show(me).realms.find((r) => r.realm === "heart").prices.half_gravity, cost, "the price is shown first");
  w.weave(me, { realm: "heart", slot: 1, law: "half_gravity" });
  assert.equal(before - t.service.aether(me), cost, "12 points at tier I, 30% off in Heavy Stars' week: 336 Aether");
  assert.deepEqual(slot("heart", 1), { slot: 1, law: "half_gravity", tier: 1, ready_at: t.clock.now + 10 * MINUTE, weaving: true });
  assert.deepEqual(w.working(me), {}, "while a slot is being woven it is empty");
  t.clock.now += 10 * MINUTE;
  assert.deepEqual(w.working(me), { heart: [{ law: "half_gravity", tier: 1 }] });
  assert.equal(w.weave(me, { realm: "heart", slot: 1, law: "half_gravity" }).repeated, true, "a retry pays nothing");
  assert.equal(before - t.service.aether(me), cost);
  assert.equal(w.show(me).realms.find((r) => r.realm === "heart").slots.length, 2, "the Heart has realm level 3's two slots");
  refused(() => w.weave(me, { realm: "heart", slot: 3, law: "bloom" }), "no_such_slot");
  refused(() => w.weave(me, { realm: "heart", slot: 1, law: "bloom" }), "slot_taken");
  refused(() => w.weave(me, { realm: "heart", slot: 2, law: "half_gravity" }), "already_woven_here");
  refused(() => w.weave(me, { realm: "heart", slot: 2, law: "haste" }), "law_not_restored");
  refused(() => w.weave(me, { realm: "heart", slot: 2, law: "no_such" }), "no_such_law");
  refused(() => w.weave(me, { realm: "outer-1", slot: 1, law: "bloom" }), "no_such_realm");
  const poor = fresh(100);
  refused(() => poor.w.weave(poor.me, { realm: "heart", slot: 1, law: "bloom" }), "not_enough_aether");
});

test("crown slots open at Spire levels 2 and 5, a crown law costs double, and a law is crowned or woven in a realm, never both (5.1, 5.5)", () => {
  const { t, me, w, slot } = fresh();
  refused(() => w.weave(me, { realm: CROWN, slot: 1, law: "bloom" }), "no_such_slot");
  assert.equal(w.show(me).realms[0].opens_at, 2, "the first crown slot opens at Spire level 2");
  t.service.db.prepare("UPDATE accounts SET keeper_level = 40 WHERE id = ?").run(me);
  t.service.book(me, "starlight", 500_000, "a test's grant");
  t.service.universe.build(me, { realm: "heart", kind: "keeper_s_spire", n: 1, to: 2 });
  assert.equal(w.show(me).realms[0].slots.length, 1, "Spire 2 opens the first crown slot");
  assert.equal(w.show(me).realms[0].opens_at, 5, "and the second waits for Spire level 5");
  const before = t.service.aether(me);
  w.weave(me, { realm: CROWN, slot: 1, law: "bloom" });
  assert.equal(before - t.service.aether(me),
               Math.round(LAWS.bloom.stability_cost * facts.CROWN_COST_FACTOR * facts.WEAVE_AETHER_PER_POINT),
               "a crown law costs double stability");
  assert.equal(slot(CROWN, 1).law, "bloom");
  refused(() => w.weave(me, { realm: "heart", slot: 1, law: "bloom" }), "crowned");
  w.weave(me, { realm: "heart", slot: 1, law: "slow_rivers" });
  t.service.universe.build(me, { realm: "heart", kind: "keeper_s_spire", n: 1, to: 3 });
  t.service.universe.build(me, { realm: "heart", kind: "keeper_s_spire", n: 1, to: 4 });
  t.service.universe.build(me, { realm: "heart", kind: "keeper_s_spire", n: 1, to: 5 });
  assert.equal(w.show(me).realms[0].slots.length, 2, "Spire 5 opens the second");
  assert.equal(w.show(me).realms[0].opens_at, null, "and no more open");
  assert.equal(w.show(me).realms[1].slots.length, facts.LAW_SLOTS[2], "the Heart keeps realm level 3's slots");
  refused(() => w.weave(me, { realm: CROWN, slot: 2, law: "slow_rivers" }), "woven_in_a_realm");
});

test("an emptied slot rests an hour before it is woven again, and a law woven in a realm of its school costs a fifth less (5.5, 5.6)", () => {
  const { t, me, w, slot } = fresh();
  w.weave(me, { realm: "heart", slot: 1, law: "bloom" });
  w.unweave(me, { realm: "heart", slot: 1 });
  assert.deepEqual(slot("heart", 1), { slot: 1, law: null, rests_until: t.clock.now + 60 * MINUTE });
  refused(() => w.weave(me, { realm: "heart", slot: 1, law: "bloom" }), "slot_resting");
  assert.equal(w.unweave(me, { realm: "heart", slot: 1 }).repeated, true, "an empty slot is answered as emptied");
  t.clock.now += 60 * MINUTE;
  w.weave(me, { realm: "heart", slot: 1, law: "bloom" });
  assert.equal(slot("heart", 1).law, "bloom");
  // A Verdant realm is Life's: Bloom costs 0.8 there.
  t.service.db.prepare("UPDATE accounts SET keeper_level = 3 WHERE id = ?").run(me);
  t.service.book(me, "starlight", 2_000, "a test's grant");
  t.service.universe.open(me, "Verdant");
  const verdant = w.show(me).realms.find((r) => r.realm === "outer-1").prices.bloom;
  assert.equal(verdant, Math.round(LAWS.bloom.stability_cost * facts.OWN_SCHOOL_COST_FACTOR * facts.WEAVE_AETHER_PER_POINT));
});

test("a law of a producer's school adds 10% to it in its realm, a crowned one 5% in every realm, from when its weaving ends (9.3)", () => {
  const { t, me, w } = fresh();
  const h = t.service.home;
  const tide = h.show(me).characters.find((c) => c.kind === "tidewalker").id;
  h.work(me, tide, { realm: "heart", kind: "star_well" });
  t.clock.now += 5 * MINUTE;
  const plain = h.rate(me, "heart", "star_well", t.clock.now).perHour;
  w.weave(me, { realm: "heart", slot: 1, law: "half_gravity" });
  assert.equal(h.rate(me, "heart", "star_well", t.clock.now).perHour, plain, "not while it weaves");
  const start = t.clock.now;
  t.clock.now += 70 * MINUTE;
  const woven = h.rate(me, "heart", "star_well", t.clock.now).perHour;
  assert.ok(Math.abs(woven / plain - (1 + facts.PRODUCTION_LAW_BONUS[0])) < 1e-9, "Half gravity is Motion's: Starlight +10%");
  // What the Star Well made: ten minutes at the old rate, an hour at the new.
  const made = h.made(me, "heart", "star_well", start, t.clock.now);
  const expect = (plain * 10 + woven * 60) / 60 * 1000;
  assert.ok(Math.abs(made - expect) < 1, `${made} against ${expect}`);
  // Bloom, Life's, does nothing for Starlight.
  w.weave(me, { realm: "heart", slot: 2, law: "bloom" });
  t.clock.now += 10 * MINUTE;
  assert.ok(Math.abs(h.rate(me, "heart", "star_well", t.clock.now).perHour - woven) < 1e-9);
  assert.equal(h.show(me).producers.find((p) => p.kind === "star_well").unkept.includes("laws"), false,
               "the law term is kept now");
});

test("a birth's school is drawn 3 for each law woven in its realm, 2 for the realm's own and 1 for each crown law, and a law's traits three times as likely there (11.3, 11.5)", () => {
  assert.deepEqual(birthSchools("Life", [], []), [["Life", 2]]);
  assert.deepEqual(birthSchools("Life", ["half_gravity", "bloom"], ["slow_rivers"]),
                   [["Life", 5], ["Motion", 3], ["Time", 1]]);
  assert.deepEqual(LAW_TRAITS.floaty, ["half_gravity"], "Floaty: an extra leap under Half gravity");
  assert.deepEqual(LAW_TRAITS.swimmer, ["slow_rivers"]);
  // Over many draws, Floaty comes three times as often where Half gravity runs.
  const { t, me } = fresh();
  const h = t.service.home;
  let plain = 0;
  let running = 0;
  for (let i = 0; i < 3000; i++) {
    let n = 0;
    const roll = (k) => { n = (n * 1103515245 + 12345 + i * 7919) % 2147483648; return n % k; };
    if (h.traits(roll, 1).includes("floaty")) plain++;
    n = 0;
    if (h.traits(roll, 1, ["half_gravity"]).includes("floaty")) running++;
  }
  assert.ok(running / plain > 2.4 && running / plain < 3.6, `${running} against ${plain}`);
  assert.ok(me);
});

test("weaving offline is confirmed on reconnection, once, and over HTTP (24, 5.6)", async () => {
  const { t, me, w } = fresh();
  const queue = [{ do: "weave", realm: "heart", slot: 1, law: "bloom" }, { do: "unweave", realm: "heart", slot: 2 }];
  const first = confirm(t.service, me, queue);
  assert.deepEqual(first.results, [{ confirmed: true }, { confirmed: true, repeated: true }]);
  assert.equal(first.weaving.realms[1].slots[0].law, "bloom", "a queue that weaves answers with what is woven");
  const aether = t.service.aether(me);
  assert.deepEqual(confirm(t.service, me, queue).results.map((r) => r.repeated), [true, true]);
  assert.equal(t.service.aether(me), aether, "paid once");
  const token = t.service.session("gc:weaver").token;
  const call = async (method, path, json) => {
    const r = await t.handle(new Request(`https://edge.example${path}`, {
      method, headers: { authorization: `Bearer ${token}`, ...(json ? { "content-type": "application/json" } : {}) },
      body: json ? JSON.stringify(json) : undefined }));
    return { status: r.status, body: await r.json() };
  };
  const read = await call("GET", "/v1/weaving");
  assert.equal(read.body.realms[1].slots[0].law, "bloom");
  const woven = await call("POST", "/v1/weaving", { realm: "heart", slot: 2, law: "half_gravity" });
  assert.equal(woven.body.weaving.realms[1].slots[1].law, "half_gravity");
  const gone = await call("DELETE", "/v1/weaving/heart/2");
  assert.equal(gone.body.weaving.realms[1].slots[1].law, null);
  const resting = await call("POST", "/v1/weaving", { realm: "heart", slot: 2, law: "half_gravity" });
  assert.equal(resting.status, 409);
  assert.equal(resting.body.error, "slot_resting");
  assert.ok(w);
});

test("a law's price counts the realm's other laws and the week's era, as the simulation prices them (5.5, 8.3, 8.4, 18.3, TD.14)", () => {
  const { t, me, w } = fresh();
  w.weave(me, { realm: "heart", slot: 1, law: "slow_rivers" });
  const heart = w.show(me).realms.find((r) => r.realm === "heart");
  // Bloom beside Slow rivers: Mangrove banks, 0.8. Half gravity: Flow
  // against Weight, 1.25, and Heavy Stars' 30% off a Motion law.
  assert.equal(heart.prices.bloom, Math.round(11 * 0.8 * 40));
  assert.equal(heart.prices.half_gravity, Math.round(12 * 0.7 * 1.25 * 40));
  const priced = w.stability(me, { law: "bloom", tier: 1, realm: "heart" });
  assert.equal(priced.lines.at(-1).resonances, 1);
  assert.equal(heart.prices.bloom, Math.round(priced.lines.at(-1).micro * 40 / 1_000_000), "the same function");
  const s = w.show(me).stability;
  assert.equal(s.capacity, 30 + 8 * t.service.universe.spire(me), "a Spire and no Anchor Stone yet");
  assert.ok(Math.abs(s.total - 10) < 1e-9 && s.band === 0, JSON.stringify(s));
});

test("each realm offers every restored law with its points, price, time, band after and the notes it would harmonise and clash on, and recommends two or three, harmony first, clash last, then the cheapest (23.2, 5.5, 5.6)", () => {
  const { me, w } = fresh();
  w.weave(me, { realm: "heart", slot: 1, law: "slow_rivers" });
  const heart = w.show(me).realms.find((r) => r.realm === "heart");
  assert.equal(heart.type, "Heart");
  assert.equal(w.show(me).realms[0].type, null, "the crown is no realm");
  assert.deepEqual(heart.offers.map((o) => o.law), ["bloom", "half_gravity"], "what is woven there is not offered");
  const bloom = heart.offers.find((o) => o.law === "bloom");
  const gravity = heart.offers.find((o) => o.law === "half_gravity");
  assert.equal(bloom.price, heart.prices.bloom, "the offer's price is the price shown");
  assert.equal(bloom.resonances, 1, "Mangrove banks");
  assert.equal(bloom.minutes, facts.WEAVE_MINUTES[0]);
  assert.deepEqual(gravity.clashes, ["flow"], "Weight against Slow rivers' Flow");
  assert.ok(gravity.band >= bloom.band && gravity.strain > bloom.strain);
  assert.deepEqual(heart.recommended, ["bloom", "half_gravity"], "the one that harmonises first, the one that clashes last");
  w.weave(me, { realm: "heart", slot: 2, law: "bloom" });
  assert.deepEqual(w.show(me).realms.find((r) => r.realm === "heart").recommended, [], "no free slot, no recommendation");
});

test("recommendations: a clash after every law without one, a harmony or resonance before a law with neither, by price within each, at most three (23.2)", () => {
  const offer = (law, price, { harmonies = [], clashes = [], resonances = 0, refused = null } = {}) =>
    ({ law, price, harmonies, clashes, resonances, refused });
  const offers = [
    offer("a", 100, { clashes: ["flow"], harmonies: ["life"] }),
    offer("b", 500),
    offer("c", 300, { harmonies: ["life"] }),
    offer("d", 50, { refused: "would_break" }),
    offer("e", 200),
    offer("f", 400, { resonances: 1 }),
  ];
  assert.deepEqual(recommend(offers, true), ["c", "f", "e"]);
  assert.deepEqual(recommend(offers.filter((o) => o.law !== "c" && o.law !== "f" && o.law !== "e" && o.law !== "b"), true),
                   ["a"], "a clash is still recommended when nothing else can be woven");
  assert.deepEqual(recommend(offers, false), []);
});

test("no weave may take strain to Breaking, and a universe at Breaking weaves nothing new (5.5)", () => {
  const { t, me, w } = fresh(100_000);
  w.show(me);
  t.service.db.prepare("UPDATE codex SET tier = 3 WHERE owner = ? AND tier > 0").run(me);
  t.service.db.prepare("UPDATE accounts SET keeper_level = 40 WHERE id = ?").run(me);
  t.service.book(me, "starlight", 500_000, "a test's grant");
  t.service.universe.build(me, { realm: "heart", kind: "keeper_s_spire", n: 1, to: 2 });
  w.weave(me, { realm: "heart", slot: 1, law: "slow_rivers" });
  // Half gravity crowned in Heavy Stars' week: 30% off, as a Motion law.
  w.weave(me, { realm: CROWN, slot: 1, law: "half_gravity" });
  assert.equal(w.show(me).stability.band, 5, "Cracking, under 125%");
  const before = t.service.aether(me);
  refused(() => w.weave(me, { realm: "heart", slot: 2, law: "bloom" }), "would_break");
  assert.equal(t.service.aether(me), before, "a refused weave costs nothing");
  assert.equal(w.show(me).realms.find((r) => r.realm === "heart").offers[0].refused, "would_break", "and is shown refused");
  // The week turns, the discount ends, and strain passes 125% by itself.
  t.clock.now += 7 * 24 * 60 * MINUTE;
  assert.notEqual(t.service.era().id, "heavy_stars");
  assert.equal(w.show(me).stability.band, facts.STRAIN_BANDS.length, "Breaking");
  refused(() => w.weave(me, { realm: "heart", slot: 2, law: "bloom" }), "breaking");
  assert.deepEqual(w.show(me).realms.find((r) => r.realm === "heart").recommended, [], "nothing to recommend");
  w.unweave(me, { realm: CROWN, slot: 1 });
  assert.ok(w.show(me).stability.band < facts.STRAIN_BANDS.length, "taking a law out is how strain comes down");
});

test("the Harmony view shows each realm's laws with their notes, the crown's among them, and the harmonies, clashes, resonances and chords they make, each with its factor, a resonance or chord unnamed until the Lab names it (8.2, 8.3, 8.4, 8.6, 23.2)", () => {
  const { t, me, w } = fresh(100_000);
  t.service.codex.show(me);
  t.service.db.prepare("UPDATE accounts SET keeper_level = 40 WHERE id = ?").run(me);
  t.service.book(me, "starlight", 500_000, "a test's grant");
  t.service.universe.build(me, { realm: "heart", kind: "keeper_s_spire", n: 1, to: 2 });
  t.service.codex.add(me, "bounce", 10, t.clock.now);
  t.service.codex.restore(me, "bounce");
  w.weave(me, { realm: "heart", slot: 1, law: "half_gravity" });
  w.weave(me, { realm: "heart", slot: 2, law: "bounce" });
  w.weave(me, { realm: CROWN, slot: 1, law: "slow_rivers" });
  const heart = w.harmony(me).realms.find((r) => r.realm === "heart");
  assert.deepEqual(heart.laws, [
    { law: "half_gravity", notes: ["Flow"], crowned: false },
    { law: "bounce", notes: ["Flow", "Echo"], crowned: false },
    { law: "slow_rivers", notes: ["Weight"], crowned: true },
  ], "a crown law works in every realm (5.1)");
  assert.deepEqual(heart.harmonies, [{ note: "Flow", laws: ["half_gravity", "bounce"], factor: facts.HARMONY_COST_FACTOR }]);
  assert.deepEqual(heart.clashes, [{ notes: ["Flow", "Weight"], laws: ["half_gravity", "bounce", "slow_rivers"],
                                     factor: facts.DISSONANCE_COST_FACTOR }]);
  assert.deepEqual(heart.resonances, [], "no signature pair here");
  assert.deepEqual(heart.chords, [], "no chord sounds within this capacity");
  // A chord the simulation sounds in the Heart, with every law carrying one
  // of its notes; and Mangrove banks, Slow rivers with Bloom.
  w.unweave(me, { realm: "heart", slot: 2 });
  t.clock.now += 2 * 60 * MINUTE;
  w.weave(me, { realm: "heart", slot: 2, law: "bloom" });
  const real = w.stability.bind(w);
  w.stability = (account, extra) => ({ ...real(account, extra), chords: [{ realm: 0, chord: "tempest" }] });
  const again = w.harmony(me).realms.find((r) => r.realm === "heart");
  assert.deepEqual(again.resonances, [{ name: null, laws: ["slow_rivers", "bloom"], factor: facts.RESONANCE_COST_FACTOR }]);
  assert.deepEqual(again.chords, [{ name: null, notes: ["Flow", "Spark", "Glow"], laws: ["half_gravity"],
                                   factor: facts.CHORD_COST_FACTOR }]);
});

test("the Harmony view is served over HTTP (23.2)", async () => {
  const { t, me } = fresh();
  t.service.weaving.weave(me, { realm: "heart", slot: 1, law: "slow_rivers" });
  const token = t.service.session("gc:weaver").token;
  const r = await t.handle(new Request("https://edge.example/v1/weaving/harmony",
    { headers: { authorization: `Bearer ${token}` } }));
  assert.equal(r.status, 200);
  const body = await r.json();
  assert.deepEqual(body.realms[0].laws, [{ law: "slow_rivers", notes: ["Weight"], crowned: false }]);
});
