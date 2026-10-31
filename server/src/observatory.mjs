// §12.3's Observatory and §12.4's scouting: the targets a raider is offered,
// each as its free target card, and the paid refresh.
//
// §12.3: "The Observatory offers 3 universes (4 from level 3, 5 at level 5,
// 10.2) … biased so the median heist is winnable (12.15), from the band
// 12.22 sets." "Refreshing the list costs Aether: 50, doubling with each
// refresh in the same hour." "A Trace is shown in addition to the offered
// list, pinned first (12.22)."
//
// §12.4: "Scouting is free, and it is the target card. Every target shows,
// before any heist: the Keeper's name …, Keeper level, number of realms,
// Renown, one rough loot estimate, the universe's strain and open faults
// (5.4), and for each realm its laws, the number and roles of its guards, its
// watch (5.2) and how many wards of each type it has. Nothing placed is
// shown." So a card carries counts and never a tile; the rating that orders
// the list stays on the server (TD.18), and each card says instead why it
// was offered and what the lease will charge (`stakes`, the lease's own).
//
// §12.3: "and one more while the Wanderer is at home (11.7)": a Sage's
// at-home effect "applies whenever it is not on a heist, at home or on
// guard", and the list is offered between heists, so it is one more target
// from the Keeper level that unlocks the Wanderer.
//
// A card carries its universe's depth, "up to N realms to the Heart", and
// the realms its faults open from (links.mjs); a heist crossing those realms
// is T3.3's.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { GENERATOR } from "./generator.mjs";
import { offer, successBand } from "./matchmaking.mjs";
import { Refused } from "./refused.mjs";
import { clockTicks, TICKS_PER_SECOND } from "./service.mjs";
import { lawsOf } from "./telemetry.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const OBSERVATORY = JSON.parse(readFileSync(new URL("../../content/buildings.json", import.meta.url), "utf8"))
  .find((b) => b.id === "observatory");
const HOUR = 60 * 60 * 1000;
const WANDERER = JSON.parse(readFileSync(new URL("../../content/sages.json", import.meta.url), "utf8"))
  .find((s) => s.id === "the_wanderer");
/** The Keeper level the Wanderer comes at, and the targets it adds at home. */
export const WANDERER_FROM = Number(/Keeper level (\d+)/.exec(WANDERER.unlocks)[1]);
export const WANDERER_EXTRA = /offers one more target/.test(WANDERER.at_home) ? 1 : 0;

/** §12.17's role rows and §10.3's ward kinds, in the bundle's numbering
 *  (sim/src/island.rs `Post::row`, sim/src/heist.rs `WardKind`). */
export const ROLES = ["Scout", "Warden", "Breaker", "Carrier", "Mender"];
export const WARD_KINDS = ["crystal_wall", "thorn_hedge", "static_coil", "gravity_well", "time_snare", "lantern_glare"];

/** §10.2's Observatory: "3 targets" at levels 1 and 2, 4 at 3 and 4, 5 at 5;
 *  §12.3's three before one is built. */
export function targetsAt(level) {
  const row = OBSERVATORY.levels.find((l) => l.level === level);
  return row ? Number(/(\d+) targets/.exec(row.gives)[1]) : 3;
}

/** §5.5's open faults at `strain` (a ratio) in a universe of `outer` outer
 *  realms: none in the Heart alone, and never more than its outer realms. */
export function faults(strain, outer) {
  let n = 0;
  for (const [at, count] of facts.FAULTS_BY_STRAIN) if (strain * 100 >= at) n = count;
  return Math.min(n, outer);
}

/** §12.4's facts of one realm, read from its public bundle: its laws, its
 *  guards by role and wards by kind, counted, and nothing placed. */
export function realmFacts(bundle) {
  const b = bundle instanceof Uint8Array ? bundle : new Uint8Array(bundle);
  const side = 9 + b[4];
  let at = 14 + side * side * 3;
  const guards = {};
  for (let n = b[at++]; n > 0; n--, at += 3) {
    const role = ROLES[b[at] & 15] ?? "Scout";
    guards[role] = (guards[role] ?? 0) + 1;
  }
  const wards = {};
  for (let n = b[at++]; n > 0; n--, at += 3) {
    const kind = WARD_KINDS[b[at]] ?? String(b[at]);
    wards[kind] = (wards[kind] ?? 0) + 1;
  }
  return { laws: lawsOf(b), guards, wards };
}

/** "One rough loot estimate": two significant figures. */
export const rough = (n) => {
  if (n < 100) return Math.round(n);
  const unit = 10 ** (Math.floor(Math.log10(n)) - 1);
  return Math.round(n / unit) * unit;
};

export class Observatory {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }

  /** The raider's Observatory level, 0 before one is built. */
  level(account) {
    return this.db.prepare("SELECT MAX(level) AS l FROM buildings WHERE owner = ? AND kind = 'observatory'")
      .get(account)?.l ?? 0;
  }

  /** What the next refresh costs: 50 Aether, doubled for each refresh in the
   *  hour before. */
  refreshCost(account, now = this.service.now()) {
    const n = this.db.prepare("SELECT COUNT(*) AS n FROM observatory_refreshes WHERE owner = ? AND at > ?")
      .get(account, now - HOUR).n;
    return facts.OBSERVATORY_REFRESH_AETHER * 2 ** n;
  }

  /** The bundles the last refresh set aside, so the list it buys is new. */
  setAside(account) {
    const r = this.db.prepare("SELECT shown FROM observatory_refreshes WHERE owner = ? ORDER BY at DESC LIMIT 1")
      .get(account);
    return new Set(r ? JSON.parse(r.shown) : []);
  }

  /** The Observatory as the device draws it: its targets as cards, a Trace
   *  apart and first, the refresh's price, and whether the raider is still a
   *  protected new player, whom raiding a player un-protects (§12.3). */
  view(account, now = this.service.now()) {
    const mm = this.service.matchmaking;
    const keeper = this.db.prepare("SELECT keeper_level FROM accounts WHERE id = ?").get(account)?.keeper_level ?? 1;
    const wanderer = keeper >= WANDERER_FROM;
    const size = targetsAt(this.level(account)) + (wanderer ? WANDERER_EXTRA : 0);
    const aside = this.setAside(account);
    const list = offer(mm.raider(account, now), mm.listed(now).filter((c) => !aside.has(c.bundle)), { size });
    list.targets = mm.current(list.targets);
    // The raider's week and Starlight, read once for every card's fee.
    const raider = this.service.raider(account, now);
    const targets = list.targets.map((c) => this.card(account, c, { raider }));
    return { size, wanderer, targets, trace: this.trace(account, now, raider), echoes: list.echoes, generated: list.generated,
             refresh: { aether: this.refreshCost(account, now) }, aether: this.service.aether(account),
             protected: mm.shielded(account, now) };
  }

  /** §12.3's Trace: the island of the most recent raider this player can
   *  still answer, with no fee. */
  trace(account, now, raider = this.service.raider(account, now)) {
    const mm = this.service.matchmaking;
    const raiders = this.db.prepare(
      `SELECT DISTINCT h.attacker FROM heists h JOIN leases l ON l.token = h.token
        WHERE h.defender = ? AND h.submitted_at > ? ORDER BY h.submitted_at DESC`)
      .all(account, now - facts.TRACE_HOURS * HOUR).map((r) => r.attacker);
    for (const raider of raiders) {
      if (!mm.traceable(account, raider, now)) continue;
      const island = this.db.prepare("SELECT bundle, realm FROM islands WHERE owner = ? ORDER BY realm = 'heart' DESC")
        .get(raider);
      if (!island) continue;
      const c = mm.listed(now).find((x) => x.bundle === island.bundle && x.owner === raider)
        ?? { bundle: island.bundle, owner: raider, echo: false, origin: "authored" };
      return { ...this.card(account, c, { trace: true, raider }), fee: 0 };
    }
    return null;
  }

  /** One target card (§12.4): free facts only, the fee the lease would
   *  charge now, and why it was offered — never the rating. */
  card(account, c, { trace = false, raider = this.service.raider(account) } = {}) {
    const snap = this.db.prepare("SELECT realm, realm_level, vault_level, exposed FROM snapshots WHERE bundle = ?")
      .get(c.bundle);
    const generated = c.owner === GENERATOR;
    const owner = generated ? null
      : this.db.prepare("SELECT keeper_level FROM accounts WHERE id = ?").get(c.owner);
    // The Heart and the outer realms, which are the realms table's rows.
    const realms = generated ? 1
      : 1 + this.db.prepare("SELECT COUNT(*) AS n FROM realms WHERE owner = ?").get(c.owner).n;
    let strain = 0;
    let band = 0;
    if (!generated && this.db.prepare("SELECT 1 FROM realms WHERE owner = ? LIMIT 1").get(c.owner)) {
      const p = this.service.weaving.stability(c.owner);
      strain = p.strain;
      band = p.band;
    }
    const [lo, hi] = successBand(snap.realm_level, c.origin);
    const kind = trace ? "trace" : generated ? "generated" : c.echo ? "echo" : "player";
    const reason = trace ? "trace" : c.predicted == null ? "fair"
      : c.predicted > hi ? "easier" : c.predicted < lo ? "harder" : "fair";
    const { fee } = this.service.stakes({ attacker: account, bundle: c.bundle, mode: "raid", trace_of: trace ? "t" : null },
                                        raider);
    const facts_ = realmFacts(this.service.store.get(c.bundle));
    return {
      bundle: c.bundle, kind, reason, fee,
      // §5.4's heist clock the lease would carry, in seconds (§12.5's
      // planner): across a universe, the shortest and the longest by the
      // realm landed on, and whether a raid would cross one (crossings.mjs).
      ...(([clock, longest]) => ({ clock, clock_longest: longest, across: longest > clockTicks() / TICKS_PER_SECOND }))(
        generated ? [clockTicks() / TICKS_PER_SECOND, clockTicks() / TICKS_PER_SECOND]
          : this.service.crossings.clocks(c.owner, c.bundle)),
      keeper_level: owner?.keeper_level ?? null, realms, renown: c.renown ?? null,
      // G58: the Keeper's name is §12.4's free fact, from the word lists.
      keeper_name: generated ? null : this.service.keeper.name(c.owner),
      loot: rough(snap.exposed), strain, band, faults: faults(strain, realms - 1),
      // §12.22: "up to N realms to the Heart", the most links any outer
      // realm's shortest route takes, and the realms the faults open from
      // (§5.4, links.mjs); the game's own island is one realm.
      ...(generated ? { depth: 0, fault_realms: [] } : (({ deepest, faults: at }) =>
        ({ depth: deepest, fault_realms: at }))(this.service.links.view(c.owner, strain))),
      ...(generated ? { success: [lo, hi] } : {}),
      realm: { realm: snap.realm, realm_level: snap.realm_level, vault_level: snap.vault_level,
               watch: facts.REALM_WATCH[snap.realm_level - 1], ...facts_ },
    };
  }

  /** §12.3's refresh: paid in Aether, and the list it buys leaves out the
   *  targets on show. */
  refresh(account) {
    const now = this.service.now();
    return transaction(this.db, () => {
      const cost = this.refreshCost(account, now);
      if (this.service.aether(account) < cost) throw new Refused(409, "not_enough_aether", { cost });
      const shown = this.view(account, now).targets.map((t) => t.bundle);
      this.service.book(account, "aether", -cost, "the Observatory's list refreshed (12.3)", now);
      this.db.prepare("INSERT INTO observatory_refreshes (owner, at, shown) VALUES (?, ?, ?)")
        .run(account, now, JSON.stringify(shown));
      return this.view(account, now);
    });
  }
}
