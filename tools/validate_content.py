#!/usr/bin/env python3
"""Validate the extracted content tables.

    python3 tools/validate_content.py

§24.9 asks for content validation that "fails the build rather than a player's
device", and for property tests asserting rules that must always hold — resonance
is symmetric, no chord divides by zero, no ordering depends on a hash. This is
that check for the content layer.

It reports two separate things, and only the first fails:

  ERRORS  the data is malformed or self-inconsistent. Always a bug.
  OPEN    a known, tracked contradiction in the design document. Expected until
          it is resolved; each carries the audit register id that tracks it, so
          the list shrinks as the document is reconciled rather than being
          silently tolerated.

Exit code is non-zero only for ERRORS.
"""

import collections
import itertools
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"

NOTES = ["Flow", "Weight", "Glow", "Hush", "Bloom", "Spark", "Echo", "Veil"]
OPPOSITE = {"Flow": "Weight", "Weight": "Flow", "Glow": "Hush", "Hush": "Glow",
            "Bloom": "Spark", "Spark": "Bloom", "Echo": "Veil", "Veil": "Echo"}
SCHOOLS = ["Motion", "Matter", "Time", "Energy", "Life", "Spirit"]
ROLES = ["Scout", "Breaker", "Carrier", "Warden", "Mender"]

#: §26.1's launch content table. A count that drifts from this is a real error,
#: except where the drift is itself a tracked contradiction — see BUILDINGS below.
EXPECTED = {"notes": 8, "laws": 48, "resonances": 44, "chords": 12,
            "terrain": 39, "ruleborn": 18, "roles": 5,
            "wards": 6, "sages": 4, "eras": 8}

#: §26.1 still says 16 building types. v3.0 added the Library as §10.5 without
#: updating that count, so 17 is the correct extraction and 16 is the stale copy.
BUILDINGS_IN_26_1 = 16

#: Traits are counted separately: §26.1 says 30, §11.3 enumerates 31, and §17.3
#: names a 32nd. That is contradiction C10, so it is reported, not failed.
EXPECTED_TRAITS = 30

#: A day-2 player's stability capacity, from the economy model. Used to ask
#: whether a "late-game discovery" is actually gated.
DAY_2_STABILITY = 51

#: The old names v2.3 replaced (§26.9). A surviving reference is a stale rename.
RETIRED_NAMES = ["Echo Knight", "Moss Giant", "Masquerade", "Creator Fund", "Lawbound"]

REQUIRED_LAW_FIELDS = ["id", "name", "rank", "school", "stability_cost", "notes",
                       "tier_1", "tiers_2_3", "movement", "world",
                       "raider_use", "defender_use", "weakness", "sound"]

errors: list[str] = []
open_items: list[tuple[str, str]] = []


def err(msg: str) -> None:
    errors.append(msg)


def opn(item_id: str, msg: str) -> None:
    open_items.append((item_id, msg))


def _doc_declares_attributes() -> bool:
    """Whether the design document claims size and flight are stated properties."""
    doc = ROOT / "docs" / "design" / "ruleborn-game-design-v3.0.txt"
    if not doc.exists():
        return False
    text = doc.read_text(encoding="utf-8")
    return "Size is a band on every ruleborn" in text


def load(name: str) -> list[dict]:
    path = CONTENT / f"{name}.json"
    if not path.exists():
        err(f"{name}.json is missing — run tools/extract_content.py")
        return []
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> int:
    data = {name: load(name) for name in list(EXPECTED) + ["traits", "buildings"]}
    if errors:
        report()
        return 1

    laws, notes = data["laws"], data["notes"]
    by_id = {law["id"]: law for law in laws}

    # -- counts ------------------------------------------------------------
    for name, want in EXPECTED.items():
        got = len(data[name])
        if got != want:
            err(f"{name}: {got} entries, §26.1 says {want}")

    # -- notes -------------------------------------------------------------
    note_names = [n["name"] for n in notes]
    if sorted(note_names) != sorted(NOTES):
        err(f"notes are {note_names}, expected {NOTES}")
    for n in notes:
        if OPPOSITE.get(n["name"]) != n["opposite"]:
            err(f"note {n['name']}: opposite is {n['opposite']}, "
                f"expected {OPPOSITE.get(n['name'])}")
        back = next((m for m in notes if m["name"] == n["opposite"]), None)
        if back and back["opposite"] != n["name"]:
            err(f"opposition is not symmetric: {n['name']} <-> {n['opposite']}")

    # -- laws --------------------------------------------------------------
    ids = [law["id"] for law in laws]
    for dup, count in collections.Counter(ids).items():
        if count > 1:
            err(f"duplicate law id {dup!r} ({count} times)")
    for law in laws:
        missing = [f for f in REQUIRED_LAW_FIELDS if f not in law]
        if missing:
            err(f"law {law.get('name', '?')}: missing {missing}")
        if law["school"] not in SCHOOLS:
            err(f"law {law['name']}: unknown school {law['school']}")
        if not 1 <= len(law["notes"]) <= 2:
            err(f"law {law['name']}: carries {len(law['notes'])} notes, expected 1 or 2")
        for note in law["notes"]:
            if note not in NOTES:
                err(f"law {law['name']}: unknown note {note!r}")
        # A law carrying a note and its own opposite would be internally dissonant.
        if len(law["notes"]) == 2 and OPPOSITE.get(law["notes"][0]) == law["notes"][1]:
            err(f"law {law['name']}: carries a note and its opposite")
        if not 1 <= law["stability_cost"] <= 60:
            err(f"law {law['name']}: stability cost {law['stability_cost']} out of range")

    per_school = collections.Counter(law["school"] for law in laws)
    if set(per_school.values()) != {8}:
        err(f"laws per school: {dict(per_school)}, expected 8 each")

    # -- resonances --------------------------------------------------------
    seen_pairs = {}
    for r in data["resonances"]:
        if len(r["laws"]) != 2:
            err(f"resonance {r['name']}: references {len(r['laws'])} laws, expected 2")
            continue
        for lid, lname in zip(r["laws"], r["law_names"]):
            if lid not in by_id:
                err(f"resonance {r['name']}: unknown law {lname!r}")
        if r["laws"][0] == r["laws"][1]:
            err(f"resonance {r['name']}: pairs a law with itself")
        # Resonance is symmetric: one pair, one resonance.
        key = tuple(sorted(r["laws"]))
        if key in seen_pairs:
            err(f"resonance {r['name']}: same law pair as {seen_pairs[key]}")
        seen_pairs[key] = r["name"]
        # Declared shared notes must actually be shared.
        if all(lid in by_id for lid in r["laws"]):
            actual = set(by_id[r["laws"][0]]["notes"]) & set(by_id[r["laws"][1]]["notes"])
            declared = set(r["shared_notes"])
            if declared != actual:
                err(f"resonance {r['name']}: declares shared notes {sorted(declared) or '—'}, "
                    f"but the laws share {sorted(actual) or '—'}")

    # -- chords ------------------------------------------------------------
    for c in data["chords"]:
        if len(c["notes"]) != 3:
            err(f"chord {c['name']}: {len(c['notes'])} notes, expected 3")
        if len(set(c["notes"])) != len(c["notes"]):
            err(f"chord {c['name']}: repeats a note")
        for a, b in itertools.combinations(c["notes"], 2):
            if OPPOSITE.get(a) == b:
                err(f"chord {c['name']}: contains the opposite pair {a}/{b}")

    # -- terrain -----------------------------------------------------------
    unlock_levels = {1, 3, 6, 10, 15, 21}
    for t in data["terrain"]:
        if t["keeper_level"] not in unlock_levels:
            err(f"terrain {t['name']}: unlocks at Keeper level {t['keeper_level']}, "
                f"not one of {sorted(unlock_levels)}")
    #: §6.3's own unlock table.
    expected_unlocks = {1: 14, 3: 5, 6: 6, 10: 5, 15: 5, 21: 4}
    actual_unlocks = collections.Counter(t["keeper_level"] for t in data["terrain"])
    if dict(actual_unlocks) != expected_unlocks:
        err(f"terrain unlocks per Keeper level: {dict(sorted(actual_unlocks.items()))}, "
            f"§6.3 says {expected_unlocks}")

    # -- ruleborn ----------------------------------------------------------
    rb_schools = collections.Counter(r["school"] for r in data["ruleborn"])
    if set(rb_schools.values()) != {3}:
        err(f"ruleborn per school: {dict(rb_schools)}, expected 3 each")
    for r in data["ruleborn"]:
        if r["role"] not in ROLES:
            err(f"ruleborn {r['name']}: unknown role {r['role']}")

    # -- roles, buildings, wards, sages, eras -------------------------------
    role_names = {r["name"] for r in data["roles"]}
    if role_names != set(ROLES):
        err(f"roles are {sorted(role_names)}, expected {ROLES}")
    for r in data["roles"]:
        if not 1 <= r["speed"] <= 10:
            err(f"role {r['name']}: speed {r['speed']} out of range")

    for b in data["buildings"]:
        levels = [lvl["level"] for lvl in b["levels"]]
        if levels != list(range(1, len(levels) + 1)):
            if b.get("needs_decision"):
                opn(b["needs_decision"],
                    f"building {b['name']}: \u00a710.5 states levels {levels} only. "
                    f"Every other building lists every level, and the economy model "
                    f"cannot price a faucet with seven levels missing")
            else:
                err(f"building {b['name']}: levels are {levels}, "
                    f"expected 1..{len(levels)}")
        costs = [lvl["cost_starlight"] for lvl in b["levels"]]
        if costs != sorted(costs):
            err(f"building {b['name']}: costs are not monotonically increasing")
        if any(c <= 0 for c in costs):
            err(f"building {b['name']}: a level costs nothing")

    ward_schools = collections.Counter(w["school"] for w in data["wards"])
    if set(ward_schools) != set(SCHOOLS) or set(ward_schools.values()) != {1}:
        err(f"wards by school: {dict(ward_schools)}, expected one per school")

    # -- detection (the reconciled §12.17 spec) -----------------------------
    det = json.loads((CONTENT / "detection.json").read_text(encoding="utf-8")) \
        if (CONTENT / "detection.json").exists() else None
    if det:
        if det["_tick_rate"] != 30:
            err(f"detection: tick rate {det['_tick_rate']}, the §24.10 contract says 30")
        sus = det["suspicion"]
        for zone, seconds in sus["fill_seconds"].items():
            want = round(sus["max"] / (seconds * det["_tick_rate"]))
            got = sus["fill_per_tick"][zone]
            if abs(got - want) > 1:
                err(f"detection: {zone} zone fills at {got}/tick, but "
                    f"{seconds}s at {det['_tick_rate']} Hz needs {want}")
        want_decay = round(sus["max"] / (sus["decay_seconds"] * det["_tick_rate"]))
        if abs(sus["decay_per_tick"] - want_decay) > 1:
            err(f"detection: decay {sus['decay_per_tick']}/tick, "
                f"{sus['decay_seconds']}s needs {want_decay}")
        if sus["decay_per_tick"] >= sus["fill_per_tick"]["far"] * 2:
            err("detection: suspicion drains faster than the far zone fills, "
                "so a distant guard could never reach Suspicious")
        det_roles = {g["role"] for g in det["guards"]}
        if det_roles != set(ROLES):
            err(f"detection: guard roles {sorted(det_roles)}, expected {ROLES}")
        for g in det["guards"]:
            zones = [g["near_m"], g["mid_m"], g["far_m"]]
            present = [z for z in zones if z is not None]
            if present != sorted(present):
                err(f"detection: {g['role']} zone boundaries are not increasing: {zones}")
            if not 0 < g["cone_degrees"] <= g["peripheral_degrees"] <= 360:
                err(f"detection: {g['role']} cone {g['cone_degrees']}° is not inside "
                    f"its peripheral arc {g['peripheral_degrees']}°")
        thresholds = [s["at"] for s in det["states"] if s["at"] is not None]
        if thresholds != sorted(thresholds):
            err(f"detection: state thresholds are not ordered: {thresholds}")
        if thresholds[-1] != sus["max"]:
            err(f"detection: the top state triggers at {thresholds[-1]}, "
                f"but suspicion caps at {sus['max']}")
        noise = det["noise"]["sources"]
        if [n["heard_within_m"] for n in noise if n["id"] in ("crouched_walk", "walking", "running")] \
                != [1.0, 2.5, 4.5]:
            err("detection: the crouch/walk/run noise ladder does not match §12.17")

    # -- cross-references into the law table --------------------------------
    #
    # §6.2's "With laws" column and §18.3's era rules both name laws in prose.
    # A name that no longer exists is a rename that was not carried through.
    law_names = sorted((law["name"] for law in laws), key=len, reverse=True)
    prose = [("terrain " + t["name"], t["with_laws"]) for t in data["terrain"]]
    prose += [("era " + e["name"], e["rule"]) for e in data["eras"]]
    prose += [("ward " + w["name"], w["effect_level_1"]) for w in data["wards"]]
    for where, sentence in prose:
        for retired in RETIRED_NAMES:
            if retired in sentence:
                err(f"{where}: names {retired!r}, which v2.3 retired (§26.9)")

    # -- laws must key off attributes that exist ----------------------------
    #
    # §7.3's rule is that laws change a realm's rule sheet and never contain
    # special cases. A law reading an attribute no creature carries is the same
    # failure from the other side: the parameter it reads does not exist.
    creature_attrs = set()
    for r in data["roles"]:
        creature_attrs.add(r["name"].lower())
    for r in data["ruleborn"]:
        creature_attrs.add(r["name"].lower())
    #: Attributes a law may read, beyond role and creature names.
    KNOWN_ATTRS = {"flyer", "flyers", "big", "small", "size", "mass"}
    undefined = {a for a in KNOWN_ATTRS if a not in creature_attrs}
    #: v3.0's §12.21 says these attributes now exist. They do not yet exist as
    #: fields, which is the same gap re-stated rather than closed.
    declares_attributes = any(
        r.get("size") or r.get("flight") is not None for r in data["ruleborn"]
    ) is False and _doc_declares_attributes()
    for law in laws:
        text = f"{law.get('tier_1', '')} {law.get('tiers_2_3', '')}".lower()
        hits = sorted(a for a in undefined if a in text.split()
                      or f"{a} characters" in text or f"{a} ones" in text)
        if hits:
            where = ("\u00a712.21 declares size a band on every ruleborn and "
                     "flight a stated property, but neither appears as a field in "
                     "\u00a711.1 or \u00a711.11 \u2014 Featherkin's flight is "
                     "still prose in a Passive column"
                     if declares_attributes else
                     "\u00a711.1 has health, speed, power and carry; "
                     "\u00a711.11's proportions are art direction")
            opn("G12", f"law {law['name']} keys off {hits} \u2014 no creature or "
                       f"role carries that attribute ({where})")

    # =====================================================================
    # Known open contradictions — reported, not failed
    # =====================================================================

    n_traits = len(data["traits"])
    if n_traits != EXPECTED_TRAITS:
        opn("C10", f"§11.3 enumerates {n_traits} traits, §26.1's launch table says "
                   f"{EXPECTED_TRAITS}, and §17.3 names a \u201crare Starborn trait\u201d "
                   f"that appears in neither")

    names = {b["name"] for b in data["buildings"]}
    has_library = any("Library" in n for n in names)
    if not has_library:
        opn("C8", "the Library is referenced four times as the non-raiding page "
                  "source (§7.6, §12.1, §27.2, §30.15) but is not among the "
                  "building types in §10.2 — no cost, no levels, no placement rule")
    elif len(data["buildings"]) != BUILDINGS_IN_26_1:
        opn("C8", f"v3.0 added the Library as \u00a710.5, so there are now "
                  f"{len(data['buildings'])} building types \u2014 but \u00a726.1's "
                  f"launch table still says {BUILDINGS_IN_26_1}, and \u00a710.2's "
                  f"table of every level of every building does not contain it")

    if all(w.get("missing") == "levels 2-5" for w in data["wards"]):
        opn("G3", "§10.3 specifies ward level 1 only, but §10.2 gives the Ward "
                  "building five levels and §21.9 budgets 6 types x 5 levels of props")

    ranks = collections.Counter(law["rank"] for law in laws)
    if "Uncommon" not in ranks:
        opn("C3", f"law ranks are {dict(ranks)} \u2014 \u00a77.10's own table says "
                  f"18/14/10/6 plus 3 paradoxes. v3.0 re-tagged 12 laws from Rare "
                  f"to Uncommon, which moved the split without matching it, and "
                  f"left \u00a77.6, \u00a714.4 and the glossary on the old "
                  f"three-rank page costs")

    pools = collections.Counter()
    for law in laws:
        for note in law["notes"]:
            pools[note] += 1
    two_note = sum(1 for law in laws if len(law["notes"]) == 2)
    reachable_with_two = 0
    for c in data["chords"]:
        banned = {OPPOSITE[n] for n in c["notes"]}
        pool = [law for law in laws
                if set(law["notes"]) & set(c["notes"]) and not set(law["notes"]) & banned]
        if any(set(c["notes"]) <= set(a["notes"]) | set(b["notes"])
               for a, b in itertools.combinations(pool, 2)):
            reachable_with_two += 1
    # v3.0's §8.8 changed the rule to three *distinct laws*, which makes §8.5
    # true. Whether it makes a chord late-game is a different question, and the
    # cheapest three-law combination is how to answer it.
    by_id = {law["id"]: law for law in laws}
    cheapest, all_common = None, 0
    for c in data["chords"]:
        banned = {OPPOSITE[n] for n in c["notes"]}
        pool = [law for law in laws
                if set(law["notes"]) & set(c["notes"]) and not set(law["notes"]) & banned]
        best = None
        for combo in itertools.combinations(pool, 3):
            if set(c["notes"]) <= set().union(*(set(l["notes"]) for l in combo)):
                cost = sum(l["stability_cost"] for l in combo)
                if best is None or cost < best[0]:
                    best = (cost, [l["rank"] for l in combo])
        if best:
            cheapest = best[0] if cheapest is None else min(cheapest, best[0])
            all_common += set(best[1]) == {"Common"}
    if cheapest is not None and cheapest <= DAY_2_STABILITY:
        opn("D14", f"\u00a78.8 fixed the rule \u2014 a chord needs three distinct "
                   f"laws \u2014 but not the outcome it argued for. The cheapest "
                   f"chord now costs {cheapest} stability against a day-2 capacity "
                   f"of {DAY_2_STABILITY}, up from 26, and {all_common} of "
                   f"{len(data['chords'])} are still three commons. The gate that "
                   f"makes a chord late-game is the Lab level 3 (Spire 5, about day "
                   f"42), which \u00a78.5 mentions and \u00a78.8 does not lean on")
    elif reachable_with_two:
        opn("D14", f"{reachable_with_two} of {len(data['chords'])} chords are reachable "
                   f"with two laws, not the three \u00a78.5 describes "
                   f"({two_note} of {len(laws)} laws carry two notes)")

    # v3.0's §21.8 now says "every school has a sound signature — six in all",
    # which is what the content holds. The check only fires against the older
    # wording, where every *law* had one.
    doc = ROOT / "docs" / "design" / "ruleborn-game-design-v3.0.txt"
    per_law_claimed = doc.exists() and "every law also has a sound signature" in \
        doc.read_text(encoding="utf-8")
    sounds = collections.Counter(law["sound"] for law in laws)
    if per_law_claimed and len(sounds) < len(laws):
        per_school = all(
            len({law["school"] for law in laws if law["sound"] == snd}) == 1
            for snd in sounds)
        opn("C20", f"48 laws share {len(sounds)} sound signatures"
                   f"{' — one per school' if per_school else ''}, but §21.8 says "
                   f"\"every law also has a sound signature, so a player can hear "
                   f"which rules are running\"")

    # The chord layer demands the notes evenly; the law layer does not supply them
    # evenly. Stating D13 this way is sharper than the raw pool imbalance.
    demand = collections.Counter(n for c in data["chords"] for n in c["notes"])
    if demand:
        ratio = {n: round(pools[n] / demand[n], 1) for n in NOTES if demand[n]}
        spread = max(ratio.values()) - min(ratio.values())
        worst = max(OPPOSITE.items(), key=lambda kv: abs(pools[kv[0]] - pools[kv[1]]))
        if spread > 1.0:
            opn("D13", f"{worst[0]} {pools[worst[0]]} laws against its opposite "
                f"{worst[1]} {pools[worst[1]]} — chords demand the notes evenly (" +
                ", ".join(f"{n} {demand[n]}" for n in NOTES) +
                ") but the law pool does not supply them evenly (" +
                ", ".join(f"{n} {pools[n]}" for n in NOTES) + ")")

    role_conflicts = [r["name"] for r in data["ruleborn"]
                      if r.get("conflict_severity") == "role"]
    wording = sum(1 for r in data["ruleborn"] if r.get("conflict_severity") == "wording")
    if role_conflicts:
        opn("C6", f"§11.2 and §11.11 give different roles for {', '.join(role_conflicts)}; "
                  f"{wording} more differ on ability wording")

    report()
    return 1 if errors else 0


def report() -> None:
    print()
    if errors:
        print(f"ERRORS  {len(errors)} — the data is malformed; fix before use\n")
        for e in errors:
            print(f"  ✗ {e}")
        print()
    else:
        print("ERRORS  none — every table is well formed and internally consistent\n")

    if open_items:
        print(f"OPEN    {len(open_items)} known contradictions in the design document")
        print("        (tracked in the audit register; expected until resolved)\n")
        for item_id, msg in open_items:
            print(f"  [{item_id}] {msg}")
        print()


if __name__ == "__main__":
    raise SystemExit(main())
