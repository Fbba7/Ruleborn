// §5.3's links, §5.4's depth, clock and faults, and §9.3's band and fault
// terms (links.mjs, home.mjs).

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { depths, faultRealms } from "../src/links.mjs";
import { clockTicks, TICKS_PER_SECOND } from "../src/service.mjs";
import { server } from "./setup.mjs";

const facts = JSON.parse(readFileSync(new URL("../src/facts.json", import.meta.url), "utf8"));
const HOUR = 60 * 60 * 1000;
const refused = (fn, reason) => assert.throws(fn, (e) => e.reason === reason, reason);

/** A Keeper with `n` outer realms opened, in §5.2's order, and Starlight to
 *  spare. */
function keeper(n) {
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:links").account;
  t.service.db.prepare("UPDATE accounts SET keeper_level = 40 WHERE id = ?").run(me);
  t.service.book(me, "starlight", 1_000_000, "a test's grant");
  for (const type of facts.REALM_TYPES.slice(0, n)) t.service.universe.open(me, type);
  return { t, me, u: t.service.universe, l: t.service.links };
}

const pairs = (v) => v.links.map((l) => `${l.kind} ${l.a}-${l.b}`);

test("each outer realm opens with a Stone bridge to the Heart while it has a socket, then to the first opened realm with one; each realm's depth sets §5.4's clock for a crew landing there (5.3, 5.4)", () => {
  const { t, me, u } = keeper(6);
  const v = u.show(me);
  assert.deepEqual(pairs(v), ["stone_bridge outer-1-heart", "stone_bridge outer-2-heart", "stone_bridge outer-3-heart",
                              "stone_bridge outer-4-heart", "stone_bridge outer-5-outer-1",
                              "stone_bridge outer-6-outer-1"], "the Heart has four sockets (5.3)");
  assert.deepEqual(v.depth, { heart: 0, "outer-1": 1, "outer-2": 1, "outer-3": 1, "outer-4": 1, "outer-5": 2,
                              "outer-6": 2 });
  assert.equal(v.deepest, 2, "the card's \"up to 2 realms to the Heart\" (12.22)");
  assert.deepEqual([clockTicks(v.depth["outer-1"]), clockTicks(v.depth["outer-5"]), clockTicks(9)]
    .map((n) => n / TICKS_PER_SECOND), [165, 180, 240], "150 s and 15 a link, up to 240 (5.4)");
  // A universe whose realms were opened before links were kept gets them
  // the same way, the first time it is read.
  t.service.db.prepare("DELETE FROM links WHERE owner = ?").run(me);
  assert.deepEqual(pairs(u.show(me)), pairs(v));
});

test("a link is built at §5.3's price and refused past a socket, a kind's limit, one an outer realm and two, or a realm cut off; a Chute runs one way, and a link comes down only while every realm still reaches the Heart (5.3)", () => {
  const { t, me, l } = keeper(3);
  const before = t.service.balance(me).starlight;
  const v = l.build(me, { a: "outer-1", b: "outer-2", kind: "rope_bridge" }).universe;
  assert.equal(t.service.balance(me).starlight, before - facts.LINK_KINDS.rope_bridge.cost);
  assert.ok(pairs(v).includes("rope_bridge outer-1-outer-2"));
  refused(() => l.build(me, { a: "outer-2", b: "outer-1", kind: "stone_bridge" }), "already_linked");
  refused(() => l.build(me, { a: "outer-1", b: "outer-9", kind: "stone_bridge" }), "no_such_realm");
  refused(() => l.build(me, { a: "outer-1", b: "outer-2", kind: "zipline" }), "no_such_link");
  l.build(me, { a: "outer-2", b: "outer-3", kind: "chute" });
  refused(() => l.build(me, { a: "outer-1", b: "outer-3", kind: "stone_bridge" }), "too_many_links");
  // A Chute from the Heart out would leave its realm with no way in: the
  // Chute runs its owner's way, and only that way.
  const chute = v.links.length + 1;
  const outer3 = t.service.db.prepare("SELECT n FROM links WHERE owner = ? AND a = 'outer-3' AND b = 'heart'").get(me).n;
  refused(() => l.rebuild(me, outer3, { kind: "chute", from: "heart" }), "realm_cut_off");
  const turned = l.rebuild(me, outer3, { kind: "chute", from: "outer-3" }).universe;
  assert.equal(turned.depth["outer-3"], 1, "down the Chute to the Heart");
  refused(() => l.rebuild(me, 1, { kind: "chute" }), "link_limit");
  // Taking down outer-2's bridge leaves it the rope bridge to outer-1 and
  // the Chutes down through outer-3.
  const outer2 = t.service.db.prepare("SELECT n FROM links WHERE owner = ? AND a = 'outer-2' AND b = 'heart'").get(me).n;
  const down = l.remove(me, outer2).universe;
  assert.equal(down.depth["outer-2"], 2);
  // Without its Chute to the Heart, outer-3 has only a Chute in.
  refused(() => l.remove(me, outer3), "realm_cut_off");
  assert.ok(chute > 0);
});

test("a Rift costs 20 Aether an hour, paid as the universe is read; one its owner cannot pay for stands closed, crossing nothing, and opens again with Aether for an hour (5.3)", () => {
  const { t, me, l, u } = keeper(2);
  t.service.book(me, "aether", 50, "a test's grant");
  const v = l.build(me, { a: "outer-1", b: "outer-2", kind: "rift" }).universe;
  assert.ok(pairs(v).includes("rift outer-1-outer-2"));
  refused(() => l.build(me, { a: "heart", b: "outer-1", kind: "rift" }), "already_linked");
  t.clock.now += 2 * HOUR + 10;
  u.show(me);
  assert.equal(t.service.aether(me), 50 - 2 * facts.LINK_KINDS.rift.aether_an_hour);
  t.clock.now += 2 * HOUR;
  const closed = u.show(me);
  assert.equal(closed.links.find((x) => x.kind === "rift").open, false, "10 Aether pays no hour");
  assert.equal(t.service.aether(me), 10);
  t.clock.now += 5 * HOUR;
  t.service.book(me, "aether", 100, "a test's grant");
  const open = u.show(me);
  assert.equal(open.links.find((x) => x.kind === "rift").open, true);
  assert.equal(t.service.aether(me), 110, "the hours it stood closed cost nothing");
});

test("faults open from the outer realms whose routes to the Heart are longest, ties by the order they opened; a fault cuts its realm's production by 10% and the stability band adds its share everywhere (5.4, 5.5, 9.3)", () => {
  const realms = ["heart", "outer-1", "outer-2", "outer-3", "outer-4", "outer-5"];
  const d = depths(realms, [{ kind: "stone_bridge", a: "outer-1", b: "heart" },
    { kind: "stone_bridge", a: "outer-2", b: "outer-1" }, { kind: "chute", a: "outer-3", b: "outer-2" },
    { kind: "stone_bridge", a: "outer-4", b: "heart" }, { kind: "stone_bridge", a: "outer-5", b: "heart" }]);
  assert.deepEqual(d, { heart: 0, "outer-1": 1, "outer-2": 2, "outer-3": 3, "outer-4": 1, "outer-5": 1 });
  assert.deepEqual(faultRealms(d, 3), ["outer-3", "outer-2", "outer-1"]);
  assert.deepEqual(faultRealms(d, 5), ["outer-3", "outer-2", "outer-1", "outer-4", "outer-5"]);
  const { t, me } = keeper(2);
  const h = t.service.home;
  t.service.universe.build(me, { realm: "outer-1", kind: "star_well", n: 1, to: 1 });
  t.service.universe.build(me, { realm: "heart", kind: "star_well", n: 1, to: 1 });
  const crew = h.show(me).characters;
  h.work(me, crew[0].id, { realm: "outer-1", kind: "star_well" });
  h.work(me, crew[1].id, { realm: "heart", kind: "star_well" });
  t.clock.now += 10 * 60 * 1000;
  const quiet = (realm) => h.rate(me, realm, "star_well", t.clock.now);
  assert.deepEqual([quiet("outer-1").band, quiet("outer-1").fault], [0, false], "a new universe is Quiet");
  const base = { "outer-1": quiet("outer-1").perHour, heart: quiet("heart").perHour };
  // The universe as it would stand at Strained, 105%: one fault, from the
  // deeper of two realms of depth 1, the first opened.
  const real = t.service.weaving.stability.bind(t.service.weaving);
  t.service.weaving.stability = (...args) => ({ ...real(...args), strain: 1.05, band: 4 });
  const strained = { "outer-1": quiet("outer-1"), heart: quiet("heart") };
  assert.equal(strained["outer-1"].fault, true);
  assert.ok(Math.abs(strained.heart.perHour / base.heart - 1.15) < 1e-9, "+15% at Strained (5.5)");
  assert.ok(Math.abs(strained["outer-1"].perHour / base["outer-1"] - 1.15 * 0.9) < 1e-9,
            "and 10% off the realm the fault opens from (9.3)");
  assert.deepEqual(t.service.universe.view(me).faults, ["outer-1"]);
  t.service.weaving.stability = real;
});

test("links are built, rebuilt and taken down over HTTP (5.3)", async () => {
  const { t } = keeper(2);
  const { token } = t.service.session("gc:links");
  const call = (method, path, json) => t.handle(new Request(`https://edge.example${path}`, {
    method, headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
    body: json ? JSON.stringify(json) : undefined }));
  const got = await (await call("GET", "/v1/universe")).json();
  assert.equal(got.links.length, 2);
  const built = await (await call("POST", "/v1/universe/links", { a: "outer-1", b: "outer-2", kind: "stone_bridge" })).json();
  const n = built.universe.links.at(-1).n;
  const rebuilt = await (await call("PUT", `/v1/universe/links/${n}`, { kind: "rope_bridge" })).json();
  assert.equal(rebuilt.universe.links.at(-1).kind, "rope_bridge");
  const gone = await (await call("DELETE", `/v1/universe/links/${n}`)).json();
  assert.equal(gone.universe.links.length, 2);
  const cut = await call("DELETE", "/v1/universe/links/1");
  assert.deepEqual([cut.status, (await cut.json()).error], [409, "realm_cut_off"]);
});
