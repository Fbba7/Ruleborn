// The deep security run's fixes at the edge and in the request paths
// (SEC-23 onwards): each request's work is bounded, and what it answers
// shows no more than its caller may see.

import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { connect, createServer as createNetServer } from "node:net";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { handler } from "../src/http.mjs";
import { KINDS } from "../src/limits.mjs";
import { confirm, MAX_ACTIONS } from "../src/offline.mjs";
import { openPlan, play, server } from "./setup.mjs";

test("SEC-23: an offline batch of weaves builds the weaving view once, not once a weave", (ctx) => {
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:sec23").account;
  t.service.universe.ensure(me, t.clock.now);
  const views = ctx.mock.method(t.service.weaving, "view");
  const actions = Array.from({ length: MAX_ACTIONS }, () => ({ do: "unweave", realm: "heart", slot: 1 }));
  const answer = confirm(t.service, me, actions);
  assert.equal(answer.results.length, MAX_ACTIONS);
  assert.ok(answer.results.every((r) => r.confirmed && r.repeated), "an empty slot is answered as emptied");
  assert.ok(answer.weaving, "the batch still answers with what is woven");
  assert.equal(views.mock.callCount(), 1, "one view, after the whole queue");
  // A weave asked for on its own still answers with the view.
  const one = t.service.weaving.unweave(me, { realm: "heart", slot: 1 });
  assert.ok(one.weaving);
  assert.equal(one.repeated, true);
});

/** A Request to the edge function, as the HTTP tests make one. */
const call = (t, method, path, { token, json, peer, handle = t.handle } = {}) => handle(new Request(
  `https://edge.example${path}`, {
    method,
    headers: { ...(token ? { authorization: `Bearer ${token}` } : {}),
               ...(json ? { "content-type": "application/json" } : {}),
               ...(peer ? { "x-peer": peer } : {}) },
    body: json ? JSON.stringify(json) : undefined,
  }));

test("SEC-34: a sign-in nonce is held to its address where the deployment says it, and only there", async () => {
  const t = server();
  const handle = handler(t.service, { peerOf: (r) => r.headers.get("x-peer") });
  for (let i = 0; i < KINDS.unsigned.burst; i++) {
    assert.equal((await call(t, "POST", "/v1/session/nonce", { peer: "198.51.100.7", handle })).status, 200, `nonce ${i}`);
  }
  assert.equal((await call(t, "POST", "/v1/session/nonce", { peer: "198.51.100.7", handle })).status, 429);
  assert.equal((await call(t, "POST", "/v1/session/nonce", { peer: "198.51.100.8", handle })).status, 200,
               "another address has its own bucket");
  // With no address to tell callers apart, no shared bucket holds them all.
  for (let i = 0; i < KINDS.unsigned.burst + 5; i++) {
    assert.equal((await call(t, "POST", "/v1/session/nonce")).status, 200);
  }
});

test("SEC-44: a constellation appointment of the wrong shape is refused 400, not bound into SQL", async () => {
  const t = server();
  const me = t.service.session("gc:sec44");
  for (const json of [{ account: true, role: "elder" }, { account: "x", role: ["elder"] }, { role: "elder" }]) {
    const r = await call(t, "POST", "/v1/constellations/c1/roles", { token: me.token, json });
    assert.equal(r.status, 400, JSON.stringify(json));
    assert.equal((await r.json()).error, "malformed_body");
  }
});

test("SEC-44: a Workshop entry's remixOf of the wrong shape is refused 400, and a missing parent costs no simulation", async (ctx) => {
  const t = server();
  const me = t.service.session("gc:sec44");
  const island = t.build.exampleIsland(true);
  const cleared = play(t, { bundle: t.service.store.put(island), seed: "7", ticks: 150 * 30 }, { plan: openPlan() });
  const b64 = (u8) => Buffer.from(u8).toString("base64");
  const entry = (remixOf) => ({ bundle: b64(island), replay: b64(cleared), adjective: 0, noun: 1, remixOf });
  const verify = ctx.mock.method(t.service.builds.current, "verify");
  const wrong = await call(t, "POST", "/v1/workshop", { token: me.token, json: entry([1]) });
  assert.equal(wrong.status, 400);
  assert.equal((await wrong.json()).error, "malformed_body");
  const none = await call(t, "POST", "/v1/workshop", { token: me.token, json: entry("no-such-item") });
  assert.equal(none.status, 404);
  assert.equal((await none.json()).error, "no_such_island");
  assert.equal(verify.mock.callCount(), 0, "neither re-simulated the replay");
  const made = await call(t, "POST", "/v1/workshop", { token: me.token, json: entry(undefined) });
  assert.equal(made.status, 201, "an entry with no remixOf is published as before");
});

/** main.mjs on a free port, its data in a new directory, with `env`. */
async function listening(env = {}) {
  const dir = join(mkdtempSync(join(tmpdir(), "rb-sec34-")), "data");
  const port = await new Promise((done) => {
    const probe = createNetServer().listen(0, "127.0.0.1", () => {
      const { port: p } = probe.address();
      probe.close(() => done(p));
    });
  });
  const child = spawn(process.execPath, ["--no-warnings", fileURLToPath(new URL("../src/main.mjs", import.meta.url)),
                                         String(port)],
                      { env: { ...process.env, RULEBORN_DATA: dir, RULEBORN_STUB_SIGNIN: "1", ...env },
                        stdio: ["ignore", "pipe", "pipe"] });
  let stderr = "";
  child.stderr.on("data", (b) => { stderr += b; });
  await new Promise((done, fail) => {
    let said = "";
    child.stdout.on("data", (b) => { said += b; if (said.includes("ruleborn server on")) done(); });
    child.on("exit", (code) => fail(new Error(`main.mjs exited ${code}: ${said}`)));
  });
  return {
    port, stderr: () => stderr,
    stop: () => { child.kill(); rmSync(dirname(dir), { recursive: true, force: true }); },
  };
}

/** What the server writes back on a raw socket after `text`, and whether
 *  it closed the socket, within `ms`. */
function raw(port, text, ms) {
  return new Promise((done, fail) => {
    const socket = connect(port, "127.0.0.1");
    let got = "";
    const timer = setTimeout(() => { socket.destroy(); done({ got, closed: false }); }, ms);
    socket.on("data", (b) => { got += b; });
    socket.on("close", () => { clearTimeout(timer); done({ got, closed: true }); });
    socket.on("error", (err) => { if (err.code !== "ECONNRESET") fail(err); });
    socket.write(text);
  });
}

test("SEC-34: an unknown method is answered 405 with no stack in the log, and a half-sent header is cut off", async () => {
  const server = await listening({ RULEBORN_HEADERS_TIMEOUT_MS: "500" });
  try {
    const trace = await raw(server.port, "TRACE /v1/x HTTP/1.1\r\nhost: localhost\r\nconnection: close\r\n\r\n", 5_000);
    assert.match(trace.got, /^HTTP\/1\.1 405 /);
    assert.match(trace.got, /"method_not_allowed"/);
    assert.doesNotMatch(server.stderr(), /TypeError|at new Request|    at /, "no stack");
    const slow = await raw(server.port, "GET /v1/balance HTTP/1.1\r\nhost: loc", 5_000);
    assert.equal(slow.closed, true, "the server closed a socket whose headers never came");
  } finally {
    server.stop();
  }
});

test("SEC-34: the listener's timeouts and connection cap are set, the cap from RULEBORN_MAX_CONNECTIONS", () => {
  const main = readFileSync(new URL("../src/main.mjs", import.meta.url), "utf8");
  assert.match(main, /process\.env\.RULEBORN_HEADERS_TIMEOUT_MS \?\? 10_000/);
  assert.match(main, /requestTimeout: Math\.max\(30_000, headersTimeout\), keepAliveTimeout: 5_000/);
  assert.match(main, /listener\.maxConnections = Number\(process\.env\.RULEBORN_MAX_CONNECTIONS \?\? 2048\)/);
});
