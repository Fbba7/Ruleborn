// The edge function, through web-standard Requests.

import assert from "node:assert/strict";
import { test } from "node:test";

import { openPlan, play, server } from "./setup.mjs";

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
  assert.deepEqual(balance, { starlight: 2700, essence: 2700, starglass: 0 });
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
  assert.equal(words.adjectives.length, 16);
  const made = await call("POST", "/v1/workshop", { token: creator.token,
    json: { bundle: b64(island), replay: b64(cleared), adjective: 0, noun: 1 } });
  assert.equal(made.status, 201);
  const item = await made.json();
  assert.equal(item.name.en, "Amber Maze");

  const listed = await (await call("GET", "/v1/workshop?list=new", { token: player.token })).json();
  assert.deepEqual(listed.map((i) => i.id), [item.id]);

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
