// The session's routes over HTTP (auth_http.mjs, docs/security/auth.md):
// sign-in, refresh, sign-out and sign-out everywhere; §24.1's limits with
// answers that never say whether an account exists; no token in a cache, a
// URL or a log; and the web deletion page's Google sign-in, bound to its
// cookie and refused from any other site (§20.11, G39).

import assert from "node:assert/strict";
import { test } from "node:test";

import { DELETE_COOKIE } from "../src/auth_http.mjs";
import { handler, routeOf } from "../src/http.mjs";
import { KINDS } from "../src/limits.mjs";
import { SESSION_MS } from "../src/tokens.mjs";
import { WEB, real } from "./auth_fixtures.mjs";
import { server } from "./setup.mjs";

const request = (path, { method = "GET", token, peer, body, headers = {} } = {}) =>
  new Request(`https://edge.example${path}`, {
    method,
    headers: { ...(token ? { authorization: `Bearer ${token}` } : {}), ...(peer ? { "x-peer": peer } : {}),
               ...(body !== undefined ? { "content-type": "application/json" } : {}), ...headers },
    body: body !== undefined ? JSON.stringify(body) : undefined });

const read = async (res) => ({ status: res.status, body: await res.json() });

test("sign in, refresh, sign out over HTTP: every answer no-store, and the session ended at once", async () => {
  const t = server();
  const signed = await t.handle(request("/v1/session", { method: "POST", body: { credential: "gc:alice" } }));
  assert.equal(signed.status, 200);
  assert.equal(signed.headers.get("cache-control"), "no-store");
  const s = await signed.json();
  assert.equal(s.expiresIn, SESSION_MS / 1000);
  assert.equal((await t.handle(request("/v1/balance", { token: s.token }))).status, 200);
  const who = await read(await t.handle(request("/v1/session", { token: s.token })));
  assert.deepEqual(who, { status: 200, body: { account: s.account, devices: 1 } });

  const refreshed = await t.handle(request("/v1/session/refresh", { method: "POST", body: { refreshToken: s.refreshToken } }));
  assert.equal(refreshed.headers.get("cache-control"), "no-store");
  const r = await refreshed.json();
  assert.equal(r.account, s.account);
  const reused = await read(await t.handle(request("/v1/session/refresh", { method: "POST",
                                                                         body: { refreshToken: s.refreshToken } })));
  assert.deepEqual(reused, { status: 401, body: { error: "session_refused" } });
  assert.equal((await t.handle(request("/v1/balance", { token: r.token }))).status, 401, "the family ended");

  const again = await (await t.handle(request("/v1/session", { method: "POST", body: { credential: "gc:alice" } }))).json();
  const out = await read(await t.handle(request("/v1/session/end", { method: "POST", token: again.token })));
  assert.deepEqual(out, { status: 200, body: { ended: 1 } });
  assert.deepEqual(await read(await t.handle(request("/v1/balance", { token: again.token }))),
                   { status: 401, body: { error: "session_refused" } });
  // Signed out with an access token past its hour: the refresh token proves it.
  const late = await (await t.handle(request("/v1/session", { method: "POST", body: { credential: "gc:alice" } }))).json();
  t.clock.now += SESSION_MS + 1;
  const ended = await read(await t.handle(request("/v1/session/end", { method: "POST",
                                                                     body: { refreshToken: late.refreshToken } })));
  assert.deepEqual(ended, { status: 200, body: { ended: 1 } });
  const nothing = await read(await t.handle(request("/v1/session/end", { method: "POST", body: { refreshToken: "r1.x" } })));
  assert.deepEqual(nothing, { status: 401, body: { error: "session_refused" } });
});

test("sign out everywhere over HTTP ends every device's session", async () => {
  const t = server();
  const devices = [];
  for (let i = 0; i < 3; i++) {
    devices.push(await (await t.handle(request("/v1/session", { method: "POST", body: { credential: "gc:alice" } }))).json());
  }
  assert.equal((await read(await t.handle(request("/v1/session", { token: devices[0].token })))).body.devices, 3);
  const out = await read(await t.handle(request("/v1/session/end", { method: "POST", token: devices[2].token,
                                                                    body: { everywhere: true } })));
  assert.deepEqual(out, { status: 200, body: { ended: 3 } });
  for (const d of devices) assert.equal((await t.handle(request("/v1/balance", { token: d.token }))).status, 401);
  const bad = await t.handle(request("/v1/session/end", { method: "POST", token: devices[0].token,
                                                         body: { everywhere: "yes" } }));
  assert.equal(bad.status, 400);
});

test("a refused session says nothing of why: forged, malformed, expired, signed out and reused alike", async () => {
  const t = server();
  const s = t.service.session("gc:alice");
  const answers = new Set();
  const ask = async (token) => answers.add(JSON.stringify(await read(await t.handle(request("/v1/balance", { token })))));
  await ask(s.token.slice(0, -1) + "A");
  await ask("");
  await ask("not a token");
  const out = t.service.session("gc:alice");
  t.service.auth.signOut(out.token);
  await ask(out.token);
  const old = t.service.session("gc:alice");
  const next = t.service.auth.refresh(old.refreshToken);
  assert.throws(() => t.service.auth.refresh(old.refreshToken));
  await ask(next.token);
  t.clock.now += SESSION_MS;
  await ask(s.token);
  assert.deepEqual([...answers], [JSON.stringify({ status: 401, body: { error: "session_refused" } })]);
});

test("a sign-in held back answers the same for an account that exists and one that does not (24.1, no enumeration)", async () => {
  const t = server();
  const handle = handler(t.service, { peerOf: (r) => r.headers.get("x-peer") });
  t.service.session("gc:exists");
  const signIn = (credential, peer) => handle(request("/v1/session", { method: "POST", peer, body: { credential } }));
  for (const who of ["gc:exists", "gc:new-one"]) {
    for (let i = 0; i < KINDS.signIns.burst; i++) await signIn(who, `198.51.100.${i}`);
  }
  const a = await signIn("gc:exists", "198.51.100.200");
  const b = await signIn("gc:new-one", "198.51.100.201");
  assert.deepEqual([a.status, a.headers.get("retry-after"), await a.json()],
                   [b.status, b.headers.get("retry-after"), await b.json()]);
  assert.equal(a.status, 429);
  // Six a minute an account: one more after its ten seconds.
  t.clock.now += KINDS.signIns.per;
  assert.equal((await signIn("gc:exists", "198.51.100.202")).status, 200);
  // A refused credential is refused alike whether or not anyone holds it.
  const no1 = await read(await signIn("not a proof", "203.0.113.1"));
  const no2 = await read(await signIn({ publicKeyUrl: "x" }, "203.0.113.1"));
  assert.deepEqual(no1, no2);
});

test("refreshes are held to the session's sign-in bucket, and a stream of bad ones holds the address back (24.1)", async () => {
  const t = server();
  const handle = handler(t.service, { peerOf: (r) => r.headers.get("x-peer") });
  const post = (path, peer, body) => handle(request(path, { method: "POST", peer, body }));
  let s = t.service.session("gc:alice");
  for (let i = 0; i < KINDS.signIns.burst; i++) {
    const r = await post("/v1/session/refresh", "198.51.100.1", { refreshToken: s.refreshToken });
    assert.equal(r.status, 200, `refresh ${i}`);
    s = await r.json();
  }
  assert.equal((await post("/v1/session/refresh", "198.51.100.1", { refreshToken: s.refreshToken })).status, 429);
  for (let i = 0; i < KINDS.failedSignIns.burst; i++) {
    assert.equal((await post("/v1/session/refresh", "203.0.113.9", { refreshToken: `r1.k0.${1000 + i}.0.x` })).status, 401);
  }
  assert.equal((await post("/v1/session/refresh", "203.0.113.9", { refreshToken: s.refreshToken })).status, 429,
               "the address is held, a good token or not");
  assert.equal((await post("/v1/session/nonce", "203.0.113.9")).status, 429, "and asks for no nonce");
  const n = await post("/v1/session/nonce", "203.0.113.10");
  assert.equal(n.status, 200);
  assert.match((await n.json()).nonce, /^n1\./);
});

test("no token reaches a log: a failing request logs its route alone, never its header, body or path's token", async () => {
  const t = server();
  const s = t.service.session("gc:alice");
  const lines = [];
  const saved = { error: console.error, log: console.log, warn: console.warn };
  for (const k of Object.keys(saved)) console[k] = (...a) => lines.push(a.map(String).join(" "));
  try {
    t.service.auth.account = () => { throw new Error("database down"); };
    const res = await t.handle(request(`/v1/heists/${s.refreshToken}/replay?token=${s.token}`, { token: s.token }));
    assert.equal(res.status, 500);
    await t.handle(request("/v1/session/refresh", { method: "POST", body: { refreshToken: s.refreshToken } }));
  } finally {
    Object.assign(console, saved);
  }
  assert.ok(lines.length > 0, "the failure was logged");
  for (const line of lines) {
    for (const secret of [s.token, s.refreshToken, s.token.split(".").at(-1), s.refreshToken.split(".").at(-1)]) {
      assert.ok(!line.includes(secret), `no token in: ${line}`);
    }
  }
  assert.equal(routeOf(`/v1/heists/${s.refreshToken}/replay?token=${s.token}`), "v1/heists");
});

/** The web deletion page's flow, with real Google sign-in. */
async function page(r, handle) {
  const res = await handle(new Request("https://edge.example/account/delete"));
  const html = await res.text();
  const nonce = /data-nonce="([^"]+)"/.exec(html)[1];
  const set = res.headers.get("set-cookie");
  return { res, html, nonce, set, cookie: `${DELETE_COOKIE}=${/=([^;]+)/.exec(set)[1]}` };
}

const remove = (handle, { idToken, cookie, origin = "https://edge.example", site = "same-origin",
                          type = "application/json" }) =>
  handle(new Request("https://edge.example/v1/account/delete", {
    method: "POST",
    headers: { "content-type": type, ...(cookie ? { cookie } : {}), ...(origin ? { origin } : {}),
               ...(site ? { "sec-fetch-site": site } : {}) },
    body: JSON.stringify({ idToken, withdrawIslands: false }) }));

test("the web deletion page serves a nonce in a host-only, script-proof cookie and a strict content policy (20.11)", async () => {
  const r = real();
  const handle = handler(r.t.service, { webClientId: WEB });
  const p = await page(r, handle);
  assert.equal(p.res.status, 200);
  assert.match(p.set, new RegExp(`^${DELETE_COOKIE}=n1\\.`));
  for (const attr of ["Secure", "HttpOnly", "SameSite=Strict", "Path=/", "Max-Age=300"]) assert.ok(p.set.includes(attr), attr);
  assert.ok(!/Domain=/i.test(p.set), "host-only");
  assert.equal(p.cookie.split("=")[1], p.nonce, "the page's nonce is the cookie's");
  const csp = p.res.headers.get("content-security-policy");
  assert.match(csp, /default-src 'none'/);
  assert.match(csp, /frame-ancestors 'none'/);
  const scriptNonce = /script-src 'nonce-([^']+)'/.exec(csp)[1];
  for (const tag of p.html.match(/<script[^>]*>/g)) assert.ok(tag.includes(`nonce="${scriptNonce}"`), tag);
  assert.ok(!p.html.includes("{{"), "every placeholder filled");
  assert.equal(p.res.headers.get("cache-control"), "no-store");
  assert.equal(p.res.headers.get("referrer-policy"), "no-referrer");
  const second = await page(r, handle);
  assert.notEqual(second.nonce, p.nonce, "a nonce a serving");
});

test("a web deletion needs the Google token that carries this browser's nonce, once, sent from this site (20.11, CSRF)", async () => {
  const r = real();
  const handle = handler(r.t.service, { webClientId: WEB });
  const me = await r.signIn({ idToken: r.idToken({ nonce: r.t.service.auth.nonce().nonce }) });
  const p = await page(r, handle);
  const idToken = r.idToken({ aud: WEB, nonce: p.nonce });
  const status = async (res) => [res.status, (await res.json()).error];
  assert.deepEqual(await status(await remove(handle, { idToken, cookie: p.cookie, origin: "https://evil.example" })),
                   [403, "cross_site"]);
  assert.deepEqual(await status(await remove(handle, { idToken, cookie: p.cookie, site: "cross-site" })),
                   [403, "cross_site"]);
  assert.deepEqual(await status(await remove(handle, { idToken, cookie: p.cookie, type: "text/plain" })),
                   [415, "json_only"]);
  assert.deepEqual(await status(await remove(handle, { idToken })), [401, "google_identity_refused"], "no cookie");
  const other = await page(r, handle);
  assert.deepEqual(await status(await remove(handle, { idToken, cookie: other.cookie })),
                   [401, "google_identity_refused"], "another browser's nonce");
  assert.deepEqual(await status(await remove(handle, { idToken: r.idToken({ aud: WEB }), cookie: p.cookie })),
                   [401, "google_identity_refused"], "a token with no nonce");
  assert.equal(r.t.service.account(me.token), me.account, "nothing deleted yet");
  const ok = await remove(handle, { idToken, cookie: p.cookie });
  assert.equal(ok.status, 200);
  assert.match(ok.headers.get("set-cookie"), /Max-Age=0/);
  assert.throws(() => r.t.service.account(me.token), (e) => e.reason === "account_deleted", "signed out at once");
  // Replayed: the nonce is spent.
  assert.deepEqual(await status(await remove(handle, { idToken, cookie: p.cookie })), [401, "google_identity_refused"]);
});
