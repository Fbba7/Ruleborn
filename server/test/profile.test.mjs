// §23.2's Profile and stats (profile.mjs, TD.24).

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { grade, RECORDS } from "../src/profile.mjs";
import { twoPlayers } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const HOUR = 60 * 60 * 1000;

/** A raid on the defender settled with `verdict`, lasting `heistMs`, with
 *  the event log's `report` if one is given. */
function raid(t, verdict, heistMs, report = null, crossing = null) {
  t.clock.now += HOUR;
  const lease = t.service.lease(t.raider.account, t.bundle);
  const row = t.service.db.prepare("SELECT * FROM leases WHERE token = ?").get(lease.token);
  return t.service.settle(row, new Uint8Array(8), `pr-${t.clock.now}`, t.clock.now,
                          { validated: true, verdict, heistMs, report, crossing });
}

/** An event-log report (sim.mjs `report`) landing on (x, y). */
const report = (x, y, alarm, slept) => ({ landing: { x, y }, held: 60, alarm, bells: 0, slept, alerted: 0,
                                         seen: [], fired: [], caughtBy: [] });

const verdict = (g, banked, caught = 0) =>
  ({ grade: g, out: 3 - caught, caught, crew: 3, banked, capacity: 800, pages: 0, cracked: 0, left: 0 });

test("§18.5's badges are graded gold at the mark, silver at half and bronze at a tenth, rounded up, and a mark of 1 has one grade (18.5)", () => {
  assert.deepEqual(facts.BADGE_MARKS, { first_heist: 1, ghost: 50, vault_breaker: 250, iron_wall: 100,
                                        law_hunter: 24, resonant: 12, hoarder: 5000, friendly: 25, paradox: 1 });
  assert.deepEqual([0, 4, 5, 24, 25, 49, 50, 80].map((n) => grade(n, 50)),
                   [null, null, "bronze", "bronze", "silver", "silver", "gold", "gold"]);
  assert.deepEqual([2, 3, 12, 24].map((n) => grade(n, 24)), [null, "bronze", "silver", "gold"], "a tenth of 24 rounds up to 3");
  assert.deepEqual([0, 1].map((n) => grade(n, 1)), [null, "gold"]);
});

test("the profile counts heists by each outcome's name and defences held and leaked, Partial apart, and never the rating (12.9, 12.15, G69)", () => {
  const t = twoPlayers();
  raid(t, verdict("clean", 800), 70_000);
  raid(t, verdict("partial", 300, 1), 90_000);
  raid(t, verdict("foiled", 0, 3), 120_000);
  const p = t.service.profile.view(t.raider.account);
  assert.deepEqual(p.heists, { clean: 1, loud: 0, partial: 1, foiled: 1 });
  const d = t.service.profile.view(t.defender.account);
  assert.deepEqual(d.defences, { held: 1, leaked: 2, partial: 1 });
  assert.ok(!JSON.stringify(p).includes("rating") && !JSON.stringify(p).includes("deviation"));
  assert.equal(p.renown.renown, t.service.seasons.league(t.raider.account).renown, "this season's Renown and league");
  assert.deepEqual(p.log.map((h) => h.grade), ["foiled", "partial", "clean"], "the battle log, newest first");
  assert.ok(p.log.every((h) => h.replay === "kept"));
});

test("the profile's records come from the heist rows: the fastest escape, the fewest caught, the biggest haul and the longest defence held, the rest not recorded yet (13.2, 23.2)", () => {
  const t = twoPlayers();
  const a = raid(t, verdict("clean", 800), 70_000);
  const b = raid(t, verdict("loud", 500, 1), 50_000);
  raid(t, verdict("foiled", 0, 3), 140_000);
  raid(t, verdict("foiled", 0, 3), 100_000);
  const rec = (p) => Object.fromEntries(p.records.map((r) => [r.id, r.value]));
  const p = rec(t.service.profile.view(t.raider.account));
  assert.deepEqual(Object.keys(p), RECORDS);
  assert.equal(p.fastest_escape, 50_000, "the quickest heist that got out");
  assert.equal(p.fewest_caught, 0);
  assert.equal(p.biggest_haul, Math.max(a.haul.total, b.haul.total));
  assert.equal(rec(t.service.profile.view(t.defender.account)).longest_defence, 140_000);
  assert.equal(p.most_realms, 1, "the Heart alone");
  for (const id of ["fewest_alarms", "most_guards_slept_past", "favourite_edge", "favourite_law",
                    "minutes_a_day"]) assert.equal(p[id], null, id);
});

test("the profile's records from each heist's event-log report: the fewest alarms and the most guards slept past in a heist that got out, and the edge raiders most often land on (13.2, 23.2, TD.39)", () => {
  const t = twoPlayers();
  // The example island is realm level 3: 12 tiles a side.
  raid(t, verdict("clean", 800), 70_000, report(0, 5, 2, 1));
  raid(t, verdict("loud", 500, 1), 50_000, report(11, 4, 1, 0));
  raid(t, verdict("partial", 200, 2), 50_000, report(0, 8, 4, 2));
  raid(t, verdict("foiled", 0, 3), 140_000, report(5, 11, 0, 3));
  const rec = (p) => Object.fromEntries(p.records.map((r) => [r.id, r.value]));
  const p = rec(t.service.profile.view(t.raider.account));
  assert.equal(p.fewest_alarms, 1, "the lowest the realm alarm stayed in a heist that got out");
  assert.equal(p.most_guards_slept_past, 2, "a foiled heist slept past nobody it counts");
  assert.equal(rec(t.service.profile.view(t.defender.account)).favourite_edge, "west",
               "two raids landed on the west edge, one each on the east and south");
  for (const id of ["favourite_law", "minutes_a_day"]) assert.equal(p[id], null, id);
});

test("the profile's most realms in one raid counts the realms a raid across a universe went through, and its landing edge is not the Heart's (23.2, 5.4, T3.3)", () => {
  const t = twoPlayers();
  raid(t, verdict("clean", 800), 70_000, report(0, 5, 2, 1));
  const across = (realms) => ({ landed: realms[0], realms });
  raid(t, verdict("loud", 500), 90_000, report(11, 4, 1, 0), across(["outer-2", "outer-1", "heart"]));
  raid(t, verdict("foiled", 0, 3), 140_000, report(11, 6, 0, 0), across(["outer-1", "heart"]));
  const rec = (p) => Object.fromEntries(p.records.map((r) => [r.id, r.value]));
  assert.equal(rec(t.service.profile.view(t.raider.account)).most_realms, 3);
  assert.equal(rec(t.service.profile.view(t.defender.account)).favourite_edge, "west",
               "the two that crossed came in at the Heart's entrance, not over an edge");
});

test("the profile's collection counts the album's forms the roster has brought home and the cosmetics owned (23.2, 11.10)", () => {
  const t = twoPlayers();
  const before = t.service.profile.view(t.raider.account).collection;
  const forms = new Set(t.service.home.characters(t.raider.account).filter((c) => c.form)
    .map((c) => `${c.kind}/${c.form}`)).size;
  assert.deepEqual(before, { forms, of: 54, cosmetics: 0 }, "the three who woke, each in a form");
  assert.ok(forms >= 1);
  t.service.seasons.grantCosmetic(t.raider.account, "hatch-outfit");
  assert.equal(t.service.profile.view(t.raider.account).collection.cosmetics, 1);
});

test("the profile's badges count first heist, clean heists, Vaults opened, defences held, laws met, resonances found, Starlight banked and friendly heists, each graded (18.5)", () => {
  const t = twoPlayers();
  const a = raid(t, verdict("clean", 800), 70_000);
  raid(t, verdict("foiled", 0, 3), 90_000);
  const by = (p) => Object.fromEntries(p.badges.map((b) => [b.id, [b.count, b.grade]]));
  const p = by(t.service.profile.view(t.raider.account));
  assert.deepEqual(p.first_heist, [2, "gold"]);
  assert.deepEqual(p.ghost, [1, null]);
  assert.deepEqual(p.vault_breaker, [1, null]);
  assert.deepEqual(p.hoarder, [a.haul.starlight, grade(a.haul.starlight, 5000)]);
  assert.equal(p.law_hunter[0], t.service.codex.show(t.raider.account).laws.length);
  assert.deepEqual(p.paradox, [0, null], "no paradoxes until the paradox laws");
  const fresh = by(t.service.profile.view(t.service.session("gc:new").account));
  assert.deepEqual([fresh.first_heist, fresh.law_hunter], [[0, null], [3, "bronze"]],
                   "a new Keeper's three starting laws are met: a tenth of 24, rounded up");
  assert.deepEqual(by(t.service.profile.view(t.defender.account)).iron_wall, [1, null]);
});

test("a 13-to-15 profile is never served to another account, a 16-to-17 or adult one only once its switch is on, and a 13-to-15 player cannot turn it on (20.2)", () => {
  const t = twoPlayers();
  const me = t.defender.account;
  const other = t.raider.account;
  const refused = (fn, reason) => assert.throws(fn, (e) => e.reason === reason, reason);
  // A profile not shown answers as no account at all (SEC-45).
  refused(() => t.service.profile.show(other, me), "no_such_account");
  t.service.profile.share(me, true);
  const seen = t.service.profile.show(other, me);
  assert.ok(seen.heists && !("log" in seen) && !("public" in seen), "the record, not the battle log");
  for (const band of ["16-17", "13-15"]) {
    t.service.db.prepare("UPDATE accounts SET age_band = ?, profile_public = 0 WHERE id = ?").run(band, me);
    refused(() => t.service.profile.show(other, me), "no_such_account");
  }
  refused(() => t.service.profile.share(me, true), "profile_private_at_this_age");
  t.service.db.prepare("UPDATE accounts SET profile_public = 1 WHERE id = ?").run(me);
  refused(() => t.service.profile.show(other, me), "no_such_account");
  assert.equal(t.service.profile.show(me, me).can_share, false, "the player still sees their own");
  t.service.db.prepare("UPDATE accounts SET age_band = '16-17', profile_public = 0 WHERE id = ?").run(me);
  t.service.profile.share(me, true);
  assert.ok(t.service.profile.show(other, me).badges);
});

test("the profile is served over HTTP, its switch set there (20.2, 23.2)", async () => {
  const t = twoPlayers();
  const { token } = t.service.session("gc:defender");
  const other = t.service.session("gc:raider").token;
  const call = (method, path, who, json) => t.handle(new Request(`https://edge.example${path}`, {
    method, headers: { authorization: `Bearer ${who}`, ...(json ? { "content-type": "application/json" } : {}) },
    body: json ? JSON.stringify(json) : undefined }));
  const own = await (await call("GET", "/v1/profile", token)).json();
  assert.equal(own.public, false);
  const hidden = await call("GET", `/v1/profile/${t.defender.account}`, other);
  assert.deepEqual([hidden.status, (await hidden.json()).error], [404, "no_such_account"], "as no account (SEC-45)");
  assert.equal((await (await call("PUT", "/v1/profile", token, { public: true })).json()).public, true);
  assert.equal((await call("GET", `/v1/profile/${t.defender.account}`, other)).status, 200);
});
