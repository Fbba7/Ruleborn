// The home economy's first part (§5.2, §9.5, §10.1, §10.2, §14.2): a
// universe's realms and buildings, bought with Starlight from the ledger.
//
// §5.2: "Every universe has one Heart and up to six outer realms. Outer realms
// open at Keeper levels 3, 6, 10, 15, 21 and 28, and the player picks each
// one's type from those not yet owned". §9.5 prices the opening and each
// realm level; §10.2 gives "Every level of every building" — its cost, what
// it needs (a Spire level, a Keeper level) and where it stands — which this
// reads from content/buildings.json, the document's own table extracted.
// §14.2 pays Keeper experience for "spending (1 for every 40 Starlight)".
//
// The server decides what a player may buy, and says why not, so the device
// draws the answer and never re-derives a rule. Every purchase names the
// state it leads to — the building's next level, the realm's — so a retry of
// one already made is answered as made and never charged twice (§24.12).
//
// What a universe holds is also what its islands may claim: an island
// published to a realm the player has not opened, at a realm level above the
// realm's, or with a Vault above the one built, is refused (service.publish).
// Staffing, production and the roster come in the home economy's later parts
// (G42).
//
// §10.1: "Buildings sit on the realm grid and block movement and sight. …
// Moving a building is free and instant, like terrain." Each building keeps
// the tile it was put on, and an island published to a realm carries the
// realm's placed buildings on those tiles and no others, so a raid meets the
// buildings the player built where the player put them.

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";
import { HEART_LEVEL, REALMS } from "./service.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));
const table = JSON.parse(readFileSync(new URL("../../content/buildings.json", import.meta.url), "utf8"));

/** A §10.2 "Needs" cell as the Spire and Keeper levels it names (0 if none). */
function needs(text) {
  const spire = /Spire (\d+)/.exec(text);
  const keeper = /Keeper level (\d+)/.exec(text);
  return { spire: spire ? Number(spire[1]) : 0, keeper: keeper ? Number(keeper[1]) : 0 };
}

/** §10.2's placement line: where a kind may stand. "One per law slot" stands
 *  in every realm, as many as the realm has slots. */
function where(placement) {
  if (placement.startsWith("Heart")) return "heart";
  if (placement.startsWith("Outer realms")) return "outer";
  return "every";
}

/** Every kind of building, by §10.2's id. */
export const KINDS = Object.fromEntries(table.map((b) => [b.id, {
  id: b.id,
  name: b.name,
  where: where(b.placement),
  levels: b.levels.map((l) => ({ cost: l.cost_starlight, needs: needs(l.needs) })),
}]));

export const SPIRE = "keeper_s_spire";

/** A ledger reason for Starlight spent on the universe; §14.2's experience
 *  counts every row that starts so, and nothing else. */
const SPENT = "spent on ";

/** How many of a kind a realm at `level` may hold: §5.2's ward limit and
 *  guard posts, a law pylon a law slot, one of each producer (§5.8), and one
 *  of everything else. The Heart counts as realm level 3 (G19). */
export function allowed(kind, level) {
  if (kind === "ward") return facts.WARD_LIMITS[level - 1];
  if (kind === "guardian_post") return facts.GUARD_POSTS[level - 1];
  if (kind === "law_pylon") return facts.LAW_SLOTS[level - 1];
  return 1;
}

/** Whether `kind` may stand in `realm` at all. */
const placeable = (kind, realm) => KINDS[kind].where === "every"
  || (KINDS[kind].where === "heart") === (realm === "heart");

/** §9.5's price and §5.2's Spire for a realm to reach `level` (1 = opening). */
const realmPrice = (level) => ({
  cost: level === 1 ? facts.REALM_OPEN_COST : facts.REALM_LEVEL_COSTS[level - 2],
  spire: facts.REALM_LEVEL_SPIRE[level - 1],
});

const integer = (v, lo, hi) => Number.isInteger(v) && v >= lo && v <= hi;

/** For the load run and the tests only, and reached by no route: `owner`'s
 *  universe raised, unpaid, until an island in `realm` at `realmLevel` with
 *  a Vault at `vault` is one it may publish. */
export function raiseTo(db, owner, realm, realmLevel, vault, now = 0) {
  const universe = new Universe({ db });
  universe.ensure(owner, now);
  const outer = REALMS.indexOf(realm);
  for (let i = 1; i <= outer; i++) {
    db.prepare(`INSERT INTO realms (owner, realm, type, level, opened_at) VALUES (?, ?, ?, ?, ?)
                ON CONFLICT (owner, realm) DO UPDATE SET level = MAX(level, excluded.level)`)
      .run(owner, REALMS[i], facts.REALM_TYPES[i - 1], i === outer ? realmLevel : 1, now);
  }
  db.prepare("UPDATE buildings SET level = MAX(level, ?) WHERE owner = ? AND realm = 'heart' AND kind = 'vault'")
    .run(vault, owner);
}

export class Universe {
  constructor(service) {
    this.service = service;
    this.db = service.db;
  }

  /** The start (F56), written the first time a universe changes: until then
   *  a universe with no rows is read as holding it. */
  ensure(account, now) {
    const insert = this.db.prepare(
      `INSERT OR IGNORE INTO buildings (owner, realm, kind, n, level, changed_at)
       VALUES (?, 'heart', ?, 1, 1, ?)`);
    if (this.db.prepare("SELECT 1 FROM buildings WHERE owner = ? LIMIT 1").get(account)) return;
    for (const kind of facts.STARTING_HEART) insert.run(account, kind, now);
  }

  /** The realms, the Heart first: {realm, type, level}. */
  realms(account) {
    return [{ realm: "heart", type: "Heart", level: HEART_LEVEL },
            ...this.db.prepare("SELECT realm, type, level FROM realms WHERE owner = ? ORDER BY realm")
              .all(account)];
  }

  /** Every building: {realm, kind, n, level, changed_at, x, y}, x and y
   *  null until it is placed. */
  buildings(account) {
    const rows = this.db.prepare(
      "SELECT realm, kind, n, level, changed_at, x, y FROM buildings WHERE owner = ? ORDER BY realm, kind, n").all(account);
    return rows.length ? rows : facts.STARTING_HEART.map((kind) => ({ realm: "heart", kind, n: 1, level: 1 }));
  }

  /** The Spire's level, which most of §10.2's "Needs" read. */
  spire(account) {
    return this.buildings(account).find((b) => b.kind === SPIRE)?.level ?? 1;
  }

  /** Starlight spent on the universe so far, for §14.2's experience. */
  spent(account) {
    return -Number(this.db.prepare(
      `SELECT COALESCE(SUM(starlight), 0) AS n FROM ledger
        WHERE account = ? AND reason LIKE '${SPENT}%'`).get(account).n);
  }

  /** Why a price cannot be paid now, or null: the first of the Keeper level
   *  it needs, the Spire level, then the Starlight. */
  blocked(price, { keeper, spire, starlight }) {
    if (price.keeper && keeper < price.keeper) return "keeper_level";
    if (price.spire && spire < price.spire) return "spire_level";
    if (starlight < price.cost) return "starlight";
    return null;
  }

  /** The universe as the device draws it: each realm with its buildings,
   *  what each one's next level costs and needs and whether it can be bought
   *  now, the kinds there is room to build, and the next realm to open. */
  view(account) {
    const me = {
      keeper: this.db.prepare("SELECT keeper_level FROM accounts WHERE id = ?").get(account).keeper_level,
      spire: this.spire(account),
      starlight: this.service.balance(account).starlight,
    };
    const all = this.buildings(account);
    const offer = (price) => ({ cost: price.cost, needs: { keeper: price.keeper ?? 0, spire: price.spire ?? 0 },
                                blocked: this.blocked(price, me) });
    const realms = this.realms(account).map((r) => {
      const here = all.filter((b) => b.realm === r.realm);
      const buildings = here.map((b) => {
        const levels = KINDS[b.kind].levels;
        const next = levels[b.level];
        return { kind: b.kind, name: KINDS[b.kind].name, n: b.n, level: b.level, top: levels.length,
                 next: next ? offer({ cost: next.cost, ...next.needs }) : null,
                 at: b.x == null ? null : { x: b.x, y: b.y } };
      });
      const room = Object.values(KINDS)
        .filter((k) => placeable(k.id, r.realm) && here.filter((b) => b.kind === k.id).length < allowed(k.id, r.level))
        .map((k) => ({ kind: k.id, name: k.name,
                       n: firstFree(here.filter((b) => b.kind === k.id).map((b) => b.n)),
                       ...offer({ cost: k.levels[0].cost, ...k.levels[0].needs }) }));
      const raise = r.realm !== "heart" && r.level < facts.REALM_LEVEL_SPIRE.length
        ? offer(realmPrice(r.level + 1)) : null;
      // The realm's published island, by its bundle: what the realm view
      // reads its grid, terrain, wards and guard posts from (§23.2).
      const island = this.db.prepare("SELECT bundle FROM islands WHERE owner = ? AND realm = ?")
        .get(account, r.realm)?.bundle ?? null;
      return { ...r, buildings, room, raise, island };
    });
    const owned = realms.length - 1;
    const open = owned < facts.REALM_TYPES.length ? {
      realm: REALMS[owned + 1],
      types: facts.REALM_TYPES.filter((t) => !realms.some((r) => r.type === t)),
      ...offer({ ...realmPrice(1), keeper: facts.REALM_KEEPER_LEVELS[owned] }),
    } : null;
    // §5.3's links, each realm's depth and where the faults open (links.mjs).
    const links = this.service.links.view(account, this.service.weaving.stability(account).strain);
    return { ...me, realms, open, ...links };
  }

  /** The universe as the device reads it: its links made for a universe
   *  opened before they were kept, and a Rift's upkeep paid, first. */
  show(account) {
    const now = this.service.now();
    return transaction(this.db, () => {
      this.ensure(account, now);
      this.service.links.ensure(account, now);
      this.service.links.upkeep(account, now);
      return this.view(account);
    });
  }

  /** Starlight paid for `what`, and §14.2's experience for it: 1 for every
   *  40 spent, counted over everything spent, so no fraction is lost between
   *  purchases. Inside the purchase's transaction. */
  pay(account, cost, what, now) {
    const before = this.spent(account);
    this.service.book(account, "starlight", -cost, `${SPENT}${what}`, now);
    const xp = Math.floor((before + cost) / facts.STARLIGHT_PER_XP) - Math.floor(before / facts.STARLIGHT_PER_XP);
    return xp > 0 ? this.service.keeper.award(account, xp) : null;
  }

  /** A price checked against the player: refused with the first reason. */
  afford(account, price) {
    const why = this.blocked(price, {
      keeper: this.db.prepare("SELECT keeper_level FROM accounts WHERE id = ?").get(account).keeper_level,
      spire: this.spire(account),
      starlight: this.service.balance(account).starlight,
    });
    if (why === "starlight") throw new Refused(409, "not_enough_starlight", { cost: price.cost });
    if (why) throw new Refused(409, `needs_${why}`, { needs: price[why === "keeper_level" ? "keeper" : "spire"] });
  }

  /** §5.2: the next outer realm opened, of a `type` not yet owned. */
  open(account, type) {
    if (!facts.REALM_TYPES.includes(type)) throw new Refused(400, "no_such_realm_type");
    const now = this.service.now();
    return transaction(this.db, () => {
      const realms = this.realms(account);
      if (realms.some((r) => r.type === type)) return this.done(account, null, true);
      const owned = realms.length - 1;
      if (owned >= facts.REALM_TYPES.length) throw new Refused(409, "every_realm_open");
      this.afford(account, { ...realmPrice(1), keeper: facts.REALM_KEEPER_LEVELS[owned] });
      this.ensure(account, now);
      const realm = REALMS[owned + 1];
      // A new outer realm can move where the faults open (§5.4): what the
      // producers made before is paid under the faults that held.
      this.service.links.ensure(account, now);
      this.service.home?.settleAll(account, now);
      this.db.prepare("INSERT INTO realms (owner, realm, type, level, opened_at) VALUES (?, ?, ?, 1, ?)")
        .run(account, realm, type, now);
      // §5.3: "A universe needs one link per outer realm".
      this.service.links.join(account, realm, now);
      return this.done(account, this.pay(account, facts.REALM_OPEN_COST, `opening ${realm} (9.5)`, now));
    });
  }

  /** §5.2: an outer realm raised to level `to`, the one after its own. */
  raise(account, realm, to) {
    const now = this.service.now();
    return transaction(this.db, () => {
      const r = this.realms(account).find((x) => x.realm === realm);
      if (!r || realm === "heart") throw new Refused(404, "no_such_realm");
      if (!integer(to, 2, facts.REALM_LEVEL_SPIRE.length)) throw new Refused(400, "malformed_body");
      if (r.level >= to) return this.done(account, null, true);
      if (to !== r.level + 1) throw new Refused(409, "not_the_next_level");
      const price = realmPrice(to);
      this.afford(account, price);
      this.ensure(account, now);
      this.db.prepare("UPDATE realms SET level = ? WHERE owner = ? AND realm = ?").run(to, account, realm);
      return this.done(account, this.pay(account, price.cost, `${realm} to level ${to} (9.5)`, now));
    });
  }

  /** §10.2: building `n` of `kind` in `realm` taken to level `to`: built,
   *  at 1, or raised a level. */
  build(account, { realm, kind, n, to }) {
    if (typeof kind !== "string" || !Object.hasOwn(KINDS, kind)) throw new Refused(400, "no_such_building");
    const levels = KINDS[kind].levels;
    if (!integer(to, 1, levels.length) || !integer(n, 1, 8)) throw new Refused(400, "malformed_body");
    const now = this.service.now();
    return transaction(this.db, () => {
      const r = this.realms(account).find((x) => x.realm === realm);
      if (!r) throw new Refused(404, "no_such_realm");
      const have = this.buildings(account).find((b) => b.realm === realm && b.kind === kind && b.n === n);
      const level = have?.level ?? 0;
      if (level >= to) return this.done(account, null, true);
      if (to !== level + 1) throw new Refused(409, "not_the_next_level");
      if (!have) {
        if (!placeable(kind, realm)) throw new Refused(409, "not_in_this_realm");
        if (n > allowed(kind, r.level)) throw new Refused(409, "no_room");
      }
      const price = { cost: levels[to - 1].cost, ...levels[to - 1].needs };
      this.afford(account, price);
      this.ensure(account, now);
      // What a producer made at the level it had is paid at that level
      // before it rises, and every producer before the Spire or an Anchor
      // Stone moves the universe's stability band (home.mjs).
      this.service.home?.settleAll(account, now);
      this.db.prepare(
        `INSERT INTO buildings (owner, realm, kind, n, level, changed_at) VALUES (?, ?, ?, ?, ?, ?)
         ON CONFLICT (owner, realm, kind, n) DO UPDATE SET level = excluded.level, changed_at = excluded.changed_at`)
        .run(account, realm, kind, n, to, now);
      return this.done(account, this.pay(account, price.cost, `${KINDS[kind].name} ${n} in ${realm} to level ${to} (10.2)`, now));
    });
  }

  /** §10.1: building `n` of `kind` in `realm` put with its footprint's
   *  north-west tile on (x, y), free and at once. The footprint must lie on
   *  the realm's grid and on no other building's; whether it stands on
   *  ground the island leaves bare is the island's to say when published. */
  place(account, { realm, kind, n, x, y }) {
    if (typeof kind !== "string" || !Object.hasOwn(KINDS, kind)) throw new Refused(400, "no_such_building");
    if (!integer(n, 1, 8) || !integer(x, 0, 255) || !integer(y, 0, 255)) throw new Refused(400, "malformed_body");
    const sizes = this.service.builds.current.footprints;
    if (!Object.hasOwn(sizes, kind)) throw new Refused(409, "not_on_the_grid");
    const now = this.service.now();
    return transaction(this.db, () => {
      const r = this.realms(account).find((v) => v.realm === realm);
      if (!r) throw new Refused(404, "no_such_realm");
      this.ensure(account, now);
      const here = this.buildings(account).filter((b) => b.realm === realm);
      if (!here.some((b) => b.kind === kind && b.n === n)) throw new Refused(404, "not_built");
      // §5.2's grid: 9 tiles and one a realm level; the Heart counts as 3.
      const side = 9 + (realm === "heart" ? HEART_LEVEL : r.level);
      const size = sizes[kind];
      if (x + size > side || y + size > side) throw new Refused(409, "off_the_grid");
      const overlaps = (b) => b.x != null && !(b.kind === kind && b.n === n)
        && x < b.x + sizes[b.kind] && b.x < x + size && y < b.y + sizes[b.kind] && b.y < y + size;
      if (here.some(overlaps)) throw new Refused(409, "tile_taken");
      this.db.prepare("UPDATE buildings SET x = ?, y = ? WHERE owner = ? AND realm = ? AND kind = ? AND n = ?")
        .run(x, y, account, realm, kind, n);
      return { universe: this.view(account) };
    });
  }

  /** What a purchase answers: the universe after it, and the Keeper
   *  experience it earned — none for one already made. */
  done(account, keeper, repeated = false) {
    return { universe: this.view(account), keeper, ...(repeated ? { repeated: true } : {}) };
  }

  /** Why an island may not stand for `owner` in `realm`: the realm not
   *  opened, its realm level above the realm's, its Vault above the one
   *  built, or its `buildings` ([{kind, x, y}]) not the realm's placed ones
   *  on their tiles. The game's own seeded islands answer to no universe
   *  (§13.1). */
  problems(owner, realm, realmLevel, vaultLevel, buildings = []) {
    if (this.db.prepare("SELECT seeded FROM accounts WHERE id = ?").get(owner)?.seeded) return [];
    const out = [];
    const r = this.realms(owner).find((x) => x.realm === realm);
    if (!r) out.push("realm_not_open");
    else if (realm !== "heart" && realmLevel > r.level) out.push("realm_level_not_built");
    const vault = this.buildings(owner).find((b) => b.realm === "heart" && b.kind === "vault")?.level ?? 0;
    if (vaultLevel > vault) out.push("vault_level_not_built");
    const at = (b) => `${b.kind} ${b.x} ${b.y}`;
    const placed = this.buildings(owner).filter((b) => b.realm === realm && b.x != null).map(at).sort();
    if (placed.join() !== buildings.map(at).sort().join()) out.push("buildings_not_as_placed");
    return out;
  }
}

/** The lowest number from 1 not already taken. */
function firstFree(taken) {
  let n = 1;
  while (taken.includes(n)) n++;
  return n;
}
