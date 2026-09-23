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
  assert.deepEqual(balance, { starlight: 2700, essence: 2700 });
});

test("no session, no service; a bad route is a 404", async () => {
  const t = server();
  const r = await t.handle(new Request("https://edge.example/v1/balance"));
  assert.equal(r.status, 401);
  const nowhere = await t.handle(new Request("https://edge.example/v2/anything"));
  assert.equal(nowhere.status, 404);
});
