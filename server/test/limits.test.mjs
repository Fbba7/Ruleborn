// How fast one account, or one address, may ask (G44).

import assert from "node:assert/strict";
import { test } from "node:test";

import { handler } from "../src/http.mjs";
import { KINDS, Limiter, peerKey } from "../src/limits.mjs";
import { server } from "./setup.mjs";

test("a bucket answers its burst, then says how long to wait, and refills at its rate", () => {
  const l = new Limiter({ kinds: { k: { burst: 3, per: 1000 } } });
  assert.deepEqual([0, 0, 0].map(() => l.take("k", "a", 0)), [0, 0, 0]);
  assert.equal(l.take("k", "a", 0), 1000);
  assert.equal(l.take("k", "a", 400), 600, "the wait counts down");
  assert.equal(l.take("k", "b", 400), 0, "another caller has their own");
  assert.equal(l.take("k", "a", 1000), 0, "one back after its time");
  assert.equal(l.take("k", "a", 1000), 1000);
  assert.equal(l.take("k", "a", 60_000), 0, "and full again, never more than full");
  assert.equal(l.take("k", "a", 60_000), 0);
  assert.equal(l.take("k", "a", 60_000), 0);
  assert.equal(l.take("k", "a", 60_000), 1000);
});

test("a limiter holds at most so many callers a kind, forgetting that kind's longest idle", () => {
  const l = new Limiter({ kinds: { k: { burst: 1, per: 1000 }, other: { burst: 1, per: 1000 } }, most: 2 });
  l.take("k", "a", 0);
  l.take("k", "b", 0);
  l.take("k", "a", 0);          // a is refused, and is the most recent now
  l.take("k", "c", 0);          // b, the longest idle, is forgotten
  assert.equal(l.buckets.get("k").size, 2);
  assert.ok(l.take("k", "a", 0) > 0, "a is still held to its bucket");
  assert.equal(l.take("k", "b", 0), 0, "b forgotten has a full one");
  // Callers of another kind, however many, never push this kind's out.
  for (let i = 0; i < 100; i++) l.take("other", `x${i}`, 0);
  assert.ok(l.take("k", "a", 0) > 0, "a is held still");
  assert.equal(l.buckets.get("other").size, 2);
});

test("peek says what take would, and takes nothing", () => {
  const l = new Limiter({ kinds: { k: { burst: 1, per: 1000 } } });
  assert.equal(l.peek("k", "a", 0), 0);
  assert.equal(l.buckets.get("k").size, 0, "a key never taken is not stored");
  l.take("k", "a", 0);
  assert.equal(l.peek("k", "a", 0), 1000);
  assert.equal(l.peek("k", "a", 250), 750);
  assert.equal(l.peek("k", "a", 1000), 0);
  assert.equal(l.take("k", "a", 1000), 0);
});

test("an IPv6 address is limited by its /64, an IPv4 one as it is", () => {
  assert.equal(peerKey("198.51.100.7"), "198.51.100.7");
  assert.equal(peerKey("::ffff:198.51.100.7"), "198.51.100.7");
  assert.equal(peerKey("2001:db8::1"), "2001:db8:0:0::/64");
  assert.equal(peerKey("2001:DB8:0:0:ffff::c7"), "2001:db8:0:0::/64");
  assert.equal(peerKey("2001:db8:0:1::1"), "2001:db8:0:1::/64");
  assert.equal(peerKey("fe80::1%eth0"), "fe80:0:0:0::/64");
  assert.equal(peerKey(""), null);
  assert.equal(peerKey(null), null);
});

const request = (path, { method = "GET", token, peer, body } = {}) =>
  new Request(`https://edge.example${path}`, {
    method,
    headers: { ...(token ? { authorization: `Bearer ${token}` } : {}), ...(peer ? { "x-peer": peer } : {}),
               ...(body ? { "content-type": "application/json" } : {}) },
    body: body ? JSON.stringify(body) : undefined });

test("an account asking past its bucket is answered 429, with how long to wait, and no other account is (G44)", async () => {
  const t = server();
  const a = t.service.session("gc:a");
  const b = t.service.session("gc:b");
  for (let i = 0; i < KINDS.calls.burst; i++) {
    assert.equal((await t.handle(request("/v1/balance", { token: a.token }))).status, 200, `call ${i}`);
  }
  const refused = await t.handle(request("/v1/balance", { token: a.token }));
  assert.equal(refused.status, 429);
  assert.equal(refused.headers.get("retry-after"), "1");
  assert.deepEqual(await refused.json(), { error: "too_many_requests", retryAfter: 1 });
  assert.equal((await t.handle(request("/v1/balance", { token: b.token }))).status, 200);
  t.clock.now += KINDS.calls.per;
  assert.equal((await t.handle(request("/v1/balance", { token: a.token }))).status, 200, "and one more once it refills");
});

test("a refused request reads nothing from the database, and a bad token takes no one's bucket (G44)", async () => {
  const t = server();
  const a = t.service.session("gc:a");
  for (let i = 0; i < KINDS.calls.burst; i++) await t.handle(request("/v1/era", { token: a.token }));
  const db = t.service.db;
  const prepare = db.prepare;
  let asked = 0;
  db.prepare = (sql) => { asked++; return prepare.call(db, sql); };
  try {
    assert.equal((await t.handle(request("/v1/balance", { token: a.token }))).status, 429);
  } finally {
    db.prepare = prepare;
  }
  assert.equal(asked, 0);
  const forged = `${a.account}.${Number.MAX_SAFE_INTEGER}.forged`;
  assert.equal((await t.handle(request("/v1/balance", { token: forged }))).status, 401);
});

test("what runs the simulation has its own, smaller bucket, whichever route runs it (G44)", async () => {
  for (const [method, path] of [["PUT", "/v1/islands/heart"], ["POST", "/v1/heists/nosuch"],
                                ["POST", "/v1/workshop"], ["POST", "/v1/workshop/plays/nosuch"]]) {
    const t = server();
    const a = t.service.session("gc:a");
    const send = () => t.handle(new Request(`https://edge.example${path}`, {
      method, headers: { authorization: `Bearer ${a.token}` }, body: new Uint8Array([1, 2, 3]) }));
    for (let i = 0; i < KINDS.simulations.burst; i++) {
      assert.notEqual((await send()).status, 429, `${path} ${i}`);
    }
    const refused = await send();
    assert.equal(refused.status, 429, path);
    assert.equal(refused.headers.get("retry-after"), String(KINDS.simulations.per / 1000));
    assert.equal((await t.handle(request("/v1/balance", { token: a.token }))).status, 200, "other calls still go");
  }
});

test("a sign-in is limited by the account it proves, whatever the address, and whether or not one is told (G44)", async () => {
  const t = server();
  const signIn = (credential, peer) => t.handle(request("/v1/session", { method: "POST", peer, body: { credential } }));
  for (let i = 0; i < KINDS.signIns.burst; i++) {
    assert.equal((await signIn("gc:x", `2001:db8:${i}::1`)).status, 200, `sign-in ${i}`);
  }
  const refused = await signIn("gc:x", "2001:db8:99::1");
  assert.equal(refused.status, 429);
  assert.equal(refused.headers.get("retry-after"), String(KINDS.signIns.per / 1000));
  assert.equal((await signIn("gc:y")).status, 200, "another account has its own");
  // Refused, it read nothing and made nothing: no account for a new identity.
  const before = t.service.db.prepare("SELECT COUNT(*) AS n FROM accounts").get().n;
  for (let i = 0; i < KINDS.signIns.burst + 1; i++) await signIn("gc:z");
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM accounts").get().n, before + 1);
});

test("failed sign-ins are limited by address, an IPv6 one by its /64, and players sharing one are never held by each other's (G44)", async () => {
  const t = server();
  const handle = handler(t.service, { peerOf: (r) => r.headers.get("x-peer") });
  const post = (path, peer, body) => handle(request(path, { method: "POST", peer, body }));
  // Many players behind one address sign in, each once: none is refused.
  for (let i = 0; i < 3 * KINDS.failedSignIns.burst; i++) {
    assert.equal((await post("/v1/session", "198.51.100.7", { credential: `gc:p${i}` })).status, 200, `player ${i}`);
  }
  // Failures from a /64, each from another address in it, fill its bucket:
  // a malformed body and an identity refused both count, and so does the
  // web deletion's.
  const block = (i) => `2001:db8:0:1::${i.toString(16)}`;
  for (let i = 0; i < KINDS.failedSignIns.burst; i++) {
    const r = i % 3 === 0 ? await post("/v1/session", block(i), { nothing: 1 })
      : i % 3 === 1 ? await handle(new Request("https://edge.example/v1/session", {
          method: "POST", headers: { "x-peer": block(i) }, body: "x" }))
      : await post("/v1/account/delete", block(i), { idToken: "not a token" });
    assert.ok([400, 401, 503].includes(r.status), `failure ${i}: ${r.status}`);
  }
  const held = await post("/v1/session", "2001:db8:0:1::ffff", { credential: "gc:ok" });
  assert.equal(held.status, 429, "the whole /64 is held, even with a good credential");
  assert.equal((await post("/v1/session", "2001:db8:0:2::1", { credential: "gc:ok" })).status, 200, "the next /64 is not");
  t.clock.now += KINDS.failedSignIns.per;
  assert.equal((await post("/v1/session", "2001:db8:0:1::ffff", { credential: "gc:ok" })).status, 200, "and it refills");
});

test("a 429 that says no wait carries no Retry-After", async () => {
  const t = server();
  const { Refused } = await import("../src/refused.mjs");
  const h = handler({ ...t.service, now: () => t.clock.now, account: () => { throw new Refused(429, "survey_once_a_quarter"); },
                      holder: () => "a" });
  const r = await h(request("/v1/balance", { token: "x" }));
  assert.equal(r.status, 429);
  assert.equal(r.headers.get("retry-after"), null);
});
