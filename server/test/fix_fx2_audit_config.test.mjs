// FX2-6's audit (docs/security/audit-2026-11/server-b.md), main.mjs's
// configuration: AUD-B-14 to AUD-B-19, fixed in FX2-7-audit-b-config. The one
// proof still in stillOpen (fix_fx2_open.mjs) is AUD-B-18's guard in the
// seasons service, outside FX2-7's files: main.mjs refuses the value first.
import test from "node:test";
import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { createServer, request as httpRequest } from "node:http";
import { connect } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { server } from "./setup.mjs";
import { stillOpen } from "./fix_fx2_open.mjs";

const MAIN = fileURLToPath(new URL("../src/main.mjs", import.meta.url));
const APPLE = fileURLToPath(new URL("./fixtures/apple/", import.meta.url));
const CLEARED = ["RULEBORN_STUB_SIGNIN", "RULEBORN_GAMECENTER_ROOTS", "RULEBORN_STOREKIT_ROOTS", "RULEBORN_BUNDLE_ID",
  "RULEBORN_MAX_CONNECTIONS", "RULEBORN_HEADERS_TIMEOUT_MS", "RULEBORN_SEASON_START", "RULEBORN_REPLAYS_MIN_FREE_MB",
  "RULEBORN_APPLE_ROOTS"];

async function freePort() {
  const s = createServer();
  await new Promise((d) => s.listen(0, "127.0.0.1", d));
  const { port } = s.address();
  await new Promise((d) => s.close(d));
  return port;
}

/** main.mjs with real (Google) sign-in, the journal on its own folder, and
 *  `env` over that: resolves once it listens or exits. */
async function boot(env = {}) {
  const dir = mkdtempSync(join(tmpdir(), "rb-fx2-config-"));
  const port = await freePort();
  const all = { ...process.env };
  for (const k of CLEARED) delete all[k];
  Object.assign(all, { RULEBORN_DATA: join(dir, "data"), RULEBORN_GOOGLE_CLIENT_IDS: "audit.test",
    RULEBORN_PEER_HEADER: "x-real-ip", RULEBORN_DELETIONS: join(dir, "journal") }, env);
  const child = spawn(process.execPath, ["--no-warnings", MAIN, String(port)], { env: all, stdio: ["ignore", "pipe", "pipe"] });
  const exited = new Promise((d) => child.on("exit", d));
  let stderr = "";
  child.stderr.on("data", (b) => { stderr += b; });
  const started = await new Promise((done) => {
    let said = "";
    child.stdout.on("data", (b) => { said += b; if (said.includes("ruleborn server on")) done(true); });
    child.on("exit", () => done(false));
  });
  const stop = async () => { child.kill(); await exited; rmSync(dir, { recursive: true, force: true }); };
  return { started, port, dir, stderr: () => stderr, stop };
}

/** Whether a socket whose headers never finish is closed within `ms`. */
function closedWithin(port, ms) {
  return new Promise((done) => {
    const s = connect(port, "127.0.0.1", () => s.write("GET /v1/rules HTTP/1.1\r\nHost: x\r\n"));
    const timer = setTimeout(() => { s.destroy(); done(false); }, ms);
    s.on("data", () => {});
    s.on("error", () => {});
    s.on("close", () => { clearTimeout(timer); done(true); });
  });
}

function get(port) {
  return new Promise((done) => {
    const r = httpRequest({ host: "127.0.0.1", port, path: "/v1/rules", agent: false }, (res) => { res.resume(); done(res.statusCode); });
    r.on("error", (e) => done(e.code));
    r.setTimeout(3000, () => { r.destroy(); done("timeout"); });
    r.end();
  });
}

async function booted(env, check) {
  const run = await boot(env);
  try { await check(run); } finally { await run.stop(); }
}

// `new Store("")` is the in-memory store, so the journal must never be built
// on an empty value: with stubbed sign-in (where a journal inside the data
// folder is only warned), the default folder is the one checked and used.
test("AUD-B-14: an empty RULEBORN_DELETIONS keeps the deletion journal on disk, in the folder checked (F50, SEC-38)", () =>
  booted({ RULEBORN_DELETIONS: "", RULEBORN_STUB_SIGNIN: "1" }, (run) => {
    assert.equal(run.started, true);
    assert.equal(existsSync(join(run.dir, "data", "deletions")), true, "the journal's folder is on disk");
    assert.match(run.stderr(), /RULEBORN_DELETIONS is inside RULEBORN_DATA/, "the folder checked is that folder");
  }));

test("AUD-B-14: main.mjs refuses to start with real sign-in and RULEBORN_DELETIONS empty", () =>
  booted({ RULEBORN_DELETIONS: "" }, (run) => assert.equal(run.started, false)));

test("AUD-B-15: Game Center and StoreKit roots without RULEBORN_BUNDLE_ID are refused, not switched off", async () => {
  for (const roots of [{ RULEBORN_GAMECENTER_ROOTS: join(APPLE, "root.pem") }, { RULEBORN_STOREKIT_ROOTS: join(APPLE, "root.pem") },
    { RULEBORN_GAMECENTER_ROOTS: join(APPLE, "root.pem"), RULEBORN_STOREKIT_ROOTS: join(APPLE, "root.pem") }]) {
    await booted(roots, (run) => assert.equal(run.started, false, Object.keys(roots).join(" and ")));
  }
});

test("AUD-B-16: an empty RULEBORN_MAX_CONNECTIONS keeps the default, not 0", () =>
  booted({ RULEBORN_MAX_CONNECTIONS: "" }, async (run) => {
    assert.equal(run.started, true);
    const status = await get(run.port);
    assert.equal(typeof status, "number", `the listener answers (got ${status})`);
  }));

test("AUD-B-16: an unreadable RULEBORN_MAX_CONNECTIONS is refused at startup, not taken as no cap", async () => {
  for (const value of ["abc", "0", "-1", "1.5"]) {
    await booted({ RULEBORN_MAX_CONNECTIONS: value }, (run) => assert.equal(run.started, false, value));
  }
});

test("the defaults close a socket whose headers never finish within 12.5 s (SEC-34)", () =>
  booted({}, async (run) => {
    assert.equal(run.started, true);
    assert.equal(typeof await get(run.port), "number", "the listener answers");
    assert.equal(await closedWithin(run.port, 12_500), true);
  }));

test("AUD-B-17: an empty RULEBORN_HEADERS_TIMEOUT_MS keeps the 10 s headers timeout (SEC-34)", () =>
  booted({ RULEBORN_HEADERS_TIMEOUT_MS: "" }, async (run) => {
    assert.equal(run.started, true);
    assert.equal(await closedWithin(run.port, 12_500), true);
  }));

test("AUD-B-18: an unreadable RULEBORN_SEASON_START is refused at startup", () =>
  booted({ RULEBORN_SEASON_START: "next monday" }, (run) => assert.equal(run.started, false)));

// The seasons service's own guard (seasons.mjs, outside FX2-7's files): main.mjs
// now refuses the value above before it reaches the service.
test("AUD-B-18: with seasonStart NaN there is no current season", () => {
  const { service } = server({ seasonStart: NaN });
  return stillOpen("AUD-B-18 (seasons.mjs)", () => assert.ok(service.seasons.current(), "the current season is a row"));
});

test("AUD-B-19: an empty RULEBORN_REPLAYS_MIN_FREE_MB keeps the 512 MiB floor (SEC-18)", () => {
  // main.mjs's own expression for the floor, evaluated with the variable empty,
  // after main.mjs's own reading of its settings (`settled`) where it has one.
  const source = readFileSync(MAIN, "utf8");
  const expr = source.match(/minFreeBytes:\s*([^}]+?)\s*\}/)?.[1];
  if (!expr) throw new Error("main.mjs's minFreeBytes expression moved: update this proof");
  const env = { RULEBORN_REPLAYS_MIN_FREE_MB: "" };
  const settled = source.match(/^function settled\(env\) \{\n[\s\S]*?\n\}$/m)?.[0];
  if (settled) new Function(`${settled}\nreturn settled;`)()(env);
  const floor = new Function("process", `return ${expr};`)({ env });
  assert.equal(floor, 512 * 2 ** 20);
});
