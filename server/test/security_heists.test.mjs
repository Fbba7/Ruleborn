// Security review findings on heist submission (docs/security/review.md).

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { test } from "node:test";

import { readHeader } from "../src/sim.mjs";
import { openPlan, play, twoPlayers } from "./setup.mjs";

const KINDS = JSON.parse(readFileSync(new URL("../../content/ruleborn.json", import.meta.url))).map((k) => k.id);

// SR-02: §12.5's manifest "the server checks against the roster it holds".
// Without ?crew= it was checked against nothing: a raider could play any
// kinds they had never hatched, and no character rested after.
test("SR-02: a replay carrying a crew manifest is refused unless it names the roster's crew", async () => {
  const t = twoPlayers(true);
  const me = t.raider.account;
  const held = new Set(t.service.home.show(me).characters?.map((c) => c.kind) ?? []);
  const claimed = KINDS.filter((k) => !held.has(k)).slice(0, 3);
  assert.equal(claimed.length, 3);
  const manifest = { members: claimed.map((k) => ({ kind: KINDS.indexOf(k) })), sage: 0, casts: [] };
  const lease = t.service.lease(me, t.bundle);
  const replay = play(t, lease, { plan: openPlan(), manifest });
  assert.equal(readHeader(replay).manifest, true);

  const res = await t.handle(new Request(`https://edge.example/v1/heists/${lease.token}`, {
    method: "POST", headers: { authorization: `Bearer ${t.raider.token}` }, body: replay }));
  const out = await res.json();
  assert.equal(out.validated, false, "kinds the raider does not hold are not played for them");
  assert.equal(out.reason, "crew_not_named");
  assert.deepEqual(t.service.balance(me), { starlight: 0, essence: 0 }, "and nothing is paid");
});
