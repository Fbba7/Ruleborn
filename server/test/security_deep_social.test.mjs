// The deep security run's fixes in the universe and the social areas
// (SEC-35 onwards): a free change keeps what is owed, and what is shown of
// a player or a crew is no more than the caller may see.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { clockTicks } from "../src/service.mjs";
import { Social } from "../src/social.mjs";
import { Workshop } from "../src/workshop.mjs";
import { openPlan, play, server, twoPlayers } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const HOUR = 60 * 60 * 1000;

/** A Keeper with two outer realms and a Rift between them, paid from `aether`. */
function rift(aether) {
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:sec35").account;
  t.service.db.prepare("UPDATE accounts SET keeper_level = 40 WHERE id = ?").run(me);
  t.service.book(me, "starlight", 1_000_000, "a test's grant");
  for (const type of facts.REALM_TYPES.slice(0, 2)) t.service.universe.open(me, type);
  t.service.book(me, "aether", aether, "a test's grant");
  t.service.links.build(me, { a: "outer-1", b: "outer-2", kind: "rift" });
  const row = () => t.service.db.prepare("SELECT * FROM links WHERE owner = ? AND kind = 'rift'").get(me);
  return { t, me, l: t.service.links, row };
}

test("SEC-35: a Rift its owner cannot pay for stays closed when it is rebuilt reversed", () => {
  const perHour = facts.LINK_KINDS.rift.aether_an_hour;
  const { t, me, l, row } = rift(perHour + 5);
  t.clock.now += 2 * HOUR + 10;
  t.service.universe.show(me);
  assert.equal(row().open, 0, "one hour paid, the second not");
  const turned = l.rebuild(me, row().n, { kind: "rift", from: "outer-2" }).universe;
  const shown = turned.links.find((x) => x.kind === "rift");
  assert.equal(shown.a, "outer-2", "the direction changed");
  assert.equal(shown.open, false, "and nothing else: it still stands closed");
  assert.equal(t.service.aether(me), 5);
});

test("SEC-35: a Rift rebuilt reversed owes its upkeep from where it was paid to, not from the rebuild", () => {
  const perHour = facts.LINK_KINDS.rift.aether_an_hour;
  const { t, me, l, row } = rift(10 * perHour);
  const paidTo = row().paid_to;
  t.clock.now += 50 * 60 * 1000;
  l.rebuild(me, row().n, { kind: "rift", from: "outer-2" });
  assert.equal(row().paid_to, paidTo, "the 50 minutes since it was paid are still owed");
  t.clock.now += 20 * 60 * 1000;
  t.service.universe.show(me);
  assert.equal(t.service.aether(me), 9 * perHour, "the hour is paid at the hour, as if it had not been touched");
  assert.equal(row().open, 1);
});

/** A Workshop with one island published by `creator`, and a moderator. */
function workshop() {
  const t = server();
  const w = new Workshop(t.service);
  const island = t.build.exampleIsland(true);
  const cleared = t.build.record(island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  const creator = t.service.session("gc:creator").account;
  const item = w.publish(creator, island, cleared, { adjective: 1, noun: 9 });
  const person = t.service.session("gc:moderator").account;
  t.service.db.prepare("UPDATE accounts SET moderator = 1 WHERE id = ?").run(person);
  const remove = (id) => w.resolve(person, w.report(person, id, "unfair").report, "remove", "unfair");
  return { t, w, island, cleared, creator, item, remove };
}

/** A play's clear, as the device would record it, not yet submitted. */
function cleared(t, p) {
  return t.build.record(t.service.bundle(p.bundle), { seed: BigInt(p.seed), ticks: p.ticks, crew: 3,
                                                       commands: openPlan() });
}

test("SEC-40: a play submitted once its island is taken down is answered, but earns its creator nothing", () => {
  const { t, w, creator, item, remove } = workshop();
  const player = t.service.session("gc:player").account;
  const p = w.play(player, item.id);
  remove(item.id);
  const outcome = w.submitPlay(player, p.token, cleared(t, p));
  assert.equal(outcome.validated, true, "the player still sees their result");
  assert.equal(outcome.cleared, true);
  assert.equal(outcome.counted, false);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM workshop_completions").get().n, 0);
  assert.equal(w.ladder(creator).completions, 0);
  assert.deepEqual(t.service.fund.played(0, t.clock.now + 1), {}, "and no Fund time");
});

test("SEC-40: a play submitted once its island is withdrawn earns nothing; completions earned while listed stay", () => {
  const { t, w, creator, item, remove } = workshop();
  const early = t.service.session("gc:early").account;
  const p0 = w.play(early, item.id);
  assert.equal(w.submitPlay(early, p0.token, cleared(t, p0)).counted, true);
  const late = t.service.session("gc:late").account;
  const p1 = w.play(late, item.id);
  w.withdraw(creator, item.id);
  assert.equal(w.submitPlay(late, p1.token, cleared(t, p1)).counted, false);
  assert.equal(w.ladder(creator).completions, 1, "the creator keeps what was earned while it was listed");
  assert.deepEqual(Object.keys(t.service.fund.played(0, t.clock.now + 1)), [creator]);
  // A removed island drops off the ladder altogether.
  const other = workshop();
  const player = other.t.service.session("gc:player").account;
  const p2 = other.w.play(player, other.item.id);
  assert.equal(other.w.submitPlay(player, p2.token, cleared(other.t, p2)).counted, true);
  assert.equal(other.w.ladder(other.creator).completions, 1);
  other.remove(other.item.id);
  assert.equal(other.w.ladder(other.creator).completions, 0);
});

test("SEC-42: a crew's invite is shown to its members only", async () => {
  const t = server();
  const a = t.service.session("gc:sec42a");
  const b = t.service.session("gc:sec42b");
  const get = async (who, path) => (await t.handle(new Request(`https://edge.example${path}`,
    { headers: { authorization: `Bearer ${who.token}` } }))).json();
  const started = new Social(t.service).startCrew(a.account);
  assert.ok(started.invite, "the founder is given the invite");
  const own = (await get(a, "/v1/crews/mine")).crew;
  assert.equal(own.invite, started.invite, "a member still sees it");
  const seen = await get(b, `/v1/crews/${started.id}`);
  assert.equal(seen.id, started.id);
  assert.equal("invite" in seen, false, "one outside the crew does not");
});

test("SEC-48: the friends' feed answers for more friends than SQLite has bound variables", () => {
  const t = twoPlayers(true);
  const watcher = t.service.session("gc:sec48").account;
  t.service.friends.accept(t.raider.account, t.service.friends.invite(watcher).invite);
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  // 16,400 more friends, written straight to the tables in one transaction.
  const db = t.service.db;
  const account = db.prepare("INSERT INTO accounts (id, platform_identity, created_at) VALUES (?, ?, ?)");
  const friend = db.prepare("INSERT INTO friends (a, b, since) VALUES (?, ?, ?)");
  db.exec("BEGIN");
  for (let i = 0; i < 16_400; i++) {
    const id = `sec48-${String(i).padStart(5, "0")}`;
    account.run(id, `gc:${id}`, t.clock.now);
    friend.run(...[watcher, id].sort(), t.clock.now);
  }
  db.exec("COMMIT");
  assert.equal(t.service.friends.list(watcher).length, 16_401);
  assert.deepEqual(t.service.friends.feed(watcher).map((e) => [e.raider, e.defender]),
                   [[t.raider.account, t.defender.account]], "the same answer as with one friend");
});
