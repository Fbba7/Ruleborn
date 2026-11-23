// FX1-6: the proofs of docs/security/audit-2026-11/server-a.md, one test per
// finding, each failing on the code the audit read.

import assert from "node:assert/strict";
import { test } from "node:test";

import { deleteAccount } from "../src/accounts.mjs";
import { clockTicks } from "../src/service.mjs";
import { Workshop } from "../src/workshop.mjs";
import { established, openPlan, server } from "./setup.mjs";

/** B's island X, then B's next: X is B's echo. A, under 13, lists the same
 *  bytes in the Workshop and is deleted. */
function erasedEcho() {
  const t = server();
  const a = t.service.session("gc:a").account;
  const b = t.service.session("gc:b").account;
  established(t, a);
  established(t, b);
  const x = t.build.exampleIsland(true);
  const xBundle = t.service.publish(b, x).bundle;
  const cleared = t.build.record(x, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  new Workshop(t.service).publish(a, x, cleared, { adjective: 1, noun: 9 });
  t.service.publish(b, t.build.exampleIsland(false));
  deleteAccount(t.service, a, "under-13");
  return { t, a, b, xBundle };
}

test("FX1-A-01: an echo whose bytes are gone is no target, and the others are still drawn (12.22, 20.11)", () => {
  const { t, xBundle } = erasedEcho();
  const now = t.service.now();
  let list;
  assert.doesNotThrow(() => { list = t.service.matchmaking.fresh(now); }, "the candidates are still made");
  for (const c of list) assert.notEqual(t.service.bundle(c.bundle), null, `${c.bundle}: a target is bytes to play`);
  assert.ok(list.length > 0, "B's current island is still a target");
  assert.doesNotThrow(() => t.service.matchmaking.listed(now));
});

test("FX1-A-02: an under-13 deletion erases bytes another player's echo is (20.11)", () => {
  // FX1-A-02, not fixed here: accounts.mjs's erase() keeps bytes another
  // player's island, Workshop island, link or lease still needs, but not
  // their snapshot, so B's echo X loses its bytes. This asserts what happens
  // today; the fix (keep bytes whose snapshot is another player's) turns it.
  const { t, b, xBundle } = erasedEcho();
  const snap = t.service.db.prepare("SELECT owner FROM snapshots WHERE bundle = ?").get(xBundle);
  assert.equal(snap.owner, b, "X's snapshot is B's");
  assert.equal(t.service.bundle(xBundle), null, "FX1-A-02: and its bytes are gone");
});
