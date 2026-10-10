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
from design_doc import TEXT as SRC                                # noqa: E402
OUT = ROOT / "content"

NOTES = ["Flow", "Weight", "Glow", "Hush", "Bloom", "Spark", "Echo", "Veil"]
OPPOSITE = {"Flow": "Weight", "Weight": "Flow", "Glow": "Hush", "Hush": "Glow",
            "Bloom": "Spark", "Spark": "Bloom", "Echo": "Veil", "Veil": "Echo"}
SCHOOLS = ["Motion", "Matter", "Time", "Energy", "Life", "Spirit"]
ROLES = ["Scout", "Breaker", "Carrier", "Warden", "Mender"]


def heading(text: str, title: str) -> str | None:
    """The numbered heading for a section title, whatever number it carries.

    Two of this file's markers named a number: ``"10.5 The Library"``. v3.1
    renumbered that section to 10.4, so the Library dropped out of
    ``buildings.json`` altogether and its level table was swallowed by the
    ward extractor as ninety-nine extra wards named "1", "2", "900 Starlight".

    A marker that names a number is a marker that a renumbering breaks, and
    this document renumbers — D29 is the record of the same fault in forty-one
    citations. Titles move far less often than numbers, so the markers are
    written as titles and the number is looked up here.
    """
    m = re.search(rf"^(\d+\.\d+ {re.escape(title)})\s*$", text, re.M)
    return m.group(1) if m else None


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


#: 7.10's engine-cost ladder, cheapest first, with the points each rung costs.
ENGINE_RUNGS = {
    "Parameter": 0, "Placement or attribute": 1, "Conditional or periodic": 2,
    "Spawned entity": 4, "Rewind": 8,
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
        # The last sheet used to run to the end of the document — 10,616 lines
        # instead of 28 — so `fields()` re-paired every table in §7.8 onward
        # into it, and whatever cell followed a matching label overwrote the
        # real value. §21.7's column header "How the realm looks" is one, which
        # is how Mirror images ended up with `world` set to the *label* "How
        # characters move" (D41). Bound it at the next section heading.
        end = (heads[idx + 1][0] if idx + 1 < len(heads)
               else next((k for k in range(i + 1, len(lines))
                          if re.match(r"\d+\.\d+ ", lines[k])), len(lines)))
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
        # v3.3: every sheet names the engine work its effect needs — a rung of
        # 7.10's ladder — and whether it ships at launch. Both are data 7.10
        # computes from, so they are kept as data rather than as the sentence.
        kind = raw.get("Effect kind", "")
        rung = next((r for r in ENGINE_RUNGS if kind.startswith(r + ":")), None)
        if rung:
            law["engine_rung"] = rung
            law["launch"] = "Ships at launch" in kind
        laws.append(law)
    return laws


def codex_chapters(text: str, laws: list[dict]) -> list[dict]:
    """§7.6: "at launch it holds the launch 24 (7), 12 findable from the start
    and all 24 from Keeper level 6. Chapter 1’s twelve are two of each school:
    … — Bounce and Half gravity, …, Whispers and Echoes — …". A launch law
    named there is chapter 1, any other launch law chapter 2. Laws after
    launch are left without one: which come 25th to 36th is the release
    order, which §26.1 does not number law by law (G49)."""
    m = re.search(r"Chapter 1’s twelve are[^—]*— (.+?) —", text)
    if not m:
        return laws
    names = {n.strip() for pair in m.group(1).split(",") for n in pair.split(" and ")}
    for law in laws:
        if law.get("launch"):
            law["chapter"] = 1 if law["name"] in names else 2
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
    "At home": "at_home", "Ability": "ability", "Rule sheet": "rule_sheet",
    "Resists": "resists", "Best at": "best_at", "Sounds like": "sound",
}


#: How 11.2's column headings map onto the fields kept from it. v3.0's table
#: had five columns; v3.1 added Size and Flies, which is C26's fix — 12.21
#: declared size and flight as properties and no table carried them.
SUMMARY_COLUMNS = {
    "Ruleborn": "name", "School": "school", "Role": "role",
    "Size": "size", "Flies": "flies",
    "Ability (cooldown)": "ability", "Passive": "passive",
    # v3.3: abilities have two uses a heist and no cooldown (12.6), and the
    # last column is the law family each ruleborn resists (11.11).
    "Ability (two uses a heist)": "ability", "Resists": "resists",
}


def summary_table(text: str) -> dict[str, dict]:
    """11.2's summary of the 18 ruleborn, read by column heading.

    It was read by offset — school at +1, role at +2, ability at +3, passive
    at +4 — which is correct for exactly the width of table it was written
    against. v3.1 inserted Size and Flies between Role and Ability, so every
    creature's ability became "standard" and every passive became "yes" or
    "no", and `content/ruleborn.json` would have carried that as fact.

    Nothing would have caught it. C6 compares this table against 11.11's
    character bible, so a shifted read makes eighteen creatures disagree
    about their ability — which is what C6 says they do, and the check was
    already open. A fault that produces the symptom the register is expecting
    is the hardest kind to see.
    """
    block = section(text, "11.2 The 18 ruleborn", "11.3 Traits")
    cells = [c.strip().lstrip("| ").strip() for c in block.split("\n") if c.strip()]
    # section() hands back the heading line too, so skip forward to the header
    # row rather than assuming it is first.
    i = next((k for k, c in enumerate(cells) if c in SUMMARY_COLUMNS), len(cells))
    heads = []
    while i < len(cells) and cells[i] in SUMMARY_COLUMNS:
        heads.append(SUMMARY_COLUMNS[cells[i]])
        i += 1
    if "name" not in heads or "role" not in heads:
        raise SystemExit(
            f"11.2's header row is {cells[:8]}, which this reader does not "
            f"recognise. Add the new column to SUMMARY_COLUMNS rather than "
            f"letting the row shift.")
    out = {}
    for j in range(i, len(cells) - len(heads) + 1, len(heads)):
        row = dict(zip(heads, cells[j:j + len(heads)]))
        if row.get("role") in ROLES:
            out[row["name"]] = row
    return out


def characters_on_screen(text: str) -> dict[str, dict]:
    """§21.6's table: each ruleborn's body and size, colours and signature
    moment, by name. The height is the body's last figure, "0.6 m"."""
    block = section(text, heading(text, "Characters") or "21.6 Characters",
                    heading(text, "Laws on screen") or "21.7 Laws on screen")
    cells = [c.strip()[2:].strip() for c in block.split("\n") if c.strip().startswith("| ")]
    head = ["Ruleborn", "Body and size", "Colours", "Signature moment"]
    i = next(k for k in range(len(cells)) if cells[k:k + 4] == head) + 4
    out = {}
    while i + 4 <= len(cells) and cells[i] != "Character":
        name, body, colours, signature = cells[i:i + 4]
        m = re.search(r"([\d.]+) m$", body)
        out[slug(name)] = {"body": body, "height_m": float(m.group(1)) if m else None,
                           "colours": colours, "signature": signature}
        i += 4
    return out


def extract_ruleborn(text: str) -> list[dict]:
    summary = summary_table(text)
    screen = characters_on_screen(text)
    names = set()
    lines = text.split("\n")
    heads = []
    for i, line in enumerate(lines):
        m = CREATURE_HEAD.match(line.strip())
        if m:
            heads.append((i, m))
            names.add(m.group(1).strip())

    out = []
    for idx, (i, m) in enumerate(heads):
        # The same unbounded last block as the law sheets (D41): the eighteenth
        # creature's ran to the end of the document, so a later "| Look" pair
        # overwrote Soulmender's with a Sage's name. Bound it at the next
        # section heading. D42.
        end = (heads[idx + 1][0] if idx + 1 < len(heads)
               else next((k for k in range(i + 1, len(lines))
                          if re.match(r"\d+\.\d+ |^\d+[A-Z]", lines[k])),
                         len(lines)))
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
            # v3.3 generates 11.2 from 11.11's cards (C6's fix), dropping the
            # card's closing "Two uses a heist" — the column heading says it.
            # A difference in that clause alone is the summary, not a conflict.
            card = re.sub(r"\.\s*Two uses a heist\.?$", "", entry.get("ability") or "")
            if alt.get("ability") not in (entry.get("ability"), card):
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
            if "passive" in alt:
                entry["passive_11_2"] = alt["passive"]
            if "resists" in alt:
                entry["resists"] = alt["resists"]
            # C26: 11.2 now carries size and flight, which 12.21 declared as
            # properties and no table had. Unlike ability and passive they are
            # stated in one place only, so they are not labelled 11_2 — the
            # suffix marks a fact this document states twice, and these it
            # states once.
            for field in ("size", "flies"):
                if field in alt:
                    entry[field] = alt[field]
        # §21.6's body, height, colours and signature (G63), so a card can
        # carry all of them (§23.5).
        if entry["id"] in screen:
            entry.update({k: v for k, v in screen[entry["id"]].items() if v is not None})
        out.append(entry)
    return out


def special_tables(text: str) -> dict[str, list[list[str]]]:
    """§11.8's tables, as rows of cells under each subheading."""
    block = section(text, heading(text, "Special characters") or "11.8 Special characters",
                    heading(text, "How laws shape ruleborn") or "11.9 How laws shape ruleborn")
    cells = [c.strip()[2:].strip() for c in block.split("\n") if c.strip().startswith("| ")]
    return cells


def extract_visitors(text: str) -> list[dict]:
    """§11.8's visitors: who comes to the Visitor's Dock and what each offers.
    The Stray is a ruleborn of one of the eighteen kinds, never a nineteenth."""
    cells = special_tables(text)
    i = cells.index("What they offer") + 1
    out = []
    while i + 2 <= len(cells) and cells[i].startswith("The "):
        name, offer = cells[i:i + 2]
        row = {"id": slug(name.removeprefix("The ")), "name": name, "offer": offer,
               "source": "11.8"}
        if "one of the eighteen kinds" in offer:
            row["kind"] = "one of the eighteen"
        out.append(row)
        i += 2
    return out


def extract_paradox_born(text: str) -> list[dict]:
    """§11.8's paradox-born: what each comes from and its gift, and its level-1
    numbers and body. They have no role in §11.1 and no form (§11.10); the
    Twinned's health and carry are one body's pools, shared (C53)."""
    cells = special_tables(text)
    i = cells.index("Gift") + 1
    gifts = {}
    while i + 3 <= len(cells) and cells[i].startswith("The "):
        name, source, gift = cells[i:i + 3]
        gifts[name] = (source, gift)
        i += 3
    j = cells.index("Body") + 1
    out = []
    while j + 6 <= len(cells) and cells[j].startswith("The "):
        name, health, speed, power, carry, body = cells[j:j + 6]
        source, gift = gifts.get(name, ("", ""))
        lead = lambda s: int(re.match(r"\d+", s).group(0))
        size = re.match(r"(Small|Standard|Large)", body)
        out.append({
            "id": slug(name.removeprefix("The ")), "name": name, "paradox": source,
            "gift": gift, "health": lead(health), "speed": float(speed),
            "power": int(power), "carry": lead(carry), "body": body,
            "size": size.group(1) if size else None,
            "shared_pools": "shared" in health and "shared" in carry,
            "forms": [], "source": "11.8",
        })
        j += 6
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
    # v3.0 inserted the Library between the ward table and 11.1, so an end
    # marker of "11.1 Roles" swallows the Library's level table as extra
    # wards. v3.1 renumbered the Library from 10.5 to 10.4, which broke the
    # fix and put the rows back — ninety-nine of them, because v3.1's table
    # is longer. The marker is the title now.
    end = heading(text, "The Library") or "11.1 Roles"
    # v3.3 answered G3: seven columns, a sensor for each ward, what an upgrade
    # scales, and whether the ward is seen. Levels 2-5 scale "the number in the
    # column above" by 10.2's effect ladder, so no ward is missing its levels.
    headers = ["Ward", "School", "Sensor: kind and radius",
               "Effect at level 1: what, where, how much, how long",
               "An upgrade scales", "Resets after", "Seen"]
    if headers[2] in text:
        return table(text, "10.3 Wards", end,
                     ["name", "school", "sensor", "effect_level_1", "scales",
                      "resets_after", "seen"], headers)
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
    """§11.7's Sages, and what each gains at every fifth level (G52, v3.7):
    the second table, which the first one's reader would otherwise read on
    into as eleven more Sages."""
    end = "What each launch Sage gains at every fifth level"
    if end not in text:
        end = "11.8 Special characters"
    rows = table(text, "11.7 Sages, the heroes", end,
                 ["name", "unlocks", "heist_powers", "at_home"],
                 ["Sage", "Unlocks", "Heist powers", "At home"])
    if end != "11.8 Special characters":
        block = section(text, end, heading(text, "Special characters") or "11.8 Special characters")
        cells = [c.strip()[2:].strip() for c in block.split("\n") if c.strip().startswith("| ")]
        levels = cells[1:cells.index("The Archivist")] if "The Archivist" in cells else []
        width = len(levels) + 1
        by_name = {cells[i]: dict(zip(levels, cells[i + 1:i + width]))
                   for i in range(len(levels) + 1, len(cells) - width + 1, width)}
        for r in rows:
            if r["name"] in by_name:
                r["levels"] = by_name[r["name"]]
    return rows


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


def extract_forms(text: str, ruleborn: list[dict]) -> list[dict]:
    """§11.10: "Eighteen kinds and three notes make 54 forms. The three notes
    are the same for every kind", so the forms are the product of §11.11's
    kinds and §11.10's note table, one row each — the table a Forms album, a
    Nursery's odds and a hatch all read."""
    notes = table(text, "11.10 Law-shaped forms", "11.11 The character bible",
                  ["note", "look", "quirk"],
                  ["Note of the form", "How it looks", "Its small quirk"])
    return [{"id": f"{kind['id']}_{note['id']}", "kind": kind["name"],
             "note": note["note"], "look": note["look"], "quirk": note["quirk"]}
            for kind in ruleborn for note in notes]


BUILDING_NAMES = ["Keeper's Spire", "Vault", "Anchor Stone", "Star Well",
                  "Aether Spring", "Garden", "Storehouse", "Law Pylon", "Hearth",
                  "Nursery", "Guardian Post", "Ward", "Resonance Lab",
                  "Observatory", "Beacon", "Visitor's Dock",
                  # v3.3 moved the Library's ten levels into 10.2 (C8).
                  "Library"]


def extract_library(text: str) -> dict | None:
    """v3.0 added the Library as §10.5, outside §10.2's table of sixteen.

    It is a building — "a building at the Heart, one per universe" — so it
    belongs with the others, and being outside the table is exactly how C8
    happened in the first place.
    """
    start = heading(text, "The Library")
    if not start:
        return None
    block = section(text, start, "11Characters")
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
        # The note was written when v3.0 gave three levels and would have gone
        # on saying so after v3.1 gave ten, which is the fault this file's
        # heading lookup is also about: a sentence about the data, kept beside
        # the data, not derived from it.
        "note": (f"\u00a7{start.split()[0]} gives all {len(levels)} levels, but "
                 f"outside \u00a710.2's table of every level of every building"
                 if len(levels) >= 10 else
                 f"\u00a7{start.split()[0]} gives {len(levels)} levels "
                 f"({', '.join(str(l['level']) for l in levels)}); the other "
                 f"{10 - len(levels)} are not stated, and every other building "
                 f"in \u00a710.2 lists every level"),
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
            # A level row: a level number then a Starlight cost. v3.3 added a
            # per-realm table of Guardian Post starts ("1", "+6%", ...) inside
            # the Guardian Post's block; it is not a level ladder.
            if (re.fullmatch(r"\d+", cells[i])
                    and re.fullmatch(r"[\d,]+", cells[i + 1])):
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
    write("laws", codex_chapters(text, extract_laws(text)))
    write("resonances", extract_resonances(text))
    write("chords", extract_chords(text))
    write("terrain", extract_terrain(text))
    write("roles", extract_roles(text))
    ruleborn = extract_ruleborn(text)
    write("ruleborn", ruleborn)
    write("forms", extract_forms(text, ruleborn))
    write("visitors", extract_visitors(text))
    write("paradox_born", extract_paradox_born(text))
    write("traits", extract_traits(text))
    buildings = extract_buildings(text)
    # Before v3.3 the Library lived outside 10.2's table; read it from there
    # only when 10.2 does not carry it.
    in_table = any(b["id"] == "library" and b["levels"] for b in buildings)
    library = None if in_table else extract_library(text)
    if not in_table:
        buildings = [b for b in buildings if b["id"] != "library"]
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
