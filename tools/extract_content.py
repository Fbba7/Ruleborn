#!/usr/bin/env python3
"""Extract the design document's content into validated data tables.

    python3 tools/extract_content.py

§24 says laws, resonances, ruleborn, traits, buildings, eras and anomalies should
live in data tables so content and balance ship without an app update. They do
not yet exist, so this pulls them out of the document into `content/`, where they
can be validated (`tools/validate_content.py`), diffed, and eventually loaded.

Two rules this follows:

  * Extraction only. Nothing here invents or corrects a value. Where the document
    contradicts itself the extractor records BOTH readings and marks the item
    `needs_decision`, so the conflict is visible in the data rather than silently
    resolved by whichever section was parsed last.
  * The document is the input, never the output. When a contradiction is settled,
    the fix belongs in the design document; re-running this reproduces it.
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "docs" / "design" / "ruleborn-game-design-v3.0.txt"
OUT = ROOT / "content"

NOTES = ["Flow", "Weight", "Glow", "Hush", "Bloom", "Spark", "Echo", "Veil"]
OPPOSITE = {"Flow": "Weight", "Weight": "Flow", "Glow": "Hush", "Hush": "Glow",
            "Bloom": "Spark", "Spark": "Bloom", "Echo": "Veil", "Veil": "Echo"}
SCHOOLS = ["Motion", "Matter", "Time", "Energy", "Life", "Spirit"]
ROLES = ["Scout", "Breaker", "Carrier", "Warden", "Mender"]


def section(text: str, start: str, end: str) -> str:
    """Slice one section out of the document.

    Markers must be unique to the body. Several section titles also appear in
    the contents list at the top, which would slice backwards and silently
    return nothing, so an inverted or empty slice is an error rather than an
    empty table.
    """
    a = text.index(start)
    b = text.index(end, a + len(start))
    if b <= a:
        raise ValueError(f"section marker {end!r} precedes {start!r}")
    return text[a:b]


def fields(block: str) -> dict[str, str]:
    """Parse a run of '| key' / '| value' pairs into a dict."""
    cells = [c.strip() for c in block.split("\n") if c.strip().startswith("| ")]
    cells = [c[2:].strip() for c in cells]
    return {cells[i]: cells[i + 1] for i in range(0, len(cells) - 1, 2)}


# ---------------------------------------------------------------------------
# Laws (§7.7, the full sheets — the richest of the three places laws appear)
# ---------------------------------------------------------------------------

LAW_HEAD = re.compile(
    r"^(.+?)(Common|Uncommon|Rare|Deep) · "
    r"(Motion|Matter|Time|Energy|Life|Spirit) · cost (\d+)\s*$")

FIELD_MAP = {
    "Tier I": "tier_1",
    "Tiers II and III": "tiers_2_3",
    "How characters move": "movement",
    "How the realm looks": "world",
    "A raider uses it to": "raider_use",
    "A defender uses it to": "defender_use",
    "Its weakness": "weakness",
    "It sounds like": "sound",
}


def extract_laws(text: str) -> list[dict]:
    lines = text.split("\n")
    heads = []
    for i, line in enumerate(lines):
        m = LAW_HEAD.match(line.strip())
        if m:
            heads.append((i, m))

    laws = []
    for idx, (i, m) in enumerate(heads):
        end = heads[idx + 1][0] if idx + 1 < len(heads) else len(lines)
        block = "\n".join(lines[i + 1:end])
        j = i + 1
        while not lines[j].strip():
            j += 1
        notes = lines[j].split()
        raw = fields(block)
        law = {
            "id": slug(m.group(1).strip()),
            "name": m.group(1).strip(),
            "rank": m.group(2),
            "school": m.group(3),
            "stability_cost": int(m.group(4)),
            "notes": notes,
        }
        for src, dst in FIELD_MAP.items():
            if src in raw:
                law[dst] = raw[src]
        laws.append(law)
    return laws


def slug(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


# ---------------------------------------------------------------------------
# Ruleborn (§11.11 the bible, cross-checked against §11.2 the summary table)
# ---------------------------------------------------------------------------

CREATURE_HEAD = re.compile(
    r"^(.+?)(Scout|Breaker|Carrier|Warden|Mender) · "
    r"(Motion|Matter|Time|Energy|Life|Spirit)\s*$")

CREATURE_FIELDS = {
    "Look": "look", "Proportions": "proportions", "Personality": "personality",
    "At home": "at_home", "Ability": "ability", "Resists": "resists",
    "Best at": "best_at", "Sounds like": "sound",
}


def extract_ruleborn(text: str) -> list[dict]:
    # §11.2's summary table, for the cross-check.
    table = section(text, "11.2 The 18 ruleborn", "11.3 Traits")
    cells = [c.strip().lstrip("| ").strip() for c in table.split("\n") if c.strip()]
    summary = {}
    names = set()
    lines = text.split("\n")
    heads = []
    for i, line in enumerate(lines):
        m = CREATURE_HEAD.match(line.strip())
        if m:
            heads.append((i, m))
            names.add(m.group(1).strip())
    for i, cell in enumerate(cells):
        if cell in names and i + 4 < len(cells) and cells[i + 2] in ROLES:
            summary[cell] = {
                "school": cells[i + 1], "role": cells[i + 2],
                "ability": cells[i + 3], "passive": cells[i + 4],
            }

    out = []
    for idx, (i, m) in enumerate(heads):
        end = heads[idx + 1][0] if idx + 1 < len(heads) else len(lines)
        raw = fields("\n".join(lines[i + 1:end]))
        name = m.group(1).strip()
        entry = {
            "id": slug(name), "name": name,
            "role": m.group(2), "school": m.group(3),
            "source": "11.11",
        }
        for src, dst in CREATURE_FIELDS.items():
            if src in raw:
                entry[dst] = raw[src]

        alt = summary.get(name)
        if alt:
            conflicts = {}
            if alt["school"] != entry["school"]:
                conflicts["school"] = alt["school"]
            if alt["role"] != entry["role"]:
                conflicts["role"] = alt["role"]
            if alt["ability"] != entry.get("ability"):
                conflicts["ability"] = alt["ability"]
            if conflicts:
                # C6: the document specifies these creatures twice and the two
                # specs disagree. Both readings are kept; neither is chosen here.
                # A role conflict is material — it changes crew composition, guard
                # behaviour and the Nursery's fewest-roles-first rule. An ability
                # that is merely worded differently still needs reconciling, but
                # it does not change what the creature is.
                entry["needs_decision"] = "C6"
                entry["conflict_severity"] = (
                    "role" if "role" in conflicts or "school" in conflicts else "wording")
                entry["alt_11_2"] = conflicts
            entry["passive_11_2"] = alt["passive"]
        out.append(entry)
    return out


# ---------------------------------------------------------------------------
# Terrain (§6.2, seven family tables)
# ---------------------------------------------------------------------------

TERRAIN_FAMILIES = ["Ground shape", "Water", "Plants", "Rock and crystal",
                    "Air and light", "Heat and energy", "Built"]
TERRAIN_COLS = ["name", "movement", "sight", "points", "found_in", "with_laws", "keeper_level"]


def extract_terrain(text: str) -> list[dict]:
    block = section(text, "6.2 The 39 features", "6.3 When features unlock")
    lines = [l.rstrip() for l in block.split("\n")]
    out, family = [], None
    row: list[str] = []
    for line in lines:
        bare = line.strip()
        if bare in TERRAIN_FAMILIES:
            family, row = bare, []
            continue
        if not bare.startswith("| "):
            continue
        cell = bare[2:].strip()
        if cell == "Feature":          # header row starts
            row = []
            continue
        if cell in ("Movement", "Sight and hiding", "Points", "Found in",
                    "With laws", "Keeper level"):
            continue
        row.append(cell)
        if len(row) == len(TERRAIN_COLS):
            entry = dict(zip(TERRAIN_COLS, row))
            entry["family"] = family
            entry["id"] = slug(entry["name"])
            entry["keeper_level"] = int(entry["keeper_level"])
            out.append(entry)
            row = []
    return out


# ---------------------------------------------------------------------------
# Notes, resonances, chords (§8)
# ---------------------------------------------------------------------------

def extract_resonances(text: str) -> list[dict]:
    block = section(text, "8.4 Signature resonances", "8.5 Chords")
    cells = [c.strip()[2:].strip() for c in block.split("\n") if c.strip().startswith("| ")]
    # header: Resonance | Laws | Shared notes | Added effect
    if cells[:4] == ["Resonance", "Laws", "Shared notes", "Added effect"]:
        cells = cells[4:]
    out = []
    for i in range(0, len(cells) - 3, 4):
        name, laws, shared, effect = cells[i:i + 4]
        parts = [p.strip() for p in laws.split("+")]
        out.append({
            "id": slug(name), "name": name,
            "laws": [slug(p) for p in parts], "law_names": parts,
            "shared_notes": [] if shared == "—" else shared.split(),
            "effect": effect,
        })
    return out


def extract_chords(text: str) -> list[dict]:
    block = section(text, "8.5 Chords", "8.6 How players discover")
    cells = [c.strip()[2:].strip() for c in block.split("\n") if c.strip().startswith("| ")]
    if cells[:3] == ["Chord", "Notes", "Effect"]:
        cells = cells[3:]
    out = []
    for i in range(0, len(cells) - 2, 3):
        name, notes, effect = cells[i:i + 3]
        out.append({"id": slug(name), "name": name,
                    "notes": notes.split(), "effect": effect})
    return out


def extract_notes(text: str) -> list[dict]:
    block = section(text, "8.1 The eight notes", "8.2 Harmonies")
    cells = [c.strip()[2:].strip() for c in block.split("\n") if c.strip().startswith("| ")]
    if cells[:4] == ["Note", "What laws with this note do", "Opposite", "Symbol"]:
        cells = cells[4:]
    out = []
    for i in range(0, len(cells) - 3, 4):
        name, does, opposite, symbol = cells[i:i + 4]
        out.append({"id": slug(name), "name": name, "does": does,
                    "opposite": opposite, "symbol": symbol})
    return out


# ---------------------------------------------------------------------------
# Simple tables: roles, wards, eras, sages, buildings, traits
# ---------------------------------------------------------------------------

def table(text: str, start: str, end: str, columns: list[str],
          headers: list[str]) -> list[dict]:
    """Parse a flat '| cell' table whose header row is `headers`."""
    block = section(text, start, end)
    cells = [c.strip()[2:].strip() for c in block.split("\n") if c.strip().startswith("| ")]
    if cells[:len(headers)] == headers:
        cells = cells[len(headers):]
    rows = []
    for i in range(0, len(cells) - len(columns) + 1, len(columns)):
        row = dict(zip(columns, cells[i:i + len(columns)]))
        row["id"] = slug(row[columns[0]])
        rows.append(row)
    return rows


def extract_roles(text: str) -> list[dict]:
    rows = table(text, "11.1 Roles", "11.2 The 18 ruleborn",
                 ["name", "health", "speed", "power", "carry", "job"],
                 ["Role", "Health", "Speed (tiles/s)", "Power", "Carry", "Job in a heist"])
    for r in rows:
        r["health"] = int(r["health"])
        r["speed"] = float(r["speed"])
        r["power"] = int(r["power"])
        r["carry"] = int(r["carry"])
    return rows


def extract_wards(text: str) -> list[dict]:
    # v3.0 inserted 10.5 (the Library) between the ward table and 11.1, so the
    # old end marker swallowed the Library's level table as four extra wards.
    end = "10.5 The Library" if "10.5 The Library" in text else "11.1 Roles"
    rows = table(text, "10.3 Wards", end,
                 ["name", "school", "effect_level_1", "resets_after"],
                 ["Ward", "School", "Effect at level 1", "Resets after"])
    for r in rows:
        # G3: §10.3 gives level 1 only, but §21.9 and §10.2 both assume five levels.
        r["needs_decision"] = "G3"
        r["missing"] = "levels 2-5"
    return rows


def extract_eras(text: str) -> list[dict]:
    return table(text, "18.3 Eras (at launch)", "18.4 Epochs",
                 ["name", "rule"], ["Era", "Rule for the week"])


def extract_sages(text: str) -> list[dict]:
    return table(text, "11.7 Sages, the heroes", "11.8 Special characters",
                 ["name", "unlocks", "heist_powers", "at_home"],
                 ["Sage", "Unlocks", "Heist powers", "At home"])


def extract_traits(text: str) -> list[dict]:
    """§11.3 packs each family's traits into one prose cell: 'Name: effect.'"""
    rows = table(text, "11.3 Traits", "11.4 Levels", ["kind", "traits"],
                 ["Kind", "Traits"])
    out = []
    for row in rows:
        for part in re.split(r"(?<=\.)\s+(?=[A-Z])", row["traits"]):
            m = re.match(r"^([A-Z][A-Za-z-]*(?: [a-z]+)?):\s*(.+?)\.?$", part.strip())
            if m:
                out.append({"id": slug(m.group(1)), "name": m.group(1),
                            "family": row["kind"], "effect": m.group(2).strip()})
    return out


BUILDING_NAMES = ["Keeper's Spire", "Vault", "Anchor Stone", "Star Well",
                  "Aether Spring", "Garden", "Storehouse", "Law Pylon", "Hearth",
                  "Nursery", "Guardian Post", "Ward", "Resonance Lab",
                  "Observatory", "Beacon", "Visitor's Dock"]


def extract_library(text: str) -> dict | None:
    """v3.0 added the Library as §10.5, outside §10.2's table of sixteen.

    It is a building — "a building at the Heart, one per universe" — so it
    belongs with the others, and being outside the table is exactly how C8
    happened in the first place.
    """
    if "10.5 The Library" not in text:
        return None
    block = section(text, "10.5 The Library", "11Characters")
    cells = [l.strip().lstrip("| ").strip() for l in block.split("\n") if l.strip()]
    levels = []
    for i, cell in enumerate(cells):
        if re.fullmatch(r"\d+", cell) and i + 2 < len(cells) \
                and re.fullmatch(r"[\d,]+( Starlight)?", cells[i + 1]):
            levels.append({
                "level": int(cell),
                "cost_starlight": int(
                    cells[i + 1].replace(",", "").replace(" Starlight", "")),
                "needs": "Spire " + cell,
                "gives": f"{cells[i + 2]} pages a day",
            })
    return {
        "name": "The Library", "id": "library", "placement": "Heart; 1.",
        "levels": levels,
        "note": "\u00a710.5 gives levels 1, 5 and 10 only; the other seven are "
                "not stated. Every other building in \u00a710.2 lists every level.",
        "needs_decision": "C8",
    }


def extract_buildings(text: str) -> list[dict]:
    block = section(text, "10.2 Every level of every building", "10.3 Wards")
    lines = [l.rstrip() for l in block.split("\n")]
    out, current, placement, cells = [], None, None, []

    def flush():
        if not current:
            return
        levels, i = [], 0
        while i + 3 < len(cells):
            if re.fullmatch(r"\d+", cells[i]):
                levels.append({
                    "level": int(cells[i]),
                    "cost_starlight": int(cells[i + 1].replace(",", "")),
                    "needs": cells[i + 2],
                    "gives": cells[i + 3],
                })
                i += 6          # two further columns: build day, income hours
            else:
                i += 1
        out.append({"id": slug(current), "name": current,
                    "placement": placement, "levels": levels})

    for i, line in enumerate(lines):
        bare = line.strip()
        if bare in BUILDING_NAMES:
            flush()
            current, cells = bare, []
            placement = lines[i + 2].strip() if i + 2 < len(lines) else ""
        elif current and bare.startswith("| "):
            cells.append(bare[2:].strip())
    flush()
    return out


# ---------------------------------------------------------------------------

def write(name: str, rows: list[dict]) -> None:
    OUT.mkdir(exist_ok=True)
    path = OUT / f"{name}.json"
    path.write_text(json.dumps(rows, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    material = sum(1 for r in rows if r.get("conflict_severity") == "role")
    wording = sum(1 for r in rows if r.get("conflict_severity") == "wording")
    note = ""
    if material or wording:
        note = f"  ({material} role conflicts, {wording} wording conflicts)"
    print(f"  content/{name}.json  {len(rows):>3} entries{note}")


def main() -> int:
    if not SRC.exists():
        print(f"missing {SRC}; run tools/extract_design_doc.py first", file=sys.stderr)
        return 1
    text = SRC.read_text(encoding="utf-8")
    print("Extracted from the design document:")
    write("notes", extract_notes(text))
    write("laws", extract_laws(text))
    write("resonances", extract_resonances(text))
    write("chords", extract_chords(text))
    write("terrain", extract_terrain(text))
    write("roles", extract_roles(text))
    write("ruleborn", extract_ruleborn(text))
    write("traits", extract_traits(text))
    buildings = extract_buildings(text)
    library = extract_library(text)
    if library:
        buildings.append(library)
    write("buildings", buildings)
    write("wards", extract_wards(text))
    write("sages", extract_sages(text))
    write("eras", extract_eras(text))
    print("\nNow run: python3 tools/validate_content.py")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
