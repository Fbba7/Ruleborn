# What the database costs, and what was cut (T13)

The server's database, measured the way D1 bills it (rows written with their
index entries, rows read as rows scanned), before and after this track's
changes, priced on §28.3's D1 source. Every change keeps the design's rules:
the ledger, Renown and season stars stay append-only, snapshots are never
edited, a heist is still its own rating period (§12.22), and every cap,
count and freshness the server had it still has. Where a further cut would
change a rule, it is an owner option below, with its numbers; none of those
is made.

## The result

`node server/load.mjs` plays 60 players of each archetype (§14.1) for three
days through the real service and simulation. "Before" is the server as it
was (commit `f8adf28`) under the same load test; "after" is this branch.

| A player a day | Engaged | Regular | Casual |
| --- | ---: | ---: | ---: |
| Billed rows written, before (as `load.json` had it) | 86.15 | 48.44 | 27.53 |
| Billed rows written, before (this load test) | 77.49 | 41.79 | 21.24 |
| Billed rows written, after | **61.74** | **33.81** | **17.47** |
| Rows written as SQLite counts them, before / after | 52.1 / 42.2 | 28.2 / 23.2 | 13.8 / 11.5 |
| Rows read, before (day 3) | 7,261 | 2,639 | 938 |
| Rows read, before, by day 14 | 60,216 | 16,118 | 3,960 |
| Rows read, after (day 3) | **950** | **357** | **145** |
| Target lists, rows read a day an island, before / after | 170 / 147 | 170 / 147 | 170 / 147 |

A player's first heist, once in all (its roster and Codex): 37.2 billed rows
before, 34.2 after.

The two "before" lines differ by what the load test now plays: the screens a
session reads (the Observatory before each heist, the raid badge each session,
the defence log once a day), and each player's first heist a week before the
measured days, as the harness already treated a player's first session.
Billed writes fall 20% engaged, 19% regular and 18% casual against the same
load; 28%, 30% and 37% against the old `load.json`. A heist that scores
everything for both players (`cost.test.mjs`) bills 15 rows with its lease,
from 23.75: the load test's drawn crews are mostly foiled at Renown's floor,
so the Renown fold below shows only there. Reads fall 87%, 86% and 85%, and
stop growing with a player's history: before, an engaged player read 3,878
rows on day 1, 10,684 on day 3 and 60,216 on day 14, as the raid badge, the
defence log and the Trace read every lease ever issued; after, 667, 977 and
1,205 on days 1 to 3, the week's raids filling up, and the 14-day run rises
and falls with the week (numbers below, "Growth").

### What it costs a month

§24.1's arithmetic: a third of monthly players play on a day (§25.1); monthly
writes are players × ⅓ × billed rows a day × 30, at $5 a month with 50 million
included, then $1 a million; reads the same way with 25 billion included,
then $0.001 a million, the target lists' reads counted for one island a
monthly player (§28.3's D1 source).

| Monthly players | 1,000 | 10,000 | 1,000,000 |
| --- | ---: | ---: | ---: |
| Writes a month, engaged before → after | 0.8M → 0.6M | 7.7M → 6.2M | 775M → 617M |
| Writes a month, casual before → after | 0.2M → 0.2M | 2.1M → 1.7M | 212M → 175M |
| Reads a month, engaged before (day 3) → after | 0.08B → 0.01B | 0.8B → 0.1B | 78B → 14B |
| **Cost a month, engaged**, before → after | $5 → $5 | $5 → $5 | **$783 → $572** |
| **Cost a month, regular**, before → after | $5 → $5 | $5 → $5 | **$380 → $293** |
| **Cost a month, casual**, before → after | $5 → $5 | $5 → $5 | **$167 → $130** |

At a million monthly players the before figures are writes ($730, $373,
$167) and reads at a player's third day ($53, $7, $0); by a player's
fourteenth day the reads alone were $582, $141 and $20 a month and rising.
After, every archetype's reads sit inside the 25 billion included. Against
the old `load.json`'s $817 at a million engaged players, the after figure is
$572; §24.1's table says "about $60 to $615".

1,000 and 10,000 monthly players cost the $5 plan either way: §24.1 needs it
from the first heist for validation's CPU. On the free plan's limits alone
(5 million reads and 100,000 writes a day), the after figures carry 1,619
engaged or 5,724 casual daily players on writes, where before they carried
1,290 and 4,708; reads carry 4,561 and 17,170.

### What the 60-player test cannot show

Some reads before grew with the whole population, not the player. The load
test lists each request's statements that read a table whole (`scans` in
`load.json`); before, at 60 players:

| Request | Read whole | What it costs at a million monthly players |
| --- | --- | --- |
| Raid badge, defence log, Trace | every lease ever issued (no index on the defender) | about 40 million rows a call a month in; five badge calls a day an engaged player |
| Observatory | every island and every account, twice, to see if anything changed | 3 million rows a view |
| Observatory | every snapshot ever published, for the echoes | every snapshot, at each rebuild |

After, none of these is a whole read: the raids on a player are a range of
`heists_by_defender`, the staleness check is three index rows, the echoes a
range of `snapshots_by_published`. The one whole read left is the
Observatory's candidate list, rebuilt from every island when it is a minute
old or when an island changes (SR-03); it is owner option 1 below.

## How it is measured

- **Writes** (`billed()` in `server/load.mjs`): each changed row, and an entry
  for every index an insert or delete writes or an update's SET touches, as
  D1's pricing says ("Indexes will add an additional written row when writes
  include the indexed column"). A table keyed by its text primary key without
  a rowid has no separate key index; a partial index is written only for the
  rows it holds.
- **Reads** (`reads()`, new): D1 bills rows scanned, not returned, and SQLite
  keeps no such count where node can see it. Each statement is run a second
  time against counting views (`__r_t`, `SELECT rowid, * FROM t WHERE
  __seen(rowid)`) that the planner flattens into the same loops on the same
  indexes, so the function is called once for each row a loop lands on: a
  scan counts its table, a search its range, an aggregate every row it sums,
  a correlated subquery each time it runs, and a LIMIT that stops a loop stops
  the count. `server/test/db_reads.test.mjs` holds it to each kind of loop,
  and to every statement a heist and a target-list rebuild run: the counted
  copy's loops are the statement's own. Not counted: the reads SQLite makes
  of a key on a write (a unique index, a foreign key), which D1 may bill too.
- `load.json` now carries, for each archetype, `readsPerPlayerDay`,
  `readsPerPlayerByDay`, `readsByOperation`, `periodicReadsADayAnIsland`,
  `readsBySql` (the statements that read most), `scans`, `billedByTable` and
  `firstHeist`; `against` adds the reads budget (§24.1's 2,500 a player a
  day: 0.37, 0.14 and 0.05 of it after) and the reads' dollars a month.
  `--check` still fails when the writes move.

## The write cuts

Engaged billed rows a day, against the same load test (77.49 before):

| Change | Rows a day | Rule kept | Test |
| --- | ---: | --- | --- |
| Leases and heists keyed by their token without a rowid: the key's index is the table, one entry fewer a lease and a heist | −8.0 | §24.13's one lease a target: the newest lease is the last issued, as a lease is never issued at the moment of the one before | `db_keyed.test.mjs` |
| A heist's row written once, last, validated and with its outcome, not written and then marked: the ledger's, Renown's and the stars' rows name the heist plainly, so a parent written after them has no table to search | −4.0 | Fee and reward in one transaction (§24.13); the ledger append-only | `cost.test.mjs` |
| A heist's season stars and Renown ride the one ledger row the heist books each player: both are §9.1's currencies, and a heist that moves only them books a ledger row of them alone; the season-stars table keeps tiers bought | −3.7 (and −4 a scoring heist) | Stars and Renown as append-only events, reset and pulled back each season (§18.2, §12.9); Ember's floor | `db_writes.test.mjs`, `db_totals.test.mjs`, `cost.test.mjs` |
| The raider's Glicko-2 state on their account row, written in the UPDATE the heist's Keeper experience already makes, with the raids count | −4.0 | A heist is its own rating period (§12.22); a deletion clears it | `db_writes.test.mjs` |
| A defence log read with no raid new since the last read writes nothing | small | The raid badge's count unchanged | `db_writes.test.mjs` |
| Added for the reads: a heist's defender (`heists_by_defender`) | +4.0 | | |
| Added for the reads: a player's waiting raids (`notifications_waiting`, partial): its entry written with the day's first raid and taken away when the message goes | +2 a raided player's day (the load test sends no notifications, so shows none of it) | | |

Per heist with its lease, the scoring heist `cost.test.mjs` plays now bills
15 rows (23.75 before), and its ceiling is lowered to 15.

## The read cuts

| Change | What it read | What it reads |
| --- | --- | --- |
| Running totals written with each ledger, Renown and season-stars row (a cache the rows rebuild: each total is the sum of the rows to it) — §24.8's running Renown total, kept on the rows rather than on the standing, so it costs no row written | every row the player was ever booked, for each balance; every Renown or stars row of the season | the newest row |
| `heists.defender` and `heists_by_defender (defender, submitted_at)` | every lease ever issued, for the raid badge, the defence log, the Trace, the Profile's raids | that player's raids in the range |
| The raid badge counts the raids since the log was read | the season's every raid and report, five times a day | the new raids |
| The week's raids and Renown heists counted from Monday's `day`, which `heists_by_attacker` holds | every heist the raider played | the week's |
| The pair's earlier heists of the day by the heist's own attacker, day and defender | every lease the raider took | the day's heists |
| §7.6's floor counts the raider's raids on their row, carried in the experience's UPDATE | every heist the raider played, on every heist | one row |
| A player's events of a day from the batches started since it (`event_batches_by_who_at`) | the player's 90 days of batches | a day's |
| The waiting raided notification by its player (`notifications_waiting`) | every unsent notification of every player, on every raid | one row |
| A Trace's lease by the robbery it answers (`leases_by_trace`, partial: only Trace leases write it) | every lease, for each robbery checked | one entry |
| The candidates' staleness from three index rows (`islands_by_change`, `accounts_banned`, `accounts_deleted`; the last two partial, written only on a ban or a deletion) | every island and every account twice, on each Observatory view | three rows |
| The echoes from the last 14 days' snapshots (`snapshots_by_published`) | every snapshot ever published | 14 days' |
| The candidates and the target lists read every island in one joined query: its snapshot, owner, rating, standing, newest Renown row and newest ledger row | seven reads an island and every Renown row of its owner's season | six rows an island |
| The Observatory reads the raider's week and Starlight once for all its cards | each card's | once |
| The raider's recent raids read newest day first | every raid the raider played, sorted | the last days' |

`server/test/db_reads.test.mjs` holds each to its index, and holds the load
test's day to no whole-table read but the candidates' rebuild;
`db_totals.test.mjs` holds a heist day's reads flat over ten weeks of history
(the old server's doubled).

## The migrations

`open()` moves a database from the schema before this branch, in its one
transaction:

- Columns added (null on old rows, which are summed or counted once and then
  carried on): ledger totals and stars, Renown and stars totals, a heist's
  defender (filled from its lease), an account's raids and raider rating (the
  rating moved from `ratings`, none left behind).
- Leases and heists made again without a rowid, every row moved; the ledger,
  Renown and season stars made again without the foreign key to the heist,
  every row moved, their append-only triggers made again. The foreign keys are
  off for the move, as SQLite needs to make again a table others name, and
  every key is checked before it commits.
- Indexes made; the events view made again with each batch's start.
- Its cost, once: every row of those five tables written again, and an entry
  for each in each new index; on a database the size of a soft launch's, a
  few dollars of writes at most.

`db_totals.test.mjs` and `db_keyed.test.mjs` open a database as the old
server left it and check every row's columns, the balances, the defence log,
the foreign keys and the append-only triggers, then play on it. And once by
hand, a database the old server itself wrote (commit `f8adf28`: two players
raiding each other for five days, books, tier claims, a lease held), opened
by this one: every balance, the Aether, both players' Renown and stars and
the defence log read the same; every foreign key holds; the held lease is
handed back; and a raid played on it books totals that carry the old rows.

## Owner options (each changes a rule; none is made)

1. **The Observatory from the hourly list.** §24.8: "Target selection is a
   file, not a query." The Observatory still makes its candidates from every
   island when they are a minute old or any island changes (SR-03), about six
   rows an island, in each server instance. At a million islands that is 6
   million rows a rebuild; with a publish somewhere every second, about one
   rebuild a view in each instance. Serving it from the hourly target lists,
   with a republished island's card swapped to its current snapshot and a
   banned owner's taken out at the view, reads a few rows a view; a new island
   would appear within the hour, as on the lists. At a million monthly
   players, 1.3 million views a day, the rebuilds are on the order of 8
   trillion rows a day if every view rebuilds, $240,000 a month; the list,
   about $0.
2. **A day as the rating period** instead of a heist (§12.22: "A heist is
   its own rating period"). Glicko-2 is defined over periods; one a day writes
   each rated island once a day (the raider's rating now rides the row the
   heist writes anyway): an island raided four times a day writes its rating
   once, −3 a day engaged (−$30 a month at a million monthly players).
3. **The heist's telemetry event from the heist's row.** Each heist appends
   its event to the player's batch: 4 rows a day engaged. The report could
   count heists from the `heists` table instead, which is kept anyway; the
   batch is pseudonymous and the heist row is not, so it is the owner's call
   (§24.3, §20.5). −4 a day engaged.
4. **A raid notification that names the day's raids by reference.** Each raid
   after the first rewrites the waiting notification's list: about 3 rows a
   day for a player raided four times. The list can be read at send time from
   `heists_by_defender`; the notification tests notify for heists that are not
   in the table, so they would play real ones. −3 a day for a raided player.
5. **AUTOINCREMENT dropped on the append-only tables.** The ledger, Renown,
   stars, notifications and event batches update `sqlite_sequence` on each
   insert; a plain integer key behaves the same for a table nothing is deleted
   from. Whether D1 bills that row is to be read on the edge run before soft
   launch; if it does, about 8 rows a day engaged.
6. **The telemetry day index.** `event_batches_by_day` costs a row a player a
   day for the daily compaction's range; without it compaction reads every
   batch, about 90 rows a player, once a day: a write traded for reads at a
   thousandth of the price, if one compaction query that size runs on the
   edge platform.
7. **§24.1's five writes.** After these cuts an engaged day bills 62 rows:
   heists 12, the ledger 12, telemetry 11, leases 8, sessions 5, the account
   row 5, notifications 4, ratings 4, the Codex 1. Five a
   day would need every heist's records folded into one row and the ratings
   moved to a daily period (options 2 and 3), as `docs/decisions/brief.json`
   costs it.

## Sign-in and sessions (not changed)

Left as they are, as this track was asked. A refresh writes its session row
on every use, rotating its generation: 7 billed rows a day engaged, 11% of
the day after these cuts. What I would change there: rotate only when the
token is older than an interval (T11's `RULEBORN_REFRESH_ROTATE_HOURS`,
86.15 against 82.48 before these cuts, `docs/progress/T11.md`), and write the
session's `used_at` and `place` only when they move by more than the devices
list shows (an hour, a country), so a refresh inside the interval writes
nothing. The day's `sign_in` event is already written once a day.

## Growth

A 14-day run, the same 60 players (`node server/load.mjs --days 14`):

| Rows read a player a day | Engaged | Regular | Casual |
| --- | ---: | ---: | ---: |
| Before, mean of 14 days | 30,535 | 8,529 | 2,294 |
| Before, day 14 | 60,216 | 16,118 | 3,960 |
| After, mean of 14 days | AFTER14_E | AFTER14_R | AFTER14_C |
| After, day 14 | AFTER14D_E | AFTER14D_R | AFTER14D_C |
