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
  -- §14.2: the experience toward the next level (keeper.mjs).
  keeper_xp         INTEGER NOT NULL DEFAULT 0,
  -- §7.6's "a law you are actually working on" (codex.mjs).
  working_on        TEXT,
  -- §11.7's guardian Sage, stationed at the Heart (keeper.mjs).
  guardian_sage     TEXT,
  -- §23.2's defence log last read: raids after it are new (defences.mjs).
  defences_seen_at  INTEGER,
  -- §20.2's profile visibility: off by default, never on for 13 to 15.
  profile_public    INTEGER NOT NULL DEFAULT 0,
  -- G58: the Keeper's name from the word lists, by index; raiders see it.
  keeper_adjective  INTEGER,
  keeper_noun       INTEGER,
  -- §20.11's terms-of-use gate: the version of the terms accepted (safety.mjs).
  terms_version     TEXT,
  created_at        INTEGER NOT NULL,
  -- §20.5: "Age bands instead of birthdates"; §20.7 sets what each may do.
  age_band          TEXT NOT NULL DEFAULT '18+' CHECK (age_band IN ('13-15', '16-17', '18+')),
  -- §20.4: a person reviews reports; this marks who may act on them.
  moderator         INTEGER NOT NULL DEFAULT 0,
  -- Who may read the telemetry report (telemetry.mjs).
  analyst           INTEGER NOT NULL DEFAULT 0,
  -- §20.12: "Their islands leave matchmaking and the Workshop immediately."
  banned_at         INTEGER,
  banned_reason     TEXT,
  -- §20.5's deletion: the identity is gone, the id kept for the records
  -- nobody edits (accounts.mjs).
  deleted_at        INTEGER,
  deleted_reason    TEXT,
  -- §14.6 and §20.2's notifications: the device's IANA time zone (none
  -- reported, no push: G34), their daily reminder (minutes after local
  -- midnight), an adult's choice of a quiet night, and the device's push
  -- token (notifications.mjs).
  time_zone         TEXT,
  reminder_at       INTEGER,
  night_quiet       INTEGER NOT NULL DEFAULT 1,
  push_token        TEXT,
  -- §13.1's seeded islands: the game's own, "stocked with designed islands
  -- from the start", and no new player to protect (matchmaking.mjs).
  seeded            INTEGER NOT NULL DEFAULT 0,
  fund_opt_in       INTEGER NOT NULL DEFAULT 0
);

-- §24.8: "Owner, the hash of the current bundle, when it changed." One row a
-- realm: a universe is a Heart and up to six outer realms (§5.2).
CREATE TABLE IF NOT EXISTS islands (
  owner      TEXT NOT NULL REFERENCES accounts(id),
  realm      TEXT NOT NULL,
  bundle     TEXT NOT NULL REFERENCES snapshots(bundle),
  changed_at INTEGER NOT NULL,
  origin     TEXT,
  seed       TEXT,
  terrain    TEXT,
  name_adjective INTEGER,
  name_noun  INTEGER,
  PRIMARY KEY (owner, realm)
);

-- §20.11: "a way to block another player". The blocker's list (safety.mjs).
CREATE TABLE IF NOT EXISTS blocks (
  blocker TEXT NOT NULL REFERENCES accounts(id),
  blocked TEXT NOT NULL REFERENCES accounts(id),
  at      INTEGER NOT NULL,
  PRIMARY KEY (blocker, blocked)
);
CREATE INDEX IF NOT EXISTS blocks_by_blocked ON blocks (blocked);

-- §5.2: a universe's outer realms, each of a type not yet owned, opened in
-- order at the Keeper levels §5.2 gives. The Heart has no row: every
-- universe has one, and it counts as realm level 3 (G19). universe.mjs.
CREATE TABLE IF NOT EXISTS realms (
  owner     TEXT NOT NULL REFERENCES accounts(id),
  realm     TEXT NOT NULL,
  type      TEXT NOT NULL,
  level     INTEGER NOT NULL CHECK (level BETWEEN 1 AND 5),
  opened_at INTEGER NOT NULL,
  PRIMARY KEY (owner, realm),
  UNIQUE (owner, type)
);

-- §10.2: every building a universe holds, by realm, kind (§10.2's id) and
-- its number among that kind there. A universe with no rows holds the start
-- (F56), written the first time it changes. universe.mjs.
-- §12.3: "Refreshing the list costs Aether: 50, doubling with each refresh
-- in the same hour" — each refresh, and the targets it set aside so the list
-- it bought is new. observatory.mjs.
CREATE TABLE IF NOT EXISTS observatory_refreshes (
  owner TEXT NOT NULL REFERENCES accounts(id),
  at    INTEGER NOT NULL,
  shown TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS observatory_refreshes_by_owner ON observatory_refreshes (owner, at);

-- §8.6's Resonance Lab: each experiment, in its chamber, running until
-- ready_at and settled once with its result; and what the Lab has found and
-- hinted, a resonance, a chord or a hint by its id. lab.mjs.
CREATE TABLE IF NOT EXISTS lab_experiments (
  owner      TEXT NOT NULL REFERENCES accounts(id),
  chamber    INTEGER NOT NULL,
  laws       TEXT NOT NULL,
  started_at INTEGER NOT NULL,
  ready_at   INTEGER NOT NULL,
  unstable   INTEGER NOT NULL DEFAULT 0,
  settled_at INTEGER,
  result     TEXT
);
CREATE INDEX IF NOT EXISTS lab_experiments_by_owner ON lab_experiments (owner, chamber);
CREATE TABLE IF NOT EXISTS lab_discoveries (
  owner    TEXT NOT NULL REFERENCES accounts(id),
  kind     TEXT NOT NULL CHECK (kind IN ('resonance', 'chord', 'hint')),
  id       TEXT NOT NULL,
  found_at INTEGER NOT NULL,
  PRIMARY KEY (owner, kind, id)
);

CREATE TABLE IF NOT EXISTS buildings (
  owner      TEXT NOT NULL REFERENCES accounts(id),
  realm      TEXT NOT NULL,
  kind       TEXT NOT NULL,
  n          INTEGER NOT NULL,
  level      INTEGER NOT NULL CHECK (level >= 1),
  changed_at INTEGER NOT NULL,
  -- Where it stands (10.1): its footprint's north-west tile, or none until
  -- it is placed. The Vault, pylons, posts and wards stand where the island
  -- puts them.
  x          INTEGER,
  y          INTEGER,
  PRIMARY KEY (owner, realm, kind, n)
);

-- §11.5: every character a player owns — the three who wake in the first
-- minute, the two strays of the first heist, the births — with its kind
-- (§11.2's id), its traits (§11.3's ids), its level (§11.4), its home (the
-- Spire, or the realm whose Hearth it lives in) and the work it is given:
-- a producer or a Guardian Post, from when (§5.8, §11.6). home.mjs.
CREATE TABLE IF NOT EXISTS characters (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  owner      TEXT NOT NULL REFERENCES accounts(id),
  kind       TEXT NOT NULL,
  traits     TEXT NOT NULL DEFAULT '[]',
  level      INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
  home       TEXT NOT NULL,
  via        TEXT NOT NULL CHECK (via IN ('woke', 'stray', 'birth')),
  -- §11.10's form, the note the laws around its birth set (home.mjs).
  form       TEXT,
  -- §19.20's name from the word lists, as their indices (home.mjs).
  name_adjective INTEGER,
  name_noun  INTEGER,
  joined_at  INTEGER NOT NULL,
  work_realm TEXT,
  work_kind  TEXT,
  work_n     INTEGER,
  work_since INTEGER,
  -- 11.6: away on a heist and resting after it, from and until (home.mjs).
  away_from  INTEGER,
  away_until INTEGER
);
CREATE INDEX IF NOT EXISTS characters_by_owner ON characters (owner);

-- §9.3: what each producer has made and not yet paid, in thousandths, as of
-- settled_at; it holds 12 hours of output until collected. home.mjs.
CREATE TABLE IF NOT EXISTS producers (
  owner      TEXT NOT NULL REFERENCES accounts(id),
  realm      TEXT NOT NULL,
  kind       TEXT NOT NULL,
  stored     INTEGER NOT NULL DEFAULT 0 CHECK (stored >= 0),
  settled_at INTEGER NOT NULL,
  PRIMARY KEY (owner, realm, kind)
);

-- §10.2's Nursery: "one birth every 6 h; holds 3". Births are ready from
-- since, one a period, up to what it holds. home.mjs.
-- §11.5: a stray a heist found, offered to the roster until it is taken
-- or declined; its form is drawn when it is taken (home.mjs).
CREATE TABLE IF NOT EXISTS stray_offers (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  owner     TEXT NOT NULL REFERENCES accounts(id),
  heist     TEXT NOT NULL,
  kind      TEXT NOT NULL,
  traits    TEXT NOT NULL,
  law       TEXT,
  found_at  INTEGER NOT NULL,
  answer    TEXT CHECK (answer IN ('taken', 'declined')),
  character INTEGER
);
CREATE INDEX IF NOT EXISTS stray_offers_by_owner ON stray_offers (owner);

CREATE TABLE IF NOT EXISTS nurseries (
  owner TEXT NOT NULL REFERENCES accounts(id),
  realm TEXT NOT NULL,
  since INTEGER NOT NULL,
  PRIMARY KEY (owner, realm)
);

-- §7.6: the Codex — each law a player has met, its pages, and its tier (0
-- not restored, then I to III). codex.mjs.
CREATE TABLE IF NOT EXISTS codex (
  owner       TEXT NOT NULL REFERENCES accounts(id),
  law         TEXT NOT NULL,
  pages       INTEGER NOT NULL DEFAULT 0 CHECK (pages >= 0),
  tier        INTEGER NOT NULL DEFAULT 0 CHECK (tier BETWEEN 0 AND 3),
  met_at      INTEGER NOT NULL,
  restored_at INTEGER,
  -- §18.5's mastery steps: first woven, first crossed in a successful heist.
  woven_at    INTEGER,
  crossed_at  INTEGER,
  PRIMARY KEY (owner, law)
);

-- §7.6: "After each heist the player picks one law the crew crossed to
-- study": the one study a heist allows, by its token. codex.mjs.
CREATE TABLE IF NOT EXISTS studies (
  token TEXT PRIMARY KEY REFERENCES heists(token),
  owner TEXT NOT NULL REFERENCES accounts(id),
  law   TEXT NOT NULL,
  pages INTEGER NOT NULL,
  at    INTEGER NOT NULL
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
  published_at INTEGER NOT NULL,
  origin       TEXT
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
  -- §12.3: an echo is a past snapshot, robbed from nobody; a Trace answers
  -- the heist named, with no entry fee (matchmaking.mjs).
  echo        INTEGER NOT NULL DEFAULT 0,
  trace_of    TEXT,
  -- §12.11 and §17.6: a raid, a friendly heist or a challenge link's play,
  -- the last two taking nothing from the island's owner (friends.mjs).
  mode        TEXT NOT NULL DEFAULT 'raid' CHECK (mode IN ('raid', 'friendly', 'challenge')),
  challenge   TEXT,
  -- §18.3's era of the week it was leased in, as the replay's header must
  -- name it: the wire value, 0 for none (eras.mjs).
  era         INTEGER NOT NULL DEFAULT 0,
  -- §5.4: the universe a heist across the defender's realms crosses, its
  -- RBU1 bundle's hash (crossings.mjs); null for the Heart alone.
  universe    TEXT
);
-- §24.13's one lease a target is kept by the issuing transaction, which
-- hands back the newest lease the attacker holds on it with no heist; a
-- lease is settled by its heist row, so settling one writes nothing more.
CREATE INDEX IF NOT EXISTS leases_by_target ON leases (attacker, bundle, issued_at);

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
  day          TEXT NOT NULL,
  -- §24.3: the replay itself is kept "30 to 90 days", then deleted; the row
  -- and its hashes stay.
  replay_gone  INTEGER NOT NULL DEFAULT 0
);
-- A player's heists by day: every count of the day's and week's heists
-- reads through it. Whether a heist was validated is not in it, so marking
-- one validated as it settles (service.settle) touches no index entry.
CREATE INDEX IF NOT EXISTS heists_by_attacker ON heists (attacker, day);

-- §24.8: "Target selection is a file, not a query. Candidate lists per
-- difficulty band are generated periodically as static objects". The lists
-- themselves are content-addressed objects in storage; this row names the
-- current one for each band, and is the only thing a regeneration changes.
CREATE TABLE IF NOT EXISTS target_lists (
  band         TEXT PRIMARY KEY,
  list         TEXT NOT NULL,
  candidates   INTEGER NOT NULL,
  generated_at INTEGER NOT NULL,
  -- The list before this one, still served to a device that fetched the
  -- index just before it changed; the one before that is deleted, as a list
  -- names players (service.targetLists).
  previous     TEXT,
  -- When the previous list stopped being current: it is kept one rebuild after
  -- that, then deleted (G38).
  superseded_at INTEGER
);

-- §24.12: "Grant — only then is the haul minted, into an append-only ledger."
-- One row a player an event: what it moved in each currency (no Starglass:
-- the owner answered F41 with no currency, every item priced in money), and
-- how much of it counts to §9.6's day and week caps — a haul, or a defence
-- share (G37). A heist books one row for its raider and, when it pays them,
-- one for its defender; the heist's outcome keeps the lines — fee, haul,
-- fee returned, share — that the row sums, so a heist costs one written row
-- a player, not one a line (§24.1's writes; F47).
CREATE TABLE IF NOT EXISTS ledger (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  account   TEXT NOT NULL REFERENCES accounts(id),
  starlight INTEGER NOT NULL DEFAULT 0,
  essence   INTEGER NOT NULL DEFAULT 0,
  aether    INTEGER NOT NULL DEFAULT 0,
  paid      INTEGER NOT NULL DEFAULT 0,
  reason    TEXT NOT NULL,
  -- Deferred: the heist row and its ledger rows are written in one
  -- transaction, and the heist's outcome includes what the ledger booked.
  heist     TEXT REFERENCES heists(token) DEFERRABLE INITIALLY DEFERRED,
  at        INTEGER NOT NULL,
  CHECK (starlight != 0 OR essence != 0 OR aether != 0 OR paid != 0)
);
CREATE INDEX IF NOT EXISTS ledger_by_account ON ledger (account, at);
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

-- A season's premium track, bought as a store product (§18.2, F41). It
-- never lapses (§18.8's "nothing expires forever"); a refund takes it back
-- (G32).

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
  redeemed_at INTEGER,
  -- A gift's friend (F41); null for the buyer's own.
  recipient   TEXT REFERENCES accounts(id)
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
  -- Who received it, if not the buyer: a gift (F41).
  recipient TEXT REFERENCES accounts(id),
  PRIMARY KEY (store, txn)
);
CREATE INDEX IF NOT EXISTS purchases_by_account ON purchases (account, at);
-- The daily job deletes lapsed intents (service.expireLapsed), and a
-- purchase names its intent: without this, each intent deleted would read
-- every purchase ever made to check none names it.
CREATE INDEX IF NOT EXISTS purchases_by_intent ON purchases (intent);
CREATE TRIGGER IF NOT EXISTS purchases_append_only_update BEFORE UPDATE ON purchases
  BEGIN SELECT RAISE(ABORT, 'a purchase is a record (22.1)'); END;
CREATE TRIGGER IF NOT EXISTS purchases_append_only_delete BEFORE DELETE ON purchases
  BEGIN SELECT RAISE(ABORT, 'a purchase is a record (22.1)'); END;

-- A refund or revocation a store reported, and a refund it reversed (G32):
-- one row an event, in the order they came. A transaction is refunded while
-- its latest is a refund.
CREATE TABLE IF NOT EXISTS refunds (
  id    INTEGER PRIMARY KEY,
  store TEXT NOT NULL,
  txn   TEXT NOT NULL,
  kind  TEXT NOT NULL CHECK (kind IN ('refund', 'reversal')),
  at    INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS refunds_by_txn ON refunds (store, txn, id);
CREATE TRIGGER IF NOT EXISTS refunds_append_only_update BEFORE UPDATE ON refunds
  BEGIN SELECT RAISE(ABORT, 'a refund is a record (22.1)'); END;
CREATE TRIGGER IF NOT EXISTS refunds_append_only_delete BEFORE DELETE ON refunds
  BEGIN SELECT RAISE(ABORT, 'a refund is a record (22.1)'); END;

-- Friends (§12.11, §17.6; friends.mjs): one row a pair, the smaller id
-- first; an invite one player shares and another accepts; a challenge link
-- to an island.
CREATE TABLE IF NOT EXISTS friends (
  a     TEXT NOT NULL REFERENCES accounts(id),
  b     TEXT NOT NULL REFERENCES accounts(id),
  since INTEGER NOT NULL,
  invited_by TEXT,
  gift_at    INTEGER,
  PRIMARY KEY (a, b),
  CHECK (a < b)
);
CREATE INDEX IF NOT EXISTS friends_by_b ON friends (b);
-- §13.3's hold, measured on the server (holds.mjs): each bundle's
-- measurement under a rules version, how far it has come and what it held.
CREATE TABLE IF NOT EXISTS island_holds (
  bundle      TEXT NOT NULL,
  rules       TEXT NOT NULL,
  raids       INTEGER NOT NULL,
  played      INTEGER NOT NULL,
  held        INTEGER NOT NULL,
  queued_at   INTEGER NOT NULL,
  measured_at INTEGER,
  PRIMARY KEY (bundle, rules)
);
-- §18.9's Island Fund (fund.mjs): each closed quarter's net revenue and
-- fund, and what each opted-in creator's islands earned of it.
CREATE TABLE IF NOT EXISTS fund_quarters (
  quarter   INTEGER PRIMARY KEY,
  net       INTEGER NOT NULL,
  pool      INTEGER NOT NULL,
  closed_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS fund_payouts (
  quarter INTEGER NOT NULL REFERENCES fund_quarters(quarter),
  creator TEXT NOT NULL REFERENCES accounts(id),
  seconds INTEGER NOT NULL,
  cents   INTEGER NOT NULL,
  PRIMARY KEY (quarter, creator)
);
-- §5.3's links between a universe's realms (links.mjs): each its kind and
-- the two realms it joins, a Chute running from a to b; a Rift's upkeep paid
-- to paid_to, and whether it stands open.
CREATE TABLE IF NOT EXISTS links (
  owner    TEXT NOT NULL REFERENCES accounts(id),
  n        INTEGER NOT NULL,
  kind     TEXT NOT NULL,
  a        TEXT NOT NULL,
  b        TEXT NOT NULL,
  built_at INTEGER NOT NULL,
  paid_to  INTEGER NOT NULL,
  open     INTEGER NOT NULL DEFAULT 1,
  PRIMARY KEY (owner, n)
);
CREATE TABLE IF NOT EXISTS friend_invites (
  code       TEXT PRIMARY KEY,
  account    TEXT NOT NULL REFERENCES accounts(id),
  created_at INTEGER NOT NULL,
  used_at    INTEGER
);
CREATE TABLE IF NOT EXISTS challenges (
  code       TEXT PRIMARY KEY,
  account    TEXT NOT NULL REFERENCES accounts(id),
  bundle     TEXT NOT NULL REFERENCES snapshots(bundle),
  created_at INTEGER NOT NULL
);

-- The notification outbox (§14.6, §20.2; notifications.mjs): what is owed a
-- player, when it may be sent, and when it was.
CREATE TABLE IF NOT EXISTS notifications (
  id      INTEGER PRIMARY KEY AUTOINCREMENT,
  account TEXT NOT NULL REFERENCES accounts(id),
  kind    TEXT NOT NULL,
  data    TEXT NOT NULL,
  due_at  INTEGER NOT NULL,
  sent_at INTEGER,
  -- How often the push service could not take it (notifications.mjs).
  attempts INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX IF NOT EXISTS notifications_due ON notifications (sent_at, due_at);

-- §13.1's rule, season by season: the defence reward's share of what a
-- foiled crew carried, and the weekly measure that set it (seasons.mjs).
CREATE TABLE IF NOT EXISTS defence_shares (
  season   INTEGER PRIMARY KEY,
  percent  INTEGER NOT NULL,
  measured REAL,
  set_at   INTEGER NOT NULL
);

-- §12.22's Glicko-2 ratings: a raider's skill by account, an island's
-- difficulty by owner and realm (matchmaking.mjs).
CREATE TABLE IF NOT EXISTS ratings (
  kind       TEXT NOT NULL CHECK (kind IN ('raider', 'island')),
  key        TEXT NOT NULL,
  rating     REAL NOT NULL,
  deviation  REAL NOT NULL,
  volatility REAL NOT NULL,
  games      INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (kind, key)
);

-- §20.12: "The minimum identifiers needed to enforce the ban are kept". A
-- banned platform identity, apart from the account: the account's records
-- are severed from it on deletion like anyone's, and sign-in still refuses
-- it (accounts.mjs).
CREATE TABLE IF NOT EXISTS bans (
  identity  TEXT PRIMARY KEY,
  banned_at INTEGER NOT NULL,
  reason    TEXT
);

-- What an under-13 deletion still has to delete outside the database — a
-- replay, an island's bytes — or remake (the target lists, store 'lists'),
-- written in the deletion's transaction and cleared once done (accounts.mjs).
CREATE TABLE IF NOT EXISTS erasures (
  store TEXT NOT NULL CHECK (store IN ('replays', 'bundles', 'lists')),
  hash  TEXT NOT NULL,
  PRIMARY KEY (store, hash)
);

-- 5.6's law slots: what each realm's slot holds, and the crown's as realm
-- 'crown' (weaving.mjs). A law weaves until ready_at, at the tier the Codex
-- has it; an emptied slot rests until rests_until.
CREATE TABLE IF NOT EXISTS law_slots (
  owner       TEXT NOT NULL REFERENCES accounts(id),
  realm       TEXT NOT NULL,
  slot        INTEGER NOT NULL CHECK (slot >= 1),
  law         TEXT,
  tier        INTEGER CHECK (tier BETWEEN 1 AND 3),
  ready_at    INTEGER,
  rests_until INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (owner, realm, slot)
);

-- A bundle an under-13 deletion erased, still to be purged from the edge's
-- cache (20.11; edge.mjs): its path, and when to ask again. Deleted when the
-- edge confirms.
CREATE TABLE IF NOT EXISTS edge_purges (
  path      TEXT PRIMARY KEY,
  queued_at INTEGER NOT NULL,
  attempts  INTEGER NOT NULL DEFAULT 0,
  due_at    INTEGER NOT NULL
);

-- First-party telemetry (§24, §24.3; telemetry.mjs). Keyed by a pseudonym,
-- never an account (§20.5), and discarded after 90 days: not append-only,
-- because §24.3 says the raw events go. §24.1: "Telemetry is batched rather
-- than written per event", so a row is a batch — a player's events of a
-- day, appended to (telemetry.write) — and events is the view that reads it
-- event by event. Its at is when the row was started; a batch's day is its
-- earliest event's, which compaction goes by.
CREATE TABLE IF NOT EXISTS event_batches (
  id     INTEGER PRIMARY KEY AUTOINCREMENT,
  who    TEXT NOT NULL,
  at     INTEGER NOT NULL,
  day    TEXT NOT NULL,
  events TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS event_batches_by_day ON event_batches (day);
CREATE INDEX IF NOT EXISTS event_batches_by_who ON event_batches (who);
CREATE VIEW IF NOT EXISTS events AS
  SELECT b.id AS batch, b.who, json_extract(e.value, '$.kind') AS kind,
         json_extract(e.value, '$.data') AS data, json_extract(e.value, '$.at') AS at,
         strftime('%Y-%m-%d', json_extract(e.value, '$.at') / 1000, 'unixepoch') AS day
    FROM event_batches b, json_each(b.events) e;

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
  day30   INTEGER NOT NULL,
  -- G29: day-60 returns; null for a cohort written before they were kept.
  day60   INTEGER
);
CREATE TABLE IF NOT EXISTS event_days (
  day     TEXT NOT NULL,
  kind    TEXT NOT NULL,
  events  INTEGER NOT NULL,
  players INTEGER NOT NULL,
  PRIMARY KEY (day, kind)
);
`;

/** Columns a table no longer has: the fixed UTC offset the time zone
 *  replaced (G34), which a daylight-saving change made wrong. */
const DROPPED = [
  ["accounts", "utc_offset"],
  // Settled is the heist row's to say (service.issue).
  ["leases", "state"],
];

/** Columns added to a table after a database was first made: `CREATE TABLE IF
 *  NOT EXISTS` leaves an old table as it was, so each is added if missing. */
const ADDED = [
  // §18.9: a creator's opting in to the Island Fund (fund.mjs).
  ["accounts", "fund_opt_in", "INTEGER NOT NULL DEFAULT 0"],
  // §17.6's invite gift (friends.mjs): which of a pair shared the invite the
  // other accepted, and when the matching cosmetic was given.
  ["friends", "invited_by", "TEXT"],
  ["friends", "gift_at", "INTEGER"],
  // §13.3's curation (curation.mjs): an island's origin, and for a layout
  // the generator made, its seed and its terrain's digest; the name its
  // owner gave it from the word lists.
  ["islands", "origin", "TEXT"],
  ["islands", "seed", "TEXT"],
  ["islands", "terrain", "TEXT"],
  ["islands", "name_adjective", "INTEGER"],
  ["islands", "name_noun", "INTEGER"],
  ["snapshots", "origin", "TEXT"],
  ["accounts", "age_band", "TEXT NOT NULL DEFAULT '18+'"],
  ["accounts", "moderator", "INTEGER NOT NULL DEFAULT 0"],
  ["accounts", "banned_at", "INTEGER"],
  ["accounts", "banned_reason", "TEXT"],
  // The cosmetics a player wears, slot by slot (shop.mjs).
  ["accounts", "equipped", "TEXT NOT NULL DEFAULT '{}'"],
  ["standings", "tier_stars", "INTEGER"],
  ["accounts", "analyst", "INTEGER NOT NULL DEFAULT 0"],
  ["accounts", "deleted_at", "INTEGER"],
  ["accounts", "deleted_reason", "TEXT"],
  ["accounts", "seeded", "INTEGER NOT NULL DEFAULT 0"],
  ["accounts", "time_zone", "TEXT"],
  ["accounts", "reminder_at", "INTEGER"],
  ["accounts", "night_quiet", "INTEGER NOT NULL DEFAULT 1"],
  ["accounts", "push_token", "TEXT"],
  // §14.2's experience toward the next Keeper level (keeper.mjs).
  ["accounts", "keeper_xp", "INTEGER NOT NULL DEFAULT 0"],
  // §7.6's "a law you are actually working on" (codex.mjs).
  ["accounts", "working_on", "TEXT"],
  // §11.7's guardian Sage, stationed at the Heart (keeper.mjs).
  ["accounts", "guardian_sage", "TEXT"],
  ["accounts", "defences_seen_at", "INTEGER"],
  ["accounts", "profile_public", "INTEGER NOT NULL DEFAULT 0"],
  ["accounts", "keeper_adjective", "INTEGER"],
  ["accounts", "keeper_noun", "INTEGER"],
  // The terms of use accepted (safety.mjs).
  ["accounts", "terms_version", "TEXT"],
  ["heists", "replay_gone", "INTEGER NOT NULL DEFAULT 0"],
  ["leases", "echo", "INTEGER NOT NULL DEFAULT 0"],
  ["leases", "trace_of", "TEXT"],
  ["leases", "mode", "TEXT NOT NULL DEFAULT 'raid'"],
  ["leases", "challenge", "TEXT"],
  ["leases", "era", "INTEGER NOT NULL DEFAULT 0"],
  ["leases", "universe", "TEXT"],
  ["target_lists", "previous", "TEXT"],
  ["target_lists", "superseded_at", "INTEGER"],
  ["notifications", "attempts", "INTEGER NOT NULL DEFAULT 0"],
  ["cohorts", "day60", "INTEGER"],
  ["purchase_intents", "recipient", "TEXT REFERENCES accounts(id)"],
  ["purchases", "recipient", "TEXT REFERENCES accounts(id)"],
  // A character away on a heist and resting after it (home.mjs).
  ["characters", "form", "TEXT"],
  ["characters", "name_adjective", "INTEGER"],
  ["characters", "name_noun", "INTEGER"],
  ["characters", "away_from", "INTEGER"],
  ["characters", "away_until", "INTEGER"],
  // Where a building stands (universe.mjs `place`).
  ["buildings", "x", "INTEGER"],
  ["buildings", "y", "INTEGER"],
  // §18.5's mastery steps (codex.mjs).
  ["codex", "woven_at", "INTEGER"],
  ["codex", "crossed_at", "INTEGER"],
];

/** A ledger of a row a currency — and one made while there was Starglass —
 *  is rebuilt around its rows as a row a player an event with both
 *  currencies: the append-only triggers forbid changing a row, not moving
 *  them. Each old row moves as it was, one currency set, and its haul or
 *  defence share counted to the caps as before. Starglass rows are not
 *  moved: the owner answered F41 with no currency, and what was paid is in
 *  `purchases`, the record of money. */
function ledgerByCurrency(db) {
  const old = db.prepare("SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'ledger'").get();
  if (!old || !/\bcurrency\b/.test(old.sql)) return false;
  db.exec(`DROP TRIGGER IF EXISTS ledger_append_only_update;
           DROP TRIGGER IF EXISTS ledger_append_only_delete;
           DROP INDEX IF EXISTS ledger_by_account;
           ALTER TABLE ledger RENAME TO ledger_by_currency;`);
  return true;
}

/** A ledger made before Aether (§9.3's Aether Springs) is rebuilt with the
 *  column, each row moving as it was: its check names the currencies, and
 *  SQLite cannot change a check in place. */
function ledgerWithoutAether(db) {
  const old = db.prepare("SELECT sql FROM sqlite_master WHERE type = 'table' AND name = 'ledger'").get();
  if (!old || /\baether\b/.test(old.sql) || /\bcurrency\b/.test(old.sql)) return false;
  db.exec(`DROP TRIGGER IF EXISTS ledger_append_only_update;
           DROP TRIGGER IF EXISTS ledger_append_only_delete;
           DROP INDEX IF EXISTS ledger_by_account;
           ALTER TABLE ledger RENAME TO ledger_before_aether;`);
  return true;
}

export function open(path = ":memory:") {
  const db = new DatabaseSync(path);
  // Set here, as SCHEMA's own pragma does nothing inside a transaction.
  db.exec("PRAGMA foreign_keys = ON");
  // The one-time migrations and the schema in one transaction (SQLite's DDL
  // is transactional): an upgrade stopped part-way — a crash, a lock, a copy
  // that throws — leaves the old shape whole to be migrated on the next
  // open, never a new empty ledger beside the old rows (§24.12).
  transaction(db, () => {
    // The added columns first, so an old accounts table has them before the
    // schema's indexes and triggers are checked against it.
    const has = (table) => db.prepare(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?").get(table);
    for (const [table, column, type] of ADDED) {
      if (has(table) && !db.prepare(`PRAGMA table_info(${table})`).all().some((c) => c.name === column)) {
        db.exec(`ALTER TABLE ${table} ADD COLUMN ${column} ${type}`);
      }
    }
    // A lease's state was written when its heist settled; now its heist row
    // says so, and the index that read the state goes before the column.
    // The heists' index that held whether each was validated is remade
    // without it.
    db.exec("DROP INDEX IF EXISTS one_open_lease_per_target; DROP INDEX IF EXISTS heists_by_day");
    for (const [table, column] of DROPPED) {
      if (has(table) && db.prepare(`PRAGMA table_info(${table})`).all().some((c) => c.name === column)) {
        db.exec(`ALTER TABLE ${table} DROP COLUMN ${column}`);
      }
    }
    const rebuilt = ledgerByCurrency(db);
    const aethered = ledgerWithoutAether(db);
    // Telemetry written before batching, a row an event: moved aside, and
    // poured into batches of one once the schema stands.
    const unbatched = db.prepare("SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'events'").get();
    if (unbatched) {
      db.exec(`DROP INDEX IF EXISTS events_by_day; DROP INDEX IF EXISTS events_by_who;
               ALTER TABLE events RENAME TO events_before_batches;`);
    }
    db.exec(SCHEMA);
    if (unbatched) {
      db.exec(`INSERT INTO event_batches (who, at, day, events)
                 SELECT who, at, day, json_array(json_object('kind', kind, 'data', json(data), 'at', at))
                   FROM events_before_batches ORDER BY id;
               DROP TABLE events_before_batches;`);
    }
    // A ban made before the bans table was held on the account's identity,
    // and kept it even once the account was deleted: the ban moves to the
    // identity, to the day; a deleted account's row is severed like anyone's
    // and keeps no ban time to match it back by; and a banned player's
    // friendships and invites end, as a ban now ends them (accounts.mjs).
    db.exec(`INSERT OR IGNORE INTO bans (identity, banned_at, reason)
               SELECT platform_identity, banned_at - banned_at % 86400000, banned_reason FROM accounts
                WHERE banned_at IS NOT NULL AND platform_identity NOT LIKE 'deleted:%';
             UPDATE accounts SET platform_identity = 'deleted:' || id, banned_at = NULL, banned_reason = NULL
              WHERE deleted_at IS NOT NULL AND (platform_identity NOT LIKE 'deleted:%' OR banned_at IS NOT NULL);
             DELETE FROM friends WHERE a IN (SELECT id FROM accounts WHERE banned_at IS NOT NULL)
                                    OR b IN (SELECT id FROM accounts WHERE banned_at IS NOT NULL);
             DELETE FROM friend_invites WHERE account IN (SELECT id FROM accounts WHERE banned_at IS NOT NULL);`);
    if (aethered) {
      db.exec(`INSERT INTO ledger (id, account, starlight, essence, paid, reason, heist, at)
                 SELECT id, account, starlight, essence, paid, reason, heist, at FROM ledger_before_aether;
               DROP TABLE ledger_before_aether;`);
    }
    if (rebuilt) {
      db.exec(`INSERT INTO ledger (id, account, starlight, essence, paid, reason, heist, at)
                 SELECT id, account,
                        CASE currency WHEN 'starlight' THEN amount ELSE 0 END,
                        CASE currency WHEN 'essence' THEN amount ELSE 0 END,
                        CASE WHEN reason = 'haul (9.6)' OR reason LIKE '%of what a foiled crew carried (9.4)'
                             THEN amount ELSE 0 END,
                        reason, heist, at FROM ledger_by_currency
                  WHERE currency IN ('starlight', 'essence') AND amount != 0;
               DROP TABLE ledger_by_currency;`);
    }
  });
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
