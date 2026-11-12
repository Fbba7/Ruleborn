// What the server stores, as server/privacy.json declares it (§20.5, §20.11,
// §20.12): every column declared, and each deletion and time limit it states
// done — against the real simulation build.

import assert from "node:assert/strict";
import { mkdtempSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { quarterOf } from "../src/fund.mjs";

import { Journal, REAPPLY_DAYS, deleteAccount, reapplyDeletions } from "../src/accounts.mjs";
import { Store } from "../src/store.mjs";
import { open } from "../src/db.mjs";
import { SENT_KEEP_DAYS } from "../src/notifications.mjs";
import { routeOf } from "../src/http.mjs";
import { DECLARATIONS, load, problems, render, schema } from "../src/privacy.mjs";
import { CLOSED_KEEP_DAYS, LEASE_MS, Refused, TARGET_LISTS_MS, clockTicks } from "../src/service.mjs";
import { INTENT_MS } from "../src/shop.mjs";
import { Social } from "../src/social.mjs";
import { Workshop } from "../src/workshop.mjs";
import { counting, established, openPlan, play, server } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);
const DAY = 24 * 60 * 60 * 1000;
const doc = load();

test("every column the server stores is declared, with the stores' words for it, and nothing else is (20.5)", async () => {
  assert.deepEqual(problems(doc, schema(open())), []);
  // The check finds what it is for: a column nobody declared.
  const db = open();
  db.exec("ALTER TABLE accounts ADD COLUMN email TEXT");
  assert.deepEqual(problems(doc, schema(db)), ["accounts.email: stored, not declared"]);
  assert.equal(readFileSync(DECLARATIONS, "utf8"), render(doc),
               "server/declarations.md is written from privacy.json: node server/src/privacy.mjs --write");
});

/**
 * A player, X, who has done everything the server keeps something of: an
 * island of their own bytes and a Workshop island of bytes another player
 * also published, raids both ways, an open lease, ratings, Workshop plays,
 * a rating, a remix and a report, a constellation and a crew, friends, an
 * open invite and a challenge link, notifications sent and waiting, and
 * telemetry.
 */
async function busy() {
  const t = server();
  const x = t.service.session("gc:x");
  const xSession = t.service.auth.holder(x.token).session;
  const y = t.service.session("gc:y");
  established(t, x.account);
  established(t, y.account);
  const own = t.build.exampleIsland(true);
  own[5] = 7;                                          // a Vault level no one else's island has
  const xBundle = t.service.publish(x.account, own).bundle;
  const yBundle = t.service.publish(y.account, t.build.exampleIsland(false)).bundle;
  const raid = (who, bundle, plan) => {
    const lease = t.service.lease(who, bundle);
    return t.service.submit(who, lease.token, play(t, lease, { plan }));
  };
  raid(y.account, xBundle, openPlan());
  t.clock.now += DAY;
  const studied = t.service.lease(x.account, yBundle);
  t.service.submit(x.account, studied.token, play(t, studied, { plan: null }));
  // The Codex: a heist studied, a law worked on (codex.mjs).
  const crossed = t.service.codex.show(x.account).laws.find((l) => !["half_gravity", "slow_rivers", "bloom"].includes(l.law));
  t.service.codex.study(x.account, { heist: studied.token, law: crossed.law });
  t.service.codex.workOn(x.account, crossed.law);
  // The Observatory's list refreshed (observatory.mjs).
  t.service.book(x.account, "aether", 50, "a test's grant");
  t.service.observatory.refresh(x.account);
  // A law woven (weaving.mjs).
  t.service.book(x.account, "aether", 1_000, "a test's grant");
  t.service.weaving.weave(x.account, { realm: "heart", slot: 1, law: "bloom" });
  // A Lab experiment run and settled (lab.mjs).
  t.service.db.prepare("UPDATE accounts SET keeper_level = MAX(keeper_level, 3) WHERE id = ?").run(x.account);
  t.service.book(x.account, "starlight", 2_000, "a test's grant");
  t.service.universe.build(x.account, { realm: "heart", kind: "resonance_lab", n: 1, to: 1 });
  t.service.lab.start(x.account, { chamber: 1, laws: ["slow_rivers", "bloom"] });
  t.clock.now += 5 * 60_000;
  t.service.lab.show(x.account);
  // The defence log read (defences.mjs).
  t.service.defences.show(x.account);
  // The profile shown to others (profile.mjs).
  t.service.profile.share(x.account, true);
  // The Keeper's name from the word lists (keeper.mjs, G58).
  t.service.keeper.setName(x.account, { adjective: 0, noun: 0 });
  t.clock.now += DAY;
  raid(x.account, yBundle, null);
  const held = t.service.lease(x.account, yBundle);

  const w = new Workshop(t.service);
  const shared = t.build.exampleIsland(true);
  const cleared = t.build.record(shared, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  // y listed these bytes first and withdrew them, so x may list them too
  // (SEC-41) and they are bytes another player's Workshop island also is.
  w.withdraw(y.account, w.publish(y.account, shared, cleared, { adjective: 2, noun: 2 }).id);
  const mine = w.publish(x.account, shared, cleared, { adjective: 0, noun: 0 });
  const yours = Uint8Array.from(shared);
  yours[6] = (yours[6] + 1) & 0xff;                      // the loot exposed: y's own bytes
  const theirs = w.publish(y.account, yours,
    t.build.record(yours, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() }), { adjective: 1, noun: 1 });
  const p = w.play(x.account, theirs.id);
  w.submitPlay(x.account, p.token, t.build.record(t.service.bundle(p.bundle),
    { seed: BigInt(p.seed), ticks: p.ticks, crew: 3, commands: openPlan() }));
  w.rate(x.account, theirs.id, { fun: 5, cleverness: 4, fairness: 3 });
  w.remix(x.account, theirs.id);
  w.report(x.account, theirs.id, "other");
  // A quarter of the Island Fund closed, paying x for y's play on its island
  // (fund.mjs).
  t.service.fund.optIn(x.account, true);
  counting(t, y.account);                              // y's time counts (SEC-26)
  const yp = w.play(y.account, mine.id);
  w.submitPlay(y.account, yp.token, t.build.record(t.service.bundle(yp.bundle),
    { seed: BigInt(yp.seed), ticks: yp.ticks, crew: 3, commands: openPlan() }));
  t.service.db.prepare("INSERT INTO purchases (store, txn, account, product, price, at) VALUES ('apple', 'f1', ?, 'p', 999, ?)")
    .run(y.account, t.clock.now);
  const quarterNow = quarterOf(t.clock.now);
  const realNow = t.clock.now;
  t.clock.now = quarterNow.ends_at + 1;
  t.service.fund.close(quarterNow.q);
  t.clock.now = realNow;

  t.service.db.prepare("UPDATE accounts SET keeper_level = 6").run();
  const social = new Social(t.service);
  social.join(y.account, social.found(x.account, { adjective: 1, noun: 1 }).id);
  social.startCrew(x.account);
  t.service.friends.accept(y.account, t.service.friends.invite(x.account).invite);
  t.service.friends.invite(x.account);
  t.service.friends.challenge(x.account);
  // The terms accepted, and a block each way with a third player (safety.mjs).
  t.service.safety.accept(x.account, t.service.safety.terms(x.account).version);
  const z = t.service.session("gc:z").account;
  t.service.safety.block(x.account, z);
  t.service.safety.block(z, x.account);
  // A realm of their own, opened and paid for (universe.mjs).
  t.service.book(x.account, "starlight", 5_000, "a test's grant");
  t.service.universe.open(x.account, "Verdant");
  // Its roster at work, a producer collected, a birth at a Nursery (home.mjs).
  t.service.universe.build(x.account, { realm: "outer-1", kind: "nursery", n: 1, to: 1 });
  const home = t.service.home.show(x.account);
  t.service.home.work(x.account, home.characters[0].id, { realm: "heart", kind: "garden" });
  t.clock.now += 6 * 60 * 60 * 1000;
  t.service.home.collect(x.account, { realm: "heart", kind: "garden" });
  t.service.book(x.account, "essence", 1_000, "a test's grant");
  t.service.home.birth(x.account, { realm: "outer-1", n: home.characters.length + 1 });
  // A Sage stationed at the Heart (§11.7).
  t.service.keeper.setGuardian(x.account, "the_archivist");
  // A heist's stray waiting for an answer (§11.5): found by the first of
  // the heist tokens the one-in-eight roll finds one for.
  for (let i = 0; !t.service.home.findStray(x.account, `privacy-${i}`, ["stillness"], t.clock.now); i++);

  const n = t.service.notifications;
  // Settings no player starts with, so clearing them is seen.
  n.set(x.account, { pushToken: "device-x", reminder: 12 * 60, timeZone: "UTC", nightQuiet: false },
        { session: xSession });                        // the session that registered it (SEC-37)
  t.service.db.prepare(`UPDATE accounts SET equipped = '{"banner":"x"}' WHERE id = ?`).run(x.account);
  t.clock.now = Date.UTC(2026, 8, 25, 12, 5);
  await n.deliver(() => {});
  t.clock.now += 60 * 1000;
  raid(y.account, xBundle, openPlan());                // waiting: the night is not the issue, the tick is
  t.service.telemetry.record(x.account, "worth", { rating: 4 }, t.clock.now);
  // The device's sessions (G29), which first_seen is kept from.
  for (const p of [x.account, y.account]) t.service.telemetry.batch(p, [{ kind: "session_start", data: {} }]);
  n.set(x.account, { timeZone: "Europe/Berlin" });
  t.service.auth.link(x.account, "gc:x", "gp:x");     // the same account on Android (auth.mjs)
  return { t, x: x.account, y: y.account, xBundle, yBundle, held, mine, theirs, w };
}

/** Rows of `table` whose `column` names `account`, as the column says it does. */
function naming(db, table, column, names, account, pseudonym) {
  const where = {
    account: `${column} = ?`,
    "account-realm": `(${column} = ? OR substr(${column}, 1, ${account.length + 1}) = '${account}/')`,
    pseudonym: `${column} = ?`,
  }[names];
  return db.prepare(`SELECT COUNT(*) AS n FROM ${table} WHERE ${where}`)
    .get(names === "pseudonym" ? pseudonym : account).n;
}

for (const reason of ["requested", "under-13"]) {
  test(`deleting an account ${reason === "under-13" ? "because its player is under 13" : "at the player's request"} does what privacy.json says, table by table (20.12, 20.11)`, async () => {
    const s = await busy();
    const { t, x } = s;
    const db = t.service.db;
    const who = t.service.telemetry.pseudonym(x);
    // Each table that holds rows naming X holds some before, so the checks
    // below are not passed by a table that was empty anyway.
    const before = {};
    for (const [table, d] of Object.entries(doc.tables)) {
      for (const [c, col] of Object.entries(d.columns)) {
        if (col.names) before[`${table}.${c}`] = naming(db, table, c, col.names, x, who);
      }
    }
    // What is erased must have been there to erase: every table the
    // declaration says loses X's rows holds some before (the pair's other
    // column aside).
    const young = reason === "under-13";
    const effective = (d) => (d.deletion === "erased-under-13" ? (young ? "erased" : "severed") : d.deletion);
    const empty = Object.entries(doc.tables).flatMap(([table, d]) => Object.entries(d.columns)
      .filter(([, col]) => col.names && (effective(d) === "erased" || (young && col.deletion_under_13)))
      .map(([c]) => `${table}.${c}`)).filter((k) => before[k] === 0);
    assert.deepEqual(empty, [before["friends.a"] ? "friends.b" : "friends.a"], "the scenario touches every table erased");
    // An under-13 player's leases never played go (§24.13: they reserved nothing).
    const unplayed = db.prepare(
      "SELECT COUNT(*) AS n FROM leases WHERE attacker = ? AND token NOT IN (SELECT token FROM heists)").get(x).n;
    assert.equal(unplayed, 1);
    const row = db.prepare("SELECT * FROM accounts WHERE id = ?").get(x);
    const defaults = Object.fromEntries(db.prepare("PRAGMA table_info(accounts)").all()
      .map((c) => [c.name, c.dflt_value === null ? null : JSON.parse(c.dflt_value.replace(/^'(.*)'$/, '"$1"'))]));
    // Every setting a deletion clears was set, so its clearing is seen (a
    // ban's are the ban test's).
    for (const [c, col] of Object.entries(doc.tables.accounts.columns)) {
      if (col.deletion === "cleared" && !c.startsWith("banned_")) assert.notDeepEqual(row[c], defaults[c], `accounts.${c} was set`);
    }
    // Two lists a band, the current and the one before, both naming X: an
    // under-13 deletion leaves neither.
    t.service.targetLists();
    t.clock.now += 1000;
    const moved = t.build.exampleIsland(false);
    moved[5] = 9;
    t.service.publish(s.y, moved);
    t.service.targetLists();
    const lists = db.prepare("SELECT list, previous FROM target_lists").all().flatMap((r) => [r.list, r.previous]);
    const naming_x = lists.filter((h) => JSON.parse(new TextDecoder().decode(t.service.bundle(h)))
      .candidates.some((c) => c.owner === x));
    assert.equal(naming_x.length, 2, "the current list and the one before both name X");

    deleteAccount(t.service, x, reason);

    for (const [table, d] of Object.entries(doc.tables)) {
      const deletion = effective(d);
      for (const [c, col] of Object.entries(d.columns)) {
        if (!col.names) continue;
        const left = naming(db, table, c, col.names, x, who);
        const cleared = young && col.deletion_under_13 === "cleared";
        if (deletion === "erased" || cleared) assert.equal(left, 0, `${table}.${c} is ${cleared ? "cleared" : "erased"}`);
        else if (young && col.deletion_under_13 === "unplayed") assert.equal(left, before[`${table}.${c}`] - unplayed, `${table}.${c}: the unplayed go`);
        else assert.equal(left, before[`${table}.${c}`], `${table}.${c} is ${deletion}, as it was`);
      }
    }
    const after = db.prepare("SELECT * FROM accounts WHERE id = ?").get(x);
    for (const [c, col] of Object.entries(doc.tables.accounts.columns)) {
      if (col.deletion === "cleared") assert.equal(after[c], defaults[c], `accounts.${c} is cleared`);
      else if (col.deletion === "replaced") assert.equal(after[c], `deleted:${x}`, `accounts.${c} is replaced`);
      else if (!["deleted_at", "deleted_reason"].includes(c)) assert.deepEqual(after[c], row[c], `accounts.${c} is kept`);
    }
    // The files: an under-13 player's replays and their own island's bytes
    // go; bytes another player also published stay; no target list names them.
    const played = db.prepare("SELECT log_hash FROM heists WHERE attacker = ?").all(x);
    assert.ok(played.length > 0);
    for (const h of played) assert.equal(t.service.replays.get(h.log_hash) === null, young, "the replays they played");
    assert.equal(t.service.bundle(s.xBundle) === null, young, "their own island's bytes");
    assert.notEqual(t.service.bundle(s.mine.bundle), null, "bytes another player's Workshop island also is");
    if (young) {
      for (const h of naming_x) assert.equal(t.service.bundle(h), null, "a list that named them is deleted");
      assert.deepEqual(db.prepare("SELECT * FROM erasures").all(), [], "and nothing is left to erase");
      for (const r of db.prepare("SELECT list, previous FROM target_lists").all()) {
        assert.equal(r.previous, null);
        const list = JSON.parse(new TextDecoder().decode(t.service.bundle(r.list)));
        assert.ok(list.candidates.every((c) => c.owner !== x));
      }
      // A raid leased on their island before it went is refused, not crashed.
      const lease = db.prepare("SELECT * FROM leases WHERE attacker = ? AND bundle = ? AND token IN (SELECT token FROM heists) LIMIT 1")
        .get(s.y, s.xBundle);
      assert.ok(lease);
    }
    assert.notEqual(t.service.session("gc:x").account, x, "signing in again starts afresh");
  });
}

test("an open raid on an under-13 player's erased island is refused as withdrawn, not crashed (20.11)", async () => {
  const s = await busy();
  const { t } = s;
  const lease = t.service.lease(s.y, s.xBundle);
  const replay = play(t, lease, { plan: openPlan() });
  deleteAccount(t.service, s.x, "under-13");
  const out = t.service.submit(s.y, lease.token, replay);
  assert.deepEqual([out.validated, out.reason], [false, "island_withdrawn"]);
});

test("what privacy.json keeps for a number of days is deleted by a job the server runs daily (20.5)", async () => {
  const main = readFileSync(new URL("../src/main.mjs", import.meta.url), "utf8");
  const s = await busy();
  const jobs = new Set();
  for (const [table, d] of Object.entries(doc.tables)) {
    for (const k of [d.keep, ...Object.values(d.columns).map((c) => c.keep)]) {
      if (k?.days === undefined) continue;
      const path = k.by.split(".");
      const owner = path.length === 1 ? s.t.service : s.t.service[path[0]];
      assert.equal(typeof owner?.[path.at(-1)], "function", `${table}: ${k.by} is a function`);
      assert.match(main, new RegExp(`service\\.${k.by.replace(".", "\\.")}\\(`), `${k.by} is run by main.mjs`);
      jobs.add(k.by);
    }
  }
  assert.deepEqual([...jobs].sort(), ["auth.expire", "expireLapsed", "expireReplays", "friends.expire", "notifications.expire", "telemetry.compact"]);
});

test("a sent notification is kept a week, and one waiting is not dropped (14.6, 20.5)", async () => {
  const { t, x } = await busy();
  const n = t.service.notifications;
  const count = (sent) => t.service.db.prepare(
    `SELECT COUNT(*) AS n FROM notifications WHERE account = ? AND sent_at IS ${sent ? "NOT" : ""} NULL`).get(x).n;
  assert.deepEqual([count(true), count(false)], [1, 1], "a reminder sent with the day's raid in it (G34), a raid waiting");
  const sentAt = t.service.db.prepare("SELECT MAX(sent_at) AS at FROM notifications WHERE account = ?").get(x).at;
  assert.equal(n.expire(sentAt + SENT_KEEP_DAYS * DAY), 0);
  const sent = t.service.db.prepare("SELECT COUNT(*) AS n FROM notifications WHERE sent_at <= ?").get(sentAt).n;
  assert.equal(n.expire(sentAt + SENT_KEEP_DAYS * DAY + 1), sent, "every player's, the raider's too");
  assert.deepEqual([count(true), count(false)], [0, 1]);
});

test("a deleted or banned player is owed no notification of a raid leased before (13, 20.12)", async () => {
  for (const end of ["deleted", "banned"]) {
    const { t, x, y, xBundle } = await busy();
    const lease = t.service.lease(y, xBundle);
    const replay = play(t, lease, { plan: openPlan() });
    const raided = () => t.service.db.prepare("SELECT id, data FROM notifications WHERE account = ? AND kind = 'raided'")
      .all(x).map((r) => ({ ...r }));
    if (end === "deleted") deleteAccount(t.service, x);
    else new Workshop(t.service).ban(x, "offensive");
    const was = raided();
    t.service.submit(y, lease.token, replay);
    assert.deepEqual(raided(), was, `${end}: nothing added`);
  }
});

test("a raid leased on a player before their deletion settles for the raider and records nothing of them (20.12)", async () => {
  // X's island is bytes Y's is too, so an under-13 deletion keeps them.
  const { t, x, y, xBundle } = await busy();
  const z = t.service.session("gc:z").account;
  t.service.publish(y, t.service.bundle(xBundle));
  const lease = t.service.lease(z, xBundle, x);
  const replay = play(t, lease, { plan: openPlan() });
  deleteAccount(t.service, x, "under-13");
  assert.notEqual(t.service.bundle(xBundle), null, "another player's island is these bytes");
  const out = t.service.submit(z, lease.token, replay);
  assert.equal(out.validated, true, "the raider played it honestly");
  assert.deepEqual([out.rating, out.renown.defender, out.stars.defender], [null, 0, 0]);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM ratings WHERE key = ? OR key LIKE ?")
    .get(x, `${x}/%`).n, 0, "no rating of them comes back");
});

test("an under-13 deletion keeps bytes another player's island, link or raid still needs (20.11)", async () => {
  // X published first, so X owns the snapshot; C holds the same bytes, R
  // leased them as C's, and C moved on before X was deleted.
  const { t, x, xBundle } = await busy();
  const c = t.service.session("gc:c").account;
  const r = t.service.session("gc:r").account;
  established(t, c);
  t.service.publish(c, t.service.bundle(xBundle));
  const lease = t.service.lease(r, xBundle, c);
  const replay = play(t, lease, { plan: openPlan() });
  const away = t.build.exampleIsland(false);
  away[5] = 8;
  t.service.publish(c, away);
  deleteAccount(t.service, x, "under-13");
  assert.notEqual(t.service.bundle(xBundle), null);
  assert.equal(t.service.submit(r, lease.token, replay).validated, true);
});

test("an under-13 deletion keeps bytes another player's challenge link still offers (17.6, 20.11)", async () => {
  const { t, x, xBundle } = await busy();
  const d = t.service.session("gc:d").account;
  t.service.publish(d, t.service.bundle(xBundle));
  const link = t.service.friends.challenge(d);
  const away = t.build.exampleIsland(false);
  away[5] = 8;
  t.service.publish(d, away);
  deleteAccount(t.service, x, "under-13");
  assert.equal(link.bundle, xBundle);
  assert.notEqual(t.service.bundle(xBundle), null);
});

test("an under-13 deletion stopped between its commit and its files is finished at the next start (20.11, 20.12)", async () => {
  const { t, x, xBundle } = await busy();
  const replays = t.service.db.prepare("SELECT log_hash FROM heists WHERE attacker = ?").all(x).map((h) => h.log_hash);
  const remove = t.service.store.delete;
  t.service.store.delete = () => { throw new Error("the process stops"); };
  assert.throws(() => deleteAccount(t.service, x, "under-13"), /the process stops/);
  t.service.store.delete = remove;
  assert.ok(t.service.db.prepare("SELECT COUNT(*) AS n FROM erasures").get().n > 0, "what is left is written down");
  assert.equal(reapplyDeletions(t.service), 0, "the account itself is deleted");
  assert.equal(t.service.bundle(xBundle), null);
  for (const h of replays) assert.equal(t.service.replays.get(h), null);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM erasures").get().n, 0);
});

test("used and lapsed invites and challenge links are deleted; a link played before still counts as played (17.6, 20.5)", async () => {
  const { t, x, y } = await busy();
  const f = t.service.friends;
  const count = (table) => t.service.db.prepare(`SELECT COUNT(*) AS n FROM ${table} WHERE account = ?`).get(x).n;
  assert.deepEqual([count("friend_invites"), count("challenges")], [2, 1]);
  assert.deepEqual(f.expire(), { invites: 1, challenges: 0 }, "the used invite goes at once");
  t.clock.now += 7 * DAY + 1;
  assert.deepEqual(f.expire(), { invites: 1, challenges: 1 });
  assert.deepEqual([count("friend_invites"), count("challenges")], [0, 0]);
  assert.deepEqual(f.list(y).map((r) => r.account), [x], "the friendship itself stays");
});

test("a target list is kept while current and one list after, then deleted; one gone back to stays (20.5)", async () => {
  const { t, x, y } = await busy();
  const band = () => t.service.db.prepare("SELECT list, previous FROM target_lists").all()
    .find((r) => JSON.parse(new TextDecoder().decode(t.service.bundle(r.list))).candidates.some((c) => c.owner === y));
  const publish = (level) => {
    t.clock.now += 1000;
    const island = t.build.exampleIsland(false);
    island[5] = level;
    t.service.publish(y, island);
    t.service.targetLists();
    return band();
  };
  const a = publish(5);
  const b = publish(6);
  assert.equal(b.previous, a.list);
  const c = publish(4);
  assert.equal(c.previous, b.list);
  assert.equal(t.service.bundle(a.list), null, "two lists back is deleted");
  assert.notEqual(t.service.bundle(b.list), null, "the one before is still served");
  // Back to the bytes of two lists ago: that list is current again, not deleted.
  const again = publish(6);
  assert.equal(again.list, b.list);
  assert.notEqual(t.service.bundle(again.list), null);
  assert.notEqual(t.service.bundle(again.previous), null);
  // A band every island leaves keeps no list, and neither of its files.
  const bands = t.service.db.prepare("SELECT band, list, previous FROM target_lists").all();
  t.service.db.prepare("DELETE FROM islands").run();
  assert.deepEqual(t.service.targetLists(), {});
  for (const r of bands) {
    assert.equal(t.service.bundle(r.list), null);
    if (r.previous) assert.equal(t.service.bundle(r.previous), null);
  }
  assert.ok(x);
});

test("a superseded list is deleted one rebuild later though its band has not changed, and lists are cached no longer (G38)", async () => {
  const { t, y } = await busy();
  const band = () => t.service.db.prepare("SELECT list, previous FROM target_lists").all()
    .find((r) => JSON.parse(new TextDecoder().decode(t.service.bundle(r.list))).candidates.some((c) => c.owner === y));
  t.service.targetLists();
  const island = t.build.exampleIsland(false);
  island[5] = 6;
  t.service.publish(y, island);
  t.service.targetLists();
  const was = band();
  assert.notEqual(was.previous, null);
  const res = await t.handle(new Request(`https://edge.example/v1/bundles/${was.list}`));
  assert.equal(res.headers.get("cache-control"), `public, max-age=${TARGET_LISTS_MS / 1000}`);
  t.clock.now += TARGET_LISTS_MS - 1;
  t.service.targetLists();
  assert.notEqual(t.service.bundle(was.previous), null, "within the hour, still served");
  t.clock.now += 1;
  t.service.targetLists();
  assert.deepEqual([band().list, band().previous], [was.list, null], "the band is unchanged");
  assert.equal(t.service.bundle(was.previous), null, "an hour on, deleted");
  const islandRes = await t.handle(new Request(`https://edge.example/v1/bundles/${t.service.db.prepare(
    "SELECT bundle FROM islands WHERE owner = ?").get(y).bundle}`));
  assert.equal(islandRes.headers.get("cache-control"), "public, max-age=31536000, immutable", "an island, a year");
});

test("an intent that lapsed unredeemed and a lease that expired unplayed go a week after they close (G38)", async () => {
  const { t, x, y, xBundle } = await busy();
  const db = t.service.db;
  t.service.verifyReceipt = (store, receipt) => ({ transaction: receipt, product: "premium.1", intent: receipt });
  const lapsed = t.service.shop.intent(x, "premium.1").intent;
  const redeemed = t.service.shop.intent(x, "premium.1").intent;
  t.service.shop.redeem(x, "app-store", redeemed);
  const open = t.service.lease(y, xBundle).token;
  const played = db.prepare("SELECT COUNT(*) AS n FROM leases WHERE token IN (SELECT token FROM heists)").get().n;
  const start = t.clock.now;
  t.clock.now = start + LEASE_MS + CLOSED_KEEP_DAYS * DAY - 1;
  // busy()'s held lease, issued a day sooner, has gone a week past its end.
  assert.deepEqual(t.service.expireLapsed(), { intents: 1, leases: 1, plays: 0 }, "the intent lapsed sooner");
  assert.equal(db.prepare("SELECT 1 FROM purchase_intents WHERE id = ?").get(lapsed), undefined);
  assert.ok(db.prepare("SELECT 1 FROM purchase_intents WHERE id = ?").get(redeemed), "a redeemed one is a record");
  assert.ok(db.prepare("SELECT 1 FROM leases WHERE token = ?").get(open), "a week less a moment after it expired");
  t.clock.now += 2;
  assert.deepEqual(t.service.expireLapsed(), { intents: 0, leases: 1, plays: 0 });
  assert.equal(db.prepare("SELECT 1 FROM leases WHERE token = ?").get(open), undefined);
  assert.equal(db.prepare("SELECT COUNT(*) AS n FROM leases WHERE token IN (SELECT token FROM heists)").get().n, played,
               "a played lease is a record");
  assert.deepEqual(t.service.expireLapsed(), { intents: 0, leases: 0, plays: 0 }, "once");
  // A receipt that comes after its intent went is honoured as one with none.
  const out = t.service.shop.redeem(x, "app-store", lapsed);
  assert.equal(out.product, "premium.1");
  assert.equal(db.prepare("SELECT intent FROM purchases WHERE txn = ?").get(lapsed).intent, null);
  assert.ok(INTENT_MS < DAY);
});

test("a lease closed unplayed when its target was leased again goes too (G38)", async () => {
  const { t, y, xBundle } = await busy();
  const db = t.service.db;
  const first = t.service.lease(y, xBundle).token;
  t.clock.now += LEASE_MS + 1;
  const second = t.service.lease(y, xBundle).token;
  assert.notEqual(first, second);
  assert.equal(db.prepare("SELECT 1 FROM heists WHERE token = ?").get(first), undefined, "closed, never played");
  assert.equal(t.service.lease(y, xBundle).token, second, "and the new one is the one held");
  t.clock.now += CLOSED_KEEP_DAYS * DAY;
  t.service.expireLapsed();
  assert.equal(db.prepare("SELECT 1 FROM leases WHERE token = ?").get(first), undefined);
});

test("a list no band names — left by a crash, a failed run, a restore or an older server — is swept at start (20.5)", async () => {
  const { t } = await busy();
  t.service.targetLists();
  const stray = t.service.store.put(new TextEncoder().encode(JSON.stringify({ band: "realm-level-1", candidates: [] })));
  const named = t.service.targets();
  assert.equal(t.service.sweepLists(), 1);
  assert.equal(t.service.bundle(stray), null);
  for (const list of Object.values(named)) assert.notEqual(t.service.bundle(list), null, "a named list stays");
  const islands = t.service.db.prepare("SELECT bundle FROM snapshots").all();
  for (const i of islands) assert.notEqual(t.service.bundle(i.bundle), null, "an island's bytes are never a list");
});

test("a ban keeps the identity alone: a banned player's deletion severs the rest, and the ban holds (20.12)", async () => {
  const { t, x, y } = await busy();
  const invite = t.service.friends.invite(x).invite;
  new Workshop(t.service).ban(x, "offensive");
  assert.deepEqual(t.service.friends.list(y), [], "a ban ends friendships");
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM friend_invites WHERE account = ?").get(x).n, 0,
               "and its invites");
  refusal(() => t.service.friends.accept(t.service.session("gc:z").account, invite), "no_such_invite");
  // An invite a banned inviter somehow still has is refused too.
  const w = t.service.session("gc:w").account;
  const open_ = t.service.friends.invite(w).invite;
  t.service.db.prepare("UPDATE accounts SET banned_at = 1 WHERE id = ?").run(w);
  refusal(() => t.service.friends.accept(y, open_), "no_such_invite");
  deleteAccount(t.service, x);
  const row = t.service.db.prepare("SELECT platform_identity, banned_at, banned_reason FROM accounts WHERE id = ?").get(x);
  assert.deepEqual({ ...row }, { platform_identity: `deleted:${x}`, banned_at: null, banned_reason: null },
                   "the account's records lead to no one, and keep no ban time to match back by");
  const ban = t.service.db.prepare("SELECT identity, banned_at, reason FROM bans").get();
  assert.deepEqual([ban.identity, ban.reason, ban.banned_at % DAY], ["gc:x", "offensive", 0], "to the day");
  refusal(() => t.service.session("gc:x"), "banned");
});

test("a ban made before the bans table holds, and its deleted account is severed, on deletion and on upgrade (20.12)", async () => {
  // A ban as the server wrote it before: on the account alone.
  const { t, x } = await busy();
  t.service.db.prepare("UPDATE accounts SET banned_at = ?, banned_reason = 'offensive' WHERE id = ?").run(t.clock.now, x);
  deleteAccount(t.service, x);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM bans WHERE identity = 'gc:x'").get().n, 1);
  refusal(() => t.service.session("gc:x"), "banned");
  // A database whose banned account was deleted the old way, opened by this server.
  const dir = mkdtempSync(join(tmpdir(), "ruleborn-"));
  const file = join(dir, "old.sqlite");
  const old = await busy();
  old.t.service.db.prepare("UPDATE accounts SET banned_at = ?, banned_reason = 'offensive', deleted_at = ? WHERE id = ?")
    .run(old.t.clock.now, old.t.clock.now, old.x);
  old.t.service.db.exec(`VACUUM INTO '${file}'`);
  const db = open(file);
  const a = db.prepare("SELECT platform_identity, banned_at FROM accounts WHERE id = ?").get(old.x);
  assert.deepEqual({ ...a }, { platform_identity: `deleted:${old.x}`, banned_at: null });
  assert.equal(db.prepare("SELECT COUNT(*) AS n FROM bans WHERE identity = 'gc:x'").get().n, 1);
  assert.equal(db.prepare("SELECT COUNT(*) AS n FROM friends WHERE a = ? OR b = ?").get(old.x, old.x).n, 1,
               "a deleted account's friends went at its deletion, not here: only a live ban's go");
});

for (const reason of ["requested", "under-13"]) {
  test(`a deletion ${reason === "under-13" ? "for being under 13 " : ""}is journalled outside the database, and made again on a database restored from before it (20.12, F50)`, async () => {
    const dir = mkdtempSync(join(tmpdir(), "ruleborn-"));
    const bucket = join(dir, "deletions");
    const { t, x, y } = await busy();
    const journal = new Journal(new Store(bucket));
    t.service.deletions = journal;
    const backup = join(dir, "backup.sqlite");
    t.service.db.exec(`VACUUM INTO '${backup}'`);
    deleteAccount(t.service, x, reason);
    deleteAccount(t.service, x, reason);
    assert.deepEqual(journal.entries().map((e) => [e.account, e.reason]), [[x, reason]], "once");
    // An object that is not an entry costs only itself.
    new Store(bucket).put(new TextEncoder().encode('{"account": "cut sho'));
    journal.append({ account: y, reason: "requested", withdraw: false, at: t.clock.now });
    assert.deepEqual(journal.entries().map((e) => e.account), [x, y]);
    const written = new Store(bucket).keys().sort();
    // The restore: yesterday's database, today's journal.
    const restored = server({ db: open(backup), deletions: new Journal(new Store(bucket)) });
    restored.clock.now = t.clock.now;
    const db = restored.service.db;
    assert.equal(db.prepare("SELECT platform_identity FROM accounts WHERE id = ?").get(x).platform_identity, "gc:x");
    assert.equal(reapplyDeletions(restored.service), 2);
    assert.equal(reapplyDeletions(restored.service), 0, "once");
    assert.deepEqual(new Store(bucket).keys().sort(), written, "making a deletion again journals nothing");
    const row = db.prepare("SELECT platform_identity, deleted_reason FROM accounts WHERE id = ?").get(x);
    assert.deepEqual({ ...row }, { platform_identity: `deleted:${x}`, deleted_reason: reason });
    assert.equal(db.prepare("SELECT COUNT(*) AS n FROM notifications WHERE account = ?").get(x).n, 0);
    const erased = ["ratings", "workshop_plays"].map((table) => db.prepare(
      `SELECT COUNT(*) AS n FROM ${table} WHERE ${table === "ratings" ? "key" : "player"} = ?`).get(x).n);
    if (reason === "under-13") assert.deepEqual(erased, [0, 0], "and made again as far as the first time");
    else assert.ok(erased[1] > 0);
    assert.deepEqual(new Journal(new Store(join(dir, "empty"))).entries(), []);
  });
}

test("a start makes again only the journal's last 31 days: a restore reaches no further back (F50)", async () => {
  const { t, x, y } = await busy();
  const dir = mkdtempSync(join(tmpdir(), "ruleborn-"));
  const backup = join(dir, "backup.sqlite");
  t.service.db.exec(`VACUUM INTO '${backup}'`);
  const journal = new Journal();
  journal.append({ account: x, reason: "requested", withdraw: true, at: t.clock.now - REAPPLY_DAYS * DAY - 1 });
  journal.append({ account: y, reason: "requested", withdraw: true, at: t.clock.now - REAPPLY_DAYS * DAY });
  const restored = server({ db: open(backup), deletions: journal });
  restored.clock.now = t.clock.now;
  assert.equal(REAPPLY_DAYS, 31);
  // The edge handler's first request makes them again, as main.mjs does.
  await restored.handle(new Request("https://edge.example/v1/era"));
  const gone = (a) => Boolean(restored.service.db.prepare("SELECT deleted_at FROM accounts WHERE id = ?").get(a).deleted_at);
  assert.deepEqual([gone(x), gone(y)], [false, true]);
  const withdrawn = restored.service.db.prepare(
    "SELECT COUNT(*) AS n FROM workshop_items WHERE creator = ? AND withdrawn_at IS NOT NULL").get(y).n;
  assert.ok(withdrawn > 0, "made again as it was asked for: islands withdrawn");
});

test("an account is held to the most protective age band until the device's age check answers (20.1, 20.2)", async () => {
  const t = server({ firstBand: undefined });
  const me = t.service.session("gc:new");
  const band = () => t.service.db.prepare("SELECT age_band FROM accounts WHERE id = ?").get(me.account).age_band;
  assert.equal(band(), "13-15");
  const res = await t.handle(new Request("https://edge.example/v1/age", {
    method: "PUT", headers: { authorization: `Bearer ${me.token}`, "content-type": "application/json" },
    body: JSON.stringify({ band: "18+" }) }));
  assert.equal(res.status, 200);
  assert.equal(band(), "18+");
  assert.equal(res.headers.get("strict-transport-security"), "max-age=31536000", "and every answer asks for HTTPS");
});

test("the server's own log names a route, never an id in its path, a token or a heist (20.5)", () => {
  assert.equal(routeOf("/v1/heists/abc123/replay?token=xyz"), "v1/heists");
  assert.equal(routeOf("/v1/age"), "v1/age");
  assert.equal(routeOf(undefined), "");
  const main = readFileSync(new URL("../src/main.mjs", import.meta.url), "utf8");
  // Each log call, whole: none carries a raw path, a token or a message's heists.
  const calls = [...main.matchAll(/console\.(log|error)\(/g)].map((m) => {
    let depth = 0;
    for (let i = m.index + m[0].length - 1; i < main.length; i++) {
      depth += main[i] === "(" ? 1 : main[i] === ")" ? -1 : 0;
      if (depth === 0) return main.slice(m.index, i + 1);
    }
    return main.slice(m.index);
  });
  assert.ok(calls.length >= 4);
  for (const call of calls) {
    assert.doesNotMatch(call.replace("routeOf(req.url)", ""), /req\.url|token|JSON\.stringify\(message/, call);
  }
  assert.match(main, /console\.error\(`\$\{req\.method\} \/\$\{routeOf\(req\.url\)\}:`/);
});

test("the server starts by making journalled deletions again and sweeping stray lists, before it listens, with a kept secret (20.12)", () => {
  const main = readFileSync(new URL("../src/main.mjs", import.meta.url), "utf8");
  const at = (s) => main.indexOf(s);
  assert.ok(at("reapplyDeletions(service)") > 0 && at("reapplyDeletions(service)") < at(".listen("));
  assert.ok(at("service.sweepLists()") > at("reapplyDeletions(service)") && at("service.sweepLists()") < at(".listen("));
  assert.match(main, /secret: secret\(\)/);
  assert.match(main, /join\(data, "secret"\)/, "a secret made once is kept in the data directory");
  assert.match(main, /key\.length < SECRET_MIN/, "and a short one refused");
});
