// The season track (§18.2, §18.8).
//
// §18.2: "Fifty tiers, climbed with season points from heists, defences and
// discoveries. The free track gives pages, Essence and a stray. The premium
// track, bought with Starglass, adds cosmetics only." §18.8: "Unclaimed tiers
// stay claimable in a later season at the same cost. A missed season costs
// time, never access", and "Joining in week 6 does not mean losing 5 weeks.
// The track scales to the time remaining." §9.1 calls the points season
// stars, "reset each season".
//
// The document gives no star amounts, no tier cost and no tier-by-tier
// rewards. Each is a named constant here, and the readings are register G28.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));

/** Stars for a heist, by grade: ten times §12.9's Renown outcome for the
 *  raider, and what the raider did not take for the defender — a heist the
 *  defence foiled is a whole ten to it, a clean one nothing (G28). */
export const HEIST_STARS = 10;
export function heistStars(grade) {
  const raider = Math.round(HEIST_STARS * (facts.RENOWN_OUTCOME[grade] ?? 0));
  return { raider, defender: HEIST_STARS - raider };
}

/** A tier's price, as the owner decided it (G28): 10 stars, a §14.1 regular
 *  player's average day of raids at §9.6's success split, 490 for the track.
 *  Tier 1 costs nothing: "the season track's first tier is complete on day
 *  one" (§14's start-partly-filled rule). */
export const TIER_STARS = HEIST_STARS;

/** The six premium kinds §18.2 names, a cosmetic every fifth tier (G28). */
export const PREMIUM_KINDS = ["realm_skin", "sky_theme", "bridge_style", "outfit", "sage_robe", "law_visual"];

/** A Starglass is a euro (§19.12's "visible 1:1 rate"), held in hundredths
 *  so a price in cents is exact (G28, F41). */
export const PREMIUM_PRICE = facts.PREMIUM_TRACK_EUR * 100;

/**
 * Tier `tier`'s rewards in a season. The free track: at the top, a stray
 * offered for adoption at the next birth's price (F38, decided: a found stray
 * joins only when that price is paid),
 * a little Starglass every tenth tier (§9.1's "small amounts from the free
 * season track" — one Starglass a season, a sixth of the premium track),
 * five pages every other fifth, and Essence on the rest. The premium track: a
 * cosmetic every fifth tier, through the six kinds in turn (G28).
 */
export function tierRewards(season, tier) {
  let free;
  if (tier === facts.SEASON_TIERS) free = { strayOffer: 1 };
  else if (tier % 10 === 0) free = { starglass: 25 };
  else if (tier % 5 === 0) free = { pages: 5 };
  else free = { essence: 500 };
  const premium = tier % 5 === 0
    ? { cosmetic: `track-${season}-${tier}`, kind: PREMIUM_KINDS[(tier / 5 - 1) % PREMIUM_KINDS.length] }
    : null;
  return { free, premium };
}

export class Track {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }
  get seasons() { return this.service.seasons; }

  /** §18.8's catch-up: a player's tier price for a season is fixed when they
   *  first appear in it, scaled to the time left (G28). A season they never
   *  appeared in keeps the full price. */
  tierStars(account, season) {
    const row = this.db.prepare("SELECT tier_stars FROM standings WHERE season = ? AND account = ?")
      .get(season, account);
    return row?.tier_stars ?? TIER_STARS;
  }

  static scaled(remainingMs, seasonMs) {
    return Math.max(1, Math.round(TIER_STARS * Math.min(1, remainingMs / seasonMs)));
  }

  /** Stars in hand this season: earned, less spent. Last season's are gone. */
  stars(account, season = this.seasons.current().id) {
    return Number(this.db.prepare(
      "SELECT COALESCE(SUM(amount), 0) AS n FROM season_stars WHERE season = ? AND account = ?")
      .get(season, account).n);
  }

  /** A heist's stars, booked in the grant's transaction. An echo's owner
   *  defended nothing, and earns nothing. The raider has appeared in the
   *  season, so their tier price is fixed now if it is not yet: an echo raid
   *  opens their standing like any heist, and a season of them cannot wait
   *  out §18.8's catch-up to buy every tier at its floor. */
  settle(lease, verdict, season, now, { echo = false } = {}) {
    const s = heistStars(verdict.grade);
    if (echo) s.defender = 0;
    this.seasons.standing(lease.attacker, season);
    if (s.defender) this.seasons.standing(lease.defender, season);
    const book = this.db.prepare(
      "INSERT INTO season_stars (season, account, amount, reason, heist, at) VALUES (?, ?, ?, ?, ?, ?)");
    if (s.raider) book.run(season, lease.attacker, s.raider, `heist, ${verdict.grade} (18.2)`, lease.token, now);
    if (s.defender) book.run(season, lease.defender, s.defender, `defence, ${verdict.grade} (18.2)`, lease.token, now);
    return s;
  }

  claimed(account, season) {
    return this.db.prepare(
      "SELECT tier, track FROM track_claims WHERE account = ? AND season = ? ORDER BY tier")
      .all(account, season);
  }

  premium(account, season) {
    return Boolean(this.db.prepare("SELECT 1 FROM premium_tracks WHERE account = ? AND season = ?")
      .get(account, season));
  }

  /** A season's track as a player sees it: stars in hand, the tier price,
   *  how far they have claimed, and every tier's rewards. */
  view(account, season = this.seasons.current().id) {
    const current = this.seasons.current().id;
    if (!Number.isInteger(season) || season < 1 || season > current) {
      throw new Refused(404, "no_such_season");
    }
    if (season === current) this.seasons.standing(account, season);
    const free = this.claimed(account, season).filter((c) => c.track === "free").length;
    const price = this.tierStars(account, season);
    return {
      season, current, stars: this.stars(account, current), tierStars: price,
      claimed: free, premium: this.premium(account, season),
      next: free < facts.SEASON_TIERS ? { tier: free + 1, cost: free === 0 ? 0 : price } : null,
      tiers: Array.from({ length: facts.SEASON_TIERS }, (_, i) => ({ tier: i + 1, ...tierRewards(season, i + 1) })),
    };
  }

  /**
   * Claim the next tier of a season's track, this season's or any before it
   * (§18.8: "claimable in a later season at the same cost"), paid from this
   * season's stars. With the premium track, its reward comes with it.
   */
  claim(account, season = this.seasons.current().id) {
    const now = this.service.now();
    return transaction(this.db, () => {
      const v = this.view(account, season);
      if (!v.next) throw new Refused(409, "track_complete");
      if (v.stars < v.next.cost) {
        throw new Refused(409, "not_enough_stars", { stars: v.stars, cost: v.next.cost });
      }
      const { tier, cost } = v.next;
      if (cost) {
        this.db.prepare(
          "INSERT INTO season_stars (season, account, amount, reason, heist, at) VALUES (?, ?, ?, ?, NULL, ?)")
          .run(v.current, account, -cost, `season ${season}, tier ${tier} (18.2)`, now);
      }
      const rewards = tierRewards(season, tier);
      const out = { season, tier, cost, free: this.grant(account, season, tier, "free", rewards.free, now) };
      if (v.premium && rewards.premium) {
        out.premium = this.grant(account, season, tier, "premium", rewards.premium, now);
      }
      return out;
    });
  }

  /**
   * Buy a season's premium track with Starglass — this season's or, since
   * "nothing expires forever", an earlier one's, at the same price. The
   * premium rewards of tiers already claimed come with it.
   */
  buyPremium(account, season = this.seasons.current().id) {
    const now = this.service.now();
    return transaction(this.db, () => {
      const v = this.view(account, season);
      if (v.premium) throw new Refused(409, "premium_already_owned");
      this.service.spendStarglass(account, PREMIUM_PRICE, `the premium track, season ${season} (18.2)`, now);
      this.db.prepare("INSERT INTO premium_tracks (account, season, bought_at) VALUES (?, ?, ?)")
        .run(account, season, now);
      const granted = [];
      for (let tier = 1; tier <= v.claimed; tier++) {
        const r = tierRewards(season, tier).premium;
        if (r) granted.push({ tier, ...this.grant(account, season, tier, "premium", r, now) });
      }
      return { season, premium: true, granted };
    });
  }

  /** One reward, booked where the server holds it: Essence and Starglass in
   *  the ledger, a cosmetic in what the account owns. Pages and strays live
   *  on the device, so the claim row is their record (D64). */
  grant(account, season, tier, track, reward, now) {
    this.db.prepare(
      "INSERT INTO track_claims (account, season, tier, track, reward, at) VALUES (?, ?, ?, ?, ?, ?)")
      .run(account, season, tier, track, JSON.stringify(reward), now);
    const reason = `season ${season}, tier ${tier}, ${track} track (18.2)`;
    if (reward.essence) this.service.book(account, "essence", reward.essence, reason, now);
    if (reward.starglass) this.service.book(account, "starglass", reward.starglass, reason, now);
    if (reward.cosmetic) this.seasons.grantCosmetic(account, reward.cosmetic);
    return reward;
  }
}
