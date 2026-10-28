// The lease and heist tables, keyed by their token without a rowid (db.mjs):
// what each costs to write, as D1 bills it, and the migration that moves a
// database made with rowids, every row as it was.

import assert from "node:assert/strict";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { DatabaseSync } from "node:sqlite";

import { open } from "../src/db.mjs";
import { billed } from "../load.mjs";
import { openPlan, play, server, twoPlayers } from "./setup.mjs";

const DAY = 24 * 60 * 60 * 1000;

test("a lease bills two rows, its own and its target's index entry: its token's index is the table (24.1)", () => {
  const t = twoPlayers();
  const db = t.service.db;
  for (const table of ["leases", "heists"]) {
    assert.equal(db.prepare("SELECT wr FROM pragma_table_list WHERE name = ?").get(table).wr, 1, table);
  }
  const bill = billed(db);
  t.service.lease(t.raider.account, t.bundle);
  assert.equal(bill.rows, 2);
  assert.deepEqual([...bill.byTable], [["leases", 2]]);
});

test("the newest lease on a target is the last issued, at one moment or with the clock gone back (24.13)", () => {
  const t = twoPlayers();
  const first = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, first.token, play(t, first, { plan: openPlan() }));
  // The same moment: the next is issued after it, and is the one held.
  const second = t.service.lease(t.raider.account, t.bundle);
  assert.notEqual(second.token, first.token);
  assert.equal(t.service.lease(t.raider.account, t.bundle).token, second.token);
  t.service.submit(t.raider.account, second.token, play(t, second, { plan: openPlan() }));
  t.service.db.prepare("UPDATE accounts SET created_at = 0 WHERE id = ?").run(t.defender.account);
  t.clock.now -= 60_000;
  const third = t.service.lease(t.raider.account, t.bundle);
  assert.ok(![first.token, second.token].includes(third.token));
  assert.equal(t.service.lease(t.raider.account, t.bundle).token, third.token, "and handed back");
});

test("a database whose leases and heists have rowids, and whose records name a heist by a key, is moved, every row as it was", () => {
  const dir = mkdtempSync(join(tmpdir(), "ruleborn-"));
  const path = join(dir, "old.db");
  try {
    const t = twoPlayers();
    const played = t.service.lease(t.raider.account, t.bundle);
    const out = t.service.submit(t.raider.account, played.token, play(t, played, { plan: openPlan() }));
    t.clock.now += 2 * DAY;
    const held = t.service.lease(t.raider.account, t.bundle);
    t.service.db.exec(`VACUUM INTO '${path}'`);
    // Made again as they were, with rowids.
    const old = new DatabaseSync(path);
    old.exec("PRAGMA foreign_keys = OFF; PRAGMA legacy_alter_table = ON");
    for (const table of ["leases", "heists"]) {
      const sql = old.prepare("SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?").get(table).sql;
      const others = old.prepare(
        "SELECT sql FROM sqlite_master WHERE tbl_name = ? AND type IN ('index', 'trigger') AND sql IS NOT NULL").all(table)
        .map((r) => r.sql);
      old.exec(`ALTER TABLE ${table} RENAME TO ${table}_keyed; ${sql.replace(/\)\s*WITHOUT ROWID\s*$/i, ")")};
                INSERT INTO ${table} SELECT * FROM ${table}_keyed; DROP TABLE ${table}_keyed; ${others.join(";\n")};`);
      assert.equal(old.prepare("SELECT wr FROM pragma_table_list WHERE name = ?").get(table).wr, 0);
    }
    // And the records a heist books, naming it by a deferred foreign key.
    for (const table of ["ledger", "renown", "season_stars"]) {
      const sql = old.prepare("SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?").get(table).sql;
      const others = old.prepare(
        "SELECT sql FROM sqlite_master WHERE tbl_name = ? AND type IN ('index', 'trigger') AND sql IS NOT NULL").all(table)
        .map((r) => r.sql);
      const keyed = sql.replace(/\bheist(\s+)TEXT,/, "heist$1TEXT REFERENCES heists(token) DEFERRABLE INITIALLY DEFERRED,");
      assert.notEqual(keyed, sql, table);
      old.exec(`ALTER TABLE ${table} RENAME TO ${table}_keyed; ${keyed};
                INSERT INTO ${table} SELECT * FROM ${table}_keyed; DROP TABLE ${table}_keyed; ${others.join(";\n")};`);
    }
    const rows = (db, table, by = "token") => db.prepare(`SELECT * FROM ${table} ORDER BY ${by}`).all().map((r) => ({ ...r }));
    const before = { leases: rows(old, "leases"), heists: rows(old, "heists"), ledger: rows(old, "ledger", "id"),
                     renown: rows(old, "renown", "id"), season_stars: rows(old, "season_stars", "id") };
    old.close();

    const db = open(path);
    for (const table of ["leases", "heists"]) {
      assert.equal(db.prepare("SELECT wr FROM pragma_table_list WHERE name = ?").get(table).wr, 1, table);
      assert.deepEqual(rows(db, table), before[table], `every ${table} row as it was`);
    }
    for (const table of ["ledger", "renown", "season_stars"]) {
      assert.deepEqual(rows(db, table, "id"), before[table], `every ${table} row as it was`);
      assert.ok(!db.prepare(`PRAGMA foreign_key_list(${table})`).all().some((k) => k.table === "heists"), table);
    }
    assert.throws(() => db.prepare("DELETE FROM ledger").run(), /append-only/, "and still append-only");
    for (const trigger of ["renown_append_only_update", "season_stars_append_only_update", "ledger_append_only_delete"]) {
      assert.ok(db.prepare("SELECT 1 FROM sqlite_master WHERE type = 'trigger' AND name = ?").get(trigger), trigger);
    }
    assert.equal(db.prepare("SELECT COUNT(*) AS n FROM sqlite_master WHERE name LIKE '%_with_rowid'").get().n, 0);
    assert.deepEqual(db.prepare("PRAGMA foreign_key_check").all(), [], "every row's foreign keys still hold");
    assert.equal(db.prepare("PRAGMA foreign_keys").get().foreign_keys, 1, "and are on again");
    for (const index of ["leases_by_target", "leases_by_trace", "heists_by_attacker", "heists_by_defender"]) {
      assert.ok(db.prepare("SELECT 1 FROM sqlite_master WHERE type = 'index' AND name = ?").get(index), index);
    }
    // The server on it: the held lease is handed back, the played heist's
    // retry is answered from its row, and the append-only ledger still names it.
    const u = server({ db, random: t.service.random, now: t.service.now });
    for (const key of t.service.store.keys()) u.service.store.put(t.service.store.get(key));
    assert.equal(u.service.lease(t.raider.account, t.bundle).token, held.token);
    const again = u.service.submit(t.raider.account, played.token, play(t, played, { plan: openPlan() }));
    assert.equal(again.repeated, true);
    assert.deepEqual(again.haul, out.haul);
    u.service.submit(t.raider.account, held.token, play(t, held, { plan: openPlan() }));
    assert.equal(db.prepare("SELECT COUNT(*) AS n FROM heists").get().n, 2);
    db.close();
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});
