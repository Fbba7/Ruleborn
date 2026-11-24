// FX2-9-audit-b-match: the offer's echoes flag (FX1-A-09, request FX1-R9).
// The lead's answer (cycle 169): the flag means an echo is among the targets,
// as the client shows it ("echoes of recent ones are among these").

import assert from "node:assert/strict";
import { test } from "node:test";

import { ratingFor } from "../src/glicko.mjs";
import { offer } from "../src/matchmaking.mjs";

/** A candidate a raider at 1500 beats with probability `p`. */
const candidate = (id, p, extra = {}) => ({ bundle: id, owner: `owner-${id}`, realm: "heart", realmLevel: 1,
  keeperLevel: 5, renown: 100, rating: ratingFor(p), deviation: 0, origin: "authored", echo: false, ...extra });
const RAIDER = { account: "me", rating: 1500, deviation: 0, renown: 100, keeperLevel: 5, recent: 0.625 };

test("FX1-A-09: a thin list that reached for an echo it did not offer does not say echoes (12.22)", () => {
  // Two live islands in the band, three outside it, and one echo outside it:
  // the list reaches for echoes, but the echo is not among the three it offers.
  const out = offer(RAIDER, [candidate("a", 0.62), candidate("b", 0.63), candidate("x", 0.5),
                             candidate("y", 0.52), candidate("z", 0.75), candidate("old", 0.5, { echo: true })]);
  assert.ok(out.targets.every((c) => !c.echo), "no echo is offered");
  assert.equal(out.echoes, false, "the list says no echo is among its targets");
});

test("FX1-A-09: a thin list that offers an echo says so (12.3, 12.22)", () => {
  const out = offer(RAIDER, [candidate("a", 0.62), candidate("b", 0.63), candidate("old", 0.64, { echo: true })]);
  assert.ok(out.targets.some((c) => c.echo), "the echo is offered");
  assert.equal(out.echoes, true);
});
