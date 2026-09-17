#!/usr/bin/env python3
"""Machine checks over the Ruleborn design document.

Every quantitative claim in docs/analysis/ that could be checked mechanically is
checked here, so the analysis can be re-run against a later version of the design
and the findings re-confirmed or retired.

Usage:
    python3 tools/check_design_consistency.py [path to the extracted text]

Checks read their numbers **from the document** wherever they can, so a check
can retire when the document is fixed. An earlier version hard-coded the role
stats and the Vault load rate, which meant those checks would have reported the
same failure against any version — including one that had fixed them.
"""

import collections
import itertools
import re
import sys

DEFAULT_DOC = "docs/design/ruleborn-game-design-v3.1.txt"

# --------------------------------------------------------------------------
# Supersession
# --------------------------------------------------------------------------
#
# §30.18 draws the right lesson from the v2.3 audit: four of six conflicts had
# one cause, a table that summarises something else and was updated in only one
# place. v3.0 then fixed six systems and left copies of four of them standing.
#
# This is the check that lesson implies. Each entry names a decision the document
# has made, and the exact sentences elsewhere that still describe the version it
# replaced. A fix is not finished while any of them is still in the file.
SUPERSESSIONS = [
    dict(
        fix="the detection model",
        winner="12.17",
        said="12.8 states the older single-cone, percent-per-second rules are gone",
        stale=[
            ("+50% a second in sight",
             "29.1, the formulas appendix, still tabulates it — and cites 12.8"),
            ("start at 25% awareness",
             "5.4's landing rule is still written in the deleted percentage unit"),
        ],
    ),
    dict(
        fix="the ambush floor",
        winner="12.8",
        said="12.8 adds a floor of half the target's full health",
        stale=[
            ("First unseen hit: 2 s stun and triple damage",
             "29.1 still gives triple damage with no floor"),
        ],
    ),
    dict(
        fix="the Vault loading rate",
        winner="12.19",
        said="12.19 gives every role 30 units a second",
        stale=[
            ("each Carrier loads 150 loot a second",
             "12.6 still has Carriers only, at five times the rate"),
        ],
    ),
    dict(
        fix="the law rarity split",
        winner="7.7",
        said="the 48 law sheets are re-tagged to 18/12/6/12",
        stale=[
            ("15 pages for a common law",
             "7.6 still prices three ranks, and never mentions Uncommon"),
            ("1,485 pages",
             "14.4's Codex total is still the three-rank arithmetic"),
            ("15, 30 or 60 pages by rank",
             "the glossary and the price list still carry three ranks"),
        ],
    ),
]

#: §12.8's wind-up, read as the universal attack interval — the only cadence the
#: document states, and since v3.0 the one §12.20 adopts explicitly.
WIND_UP = 0.8
AMBUSH_MULTIPLIER = 3.0

LAW_HEADER = re.compile(
    r"^(.+?)(Common|Uncommon|Rare|Deep) · "
    r"(Motion|Matter|Time|Energy|Life|Spirit) · cost (\d+)\s*$"
)
CREATURE_HEADER = re.compile(
    r"^(.+?)(Scout|Breaker|Carrier|Warden|Mender) · "
    r"(Motion|Matter|Time|Energy|Life|Spirit)\s*$"
)

OPPOSITE = {
    "Flow": "Weight", "Weight": "Flow",
    "Glow": "Hush", "Hush": "Glow",
    "Bloom": "Spark", "Spark": "Bloom",
    "Echo": "Veil", "Veil": "Echo",
}

CHORDS = {
    "Tempest": ("Flow", "Spark", "Glow"),
    "Deep sleep": ("Weight", "Hush", "Bloom"),
    "Ghost tide": ("Flow", "Echo", "Hush"),
    "Fair lights": ("Glow", "Bloom", "Veil"),
    "Iron bell": ("Weight", "Echo", "Glow"),
    "Mirage": ("Flow", "Veil", "Glow"),
    "Clockwork": ("Weight", "Spark", "Echo"),
    "Wild hunt": ("Flow", "Spark", "Hush"),
    "Hidden garden": ("Bloom", "Hush", "Veil"),
    "Lantern festival": ("Glow", "Bloom", "Echo"),
    "Quicksand": ("Weight", "Veil", "Hush"),
    "Rebound": ("Flow", "Echo", "Spark"),
}

RULEBORN = [
    "Featherkin", "Skyskipper", "Rambler", "Glass Golem", "Quarryback",
    "Prism Mite", "Tidewalker", "Hourkeeper", "Stillwatch", "Emberling",
    "Stormhound", "Sparkwright", "Mossbear", "Bloomling", "Rootrunner",
    "Echoplate", "Lantern Wisp", "Soulmender",
]
ROLES = ["Scout", "Breaker", "Carrier", "Warden", "Mender"]

failures: list[str] = []


def check(label: str, ok: bool, detail: str = "") -> None:
    print(f"  [{'PASS' if ok else 'FAIL'}] {label}{(': ' + detail) if detail else ''}")
    if not ok:
        failures.append(label)


def parse_laws(lines: list[str]) -> dict:
    laws = {}
    for i, line in enumerate(lines):
        m = LAW_HEADER.match(line.strip())
        if not m:
            continue
        j = i + 1
        while j < len(lines) and not lines[j].strip():
            j += 1
        laws[m.group(1).strip()] = {
            "rank": m.group(2),
            "school": m.group(3),
            "cost": int(m.group(4)),
            "notes": lines[j].split(),
        }
    return laws


def parse_roles_from_table(text: str) -> dict:
    """Roles as given by the 11.2 summary table."""
    start = text.index("11.2 The 18 ruleborn")
    end = text.index("11.3 Traits")
    cells = [l.strip().lstrip("| ").strip() for l in text[start:end].split("\n") if l.strip()]
    out = {}
    for i, cell in enumerate(cells):
        if cell in RULEBORN and i + 2 < len(cells) and cells[i + 2] in ROLES:
            out[cell] = (cells[i + 1], cells[i + 2])
    return out


def parse_roles_from_bible(lines: list[str]) -> dict:
    """Roles as given by the 11.11 character bible."""
    out = {}
    for line in lines:
        m = CREATURE_HEADER.match(line.strip())
        if m and m.group(1).strip() in RULEBORN:
            out[m.group(1).strip()] = (m.group(3), m.group(2))
    return out


def section(text: str, start: str, end: str) -> str:
    """The text between two headings, raising rather than slicing backwards."""
    i = text.index(start)
    j = text.index(end, i)
    if j <= i:
        raise SystemExit(f"section({start!r}, {end!r}) is inverted")
    return text[i:j]


def parse_role_stats(text: str) -> dict:
    """§11.1's role table: Health, Speed, Power, Carry.

    Parsed rather than transcribed, so re-tuning the table re-runs every fight
    and Vault check below against the new numbers.
    """
    block = section(text, "11.1 Roles", "11.2 The 18 ruleborn")
    cells = [l.strip().lstrip("| ").strip() for l in block.split("\n") if l.strip()]
    out = {}
    for i, cell in enumerate(cells):
        if cell in ROLES and i + 4 < len(cells):
            try:
                health, speed, power, carry = (
                    float(cells[i + 1]), float(cells[i + 2]),
                    float(cells[i + 3]), float(cells[i + 4]),
                )
            except ValueError:
                continue
            out[cell] = dict(health=health, speed=speed, power=power, carry=carry)
    return out


def parse_load_rates(text: str) -> list[tuple[str, float, bool]]:
    """Every statement in the document about how fast loot is loaded.

    Returns (quoted phrase, units per second, everyone-loads). More than one
    distinct rate is the finding: it means the phase is specified twice.
    """
    out = []
    for m in re.finditer(
        r"(each Carrier loads (\d+) loot a second"
        r"|Every role can load, at (\d+) units a second"
        r"|loads (\d+) loot a second)", text
    ):
        phrase = m.group(1)
        rate = float(next(g for g in m.groups()[1:] if g))
        out.append((phrase, rate, "Every role" in phrase))
    return out


def parse_rank_table(text: str) -> dict:
    """§7.10's Rank / Count / Pages table."""
    block = section(text, "7.9 Rarity buys specificity", "This follows the published")
    cells = [l.strip().lstrip("| ").strip() for l in block.split("\n") if l.strip()]
    out = {}
    for i, cell in enumerate(cells):
        if cell in ("Common", "Uncommon", "Rare", "Deep", "Paradox") and i + 3 < len(cells):
            try:
                count = int(cells[i + 1])
                pages = int(cells[i + 3])
            except ValueError:
                continue
            out[cell] = (count, pages)
    return out


def parse_restore_costs(text: str) -> str | None:
    """§7.6's one-line statement of what a law costs to restore."""
    m = re.search(r"Restoring a law: ([^\n]+)", text)
    return m.group(1).strip() if m else None


def ambush_has_floor(text: str) -> bool:
    """Whether §12.8's ambush carries the health floor that makes its own rule true."""
    block = section(text, "12.8 Guards, stealth and fights", "12.9 Outcomes")
    return bool(re.search(r"half the guard's full health|half the target's", block))


def main() -> int:
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DOC
    text = open(path, encoding="utf-8").read()
    lines = text.split("\n")
    laws = parse_laws(lines)

    print("\nContent counts")
    check("48 laws specified in 7.7", len(laws) == 48, f"{len(laws)} found")
    schools = collections.Counter(d["school"] for d in laws.values())
    check("8 laws per school", set(schools.values()) == {8}, str(dict(schools)))
    ranks = collections.Counter(d["rank"] for d in laws.values())
    stated = parse_rank_table(text)
    stated_counts = {k: v[0] for k, v in stated.items() if k != "Paradox"}
    check(
        "the authored law sheets match 7.10's own rank table",
        dict(ranks) == stated_counts,
        f"authored {dict(ranks)} against 7.10's {stated_counts}",
    )

    # 7.10 prices each rank in pages; 7.6 states the same thing in a sentence.
    restore = parse_restore_costs(text)
    stated_pages = {k: v[1] for k, v in stated.items()}
    missing = [r for r in ranks if restore and r.lower() not in restore.lower()]
    agrees = restore is not None and all(
        str(pages) in restore for rank, pages in stated_pages.items() if rank in ranks
    )
    check(
        "7.6's restore costs match 7.10's pages column",
        agrees and not missing,
        f"7.10 prices {stated_pages}; 7.6 says {restore!r}"
        + (f"; it never mentions {', '.join(missing)}" if missing else ""),
    )

    print("\nNote economy (8.1)")
    by_note = collections.defaultdict(list)
    for name, d in laws.items():
        for note in d["notes"]:
            by_note[note].append(name)
    sizes = {k: len(v) for k, v in sorted(by_note.items(), key=lambda kv: -len(kv[1]))}
    print(f"        note pools: {sizes}")
    worst = max(OPPOSITE.items(), key=lambda ab: abs(len(by_note[ab[0]]) - len(by_note[ab[1]])))
    a, b = worst
    check(
        "opposite note pairs are within 2 laws of each other",
        all(abs(len(by_note[x]) - len(by_note[y])) <= 2 for x, y in OPPOSITE.items()),
        f"{a} {len(by_note[a])} vs {b} {len(by_note[b])}",
    )
    # 8.8 states the rebalance as done. The law sheets are where it would show.
    claims_rebalance = "eight or nine laws per note" in text
    check(
        "8.8's claim that the note table 'now runs eight or nine laws per note' holds",
        not claims_rebalance or set(sizes.values()) <= {8, 9},
        f"the section claims it; the 48 law sheets give {sizes}",
    )

    print("\nChord reachability (8.5)")
    min_laws = {}
    for chord, notes in CHORDS.items():
        banned = {OPPOSITE[n] for n in notes}
        pool = [
            n for n, d in laws.items()
            if set(d["notes"]) & set(notes) and not set(d["notes"]) & banned
        ]
        best = None
        for k in (1, 2, 3):
            for combo in itertools.combinations(pool, k):
                covered = set().union(*(set(laws[n]["notes"]) for n in combo))
                if set(notes) <= covered:
                    best = k
                    break
            if best:
                break
        min_laws[chord] = best
    print(f"        minimum laws per chord: {collections.Counter(min_laws.values())}")
    two_note = sum(1 for d in laws.values() if len(d["notes"]) > 1)
    requires_distinct = "three distinct laws" in text
    check(
        "8.5 requires three distinct laws, not three notes",
        requires_distinct,
        f"{two_note} of {len(laws)} laws carry two notes, so "
        f"all 12 chords are reachable with {min(min_laws.values())} laws "
        "unless the rule names distinct laws",
    )

    print("\nRuleborn roles (11.2 vs 11.11)")
    table = parse_roles_from_table(text)
    bible = parse_roles_from_bible(lines)
    conflicts = [n for n in RULEBORN if table.get(n) != bible.get(n)]
    check(
        "11.2 and 11.11 agree on every ruleborn's school and role",
        not conflicts,
        ", ".join(f"{n}: {table.get(n)} vs {bible.get(n)}" for n in conflicts),
    )

    print("\nRaid economy (9.4 vs 9.6)")
    six_raids = sum(0.85 ** i for i in range(6))     # 9.6 fatigue curve
    per_attempt = 0.46                               # 9.6: attempt ≈ 46% of a clean haul
    daily_production = {31: 17_300, 181: 152_800, 301: 256_100}   # 9.3, engaged player
    for day, (level, production) in zip(
        daily_production, [(6, 17_300), (10, 152_800), (10, 256_100)]
    ):
        base = 100 * 1.5 ** (level - 1)
        raids = base * per_attempt * six_raids
        share = raids / (raids + production)
        print(f"        day {day:>3}: raids {raids:>9,.0f} vs production {production:>9,} -> {share:6.1%} of income")
    day31 = 100 * 1.5 ** 5 * per_attempt * six_raids
    check(
        "heists supply 'roughly a third' of resources (9.4) / '40% of mid-game growth' (12.1)",
        day31 / (day31 + 17_300) > 0.25,
        "the 9.6 formula yields 3-8%, an order of magnitude below the stated target",
    )

    print("\nFights (12.8, 11.1)")
    role_stats = parse_role_stats(text)
    floor = 0.5 if ambush_has_floor(text) else 0.0
    check(
        "the ambush rule is stated with a health floor (12.8)",
        floor > 0,
        f"a floor of {floor:.0%} of the target's full health" if floor
        else "triple Power alone; without a floor the rule below cannot hold",
    )

    def ambush_damage(power: float, health: float) -> float:
        return max(AMBUSH_MULTIPLIER * power, floor * health)

    holds = sum(
        1
        for a in role_stats.values()
        for d in role_stats.values()
        if 2 * ambush_damage(a["power"], d["health"]) >= d["health"]
    )
    check(
        "two ambush hits knock out an equal-level guard (12.8)",
        holds == len(role_stats) ** 2,
        f"true for {holds} of {len(role_stats) ** 2} role pairings"
        + ("" if holds == len(role_stats) ** 2 else
           "; the rule needs Power = Health/4 and no role reaches it"),
    )

    print("\nThe Vault phase (12.6, 12.19, 11.1)")
    rates = parse_load_rates(text)
    distinct = sorted({r for _, r, _ in rates})
    check(
        "the document states one loading rate",
        len(distinct) <= 1,
        "two rates are live: " + "; ".join(f"{p!r} = {r:.0f}/s" for p, r, _ in rates)
        + " — the superseded one was not deleted",
    )
    everyone_loads = any(every for _, _, every in rates)
    capacity = sum(r["carry"] for r in role_stats.values())
    carrier = role_stats["Carrier"]["carry"]
    check(
        "a crew of five can fill its bags",
        everyone_loads,
        f"every role loads, so all {capacity:.0f} units are reachable" if everyone_loads
        else f"{capacity - carrier:.0f} of {capacity:.0f} units of crew capacity are "
             f"unreachable: only Carriers load, and only into themselves",
    )
    slowest = min(distinct) if distinct else 0
    fill = max(r["carry"] for r in role_stats.values()) / slowest if slowest else 0
    check(
        "loading lasts long enough to contain a decision (12.6: one per 8-12s)",
        fill >= 8,
        f"a full bag at {slowest:.0f}/s takes {fill:.1f}s",
    )
    volley = sum(r["power"] * (2 if n == "Breaker" else 1) for n, r in role_stats.items())
    crack = (1_500 * 6) / (volley * 1.08 ** 11 / WIND_UP)
    check(
        "cracking a level-6 Vault fits the 30-second phase (12.6)",
        20 <= crack <= 30,
        f"{crack:.0f}s at one hit per 0.8s for Power damage",
    )

    print("\nWards and pylons (11.1, 10.2, 12.6)")
    breaker = role_stats["Breaker"]["power"] * 2
    check(
        "'who cracks' is a decision (12.6) rather than always the Breaker",
        breaker / volley < 0.5,
        f"the Breaker is {100 * breaker / volley:.0f}% of the crew's damage against "
        f"wards, pylons and the Vault, so four extra characters cut the time by "
        f"{100 * (1 - breaker / volley):.0f}%",
    )
    ward_block = section(text, "10.3 Wards", "10.4 The Library")
    check(
        "every ward's '+15% effect' names one quantity (10.2, 10.3)",
        "scales" in ward_block or "the level scales" in ward_block,
        "10.3 gives level-1 effects in six different units and 10.2 prices five "
        "levels as '+15% effect'; nothing says which number the percentage moves",
    )

    print("\nSupersession — is each fix finished?")
    for entry in SUPERSESSIONS:
        survivors = [(phrase, where) for phrase, where in entry["stale"] if phrase in text]
        check(
            f"{entry['fix']} is stated once ({entry['winner']})",
            not survivors,
            "; ".join(where for _, where in survivors),
        )

    print("\nStability arithmetic (5.5)")
    capacity = (30 + 8 * 10) + 7 * (8 + 5 * 10)
    check("Spire 10 + seven Anchor Stones 10 = 516 stability", capacity == 516, str(capacity))
    max_slots = 2 + 6 * 3 + 2     # Heart realm laws + six outer realms at level 5 + two crown
    check("a finished universe weaves 22 laws", max_slots == 22, str(max_slots))

    print("\nBusiness case (22.2)")
    low = 20_000 * 0.02 * 8 * 0.85
    base = 100_000 * 0.03 * 10 * 0.85
    high_15 = 500_000 * 0.04 * 12 * 0.85
    high_30 = 500_000 * 0.04 * 12 * 0.70
    check("low scenario ≈ €2,700 at 15% commission", round(low) == 2720, f"€{low:,.0f}")
    check("base scenario ≈ €25,500 at 15% commission", round(base) == 25500, f"€{base:,.0f}")
    check(
        "high scenario ≈ €168,000 at the stated 15% commission (22.5)",
        abs(high_15 - 168_000) < 1000,
        f"15% gives €{high_15:,.0f}; the quoted €168,000 is 30% (€{high_30:,.0f}) — "
        "defensible, since that scenario crosses the $1M small-business threshold, "
        "but it contradicts 22.5",
    )

    print(f"\n{len(failures)} inconsistencies confirmed:")
    for f in failures:
        print(f"  - {f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
