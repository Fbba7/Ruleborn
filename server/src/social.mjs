// Constellations and crews (§17.1, §17.5, §17.7).
//
// §17.1: "up to 30 Keepers, joined through the Beacon from Keeper level 6: a
// founder, up to four elders, and members." §17.7: a crew is "4 to 8 … the
// people you actually play with … Formed inside a constellation, or with
// friends across constellations", and "a crew survives its founder leaving.
// Any member can keep it; nothing is lost when someone stops playing."
//
// Nothing here is an obligation (§17's opening): no quotas, no activity
// minimums, and leaving costs nothing. Chat, the Grand Law vote, anomalies,
// page requests and borrowed crew are not built (D63).

import { readFileSync } from "node:fs";

import { transaction } from "./db.mjs";
import { Refused } from "./refused.mjs";
import { WORDS, Workshop } from "./workshop.mjs";

const facts = JSON.parse(readFileSync(new URL("./facts.json", import.meta.url), "utf8"));

/** SEC-43: how long a member removed from a constellation is kept from
 *  joining it again. */
export const REMOVED_DAYS = 7;
const DAY = 24 * 60 * 60 * 1000;

export class Social {
  constructor(service) {
    this.service = service;
  }

  get db() { return this.service.db; }
  now() { return this.service.now(); }

  // -- constellations --------------------------------------------------------

  /** The constellation a player is in now, with their role, or null. */
  membership(account) {
    return this.db.prepare(
      "SELECT * FROM constellation_members WHERE account = ? AND left_at IS NULL").get(account) ?? null;
  }

  members(id) {
    return this.db.prepare(
      `SELECT account, role, joined_at FROM constellation_members
        WHERE constellation = ? AND left_at IS NULL ORDER BY joined_at, rowid`).all(id);
  }

  keeperLevel(account) {
    return this.db.prepare("SELECT keeper_level FROM accounts WHERE id = ?").get(account).keeper_level;
  }

  /** §17.1's gate: the Beacon opens constellations from Keeper level 6. */
  gate(account) {
    if (this.keeperLevel(account) < facts.CONSTELLATION_KEEPER_LEVEL) {
      throw new Refused(403, "keeper_level_too_low", { needs: facts.CONSTELLATION_KEEPER_LEVEL });
    }
    if (this.membership(account)) throw new Refused(409, "already_in_a_constellation");
  }

  /** Found one: its founder is its first member. The name is from the
   *  Workshop's word lists (D63: §20.4 filters constellation names, which
   *  implies free text, and no filter exists here yet). */
  found(account, { adjective, noun } = {}) {
    this.gate(account);
    if (!Number.isInteger(adjective) || !Number.isInteger(noun)
        || !WORDS.adjectives[adjective] || !WORDS.nouns[noun]) {
      throw new Refused(400, "name_not_from_the_word_lists");
    }
    const id = this.service.random(8).toString("hex");
    const now = this.now();
    transaction(this.db, () => {
      this.db.prepare(
        "INSERT INTO constellations (id, name_adjective, name_noun, founded_at) VALUES (?, ?, ?, ?)")
        .run(id, adjective, noun, now);
      this.db.prepare(
        `INSERT INTO constellation_members (constellation, account, role, joined_at)
         VALUES (?, ?, 'founder', ?)`).run(id, account, now);
    });
    return this.constellation(id);
  }

  /** A constellation as `viewer` sees it: §17.8's block hides a member the
   *  viewer blocked, or who blocked them, from its list. To a viewer outside
   *  it and across a block from its founder it does not exist (one member's
   *  blocks do not hide an open group from everyone they blocked, SEC-43), as
   *  join() answers them, so neither route tells the block. */
  constellation(id, viewer = null) {
    const c = this.db.prepare("SELECT * FROM constellations WHERE id = ?").get(id);
    if (!c) throw new Refused(404, "no_such_constellation");
    const members = this.members(id);
    const founder = members.filter((m) => m.role === "founder");
    if (this.hiddenFrom(viewer, members, founder)) throw new Refused(404, "no_such_constellation");
    return { id: c.id, name: Workshop.name(c.name_adjective, c.name_noun),
             members: members.filter((m) => this.shown(viewer, m.account)) };
  }

  /** Whether `viewer` is shown `account`: not across a block either way (§17.8). */
  shown(viewer, account) {
    return !viewer || viewer === account || !this.service.safety.between(viewer, account);
  }

  /** Whether a group of these members is hidden from `viewer`: they are not
   *  in it, and one of `across` (every member of a crew, the founder of a
   *  constellation) is across a block from them. It is one they cannot
   *  join, answered as one that does not exist, so the block is not told
   *  (§17.8's "invitations"). */
  hiddenFrom(viewer, members, across = members) {
    return Boolean(viewer) && !members.some((m) => m.account === viewer)
      && across.some((m) => this.service.safety.between(viewer, m.account));
  }

  /** Join through the Beacon: open to any Keeper past the gate while there is
   *  room. §17.1 says nothing of approval, so none is asked (D63). One its
   *  last member left is closed: it would have no founder (§17.1). */
  join(account, id) {
    this.gate(account);
    this.constellation(id, account);
    // SEC-43: one its founder or an elder removed stays out a week.
    const removed = this.db.prepare(
      `SELECT MAX(left_at) AS at FROM constellation_members
        WHERE constellation = ? AND account = ? AND removed = 1`).get(id, account).at;
    if (removed !== null && removed > this.now() - REMOVED_DAYS * DAY) {
      throw new Refused(403, "removed_from_constellation", { until: removed + REMOVED_DAYS * DAY });
    }
    return transaction(this.db, () => {
      const members = this.members(id).length;
      if (members === 0) throw new Refused(410, "constellation_closed");
      if (members >= facts.CONSTELLATION_SIZE) {
        throw new Refused(409, "constellation_full", { size: facts.CONSTELLATION_SIZE });
      }
      this.db.prepare(
        `INSERT INTO constellation_members (constellation, account, role, joined_at)
         VALUES (?, ?, 'member', ?)`).run(id, account, this.now());
      return this.constellation(id, account);
    });
  }

  /** Leave, at no cost. A founder who leaves hands the constellation on — to
   *  the longest-standing elder, else the longest-standing member — as §17.7
   *  says a crew survives its founder; the last to leave leaves it empty,
   *  and closed. */
  leave(account) {
    const m = this.membership(account);
    if (!m) throw new Refused(409, "not_in_a_constellation");
    transaction(this.db, () => this.depart(m));
    return { left: m.constellation };
  }

  /** `leave`'s writes, in the caller's transaction: a ban's (§20.12). */
  depart(m) {
    this.db.prepare(
      "UPDATE constellation_members SET left_at = ? WHERE account = ? AND left_at IS NULL")
      .run(this.now(), m.account);
    if (m.role === "founder") {
      const heir = this.members(m.constellation)
        .sort((a, b) => (a.role === "elder" ? 0 : 1) - (b.role === "elder" ? 0 : 1))[0];
      if (heir) this.setRole(m.constellation, heir.account, "founder");
    }
  }

  setRole(constellation, account, role) {
    this.db.prepare(
      `UPDATE constellation_members SET role = ?
        WHERE constellation = ? AND account = ? AND left_at IS NULL`).run(role, constellation, account);
  }

  /** The founder names up to four elders, and can make one a member again;
   *  in the constellation `id` names, when the caller names one (RB-26). */
  appoint(founder, account, role, id = null) {
    const f = this.membership(founder);
    if (!f || f.role !== "founder" || (id !== null && f.constellation !== id)) {
      throw new Refused(403, "founder_only");
    }
    const m = this.membership(account);
    if (!m || m.constellation !== f.constellation || account === founder) {
      throw new Refused(404, "not_a_member");
    }
    if (!["elder", "member"].includes(role)) throw new Refused(400, "no_such_role");
    if (role === "elder" && m.role !== "elder"
        && this.members(f.constellation).filter((x) => x.role === "elder").length
           >= facts.CONSTELLATION_ELDERS) {
      throw new Refused(409, "elders_full", { elders: facts.CONSTELLATION_ELDERS });
    }
    this.setRole(f.constellation, account, role);
    return this.constellation(f.constellation, founder);
  }

  /** SEC-43: the founder removes an elder or a member, an elder a member.
   *  The removed player leaves as by leave() and cannot join that
   *  constellation again for REMOVED_DAYS. */
  remove(officer, id, account) {
    const o = this.membership(officer);
    if (!o || o.constellation !== id || !["founder", "elder"].includes(o.role)) {
      throw new Refused(403, "officers_only");
    }
    const m = this.membership(account);
    if (!m || m.constellation !== id || account === officer) throw new Refused(404, "not_a_member");
    if (m.role === "founder" || (o.role === "elder" && m.role !== "member")) {
      throw new Refused(403, "officers_only");
    }
    this.db.prepare(
      "UPDATE constellation_members SET left_at = ?, removed = 1 WHERE account = ? AND left_at IS NULL")
      .run(this.now(), account);
    return this.constellation(id, officer);
  }

  /** Whether two players share a constellation now: §18.7's "completions
   *  from a creator's own constellation count at a quarter". */
  sameConstellation(a, b) {
    const x = this.membership(a);
    const y = this.membership(b);
    return Boolean(x && y && x.constellation === y.constellation);
  }

  // -- crews -------------------------------------------------------------------

  crewOf(account) {
    return this.db.prepare(
      "SELECT crew FROM crew_members WHERE account = ? AND left_at IS NULL").get(account)?.crew ?? null;
  }

  /** A crew as `viewer` sees it: members across a block from them are left
   *  out of the list (§17.8), and to one outside it across a block from a
   *  member it does not exist (hiddenFrom); whether it has formed counts
   *  everyone. */
  crew(id, viewer = null) {
    const c = this.db.prepare("SELECT * FROM crews WHERE id = ?").get(id);
    if (!c) throw new Refused(404, "no_such_crew");
    const members = this.db.prepare(
      "SELECT account, joined_at FROM crew_members WHERE crew = ? AND left_at IS NULL ORDER BY joined_at, rowid")
      .all(id);
    const [least] = facts.CREW_SIZE;
    // §17.7's "4 to 8": a crew forms from its first member and counts as one
    // — for co-op and shared goals — from four (D63).
    if (this.hiddenFrom(viewer, members)) throw new Refused(404, "no_such_crew");
    // The invite joins the crew, so only its members see it (SEC-42).
    const member = viewer !== null && members.some((m) => m.account === viewer);
    return { id, ...(member ? { invite: c.invite } : {}), members: members.filter((m) => this.shown(viewer, m.account)),
             formed: members.length >= least };
  }

  /** Start a crew. It is joined by its invite — §17.7's friends "across
   *  constellations" have no other way to find each other here. */
  startCrew(account) {
    if (this.crewOf(account)) throw new Refused(409, "already_in_a_crew");
    const id = this.service.random(8).toString("hex");
    const invite = this.service.random(6).toString("hex");
    const now = this.now();
    transaction(this.db, () => {
      this.db.prepare("INSERT INTO crews (id, invite, founded_at) VALUES (?, ?, ?)").run(id, invite, now);
      this.db.prepare("INSERT INTO crew_members (crew, account, joined_at) VALUES (?, ?, ?)")
        .run(id, account, now);
    });
    return this.crew(id, account);
  }

  joinCrew(account, invite) {
    if (this.crewOf(account)) throw new Refused(409, "already_in_a_crew");
    const c = this.db.prepare("SELECT id FROM crews WHERE invite = ?").get(invite);
    if (!c) throw new Refused(404, "no_such_crew");
    this.crew(c.id, account);
    return transaction(this.db, () => {
      const [, most] = facts.CREW_SIZE;
      const members = this.crew(c.id).members.map((m) => m.account);
      if (members.length >= most) throw new Refused(409, "crew_full", { size: most });
      // SR-14, the owner's rule: §17.7's "inside a constellation, or with
      // friends across constellations" — a friend or constellation-mate of
      // one member; for a 13-to-15 (§20.7's friends only), a friend of every
      // member. A crew with nobody left in it is anyone's to start again.
      const minor = this.db.prepare("SELECT age_band FROM accounts WHERE id = ?").get(account)?.age_band === "13-15";
      const friend = (m) => this.service.friends.areFriends(account, m);
      const welcome = minor ? members.every(friend)
        : !members.length || members.some((m) => friend(m) || this.sameConstellation(account, m));
      if (!welcome) throw new Refused(403, "not_friends");
      this.db.prepare("INSERT INTO crew_members (crew, account, joined_at) VALUES (?, ?, ?)")
        .run(c.id, account, this.now());
      return this.crew(c.id, account);
    });
  }

  /** A new invite for a crew, the old one joining nobody from now (SEC-42).
   *  A crew has no founder to keep it, so its leader here is the member who
   *  has been in it longest: the founder while they stay, then the next to
   *  have joined. */
  newInvite(account, id) {
    const c = this.db.prepare("SELECT id FROM crews WHERE id = ?").get(id);
    if (!c) throw new Refused(404, "no_such_crew");
    const leader = this.db.prepare(
      "SELECT account FROM crew_members WHERE crew = ? AND left_at IS NULL ORDER BY joined_at, rowid LIMIT 1")
      .get(id)?.account;
    if (leader !== account) throw new Refused(403, "crew_leader_only");
    this.db.prepare("UPDATE crews SET invite = ? WHERE id = ?").run(this.service.random(6).toString("hex"), id);
    return this.crew(id, account);
  }

  /** Leave a crew. It carries on with whoever is left: there is no founder
   *  to lose, so "any member can keep it". */
  leaveCrew(account) {
    const id = this.crewOf(account);
    if (!id) throw new Refused(409, "not_in_a_crew");
    this.db.prepare("UPDATE crew_members SET left_at = ? WHERE account = ? AND left_at IS NULL")
      .run(this.now(), account);
    return { left: id };
  }
}
