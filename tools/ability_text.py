#!/usr/bin/env python3
"""C6's remaining half, creature by creature: are the two ability texts one
design written twice, or two designs?

    python3 tools/ability_text.py
    python3 tools/ability_text.py --self-test

Why this exists
---------------
C6 is the last gate holding the character screens, and the register has
described what is left of it as wording - "all 18 still give different ability
text, so the two sections are one reconciliation apart rather than two rosters
apart". That was written after v3.1 reconciled the schools and roles, and it is
too kind. Reading the 18 pairs out of `content/ruleborn.json`:

* **Cooldowns.** Fifteen pairs state one on both sides. In thirteen of them
  §11.2's is shorter, by a median of four seconds, and in one they agree. A
  difference that runs one way in thirteen of fourteen is not two people
  wording the same number differently; it is two balance passes, and §11.2's is
  the more generous one throughout.

* **Effects.** Twelve of the eighteen do a different thing, not the same thing
  by a different amount. Mossbear takes 50% less damage in §11.11 and heals 20%
  in §11.2. Prism Mite splits into copies with half the health, or into mites
  each carrying half the loot. Echoplate shields the whole crew and reflects, or
  shields one ally and does not. Three creatures - Quarryback, Tidewalker,
  Echoplate - have no cooldown in §11.11 at all, because §11.11 describes
  something continuous and §11.2 describes an activated power.

So the screen is not waiting for someone to choose a phrasing. It is waiting for
the eighteen abilities to be designed once. That is content work, and it is the
reason C6 stays a full gate on screens while it is only partly one on
characters: a character screen still has a portrait, a role, a school, traits
and levels to draw, and every one of those is settled.

What is a judgement here, and what is not
-----------------------------------------
`cooldowns()` is read out of the two texts and is not a judgement. `KIND` is:
each of the eighteen is classified by hand as `magnitude` or `effect` with the
reason written out, because no regular expression can tell "heals 20%" from
"takes 50% less damage" - they share no words and mean different things, while
"Glide 3 tiles" and "Glide over one gap" share a word and mean the same thing.

The check that keeps it honest is that `KIND` must name every creature in the
content file and no others, so a roster change cannot leave a stale judgement
behind. Nothing here is written to `content/ruleborn.json`; the content says
what the document says, and this is a reading of it.
"""

import argparse
import collections
import json
import pathlib
import re
import statistics
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONTENT = ROOT / "content"

#: §11.11 states a cooldown after a semicolon, or as "per N s" where the
#: ability is a repeating one. §11.2's summary table puts it in trailing
#: parentheses. Anything else means that side states no cooldown, which is
#: itself the finding for three of the eighteen.
CD_BIBLE = (re.compile(r";\s*(\d+(?:\.\d+)?)\s*s"),
            re.compile(r"per (\d+(?:\.\d+)?)\s*s"))
CD_TABLE = re.compile(r"\((\d+(?:\.\d+)?)\s*s\)\s*$")

MAGNITUDE, EFFECT = "magnitude", "effect"

#: §11.2's own order, so the report reads down the roster the way
#: the summary table does.
ROLE_ORDER = ("Scout", "Breaker", "Carrier", "Warden", "Mender")

#: id -> (kind, why). `magnitude` means the two texts describe the same thing
#: and disagree about how much; `effect` means they describe different things.
#: Every reason quotes both sides, so a reader can disagree with the call
#: rather than with the count.
KIND = {
    "featherkin": (MAGNITUDE,
        "Both glide over an obstacle. §11.11 specifies it as 3 tiles and "
        "one height level, §11.2 as “one gap or wall” - a "
        "specification and a summary of the same move."),
    "skyskipper": (EFFECT,
        "§11.11 carries 40% more and hops; §11.2 only bounds 4 tiles "
        "while loaded. The carry bonus is a Carrier's whole reason to exist and "
        "only one side has it."),
    "rambler": (EFFECT,
        "§11.11 breaks “one wall or boulder” - terrain. "
        "§11.2 breaks “the first ward hit” - a placed defence. "
        "§6 and §10.2 are different systems with different budgets."),
    "glass_golem": (MAGNITUDE,
        "Both raise a crystal wall. §11.2 says it blocks guards, which is "
        "what a wall is for; the wall lasts 6 s or 5 s and the cooldown is 20 "
        "or 16."),
    "quarryback": (EFFECT,
        "§11.11 is a movement attack - “rolls 5 tiles then slams; "
        "double damage to walls” - with no cooldown. §11.2 is a timed "
        "buff: break walls and the Vault 50% faster for 6 s. The Vault is in "
        "one and not the other, and it is the thing a heist is for."),
    "prism_mite": (EFFECT,
        "§11.11 splits into “two half-health copies”, which is "
        "survivability. §11.2 splits into “two mites, each carrying "
        "half”, which is loot throughput. Half the health and half the "
        "loot are different halves."),
    "tidewalker": (EFFECT,
        "§11.11 is a terrain affinity that carries an ally through water "
        "and has no cooldown. §11.2 is an activated “ignore all "
        "slowing” for 6 s, solo, on 15 s. Water is a realm feature; "
        "slowing is a status."),
    "hourkeeper": (MAGNITUDE,
        "Both undo damage by rewinding an ally. The window is 3 s or 5 s and "
        "the cooldown 24 or 16."),
    "stillwatch": (EFFECT,
        "§11.11 freezes “one guard”; §11.2 freezes "
        "“one guard or ward”. A ward is a placed object rather than a "
        "character, and whether the freeze reaches it changes every ward-heavy "
        "layout — which is most of §13.4's."),
    "emberling": (EFFECT,
        "§11.11 is area damage plus a 1 s stun, which is crowd control "
        "against guards. §11.2 is heavy damage to “a ward or "
        "pylon”, which is single-target demolition. The stun exists on one "
        "side only."),
    "stormhound": (EFFECT,
        "§11.2 adds “hits chain to a second target”, which "
        "§11.11 has no trace of, and drops “carrying anything”, "
        "which §11.11 has. The speed is 40% or 60%."),
    "sparkwright": (EFFECT,
        "The one pair whose numbers agree exactly - 5 s off a cooldown, on a "
        "20 s cooldown - and they still differ: §11.11 cuts “one "
        "ally's”, §11.2 cuts “the Sage's power cooldowns”. "
        "§12.5 makes the Sage a separate slot from the crew, so this is "
        "the clearest case that the gap is not numeric."),
    "mossbear": (EFFECT,
        "§11.11 takes 50% less damage for 6 s; §11.2 heals 20% over "
        "4 s. Mitigation and healing are different resources and are countered "
        "differently."),
    "bloomling": (EFFECT,
        "§11.11 heals all nearby allies 15% at once, with no radius. "
        "§11.2 heals 6 a second for 5 s within 3 tiles. Instant against "
        "over-time, percentage against flat, and only one states the radius."),
    "rootrunner": (MAGNITUDE,
        "Both grow a root bridge over a gap. §11.2 gives it a life - 8 s - "
        "and a shorter cooldown."),
    "echoplate": (EFFECT,
        "§11.11 blocks one hit “for the crew” and returns it at "
        "40%. §11.2 shields “an ally”, takes its next hit, and "
        "reflects nothing. Crew against one ally, and a reflect on one side "
        "only."),
    "lantern_wisp": (MAGNITUDE,
        "Both reveal hidden wards within a radius: 6 tiles or a 5-tile area "
        "held for 6 s. §11.2 also names illusions, which is a kind of "
        "revealing rather than a second ability."),
    "soulmender": (MAGNITUDE,
        "Both share the crew's incoming damage. For 8 s or 6 s, on 22 s or "
        "18 s."),
}


#: §12.6 sets the game's own pace: "roughly one every 8 to 12 seconds, or 15 to
#: 25 in a run", and names "when to use abilities and casts" as one of the
#: decisions it is counting.
DECISION_SECONDS = (8, 12)
DECISIONS_PER_RUN = (15, 25)

#: §12.5. The clock is 150 s plus 15 s per link, capped at 240.
CLOCK = (150, 240)

#: §12.5 again: 3 characters, 4 from Keeper level 8, 5 from level 16.
CREW = (3, 5)


def cadence(rows: list[dict], key: str) -> dict:
    """How many ability windows a heist affords, against §12.6's own budget.

    This is the question under the cooldown column, and neither table was
    written against it. An ability comes off cooldown every `c` seconds per
    character, so a crew of `n` gets `clock * n / c` windows in a run - and
    §12.6 budgets 15 to 25 *decisions* for the whole heist, abilities included
    among them.

    The crew grows from 3 to 5 over Keeper levels 8 and 16 and the clock grows
    with the route, so this is not one number: it is a range that widens as the
    player levels. That is the part worth seeing. §11.11's cooldowns land at
    the top of §12.6's budget for a crew of three on a short clock and nowhere
    near it after that, which means the document describes the early game and
    the tables describe a different one.
    """
    cds = [r[key] for r in rows if r[key]]
    median = statistics.median(cds)
    windows = {}
    for clock in CLOCK:
        for n in CREW:
            windows[(clock, n)] = clock * n / median
    return dict(
        n=len(cds), median=median, low=min(cds), high=max(cds),
        windows=windows,
        fewest=min(windows.values()), most=max(windows.values()),
        # And the inverse: what a cooldown would have to be for one ability to
        # come off cooldown at §12.6's own stated cadence.
        implied={n: (DECISION_SECONDS[0] * n, DECISION_SECONDS[1] * n)
                 for n in CREW},
    )


#: What each role's ability is allowed to be about.
#:
#: §11.5 births fewest-roles-first, §12.8 makes guards behave differently
#: toward each role, and §11.11 states outright that no ruleborn is strictly
#: better than another and that levels "never turn a Scout into a Warden". All
#: three depend on the roles staying distinguishable, and the fastest way to
#: lose that is an ability that does another role's job well.
#:
#: These are the domains the document already gives each role, with the
#: sections that give them. They are used to check the picks below, not to
#: generate them.
ROLE_DOMAIN = {
    "Scout":   ("information and its own movement \u2014 \u00a712.4's scout "
                "report and \u00a712.17's detection are what a Scout is for",
                ("reveal", "hidden", "sight", "notice", "glide", "sprint",
                 "light", "illusion", "ward", "guard", "tiles", "speed")),
    "Breaker": ("damage to what \u00a712.6 makes breakable: wards, pylons and "
                "the Vault",
                ("break", "damage", "wall", "ward", "pylon", "vault", "crack")),
    "Carrier": ("loot: how much the crew can hold and how it moves \u2014 all "
                "that is left to a Carrier since \u00a712.19 gave every role "
                "the same 30-a-second load rate",
                ("carry", "carrying", "loot", "load", "bags", "half", "bound",
                 "obstacle", "gap", "bridge", "water", "slow")),
    "Warden":  ("taking or stopping damage on the crew's behalf",
                ("block", "shield", "absorb", "less damage", "wall", "freeze",
                 "root", "guard", "hit")),
    "Mender":  ("restoring the crew: health, and readiness",
                ("heal", "health", "restore", "rewind", "undo", "cooldown",
                 "share", "damage is shared", "allies", "ally")),
}

#: The pick for each of the eighteen, and the reason.
#:
#: `side` is "11.11", "11.2" or "merge". Where it is "merge" the two texts each
#: carry something the other needs and `text` says what the one ability is.
#: Where it is a side, `text` is that side's own words, edited only where the
#: reason says so.
#:
#: **Every reason argues from the role or from a system the document already
#: has, never from taste.** That is the whole point: eighteen picks argued from
#: taste is a redesign and needs a designer; eighteen argued from §12.6, §12.19
#: and §11.11 is a reading of the document that can be checked and disagreed
#: with line by line.
#:
#: The cooldowns are deliberately not settled here. Both tables are two to
#: three times over §12.6's decision budget for the whole run (D32), so a
#: cooldown picked from either column is picked from a table that does not fit
#: the game around it. Every pick below states the effect; D32 states the
#: number, once, for all eighteen.
PICK = {
    # -- Scouts: information and their own movement -------------------------
    "featherkin": ("11.11", "Glide 3 tiles, ignoring one height level",
        "The same move in both. \u00a711.11 says it in tiles and height "
        "levels, which is the unit \u00a75.4 lays a realm out in and the one "
        "a screen can show; \u00a711.2's \u201cone gap or wall\u201d is a "
        "summary of it and cannot be drawn."),
    "stormhound": ("11.11", "Sprints 40% faster for 5 s",
        "Both texts poach. \u00a711.2 adds \u201chits chain to a second "
        "target\u201d, which is damage and so the Breaker's; \u00a711.11 "
        "adds \u201ccarrying anything\u201d, which is the Carrier's and is "
        "the one thing \u00a712.19 left a Carrier. Strip both and the sprint "
        "is what is left, which is a Scout's own movement."),
    "lantern_wisp": ("merge",
        "Reveals hidden wards and guards within 6 tiles, held for 6 s",
        "\u00a712.4 already names the Lantern Wisp as one of the three ways "
        "ward positions are learned during a heist, so the reveal is this "
        "creature's job and \u00a711.11's \u201cand guards\u201d is the "
        "half \u00a712.17's detection needs. \u00a711.2 contributes the "
        "duration: a reveal with no duration cannot be timed by a player or "
        "drawn as a state."),

    # -- Breakers: what 12.6 makes breakable --------------------------------
    "rambler": ("11.2", "Charge 5 tiles, breaking the first ward hit",
        "\u00a711.11 breaks \u201cone wall or boulder\u201d, which is "
        "\u00a76 terrain and belongs to whoever crosses it. \u00a712.6 names "
        "wards, pylons and the Vault as what a heist breaks, and that set is "
        "what makes a Breaker a Breaker."),
    "quarryback": ("11.2", "Break walls and the Vault 50% faster for 6 s",
        "\u00a712.6 already gives every Breaker double damage to the Vault as "
        "a property of the role. \u00a711.11's \u201cdouble damage to "
        "walls\u201d restates the role bonus, and an ability that restates the "
        "role is not an ability. \u00a711.2's timed buff stacks on top of it "
        "and puts a \u201cwhen\u201d into the Vault phase, which \u00a712.6 "
        "calls the heist's central decision."),
    "emberling": ("11.2", "Burst a ward or pylon for heavy damage",
        "\u00a711.11's 1 s stun is crowd control against guards, and "
        "\u00a712.20 prices attacking a guard at 1000 suspicion \u2014 so a "
        "stun is an escape tool, which is the Warden's and the Scout's. "
        "\u00a711.2's version breaks things, which is the role."),

    # -- Carriers: loot, all 12.19 left them --------------------------------
    "skyskipper": ("merge", "Bound 4 tiles while loaded; carries 40% more",
        "\u00a712.19 gave every role the same 30-a-second load rate, so "
        "capacity is the whole of what still separates a Carrier. "
        "\u00a711.11's 40% is that, and it is a passive rather than an "
        "ability \u2014 \u00a711.2 reads the ability column and finds only "
        "the hop. Both, in their own columns."),
    "prism_mite": ("11.2", "Split into two mites, each carrying half, for 5 s",
        "\u00a711.11's half-health copies are a survivability trick, which is "
        "the Warden's. Two mites each carrying half is loot throughput at the "
        "Vault, which is the Carrier's and is the phase \u00a712.6 builds the "
        "run around."),
    "tidewalker": ("merge",
        "Ignore all slowing for 6 s; wades at full speed and carries one ally "
        "through water",
        "\u00a711.11 is a terrain affinity with no cooldown \u2014 that is a "
        "passive, and it is the one the creature is named for, against "
        "\u00a76's water and the starting law Slow rivers. \u00a711.2 is the "
        "ability. Neither replaces the other."),
    "rootrunner": ("11.2", "Grow a root bridge over a gap for 8 s",
        "Identical but for the bridge's life. A bridge that never expires "
        "edits the realm for the rest of the heist, which \u00a713.3's "
        "generator lays out and cannot re-plan around."),

    # -- Wardens: taking damage so the crew does not ------------------------
    "glass_golem": ("merge",
        "Raise a crystal wall that blocks guards for 6 s",
        "\u00a711.2 says what the wall is for, which \u00a711.11 leaves to "
        "the reader; \u00a711.11 gives it the longer life. The wall is the "
        "same wall."),
    "stillwatch": ("11.11", "Freezes one guard for 2.5 s",
        "\u00a711.2 adds wards to the target set, and G3's ward spec gives "
        "\u00a712.5's Tinker trait a disarm action for exactly that. An "
        "ability that duplicates an action the crew already has is a second "
        "way to do one thing, which is what \u00a731.2 is about."),
    "mossbear": ("11.11", "Roots in place, taking 50% less damage for 6 s",
        "\u00a711.2 makes it heal, and there are four Menders whose whole "
        "role that is. Mitigation and healing are countered differently and "
        "\u00a711.11 says levels never turn one role into another; this would "
        "do it in one line."),
    "echoplate": ("11.11", "Shield flare, blocking one hit for the crew",
        "\u00a711.11's reflect \u2014 \u201creturns once at 40%\u201d "
        "\u2014 is damage, and so the Breaker's; drop it. What is left is a "
        "block for the whole crew, and that is what makes a Warden worth one "
        "of three slots. \u00a711.2's single-ally shield is not."),

    # -- Menders: health and readiness --------------------------------------
    "hourkeeper": ("11.2",
        "Return an ally to its health of 5 seconds ago",
        "The same ability. \u00a711.2 states the window, and the window is "
        "the implementable part: \u00a712.21 requires every effect to be a "
        "change to a named parameter, and \u201chealth 5 seconds ago\u201d "
        "names the buffer the engine has to keep."),
    "sparkwright": ("11.11", "Cuts one ally's cooldown by 5 s",
        "\u00a711.2 aims it at the Sage, and \u00a712.5 makes the Sage one "
        "slot beside the crew rather than part of it \u2014 and a slot nobody "
        "has before Keeper level 2. An ability that does nothing in a crew "
        "without a Sage is an ability most early heists do not have."),
    "bloomling": ("merge",
        "Heal all allies within 3 tiles by 15% over 5 s",
        "\u00a711.2 states the radius and the duration, which \u00a711.11's "
        "\u201call nearby allies\u201d cannot be drawn without. "
        "\u00a711.11 states it as a percentage, which \u00a711.2's flat "
        "\u201c6 a second\u201d does not \u2014 and characters level "
        "(\u00a711.7), so a flat heal shrinks against its own crew every "
        "level."),
    "soulmender": ("11.11", "Links the crew: damage is shared for 8 s",
        "The same ability at two durations, and the duration is D32's to set "
        "with the rest. \u00a711.11's is kept only so the pick is recorded "
        "against one of the two texts rather than invented."),
}


def mislabelled(rows: list[dict]) -> list[str]:
    """A pick that names a side but does not carry that side's words.

    `pick` is a label and `picked` is text, and nothing ties them together —
    an edit to one and not the other would leave a pick claiming to come from
    §11.11 while saying what §11.2 says, which is the disagreement this whole
    file is about, reintroduced inside the fix for it.

    Content words, because the two texts differ in grammar everywhere: a pick
    labelled with a side must share most of its words with that side.
    """
    stop = {"a", "an", "the", "for", "of", "to", "and", "or", "in", "on", "at",
            "s", "one", "its", "it", "by", "over", "with", "into", "all"}
    bad = []
    for r in rows:
        if r["pick"] not in ("11.11", "11.2"):
            continue
        source = r["bible"] if r["pick"] == "11.11" else r["table"]
        words = {w for w in re.findall(r"[a-z]+", r["picked"].lower())
                 if w not in stop}
        have = {w for w in re.findall(r"[a-z]+", source.lower())
                if w not in stop}
        if not words:
            continue
        shared = len(words & have) / len(words)
        if shared < 0.6:
            bad.append(f"{r['name']}'s pick is labelled {r['pick']} but only "
                       f"{shared:.0%} of its words are in that text")
    return bad


def named_laws(text: str, laws: list) -> list[str]:
    """Which authored laws a passive names, by name.

    §11.11 states the rule its own passives follow: "Each resists exactly one
    law family, so crew choice against a scouted island is a real decision."
    That is testable — a resistance has to name a law — and it is the argument
    `docs/design/spec/ruleborn.md` makes for adopting §11.11's column, made
    from the data instead of by eye.
    """
    low = text.lower()
    return sorted({law["name"] for law in laws
                   if law["name"].lower() in low})


def passives(roster: list, laws: list) -> list[dict]:
    """Each creature's two passives, and whether each names a law."""
    out = []
    for c in roster:
        bible, table = c.get("resists", ""), c.get("passive_11_2", "")
        out.append(dict(
            name=c["name"], role=c["role"], bible=bible, table=table,
            bible_laws=named_laws(bible, laws),
            table_laws=named_laws(table, laws),
            same=bible.strip().lower() == table.strip().lower(),
        ))
    return out


def picks(rows: list[dict]) -> list[dict]:
    """Each creature with its pick attached."""
    out = []
    for r in rows:
        side, text, why = PICK.get(r["id"], (None, "", ""))
        out.append({**r, "pick": side, "picked": text, "reason": why})
    return out


def off_role(rows: list[dict]) -> list[str]:
    """Picks whose text reads as another role's job.

    A keyword test, and a weak one - it is here to catch the obvious case
    where a pick's own reason argues one role and its text says another, not
    to judge design. The reasons above are the argument; this is the guard
    against an edit that changes a text and not the reason under it.
    """
    bad = []
    for r in rows:
        if not r["picked"]:
            continue
        low = r["picked"].lower()
        mine = set(ROLE_DOMAIN[r["role"]][1])
        if not any(w in low for w in mine):
            bad.append(f"{r['name']} is a {r['role']} and its picked text "
                       f"touches nothing in that role's domain: "
                       f"{r['picked']!r}")
    return bad


def load() -> list:
    return json.loads((CONTENT / "ruleborn.json").read_text(encoding="utf-8"))


def cooldown(text: str, table: bool) -> float | None:
    if table:
        m = CD_TABLE.search(text)
        return float(m.group(1)) if m else None
    for pattern in CD_BIBLE:
        m = pattern.search(text)
        if m:
            return float(m.group(1))
    return None


def pairs(roster: list) -> list[dict]:
    out = []
    for c in roster:
        bible = c["ability"]
        table = c["alt_11_2"]["ability"]
        kind, why = KIND.get(c["id"], (None, ""))
        out.append(dict(
            id=c["id"], name=c["name"], role=c["role"],
            bible=bible, table=table, kind=kind, why=why,
            cd_bible=cooldown(bible, table=False),
            cd_table=cooldown(table, table=True),
        ))
    return out


def cooldowns(rows: list[dict]) -> dict:
    """The mechanical half: where both sides state one, which way does it go?"""
    both = [r for r in rows if r["cd_bible"] is not None and r["cd_table"] is not None]
    deltas = [r["cd_table"] - r["cd_bible"] for r in both]
    return dict(
        both=len(both),
        shorter=sum(1 for d in deltas if d < 0),
        longer=sum(1 for d in deltas if d > 0),
        equal=sum(1 for d in deltas if d == 0),
        median=statistics.median(d for d in deltas if d) if any(deltas) else 0,
        missing=[r["name"] for r in rows if r["cd_bible"] is None],
    )


def unclassified(rows: list[dict]) -> tuple[list, list]:
    """Creatures with no judgement, and judgements with no creature."""
    ids = {r["id"] for r in rows}
    return ([r["name"] for r in rows if r["kind"] is None],
            sorted(set(KIND) - ids))


def report(rows: list[dict]) -> None:
    cd = cooldowns(rows)
    effect = [r for r in rows if r["kind"] == EFFECT]
    print("C6's remaining half: 18 creatures, two ability texts each\n")
    print(f"  {'':<14}{'role':<9}{'11.11':>7}{'11.2':>7}{'Δ':>7}   kind")
    for r in rows:
        a, b = r["cd_bible"], r["cd_table"]
        delta = f"{b - a:+.0f}" if a is not None and b is not None else ""
        print(f"  {r['name']:<14}{r['role']:<9}"
              f"{f'{a:.1f}' if a is not None else '—':>7}"
              f"{f'{b:.1f}' if b is not None else '—':>7}{delta:>7}   {r['kind']}")
    print()
    print(f"  Cooldowns: {cd['both']} pairs state one on both sides. "
          f"{cd['shorter']} have §11.2 shorter, {cd['longer']} longer, "
          f"{cd['equal']} equal;")
    print(f"  the median difference is {cd['median']:+.0f} seconds. "
          f"{len(cd['missing'])} state none in §11.11 at all "
          f"({', '.join(cd['missing'])}),")
    print(f"  because §11.11 describes something continuous there and "
          f"§11.2 an activated power.\n")
    print(f"  Effects: {len(effect)} of {len(rows)} do a different thing rather "
          f"than the same thing by a\n  different amount.\n")
    for r in effect:
        print(f"  {r['name']}")
        print(f"    11.11  {r['bible']}")
        print(f"    11.2   {r['table']}")
        print(f"           {r['why']}\n")
    # -- the draft ---------------------------------------------------------
    picked = picks(rows)
    counts = collections.Counter(r["pick"] for r in picked)
    print(f"\n  The pick, creature by creature \u2014 "
          f"{counts['11.11']} from \u00a711.11, {counts['11.2']} from "
          f"\u00a711.2, {counts['merge']} that need both\n")
    for role in ROLE_ORDER:
        here = [r for r in picked if r["role"] == role]
        print(f"  {role.upper()} \u2014 {ROLE_DOMAIN[role][0]}")
        for r in here:
            print(f"    {r['name']:<14} [{r['pick']:<5}] {r['picked']}")
            print(f"    {'':<14}         {r['reason']}")
        print()

    # -- the cooldowns, which are one decision rather than eighteen ---------
    print("  The cooldowns are not settled above, and cannot be settled by "
          "picking a column.\n")
    print(f"  {'':<8}{'median':>8}{'windows in a run':>20}")
    print(f"  {'':<8}{'':>8}{'crew 3, 150 s':>16}{'crew 5, 240 s':>16}")
    for key, label in (("cd_bible", "11.11"), ("cd_table", "11.2")):
        c = cadence(rows, key)
        print(f"  {label:<8}{c['median']:>7.0f}s"
              f"{c['windows'][(CLOCK[0], CREW[0])]:>16.0f}"
              f"{c['windows'][(CLOCK[1], CREW[1])]:>16.0f}")
    lo, hi = DECISIONS_PER_RUN
    print(f"\n  \u00a712.6 budgets {lo} to {hi} decisions for the whole run "
          f"and names \u201cwhen to use abilities")
    print(f"  and casts\u201d as one of them. Both tables hand a full crew two "
          f"to three times that many")
    print(f"  ability windows on their own, and the number grows with the crew "
          f"(3 to 5) and the")
    print(f"  clock (150 s to 240 s) \u2014 so the game gets more frantic as "
          f"the player levels, which")
    print(f"  is a progression fault rather than a balance one. For one "
          f"ability to come off cooldown")
    print(f"  at \u00a712.6's own 8-to-12-second cadence the numbers would "
          f"have to be:\n")
    imp = cadence(rows, "cd_bible")["implied"]
    for n in CREW:
        print(f"    a crew of {n}: {imp[n][0]} to {imp[n][1]} s")
    print(f"\n  against 8-24 in \u00a711.11 and 10-20 in \u00a711.2. That is "
          f"D32, it is one decision")
    print(f"  rather than eighteen, and every cooldown above follows from it.\n")

    print("  A difference that runs one way in "
          f"{cd['shorter']} of {cd['both']} is two balance passes, not two "
          "wordings. Settling")
    print("  it is designing eighteen abilities once. It is the last gate "
          "standing on the")
    print("  screens \u2014 C3 and C8 are decided in everything but two "
          "sentences and a table \u2014 and")
    print("  it does not hold the character art, which needs a portrait, a "
          "role and a school,")
    print("  all three settled since v3.1.")


def self_test() -> int:
    ok = True

    def check(name: str, got, want) -> None:
        nonlocal ok
        good = got == want
        ok = ok and good
        print(f"  [{'ok ' if good else 'FAIL'}] {name}"
              f"{'' if good else f'  got {got!r}, want {want!r}'}")

    rows = pairs(load())
    check("all 18 creatures are read", len(rows), 18)
    # A judgement with no creature, or a creature with no judgement, is how a
    # hand-written classification goes stale behind a roster change.
    check("every creature is classified and no judgement is orphaned",
          unclassified(rows), ([], []))
    cd = cooldowns(rows)
    check("13 of the 15 comparable pairs have §11.2 shorter",
          (cd["shorter"], cd["both"]), (13, 15))
    check("three creatures state no cooldown in §11.11",
          len(cd["missing"]), 3)
    check("12 of the 18 differ in effect",
          sum(1 for r in rows if r["kind"] == EFFECT), 12)
    # The two readers must not both match the same text, or a pair would be
    # compared with itself and always agree.
    check("§11.2's trailing-parenthesis form is not read as §11.11's",
          cooldown("Glide over one gap or wall (12 s)", table=False), None)
    check("§11.11's semicolon form is not read as §11.2's",
          cooldown("Glide 3 tiles, ignoring one height level; 14 s cooldown",
                   table=True), None)

    # -- the draft ---------------------------------------------------------
    drafted = picks(rows)
    check("every creature carries a pick and no pick is orphaned",
          ([r["name"] for r in drafted if not r["pick"]],
           sorted(set(PICK) - {r["id"] for r in rows})), ([], []))
    check("every pick names a side or says it needs both",
          sorted({r["pick"] for r in drafted}), ["11.11", "11.2", "merge"])
    check("no pick is labelled with a side it does not come from",
          mislabelled(drafted), [])
    check("no picked ability does another role's job", off_role(drafted), [])
    # A dead entry in ROLE_DOMAIN would make off_role check fewer roles than
    # it looks like it is checking.
    check("every role in ROLE_DOMAIN has creatures in it",
          sorted({r["role"] for r in drafted}), sorted(ROLE_DOMAIN))
    check("ROLE_ORDER covers every role", sorted(ROLE_ORDER), sorted(ROLE_DOMAIN))

    # -- D32 ---------------------------------------------------------------
    # The finding is that both tables overrun §12.6's budget for the whole run,
    # at the smallest crew and the shortest clock. If a re-cost ever brings one
    # inside it, this fails and D32 is the thing to re-read — which is what
    # pinning a finding to a test is for.
    for key, label in (("cd_bible", "11.11"), ("cd_table", "11.2")):
        c = cadence(rows, key)
        check(f"{label}'s cooldowns reach §12.6's whole-run budget of "
              f"{DECISIONS_PER_RUN[1]} at the smallest crew and clock",
              c["fewest"] >= DECISIONS_PER_RUN[1], True)
    check("and §12.6's own cadence implies longer cooldowns than either "
          "table has",
          min(cadence(rows, "cd_bible")["implied"][CREW[0]])
          > max(r["cd_table"] for r in rows if r["cd_table"]), True)
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return self_test()
    report(pairs(load()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
