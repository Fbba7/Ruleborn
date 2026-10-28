// The rows a heist and a session write, each cut held by a test (§24.1's
// writes; docs/server/db-cost.md): a raider's row written once a heist, a
// heist's stars on the ledger row it books, and no write that says nothing.

import assert from "node:assert/strict";
import { test } from "node:test";

import { billed } from "../load.mjs";
import { established, openPlan, play, twoPlayers } from "./setup.mjs";

const DAY = 24 * 60 * 60 * 1000;

/** Every write `fn` makes that changes a row, as "VERB table". */
function writes(db, fn) {
  const prepare = db.prepare;
  const seen = [];
  db.prepare = (sql) => {
    const st = prepare.call(db, sql);
    const run = st.run.bind(st);
    st.run = (...a) => {
      const r = run(...a);
      const m = /^\s*(INSERT(?: OR \w+)? INTO|UPDATE|DELETE FROM) (\w+)/i.exec(sql);
      if (m && r.changes) seen.push(`${m[1].split(" ")[0]} ${m[2]}`);
      return r;
    };
    return st;
  };
  try {
    fn();
  } finally {
    db.prepare = prepare;
  }
  return seen;
}

test("a heist writes its raider's row once: the experience, the raids played and the rating together", () => {
  const t = twoPlayers();
  t.service.book(t.raider.account, "starlight", 20_000, "grant");
  const lease = t.service.lease(t.raider.account, t.bundle);
  const replay = play(t, lease, { plan: openPlan() });
  const order = writes(t.service.db, () => t.service.submit(t.raider.account, lease.token, replay));
  assert.equal(order.filter((w) => w === "UPDATE accounts").length, 1, order.join(", "));
  const ratings = order.filter((w) => w.endsWith(" ratings"));
  assert.equal(ratings.length, 1, `the island's rating alone: ${order.join(", ")}`);
  const row = t.service.db.prepare(
    "SELECT keeper_xp, raids, raider_rating, raider_games FROM accounts WHERE id = ?").get(t.raider.account);
  assert.equal(row.raids, 1);
  assert.equal(row.raider_games, 1);
  assert.ok(row.keeper_xp > 0);
  assert.equal(t.service.matchmaking.raiderRating(t.raider.account).rating, row.raider_rating);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM ratings WHERE kind = 'raider'").get().n, 0);
});

test("a raid past the week's twenty, which earns no experience, still writes the raider's row once", () => {
  const t = twoPlayers();
  for (let i = 0; i < 21; i++) {
    const lease = t.service.lease(t.raider.account, t.bundle);
    const replay = play(t, lease, { plan: openPlan() });
    const order = writes(t.service.db, () => t.service.submit(t.raider.account, lease.token, replay));
    assert.equal(order.filter((w) => w === "UPDATE accounts").length, 1, `raid ${i + 1}: ${order.join(", ")}`);
    t.clock.now += 5 * 60 * 1000;
  }
  const out = t.service.db.prepare("SELECT raids, raider_games FROM accounts WHERE id = ?").get(t.raider.account);
  assert.deepEqual({ ...out }, { raids: 21, raider_games: 21 });
});

test("a heist's stars ride the ledger row it books, and a stars row is written only where it books none (18.2)", () => {
  const t = twoPlayers();
  t.service.book(t.raider.account, "starlight", 20_000, "grant");
  const lease = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.ok(out.stars.raider > 0);
  const db = t.service.db;
  const row = db.prepare("SELECT stars, stars_total, season FROM ledger WHERE heist = ? AND account = ?")
    .get(lease.token, t.raider.account);
  assert.equal(row.stars, out.stars.raider);
  assert.equal(db.prepare("SELECT COUNT(*) AS n FROM season_stars WHERE heist = ?").get(lease.token).n, 0);
  assert.equal(t.service.track.stars(t.raider.account), out.stars.raider);
  // A defence that pays its defender nothing books their stars where stars go alone.
  t.clock.now += DAY;
  const foil = t.service.lease(t.raider.account, t.bundle);
  const greedy = openPlan().filter((c) => c.kind !== "Skiff" && c.tick < 62 * 30);
  const foiled = t.service.submit(t.raider.account, foil.token, play(t, foil, { plan: greedy }));
  assert.equal(foiled.verdict.grade, "foiled");
  const defenderRow = db.prepare("SELECT stars FROM ledger WHERE heist = ? AND account = ?").get(foil.token, t.defender.account);
  const defenderStars = db.prepare("SELECT COALESCE(SUM(amount), 0) AS n FROM season_stars WHERE heist = ? AND account = ?")
    .get(foil.token, t.defender.account).n;
  assert.equal((defenderRow?.stars ?? 0) + defenderStars, foiled.stars.defender);
  assert.equal(t.service.track.stars(t.defender.account), foiled.stars.defender);
});

test("reading the defence log with no raid new since it was read writes nothing", () => {
  const t = twoPlayers();
  established(t, t.raider.account);
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  const db = t.service.db;
  assert.deepEqual(writes(db, () => t.service.defences.show(t.defender.account)), ["UPDATE accounts"], "the raid read");
  t.clock.now += 1000;
  assert.deepEqual(writes(db, () => t.service.defences.show(t.defender.account)), [], "nothing new, nothing written");
  assert.deepEqual(t.service.defences.badge(t.defender.account), { unseen: 0 });
});

test("a lease and a scoring heist bill each index entry they need and none they do not (24.1)", () => {
  const t = twoPlayers();
  t.service.book(t.raider.account, "starlight", 20_000, "grant");
  const first = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, first.token, play(t, first, { plan: openPlan() }));
  t.clock.now += 2 * DAY;
  const bill = billed(t.service.db);
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  const by = Object.fromEntries(bill.byTable);
  // The lease: its row and its target's entry. The heist: its row, its
  // attacker's and its defender's entries, written once.
  assert.equal(by.leases, 2);
  assert.equal(by.heists, 3);
  // The raider's ledger row and its index entry, carrying the stars.
  assert.equal(by.ledger, 2);
  assert.equal(by.season_stars ?? 0, 0);
  assert.equal(by.accounts, 1, "the raider's row, once");
  assert.equal(by.ratings, 1, "the island's rating");
});
