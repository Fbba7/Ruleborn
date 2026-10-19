// §5.4's heist across a universe (D71, T3.3).
//
// §5.4: "The crew lands on any edge tile of any outer realm the raider
// chooses. The Heart is ringed by strong winds, so skiffs can't land there."
// A raid leased with `universe` is played across the defender's realms: the
// Heart leased, and each outer realm with an island on it, joined by the
// defender's open links between them (links.mjs). A realm opened with no
// island on it is not in the universe, nor are the links through it; a
// closed Rift crosses nothing. The universe travels as its own bundle, `RBU1`
// (sim/src/universe.rs), stored by its hash beside the islands it names, so a
// device fetches it as it fetches an island and the lease names it.
//
// The clock is §5.4's for the realm the crew lands on: "150 seconds plus 15
// seconds for each link on the shortest route from the landing realm to the
// Heart, up to 240 seconds", and Quiet Week's 30 more. The lease lists each
// realm's; the replay's header names one, and the simulation says which realm
// the crew landed on, so the server holds the two to each other.
//
// An overloaded universe (§5.5) carries what its strain does to a heist as
// the server reads it at the lease: its faults, each an entry from the outer
// realm it opens from straight to the Heart (§5.4: "or a fault if the target
// is overloaded"), on that realm's clock, and its laws' flicker, at Cracking
// and at Breaking twice as often (G88).
//
// A universe with no outer realm on it is the Heart alone, and a lease asked
// for one is the one-island lease it always was.

import { depths } from "./links.mjs";
import { REALMS, TICKS_PER_SECOND, clockTicks } from "./service.mjs";

/** §5.3's links in the order the bundle numbers them. */
export const LINK_WIRE = ["stone_bridge", "rope_bridge", "chute", "rift"];
const MAGIC = "RBU1";

/** §5.5's flicker by the strain band: Cracking's, and Breaking's twice as
 *  often; none below. */
export const flickerOf = (band) => (band >= 6 ? 2 : band >= 5 ? 1 : 0);

/** A universe's bundle: its realms in code order, each its code (0 the
 *  Heart, k outer realm k) and island's hash, then its links, each its kind
 *  and the realms' places in that order, a Chute running from the first;
 *  then its flicker and the places of the realms its faults open from,
 *  rising. */
export function encodeUniverse(realms, links, { flicker = 0, faults = [] } = {}) {
  return Uint8Array.from([
    ...Buffer.from(MAGIC), realms.length,
    ...realms.flatMap((r) => [REALMS.indexOf(r.realm), ...Buffer.from(r.bundle, "hex")]),
    links.length, ...links.flatMap((l) => [LINK_WIRE.indexOf(l.kind), l.a, l.b]),
    flicker, faults.length, ...[...faults].sort((x, y) => x - y),
  ]);
}

/** The inverse, as far as the server reads it: realms {realm, bundle},
 *  links {kind, a, b} by realm name, the flicker and the realms the faults
 *  open from; null for bytes that are not one. The simulation checks the
 *  rest. */
export function decodeUniverse(bytes) {
  if (!bytes || bytes.length < 6 || Buffer.from(bytes.subarray(0, 4)).toString() !== MAGIC) return null;
  const n = bytes[4];
  const realms = [];
  let at = 5;
  for (let i = 0; i < n; i++, at += 33) {
    realms.push({ realm: REALMS[bytes[at]], bundle: Buffer.from(bytes.subarray(at + 1, at + 33)).toString("hex") });
  }
  const links = [];
  for (let i = 0, m = bytes[at++]; i < m; i++, at += 3) {
    links.push({ kind: LINK_WIRE[bytes[at]], a: realms[bytes[at + 1]]?.realm, b: realms[bytes[at + 2]]?.realm });
  }
  const flicker = bytes[at++];
  const f = bytes[at++] ?? 0;
  const faults = Array.from(bytes.subarray(at, at + f), (p) => realms[p]?.realm);
  return at + f === bytes.length ? { realms, links, flicker, faults } : null;
}

export class Crossings {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }

  /** The universe a raid on `defender`'s island `heart` crosses: its hash,
   *  stored with its bytes; null when that island is not their Heart's now —
   *  an outer realm's island or a past one is raided alone — or no outer
   *  realm of theirs with an island on it reaches the Heart by the links
   *  between realms with islands, so there is nowhere to land. */
  of(defender, heart) {
    // Read as the owner's universe page reads it: links made for realms
    // opened before they were kept, and a Rift's upkeep paid or not.
    const now = this.service.now();
    if (!this.plan(defender, heart)) return null;
    this.service.links.ensure(defender, now);
    this.service.links.upkeep(defender, now);
    const plan = this.plan(defender, heart);
    if (!plan) return null;
    const { realms, place, links, depth } = plan;
    const reaches = (r) => r !== "heart" && Number.isFinite(depth[r]);
    // §5.5 at the lease: the strain's band, and the faults open from the
    // realms with islands on them that a crew can land on (links.mjs, as the
    // Observatory card says).
    const { strain, band } = this.service.weaving.stability(defender);
    const faults = this.service.links.view(defender, strain).faults.filter(reaches).map((r) => place.get(r));
    return this.service.store.put(encodeUniverse(realms, links, { flicker: flickerOf(band), faults }));
  }

  /** The universe `of` would make, read and nothing changed: its realms with
   *  islands, their places, its open links between them and each realm's
   *  depth; null when `heart` is not the defender's Heart now or no outer
   *  realm with an island reaches it. */
  plan(defender, heart) {
    const store = this.service.store;
    const current = this.db.prepare("SELECT 1 FROM islands WHERE owner = ? AND realm = 'heart' AND bundle = ?")
      .get(defender, heart);
    if (!current) return null;
    const outer = this.db.prepare("SELECT realm, bundle FROM islands WHERE owner = ? AND realm != 'heart'")
      .all(defender).filter((r) => REALMS.includes(r.realm) && store.get(r.bundle))
      .sort((x, y) => REALMS.indexOf(x.realm) - REALMS.indexOf(y.realm));
    const realms = [{ realm: "heart", bundle: heart }, ...outer];
    const place = new Map(realms.map((r, i) => [r.realm, i]));
    const rows = this.service.links.rows(defender).filter((l) => l.open && place.has(l.a) && place.has(l.b));
    const links = rows.map((l) => ({ kind: l.kind, a: place.get(l.a), b: place.get(l.b) }));
    const depth = depths(realms.map((r) => r.realm), rows);
    if (!outer.some((r) => Number.isFinite(depth[r.realm]))) return null;
    return { realms, place, links, depth };
  }

  /** The clocks a raid across `defender`'s universe from `heart` may play
   *  on, in seconds, shortest and longest by the realm landed on (§5.4); the
   *  Heart's alone with no universe. The era's extra is the lease's. */
  clocks(defender, heart) {
    const plan = this.plan(defender, heart);
    const reach = plan ? Object.entries(plan.depth).filter(([r, d]) => r !== "heart" && Number.isFinite(d))
      .map(([, d]) => d) : [0];
    return [Math.min(...reach), Math.max(...reach)].map((d) => clockTicks(d) / TICKS_PER_SECOND);
  }

  /** What the lease shows of its universe: its hash, each realm with its
   *  island, its links to the Heart, the clock a crew landing there plays
   *  on (null for the Heart, and for a realm with no route to it) and
   *  whether a fault opens from it, the links, and the flicker. `extra` is
   *  the era's ticks on every clock (§18.3). */
  view(digest, extra = 0) {
    const u = decodeUniverse(this.service.store.get(digest));
    if (!u) return null;
    const depth = depths(u.realms.map((r) => r.realm), u.links);
    return {
      digest,
      realms: u.realms.map(({ realm, bundle }) => ({
        realm, bundle, links: Number.isFinite(depth[realm]) ? depth[realm] : null,
        ticks: realm !== "heart" && Number.isFinite(depth[realm]) ? clockTicks(depth[realm]) + extra : null,
        fault: u.faults.includes(realm),
      })),
      links: u.links,
      flicker: u.flicker,
    };
  }

  /** The universe's bytes and its islands' in its order, for the
   *  simulation; null when one is gone from storage. */
  bundles(digest) {
    const store = this.service.store;
    const bytes = store.get(digest);
    const u = decodeUniverse(bytes);
    if (!u) return null;
    const islands = u.realms.map((r) => store.get(r.bundle));
    return islands.every(Boolean) ? { bytes, islands, realms: u.realms.map((r) => r.realm) } : null;
  }
}

/** The era's extra ticks on a lease's clocks: its own ticks are the Heart's
 *  clock and that extra (service.issue). */
export function eraExtra(lease) {
  return lease.ticks - clockTicks(0);
}
