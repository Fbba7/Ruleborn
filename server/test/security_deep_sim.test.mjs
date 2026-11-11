// The deep security run's fix for an island whose declared exposure the
// rules cannot hold (SEC-17, part A): bytes 6-9 of a bundle are `exposed`,
// a u32 the simulation reads as an i32, so one above i32::MAX wrapped to a
// negative exposure. The server now refuses such a bundle before the
// simulation sees it.

import assert from "node:assert/strict";
import { test } from "node:test";

import { established, server } from "./setup.mjs";

test("SEC-17: an island whose exposure is above i32::MAX is refused as malformed; one at i32::MAX is not", async () => {
  const t = server();
  const keeper = t.service.session("gc:keeper");
  established(t, keeper.account);
  const put = (bytes) => t.handle(new Request("https://edge.example/v1/islands/heart", {
    method: "PUT", headers: { authorization: `Bearer ${keeper.token}` }, body: bytes }));
  const withExposure = (n) => {
    const b = t.build.exampleIsland(true).slice();
    new DataView(b.buffer, b.byteOffset, b.byteLength).setUint32(6, n, true);
    return b;
  };
  for (const n of [0x80000000, 0xffffffff]) {
    const res = await put(withExposure(n));
    assert.equal(res.status, 400, `exposure ${n}`);
    assert.equal((await res.json()).error, "island_malformed");
  }
  assert.equal(t.service.db.prepare("SELECT COUNT(*) AS n FROM islands WHERE owner = ?").get(keeper.account).n, 0,
               "nothing listed");
  // The guard reads only bytes 6-9; a bundle too short to hold them is the
  // simulation's to refuse, as before.
  assert.equal(t.build.island(new Uint8Array([0x52, 0x42])).error, "island_malformed");
  assert.equal((await put(withExposure(0x7fffffff))).status, 201, "the largest exposure the rules hold");
});
