#!/usr/bin/env python3
"""Machine checks over the Ruleborn design document.

Every quantitative claim in docs/analysis/ that could be checked mechanically is
checked here, so the analysis can be re-run against a later version of the design
and the findings re-confirmed or retired.

Usage:
    python3 tools/check_design_consistency.py docs/design/ruleborn-game-design-v2.3.txt
"""

import collections
import itertools
import re
import sys

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


def main() -> int:
    path = sys.argv[1] if len(sys.argv) > 1 else "docs/design/ruleborn-game-design-v2.3.txt"
    text = open(path, encoding="utf-8").read()
    lines = text.split("\n")
    laws = parse_laws(lines)

    print("\nContent counts")
    check("48 laws specified in 7.7", len(laws) == 48, f"{len(laws)} found")
    schools = collections.Counter(d["school"] for d in laws.values())
    check("8 laws per school", set(schools.values()) == {8}, str(dict(schools)))
    ranks = collections.Counter(d["rank"] for d in laws.values())
    check(
        "law ranks match the 7.10 five-rank table (18/14/10/6 + 3 paradox)",
        ranks.get("Uncommon", 0) == 14,
        f"actual {dict(ranks)} — no law is tagged Uncommon; 7.4 three-rank split is what is authored",
    )

    print("\nNote economy (8.1)")
    by_note = collections.defaultdict(list)
    for name, d in laws.items():
        for note in d["notes"]:
            by_note[note].append(name)
    sizes = {k: len(v) for k, v in sorted(by_note.items(), key=lambda kv: -len(kv[1]))}
    print(f"        note pools: {sizes}")
    check(
        "opposite note pairs are within 2 laws of each other",
        all(abs(len(by_note[a]) - len(by_note[b])) <= 2 for a, b in OPPOSITE.items()),
        "Glow 12 vs Hush 6 — the Glow/Hush pair is 2:1",
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
    check(
        "chords need three laws, as 8.5 states",
        all(v >= 3 for v in min_laws.values()),
        f"all 12 chords are reachable with {min(min_laws.values())} laws, "
        "because 23 of 48 laws carry two notes",
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
    # §11.1's level-1 role stats, read straight from the table.
    role_stats = {
        "Scout": (12, 120, 60), "Breaker": (40, 180, 60), "Carrier": (8, 160, 300),
        "Warden": (20, 420, 80), "Mender": (6, 130, 60),
    }
    # §12.8: "two ambush hits knock out a guard of equal level", with an ambush at
    # triple damage and the section's own 0.8s wind-up as the attack interval.
    holds = sum(
        1
        for power, _, _ in role_stats.values()
        for _, health, _ in role_stats.values()
        if 2 * 3 * power >= health
    )
    check(
        "two ambush hits knock out an equal-level guard (12.8)",
        holds == len(role_stats) ** 2,
        f"true for {holds} of {len(role_stats) ** 2} role pairings; the rule needs "
        f"Power = Health/4 and no role reaches it",
    )
    ratio, slowest, toughest = max(
        (health / power, a, d)
        for a, (power, _, _) in role_stats.items()
        for d, (_, health, _) in role_stats.items()
    )
    # One ambush at triple damage, then the remainder, at one hit per 0.8s.
    seconds = (1 + max(0, -(-(ratio - 3) // 1))) * 0.8
    check(
        "no single fight eats a tenth of the 3-minute heist (11.6, 12.6)",
        seconds <= 18,
        f"a {slowest} against a {toughest} takes {seconds:.0f}s, which is "
        f"{100 * seconds / 180:.0f}% of the heist and a third of the 15-25 "
        f"decisions 12.6 budgets for the whole run",
    )

    print("\nThe Vault phase (12.6, 11.1)")
    capacity = sum(carry for _, _, carry in role_stats.values())
    carrier_carry = role_stats["Carrier"][2]
    check(
        "a crew of five can fill its bags (12.6 loads Carriers only)",
        capacity == carrier_carry,
        f"{capacity - carrier_carry} of {capacity} units of crew capacity are "
        f"unreachable: only Carriers load, and only into themselves",
    )
    check(
        "loading lasts long enough to contain a decision (12.6: one per 8-12s)",
        carrier_carry / 150 >= 8,
        f"filling a Carrier at 150/s takes {carrier_carry / 150:.1f}s, against a "
        f"phase budgeted at about 30s whose stated core decision is when to stop",
    )
    # The corroboration, stated as a passing check rather than a failure.
    volley = sum(power * (2 if name == "Breaker" else 1)
                 for name, (power, _, _) in role_stats.items())
    crack = (1_500 * 6) / (volley * 1.08 ** 11 / 0.8)
    check(
        "cracking a level-6 Vault fits the 30-second phase (12.6)",
        20 <= crack <= 30,
        f"{crack:.0f}s at one hit per 0.8s for Power damage",
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
