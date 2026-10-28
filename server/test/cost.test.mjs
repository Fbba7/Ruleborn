// What the database is asked to write and read for a heist (§24.1's budget,
// F47): each change here is a line on the bill, so each is held down by a
// test that fails when it comes back.

import assert from "node:assert/strict";
import { DatabaseSync } from "node:sqlite";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

import { open } from "../src/db.mjs";
import { billed } from "../load.mjs";
import { openPlan, play, twoPlayers } from "./setup.mjs";

/** A crew that loads and never leaves: foiled (as defence.test.mjs plays it). */
const greedy = () => openPlan().filter((c) => c.kind !== "Skiff" && c.tick < 62 * 30);

/** Every write statement `fn` runs, in order, by its first words. */
function writes(t, fn) {
  const db = t.service.db;
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

test("a heist's row is written once, after the rows it pays, and no table it pays is searched for it (F47)", () => {
  // The ledger's, Renown's and the stars' rows name the heist plainly: had
  // they a foreign key to it, the heist's row written after them would make
  // SQLite search each of those tables, every heist ever played, for the
  // rows it settles; written first, it was written twice, then marked.
  const t = twoPlayers();
  const db = t.service.db;
  for (const table of ["ledger", "renown", "season_stars"]) {
    assert.ok(!db.prepare(`PRAGMA foreign_key_list(${table})`).all().some((k) => k.table === "heists"), table);
  }
  const lease = t.service.lease(t.raider.account, t.bundle);
  const replay = play(t, lease, { plan: openPlan() });
  const order = writes(t, () => t.service.submit(t.raider.account, lease.token, replay));
  assert.deepEqual(order.filter((w) => w.endsWith(" heists")), ["INSERT heists"], order.join(", "));
  const at = order.indexOf("INSERT heists");
  for (const child of ["INSERT ledger", "INSERT renown", "INSERT season_stars"]) {
    assert.ok(order.indexOf(child) < at, `${child} after the heist: ${order.join(", ")}`);
  }
  // And the heist it settles is validated, with its outcome, once it is done.
  const row = db.prepare("SELECT validated, outcome FROM heists WHERE token = ?").get(lease.token);
  assert.equal(row.validated, 1);
  assert.equal(JSON.parse(row.outcome).verdict.grade, "clean");
});

test("a heist books one ledger row a player: the raider's fee, haul and fee returned in one, the defender's in one (F47)", () => {
  const t = twoPlayers();
  t.service.book(t.raider.account, "starlight", 50_000, "grant");
  const clean = t.service.lease(t.raider.account, t.bundle);
  const out = t.service.submit(t.raider.account, clean.token, play(t, clean, { plan: openPlan() }));
  const rows = t.service.db.prepare("SELECT account, starlight, essence, paid FROM ledger WHERE heist = ?")
    .all(clean.token).map((r) => ({ ...r }));
  assert.deepEqual(rows, [{ account: t.raider.account,
    starlight: -out.fee + out.haul.starlight + out.feeReturned, essence: out.haul.essence,
    paid: out.haul.starlight + out.haul.essence }]);
  t.clock.now += 2 * 24 * 60 * 60 * 1000;
  const foil = t.service.lease(t.raider.account, t.bundle);
  const foiled = t.service.submit(t.raider.account, foil.token, play(t, foil, { plan: greedy() }));
  assert.equal(foiled.verdict.grade, "foiled");
  const two = t.service.db.prepare("SELECT account, starlight, essence, paid FROM ledger WHERE heist = ? ORDER BY id")
    .all(foil.token).map((r) => ({ ...r }));
  assert.deepEqual(two.map((r) => r.account), [t.raider.account, t.defender.account]);
  assert.equal(two[1].starlight, foiled.fee + foiled.defence.starlight);
  assert.equal(two[1].paid, foiled.defence.starlight + foiled.defence.essence, "the share counts to the defender's caps");
});

test("settling a heist does not write its lease again: its heist row says it is settled (F47)", () => {
  const t = twoPlayers();
  const lease = t.service.lease(t.raider.account, t.bundle);
  const replay = play(t, lease, { plan: openPlan() });
  const order = writes(t, () => t.service.submit(t.raider.account, lease.token, replay));
  assert.ok(!order.some((w) => w.endsWith(" leases")), order.join(", "));
  // And the target can be leased again at once, as a new lease.
  assert.notEqual(t.service.lease(t.raider.account, t.bundle).token, lease.token);
});

test("finding the lease a player holds on a target reads its newest lease, however many they have played (F47)", () => {
  const t = twoPlayers();
  const db = t.service.db;
  const played = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, played.token, play(t, played, { plan: openPlan() }));
  // A long history on the one target, every lease of it played.
  const copy = (table, set) => {
    const cols = db.prepare(`PRAGMA table_info(${table})`).all().map((c) => c.name).filter((c) => !(c in set));
    return db.prepare(`INSERT INTO ${table} (${[...Object.keys(set), ...cols]})
      SELECT ${[...Object.keys(set).map((k) => `:${k}`), ...cols]} FROM ${table} WHERE token = :from`);
  };
  const lease = copy("leases", { token: 0, issued_at: 0, expires_at: 0 });
  const heist = copy("heists", { token: 0 });
  for (let i = 0; i < 300; i++) {
    lease.run({ token: `old${i}`, issued_at: i, expires_at: i + 1, from: played.token });
    heist.run({ token: `old${i}`, from: played.token });
  }
  const plan = db.prepare("EXPLAIN QUERY PLAN SELECT * FROM leases WHERE attacker = ? AND bundle = ? "
    + "ORDER BY issued_at DESC LIMIT 1").all("a", "b").map((r) => r.detail).join("; ");
  assert.match(plan, /leases_by_target/);
  assert.doesNotMatch(plan, /TEMP B-TREE/, "read newest first from the index, and stopped at one");
  const reads = [];
  const prepare = db.prepare;
  db.prepare = (sql) => { reads.push(sql); return prepare.call(db, sql); };
  try {
    const fresh = t.service.lease(t.raider.account, t.bundle);
    assert.notEqual(fresh.token, played.token);
    assert.equal(t.service.lease(t.raider.account, t.bundle).token, fresh.token, "and held, it is handed back");
  } finally {
    db.prepare = prepare;
  }
  assert.ok(!reads.some((sql) => /NOT EXISTS/.test(sql) && /FROM leases/.test(sql)), reads.join("\n"));
});

test("a player's sign-ins of a day are one event, and the day's other events join its row (F47, G29)", () => {
  const t = twoPlayers();
  const db = t.service.db;
  const who = t.service.telemetry.pseudonym(t.raider.account);
  const count = (kind) => db.prepare("SELECT COUNT(*) AS n FROM events WHERE who = ? AND kind = ?").get(who, kind).n;
  for (let i = 0; i < 4; i++) t.service.session("gc:raider");
  assert.equal(count("sign_in"), 1, "one a day, however many sign-ins");
  t.clock.now += 24 * 60 * 60 * 1000;
  t.service.session("gc:raider");
  assert.equal(count("sign_in"), 2, "and one the next day");
});

// A heist between two players that scores everything — the haul, Renown and
// stars both ways, a rating each, the defender's share and notification —
// billed 28.25 rows with its lease under the ledger a row a line, a lease
// written again as it settled, and the heist written after its children;
// 23.75 once those went. Now 21: the lease and the heist each keyed by its
// token without a rowid (one index entry fewer each), and the heist written
// once, not written and then marked validated — less the index entries the
// reads need, a heist's defender and a player's waiting raids (db.mjs). The
// ceiling holds the saving.
test("a scoring heist and its lease bill at most 21 rows, index entries counted, as D1 bills them (24.1, F47)", () => {
  const t = twoPlayers();
  // A player's first heist also writes, once, the universe's start and the
  // roster it brings home (§11.5's two strays, home.mjs): a player's cost,
  // not a heist's, so one heist is played before the bill opens.
  const first = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, first.token, play(t, first, { plan: openPlan() }));
  t.clock.now += 2 * 24 * 60 * 60 * 1000;
  const bill = billed(t.service.db);
  const cycles = 4;
  for (let i = 0; i < cycles; i++) {
    const lease = t.service.lease(t.raider.account, t.bundle);
    t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: i % 2 ? greedy() : openPlan() }));
    t.clock.now += 2 * 24 * 60 * 60 * 1000;
  }
  assert.ok(bill.rows / cycles <= 21, `${bill.rows / cycles} billed rows a lease and heist`);
});

test("a ledger of a row a currency is rebuilt as a row an event, its hauls and shares still counted to the caps", () => {
  const dir = mkdtempSync(join(tmpdir(), "ruleborn-"));
  const path = join(dir, "old.db");
  try {
    const old = new DatabaseSync(path);
    old.exec(`CREATE TABLE accounts (id TEXT PRIMARY KEY, platform_identity TEXT NOT NULL UNIQUE,
                league TEXT NOT NULL DEFAULT 'dust', cosmetics TEXT NOT NULL DEFAULT '[]',
                pass_expires_at INTEGER, keeper_level INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL);
              CREATE TABLE ledger (id INTEGER PRIMARY KEY AUTOINCREMENT, account TEXT NOT NULL REFERENCES accounts(id),
                currency TEXT NOT NULL CHECK (currency IN ('starlight', 'essence')), amount INTEGER NOT NULL,
                reason TEXT NOT NULL, heist TEXT, at INTEGER NOT NULL);
              CREATE INDEX ledger_by_account ON ledger (account, currency);
              INSERT INTO accounts (id, platform_identity, created_at) VALUES ('a', 'gc:a', 0);
              INSERT INTO ledger (account, currency, amount, reason, at) VALUES ('a', 'starlight', -100, 'entry fee (9.4)', 5);
              INSERT INTO ledger (account, currency, amount, reason, at) VALUES ('a', 'starlight', 900, 'haul (9.6)', 5);
              INSERT INTO ledger (account, currency, amount, reason, at) VALUES ('a', 'essence', 900, 'haul (9.6)', 5);
              INSERT INTO ledger (account, currency, amount, reason, at)
                VALUES ('a', 'essence', 40, '5% of what a foiled crew carried (9.4)', 6);`);
    old.close();
    const db = open(path);
    const r = db.prepare("SELECT SUM(starlight) AS s, SUM(essence) AS e, SUM(paid) AS p FROM ledger WHERE account = 'a'").get();
    assert.deepEqual({ ...r }, { s: 800, e: 940, p: 1840 });
    assert.throws(() => db.prepare("UPDATE ledger SET starlight = 1").run(), /append-only/);
    db.close();
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("a ledger made before Aether is rebuilt with it, every row moved as it was and still append-only (9.3)", () => {
  const dir = mkdtempSync(join(tmpdir(), "ruleborn-"));
  const path = join(dir, "old.db");
  try {
    const old = new DatabaseSync(path);
    old.exec(`CREATE TABLE accounts (id TEXT PRIMARY KEY, platform_identity TEXT NOT NULL UNIQUE,
                league TEXT NOT NULL DEFAULT 'dust', cosmetics TEXT NOT NULL DEFAULT '[]',
                pass_expires_at INTEGER, keeper_level INTEGER NOT NULL DEFAULT 1, created_at INTEGER NOT NULL);
              CREATE TABLE ledger (id INTEGER PRIMARY KEY AUTOINCREMENT, account TEXT NOT NULL REFERENCES accounts(id),
                starlight INTEGER NOT NULL DEFAULT 0, essence INTEGER NOT NULL DEFAULT 0,
                paid INTEGER NOT NULL DEFAULT 0, reason TEXT NOT NULL, heist TEXT, at INTEGER NOT NULL,
                CHECK (starlight != 0 OR essence != 0 OR paid != 0));
              INSERT INTO accounts (id, platform_identity, created_at) VALUES ('a', 'gc:a', 0);
              INSERT INTO ledger (account, starlight, essence, paid, reason, at) VALUES ('a', 900, 300, 1200, 'haul (9.6)', 5);
              INSERT INTO ledger (account, starlight, reason, at) VALUES ('a', -100, 'entry fee (9.4)', 6);`);
    old.close();
    const db = open(path);
    const r = db.prepare("SELECT SUM(starlight) AS s, SUM(essence) AS e, SUM(paid) AS p, SUM(aether) AS a FROM ledger").get();
    assert.deepEqual({ ...r }, { s: 800, e: 300, p: 1200, a: 0 });
    db.prepare("INSERT INTO ledger (account, aether, reason, at) VALUES ('a', 60, 'collected (9.3)', 7)").run();
    assert.throws(() => db.prepare("UPDATE ledger SET aether = 1").run(), /append-only/);
    db.close();
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
