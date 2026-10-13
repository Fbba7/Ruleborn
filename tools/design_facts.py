#!/usr/bin/env python3
"""Facts the design document states, in one place, for the tools that read them.

    python3 tools/design_facts.py          # every fact, its value and its home

Why this exists
---------------
§31.4 pins four constants in the document's own data — tick rate, law count,
crew size, page total — and the build checker verifies them against the prose.
That rule stops at the document. One level out, in the tools that check it,
eleven more of the document's facts were each written down two to four times.

The worst are not the repeats. They are the disagreements:

  * `SETTLED` had four homes and `build_roadmap`'s was missing `withdrawn`,
    so a withdrawn item counted as open on the roadmap and settled everywhere
    else.
  * `HOLD_BAND` had four, as `(30.0, 45.0)` in three and `(30, 45)` in the
    fourth.
  * `CREW` meant the range 3-to-5 in one tool and the number 5 in another —
    the same name for two facts, which is worse than the same fact twice.

And the repeats that agree are worse than they look, because **four of them
restate data this repository has already extracted**. `content/notes.json`
carries the eight notes and their oppositions; `content/roles.json` carries the
five roles. Four tools typed the notes out again and four typed the roles.

So: derived from `content/` where the extraction already exists, declared with
the section that owns it where it does not, and
`check_docs_consistency.check_one_fact_home` refuses a second copy.
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"


def _load(name: str) -> list:
    return json.loads((CONTENT / f"{name}.json").read_text(encoding="utf-8"))


# -- derived: the extraction already exists, so nothing is typed twice -------

#: §8.1's eight notes, in the document's own order.
NOTES = tuple(n["name"] for n in _load("notes"))

#: §8.1's oppositions. A law may not carry a note and its opposite, and a chord
#: needs three notes none of which are opposites (§8.5).
OPPOSITE = {n["name"]: n["opposite"] for n in _load("notes")}

#: §11.1's five role names. Named for what it is: `heist_harness.sim.ROLES`
#: is the full stats table read from the same file, and one name for two facts
#: is worse than one fact in two places.
ROLE_NAMES = tuple(r["name"] for r in _load("roles"))

#: §7's six schools, read off the 48 law sheets rather than listed again.
SCHOOLS = tuple(dict.fromkeys(law["school"] for law in _load("laws")))


# -- declared: stated in prose, with the section that owns each -------------

#: §13.2. How often a defence should hold: "Below a quarter, defenders feel
#: helpless and stop designing. Above half, raiding feels futile."
HOLD_BAND = (30.0, 45.0)

#: §12.6. "roughly one every 8 to 12 seconds, or 15 to 25 in a run."
DECISION_BAND = (15, 25)
DECISION_SECONDS = (8, 12)

#: §12.6: "each ruleborn's ability has two uses a heist, with a lockout of one
#: decision slot (10 seconds) between them", and "At most four abilities are
#: ready at once".
ABILITY_LOCKOUT_SECONDS = 10
ABILITIES_READY = 4

#: §11.7: "After using any power the Sage cools down for 20 seconds before it
#: can use another".
SAGE_COOLDOWN_SECONDS = 20

#: §12.5. Three characters, four from Keeper level 8, five from level 16.
CREW_RANGE = (3, 5)

#: §5.2 (v3.7): wards and guard posts by realm level 1 to 5, "a measured
#: budget, not a formula", re-measured with every recorded answer built: "8, 8,
#: 6, 2 and 0" wards on 1, 1, 2, 1 and 1 posts. v3.3 to v3.6 shipped 8, 8, 6, 7,
#: 8 on 1, 1, 2, 3, 3; v3.2's were 3 + realm level and 1 + (level - 1) // 2.
WARD_LIMITS = (8, 8, 6, 2, 0)
GUARD_POSTS = (1, 1, 2, 1, 1)
#: §10.1: "Most are 2 by 2 tiles; the Spire and Vault are 3 by 3": the side of
#: most buildings' footprints, and the Spire's and the Vault's.
BUILDING_FOOTPRINTS = (2, 3)
#: §12.17 (v3.7), "A realm’s watch": "at realm level 1 suspicion fills at 0.6
#: of the rates above; at level 2 every zone reaches 0.75 as far, and at level 3
#: 0.7 as far; from level 4 guards see and notice at full strength". (suspicion
#: fill, sight) by realm level 1 to 5; §5.2 tunes the budget with it.
REALM_WATCH = ((0.6, 1.0), (1.0, 0.75), (1.0, 0.7), (1.0, 1.0), (1.0, 1.0))
#: §5.2's law slots by realm level, from its "Outer realm levels" table.
LAW_SLOTS = (1, 1, 2, 2, 3)
#: §5.2: "Outer realms open at Keeper levels 3, 6, 10, 15, 21 and 28", the
#: nth realm at the nth level.
REALM_KEEPER_LEVELS = (3, 6, 10, 15, 21, 28)
#: §5.2's six outer realm types, in its table's order; "the player picks each
#: one's type from those not yet owned".
REALM_TYPES = ("Skyfield", "Crystalline", "Tidehold", "Emberreach", "Verdant", "Lantern Vale")
#: §5.2's "Needs" column: the Spire level a realm needs to open (level 1) and
#: to rise to each level after it.
REALM_LEVEL_SPIRE = (1, 3, 5, 7, 9)
#: §9.5's price list: "Opening an outer realm | 2,000 Starlight"; "Realm
#: levels 2 to 5 | 6,000, 20,000, 55,000 and 140,000 Starlight".
REALM_OPEN_COST = 2_000
REALM_LEVEL_COSTS = (6_000, 20_000, 55_000, 140_000)
#: What a new universe's Heart holds, by §10.2's building ids, each at level
#: 1: the economy model's start, which §9.3's production and §14's curves are
#: run from. §9.6 (v3.7, F56): "A new universe starts with the Heart and, at
#: level 1 in it, the Keeper’s Spire, the Vault, a Star Well, an Aether Spring,
#: a Garden and a Hearth … This is the one place that states it".
STARTING_HEART = ("keeper_s_spire", "vault", "star_well", "aether_spring", "garden", "hearth")

#: §12.8 and §12.20. One hit every 0.8 seconds for damage equal to Power, on
#: both sides. The 0.8 is the only cadence the document states.
WIND_UP = 0.8

#: §12.8 (v3.3): the first hit on an Unaware guard is a knockout "after a 2 s
#: takedown" (§29.1). v3.2's triple Power and half-health floor are gone.
TAKEDOWN_SECONDS = 2

#: §11.1 (v3.3): "While two or more characters work the same object, every
#: hit on it deals 25% more: the assist bonus."
ASSIST_BONUS = 0.25

#: §10.3 (v3.3): "The disarmer stands on the ward's tile for 15 seconds at
#: every ward level".
DISARM_SECONDS = 15

#: §12.6. The Vault's health, per Vault level.
VAULT_HEALTH_PER_LEVEL = 1_500

#: §12.6: "Breakers deal double damage to it."
BREAKER_VAULT_MULTIPLIER = 2

#: §10.3 (v3.3; one value since v3.4, C34): "Every ward has 550 health a
#: level", the smallest multiple of 50 at which smashing a level-2 ward loses
#: to a Tinker's disarm.
WARD_HEALTH_PER_LEVEL = 550

#: §12.19: "Every role can load, at 30 units a second."
LOAD_PER_SECOND = 30

#: §11.1, the Carrier: "15% slower when loaded".
CARRIER_LOADED_PACE = 0.85

#: §12.20: "has ten seconds before capture. An ally standing adjacent revives
#: it in 3 seconds, a Mender in 1.5, and it returns at 30% of its full health"
#: (v3.3, G14).
DOWN_SECONDS = 10
REVIVE_SECONDS = 3.0
MENDER_REVIVE_SECONDS = 1.5
REVIVE_HEALTH = 0.30

#: §12.17 (v3.3, G13): "crouched, a crew member moves at half its role's
#: speed (11.1), and running, at double".
CROUCH_PACE = 0.5
RUN_PACE = 2.0

#: §5.4: the skiff "takes 5 seconds to reach an outer realm and 20 seconds to
#: fight the winds around the Heart".
SKIFF_OUTER_SECONDS = 5
SKIFF_HEART_SECONDS = 20

#: §5.4: "A landing skiff can be heard: guards within 6 tiles of the landing
#: spot start at 250 of 1,000 suspicion (12.17), unless the spot is in fog,
#: darkness or tall grass."
LANDING_HEARD_TILES = 6
LANDING_SUSPICION = 250

#: §12.9's grades, as the value each is worth when a run is scored.
GRADE_VALUE = {"clean": 1.0, "loud": 0.7, "partial": 0.4, "foiled": 0.0}

#: §9.6, what a raid pays: "Haul = B(V) × grade × difficulty × richness ×
#: fatigue × fill", with "B(V), the base — 2,400 × 1.5^(V−1)" keyed to the
#: target's Vault level; fatigue "0.85 on each successive raid that day";
#: richness "clamped between 0.6 and 1.8, with a reduction above 1.5" (the
#: excess halved); difficulty "Level or above 1.0 to 1.2, one below 0.8, two
#: below 0.5, three or more below 0.25". The server and the economy model both
#: mint from these. The base is the owner's (F36): the smallest hundred at
#: which §9.6's raid-worth check holds on every day at every Vault level, with
#: the fee an attempt keeps inside it (F39) — 5,000, which v3.7 states (F53
#: for why not F36's 4,600).
HAUL_BASE = 5000
HAUL_GROWTH = 1.5
HAUL_FATIGUE = 0.85
RICHNESS_CLAMP = (0.6, 1.8, 1.5)
#: §9.6 (v3.7, G17 A): "same level 1.0, one above 1.1, two or more above 1.2;
#: one below 0.8, two below 0.5, three or more below 0.25". Kept as (same level,
#: cap above, one below, two below, three or more below): the server steps 0.1 a
#: Keeper level up to the cap, which is the 1.1 the document states one above.
DIFFICULTY = (1.0, 1.2, 0.8, 0.5, 0.25)
#: §9.6's band: "an attempt is worth 12% to 17% of a clean same-level haul —
#: 0.1222 for a crew that stops at a fixed 70% fill and 0.1698 for one that
#: reads the guards". Expected grade times fill over every attempt, foiled ones
#: included, so it replaces both the old 0.46 and the fill term. The lower edge
#: prices the raid-worth check; the full re-run publishes at both edges (14.2).
ATTEMPT_BAND = (0.1222, 0.1698)

#: §9.5's roster's keep: "25% of Essence production, taken as it is collected
#: and never from stock". It ships at a quarter until the sink search sets it
#: (32.9); the economy model charges it.
ROSTER_KEEP_SHARE = 0.25

#: §9.5's birth price: "100 × 1.3455^ruleborn owned Essence, where owned is
#: n − 1 for the nth birth" — the base and the growth.
BIRTH_PRICE = (100, 1.3455)
#: §7.6, "the home of the page costs": "Restoring a law: 10, 20, 35 or 60
#: pages by rank" — common, uncommon, rare, deep.
PAGE_COSTS = (10, 20, 35, 60)
#: §7.6: "tier II costs 20 more pages and 2,000 Aether (Spire level 4); tier III
#: costs 40 more pages and 8,000 Aether (Spire level 7)" — (pages, Aether, Spire).
TIER_COSTS = ((20, 2_000, 4), (40, 8_000, 7))
#: §7.6: "receives 2 of its pages, 3 if the heist was clean", "a foiled heist
#: gives one", and a law met "joins the Codex with 1 page".
STUDY_PAGES = (2, 3)
FOILED_PAGES = 1
MEET_PAGES = 1
#: §7.6: "Every eighth heist guarantees a page of a law you are actually
#: working on".
FLOOR_HEISTS = 8
#: §7.6: "Starting laws: Half gravity, Slow rivers and Bloom, all at tier I."
STARTING_LAWS = ("half_gravity", "slow_rivers", "bloom")
#: §7.6: "12 findable from the start and all 24 from Keeper level 6".
CHAPTER_TWO_KEEPER = 6
#: §9.5's character levels: "150 × 1.55^(level − 2) Essence per level, up to
#: level 10" — the base, the growth and the top.
LEVEL_PRICE = (150, 1.55, 10)
#: §9.2's best workers: "Motion and Matter ruleborn (+15%)" at a Star Well, and
#: each resource's two schools alike.
WORKER_SCHOOL_BONUS = 0.15
#: §11.5: "The roster holds 3 characters for the Spire plus the places in every
#: Hearth, 38 at the most at launch".
ROSTER_PLACES = (3, 38)
#: §11.6: "Production starts 5 minutes after assignment, so constant swapping
#: doesn't pay."
PRODUCTION_START_MINUTES = 5
#: §9.3: "Each building holds 12 hours of output until collected", and a
#: producer earns "× 1.1 in a realm of that school".
PRODUCER_HOLD_HOURS = 12
OWN_SCHOOL_PRODUCTION = 1.1
#: §9.3: "(1 + 0.10 per realm law of a matching school + 0.05 per matching
#: crown law)" — a realm law's share, and a crown law's.
PRODUCTION_LAW_BONUS = (0.10, 0.05)
#: §5.6: "10 minutes at tier I, 40 minutes at tier II and 2 hours at tier III"
#: to weave a law, in minutes; "Weaving costs 40 Aether per point of the law's
#: stability cost"; and "the slot then rests for an hour", in minutes.
WEAVE_MINUTES = (10, 40, 120)
WEAVE_AETHER_PER_POINT = 40
SLOT_REST_MINUTES = 60
#: §5.1: "The Spire opens 1 crown slot at Spire level 2 and a second at Spire
#: level 5" — the Spire level for each crown slot.
CROWN_SLOT_SPIRE = (2, 5)
#: §5.5: "Cost of a law = base cost × tier (1.0, 1.3 or 1.6) × 2 if crowned ×
#: 0.8 in a realm of its school × …" — the terms that are the law's alone.
TIER_COST_FACTORS = (1.0, 1.3, 1.6)
CROWN_COST_FACTOR = 2
OWN_SCHOOL_COST_FACTOR = 0.8
#: §11.5: a birth's school "weighted as 11.9 states: 3 for each law woven in its
#: realm, 2 for the realm's own school and 1 for each crown law".
BIRTH_WEIGHTS = (3, 2, 1)
#: §11.3: "Traits tied to a law are three times as likely when a character is
#: born in a realm running that law."
LAW_TRAIT_WEIGHT = 3
#: §5.2's "Boosted resource" column, by realm type in the table's order.
REALM_BOOSTS = ("starlight", "starlight", "aether", "aether", "essence", "essence")
#: The first session's first minute (§15.6): "Three ruleborn wake: a Featherkin, an Emberling and a
#: Tidewalker."
STARTING_CREW = ("featherkin", "emberling", "tidewalker")

#: §5.4, "the clock's one home": "150 seconds plus 15 seconds for each link on
#: the shortest route from the landing realm to the Heart, up to 240 seconds".
HEIST_CLOCK = (150, 15, 240)

#: §9.4 (v3.7, F39 B): "Entry fee: 2% of B(V) at the target’s Vault level
#: (9.6), never more than the raider holds".
ENTRY_FEE_RATE = 0.02

#: §12.9: "Renown for a clean heist = 20 × (1 + (defender's Renown − raider's
#: Renown) ÷ 1,000), kept between 8 and 40, then multiplied by the outcome
#: above. The defender gains or loses the mirror amount." (base, scale, floor, cap)
RENOWN_CLEAN = (20, 1000, 8, 40)

#: §12.9's Renown column: ×1.0 clean, ×0.8 loud, ×0.5 partial.
RENOWN_OUTCOME = {"clean": 1.0, "loud": 0.8, "partial": 0.5}

#: §12.9: "A foiled heist costs the raider a flat 8".
RENOWN_FOILED = 8

#: §18.1: "A season lasts eight weeks."
SEASON_WEEKS = 8

#: §18.1: "six leagues: Dust, Ember, Tide, Star, Nova and Paradox, each with
#: three divisions except Paradox".
LEAGUES = ("Dust", "Ember", "Tide", "Star", "Nova", "Paradox")
LEAGUE_DIVISIONS = 3

#: §14.7's "Share of active players at season end", in per cent, for the five
#: leagues it gives one; Dust has none ("—").
LEAGUE_SHARES = {"Ember": 30, "Tide": 30, "Star": 25, "Nova": 10, "Paradox": 1}

#: §17.1: "up to 30 Keepers, joined through the Beacon from Keeper level 6: a
#: founder, up to four elders, and members."
CONSTELLATION_SIZE = 30
CONSTELLATION_KEEPER_LEVEL = 6
CONSTELLATION_ELDERS = 4

#: §17.7: a crew is "4 to 8", "the people you actually play with".
CREW_SIZE = (4, 8)

#: §12.22's band (v3.7, F44 D): "Renown within 150, Keeper level from 2 below
#: the raider’s to 3 above". (Renown, (below, above))
MATCH_WINDOW = (150, (2, 3))

#: §12.22's rating: "a wide deviation, 350 on Glicko-2's scale … (volatility
#: 0.06, system constant 0.5)". (deviation, volatility, system constant)
GLICKO = (350, 0.06, 0.5)

#: §12.22's guarantee draws the middle target "from the raider-success band
#: for the target's realm level — 55 to 70% at every realm level (13.2)" (v3.7;
#: v3.6 gave realm level 1 its own 60 to 75%). Per cent. These are the
#: generated islands' bands; an authored island's is HOLD_BAND's.
RAIDER_SUCCESS = (55, 70)

#: §12.22: "If fewer than three live candidates, echoes included … sit inside
#: the band".
THIN_BAND = 3

#: §12.3: "New players can't be raided by other players for their first 72
#: hours, or until they raid a player themselves."
NEW_PLAYER_SHIELD_HOURS = 72

#: §12.3 (v3.7): "Trace: within 24 hours of a raid on their island that was not
#: foiled and was not past the raider’s twenty paid raids that week (9.6), a
#: player can target the raider once, with no entry fee."
TRACE_HOURS = 24

#: §12.3's echoes: "snapshots of real universes from the last 14 days".
ECHO_DAYS = 14

#: §9.4 (v3.7, G31 A): "a foiled heist gives the defender the entry fee plus 5%
#: of the clean haul the crew’s unbanked load would have made on this island".
#: Per cent.
DEFENCE_SHARE = 5

#: §13.1's rule: "Below 15%, the defence reward's share of what a foiled crew
#: was carrying (9.4) rises by 5 points a season, at most three times, from 5%
#: to 20%". (threshold %, step, most rises, from %, to %)
DEFENCE_SHARE_RISE = (15, 5, 3, 5, 20)

#: §24.1 (v3.7, F47 A): "Budget, measured: about 14 rows a clean heist, and at
#: least 46, 24 and 11 rows a day for engaged, regular and casual players".
#: Rows written a player-day, by §14.1's archetype; server/load.mjs measures them.
WRITE_BUDGET = {"engaged": 46, "regular": 24, "casual": 11}

#: §24.1: "The paid plan is $5 a month and includes 25 billion row reads and
#: 50 million row writes". A month's writes.
PAID_WRITES_MONTH = 50_000_000

#: §28.3's D1 source: "then $0.001 per million reads and $1.00 per million
#: writes". Dollars.
WRITE_PRICE_PER_MILLION = 1.0

#: §28.3's D1 source: "the free plan allows 5 million row reads and 100,000
#: row writes a day".
FREE_WRITES_DAY = 100_000

#: §28.3's Workers source: "CPU time per request of 30 seconds by default on
#: the paid plan … against 10 milliseconds on the free plan".
FREE_CPU_MS = 10

#: §20.2's "Notifications at night": "Never, 21:00 to 08:00" at 13 to 15,
#: "Never, 22:00 to 08:00" at 16 and 17, "Off 22:00 to 08:00 by default" for
#: adults. (from hour, to hour), local time.
NIGHT_HOURS = {"13-15": (21, 8), "16-17": (22, 8), "18+": (22, 8)}

#: §24.3 (v3.7, G29 B): "Raw replays and logs are kept 90 days". v3.6 gave a
#: range of 30 to 90; the server always kept the most.
RAW_KEEP_DAYS = 90

#: §25.1's gate: "a third of monthly players play on a given day". A share.
DAILY_SHARE = (1, 3)

#: §18.2 (v3.7, F42 A): "Fifty tiers, climbed with season stars from heists and
#: defences."
SEASON_TIERS = 50

#: §22.1 sells "The season pass premium track (cosmetic), about €6 a season".
PREMIUM_TRACK_EUR = 6

#: §20.2's purchases row: "€25 a month cap" at 13 to 15 and "€50 a month cap"
#: at 16 and 17; adults get a "Monthly spending summary" and no cap.
SPENDING_CAPS_EUR = {"13-15": 25, "16-17": 50}

#: §14.2: "Keeper experience comes from successful heists (30 + 6 × Keeper
#: level), foiled heists (10 + 2 × level), spending (1 for every 40
#: Starlight) and restoring laws (60 + 10 × level)." (base, per level)
XP_PER_SUCCESSFUL_HEIST = (30, 6)
XP_PER_FOILED_HEIST = (10, 2)
XP_PER_LAW_RESTORED = (60, 10)
STARLIGHT_PER_XP = 40

#: §14.2's table, "XP to next" from level 1 to level 39: the experience to
#: advance from level n to n + 1, index 0 being level 1. Level 40 is the top.
KEEPER_XP_TO_NEXT = (
    140, 90, 270, 370, 460, 620, 1_050, 1_020, 1_870, 2_230,
    2_450, 1_550, 3_920, 2_330, 3_580, 1_610, 8_700, 5_850, 6_790, 8_100,
    10_520, 13_450, 15_980, 19_480, 19_010, 21_280, 22_980, 26_960, 31_930, 31_830,
    32_990, 39_760, 40_660, 42_860, 49_230, 53_670, 51_850, 56_740, 57_880,
)

#: Where each declared fact is stated, so the report can cite it and a reader
#: can check it. The derived ones cite the content file instead.
HOME = {
    "NOTES": "content/notes.json (8.1)",
    "OPPOSITE": "content/notes.json (8.1)",
    "ROLE_NAMES": "content/roles.json (11.1)",
    "SCHOOLS": "content/laws.json (7)",
    "HOLD_BAND": "13.2",
    "XP_PER_SUCCESSFUL_HEIST": "14.2",
    "XP_PER_FOILED_HEIST": "14.2",
    "XP_PER_LAW_RESTORED": "14.2",
    "STARLIGHT_PER_XP": "14.2",
    "KEEPER_XP_TO_NEXT": "14.2",
    "DECISION_BAND": "12.6",
    "DECISION_SECONDS": "12.6",
    "ABILITY_LOCKOUT_SECONDS": "12.6",
    "ABILITIES_READY": "12.6",
    "SAGE_COOLDOWN_SECONDS": "11.7",
    "CREW_RANGE": "12.5",
    "WARD_LIMITS": "5.2",
    "GUARD_POSTS": "10.2",
    "BUILDING_FOOTPRINTS": "10.1",
    "REALM_WATCH": "12.17",
    "LAW_SLOTS": "5.2",
    "REALM_KEEPER_LEVELS": "5.2",
    "REALM_TYPES": "5.2",
    "REALM_LEVEL_SPIRE": "5.2",
    "REALM_OPEN_COST": "9.5",
    "REALM_LEVEL_COSTS": "9.5",
    "STARTING_HEART": "9.6",
    "WIND_UP": "12.8",
    "TAKEDOWN_SECONDS": "29.1",
    "ASSIST_BONUS": "11.1",
    "DISARM_SECONDS": "10.3",
    "VAULT_HEALTH_PER_LEVEL": "12.6",
    "BREAKER_VAULT_MULTIPLIER": "12.6",
    "WARD_HEALTH_PER_LEVEL": "10.3",
    "LOAD_PER_SECOND": "12.19",
    "CARRIER_LOADED_PACE": "11.1",
    "DOWN_SECONDS": "12.20",
    "REVIVE_SECONDS": "12.20",
    "MENDER_REVIVE_SECONDS": "12.20",
    "REVIVE_HEALTH": "12.20",
    "CROUCH_PACE": "12.17",
    "RUN_PACE": "12.17",
    "SKIFF_OUTER_SECONDS": "5.4",
    "SKIFF_HEART_SECONDS": "5.4",
    "LANDING_HEARD_TILES": "5.4",
    "LANDING_SUSPICION": "5.4",
    "GRADE_VALUE": "12.9",
    "HAUL_BASE": "9.6",
    "HAUL_GROWTH": "9.6",
    "HAUL_FATIGUE": "9.6",
    "RICHNESS_CLAMP": "9.6",
    "DIFFICULTY": "9.6",
    "ATTEMPT_BAND": "9.6",
    "ROSTER_KEEP_SHARE": "9.5",
    "BIRTH_PRICE": "9.5",
    "PAGE_COSTS": "7.6",
    "TIER_COSTS": "7.6",
    "STUDY_PAGES": "7.6",
    "FOILED_PAGES": "7.6",
    "MEET_PAGES": "7.6",
    "FLOOR_HEISTS": "7.6",
    "STARTING_LAWS": "7.6",
    "CHAPTER_TWO_KEEPER": "7.6",
    "LEVEL_PRICE": "9.5",
    "WORKER_SCHOOL_BONUS": "9.2",
    "ROSTER_PLACES": "11.5",
    "PRODUCTION_START_MINUTES": "11.6",
    "PRODUCER_HOLD_HOURS": "9.3",
    "OWN_SCHOOL_PRODUCTION": "9.3",
    "PRODUCTION_LAW_BONUS": "9.3",
    "WEAVE_MINUTES": "5.6",
    "WEAVE_AETHER_PER_POINT": "5.6",
    "SLOT_REST_MINUTES": "5.6",
    "CROWN_SLOT_SPIRE": "5.1",
    "TIER_COST_FACTORS": "5.5",
    "CROWN_COST_FACTOR": "5.5",
    "OWN_SCHOOL_COST_FACTOR": "5.5",
    "BIRTH_WEIGHTS": "11.5",
    "LAW_TRAIT_WEIGHT": "11.3",
    "REALM_BOOSTS": "5.2",
    "STARTING_CREW": "15.6",
    "HEIST_CLOCK": "5.4",
    "ENTRY_FEE_RATE": "9.4",
    "RENOWN_CLEAN": "12.9",
    "RENOWN_OUTCOME": "12.9",
    "RENOWN_FOILED": "12.9",
    "SEASON_WEEKS": "18.1",
    "LEAGUES": "18.1",
    "LEAGUE_DIVISIONS": "18.1",
    "LEAGUE_SHARES": "14.7",
    "CONSTELLATION_SIZE": "17.1",
    "CONSTELLATION_KEEPER_LEVEL": "17.1",
    "CONSTELLATION_ELDERS": "17.1",
    "CREW_SIZE": "17.7",
    "MATCH_WINDOW": "12.22",
    "GLICKO": "12.22",
    "RAIDER_SUCCESS": "12.22",
    "THIN_BAND": "12.22",
    "NEW_PLAYER_SHIELD_HOURS": "12.3",
    "TRACE_HOURS": "12.3",
    "ECHO_DAYS": "12.3",
    "DEFENCE_SHARE": "9.4",
    "DEFENCE_SHARE_RISE": "13.1",
    "WRITE_BUDGET": "24.1",
    "PAID_WRITES_MONTH": "24.1",
    "WRITE_PRICE_PER_MILLION": "28.3",
    "FREE_WRITES_DAY": "28.3",
    "FREE_CPU_MS": "28.3",
    "NIGHT_HOURS": "20.2",
    "RAW_KEEP_DAYS": "24.3",
    "DAILY_SHARE": "25.1",
    "SEASON_TIERS": "18.2",
    "PREMIUM_TRACK_EUR": "22.1",
    "SPENDING_CAPS_EUR": "20.2",
}


#: How each declared fact reads in its home section, so the value here can be
#: checked against the document rather than trusted. Until v3.3 nothing did:
#: the rule above stops a second copy in the tools, and nothing stopped the one
#: copy going stale when the document moved. The pattern captures the value;
#: the function turns the capture into this module's unit.
def _xp_table(text: str):
    """§14.2's "XP to next" column, read whole: rows numbered 1 to N in order,
    every one a number but the last, the top level's "—". Anything else —
    a row added past the top, one dropped or renumbered — reads as None, so
    it disagrees with the declared table rather than passing unread."""
    rows = re.findall(r"\| (\d+)\n\| ([\d,]+|—)\n\| [\d,]+\n", text)
    levels = [int(n) for n, _ in rows]
    if not rows or levels != list(range(1, len(rows) + 1)) or rows[-1][1] != "—" \
            or any(v == "—" for _, v in rows[:-1]):
        return None
    return tuple(int(v.replace(",", "")) for _, v in rows[:-1])


_words = {"half": 0.5, "double": 2.0, "ten": 10, "two": 2, "three": 3}
_n = lambda x: _words.get(x, None) if x in _words else float(x.replace(",", ""))
STATED = {
    "XP_PER_SUCCESSFUL_HEIST": (r"successful heists \((\d+) \+ (\d+) × Keeper level\)",
                                lambda m: (int(m[0]), int(m[1]))),
    "XP_PER_FOILED_HEIST": (r"foiled heists \((\d+) \+ (\d+) × level\)",
                            lambda m: (int(m[0]), int(m[1]))),
    "XP_PER_LAW_RESTORED": (r"restoring laws \((\d+) \+ (\d+) × level\)",
                            lambda m: (int(m[0]), int(m[1]))),
    "STARLIGHT_PER_XP": (r"spending \(1 for every (\d+) Starlight\)", lambda m: int(m[0])),
    "KEEPER_XP_TO_NEXT": (r"(Keeper levels: experience needed[\s\S]*?\| \d+\n\| —\n\| [\d,]+\n)",
                          lambda m: _xp_table(m[0])),
    "HOLD_BAND": (r"Authored islands are held to (\d+) to (\d+)%",
                  lambda m: (float(m[0]), float(m[1]))),
    "DECISION_BAND": (r"or (\d+) to (\d+) in a run", lambda m: (int(m[0]), int(m[1]))),
    "ABILITY_LOCKOUT_SECONDS": (r"with a lockout of one decision slot \((\d+) seconds\)",
                                lambda m: int(m[0])),
    "ABILITIES_READY": (r"At most (four) abilities are ready at once",
                        lambda m: {"four": 4}[m[0]]),
    "SAGE_COOLDOWN_SECONDS": (r"After using any power the Sage cools down for (\d+) seconds",
                              lambda m: int(m[0])),
    "DECISION_SECONDS": (r"roughly one every (\d+) to (\d+) seconds",
                         lambda m: (int(m[0]), int(m[1]))),
    "CREW_RANGE": (r"A crew of (\d+) to (\d+)", lambda m: (int(m[0]), int(m[1]))),
    "WARD_LIMITS": (r"the legibility cap 13.2 sets: (\d+), (\d+), (\d+), (\d+) and (\d+)",
                    lambda m: tuple(int(x) for x in m)),
    "REALM_WATCH": (r"at realm level 1 suspicion fills at ([\d.]+) of the rates above; at level 2 every "
                    r"zone reaches ([\d.]+) as far, and at level 3 ([\d.]+) as far; from level 4 guards see "
                    r"and notice at full strength",
                    lambda m: ((float(m[0]), 1.0), (1.0, float(m[1])), (1.0, float(m[2])),
                               (1.0, 1.0), (1.0, 1.0))),
    "BUILDING_FOOTPRINTS": (r"Most are (\d) by \1 tiles; the Spire and Vault are (\d) by \2",
                            lambda m: (int(m[0]), int(m[1]))),
    "GUARD_POSTS": (r"Every realm; (\d+), (\d+), (\d+), (\d+) and (\d+) by realm level"
                    r"(?:, the Heart counting as realm level 3)? \(5\.2\)\. One ruleborn",
                    lambda m: tuple(int(x) for x in m)),
    "LAW_SLOTS": (r"\| 10 by 10\n\| (\d+)\n[\s\S]*?\| 11 by 11\n\| (\d+)\n[\s\S]*?"
                  r"\| 12 by 12\n\| (\d+)\n[\s\S]*?\| 13 by 13\n\| (\d+)\n[\s\S]*?"
                  r"\| 14 by 14\n\| (\d+)\n", lambda m: tuple(int(x) for x in m)),
    "REALM_KEEPER_LEVELS": (r"Outer realms open at Keeper levels (\d+), (\d+), (\d+), (\d+), (\d+) and (\d+)",
                            lambda m: tuple(int(x) for x in m)),
    "REALM_TYPES": (r"\| ([^\n]+)\n\| Motion\n[\s\S]*?\| ([^\n]+)\n\| Matter\n[\s\S]*?"
                    r"\| ([^\n]+)\n\| Time\n[\s\S]*?\| ([^\n]+)\n\| Energy\n[\s\S]*?"
                    r"\| ([^\n]+)\n\| Life\n[\s\S]*?\| ([^\n]+)\n\| Spirit\n", lambda m: tuple(m)),
    "REALM_LEVEL_SPIRE": (r"\| 10 by 10\n(?:\| [^\n]*\n){6}\| Spire (\d+)\n[\s\S]*?"
                          r"\| 11 by 11\n(?:\| [^\n]*\n){6}\| Spire (\d+)\n[\s\S]*?"
                          r"\| 12 by 12\n(?:\| [^\n]*\n){6}\| Spire (\d+)\n[\s\S]*?"
                          r"\| 13 by 13\n(?:\| [^\n]*\n){6}\| Spire (\d+)\n[\s\S]*?"
                          r"\| 14 by 14\n(?:\| [^\n]*\n){6}\| Spire (\d+)\n",
                          lambda m: tuple(int(x) for x in m)),
    "REALM_OPEN_COST": (r"\| Opening an outer realm\n\| ([\d,]+) Starlight",
                        lambda m: int(m[0].replace(",", ""))),
    "REALM_LEVEL_COSTS": (r"\| Realm levels 2 to 5\n\| ([\d,]+), ([\d,]+), ([\d,]+) and ([\d,]+) Starlight",
                          lambda m: tuple(int(x.replace(",", "")) for x in m)),
    # §14.2's first row names the Heart and the Lab; F56 decides the rest.
    "STARTING_HEART": (r"A new universe starts with the Heart and, at level 1 in it, the ([^:]+): the starting "
                       r"universe",
                       lambda m: tuple({"Keeper’s Spire": "keeper_s_spire", "Vault": "vault",
                                        "Star Well": "star_well", "Aether Spring": "aether_spring",
                                        "Garden": "garden", "Hearth": "hearth"}.get(n, n)
                                       for n in re.split(r", (?:and )?| and ",
                                                         re.sub(r"\b(?:the|a|an) ", "", m[0])))),
    "WIND_UP": (r"shows a ([\d.]+)-second wind-up", lambda m: float(m[0])),
    "TAKEDOWN_SECONDS": (r"after a (\d+) s takedown", lambda m: int(m[0])),
    "ASSIST_BONUS": (r"every hit on it deals (\d+)% more: the assist bonus",
                     lambda m: int(m[0]) / 100),
    "DISARM_SECONDS": (r"stands on the ward's tile for (\d+) seconds", lambda m: int(m[0])),
    "VAULT_HEALTH_PER_LEVEL": (r"([\d,]+) health per Vault level", lambda m: int(_n(m[0]))),
    "BREAKER_VAULT_MULTIPLIER": (r"Breakers deal (double) damage to it",
                                 lambda m: int(_n(m[0]))),
    "WARD_HEALTH_PER_LEVEL": (r"Every ward has (\d+) health a level", lambda m: int(m[0])),
    "LOAD_PER_SECOND": (r"Every role can load, at (\d+) units a second",
                        lambda m: int(m[0])),
    "CARRIER_LOADED_PACE": (r"(\d+)% slower when loaded", lambda m: 1 - int(m[0]) / 100),
    "DOWN_SECONDS": (r"has (\w+) seconds before capture", lambda m: int(_n(m[0]))),
    "REVIVE_SECONDS": (r"revives it in (\d+) seconds", lambda m: float(m[0])),
    "MENDER_REVIVE_SECONDS": (r"a Mender in ([\d.]+)", lambda m: float(m[0])),
    "REVIVE_HEALTH": (r"returns at (\d+)% of its full health", lambda m: int(m[0]) / 100),
    "CROUCH_PACE": (r"crouched, a crew member moves at (half) its role's speed",
                    lambda m: _n(m[0])),
    "RUN_PACE": (r"and running, at (double)", lambda m: _n(m[0])),
    "SKIFF_OUTER_SECONDS": (r"takes (\d+) seconds to reach an outer realm",
                            lambda m: int(m[0])),
    "SKIFF_HEART_SECONDS": (r"and (\d+) seconds to (?:fight the winds around|reach) the Heart",
                            lambda m: int(m[0])),
    "LANDING_HEARD_TILES": (r"guards within (\d+) tiles of the landing spot",
                            lambda m: int(m[0])),
    "LANDING_SUSPICION": (r"of the landing spot start at ([\d,]+) of 1,000 suspicion",
                          lambda m: int(m[0].replace(",", ""))),
    "GRADE_VALUE": (r"\| Clean\n[^\n]*\n\| ×([\d.]+)[\s\S]*?\| Loud\n[^\n]*\n\| ×([\d.]+)"
                    r"[\s\S]*?\| Partial\n[^\n]*\n\| ×([\d.]+)[\s\S]*?\| Foiled\n[^\n]*\n\| ×([\d.]+)",
                    lambda m: {"clean": float(m[0]), "loud": float(m[1]),
                               "partial": float(m[2]), "foiled": float(m[3])}),
    "HAUL_BASE": (r"\| ([\d,]+) × [\d.]+\(V−1\)", lambda m: int(m[0].replace(",", ""))),
    "HAUL_GROWTH": (r"\| [\d,]+ × ([\d.]+)\(V−1\)", lambda m: float(m[0])),
    "HAUL_FATIGUE": (r"\| Fatigue\n\| ([\d.]+) on each successive raid", lambda m: float(m[0])),
    "RICHNESS_CLAMP": (r"clamped between ([\d.]+) and ([\d.]+), with a reduction above ([\d.]+)",
                       lambda m: tuple(float(x) for x in m)),
    "DIFFICULTY": (r"By Keeper level against the raider’s: same level ([\d.]+), one above ([\d.]+), two "
                   r"or more above ([\d.]+); one below ([\d.]+), two below ([\d.]+), three or more below "
                   r"([\d.]+)",
                   # One above must be the 0.1 step the server takes; if not, the
                   # six numbers are returned and the comparison fails.
                   lambda m: (lambda v: (v[0], v[2], v[3], v[4], v[5])
                              if round(v[1] - v[0], 6) == 0.1 else tuple(v))([float(x) for x in m])),
    "ROSTER_KEEP_SHARE": (r"\| The roster's keep\n\| (\d+)% of Essence production",
                          lambda m: int(m[0]) / 100),
    "BIRTH_PRICE": (r"\| A new ruleborn\n\| (\d+) × ([\d.]+) ?ruleborn owned Essence, where owned is n − 1",
                    lambda m: (int(m[0]), float(m[1]))),
    "PAGE_COSTS": (r"Restoring a law: (\d+), (\d+), (\d+) or (\d+) pages by rank",
                   lambda m: tuple(int(x) for x in m)),
    "TIER_COSTS": (r"tier II costs (\d+) more pages and ([\d,]+) Aether \(Spire level (\d+)\); tier III costs "
                   r"(\d+) more pages and ([\d,]+) Aether \(Spire level (\d+)\)",
                   lambda m: tuple(tuple(int(x.replace(",", "")) for x in m[i:i + 3]) for i in (0, 3))),
    "STUDY_PAGES": (r"receives (\d+) of its pages, (\d+) if the heist was clean", lambda m: (int(m[0]), int(m[1]))),
    "FOILED_PAGES": (r"a foiled heist gives (one|two)", lambda m: {"one": 1, "two": 2}[m[0]]),
    "MEET_PAGES": (r"joins the Codex with (\d+) page", lambda m: int(m[0])),
    "FLOOR_HEISTS": (r"Every (eighth|tenth|sixth) heist guarantees a page", lambda m: {"sixth": 6, "eighth": 8, "tenth": 10}[m[0]]),
    "STARTING_LAWS": (r"Starting laws: ([\w ]+), ([\w ]+) and ([\w ]+), all at tier I",
                      lambda m: tuple(x.strip().lower().replace(" ", "_") for x in m)),
    "CHAPTER_TWO_KEEPER": (r"12 findable from the start and all 24 from Keeper level (\d+)", lambda m: int(m[0])),
    "LEVEL_PRICE": (r"\| Character levels\n\| (\d+) × ([\d.]+) ?level − 2 Essence per level, up to level (\d+)",
                    lambda m: (int(m[0]), float(m[1]), int(m[2]))),
    "WORKER_SCHOOL_BONUS": (r"Motion and Matter ruleborn \(\+(\d+)%\)", lambda m: int(m[0]) / 100),
    "ROSTER_PLACES": (r"The roster holds (\d+) characters for the Spire plus the places in every "
                      r"Hearth, (\d+) at the most at launch", lambda m: (int(m[0]), int(m[1]))),
    "PRODUCTION_START_MINUTES": (r"Production starts (\d+) minutes after assignment",
                                 lambda m: int(m[0])),
    "PRODUCER_HOLD_HOURS": (r"Each building holds (\d+) hours of output until collected",
                            lambda m: int(m[0])),
    "OWN_SCHOOL_PRODUCTION": (r"× ([\d.]+) in a realm of that school", lambda m: float(m[0])),
    "PRODUCTION_LAW_BONUS": (r"\(1 \+ ([\d.]+) per realm law of a matching school \+ ([\d.]+) per matching crown law\)",
                             lambda m: (float(m[0]), float(m[1]))),
    "WEAVE_MINUTES": (r"(\d+) minutes at tier I, (\d+) minutes at tier II and (\d+) hours at tier III",
                      lambda m: (int(m[0]), int(m[1]), int(m[2]) * 60)),
    "WEAVE_AETHER_PER_POINT": (r"Weaving costs (\d+) Aether per point of the law's stability cost",
                               lambda m: int(m[0])),
    "SLOT_REST_MINUTES": (r"the slot then rests for (an hour|\d+ minutes)",
                          lambda m: 60 if m[0] == "an hour" else int(m[0].split()[0])),
    "CROWN_SLOT_SPIRE": (r"The Spire opens 1 crown slot at Spire level (\d+) and a second at Spire level (\d+)",
                         lambda m: (int(m[0]), int(m[1]))),
    "TIER_COST_FACTORS": (r"Cost of a law = base cost × tier \(([\d.]+), ([\d.]+) or ([\d.]+)\)",
                          lambda m: tuple(float(x) for x in m)),
    "CROWN_COST_FACTOR": (r"Cost of a law = base cost × tier \([^)]*\) × (\d+) if crowned", lambda m: int(m[0])),
    "OWN_SCHOOL_COST_FACTOR": (r"× (\d+) if crowned × ([\d.]+) in a realm of its school", lambda m: float(m[1])),
    "LAW_TRAIT_WEIGHT": (r"Traits tied to a law are (two|three|four) times as likely",
                         lambda m: {"two": 2, "three": 3, "four": 4}[m[0]]),
    "BIRTH_WEIGHTS": (r"weighted as 11\.9 states: (\d+) for each law woven in its realm, (\d+) for the realm's own "
                      r"school and (\d+) for each crown law", lambda m: tuple(int(x) for x in m)),
    "REALM_BOOSTS": (r"\| Motion\n\| [^\n]+\n\| (\w+)\n[\s\S]*?\| Matter\n\| [^\n]+\n\| (\w+)\n"
                     r"[\s\S]*?\| Time\n\| [^\n]+\n\| (\w+)\n[\s\S]*?\| Energy\n\| [^\n]+\n\| (\w+)\n"
                     r"[\s\S]*?\| Life\n\| [^\n]+\n\| (\w+)\n[\s\S]*?\| Spirit\n\| [^\n]+\n\| (\w+)\n",
                     lambda m: tuple(x.lower() for x in m)),
    "STARTING_CREW": (r"Three ruleborn wake: an? (\w+), an? (\w+) and an? (\w+)\.",
                      lambda m: tuple(x.lower() for x in m)),
    "ATTEMPT_BAND": (r"(0\.\d+) for a crew that stops at a fixed 70% fill and (0\.\d+) for one "
                     r"that reads the guards", lambda m: (float(m[0]), float(m[1]))),
    "HEIST_CLOCK": (r"\| (\d+) seconds plus (\d+) seconds for each link on the shortest route "
                    r"from the landing realm to the Heart, up to (\d+) seconds",
                    lambda m: tuple(int(x) for x in m)),
    "ENTRY_FEE_RATE": (r"Entry fee: (\d+)% of B\(V\) at the target’s Vault level", lambda m: int(m[0]) / 100),
    "RENOWN_CLEAN": (r"Renown for a clean heist = (\d+) × \(1 \+ \(defender's Renown − raider's "
                     r"Renown\) ÷ ([\d,]+)\), kept between (\d+) and (\d+)",
                     lambda m: tuple(int(x.replace(",", "")) for x in m)),
    "RENOWN_OUTCOME": (r"\| Clean\n[^\n]*\n\| ×[\d.]+\n\| ×([\d.]+)[\s\S]*?\| Loud\n[^\n]*\n"
                       r"\| ×[\d.]+\n\| ×([\d.]+)[\s\S]*?\| Partial\n[^\n]*\n\| ×[\d.]+\n\| ×([\d.]+)",
                       lambda m: {"clean": float(m[0]), "loud": float(m[1]), "partial": float(m[2])}),
    "RENOWN_FOILED": (r"A foiled heist costs the raider a flat (\d+)", lambda m: int(m[0])),
    "SEASON_WEEKS": (r"A season lasts (\w+) weeks", lambda m: {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8}.get(m[0])),
    "LEAGUES": (r"six leagues: (\w+), (\w+), (\w+), (\w+), (\w+) and (\w+), each",
                lambda m: tuple(m)),
    "LEAGUE_DIVISIONS": (r"each with (\w+) divisions except Paradox",
                         lambda m: {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8}.get(m[0])),
    "LEAGUE_SHARES": (r"\| Ember\n[^\n]*\n\| About (\d+)%[\s\S]*?\| Tide\n[^\n]*\n\| About (\d+)%"
                      r"[\s\S]*?\| Star\n[^\n]*\n\| About (\d+)%[\s\S]*?\| Nova\n[^\n]*\n\| About (\d+)%"
                      r"[\s\S]*?\| Paradox\n[^\n]*\n\| About (\d+)%",
                      lambda m: dict(zip(("Ember", "Tide", "Star", "Nova", "Paradox"), map(int, m)))),
    "CONSTELLATION_SIZE": (r"up to (\d+) Keepers, joined through the Beacon", lambda m: int(m[0])),
    "CONSTELLATION_KEEPER_LEVEL": (r"joined through the Beacon from Keeper level (\d+)",
                                   lambda m: int(m[0])),
    "CONSTELLATION_ELDERS": (r"a founder, up to (\w+) elders", lambda m: {"one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6, "seven": 7, "eight": 8}.get(m[0])),
    "CREW_SIZE": (r"\| Crew\n\| (\d+) to (\d+)", lambda m: (int(m[0]), int(m[1]))),
    # The document's wording ("Keeper level within 3") or the decided one
    # (F44: "from 2 below to 3 above"), so the check tells when it catches up.
    "MATCH_WINDOW": (r"\| 1\. The band\n\| Renown within (\d+), Keeper level "
                     r"(?:within (\d+)|from (\d+) below(?: the raider’s)? to (\d+) above)",
                     lambda m: (int(m[0]), int(m[1])) if m[1] else (int(m[0]), (int(m[2]), int(m[3])))),
    "GLICKO": (r"a wide deviation, (\d+) on Glicko-2's scale, which narrows with every observed "
               r"attack under Glicko-2's update \(volatility ([\d.]+), system constant ([\d.]+)\)",
               lambda m: (int(m[0]), float(m[1]), float(m[2]))),
    "RAIDER_SUCCESS": (r"(\d+) to (\d+)% at every realm level \(13\.2\)",
                       lambda m: (int(m[0]), int(m[1]))),
    "THIN_BAND": (r"If fewer than (\w+) live candidates, echoes included",
                  lambda m: {"two": 2, "three": 3, "four": 4, "five": 5}.get(m[0])),
    "NEW_PLAYER_SHIELD_HOURS": (r"New players can't be raided by other players for their first (\d+) hours",
                                lambda m: int(m[0])),
    "TRACE_HOURS": (r"Trace: within (\d+) hours of a raid on their island", lambda m: int(m[0])),
    "ECHO_DAYS": (r"snapshots of real universes from the last (\d+) days", lambda m: int(m[0])),
    "DEFENCE_SHARE": (r"a foiled heist gives the defender the entry fee plus (\d+)% of the clean haul "
                      r"the crew’s unbanked load would have made", lambda m: int(m[0])),
    "DEFENCE_SHARE_RISE": (r"Below (\d+)%, the defence reward's share of what a foiled crew was carrying "
                           r"\(9\.4\) rises by (\d+) points a season, at most (\w+) times, from (\d+)% to (\d+)%",
                           lambda m: (int(m[0]), int(m[1]), {"two": 2, "three": 3, "four": 4}.get(m[2]),
                                      int(m[3]), int(m[4]))),
    "WRITE_BUDGET": (r"at least (\d+), (\d+) and (\d+) rows a day for engaged, regular and casual players",
                     lambda m: {"engaged": int(m[0]), "regular": int(m[1]), "casual": int(m[2])}),
    "PAID_WRITES_MONTH": (r"The paid plan is \$\d+ a month and includes \d+ billion row reads and (\d+) "
                          r"million row writes", lambda m: int(m[0]) * 1_000_000),
    "WRITE_PRICE_PER_MILLION": (r"then \$[\d.]+ per million reads and \$([\d.]+) per million writes",
                                lambda m: float(m[0])),
    "FREE_WRITES_DAY": (r"the free plan allows \d+ million row reads and ([\d,]+) row writes a day",
                        lambda m: int(m[0].replace(",", ""))),
    "FREE_CPU_MS": (r"against (\d+) milliseconds on the free plan", lambda m: int(m[0])),
    "NIGHT_HOURS": (r"\| Notifications at night\n\| Never, (\d+):00 to (\d+):00\n\| Never, (\d+):00 to "
                    r"(\d+):00\n\| Off (\d+):00 to (\d+):00 by default",
                    lambda m: {"13-15": (int(m[0]), int(m[1])), "16-17": (int(m[2]), int(m[3])),
                               "18+": (int(m[4]), int(m[5]))}),
    "RAW_KEEP_DAYS": (r"Raw replays and logs are kept (\d+) days", lambda m: int(m[0])),
    "DAILY_SHARE": (r"\| Players still playing after 1, 7 and 30 days: [^;\n]*; a (\w+) of monthly players "
                    r"play on a given day", lambda m: {"half": (1, 2), "third": (1, 3), "quarter": (1, 4)}.get(m[0])),
    "SEASON_TIERS": (r"(\w+) tiers, climbed with season stars",
                     lambda m: {"Forty": 40, "Fifty": 50, "Sixty": 60, "Seventy": 70, "Eighty": 80,
                                "Ninety": 90, "A hundred": 100}.get(m[0])),
    "PREMIUM_TRACK_EUR": (r"The season pass premium track \(cosmetic\), about €(\d+) a season",
                          lambda m: int(m[0])),
    "SPENDING_CAPS_EUR": (r"\| Purchases\n\| [^\n]*€(\d+) a month cap\n\| €(\d+) a month cap",
                          lambda m: {"13-15": int(m[0]), "16-17": int(m[1])}),
}

#: Facts the document has moved past and this repository has not, each with
#: the register item that owns the gap. Reported as behind, not as agreeing:
#: the simulation still reads these values, so they stay declared until the
#: port lands, and then they go.
BEHIND: dict[str, tuple[str, str]] = {
    # A fact the owner has decided and the document does not state yet: the
    # value above is the decision, and the check holds it to that until the
    # document takes the edit and the item closes.
}


def against_document() -> tuple[list[str], list[str]]:
    """(disagreements, facts behind the document), for every declared fact."""
    import design_doc
    sys.path.insert(0, str(ROOT / "tools"))
    import check_document
    from audit_register import is_open
    doc = check_document.Doc(str(design_doc.HTML))
    index = check_document.section_index(doc)
    wrong, behind = [], []
    for name, (pattern, read) in STATED.items():
        home = HOME[name]
        m = re.search(pattern, index.get(home, ""))
        value = read(m.groups()) if m else None
        if name in BEHIND:
            item, now = BEHIND[name]
            behind.append(f"{name} ({home}): {now} [{item}]")
            if not is_open(item):
                wrong.append(f"{name}: listed as behind under {item}, which "
                             f"the register calls settled")
            if m and value == globals()[name]:
                wrong.append(f"{name}: listed as behind under {item}, but "
                             f"{home} still states {value!r}")
            continue
        if value != globals()[name]:
            wrong.append(f"{name}: declared {globals()[name]!r}, {home} "
                         f"{'states ' + repr(value) if m else 'no longer states it'}")
    unstated = sorted(n for n, h in HOME.items()
                      if not h.startswith("content/") and n not in STATED)
    wrong += [f"{n}: declared with no pattern to check it by" for n in unstated]
    return wrong, behind


def as_json() -> str:
    """Every declared fact, for the tools that cannot import Python — the
    server (server/src/facts.json). Generated, never edited: `--check-json`
    fails when the copy has drifted from this file."""
    facts = {name: globals()[name] for name in HOME}
    return json.dumps(facts, indent=1, sort_keys=True) + "\n"


def main() -> int:
    if "--json" in sys.argv:
        sys.stdout.write(as_json())
        return 0
    if "--check-json" in sys.argv:
        path = pathlib.Path(sys.argv[sys.argv.index("--check-json") + 1])
        if path.read_text(encoding="utf-8") != as_json():
            print(f"{path} has drifted from tools/design_facts.py; regenerate it with "
                  f"python3 tools/design_facts.py --json > {path}")
            return 1
        print(f"{path} matches tools/design_facts.py")
        return 0
    print("What the design document says, and where each tool should read it "
          "from\n")
    width = max(len(k) for k in HOME)
    for name, home in HOME.items():
        value = repr(globals()[name])
        print(f"  {name:<{width}}  {value[:52]:<54}{home}")
    missing = sorted(set(HOME) - set(globals()))
    extra = sorted(n for n in globals()
                   if n.isupper() and len(n) > 2 and n not in HOME
                   and n not in ("ROOT", "CONTENT", "HOME", "STATED", "BEHIND"))
    if missing or extra:
        print(f"\n  HOME and the module disagree: missing {missing}, "
              f"undeclared {extra}")
        return 1
    wrong, behind = against_document()
    if behind:
        print("\n  Behind the document, and owned by a register item:")
        for line in behind:
            print(f"    {line}")
    if wrong:
        print("\n  Declared facts the document no longer states:")
        for line in wrong:
            print(f"    {line}")
        return 1
    print(f"\n  {len(STATED) - len(behind)} declared facts read back from their "
          f"home sections.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
