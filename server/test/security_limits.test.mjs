// Security review findings on resource exhaustion (docs/security/review.md).

import assert from "node:assert/strict";
import { test } from "node:test";

import * as matchmaking from "../src/matchmaking.mjs";
import { established, server } from "./setup.mjs";

/** How many statements the database prepares while `f` runs. */
async function statements(t, f) {
  const db = t.service.db;
  const prepare = db.prepare.bind(db);
  let n = 0;
  db.prepare = (sql) => { n++; return prepare(sql); };
  try {
    await f();
  } finally {
    db.prepare = prepare;
  }
  return n;
}

// SR-03: GET /v1/offer and the Observatory made §12.22's candidates afresh
// for every caller, two reads an island across the whole game: at 1,000
// islands about 150 ms of the process a request, two a second an account.
test("SR-03: one making of the candidates serves every caller for a while, and a publish makes them again", async () => {
  const t = server();
  for (let i = 0; i < 40; i++) {
    const s = t.service.session(`gc:p${i}`);
    established(t, s.account);
    t.service.publish(s.account, t.build.generate(i + 1, 3));
  }
  const me = t.service.session("gc:me");
  const offer = async () => {
    const r = await t.handle(new Request("https://edge.example/v1/offer?size=3",
                                         { headers: { authorization: `Bearer ${me.token}` } }));
    assert.equal(r.status, 200);
    return r.json();
  };
  const first = await offer();
  const again = await statements(t, offer);
  assert.ok(again < 40, `a second offer read ${again} statements for 40 islands`);
  assert.deepEqual(await offer(), first);

  // A new island is a candidate at once, and so, past the window, is any other change.
  const late = t.service.session("gc:late");
  established(t, late.account);
  t.service.publish(late.account, t.build.generate(99, 3));
  assert.ok(t.service.matchmaking.candidates().some((c) => c.owner === late.account));
  t.clock.now += matchmaking.CANDIDATES_MS ?? 60_000;
  assert.ok(await statements(t, offer) >= 40, "made again once the window has passed");
});

// SR-17: every island published queued §13.3's 800 reference raids, worked
// oldest first, forty raids (about two seconds of the process) every five
// seconds. One account publishing one new island after another, inside its
// limits, queued them faster than they were measured: everyone's islands
// behind its, for good.
test("SR-17: the hold queue measures islands that stand, owners in turn, so one player cannot hold everyone's back", () => {
  const t = server();
  const spammer = t.service.session("gc:spammer");
  established(t, spammer.account);
  for (let i = 0; i < 20; i++) t.service.publish(spammer.account, t.build.generate(100 + i, 3));
  const honest = t.service.session("gc:honest");
  established(t, honest.account);
  const { bundle } = t.service.publish(honest.account, t.build.generate(7, 3));
  t.service.db.prepare("UPDATE island_holds SET raids = 2").run();
  for (let i = 0; i < 2; i++) t.service.holds.work(2);
  assert.equal(t.service.holds.status(bundle).status, "measured",
               "measured after the spammer's one standing island, not after all twenty");
});

// SR-19: the call bucket was the only bound on what a player writes. A
// device's events past the three kinds with a daily count, an invite and a
// challenge link were each a stored row a call: sixty batches of events were
// 870 kB, and two calls a second all day some 2.5 GB, kept 90 days.
test("SR-19: a day's device events, open invites and open challenge links each have a ceiling", async () => {
  const { DEVICE_EVENTS_A_DAY } = await import("../src/telemetry.mjs");
  const { MOST_OPEN } = await import("../src/friends.mjs");
  const t = server();
  const me = t.service.session("gc:me");
  established(t, me.account);
  t.service.publish(me.account, t.build.generate(3, 3));
  const call = (method, path, json) => t.handle(new Request(`https://edge.example${path}`, {
    method, headers: { authorization: `Bearer ${me.token}`, "content-type": "application/json" },
    body: json ? JSON.stringify(json) : undefined }));
  const batch = Array.from({ length: 100 }, () => ({ kind: "weave", data: { law: "bloom", realm: "heart" } }));
  const statuses = [];
  for (let i = 0; i < 6; i++) {
    t.clock.now += 1000;
    statuses.push((await call("POST", "/v1/events", batch)).status);
  }
  assert.deepEqual(statuses, [202, 202, 202, 202, 429, 429], `${DEVICE_EVENTS_A_DAY} a day, then no more`);
  for (const [path, reason] of [["/v1/friends/invites", "too_many_open_invites"],
                                ["/v1/challenges", "too_many_open_challenges"]]) {
    for (let i = 0; i < MOST_OPEN; i++) {
      t.clock.now += 1000;
      assert.equal((await call("POST", path)).status, 201);
    }
    const past = await call("POST", path);
    assert.deepEqual([past.status, (await past.json()).error], [409, reason]);
  }
  t.clock.now += 8 * 24 * 60 * 60 * 1000;
  const later = t.service.session("gc:me");
  const again = await t.handle(new Request("https://edge.example/v1/friends/invites", {
    method: "POST", headers: { authorization: `Bearer ${later.token}` } }));
  assert.equal(again.status, 201, "a lapsed invite frees its place");
});

test("SR-19: a day's unsubmitted Workshop plays and a player's open purchase intents have a ceiling too", async () => {
  const { MOST_OPEN_PLAYS, Workshop } = await import("../src/workshop.mjs");
  const { MOST_OPEN_INTENTS } = await import("../src/shop.mjs");
  const { clockTicks } = await import("../src/service.mjs");
  const { openPlan } = await import("./setup.mjs");
  const items = Array.from({ length: 12 }, (_, i) => ({ id: `c${i}`, kind: "outfit", price: 100 }));
  const t = server({ cosmetics: { items } });
  const w = new Workshop(t.service);
  const island = t.build.exampleIsland(true);
  const cleared = t.build.record(island, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  const creator = t.service.session("gc:creator").account;
  const { id } = w.publish(creator, island, cleared, { adjective: 1, noun: 9 });
  const player = t.service.session("gc:player").account;
  for (let i = 0; i < MOST_OPEN_PLAYS; i++) w.play(player, id);
  assert.throws(() => w.play(player, id), (e) => e.reason === "too_many_open_plays");
  t.clock.now += 24 * 60 * 60 * 1000 + 1;
  assert.ok(w.play(player, id).token, "a day on, the old ones no longer count");

  const buyer = t.service.session("gc:buyer").account;
  for (let i = 0; i < MOST_OPEN_INTENTS; i++) t.service.shop.intent(buyer, `c${i}`);
  assert.throws(() => t.service.shop.intent(buyer, "c11"), (e) => e.reason === "too_many_open_intents");
  t.clock.now += 16 * 60 * 1000;
  assert.ok(t.service.shop.intent(buyer, "c11").intent, "a lapsed intent frees its place");
});
