// §12.22's generated targets: "the game's own", made by the simulation from
// a seed and offered when a raider's list runs thin — after echoes, before
// any filter is widened (D66, TD.16).
//
// One seeded account holds them, as it holds §13.1's designed islands: no
// new player to shield, no Renown to move, no universe to answer to. Each UTC
// day it publishes one island a realm level, from that day's seed, so every
// server makes the same five and a raider meets a new five each day; a
// realm's rating is kept across the days, so it learns how hard the
// generator's islands of that level are, starting from the generated band's
// prior ("55 to 70% at every realm level"). Yesterday's are no echoes: the
// game's own islands are nobody's to rob twice.

import { createHash } from "node:crypto";

/** The generator's account, seeded. */
export const GENERATOR = "the-game-generator";

/** Where each realm level's island stands: the Heart is realm level 3
 *  (G19), so the generator's level-3 island is its Heart. */
export const REALM_OF_LEVEL = { 1: "outer-1", 2: "outer-2", 3: "heart", 4: "outer-3", 5: "outer-4" };

/** A day's seed for a realm level: the first eight bytes of
 *  SHA-256("generated:<day>:<level>"), so it is the same on every server. */
export function seedFor(day, level) {
  const h = createHash("sha256").update(`generated:${day}:${level}`).digest();
  return h.readBigUInt64LE(0);
}

export class Generator {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }

  /** The generator's account, made once. */
  account() {
    this.db.prepare(
      `INSERT OR IGNORE INTO accounts (id, platform_identity, created_at, age_band, seeded)
       VALUES (?, 'game:generator', 0, '18+', 1)`).run(GENERATOR);
    return GENERATOR;
  }

  /** Today's five generated islands, published if they are not already. */
  stock(now = this.service.now()) {
    const owner = this.account();
    const day = Math.floor(now / 86_400_000);
    const out = {};
    for (const [level, realm] of Object.entries(REALM_OF_LEVEL)) {
      const bytes = this.service.builds.current.generate(seedFor(day, Number(level)), Number(level));
      const held = this.db.prepare("SELECT bundle FROM islands WHERE owner = ? AND realm = ?").get(owner, realm);
      // The same day's island is already up: publishing it again would only
      // widen its rating back to the prior's deviation.
      out[level] = held && this.service.store.get(held.bundle) && Buffer.from(this.service.store.get(held.bundle)).equals(Buffer.from(bytes))
        ? held.bundle
        : this.service.publish(owner, bytes, realm, { origin: "generated" }).bundle;
    }
    return out;
  }
}
