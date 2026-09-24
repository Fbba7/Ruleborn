// What a validated heist settles (§9.4, §9.6), in exact integer arithmetic.
//
// Every number is the document's, read from facts.json — which
// tools/design_facts.py generates after reading each one back from its home
// section — or from content/. Nothing here is typed from the prose.
//
// §9.6: "Haul = B(V) × grade × difficulty × richness × fatigue × fill". The
// terms multiply as exact ratios (BigInt) and the one rounding, down, happens
// last, so a haul is the same on every server that computes it.
//
// Three readings the document leaves open are taken here and named, so they
// can be found and changed in one place (register G17):
//
//   * difficulty "Level or above 1.0 to 1.2" does not say where in the range
//     a target falls. Read as 1.0 at the raider's level and 0.1 more a level
//     above, reaching the cap at two above.
//   * §9.6 does not say what a haul is minted in. §32.9's ledger derives the
//     birth curve from "raid Essence at base 2,400 (half of each haul)", so a
//     haul is minted half Essence, the rest Starlight.
//   * The entry fee's floor is 100 Starlight, and nothing says what a raider
//     holding less pays. Read as whatever they hold: the ledger never goes
//     below zero.
//
// And three for §9.6's caps (register G20):
//
//   * "Per day: the fatigue curve, plus a hard ceiling half again above it"
//     does not say whose base the curve is in. Read as the raider's own Vault
//     level: the ceiling is there "for players punching up", so it is measured
//     from where the raider stands.
//   * "Per week: five days' worth" is read as five days of the whole fatigue
//     curve at that base. Under it no player type §14.1 models reaches either
//     cap — four raids a day are 3.19 first raids, not 6.67 — so §9.6's
//     "missing two days a week costs nothing" does not hold for them: missing
//     two days costs two sevenths. §9.6's own "A full day, four raids" column
//     would make it hold, but in that unit the day's ceiling would cap a single
//     clean raid, so §9.6 has to say which unit each cap is in (G20).
//   * A week starts on Monday, UTC, like the day.

import { readFileSync } from "node:fs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const roles = JSON.parse(readFileSync(new URL("../../content/roles.json", import.meta.url), "utf8"));

/** A decimal as an exact ratio: 0.85 is 85/100, not the nearest double. */
export function ratio(value) {
  const text = String(value);
  if (!/^\d+(\.\d+)?$/.test(text)) throw new Error(`not a plain decimal: ${text}`);
  const [whole, frac = ""] = text.split(".");
  return [BigInt(whole + frac), 10n ** BigInt(frac.length)];
}

const mul = ([a, b], [c, d]) => [a * c, b * d];
const pow = (r, k) => Array.from({ length: k }).reduce((acc) => mul(acc, r), [1n, 1n]);
const min = (x, y) => (x[0] * y[1] <= y[0] * x[1] ? x : y);
const max = (x, y) => (x[0] * y[1] >= y[0] * x[1] ? x : y);
const floor = ([n, d]) => n / d;

/** §9.6: "a full five-crew carries 750 at level 1 (11.1)" — from content/. */
export const FULL_CREW_CARRY = roles.reduce((sum, r) => sum + r.carry, 0);

/** §9.6's B(V): "2,400 × 1.5^(V−1)", V the target's Vault level. */
export function base(vaultLevel) {
  return mul([BigInt(facts.HAUL_BASE), 1n], pow(ratio(facts.HAUL_GROWTH), vaultLevel - 1));
}

/** §9.6's grade, which "supersedes the older outcome multipliers in 12.9". */
export function grade(name) {
  return ratio(facts.GRADE_VALUE[name]);
}

/**
 * §9.6's difficulty, by Keeper level: "Level or above 1.0 to 1.2, one below
 * 0.8, two below 0.5, three or more below 0.25". Where in 1.0 to 1.2 a target
 * above the raider falls is this file's reading (G17): 0.1 a level.
 */
export function difficulty(raiderLevel, targetLevel) {
  const [atLevel, cap, oneBelow, twoBelow, threeBelow] = facts.DIFFICULTY.map(ratio);
  const above = targetLevel - raiderLevel;
  if (above >= 0) {
    return min(cap, [atLevel[0] * 10n + atLevel[1] * BigInt(above), atLevel[1] * 10n]);
  }
  return above === -1 ? oneBelow : above === -2 ? twoBelow : threeBelow;
}

/**
 * §9.6's richness, from the snapshot's exposed share in bag units, which is
 * "a full five-crew's carry × the richness ratio before clamping". Clamped to
 * 0.6–1.8, "with a reduction above 1.5": the excess is halved, "so 1.8 pays
 * 1.65".
 */
export function richness(exposed) {
  const [lo, hi, knee] = facts.RICHNESS_CLAMP.map(ratio);
  let r = max(lo, min(hi, [BigInt(exposed), BigInt(FULL_CREW_CARRY)]));
  if (r[0] * knee[1] > knee[0] * r[1]) {
    // knee + (r − knee) / 2
    r = [knee[0] * r[1] + r[0] * knee[1], 2n * knee[1] * r[1]];
  }
  return r;
}

/** §9.6: "0.85 on each successive raid that day". */
export function fatigue(raidsEarlierToday) {
  return pow(ratio(facts.HAUL_FATIGUE), raidsEarlierToday);
}

/**
 * §9.6's fill: "the share loaded of the smaller of the crew's bags and the
 * target's exposed share in bag units". A full crew is 1.
 */
export function fill(banked, capacity, exposed) {
  const basis = Math.min(capacity, exposed);
  if (basis <= 0) return [0n, 1n];
  return min([1n, 1n], [BigInt(banked), BigInt(basis)]);
}

/** Every term, and the haul they multiply to, rounded down once. */
export function haul({ vaultLevel, gradeName, raiderLevel, targetLevel, exposed,
                       raidsEarlierToday, banked, capacity }) {
  const terms = {
    base: base(vaultLevel),
    grade: grade(gradeName),
    difficulty: difficulty(raiderLevel, targetLevel),
    richness: richness(exposed),
    fatigue: fatigue(raidsEarlierToday),
    fill: fill(banked, capacity, exposed),
  };
  const total = floor(Object.values(terms).reduce(mul, [1n, 1n]));
  // §32.9: "half of each haul" is Essence (G17).
  const essence = total / 2n;
  return {
    total: Number(total),
    essence: Number(essence),
    starlight: Number(total - essence),
    terms: Object.fromEntries(Object.entries(terms).map(([k, [n, d]]) => [k, Number(n) / Number(d)])),
  };
}

/**
 * §9.4: "Entry fee: 2% of the raider's Starlight, from 100 to 25,000,
 * returned in full after a clean heist." Never more than the raider holds
 * (G17).
 */
export function entryFee(starlight) {
  const [n, d] = ratio(facts.ENTRY_FEE_RATE);
  const fee = Number((BigInt(Math.max(0, starlight)) * n) / d);
  const clamped = Math.min(facts.ENTRY_FEE_MAX, Math.max(facts.ENTRY_FEE_MIN, fee));
  return Math.min(clamped, Math.max(0, starlight));
}

// -- the caps (§9.6) ---------------------------------------------------------

/** 1 + 0.85 + 0.85² + … — a whole day of the fatigue curve, in first raids. */
function wholeCurve() {
  const [n, d] = ratio(facts.HAUL_FATIGUE);
  return [d, d - n];
}

/**
 * "Per raid: never more than 1.98 times the base … richness is clamped at
 * 1.8 but the excess above 1.5 is halved, so the most any hoard can pay is
 * 1.65, and the difficulty bonus tops out at 1.2". Derived from those two
 * terms rather than typed, so it moves if either does.
 */
export function perRaidCap(vaultLevel) {
  const [, hi, knee] = facts.RICHNESS_CLAMP.map(ratio);
  const richest = [knee[0] * hi[1] + hi[0] * knee[1], 2n * knee[1] * hi[1]];
  return floor(mul(base(vaultLevel), mul(richest, ratio(facts.DIFFICULTY[1]))));
}

/** §9.6: "a hard ceiling half again above" the day's fatigue curve. */
export const HALF_AGAIN = [3n, 2n];

/** §9.6: "Per week: five days' worth, not seven". */
export const DAYS_A_WEEK_PAID = 5n;

export function dayCeiling(raiderVaultLevel) {
  return floor(mul(mul(base(raiderVaultLevel), wholeCurve()), HALF_AGAIN));
}

export function weekCeiling(raiderVaultLevel) {
  return floor(mul(mul(base(raiderVaultLevel), wholeCurve()), [DAYS_A_WEEK_PAID, 1n]));
}

/**
 * A haul after §9.6's three caps: this raid's, then what is left of the day's
 * and the week's. Returns the haul re-split half Essence, and which cap cut
 * it, if one did.
 */
export function capHaul(pay, { targetVaultLevel, raiderVaultLevel, paidToday, paidThisWeek }) {
  const limits = [
    ["raid", perRaidCap(targetVaultLevel)],
    ["day", dayCeiling(raiderVaultLevel) - BigInt(paidToday)],
    ["week", weekCeiling(raiderVaultLevel) - BigInt(paidThisWeek)],
  ];
  let total = BigInt(pay.total);
  let cappedBy = null;
  for (const [name, left] of limits) {
    const room = left > 0n ? left : 0n;
    if (total > room) {
      total = room;
      cappedBy = name;
    }
  }
  if (cappedBy === null) return { ...pay, cappedBy };
  const essence = total / 2n;
  return { ...pay, total: Number(total), essence: Number(essence),
           starlight: Number(total - essence), cappedBy };
}
