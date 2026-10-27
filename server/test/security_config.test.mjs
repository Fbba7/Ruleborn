// Security review, second pass: the server as it is deployed — the listener
// in main.mjs, its headers and its configuration (docs/security/review.md,
// SR-21 onwards). Each test failed before its fix.

import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { request as httpRequest } from "node:http";
import { mkdtempSync, readFileSync, statSync } from "node:fs";
import { createServer as createNetServer } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { DELETE_COOKIE } from "../src/auth_http.mjs";
import { handler } from "../src/http.mjs";
import { WEB, real } from "./auth_fixtures.mjs";
import { server } from "./setup.mjs";

const PUBLIC = "play.ruleborn.example";

/** A request as main.mjs's listener makes it: the URL rebuilt on localhost
 *  from the path alone, the headers the proxy passed on as they came. */
const listened = (path, { method = "GET", headers = {}, body } = {}) =>
  new Request(`http://localhost${path}`, { method, headers: { host: PUBLIC, ...headers }, body });

// SR-21: the deletion page's same-origin check compared the browser's Origin
// with the request URL's — always http://localhost behind main.mjs — so every
// real browser's deletion was refused as cross-site, and §20.5's deletion
// "from a web page" never worked once deployed.
test("SR-21: the web deletion page deletes from its own site as deployed, and still from no other", async () => {
  const main = readFileSync(new URL("../src/main.mjs", import.meta.url), "utf8");
  assert.match(main, /new Request\(`http:\/\/localhost\$\{req\.url\}`, \{\s*method: req\.method, headers: req\.headers,/,
               "the listener rebuilds the URL as this test does");
  const r = real();
  const handle = handler(r.t.service, { webClientId: WEB });
  await r.signIn({ idToken: r.idToken({ nonce: r.t.service.auth.nonce().nonce }) });
  const served = await handle(listened("/account/delete"));
  const nonce = /data-nonce="([^"]+)"/.exec(await served.text())[1];
  const cookie = `${DELETE_COOKIE}=${nonce}`;
  const post = (origin, site = "same-origin") => handle(listened("/v1/account/delete", {
    method: "POST", body: JSON.stringify({ idToken: r.idToken({ aud: WEB, nonce }) }),
    headers: { "content-type": "application/json", cookie, origin, "sec-fetch-site": site } }));
  const status = async (res) => [res.status, (await res.json()).error ?? null];

  for (const foreign of [`https://evil.example`, `https://${PUBLIC}.evil.example`, "null"]) {
    assert.deepEqual(await status(await post(foreign)), [403, "cross_site"], foreign);
  }
  assert.deepEqual(await status(await post(`https://${PUBLIC}`, "cross-site")), [403, "cross_site"]);
  const deleted = await post(`https://${PUBLIC}`);
  assert.equal(deleted.status, 200, "the page's own site deletes");
  assert.equal((await deleted.json()).deleted, true);
});

// SR-22: a player's own answers — their balance, their friends — went out
// with no word on caching, so a cache between the phone and the server (a
// proxy, an edge rule caching everything) was free to keep and serve them. Now every answer that does
// not say its own caching says no-store; the public, hashed files keep theirs.
test("SR-22: a player's own answers are never kept by a cache; bundles and pages keep their own rules", async () => {
  const t = server();
  const { token } = await (await t.handle(new Request("https://edge.example/v1/session", {
    method: "POST", headers: { "content-type": "application/json" },
    body: JSON.stringify({ credential: "gc:cached" }) }))).json();
  const get = (path) => t.handle(new Request(`https://edge.example${path}`, { headers: { authorization: `Bearer ${token}` } }));
  for (const path of ["/v1/balance", "/v1/friends", "/v1/no-such-route"]) {
    assert.equal((await get(path)).headers.get("cache-control"), "no-store", path);
  }
  const bundle = t.service.publish(t.service.session("gc:island").account, t.build.exampleIsland(true)).bundle;
  assert.equal((await get(`/v1/bundles/${bundle}`)).headers.get("cache-control"), "public, max-age=31536000, immutable");
});

/** The server as deployed: main.mjs on a free port, its data in `dir`. */
async function listening(dir) {
  const port = await new Promise((done) => {
    const probe = createNetServer().listen(0, "127.0.0.1", () => {
      const { port: p } = probe.address();
      probe.close(() => done(p));
    });
  });
  const child = spawn(process.execPath, ["--no-warnings", fileURLToPath(new URL("../src/main.mjs", import.meta.url)),
                                         String(port)],
                      { env: { ...process.env, RULEBORN_DATA: dir }, stdio: ["ignore", "pipe", "pipe"] });
  await new Promise((done, fail) => {
    let said = "";
    child.stdout.on("data", (b) => { said += b; if (said.includes("ruleborn server on")) done(); });
    child.on("exit", (code) => fail(new Error(`main.mjs exited ${code}: ${said}`)));
  });
  return { port, stop: () => child.kill() };
}

// SR-21 again, through the real listener; and SR-23: the data directory —
// the database names every player, their identities and push tokens — was
// made 0755 with the database 0644, readable by every user on the machine.
test("SR-21 and SR-23, as deployed: the deletion page's own site passes the listener, and the data is the server's alone", async () => {
  const dir = join(mkdtempSync(join(tmpdir(), "rb-sr23-")), "data");
  const server = await listening(dir);
  try {
    // node:http, as a proxy sends it: fetch would write its own Host.
    const post = (origin) => new Promise((done, fail) => {
      const req = httpRequest({ host: "127.0.0.1", port: server.port, path: "/v1/account/delete", method: "POST",
                                headers: { host: PUBLIC, origin, "sec-fetch-site": "same-origin",
                                           "content-type": "application/json" } }, (res) => {
        let text = "";
        res.on("data", (b) => { text += b; });
        res.on("end", () => done(JSON.parse(text)));
      });
      req.on("error", fail);
      req.end(JSON.stringify({ idToken: "x" }));
    });
    assert.notEqual((await post(`https://${PUBLIC}`)).error, "cross_site", "the page's own site reaches the token check");
    assert.equal((await post("https://evil.example")).error, "cross_site");
  } finally {
    server.stop();
  }
  assert.equal(statSync(dir).mode & 0o077, 0, "nobody else enters the data directory");
});
