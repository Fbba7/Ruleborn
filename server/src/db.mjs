// What the database holds (§24.8), in SQLite.
//
// §24.1 puts the dynamic tier on "edge functions against a managed serverless
// SQL database". SQLite is what those databases run, so the schema here is the
// one they take; `node:sqlite` needs nothing installed.
//
// Two tables are append-only by construction, not by convention: triggers
// refuse an UPDATE or DELETE on them.
//
//   snapshots  §24.8: "Never edited."
//   ledger     §24.12: "the haul is minted, into an append-only ledger";
//              "currency is a ledger of minting events rather than a number
//              that gets overwritten."

import { DatabaseSync } from "node:sqlite";

export const SCHEMA = `
PRAGMA foreign_keys = ON;

-- §24.8: "Identifier, platform identity, league, cosmetics owned, season
-- pass expiry". The Keeper level is here because §9.6's difficulty compares
-- the raider's to the target's.
CREATE TABLE IF NOT EXISTS accounts (
  id                TEXT PRIMARY KEY,
  platform_identity TEXT NOT NULL UNIQUE,
  league            TEXT NOT NULL DEFAULT 'dust',
  cosmetics         TEXT NOT NULL DEFAULT '[]',
  -- What a player wears, slot by slot: applied here so a raider sees it.
  equipped          TEXT NOT NULL DEFAULT '{}',
  pass_expires_at   INTEGER,
  keeper_level      INTEGER NOT NULL DEFAULT 1,
  created_at        INTEGER NOT NULL,
  -- §20.5: "Age bands instead of birthdates"; §20.7 sets what each may do.
  age_band          TEXT NOT NULL DEFAULT '18+' CHECK (age_band IN ('13-15', '16-17', '18+')),
  -- §20.4: a person reviews reports; this marks who may act on them.
  moderator         INTEGER NOT NULL DEFAULT 0,
  -- Who may read the telemetry report (telemetry.mjs).
  analyst           INTEGER NOT NULL DEFAULT 0,
  -- §20.12: "Their islands leave matchmaking and the Workshop immediately."
  banned_at         INTEGER,
  banned_reason     TEXT
);

-- §24.8: "Owner, the hash of the current bundle, when it changed." One row a
-- realm: a universe is a Heart and up to six outer realms (§5.2).
CREATE TABLE IF NOT EXISTS islands (
  owner      TEXT NOT NULL REFERENCES accounts(id),
  realm      TEXT NOT NULL,
  bundle     TEXT NOT NULL REFERENCES snapshots(bundle),
  changed_at INTEGER NOT NULL,
  PRIMARY KEY (owner, realm)
);

-- §24.8: "Bundle hash as the key, realm type, difficulty band, when
-- published. Never edited." The owner is kept so a raider cannot lease their
-- own island and a foiled heist's fee has somewhere to go.
CREATE TABLE IF NOT EXISTS snapshots (
  bundle       TEXT PRIMARY KEY,
  owner        TEXT NOT NULL REFERENCES accounts(id),
  realm        TEXT NOT NULL,
  realm_level  INTEGER NOT NULL,
  vault_level  INTEGER NOT NULL,
  exposed      INTEGER NOT NULL,
  band         TEXT,
  rules        TEXT NOT NULL,
  published_at INTEGER NOT NULL
);
CREATE TRIGGER IF NOT EXISTS snapshots_never_edited BEFORE UPDATE ON snapshots
  BEGIN SELECT RAISE(ABORT, 'snapshots are never edited (24.8)'); END;
CREATE TRIGGER IF NOT EXISTS snapshots_never_deleted BEFORE DELETE ON snapshots
  BEGIN SELECT RAISE(ABORT, 'snapshots are never edited (24.8)'); END;

-- §24.12's lease: "a target snapshot, a seed, a single-use token and an
-- expiry a day away". §24.13: "One lease per target per player at a time" —
-- the partial unique index is that rule, held by the database.
CREATE TABLE IF NOT EXISTS leases (
  token       TEXT PRIMARY KEY,
  attacker    TEXT NOT NULL REFERENCES accounts(id),
  bundle      TEXT NOT NULL REFERENCES snapshots(bundle),
  -- Whose island is raided. A snapshot is keyed by its bytes, so two players
  -- who publish the same island share one; the defender is the player whose
  -- island the lease was taken on, not whoever published the bytes first.
  defender    TEXT NOT NULL REFERENCES accounts(id),
  seed        TEXT NOT NULL,
  ticks       INTEGER NOT NULL,
  rules       TEXT NOT NULL,
  issued_at   INTEGER NOT NULL,
  expires_at  INTEGER NOT NULL,
  state       TEXT NOT NULL DEFAULT 'open' CHECK (state IN ('open', 'settled'))
);
CREATE UNIQUE INDEX IF NOT EXISTS one_open_lease_per_target
  ON leases (attacker, bundle) WHERE state = 'open';

-- §24.8: "Attacker, target bundle hash, seed, hash of the input log,
-- resulting state hash, whether validated." One row a submitted lease: the
-- token is single-use, so a retry finds this row and is answered from it
-- (§24.12: "the server recognises it, so a haul can never be paid twice").
CREATE TABLE IF NOT EXISTS heists (
  token        TEXT PRIMARY KEY REFERENCES leases(token),
  attacker     TEXT NOT NULL REFERENCES accounts(id),
  bundle       TEXT NOT NULL REFERENCES snapshots(bundle),
  seed         TEXT NOT NULL,
  log_hash     TEXT NOT NULL,
  state_hash   TEXT,
  validated    INTEGER NOT NULL,
  outcome      TEXT NOT NULL,
  review       INTEGER NOT NULL DEFAULT 0,
  grace        INTEGER NOT NULL DEFAULT 0,
  submitted_at INTEGER NOT NULL,
  day          TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS heists_by_day ON heists (attacker, day, validated);

-- §24.8: "Target selection is a file, not a query. Candidate lists per
-- difficulty band are generated periodically as static objects". The lists
-- themselves are content-addressed objects in storage; this row names the
-- current one for each band, and is the only thing a regeneration changes.
CREATE TABLE IF NOT EXISTS target_lists (
  band         TEXT PRIMARY KEY,
  list         TEXT NOT NULL,
  candidates   INTEGER NOT NULL,
  generated_at INTEGER NOT NULL
);

-- §24.12: "Grant — only then is the haul minted, into an append-only ledger."
CREATE TABLE IF NOT EXISTS ledger (
  id       INTEGER PRIMARY KEY AUTOINCREMENT,
  account  TEXT NOT NULL REFERENCES accounts(id),
  -- Starglass in hundredths: a Starglass is a euro (§19.12's 1:1), so a
  -- price in cents is exact.
  currency TEXT NOT NULL CHECK (currency IN ('starlight', 'essence', 'starglass')),
  amount   INTEGER NOT NULL,
  reason   TEXT NOT NULL,
  -- Deferred: the heist row and its ledger rows are written in one
  -- transaction, and the heist's outcome includes what the ledger booked.
  heist    TEXT REFERENCES heists(token) DEFERRABLE INITIALLY DEFERRED,
  at       INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS ledger_by_account ON ledger (account, currency);
CREATE TRIGGER IF NOT EXISTS ledger_append_only_update BEFORE UPDATE ON ledger
  BEGIN SELECT RAISE(ABORT, 'the ledger is append-only (24.12)'); END;
CREATE TRIGGER IF NOT EXISTS ledger_append_only_delete BEFORE DELETE ON ledger
  BEGIN SELECT RAISE(ABORT, 'the ledger is append-only (24.12)'); END;

-- §18.6, the Island Workshop. An item is published once and never edited or
-- deleted (§21's "player creations are never deleted or overwritten"): its
-- bundle, creator, name and lineage are fixed by a trigger, and what can
-- change is its standing — withdrawn by its creator, removed by a moderator
-- with a reason (§20.11), featured, or flagged for review.
CREATE TABLE IF NOT EXISTS workshop_items (
  id             TEXT PRIMARY KEY,
  creator        TEXT NOT NULL REFERENCES accounts(id),
  bundle         TEXT NOT NULL,
  realm_level    INTEGER NOT NULL,
  -- §18.6: "island names come from word lists" — indices into words.json.
  name_adjective INTEGER NOT NULL,
  name_noun      INTEGER NOT NULL,
  remix_of       TEXT REFERENCES workshop_items(id),
  -- §18.6: "cleared by its creator": the replay that did it, by its hash.
  cleared_by     TEXT NOT NULL,
  bytes          INTEGER NOT NULL,
  published_at   INTEGER NOT NULL,
  withdrawn_at   INTEGER,
  removed_at     INTEGER,
  removed_reason TEXT,
  featured_at    INTEGER,
  review         INTEGER NOT NULL DEFAULT 0
);
CREATE TRIGGER IF NOT EXISTS workshop_items_fixed BEFORE UPDATE OF
  id, creator, bundle, realm_level, name_adjective, name_noun, remix_of, cleared_by, bytes,
  published_at ON workshop_items
  BEGIN SELECT RAISE(ABORT, 'a Workshop island is never edited (18.6)'); END;
CREATE TRIGGER IF NOT EXISTS workshop_items_kept BEFORE DELETE ON workshop_items
  BEGIN SELECT RAISE(ABORT, 'a Workshop island is never deleted (18.6)'); END;

-- A play of a Workshop island: a seed and a clock, like a lease, but nothing
-- is staked and nothing minted — the Workshop pays in completions (§18.7).
CREATE TABLE IF NOT EXISTS workshop_plays (
  token        TEXT PRIMARY KEY,
  player       TEXT NOT NULL REFERENCES accounts(id),
  item         TEXT NOT NULL REFERENCES workshop_items(id),
  seed         TEXT NOT NULL,
  ticks        INTEGER NOT NULL,
  issued_at    INTEGER NOT NULL,
  submitted_at INTEGER,
  outcome      TEXT
);

-- §18.7: "completions by the same player count once".
CREATE TABLE IF NOT EXISTS workshop_completions (
  item   TEXT NOT NULL REFERENCES workshop_items(id),
  player TEXT NOT NULL REFERENCES accounts(id),
  weight REAL NOT NULL,
  at     INTEGER NOT NULL,
  PRIMARY KEY (item, player)
);

-- §18.6: "players rate islands for fun, cleverness and fairness".
CREATE TABLE IF NOT EXISTS workshop_ratings (
  item       TEXT NOT NULL REFERENCES workshop_items(id),
  player     TEXT NOT NULL REFERENCES accounts(id),
  fun        INTEGER NOT NULL CHECK (fun BETWEEN 1 AND 5),
  cleverness INTEGER NOT NULL CHECK (cleverness BETWEEN 1 AND 5),
  fairness   INTEGER NOT NULL CHECK (fairness BETWEEN 1 AND 5),
  at         INTEGER NOT NULL,
  PRIMARY KEY (item, player)
);

-- §18.6: "every island can be reported"; §20.4: "reviewed by a person within
-- 24 hours". A report with no reporter is the server's own: a spike in
-- completions (§18.7).
CREATE TABLE IF NOT EXISTS workshop_reports (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  item        TEXT NOT NULL REFERENCES workshop_items(id),
  reporter    TEXT REFERENCES accounts(id),
  reason      TEXT NOT NULL,
  at          INTEGER NOT NULL,
  resolved_at INTEGER,
  resolution  TEXT
);

-- §18.1: "A season lasts eight weeks." Back to back from the first; a
-- season is closed once, when its results are written.
CREATE TABLE IF NOT EXISTS seasons (
  id        INTEGER PRIMARY KEY,
  starts_at INTEGER NOT NULL,
  ends_at   INTEGER NOT NULL,
  closed_at INTEGER
);

-- A player's season: where their Renown started (§18.1's pull back from the
-- last one), and whether they have reached Ember, below which they can no
-- longer fall ("nobody can drop out of Dust or Ember").
CREATE TABLE IF NOT EXISTS standings (
  season   INTEGER NOT NULL REFERENCES seasons(id),
  account  TEXT NOT NULL REFERENCES accounts(id),
  start    INTEGER NOT NULL,
  ember    INTEGER NOT NULL DEFAULT 0,
  -- §18.8's catch-up: the season track's tier price, fixed when the player
  -- first appears in the season, scaled to the time left (track.mjs).
  tier_stars INTEGER,
  PRIMARY KEY (season, account)
);

-- §12.9's Renown, as events, like the ledger: what each heist moved, and to
-- whom. A player's Renown is their season's start plus these.
CREATE TABLE IF NOT EXISTS renown (
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  season  INTEGER NOT NULL REFERENCES seasons(id),
  account TEXT NOT NULL REFERENCES accounts(id),
  amount  INTEGER NOT NULL,
  reason  TEXT NOT NULL,
  heist   TEXT REFERENCES heists(token) DEFERRABLE INITIALLY DEFERRED,
  at      INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS renown_by_account ON renown (season, account);
CREATE TRIGGER IF NOT EXISTS renown_append_only_update BEFORE UPDATE ON renown
  BEGIN SELECT RAISE(ABORT, 'Renown is a record of heists (12.9)'); END;
CREATE TRIGGER IF NOT EXISTS renown_append_only_delete BEFORE DELETE ON renown
  BEGIN SELECT RAISE(ABORT, 'Renown is a record of heists (12.9)'); END;

-- A closed season's results: "rewards are given by league" (§18.1).
CREATE TABLE IF NOT EXISTS season_results (
  season   INTEGER NOT NULL REFERENCES seasons(id),
  account  TEXT NOT NULL REFERENCES accounts(id),
  renown   INTEGER NOT NULL,
  league   TEXT NOT NULL,
  division INTEGER,
  reward   TEXT,
  PRIMARY KEY (season, account)
);

-- §17.5: "Constellations compete as teams in a seasonal league ranked by
-- members' combined Renown and anomaly scores."
CREATE TABLE IF NOT EXISTS constellation_results (
  season        INTEGER NOT NULL REFERENCES seasons(id),
  constellation TEXT NOT NULL REFERENCES constellations(id),
  renown        INTEGER NOT NULL,
  place         INTEGER NOT NULL,
  PRIMARY KEY (season, constellation)
);

-- §17.1: "up to 30 Keepers … a founder, up to four elders, and members."
CREATE TABLE IF NOT EXISTS constellations (
  id             TEXT PRIMARY KEY,
  name_adjective INTEGER NOT NULL,
  name_noun      INTEGER NOT NULL,
  founded_at     INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS constellation_members (
  constellation TEXT NOT NULL REFERENCES constellations(id),
  account       TEXT NOT NULL REFERENCES accounts(id),
  role          TEXT NOT NULL CHECK (role IN ('founder', 'elder', 'member')),
  joined_at     INTEGER NOT NULL,
  left_at       INTEGER
);
-- One constellation at a time.
CREATE UNIQUE INDEX IF NOT EXISTS one_constellation
  ON constellation_members (account) WHERE left_at IS NULL;

-- §17.7: a crew is "4 to 8", "formed inside a constellation, or with friends
-- across constellations"; "a crew survives its founder leaving".
CREATE TABLE IF NOT EXISTS crews (
  id         TEXT PRIMARY KEY,
  invite     TEXT NOT NULL UNIQUE,
  founded_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS crew_members (
  crew      TEXT NOT NULL REFERENCES crews(id),
  account   TEXT NOT NULL REFERENCES accounts(id),
  joined_at INTEGER NOT NULL,
  left_at   INTEGER
);
CREATE UNIQUE INDEX IF NOT EXISTS one_crew ON crew_members (account) WHERE left_at IS NULL;

-- §25.1's 10% who remix: each take of an island into a builder.
CREATE TABLE IF NOT EXISTS workshop_remixes (
  item   TEXT NOT NULL REFERENCES workshop_items(id),
  player TEXT NOT NULL REFERENCES accounts(id),
  at     INTEGER NOT NULL,
  PRIMARY KEY (item, player)
);
-- §18.2's season stars ("reset each season", §9.1), as events: earned by
-- heists and defences, spent on tiers.
CREATE TABLE IF NOT EXISTS season_stars (
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  season  INTEGER NOT NULL REFERENCES seasons(id),
  account TEXT NOT NULL REFERENCES accounts(id),
  amount  INTEGER NOT NULL,
  reason  TEXT NOT NULL,
  heist   TEXT REFERENCES heists(token) DEFERRABLE INITIALLY DEFERRED,
  at      INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS season_stars_by_account ON season_stars (season, account);
CREATE TRIGGER IF NOT EXISTS season_stars_append_only_update BEFORE UPDATE ON season_stars
  BEGIN SELECT RAISE(ABORT, 'season stars are a record (18.2)'); END;
CREATE TRIGGER IF NOT EXISTS season_stars_append_only_delete BEFORE DELETE ON season_stars
  BEGIN SELECT RAISE(ABORT, 'season stars are a record (18.2)'); END;

-- Each tier of each season's track, claimed once a track (§18.2, §18.8).
CREATE TABLE IF NOT EXISTS track_claims (
  account TEXT NOT NULL REFERENCES accounts(id),
  season  INTEGER NOT NULL REFERENCES seasons(id),
  tier    INTEGER NOT NULL,
  track   TEXT NOT NULL CHECK (track IN ('free', 'premium')),
  reward  TEXT NOT NULL,
  at      INTEGER NOT NULL,
  PRIMARY KEY (account, season, tier, track)
);

-- A season's premium track, bought with Starglass (§18.2). It never lapses
-- (§18.8's "nothing expires forever").
CREATE TABLE IF NOT EXISTS premium_tracks (
  account   TEXT NOT NULL REFERENCES accounts(id),
  season    INTEGER NOT NULL REFERENCES seasons(id),
  bought_at INTEGER NOT NULL,
  PRIMARY KEY (account, season)
);

-- A purchase asked for, held under a minor's monthly cap (§20.2) until its
-- receipt comes back or it lapses. Prices in euro cents.
CREATE TABLE IF NOT EXISTS purchase_intents (
  id          TEXT PRIMARY KEY,
  account     TEXT NOT NULL REFERENCES accounts(id),
  product     TEXT NOT NULL,
  price       INTEGER NOT NULL,
  created_at  INTEGER NOT NULL,
  redeemed_at INTEGER
);

-- A store's receipt, granted once per store transaction.
CREATE TABLE IF NOT EXISTS purchases (
  store   TEXT NOT NULL,
  txn     TEXT NOT NULL,
  account TEXT NOT NULL REFERENCES accounts(id),
  product TEXT NOT NULL,
  price   INTEGER NOT NULL,
  intent  TEXT REFERENCES purchase_intents(id),
  at      INTEGER NOT NULL,
  PRIMARY KEY (store, txn)
);
CREATE INDEX IF NOT EXISTS purchases_by_account ON purchases (account, at);
CREATE TRIGGER IF NOT EXISTS purchases_append_only_update BEFORE UPDATE ON purchases
  BEGIN SELECT RAISE(ABORT, 'a purchase is a record (22.1)'); END;
CREATE TRIGGER IF NOT EXISTS purchases_append_only_delete BEFORE DELETE ON purchases
  BEGIN SELECT RAISE(ABORT, 'a purchase is a record (22.1)'); END;

-- First-party telemetry (§24, §24.3; telemetry.mjs). Keyed by a pseudonym,
-- never an account (§20.5), and discarded after 90 days: not append-only,
-- because §24.3 says the raw events go.
CREATE TABLE IF NOT EXISTS events (
  id   INTEGER PRIMARY KEY AUTOINCREMENT,
  who  TEXT NOT NULL,
  kind TEXT NOT NULL,
  data TEXT NOT NULL,
  at   INTEGER NOT NULL,
  day  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS events_by_day ON events (kind, day);
CREATE INDEX IF NOT EXISTS events_by_who ON events (who, kind, day);

-- A player's first session day, kept for good, so a cohort is still a
-- cohort after its events are gone.
CREATE TABLE IF NOT EXISTS first_seen (
  who TEXT PRIMARY KEY,
  day TEXT NOT NULL
);

-- What stays of the raw events: each cohort's returns on day 1, 7 and 30,
-- and each day's count of each kind.
CREATE TABLE IF NOT EXISTS cohorts (
  day     TEXT PRIMARY KEY,
  players INTEGER NOT NULL,
  day1    INTEGER NOT NULL,
  day7    INTEGER NOT NULL,
  day30   INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS event_days (
  day     TEXT NOT NULL,
  kind    TEXT NOT NULL,
  events  INTEGER NOT NULL,
  players INTEGER NOT NULL,
  PRIMARY KEY (day, kind)
);
`;

/** Columns added to a table after a database was first made: `CREATE TABLE IF
 *  NOT EXISTS` leaves an old table as it was, so each is added if missing. */
const ADDED = [
  ["accounts", "age_band", "TEXT NOT NULL DEFAULT '18+'"],
  ["accounts", "moderator", "INTEGER NOT NULL DEFAULT 0"],
  ["accounts", "banned_at", "INTEGER"],
  ["accounts", "banned_reason", "TEXT"],
  // The cosmetics a player wears, slot by slot (shop.mjs).
  ["accounts", "equipped", "TEXT NOT NULL DEFAULT '{}'"],
  ["standings", "tier_stars", "INTEGER"],
  ["accounts", "analyst", "INTEGER NOT NULL DEFAULT 0"],
];

/** A ledger made before Starglass: its currency check predates it, and a
 *  check cannot be altered in SQLite, so the table is rebuilt around its
 *  rows — the append-only triggers forbid changing a row, not moving them. */
function starglassLedger(db) {
  const old = db.prepare("SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'ledger'").get();
  if (!old || old.sql.includes("'starglass'")) return false;
  db.exec(`DROP TRIGGER IF EXISTS ledger_append_only_update;
           DROP TRIGGER IF EXISTS ledger_append_only_delete;
           DROP INDEX IF EXISTS ledger_by_account;
           ALTER TABLE ledger RENAME TO ledger_before_starglass;`);
  return true;
}

export function open(path = ":memory:") {
  const db = new DatabaseSync(path);
  // The added columns first, so an old accounts table has them before the
  // schema's indexes and triggers are checked against it.
  const has = (table) => db.prepare(
    "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?").get(table);
  for (const [table, column, type] of ADDED) {
    if (has(table) && !db.prepare(`PRAGMA table_info(${table})`).all().some((c) => c.name === column)) {
      db.exec(`ALTER TABLE ${table} ADD COLUMN ${column} ${type}`);
    }
  }
  const rebuilt = starglassLedger(db);
  db.exec(SCHEMA);
  if (rebuilt) {
    db.exec(`INSERT INTO ledger (id, account, currency, amount, reason, heist, at)
               SELECT id, account, currency, amount, reason, heist, at FROM ledger_before_starglass;
             DROP TABLE ledger_before_starglass;`);
  }
  return db;
}

/** Run `fn` in one transaction: all of it or none of it. */
export function transaction(db, fn) {
  db.exec("BEGIN IMMEDIATE");
  try {
    const result = fn();
    db.exec("COMMIT");
    return result;
  } catch (err) {
    db.exec("ROLLBACK");
    throw err;
  }
}
