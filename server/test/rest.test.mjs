// A heist's crew named from the roster, and its rest (§11.6, §12.9, TD.34):
// against the real simulation build.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { restMinutes } from "../src/home.mjs";
import { openPlan, play, twoPlayers } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const content = (name) => JSON.parse(readFileSync(new URL(`../../content/${name}.json`, import.meta.url), "utf8"));
const KINDS = content("ruleborn").map((k) => k.id);
const TRAITS = content("traits").map((t) => t.id);
const MINUTE = 60_000;

/** The raider's roster, a lease, and the replay its three play with the
 *  manifest the device writes for them. */
function heist(t, crew) {
  const lease = t.service.lease(t.raider.account, t.bundle);
  const manifest = { members: crew.map((c) => ({ kind: KINDS.indexOf(c.kind), form: c.wire.form, level: c.level,
                                                 traits: c.traits.map((x) => TRAITS.indexOf(x)) })),
                     sage: 0, casts: [] };
  return { lease, replay: play(t, lease, { plan: openPlan(), manifest }) };
}

test("§11.6's rest: 45, 60 or 180 minutes by the outcome, less 5% a Hearth level, Loyal's 0.75 after a success and Sleepy's 1.5", () => {
  const [clean, loud, caught] = facts.REST_MINUTES;
  assert.equal(restMinutes("clean", true, [], 0), clean);
  assert.equal(restMinutes("loud", true, [], 0), loud);
  assert.equal(restMinutes("partial", true, [], 0), loud, "out of a Partial: 60");
  assert.equal(restMinutes("partial", false, [], 0), caught, "caught in a Partial: 180");
  assert.equal(restMinutes("foiled", false, [], 0), caught);
  assert.equal(restMinutes("clean", true, [], 4), clean * 0.8, "a level 4 Hearth cuts a fifth");
  assert.equal(restMinutes("partial", true, ["loyal"], 0), loud * 0.75, "Loyal counts one who got out of a Partial");
  assert.equal(restMinutes("partial", false, ["loyal"], 0), caught, "and not one caught");
  assert.equal(restMinutes("foiled", false, ["loyal", "sleepy"], 0), caught * 1.5);
});

test("a heist names its crew from the roster, and each rests by its own outcome, off work until it is back (11.6, 12.9, TD.34)", () => {
  const t = twoPlayers(true);
  const me = t.raider.account;
  const h = t.service.home;
  const crew = h.show(me).characters;
  const worker = crew.find((c) => c.kind === "tidewalker");
  h.work(me, worker.id, { realm: "heart", kind: "star_well" });
  t.clock.now += 10 * MINUTE;
  const working = h.rate(me, "heart", "star_well", t.clock.now).perHour;
  assert.ok(working > 0);
  const { lease, replay } = heist(t, crew);
  const out = t.service.submit(me, lease.token, replay, crew.map((c) => c.id));
  assert.equal(out.validated, true);
  assert.equal(out.verdict.outMask, 0b111, "the verdict says who got out");
  const heistMs = Math.round(lease.ticks / 30 * 1000);
  // The first heist also brings two strays home (§11.5): only the crew rests.
  for (const c of h.show(me).characters.filter((x) => crew.some((y) => y.id === x.id))) {
    const before = crew.find((x) => x.id === c.id);
    const minutes = restMinutes(out.verdict.grade, true, before.traits, 0);
    assert.equal(c.state, "resting");
    assert.equal(c.resting_until, t.clock.now + heistMs + Math.round(minutes * MINUTE), c.kind);
  }
  assert.equal(h.rate(me, "heart", "star_well", t.clock.now).perHour, 0, "a character resting isn't working");
  // A repeat answers as before and rests nobody twice.
  const until = h.show(me).characters[0].resting_until;
  t.clock.now += MINUTE;
  assert.equal(t.service.submit(me, lease.token, replay, crew.map((c) => c.id)).repeated, true);
  assert.equal(h.show(me).characters[0].resting_until, until);
  // The crew still resting cannot go again.
  const next = heist(t, crew);
  const refused = t.service.submit(me, next.lease.token, next.replay, crew.map((c) => c.id));
  assert.deepEqual([refused.validated, refused.reason], [false, "crew_resting"]);
  // Back once the rest ends: the Star Well counts the worker again.
  t.clock.now = until;
  assert.equal(h.show(me).characters.find((c) => c.id === worker.id).state, "working");
  assert.ok(Math.abs(h.rate(me, "heart", "star_well", t.clock.now).perHour - working) < 1e-9);
});

test("a crew the roster does not hold, or that is not the replay's, does not record (TD.34)", () => {
  const t = twoPlayers(true);
  const me = t.raider.account;
  const crew = t.service.home.show(me).characters;
  const ids = crew.map((c) => c.id);
  const reason = (named, order = crew) => {
    const { lease, replay } = heist(t, order);
    return t.service.submit(me, lease.token, replay, named).reason;
  };
  assert.equal(reason([...ids.slice(0, 2), 999_999]), "crew_not_held");
  assert.equal(reason(ids.slice(0, 2)), "crew_mismatch", "fewer than the replay's crew");
  assert.equal(reason([ids[0], ids[0], ids[1]]), "crew_mismatch", "one twice");
  assert.equal(reason([ids[1], ids[0], ids[2]]), "crew_mismatch", "not the manifest's kinds in its order");
  const other = t.service.home.show(t.defender.account).characters.map((c) => c.id);
  assert.equal(reason(other), "crew_not_held", "another player's characters");
});

test("a resting character is woken early for 2 Essence a level a minute left, and over HTTP (11.6)", async () => {
  const t = twoPlayers(true);
  const me = t.raider.account;
  const h = t.service.home;
  const crew = h.show(me).characters;
  const { lease, replay } = heist(t, crew);
  t.service.submit(me, lease.token, replay, crew.map((c) => c.id));
  const c = h.show(me).characters[0];
  const left = Math.ceil((c.resting_until - t.clock.now) / MINUTE);
  const price = facts.WAKE_ESSENCE * c.level * left;
  assert.equal(c.wake_cost, price, "the home says the wake's price, so the device never works it out");
  t.service.book(me, "essence", price, "a test's grant");
  const essence = t.service.balance(me).essence;
  const r = await t.handle(new Request(`https://edge.example/v1/home/characters/${c.id}/wake`, {
    method: "POST", headers: { authorization: `Bearer ${t.raider.token}` } }));
  assert.equal(r.status, 200);
  assert.equal((await r.json()).home.characters[0].state, "idle");
  assert.equal(essence - t.service.balance(me).essence, price);
  assert.equal(h.wake(me, c.id).repeated, true, "one awake is answered as awake");
});
