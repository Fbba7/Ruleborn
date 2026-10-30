// Renown, leagues and seasons (§12.9, §18.1), constellations and crews (§17),
// against the real simulation build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { Refused, clockTicks } from "../src/service.mjs";
import { BOUNDS, SEASON_MS, place } from "../src/seasons.mjs";
import { Social } from "../src/social.mjs";
import { Workshop } from "../src/workshop.mjs";
import { T0, openPlan, play, server, twoPlayers } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);
const EMBER = BOUNDS.leagues.Ember;

/** A raid on the defender's island: the planned clear, or nothing at all
 *  (the crew never moves, is caught, and banks nothing: foiled). */
function raid(t, clean = true) {
  const lease = t.service.lease(t.raider.account, t.bundle);
  return t.service.submit(t.raider.account, lease.token,
                          play(t, lease, { plan: clean ? openPlan() : [] }));
}

/** Where a player's season starts, set directly: a test's shortcut to a
 *  Renown the heists would take days to reach. */
function startAt(t, account, renown, ember = renown >= EMBER) {
  const season = t.service.seasons.current().id;
  t.service.seasons.standing(account, season);
  t.service.db.prepare("UPDATE standings SET start = ?, ember = ? WHERE season = ? AND account = ?")
    .run(renown, ember ? 1 : 0, season, account);
}

const renown = (t, account) => t.service.seasons.league(account).renown;

test("a clean heist moves §12.9's Renown to the raider, and Dust's floor mints what it stops", () => {
  const t = twoPlayers(true);
  const out = raid(t);
  assert.equal(out.verdict.grade, "clean");
  // Equal Renown: 20 × (1 + 0 ÷ 1,000) × 1.0.
  assert.deepEqual(out.renown, { raider: 20, defender: 0 }, "the defender, at Dust's floor, loses nothing");
  assert.equal(renown(t, t.raider.account), 20);
  assert.equal(renown(t, t.defender.account), 0);
});

test("above its floor, the defender loses the mirror amount (12.9)", () => {
  const t = twoPlayers(true);
  startAt(t, t.defender.account, 100, false);
  // 20 × (1 + (100 − 0) ÷ 1,000) = 22.
  assert.deepEqual(raid(t).renown, { raider: 22, defender: -22 });
  assert.equal(renown(t, t.defender.account), 78);
});

test("a foiled heist costs the raider a flat 8, and the defender gains what the raider lost (12.9)", () => {
  const t = twoPlayers(true);
  startAt(t, t.raider.account, 50, false);
  const out = raid(t, false);
  assert.equal(out.verdict.grade, "foiled");
  assert.deepEqual(out.renown, { raider: -8, defender: 8 });
  // At Dust's floor a foiled raider loses nothing, and so the defender gains nothing.
  const u = twoPlayers(true);
  assert.deepEqual(raid(u, false).renown, { raider: 0, defender: 0 });
});

test("Ember, once reached, is a floor: nobody drops out of Dust or Ember (18.1)", () => {
  const t = twoPlayers(true);
  startAt(t, t.raider.account, EMBER - 5, false);
  raid(t);                                           // over the line: +20
  assert.equal(t.service.seasons.league(t.raider.account).league, "Ember");
  for (let i = 0; i < 6; i++) {
    t.clock.now += 25 * 60 * 60 * 1000;              // a fresh lease each day
    raid(t, false);
  }
  assert.equal(renown(t, t.raider.account), EMBER, "six foiled heists, and no lower than Ember's floor");
});

test("a Renown's league and division: three divisions a league, none in Paradox (18.1)", () => {
  assert.deepEqual(place(0), { league: "Dust", division: 1, floor: 0 });
  assert.deepEqual(place(EMBER), { league: "Ember", division: 1, floor: EMBER });
  const star = BOUNDS.divisions.Star;
  assert.equal(place(star[2]).division, 3);
  assert.deepEqual(place(BOUNDS.leagues.Paradox + 500),
                   { league: "Paradox", division: null, floor: BOUNDS.leagues.Paradox });
  // Every league above Dust starts higher than the one below it.
  const starts = Object.values(BOUNDS.leagues);
  assert.deepEqual([...starts].sort((a, b) => a - b), starts);
});

test("a season closes once: results and rewards by league, and the next opens pulled halfway back (18.1)", () => {
  const t = twoPlayers(true);
  const star = BOUNDS.leagues.Star;
  startAt(t, t.raider.account, star + 100);
  startAt(t, t.defender.account, 0);
  refusal(() => t.service.seasons.result(t.raider.account, 1), "season_still_open");
  t.clock.now = T0 + SEASON_MS + 1;
  assert.deepEqual(t.service.seasons.rollover(), [1]);
  assert.deepEqual(t.service.seasons.rollover(), [], "a closed season is never closed again");
  const result = t.service.seasons.result(t.raider.account, 1);
  assert.equal(result.league, "Star");
  assert.equal(result.reward, "season-1-star");
  const owned = JSON.parse(t.service.db.prepare("SELECT cosmetics FROM accounts WHERE id = ?")
    .get(t.raider.account).cosmetics);
  assert.deepEqual(owned, ["season-1-star"]);
  assert.equal(t.service.seasons.result(t.defender.account, 1).reward, null, "Dust earns no cosmetic");
  const now = t.service.seasons.league(t.raider.account);
  assert.equal(now.season, 2);
  assert.equal(now.renown, star + 50, "halfway back toward Star's floor");
  assert.equal(renown(t, t.defender.account), 0);
});

/** A server with players at Keeper level 6, the Beacon's gate. */
function beacon(n) {
  const t = server();
  const social = new Social(t.service);
  const players = [];
  for (let i = 0; i < n; i++) {
    const { account } = t.service.session(`gc:keeper${i}`);
    t.service.db.prepare("UPDATE accounts SET keeper_level = 6 WHERE id = ?").run(account);
    players.push(account);
  }
  return { ...t, social, players };
}

test("a constellation: the Beacon from Keeper level 6, thirty Keepers, a founder and four elders (17.1)", () => {
  const t = beacon(32);
  const [founder, ...rest] = t.players;
  const low = t.service.session("gc:new").account;
  refusal(() => t.social.found(low, { adjective: 0, noun: 0 }), "keeper_level_too_low");
  for (const name of [{ adjective: -1, noun: 0 }, { adjective: 0, noun: 99999 }]) {
    refusal(() => t.social.found(founder, name), "name_not_from_the_word_lists");
  }
  const c = t.social.found(founder, { adjective: 7, noun: 2 });
  assert.equal(c.name.en, "Crooked Harbour");
  refusal(() => t.social.found(founder, { adjective: 0, noun: 0 }), "already_in_a_constellation");
  for (const p of rest.slice(0, 29)) t.social.join(p, c.id);
  refusal(() => t.social.join(rest[29], c.id), "constellation_full");
  for (const p of rest.slice(0, 4)) t.social.appoint(founder, p, "elder");
  refusal(() => t.social.appoint(founder, rest[4], "elder"), "elders_full");
  refusal(() => t.social.appoint(rest[0], rest[5], "elder"), "founder_only");
  // The founder leaves; the longest-standing elder keeps it.
  t.social.leave(founder);
  const after = t.social.constellation(c.id).members;
  assert.equal(after.find((m) => m.role === "founder").account, rest[0]);
  assert.equal(after.length, 29);
  t.social.join(rest[29], c.id);
});

test("the constellation league ranks by members' combined Renown at the season's close (17.5)", () => {
  const t = beacon(4);
  const [a, b, c, d] = t.players;
  const one = t.social.found(a, { adjective: 0, noun: 0 });
  t.social.join(b, one.id);
  const two = t.social.found(c, { adjective: 1, noun: 1 });
  t.social.join(d, two.id);
  startAt(t, a, 100);
  startAt(t, b, 50);
  startAt(t, c, 400);
  t.clock.now = T0 + SEASON_MS + 1;
  t.service.seasons.rollover();
  assert.deepEqual(t.service.seasons.constellationTable(1).map((r) => [r.constellation, r.renown, r.place]),
                   [[two.id, 400, 1], [one.id, 150, 2]]);
});

test("a constellation its last member leaves is closed: nobody takes it over without a founder (17.1)", () => {
  const t = beacon(2);
  const [founder, other] = t.players;
  const c = t.social.found(founder, { adjective: 0, noun: 0 });
  t.social.leave(founder);
  refusal(() => t.social.join(other, c.id), "constellation_closed");
  refusal(() => t.social.join(founder, c.id), "constellation_closed");
  assert.deepEqual(t.social.constellation(c.id).members, []);
});

test("the constellation league counts members at the season's end, not at the rollover's run (17.5)", () => {
  const t = beacon(3);
  const [a, b, c] = t.players;
  const one = t.social.found(a, { adjective: 0, noun: 0 });
  t.social.join(b, one.id);
  const two = t.social.found(c, { adjective: 1, noun: 1 });
  startAt(t, a, 100);
  startAt(t, b, 500);
  startAt(t, c, 200);
  // The season is over, its Renown final, and the rollover not yet run.
  t.clock.now = T0 + SEASON_MS + 1;
  t.social.leave(b);
  t.social.join(b, two.id);
  t.service.seasons.rollover();
  assert.deepEqual(t.service.seasons.constellationTable(1).map((r) => [r.constellation, r.renown, r.place]),
                   [[one.id, 600, 1], [two.id, 200, 2]]);
});

test("a ban takes the player out of their constellation, handing it on, and out of their crew (20.12)", () => {
  const t = beacon(3);
  const [founder, elder, member] = t.players;
  const c = t.social.found(founder, { adjective: 0, noun: 0 });
  t.social.join(elder, c.id);
  t.social.join(member, c.id);
  t.social.appoint(founder, elder, "elder");
  const crew = t.social.startCrew(founder);
  t.social.joinCrew(member, crew.invite);
  new Workshop(t.service).ban(founder, "offensive");
  assert.deepEqual(t.social.constellation(c.id).members.map((m) => [m.account, m.role]),
                   [[elder, "founder"], [member, "member"]]);
  t.social.appoint(elder, member, "elder");
  assert.deepEqual(t.social.crew(crew.id).members.map((m) => m.account), [member]);
});

test("a crew is four to eight, joined by its invite, and survives its founder leaving (17.7)", () => {
  const t = beacon(10);
  const [first, ...rest] = t.players;
  const crew = t.social.startCrew(first);
  assert.equal(crew.formed, false, "one Keeper is not yet a crew");
  // SR-14: a crew is joined as a friend of one of its members.
  const befriend = (x, y) => t.service.db.prepare("INSERT INTO friends (a, b, since, invited_by) VALUES (?, ?, 0, ?)")
    .run(...[x, y].sort(), x);
  for (const p of rest) befriend(p, first);
  befriend(rest[7], rest[0]);                              // who is still there when the founder has left
  for (const p of rest.slice(0, 3)) t.social.joinCrew(p, crew.invite);
  assert.equal(t.social.crew(crew.id).formed, true, "four is");
  for (const p of rest.slice(3, 7)) t.social.joinCrew(p, crew.invite);
  refusal(() => t.social.joinCrew(rest[7], crew.invite), "crew_full");
  refusal(() => t.social.startCrew(rest[0]), "already_in_a_crew");
  t.social.leaveCrew(first);
  assert.equal(t.social.crew(crew.id).members.length, 7, "carries on without its founder");
  t.social.joinCrew(rest[7], crew.invite);
});

test("a Workshop completion from the creator's own constellation counts at a quarter (18.7)", () => {
  const t = beacon(3);
  const [creator, kin, stranger] = t.players;
  const c = t.social.found(creator, { adjective: 0, noun: 0 });
  t.social.join(kin, c.id);
  const w = new Workshop(t.service);
  const island = t.build.exampleIsland(true);
  const cleared = t.build.record(island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  const { id } = w.publish(creator, island, cleared, { adjective: 0, noun: 0 });
  for (const p of [kin, stranger]) {
    const run = w.play(p, id);
    w.submitPlay(p, run.token, t.build.record(t.service.bundle(run.bundle),
      { seed: BigInt(run.seed), ticks: run.ticks, crew: 3, commands: openPlan() }));
  }
  assert.equal(w.view(w.row(id)).completions, 1.25, "the stranger's whole, the kin's a quarter");
});

test("leaving the constellation to complete an island, and coming back, still counts a quarter (18.7)", () => {
  const t = beacon(4);
  const [creator, kin, other, stranger] = t.players;
  const c = t.social.found(creator, { adjective: 0, noun: 0 });
  t.social.join(kin, c.id);
  t.social.join(other, c.id);
  const w = new Workshop(t.service);
  const island = t.build.exampleIsland(true);
  const cleared = t.build.record(island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  const { id } = w.publish(creator, island, cleared, { adjective: 0, noun: 0 });
  const complete = (p) => {
    const run = w.play(p, id);
    return w.submitPlay(p, run.token, t.build.record(t.service.bundle(run.bundle),
      { seed: BigInt(run.seed), ticks: run.ticks, crew: 3, commands: openPlan() }));
  };
  t.clock.now += 60_000;
  t.social.leave(kin);                                 // the kin steps out …
  t.clock.now += 60_000;
  assert.equal(complete(kin).counted, true);
  t.social.join(kin, c.id);                            // … and back
  // The creator steps out instead, and a mate completes it meanwhile.
  t.clock.now += 60_000;
  t.social.leave(creator);
  t.clock.now += 60_000;
  complete(other);
  // A Keeper who joins only after the creator has gone never shared it.
  t.social.join(stranger, c.id);
  complete(stranger);
  assert.equal(w.view(w.row(id)).completions, 1.5, "two quarters and the stranger's whole");
});

test("leagues, constellations and crews over HTTP", async () => {
  const t = beacon(2);
  const call = (method, path, { token, json } = {}) => t.handle(new Request(`https://edge.example${path}`, {
    method,
    headers: { ...(token ? { authorization: `Bearer ${token}` } : {}),
               ...(json ? { "content-type": "application/json" } : {}) },
    body: json ? JSON.stringify(json) : undefined,
  }));
  const [a, b] = await Promise.all(["gc:keeper0", "gc:keeper1"].map(async (credential) =>
    (await call("POST", "/v1/session", { json: { credential } })).json()));
  const league = await (await call("GET", "/v1/league", { token: a.token })).json();
  assert.deepEqual([league.season, league.renown, league.league], [1, 0, "Dust"]);
  const made = await call("POST", "/v1/constellations", { token: a.token, json: { adjective: 3, noun: 4 } });
  assert.equal(made.status, 201);
  const c = await made.json();
  const joined = await (await call("POST", `/v1/constellations/${c.id}/join`, { token: b.token })).json();
  assert.equal(joined.members.length, 2);
  const crew = await (await call("POST", "/v1/crews", { token: a.token })).json();
  const inCrew = await (await call("POST", "/v1/crews/join", { token: b.token, json: { invite: crew.invite } })).json();
  assert.equal(inCrew.members.length, 2);
  assert.equal((await call("GET", "/v1/seasons/1/result", { token: a.token })).status, 409);
  // A device that knows nothing finds the player's own constellation and crew.
  const mine = await (await call("GET", "/v1/constellations/mine", { token: b.token })).json();
  assert.deepEqual([mine.constellation.id, mine.constellation.members.length], [c.id, 2]);
  assert.equal((await (await call("GET", "/v1/crews/mine", { token: b.token })).json()).crew.id, crew.id);
  await call("POST", "/v1/crews/leave", { token: b.token });
  await call("POST", "/v1/constellations/leave", { token: b.token });
  assert.deepEqual(await (await call("GET", "/v1/crews/mine", { token: b.token })).json(), { crew: null });
  assert.deepEqual(await (await call("GET", "/v1/constellations/mine", { token: b.token })).json(),
                   { constellation: null });
});
