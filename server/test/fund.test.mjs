// §18.9's Island Fund (fund.mjs).

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { capped, quarterOf } from "../src/fund.mjs";
import { TICKS_PER_SECOND } from "../src/service.mjs";
import { server } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const DAY = 24 * 60 * 60 * 1000;
const refused = (fn, reason) => assert.throws(fn, (e) => e.reason === reason, reason);

/** A quarter's world: purchases, creators with islands, and plays on them,
 *  written as the stores and the Workshop write them. */
function quarterOfPlay() {
  const t = server();
  const q = quarterOf(t.clock.now);
  const db = t.service.db;
  const who = (name, band = "18+") => {
    const a = t.service.session(`gc:${name}`).account;
    db.prepare("UPDATE accounts SET age_band = ? WHERE id = ?").run(band, a);
    return a;
  };
  let n = 0;
  const buy = (account, price, at = q.starts_at + DAY) => {
    const txn = `t${++n}`;
    db.prepare("INSERT INTO purchases (store, txn, account, product, price, at) VALUES ('apple', ?, ?, 'season-premium', ?, ?)")
      .run(txn, account, price, at);
    return txn;
  };
  const island = (creator, removed = null) => {
    const id = `i${++n}`;
    db.prepare(
      `INSERT INTO workshop_items (id, creator, bundle, realm_level, name_adjective, name_noun, cleared_by, bytes,
                                   published_at, removed_at)
       VALUES (?, ?, 'b', 3, 0, 0, 'r', 1, ?, ?)`).run(id, creator, q.starts_at, removed);
    return id;
  };
  // `counted`: the play's player counted when they played (SEC-26); the
  // Workshop writes 0 for an account too new or too low to count.
  const play = (player, item, seconds, { validated = true, held = null, at = q.starts_at + 2 * DAY,
                                         counted = true } = {}) => {
    const outcome = { validated, ...(held === null ? {} : { report: { held } }) };
    db.prepare(
      `INSERT INTO workshop_plays (token, player, item, seed, ticks, issued_at, submitted_at, outcome, counted)
       VALUES (?, ?, ?, '1', ?, ?, ?, ?, ?)`).run(`p${++n}`, player, item, seconds * TICKS_PER_SECOND, at, at,
      JSON.stringify(outcome), counted ? 1 : 0);
  };
  return { t, q, db, who, buy, island, play };
}

test("a cap is held at its share and what it would have taken goes to the rest in proportion, until none is over (18.9)", () => {
  assert.deepEqual(capped({ a: 1, b: 1, c: 2 }, 400, 1000), { a: 100, b: 100, c: 200 });
  // c would take 200, past 150: held there, and its 50 spread over a and b.
  assert.deepEqual(capped({ a: 1, b: 1, c: 2 }, 400, 150), { a: 125, b: 125, c: 150 });
  // Every creator at the cap leaves the rest of the fund unpaid.
  assert.deepEqual(capped({ a: 1, b: 1 }, 1000, 20), { a: 20, b: 20 });
  assert.deepEqual(capped({ a: 0 }, 100, 50), {});
});

test("the Island Fund pays 10% of a quarter's net revenue, after refunds and §22.5's commission, by time played on each opted-in adult creator's islands, none above 2%, at the quarter's end and once (18.9, 22.5)", () => {
  const { t, q, db, who, buy, island, play } = quarterOfPlay();
  const buyer = who("buyer");
  for (let i = 0; i < 40; i++) buy(buyer, 600);
  const refunded = buy(buyer, 600);
  db.prepare("INSERT INTO refunds (store, txn, kind, at) VALUES ('apple', ?, 'refund', ?)").run(refunded, q.starts_at + DAY);
  const reversed = buy(buyer, 600);
  db.prepare("INSERT INTO refunds (store, txn, kind, at) VALUES ('apple', ?, 'refund', ?)").run(reversed, q.starts_at + DAY);
  db.prepare("INSERT INTO refunds (store, txn, kind, at) VALUES ('apple', ?, 'reversal', ?)").run(reversed, q.starts_at + DAY);
  buy(buyer, 600, q.ends_at + DAY);                      // next quarter's
  // 41 purchases count: 24,600 cents, 20,910 net of 15%, a fund of 2,091.
  const net = Math.floor((41 * 600 * (100 - facts.STORE_COMMISSION)) / 100);
  const pool = Math.floor((net * facts.ISLAND_FUND_SHARE) / 100);
  const cap = Math.floor((pool * facts.ISLAND_FUND_CAP) / 100);
  // Sixty creators, each played for a minute, and one for an hour.
  const creators = Array.from({ length: 60 }, (_, i) => who(`c${i}`));
  const big = who("big");
  const players = Array.from({ length: 3 }, (_, i) => who(`p${i}`));
  for (const c of [...creators, big]) t.service.fund.optIn(c, true);
  creators.forEach((c) => play(players[0], island(c), 60));
  const bigIsland = island(big);
  for (let i = 0; i < 60; i++) play(players[i % 3], bigIsland, 60);
  // What does not count: the creator's own play, a refused play, a play on
  // a removed island, a minor creator, one who did not opt in.
  play(big, bigIsland, 600);
  play(players[1], bigIsland, 600, { validated: false });
  const gone = who("gone");
  t.service.fund.optIn(gone, true);
  play(players[1], island(gone, q.starts_at + DAY), 600);
  const minor = who("minor", "16-17");
  refused(() => t.service.fund.optIn(minor, true), "fund_adults_only");
  play(players[1], island(minor), 600);
  const shy = who("shy");
  play(players[1], island(shy), 600);
  assert.equal(t.service.fund.close(q.q), null, "not before the quarter ends");
  t.clock.now = q.ends_at + DAY;
  const closed = t.service.fund.close(q.q);
  assert.deepEqual([closed.net, closed.pool], [net, pool]);
  const paid = Object.fromEntries(closed.payouts.map((p) => [p.creator, p]));
  assert.deepEqual(Object.keys(paid).sort(), [...creators, big].sort(), "opted-in adults with time played");
  assert.equal(paid[big].seconds, 3600);
  assert.equal(paid[big].cents, cap, "no more than 2% of the fund");
  const each = Math.floor((pool - cap) / 60);
  assert.ok(creators.every((c) => paid[c].cents === each), "the rest spread down the tail");
  assert.ok(closed.payouts.reduce((s, p) => s + p.cents, 0) <= pool);
  // Once: a second close changes nothing, and the daily job finds it closed.
  t.service.fund.close(q.q);
  assert.equal(db.prepare("SELECT COUNT(*) AS n FROM fund_payouts").get().n, 61);
  assert.deepEqual(t.service.fund.view(big), { opted_in: true, may: true, quarters: [{ quarter: q.name, cents: cap }] });
});

test("time played counts the event log's seconds where it has them, a quarter of a constellation-mate's, and the daily job closes each ended quarter (18.7, 18.9, TD.39)", () => {
  const { t, q, db, who, buy, island, play } = quarterOfPlay();
  buy(who("buyer"), 10_000);
  const [a, b] = [who("a"), who("b")];
  const [mate, stranger] = [who("mate"), who("stranger")];
  t.service.fund.optIn(a, true);
  t.service.fund.optIn(b, true);
  db.prepare("INSERT INTO constellations (id, name_adjective, name_noun, founded_at) VALUES ('k', 0, 0, 0)").run();
  db.prepare("INSERT INTO constellation_members (constellation, account, role, joined_at) VALUES ('k', ?, 'founder', 0)")
    .run(a);
  db.prepare("INSERT INTO constellation_members (constellation, account, role, joined_at) VALUES ('k', ?, 'member', 0)")
    .run(mate);
  const ia = island(a);
  play(mate, ia, 150, { held: 80 });
  play(stranger, ia, 150, { held: 100 });
  play(stranger, island(b), 150);
  t.clock.now = q.ends_at + DAY;
  const [closed] = t.service.fund.closeEnded();
  const seconds = Object.fromEntries(closed.payouts.map((p) => [p.creator, p.seconds]));
  assert.deepEqual(seconds, { [a]: 100 + 80 * facts.KIN_COMPLETION_WEIGHT, [b]: 150 });
  assert.deepEqual(t.service.fund.closeEnded(), [], "closed once");
});

test("the Island Fund's settings page and opt-in are served over HTTP (18.9)", async () => {
  const t = server();
  const { token } = t.service.session("gc:creator");
  const call = (method, json) => t.handle(new Request("https://edge.example/v1/fund", {
    method, headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
    body: json ? JSON.stringify(json) : undefined }));
  assert.deepEqual(await (await call("GET")).json(), { opted_in: false, may: true, quarters: [] });
  assert.equal((await (await call("PUT", { optIn: true })).json()).opted_in, true);
  const bad = await call("PUT", { optIn: "yes" });
  assert.deepEqual([bad.status, (await bad.json()).error], [400, "malformed_body"]);
});
