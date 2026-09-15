#!/usr/bin/env python3
"""Price the open decisions, so they can be made from numbers rather than argument.

    python3 tools/decision_support.py            # every report
    python3 tools/decision_support.py rarity     # one

These do not pick. Each report lays out what every option costs, using the
content tables and the economy model, and says plainly which parts are a matter
of taste rather than arithmetic.

  rarity   C3 / Q3 — three law ranks or five?
  haul     C4 / C2 — what is L in B(L), and what growth rate would meet the
                     document's own stated target for raid income?
"""

import collections
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from tools.economy_model import data as econ                      # noqa: E402
from tools.economy_model.config import Config                     # noqa: E402
from tools.economy_model.model import EconomyModel                # noqa: E402

CONTENT = ROOT / "content"


def load(name: str) -> list[dict]:
    return json.loads((CONTENT / f"{name}.json").read_text(encoding="utf-8"))


# ---------------------------------------------------------------------------
# C3 — three ranks or five?
# ---------------------------------------------------------------------------

#: §7.6 and §9.5, the three-rank costs actually used by §14.4.
THREE_RANK_PAGES = {"Common": 15, "Rare": 30, "Deep": 60}
#: §7.10's five-rank table.
FIVE_RANK_PAGES = {"Common": 10, "Uncommon": 20, "Rare": 35, "Deep": 60, "Paradox": 120}
FIVE_RANK_COUNTS = {"Common": 18, "Uncommon": 14, "Rare": 10, "Deep": 6}

FREE_AT_START = 3          # Half gravity, Slow rivers, Bloom (§7.6)
PAGES_PER_DAY = 11         # §14.4, an engaged player
TIER_PAGES_PER_LAW = 60    # §14.4: tier II +20, tier III +40
WEAVABLE_AT_ONCE = 22      # §5.5


def rarity_report() -> None:
    laws = load("laws")
    counts = collections.Counter(law["rank"] for law in laws)

    print("C3 / Q3 — three law ranks, or five?\n")
    print("What is authored today (§7.4, §7.7, parsed from all 48 law sheets):")
    print(f"  {dict(counts)}   pages {THREE_RANK_PAGES}\n")
    print("What §7.10 and §27.2 describe:")
    print(f"  {FIVE_RANK_COUNTS} + 3 paradoxes   pages {FIVE_RANK_PAGES}\n")

    def total(counts_map, pages_map):
        # The three free starting laws are commons.
        out, first = 0, True
        for rank, n in counts_map.items():
            if first:
                n -= FREE_AT_START
                first = False
            out += n * pages_map[rank]
        return out

    three = total({"Common": counts["Common"], "Rare": counts["Rare"],
                   "Deep": counts["Deep"]}, THREE_RANK_PAGES)
    five = total(dict(FIVE_RANK_COUNTS), FIVE_RANK_PAGES)
    tiers = WEAVABLE_AT_ONCE * TIER_PAGES_PER_LAW

    print(f"{'':<26}{'three ranks':>14}{'five ranks':>14}")
    print(f"{'pages to restore all 48':<26}{three:>14,}{five:>14,}")
    print(f"{'pages for tiers II and III':<26}{tiers:>14,}{tiers:>14,}")
    print(f"{'total':<26}{three + tiers:>14,}{five + tiers:>14,}")
    print(f"{'days at 11 pages a day':<26}{(three + tiers) / PAGES_PER_DAY:>14,.0f}"
          f"{(five + tiers) / PAGES_PER_DAY:>14,.0f}")
    print(f"\n§14.3 publishes 'all 48 laws' on day 235 for an engaged player, and")
    print(f"§14.4's own 1,485-page figure is the three-rank total, confirming which")
    print(f"taxonomy generated the published curve.")
    print(f"\nFive ranks is {100 * (1 - five / three):.0f}% cheaper to complete, so adopting it")
    print(f"without re-tuning pulls the collection in by about "
          f"{(three - five) / PAGES_PER_DAY:.0f} days.\n")

    # -- where would the 14 Uncommons come from? --------------------------
    print("If five ranks is chosen, 14 of the 18 Rares must become Uncommon.")
    print("§7.10 says rarity tracks complexity, effect size and excitement — not")
    print("power. Three proxies for that are in the data:\n")

    res = load("resonances")
    degree = collections.Counter(lid for r in res for lid in r["laws"])
    rares = [law for law in laws if law["rank"] == "Rare"]
    scored = []
    for law in rares:
        scored.append((
            law["stability_cost"],
            len(law["notes"]),
            degree.get(law["id"], 0),
            law["name"], law["school"],
        ))
    scored.sort()
    print(f"  {'law':<16}{'school':<9}{'cost':>5}{'notes':>7}{'resonances':>12}")
    for cost, notes, deg, name, school in scored:
        print(f"  {name:<16}{school:<9}{cost:>5}{notes:>7}{deg:>12}")
    cheap = [s[3] for s in scored[:14]]
    print(f"\n  Cheapest 14 by stability cost: {', '.join(cheap)}")
    print("  That is one defensible split and it is not the only one. Cost is a")
    print("  power proxy, and §7.10 is explicit that rarity should not track power —")
    print("  so this is a starting point for a judgement, not an answer.\n")


# ---------------------------------------------------------------------------
# C4 / C2 — what is L, and what growth rate would meet the stated target?
# ---------------------------------------------------------------------------

def haul_report() -> None:
    print("C4 / C2 — what is L in B(L) = 100 x 1.5^(L-1)?\n")
    print("§9.6 calls this 'the master inflation lever'. §5.2 caps outer realms at")
    print("level 5; §9.6's own table quotes levels 2, 6 and 10; §9.4 attributes the")
    print("same sealed-share curve to the Vault, which does run 1-10.\n")

    six = sum(econ.HAUL_FATIGUE ** i for i in range(6))
    per_attempt = econ.HAUL_VALUE_PER_ATTEMPT

    print("What each reading pays, and what share of income that is:\n")
    print(f"{'reading':<22}{'L at day 181':>13}{'B(L)':>9}{'6 raids/day':>13}{'share':>8}")
    for label, source in (("Vault level (1-10)", "vault"),
                          ("realm level (1-5)", "realm"),
                          ("Keeper level / 4", "keeper_div_4")):
        model = EconomyModel(Config(archetype="engaged", days=181,
                                    haul_level_source=source, faucet="minted"))
        state = model.run()
        row = state.log[-1]
        level = model.cfg.haul_level(model.vault_level(), model.mean_realm_level(),
                                     state.keeper_level)
        base = econ.HAUL_BASE * econ.HAUL_GROWTH ** (level - 1)
        raids = base * per_attempt * six
        share = raids / (raids + row["starlight_per_day"])
        print(f"{label:<22}{level:>13}{base:>9,.0f}{raids:>13,.0f}{share:>7.1%}")

    print(f"\n§9.4's target is that a successful heist brings about a fifth of a day's")
    print(f"production, so heists supply 'roughly a third' of resources; §12.1 says")
    print(f"40% of mid-game growth. None of the three readings comes close.\n")

    # -- what growth rate WOULD hit the target? ---------------------------
    print("What growth rate would meet the target, if L is Vault level:\n")
    print(f"{'day':>5}{'production/day':>16}{'B(L) needed':>13}{'L':>4}{'growth needed':>15}")
    for day in (31, 91, 181, 301):
        model = EconomyModel(Config(archetype="engaged", days=day, faucet="share"))
        state = model.run()
        row = state.log[-1]
        production = row["starlight_per_day"]
        target_share = 1 / 3
        raids_needed = target_share / (1 - target_share) * production
        base_needed = raids_needed / (per_attempt * six)
        level = max(2, model.vault_level())
        growth = (base_needed / econ.HAUL_BASE) ** (1 / (level - 1))
        print(f"{day:>5}{production:>16,.0f}{base_needed:>13,.0f}{level:>4}{growth:>15.2f}")

    print("\nThe growth rate needed is not constant, and that is the real finding.")
    print("Production compounds as 1.35^level across a growing number of buildings;")
    print("the haul compounds as g^L across a handful of Vault levels. They are")
    print("different curves, so no single exponential holds the ratio steady — the")
    print("share drifts whichever g is chosen.\n")
    print("Three ways out, in increasing order of honesty:")
    print("  1. Pick g for the mid-game and accept drift at both ends.")
    print("  2. Peg the haul to the player's own production directly, which is what")
    print("     §9.4 did, and keep §9.6's grade, difficulty, fatigue and caps on top.")
    print("     That preserves everything §9.6 argued for except the level term.")
    print("  3. Accept that raids are a PAGE faucet, not a resource one (§7.6 already")
    print("     says pages are the reason to raid), and rewrite §9.4 and §12.1 to")
    print("     stop claiming a third of resources.\n")
    print("Option 2 deserves a hard look. §9.6's argument against a percentage is")
    print("that loot here is minted rather than transferred, so tying it to what a")
    print("DEFENDER hoards would tie inflation to behaviour nobody controls. Pegging")
    print("to the RAIDER's own production has no such problem: it is the same")
    print("quantity the progression curve is already built on.")


REPORTS = {"rarity": rarity_report, "haul": haul_report}


def main() -> int:
    if len(sys.argv) > 1:
        name = sys.argv[1]
        if name not in REPORTS:
            print(f"unknown report {name!r}; choose from {', '.join(REPORTS)}",
                  file=sys.stderr)
            return 2
        REPORTS[name]()
        return 0
    for i, fn in enumerate(REPORTS.values()):
        if i:
            print("\n" + "=" * 72 + "\n")
        fn()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
