// The deep security run's fixes for the database's locking and the
// background jobs (SEC-32, SEC-20): a brief lock held by another process is
// waited out, a failed rollback never hides the first error, housekeeping
// works in short transactions, and a job that throws is logged and set aside
// instead of ending the process.

import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { open, transaction } from "../src/db.mjs";
import { T0, openPlan, play, twoPlayers } from "./setup.mjs";

const DAY = 24 * 60 * 60 * 1000;

/** A child process that holds the write lock on `file` for `ms`, and says
 *  "locked" once it has it. */
function holdLock(file, ms) {
  const child = spawn(process.execPath, ["--no-warnings", "-e", `
    const { DatabaseSync } = require("node:sqlite");
    const db = new DatabaseSync(${JSON.stringify(file)});
    db.exec("BEGIN IMMEDIATE");
    process.stdout.write("locked\\n");
    setTimeout(() => { db.exec("COMMIT"); db.close(); }, ${ms});
  `], { stdio: ["ignore", "pipe", "inherit"] });
  const ready = new Promise((resolve, reject) => {
    child.stdout.on("data", (d) => { if (String(d).includes("locked")) resolve(); });
    child.on("error", reject);
  });
  const done = new Promise((resolve) => child.on("exit", resolve));
  return { ready, done };
}

test("SEC-32: a write lock held briefly by another process is waited out, not thrown", async () => {
  const dir = mkdtempSync(join(tmpdir(), "rb-sec32-"));
  try {
    const file = join(dir, "db.sqlite");
    const db = open(file);
    const lock = holdLock(file, 300);
    await lock.ready;
    const started = Date.now();
    // Synchronous: it blocks this process until the child commits.
    transaction(db, () => db.exec("CREATE TABLE IF NOT EXISTS sec32 (x)"));
    assert.ok(Date.now() - started >= 100, "it waited for the other process's lock");
    db.close();
    await lock.done;
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

test("SEC-32: a rollback that fails itself never hides the first error", () => {
  const first = new Error("the first error");
  const db = {
    isTransaction: true,
    exec(sql) {
      if (sql === "ROLLBACK") throw new Error("the rollback failed");
    },
  };
  assert.throws(() => transaction(db, () => { throw first; }), (err) => {
    assert.equal(err, first);
    assert.equal(err.rollback?.message, "the rollback failed");
    return true;
  });
});

test("SEC-32: expired replays are marked in short transactions, not one long one", () => {
  const t = twoPlayers(true);
  const lease = t.service.lease(t.raider.account, t.bundle);
  t.service.submit(t.raider.account, lease.token, play(t, lease, { plan: openPlan() }));
  const db = t.service.db;
  // 450 more heists with the same row, under tokens no lease names.
  db.exec("PRAGMA foreign_keys = OFF");
  const insert = db.prepare(`INSERT INTO heists (token, attacker, bundle, seed, log_hash, state_hash, validated,
    outcome, review, grace, submitted_at, day, replay_gone, defender)
    SELECT ?, attacker, bundle, seed, log_hash, state_hash, validated, outcome, review, grace, submitted_at, day,
      replay_gone, defender FROM heists WHERE token = ?`);
  for (let i = 0; i < 450; i++) insert.run(`sec32-${i}`, lease.token);
  db.exec("PRAGMA foreign_keys = ON");
  let begins = 0;
  const exec = db.exec.bind(db);
  db.exec = (sql) => {
    if (sql === "BEGIN IMMEDIATE") begins++;
    return exec(sql);
  };
  t.clock.now = T0 + 91 * DAY;
  assert.equal(t.service.expireReplays(), 451);
  assert.equal(begins, 3, "451 rows in chunks of 200");
  assert.equal(db.prepare("SELECT COUNT(*) AS n FROM heists WHERE replay_gone = 0").get().n, 0);
  assert.equal(t.service.expireReplays(), 0, "once");
});

test("SEC-20: a hold measurement that throws is logged and set aside, never thrown again", (ctx) => {
  const t = twoPlayers(false);
  const build = t.service.builds.current;
  const had = Object.getOwnPropertyDescriptor(build, "hold");
  build.hold = () => { throw new Error("a trap in the simulation"); };
  const logged = [];
  ctx.mock.method(console, "error", (...args) => logged.push(args.join(" ")));
  try {
    t.service.db.prepare("UPDATE island_holds SET raids = 30").run();
    const before = t.service.matchmaking.islandRating(t.defender.account, "heart");
    t.service.holds.work(2);
    const row = t.service.db.prepare("SELECT * FROM island_holds WHERE bundle = ?").get(t.bundle);
    assert.notEqual(row.measured_at, null, "marked, so it is never picked again");
    assert.equal(row.played, row.raids, "and reads as finished");
    assert.equal(t.service.holds.work(2), 0, "the next turn picks nothing");
    assert.deepEqual(t.service.matchmaking.islandRating(t.defender.account, "heart"), before,
                     "no prior from a measurement that failed");
    assert.ok(logged.some((line) => line.includes(`hold ${t.bundle.slice(0, 12)}:`)), "and the failure is logged");
  } finally {
    if (had) Object.defineProperty(build, "hold", had);
    else delete build.hold;
  }
});

test("SEC-20: every background job in main.mjs runs under a guard that logs and goes on", () => {
  const main = readFileSync(new URL("../src/main.mjs", import.meta.url), "utf8");
  assert.match(main, /const guarded = \(name, fn\) => \(\) => \{/);
  // No timer is armed with a bare body: each takes a guarded job.
  for (const m of main.matchAll(/setInterval\(([^,]+),/g)) {
    assert.match(m[1], /^(guarded\(|lists$|rollover$|compact$|expireReplays$|tidy$)/, m[0]);
  }
  const tidy = /const tidy = \(\) => \{([\s\S]*?)\n\};/.exec(main)[1];
  for (const job of ["notifications.expire", "friends.expire", "expireLapsed", "auth.expire", "fund.closeEnded",
                     "shop.voided"]) {
    assert.match(tidy, new RegExp(`guarded\\("[^"]+", \\(\\) => service\\.${job.replace(".", "\\.")}\\(`), job);
  }
  assert.doesNotMatch(main, /uncaughtException/, "a throw outside the jobs still stops the process");
});

/** What main.mjs writes to standard error by the time it is listening, as a
 *  deployment with real sign-in (a Google client id; its keys are fetched
 *  only at a sign-in; the proxy's address header it requires, SEC-36) and
 *  `env`; stopped once it says it is up. */
async function startupWarnings(env) {
  const dir = mkdtempSync(join(tmpdir(), "rb-sec38-"));
  const all = { ...process.env, RULEBORN_DATA: join(dir, "data"), RULEBORN_GOOGLE_CLIENT_IDS: "sec38.test",
                RULEBORN_PEER_HEADER: "x-real-ip", ...env(dir) };
  for (const k of ["RULEBORN_STUB_SIGNIN", "RULEBORN_GAMECENTER_ROOTS", "RULEBORN_DELETIONS"]) {
    if (!(k in env(dir))) delete all[k];
  }
  for (const [k, v] of Object.entries(all)) if (v === undefined) delete all[k];
  const child = spawn(process.execPath, ["--no-warnings", fileURLToPath(new URL("../src/main.mjs", import.meta.url)), "0"],
                      { env: all, stdio: ["ignore", "pipe", "pipe"] });
  let stderr = "";
  child.stderr.on("data", (b) => { stderr += b; });
  try {
    await new Promise((done, fail) => {
      let said = "";
      child.stdout.on("data", (b) => { said += b; if (said.includes("ruleborn server on")) done(); });
      child.on("exit", (code) => fail(new Error(`main.mjs exited ${code}: ${stderr}`)));
    });
    return stderr;
  } finally {
    const gone = new Promise((done) => child.on("exit", done));
    child.kill();
    await gone;
    rmSync(dir, { recursive: true, force: true });
  }
}

test("SEC-38: a deployment is warned when its deletions journal sits inside its data folder", async () => {
  assert.match(await startupWarnings(() => ({})), /RULEBORN_DELETIONS is inside RULEBORN_DATA/,
               "the default, a folder beside the database");
  assert.doesNotMatch(await startupWarnings((dir) => ({ RULEBORN_DELETIONS: join(dir, "journal") })),
                      /RULEBORN_DELETIONS is inside/, "a journal on its own storage is not");
  assert.doesNotMatch(await startupWarnings(() => ({ RULEBORN_STUB_SIGNIN: "1", RULEBORN_GOOGLE_CLIENT_IDS: undefined })), /RULEBORN_DELETIONS is inside/,
                      "nor a local server with stubbed sign-in");
});
