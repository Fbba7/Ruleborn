// §23.2's Profile and stats (TD.24): "Renown and league over time, never the
// internal rating (12.15); heists by each outcome's own name (12.9); defences
// held (Foiled) and leaked (Clean, Loud and Partial, Partial counted apart;
// 12.9); the designs' ten records, each computed from the heist rows and
// 13.2's facts …; the battle log with replays; collection and 18.5's badges.
// Private, with no sharing, for 13 to 15 (20.2)."
//
// Every number is counted from the heist rows, the Codex and the Lab. Of the
// ten records, seven have a fact on the server: the fastest escape and the
// longest defence held (§13.2's held, written at settlement), the biggest
// haul, the fewest crew caught in a heist that got out, and from each
// heist's event-log report (TD.39) the fewest alarms — the realm alarm's
// highest level — and the most guards slept past in a heist that got out,
// and the edge raiders most often land on. Most realms in one raid waits on
// universes of several realms (T3.3); the favourite law and minutes played
// a day have no fact the server keeps (G57), and say so. The collection is
// the album's forms brought home and the cosmetics owned.
//
// §18.5's nine badges pay nothing; each is graded at its mark, gold at the
// mark, silver at half of it and bronze at a tenth, rounded up, while First
// heist and Paradox, whose mark is 1, have one grade. A Vault is opened when
// the crew loaded from it, banked or carried. Paradoxes wait for the paradox
// laws, so that count is 0. Titles come from mastery only: one at a third of
// a school's steps and one at all of them (§18.5).
//
// §20.2: a 13-to-15 profile is private, with no sharing, and is never served
// to another account; a 16-to-17 one is private by default; an adult's is
// the player's choice, private until they open it.

import { readFileSync } from "node:fs";

import { mastery } from "./codex.mjs";
import { FORMS } from "./home.mjs";
import { Refused } from "./refused.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));

/** The battle log's length: the latest heists, each with its replay while it
 *  is kept (§24.3). The document gives no number; this is the screen's. */
const LOG_ROWS = 20;

/** §18.5's nine badges, in its order, each with what it counts. */
export const BADGES = ["first_heist", "ghost", "vault_breaker", "iron_wall", "law_hunter", "resonant", "hoarder",
                       "friendly", "paradox"];

/** The grade `count` earns against `mark`: gold at the mark, silver at half
 *  of it and bronze at a tenth, rounded up; a mark of 1 has one grade. */
export function grade(count, mark) {
  if (count >= mark) return "gold";
  if (mark === 1) return null;
  if (count >= Math.ceil(mark / 2)) return "silver";
  if (count >= Math.ceil(mark / 10)) return "bronze";
  return null;
}

/** The designs' ten records, in §23.2's order. */
export const RECORDS = ["fastest_escape", "fewest_alarms", "most_guards_slept_past", "fewest_caught",
                        "most_realms", "biggest_haul", "longest_defence", "favourite_edge", "favourite_law",
                        "minutes_a_day"];

/** The side of the island a landing tile is on (§5.4), a corner counted
 *  north or south; null for none. */
export function edgeOf(landing, side) {
  if (!landing) return null;
  if (landing.y === 0) return "north";
  if (landing.y === side - 1) return "south";
  if (landing.x === 0) return "west";
  return landing.x === side - 1 ? "east" : null;
}

/** The commonest of `xs`, the first met on a tie; null for none. */
function favourite(xs) {
  const n = new Map();
  for (const x of xs) n.set(x, (n.get(x) ?? 0) + 1);
  let best = null;
  for (const [x, c] of n) if (best === null || c > n.get(best)) best = x;
  return best;
}

export class Profile {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }

  /** The player's own heists, validated, newest first, with their outcomes. */
  heists(account) {
    return this.db.prepare(
      `SELECT h.token, h.bundle, h.submitted_at, h.outcome, h.replay_gone, l.mode
         FROM heists h JOIN leases l ON l.token = h.token
        WHERE h.attacker = ? AND h.validated = 1 ORDER BY h.submitted_at DESC, h.token`).all(account)
      .map((r) => ({ ...r, o: JSON.parse(r.outcome) }));
  }

  /** The raids on the player, every season, each with its island's side. */
  raids(account) {
    return this.db.prepare(
      `SELECT h.outcome, s.realm_level FROM heists h JOIN leases l ON l.token = h.token
         JOIN snapshots s ON s.bundle = h.bundle
        WHERE l.defender = ? AND h.validated = 1 AND l.mode = 'raid' AND l.echo = 0`).all(account)
      .map((r) => ({ ...JSON.parse(r.outcome), side: 9 + r.realm_level }));
  }

  /** The profile: the player's whole record, and, for themselves, the battle
   *  log and the visibility switch. */
  view(account, { own = true } = {}) {
    const a = this.db.prepare("SELECT keeper_level, age_band, profile_public FROM accounts WHERE id = ?").get(account);
    const mine = this.heists(account);
    const raids = mine.filter((h) => h.mode === "raid");
    const on = this.raids(account);
    const gradeOf = (o) => o.verdict?.grade ?? "foiled";
    const count = (rows, g) => rows.filter((o) => gradeOf(o) === g).length;
    const out = (o) => gradeOf(o) !== "foiled";
    const heldMs = (o) => (Number.isInteger(o.heldMs) ? o.heldMs : null);
    const known = (xs) => xs.filter((x) => x != null);
    const min = (xs) => (known(xs).length ? Math.min(...known(xs)) : null);
    const max = (xs) => (known(xs).length ? Math.max(...known(xs)) : null);
    const escaped = raids.map((h) => h.o).filter(out);
    const record = {
      fastest_escape: min(escaped.map(heldMs)),
      fewest_caught: min(escaped.map((o) => o.verdict?.caught ?? null)),
      biggest_haul: max(raids.map((h) => h.o.haul?.total ?? null)),
      longest_defence: max(on.filter((o) => !out(o)).map(heldMs)),
      fewest_alarms: min(escaped.map((o) => o.report?.alarm ?? null)),
      most_guards_slept_past: max(escaped.map((o) => o.report?.slept ?? null)),
      // A raid across a universe landed on an outer realm, not this island:
      // the Heart's report says where the crew came into it (crossings.mjs).
      favourite_edge: favourite(on.filter((o) => !o.crossing)
        .map((o) => edgeOf(o.report?.landing, o.side)).filter(Boolean)),
      // The realms one raid went through: the Heart alone is one (5.4).
      most_realms: max(raids.map((h) => h.o.crossing?.realms.length ?? 1)),
    };
    const seasons = this.service.seasons;
    const now = this.service.now();
    const lab = this.service.lab.names(account);
    // The Codex and the roster as they start, written the first time they
    // are asked for.
    this.service.codex.ensure(account, now);
    this.service.home.ensure(account, now);
    const codex = this.db.prepare("SELECT law, tier, woven_at, crossed_at FROM codex WHERE owner = ?").all(account);
    const counts = {
      first_heist: mine.length,
      ghost: count(mine.map((h) => h.o), "clean"),
      vault_breaker: mine.filter((h) => (h.o.verdict?.banked ?? 0) > 0 || (h.o.verdict?.left ?? 0) > 0).length,
      iron_wall: count(on, "foiled"),
      law_hunter: codex.length,
      resonant: lab.resonances.size,
      hoarder: raids.reduce((n, h) => n + (h.o.haul?.starlight ?? 0), 0),
      friendly: mine.filter((h) => h.mode === "friendly").length,
      paradox: 0,
    };
    const titles = mastery(Object.fromEntries(codex.map((r) => [r.law, r]))).map((m) => ({
      school: m.school, steps: m.steps, total: m.total,
      titles: (m.steps >= m.marks.title ? 1 : 0) + (m.steps >= m.marks.last_title ? 1 : 0),
    })).filter((t) => t.titles > 0);
    const view = {
      keeper_level: a.keeper_level,
      renown: seasons.league(account, now),
      seasons: this.db.prepare("SELECT season, renown, league FROM season_results WHERE account = ? ORDER BY season")
        .all(account).map(({ season, renown, league }) => ({ season, renown, league })),
      heists: Object.fromEntries(["clean", "loud", "partial", "foiled"].map((g) => [g, count(raids.map((h) => h.o), g)])),
      defences: { held: count(on, "foiled"), leaked: on.length - count(on, "foiled"), partial: count(on, "partial") },
      records: RECORDS.map((id) => ({ id, value: record[id] ?? null })),
      // §23.2's "collection": the forms of §11.10's album the roster has
      // brought home, and the cosmetics owned, bought or earned.
      collection: {
        forms: new Set(this.service.home.characters(account).filter((c) => c.form)
          .map((c) => `${c.kind}/${c.form}`)).size,
        of: FORMS.length,
        cosmetics: JSON.parse(this.db.prepare("SELECT cosmetics FROM accounts WHERE id = ?").get(account).cosmetics).length,
      },
      badges: BADGES.map((id) => {
        const mark = facts.BADGE_MARKS[id];
        return { id, count: counts[id], mark, grade: grade(counts[id], mark) };
      }),
      titles,
    };
    if (!own) return view;
    return {
      ...view,
      log: mine.slice(0, LOG_ROWS).map((h) => ({
        heist: h.token, island: h.bundle, at: h.submitted_at, mode: h.mode, grade: h.o.verdict?.grade ?? "foiled",
        haul: h.o.haul?.total ?? 0, replay: h.replay_gone ? "gone" : "kept" })),
      band: a.age_band, public: Boolean(a.profile_public), can_share: a.age_band !== "13-15",
    };
  }

  /** Another player's profile, as `viewer` may see it: never a 13-to-15
   *  player's, and anyone else's only once they opened it (§20.2). */
  show(viewer, account) {
    if (viewer === account) return this.view(account);
    const a = this.db.prepare("SELECT age_band, profile_public, deleted_at, banned_at FROM accounts WHERE id = ?")
      .get(account);
    if (!a || a.deleted_at || a.banned_at) throw new Refused(404, "no_such_account");
    // §17.8: across a block either way, each disappears from the other's
    // view, so the profile is no account at all, as the other routes say.
    if (this.service.safety.between(viewer, account)) throw new Refused(404, "no_such_account");
    if (a.age_band === "13-15" || !a.profile_public) throw new Refused(403, "profile_private");
    return this.view(account, { own: false });
  }

  /** The visibility switch (§20.2): never on for 13 to 15. */
  share(account, on) {
    if (typeof on !== "boolean") throw new Refused(400, "malformed_body");
    const band = this.db.prepare("SELECT age_band FROM accounts WHERE id = ?").get(account).age_band;
    if (on && band === "13-15") throw new Refused(409, "profile_private_at_this_age");
    this.db.prepare("UPDATE accounts SET profile_public = ? WHERE id = ?").run(on ? 1 : 0, account);
    return this.view(account);
  }
}
