// The rows read count (load.mjs reads()): D1 bills the rows a statement
// scans, not the rows it returns, so the count is held to what each kind of
// loop visits, and to the plans the service's own statements run.

import assert from "node:assert/strict";
import { test } from "node:test";

import { open } from "../src/db.mjs";
import { reads, run } from "../load.mjs";
import { openPlan, play, twoPlayers } from "./setup.mjs";

/** A table of 1,000 rows in ten groups of 100, indexed by group and n. */
function sample() {
  const db = open();
  db.exec(`CREATE TABLE t (id INTEGER PRIMARY KEY, g TEXT NOT NULL, n INTEGER NOT NULL, c INTEGER NOT NULL);
           CREATE INDEX t_by_g ON t (g, n);
           CREATE TABLE u (k TEXT PRIMARY KEY, v INTEGER NOT NULL);`);
  const t = db.prepare("INSERT INTO t (g, n, c) VALUES (?, ?, ?)");
  for (let i = 0; i < 1000; i++) t.run(`g${i % 10}`, i, i % 7);
  for (let i = 0; i < 20; i++) db.prepare("INSERT INTO u (k, v) VALUES (?, ?)").run(`g${i}`, i);
  return db;
}

test("a read counts the rows it visits: a key one, a scan its table, a search its range (24.1)", () => {
  const db = sample();
  const count = reads(db);
  const rows = (sql, ...a) => {
    const before = count.rows;
    db.prepare(sql).all(...a);
    return count.rows - before;
  };
  assert.equal(rows("SELECT * FROM t WHERE id = ?", 5), 1);
  assert.equal(rows("SELECT * FROM t WHERE c = 3"), 1000, "no index: every row scanned, 143 returned");
  assert.equal(rows("SELECT * FROM t WHERE g = ?", "g3"), 100);
  assert.equal(rows("SELECT * FROM t WHERE g = ? AND c = 2", "g3"), 100, "the range visited, not the 14 returned");
  assert.equal(rows("SELECT SUM(n) AS s FROM t WHERE g = ?", "g3"), 100, "an aggregate reads every row it sums");
  assert.equal(rows("SELECT * FROM t WHERE g = ? AND n > 900", "g1"), 10);
  assert.equal(rows("SELECT * FROM t WHERE g = ? ORDER BY n DESC LIMIT 1", "g3"), 1, "read newest first, stopped at one");
  assert.equal(rows("SELECT COUNT(*) AS n FROM t"), 1000);
  assert.equal(rows("SELECT * FROM u WHERE NOT EXISTS (SELECT 1 FROM t WHERE t.g = u.k)"), 20 + 10,
               "each of u's rows, and the first match of each that has one");
  assert.equal(rows("SELECT u.k, (SELECT SUM(n) FROM t WHERE t.g = u.k) AS s FROM u WHERE u.k IN ('g1', 'g2')"),
               2 + 200, "a correlated subquery, each time it runs");
  assert.equal(rows("SELECT * FROM t JOIN u ON u.k = t.g WHERE t.n < 20"), 1000 + 20);
  assert.equal(rows("SELECT 1 + 1 AS two"), 0);
  assert.equal(count.bySql.get("SELECT * FROM t WHERE id = ?"), 1);
});

test("a write reads the rows its WHERE visits, as they were; an insert reads none but its SELECT's", () => {
  const db = sample();
  const count = reads(db);
  const rows = (fn) => {
    const before = count.rows;
    fn();
    return count.rows - before;
  };
  assert.equal(rows(() => db.prepare("UPDATE t SET c = ? WHERE g = ? AND n > ?").run(9, "g4", 900)), 10,
               "the SET's argument is not the WHERE's");
  assert.equal(rows(() => db.prepare("UPDATE t SET c = ?1 WHERE id = ?2").run(9, 1)), 1);
  assert.equal(rows(() => db.prepare("UPDATE t SET c = :c WHERE c = :old").run({ c: 1, old: 9 })), 1000);
  assert.equal(rows(() => db.prepare("DELETE FROM t WHERE g = ?").run("g5")), 100, "counted before the rows go");
  assert.equal(rows(() => db.prepare("INSERT INTO u (k, v) VALUES (?, ?)").run("new", 1)), 0);
  assert.equal(rows(() => db.prepare("INSERT INTO u (k, v) SELECT 'x' || id, n FROM t WHERE g = ?").run("g6")), 100);
  assert.equal(db.prepare("SELECT COUNT(*) AS n FROM t WHERE g = 'g5'").get().n, 0, "and the writes themselves ran");
});

test("a rolled-back transaction leaves the count's views standing", () => {
  const db = sample();
  const count = reads(db);
  db.exec("BEGIN");
  db.prepare("SELECT * FROM t WHERE id = 1").get();
  db.exec("ROLLBACK");
  const before = count.rows;
  db.prepare("SELECT * FROM u WHERE k = 'g1'").get();
  assert.equal(count.rows - before, 1);
});

test("every statement a heist and a target-list rebuild run is counted on its own plan's loops", () => {
  const t = twoPlayers();
  const db = t.service.db;
  const count = reads(db);
  const ran = [];
  const prepare = db.prepare;
  db.prepare = (sql) => {
    const st = prepare(sql);
    for (const m of ["get", "all", "run"]) {
      const inner = st[m];
      st[m] = (...a) => { ran.push([sql, a]); return inner(...a); };
    }
    return st;
  };
  for (let i = 0; i < 2; i++) {
    const lease = t.service.lease(t.raider.account, t.bundle);
    t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
    t.clock.now += 2 * 24 * 60 * 60 * 1000;
  }
  t.service.targetLists();
  db.prepare = prepare;
  let compared = 0;
  for (const [sql, a] of ran) {
    const p = count.plans(sql, a);
    if (!p?.statement) continue;
    compared++;
    // The same loops, in whichever order the planner joins them.
    assert.deepEqual([...p.counted].sort(), [...p.statement].sort(), sql);
  }
  assert.ok(compared > 50, `${compared} statements compared`);
  assert.ok(count.rows > 0);
});

test("no request a session makes reads a table whole, but the candidates' rebuild of every island (24.8)", () => {
  // The load test's day: sessions, telemetry, the raid badge and log, the
  // Observatory, leases and heists. The one whole read left is matchmaking's
  // candidates, made again a minute at most (SR-03), whose cost and the
  // option of the hourly list are in docs/server/db-cost.md.
  const r = run({ players: 12, days: 2, archetype: "engaged" });
  const scans = r.scans.filter((s) => !(s.op === "observatory" && s.table === "islands"));
  assert.deepEqual(scans, [], JSON.stringify(scans));
  assert.ok(r.readsPerPlayerDay > 0);
});

test("the reads that were whole tables search an index now", () => {
  const db = open();
  const plan = (sql) => db.prepare(`EXPLAIN QUERY PLAN ${sql}`).all().map((r) => r.detail).join("; ");
  const cases = [
    // A player's waiting raids, which every raid on them joins.
    ["SELECT * FROM notifications WHERE account = ? AND kind = 'raided' AND sent_at IS NULL", /notifications_waiting/],
    // The raids on a player: the defence log, the badge, the Trace.
    [`SELECT COUNT(*) FROM heists h JOIN leases l ON l.token = h.token
       WHERE h.defender = ? AND h.submitted_at >= ? AND h.validated = 1`, /heists_by_defender/],
    // A robbery traced once.
    ["SELECT 1 FROM leases t WHERE t.trace_of = ?", /leases_by_trace/],
    // The week's raids, from Monday's day.
    ["SELECT COUNT(*) FROM heists WHERE attacker = ? AND day >= ? AND validated = 1", /heists_by_attacker \(attacker=\? AND day>\?\)/],
    // A balance, Renown and stars: the newest row.
    ["SELECT starlight_total FROM ledger WHERE account = ? ORDER BY at DESC, id DESC LIMIT 1", /ledger_by_account/],
    ["SELECT total FROM renown WHERE season = ? AND account = ? ORDER BY id DESC LIMIT 1", /renown_by_account/],
    // A player's events of a day.
    ["SELECT 1 FROM events WHERE who = ? AND started >= ? AND kind = ? AND day = ? LIMIT 1", /event_batches_by_who_at \(who=\? AND at>\?\)/],
    // The candidates' staleness: three index rows.
    ["SELECT MAX(changed_at) FROM islands", /COVERING INDEX islands_by_change/],
    ["SELECT MAX(banned_at) FROM accounts WHERE banned_at IS NOT NULL", /accounts_banned/],
    // The last 14 days' snapshots, for the echoes.
    ["SELECT bundle FROM snapshots WHERE published_at > ? ORDER BY +bundle", /snapshots_by_published/],
  ];
  for (const [sql, index] of cases) {
    const p = plan(sql);
    assert.match(p, index, sql);
    assert.doesNotMatch(p, /(^|; )SCAN (?!CONSTANT|\w+ VIRTUAL TABLE)/, sql);
  }
});
