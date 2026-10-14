// Hatching (§11.5, §11.9, §11.10, §19.20): the odds a Nursery shows, the
// strays heists find and the roster takes or declines, naming from the word
// lists, and the outfit the first hatch brings.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { FORM_ORDER, HATCH_OUTFIT, RULEBORN, birthPrice, strayFormOdds } from "../src/home.mjs";
import { server } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const HOUR = 3_600_000;

function fresh() {
  const t = server();
  const { account: me, token } = t.service.session("gc:hatch");
  const h = t.service.home;
  h.show(me);
  const grant = (currency, n) => t.service.book(me, currency, n, "a test's grant");
  return { t, me, token, h, grant };
}

test("a stray's form is its law's note, Echo first on a tie, and even odds for a law with none of the three (11.9, 11.10)", () => {
  assert.deepEqual(FORM_ORDER, ["echo", "hush", "spark"], "five chords each for Echo and Hush, then alphabetical; four for Spark");
  const odds = (law) => Object.fromEntries(strayFormOdds(law).map((f) => [f.note, f.odds]));
  assert.deepEqual(odds("stillness"), { hush: 1, spark: 0, echo: 0 });
  assert.deepEqual(odds("sleepwalk"), { hush: 0, spark: 0, echo: 1 }, "Hush and Echo: Echo first");
  assert.deepEqual(odds("half_gravity"), { hush: 1 / 3, spark: 1 / 3, echo: 1 / 3 }, "Flow alone: even odds");
  assert.deepEqual(odds(null), { hush: 1 / 3, spark: 1 / 3, echo: 1 / 3 }, "an island with no laws");
});

test("a Nursery shows each kind's odds: its schools by §11.9's weights, the roles the player has fewest of twice as likely (11.5, 11.9)", () => {
  const { me, h } = fresh();
  // §11.9's example: Slow rivers and Bloom woven in a Tidehold, Time five
  // times in eight and Life three.
  const odds = h.kindOdds(me, [["Time", 5], ["Life", 3]]);
  const school = (s) => odds.filter((k) => RULEBORN[k.kind].school === s).reduce((n, k) => n + k.odds, 0);
  assert.ok(Math.abs(school("Time") - 5 / 8) < 1e-12 && Math.abs(school("Life") - 3 / 8) < 1e-12);
  assert.ok(Math.abs(odds.reduce((n, k) => n + k.odds, 0) - 1) < 1e-12);
  // The starting three hold a Scout, a Breaker and a Carrier: in Time, the
  // Tidewalker (a Carrier, held) is half as likely as each of the others.
  const tidewalker = odds.find((k) => k.kind === "tidewalker").odds;
  const hourkeeper = odds.find((k) => k.kind === "hourkeeper").odds;
  assert.ok(Math.abs(hourkeeper - 2 * tidewalker) < 1e-12, `${hourkeeper} ${tidewalker}`);
});

test("about one successful heist in eight finds a stray, born under one of the laws crossed, offered at the next birth's price (11.5)", () => {
  const { me, h } = fresh();
  const found = [];
  for (let i = 0; i < 800; i++) {
    const id = h.findStray(me, `heist-${i}`, ["slow_rivers", "stillness"], 0);
    if (id) found.push(id);
  }
  assert.equal(facts.STRAY_HEIST_ODDS, 8);
  assert.ok(found.length > 70 && found.length < 130, `${found.length} of 800`);
  const offered = h.show(me).strays;
  assert.equal(offered.length, found.length);
  const o = offered[0];
  assert.ok(["slow_rivers", "stillness"].includes(o.law));
  assert.equal(RULEBORN[o.kind].school, "Time", "both laws are Time's");
  assert.equal(o.traits.length, 3);
  assert.equal(new Set(o.traits).size, 3);
  assert.equal(o.cost, birthPrice(3));
});

test("a stray is taken for a birth's Essence with its law's form, once; declined, it goes its way (11.5)", async () => {
  const { t, me, token, h, grant } = fresh();
  let i = 0;
  while (!h.findStray(me, `take-${i}`, ["stillness"], 0)) i++;
  while (!h.findStray(me, `take-${++i}`, ["stillness"], 0));
  const [first, second] = h.show(me).strays;
  assert.throws(() => h.takeStray(me, first.id), (e) => e.reason === "not_enough_essence" && e.detail.cost === birthPrice(3));
  grant("essence", 1_000);
  const call = async (path) => {
    const r = await t.handle(new Request(`https://edge.example${path}`, {
      method: "POST", headers: { authorization: `Bearer ${token}` } }));
    return { status: r.status, body: await r.json() };
  };
  const took = await call(`/v1/home/strays/${first.id}/take`);
  assert.equal(took.status, 200, JSON.stringify(took.body));
  const born = took.body.home.characters.find((c) => c.id === took.body.born);
  assert.equal(born.kind, first.kind);
  assert.deepEqual(born.traits, first.traits);
  assert.equal(born.form, "hush", "Stillness carries Hush");
  assert.equal(born.via, "stray");
  assert.equal(t.service.balance(me).essence, 1_000 - birthPrice(3));
  assert.equal((await call(`/v1/home/strays/${first.id}/take`)).body.repeated, true, "a retry is answered as taken");
  assert.equal(t.service.balance(me).essence, 1_000 - birthPrice(3), "and pays nothing twice");
  const declined = await call(`/v1/home/strays/${second.id}/decline`);
  assert.equal(declined.status, 200);
  assert.deepEqual(declined.body.home.strays, []);
  assert.equal((await call(`/v1/home/strays/${second.id}/take`)).body.error, "stray_gone");
});

test("a heist that finds a stray says so, and the first heist's two strays are their own (11.5)", () => {
  const { t, me, h } = fresh();
  // The settlement's call, as service.settle makes it.
  assert.equal(h.firstStrays(me, ["stillness"], 0).length, 2);
  assert.deepEqual(h.firstStrays(me, ["stillness"], 0), [], "once");
  assert.ok(h.show(me).characters.filter((c) => c.via === "stray").every((c) => c.form === "hush"),
            "each first stray's form is its law's note");
  assert.equal(t.service.home.strays(me).length, 0);
});

test("a ruleborn is named from the word lists, and the first hatch brings a free outfit (19.20)", async () => {
  const { t, me, token, h, grant } = fresh();
  const id = h.show(me).characters[0].id;
  const named = h.name(me, id, { adjective: 3, noun: 7 });
  assert.deepEqual(named.home.characters[0].name, { adjective: 3, noun: 7 });
  assert.equal(h.name(me, id, { adjective: 3, noun: 7 }).repeated, true);
  assert.throws(() => h.name(me, id, { adjective: 999, noun: 0 }), (e) => e.reason === "not_a_word");
  const r = await t.handle(new Request(`https://edge.example/v1/home/characters/${id}/name`, {
    method: "POST", headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
    body: JSON.stringify({ adjective: 1, noun: 2 }) }));
  assert.equal(r.status, 200);
  assert.deepEqual((await r.json()).home.characters[0].name, { adjective: 1, noun: 2 });
  t.service.db.prepare("UPDATE accounts SET keeper_level = 3 WHERE id = ?").run(me);
  grant("starlight", 5_000);
  grant("essence", 5_000);
  t.service.universe.open(me, "Verdant");
  t.service.universe.build(me, { realm: "outer-1", kind: "nursery", n: 1, to: 1 });
  t.clock.now += 12 * HOUR;
  const first = h.birth(me, { realm: "outer-1", n: 4 });
  assert.equal(first.first, true);
  assert.equal(first.outfit, HATCH_OUTFIT);
  assert.ok(t.service.shop.owned(me).includes(HATCH_OUTFIT));
  assert.equal(t.service.shop.kindOf(HATCH_OUTFIT), "outfit");
  const again = h.birth(me, { realm: "outer-1", n: 5 });
  assert.equal(again.first, undefined, "only the first");
  const nursery = h.show(me).nurseries[0];
  assert.ok(Math.abs(nursery.kinds.reduce((n, k) => n + k.odds, 0) - 1) < 1e-12);
  assert.ok(nursery.kinds.every((k) => RULEBORN[k.kind].school === "Life"), "a Verdant Nursery with no laws: Life's alone");
});
