// §9.4 and §9.6, against the document's own worked numbers.

import assert from "node:assert/strict";
import { test } from "node:test";

import { base, capHaul, dayCeiling, difficulty, entryFee, fatigue, feeReturned, FULL_CREW_CARRY, haul, perRaidCap,
         richness, weekCeiling } from "../src/economy.mjs";

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

test("the entry fee is 2% of B(V) at the target, never more than is held (9.4, F39)", () => {
  const rich = 10_000_000;
  assert.deepEqual([1, 2, 8, 10].map((v) => entryFee(rich, v)), [48, 72, 820, 1_845]);
  assert.equal(entryFee(40, 3), 40, "G17: a raider holding less than the fee pays what it holds");
  assert.equal(entryFee(0, 5), 0);
  // What comes back (C41): all after clean or loud, half after partial.
  assert.deepEqual(["clean", "loud", "partial", "foiled"].map((g) => feeReturned(109, g)), [109, 109, 54, 0]);
});

test("the per-raid cap is 1.98 times the base, derived from richness and difficulty (§9.6)", () => {
  for (const v of [1, 4, 10]) assert.equal(perRaidCap(v), BigInt(Math.floor(value(base(v)) * 1.98)));
});

test("a day's ceiling is half again above the whole fatigue curve; a week's is five days of it", () => {
  // 2,400 × (1 + 0.85 + 0.85² + …) = 2,400 ÷ 0.15 = 16,000 a day at the curve.
  assert.equal(dayCeiling(1), 24_000n);
  assert.equal(weekCeiling(1), 80_000n);
  assert.equal(weekCeiling(2), 120_000n);
});

test("a haul is cut by the first cap it meets, and re-split half Essence", () => {
  const pay = { total: 4000, essence: 2000, starlight: 2000 };
  const ctx = { targetVaultLevel: 1, raiderVaultLevel: 1, paidToday: 0, paidThisWeek: 0 };
  assert.equal(capHaul(pay, ctx).cappedBy, null);
  assert.equal(capHaul({ total: 9000, essence: 4500, starlight: 4500 }, ctx).total, 4752,
               "2,400 × 1.98");
  const day = capHaul(pay, { ...ctx, paidToday: 21_001 });
  assert.deepEqual([day.total, day.essence, day.starlight, day.cappedBy], [2999, 1499, 1500, "day"]);
  const week = capHaul(pay, { ...ctx, paidThisWeek: 79_000 });
  assert.deepEqual([week.total, week.cappedBy], [1000, "week"]);
  assert.equal(capHaul(pay, { ...ctx, paidThisWeek: 90_000 }).total, 0, "never negative");
});

test("the week's cap binds a grinder, and at §14.1's four raids a day never binds (G20)", () => {
  // Clean same-level raids at Vault level 1, capped as the server caps them.
  const week = (days, raidsADay) => {
    let paidThisWeek = 0;
    for (let d = 0; d < days; d++) {
      let paidToday = 0;
      for (let k = 0; k < raidsADay; k++) {
        const total = Math.floor(2400 * value(fatigue(k)));
        const pay = capHaul({ total, essence: 0, starlight: total },
                            { targetVaultLevel: 1, raiderVaultLevel: 1, paidToday, paidThisWeek });
        paidToday += pay.total;
        paidThisWeek += pay.total;
      }
    }
    return paidThisWeek;
  };
  // Twenty a day: the week's ceiling binds, and the sixth and seventh days add nothing.
  assert.equal(week(7, 20), 80_000);
  assert.equal(week(6, 20), 80_000);
  // Four a day, the engaged player's: no cap binds, so two days missed cost
  // two sevenths — §9.6's "missing two days a week costs nothing" does not
  // hold under this reading.
  assert.equal(week(5, 4) / week(7, 4), 5 / 7);
});
