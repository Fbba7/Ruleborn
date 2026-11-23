// FX1-6: the proofs of docs/security/audit-2026-11/server-a.md, one test per
// finding, each failing on the code the audit read.

import assert from "node:assert/strict";
import { test } from "node:test";

import { deleteAccount } from "../src/accounts.mjs";
import { clockTicks } from "../src/service.mjs";
import { Workshop } from "../src/workshop.mjs";
import { established, openPlan, server } from "./setup.mjs";

test("FX1-A-01: an under-13 deletion keeps bytes another player's echo still offers (20.11, 12.22)", () => {
  const t = server();
  const a = t.service.session("gc:a").account;
  const b = t.service.session("gc:b").account;
  established(t, a);
  established(t, b);
  // B publishes X first, so B owns its snapshot; A lists the same bytes in
  // the Workshop; B moves on, so X is B's echo.
  const x = t.build.exampleIsland(true);
  const xBundle = t.service.publish(b, x).bundle;
  const cleared = t.build.record(x, { seed: 7n, ticks: clockTicks(0), crew: 3, commands: openPlan() });
  new Workshop(t.service).publish(a, x, cleared, { adjective: 1, noun: 9 });
  const away = t.build.exampleIsland(false);
  t.service.publish(b, away);
  deleteAccount(t.service, a, "under-13");
  const echo = t.service.matchmaking.fresh(t.service.now()).find((c) => c.bundle === xBundle);
  assert.ok(echo, "B's echo is still offered");
  assert.notEqual(t.service.bundle(xBundle), null, "and its bytes are still there to play");
});
