// What the device built, placed and assigned offline, confirmed on
// reconnection (§24, offline.mjs).

import assert from "node:assert/strict";
import { test } from "node:test";

import { MAX_ACTIONS, confirm } from "../src/offline.mjs";
import { server } from "./setup.mjs";

function fresh() {
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:offline").account;
  t.service.book(me, "starlight", 1_000, "a test's grant");
  t.service.universe.ensure(me, t.clock.now);
  t.service.home.show(me);
  const id = (kind) => t.service.home.show(me).characters.find((c) => c.kind === kind).id;
  return { t, me, id };
}

test("the device's offline queue is made in order, each action confirmed or refused on its own, by the online rules (24)", () => {
  const { t, me, id } = fresh();
  const queue = [
    { do: "build", realm: "heart", kind: "ward", n: 1, to: 1 },
    { do: "build", realm: "heart", kind: "library", n: 1, to: 1 },
    { do: "work", character: id("tidewalker"), realm: "heart", kind: "star_well" },
    { do: "place", realm: "heart", kind: "hearth", n: 1, x: 2, y: 2 },
    { do: "build", realm: "heart", kind: "ward", n: 2, to: 1 },
    { do: "build", realm: "heart", kind: "ward", n: 3, to: 1 },
    { do: "fly", realm: "heart" },
    "a stray string",
  ];
  const answer = confirm(t.service, me, queue);
  const results = answer.results.map(({ keeper, ...r }) => r);
  assert.deepEqual(results, [
    { confirmed: true },
    { refused: "needs_keeper_level", detail: { needs: 4 } },
    { confirmed: true },
    { confirmed: true },
    { confirmed: true },
    { refused: "not_enough_starlight", detail: { cost: 350 } },
    { refused: "no_such_action" },
    { refused: "malformed_body" },
  ], "a refusal stops nothing after it, and the Starlight the first two wards cost leaves too little for a third");
  assert.ok(answer.results[0].keeper, "§14.2's experience for what was spent, as online");
  assert.equal(answer.universe.starlight, 300);
  const heart = answer.universe.realms.find((r) => r.realm === "heart");
  assert.deepEqual(heart.buildings.find((b) => b.kind === "hearth").at, { x: 2, y: 2 });
  const worker = answer.home.characters.find((c) => c.kind === "tidewalker");
  assert.equal(worker.state, "working");
  assert.equal(worker.work.since, t.clock.now, "the work counts from the server's confirmation, not the phone's clock");
});

test("a queue sent twice, its answer lost on the way back, is confirmed again and pays nothing twice (24.12)", () => {
  const { t, me, id } = fresh();
  const queue = [
    { do: "build", realm: "heart", kind: "ward", n: 1, to: 1 },
    { do: "work", character: id("emberling"), realm: "heart", kind: "star_well" },
  ];
  const first = confirm(t.service, me, queue);
  t.clock.now += 60_000;
  const again = confirm(t.service, me, queue);
  assert.deepEqual(again.results, [{ confirmed: true, repeated: true }, { confirmed: true, repeated: true }]);
  assert.equal(again.universe.starlight, first.universe.starlight, "paid once");
  assert.equal(again.home.characters.find((c) => c.kind === "emberling").work.since,
               first.home.characters.find((c) => c.kind === "emberling").work.since, "the work kept its start");
});

test("the offline queue over HTTP, and a queue that is not one refused whole (24)", async () => {
  const { t, me } = fresh();
  const token = t.service.session("gc:offline").token;
  const call = async (json) => {
    const r = await t.handle(new Request("https://edge.example/v1/offline", {
      method: "POST", headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
      body: JSON.stringify(json) }));
    return { status: r.status, body: await r.json() };
  };
  const ok = await call({ actions: [{ do: "build", realm: "heart", kind: "ward", n: 1, to: 1 }] });
  assert.equal(ok.status, 200);
  assert.deepEqual(ok.body.results.map((r) => r.confirmed), [true]);
  assert.equal(ok.body.universe.starlight, t.service.universe.view(me).starlight);
  for (const bad of [{}, { actions: [] }, { actions: "build" },
                     { actions: Array.from({ length: MAX_ACTIONS + 1 }, () => ({ do: "build" })) }]) {
    const r = await call(bad);
    assert.equal(r.status, 400);
    assert.equal(r.body.error, "malformed_body");
  }
});
