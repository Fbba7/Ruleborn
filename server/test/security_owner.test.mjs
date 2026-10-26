// Security review findings that need the owner's decision
// (docs/security/review.md, "Needs the owner"). Each test pins the issue
// as the build has it today, so it passes; once the owner decides, the
// fix turns its assertion round.

import assert from "node:assert/strict";
import { test } from "node:test";

import { quarterOf } from "../src/fund.mjs";
import { Social } from "../src/social.mjs";
import { TICKS_PER_SECOND } from "../src/service.mjs";
import { twoPlayers, server } from "./setup.mjs";

// SR-09: §12.15, "Ratings are internal … the raw numbers are never shown".
test("SR-09 (needs the owner): a target list names every island's raw rating, which 12.15 says is never shown", () => {
  const t = twoPlayers(false);
  const lists = t.service.targetLists();
  const list = JSON.parse(new TextDecoder().decode(t.service.bundle(Object.values(lists)[0])));
  assert.ok(list.candidates.length > 0);
  for (const c of list.candidates) {
    assert.equal(typeof c.rating, "number");
    assert.equal(typeof c.deviation, "number");
  }
});

// SR-10: §20.2's monthly cap, kept only when the device asks for an intent.
test("SR-10 (needs the owner): a 13-to-15's receipts with no intent are granted past the month's cap", () => {
  const t = server({ firstBand: "13-15",
                     cosmetics: { items: [{ id: "big", kind: "outfit", price: 2400 }, { id: "more", kind: "outfit", price: 500 }] },
                     verifyReceipt: (_s, r) => ({ transaction: r, product: r === "t1" ? "big" : "more", intent: null }) });
  const minor = t.service.session("gc:minor");
  t.service.shop.redeem(minor.account, "app-store", "t1");
  t.service.shop.redeem(minor.account, "app-store", "t2");
  assert.equal(t.service.shop.allowance(minor.account), 0, "€29 granted against a €25 cap");
  assert.ok(t.service.shop.summary(minor.account).months[0].cents > 2500);
});

// SR-12: §18.9's Island Fund is real money, divided by time played, and
// "the cap on one player's time on one island" is not built (fund.mjs: no
// number for it). One second account replaying a creator's island all day
// credits it hundreds of hours.
test("SR-12 (needs the owner): one player replaying one island is credited every play's time", () => {
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
  assert.equal(t.service.fund.played(q.starts_at, q.ends_at)[creator], 200 * 150,
               "200 plays by one account, 200 plays' seconds");
});

// SR-14: §17.7's crews are "formed inside a constellation, or with friends
// across constellations", and §20.7 holds a 13-to-15's co-op heists to
// friends only; joining takes only the invite.
test("SR-14 (needs the owner): a 13-to-15 joins a crew of strangers with its invite", () => {
  const t = server();
  const social = new Social(t.service);
  const stranger = t.service.session("gc:stranger").account;
  const minor = t.service.session("gc:minor").account;
  t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(minor);
  const crew = social.startCrew(stranger);
  assert.equal(t.service.friends.areFriends(minor, stranger), false);
  assert.equal(social.joinCrew(minor, crew.invite).members.length, 2);
});

// SR-15 (register D60): §24.8 has a published island's exposed loot "come
// from the owner's own ledger and buildings on the server, never from the
// bundle's word"; the server stores the four bytes the client wrote.
test("SR-15 (needs the owner, D60): an island's exposed loot is the bundle's word", () => {
  const t = server();
  const owner = t.service.session("gc:owner").account;
  const island = t.build.exampleIsland(true);
  new DataView(island.buffer, island.byteOffset).setUint32(6, 0xffffffff, true);
  const { bundle } = t.service.publish(owner, island);
  const exposed = t.service.db.prepare("SELECT exposed FROM snapshots WHERE bundle = ?").get(bundle).exposed;
  assert.equal(exposed, 0xffffffff, "a player with nothing stored claims the most richness pays");
  assert.deepEqual(t.service.balance(owner), { starlight: 0, essence: 0 });
});
