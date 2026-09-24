// Glicko-2 (Glickman, "Example of the Glicko-2 system", 2012), as §12.22
// asks: "Skill and island difficulty are Bayesian, with an uncertainty term
// … a wide deviation, 350 on Glicko-2's scale, which narrows with every
// observed attack under Glicko-2's update (volatility 0.06, system constant
// 0.5)."
//
// Pure arithmetic: a rating is {rating, deviation, volatility} on the
// Glicko scale, and nothing here touches the database.

import { readFileSync } from "node:fs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));

export const SCALE = 173.7178;
export const CENTRE = 1500;
/** §12.22's constants, from the step that is their home. */
export const [DEVIATION, VOLATILITY, TAU] = facts.GLICKO;
const EPSILON = 0.000001;

export const fresh = (rating = CENTRE) => ({ rating, deviation: DEVIATION, volatility: VOLATILITY });

const g = (phi) => 1 / Math.sqrt(1 + (3 * phi * phi) / (Math.PI * Math.PI));

/**
 * One rating period for `player` against `games`, each {opponent, score}
 * with score 1 for a win and 0 for a loss. A period with no games only
 * widens the deviation (step 6 alone).
 */
export function update(player, games) {
  const mu = (player.rating - CENTRE) / SCALE;
  const phi = player.deviation / SCALE;
  const sigma = player.volatility;
  if (games.length === 0) {
    const widened = Math.sqrt(phi * phi + sigma * sigma);
    return { ...player, deviation: Math.min(DEVIATION, widened * SCALE) };
  }
  let vInverse = 0;
  let sum = 0;
  for (const { opponent, score } of games) {
    const muJ = (opponent.rating - CENTRE) / SCALE;
    const gJ = g(opponent.deviation / SCALE);
    const e = 1 / (1 + Math.exp(-gJ * (mu - muJ)));
    vInverse += gJ * gJ * e * (1 - e);
    sum += gJ * (score - e);
  }
  const v = 1 / vInverse;
  const delta = v * sum;

  // Step 5: the new volatility, by the Illinois algorithm.
  const a = Math.log(sigma * sigma);
  const f = (x) => {
    const ex = Math.exp(x);
    const d = phi * phi + v + ex;
    return (ex * (delta * delta - phi * phi - v - ex)) / (2 * d * d) - (x - a) / (TAU * TAU);
  };
  let A = a;
  let B;
  if (delta * delta > phi * phi + v) {
    B = Math.log(delta * delta - phi * phi - v);
  } else {
    let k = 1;
    while (f(a - k * TAU) < 0) k++;
    B = a - k * TAU;
  }
  let fA = f(A);
  let fB = f(B);
  while (Math.abs(B - A) > EPSILON) {
    const C = A + ((A - B) * fA) / (fB - fA);
    const fC = f(C);
    if (fC * fB <= 0) {
      A = B;
      fA = fB;
    } else {
      fA /= 2;
    }
    B = C;
    fB = fC;
  }
  const volatility = Math.exp(A / 2);

  // Steps 6 to 8.
  const phiStar = Math.sqrt(phi * phi + volatility * volatility);
  const phiNew = 1 / Math.sqrt(1 / (phiStar * phiStar) + 1 / v);
  const muNew = mu + phiNew * phiNew * sum;
  return { rating: SCALE * muNew + CENTRE, deviation: SCALE * phiNew, volatility };
}

/**
 * The chance that `a` beats `b`, both uncertainties counted: Glicko's
 * expected score with the two deviations combined.
 */
export function expected(a, b) {
  const phi = Math.hypot(a.deviation, b.deviation) / SCALE;
  return 1 / (1 + Math.exp(-g(phi) * (a.rating - b.rating) / SCALE));
}

/** The rating at which a certain player (deviation 0) at `against` wins
 *  with probability `p`: how a hold rate becomes a prior. */
export function ratingFor(p, against = CENTRE) {
  return against - (SCALE * Math.log(p / (1 - p)));
}
