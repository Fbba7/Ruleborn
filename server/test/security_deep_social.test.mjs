// The deep security run's fixes in the universe and the social areas
// (SEC-35 onwards): a free change keeps what is owed, and what is shown of
// a player or a crew is no more than the caller may see.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { deleteAccount } from "../src/accounts.mjs";
import { clockTicks } from "../src/service.mjs";
import { Social } from "../src/social.mjs";
import { COUNTED_AGE_MS, COUNTED_KEEPER_LEVEL, LONE_FANS_A_DAY, Workshop } from "../src/workshop.mjs";
import { counting, openPlan, play, server, twoPlayers } from "./setup.mjs";

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
  counting(t, early);                   // a completion that counts (SEC-26)
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
  counting(other.t, player);
  const p2 = other.w.play(player, other.item.id);
  assert.equal(other.w.submitPlay(player, p2.token, cleared(other.t, p2)).counted, true);
  assert.equal(other.w.ladder(other.creator).completions, 1);
  other.remove(other.item.id);
  assert.equal(other.w.ladder(other.creator).completions, 0);
});

// SEC-26: one person with many accounts could lift a creator's ladder, the
// island's numbers and its Island Fund share. A completion, a rating or a
// play's time now counts only from an account at least COUNTED_AGE_MS old
// and at COUNTED_KEEPER_LEVEL when it is recorded, and of the accounts that
// play nothing but that creator's islands, only LONE_FANS_A_DAY a UTC day.
test("SEC-26: completions, ratings and play time from new or low-level accounts are recorded but do not count", () => {
  const { t, w, creator, item } = workshop();
  const score = { fun: 5, cleverness: 5, fairness: 5 };
  for (let i = 0; i < 10; i++) {
    const alt = t.service.session(`gc:alt${i}`).account;
    // Old enough but too low, or high enough but too new.
    t.service.db.prepare("UPDATE accounts SET created_at = ?, keeper_level = ? WHERE id = ?")
      .run(i % 2 ? t.clock.now - COUNTED_AGE_MS : t.clock.now - COUNTED_AGE_MS + 1,
           i % 2 ? COUNTED_KEEPER_LEVEL - 1 : COUNTED_KEEPER_LEVEL, alt);
    const p = w.play(alt, item.id);
    const out = w.submitPlay(alt, p.token, cleared(t, p));
    assert.deepEqual([out.validated, out.counted, out.ladder], [true, true, false], "recorded, not counted");
    w.rate(alt, item.id, score);
  }
  assert.deepEqual(w.ladder(creator), { level: null, completions: 0, featured: 0 }, "not even a Builder");
  const v = w.view(w.row(item.id));
  assert.deepEqual([v.completions, v.ratings.count, v.uncounted], [0, 0, { completions: 10, ratings: 10 }]);
  assert.deepEqual(w.browse(creator, "top").map((i) => i.completions ?? 0), [0]);
  assert.deepEqual(t.service.fund.played(0, t.clock.now + 1), {}, "no Island Fund time");
  // One that qualifies counts, everywhere.
  const fan = t.service.session("gc:fan").account;
  counting(t, fan);
  const p = w.play(fan, item.id);
  assert.equal(w.submitPlay(fan, p.token, cleared(t, p)).ladder, true);
  w.rate(fan, item.id, score);
  assert.equal(w.ladder(creator).completions, 1);
  assert.equal(w.view(w.row(item.id)).ratings.count, 1);
  assert.deepEqual(Object.keys(t.service.fund.played(0, t.clock.now + 1)), [creator]);
});

test("SEC-26: of the qualified accounts that play only one creator's islands, three a day count for that creator", () => {
  const { t, w, creator, item, island } = workshop();
  const score = { fun: 4, cleverness: 4, fairness: 4 };
  t.clock.now = Math.floor(t.clock.now / (24 * HOUR)) * 24 * HOUR + HOUR;   // the day's first hour
  const fan = (name) => {
    const a = t.service.session(`gc:${name}`).account;
    counting(t, a);
    const p = w.play(a, item.id);
    const ladder = w.submitPlay(a, p.token, cleared(t, p)).ladder;
    w.rate(a, item.id, score);
    return ladder;
  };
  const day = [0, 1, 2, 3, 4].map((i) => fan(`lone${i}`));
  assert.deepEqual(day, [true, true, true, false, false], `the first ${LONE_FANS_A_DAY} a day`);
  assert.equal(w.ladder(creator).completions, LONE_FANS_A_DAY);
  assert.equal(w.view(w.row(item.id)).ratings.count, LONE_FANS_A_DAY);
  // A player who has played someone else's island is no lone fan.
  // Another creator's own island: other bytes, since these are listed (SEC-41).
  const theirs = Uint8Array.from(island);
  theirs[6] = (theirs[6] + 1) & 0xff;
  const elsewhere = w.publish(t.service.session("gc:other").account, theirs,
                              t.build.record(theirs, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() }),
                              { adjective: 2, noun: 2 });
  const wide = t.service.session("gc:wide").account;
  counting(t, wide);
  const q = w.play(wide, elsewhere.id);
  w.submitPlay(wide, q.token, cleared(t, q));
  const p = w.play(wide, item.id);
  assert.equal(w.submitPlay(wide, p.token, cleared(t, p)).ladder, true, "past the cap, a wider player counts");
  // The next UTC day, three more lone fans.
  t.clock.now += 24 * HOUR;
  assert.deepEqual([5, 6, 7, 8].map((i) => fan(`lone${i}`)), [true, true, true, false]);
  assert.equal(w.ladder(creator).completions, 2 * LONE_FANS_A_DAY + 1);
});

test("SEC-41: another creator's listed or taken-down island is not listed again unchanged; a withdrawn one may be", () => {
  const { t, w, island, cleared, creator, item, remove } = workshop();
  const copier = t.service.session("gc:sec41-copier").account;
  const status = (fn) => { try { fn(); return "listed"; } catch (e) { return `${e.status} ${e.reason}`; } };
  const copy = (opts) => () => w.publish(copier, island, cleared, { adjective: 2, noun: 3, ...opts });
  const fetched = w.remix(copier, item.id);
  assert.deepEqual(Buffer.from(fetched), Buffer.from(island), "the remix hands over the bytes");
  assert.equal(status(copy({ remixOf: item.id })), "409 remix_unchanged", "a remix changed nothing");
  assert.equal(status(copy({})), "409 already_published", "nor a copy named as no remix");
  assert.equal(w.publish(creator, island, cleared, { adjective: 3, noun: 4 }).bundle, item.bundle,
               "its own creator may list it twice");
  const other = t.build.exampleIsland(true);
  other[6] = (other[6] + 1) & 0xff;                       // the loot exposed: other bytes
  const otherClear = t.build.record(other, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  const changed = w.publish(copier, other, otherClear, { adjective: 2, noun: 3, remixOf: item.id });
  assert.notEqual(changed.bundle, item.bundle, "a remix that changes something is listed");
  remove(item.id);
  assert.equal(status(copy({})), "409 already_published", "an island taken down is not listed again by another");
  // The creator's second listing withdrawn as well: nothing of theirs is shown.
  const second = w.mine(creator).find((i) => i.id !== item.id && i.bundle === item.bundle);
  w.withdraw(creator, second.id);
  assert.equal(status(copy({})), "409 already_published", "the taken-down one still counts");
});

test("SEC-41: an island its creator withdrew may be listed by another, and its bytes stay when that creator's account goes", () => {
  const { t, w, island, cleared, creator, item } = workshop();
  w.withdraw(creator, item.id);
  const later = t.service.session("gc:sec41-later").account;
  const listed = w.publish(later, island, cleared, { adjective: 2, noun: 3 });
  assert.equal(listed.bundle, item.bundle);
  deleteAccount(t.service, later, "under-13");
  assert.notEqual(t.service.bundle(item.bundle), null, "the withdrawn island's creator still holds the bytes");
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

// SEC-37: the push token lived on the account alone, so a device signed out
// (or every device, signed out everywhere) was still sent the account's
// notifications. Now the token records the session that registered it, and
// that session's end clears it; signing out everywhere always does.
test("SEC-37: a push token goes with the sign-out of the session that registered it, and with sign-out everywhere", async () => {
  const t = server();
  const phone = t.service.session("gc:sec37");
  const tablet = t.service.session("gc:sec37");
  assert.equal(phone.account, tablet.account);
  const call = (who, path, method, body) => t.handle(new Request(`https://edge.example${path}`, {
    method, headers: { authorization: `Bearer ${who.token}`, "content-type": "application/json" },
    body: JSON.stringify(body) }));
  const register = async (who, pushToken) => {
    assert.equal((await call(who, "/v1/notifications", "PUT", { pushToken, timeZone: "UTC" })).status, 200);
  };
  // A message due now, and the tokens it is sent to.
  const sentTo = async () => {
    t.service.db.prepare("INSERT INTO notifications (account, kind, data, due_at) VALUES (?, 'reminder', ?, ?)")
      .run(phone.account, JSON.stringify({ day: "2026-09-23" }), t.clock.now);
    const to = [];
    await t.service.notifications.deliver((token) => { to.push(token); return {}; });
    return to;
  };
  await register(phone, "phone-token");
  assert.deepEqual(await sentTo(), ["phone-token"]);
  // The other device's sign-out leaves the phone's token.
  assert.equal((await call(tablet, "/v1/session/end", "POST", {})).status, 200);
  assert.deepEqual(await sentTo(), ["phone-token"], "the tablet signed out; the phone still hears");
  // The phone's own sign-out takes it.
  assert.equal((await call(phone, "/v1/session/end", "POST", {})).status, 200);
  assert.deepEqual(await sentTo(), [], "the phone signed out hears nothing");
  assert.equal(t.service.db.prepare("SELECT push_token FROM accounts WHERE id = ?").get(phone.account).push_token, null);
  // Sign out everywhere, from another device than the one that registered it.
  const again = t.service.session("gc:sec37");
  const laptop = t.service.session("gc:sec37");
  await register(again, "phone-token-2");
  assert.deepEqual(await sentTo(), ["phone-token-2"]);
  assert.equal((await call(laptop, "/v1/session/end", "POST", { everywhere: true })).status, 200);
  assert.deepEqual(await sentTo(), [], "signed out everywhere, no device hears");
  // Signing out the other devices, from the one that registered it, keeps it.
  const mine = t.service.session("gc:sec37");
  t.service.session("gc:sec37");
  await register(mine, "phone-token-3");
  assert.equal((await call(mine, "/v1/session/end", "POST", { others: true })).status, 200);
  assert.deepEqual(await sentTo(), ["phone-token-3"]);
});

test("SEC-43: a member's block does not hide the constellation from the player blocked; its founder's still does", () => {
  const t = server();
  const social = new Social(t.service);
  const [founder, member, p] = ["gc:f43", "gc:m43", "gc:p43"].map((id) => t.service.session(id).account);
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6").run();
  const c = social.found(founder, { adjective: 1, noun: 2 });
  social.join(member, c.id);
  t.service.safety.block(member, p);
  // P still sees the open group, without the member who blocked them.
  assert.deepEqual(social.constellation(c.id, p).members.map((m) => m.account), [founder]);
  assert.equal(social.join(p, c.id).id, c.id, "and can join it");
  assert.deepEqual(social.constellation(c.id, member).members.map((m) => m.account).sort(),
                   [founder, member].sort(), "the member who blocked P does not see them");
  social.leave(p);
  // The founder's block hides it, answered as no such group (17.8).
  t.service.safety.block(founder, p);
  assert.throws(() => social.constellation(c.id, p), (e) => e.reason === "no_such_constellation");
  assert.throws(() => social.join(p, c.id), (e) => e.reason === "no_such_constellation");
});

test("SEC-43: the founder or an elder removes a member, who cannot join again for 7 days", async () => {
  const { REMOVED_DAYS } = await import("../src/social.mjs");
  assert.equal(REMOVED_DAYS, 7);
  const t = server();
  const social = new Social(t.service);
  const s = ["gc:f", "gc:e", "gc:m", "gc:n"].map((id) => t.service.session(id));
  const [founder, elder, member, other] = s.map((x) => x.account);
  t.service.db.prepare("UPDATE accounts SET keeper_level = 6").run();
  const c = social.found(founder, { adjective: 1, noun: 2 });
  for (const a of [elder, member, other]) social.join(a, c.id);
  social.appoint(founder, elder, "elder");
  const refused = (fn, reason) => assert.throws(fn, (e) => e.reason === reason, reason);
  // A member removes no one; an elder removes no elder or founder.
  refused(() => social.remove(member, c.id, other), "officers_only");
  refused(() => social.remove(elder, c.id, founder), "officers_only");
  refused(() => social.remove(founder, c.id, founder), "not_a_member");
  refused(() => social.remove(founder, "elsewhere", member), "officers_only");
  // An elder removes a member, over HTTP.
  const r = await t.handle(new Request(`https://edge.example/v1/constellations/${c.id}/remove`, {
    method: "POST", headers: { authorization: `Bearer ${s[1].token}`, "content-type": "application/json" },
    body: JSON.stringify({ account: member }) }));
  assert.equal(r.status, 200);
  assert.ok(!(await r.json()).members.some((m) => m.account === member), "the member is gone");
  assert.equal(social.membership(member), null);
  // They cannot join again for a week, to the millisecond.
  const until = t.clock.now + REMOVED_DAYS * 24 * 60 * 60 * 1000;
  t.clock.now = until - 1;
  refused(() => social.join(member, c.id), "removed_from_constellation");
  t.clock.now = until;
  assert.equal(social.join(member, c.id).id, c.id, "a week on, they may");
  // A player who left of their own accord may come back at once.
  social.leave(other);
  assert.equal(social.join(other, c.id).id, c.id);
  // The founder removes an elder.
  assert.ok(!social.remove(founder, c.id, elder).members.some((m) => m.account === elder));
});
