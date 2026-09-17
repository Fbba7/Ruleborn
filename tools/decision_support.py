#!/usr/bin/env python3
"""Price the open decisions, so they can be made from numbers rather than argument.

    python3 tools/decision_support.py            # every report
    python3 tools/decision_support.py rarity     # one

These do not pick. Each report lays out what every option costs, using the
content tables and the economy model, and says plainly which parts are a matter
of taste rather than arithmetic.

  rarity    C3 / Q3 — three law ranks or five?
  haul      C4 / C2 — what is L in B(L), and what growth rate would meet the
                      document's own stated target for raid income?
  staffing  F1 / Q1 — is character scarcity a feature, and which lever moves?
  combat    G2      — what the document's own Power and Health numbers imply
                      about fights, and which of its stated rules they contradict
  vault     G4      — how long cracking and loading take, and where the
                      "when to stop loading" decision actually sits
  wards     G3 / G5 — what "effect +15%" scales, what a ward costs to get past,
                      and how much of a heist a law pylon is worth
  pacing    Q6 / Q3 — what §5.8 did to the casual curve, and what the Library
                      did to the page economy the rank split was argued on
"""

import collections
import json
import math
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
#: §7.9's five-rank table.
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
    print("What §7.9 and §27.2 describe:")
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
    print("§7.9 says rarity tracks complexity, effect size and excitement — not")
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
    print("  power proxy, and §7.9 is explicit that rarity should not track power —")
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


# ---------------------------------------------------------------------------
# F1 / Q1 — is character scarcity a feature, and which lever moves?
# ---------------------------------------------------------------------------

GUARD_POSTS = 6 * 3 + 3        # §5.2, outer realms at level 5, plus the Heart
CREW = 5                       # §12.5, from Keeper level 16
BIRTH_BASE, BIRTH_GROWTH = 100, 1.15   # §9.5


def staffing_report() -> None:
    roster = 3 + 7 * econ.HEARTH_HOMES[-1]
    slots_each = econ.BUILDINGS["Star Well"].slots[-1]

    print("F1 / Q1 — is character scarcity a feature, and which lever moves?\n")

    print("The staffing curve makes spreading thin strictly optimal (§9.2):")
    for n in range(1, 4):
        print(f"    {n} worker{'s' if n > 1 else ' '} -> {econ.STAFFING[n]:.0%}"
              f"   marginal gain {econ.STAFFING[n] - econ.STAFFING[n - 1]:+.0%}")
    print("  Decreasing, so a player fills the FIRST slot of every building before")
    print("  any second. That matters more than it looks.\n")

    print(f"{'':<24}{'2 producers/realm':>20}{'1 producer/realm':>20}")
    rows = {}
    for per_realm in (2, 1):
        buildings = 7 * per_realm * 3
        rows[per_realm] = {
            "buildings": buildings,
            "slots": buildings * slots_each,
            "workers": max(0, roster - GUARD_POSTS - CREW),
            "empty": max(0, buildings - max(0, roster - GUARD_POSTS - CREW)),
        }
        r = rows[per_realm]
        r["output"] = min(r["workers"], buildings) * econ.STAFFING[1]
        r["nameplate_pct"] = r["output"] / buildings
    for key, label in (("buildings", "producing buildings"),
                       ("slots", "worker slots"),
                       ("workers", "workers actually free"),
                       ("empty", "buildings left empty")):
        print(f"{label:<24}{rows[2][key]:>20}{rows[1][key]:>20}")
    print(f"{'output vs nameplate':<24}{rows[2]['nameplate_pct']:>19.0%}"
          f"{rows[1]['nameplate_pct']:>20.0%}")

    print(f"\n  Roster is {roster} (3 at the Spire + 7 Hearths x "
          f"{econ.HEARTH_HOMES[-1]} homes, §11.5). Post the {GUARD_POSTS} guard")
    print(f"  posts §5.2 allows and field a crew of {CREW}, and "
          f"{max(0, roster - GUARD_POSTS - CREW)} characters are left to work.")
    print("\n  Consequence: NO second or third worker slot is ever worth filling.")
    print("  §10.2 grants a second slot at building level 4 and a third at level 7.")
    print("  Both are dead content under this roster — and §14.3 still lists")
    print("  'every Star Well at level 10' (day 316) and 'everything built and at")
    print("  its highest level' (day 378) as milestones.\n")

    print("A second, independent cap agrees with the first (§9.5):\n")
    print(f"    {'nth ruleborn':>14}{'Essence':>16}")
    for n in (30, 38, 50, 89):
        print(f"    {n:>14}{BIRTH_BASE * BIRTH_GROWTH ** n:>16,.0f}")
    print("\n  The birth curve caps the roster in the same place the Hearths do.")
    print("  Both halves of the character economy say ~30-40. The building rules")
    print("  ask for 152 positions. They were sized independently.\n")

    print("The three levers, priced:\n")
    print("  A. Raise the roster to match the buildings.")
    print(f"     Needs ~{rows[1]['slots'] + GUARD_POSTS + CREW} characters for one producer per realm.")
    print("     Requires changing BOTH caps: Hearth homes ~3x, and the birth")
    print(f"     growth rate, since the 89th ruleborn currently costs "
          f"{BIRTH_BASE * BIRTH_GROWTH ** 89:,.0f} Essence")
    print("     — about 200 days of an engaged player's entire Essence production.")
    print("     Cost: the Essence sink disappears, and §4's claim that characters'")
    print("     time is scarce goes with it.\n")
    print("  B. Cut the buildings to match the roster.")
    print("     One producer of each kind per realm, one worker slot each: 21 slots,")
    print(f"     {GUARD_POSTS} guard posts, a crew of {CREW} = "
          f"{21 + GUARD_POSTS + CREW} positions against {roster}.")
    print("     Cost: removes a Starlight sink, and §10.2's level-4 and level-7")
    print("     slot grants become meaningless and should be deleted.\n")
    print("  C. Keep the shortage and design around it.")
    print("     Then §9.3's production figures must be recomputed at the staffing")
    print("     a player can actually reach — about a third of nameplate — and the")
    print("     second and third slots deleted, since they can never be filled.")
    print("     Cost: honest, but it makes 'everything built and at its highest")
    print("     level' describe a universe that is two-thirds idle.\n")
    print("  This is a design choice, not arithmetic. What is NOT a choice is")
    print("  leaving all three tables as they are: they cannot all be right.")



# ---------------------------------------------------------------------------
# G2 — what a guard does when it catches you
# ---------------------------------------------------------------------------

#: §12.8 gives a 0.8-second wind-up before every guard attack. It is the only
#: cadence in the document, so the model reads it as the universal attack
#: interval: one hit per 0.8 s, for damage equal to the attacker's Power.
WIND_UP = 0.8
#: §12.8: the first hit on a guard that has not noticed the crew.
AMBUSH_MULTIPLIER = 3.0
#: §11.4: +8% health and power per character level.
LEVEL_GROWTH = 1.08


def hits_to_knock_out(power: float, health: float, ambush_floor: float = 0.0) -> int:
    """Hits to drop a target, the first one an ambush.

    ``ambush_floor`` is the proposed repair: an ambush hit deals triple Power or
    this fraction of the target's maximum health, whichever is greater.
    """
    first = max(power * AMBUSH_MULTIPLIER, health * ambush_floor)
    if first >= health:
        return 1
    return 1 + math.ceil((health - first) / power)


def combat_report() -> None:
    roles = {r["name"]: r for r in load("roles")}
    names = list(roles)

    print("G2 — fights, from the document's own numbers\n")
    print("§11.1 gives Power and Health. §12.8 gives a 0.8-second wind-up, an")
    print("ambush rule and a level cap, and then states:\n")
    print('  "Two ambush hits knock out a guard of equal level."\n')
    print("There is no attack rate and no damage formula, so this report assumes")
    print("the only cadence the document states — one hit per 0.8 s for damage")
    print("equal to Power — and asks whether that sentence is true.\n")

    print("Hits to knock out an equal-level guard, the first hit an ambush:\n")
    print(f"  {'raider':<9}" + "".join(f"{n:>9}" for n in names))
    for a in names:
        row = "".join(
            f"{hits_to_knock_out(roles[a]['power'], roles[d]['health']):>9}" for d in names
        )
        print(f"  {a:<9}{row}")

    print("\n  ...and in seconds at one hit per 0.8 s:\n")
    print(f"  {'raider':<9}" + "".join(f"{n:>9}" for n in names))
    for a in names:
        row = "".join(
            f"{hits_to_knock_out(roles[a]['power'], roles[d]['health']) * WIND_UP:>8.1f}s"
            for d in names
        )
        print(f"  {a:<9}{row}")

    two_hits = [(a, d) for a in names for d in names
                if hits_to_knock_out(roles[a]["power"], roles[d]["health"]) <= 2]
    two_ambush = [(a, d) for a in names for d in names
                  if 2 * AMBUSH_MULTIPLIER * roles[a]["power"] >= roles[d]["health"]]

    print(f"\n  The stated rule holds for {len(two_hits)} of 25 pairings read as")
    print("  ambush-then-strike, and for "
          f"{len(two_ambush)} of 25 read as two simultaneous ambushes:")
    print(f"    {', '.join(a + '->' + d for a, d in two_ambush)}")
    print("  Four of those five need a Breaker. The ratio the rule needs is")
    print("  Power = Health / 4; what the roles have is:\n")
    for n, r in roles.items():
        ratio = r["power"] / r["health"]
        print(f"    {n:<9} {r['power']:>3} / {r['health']:>3} = {ratio:.3f}"
              f"   {0.25 / ratio:>4.1f}x short")
    print("\n  No role reaches it. The Breaker is close; the other four are two")
    print("  and a half to five times below, so the sentence is not a rounding")
    print("  error — Power and Health were set for standing fights and the")
    print("  ambush rule was written against them without being checked.\n")

    print("  A repair that makes the sentence true by construction: an ambush hit")
    print("  deals triple Power OR half the target's maximum health, whichever is")
    print("  greater. Two ambushers then drop any equal-level guard, in all 25")
    print("  pairings, exactly as §12.8 says. A lone ambusher still has to finish")
    print("  the job, but is no longer wasting its time — seconds to knock out,")
    print("  with the old figure alongside:\n")
    print(f"  {'raider':<9}" + "".join(f"{n:^13}" for n in names))
    for a in names:
        cells = []
        for d in names:
            was = hits_to_knock_out(roles[a]["power"], roles[d]["health"]) * WIND_UP
            now = hits_to_knock_out(roles[a]["power"], roles[d]["health"], 0.5) * WIND_UP
            cells.append(f"{was:>5.1f}->{now:<6.1f}")
        print(f"  {a:<9}" + "".join(cells))
    print("\n  Drafted in docs/design/spec/fights.md.")


# ---------------------------------------------------------------------------
# G4 — the Vault and the loading loop
# ---------------------------------------------------------------------------

VAULT_HEALTH_PER_LEVEL = 1_500        # §12.6
CRACKING_AWARENESS_PER_5S = 10        # §12.6, percent added to Heart guards
LOAD_RATE_AS_WRITTEN = 150            # §12.6, loot per second per Carrier
DECISION_CADENCE = (8, 12)            # §12.6: one decision every 8-12 seconds


def crew_volley(roles: dict) -> float:
    """Damage a full crew of five deals to the Vault in one 0.8-second volley."""
    return sum(r["power"] * (2 if n == "Breaker" else 1) for n, r in roles.items())


def vault_report() -> None:
    roles = {r["name"]: r for r in load("roles")}

    print("G4 — the Vault phase, which §12.6 budgets at about 30 seconds\n")
    print("§12.6 names its core decision as \"when to stop loading\". The phase has")
    print("two parts, and the numbers behind them behave very differently.\n")

    capacity = sum(r["carry"] for r in roles.values())
    carrier = roles["Carrier"]["carry"]
    volley = crew_volley(roles)
    print("Throughout: a reference crew of one of each role, which is the five §12.5")
    print("allows from Keeper level 16.\n")
    print(f"Cracking. Vault health is {VAULT_HEALTH_PER_LEVEL:,} per level and Breakers deal")
    print(f"double damage, so the crew deals {volley:.0f} damage per volley at level 1:\n")
    print(f"  {'crew':>6} {'vault':>6} {'health':>8} {'damage/s':>10} {'time':>8} "
          f"{'awareness added':>17}")
    for char_level, vault_level in ((1, 1), (5, 2), (8, 4), (12, 6), (18, 8), (25, 10)):
        dps = volley * LEVEL_GROWTH ** (char_level - 1) / WIND_UP
        health = VAULT_HEALTH_PER_LEVEL * vault_level
        seconds = health / dps
        print(f"  {'L' + str(char_level):>6} {'L' + str(vault_level):>6} {health:>8,} "
              f"{dps:>10.0f} {seconds:>7.1f}s "
              f"{CRACKING_AWARENESS_PER_5S * seconds / 5:>16.0f}%")
    print("\n  That lands between 10 and 25 seconds across the whole game, against a")
    print("  30-second budget the document set independently. Vault health, role")
    print("  Power and the phase length were written in three different places and")
    print("  they agree — which is the evidence that one hit per 0.8 s for Power")
    print("  damage is the model §12.8's wind-up was describing.\n")

    print(f"Loading, as written. The crew holds {capacity} loot ({carrier} of it in the")
    print(f"Carrier), and §12.6 loads {LOAD_RATE_AS_WRITTEN} a second into each Carrier:\n")
    print(f"  time to fill the Carrier   {carrier / LOAD_RATE_AS_WRITTEN:.1f}s")
    print(f"  the other four bags        never — only Carriers load, so "
          f"{capacity - carrier} of the {capacity}")
    print("                             units of crew capacity are unreachable\n")
    print("  So the phase the document calls a decision is two seconds long and")
    print("  has one option. The 30 seconds is cracking, and cracking has no")
    print("  decision in it at all.\n")

    print("What the rate would have to be. §12.6 sets its own target: one decision")
    print(f"every {DECISION_CADENCE[0]}-{DECISION_CADENCE[1]} seconds. A loading window "
          "one decision long, with every crew")
    print("member able to load and the rate scaling with carry:\n")
    proposed = {"Carrier": 30, "other": 8}
    for n, r in roles.items():
        rate = proposed["Carrier"] if n == "Carrier" else proposed["other"]
        print(f"    {n:<9} {r['carry']:>4} units at {rate:>2}/s = {r['carry'] / rate:>5.1f}s")
    print(f"\n    crew full in {max(r['carry'] / (proposed['Carrier'] if n == 'Carrier' else proposed['other']) for n, r in roles.items()):.0f}s, "
          "which is one decision by §12.6's own cadence, and")
    print(f"    puts the whole phase at about "
          f"{25 + 10}s against a budget of 30.\n")
    print("  Drafted in docs/design/spec/vault.md, together with what the fill")
    print("  fraction is worth — which is the part that turns a timer into a bet.")


# ---------------------------------------------------------------------------
# G3 and G5 — wards and law pylons
# ---------------------------------------------------------------------------

#: §10.2's Ward table, which §10.3 never keys to anything.
WARD_LEVELS = [(1, 0.00, 10), (2, 0.15, 9), (3, 0.30, 8), (4, 0.45, 7), (5, 0.60, 6)]
#: §10.2's Law Pylon table: health, one pylon per law slot.
PYLON_HEALTH_PER_LEVEL = 600
#: Proposed in spec/wards.md.
WARD_HEALTH_PER_LEVEL = 500
DISARM_BASE, DISARM_PER_LEVEL, TINKER = 3.0, 1.0, 0.70


def damage_per_second(roles: dict, role: str, level: int, doubled: bool = True) -> float:
    """One hit per 0.8 s for Power damage, doubled for a Breaker on an object."""
    factor = 2 if (doubled and role == "Breaker") else 1
    return roles[role]["power"] * factor * LEVEL_GROWTH ** (level - 1) / WIND_UP


def wards_report() -> None:
    roles = {r["name"]: r for r in load("roles")}
    wards = load("wards")

    print("G3 and G5 — wards and pylons, the defender's objects on the route\n")

    print("What §10.2 already answers, and the analysis had not checked:")
    print("  \u2022 ward levels 2\u20135 exist, at effect +15/30/45/60% and resets")
    print("    10\u21926 s \u2014 so G3's \u201cno levels above 1\u201d is wrong about §10.2,")
    print("    right about §10.3")
    print("  \u2022 a Law Pylon has ten levels, 600 health per level, and §10.2 states")
    print("    the relationship G5 calls missing: \u201cOne per law slot; per slot\u201d\n")
    print("What is genuinely missing is smaller and sharper: \u201ceffect +15%\u201d has")
    print("no key. Each ward states its effect in different units, and for three")
    print("of the six there is more than one number it could scale \u2014 one of")
    print("which, Static Coil, has no damage number at all.\n")

    scaled = {
        "Gravity Well": ("hold 2 s", "pull radius 3 tiles"),
        "Crystal Wall": ("800 health", None),
        "Time Snare": ("freeze 2.5 s", None),
        "Static Coil": ("damage \u2014 unstated", "radius 2 tiles / every 3 s"),
        "Thorn Hedge": ("5% health a second", None),
        "Lantern Glare": ("reveal 5 s", "blind 2 s"),
    }
    print(f"  {'ward':<15} {'proposed scaled quantity':<26} {'also a candidate'}")
    for w in wards:
        take, other = scaled[w["name"]]
        also = other or "\u2014"
        print(f"  {w['name']:<15} {take:<26} {also}")
    print("\n  The rule that picks them: NEVER SCALE A DISTANCE. A ward whose")
    print("  radius grows on upgrade covers tiles it did not cover when it was")
    print("  placed, so the island the defender built is not the island they get,")
    print("  and the editor cannot show a ward's footprint without knowing its")
    print("  future level. Static Coil has no damage number at all and needs one.\n")

    print("Getting past a ward: smash it, or disarm it.\n")
    print(f"  {'ward level':>11} {'health':>7} {'Breaker L12':>12} {'Scout L12':>11} "
          f"{'disarm':>8} {'Tinker':>8}")
    for level, _, _ in WARD_LEVELS:
        health = WARD_HEALTH_PER_LEVEL * level
        disarm = DISARM_BASE + DISARM_PER_LEVEL * level
        print(f"  {level:>11} {health:>7,} "
              f"{health / damage_per_second(roles, 'Breaker', 12):>11.1f}s "
              f"{health / damage_per_second(roles, 'Scout', 12):>10.1f}s "
              f"{disarm:>7.1f}s {disarm * TINKER:>7.1f}s")
    print("\n  Smashing wins up to level 2 and loses from level 3, and a Tinker moves")
    print("  the crossover down by one. That is the shape a decision should have: the")
    print("  defender's spending changes the raider's best answer. Smashing is also")
    print("  loud (5 m, §12.17's \u201cbreaking something\u201d) and disarming is not,")
    print("  so the fast answer is rarely the quiet one.\n")

    print("Law pylons. §12.6 says breaking one is \u201coften worth a detour\u201d.")
    print("Against a 180-second heist (§11.6), the detour costs:\n")
    crew = sum(r["power"] * (2 if n == "Breaker" else 1) for n, r in roles.items())
    print(f"  {'pylon':>6} {'health':>7} {'lone Breaker L12':>17} {'whole crew L12':>16} "
          f"{'% of the heist':>15}")
    for level in (1, 3, 5, 6, 8, 10):
        health = PYLON_HEALTH_PER_LEVEL * level
        alone = health / damage_per_second(roles, "Breaker", 12)
        together = health / (crew * LEVEL_GROWTH ** 11 / WIND_UP)
        print(f"  {level:>6} {health:>7,} {alone:>16.1f}s {together:>15.1f}s "
              f"{100 * together / 180:>14.0f}%")
    breaker_share = roles["Breaker"]["power"] * 2 / crew
    print(f"\n  Note what the two columns say: four extra crew members cut the time")
    print(f"  by only {100 * (1 - breaker_share):.0f}%. Against wards, pylons and the "
          f"Vault the Breaker is")
    print(f"  {100 * breaker_share:.0f}% of the crew's damage on its own, so §12.6's "
          "\u201cwho cracks\u201d has")
    print("  one answer and is not a decision.\n")
    print("  Drafted in docs/design/spec/wards.md.")


# ---------------------------------------------------------------------------
# Q6 and Q3 — the curve, and the page economy
# ---------------------------------------------------------------------------

#: §5.8's three decisions, which the published tables were never re-run against.
V3_RULES = dict(producers_per_realm_override=1, staffing_rule="pro_rata",
                crew_assigned_not_timed=True)


def pacing_report() -> None:
    from tools.economy_model import sinks                          # noqa: E402

    print("Q6 \u2014 casual pacing, re-derived under \u00a75.8\u2019s rules\n")
    print("\u00a727.3 puts the decision like this: \u201cat one session a day,")
    print("finishing everything takes about 1,019 days. Either keep it, or add a")
    print("catch-up discount on building levels the median player passed months ago.\u201d")
    print("\nThat 1,019 was computed before \u00a75.8. Re-running the model under")
    print("\u00a75.8\u2019s rules moves every archetype, and not evenly:\n")
    under = "under \u00a75.8"
    print(f"  {'archetype':<10} {'Keeper 40, published':>21} {under:>13} {'drift':>8}")
    index = {"engaged": 0, "regular": 1, "casual": 2}
    drift = {}
    for arch in ("engaged", "regular", "casual"):
        state = EconomyModel(Config(archetype=arch, days=1400, **V3_RULES)).run()
        published = econ.PUBLISHED_KEEPER_DAYS[40][index[arch]]
        reached = state.keeper_level_days.get(40)
        drift[arch] = (reached - published) if reached else None
        print(f"  {arch:<10} {published:>21} {reached if reached else '>1400':>13} "
              f"{f'+{drift[arch]}' if drift[arch] else '':>8}")
    print("\n  The engaged and regular curves each slip 94 days. The casual curve")
    print("  slips 177 \u2014 nearly twice as far, because a flat five characters")
    print("  withheld for a crew is a larger share of a smaller roster, and partial")
    print("  staffing bites sooner when there is less of everything.\n")
    scaled = round(1019 * (556 + drift["casual"]) / 556)
    print("  Scaling \u00a727.3\u2019s own figure by that drift puts \u201cfinishing")
    print(f"  everything\u201d at roughly {scaled:,} days rather than 1,019 "
          "\u2014 about three")
    print("  years and nine months. The decision is not less urgent than the")
    print("  document thinks. It is more urgent, and it should be made against a")
    print("  re-derived number rather than the one in \u00a727.3.\n")

    print("\nQ3 \u2014 three law ranks or five, and what now decides it\n")
    print("The rank split was argued partly on the page economy: \u00a714.4 totals")
    print("the Codex at 1,485 pages and the split changes that total. v3.0 added")
    print("the Library (\u00a710.5), and the Library dwarfs it.\n")
    print(f"  {'Codex total':<26} {'pages':>6} {'no Library':>11} "
          f"{'Library 5':>10} {'Library 10':>11}")
    for rule, label in (("three_rank", "\u00a714.4 as published"),
                        ("four_rank", "the re-tagged sheets")):
        cost = sinks.codex_cost(rule)
        cells = []
        for level in (0, 5, 10):
            per_day = 4.0 + sinks.library_pages(level)      # 4 heists a day
            cells.append(f"{cost / per_day:>10.0f}d")
        print(f"  {label:<26} {cost:>6.0f} " + " ".join(cells))
    print("\n  The rank split moves the total by 11%. The Library moves the time to")
    print("  gather it by FIVE TIMES \u2014 371 days at level 0 against 68 at")
    print("  level 10. So the page economy no longer decides this question; a")
    print("  building does.\n")
    print("  Which frees Q3 to be decided on what \u00a77.9 says it is about:")
    print("  RARITY BUYS SPECIFICITY, NOT STRENGTH. Pick the split that makes")
    print("  the best collection, and regenerate every page total from the law")
    print("  table afterwards rather than restating it in four places (C23).\n")
    print("  The caveat this carried is gone: v3.0 gave the Library three of\n"
          "  its ten levels and these figures interpolated the other seven,\n"
          "  about a third low. v3.1 states all ten (\u00a710.4) and they are\n"
          "  read rather than fitted \u2014 what is left of C24 is that\n"
          "  \u00a710.4 is not \u00a710.2, where every other building lives.")


REPORTS = {"rarity": rarity_report, "haul": haul_report,
           "staffing": staffing_report, "combat": combat_report, "vault": vault_report,
           "wards": wards_report, "pacing": pacing_report}


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
