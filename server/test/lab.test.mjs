// §8.6's Resonance Lab (lab.mjs).

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { chordOf, labLevel, LAUNCH_RESONANCES } from "../src/lab.mjs";
import { CROWN } from "../src/weaving.mjs";
import { server } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const RESONANCES = JSON.parse(readFileSync(new URL("../../content/resonances.json", import.meta.url), "utf8"));
const LAWS = Object.fromEntries(JSON.parse(readFileSync(new URL("../../content/laws.json", import.meta.url), "utf8"))
  .map((l) => [l.id, l]));
const MINUTE = 60_000;

function withLab(level = 1) {
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:lab").account;
  t.service.db.prepare("UPDATE accounts SET keeper_level = 40 WHERE id = ?").run(me);
  t.service.book(me, "starlight", 5_000_000, "a test's grant");
  t.service.codex.show(me);
  for (let s = 2; s <= 2 * level - 1; s++) t.service.universe.build(me, { realm: "heart", kind: "keeper_s_spire", n: 1, to: s });
  for (let l = 1; l <= level; l++) t.service.universe.build(me, { realm: "heart", kind: "resonance_lab", n: 1, to: l });
  return { t, me, lab: t.service.lab };
}

const refused = (fn, reason) => assert.throws(fn, (e) => e.reason === reason, reason);

test("the Lab has §10.2's chambers and hours, 12 signature resonances at launch, and none before it is built (8.6, 10.2)", () => {
  assert.deepEqual([1, 2, 3, 4, 5].map(labLevel), [
    { slots: 1, minutes: 480 }, { slots: 1, minutes: 390 }, { slots: 2, minutes: 300 },
    { slots: 2, minutes: 240 }, { slots: 3, minutes: 180 }]);
  assert.equal(LAUNCH_RESONANCES.length, 12, "§8.6: 44, 12 at launch");
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:nolab").account;
  assert.deepEqual(t.service.lab.show(me).chambers, []);
  refused(() => t.service.lab.start(me, { chamber: 1, laws: ["bloom", "slow_rivers"] }), "no_lab");
});

test("the first experiment takes five free minutes and finds Mangrove banks in Slow rivers and Bloom, paying pages; the home names when it finishes, and the Harmony view then names it (8.6, 10.2, 14.6, 16)", () => {
  const { t, me, lab } = withLab();
  const was = lab.show(me).remaining;
  assert.deepEqual(lab.show(me).terms, { minutes: facts.LAB_FIRST_MINUTES, aether: 0, first: true });
  lab.start(me, { chamber: 1, laws: ["slow_rivers", "bloom"] });
  refused(() => lab.start(me, { chamber: 1, laws: ["half_gravity", "bloom"] }), "chamber_busy");
  assert.equal(lab.show(me).chambers[0].running.laws.length, 2);
  t.service.book(me, "aether", 10_000, "a test's grant");
  t.service.weaving.weave(me, { realm: "heart", slot: 1, law: "slow_rivers" });
  t.service.weaving.weave(me, { realm: "heart", slot: 2, law: "bloom" });
  const unnamed = t.service.weaving.harmony(me).realms[0].resonances[0];
  assert.equal(unnamed.name, null, "unnamed until the Lab names it (8.6)");
  const before = t.service.codex.show(me).laws.find((l) => l.law === "slow_rivers").pages;
  const ready = t.clock.now + facts.LAB_FIRST_MINUTES * MINUTE;
  assert.deepEqual(t.service.home.show(me).experiments, [{ chamber: 1, ready_at: ready }],
                   "the home names when it finishes, the device's own notice (14.6)");
  t.clock.now += facts.LAB_FIRST_MINUTES * MINUTE;
  assert.deepEqual(t.service.home.show(me).experiments, [], "finished, no timer left to set");
  const v = lab.show(me);
  assert.deepEqual(v.chambers[0].result, { laws: ["slow_rivers", "bloom"], found: "resonance", id: "mangrove_banks",
                                            pages: { law: "slow_rivers", n: facts.LAB_EMPTY_PAGES } });
  assert.deepEqual(v.found, [{ kind: "resonance", id: "mangrove_banks" }]);
  assert.equal(t.service.codex.show(me).laws.find((l) => l.law === "slow_rivers").pages, before + facts.LAB_EMPTY_PAGES);
  assert.equal(t.service.weaving.harmony(me).realms[0].resonances[0].name, "Mangrove banks", "the Harmony view names it");
  const now = lab.show(me).remaining;
  assert.deepEqual([now.Time, now.Life, now.Motion], [was.Time - 1, was.Life - 1, was.Motion],
                   "one fewer to find in each school the resonance joins (8.6)");
});

test("an experiment after the first costs 400 Aether a Lab level and the level's hours, a fifth off by the Archivist at home or on guard (8.6, 9.5, 11.7)", () => {
  const { t, me, lab } = withLab();
  lab.start(me, { chamber: 1, laws: ["slow_rivers", "half_gravity"] });
  t.clock.now += facts.LAB_FIRST_MINUTES * MINUTE;
  assert.deepEqual(lab.show(me).terms, { minutes: 384, aether: facts.LAB_AETHER_PER_LEVEL, first: false });
  refused(() => lab.start(me, { chamber: 1, laws: ["slow_rivers", "half_gravity"] }), "not_enough_aether");
  t.service.keeper.setGuardian(me, "the_archivist");
  assert.equal(lab.show(me).terms.minutes, 384, "§11.7: an at-home effect applies on guard too");
  t.service.book(me, "aether", 1_000, "a test's grant");
  lab.start(me, { chamber: 1, laws: ["slow_rivers", "half_gravity"] });
  assert.equal(t.service.aether(me), 600);
  refused(() => lab.start(me, { chamber: 2, laws: ["bloom", "half_gravity"] }), "no_such_chamber");
  refused(() => lab.start(me, { chamber: 1, laws: ["bloom", "glass"] }), "chamber_busy");
});

test("an empty experiment pays 3 pages of the worked-on law if it shares a placed law's school, else of the first placed; after three empties with one law the Lab hints one of its resonances by its partner's school (7.6, 8.6)", () => {
  const { t, me, lab } = withLab();
  t.service.book(me, "aether", 10_000, "a test's grant");
  refused(() => lab.start(me, { chamber: 1, laws: ["glass", "bloom"] }), "law_not_restored");
  refused(() => lab.start(me, { chamber: 1, laws: ["bloom", "slow_rivers", "half_gravity"] }), "malformed_body");
  refused(() => lab.start(me, { chamber: 1, laws: ["bloom", "bloom"] }), "malformed_body");
  t.service.codex.workOn(me, "bounce");                   // a Motion law, as Half gravity is
  const pages = (law) => t.service.codex.show(me).laws.find((l) => l.law === law)?.pages ?? 0;
  for (let i = 0; i < 3; i++) {
    const hg = pages("half_gravity");
    const bounce = pages("bounce");
    lab.start(me, { chamber: 1, laws: ["half_gravity", "slow_rivers"] });
    t.clock.now += 8 * 60 * MINUTE;
    const r = lab.show(me).chambers[0].result;
    assert.equal(r.found, null);
    assert.deepEqual(r.pages, { law: "bounce", n: facts.LAB_EMPTY_PAGES }, "the worked-on law, in a placed law's school");
    assert.equal(pages("bounce"), bounce + facts.LAB_EMPTY_PAGES);
    assert.equal(pages("half_gravity"), hg);
    if (i < 2) assert.equal(r.hint, null);
    else {
      assert.ok(r.hint, "the third empty experiment with these laws hints");
      const hinted = lab.show(me).hinted;
      assert.equal(hinted.length, 1);
      const res = RESONANCES.find((x) => x.id === hinted[0]);
      assert.ok(res.laws.includes(r.hint.law), "a resonance of the law used thrice");
      const partner = res.laws.find((l) => l !== r.hint.law);
      assert.equal(r.hint.school, LAWS[partner].school, "hinted by its partner's school (8.6)");
      assert.ok(!lab.show(me).found.some((f) => f.id === res.id), "hinted, not found");
    }
  }
  t.service.codex.workOn(me, "glass");                    // Matter: in neither placed law's school
  lab.start(me, { chamber: 1, laws: ["half_gravity", "slow_rivers"] });
  t.clock.now += 8 * 60 * MINUTE;
  assert.deepEqual(lab.show(me).chambers[0].result.pages, { law: "half_gravity", n: facts.LAB_EMPTY_PAGES }, "else the first placed");
});

/** An island bundle running `laws`, as lawsOf reads one: a 9-tile realm
 *  with no guards or wards. */
function islandRunning(laws) {
  const head = new Uint8Array(14 + 9 * 9 * 3 + 2);
  const parts = [head, Uint8Array.of(laws.length)];
  for (const l of laws) parts.push(Uint8Array.of(l.length), new TextEncoder().encode(l), Uint8Array.of(0, 0));
  const out = new Uint8Array(parts.reduce((n, x) => n + x.length, 0));
  let at = 0;
  for (const x of parts) { out.set(x, at); at += x.length; }
  return out;
}

test("from Lab level 3 the third sphere names, once a day and free, the first chord in §8.5's table the player has woven or crossed; a heist crossing a resonance or chord hints it (8.5, 8.6)", () => {
  assert.equal(chordOf(["bloom", "brittle_stone", "tilt"]).id, "wild_hunt", "§8.8's cheapest chord-completing triple");
  assert.equal(chordOf(["bloom", "slow_rivers", "half_gravity"]), null);
  const low = withLab(2);
  assert.equal(low.lab.show(low.me).sphere, null, "no third sphere below level 3");
  refused(() => low.lab.name(low.me), "lab_level_too_low");
  const { t, me, lab } = withLab(3);
  assert.equal(lab.show(me).chambers.length, 2);
  assert.deepEqual(lab.show(me).sphere, { today: false, next_at: null, can: false });
  refused(() => lab.name(me), "no_chord_to_name");
  // A heist crosses an island running Wild hunt's three laws and Mangrove
  // banks' two, among other resonances: each hinted, none found.
  const real = t.service.store.get.bind(t.service.store);
  const island = ["bloom", "brittle_stone", "slow_rivers", "tilt"];
  t.service.store.get = (b) => (b === "crossed" ? islandRunning(island) : real(b));
  t.service.codex.afterHeist({ attacker: me, bundle: "crossed", mode: "raid" }, { broken: 0, caught: 0 }, t.clock.now);
  const resonances = RESONANCES.filter((r) => r.laws.every((l) => island.includes(l))).map((r) => r.id).sort();
  assert.ok(resonances.includes("mangrove_banks"));
  assert.deepEqual(lab.show(me).hinted.sort(), [...resonances, "wild_hunt"].sort());
  assert.deepEqual(lab.show(me).found, []);
  // Ghost tide's laws woven: Bloom and Bounce in the Heart, Half gravity
  // crowned, a law every realm runs (8.8).
  t.service.book(me, "aether", 100_000, "a test's grant");
  t.service.codex.add(me, "bounce", 10, t.clock.now);
  t.service.codex.restore(me, "bounce");
  for (const [realm, slot, law] of [["heart", 1, "bloom"], ["heart", 2, "bounce"], ["crown", 1, "half_gravity"]]) {
    t.service.weaving.weave(me, { realm, slot, law });
  }
  assert.deepEqual(t.service.weaving.stability(me).chords, [], "its 192-point draw is past this capacity");
  // Sounding, as the simulation sounds it once the universe can pay the
  // draw (weaving.test.mjs does the same).
  const priced = t.service.weaving.stability.bind(t.service.weaving);
  t.service.weaving.stability = (a, x) => ({ ...priced(a, x), chords: [{ realm: 0, chord: "ghost_tide" }] });
  const aether = t.service.aether(me);
  assert.equal(lab.show(me).sphere.can, true);
  const first = lab.name(me);
  assert.equal(first.named, "ghost_tide", "the table's order: Ghost tide before Wild hunt");
  assert.equal(t.service.aether(me), aether, "free");
  assert.equal(t.service.weaving.harmony(me).realms[0].chords[0].name, "Ghost tide", "the Harmony view names it");
  const day = 24 * 60 * MINUTE;
  refused(() => lab.name(me), "named_today");
  assert.equal(lab.show(me).sphere.next_at, Math.floor(t.clock.now / day) * day + day);
  t.clock.now = Math.floor(t.clock.now / day) * day + day;
  assert.equal(lab.name(me).named, "wild_hunt", "the next day, the crossed chord");
  assert.deepEqual(lab.show(me).hinted.sort(), resonances, "a named chord is no longer only hinted");
  t.clock.now += day;
  refused(() => lab.name(me), "no_chord_to_name");
  assert.deepEqual(lab.show(me).found.map((f) => f.id), ["ghost_tide", "wild_hunt"]);
});

test("the Lab is served over HTTP (8.6)", async () => {
  const { t, me } = withLab();
  const { token } = t.service.session("gc:lab");
  const call = (method, json) => t.handle(new Request("https://edge.example/v1/lab", {
    method, headers: { authorization: `Bearer ${token}`, ...(json ? { "content-type": "application/json" } : {}) },
    body: json ? JSON.stringify(json) : undefined }));
  const v = await (await call("GET")).json();
  assert.equal(v.chambers.length, 1);
  const started = await (await call("POST", { chamber: 1, laws: ["slow_rivers", "bloom"] })).json();
  assert.ok(started.chambers[0].running);
  const sphere = await t.handle(new Request("https://edge.example/v1/lab/sphere", {
    method: "POST", headers: { authorization: `Bearer ${token}` } }));
  assert.deepEqual([sphere.status, (await sphere.json()).error], [409, "lab_level_too_low"]);
  assert.equal(me.length > 0, true);
  assert.equal(CROWN, "crown");
});
