// FX2-1's fail-first tests for docs/security/bug-report-2026-11.md:
// RB-01 (a failed transaction never rolls back on Node 22.5 to 22.15),
// RB-02 (a cached Game Center certificate is never fetched again),
// RB-07 and RB-22 (raising a Nursery loses its ready births, or pays the
// hours before the raise at the new rate).

import assert from "node:assert/strict";
import { X509Certificate } from "node:crypto";
import { readFileSync } from "node:fs";
import { DatabaseSync } from "node:sqlite";
import { test } from "node:test";

import { transaction } from "../src/db.mjs";
import { GameCenter } from "../src/stores.mjs";
import { GC_URL, gc as identity } from "./auth_fixtures.mjs";
import { server } from "./setup.mjs";

const HOUR = 60 * 60 * 1000;
const cert = (path) => new X509Certificate(readFileSync(new URL(path, import.meta.url)));
const ROOT = cert("./fixtures/apple/root.pem");
const INTERMEDIATE = cert("./fixtures/apple/intermediate.pem");
const GAMECENTER = cert("./fixtures/apple/gamecenter.pem");
const BUNDLE = "com.example.ruleborn";

/** node:sqlite as Node 22.5 to 22.15 ships it: `DatabaseSync.isTransaction`
 *  only arrived in Node 22.16 and 24.0, so it reads undefined there. */
function olderNode(db) {
  return new Proxy(db, {
    get(target, key) {
      if (key === "isTransaction") return undefined;
      const value = Reflect.get(target, key, target);
      return typeof value === "function" ? value.bind(target) : value;
    },
  });
}

test("RB-01: a transaction that throws is rolled back on a node:sqlite without isTransaction", () => {
  const raw = new DatabaseSync(":memory:");
  raw.exec("CREATE TABLE t (n INTEGER)");
  const db = olderNode(raw);
  assert.equal(db.isTransaction, undefined, "the stand-in hides isTransaction");
  assert.throws(() => transaction(db, () => {
    raw.prepare("INSERT INTO t (n) VALUES (1)").run();
    throw new Error("refused inside the grant");
  }), /refused inside the grant/);
  assert.equal(raw.prepare("SELECT COUNT(*) AS n FROM t").get().n, 0, "the failed write is undone");
  assert.equal(transaction(db, () => {
    raw.prepare("INSERT INTO t (n) VALUES (2)").run();
    return "ok";
  }), "ok", "and the next transaction starts and commits");
  assert.deepEqual(raw.prepare("SELECT n FROM t").all().map((r) => r.n), [2]);
  raw.close();
});

test("RB-02: an expired cached Game Center certificate is fetched again, and the sign-in succeeds", async () => {
  // A 1-day leaf for the same key, under the stand-in chain (made for this
  // test with the fixtures' openssl, `-days 1`); then the renewed leaf.
  const short = cert("./fix_fx2_gc_short.pem");
  let now = Date.parse(short.validFrom) + HOUR;
  const served = [short.raw, GAMECENTER.raw];
  const fetched = [];
  const gc = new GameCenter({
    roots: [INTERMEDIATE, ROOT], bundleId: BUNDLE, now: () => now,
    fetchCertificate: async (url) => { fetched.push(url); return served[Math.min(fetched.length - 1, 1)]; },
  });
  const first = identity({ timestamp: now });
  await gc.prepare(first);
  assert.equal(gc.verify(first), "gc:T:_player1", "the 1-day leaf signs the player in");
  now = Date.parse(short.validTo) + HOUR;
  const later = identity({ timestamp: now });
  await gc.prepare(later);
  assert.deepEqual(fetched, [GC_URL, GC_URL], "the expired certificate is fetched again");
  assert.equal(gc.verify(later), "gc:T:_player1", "and the renewed one signs the player in");
});

/** A keeper with a level-1 Nursery in outer-1, built at the clock's now. */
function keeperWithNursery() {
  const t = server();
  const me = t.service.session("gc:keeper").account;
  t.service.db.prepare("UPDATE accounts SET keeper_level = ? WHERE id = ?").run(3, me);
  t.service.book(me, "starlight", 50_000, "a test's grant");
  t.service.book(me, "essence", 100_000, "a test's grant");
  t.service.universe.open(me, "Verdant");
  t.service.universe.build(me, { realm: "outer-1", kind: "nursery", n: 1, to: 1 });
  // A level-2 Nursery needs the Spire higher than the starting one.
  t.service.db.prepare("UPDATE buildings SET level = 3 WHERE owner = ? AND kind = 'keeper_s_spire'").run(me);
  const nursery = () => t.service.home.show(me).nurseries.find((x) => x.realm === "outer-1");
  return { t, me, nursery, later: (ms) => { t.clock.now += ms; } };
}

test("RB-07: raising a Nursery that has never given a birth keeps its ready births", () => {
  const { t, me, nursery, later } = keeperWithNursery();
  later(20 * HOUR);
  assert.equal(nursery().ready, 3, "three births ready after 20 h at one every 6 h");
  t.service.universe.build(me, { realm: "outer-1", kind: "nursery", n: 1, to: 2 });
  assert.equal(nursery().ready, 3, "an upgrade is neither emptying nor building");
});

test("RB-22: raising a Nursery carries the hours before the raise at the old rate", () => {
  const { t, me, nursery, later } = keeperWithNursery();
  later(6 * HOUR);
  t.service.home.birth(me, { realm: "outer-1", n: 4 });
  assert.equal(nursery().ready, 0, "the birth emptied it, and its row exists");
  later(5 * HOUR);
  t.service.universe.build(me, { realm: "outer-1", kind: "nursery", n: 1, to: 2 });
  const raised = nursery();
  assert.equal(raised.ready, 0, "no birth is ready right after the raise: 5 h at the 6 h rate made none");
  assert.ok(raised.next_at > t.clock.now, "the next birth is still to come");
  assert.ok(raised.next_at - t.clock.now < raised.period, "and the progress made before the raise is kept");
});
