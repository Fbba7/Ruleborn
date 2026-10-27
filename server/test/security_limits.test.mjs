// Security review findings on resource exhaustion (docs/security/review.md).

import assert from "node:assert/strict";
import { test } from "node:test";

import * as matchmaking from "../src/matchmaking.mjs";
import { established, server } from "./setup.mjs";

/** How many statements the database prepares while `f` runs. */
async function statements(t, f) {
  const db = t.service.db;
  const prepare = db.prepare.bind(db);
  let n = 0;
  db.prepare = (sql) => { n++; return prepare(sql); };
  try {
    await f();
  } finally {
    db.prepare = prepare;
  }
  return n;
}

// SR-03: GET /v1/offer and the Observatory made §12.22's candidates afresh
// for every caller, two reads an island across the whole game: at 1,000
// islands about 150 ms of the process a request, two a second an account.
test("SR-03: one making of the candidates serves every caller for a while, and a publish makes them again", async () => {
  const t = server();
  for (let i = 0; i < 40; i++) {
    const s = t.service.session(`gc:p${i}`);
    established(t, s.account);
    t.service.publish(s.account, t.build.generate(i + 1, 3));
  }
  const me = t.service.session("gc:me");
  const offer = async () => {
    const r = await t.handle(new Request("https://edge.example/v1/offer?size=3",
                                         { headers: { authorization: `Bearer ${me.token}` } }));
    assert.equal(r.status, 200);
    return r.json();
  };
  const first = await offer();
  const again = await statements(t, offer);
  assert.ok(again < 40, `a second offer read ${again} statements for 40 islands`);
  assert.deepEqual(await offer(), first);

  // A new island is a candidate at once, and so, past the window, is any other change.
  const late = t.service.session("gc:late");
  established(t, late.account);
  t.service.publish(late.account, t.build.generate(99, 3));
  assert.ok(t.service.matchmaking.candidates().some((c) => c.owner === late.account));
  t.clock.now += matchmaking.CANDIDATES_MS ?? 60_000;
  assert.ok(await statements(t, offer) >= 40, "made again once the window has passed");
});
