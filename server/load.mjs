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

const facts = JSON.parse(readFileSync(new URL("./src/facts.json", import.meta.url), "utf8"));
const WASM = new URL("../sim/target/wasm32-unknown-unknown/release/ruleborn_sim.wasm", import.meta.url);
const DAY = 24 * 60 * 60 * 1000;
const T0 = Date.UTC(2026, 8, 23, 6, 0, 0);

const arg = (name, fallback) => {
  const i = process.argv.indexOf(`--${name}`);
  return i < 0 ? fallback : Number(process.argv[i + 1]);
};

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
    verifyPlatform: (c) => c, now: () => clock.now, random, seasonStart: T0,
  });
  const db = service.db;
  const changes = () => Number(db.prepare("SELECT total_changes() AS n").get().n);
  const writes = {};
  const count = (what, fn) => {
    const before = changes();
    const out = fn();
    writes[what] = (writes[what] ?? 0) + changes() - before;
    return out;
  };

  // The population: established players, each with an island of its own.
  const accounts = [];
  const bundles = [];
  for (let i = 0; i < players; i++) {
    const { account } = service.session(`gc:load-${i}`);
    db.prepare("UPDATE accounts SET created_at = ? WHERE id = ?").run(T0 - 4 * DAY, account);
    const island = build.exampleIsland(i % 2 === 0);
    island[5] = 1 + (Math.floor(i / 2) % 10);              // Vault level: a distinct island each
    island[6] = i & 255;                                   // and a distinct exposure
    bundles.push(service.publish(account, island).bundle);
    accounts.push(account);
  }
  service.targetLists();
  for (const k of Object.keys(writes)) delete writes[k];

  const [sessions, heists] = ARCHETYPES[archetype];
  const cpu = [];
  const baseline = changes();
  for (let d = 0; d < days; d++) {
    for (let s = 0; s < sessions; s++) {
      clock.now = T0 + d * DAY + s * 3 * 60 * 60 * 1000;
      for (let i = 0; i < players; i++) {
        count("session", () => service.session(`gc:load-${i}`));
        count("telemetry batch", () => service.telemetry.batch(accounts[i], [
          { kind: "session_end", data: { seconds: 300, crashed: false } },
          { kind: "worth", data: { rating: 4 } },
        ]));
        if (s >= heists) continue;
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
    clock.now = T0 + d * DAY + 23 * 60 * 60 * 1000;
    // The periodic jobs, amortised over the day's players: 96 target-list
    // runs a day (every fifteen minutes), one telemetry compaction.
    count("target lists (x96)", () => { for (let k = 0; k < 96; k++) service.targetLists(); });
    count("telemetry compaction", () => service.telemetry.compact());
  }
  cpu.sort((a, b) => a - b);
  const pct = (p) => cpu[Math.min(cpu.length - 1, Math.floor(p * cpu.length))];
  const playerDays = players * days;
  // The periodic jobs write per band and per day, not per player: counted
  // apart, as a day's total, so a small population does not inflate them.
  const PERIODIC = ["target lists (x96)", "telemetry compaction"];
  const perPlayer = Object.entries(writes).filter(([k]) => !PERIODIC.includes(k));
  const perDay = Object.fromEntries(perPlayer.map(([k, v]) => [k, +(v / playerDays).toFixed(2)]));
  const total = perPlayer.reduce((a, [, v]) => a + v, 0);
  return {
    archetype, players, days, heistsPerDay: heists, sessionsPerDay: sessions,
    writesPerPlayerDay: +(total / playerDays).toFixed(2),
    periodicWritesADay: Object.fromEntries(PERIODIC.map((k) => [k, (writes[k] ?? 0) / days])),
    writesPerHeist: +((writes["heist: validate and grant"] + writes.lease) / (playerDays * heists)).toFixed(2),
    byOperation: perDay,
    validationMs: { p50: +pct(0.5).toFixed(1), p95: +pct(0.95).toFixed(1), max: +cpu[cpu.length - 1].toFixed(1) },
  };
}

/** What the measurements do to §24.1's budget and cost table. */
export function against(result) {
  const [budget, included, price, freeWrites, freeCpu] = [facts.WRITE_BUDGET, facts.PAID_WRITES_MONTH,
    facts.WRITE_PRICE_PER_MILLION, facts.FREE_WRITES_DAY, facts.FREE_CPU_MS];
  // §25.1's gate: "a third of monthly players play on a given day".
  const [dn, dd] = facts.DAILY_SHARE;
  const monthly = (players) => (players * dn / dd) * result.writesPerPlayerDay * 30;
  return {
    budget, overBudget: +(result.writesPerPlayerDay / budget).toFixed(1),
    freeCpuMs: freeCpu, validationFitsFreePlan: result.validationMs.p95 <= freeCpu,
    freePlanPlayersADay: Math.floor(freeWrites / result.writesPerPlayerDay),
    // Monthly players, a third of them playing on a day, each a day of this
    // player's: an engaged population is the ceiling, a casual one the floor.
    paidDollarsAMonth: Object.fromEntries([1_000, 10_000, 100_000, 1_000_000].map((p) =>
      [p, +(5 + Math.max(0, monthly(p) - included) / 1e6 * price).toFixed(0)])),
  };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const results = ["engaged", "regular", "casual"].map((archetype) =>
    run({ players: arg("players", 60), days: arg("days", 3), archetype }));
  const report = results.map((r) => ({ ...r, against: against(r) }));
  if (process.argv.includes("--check")) {
    const kept = JSON.parse(readFileSync(new URL("./load.json", import.meta.url), "utf8"));
    const writesOf = (rs) => JSON.stringify(rs.map((r) => [r.archetype, r.byOperation, r.periodicWritesADay]));
    if (writesOf(kept) !== writesOf(report)) {
      console.error("server/load.json is stale: the rows a heist writes have moved. " +
                    "Run node server/load.mjs --write, and say why in the register.");
      process.exit(1);
    }
    console.log(`server/load.json matches: ${report.map((r) => `${r.archetype} ${r.writesPerPlayerDay}`).join(", ")} ` +
                `rows a player a day, against §24.1's ${facts.WRITE_BUDGET}`);
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
      console.log(`  ${r.writesPerPlayerDay} rows written a player a day, against §24.1's budget of ` +
                  `${r.against.budget}: ${r.against.overBudget}x`);
      for (const [k, v] of Object.entries(r.byOperation)) console.log(`    ${String(v).padStart(7)}  ${k}`);
      for (const [k, v] of Object.entries(r.periodicWritesADay)) console.log(`    ${String(v).padStart(7)}  ${k}, a day in all`);
      console.log(`  a validation takes ${r.validationMs.p50} ms (p95 ${r.validationMs.p95}, max ` +
                  `${r.validationMs.max}); the free plan allows ${r.against.freeCpuMs} ms a request`);
      console.log(`  the free plan's daily writes carry ${r.against.freePlanPlayersADay} such players a day`);
      console.log(`  paid plan, a third of monthly players playing a day (§25.1): ${JSON.stringify(r.against.paidDollarsAMonth)} dollars a month`);
    }
  }
}
