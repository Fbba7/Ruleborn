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
  pass_expires_at   INTEGER,
  keeper_level      INTEGER NOT NULL DEFAULT 1,
  created_at        INTEGER NOT NULL,
  -- §20.5: "Age bands instead of birthdates"; §20.7 sets what each may do.
  age_band          TEXT NOT NULL DEFAULT '18+' CHECK (age_band IN ('13-15', '16-17', '18+')),
  -- §20.4: a person reviews reports; this marks who may act on them.
  moderator         INTEGER NOT NULL DEFAULT 0,
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
  currency TEXT NOT NULL CHECK (currency IN ('starlight', 'essence')),
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

-- §25.1's 10% who remix: each take of an island into a builder.
CREATE TABLE IF NOT EXISTS workshop_remixes (
  item   TEXT NOT NULL REFERENCES workshop_items(id),
  player TEXT NOT NULL REFERENCES accounts(id),
  at     INTEGER NOT NULL,
  PRIMARY KEY (item, player)
);
`;

/** Columns added to a table after a database was first made: `CREATE TABLE IF
 *  NOT EXISTS` leaves an old table as it was, so each is added if missing. */
const ADDED = [
  ["accounts", "age_band", "TEXT NOT NULL DEFAULT '18+'"],
  ["accounts", "moderator", "INTEGER NOT NULL DEFAULT 0"],
  ["accounts", "banned_at", "INTEGER"],
  ["accounts", "banned_reason", "TEXT"],
];

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
  db.exec(SCHEMA);
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
