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
// A universe with no outer realm on it is the Heart alone, and a lease asked
// for one is the one-island lease it always was.

import { depths } from "./links.mjs";
import { REALMS, clockTicks } from "./service.mjs";

/** §5.3's links in the order the bundle numbers them. */
export const LINK_WIRE = ["stone_bridge", "rope_bridge", "chute", "rift"];
const MAGIC = "RBU1";

/** A universe's bundle: its realms in code order, each its code (0 the
 *  Heart, k outer realm k) and island's hash, then its links, each its kind
 *  and the realms' places in that order, a Chute running from the first. */
export function encodeUniverse(realms, links) {
  return Uint8Array.from([
    ...Buffer.from(MAGIC), realms.length,
    ...realms.flatMap((r) => [REALMS.indexOf(r.realm), ...Buffer.from(r.bundle, "hex")]),
    links.length, ...links.flatMap((l) => [LINK_WIRE.indexOf(l.kind), l.a, l.b]),
  ]);
}

/** The inverse, as far as the server reads it: realms {realm, bundle} and
 *  links {kind, a, b} by realm name; null for bytes that are not one. The
 *  simulation checks the rest. */
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
  return at === bytes.length ? { realms, links } : null;
}

export class Crossings {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }

  /** The universe a raid on `defender`'s Heart island `heart` crosses: its
   *  hash, stored with its bytes, or null when no outer realm of theirs has
   *  an island on it. */
  of(defender, heart) {
    const store = this.service.store;
    // Read as the owner's universe page reads it: links made for realms
    // opened before they were kept, and a Rift's upkeep paid or not.
    const now = this.service.now();
    this.service.links.ensure(defender, now);
    this.service.links.upkeep(defender, now);
    const outer = this.db.prepare("SELECT realm, bundle FROM islands WHERE owner = ? AND realm != 'heart'")
      .all(defender).filter((r) => REALMS.includes(r.realm) && store.get(r.bundle))
      .sort((x, y) => REALMS.indexOf(x.realm) - REALMS.indexOf(y.realm));
    if (!outer.length) return null;
    const realms = [{ realm: "heart", bundle: heart }, ...outer];
    const place = new Map(realms.map((r, i) => [r.realm, i]));
    const links = this.service.links.rows(defender)
      .filter((l) => l.open && place.has(l.a) && place.has(l.b))
      .map((l) => ({ kind: l.kind, a: place.get(l.a), b: place.get(l.b) }));
    return store.put(encodeUniverse(realms, links));
  }

  /** What the lease shows of its universe: its hash, each realm with its
   *  island, its links to the Heart and the clock a crew landing there
   *  plays on (null for the Heart, and for a realm with no route to it),
   *  and the links. `extra` is the era's ticks on every clock (§18.3). */
  view(digest, extra = 0) {
    const u = decodeUniverse(this.service.store.get(digest));
    if (!u) return null;
    const depth = depths(u.realms.map((r) => r.realm), u.links);
    return {
      digest,
      realms: u.realms.map(({ realm, bundle }) => ({
        realm, bundle, links: Number.isFinite(depth[realm]) ? depth[realm] : null,
        ticks: realm !== "heart" && Number.isFinite(depth[realm]) ? clockTicks(depth[realm]) + extra : null,
      })),
      links: u.links,
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
