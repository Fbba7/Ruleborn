// What the server stores, as server/privacy.json declares it (§20.5, §20.11,
// §20.12): every column declared, and each deletion and time limit it states
// done — against the real simulation build.

import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, writeFileSync, appendFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { Journal, deleteAccount, reapplyDeletions } from "../src/accounts.mjs";
import { open } from "../src/db.mjs";
import { SENT_KEEP_DAYS } from "../src/notifications.mjs";
import { DECLARATIONS, load, problems, render, schema } from "../src/privacy.mjs";
import { Refused, clockTicks } from "../src/service.mjs";
import { Social } from "../src/social.mjs";
import { Workshop } from "../src/workshop.mjs";
import { established, openPlan, play, server } from "./setup.mjs";

const refusal = (fn, reason) => assert.throws(fn, (e) => e instanceof Refused && e.reason === reason);
const DAY = 24 * 60 * 60 * 1000;
const doc = load();

test("every column the server stores is declared, with the stores' words for it, and nothing else is (20.5)", () => {
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
function busy() {
  const t = server();
  const x = t.service.session("gc:x");
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
  raid(x.account, yBundle, null);
  const held = t.service.lease(x.account, yBundle);

  const w = new Workshop(t.service);
  const shared = t.build.exampleIsland(true);
  const cleared = t.build.record(shared, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  const mine = w.publish(x.account, shared, cleared, { adjective: 0, noun: 0 });
  const theirs = w.publish(y.account, shared, cleared, { adjective: 1, noun: 1 });
  const p = w.play(x.account, theirs.id);
  w.submitPlay(x.account, p.token, t.build.record(t.service.bundle(p.bundle),
    { seed: BigInt(p.seed), ticks: p.ticks, crew: 3, commands: openPlan() }));
  w.rate(x.account, theirs.id, { fun: 5, cleverness: 4, fairness: 3 });
  w.remix(x.account, theirs.id);
  w.report(x.account, theirs.id, "other");

  t.service.db.prepare("UPDATE accounts SET keeper_level = 6").run();
  const social = new Social(t.service);
  social.join(y.account, social.found(x.account, { adjective: 1, noun: 1 }).id);
  social.startCrew(x.account);
  t.service.friends.accept(y.account, t.service.friends.invite(x.account).invite);
  t.service.friends.invite(x.account);
  t.service.friends.challenge(x.account);

  const n = t.service.notifications;
  n.set(x.account, { pushToken: "device-x", reminder: 12 * 60 });
  t.clock.now = Date.UTC(2026, 8, 25, 12, 5);
  n.deliver(() => {});
  t.clock.now += 60 * 1000;
  raid(y.account, xBundle, openPlan());                // waiting: the night is not the issue, the tick is
  t.service.telemetry.record(x.account, "worth", { rating: 4 }, t.clock.now);
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
  test(`deleting an account ${reason === "under-13" ? "because its player is under 13" : "at the player's request"} does what privacy.json says, table by table (20.12, 20.11)`, () => {
    const s = busy();
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
      "SELECT COUNT(*) AS n FROM leases WHERE attacker = ? AND state = 'open' AND token NOT IN (SELECT token FROM heists)").get(x).n;
    assert.equal(unplayed, 1);
    const row = db.prepare("SELECT * FROM accounts WHERE id = ?").get(x);
    const defaults = Object.fromEntries(db.prepare("PRAGMA table_info(accounts)").all()
      .map((c) => [c.name, c.dflt_value === null ? null : JSON.parse(c.dflt_value.replace(/^'(.*)'$/, '"$1"'))]));

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
      for (const r of db.prepare("SELECT list, previous FROM target_lists").all()) {
        assert.equal(r.previous, null);
        const list = JSON.parse(new TextDecoder().decode(t.service.bundle(r.list)));
        assert.ok(list.candidates.every((c) => c.owner !== x));
      }
      // A raid leased on their island before it went is refused, not crashed.
      const lease = db.prepare("SELECT * FROM leases WHERE attacker = ? AND bundle = ? AND state = 'settled' LIMIT 1")
        .get(s.y, s.xBundle);
      assert.ok(lease);
    }
    assert.notEqual(t.service.session("gc:x").account, x, "signing in again starts afresh");
  });
}

test("an open raid on an under-13 player's erased island is refused as withdrawn, not crashed (20.11)", () => {
  const s = busy();
  const { t } = s;
  const lease = t.service.lease(s.y, s.xBundle);
  const replay = play(t, lease, { plan: openPlan() });
  deleteAccount(t.service, s.x, "under-13");
  const out = t.service.submit(s.y, lease.token, replay);
  assert.deepEqual([out.validated, out.reason], [false, "island_withdrawn"]);
});

test("what privacy.json keeps for a number of days is deleted by a job the server runs daily (20.5)", () => {
  const main = readFileSync(new URL("../src/main.mjs", import.meta.url), "utf8");
  const s = busy();
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
  assert.deepEqual([...jobs].sort(), ["expireReplays", "friends.expire", "notifications.expire", "telemetry.compact"]);
});

test("a sent notification is kept a week, and one waiting is not dropped (14.6, 20.5)", () => {
  const { t, x } = busy();
  const n = t.service.notifications;
  const count = (sent) => t.service.db.prepare(
    `SELECT COUNT(*) AS n FROM notifications WHERE account = ? AND sent_at IS ${sent ? "NOT" : ""} NULL`).get(x).n;
  assert.deepEqual([count(true), count(false)], [2, 1], "a reminder and a raid sent, a raid waiting");
  const sentAt = t.service.db.prepare("SELECT MAX(sent_at) AS at FROM notifications WHERE account = ?").get(x).at;
  assert.equal(n.expire(sentAt + SENT_KEEP_DAYS * DAY), 0);
  const sent = t.service.db.prepare("SELECT COUNT(*) AS n FROM notifications WHERE sent_at <= ?").get(sentAt).n;
  assert.equal(n.expire(sentAt + SENT_KEEP_DAYS * DAY + 1), sent, "every player's, the raider's too");
  assert.deepEqual([count(true), count(false)], [0, 1]);
});

test("a deleted or banned player is owed no notification of a raid leased before (13, 20.12)", () => {
  const { t, x, y, xBundle } = busy();
  const lease = t.service.lease(y, xBundle);
  const replay = play(t, lease, { plan: openPlan() });
  deleteAccount(t.service, x);
  t.service.submit(y, lease.token, replay);
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM notifications WHERE account = ?").get(x).n, 0);
});

test("used and lapsed invites and challenge links are deleted; a link played before still counts as played (17.6, 20.5)", () => {
  const { t, x, y } = busy();
  const f = t.service.friends;
  const count = (table) => t.service.db.prepare(`SELECT COUNT(*) AS n FROM ${table} WHERE account = ?`).get(x).n;
  assert.deepEqual([count("friend_invites"), count("challenges")], [2, 1]);
  assert.deepEqual(f.expire(), { invites: 1, challenges: 0 }, "the used invite goes at once");
  t.clock.now += 7 * DAY + 1;
  assert.deepEqual(f.expire(), { invites: 1, challenges: 1 });
  assert.deepEqual([count("friend_invites"), count("challenges")], [0, 0]);
  assert.deepEqual(f.list(y).map((r) => r.account), [x], "the friendship itself stays");
});

test("a target list is kept while current and one list after, then deleted (20.5)", () => {
  const { t, y } = busy();
  const bands = () => t.service.db.prepare("SELECT band, list, previous FROM target_lists ORDER BY band").all();
  t.service.targetLists();
  const first = bands();
  assert.ok(first.length > 0);
  // Each republish changes the band's list: the one before stays, the one before that goes.
  const republish = (i) => {
    t.clock.now += 1000;
    const island = t.build.exampleIsland(false);
    island[5] = 5 + i;
    t.service.publish(y, island);
    return t.service.targetLists();
  };
  republish(0);
  const second = bands();
  republish(1);
  const third = bands();
  for (const was of first) {
    const now = third.find((b) => b.band === was.band);
    if (!now || now.list === was.list) continue;
    const mid = second.find((b) => b.band === was.band);
    if (mid.list === was.list) continue;
    assert.equal(now.previous, mid.list);
    assert.equal(t.service.bundle(was.list), null, "two lists back is deleted");
    assert.notEqual(t.service.bundle(mid.list), null, "the one before is still served");
  }
});

test("a ban keeps the identity alone: a banned player's deletion severs the rest, and the ban holds (20.12)", () => {
  const { t, x, y } = busy();
  const invite = t.service.friends.invite(x).invite;
  new Workshop(t.service).ban(x, "offensive");
  assert.deepEqual(t.service.friends.list(y), [], "a ban ends friendships");
  refusal(() => t.service.friends.accept(t.service.session("gc:z").account, invite), "no_such_invite");
  deleteAccount(t.service, x);
  const row = t.service.db.prepare("SELECT platform_identity FROM accounts WHERE id = ?").get(x);
  assert.equal(row.platform_identity, `deleted:${x}`, "the account's records lead to no one");
  assert.deepEqual(t.service.db.prepare("SELECT identity, reason FROM bans").all().map((r) => ({ ...r })),
                   [{ identity: "gc:x", reason: "offensive" }]);
  refusal(() => t.service.session("gc:x"), "banned");
});

test("a deletion is journalled outside the database, and made again on a database restored from before it (20.12)", () => {
  const dir = mkdtempSync(join(tmpdir(), "ruleborn-"));
  const path = join(dir, "deletions.jsonl");
  const { t, x } = busy();
  const journal = new Journal(path);
  t.service.deletions = journal;
  const backup = join(dir, "backup.sqlite");
  t.service.db.exec(`VACUUM INTO '${backup}'`);
  deleteAccount(t.service, x);
  deleteAccount(t.service, x);
  assert.deepEqual(journal.entries().map((e) => [e.account, e.reason]), [[x, "requested"]], "once");
  appendFileSync(path, '{"account": "cut sho');                  // a crash mid-line
  // The restore: yesterday's database, today's journal.
  const restored = server({ db: open(backup), deletions: new Journal(path) });
  assert.equal(restored.service.db.prepare("SELECT platform_identity FROM accounts WHERE id = ?").get(x).platform_identity, "gc:x");
  assert.equal(reapplyDeletions(restored.service), 1);
  assert.equal(reapplyDeletions(restored.service), 0, "once");
  const row = restored.service.db.prepare("SELECT platform_identity, deleted_reason FROM accounts WHERE id = ?").get(x);
  assert.deepEqual({ ...row }, { platform_identity: `deleted:${x}`, deleted_reason: "requested" });
  assert.equal(restored.service.db.prepare("SELECT COUNT(*) AS n FROM notifications WHERE account = ?").get(x).n, 0);
  writeFileSync(path, "");
  assert.deepEqual(new Journal(path).entries(), []);
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

test("the server's own log names a route, never an id in its path (20.5)", () => {
  const main = readFileSync(new URL("../src/main.mjs", import.meta.url), "utf8");
  assert.doesNotMatch(main, /console\.(log|error)\([^)]*req\.url/);
});
