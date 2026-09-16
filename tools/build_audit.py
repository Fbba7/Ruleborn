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
from audit_register import EDITS, FOUND_IN_V3, REGISTER, V3  # noqa: E402

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


def item_html(item: dict) -> str:
    label, cls = SEVERITY[item["severity"]]
    v3 = V3.get(item["id"], {})
    status = v3.get("status") or item.get("status", "open")
    rec = item.get("rec")
    v3_html = (f'<p class="v3"><span class="vlabel">v3.0</span> {v3["note"]}</p>'
               if v3.get("note") else "")
    return f"""
      <article class="item {cls}" data-group="{item['_group']}"
               data-kind="{item['kind']}" data-status="{status}"
               data-edits="{'yes' if item['id'] in EDITS else 'no'}">
        <header class="item-head">
          <span class="id">{esc(item['id'])}</span>
          <h3>{esc(item['title'])}</h3>
          <span class="kind">{KIND[item['kind']]}</span>
          <span class="status s-{status}">{STATUS[status]}</span>
        </header>
        <div class="refs">{refs_html(item['refs'])}</div>
        <p class="body">{item['body']}</p>
        {f'<p class="rec"><span class="arrow">&rarr;</span> {rec}</p>' if rec else ''}
        {v3_html}
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
        return V3.get(item["id"], {}).get("status") or item.get("status", "open")

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
  .chip:focus-visible {{ outline: 2px solid var(--accent); outline-offset: 2px; }}
  .chip[aria-pressed="true"] {{
    color: var(--ground); background: var(--ink); border-color: var(--ink);
  }}
  .chip .n {{
    font-family: "IBM Plex Mono", monospace; font-size: 11.5px;
    font-variant-numeric: tabular-nums; opacity: 0.65;
  }}

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
    <p class="eyebrow">Ruleborn &middot; design document v2.3</p>
    <h1>Audit register</h1>
    <p class="lede">Everything that changed about the plan, and everything that
      still needs fixing in the document. Section marks point into the design
      document; the repository is the source of truth and this page is generated
      from it.</p>
    <p class="lede">Read against <strong>version 3.0</strong>, which answered this
      register directly (&sect;30.18). {fixed_count} items are fixed in the
      document itself and carry a <span class="vlabel">v3.0</span> note saying
      what it did &mdash; including where a fix stopped short. {new_in_v3} items
      are new: four are decisions v3.0 took and then left a stale copy of, which
      is the pattern the whole register is about; the rest came out of building
      the simulation harnesses &sect;19.27 now depends on, and writing all 48 laws
      out against the rule sheet &sect;7.3 claims they change.</p>
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
  </header>

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
    var chips = Array.prototype.slice.call(document.querySelectorAll(".chip"));
    var items = Array.prototype.slice.call(document.querySelectorAll(".item"));
    var groups = Array.prototype.slice.call(document.querySelectorAll(".group"));
    var empty = document.getElementById("empty");
    var KEY = "ruleborn-audit-filter";

    function matches(el, filter) {{
      if (filter === "all") return true;
      var parts = filter.split(":");
      return el.dataset[parts[0]] === parts[1];
    }}

    function apply(filter) {{
      var shown = 0;
      items.forEach(function (el) {{
        var on = matches(el, filter);
        el.hidden = !on;
        if (on) shown++;
      }});
      groups.forEach(function (g) {{
        var any = Array.prototype.some.call(
          g.querySelectorAll(".item"), function (el) {{ return !el.hidden; }});
        g.hidden = !any;
      }});
      empty.hidden = shown > 0;
      chips.forEach(function (c) {{
        c.setAttribute("aria-pressed", String(c.dataset.filter === filter));
      }});
      try {{ localStorage.setItem(KEY, filter); }} catch (e) {{ /* private mode */ }}
    }}

    chips.forEach(function (c) {{
      c.addEventListener("click", function () {{ apply(c.dataset.filter); }});
    }});

    var saved = null;
    try {{ saved = localStorage.getItem(KEY); }} catch (e) {{ saved = null; }}
    if (saved && chips.some(function (c) {{ return c.dataset.filter === saved; }})) {{
      apply(saved);
    }}
  }})();
</script>
"""


def main() -> int:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(build(), encoding="utf-8")
    kinds = {}
    for item in REGISTER:
        kinds[item["_group"]] = kinds.get(item["_group"], 0) + 1
    print(f"{OUT} — {len(REGISTER)} items {kinds}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
