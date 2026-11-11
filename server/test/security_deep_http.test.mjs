// The deep security run's fixes at the edge and in the request paths
// (SEC-23 onwards): each request's work is bounded, and what it answers
// shows no more than its caller may see.

import assert from "node:assert/strict";
import { test } from "node:test";

import { confirm, MAX_ACTIONS } from "../src/offline.mjs";
import { server } from "./setup.mjs";

test("SEC-23: an offline batch of weaves builds the weaving view once, not once a weave", (ctx) => {
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:sec23").account;
  t.service.universe.ensure(me, t.clock.now);
  const views = ctx.mock.method(t.service.weaving, "view");
  const actions = Array.from({ length: MAX_ACTIONS }, () => ({ do: "unweave", realm: "heart", slot: 1 }));
  const answer = confirm(t.service, me, actions);
  assert.equal(answer.results.length, MAX_ACTIONS);
  assert.ok(answer.results.every((r) => r.confirmed && r.repeated), "an empty slot is answered as emptied");
  assert.ok(answer.weaving, "the batch still answers with what is woven");
  assert.equal(views.mock.callCount(), 1, "one view, after the whole queue");
  // A weave asked for on its own still answers with the view.
  const one = t.service.weaving.unweave(me, { realm: "heart", slot: 1 });
  assert.ok(one.weaving);
  assert.equal(one.repeated, true);
});
