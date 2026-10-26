// Security review findings that need the owner's decision
// (docs/security/review.md, "Needs the owner"). Each is a todo test: it
// shows the issue, and fails, without failing the build until it is decided.

import assert from "node:assert/strict";
import { test } from "node:test";

import { twoPlayers, server } from "./setup.mjs";

// SR-09: §12.15, "Ratings are internal … the raw numbers are never shown".
test("SR-09: a target list names no island's rating", { todo: "the owner: §12.15 or the device-side offer" }, () => {
  const t = twoPlayers(false);
  const lists = t.service.targetLists();
  const list = JSON.parse(new TextDecoder().decode(t.service.bundle(Object.values(lists)[0])));
  for (const c of list.candidates) {
    assert.equal(c.rating, undefined);
    assert.equal(c.deviation, undefined);
  }
});

// SR-10: §20.2's monthly cap, kept only when the device asks for an intent.
test("SR-10: a 13-to-15's receipt with no intent is not granted past the month's cap",
     { todo: "the owner: refuse such a receipt, or keep restores as they are" }, () => {
  const t = server({ firstBand: "13-15",
                     cosmetics: { items: [{ id: "big", kind: "outfit", price: 2400 }, { id: "more", kind: "outfit", price: 500 }] },
                     verifyReceipt: (_s, r) => ({ transaction: r, product: r === "t1" ? "big" : "more", intent: null }) });
  const minor = t.service.session("gc:minor");
  t.service.shop.redeem(minor.account, "app-store", "t1");
  assert.throws(() => t.service.shop.redeem(minor.account, "app-store", "t2"), /monthly_cap/);
});
