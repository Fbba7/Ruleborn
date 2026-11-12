// The edge function, through web-standard Requests.

import assert from "node:assert/strict";
import { test } from "node:test";

import { counting, established, openPlan, play, server } from "./setup.mjs";

test("sign in, publish, lease, play, submit and read the balance over HTTP", async () => {
  const t = server();
  const call = (method, path, { token, json, bytes } = {}) => t.handle(new Request(
    `https://edge.example${path}`, {
      method,
      headers: { ...(token ? { authorization: `Bearer ${token}` } : {}),
                 ...(json ? { "content-type": "application/json" } : {}) },
      body: json ? JSON.stringify(json) : bytes,
    }));

  const keeper = await (await call("POST", "/v1/session", { json: { credential: "gc:keeper" } })).json();
  const raider = await (await call("POST", "/v1/session", { json: { credential: "gc:raider" } })).json();
  established(t, keeper.account);

  const island = t.build.exampleIsland(true);
  const published = await call("PUT", "/v1/islands/heart", { token: keeper.token, bytes: island });
  assert.equal(published.status, 201);
  const { bundle } = await published.json();

  const fetched = await call("GET", `/v1/bundles/${bundle}`);
  assert.equal(fetched.headers.get("cache-control"), "public, max-age=31536000, immutable");
  assert.deepEqual(new Uint8Array(await fetched.arrayBuffer()), island);

  const lease = await (await call("POST", "/v1/leases", { token: raider.token, json: { bundle } })).json();
  const replay = play(t, lease, { plan: openPlan() });
  const settled = await (await call("POST", `/v1/heists/${lease.token}`,
                                    { token: raider.token, bytes: replay })).json();
  assert.equal(settled.validated, true);
  assert.equal(settled.verdict.grade, "clean");

  const balance = await (await call("GET", "/v1/balance", { token: raider.token })).json();
  assert.deepEqual(balance, { starlight: 5625, essence: 5625 });
  const level = await (await call("GET", "/v1/keeper", { token: raider.token })).json();
  assert.deepEqual(level, { level: 1, xp: 36, toNext: 140, cap: 40,
                           plan: { crew: 3, casts: 1, sage: false, load: [50, 100, 10] }, name: null },
                   "§14.2: 30 + 6 × Keeper 1, and §12.5's planning at level 1");
});

test("no session, no service; a bad route is a 404", async () => {
  const t = server();
  const r = await t.handle(new Request("https://edge.example/v1/balance"));
  assert.equal(r.status, 401);
  const nowhere = await t.handle(new Request("https://edge.example/v2/anything"));
  assert.equal(nowhere.status, 404);
});

test("the Workshop over HTTP: publish a cleared island, browse, play, rate, remix and report", async () => {
  const t = server();
  const call = (method, path, { token, json, bytes } = {}) => t.handle(new Request(
    `https://edge.example${path}`, {
      method,
      headers: { ...(token ? { authorization: `Bearer ${token}` } : {}),
                 ...(json ? { "content-type": "application/json" } : {}) },
      body: json ? JSON.stringify(json) : bytes,
    }));
  const b64 = (u8) => Buffer.from(u8).toString("base64");
  const creator = await (await call("POST", "/v1/session", { json: { credential: "gc:creator" } })).json();
  const player = await (await call("POST", "/v1/session", { json: { credential: "gc:player" } })).json();

  const island = t.build.exampleIsland(true);
  const cleared = play(t, { bundle: t.service.store.put(island), seed: "7", ticks: 150 * 30 },
                       { plan: openPlan() });
  const words = await (await call("GET", "/v1/workshop/words", { token: player.token })).json();
  // 64 of each, 4,096 names (G26), the first sixteen where they always were.
  assert.deepEqual([words.adjectives.length, words.nouns.length], [64, 64]);
  assert.deepEqual([words.adjectives[0].en, words.nouns[15].en], ["Amber", "Well"]);
  const made = await call("POST", "/v1/workshop", { token: creator.token,
    json: { bundle: b64(island), replay: b64(cleared), adjective: 0, noun: 1 } });
  assert.equal(made.status, 201);
  const item = await made.json();
  assert.equal(item.name.en, "Amber Maze");

  const listed = await (await call("GET", "/v1/workshop?list=new", { token: player.token })).json();
  assert.deepEqual(listed.map((i) => i.id), [item.id]);

  counting(t, player.account);          // a player whose completion and rating count (SEC-26)
  const p = await (await call("POST", `/v1/workshop/${item.id}/play`, { token: player.token })).json();
  const replay = play(t, p, { plan: openPlan() });
  const done = await (await call("POST", `/v1/workshop/plays/${p.token}`,
                                 { token: player.token, bytes: replay })).json();
  assert.equal(done.counted, true);
  const rated = await (await call("POST", `/v1/workshop/${item.id}/rating`, { token: player.token,
    json: { fun: 4, cleverness: 5, fairness: 4 } })).json();
  assert.equal(rated.count, 1);
  const ladder = await (await call("GET", `/v1/creators/${creator.account}`, { token: player.token })).json();
  assert.equal(ladder.level, "builder");

  const remixed = await call("POST", `/v1/workshop/${item.id}/remix`, { token: player.token });
  assert.equal(remixed.headers.get("content-type"), "application/octet-stream");
  assert.deepEqual(new Uint8Array(await remixed.arrayBuffer()), island);

  assert.equal((await call("POST", `/v1/workshop/${item.id}/report`,
    { token: player.token, json: { reason: "unfair" } })).status, 201);
  assert.equal((await call("GET", "/v1/moderation/reports", { token: player.token })).status, 403);

  assert.equal((await call("PUT", "/v1/age", { token: player.token, json: { band: "13-15" } })).status, 200);
  const curated = await call("GET", "/v1/workshop?list=top", { token: player.token });
  assert.equal(curated.status, 403);
  assert.equal((await curated.json()).error, "curated_lists_only");
});

test("a malformed body is answered, never thrown: no one request can stop the server", async () => {
  const t = server();
  const send = (method, path, body, token) => t.handle(new Request(`https://edge.example${path}`, {
    method, body, headers: token ? { authorization: `Bearer ${token}` } : {} }));
  assert.equal((await send("POST", "/v1/session", "null")).status, 400, "no sign-in needed to send one");
  const { token } = await (await send("POST", "/v1/session", JSON.stringify({ credential: "gc:fuzz" }))).json();
  for (const [method, path, body] of [
    ["POST", "/v1/leases", "{}"],
    ["POST", "/v1/leases", "[1]"],
    ["POST", "/v1/leases", JSON.stringify({ bundle: "x", mode: "challenge", challenge: { a: 1 } })],
    ["POST", "/v1/friends/accept", "{}"],
    ["POST", "/v1/friends/accept", JSON.stringify({ invite: { a: 1 } })],
    ["POST", "/v1/crews/join", JSON.stringify({ invite: [1] })],
    ["POST", "/v1/challenges", JSON.stringify({ realm: {} })],
    ["PUT", "/v1/age", "null"],
    ["PUT", "/v1/notifications", "7"],
    ["PUT", "/v1/islands/realm0", "not an island"],
  ]) {
    const res = await send(method, path, body, token);
    assert.ok(res.status >= 400 && res.status < 500, `${method} ${path} ${body}: ${res.status}`);
  }
  assert.equal((await send("GET", "/v1/workshop?limit=abc", undefined, token)).status, 200, "the default limit");
  assert.equal((await send("POST", "/v1/track/claim", "{}", token)).status, 200, "this season's track");
  // And whatever else goes wrong is the server's own 500, not a rejection.
  const logged = console.error;
  console.error = () => {};
  try {
    t.service.balance = () => { throw new TypeError("boom"); };
    const res = await send("GET", "/v1/balance", undefined, token);
    assert.deepEqual([res.status, (await res.json()).error], [500, "internal"]);
  } finally {
    console.error = logged;
  }
});

test("every JSON body is held to the size limit, the session's and the lease's too", async () => {
  const t = server();
  const big = JSON.stringify({ credential: "gc:big", pad: "x".repeat(20_000) });
  const refused = await t.handle(new Request("https://edge.example/v1/session", { method: "POST", body: big }));
  assert.deepEqual([refused.status, (await refused.json()).error], [413, "too_large"]);
  const { token } = t.service.session("gc:big");
  const lease = await t.handle(new Request("https://edge.example/v1/leases", {
    method: "POST", headers: { authorization: `Bearer ${token}` },
    body: JSON.stringify({ bundle: "x", pad: "x".repeat(20_000) }) }));
  assert.equal(lease.status, 413);
});

test("a 13-to-15's challenge link shows nothing to a stranger (20.7)", async () => {
  const t = server();
  const minor = t.service.session("gc:minor");
  const stranger = t.service.session("gc:stranger");
  t.service.publish(minor.account, t.build.exampleIsland(true));
  t.service.db.prepare("UPDATE accounts SET age_band = '13-15' WHERE id = ?").run(minor.account);
  const { challenge } = t.service.friends.challenge(minor.account);
  const res = await t.handle(new Request(`https://edge.example/v1/challenges/${challenge}`, {
    headers: { authorization: `Bearer ${stranger.token}` } }));
  assert.deepEqual([res.status, (await res.json()).from], [404, undefined]);
});
