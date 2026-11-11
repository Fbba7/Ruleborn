// The security review's findings the owner decided (docs/decisions/owner-decisions.md,
// B1 to B6). Each test pins the decided behaviour.

import assert from "node:assert/strict";
import { test } from "node:test";

import { ONE_PLAYER_ONE_ISLAND_S, quarterOf } from "../src/fund.mjs";
import { Social } from "../src/social.mjs";
import { TICKS_PER_SECOND } from "../src/service.mjs";
import { lawsOf } from "../src/telemetry.mjs";
import { raiseTo } from "../src/universe.mjs";
import { twoPlayers, server } from "./setup.mjs";

// SR-09: §12.15, "Ratings are internal … the raw numbers are never shown".
test("SR-09: a target list carries no island's raw rating or deviation (12.15)", () => {
  const t = twoPlayers(false);
  const lists = t.service.targetLists();
  const list = JSON.parse(new TextDecoder().decode(t.service.bundle(Object.values(lists)[0])));
  assert.ok(list.candidates.length > 0);
  for (const c of list.candidates) {
    assert.equal("rating" in c, false);
    assert.equal("deviation" in c, false);
  }
});

// SR-10: §20.2's monthly cap, kept only when the device asks for an intent.
test("SR-10: a 13-to-15's receipt with no intent is refused past the month's cap", () => {
  const t = server({ firstBand: "13-15",
                     cosmetics: { items: [{ id: "big", kind: "outfit", price: 2400 }, { id: "more", kind: "outfit", price: 500 }] },
                     verifyReceipt: (_s, r) => ({ transaction: r, product: r === "t1" ? "big" : "more", intent: null }) });
  const minor = t.service.session("gc:minor");
  t.service.shop.redeem(minor.account, "app-store", "t1");
  assert.equal(t.service.shop.allowance(minor.account), 100);
  assert.throws(() => t.service.shop.redeem(minor.account, "app-store", "t2"), { reason: "monthly_cap" });
  assert.equal(t.service.shop.summary(minor.account).months[0].cents, 2400, "the €5 was not granted");
});

// SR-12: §18.9's Island Fund is real money, divided by time played, and
// "the cap on one player's time on one island" is not built (fund.mjs: no
// number for it). One second account replaying a creator's island all day
// credits it hundreds of hours.
test("SR-12: one player's time on one island counts to an hour a quarter", () => {
  const t = server();
  const q = quarterOf(t.clock.now);
  const db = t.service.db;
  const creator = t.service.session("gc:creator").account;
  const alt = t.service.session("gc:alt").account;
  db.prepare(`INSERT INTO workshop_items (id, creator, bundle, realm_level, name_adjective, name_noun, cleared_by,
                                          bytes, published_at) VALUES ('i', ?, 'b', 3, 0, 0, 'r', 1, ?)`)
    .run(creator, q.starts_at);
  const at = q.starts_at + 1000;
  for (let n = 0; n < 200; n++) {
    db.prepare(`INSERT INTO workshop_plays (token, player, item, seed, ticks, issued_at, submitted_at, outcome)
                VALUES (?, ?, 'i', '1', ?, ?, ?, '{"validated":true}')`).run(`p${n}`, alt, 150 * TICKS_PER_SECOND, at, at);
  }
  assert.equal(ONE_PLAYER_ONE_ISLAND_S, 3600);
  assert.equal(t.service.fund.played(q.starts_at, q.ends_at)[creator], ONE_PLAYER_ONE_ISLAND_S,
               "200 plays by one account, an hour");
});

// SR-14: §17.7's crews are "formed inside a constellation, or with friends
// across constellations", and §20.7 holds a 13-to-15's co-op heists to
// friends only; joining takes only the invite.
test("SR-14: a 13-to-15 joins a crew only as a friend of every member; an adult as a friend or constellation-mate of one", () => {
  const t = server();
  const social = new Social(t.service);
  const stranger = t.service.session("gc:stranger").account;
  const minor = t.service.session("gc:minor").account;
  t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(minor);
  const crew = social.startCrew(stranger);
  assert.equal(t.service.friends.areFriends(minor, stranger), false);
  assert.throws(() => social.joinCrew(minor, crew.invite), { reason: "not_friends" });
  const adult = t.service.session("gc:adult").account;
  assert.throws(() => social.joinCrew(adult, crew.invite), { reason: "not_friends" });
  const [x, y] = [minor, stranger].sort();
  t.service.db.prepare("INSERT INTO friends (a, b, since, invited_by) VALUES (?, ?, 0, ?)").run(x, y, stranger);
  assert.equal(social.joinCrew(minor, crew.invite).members.length, 2);
  const other = t.service.session("gc:other").account;
  const [p, q] = [other, stranger].sort();
  t.service.db.prepare("INSERT INTO friends (a, b, since, invited_by) VALUES (?, ?, 0, ?)").run(p, q, stranger);
  assert.equal(social.joinCrew(other, crew.invite).members.length, 3, "an adult friend of one member joins");
  const late = t.service.session("gc:late").account;
  t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(late);
  const [r, w] = [late, stranger].sort();
  t.service.db.prepare("INSERT INTO friends (a, b, since, invited_by) VALUES (?, ?, 0, ?)").run(r, w, stranger);
  assert.throws(() => social.joinCrew(late, crew.invite), { reason: "not_friends" }, "a friend of one, not of all");
});

// SR-15 (register D60): §24.8 has a published island's exposed loot "come
// from the owner's own ledger and buildings on the server, never from the
// bundle's word"; the server stores the four bytes the client wrote.
test("SR-15 (D60 unbuilt): an island's exposed loot is clamped to 750, the median richness", () => {
  const t = server();
  const owner = t.service.session("gc:owner").account;
  const island = t.build.exampleIsland(true);
  // SEC-17: an exposure above i32::MAX, which the simulation would read as a
  // negative one, is not an island at all; the largest it can hold is
  // clamped as before.
  new DataView(island.buffer, island.byteOffset).setUint32(6, 0xffffffff, true);
  assert.throws(() => t.service.publish(owner, island), { reason: "island_malformed" });
  new DataView(island.buffer, island.byteOffset).setUint32(6, 0x7fffffff, true);
  const { bundle } = t.service.publish(owner, island);
  const exposed = t.service.db.prepare("SELECT exposed FROM snapshots WHERE bundle = ?").get(bundle).exposed;
  assert.equal(exposed, 750, "a player with nothing stored claims no more than the median");
  assert.deepEqual(t.service.balance(owner), { starlight: 0, essence: 0 });
});

// SR-16 (register G60, G61): §24.8, "a realm plays what its owner wove",
// and "each posted guard's kind, form and level ride in the bundle, checked
// against the owner's roster". Neither is checked: an island defends with
// laws its owner never wove and guards nobody posted.
test("SR-16: an island runs only the laws its owner wove (guards follow with G60)", () => {
  const t = server({ strictUniverse: true });
  const owner = t.service.session("gc:owner").account;
  const island = t.build.exampleIsland(false);
  raiseTo(t.service.db, owner, "heart", island[4], island[5]);
  assert.deepEqual(lawsOf(island), ["brittle_stone", "haste"], "the example island runs two laws");
  const woven = () => t.service.db.prepare("SELECT COUNT(*) AS n FROM law_slots WHERE owner = ?").get(owner).n;
  assert.equal(woven(), 0, "nothing woven");
  assert.throws(() => t.service.publish(owner, island), (e) => e.reason === "island_not_publishable"
    && e.detail.problems.includes("law_not_woven"));
  ["brittle_stone", "haste"].forEach((law, n) => t.service.db.prepare(
    "INSERT INTO law_slots (owner, realm, slot, law, tier, ready_at, rests_until) VALUES (?, 'heart', ?, ?, 1, 0, 0)")
    .run(owner, n + 1, law));
  assert.match(t.service.publish(owner, island).bundle, /^[0-9a-f]{64}$/, "woven, it is published");
});
