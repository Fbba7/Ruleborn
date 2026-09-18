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
from audit_register import (DEPENDS, DESIGN_GATES, EDITS, FOUND_IN_V3,  # noqa: E402
                            REGISTER, RESEARCH, V3, V31, side_of)

from build_stamp import stamped  # noqa: E402

OUT = pathlib.Path(__file__).resolve().parent.parent / "docs" / "audit" / "index.html"

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
    "fixed":    "Fixed in v3.0",
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


SETTLED = {"done", "adopted", "fixed", "withdrawn"}


def _status_of(item: dict) -> str:
    return V3.get(item["id"], {}).get("status") or item.get("status", "open")


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
    stat = [(V31.get(i["id"], {}).get("status")
             or V3.get(i["id"], {}).get("status")
             or i.get("status", "open")) for i in items]
    settled = sum(1 for x in stat if x in SETTLED)
    drafted = sum(1 for x in stat if x in DRAFTED)
    total = len(items) or 1
    return dict(total=len(items), settled=settled, drafted=drafted,
                open=len(items) - settled - drafted,
                settled_pct=100 * settled / total,
                drafted_pct=100 * (settled + drafted) / total)


def areas_of(item_id: str) -> list[str]:
    """Which design areas this item gates, open or already cleared.

    An item can gate more than one: C6's two rosters decide both which roster
    a character screen reads from and what eleven of the eighteen creatures
    actually are.
    """
    return [area for area, spec in DESIGN_GATES.items()
            if item_id in spec["gates"] or item_id in spec.get("closed", {})]


def area_gates(area: str) -> tuple[list[str], list[str]]:
    """The register items that gate one design area: cleared, then still open."""
    spec = DESIGN_GATES[area]
    return list(spec.get("closed", {})), list(spec["gates"])


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
        body = (f"<ul>{rows}</ul>" if gates else
                '<p class="clear">Nothing open. This can start now.</p>')
        out.append(
            f'<div class="gate-area"><h3>{esc(area.capitalize())}'
            f'<span class="gate-count{cls}">{len(gates)} open</span></h3>'
            f'<p class="what">{spec["what"]}</p>{body}</div>')
    return f"""
    <details><summary>When the design of realms, screens and characters can
      start</summary>
      <p class="blurb">Each area lists the items still open that decide
        something a designer would otherwise have to guess, and what each one
        changes about the drawing. Almost all of them are backend items: the
        split says where work happens, this says what it holds up.</p>
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


def item_html(item: dict) -> str:
    label, cls = SEVERITY[item["severity"]]
    v3 = V3.get(item["id"], {})
    status = (V31.get(item["id"], {}).get("status")
              or v3.get("status") or item.get("status", "open"))
    rec = item.get("rec")
    v3_html = (f'<p class="v3"><span class="vlabel">v3.0</span> {v3["note"]}</p>'
               if v3.get("note") else "")
    # v3.1 is a second layer, not a replacement: what v3.0 did about an item is
    # part of the item's history and stays on the page beneath it.
    v31 = V31.get(item["id"], {})
    v31_html = (f'<p class="v3 v31"><span class="vlabel">v3.1</span> {v31["note"]}</p>'
                if v31.get("note") else "")
    return f"""
      <article class="item {cls}" id="{item['id']}" data-group="{item['_group']}"
               data-kind="{item['kind']}" data-status="{status}"
               data-side="{side_of(item['id'])}"
               data-areas="{' '.join(areas_of(item['id']))}"
               data-edits="{'yes' if item['id'] in EDITS else 'no'}">
        <header class="item-head">
          <span class="id">{esc(item['id'])}</span>
          <h3>{esc(item['title'])}</h3>
          <span class="kind">{KIND[item['kind']]}</span>
          <span class="status s-{status}">{STATUS[status]}</span>
          <span class="side side-{side_of(item['id'])}">{SIDE_LABEL[side_of(item['id'])]}</span>
          {measured_html(item)}
        </header>
        <div class="refs">{refs_html(item['refs'])}</div>
        {deps_html(item)}
        <p class="body">{item['body']}</p>
        {f'<p class="rec"><span class="arrow">&rarr;</span> {rec}</p>' if rec else ''}
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
        return (V31.get(item["id"], {}).get("status")
                or V3.get(item["id"], {}).get("status")
                or item.get("status", "open"))

    open_count = sum(1 for i in REGISTER if status_of(i) == "open")
    done_count = sum(1 for i in REGISTER if status_of(i) in ("done", "adopted"))
    fixed_count = sum(1 for i in REGISTER if status_of(i) == "fixed")
    touched = sum(1 for i in REGISTER if i["id"] in V3)
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
    chips += (f'<button class="chip alt" data-filter="status:fixed">Fixed in v3.0'
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
    <p class="eyebrow">Ruleborn &middot; design document v3.1</p>
    <h1>Audit register</h1>
    <p class="lede">Everything that changed about the plan, and everything that
      still needs fixing in the document. Section marks point into the design
      document; the repository is the source of truth and this page is generated
      from it.</p>
    <p class="lede">Read against <strong>version 3.1</strong>. Two versions have
      now answered this register, and each item carries what they did: a
      <span class="vlabel">v3.0</span> note, and a <span class="vlabel">v3.1</span>
      note beneath it where v3.1 moved. {fixed_count} items are fixed in the
      document itself &mdash; including where a fix stopped short.</p>
    <p class="lede"><strong>v3.1 is the first version whose fixes were checked
      rather than claimed.</strong> It ships a build checker, pins its constants
      in data, and closes eight items &mdash; C7, C10, C17, C21, C24, C26, D4 and
      D10 &mdash; every one of which was verified here against the built document
      rather than taken from &sect;31.9's own list. v3.0 published a list like
      that too, and C21 to C24 are what it missed.<br><br>What it did not reach
      is <strong>F24</strong> and <strong>F25</strong>: a supersession check that
      passes on a document still containing the model it bans, and six facts that
      still have two homes against &sect;31.2's rule that each should have one.</p>
    <p class="lede"><strong>{edit_count} edits are drafted</strong> across
      {edit_items} items &mdash; the section to open, the sentence as it stands
      today, and what to put there. Every quoted sentence is checked against the
      document by <code>tools/check_edits.py</code>, which fails the build if one
      is not there or appears twice.</p>

    <div class="summary">
      <div><span class="n">{len(REGISTER)}</span><span class="k">items tracked</span></div>
      <div><span class="n">{open_count}</span><span class="k">open</span></div>
      <div><span class="n">{fixed_count}</span><span class="k">fixed in v3.0</span></div>
      <div><span class="n">{done_count}</span><span class="k">done or adopted</span></div>
      <div><span class="n">{counts['blocking'] + counts['design']}</span><span class="k">blocking the build</span></div>
      <div><span class="n">{edit_count}</span><span class="k">edits drafted</span></div>
      <div><span class="n">{today.split()[0]} {today.split()[1][:3]}</span><span class="k">last generated</span></div>
    </div>
{tabs_html()}
  </header>
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
