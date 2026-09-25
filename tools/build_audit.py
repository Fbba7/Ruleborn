#!/usr/bin/env python3
"""Render the audit register to a static HTML page.

    python3 tools/build_audit.py

Reads tools/audit_register.py and writes docs/audit/index.html. Every item is
present in the markup, so the page reads correctly with no JavaScript at all;
the script only filters and remembers the chosen filter.
"""

import datetime
import html
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from design_doc import TEXT as DOC_TEXT, VERSION as DOC_VERSION   # noqa: E402
from audit_register import (DEPENDS, DESIGN_GATES, EDITS, FOUND_IN_V3,
                            status as reg_status,
                            GATE_OWNER,  # noqa: E402
                            REGISTER, RESEARCH, SETTLED, V3, V31, V32, V33, V34,
                            FOUND_IN_V33, FOUND_IN_V34, side_of, status_before_v34)

from build_stamp import stamped  # noqa: E402

OUT = pathlib.Path(__file__).resolve().parent.parent / "docs" / "audit" / "index.html"
DECISIONS = pathlib.Path(__file__).resolve().parent.parent / "docs" / "decisions"


def answers() -> dict[str, dict]:
    """The owner's answers (docs/decisions/answers.json), each with the chosen
    option's label and document edit from the brief, keyed by item id."""
    import json
    got = json.loads((DECISIONS / "answers.json").read_text(encoding="utf-8"))["answers"]
    brief = json.loads((DECISIONS / "brief.json").read_text(encoding="utf-8"))["entries"]
    out = {}
    for item_id, a in got.items():
        # An answer the brief does not have is build_brief --check's to report.
        option = next((o for o in brief.get(item_id, {}).get("options", [])
                       if o["key"] == a.get("option")), None)
        if option is not None:
            out[item_id] = dict(a, label=option["label"], doc_edit=option.get("doc_edit", ""))
    return out


ANSWERS = answers()

SEVERITY = {
    "change":      ("Approach change", "chg"),
    "blocking":    ("Blocking",        "blk"),
    "design":      ("Design finding",  "dsg"),
    "significant": ("Significant",     "sig"),
    "minor":       ("Minor",           "min"),
    "choice":      ("Your call",       "cho"),
}

KIND = {
    "deviation":     "change",
    "contradiction": "conflict",
    "gap":           "unspecified",
    "finding":       "finding",
    "decision":      "decision",
}

STATUS = {
    "open":     "Open",
    "proposed": "Proposed",
    "adopted":  "Adopted",
    "done":     "Done",
    "fixed":    "Fixed in the document",
    # An item raised, checked, and found not to hold. Kept rather than deleted:
    # a check that was run and failed to confirm is evidence too, and the route
    # from the wrong answer to the right one is usually where the fault was.
    "withdrawn": "Withdrawn",
}

GROUPS = [
    ("changes", "What changed about the approach",
     "Deviations from the plan the design document sets out, each with what it "
     "costs and why it was worth it.",
     lambda i: i["kind"] == "deviation"),
    ("blocking", "Blocking — fix before any content or core code",
     "Systems specified twice and incompatibly. Nothing downstream can be locked "
     "while two answers exist.",
     lambda i: i["severity"] == "blocking" and i["kind"] != "deviation"),
    ("design", "Design findings — these change how the game plays",
     "Not clerical. Each is arithmetic from the document's own published tables, "
     "and each asks a question about the design rather than the prose.",
     lambda i: i["severity"] == "design"),
    ("significant", "Significant — will cause balance or build errors",
     "Smaller conflicts, but each one produces a wrong number or a wrong asset "
     "count if it reaches implementation.",
     lambda i: i["severity"] == "significant" and i["kind"] != "deviation"),
    ("minor", "Minor — tidy before the spec is frozen",
     "Copy and consistency.",
     lambda i: i["severity"] == "minor" and i["kind"] != "deviation"),
    ("choices", "Decisions that are yours",
     "These cannot be resolved by reading the document more carefully — they "
     "change what the game is. Each says what it blocks, what the numbers are, "
     "and a leaning where there is one. Q8 is small and comes first: it swings "
     "Q1 by a factor of three.",
     lambda i: i["kind"] == "decision"),
]


def esc(text: str) -> str:
    return html.escape(text, quote=False)


def plain(text: str) -> str:
    """A title without its markup: two of them carry tags for the body copy."""
    import html as _html
    import re as _re
    return _html.unescape(_re.sub(r"<[^>]+>", "", text))


def _status_of(item: dict) -> str:
    """The register's own answer. This file had a second, v3.0-only copy of it,
    so the page's header and its "Where to start" section counted the same
    items two different ways — D35."""
    return reg_status(item)


def _open(by_id: dict, item_id: str) -> bool:
    item = by_id.get(item_id)
    return bool(item) and _status_of(item) not in SETTLED


def _unlocks(by_id: dict, item_id: str) -> set:
    """Everything still open that waits on this, directly or through others."""
    reverse: dict = {}
    for item, needs in DEPENDS.items():
        for need in needs:
            reverse.setdefault(need, []).append(item)
    seen, stack = set(), list(reverse.get(item_id, []))
    while stack:
        node = stack.pop()
        if node in seen:
            continue
        seen.add(node)
        stack.extend(reverse.get(node, []))
    return {n for n in seen if _open(by_id, n)}


#: What counts as finished, for the progress bars on the tabs.
#:
#: Two tones, the same distinction the roadmap's bars make: an item whose
#: resolution is *drafted* is not the same as one that is settled, and the
#: register spent most of this session proving that difference matters. So
#: "proposed" fills the paler half and never the darker one.
SETTLED = ("fixed", "done", "adopted", "withdrawn")
DRAFTED = ("proposed",)


def side_progress(side: str) -> dict:
    """How far along one side of the work is.

    An item that needs both sides counts on both, so each bar is the whole of
    that side rather than a share of it — the same rule the tab's own
    filter follows, so the bar and the list it opens count the same items.
    The three bars therefore add up to more than the register, which is
    the honest answer to "how much of the frontend is done".
    """
    items = [i for i in REGISTER
             if side == "all" or side_of(i["id"]) in (side, "both")]
    stat = [reg_status(i) for i in items]
    settled = sum(1 for x in stat if x in SETTLED)
    drafted = sum(1 for x in stat if x in DRAFTED)
    total = len(items) or 1
    return dict(total=len(items), settled=settled, drafted=drafted,
                open=len(items) - settled - drafted,
                settled_pct=100 * settled / total,
                drafted_pct=100 * (settled + drafted) / total)


def areas_of(item_id: str) -> list[str]:
    """Which design areas this item has ever gated, in any state.

    An item can gate more than one and be in a different state in each: C6
    still decides which ability text a character screen shows, and has stopped
    deciding anything a character artist draws.
    """
    return [area for area, spec in DESIGN_GATES.items()
            if any(item_id in spec.get(k, {})
                   for k in ("gates", "closed", "partly"))]


def area_gates(area: str) -> tuple[list[str], list[str]]:
    """One design area's gates: those cleared for it, then those still open.

    An item under `partly` counts as cleared *for this area* while staying
    open elsewhere. That is the honest arithmetic — the bar answers "can the
    drawing start", and an item that has stopped blocking the drawing has
    stopped blocking the drawing whatever else it still decides.
    """
    spec = DESIGN_GATES[area]
    return (list(spec.get("closed", {})) + list(spec.get("partly", {})),
            list(spec["gates"]))


def area_progress(area: str) -> dict:
    """How close one design area is to being able to start.

    A different question from `side_progress`, and the one actually asked:
    not how much of the register is done, but **how many of the things a
    character artist or a screen designer would otherwise have to guess are
    settled**. The denominator is this area's own gates and nothing else, so
    100% means the drawing can start rather than that the project is finished.
    """
    closed, open_ = area_gates(area)
    total = len(closed) + len(open_) or 1
    return dict(total=len(closed) + len(open_), settled=len(closed),
                drafted=0, open=len(open_),
                settled_pct=100 * len(closed) / total,
                drafted_pct=100 * len(closed) / total)


def tabs_html() -> str:
    """Two tabs and an everything tab, each with its own progress bar.

    The bar answers the question the tab raises: having split the register in
    two, how far along is each half? The darker fill is settled, the paler one
    adds what is drafted and waiting for sign-off.

    A tab picks a *side*, which is a different axis from the chips below it:
    choosing the frontend and then choosing one of its groups is the question
    a reader actually has, and a single control set would have made the two
    choices overwrite each other.
    """
    tabs = [("all", "Everything", "every item in the register"),
            ("backend", "Backend", "rules, numbers and the simulation"),
            ("frontend", "Frontend &amp; design", "anything a player sees"),
            ("area:realms", "Realms", DESIGN_GATES["realms"]["what"]),
            ("area:screens", "Screens", DESIGN_GATES["screens"]["what"]),
            ("area:characters", "Characters", DESIGN_GATES["characters"]["what"])]
    out = []
    for key, label, what in tabs:
        area = key.split(":")[1] if key.startswith("area:") else None
        p = area_progress(area) if area else side_progress(key)
        pressed = ' aria-pressed="true"' if key == "all" else ""
        cls = "tab area" if area else "tab"
        out.append(f"""
      <button class="{cls}" data-side="{key}" title="{esc(what)}"{pressed}>
        <span class="tab-head"><span class="tab-name">{label}</span>
          <span class="tab-n">{p['total']}</span></span>
        <span class="bar">
          <span class="fill drafted" style="width:{p['drafted_pct']:.1f}%"></span>
          <span class="fill settled" style="width:{p['settled_pct']:.1f}%"></span>
        </span>
        <span class="tab-foot">{
            f"{p['settled']} of {p['total']} gates cleared"
            if area else
            f"{p['settled']} settled &middot; {p['drafted']} drafted "
            f"&middot; {p['open']} open"}</span>
      </button>""")
    both = sum(1 for i in REGISTER if side_of(i["id"]) == "both")
    return (f'<nav class="tabs" aria-label="Backend or frontend">'
            f'{"".join(out)}</nav>\n'
            f'    <p class="tabs-note">The first three bars measure the '
            f'<em>audit</em>: an item is settled when the document answers it. '
            f'{both} items need both sides and count on both, so those two add '
            f'up to more than {len(REGISTER)}.<br><br>'
            f'<strong>The last three answer a different question &mdash; when '
            f'can the drawing start?</strong> Each counts only the items that '
            f'decide something its designer would otherwise have to guess, so '
            f'100% means that area can begin, not that the project is done. '
            f'Nothing has been drawn yet; these say what each area is waiting '
            f'on, and the panel above lists every gate by name.</p>')


def handoff(area: str) -> dict:
    """Whether this area can be handed to someone who will draw it, and if not,
    who is holding it.

    The gate panel answers "how far along is this", and that turned out to be
    the wrong question. The one actually asked is **when can I hand realms, or
    screens, or characters, to someone and have them start** - and a percentage
    cannot answer it, because an area at 6 of 7 with the last gate unanswerable
    is further from starting than an area at 3 of 5 whose two are a decision
    away.

    So the verdict is one of three, derived from the open gates and their
    owners rather than typed anywhere:

        ready   No open gates. The drawing can start.
        yours   Every open gate is a decision, or needs evidence from outside.
                Everything that could be measured has been and every edit is
                drafted; this is one conversation from starting.
        mine    At least one open gate still has analysis or drafting in it.
                Handing this over now would be handing over the questions too.

    `mine` wins over `yours` when both are present, because an area is held by
    the slowest thing in it.
    """
    open_ = list(DESIGN_GATES[area]["gates"])
    owners = [GATE_OWNER[g] for g in open_]
    if not open_:
        verdict = "ready"
    elif "mine" in owners:
        verdict = "mine"
    else:
        verdict = "yours"
    return dict(
        area=area, verdict=verdict, open=open_,
        mine=[g for g in open_ if GATE_OWNER[g] == "mine"],
        yours=[g for g in open_ if GATE_OWNER[g] == "yours"],
        outside=[g for g in open_ if GATE_OWNER[g] == "outside"],
    )


#: What each verdict says, in the words the question was asked in.
HANDOFF_WORDS = {
    "ready": ("Ready", "Hand it over. Nothing open decides anything a "
                       "designer would otherwise have to guess."),
    "yours": ("Waiting on you", "Everything that can be measured has been and "
                                "every edit is drafted. What is left is yours "
                                "to answer."),
    "mine":  ("Not yet", "Still has drafting in it. Handing it over now would "
                         "hand over the questions with it."),
}


def handoff_html() -> str:
    """The verdict band: three areas, three words, and what each is waiting on.

    Outside a <details>, and above everything else, because it is the question
    the register is read to answer and it was previously three clicks down
    inside a progress panel.
    """
    by_id = {i["id"]: i for i in REGISTER}
    cards = []
    for area in DESIGN_GATES:
        h = handoff(area)
        word, gloss = HANDOFF_WORDS[h["verdict"]]
        groups = []
        for key, label in (("mine", "still being worked"),
                           ("yours", "your decision"),
                           ("outside", "needs evidence from outside")):
            if h[key]:
                links = ", ".join(
                    f'<a href="#{g}">{g}</a>' for g in h[key])
                groups.append(f'<li><span class="who {key}">{label}</span> {links}'
                              f'<span class="gt">{esc(plain(by_id[h[key][0]]["title"]))}'
                              f'{"" if len(h[key]) == 1 else " &hellip;"}</span></li>')
        body = (f'<ul class="waiting">{"".join(groups)}</ul>' if groups
                else '<p class="waiting none">Nothing open.</p>')
        cards.append(
            f'<div class="ho {h["verdict"]}">'
            f'<h3>{esc(area.capitalize())}</h3>'
            f'<p class="verdict">{word}</p>'
            f'<p class="gloss">{gloss}</p>{body}</div>')
    return f"""
  <section class="handoff">
    <h2>Can the drawing start?</h2>
    <p class="blurb">One verdict per area, derived from the gates below and who
      has to move next on each &mdash; not typed anywhere, so it cannot say
      &ldquo;ready&rdquo; while something is still open. <strong>Ready means
      hand it over.</strong> Until then this says who is holding it: a decision
      only you can make, evidence nobody here can produce, or drafting that is
      still mine to do.</p>
    <div class="hos">{''.join(cards)}</div>
  </section>"""



# --------------------------------------------------------------------------
# What is blocked, and why — derived from the register, never typed
# --------------------------------------------------------------------------

#: The order the summary reads in: the most critical first. A deviation sits
#: in its own severity's tier here, since what it costs is what that says.
CRITICALITY = [
    ("blocking", "Blocking",
     "Specified twice and incompatibly: nothing downstream of it can be locked."),
    ("design", "Design findings",
     "Change how the game plays; each is arithmetic from the document's own tables."),
    ("significant", "Significant",
     "Each produces a wrong number, a wrong asset or a missing rule if it reaches "
     "the build."),
    ("minor", "Minor",
     "Copy, consistency and small readings; tidy before the specification is frozen."),
    ("choice", "Decisions", "What the game is; yours to make."),
]

#: Why an open item is still open, in the order one reason wins over another:
#: an item held by another is held whatever else it waits on, and evidence
#: nobody here can produce outranks a decision that would follow from it.
BLOCKERS = {
    "held":     ("Held by another item",
                 "Cannot move until what it waits on is settled."),
    "outside":  ("Needs outside evidence",
                 "A number from the world outside this repository."),
    "yours":    ("Your decision",
                 "The analysis is done; the answer changes what the game is."),
    "build":    ("Outside this repository",
                 "Devices, credentials, filing or the client's screens."),
    "document": ("Waiting for the document",
                 "Edits are drafted; the next version of the document closes it."),
    "mine":     ("Still being worked",
                 "A measurement or a fix still to make here."),
}


#: The grid's column heads, short enough for a phone; the legend spells them out.
SHORT = {"held": "Held", "outside": "Evidence", "yours": "Yours", "build": "Outside",
         "document": "Document", "mine": "Working"}


def chapters() -> dict[str, str]:
    """The document's chapters by number, read from the document itself."""
    import re
    out: dict[str, str] = {}
    for m in re.finditer(r"^(\d{1,2})([A-Z][^\n]{2,80})$",
                         DOC_TEXT.read_text(encoding="utf-8"), re.M):
        out.setdefault(m.group(1), m.group(2).strip())
    return out


def blocker(item: dict, by_id: dict) -> tuple[str, str]:
    """(why, what) for an open item: the one reason it is still open, and the
    register's own words for it.

    Read from what the register already records — what an item waits on
    (DEPENDS), the questions only the outside world answers (RESEARCH), the
    reason an item has no edit (check_edits.NO_EDIT_BECAUSE) and the edits
    drafted for it (EDITS) — so it cannot drift from the entries below. An
    item none of them explains fails the build rather than reading as
    blocked for no reason.
    """
    from check_edits import NO_EDIT_BECAUSE
    # Decided by the owner: no longer theirs, whatever it waited on. It waits
    # on the build change the answer needs, then on the document.
    a = ANSWERS.get(item["id"])
    if a:
        decided = f"decided, {a['option']}: {a['label']}"
        if a["build"] == "to do":
            return "mine", f"{decided}; the build change is still to make"
        if a["build"] == "outside":
            return "build", f"{decided}; the build change needs what this repository cannot reach"
        return "document", f"{decided}; the document takes it next"
    held = [d for d in DEPENDS.get(item["id"], []) if _open(by_id, d)]
    if held:
        return "held", "waits on " + ", ".join(held)
    if item["id"] in RESEARCH:
        return "outside", plain(RESEARCH[item["id"]])
    reason = NO_EDIT_BECAUSE.get(item["id"])
    if reason:
        head, _, tail = reason.partition(":")
        what = (tail or head).strip()
        if "decision" in head:
            return "yours", what
        if "limit" in head:
            return "build", what
        if "re-measurement" in head or "no document sentence" in head:
            return "mine", reason
        raise SystemExit(f"{item['id']}: no reading of why it is open: {reason!r}")
    if item["kind"] == "decision":
        return "yours", plain(item.get("rec", ""))
    edits = EDITS.get(item["id"], [])
    if edits:
        where = ", ".join(dict.fromkeys(f"\u00a7{e['section']}" for e in edits))
        return "document", (f"{len(edits)} edit{'s' if len(edits) != 1 else ''} drafted "
                            f"for {where}; it closes when the document takes them")
    raise SystemExit(f"{item['id']}: open, and nothing in the register says why")


def blocked() -> list[dict]:
    """Every open item with its criticality, topic and blocker."""
    by_id = {i["id"]: i for i in REGISTER}
    names = chapters()
    out = []
    for item in REGISTER:
        if not _open(by_id, item["id"]):
            continue
        top = item["refs"][0].split(".")[0] if item.get("refs") else ""
        why, what = blocker(item, by_id)
        out.append(dict(item=item, tier=item["severity"], why=why, what=what,
                        chapter=top, topic=names.get(top, "Across the document")))
    return out


def blocked_html() -> str:
    """The page's first answer: what is blocked, how badly, and why.

    Criticality first, then the design chapter each item sits in — the
    topic — then the one reason it is still open. A grid on top counts the
    same rows both ways, so "how much of the significant work is waiting on
    me" is one glance, not a filter.
    """
    rows = blocked()
    tiers = [t for t in CRITICALITY if any(r["tier"] == t[0] for r in rows)]
    whys = [w for w in BLOCKERS if any(r["why"] == w for r in rows)]
    count = lambda **k: sum(1 for r in rows if all(r[a] == b for a, b in k.items()))

    head = "".join(f'<th scope="col"><span class="bk {w}" title="{BLOCKERS[w][0]}">{SHORT[w]}</span></th>'
                   for w in whys)
    grid = "".join(
        f'<tr><th scope="row"><a href="#blk-{t}">{label}</a></th>'
        + "".join(f'<td>{count(tier=t, why=w) or ""}</td>' for w in whys)
        + f'<td class="tot">{count(tier=t)}</td></tr>'
        for t, label, _ in tiers)
    foot = ("<tr><th scope=\"row\">All</th>"
            + "".join(f'<td class="tot">{count(why=w)}</td>' for w in whys)
            + f'<td class="tot">{len(rows)}</td></tr>')

    legend = "".join(
        f'<li><span class="bk {w}">{SHORT[w]}</span> <strong>{BLOCKERS[w][0]}.</strong> '
        f'{BLOCKERS[w][1]}</li>'
        for w in whys)

    tiers_html = []
    for t, label, gloss in tiers:
        mine = [r for r in rows if r["tier"] == t]
        topics: dict[str, list[dict]] = {}
        for r in mine:
            topics.setdefault(r["chapter"], []).append(r)
        order = sorted(topics, key=lambda c: (-len(topics[c]), int(c) if c.isdigit() else 99))
        blocks = []
        for c in order:
            rs = topics[c]
            why_n = {}
            for r in rs:
                why_n[r["why"]] = why_n.get(r["why"], 0) + 1
            tally = " &middot; ".join(f"{n} {BLOCKERS[w][0].lower()}"
                                      for w, n in sorted(why_n.items(), key=lambda kv: -kv[1]))
            items = "".join(
                f'<li><a href="#{r["item"]["id"]}">{r["item"]["id"]}</a> '
                f'<span class="bt">{esc(plain(r["item"]["title"]))}</span>'
                f'<span class="bw"><span class="bk {r["why"]}">{BLOCKERS[r["why"]][0]}</span> '
                f'{esc(r["what"])}</span></li>'
                for r in rs)
            section = f"&sect;{c} " if c.isdigit() else ""
            blocks.append(
                f'<details class="topic"{" open" if t in ("blocking", "design") else ""}>'
                f'<summary><span class="tn">{section}{esc(rs[0]["topic"])}</span>'
                f'<span class="tc">{len(rs)}</span><span class="tw">{tally}</span></summary>'
                f'<ul class="bl">{items}</ul></details>')
        tiers_html.append(
            f'<div class="tier {t}" id="blk-{t}"><h3>{label}'
            f'<span class="tier-n">{len(mine)}</span></h3>'
            f'<p class="tier-gloss">{esc(gloss)}</p>{"".join(blocks)}</div>')

    yours = count(why="yours")
    return f"""
  <section class="blocked" aria-labelledby="blocked-h">
    <h2 id="blocked-h">What is blocked, and why</h2>
    <p class="blurb"><strong>{len(rows)} items are open.</strong> Each is counted
      once, by how critical it is and by the one thing holding it &mdash;
      <strong>{yours} wait on a decision of yours</strong>. Read from the
      register itself (what each item waits on, the reason it has no edit, the
      edits drafted for it), so this cannot say something is moving that is
      not. The topic is the design chapter the item is filed under.</p>
    <div class="bgrid-wrap"><table class="bgrid">
      <thead><tr><th scope="col">Criticality</th>{head}<th scope="col">Open</th></tr></thead>
      <tbody>{grid}</tbody><tfoot>{foot}</tfoot>
    </table></div>
    <ul class="blegend">{legend}</ul>
    {"".join(tiers_html)}
  </section>"""


# --------------------------------------------------------------------------
# What is built — derived from sim/status.json, never typed
# --------------------------------------------------------------------------

SIM = pathlib.Path(__file__).resolve().parent.parent / "sim"


def built_systems() -> tuple[list[dict], dict]:
    """Each system in sim/systems.json with a verdict read from sim/status.json.

    A system is **built** only if every test that proves it passed on the last
    run of ``sim/status.py``. A test that has been renamed or deleted is
    **missing**, never built: a system whose proof has lost its subject must
    not read as proven, which is the fault this repository keeps finding in
    the document and is not going to commit in its own progress report.
    """
    import json
    manifest = json.loads((SIM / "systems.json").read_text(encoding="utf-8"))
    status = json.loads((SIM / "status.json").read_text(encoding="utf-8"))
    results = status.get("tests", {})
    rows = []
    for system in manifest["systems"]:
        got = [results.get(t) for t in system["tests"]]
        if any(g is None for g in got):
            verdict = "missing"
        elif all(g == "passed" for g in got):
            verdict = "built"
        else:
            verdict = "failing"
        rows.append(dict(system, verdict=verdict,
                         passed=sum(1 for g in got if g == "passed")))
    return rows, dict(status, targets_manifest=manifest["targets"])


BUILT_WORDS = {
    "built": "Built",
    "failing": "Failing",
    "missing": "Proof missing",
}


def built_html() -> str:
    try:
        rows, status = built_systems()
    except FileNotFoundError:
        return ""
    cross = status.get("cross_target", [])
    agree = cross and all(r["agree"] for r in cross)
    goldens = status.get("goldens", [])
    tests = status.get("tests", {})
    passed = sum(1 for v in tests.values() if v == "passed")
    largest = max((g["bytes"] for g in goldens), default=0)

    sys_rows = "".join(
        f'<li class="bs {r["verdict"]}"><span class="bv">{BUILT_WORDS[r["verdict"]]}</span> '
        f'<strong>{esc(r["name"])}</strong> '
        f'<span class="bref">\u00a7{esc(r["section"])} \u00b7 {esc(r["task"])} '
        f'\u00b7 {r["passed"]}/{len(r["tests"])} tests</span>'
        f'<span class="bwhat">{esc(r["what"])}</span></li>'
        for r in rows)

    def target_row(t: dict) -> str:
        if t["how"].startswith("needs"):
            return (f'<li class="bt waiting"><span class="bv">Needs a device</span> '
                    f'{esc(t["name"])}</li>')
        return (f'<li class="bt {"built" if agree else "failing"}"><span class="bv">'
                f'{"Agrees" if agree else "Diverges"}</span> {esc(t["name"])} '
                f'<span class="bref">{esc(t["how"])}</span></li>')
    target_rows = "".join(target_row(t) for t in status["targets_manifest"])

    content = status.get("content")
    if content is None:
        content_html = ""
    else:
        bad = content["disagree"]
        lines = "".join(f'<li class="bs failing"><span class="bv">Disagrees</span> {esc(w)}</li>'
                        for w in bad)
        lines += "".join(f'<li class="bs waiting"><span class="bv">Not modelled</span> {esc(n)}</li>'
                         for n in content["not_modelled"])
        lines += "".join(f'<li class="bs waiting"><span class="bv">Not in the document</span> {esc(n)}</li>'
                         for n in content.get("readings", []))
        content_html = f"""
    <h3 class="bh">The simulation against <code>content/</code></h3>
    <p class="blurb">{content["agree"]} values the simulation carries as constants
      agree with <code>detection.json</code>, <code>roles.json</code> and, for the
      numbers with no content file, <code>tools/design_facts.py</code>{f", <strong>{len(bad)} disagree</strong>" if bad else ""}.
      Every other number in those files is named below as not modelled yet, and
      the gate fails on any it neither compares nor names &mdash; so none passes
      as agreeing by being absent. Last come the numbers the simulation needs
      that the document does not give.</p>
    <ul class="blist">{lines}</ul>"""

    built = sum(1 for r in rows if r["verdict"] == "built")
    return f"""
  <section class="built">
    <h2>What is built</h2>
    <p class="blurb">The simulation core in <code>sim/</code>, read from the last
      run of its own gate rather than from anything typed here. A system reads
      <strong>built</strong> only if every test that proves it passed; a test
      that is renamed or deleted makes its system read <em>proof missing</em>,
      never built.</p>
    <div class="bsum">
      <div><span class="n">{built}/{len(rows)}</span><span class="k">systems built</span></div>
      <div><span class="n">{passed}/{len(tests)}</span><span class="k">tests passing</span></div>
      <div><span class="n">{sum(1 for g in goldens if g["verifies"])}/{len(goldens)}</span><span class="k">golden replays verify</span></div>
      <div><span class="n">{largest}</span><span class="k">bytes, largest heist of 2,048</span></div>
    </div>
    <h3 class="bh">Systems</h3>
    <ul class="blist">{sys_rows}</ul>
    <h3 class="bh">The same checksum on every target (T3.1)</h3>
    <p class="blurb">{len(cross)} seeds, {status.get("ticks", 0):,} ticks each.
      \u00a724.7 names four targets; two can be run here.</p>
    <ul class="blist">{target_rows}</ul>{content_html}
  </section>
"""

def design_gates_html() -> str:
    """When the design of realms, screens and characters can start.

    The backend and frontend tabs say where an item's work happens. This says what
    the design work is waiting on, which is the question the split was asked
    for, and it is a different question: almost everything that gates a
    designer is a backend item.

    Written from the register's own statuses rather than from memory. The first
    draft of this listed eight gates that v3.0 and v3.1 had already closed —
    C5, Q8, C11, C9, C1, C26, G12, C10 — which would have told a designer to
    wait for finished work. `check_edits.bad_sides()` now refuses a gate whose
    item is not open.
    """
    by_id = {i["id"]: i for i in REGISTER}
    out = []
    for area, spec in DESIGN_GATES.items():
        gates = spec["gates"]
        cls = "" if gates else " none"
        rows = "".join(
            f'<li><a href="#{gid}">{gid}</a> {why} '
            f'<span style="opacity:.65">&mdash; {esc(by_id[gid]["title"])}</span></li>'
            for gid, why in gates.items())
        # What this area no longer waits on, so the panel says how far it has
        # come rather than only what is left. Nine of these were cleared by
        # v3.0 and v3.1 and the page never said so.
        done = {**spec.get("closed", {}), **spec.get("partly", {})}
        cleared = "".join(
            f'<li><a href="#{gid}">{gid}</a> {why}</li>'
            for gid, why in done.items())
        settled = (f'<details class="cleared"><summary>{len(done)} already '
                   f'settled</summary><ul>{cleared}</ul></details>'
                   if done else "")
        body = (f"<ul>{rows}</ul>" if gates else
                '<p class="clear">Nothing open. This can start now.</p>')
        out.append(
            f'<div class="gate-area"><h3>{esc(area.capitalize())}'
            f'<span class="gate-count{cls}">{len(gates)} open</span></h3>'
            f'<p class="what">{spec["what"]}</p>{body}{settled}</div>')
    return f"""
    <details><summary>When the design of realms, screens and characters can
      start</summary>
      <p class="blurb">Each area lists the items still open that decide
        something a designer would otherwise have to guess, and what each one
        changes about the drawing, then what it has already settled. Almost all
        of them are backend items: the split says where work happens, this says
        what it holds up. An item can be settled for one area and open for
        another &mdash; C6 stopped deciding anything a character artist draws
        when v3.1 reconciled the two rosters&rsquo; roles, and still decides
        which ability text a screen shows.</p>
      <div class="gates">{''.join(out)}</div>
    </details>"""


def start_here_html() -> str:
    """Where to begin, computed from the dependency graph rather than asserted.

    The register says what is wrong a hundred times over and, without this,
    nothing about the order. Most items cannot be started until something else
    is settled, and which ones is not apparent from reading them.
    """
    by_id = {i["id"]: i for i in REGISTER}
    opens = [i for i in REGISTER if _open(by_id, i["id"])]
    ready = [i for i in opens
             if not [d for d in DEPENDS.get(i["id"], []) if _open(by_id, d)]]
    decisions = [i for i in opens if i["kind"] == "decision"]

    def row(item):
        n = len(_unlocks(by_id, item["id"]))
        unl = f' <span class="unlocks">unlocks {n}</span>' if n else ""
        return (f'<li><a href="#{item["id"]}">{item["id"]}</a> '
                f'{esc(plain(item["title"]))}{unl}</li>')

    dec = "".join(
        f'<li><a href="#{d["id"]}">{d["id"]}</a> {esc(plain(d["title"]))}'
        + (f' <span class="unlocks">unlocks {len(_unlocks(by_id, d["id"]))}</span>'
           if _unlocks(by_id, d["id"]) else "")
        + (f' <span class="held">held by '
           + ", ".join(f'<a href="#{b}">{b}</a>'
                       for b in DEPENDS.get(d["id"], []) if _open(by_id, b))
           + "</span>"
           if [b for b in DEPENDS.get(d["id"], []) if _open(by_id, b)] else "")
        + "</li>"
        for d in sorted(decisions, key=lambda i: -len(_unlocks(by_id, i["id"]))))

    blocking_first = sorted(
        ready, key=lambda i: ({"blocking": 0, "design": 1, "significant": 2,
                               "change": 3, "minor": 4, "choice": 5}[i["severity"]],
                              -len(_unlocks(by_id, i["id"])), i["id"]))

    research = "".join(
        f'<li><a href="#{k}">{k}</a> {esc(plain(by_id[k]["title"]))}'
        f'<span class="q">{RESEARCH[k]}</span></li>'
        for k in sorted(RESEARCH) if k in by_id)

    return f"""
  <section class="start">
    <h2>Where to start</h2>
    <p class="blurb">Computed from the dependency graph, not asserted: an item is
      ready when nothing it waits on is still open. Every item below also carries
      its own dependencies, both directions, in its entry.
      <strong>{len(opens)} items are open, {len(ready)} of them can be worked
      now.</strong> &ldquo;Open&rdquo; includes items whose resolution is drafted
      and waiting for sign-off.</p>

    <details open><summary>The decisions, and what each unlocks</summary>
      <p class="blurb">These cannot be settled by reading the document more
        carefully. The number is how much of the register waits on each, through
        the whole chain rather than directly.</p>
      <ol class="startlist">{dec}</ol>
    </details>

    <details><summary>Ready to work now &mdash; {len(ready)} items</summary>
      <ol class="startlist">{"".join(row(i) for i in blocking_first)}</ol>
    </details>

    <details><summary>The four chains that carry most of the graph</summary>
      <div class="chains">
        <p><strong>The generator.</strong> <a href="#C5">C5</a> and
          <a href="#Q8">Q8</a> settle how many guard posts a realm has &rarr;
          <a href="#F22">F22</a> &rarr; <a href="#F11">F11</a> &rarr;
          <a href="#F9">F9</a> and <a href="#F13">F13</a>. Nothing downstream is
          fixable by improving the generator alone.</p>
        <p><strong>The raid payout.</strong> <a href="#C4">C4</a> says what
          &sect;9.6&rsquo;s level term is &rarr; <a href="#C2">C2</a> picks one
          model &rarr; <a href="#F14">F14</a> re-derives the 0.46 the progression
          curve rests on &rarr; <a href="#F19">F19</a> turns it into a band.</p>
        <p><strong>Law rarity.</strong> <a href="#C8">C8</a> settles the Library,
          which now decides the page economy &rarr; <a href="#Q3">Q3</a> &rarr;
          <a href="#C3">C3</a> &rarr; <a href="#C23">C23</a>.</p>
        <p><strong>Scope.</strong> <a href="#F10">F10</a> classifies the 48 laws
          by what each needs from the engine &rarr; <a href="#D6">D6</a> &rarr;
          <a href="#Q5">Q5</a> &rarr; <a href="#G11">G11</a>.</p>
      </div>
    </details>

    <details><summary>What cannot be settled from inside this repository
      &mdash; {len(RESEARCH)} questions</summary>
      <p class="blurb">Everything else here is arithmetic against the design
        document or a measurement the simulation harness can make. These are not:
        each needs a number from the outside world. Each is written to stand
        alone.</p>
      <ol class="startlist research">{research}</ol>
    </details>
{design_gates_html()}
  </section>
"""


def deps_html(item: dict) -> str:
    """What this item waits on, and what waits on it.

    Both directions come from one table: `DEPENDS` records only "x needs y", and
    the reverse is computed, so the two can never disagree.
    """
    needs = DEPENDS.get(item["id"], [])
    blocks = sorted(k for k, v in DEPENDS.items() if item["id"] in v)
    if not needs and not blocks:
        return ""
    parts = []
    if needs:
        parts.append("waits on " + ", ".join(
            '<a href="#' + n + '">' + n + '</a>' for n in needs))
    if blocks:
        parts.append("unblocks " + ", ".join(
            '<a href="#' + b + '">' + b + '</a>' for b in blocks))
    return '<p class="deps">' + " &middot; ".join(parts) + '</p>'


def measured_html(item: dict) -> str:
    """A badge saying this item's numbers were re-run against the live harness.

    Absence is the honest default: it means nobody has checked, not that the
    numbers are wrong. `tools/check_findings_fresh.py` keeps the list.
    """
    if not item.get("measured"):
        return ""
    return ('<span class="measured" title="re-run against harness '
            + item["measured"][:16] + '">re-measured</span>')


def refs_html(refs: list[str]) -> str:
    return "".join(f'<span class="ref">§{esc(r)}</span>' for r in refs)


ACTION_LABEL = {
    "replace": "Replace", "delete": "Delete", "insert": "Add",
    "regenerate": "Regenerate", "retag": "Re-tag",
}


def edits_html(item_id: str) -> str:
    """The work order: what to type, and where."""
    edits = EDITS.get(item_id)
    if not edits:
        return ""
    rows = []
    for edit in edits:
        action = edit["action"]
        head = (f'<span class="e-act a-{action}">{ACTION_LABEL[action]}</span>'
                f'<span class="e-sec">&sect;{esc(edit["section"])}</span>')
        if edit.get("target"):
            head += f'<span class="e-tgt">{esc(edit["target"])}</span>'
        parts = [f'<header class="e-head">{head}</header>']
        if edit.get("find"):
            parts.append(f'<p class="e-find"><span class="e-lab">now</span>'
                         f'<code>{esc(edit["find"])}</code></p>')
        if edit.get("from_"):
            parts.append(f'<p class="e-find"><span class="e-lab">paste from</span>'
                         f'<code>docs/design/generated/{esc(edit["from_"])}</code></p>')
        if edit.get("replace"):
            label = "becomes" if edit["action"] == "replace" else (
                "re-tag to" if edit["action"] == "retag" else "add")
            parts.append(f'<p class="e-new"><span class="e-lab">{label}</span>'
                         f'<code>{esc(edit["replace"])}</code></p>')
        if edit.get("why"):
            parts.append(f'<p class="e-why">{edit["why"]}</p>')
        rows.append(f'<li class="edit">{"".join(parts)}</li>')
    n = len(edits)
    return (f'<details class="edits"><summary>{n} edit{"s" if n > 1 else ""} '
            f'to the document</summary><ol class="edit-list">'
            f'{"".join(rows)}</ol></details>')


#: What each side is called on the page. "Frontend" carries "and design"
#: because that is what the split is for: screens, art and the layout of a
#: realm are one side of the work, and the rules are the other.
SIDE_LABEL = {
    "backend": "backend",
    "frontend": "frontend &amp; design",
    "both": "both",
}


def decided_html(item_id: str) -> str:
    """The owner's answer to a decision, and the document edit it asks for."""
    a = ANSWERS.get(item_id)
    if not a:
        return ""
    build = {"none": "the build already does this", "to do": "the build change is still to make",
             "done": "built", "outside": "the build change needs what this repository cannot reach"}
    edit = f' Document: {esc(a["doc_edit"])}' if a.get("doc_edit") else ""
    if a.get("client"):
        edit = f' Client: {esc(a["client"])}.' + edit
    return (f'<p class="rec decided"><span class="arrow">&#10003;</span> <strong>Decided '
            f'{esc(a["option"])}:</strong> {esc(a["label"])} ({build[a["build"]]}).{edit}</p>')


def item_html(item: dict) -> str:
    label, cls = SEVERITY[item["severity"]]
    v3 = V3.get(item["id"], {})
    state = reg_status(item)
    rec = item.get("rec")
    v3_html = (f'<p class="v3"><span class="vlabel">v3.0</span> {v3["note"]}</p>'
               if v3.get("note") else "")
    # v3.1 is a second layer, not a replacement: what v3.0 did about an item is
    # part of the item's history and stays on the page beneath it.
    v31 = V31.get(item["id"], {})
    v31_html = (f'<p class="v3 v31"><span class="vlabel">v3.1</span> {v31["note"]}</p>'
                if v31.get("note") else "")
    # and v3.2 a third, for the same reason.
    v32 = V32.get(item["id"], {})
    v31_html += (f'<p class="v3 v32"><span class="vlabel">v3.2</span> {v32["note"]}</p>'
                 if v32.get("note") else "")
    # and v3.3 a fourth.
    v33 = V33.get(item["id"], {})
    v31_html += (f'<p class="v3 v33"><span class="vlabel">v3.3</span> {v33["note"]}</p>'
                 if v33.get("note") else "")
    # and v3.4 a fifth.
    v34 = V34.get(item["id"], {})
    v31_html += (f'<p class="v3 v34"><span class="vlabel">v3.4</span> {v34["note"]}</p>'
                 if v34.get("note") else "")
    return f"""
      <article class="item {cls}" id="{item['id']}" data-group="{item['_group']}"
               data-kind="{item['kind']}" data-status="{state}"
               data-side="{side_of(item['id'])}"
               data-areas="{' '.join(areas_of(item['id']))}"
               data-edits="{'yes' if item['id'] in EDITS else 'no'}">
        <header class="item-head">
          <span class="id">{esc(item['id'])}</span>
          <h3>{esc(item['title'])}</h3>
          <span class="kind">{KIND[item['kind']]}</span>
          <span class="status s-{state}">{STATUS[state]}</span>
          <span class="side side-{side_of(item['id'])}">{SIDE_LABEL[side_of(item['id'])]}</span>
          {measured_html(item)}
        </header>
        <div class="refs">{refs_html(item['refs'])}</div>
        {deps_html(item)}
        <p class="body">{item['body']}</p>
        {f'<p class="rec"><span class="arrow">&rarr;</span> {rec}</p>' if rec else ''}
        {decided_html(item['id'])}
        {v3_html}
        {v31_html}
        {edits_html(item['id'])}
      </article>"""


def build() -> str:
    for group_id, _, _, pred in GROUPS:
        for item in REGISTER:
            if pred(item) and "_group" not in item:
                item["_group"] = group_id
    stray = [i["id"] for i in REGISTER if "_group" not in i]
    if stray:
        raise SystemExit(f"items in no group: {stray}")

    counts = {g: sum(1 for i in REGISTER if i["_group"] == g) for g, *_ in GROUPS}
    def status_of(item: dict) -> str:
        return reg_status(item)

    open_count = sum(1 for i in REGISTER if status_of(i) == "open")
    done_count = sum(1 for i in REGISTER if status_of(i) in ("done", "adopted"))
    fixed_count = sum(1 for i in REGISTER if status_of(i) == "fixed")
    touched = sum(1 for i in REGISTER if i["id"] in V3)
    answered = [k for k in V34 if status_before_v34(k) not in SETTLED]
    v34_closed = sum(1 for k in answered if V34[k]["status"] != "open")
    v34_open = ", ".join(sorted(k for k in answered if V34[k]["status"] == "open"))
    new_in_v3 = sum(1 for i in REGISTER if i["id"] in FOUND_IN_V3)
    today = datetime.date.today().strftime("%d %B %Y")

    chips = "".join(
        f'<button class="chip" data-filter="group:{g}">{esc(title.split(" — ")[0])}'
        f'<span class="n">{counts[g]}</span></button>'
        for g, title, _, _ in GROUPS
    )
    gap_count = sum(1 for i in REGISTER if i["kind"] == "gap")
    chips += (f'<button class="chip alt" data-filter="kind:gap">Specified nowhere'
              f'<span class="n">{gap_count}</span></button>')
    chips += (f'<button class="chip alt" data-filter="status:fixed">Fixed in the document'
              f'<span class="n">{fixed_count}</span></button>')
    edit_items = sum(1 for i in REGISTER if i["id"] in EDITS)
    edit_count = sum(len(v) for v in EDITS.values())
    chips += (f'<button class="chip alt" data-filter="edits:yes">Has edits to make'
              f'<span class="n">{edit_items}</span></button>')

    sections = []
    for group_id, title, blurb, _ in GROUPS:
        items = [i for i in REGISTER if i["_group"] == group_id]
        if not items:
            continue
        sections.append(f"""
      <section class="group" id="g-{group_id}" data-group="{group_id}">
        <div class="group-head">
          <h2>{esc(title)}</h2>
          <p class="blurb">{esc(blurb)}</p>
        </div>
        {''.join(item_html(i) for i in items)}
      </section>""")

    return f"""<title>Ruleborn Audit Register</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Marcellus&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap">

<style>
  /* Light palette on bare :root; dark redefines only the tokens. The hues are
     the design document's own (§21.2), shifted in luminance so they hold their
     contrast on paper as well as on the violet ground. */
  :root {{
    --ground: #FCFBFF;
    --raised: #FFFFFF;
    --ink: #221C3A;
    --muted: #6E6685;
    --faint: #958CAD;
    --rule: #E6E2EE;
    --rule-strong: #D3CCE3;

    --blk: #C0304A;
    --dsg: #7A46C8;
    --sig: #A77410;
    --min: #6E6685;
    --chg: #1F6F83;
    --cho: #2E7D5B;

    --accent: #7A46C8;
    color-scheme: light;
  }}
  @media (prefers-color-scheme: dark) {{
    :root:not([data-theme="light"]) {{
      --ground: #17122C;
      --raised: #1E1839;
      --ink: #EDE9F8;
      --muted: #A79FC4;
      --faint: #7E76A0;
      --rule: #2E2650;
      --rule-strong: #3D3466;

      --blk: #E2536B;
      --dsg: #B18CF5;
      --sig: #F2B43C;
      --min: #A79FC4;
      --chg: #3CC6D8;
      --cho: #5CC46A;

      --accent: #B18CF5;
      color-scheme: dark;
    }}
  }}
  :root[data-theme="dark"] {{
    --ground: #17122C;
    --raised: #1E1839;
    --ink: #EDE9F8;
    --muted: #A79FC4;
    --faint: #7E76A0;
    --rule: #2E2650;
    --rule-strong: #3D3466;
    --blk: #E2536B;
    --dsg: #B18CF5;
    --sig: #F2B43C;
    --min: #A79FC4;
    --chg: #3CC6D8;
    --cho: #5CC46A;
    --accent: #B18CF5;
    color-scheme: dark;
  }}

  [hidden] {{ display: none !important; }}

  body {{
    margin: 0;
    background: var(--ground);
    color: var(--ink);
    font-family: "IBM Plex Sans", system-ui, -apple-system, sans-serif;
    font-size: 15.5px;
    line-height: 1.6;
    -webkit-font-smoothing: antialiased;
  }}

  .wrap {{
    max-width: 780px;
    margin: 0 auto;
    padding-inline: 20px;
    padding-block: 40px 72px;
  }}

  h1, h2 {{ font-family: Marcellus, Georgia, serif; font-weight: 400; text-wrap: balance; }}
  h1 {{ font-size: clamp(30px, 7vw, 42px); line-height: 1.1; margin: 0 0 6px; letter-spacing: 0.01em; }}
  h2 {{ font-size: 23px; margin: 0; }}
  h3 {{ font-family: "IBM Plex Sans", sans-serif; font-size: 16.5px; font-weight: 600;
       margin: 0; line-height: 1.35; text-wrap: balance; }}
  p {{ margin: 0; }}

  .eyebrow {{
    font-family: "IBM Plex Mono", monospace;
    text-transform: uppercase; letter-spacing: 0.16em;
    font-size: 11px; color: var(--accent); margin: 0 0 10px;
  }}
  .lede {{ color: var(--muted); font-size: 17px; max-width: 62ch; margin-top: 14px; }}

  /* --- summary ------------------------------------------------------- */
  .summary {{
    display: flex; flex-wrap: wrap; gap: 0;
    margin: 30px 0 0; border-top: 1px solid var(--rule);
    border-bottom: 1px solid var(--rule); padding-block: 14px;
  }}
  .summary div {{ flex: 1 1 108px; padding-right: 14px; }}
  .summary .n {{
    font-family: "IBM Plex Mono", monospace; font-size: 23px; font-weight: 500;
    font-variant-numeric: tabular-nums; display: block; line-height: 1.2;
  }}
  .summary .k {{ font-size: 12.5px; color: var(--muted); }}

  /* --- filter -------------------------------------------------------- */
  .filters {{
    position: sticky; top: env(safe-area-inset-top, 0px);
    background: var(--ground); z-index: 5;
    display: flex; flex-wrap: wrap; gap: 7px;
    padding-block: 14px; margin-bottom: 8px;
    border-bottom: 1px solid var(--rule);
  }}
  .chip {{
    font-family: inherit; font-size: 13px; font-weight: 500;
    color: var(--muted); background: transparent;
    border: 1px solid var(--rule-strong); border-radius: 999px;
    padding: 6px 12px; cursor: pointer; min-height: 34px;
    display: inline-flex; align-items: center; gap: 7px;
  }}
  .chip:hover {{ color: var(--ink); border-color: var(--faint); }}
  /* A chip the chosen side has nothing under: shown, so the reader can
     see it is empty rather than wonder where it went. */
  .chip:disabled {{ opacity: 0.38; cursor: default; }}
  .chip:disabled:hover {{ color: var(--muted); border-color: var(--rule-strong); }}
  .chip:focus-visible {{ outline: 2px solid var(--accent); outline-offset: 2px; }}
  .chip[aria-pressed="true"] {{
    color: var(--ground); background: var(--ink); border-color: var(--ink);
  }}
  .chip .n {{
    font-family: "IBM Plex Mono", monospace; font-size: 11.5px;
    font-variant-numeric: tabular-nums; opacity: 0.65;
  }}

  /* --- can the drawing start? ------------------------------------------- */
  .handoff {{
    margin: 28px 0 8px; padding: 18px 20px;
    border: 1px solid var(--rule-strong); border-radius: 10px;
    background: var(--raised);
  }}
  .handoff h2 {{ font-size: 21px; margin: 0 0 6px; }}
  .handoff .blurb {{
    color: var(--muted); font-size: 14px; max-width: 62ch; margin: 0 0 14px;
  }}
  .hos {{ display: grid; gap: 12px; grid-template-columns: repeat(3, 1fr); }}
  @media (max-width: 760px) {{ .hos {{ grid-template-columns: 1fr; }} }}
  .ho {{
    border: 1px solid var(--rule); border-radius: 9px; padding: 14px 15px;
    border-left: 4px solid var(--rule-strong); background: var(--ground);
  }}
  .ho h3 {{
    font-family: "IBM Plex Mono", monospace; font-size: 11.5px;
    letter-spacing: 0.08em; text-transform: uppercase; color: var(--muted);
    margin: 0 0 6px; font-weight: 600;
  }}
  .ho .verdict {{ font-size: 20px; font-weight: 650; margin: 0; line-height: 1.2; }}
  .ho .gloss {{
    color: var(--muted); font-size: 13px; margin: 6px 0 10px; line-height: 1.45;
  }}
  .ho.ready {{ border-left-color: var(--cho); }}
  .ho.ready .verdict {{ color: var(--cho); }}
  .ho.yours {{ border-left-color: var(--sig); }}
  .ho.yours .verdict {{ color: var(--sig); }}
  .ho.mine {{ border-left-color: var(--min); }}
  .ho.mine .verdict {{ color: var(--ink); }}
  .waiting {{ margin: 0; padding: 0; list-style: none; }}
  .waiting li {{
    border-top: 1px solid var(--rule); padding: 8px 0 0; margin-top: 8px;
    font-size: 13.5px;
  }}
  .waiting li:first-child {{ border-top: 0; margin-top: 0; }}
  .waiting .who {{
    display: block; font-family: "IBM Plex Mono", monospace; font-size: 10.5px;
    letter-spacing: 0.07em; text-transform: uppercase; margin-bottom: 3px;
  }}
  .waiting .who.mine {{ color: var(--min); }}
  .waiting .who.yours {{ color: var(--sig); }}
  .waiting .who.outside {{ color: var(--chg); }}
  .waiting .gt {{
    display: block; color: var(--muted); font-size: 12.5px; margin-top: 2px;
    line-height: 1.4;
  }}
  .waiting.none {{ color: var(--cho); font-size: 13.5px; margin: 0; }}

  /* --- what is blocked, and why -------------------------------------- */
  .blocked {{
    margin: 28px 0 8px; padding: 18px 20px;
    border: 1px solid var(--rule-strong); border-radius: 10px;
    background: var(--raised);
  }}
  .blocked h2 {{ font-size: 21px; margin: 0 0 6px; }}
  .blocked .blurb {{ color: var(--muted); font-size: 14px; max-width: 62ch; margin: 0 0 14px; }}
  .bgrid-wrap {{ overflow-x: auto; margin: 0 -4px; }}
  .bgrid {{ border-collapse: collapse; width: 100%; font-size: 13px; }}
  .bgrid th, .bgrid td {{ padding: 6px 8px; border-bottom: 1px solid var(--rule); text-align: right; }}
  .bgrid thead th {{ vertical-align: bottom; font-weight: 500; }}
  .bgrid th[scope="row"], .bgrid thead th:first-child {{ text-align: left; font-weight: 600; }}
  .bgrid th[scope="row"] a {{ color: var(--ink); text-decoration: none; }}
  .bgrid td {{ font-family: "IBM Plex Mono", monospace; font-variant-numeric: tabular-nums; }}
  .bgrid .tot {{ font-weight: 600; }}
  @media (max-width: 480px) {{
    .bgrid {{ font-size: 12px; }}
    .bgrid th, .bgrid td {{ padding: 5px 3px; }}
    .bgrid .bk {{ padding: 1px 3px; letter-spacing: 0; font-size: 9.5px; }}
    .blocked {{ padding: 16px 14px; }}
  }}
  .bgrid tfoot th, .bgrid tfoot td {{ border-bottom: 0; border-top: 1px solid var(--rule-strong); }}
  .bk {{
    display: inline-block; font-family: "IBM Plex Mono", monospace; font-size: 10.5px;
    letter-spacing: 0.05em; text-transform: uppercase; white-space: nowrap;
    padding: 1px 6px; border-radius: 4px; border: 1px solid currentColor;
  }}
  .bk.held {{ color: var(--blk); }}
  .bk.outside {{ color: var(--chg); }}
  .bk.yours {{ color: var(--sig); }}
  .bk.build {{ color: var(--muted); }}
  .bk.document {{ color: var(--cho); }}
  .bk.mine {{ color: var(--dsg); }}
  .blegend {{ list-style: none; padding: 0; margin: 12px 0 4px; font-size: 12.5px;
             color: var(--muted); display: grid; gap: 4px; }}
  .tier {{ margin-top: 18px; border-left: 4px solid var(--rule-strong); padding-left: 12px; }}
  .tier.blocking {{ border-left-color: var(--blk); }}
  .tier.design {{ border-left-color: var(--dsg); }}
  .tier.significant {{ border-left-color: var(--sig); }}
  .tier.minor {{ border-left-color: var(--min); }}
  .tier.choice {{ border-left-color: var(--cho); }}
  .tier h3 {{ font-size: 16px; display: flex; align-items: baseline; gap: 8px; }}
  .tier-n {{ font-family: "IBM Plex Mono", monospace; font-size: 13px; color: var(--muted); }}
  .tier-gloss {{ color: var(--muted); font-size: 13px; margin: 2px 0 6px; }}
  .topic {{ border-top: 1px solid var(--rule); }}
  .topic summary {{
    cursor: pointer; padding: 7px 0; display: flex; flex-wrap: wrap;
    align-items: baseline; gap: 4px 10px; font-size: 14px;
  }}
  .topic .tn {{ font-weight: 600; }}
  .topic .tc {{ font-family: "IBM Plex Mono", monospace; font-size: 12.5px; color: var(--muted); }}
  .topic .tw {{ flex-basis: 100%; font-size: 12px; color: var(--muted); }}
  .bl {{ list-style: none; margin: 0 0 8px; padding: 0; }}
  .bl li {{ font-size: 13.5px; padding: 6px 0; border-top: 1px dashed var(--rule); }}
  .bl li:first-child {{ border-top: 0; }}
  .bl .bt {{ margin-left: 4px; }}
  .bl .bw {{ display: block; color: var(--muted); font-size: 12.5px; margin-top: 3px; line-height: 1.45; }}
  .bl .bw .bk {{ margin-right: 6px; }}

  /* --- what is built --------------------------------------------------- */
  .built {{
    margin: 28px 0 8px; padding: 18px 20px;
    border: 1px solid var(--rule-strong); border-radius: 10px;
    background: var(--raised);
  }}
  .built h2 {{ font-size: 21px; margin: 0 0 6px; }}
  .built .blurb {{ color: var(--muted); font-size: 14px; max-width: 62ch; margin: 0 0 12px; }}
  .built .bh {{ font-size: 13px; text-transform: uppercase; letter-spacing: 0.08em;
               color: var(--muted); margin: 16px 0 6px; font-family: "IBM Plex Mono", monospace; }}
  .bsum {{ display: flex; flex-wrap: wrap; border-top: 1px solid var(--rule);
          border-bottom: 1px solid var(--rule); padding-block: 10px; }}
  .bsum div {{ flex: 1 1 110px; padding-right: 12px; }}
  .bsum .n {{ font-family: "IBM Plex Mono", monospace; font-size: 20px; display: block; }}
  .bsum .k {{ font-size: 12px; color: var(--muted); }}
  .blist {{ list-style: none; margin: 0; padding: 0; }}
  .blist li {{ border-top: 1px solid var(--rule); padding: 8px 0 8px 10px;
              border-left: 3px solid var(--rule-strong); margin-bottom: 2px; font-size: 14px; }}
  .blist li.built {{ border-left-color: var(--cho); }}
  .blist li.failing {{ border-left-color: var(--blk); }}
  .blist li.missing {{ border-left-color: var(--sig); }}
  .blist li.waiting {{ border-left-color: var(--min); }}
  .bv {{ font-family: "IBM Plex Mono", monospace; font-size: 10.5px; text-transform: uppercase;
        letter-spacing: 0.06em; margin-right: 6px; }}
  .built li.built .bv {{ color: var(--cho); }}
  .built li.failing .bv {{ color: var(--blk); }}
  .built li.missing .bv {{ color: var(--sig); }}
  .built li.waiting .bv {{ color: var(--muted); }}
  .bref {{ font-family: "IBM Plex Mono", monospace; font-size: 11px; color: var(--faint);
          margin-left: 6px; }}
  .bwhat {{ display: block; color: var(--muted); font-size: 13px; margin-top: 2px; }}

  /* --- where to start -------------------------------------------------- */
  .start {{
    margin: 28px 0 8px; padding: 18px 20px;
    border: 1px solid var(--rule-strong); border-radius: 10px;
    background: color-mix(in srgb, var(--accent) 5%, transparent);
  }}
  .start h2 {{ font-size: 21px; margin: 0 0 6px; }}
  .start .blurb {{ color: var(--muted); font-size: 14px; max-width: 62ch; margin: 0 0 12px; }}
  .start details {{ margin-top: 10px; }}
  .start summary {{
    cursor: pointer; font-family: "IBM Plex Mono", monospace; font-size: 12px;
    letter-spacing: 0.04em; color: var(--accent); padding: 5px 0;
    list-style: none; display: inline-flex; align-items: center; gap: 6px;
  }}
  .start summary::-webkit-details-marker {{ display: none; }}
  .start summary::before {{ content: "\25B8"; font-size: 10px; }}
  .start details[open] > summary::before {{ content: "\25BE"; }}
  .start summary:hover {{ text-decoration: underline; }}
  .startlist {{ margin: 8px 0 0; padding-left: 22px; }}
  .startlist li {{ margin-bottom: 7px; font-size: 14px; }}
  .startlist a {{
    font-family: "IBM Plex Mono", monospace; font-size: 12px; font-weight: 500;
    color: var(--ground); background: var(--min); padding: 1px 6px;
    border-radius: 4px; text-decoration: none; margin-right: 4px;
  }}
  .unlocks, .held {{
    font-family: "IBM Plex Mono", monospace; font-size: 10.5px;
    white-space: nowrap; margin-left: 4px;
  }}
  .unlocks {{ color: var(--cho); }}
  .held {{ color: var(--blk); }}
  .held a {{ background: transparent; color: inherit; padding: 0; }}
  .research .q {{
    display: block; color: var(--muted); font-size: 13px;
    margin-top: 3px; max-width: 62ch;
  }}
  .chains p {{ font-size: 14px; margin: 0 0 9px; max-width: 64ch; color: var(--ink); }}
  .chains a {{
    font-family: "IBM Plex Mono", monospace; font-size: 12px;
    color: var(--accent); text-decoration: none;
  }}
  .chains a:hover {{ text-decoration: underline; }}

  /* --- groups and items ---------------------------------------------- */
  .group {{ margin-top: 44px; }}
  .group-head {{ margin-bottom: 20px; }}
  .group-head .blurb {{ color: var(--muted); font-size: 14.5px; margin-top: 5px; max-width: 60ch; }}

  .item {{
    border-left: 3px solid var(--rule-strong);
    padding: 0 0 0 18px;
    margin-bottom: 26px;
  }}
  .item.blk {{ border-left-color: var(--blk); }}
  .item.dsg {{ border-left-color: var(--dsg); }}
  .item.sig {{ border-left-color: var(--sig); }}
  .item.min {{ border-left-color: var(--min); }}
  .item.chg {{ border-left-color: var(--chg); }}
  .item.cho {{ border-left-color: var(--cho); }}

  .item-head {{
    display: flex; align-items: baseline; gap: 10px; flex-wrap: wrap;
    margin-bottom: 7px;
  }}
  .id {{
    font-family: "IBM Plex Mono", monospace; font-size: 12px; font-weight: 500;
    color: var(--ground); background: var(--min);
    padding: 2px 7px; border-radius: 4px; letter-spacing: 0.02em;
  }}
  .blk .id {{ background: var(--blk); }}
  .dsg .id {{ background: var(--dsg); }}
  .sig .id {{ background: var(--sig); }}
  .chg .id {{ background: var(--chg); }}
  .cho .id {{ background: var(--cho); }}

  .item-head h3 {{ flex: 1 1 260px; }}

  .kind {{
    font-family: "IBM Plex Mono", monospace; font-size: 10.5px;
    letter-spacing: 0.06em; color: var(--faint);
    border: 1px solid var(--rule-strong); border-radius: 3px;
    padding: 0 5px; white-space: nowrap;
  }}

  .chip.alt {{ border-style: dashed; }}

  .status {{
    font-family: "IBM Plex Mono", monospace; font-size: 11px;
    letter-spacing: 0.06em; text-transform: uppercase;
    color: var(--faint); white-space: nowrap;
  }}
  /* --- the two parts, as tabs with their own progress ----------------- */
  .tabs {{
    display: flex; gap: 10px; margin: 26px 0 0; flex-wrap: wrap;
  }}
  .tab {{
    flex: 1 1 180px; min-width: 160px;
    font-family: inherit; text-align: left; cursor: pointer;
    background: transparent; color: var(--ink);
    border: 1px solid var(--rule-strong); border-radius: 10px;
    padding: 12px 14px 11px;
    display: flex; flex-direction: column; gap: 8px;
  }}
  .tab:hover {{ border-color: var(--faint); }}
  .tab:focus-visible {{ outline: 2px solid var(--accent); outline-offset: 2px; }}
  .tab[aria-pressed="true"] {{
    border-color: var(--accent);
    background: color-mix(in srgb, var(--accent) 7%, transparent);
  }}
  /* The three design areas answer a different question from the three sides,
     so they read as a second row rather than as more of the same. */
  .tab.area {{ border-style: dashed; flex-basis: 150px; }}
  .tab.area[aria-pressed="true"] {{ border-style: solid; }}
  .tab.area .fill.settled {{ background: var(--dsg); }}
  .tab.area .fill.drafted {{ background: var(--dsg); opacity: 0.25; }}
  .tab-head {{ display: flex; align-items: baseline; gap: 8px; }}
  .tab-name {{ font-size: 15px; font-weight: 600; }}
  .tab-n {{
    font-family: "IBM Plex Mono", monospace; font-size: 12px;
    color: var(--muted); font-variant-numeric: tabular-nums; margin-left: auto;
  }}
  .tab .bar {{
    position: relative; display: block; height: 7px; border-radius: 4px;
    background: var(--rule); overflow: hidden;
  }}
  .tab .fill {{
    position: absolute; inset: 0 auto 0 0; border-radius: 4px; display: block;
  }}
  .tab .fill.settled {{ background: var(--cho); }}
  .tab .fill.drafted {{ background: var(--sig); opacity: 0.55; }}
  .tabs-note {{
    color: var(--muted); font-size: 13px; line-height: 1.5;
    margin: 10px 0 0; max-width: 62ch;
  }}
  .tab-foot {{
    font-size: 12px; color: var(--muted); font-variant-numeric: tabular-nums;
  }}

  .side {{
    font-family: "IBM Plex Mono", monospace; font-size: 10.5px;
    letter-spacing: 0.05em; white-space: nowrap;
    border: 1px solid currentColor; border-radius: 3px; padding: 0 5px;
  }}
  .side-backend {{ color: var(--chg); }}
  .side-frontend {{ color: var(--dsg); }}
  .side-both {{ color: var(--sig); }}

  .gates {{ margin-top: 10px; }}
  .gate-area {{ margin-bottom: 18px; }}
  .gate-area h3 {{ font-size: 15px; margin-bottom: 2px; }}
  .gate-area .what {{ color: var(--muted); font-size: 13.5px; margin-bottom: 8px; }}
  .gate-area ul {{ margin: 0; padding-left: 20px; }}
  .gate-area li {{ font-size: 14px; margin-bottom: 6px; }}
  .gate-area .clear {{ color: var(--cho); font-size: 14px; }}
  .cleared {{ margin-top: 8px; }}
  .cleared > summary {{
    cursor: pointer; font-family: "IBM Plex Mono", monospace;
    font-size: 11.5px; color: var(--cho); list-style: none;
  }}
  .cleared > summary::-webkit-details-marker {{ display: none; }}
  .cleared > summary::before {{ content: "\2713 "; }}
  .cleared > summary:hover {{ text-decoration: underline; }}
  .cleared li {{ color: var(--muted); font-size: 13.5px; }}
  .gate-count {{
    font-family: "IBM Plex Mono", monospace; font-size: 11px;
    color: var(--ground); background: var(--blk);
    padding: 1px 6px; border-radius: 4px; margin-left: 6px;
  }}
  .gate-count.none {{ background: var(--cho); }}

  .measured {{
    font-family: "IBM Plex Mono", monospace; font-size: 10.5px;
    letter-spacing: 0.05em; color: var(--cho); white-space: nowrap;
    border: 1px solid currentColor; border-radius: 3px; padding: 0 5px;
  }}
  .status.s-done, .status.s-adopted {{ color: var(--cho); }}
  .status.s-proposed {{ color: var(--sig); }}
  .status.s-fixed {{ color: var(--chg); font-weight: 500; }}
  .status.s-withdrawn {{ color: var(--faint); text-decoration: line-through;
                          text-decoration-thickness: 1px; }}

  /* What version 3.0 did about an item, as a layer over what was found. */
  .v3 {{
    margin-top: 10px; padding: 9px 12px; border-radius: 6px;
    background: color-mix(in srgb, var(--chg) 9%, transparent);
    border-left: 2px solid var(--chg);
    color: var(--ink); font-size: 14px; max-width: 66ch;
  }}
  .v3.v31 {{
    background: color-mix(in srgb, var(--cho) 10%, transparent);
    border-left-color: var(--cho);
  }}
  .v3.v31 .vlabel {{ color: var(--cho); }}
  .v3.v32 {{
    background: color-mix(in srgb, var(--dsg) 10%, transparent);
    border-left-color: var(--dsg);
  }}
  .v3.v32 .vlabel {{ color: var(--dsg); }}
  .v3.v33 {{
    background: color-mix(in srgb, var(--sig) 10%, transparent);
    border-left-color: var(--sig);
  }}
  .v3.v33 .vlabel {{ color: var(--sig); }}
  .v3.v34 {{
    background: color-mix(in srgb, var(--blk) 8%, transparent);
    border-left-color: var(--blk);
  }}
  .v3.v34 .vlabel {{ color: var(--blk); }}
  .vlabel {{
    font-family: "IBM Plex Mono", monospace; font-size: 10.5px;
    text-transform: uppercase; letter-spacing: 0.08em; color: var(--chg);
    margin-right: 7px; font-weight: 500;
  }}

  /* The work order: what to type, and where. Collapsed by default, because
     most readings of this page are not an editing session. */
  .edits {{ margin-top: 12px; max-width: 70ch; }}
  .edits > summary {{
    cursor: pointer; font-family: "IBM Plex Mono", monospace; font-size: 11.5px;
    letter-spacing: 0.04em; color: var(--accent); padding: 5px 0;
    list-style: none; display: inline-flex; align-items: center; gap: 6px;
  }}
  .edits > summary::-webkit-details-marker {{ display: none; }}
  .edits > summary::before {{ content: "▸"; font-size: 10px; }}
  .edits[open] > summary::before {{ content: "▾"; }}
  .edits > summary:hover {{ text-decoration: underline; }}
  .edits > summary:focus-visible {{ outline: 2px solid var(--accent); outline-offset: 3px; }}

  .edit-list {{ margin: 8px 0 0; padding: 0 0 0 20px; }}
  .edit {{ margin-bottom: 16px; }}
  .edit::marker {{ font-family: "IBM Plex Mono", monospace; font-size: 11px;
                   color: var(--faint); }}
  .e-head {{ display: flex; align-items: baseline; gap: 8px; flex-wrap: wrap;
             margin-bottom: 6px; }}
  .e-act {{
    font-family: "IBM Plex Mono", monospace; font-size: 10.5px; font-weight: 500;
    letter-spacing: 0.05em; text-transform: uppercase; color: var(--ground);
    background: var(--muted); border-radius: 3px; padding: 1px 6px;
  }}
  .a-replace, .a-retag {{ background: var(--sig); }}
  .a-delete {{ background: var(--blk); }}
  .a-insert {{ background: var(--cho); }}
  .a-regenerate {{ background: var(--chg); }}
  .e-sec {{ font-family: "IBM Plex Mono", monospace; font-size: 12px;
            color: var(--ink); font-weight: 500; }}
  .e-tgt {{ font-size: 13px; color: var(--muted); font-style: italic; }}
  .e-find, .e-new {{ margin: 0 0 5px; font-size: 13.5px; }}
  .e-lab {{
    font-family: "IBM Plex Mono", monospace; font-size: 10px; color: var(--faint);
    text-transform: uppercase; letter-spacing: 0.07em;
    display: inline-block; min-width: 72px;
  }}
  .e-find code {{ background: transparent; border-left: 2px solid var(--blk);
                  padding: 2px 0 2px 8px; color: var(--muted);
                  display: inline-block; max-width: calc(100% - 78px);
                  vertical-align: top; white-space: pre-wrap; }}
  .e-new code {{ background: transparent; border-left: 2px solid var(--cho);
                 padding: 2px 0 2px 8px; color: var(--ink);
                 display: inline-block; max-width: calc(100% - 78px);
                 vertical-align: top; white-space: pre-wrap; }}
  .e-why {{ font-size: 13px; color: var(--muted); margin: 6px 0 0 0;
            padding-left: 10px; border-left: 1px solid var(--rule-strong); }}

  .refs {{ display: flex; flex-wrap: wrap; gap: 5px; margin-bottom: 9px; }}
  .ref {{
    font-family: "IBM Plex Mono", monospace; font-size: 11.5px;
    color: var(--muted); background: var(--rule);
    padding: 1px 6px; border-radius: 3px; white-space: nowrap;
  }}

  .deps {{
    font-family: "IBM Plex Mono", monospace; font-size: 11.5px;
    color: var(--muted); margin: 0 0 9px;
  }}
  .deps a {{ color: var(--accent); text-decoration: none; }}
  .deps a:hover {{ text-decoration: underline; }}
  .item .body {{ color: var(--ink); max-width: 66ch; overflow-wrap: break-word; }}
  .item .rec {{
    margin-top: 10px; color: var(--muted); font-size: 14.5px; max-width: 66ch;
    position: relative; padding-left: 20px;
  }}
  .rec .arrow {{
    color: var(--accent); font-weight: 600;
    position: absolute; left: 0; top: 0;
  }}
  .item strong {{ font-weight: 600; color: var(--ink); }}
  .item em {{ font-style: italic; }}
  code {{
    font-family: "IBM Plex Mono", monospace; font-size: 0.89em;
    background: var(--rule); padding: 1px 5px; border-radius: 3px;
    overflow-wrap: anywhere;
  }}

  .empty {{ color: var(--muted); font-size: 14.5px; padding: 26px 0; }}

  footer {{
    margin-top: 56px; padding-top: 22px; border-top: 1px solid var(--rule);
    color: var(--muted); font-size: 13.5px; max-width: 64ch;
  }}
  footer p + p {{ margin-top: 10px; }}

  @media (prefers-reduced-motion: reduce) {{ * {{ transition: none !important; }} }}
</style>

<div class="wrap">
  <header>
    <p class="eyebrow">Ruleborn &middot; design document v{DOC_VERSION}</p>
    <h1>Audit register</h1>
    <p class="lede">Everything that changed about the plan, and everything that
      still needs fixing in the document. Section marks point into the design
      document; the repository is the source of truth and this page is generated
      from it.</p>
    <p class="lede">Read against <strong>version {DOC_VERSION}</strong>. Five
      versions have now answered this register, and each item carries what each
      one did, as a note per version beneath it. {fixed_count} items are fixed
      in the document itself &mdash; including where a fix stopped short.</p>
    <p class="lede"><strong>v3.4 closes {v34_closed} of the {len(answered)} items it
      answers.</strong> Each was read against the built document by section and
      line rather than taken from &sect;31.9's own list, every check that tracked
      one was re-run, and the rules it changed were ported to the simulation and
      the harness the same day. Two stay open, both waiting on the same
      economy re-run &mdash; {v34_open} &mdash; and that re-run is this
      repository's to do (<strong>D58</strong> first). The four items registered
      after v3.4's snapshot (F33, F34, G17, D58) are not in its list.<br><br>Reading
      it against itself, and running the sweep it names, found
      {len(FOUND_IN_V34)} more. <strong>F35</strong>: brief 37's rule for the
      crack's reach cannot choose one, because with no call at all the depth
      gate fails from two realms up and every realm level holds far above its
      band &mdash; so its fallback would delete the call on evidence that says
      nothing about the call; read on its own, every metre of reach costs depth,
      and the 5 m shipped removes it. <strong>G18</strong>: a ward ignores its
      disarmer only while it stands on the tile, so a Well or a Glare still fires
      on the walk there. <strong>C40</strong>: one sentence &sect;31.3's own
      change made false. And <strong>D59</strong>, the harness's own: its
      optimal crew disarmed what v3.3 made a fifteen-second job and played below
      the competent crew, which every depth figure on v3.3's wards measured.
      <br><br>Before that, v3.3 closed 55 of 64; reading v3.3 against itself and
      porting it found F32 to F34, and the server found G17 and D58.</p>
    <p class="lede"><strong>{edit_count} edits are drafted</strong> across
      {edit_items} items &mdash; the section to open, the sentence as it stands
      today, and what to put there. Every quoted sentence is checked against the
      document by <code>tools/check_edits.py</code>, which fails the build if one
      is not there or appears twice.</p>

    <div class="summary">
      <div><span class="n">{len(REGISTER)}</span><span class="k">items tracked</span></div>
      <div><span class="n">{open_count}</span><span class="k">open, none drafted</span></div>
      <div><span class="n">{fixed_count}</span><span class="k">fixed in the document</span></div>
      <div><span class="n">{done_count}</span><span class="k">done or adopted</span></div>
      <div><span class="n">{counts['blocking'] + counts['design']}</span><span class="k">blocking the build</span></div>
      <div><span class="n">{edit_count}</span><span class="k">edits drafted</span></div>
      <div><span class="n">{today.split()[0]} {today.split()[1][:3]}</span><span class="k">last generated</span></div>
    </div>
{tabs_html()}
  </header>
{blocked_html()}
{handoff_html()}
{built_html()}
{start_here_html()}
  <nav class="filters" aria-label="Filter the register">
    <button class="chip" data-filter="all" aria-pressed="true">Everything<span class="n">{len(REGISTER)}</span></button>
    {chips}
  </nav>

  <main id="list">{''.join(sections)}
    <p class="empty" id="empty" hidden>Nothing in that filter.</p>
  </main>

  <footer>
    <p><strong>How this page is maintained.</strong> The register lives in
      <code>tools/audit_register.py</code> and this page is generated by
      <code>python3 tools/build_audit.py</code>. Change an item's status there
      and rebuild &mdash; never edit the generated HTML, or the next build will
      overwrite it.</p>
    <p>Findings marked F were produced by <code>tools/economy_model/</code>,
      which rebuilds the day-by-day model §24 describes but does not contain.
      Contradictions marked C are asserted where possible in
      <code>tools/check_design_consistency.py</code>, so they are re-checked
      automatically against any later version of the document rather than by
      re-reading 85,000 words.</p>
    <p>The full analysis behind every item is in <code>docs/analysis/</code>.</p>
  </footer>
</div>

<script>
  (function () {{
    "use strict";
    // Two axes, not one. The tabs pick a side; the chips pick a group, a kind
    // or a status. A reader who wants the frontend's blocking items is asking
    // both questions at once, so one control set would have thrown away
    // whichever choice they made first.
    var tabs = Array.prototype.slice.call(document.querySelectorAll(".tab"));
    var chips = Array.prototype.slice.call(document.querySelectorAll(".chip"));
    var items = Array.prototype.slice.call(document.querySelectorAll(".item"));
    var groups = Array.prototype.slice.call(document.querySelectorAll(".group"));
    var empty = document.getElementById("empty");
    var KEY = "ruleborn-audit-filter";
    var side = "all";
    var chip = "all";

    // An item that needs backend and frontend work belongs to both sides, so
    // each side shows the whole of its own work rather than a share of it.
    function onSide(el, which) {{
      if (which === "all") return true;
      // A design-area tab is a different question from a side: it asks which
      // items gate the drawing of that area, and most of them are backend.
      if (which.indexOf("area:") === 0) {{
        var want = which.slice(5);
        return (el.dataset.areas || "").split(" ").indexOf(want) >= 0;
      }}
      return el.dataset.side === which || el.dataset.side === "both";
    }}

    function onChip(el, filter) {{
      if (filter === "all") return true;
      var parts = filter.split(":");
      return el.dataset[parts[0]] === parts[1];
    }}

    // The chip counts are the register's totals as built, which stop being
    // true the moment a side is chosen. Recounting them against the live side
    // keeps every number on the page answering the same question.
    function recount() {{
      chips.forEach(function (c) {{
        var n = c.querySelector(".n");
        if (!n) return;
        var hits = 0;
        items.forEach(function (el) {{
          if (onSide(el, side) && onChip(el, c.dataset.filter)) hits++;
        }});
        n.textContent = String(hits);
        c.disabled = hits === 0;
      }});
    }}

    function apply() {{
      var shown = 0;
      items.forEach(function (el) {{
        var on = onSide(el, side) && onChip(el, chip);
        el.hidden = !on;
        if (on) shown++;
      }});
      groups.forEach(function (g) {{
        var any = Array.prototype.some.call(
          g.querySelectorAll(".item"), function (el) {{ return !el.hidden; }});
        g.hidden = !any;
      }});
      empty.hidden = shown > 0;
      tabs.forEach(function (t) {{
        t.setAttribute("aria-pressed", String(t.dataset.side === side));
      }});
      chips.forEach(function (c) {{
        c.setAttribute("aria-pressed", String(c.dataset.filter === chip));
      }});
      recount();
      try {{
        localStorage.setItem(KEY, JSON.stringify({{side: side, chip: chip}}));
      }} catch (e) {{ /* private mode */ }}
    }}

    tabs.forEach(function (t) {{
      t.addEventListener("click", function () {{
        side = t.dataset.side;
        // A chip the new side has nothing under would show an empty page and
        // look broken, so the side's choice wins and the chip goes back to all.
        if (!items.some(function (el) {{
          return onSide(el, side) && onChip(el, chip);
        }})) chip = "all";
        apply();
      }});
    }});
    chips.forEach(function (c) {{
      c.addEventListener("click", function () {{ chip = c.dataset.filter; apply(); }});
    }});

    var saved = null;
    try {{ saved = JSON.parse(localStorage.getItem(KEY) || "null"); }}
    catch (e) {{ saved = null; }}
    if (saved && typeof saved === "object") {{
      if (tabs.some(function (t) {{ return t.dataset.side === saved.side; }})) {{
        side = saved.side;
      }}
      if (saved.chip === "all"
          || chips.some(function (c) {{ return c.dataset.filter === saved.chip; }})) {{
        chip = saved.chip;
      }}
    }}
    apply();
  }})();
</script>
"""


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    # Carry a digest of this page, so the republish job can tell what
    # is live without comparing calendar days (D28).
    OUT.write_text(stamped(build()), encoding="utf-8")
    kinds = {}
    for item in REGISTER:
        kinds[item["_group"]] = kinds.get(item["_group"], 0) + 1
    print(f"{OUT} — {len(REGISTER)} items {kinds}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
