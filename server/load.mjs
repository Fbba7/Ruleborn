// The server under load, against §24.1's budget (phase 14's load testing).
//
//     node server/load.mjs [--players N] [--days D] [--json] [--write | --check]
//
// §24.1: "Budget: about 100 to 200 kilobytes and five writes per active
// player per day. That is the design constraint, not an estimate made
// afterwards." Its cost table puts 1,000 and 10,000 monthly players at €0,
// on the free plans §28.3 cites; the paid plan at $5 "includes … 50 million
// row writes — several times what a million players generate".
//
// This plays a population of §14.1's players through the real service — the
// same database schema, the simulation's WebAssembly build, every grant,
// Renown, stars, rating and event a heist books — and measures what the
// budget is about: rows written per player per day, by what wrote them, and
// the CPU a re-simulation takes, against the free plan's 10 ms a request.
// Rows read are not measured: SQLite does not count them as D1 bills them.
// Rows written are measured twice: as SQLite changes them, and as D1 bills
// them — "Indexes will add an additional written row when writes include the
// indexed column" — each changed row and every index entry its write
// touches (billed(), below). The budget and the cost are read from the
// billed count, which is what the bill is.
//
// Writes are deterministic (the clock and the random source are the tests');
// CPU time is this machine's. --write records both in server/load.json, and
// --check fails if the writes have moved since, so a change that adds a write
// to every heist is seen when it is made.

import { readFileSync, writeFileSync } from "node:fs";

import { open } from "./src/db.mjs";
import { ERAS } from "./src/eras.mjs";
import { Service } from "./src/service.mjs";
import { Build, Builds } from "./src/sim.mjs";
import { Store } from "./src/store.mjs";
import { raiseTo } from "./src/universe.mjs";

const facts = JSON.parse(readFileSync(new URL("./src/facts.json", import.meta.url), "utf8"));
const WASM = new URL("../sim/target/wasm32-unknown-unknown/release/ruleborn_sim.wasm", import.meta.url);
const DAY = 24 * 60 * 60 * 1000;
const T0 = Date.UTC(2026, 8, 23, 6, 0, 0);

const arg = (name, fallback) => {
  const i = process.argv.indexOf(`--${name}`);
  return i < 0 ? fallback : Number(process.argv[i + 1]);
};

/**
 * Wraps `db` so each write statement adds what D1 would bill for it: every
 * row it changed, and for each, an entry in every index an insert or delete
 * writes, or in each index an update's SET columns belong to (a table's text
 * primary key is an index too). An upsert is an insert when it made a row
 * (the connection's last insert rowid moved) and otherwise an update of the
 * columns its DO UPDATE sets. A partial index holds only the rows its WHERE
 * takes: an inserted row writes it if it is one of them, an update if it
 * sets a column the index holds or chooses by, and a delete is counted as if
 * every row it took were in it. Returns the running count.
 */
export function billed(db) {
  const prepare = db.prepare.bind(db);
  const indexes = new Map();
  const of = (table) => {
    if (!indexes.has(table)) {
      indexes.set(table, prepare(`PRAGMA index_list(${table})`).all().map((i) => {
        const cols = prepare(`PRAGMA index_info(${i.name})`).all().map((c) => c.name);
        const sql = i.partial ? prepare("SELECT sql FROM sqlite_master WHERE name = ?").get(i.name).sql : null;
        const where = sql ? /\bWHERE\b([\s\S]*)$/i.exec(sql)[1] : null;
        // What a partial index chooses by is a column it holds too, for an update.
        const chosen = where ? prepare(`PRAGMA table_info(${table})`).all().map((c) => c.name)
          .filter((c) => new RegExp(`\\b${c}\\b`).test(where)) : [];
        return { cols: [...cols, ...chosen], where };
      }));
    }
    return indexes.get(table);
  };
  const count = { rows: 0, byTable: new Map() };
  db.prepare = (sql) => {
    const st = prepare(sql);
    const s = sql.replace(/\s+/g, " ").trim();
    let m, per = null, table = null;
    const updating = (table, setList) => {
      const set = setList.split(",").map((x) => x.trim().split(/\s*=/)[0]);
      return 1 + of(table).filter((i) => i.cols.some((c) => set.includes(c))).length;
    };
    const upsert = /ON CONFLICT .*? DO UPDATE SET (.*?)(?: WHERE .*)?$/i.exec(s);
    if ((m = /^INSERT (?:OR \w+ )?INTO (\w+)/i.exec(s)) || (m = /^DELETE FROM (\w+)/i.exec(s))) {
      table = m[1];
      const insert = /^INSERT/i.test(s);
      // An inserted row is in a partial index if the index's WHERE takes it.
      const holds = (i, rowid) => !i.where || !insert || rowid === null
        || Boolean(prepare(`SELECT 1 FROM ${table} WHERE rowid = ? AND (${i.where})`).get(rowid));
      per = (inserted, rowid) => (upsert && !inserted ? updating(table, upsert[1])
        : 1 + of(table).filter((i) => holds(i, rowid)).length);
    } else if ((m = /^UPDATE (\w+) SET (.*?) WHERE/i.exec(s))) {
      table = m[1];
      const set = m[2];
      per = () => updating(table, set);
    }
    if (per) {
      const run = st.run.bind(st);
      const rowid = () => prepare("SELECT last_insert_rowid() AS r").get().r;
      st.run = (...a) => {
        const before = upsert ? rowid() : null;
        const r = run(...a);
        const after = r.changes ? rowid() : null;
        const n = Number(r.changes) * per(upsert ? after !== before : true, Number(r.changes) === 1 ? after : null);
        count.rows += n;
        if (n) count.byTable.set(table, (count.byTable.get(table) ?? 0) + n);
        return r;
      };
    }
    return st;
  };
  return count;
}

/**
 * Wraps `db` so each statement adds the rows D1 would bill it as read: every
 * row a scan or a search visits, not the rows it returns ("Rows read measure
 * how many rows a query reads (scans)"). SQLite keeps no such count where
 * node can see it, so the statement is run a second time against counting
 * views — `__r_t`, `SELECT rowid, * FROM t WHERE __seen(rowid)` for each
 * table `t` — that the planner flattens into the same loops on the same
 * indexes: the function is called once for each row a loop lands on, an
 * aggregate's rows and a correlated subquery's each time included, and a
 * LIMIT that stops a loop stops the count. An UPDATE or DELETE reads the rows
 * its WHERE visits, counted before it runs; an INSERT … SELECT, its SELECT.
 * The checks SQLite makes of a key on a write (a unique index, a foreign
 * key) are not counted. `rows` is the running total; `bySql` each
 * statement's.
 */
export function reads(db) {
  const prepare = db.prepare.bind(db);
  const count = { rows: 0, bySql: new Map(), scans: new Map(), op: null };
  let seen = 0;
  db.function("__seen", { deterministic: false }, (_rowid) => { seen++; return 1; });
  const tables = new Set();
  const views = new Map();
  const counted = (name) => {
    if (tables.has(name)) return true;
    const row = prepare("SELECT type, sql FROM main.sqlite_master WHERE name = ? AND type IN ('table', 'view')").get(name);
    if (!row) return false;
    tables.add(name);
    if (row.type === "table") {
      db.exec(`CREATE TEMP VIEW IF NOT EXISTS __r_${name} AS SELECT rowid AS rowid, * FROM main.${name} WHERE __seen(rowid)`);
    } else {
      views.set(name, row.sql);
      const body = row.sql.replace(/^[\s\S]*?\bAS\b/i, "");
      db.exec(`CREATE TEMP VIEW IF NOT EXISTS __r_${name} AS ${rewrite(body)}`);
    }
    return true;
  };
  // Every table a FROM or a JOIN names (the schema's one comma join, the
  // events view's, joins a table-valued function).
  // A table named without an alias keeps its name as the view's, so the
  // statement's `t.column`s still name it.
  const KEYWORDS = /^(WHERE|JOIN|ON|LEFT|INNER|CROSS|NATURAL|OUTER|ORDER|GROUP|HAVING|LIMIT|UNION|EXCEPT|INTERSECT|WINDOW|SET|USING|INDEXED|NOT|RETURNING)$/i;
  const rewrite = (sql) => sql.replace(/\b(FROM|JOIN)(\s+)(\w+)\b(?!\s*\()/gi, (all, kw, sp, name, at) => {
    if (!counted(name)) return all;
    const next = /^\s+(?:AS\s+)?(\w+)/i.exec(sql.slice(at + all.length));
    return `${kw}${sp}__r_${name}${next && !KEYWORDS.test(next[1]) ? "" : ` AS ${name}`}`;
  });
  // Made before any transaction, which a rollback would take them back with.
  for (const r of prepare("SELECT name FROM main.sqlite_master WHERE type IN ('table', 'view') AND name NOT LIKE 'sqlite_%'").all()) {
    counted(r.name);
  }
  const plans = new Map();
  /** What a statement reads, as a SELECT over the counting views, and which
   *  of its arguments it takes; null for one that reads no table. */
  const plan = (sql) => {
    if (plans.has(sql)) return plans.get(sql);
    const s = sql.trim();
    let read = null;
    let m;
    const numbered = /\?\d/.test(s);
    // The `?`s a statement's text has before `at`, as its arguments are bound.
    const before = (at) => (s.slice(0, at).replace(/'[^']*'/g, "").match(/\?(?!\d)/g) ?? []).length;
    if (/^(SELECT|WITH)\b/i.test(s)) {
      read = { sql: rewrite(s), skip: 0 };
    } else if ((m = /^(UPDATE)\s+(?:OR\s+\w+\s+)?(\w+)\s+SET\b/i.exec(s)) || (m = /^(DELETE)\s+FROM\s+(\w+)/i.exec(s))) {
      const where = /\bWHERE\b/i.exec(s);
      if (counted(m[2])) {
        read = { sql: `SELECT 1 FROM __r_${m[2]} AS ${m[2]}${where ? ` ${rewrite(s.slice(where.index))}` : ""}`,
                 skip: where && !numbered ? before(where.index) : 0 };
      }
    } else if ((m = /^INSERT\b[\s\S]*?\)\s*(SELECT\b[\s\S]*)$/i.exec(s))) {
      const select = m[1].replace(/\bON\s+CONFLICT\b[\s\S]*$/i, "");
      read = { sql: rewrite(select), skip: numbered ? 0 : before(s.length - m[1].length) };
    }
    if (read && !/__r_/.test(read.sql)) read = null;
    if (read) {
      read.st = prepare(read.sql);
      read.st.setAllowUnknownNamedParameters?.(true);
      // The tables it reads whole: a cost that grows with the table.
      read.scans = [...new Set(prepare(`EXPLAIN QUERY PLAN ${read.sql}`).all()
        .map((r) => /^SCAN (?:main\.)?(\w+)/.exec(r.detail)?.[1]).filter((t) => t && tables.has(t)))];
    }
    plans.set(sql, read);
    return read;
  };
  const tally = (sql, args) => {
    const p = plan(sql);
    if (!p) return;
    seen = 0;
    const a = args.length === 1 && args[0] && typeof args[0] === "object" && !ArrayBuffer.isView(args[0])
      ? args : args.slice(p.skip);
    p.st.all(...a);
    count.rows += seen;
    count.bySql.set(sql, (count.bySql.get(sql) ?? 0) + seen);
    for (const table of p.scans) {
      const key = `${count.op ?? ""}\u0000${table}\u0000${sql}`;
      count.scans.set(key, (count.scans.get(key) ?? 0) + seen);
    }
  };
  /** A statement's query plan and its counted copy's, each loop as its
   *  access alone (the table's name or alias aside): the same loops on the
   *  same indexes, or the count is not of what D1 would run. */
  count.plans = (sql, args = []) => {
    const p = plan(sql);
    if (!p) return null;
    const loops = (st, a) => st.all(...a).map((r) => r.detail
      .replace(/^(SCAN|SEARCH) (?:main\.)?\w+(?: AS \w+)?/, "$1 _")
      .replace(/^(CORRELATED )?(SCALAR|LIST) SUBQUERY \d+/, "$1$2 SUBQUERY"));
    const head = s => /^(SELECT|WITH)\b/i.test(s.trim());
    const a = args.slice(p.skip);
    return { statement: head(sql) ? loops(prepare(`EXPLAIN QUERY PLAN ${sql}`), args) : null,
             counted: loops(prepare(`EXPLAIN QUERY PLAN ${p.sql}`), a) };
  };
  db.prepare = (sql) => {
    const st = prepare(sql);
    for (const method of ["get", "all", "iterate", "run"]) {
      const inner = st[method].bind(st);
      st[method] = (...a) => {
        // A write's WHERE reads the rows as they were.
        if (method === "run") tally(sql, a);
        const out = inner(...a);
        if (method !== "run") tally(sql, a);
        return out;
      };
    }
    return st;
  };
  return count;
}

/** §14.1's archetypes: sessions and heists a day. */
export const ARCHETYPES = { engaged: [5, 4], regular: [3, 2], casual: [1, 1] };

export function run({ players = 60, days = 3, archetype = "engaged" } = {}) {
  const clock = { now: T0 };
  let counter = 0;
  const random = (n) => {
    counter++;
    const out = Buffer.alloc(n);
    for (let i = 0; i < n; i++) out[i] = (counter * 37 + i * 11 + (counter >> 8) * (i + 1) * 53 + (counter >> 16) * 7) & 255;
    return out;
  };
  const build = Build.load(new URL(WASM).pathname);
  const service = new Service({
    db: open(), store: new Store(), builds: new Builds([build]), secret: "load",
    verifyPlatform: (c) => c, now: () => clock.now, random, seasonStart: T0, firstBand: "18+",
  });
  const db = service.db;
  const bill = billed(db);
  const read = reads(db);
  const changes = () => Number(db.prepare("SELECT total_changes() AS n").get().n);
  const writes = {};
  const bills = {};
  const rowsRead = {};
  const count = (what, fn) => {
    const before = [changes(), bill.rows, read.rows];
    read.op = what;
    const out = fn();
    read.op = null;
    writes[what] = (writes[what] ?? 0) + changes() - before[0];
    bills[what] = (bills[what] ?? 0) + bill.rows - before[1];
    rowsRead[what] = (rowsRead[what] ?? 0) + read.rows - before[2];
    return out;
  };

  // The population: established players, each with an island of its own.
  const accounts = [];
  const bundles = [];
  // The device signs in once and then refreshes its session when its hour
  // is up, as the client does (docs/security/auth.md).
  const refresh = [];
  for (let i = 0; i < players; i++) {
    const { account, refreshToken } = service.session(`gc:load-${i}`);
    refresh.push(refreshToken);
    db.prepare("UPDATE accounts SET created_at = ? WHERE id = ?").run(T0 - 4 * DAY, account);
    const island = build.exampleIsland(i % 2 === 0);
    island[5] = 1 + (Math.floor(i / 2) % 10);              // Vault level: a distinct island each
    island[6] = i & 255;                                   // and a distinct exposure
    raiseTo(db, account, "heart", island[4], island[5]);  // a universe built that far
    bundles.push(service.publish(account, island).bundle);
    // Established: their first session is long behind them, so the one
    // first_seen row each player ever writes is not counted as a day's.
    service.telemetry.batch(account, [{ kind: "session_start", data: {} }]);
    accounts.push(account);
  }
  service.targetLists();
  for (const k of Object.keys(writes)) delete writes[k];
  for (const k of Object.keys(bills)) delete bills[k];
  for (const k of Object.keys(rowsRead)) delete rowsRead[k];
  bill.byTable.clear();
  read.bySql.clear();
  read.scans.clear();

  const [sessions, heists] = ARCHETYPES[archetype];
  const readsByDay = [];
  const cpu = [];
  const baseline = changes();
  for (let d = 0; d < days; d++) {
    for (let s = 0; s < sessions; s++) {
      clock.now = T0 + d * DAY + s * 3 * 60 * 60 * 1000;
      for (let i = 0; i < players; i++) {
        count("session", () => { refresh[i] = service.auth.refresh(refresh[i]).refreshToken; });
        count("telemetry batch", () => service.telemetry.batch(accounts[i], [
          { kind: "session_start", data: {} },
          { kind: "session_end", data: { seconds: 300, crashed: false } },
          { kind: "worth", data: { rating: 4 } },
        ]));
        // The screens a session reads (the client's Home and its badge, the
        // Observatory before a heist): reads the budget counts too.
        count("raid badge", () => service.defences.badge(accounts[i]));
        if (s === 0) count("defence log", () => service.defences.show(accounts[i]));
        if (s >= heists) continue;
        count("observatory", () => service.observatory.view(accounts[i]));
        const target = (i + 1 + s + d * heists) % players;
        const lease = count("lease", () => service.lease(accounts[i], bundles[target]));
        // The device's half — recording the replay — is not the server's.
        const era = ERAS.find((e) => e.id === lease.era)?.wire ?? 0;
        const replay = build.recordDrawn(service.bundle(lease.bundle),
                                         { seed: BigInt(lease.seed), ticks: lease.ticks, crew: 3, era });
        const t0 = process.hrtime.bigint();
        const out = count("heist: validate and grant", () => service.submit(accounts[i], lease.token, replay));
        // A refused heist writes less and costs no re-simulation: the load
        // test must not quietly measure refusals.
        if (!out.validated) throw new Error(`a load-test heist was refused: ${out.reason}`);
        cpu.push(Number(process.hrtime.bigint() - t0) / 1e6);
      }
    }
    // A player's reads by the day: what grows with the history read.
    const played = Object.entries(rowsRead).reduce((a, [k, v]) => a + (k.includes("(x24)") || k.includes("compaction") ? 0 : v), 0);
    readsByDay.push(+((played - readsByDay.reduce((a, v) => a + v * players, 0)) / players).toFixed(1));
    clock.now = T0 + d * DAY + 23 * 60 * 60 * 1000;
    // The periodic jobs, amortised over the day's players: 24 target-list
    // runs a day (hourly, as the owner decided, G21), one telemetry compaction.
    count("target lists (x24)", () => { for (let k = 0; k < 24; k++) service.targetLists(); });
    count("telemetry compaction", () => service.telemetry.compact());
  }
  cpu.sort((a, b) => a - b);
  const pct = (p) => cpu[Math.min(cpu.length - 1, Math.floor(p * cpu.length))];
  const playerDays = players * days;
  // The periodic jobs write per band and per day, not per player: counted
  // apart, as a day's total, so a small population does not inflate them.
  const PERIODIC = ["target lists (x24)", "telemetry compaction"];
  const perPlayer = Object.entries(writes).filter(([k]) => !PERIODIC.includes(k));
  const perDay = Object.fromEntries(perPlayer.map(([k, v]) => [k, +(v / playerDays).toFixed(2)]));
  const total = perPlayer.reduce((a, [, v]) => a + v, 0);
  const billedPerPlayer = Object.entries(bills).filter(([k]) => !PERIODIC.includes(k));
  const billedTotal = billedPerPlayer.reduce((a, [, v]) => a + v, 0);
  const readPerPlayer = Object.entries(rowsRead).filter(([k]) => !PERIODIC.includes(k));
  const readTotal = readPerPlayer.reduce((a, [, v]) => a + v, 0);
  return {
    archetype, players, days, heistsPerDay: heists, sessionsPerDay: sessions,
    writesPerPlayerDay: +(total / playerDays).toFixed(2),
    periodicWritesADay: Object.fromEntries(PERIODIC.map((k) => [k, (writes[k] ?? 0) / days])),
    writesPerHeist: +((writes["heist: validate and grant"] + writes.lease) / (playerDays * heists)).toFixed(2),
    byOperation: perDay,
    billedRowsPerPlayerDay: +(billedTotal / playerDays).toFixed(2),
    billedPerHeist: +((bills["heist: validate and grant"] + bills.lease) / (playerDays * heists)).toFixed(2),
    billedByOperation: Object.fromEntries(billedPerPlayer.map(([k, v]) => [k, +(v / playerDays).toFixed(2)])),
    validationMs: { p50: +pct(0.5).toFixed(1), p95: +pct(0.95).toFixed(1), max: +cpu[cpu.length - 1].toFixed(1) },
    // Where the billed rows go, a player a day, the periodic jobs' included.
    billedByTable: Object.fromEntries([...bill.byTable].sort((a, b) => b[1] - a[1])
      .map(([k, v]) => [k, +(v / playerDays).toFixed(2)])),
    // Rows read as D1 bills them (reads(), above): a player's requests a day,
    // and the periodic jobs' reads a day an island, as they read every island.
    readsPerPlayerDay: +(readTotal / playerDays).toFixed(1),
    readsPerHeist: +((rowsRead["heist: validate and grant"] + rowsRead.lease) / (playerDays * heists)).toFixed(1),
    readsByOperation: Object.fromEntries(readPerPlayer.map(([k, v]) => [k, +(v / playerDays).toFixed(1)])),
    readsPerPlayerByDay: readsByDay,
    periodicReadsADayAnIsland: Object.fromEntries(PERIODIC.map((k) => [k, +((rowsRead[k] ?? 0) / days / players).toFixed(1)])),
    // Each request's statement that reads a table whole, and the rows it
    // read so a player a day: a cost that grows with the table, not the player.
    scans: [...read.scans].map(([k, n]) => [...k.split("\u0000"), n])
      .filter(([op]) => !PERIODIC.includes(op))
      .map(([op, table, sql, n]) => ({ op, table, rows: +(n / playerDays).toFixed(1), sql: sql.replace(/\s+/g, " ").trim().slice(0, 120) }))
      .sort((a, b) => b.rows - a.rows),
    // The statements that read the most, a player a day: where a cut is.
    readsBySql: [...read.bySql].sort((a, b) => b[1] - a[1]).slice(0, Number(process.env.LOAD_SQL_TOP ?? 12))
      .map(([sql, n]) => [+(n / playerDays).toFixed(1), sql.replace(/\s+/g, " ").trim().slice(0, 160)]),
  };
}

/** §24.1's reads budget, "2,500 row reads per active player per day", and
 *  §28.3's D1 source: the free plan's 5 million row reads a day; the paid
 *  plan's 25 billion a month included, then $0.001 a million. */
export const READS = { budget: 2_500, freeDay: 5_000_000, paidMonth: 25e9, pricePerMillion: 0.001 };

/** What the measurements do to §24.1's budget and cost table. */
export function against(result) {
  // §24.1 (v3.7): "at least 46, 24 and 11 rows a day for engaged, regular and
  // casual players": the rows written, by this run's archetype.
  const [budget, included, price, freeWrites, freeCpu] = [facts.WRITE_BUDGET[result.archetype],
    facts.PAID_WRITES_MONTH, facts.WRITE_PRICE_PER_MILLION, facts.FREE_WRITES_DAY, facts.FREE_CPU_MS];
  // §25.1's gate: "a third of monthly players play on a given day".
  const [dn, dd] = facts.DAILY_SHARE;
  // D1 bills the billed count: rows and their index entries.
  const monthly = (players) => (players * dn / dd) * result.billedRowsPerPlayerDay * 30;
  return {
    budget, overBudget: +(result.writesPerPlayerDay / budget).toFixed(1),
    freeCpuMs: freeCpu, validationFitsFreePlan: result.validationMs.p95 <= freeCpu,
    freePlanPlayersADay: Math.floor(freeWrites / result.billedRowsPerPlayerDay),
    // Monthly players, a third of them playing on a day, each a day of this
    // player's: an engaged population is the ceiling, a casual one the floor.
    paidDollarsAMonth: Object.fromEntries([1_000, 10_000, 100_000, 1_000_000].map((p) =>
      [p, +(5 + Math.max(0, monthly(p) - included) / 1e6 * price).toFixed(0)])),
    // Reads: the day's players' requests, and the periodic jobs' reads of
    // every island, an island each monthly player (the lists hold them all).
    readBudget: READS.budget,
    readsOverBudget: +(result.readsPerPlayerDay / READS.budget).toFixed(2),
    freePlanReadsPlayersADay: Math.floor(READS.freeDay / readsADay(result, 1)),
    readDollarsAMonth: Object.fromEntries([1_000, 10_000, 100_000, 1_000_000].map((p) =>
      [p, +(Math.max(0, readsAMonth(result, p) - READS.paidMonth) / 1e6 * READS.pricePerMillion).toFixed(2)])),
  };
}

/** Rows read a day a daily player brings: their own, and the periodic
 *  jobs' over the `islandsADailyPlayer` islands each stands for. */
function readsADay(result, islandsADailyPlayer) {
  const periodic = Object.values(result.periodicReadsADayAnIsland).reduce((a, v) => a + v, 0);
  return result.readsPerPlayerDay + periodic * islandsADailyPlayer;
}

/** Rows read a month at `players` monthly players, a third playing a day. */
export function readsAMonth(result, players) {
  const [dn, dd] = facts.DAILY_SHARE;
  return (players * dn / dd) * readsADay(result, dd / dn) * 30;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const results = ["engaged", "regular", "casual"].map((archetype) =>
    run({ players: arg("players", 60), days: arg("days", 3), archetype }));
  const report = results.map((r) => ({ ...r, against: against(r) }));
  if (process.argv.includes("--check")) {
    const kept = JSON.parse(readFileSync(new URL("./load.json", import.meta.url), "utf8"));
    const writesOf = (rs) => JSON.stringify(rs.map((r) => [r.archetype, r.byOperation, r.billedByOperation,
                                                           r.periodicWritesADay]));
    if (writesOf(kept) !== writesOf(report)) {
      console.error("server/load.json is stale: the rows a heist writes have moved. " +
                    "Run node server/load.mjs --write, and say why in the register.");
      process.exit(1);
    }
    console.log(`server/load.json matches: ${report.map((r) => `${r.archetype} ${r.billedRowsPerPlayerDay}`).join(", ")} ` +
                `billed rows a player a day; written ${report.map((r) => `${r.archetype} ${r.writesPerPlayerDay}`).join(", ")}, ` +
                `against §24.1's ${report.map((r) => facts.WRITE_BUDGET[r.archetype]).join(", ")}`);
    process.exit(0);
  }
  if (process.argv.includes("--write")) {
    writeFileSync(new URL("./load.json", import.meta.url), `${JSON.stringify(report, null, 1)}\n`);
  }
  if (process.argv.includes("--json")) {
    console.log(JSON.stringify(report, null, 1));
  } else {
    for (const r of report) {
      console.log(`${r.archetype}: ${r.players} players x ${r.days} days, ${r.sessionsPerDay} sessions and ` +
                  `${r.heistsPerDay} heists a day`);
      console.log(`  ${r.writesPerPlayerDay} rows written a player a day, ${r.billedRowsPerPlayerDay} as D1 bills ` +
                  `them with their index entries, against §24.1's budget of ${r.against.budget}: ${r.against.overBudget}x`);
      for (const [k, v] of Object.entries(r.byOperation)) console.log(`    ${String(v).padStart(7)}  ${k}`);
      for (const [k, v] of Object.entries(r.periodicWritesADay)) console.log(`    ${String(v).padStart(7)}  ${k}, a day in all`);
      console.log(`  a validation takes ${r.validationMs.p50} ms (p95 ${r.validationMs.p95}, max ` +
                  `${r.validationMs.max}); the free plan allows ${r.against.freeCpuMs} ms a request`);
      console.log(`  the free plan's daily writes carry ${r.against.freePlanPlayersADay} such players a day`);
      console.log(`  paid plan, a third of monthly players playing a day (§25.1): ${JSON.stringify(r.against.paidDollarsAMonth)} dollars a month`);
      console.log(`  ${r.readsPerPlayerDay} rows read a player a day (by day ${r.readsPerPlayerByDay.join(", ")}), ` +
                  `against §24.1's ${r.against.readBudget}; and the periodic jobs read ` +
                  `${JSON.stringify(r.periodicReadsADayAnIsland)} a day an island`);
      for (const [k, v] of Object.entries(r.readsByOperation)) console.log(`    ${String(v).padStart(7)}  ${k}`);
      console.log(`  reads past the paid plan's 25 billion: ${JSON.stringify(r.against.readDollarsAMonth)} dollars a month`);
    }
  }
}
