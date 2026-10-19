// §13.3's curation, "the default creative act": "Swap a law, move a post,
// turn a post, pick a different generated layout, name it."
//
// A layout is the generator's (sim/src/island.rs `Island::curated`): drawn
// from a seed at the realm's level, with what the player has — the
// buildings where their universe placed them, the Vault at the level they
// built and the laws woven in that realm — and nothing the generator chose
// for them, since it never weaves for a player (G54). It is published with
// the generated origin, and keeps it, with its seed and its terrain's
// digest, while only curation's verbs change it: "A curated defence keeps
// the generated origin while only curation's verbs are used, and is
// authored once its terrain is edited; one outside its band saves with a
// warning and is judged against its origin's band (12.22)". Moving and
// turning a post are the island's own edits, republished whole with
// PUT /v1/islands; a swap is a weave (weaving.mjs `weave` with `swap`).
//
// Each realm is offered three layouts a page, from seeds that are the same
// for one player and realm on every server: the first eight bytes of
// SHA-256("curation:<account>:<realm>:<n>"). Any seed may be laid; the
// three are a menu, not a limit.
//
// The hold the server measures for an island's digest rides on the view
// (holds.mjs); §13.3's stealth-path count, shown at once for every edit, is
// G55's and not here.

import { createHash } from "node:crypto";

import { Refused } from "./refused.mjs";
import { HEART_LEVEL, REALMS } from "./service.mjs";
import { WORDS } from "./workshop.mjs";

/** Layouts offered a page. */
export const LAYOUTS = 3;
const U64 = /^\d{1,20}$/;

/** The seed of a player's `n`th offered layout in `realm`, as a decimal
 *  string: a u64 is past what a JSON number holds. */
export function layoutSeed(account, realm, n) {
  const h = createHash("sha256").update(`curation:${account}:${realm}:${n}`).digest();
  return h.readBigUInt64LE(0).toString();
}

export class Curation {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }
  get universe() { return this.service.universe; }

  /** The realm as its owner has it: its level, the Vault's, its placed
   *  buildings and the laws woven there and working. */
  realm(account, realm) {
    if (!REALMS.includes(realm)) throw new Refused(404, "no_such_realm");
    this.universe.ensure(account, this.service.now());
    const r = this.universe.realms(account).find((x) => x.realm === realm);
    if (!r) throw new Refused(404, "realm_not_open");
    const all = this.universe.buildings(account);
    const vault = all.find((b) => b.realm === "heart" && b.kind === "vault")?.level ?? 1;
    const buildings = all.filter((b) => b.realm === realm && b.x != null)
      .map((b) => ({ kind: b.kind, x: b.x, y: b.y }));
    const laws = (this.service.weaving.working(account)[realm] ?? []).map((l) => l.law);
    return { type: r.type, level: realm === "heart" ? HEART_LEVEL : r.level, vaultLevel: Math.max(1, vault),
             buildings, laws };
  }

  /** §23.2's curation screen for one realm: the island and its origin, the
   *  name, the layouts on `page`, and what a swap of each woven law would
   *  cost, priced as a weave in its place (§5.6, G54). */
  view(account, realm, page = 0) {
    if (!Number.isInteger(page) || page < 0) throw new Refused(400, "malformed_body");
    const r = this.realm(account, realm);
    const row = this.db.prepare(
      "SELECT bundle, origin, seed, name_adjective, name_noun FROM islands WHERE owner = ? AND realm = ?")
      .get(account, realm);
    return {
      realm, type: r.type, level: r.level, vaultLevel: r.vaultLevel, aether: this.service.aether(account),
      island: row?.bundle ?? null,
      origin: row ? (row.origin ?? "authored") : null,
      seed: row?.seed ?? null,
      name: row?.name_adjective == null ? null : { adjective: row.name_adjective, noun: row.name_noun },
      page,
      layouts: Array.from({ length: LAYOUTS }, (_, i) => layoutSeed(account, realm, page * LAYOUTS + i)),
      swaps: this.service.weaving.swaps(account, realm),
      // §13.3's hold: "measuring…" until the reference crew's raids land
      // (holds.mjs), never an estimate.
      hold: row ? this.service.holds.status(row.bundle) : null,
    };
  }

  /** "Pick a different generated layout": the generator's layout from
   *  `seed` laid on the realm and published, generated. */
  layout(account, realm, seed) {
    if (typeof seed !== "string" || !U64.test(seed) || BigInt(seed) >= 2n ** 64n) {
      throw new Refused(400, "malformed_body");
    }
    const r = this.realm(account, realm);
    const build = this.service.builds.current;
    const bytes = build.curated(seed, r.level, r.vaultLevel, r.buildings, r.laws);
    const out = this.service.publish(account, bytes, realm, { origin: "generated", seed, terrain: build.terrain(bytes) });
    return { ...out, ...this.view(account, realm) };
  }

  /** The origin a republished island takes: generated while its terrain
   *  is the curated layout's, with that layout's seed; authored once it is
   *  edited (§13.3). */
  origin(account, realm, bytes) {
    const row = this.db.prepare("SELECT seed, terrain FROM islands WHERE owner = ? AND realm = ?").get(account, realm);
    if (row?.terrain && this.service.builds.current.terrain(bytes) === row.terrain) {
      return { origin: "generated", seed: row.seed, terrain: row.terrain };
    }
    return { origin: "authored" };
  }

  /** "Name it": from the word lists, as every name in the game is (G58). */
  name(account, realm, { adjective, noun }) {
    if (!Number.isInteger(adjective) || !Number.isInteger(noun)
        || !WORDS.adjectives[adjective] || !WORDS.nouns[noun]) {
      throw new Refused(400, "name_not_from_the_word_lists");
    }
    this.realm(account, realm);
    const changed = this.db.prepare(
      "UPDATE islands SET name_adjective = ?, name_noun = ? WHERE owner = ? AND realm = ?")
      .run(adjective, noun, account, realm).changes;
    if (!changed) throw new Refused(409, "no_island");
    return this.view(account, realm);
  }
}
