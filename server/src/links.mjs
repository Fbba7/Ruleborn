// §5.3's links: how a universe's realms join, and what depends on it.
//
// §5.3: "The Heart has four link sockets and outer realms three. Every realm
// must connect to the Heart. A universe needs one link per outer realm and
// may have two extra, for loops and shortcuts." Each kind has its price and
// its limit (design_facts.LINK_KINDS): a Stone bridge is free, a Rope bridge
// 300 Starlight, a Chute 1,500 and one way, its owner setting the
// direction, at most two; a Rift 5,000, at most one, and "20 Aether an hour".
//
// Opening an outer realm brings its one link: a Stone bridge to the Heart
// while the Heart has a socket free, else to the first opened outer realm
// that has one (an assumption: §5.3 says a realm needs a link, not where it
// goes). A universe opened before links were kept gets them the same way,
// realm by realm in the order they opened, the first time it is read.
//
// From the links come each outer realm's depth — the links on its shortest
// route to the Heart, crossing a Chute only its own way — which sets §5.4's
// heist clock for a crew landing there and the Observatory card's "up to N
// realms to the Heart" (§12.22), and where §5.5's faults open: "the first
// opens from the outer realm whose shortest route to the Heart is longest,
// the next from the next longest, ties broken by the order the realms
// opened" (§5.4).
//
// The Rift's upkeep is charged by the hour from Aether whenever the universe
// is read or changed, for the whole hours since it was last paid. A Rift its
// owner cannot pay for stands closed, crossing nothing, until there is Aether
// for an hour again, and the hours it stood closed cost nothing. So no realm
// may depend on a Rift to reach the Heart (assumptions both: §5.3 gives the
// price, not what happens when it is not paid; G-register).

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";
import { REALMS } from "./service.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const HOUR = 60 * 60 * 1000;
export const KINDS = Object.keys(facts.LINK_KINDS);
const RIFT = "rift";
const sockets = (realm) => (realm === "heart" ? facts.LINK_SOCKETS.heart : facts.LINK_SOCKETS.outer);

/** Each realm's depth: the fewest links from it to the Heart over `links`
 *  ({kind, a, b, open}), a Chute crossed only from `a` to `b` and a closed
 *  link not at all; Infinity for a realm with no route. */
export function depths(realms, links) {
  const out = Object.fromEntries(realms.map((r) => [r, r === "heart" ? 0 : Infinity]));
  // Breadth first from the Heart, walking each link backwards.
  let frontier = ["heart"];
  while (frontier.length) {
    const next = [];
    for (const at of frontier) {
      for (const l of links) {
        if (l.open === false) continue;
        const from = l.b === at ? l.a : (l.a === at && !facts.LINK_KINDS[l.kind].one_way ? l.b : null);
        if (from && out[from] === Infinity) {
          out[from] = out[at] + 1;
          next.push(from);
        }
      }
    }
    frontier = next;
  }
  return out;
}

/** §5.4's faults: the outer realms they open from, `count` of them, deepest
 *  first, ties by the order the realms opened. */
export function faultRealms(depth, count) {
  return Object.keys(depth).filter((r) => r !== "heart")
    .sort((x, y) => (depth[y] - depth[x]) || (REALMS.indexOf(x) - REALMS.indexOf(y)))
    .slice(0, count);
}

export class Links {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }
  get universe() { return this.service.universe; }

  rows(account) {
    return this.db.prepare("SELECT n, kind, a, b, built_at, paid_to, open FROM links WHERE owner = ? ORDER BY n")
      .all(account).map((l) => ({ ...l, open: l.open !== 0 }));
  }

  /** Every outer realm with its one link, made in the order the realms
   *  opened for a universe that has none yet. Inside the caller's
   *  transaction. */
  ensure(account, now) {
    for (const r of this.universe.realms(account)) {
      if (r.realm !== "heart") this.join(account, r.realm, now);
    }
  }

  /** `realm`'s own link, if it has none: a Stone bridge to the Heart while
   *  it has a socket free, else to the first opened realm with one. */
  join(account, realm, now) {
    const rows = this.rows(account);
    if (rows.some((l) => l.a === realm || l.b === realm)) return;
    const used = (x) => rows.filter((l) => l.a === x || l.b === x).length;
    const to = this.universe.realms(account).map((r) => r.realm)
      .find((x) => x !== realm && used(x) < sockets(x) && (x === "heart" || rows.some((l) => l.a === x || l.b === x)));
    if (!to) throw new Refused(409, "no_free_socket");
    this.insert(account, "stone_bridge", realm, to, now);
  }

  /** A new link, numbered one past every number the player's links were
   *  given, removed ones too: a number is never given again, so a retried
   *  removal finds nothing (FX1-A-16). */
  insert(account, kind, a, b, now) {
    const n = Math.max(this.db.prepare("SELECT links_n FROM accounts WHERE id = ?").get(account)?.links_n ?? 0,
      this.db.prepare("SELECT MAX(n) AS n FROM links WHERE owner = ?").get(account).n ?? 0) + 1;
    this.db.prepare("UPDATE accounts SET links_n = ? WHERE id = ?").run(n, account);
    this.db.prepare("INSERT INTO links (owner, n, kind, a, b, built_at, paid_to, open) VALUES (?, ?, ?, ?, ?, ?, ?, 1)")
      .run(account, n, kind, a, b, now, now);
    return n;
  }

  /** The Rift's hours paid from Aether since it was last paid; closed when
   *  there is not enough for the next hour, open again when there is. */
  upkeep(account, now) {
    const perHour = facts.LINK_KINDS.rift.aether_an_hour;
    for (const l of this.rows(account).filter((x) => x.kind === RIFT)) {
      if (!l.open) {
        if (this.service.aether(account) < perHour) continue;
        this.db.prepare("UPDATE links SET open = 1, paid_to = ? WHERE owner = ? AND n = ?").run(now, account, l.n);
        continue;
      }
      const hours = Math.floor((now - l.paid_to) / HOUR);
      if (hours < 1) continue;
      const affordable = Math.min(hours, Math.floor(this.service.aether(account) / perHour));
      if (affordable > 0) this.service.book(account, "aether", -affordable * perHour, `the Rift's upkeep, ${affordable} h (5.3)`, now);
      if (affordable < hours) {
        this.db.prepare("UPDATE links SET open = 0, paid_to = ? WHERE owner = ? AND n = ?").run(now, account, l.n);
      } else {
        this.db.prepare("UPDATE links SET paid_to = ? WHERE owner = ? AND n = ?").run(l.paid_to + hours * HOUR, account, l.n);
      }
    }
  }

  /** What would refuse `links` as the universe's: a socket over its count,
   *  a kind over its limit, more links than one an outer realm and two, or
   *  an outer realm that cannot reach the Heart without a Rift. */
  refusal(account, links) {
    const realms = this.universe.realms(account).map((r) => r.realm);
    for (const r of realms) {
      if (links.filter((l) => l.a === r || l.b === r).length > sockets(r)) return "no_free_socket";
    }
    for (const kind of KINDS) {
      const limit = facts.LINK_KINDS[kind].limit;
      if (limit !== null && links.filter((l) => l.kind === kind).length > limit) return "link_limit";
    }
    if (links.length > realms.length - 1 + facts.LINKS_EXTRA) return "too_many_links";
    const sure = depths(realms, links.filter((l) => l.kind !== RIFT));
    if (realms.some((r) => sure[r] === Infinity)) return "realm_cut_off";
    return null;
  }

  /** A link built between two open realms: §5.3's price paid in Starlight.
   *  A Chute runs from `a` to `b`. */
  build(account, { a, b, kind }) {
    if (!KINDS.includes(kind)) throw new Refused(400, "no_such_link");
    const now = this.service.now();
    return this.change(account, now, (rows, realms) => {
      if (!realms.includes(a) || !realms.includes(b) || a === b) throw new Refused(404, "no_such_realm");
      if (rows.some((l) => (l.a === a && l.b === b) || (l.a === b && l.b === a))) throw new Refused(409, "already_linked");
      const next = [...rows, { kind, a, b, open: true }];
      const why = this.refusal(account, next);
      if (why) throw new Refused(409, why);
      const cost = facts.LINK_KINDS[kind].cost;
      if (cost > 0) this.universe.afford(account, { cost });
      const n = this.insert(account, kind, a, b, now);
      return cost > 0 ? this.universe.pay(account, cost, `a ${kind.replace("_", " ")}, link ${n} (5.3)`, now) : null;
    });
  }

  /** Link `n` rebuilt as `kind` at that kind's price — a Chute running
   *  from `from` — or the same kind answered as done. */
  rebuild(account, n, { kind, from = null }) {
    if (!KINDS.includes(kind)) throw new Refused(400, "no_such_link");
    const now = this.service.now();
    return this.change(account, now, (rows) => {
      const l = rows.find((x) => x.n === n);
      if (!l) throw new Refused(404, "no_such_link");
      const [a, b] = from === null || from === l.a ? [l.a, l.b] : from === l.b ? [l.b, l.a] : [null, null];
      if (!a) throw new Refused(400, "malformed_body");
      if (l.kind === kind && l.a === a) return null;
      const why = this.refusal(account, rows.map((x) => (x.n === n ? { ...x, kind, a, b } : x)));
      if (why) throw new Refused(409, why);
      const cost = l.kind === kind ? 0 : facts.LINK_KINDS[kind].cost;
      if (cost > 0) this.universe.afford(account, { cost });
      // The same kind turned round costs nothing, so it changes only the
      // direction: what is owed and a closed Rift carry over (SEC-35).
      if (l.kind === kind) this.db.prepare("UPDATE links SET a = ?, b = ? WHERE owner = ? AND n = ?").run(a, b, account, n);
      else this.db.prepare("UPDATE links SET kind = ?, a = ?, b = ?, paid_to = ?, open = 1 WHERE owner = ? AND n = ?")
        .run(kind, a, b, now, account, n);
      return cost > 0 ? this.universe.pay(account, cost, `a ${kind.replace("_", " ")}, link ${n} (5.3)`, now) : null;
    });
  }

  /** Link `n` taken down, if every realm still reaches the Heart. */
  remove(account, n) {
    const now = this.service.now();
    return this.change(account, now, (rows) => {
      if (!rows.some((x) => x.n === n)) return null;
      const why = this.refusal(account, rows.filter((x) => x.n !== n));
      if (why) throw new Refused(409, why);
      this.db.prepare("DELETE FROM links WHERE owner = ? AND n = ?").run(account, n);
      return null;
    });
  }

  /** A change to the links, in one transaction: what the producers made
   *  under the faults that held is paid first (home.mjs). */
  change(account, now, fn) {
    return transaction(this.db, () => {
      this.universe.ensure(account, now);
      this.ensure(account, now);
      this.upkeep(account, now);
      this.service.home?.settleAll(account, now);
      const keeper = fn(this.rows(account), this.universe.realms(account).map((r) => r.realm));
      return this.universe.done(account, keeper);
    });
  }

  /** The universe's links and what follows from them: each realm's depth
   *  and §5.4's clock for a crew landing there, the deepest, and the realms
   *  the faults open from at the universe's strain. */
  view(account, strain) {
    const realms = this.universe.realms(account).map((r) => r.realm);
    // A universe opened before links were kept is read with them made.
    if (realms.some((r) => r !== "heart" && !this.rows(account).some((l) => l.a === r || l.b === r))) {
      this.ensure(account, this.service.now());
    }
    const rows = this.rows(account);
    const depth = depths(realms, rows);
    const outer = realms.filter((r) => r !== "heart");
    let faults = 0;
    for (const [at, count] of facts.FAULTS_BY_STRAIN) if (strain * 100 >= at) faults = count;
    faults = Math.min(faults, outer.length);
    return {
      links: rows.map(({ n, kind, a, b, open }) => ({ n, kind, a, b, open })),
      depth,
      deepest: outer.length ? Math.max(...outer.map((r) => depth[r])) : 0,
      faults: faultRealms(depth, faults),
    };
  }
}
