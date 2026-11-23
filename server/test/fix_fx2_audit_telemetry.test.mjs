// FX2-6's audit, telemetry (docs/security/audit-2026-11/server-b.md).

import assert from "node:assert/strict";
import { test } from "node:test";

import { server } from "./setup.mjs";

// AUD-B-03: the share of players who bought something (design line 11321)
// counts buyers among the period's players, so it never exceeds 1.
test("AUD-B-03: the buyer share counts only buyers among the period's players", () => {
  const t = server();
  const tel = t.service.telemetry;
  const [a, b, c] = ["gc:a", "gc:b", "gc:c"].map((p) => t.service.session(p).account);
  const D = Date.UTC(2026, 8, 23, 23, 50, 0);
  // A plays on D+1 and buys nothing; B and C start a session at 23:50 on D
  // and buy at 00:10 on D+1.
  tel.record(a, "session_start", {}, D + 21 * 60e3);
  for (const who of [b, c]) {
    tel.record(who, "session_start", {}, D);
    tel.record(who, "purchase", { product: "premium.1", cents: 499 }, D + 20 * 60e3);
  }
  const next = new Date(D + 20 * 60e3).toISOString().slice(0, 10);
  const r = tel.report({ from: next, to: next });
  assert.equal(r.players, 1);
  assert.equal(r.buyers, 0, "neither buyer played that day");
  const both = tel.report({ from: new Date(D).toISOString().slice(0, 10), to: next });
  assert.equal(both.players, 3);
  assert.equal(both.buyers, 2 / 3);
});

// AUD-B-04: a device clock a little ahead of the server's is not a reason to
// refuse a batch, which the client then drops whole (services.gd).
test("AUD-B-04: a device whose clock runs a second ahead still has its session events taken", () => {
  const t = server();
  const tel = t.service.telemetry;
  const me = t.service.session("gc:a").account;
  const now = t.clock.now;
  tel.batch(me, [{ kind: "session_start", data: {}, at: now - 60e3 + 1000 },
                 { kind: "session_end", data: { seconds: 60, crashed: false }, at: now + 1000 }]);
  const rows = t.service.db.prepare("SELECT kind, at FROM events WHERE kind LIKE 'session_%' ORDER BY at").all();
  assert.deepEqual(rows.map((r) => r.kind), ["session_start", "session_end"]);
  assert.ok(rows.every((r) => r.at <= now), "an event is never kept as later than the server's clock");
  // Far ahead is still refused.
  assert.throws(() => tel.batch(me, [{ kind: "session_start", data: {}, at: now + 60 * 60e3 }]),
                (e) => e.status === 400);
});
