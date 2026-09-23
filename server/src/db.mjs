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
  created_at        INTEGER NOT NULL
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
`;

export function open(path = ":memory:") {
  const db = new DatabaseSync(path);
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
