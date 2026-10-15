// §13.3's curation (curation.mjs) and G54's swap (weaving.mjs).

import assert from "node:assert/strict";
import { test } from "node:test";

import { LAYOUTS } from "../src/curation.mjs";
import { prior } from "../src/matchmaking.mjs";
import { lawsOf } from "../src/telemetry.mjs";
import { server } from "./setup.mjs";

const MINUTE = 60_000;
const refused = (fn, reason) => assert.throws(fn, (e) => e.reason === reason, reason);

/** A player with Slow rivers woven and working in the Heart. */
function curator() {
  const t = server({ strictUniverse: true });
  const { account: me, token } = t.service.session("gc:curator");
  t.service.codex.show(me);
  t.service.book(me, "aether", 100_000, "a test's grant");
  t.service.weaving.weave(me, { realm: "heart", slot: 1, law: "slow_rivers" });
  t.clock.now += 10 * MINUTE;
  return { t, me, token };
}

/** Where a bundle's guard list starts: the 14-byte header, then 3 bytes a
 *  tile (island.rs). */
const guardsAt = (bytes) => 14 + 3 * (9 + bytes[4]) ** 2;

test("curation offers the generator's layouts for a realm and lays one with the player's own laws, published as generated and rated from the generated band (13.3, 12.22, G54)", () => {
  const { t, me } = curator();
  const v = t.service.curation.view(me, "heart");
  assert.deepEqual([v.island, v.origin, v.level, v.vaultLevel], [null, null, 3, 1]);
  assert.equal(new Set(v.layouts).size, LAYOUTS, "three different layouts a page");
  assert.deepEqual(t.service.curation.view(me, "heart").layouts, v.layouts, "the same menu every time");
  assert.ok(t.service.curation.view(me, "heart", 1).layouts.every((s) => !v.layouts.includes(s)), "another page, others");
  const out = t.service.curation.layout(me, "heart", v.layouts[0]);
  assert.deepEqual([out.origin, out.seed, out.island], ["generated", v.layouts[0], out.bundle]);
  const bytes = t.service.bundle(out.bundle);
  assert.deepEqual(Buffer.from(bytes), Buffer.from(t.build.curated(v.layouts[0], 3, 1, [], ["slow_rivers"])));
  assert.deepEqual(lawsOf(bytes), ["slow_rivers"], "the realm's woven law, and none the generator chose");
  assert.deepEqual(t.build.island(bytes).problems, []);
  assert.equal(t.service.db.prepare("SELECT origin FROM snapshots WHERE bundle = ?").get(out.bundle).origin, "generated");
  assert.equal(t.service.matchmaking.islandRating(me, "heart").rating, prior(3, "generated").rating,
               "judged against the generated band (12.22)");
  assert.equal(t.service.curation.layout(me, "heart", v.layouts[0]).bundle, out.bundle, "a retry lays the same island");
  for (const seed of ["x", "-1", (2n ** 64n).toString(), 7]) {
    refused(() => t.service.curation.layout(me, "heart", seed), "malformed_body");
  }
  refused(() => t.service.curation.view(me, "outer-1"), "realm_not_open");
  refused(() => t.service.curation.view(me, "outer-9"), "no_such_realm");
});

test("a curated defence keeps the generated origin while only curation's verbs are used, is authored once its terrain is edited, and is named from the word lists, over HTTP (13.3, G58)", async () => {
  const { t, token } = curator();
  const call = (method, path, body) => t.handle(new Request(`https://edge.example${path}`, {
    method, headers: { authorization: `Bearer ${token}`,
                       "content-type": body instanceof Uint8Array ? "application/octet-stream" : "application/json" },
    body: body === undefined ? undefined : body instanceof Uint8Array ? body : JSON.stringify(body) }));
  const v = await (await call("GET", "/v1/curation/heart")).json();
  const laid = await (await call("POST", "/v1/curation/heart/layout", { seed: v.layouts[1] })).json();
  assert.equal(laid.origin, "generated");
  // Turn the first post a quarter.
  const turned = Uint8Array.from(t.service.bundle(laid.bundle));
  const at = guardsAt(turned) + 1;
  turned[at] = (turned[at] & 0x0f) | ((((turned[at] >> 4) + 1) % 4) << 4);
  assert.equal((await call("PUT", "/v1/islands/heart", turned)).status, 201);
  let now = await (await call("GET", "/v1/curation/heart")).json();
  assert.notEqual(now.island, laid.bundle);
  assert.deepEqual([now.origin, now.seed], ["generated", v.layouts[1]], "a post turned keeps it generated");
  // The corner tile's pace changed: the terrain is edited.
  const edited = Uint8Array.from(turned);
  edited[15] = 50;
  assert.equal((await call("PUT", "/v1/islands/heart", edited)).status, 201);
  now = await (await call("GET", "/v1/curation/heart")).json();
  assert.deepEqual([now.origin, now.seed], ["authored", null], "the terrain edited, authored (13.3)");
  const named = await (await call("PUT", "/v1/curation/heart/name", { adjective: 0, noun: 1 })).json();
  assert.deepEqual(named.name, { adjective: 0, noun: 1 });
  const bad = await call("PUT", "/v1/curation/heart/name", { adjective: 0, noun: "Vault" });
  assert.deepEqual([bad.status, (await bad.json()).error], [400, "name_not_from_the_word_lists"]);
});

test("a swap weaves the new law in the old one's place at §5.6's price and time as curation prices it, with no hour's rest (G54, 5.6)", () => {
  const { t, me } = curator();
  const [swap] = t.service.curation.view(me, "heart").swaps;
  assert.deepEqual([swap.slot, swap.law], [1, "slow_rivers"]);
  assert.deepEqual(swap.offers.map((o) => o.law).sort(), ["bloom", "half_gravity"]);
  const offer = swap.offers.find((o) => o.law === "bloom");
  assert.ok(offer.price > 0);
  assert.equal(offer.minutes, 10);
  refused(() => t.service.weaving.weave(me, { realm: "heart", slot: 1, law: "bloom" }), "slot_taken");
  refused(() => t.service.weaving.weave(me, { realm: "heart", slot: 2, law: "bloom", swap: true }), "nothing_to_swap");
  const before = t.service.aether(me);
  const out = t.service.weaving.weave(me, { realm: "heart", slot: 1, law: "bloom", swap: true });
  assert.equal(t.service.aether(me), before - offer.price, "the price on the button");
  const slot = out.weaving.realms.find((r) => r.realm === "heart").slots[0];
  assert.deepEqual([slot.law, slot.weaving, slot.ready_at], ["bloom", true, t.clock.now + 10 * MINUTE]);
});
