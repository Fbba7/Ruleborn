// The running totals kept beside the append-only records (db.mjs): the
// ledger's balances, a season's Renown and stars. Each is a cache the rows
// can always rebuild, so each is held to its rows' sum, through every way a
// row is written, a clock that goes back, and a database from before them.

import assert from "node:assert/strict";
import { mkdtempSync, readdirSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { DatabaseSync } from "node:sqlite";

import { open } from "../src/db.mjs";
import { reads } from "../load.mjs";
import { established, openPlan, play, server, twoPlayers } from "./setup.mjs";

const DAY = 24 * 60 * 60 * 1000;

/** A crew that loads and never leaves: foiled. */
const greedy = () => openPlan().filter((c) => c.kind !== "Skiff" && c.tick < 62 * 30);

/** Two players who raid each other, clean and foiled, with Starlight to pay fees. */
function rivals() {
  const t = twoPlayers();
  established(t, t.raider.account);
  // The same open island, its exposure a byte apart: a snapshot of its own.
  const island = t.build.exampleIsland(true);
  island[6] = (island[6] + 1) & 255;
  const back = t.service.publish(t.raider.account, island).bundle;
  t.service.book(t.raider.account, "starlight", 40_000, "grant");
  t.service.book(t.defender.account, "starlight", 40_000, "grant");
  const raid = (who, bundle, plan) => {
    const lease = t.service.lease(who, bundle);
    return t.service.submit(who, lease.token, play(t, lease, { plan }));
  };
  return { ...t, back, raid };
}

/** Each kind of total against its rows, for one player. */
function agree(t, account) {
  const db = t.service.db;
  const sum = db.prepare(`SELECT COALESCE(SUM(starlight), 0) AS starlight, COALESCE(SUM(essence), 0) AS essence,
                                 COALESCE(SUM(aether), 0) AS aether FROM ledger WHERE account = ?`).get(account);
  assert.deepEqual(t.service.balance(account), { starlight: sum.starlight, essence: sum.essence });
  assert.equal(t.service.aether(account), sum.aether);
  // Every row's totals are the rows to it, summed: the newest is not alone in being right.
  const rows = db.prepare("SELECT * FROM ledger WHERE account = ? ORDER BY at, id").all(account);
  let s = 0, e = 0, a = 0;
  for (const r of rows) {
    s += r.starlight; e += r.essence; a += r.aether;
    if (r.starlight_total !== null) assert.deepEqual([r.starlight_total, r.essence_total, r.aether_total], [s, e, a]);
  }
  for (const table of ["renown", "season_stars"]) {
    for (const { season } of db.prepare(`SELECT DISTINCT season FROM ${table} WHERE account = ?`).all(account)) {
      let total = 0;
      for (const r of db.prepare(`SELECT amount, total FROM ${table} WHERE season = ? AND account = ? ORDER BY id`)
        .all(season, account)) {
        total += r.amount;
        if (r.total !== null) assert.equal(r.total, total, `${table} ${season}`);
      }
    }
  }
  const season = t.service.seasons.current().id;
  const renown = db.prepare("SELECT COALESCE(SUM(amount), 0) AS n FROM renown WHERE season = ? AND account = ?")
    .get(season, account).n;
  assert.equal(t.service.seasons.league(account).renown, t.service.seasons.standing(account, season).start + renown);
  // A heist's stars ride its ledger row when it books one (service.mint):
  // the season's stars are both tables' rows, and each ledger row's total
  // is its season's stars to it.
  const stars = db.prepare("SELECT COALESCE(SUM(amount), 0) AS n FROM season_stars WHERE season = ? AND account = ?")
    .get(season, account).n + db.prepare("SELECT COALESCE(SUM(stars), 0) AS n FROM ledger WHERE season = ? AND account = ?")
    .get(season, account).n;
  assert.equal(t.service.track.stars(account), stars);
  const by = new Map();
  for (const r of rows) {
    if (r.season === null) continue;
    by.set(r.season, (by.get(r.season) ?? 0) + r.stars);
    assert.equal(r.stars_total, by.get(r.season), `ledger stars to row ${r.id}`);
  }
}

test("every balance, Renown and stars total is its rows summed, through heists, books and claims (24.12)", () => {
  const t = rivals();
  for (let d = 0; d < 6; d++) {
    t.raid(t.raider.account, t.bundle, d % 2 ? greedy() : openPlan());
    t.raid(t.defender.account, t.back, d % 3 ? openPlan() : greedy());
    t.clock.now += DAY + 3_600_000;
  }
  t.service.book(t.raider.account, "aether", 500, "collected (9.3)");
  t.service.book(t.raider.account, "aether", -120, "woven (5.6)");
  for (const who of [t.raider.account, t.defender.account]) {
    try { t.service.track.claim(who); } catch { /* not enough stars yet */ }
    try { t.service.track.claim(who); } catch { /* not enough stars yet */ }
  }
  assert.ok(t.service.db.prepare("SELECT COUNT(*) AS n FROM renown").get().n > 0, "Renown moved");
  assert.ok(t.service.db.prepare("SELECT COUNT(*) AS n FROM season_stars").get().n > 0, "stars were earned");
  agree(t, t.raider.account);
  agree(t, t.defender.account);
  // Totals are written with each row, never after: the ledger is still append-only.
  assert.throws(() => t.service.db.prepare("UPDATE ledger SET starlight_total = 0").run(), /append-only/);
  assert.throws(() => t.service.db.prepare("UPDATE renown SET total = 0").run(), /record of heists/);
});

test("a clock a moment behind books after the newest row, and every balance still sums (24.12)", () => {
  const t = rivals();
  t.raid(t.raider.account, t.bundle, openPlan());
  const newest = t.service.db.prepare("SELECT MAX(at) AS at FROM ledger WHERE account = ?").get(t.raider.account).at;
  t.clock.now -= 5_000;
  t.service.book(t.raider.account, "starlight", 7, "a late writer");
  const row = t.service.db.prepare("SELECT at FROM ledger WHERE account = ? ORDER BY id DESC LIMIT 1").get(t.raider.account);
  assert.equal(row.at, newest, "dated at the newest row, not before it");
  t.service.book(t.raider.account, "starlight", 3, "and another");
  agree(t, t.raider.account);
});

test("the server writes a ledger, Renown or stars row only with its totals", () => {
  // A row without them would be summed past: every insert is the server's
  // own, through Service.mint, Seasons.settle and Track.book.
  const src = new URL("../src/", import.meta.url);
  for (const file of readdirSync(src).filter((f) => f.endsWith(".mjs") && f !== "db.mjs")) {
    const text = readFileSync(new URL(file, src), "utf8");
    for (const m of text.matchAll(/INSERT INTO (ledger|renown|season_stars) \(([^)]*)\)/g)) {
      assert.match(m[2], m[1] === "ledger" ? /starlight_total/ : /\btotal\b/, `${file}: ${m[0]}`);
    }
  }
});

/** `table` made again without `column`, its rows, indexes and triggers as
 *  they were: SQLite's DROP COLUMN cannot take a column a comment comes
 *  before when it is the table's last. */
function without(db, table, column) {
  const lines = db.prepare("SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?").get(table).sql.split("\n");
  const at = lines.findIndex((l) => new RegExp(`^\\s*${column}\\s`).test(l));
  let from = at;
  while (from > 0 && /^\s*--/.test(lines[from - 1])) from--;
  lines.splice(from, at - from + 1);
  // The column before a closing parenthesis keeps no comma.
  const close = lines.findIndex((l, i) => i >= from && /^\s*\)/.test(l));
  if (close === from) {
    let prev = from - 1;
    while (/^\s*--/.test(lines[prev])) prev--;
    lines[prev] = lines[prev].replace(/,\s*$/, "");
  }
  const made = lines.join("\n");
  const others = db.prepare("SELECT sql FROM sqlite_master WHERE tbl_name = ? AND type IN ('index', 'trigger') AND sql IS NOT NULL")
    .all(table).map((r) => r.sql).filter((sql) => !new RegExp(`\\b${column}\\b`).test(sql));
  const columns = db.prepare(`PRAGMA table_info(${table})`).all().map((c) => c.name).filter((c) => c !== column);
  db.exec(`PRAGMA foreign_keys = OFF; PRAGMA legacy_alter_table = ON; ALTER TABLE ${table} RENAME TO ${table}_new;
           ${made}; INSERT INTO ${table} (${columns}) SELECT ${columns} FROM ${table}_new; DROP TABLE ${table}_new;
           ${others.join(";\n")}; PRAGMA legacy_alter_table = OFF;`);
}

test("a database from before the totals opens with every row as it was, and its next rows carry the sums on", () => {
  const dir = mkdtempSync(join(tmpdir(), "ruleborn-"));
  const path = join(dir, "old.db");
  try {
    // A database as this server wrote it before: no totals, no defender on a
    // heist, no raids count; then opened by this one.
    const t = rivals();
    t.raid(t.raider.account, t.bundle, openPlan());
    t.raid(t.defender.account, t.back, greedy());
    t.clock.now += DAY;
    t.raid(t.raider.account, t.bundle, greedy());
    t.service.db.exec(`VACUUM INTO '${path}'`);
    const old = new DatabaseSync(path);
    old.exec(`DROP INDEX heists_by_defender; DROP TRIGGER heists_defender_named; DROP INDEX notifications_waiting;
              DROP INDEX leases_by_trace; DROP INDEX event_batches_by_who_at;
              CREATE INDEX event_batches_by_who ON event_batches (who);
              DROP VIEW events;
              CREATE VIEW events AS
                SELECT b.id AS batch, b.who, json_extract(e.value, '$.kind') AS kind,
                       json_extract(e.value, '$.data') AS data, json_extract(e.value, '$.at') AS at,
                       strftime('%Y-%m-%d', json_extract(e.value, '$.at') / 1000, 'unixepoch') AS day
                  FROM event_batches b, json_each(b.events) e;

              `);
    // The totals, and a raider's rating where it was, in the ratings table.
    old.exec(`INSERT INTO ratings (kind, key, rating, deviation, volatility, games, updated_at)
                SELECT 'raider', id, raider_rating, raider_deviation, raider_volatility, raider_games, 0
                  FROM accounts WHERE raider_rating IS NOT NULL;`);
    for (const column of ["aether_total", "essence_total", "starlight_total"]) without(old, "ledger", column);
    for (const [table, column] of [["heists", "defender"], ["accounts", "raider_games"], ["accounts", "raider_volatility"],
                                   ["accounts", "raider_deviation"], ["accounts", "raider_rating"], ["accounts", "raids"],
                                   ["renown", "total"], ["season_stars", "total"], ["ledger", "stars_total"],
                                   ["ledger", "stars"], ["ledger", "season"]]) {
      without(old, table, column);
    }
    const before = {
      ledger: old.prepare("SELECT id, account, starlight, essence, aether, paid, reason, heist, at FROM ledger ORDER BY id").all(),
      renown: old.prepare("SELECT id, season, account, amount, reason, heist, at FROM renown ORDER BY id").all(),
      heists: old.prepare("SELECT COUNT(*) AS n FROM heists").get().n,
      raiders: old.prepare("SELECT key, rating, deviation, volatility, games FROM ratings WHERE kind = 'raider' ORDER BY key").all()
        .map((r) => ({ ...r })),
    };
    assert.ok(before.raiders.length > 0);
    old.close();
    const db = open(path);
    assert.deepEqual(db.prepare("SELECT id, account, starlight, essence, aether, paid, reason, heist, at FROM ledger ORDER BY id").all(),
                     before.ledger, "every ledger row as it was");
    assert.deepEqual(db.prepare("SELECT id, season, account, amount, reason, heist, at FROM renown ORDER BY id").all(),
                     before.renown, "every Renown row as it was");
    assert.equal(db.prepare("SELECT COUNT(*) AS n FROM ledger WHERE starlight_total IS NOT NULL").get().n, 0);
    // A raider's rating moved to their row, the same numbers, none left behind.
    assert.deepEqual(db.prepare(`SELECT id AS key, raider_rating AS rating, raider_deviation AS deviation,
                                        raider_volatility AS volatility, raider_games AS games FROM accounts
                                  WHERE raider_rating IS NOT NULL ORDER BY id`).all().map((r) => ({ ...r })), before.raiders);
    assert.equal(db.prepare("SELECT COUNT(*) AS n FROM ratings WHERE kind = 'raider'").get().n, 0);
    // Each heist names its lease's defender, as the lease does.
    assert.equal(db.prepare(`SELECT COUNT(*) AS n FROM heists h JOIN leases l ON l.token = h.token
                              WHERE h.defender = l.defender`).get().n, before.heists);
    // The same server, on the opened database: the balances are the sums, and
    // the defence log has the raids it had.
    // Its clock and its random source, so no token is drawn twice.
    const u = server({ db, random: t.service.random, now: t.service.now });
    for (const key of t.service.store.keys()) u.service.store.put(t.service.store.get(key));
    const s = u.service;
    const view = { ...t, service: s };
    agree(view, t.raider.account);
    agree(view, t.defender.account);
    assert.equal(s.defences.view(t.defender.account).raids.length, 2);
    // A raid played on it books totals that carry the old rows' sums.
    t.clock.now += DAY;
    const lease = s.lease(t.raider.account, t.bundle);
    s.submit(t.raider.account, lease.token, play(view, lease, { plan: openPlan() }));
    s.book(t.defender.account, "essence", 11, "after the upgrade");
    assert.ok(db.prepare("SELECT COUNT(*) AS n FROM ledger WHERE starlight_total IS NOT NULL").get().n > 0);
    agree(view, t.raider.account);
    agree(view, t.defender.account);
    assert.equal(s.raidsPlayed(t.raider.account), 3, "the raids count, counted once and carried");
    db.close();
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("what a heist day reads does not grow with the raider's history (24.1's reads)", () => {
  const t = rivals();
  const count = reads(t.service.db);
  const day = () => {
    const before = count.rows;
    t.service.observatory.view(t.raider.account);
    t.service.defences.badge(t.defender.account);
    t.raid(t.raider.account, t.bundle, openPlan());
    t.raid(t.defender.account, t.back, greedy());
    t.service.defences.show(t.defender.account);
    // A week apart, so the week's counts are one heist each.
    t.clock.now += 7 * DAY + 3_600_000;
    return count.rows - before;
  };
  const early = [day(), day(), day()];
  for (let i = 0; i < 4; i++) day();
  const late = [day(), day(), day()];
  const mean = (xs) => xs.reduce((a, b) => a + b, 0) / xs.length;
  if (process.env.SHOW) console.log(early, late);
  assert.ok(mean(late) <= mean(early) * 1.15, `${early} rows early, ${late} after ${10} weeks`);
});
