// Friends (§12.11, §17.6), against the real simulation build.

import assert from "node:assert/strict";
import { test } from "node:test";

import { Refused } from "../src/service.mjs";
import { Workshop } from "../src/workshop.mjs";
import { openPlan, play, twoPlayers } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);
const DAY = 24 * 60 * 60 * 1000;

/** The defender and raider of twoPlayers, made friends by an invite. */
function friends(t) {
  const { invite } = t.service.friends.invite(t.defender.account);
  t.service.friends.accept(t.raider.account, invite);
}

test("two players become friends by an invite one shares, and either can end it (17.6)", () => {
  const t = twoPlayers(true);
  const f = t.service.friends;
  const { invite } = f.invite(t.defender.account);
  refusal(() => f.accept(t.defender.account, invite), "own_invite");
  assert.deepEqual(f.accept(t.raider.account, invite), { friend: t.defender.account });
  refusal(() => f.accept(t.raider.account, invite), "no_such_invite");
  assert.deepEqual(f.list(t.raider.account).map((x) => x.account), [t.defender.account]);
  assert.equal(f.areFriends(t.defender.account, t.raider.account), true);
  const late = f.invite(t.raider.account).invite;
  t.clock.now += 8 * DAY;
  refusal(() => f.accept(t.service.session("gc:late").account, late), "no_such_invite");
  f.remove(t.defender.account, t.raider.account);
  assert.deepEqual(f.list(t.raider.account), []);
});

test("a friendly heist is for fun: no fee, no Renown, the friend loses nothing and earns a page a catch (12.11)", () => {
  const t = twoPlayers(true);
  refusal(() => t.service.lease(t.raider.account, t.bundle, null, { mode: "friendly" }), "not_friends");
  friends(t);
  // A new friend is still a friend: §12.3's protection is against raids.
  t.service.db.prepare("UPDATE accounts SET created_at = ? WHERE id = ?").run(t.clock.now, t.defender.account);
  const lease = t.service.lease(t.raider.account, t.bundle, null, { mode: "friendly" });
  assert.equal(lease.mode, "friendly");
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: [] }));
  assert.equal(out.verdict.grade, "foiled");
  assert.deepEqual([out.fee, out.renown, out.stars, out.rating, out.defence], [0, { raider: 0, defender: 0 },
                   { raider: 0, defender: 0 }, null, null]);
  assert.equal(out.friendPages, out.verdict.caught, "a page for every raider their guards catch");
  assert.ok(out.friendPages > 0);
  assert.deepEqual(t.service.balance(t.defender.account), { starlight: 0, essence: 0 });
  assert.deepEqual(t.service.replay(t.defender.account, lease.token).length > 0, true, "both see the replay");
});

test("the friends' feed shows what friends did this week, and nothing of strangers (17.6)", () => {
  const t = twoPlayers(true);
  const watcher = t.service.session("gc:watcher").account;
  assert.deepEqual(t.service.friends.feed(watcher), []);
  const { invite } = t.service.friends.invite(watcher);
  t.service.friends.accept(t.raider.account, invite);
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.deepEqual(t.service.friends.feed(watcher).map((e) => [e.raider, e.defender, e.grade, e.mode]),
                   [[t.raider.account, t.defender.account, "clean", "raid"]]);
  assert.deepEqual(t.service.friends.feed(t.defender.account), [], "the defender is not the watcher's friend");
  t.clock.now += 8 * 24 * 60 * 60 * 1000;
  assert.deepEqual(t.service.friends.feed(watcher), [], "a week on, gone from the feed");
});

test("a 13-to-15's heists are in no feed, as the friend or as the other party (G35)", () => {
  const minor = (account) => t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(account);
  const t = twoPlayers(true);
  const watcher = t.service.session("gc:watcher").account;
  t.service.friends.accept(t.raider.account, t.service.friends.invite(watcher).invite);
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.equal(t.service.friends.feed(watcher).length, 1);
  // The raided player is 13 to 15 and nobody's friend here: still hidden.
  minor(t.defender.account);
  assert.deepEqual(t.service.friends.feed(watcher), [], "the other party is a minor");
  t.service.db.prepare("UPDATE accounts SET age_band = '18+' WHERE id = ?").run(t.defender.account);
  // The watcher's friend is the minor: hidden from the watcher's feed.
  minor(t.raider.account);
  assert.deepEqual(t.service.friends.feed(watcher), [], "the friend is a minor");
});

test("a challenge link plays the island once for anyone who holds it (17.6)", () => {
  const t = twoPlayers(true);
  const { challenge, bundle } = t.service.friends.challenge(t.defender.account);
  refusal(() => t.service.lease(t.defender.account, bundle, null, { mode: "challenge", challenge }), "own_island");
  const lease = t.service.lease(t.raider.account, bundle, null, { mode: "challenge", challenge });
  const out = t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  assert.deepEqual([out.mode, out.fee, out.renown.raider], ["challenge", 0, 0]);
  assert.equal(out.haul.total, 0, "for fun only: no haul (F48)");
  assert.deepEqual(t.service.balance(t.raider.account), { starlight: 0, essence: 0 },
                   "and no ledger line");
  t.clock.now += DAY + 1;
  refusal(() => t.service.lease(t.raider.account, bundle, null, { mode: "challenge", challenge }),
          "challenge_already_played");
  refusal(() => t.service.lease(t.raider.account, bundle, null, { mode: "challenge", challenge: "nope" }),
          "no_such_challenge");
});

test("a banned player's challenge links are void (20.12)", () => {
  const t = twoPlayers(true);
  const { challenge, bundle } = t.service.friends.challenge(t.defender.account);
  new Workshop(t.service).ban(t.defender.account, "offensive");
  refusal(() => t.service.lease(t.raider.account, bundle, null, { mode: "challenge", challenge }),
          "no_such_challenge");
});

test("friends and challenges over HTTP", async () => {
  const t = twoPlayers(true);
  const call = (method, path, who, json) => t.handle(new Request(`https://edge.example${path}`, {
    method, headers: { authorization: `Bearer ${who.token}`, ...(json ? { "content-type": "application/json" } : {}) },
    body: json ? JSON.stringify(json) : undefined }));
  const { invite } = await (await call("POST", "/v1/friends/invites", t.defender)).json();
  assert.equal((await call("POST", "/v1/friends/accept", t.raider, { invite })).status, 200);
  const list = await (await call("GET", "/v1/friends", t.defender)).json();
  assert.deepEqual(list.map((f) => f.account), [t.raider.account]);
  const lease = await (await call("POST", "/v1/leases", t.raider, { bundle: t.bundle, mode: "friendly" })).json();
  assert.equal(lease.mode, "friendly");
  const link = await (await call("POST", "/v1/challenges", t.defender)).json();
  const opened = await (await call("GET", `/v1/challenges/${link.challenge}`, t.raider)).json();
  assert.deepEqual([opened.bundle, opened.from], [t.bundle, t.defender.account]);
  assert.equal((await call("DELETE", `/v1/friends/${t.raider.account}`, t.defender)).status, 200);
});
