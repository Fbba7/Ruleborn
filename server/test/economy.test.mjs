// §9.4 and §9.6, against the document's own worked numbers.

import assert from "node:assert/strict";
import { test } from "node:test";

import { base, difficulty, entryFee, fatigue, FULL_CREW_CARRY, haul, richness } from "../src/economy.mjs";

const value = ([n, d]) => Number(n) / Number(d);

test("B(V) is §9.6's table: 2,400 at Vault level 1, 3,600 at 2, 18,225 at 6, 92,264 at 10", () => {
  assert.equal(value(base(1)), 2400);
  assert.equal(value(base(2)), 3600);
  assert.equal(value(base(6)), 18225);
  assert.equal(Math.floor(value(base(10))), 92264);
});

test("six raids in a day pay about 4.15 times one (§9.6)", () => {
  const six = [0, 1, 2, 3, 4, 5].reduce((sum, k) => sum + value(fatigue(k)), 0);
  assert.equal(six.toFixed(2), "4.15");
});

test("a full five-crew carries 750 (§9.6, from content/roles.json)", () => {
  assert.equal(FULL_CREW_CARRY, 750);
});

test("richness is clamped to 0.6–1.8 and the excess over 1.5 halved: 1.8 pays 1.65", () => {
  assert.equal(value(richness(750)), 1);
  assert.equal(value(richness(750 * 1.8)), 1.65);
  assert.equal(value(richness(750 * 3)), 1.65);
  assert.equal(value(richness(750 * 0.4)), 0.6);
  assert.equal(value(richness(0)), 0.6, "a sealed island still pays 0.6 (9.6)");
});

test("difficulty by Keeper level: 0.8, 0.5 and 0.25 below; 1.0 to 1.2 at or above", () => {
  assert.equal(value(difficulty(10, 9)), 0.8);
  assert.equal(value(difficulty(10, 8)), 0.5);
  assert.equal(value(difficulty(10, 7)), 0.25);
  assert.equal(value(difficulty(10, 1)), 0.25);
  assert.equal(value(difficulty(10, 10)), 1.0);
  assert.equal(value(difficulty(10, 11)), 1.1, "this file's reading of 1.0 to 1.2 (G17)");
  assert.equal(value(difficulty(10, 15)), 1.2, "and the cap");
});

test("no raid pays more than 1.98 times its base (§9.6's per-raid cap)", () => {
  const most = haul({ vaultLevel: 4, gradeName: "clean", raiderLevel: 1, targetLevel: 30,
                      exposed: 100_000, raidsEarlierToday: 0, banked: 750, capacity: 750 });
  assert.equal(most.total, Math.floor(value(base(4)) * 1.98));
});

test("a haul is minted half Essence (§32.9's reading, G17) and rounds down once", () => {
  const h = haul({ vaultLevel: 3, gradeName: "loud", raiderLevel: 5, targetLevel: 5,
                   exposed: 750, raidsEarlierToday: 2, banked: 300, capacity: 508 });
  // 5,400 × 0.7 × 1 × 1 × 0.7225 × 300/508
  assert.equal(h.total, Math.floor(5400 * 0.7 * 0.7225 * 300 / 508));
  assert.equal(h.essence, Math.floor(h.total / 2));
  assert.equal(h.starlight + h.essence, h.total);
  const foiled = haul({ vaultLevel: 3, gradeName: "foiled", raiderLevel: 5, targetLevel: 5,
                        exposed: 750, raidsEarlierToday: 0, banked: 0, capacity: 508 });
  assert.equal(foiled.total, 0);
});

test("fill is against the smaller of the crew's bags and what is exposed", () => {
  const poor = haul({ vaultLevel: 1, gradeName: "clean", raiderLevel: 1, targetLevel: 1,
                      exposed: 300, raidsEarlierToday: 0, banked: 300, capacity: 508 });
  assert.equal(poor.terms.fill, 1, "a poor island's exposed share, all taken, is a full load");
  assert.equal(poor.terms.richness, 0.6, "and poverty is priced once, by richness");
});

test("the entry fee is 2% of Starlight, from 100 to 25,000 (§9.4), never more than is held", () => {
  assert.equal(entryFee(1_000), 100);
  assert.equal(entryFee(50_000), 1_000);
  assert.equal(entryFee(10_000_000), 25_000);
  assert.equal(entryFee(40), 40, "G17: a raider holding less than 100 pays what it holds");
  assert.equal(entryFee(0), 0);
});
