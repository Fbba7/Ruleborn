// The deep security run's fixes in the universe and the social areas
// (SEC-35 onwards): a free change keeps what is owed, and what is shown of
// a player or a crew is no more than the caller may see.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { server } from "./setup.mjs";

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
