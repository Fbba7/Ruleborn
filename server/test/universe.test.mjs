// The home economy's first part (§5.2, §9.5, §10.1, §10.2, §14.2): realms
// and buildings bought with Starlight, their gates, where they stand, and the
// islands they allow.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { KINDS, allowed } from "../src/universe.mjs";
import { server } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));

function fresh() {
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:keeper").account;
  const u = t.service.universe;
  const grant = (n) => t.service.book(me, "starlight", n, "a test's grant");
  const keeper = (level) => t.service.db.prepare("UPDATE accounts SET keeper_level = ? WHERE id = ?").run(level, me);
  return { t, me, u, grant, keeper };
}

function refused(fn, reason, detail) {
  assert.throws(fn, (err) => {
    assert.equal(err.reason, reason);
    if (detail) assert.deepEqual(err.detail, detail);
    return true;
  });
}

const heart = (view) => view.realms.find((r) => r.realm === "heart");

/** A bare island at realm `level`, 9 + level tiles a side, its Vault at
 *  `vault`: nothing on it but the Vault (as service.test.mjs builds one). */
function bare(level, vault) {
  const side = 9 + level;
  const bytes = new Uint8Array(14 + side * side * 3 + 3);
  bytes.set(new TextEncoder().encode("RBI1"));
  bytes[4] = level;
  bytes[5] = vault;
  new DataView(bytes.buffer).setUint32(6, 750, true);
  bytes.set([5, 7, 9, 9], 10);
  return bytes;
}

test("a new universe is the Heart with its start, and says what each next level costs and needs (10.2, F56)", () => {
  const { me, u } = fresh();
  const v = u.view(me);
  assert.equal(v.spire, 1);
  assert.equal(v.starlight, 0);
  assert.deepEqual(v.realms.map((r) => [r.realm, r.level]), [["heart", 3]], "the Heart counts as realm level 3 (G19)");
  const h = heart(v);
  assert.deepEqual(h.buildings.map((b) => b.kind).sort(), [...facts.STARTING_HEART].sort());
  assert.ok(h.buildings.every((b) => b.level === 1));
  const vault = h.buildings.find((b) => b.kind === "vault");
  assert.deepEqual(vault.next, { cost: 1_720, needs: { keeper: 0, spire: 2 }, blocked: "spire_level" },
                   "§10.2's Vault 2: 1,720 Starlight, Spire 2");
  const spire = h.buildings.find((b) => b.kind === "keeper_s_spire");
  assert.deepEqual(spire.next, { cost: 2_200, needs: { keeper: 5, spire: 0 }, blocked: "keeper_level" });
  // Room in the Heart for what it may hold and does not: never an outer
  // realm's Storehouse or Nursery, never a second producer (§5.8).
  const room = h.room.map((r) => r.kind);
  assert.ok(room.includes("anchor_stone") && room.includes("ward") && room.includes("library"));
  assert.ok(!room.includes("storehouse") && !room.includes("nursery") && !room.includes("star_well"));
  assert.deepEqual(h.room.find((r) => r.kind === "library"),
                   { kind: "library", name: "Library", n: 1, cost: 900, needs: { keeper: 4, spire: 0 }, blocked: "keeper_level" });
  assert.deepEqual(v.open, { realm: "outer-1", types: facts.REALM_TYPES, cost: 2_000, needs: { keeper: 3, spire: 1 },
                             blocked: "keeper_level" }, "§5.2: the first outer realm at Keeper 3, 2,000 Starlight");
  assert.equal(t_rows(u, me), 0, "reading a universe writes nothing");
});

const t_rows = (u, me) => u.db.prepare("SELECT COUNT(*) AS n FROM buildings WHERE owner = ?").get(me).n;

test("a building is bought with Starlight from the ledger, once, however often the purchase is sent (10.2, 24.12)", () => {
  const { me, u, t, grant } = fresh();
  grant(1_000);
  const out = u.build(me, { realm: "heart", kind: "anchor_stone", n: 1, to: 1 });
  assert.equal(out.universe.starlight, 400);
  assert.deepEqual(heart(out.universe).buildings.find((b) => b.kind === "anchor_stone").next.cost, 1_320);
  assert.equal(t_rows(u, me), facts.STARTING_HEART.length + 1, "the start is written with the first purchase");
  const again = u.build(me, { realm: "heart", kind: "anchor_stone", n: 1, to: 1 });
  assert.equal(again.repeated, true);
  assert.equal(again.keeper, null);
  assert.equal(t.service.balance(me).starlight, 400, "a retry is never charged");
  const rows = t.service.db.prepare("SELECT starlight, reason FROM ledger WHERE account = ? AND starlight < 0").all(me)
    .map((r) => ({ ...r }));
  assert.deepEqual(rows, [{ starlight: -600, reason: "spent on Anchor Stone 1 in heart to level 1 (10.2)" }]);
});

test("spending earns §14.2's experience, 1 for every 40 Starlight, with nothing lost between purchases", () => {
  const { me, u, grant } = fresh();
  grant(20_000);
  const first = u.build(me, { realm: "heart", kind: "ward", n: 1, to: 1 });     // 350: 8.75
  assert.deepEqual(first.keeper, { gained: 8, level: 1, xp: 8, toNext: 140, levelled: 0 });
  const second = u.build(me, { realm: "heart", kind: "ward", n: 2, to: 1 });    // 700: 17.5
  assert.equal(second.keeper.gained, 9, "the 0.75 left over counts toward the next");
  // Keeper 1 to 2 is 140 experience: 5,600 Starlight spent in all.
  for (const kind of ["anchor_stone", "resonance_lab", "observatory", "beacon"]) {
    u.build(me, { realm: "heart", kind, n: 1, to: 1 });                         // 600, 1,500, 1,200, 1,000
  }
  u.build(me, { realm: "heart", kind: "ward", n: 3, to: 1 });                   // 5,350: 133.75
  const up = u.build(me, { realm: "heart", kind: "ward", n: 4, to: 1 });        // 5,700: 142.5
  assert.deepEqual(up.keeper, { gained: 9, level: 2, xp: 2, toNext: 90, levelled: 1 });
  assert.equal(u.spent(me), 5_700);
});

test("what a building needs is checked before anything is paid: its Keeper and Spire levels, the Starlight, the next level only", () => {
  const { me, u, t, grant, keeper } = fresh();
  refused(() => u.build(me, { realm: "heart", kind: "vault", n: 1, to: 2 }), "needs_spire_level", { needs: 2 });
  refused(() => u.build(me, { realm: "heart", kind: "keeper_s_spire", n: 1, to: 2 }), "needs_keeper_level", { needs: 5 });
  refused(() => u.build(me, { realm: "heart", kind: "library", n: 1, to: 1 }), "needs_keeper_level", { needs: 4 });
  refused(() => u.build(me, { realm: "heart", kind: "ward", n: 1, to: 1 }), "not_enough_starlight", { cost: 350 });
  refused(() => u.build(me, { realm: "heart", kind: "ward", n: 1, to: 2 }), "not_the_next_level");
  grant(10_000);
  keeper(5);
  u.build(me, { realm: "heart", kind: "keeper_s_spire", n: 1, to: 2 });
  assert.equal(u.spire(me), 2);
  u.build(me, { realm: "heart", kind: "vault", n: 1, to: 2 });
  refused(() => u.build(me, { realm: "heart", kind: "vault", n: 1, to: 3 }), "needs_spire_level", { needs: 3 });
  refused(() => u.build(me, { realm: "heart", kind: "hearth", n: 1, to: 2 }), "needs_spire_level", { needs: 3 },
          "a five-level building needs half the Spire's level, rounded up (10.1)");
  assert.equal(t.service.balance(me).starlight, 10_000 - 2_200 - 1_720, "a refusal pays nothing");
});

test("a realm holds §5.2's count of each kind, where §10.2 places it", () => {
  const { me, u, grant } = fresh();
  grant(100_000);
  for (let n = 1; n <= allowed("ward", 3); n++) u.build(me, { realm: "heart", kind: "ward", n, to: 1 });
  refused(() => u.build(me, { realm: "heart", kind: "ward", n: 7, to: 1 }), "no_room");
  assert.ok(!heart(u.view(me)).room.some((r) => r.kind === "ward"), "the Heart's six wards (G19), and no seventh");
  refused(() => u.build(me, { realm: "heart", kind: "star_well", n: 2, to: 1 }), "no_room", undefined,
          "one producer of each kind a realm (5.8)");
  refused(() => u.build(me, { realm: "heart", kind: "storehouse", n: 1, to: 1 }), "not_in_this_realm");
  refused(() => u.build(me, { realm: "outer-1", kind: "anchor_stone", n: 1, to: 1 }), "no_such_realm");
  refused(() => u.build(me, { realm: "heart", kind: "moat", n: 1, to: 1 }), "no_such_building");
  refused(() => u.build(me, { realm: "heart", kind: "ward", n: 1, to: 1.5 }), "malformed_body");
  assert.deepEqual([1, 2, 3, 4, 5].map((l) => allowed("guardian_post", l)), facts.GUARD_POSTS);
  assert.deepEqual([1, 2, 3, 4, 5].map((l) => allowed("law_pylon", l)), facts.LAW_SLOTS);
  assert.equal(KINDS.vault.where, "heart");
  assert.equal(KINDS.nursery.where, "outer");
});

test("outer realms open at §5.2's Keeper levels, each of a type not yet owned, and rise at its Spire levels", () => {
  const { me, u, grant, keeper } = fresh();
  grant(200_000);
  refused(() => u.open(me, "Skyfield"), "needs_keeper_level", { needs: 3 });
  refused(() => u.open(me, "Mirewood"), "no_such_realm_type");
  keeper(3);
  const opened = u.open(me, "Skyfield");
  assert.deepEqual(opened.universe.realms.map((r) => [r.realm, r.type, r.level]),
                   [["heart", "Heart", 3], ["outer-1", "Skyfield", 1]]);
  assert.equal(opened.universe.starlight, 198_000);
  assert.equal(opened.keeper.gained, 50, "2,000 Starlight is 50 experience");
  assert.equal(u.open(me, "Skyfield").repeated, true, "a retry opens nothing more");
  assert.ok(!opened.universe.open.types.includes("Skyfield"));
  refused(() => u.open(me, "Verdant"), "needs_keeper_level", { needs: 6 });
  // An outer realm takes what §10.2 places there, and what every realm does.
  u.build(me, { realm: "outer-1", kind: "storehouse", n: 1, to: 1 });
  u.build(me, { realm: "outer-1", kind: "star_well", n: 1, to: 1 });
  refused(() => u.build(me, { realm: "outer-1", kind: "vault", n: 1, to: 1 }), "not_in_this_realm");
  refused(() => u.build(me, { realm: "outer-1", kind: "guardian_post", n: 2, to: 1 }), "no_room",
          undefined, "one guard post at realm level 1 (5.2)");
  // Level 2: 6,000 Starlight at Spire 3.
  refused(() => u.raise(me, "outer-1", 2), "needs_spire_level", { needs: 3 });
  refused(() => u.raise(me, "outer-1", 3), "not_the_next_level");
  refused(() => u.raise(me, "heart", 2), "no_such_realm");
  keeper(9);
  u.build(me, { realm: "heart", kind: "keeper_s_spire", n: 1, to: 2 });
  u.build(me, { realm: "heart", kind: "keeper_s_spire", n: 1, to: 3 });
  const before = u.view(me).starlight;
  const raised = u.raise(me, "outer-1", 2);
  assert.equal(raised.universe.realms[1].level, 2);
  assert.equal(before - raised.universe.starlight, 6_000);
  assert.equal(u.raise(me, "outer-1", 2).repeated, true);
  assert.deepEqual(raised.universe.realms[1].raise, { cost: 20_000, needs: { keeper: 0, spire: 5 }, blocked: "spire_level" });
});

test("an island is published only as far as its owner's universe is built: the realm, its level, the Vault", () => {
  const { t, me, u, grant, keeper } = fresh();
  const island = t.build.exampleIsland(true);
  island[5] = 2;
  assert.throws(() => t.service.publish(me, island), (e) => e.reason === "island_not_publishable"
    && e.detail.problems.includes("vault_level_not_built"));
  island[5] = 1;
  assert.ok(t.service.publish(me, island).bundle, "the start's Vault is level 1");
  const outer = bare(1, 1);
  assert.throws(() => t.service.publish(me, outer, "outer-1"), (e) => e.detail.problems.includes("realm_not_open"));
  grant(10_000);
  keeper(3);
  u.open(me, "Tidehold");
  assert.ok(t.service.publish(me, outer, "outer-1").bundle);
  assert.throws(() => t.service.publish(me, bare(2, 1), "outer-1"), (e) => e.detail.problems.includes("realm_level_not_built"));
  // The game's own islands answer to no universe (13.1).
  const seed = t.service.session("gc:seed").account;
  t.service.db.prepare("UPDATE accounts SET seeded = 1 WHERE id = ?").run(seed);
  island[5] = 6;
  assert.ok(t.service.publish(seed, island).bundle);
});

test("a building keeps the tile it is put on, moves free and at once, and stays on the grid and off the others (10.1)", () => {
  const { t, me, u } = fresh();
  const sizes = t.build.footprints;
  assert.equal(sizes.keeper_s_spire, 3, "the Spire is 3 by 3");
  assert.equal(sizes.star_well, 2, "most are 2 by 2");
  for (const own of ["vault", "law_pylon", "guardian_post", "ward"]) assert.ok(!(own in sizes), `${own} has its own list`);
  const spire = () => heart(u.view(me)).buildings.find((b) => b.kind === "keeper_s_spire");
  assert.equal(spire().at, null, "not placed yet");
  const starlight = u.view(me).starlight;
  assert.deepEqual(heart(u.place(me, { realm: "heart", kind: "keeper_s_spire", n: 1, x: 0, y: 0 }).universe)
    .buildings.find((b) => b.kind === "keeper_s_spire").at, { x: 0, y: 0 });
  u.place(me, { realm: "heart", kind: "keeper_s_spire", n: 1, x: 1, y: 0 });
  assert.deepEqual(spire().at, { x: 1, y: 0 }, "moved");
  assert.equal(u.view(me).starlight, starlight, "free");
  const at = (kind, x, y, n = 1, realm = "heart") => () => u.place(me, { realm, kind, n, x, y });
  refused(at("vault", 4, 4), "not_on_the_grid");
  refused(at("nope", 4, 4), "no_such_building");
  refused(at("keeper_s_spire", 4, 4, 2), "not_built");
  refused(at("observatory", 4, 4), "not_built");
  refused(at("keeper_s_spire", 10, 0), "off_the_grid", undefined, "the Heart is 12 by 12 and the Spire 3");
  refused(at("star_well", 2, 1), "tile_taken", undefined, "the Spire covers 1 to 3 by 0 to 2");
  refused(at("star_well", 0, 0, 1, "outer-1"), "no_such_realm");
  refused(at("star_well", -1, 0), "malformed_body");
  at("star_well", 4, 0)();
  at("keeper_s_spire", 9, 9)();
  assert.deepEqual(spire().at, { x: 9, y: 9 }, "a building moved clears the tiles it left");
  at("star_well", 1, 0)();
});

test("a published island carries the realm's placed buildings on their tiles, and no others (10.1)", () => {
  const { t, me, u } = fresh();
  const code = (kind) => t.build.buildingKinds[kind].code;
  const island = (...buildings) => {
    const base = bare(3, 1);
    if (!buildings.length) return base;
    const out = new Uint8Array(base.length + 1 + 3 * buildings.length);
    out.set(base);
    out[base.length] = buildings.length;
    buildings.forEach(([kind, x, y], i) => out.set([code(kind), x, y], base.length + 1 + 3 * i));
    return out;
  };
  const problems = (bytes) => {
    try {
      t.service.publish(me, bytes);
      return [];
    } catch (e) {
      return e.detail.problems;
    }
  };
  assert.deepEqual(problems(island()), [], "nothing placed, nothing carried");
  assert.deepEqual(t.build.buildings(island(["keeper_s_spire", 0, 0], ["star_well", 4, 0])),
                   [{ kind: "keeper_s_spire", x: 0, y: 0 }, { kind: "star_well", x: 4, y: 0 }], "the simulation reads them back");
  assert.deepEqual(problems(island(["keeper_s_spire", 0, 0])), ["buildings_not_as_placed"], "a Spire not placed");
  u.place(me, { realm: "heart", kind: "keeper_s_spire", n: 1, x: 0, y: 0 });
  u.place(me, { realm: "heart", kind: "star_well", n: 1, x: 4, y: 0 });
  assert.deepEqual(problems(island()), ["buildings_not_as_placed"], "the placed buildings left out");
  assert.deepEqual(problems(island(["keeper_s_spire", 0, 0])), ["buildings_not_as_placed"], "the Star Well left out");
  assert.deepEqual(problems(island(["keeper_s_spire", 1, 0], ["star_well", 4, 0])), ["buildings_not_as_placed"], "the Spire elsewhere");
  assert.deepEqual(problems(island(["keeper_s_spire", 0, 0], ["star_well", 4, 0], ["observatory", 7, 3])),
                   ["buildings_not_as_placed"], "an Observatory never built");
  assert.deepEqual(problems(island(["star_well", 4, 0], ["keeper_s_spire", 0, 0])), [], "in any order");
  // The simulation's own rules still hold: a footprint over the Vault is
  // crowded, whatever was placed.
  u.place(me, { realm: "heart", kind: "star_well", n: 1, x: 5, y: 7 });
  assert.deepEqual(problems(island(["keeper_s_spire", 0, 0], ["star_well", 5, 7])), ["crowded"]);
});

test("the universe over HTTP: read, bought, and refused with the reason (5.2, 10.2)", async () => {
  const t = server({ strictUniverse: true });
  const call = async (method, path, token, json) => {
    const r = await t.handle(new Request(`https://edge.example${path}`, {
      method, headers: { authorization: `Bearer ${token}`, ...(json ? { "content-type": "application/json" } : {}) },
      body: json ? JSON.stringify(json) : undefined }));
    return { status: r.status, body: await r.json() };
  };
  const { account, token } = t.service.session("gc:keeper");
  const read = await call("GET", "/v1/universe", token);
  assert.equal(read.status, 200);
  assert.equal(read.body.spire, 1);
  const poor = await call("POST", "/v1/universe/buildings", token, { realm: "heart", kind: "ward", n: 1, to: 1 });
  assert.equal(poor.status, 409);
  assert.equal(poor.body.error, "not_enough_starlight");
  t.service.book(account, "starlight", 5_000, "a test's grant");
  const built = await call("POST", "/v1/universe/buildings", token, { realm: "heart", kind: "ward", n: 1, to: 1 });
  assert.equal(built.status, 200);
  assert.equal(built.body.universe.starlight, 4_650);
  t.service.db.prepare("UPDATE accounts SET keeper_level = 3 WHERE id = ?").run(account);
  const opened = await call("POST", "/v1/universe/realms", token, { type: "Verdant" });
  assert.equal(opened.body.universe.realms[1].type, "Verdant");
  const raise = await call("POST", "/v1/universe/realms/outer-1/level", token, { to: 2 });
  assert.equal(raise.body.error, "needs_spire_level");
  const typeless = await call("POST", "/v1/universe/realms", token, { type: 3 });
  assert.equal(typeless.status, 400);
  const moved = await call("PUT", "/v1/universe/buildings/place", token, { realm: "heart", kind: "hearth", n: 1, x: 2, y: 2 });
  assert.deepEqual(moved.body.universe.realms[0].buildings.find((b) => b.kind === "hearth").at, { x: 2, y: 2 });
  const taken = await call("PUT", "/v1/universe/buildings/place", token, { realm: "heart", kind: "garden", n: 1, x: 3, y: 3 });
  assert.equal(taken.status, 409);
  assert.equal(taken.body.error, "tile_taken");
});
