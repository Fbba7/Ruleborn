// §18.9's Island Fund, paid from the purchase records.
//
// §18.9: "10% of net cosmetic and season-pass revenue goes into a Island
// Fund each quarter. … The fund is divided at the end of each quarter by
// time actually played on each island. … no single creator may take more
// than 2% of a quarter's fund. The remainder spreads down the tail. …
// Payment requires opting in, verifying identity and being 18 or over. …
// Time played is … self-play and constellation play are discounted as in
// 18.7, and any island found gaming the count is removed from the fund
// permanently."
//
// Net revenue is each purchase's price, less a refund the store has not
// reversed (G32), less the store's commission at §22.5's 15%, the rate of the
// low and base scenarios and of both stores' first million; the fund is 10%
// of it, in euro cents, rounded down. Time played on an island is each
// validated Workshop play's seconds — from the landing to the last crew
// member out or caught where the event log gives it (TD.39), else the
// clock — none of it the creator's own and a quarter of it a player's who
// shared a constellation with the creator (§18.7's readings, workshop.mjs).
// A removed island earns nothing. Each opted-in creator of 18 or over takes
// the share of the fund their islands' time is of all such creators' time,
// none above 2%, what a cap leaves spread over the creators under it in
// proportion, again until none is over (an assumption: §18.9 says the
// remainder "spreads down the tail", not how).
//
// A quarter is closed once, after it ends, by the daily job: the payouts are
// written then and never again (G-register). Not built, because §18.9 gives
// no numbers for them: the share per hour that "falls in bands as a
// creator's total rises", the floor for an island past 500 completions, and
// the cap on one player's time on one island. Identity checks and paying the
// money are outside the server.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";
import { TICKS_PER_SECOND } from "./service.mjs";
import { kin } from "./workshop.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));

/** The UTC quarter `at` falls in: its number since 1970 and its bounds. */
export function quarterOf(at) {
  const d = new Date(at);
  const q = d.getUTCFullYear() * 4 + Math.floor(d.getUTCMonth() / 3);
  return quarter(q);
}

export function quarter(q) {
  const year = Math.floor(q / 4);
  const month = (q % 4) * 3;
  return { q, starts_at: Date.UTC(year, month, 1), ends_at: Date.UTC(year, month + 3, 1),
           name: `${year}-Q${(q % 4) + 1}` };
}

/** Shares of `pool` in proportion to `weights` ({id: weight}), none above
 *  `cap`: a share at the cap is held there and what it would have taken goes
 *  to the rest in proportion, until none is over. Whole cents, rounded
 *  down, so the pool is never overpaid. */
export function capped(weights, pool, cap) {
  const out = {};
  let open = Object.keys(weights).filter((id) => weights[id] > 0);
  let left = pool;
  for (;;) {
    const total = open.reduce((s, id) => s + weights[id], 0);
    if (!total) break;
    const over = open.filter((id) => (left * weights[id]) / total > cap);
    if (!over.length) {
      for (const id of open) out[id] = Math.floor((left * weights[id]) / total);
      break;
    }
    for (const id of over) out[id] = cap;
    left -= cap * over.length;
    open = open.filter((id) => !over.includes(id));
  }
  return out;
}

export class Fund {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }

  /** A quarter's net revenue in euro cents: what was paid, less what was
   *  refunded and not reversed, less §22.5's store commission. */
  net(from, to) {
    const rows = this.db.prepare(
      `SELECT p.price FROM purchases p
        WHERE p.at >= ? AND p.at < ?
          AND COALESCE((SELECT r.kind FROM refunds r WHERE r.store = p.store AND r.txn = p.txn
                         ORDER BY r.id DESC LIMIT 1), 'reversal') != 'refund'`).all(from, to);
    const gross = rows.reduce((s, r) => s + r.price, 0);
    return Math.floor((gross * (100 - facts.STORE_COMMISSION)) / 100);
  }

  /** Seconds played on each creator's islands in a quarter, §18.7's way:
   *  none of a creator's own, a quarter of a constellation-mate's, nothing
   *  on an island removed from the Workshop. */
  played(from, to) {
    const rows = this.db.prepare(
      `SELECT p.player, p.ticks, p.outcome, i.creator, i.published_at FROM workshop_plays p
         JOIN workshop_items i ON i.id = p.item
        WHERE p.submitted_at >= ? AND p.submitted_at < ? AND i.removed_at IS NULL`).all(from, to);
    const out = {};
    for (const r of rows) {
      const o = r.outcome ? JSON.parse(r.outcome) : null;
      if (!o?.validated || r.player === r.creator) continue;
      const seconds = Number.isInteger(o.report?.held) ? o.report.held : r.ticks / TICKS_PER_SECOND;
      const weight = kin(this.db, r.player, r.creator, r.published_at) ? facts.KIN_COMPLETION_WEIGHT : 1;
      out[r.creator] = (out[r.creator] ?? 0) + seconds * weight;
    }
    return out;
  }

  /** Quarter `q` divided, once, after it ends: the fund, each opted-in
   *  adult creator's seconds and share, written for good. A quarter already
   *  closed, or not yet over, is left as it is. Returns the quarter's rows. */
  close(q, now = this.service.now()) {
    const quarter_ = quarter(q);
    if (now < quarter_.ends_at) return null;
    return transaction(this.db, () => {
      const done = this.db.prepare("SELECT * FROM fund_quarters WHERE quarter = ?").get(q);
      if (done) return this.payouts(q);
      const net = this.net(quarter_.starts_at, quarter_.ends_at);
      const pool = Math.floor((net * facts.ISLAND_FUND_SHARE) / 100);
      const eligible = new Set(this.db.prepare(
        "SELECT id FROM accounts WHERE fund_opt_in = 1 AND age_band = '18+' AND banned_at IS NULL AND deleted_at IS NULL")
        .all().map((r) => r.id));
      const played = Object.fromEntries(Object.entries(this.played(quarter_.starts_at, quarter_.ends_at))
        .filter(([creator]) => eligible.has(creator)));
      const cap = Math.floor((pool * facts.ISLAND_FUND_CAP) / 100);
      const shares = capped(played, pool, cap);
      this.db.prepare("INSERT INTO fund_quarters (quarter, net, pool, closed_at) VALUES (?, ?, ?, ?)")
        .run(q, net, pool, now);
      const insert = this.db.prepare(
        "INSERT INTO fund_payouts (quarter, creator, seconds, cents) VALUES (?, ?, ?, ?)");
      for (const [creator, seconds] of Object.entries(played)) {
        insert.run(q, creator, Math.round(seconds), shares[creator] ?? 0);
      }
      return this.payouts(q);
    });
  }

  /** Every quarter that has ended and is not closed, closed: the daily job. */
  closeEnded(now = this.service.now()) {
    const last = quarterOf(now).q - 1;
    const first = this.db.prepare("SELECT MIN(at) AS at FROM purchases").get().at;
    if (first == null) return [];
    const out = [];
    for (let q = quarterOf(first).q; q <= last; q++) {
      if (!this.db.prepare("SELECT 1 FROM fund_quarters WHERE quarter = ?").get(q)) out.push(this.close(q, now));
    }
    return out;
  }

  payouts(q) {
    const head = this.db.prepare("SELECT * FROM fund_quarters WHERE quarter = ?").get(q);
    return { quarter: quarter(q).name, net: head.net, pool: head.pool,
             payouts: this.db.prepare("SELECT creator, seconds, cents FROM fund_payouts WHERE quarter = ? ORDER BY creator")
               .all(q).map((r) => ({ creator: r.creator, seconds: r.seconds, cents: r.cents })) };
  }

  /** §18.9's settings page: whether the player has opted in, whether they
   *  may, and what each closed quarter paid them. No live counter and no
   *  projection: only quarters already closed. */
  view(account) {
    const a = this.db.prepare("SELECT fund_opt_in, age_band FROM accounts WHERE id = ?").get(account);
    const paid = this.db.prepare(
      `SELECT f.quarter, f.cents FROM fund_payouts f WHERE f.creator = ? ORDER BY f.quarter`).all(account);
    return { opted_in: a.fund_opt_in === 1, may: a.age_band === "18+",
             quarters: paid.map((r) => ({ quarter: quarter(r.quarter).name, cents: r.cents })) };
  }

  /** Opting in or out; only at 18 or over (§18.9, §20.7). */
  optIn(account, yes) {
    if (typeof yes !== "boolean") throw new Refused(400, "malformed_body");
    const a = this.db.prepare("SELECT age_band FROM accounts WHERE id = ?").get(account);
    if (yes && a.age_band !== "18+") throw new Refused(403, "fund_adults_only");
    this.db.prepare("UPDATE accounts SET fund_opt_in = ? WHERE id = ?").run(yes ? 1 : 0, account);
    return this.view(account);
  }
}
