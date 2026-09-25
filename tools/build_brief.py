#!/usr/bin/env python3
"""Render the owner's decision brief to a page where each decision is answered.

    python3 tools/build_brief.py            # write docs/decisions/index.html
    python3 tools/build_brief.py --check    # the gate check_all.sh runs

The brief is `docs/decisions/brief.json`: for every open register item whose
blocker is the owner's decision (build_audit.blocker), the question, its
options with their consequences and numbers, what the build does today, a
recommendation, and quotes from the design document. It was drafted, checked
from two sides and merged by a multi-agent pass, then synthesised into an
order to decide in, the decisions that share one choice, and the places two
recommendations collide.

The page is static: every word of the brief is in the markup, so it reads with
no script. The answers are not: the published page keeps them in its own
database (`answers/<id>`: the option, a note, when), which Claude reads back
to turn each answer into register and document edits.

The check fails when a quote is not in the design document word for word,
when a recommendation names an option the entry does not have, when an entry
names an item the register does not have, or when an open decision has no
entry — so the brief cannot fall behind the register in silence.
"""

import html
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import build_audit                                                  # noqa: E402
from design_doc import TEXT as DOC_TEXT                              # noqa: E402

BRIEF = ROOT / "docs" / "decisions" / "brief.json"
OUT = ROOT / "docs" / "decisions" / "index.html"
AUDIT_URL = "https://claude.ai/artifact/8m5MgpjWfFurnfwc6b76sN"

TIERS = {"blocking": "Blocking", "design": "Design", "significant": "Significant",
         "minor": "Minor", "choice": "Decision"}


def esc(text) -> str:
    return html.escape(str(text), quote=True)


def load() -> dict:
    return json.loads(BRIEF.read_text(encoding="utf-8"))


def problems(brief: dict) -> list[str]:
    """What is wrong with the brief against the register and the document."""
    out = []
    doc = DOC_TEXT.read_text(encoding="utf-8")
    lines = set(doc.split("\n"))
    by_id = {i["id"]: i for i in build_audit.REGISTER}
    entries = brief["entries"]
    for eid, e in entries.items():
        if eid not in by_id:
            out.append(f"{eid}: no such register item")
            continue
        keys = [o["key"] for o in e["options"]]
        if len(set(keys)) != len(keys):
            out.append(f"{eid}: two options share a key")
        if e["recommendation"].get("confidence") not in ("high", "medium", "low"):
            out.append(f"{eid}: a recommendation needs a confidence: high, medium or low")
        if e["recommendation"]["option"] not in keys:
            out.append(f"{eid}: recommends {e['recommendation']['option']!r}, not one of {keys}")
        for q in e.get("quotes", []):
            if not any(q["text"] in line for line in lines):
                out.append(f"{eid}: quote not in the document: {q['text'][:70]!r}")
    got = json.loads((ROOT / "docs" / "decisions" / "answers.json")
                     .read_text(encoding="utf-8"))["answers"]
    for eid, a in got.items():
        if eid not in entries:
            out.append(f"answers.json: {eid} is not in the brief")
        elif a.get("option") not in [o["key"] for o in entries[eid]["options"]]:
            out.append(f"answers.json: {eid} answers {a.get('option')!r}, not one of its options")
        if a.get("build") not in ("none", "to do", "done", "outside"):
            out.append(f"answers.json: {eid} has build {a.get('build')!r}")
    wanted = {r["item"]["id"] for r in build_audit.blocked() if r["why"] == "yours"}
    for eid in sorted(wanted - set(entries)):
        out.append(f"{eid}: waits on the owner's decision and has no entry in the brief")
    order = brief["order"]
    if sorted(order) != sorted(entries):
        out.append("the order does not list every entry exactly once")
    for g in brief.get("groups", []) + brief.get("conflicts", []):
        for gid in g["ids"]:
            if gid not in entries:
                out.append(f"a group or conflict names {gid}, which has no entry")
    for qid in brief.get("quick", []):
        if qid not in entries:
            out.append(f"the quick list names {qid}, which has no entry")
    return out


def option_html(eid: str, o: dict, rec: str) -> str:
    recommended = o["key"] == rec
    tag = '<span class="rec-tag">Recommended</span>' if recommended else ""
    details = []
    for label, key in (("Numbers", "numbers"), ("Document edit", "doc_edit"),
                       ("Build change", "build_change")):
        v = (o.get(key) or "").strip()
        if v and v.lower() not in ("none", "n/a"):
            details.append(f'<div class="od"><dt>{label}</dt><dd>{esc(v)}</dd></div>')
    more = (f'<details class="omore"><summary>Numbers and edits</summary>'
            f'<dl>{"".join(details)}</dl></details>') if details else ""
    return f"""
        <label class="opt{' is-rec' if recommended else ''}" for="o-{eid}-{o['key']}">
          <input type="radio" name="o-{eid}" id="o-{eid}-{o['key']}" value="{esc(o['key'])}" disabled>
          <span class="ob">
            <span class="oh"><span class="ok">{esc(o['key'])}</span>
              <span class="ol">{esc(o['label'])}</span>{tag}</span>
            <span class="om">{esc(o['means'])}</span>
            <span class="oc">{esc(o['consequences'])}</span>
            {more}
          </span>
        </label>"""


def entry_html(n: int, eid: str, e: dict, item: dict, topic: str, quick: bool) -> str:
    rec = e["recommendation"]
    opts = "".join(option_html(eid, o, rec["option"]) for o in e["options"])
    quotes = "".join(
        f'<li><span class="qs">&sect;{esc(q["section"])}</span> '
        f'<q>{esc(q["text"])}</q></li>' for q in e.get("quotes", []))
    panel = ""
    if e.get("panel"):
        votes = "".join(
            f'<li><span class="pl">{esc(v["lens"])}</span> <strong>{esc(v["option"])}</strong>'
            f'{"" if (v.get("variant") or "none").lower() == "none" else " &middot; " + esc(v["variant"])}'
            f'<span class="pr">{esc(v["reasoning"])}</span></li>' for v in e["panel"])
        panel = f'<details class="panel"><summary>Three judges</summary><ul>{votes}</ul></details>'
    also = (e.get("also_needed") or "").strip()
    also_html = (f'<p class="also"><span class="lab">Also needed</span> {esc(also)}</p>'
                 if also and also.lower() not in ("nothing", "none") else "")
    inter = [i for i in e.get("interacts_with", []) if i != eid]
    inter_html = (f'<p class="inter"><span class="lab">Weigh with</span> '
                  + ", ".join(f'<a href="#{esc(i)}">{esc(i)}</a>' for i in inter) + "</p>"
                  if inter else "")
    rec_label = next((o["label"] for o in e["options"] if o["key"] == rec["option"]), "")
    return f"""
    <article class="decision" id="{esc(eid)}" data-id="{esc(eid)}" data-tier="{esc(item['severity'])}"
             data-rec="{esc(rec['option'])}" data-quick="{'yes' if quick else 'no'}" data-answered="no">
      <header class="dh">
        <span class="step" title="Decide in this order">{n}</span>
        <span class="did">{esc(eid)}</span>
        <span class="tier t-{esc(item['severity'])}">{TIERS.get(item['severity'], item['severity'])}</span>
        <span class="topic">{esc(topic)}</span>
        <span class="state" id="st-{esc(eid)}">Not answered</span>
      </header>
      <h3 class="q">{esc(e['question'])}</h3>
      <p class="why">{esc(e['why_it_matters'])}</p>
      <details class="today"><summary>What the build does today</summary><p>{esc(e['today'])}</p></details>
      <fieldset class="opts" aria-label="Options for {esc(eid)}">{opts}
      </fieldset>
      <div class="recbox">
        <p><span class="lab">Recommended: {esc(rec['option'])}, {esc(rec_label)}</span>
          <span class="conf c-{esc(rec['confidence'])}">{esc(rec['confidence'])} confidence</span></p>
        <p class="rr">{esc(rec['rationale'])}</p>
        {panel}
      </div>
      {also_html}{inter_html}
      {f'<details class="quotes"><summary>What the document says</summary><ul>{quotes}</ul></details>' if quotes else ''}
      <div class="notebox">
        <label for="n-{esc(eid)}">Note for Claude (optional)</label>
        <textarea id="n-{esc(eid)}" rows="2" placeholder="A number, a condition, or why" disabled></textarea>
        <div class="nb">
          <button type="button" class="btn save-note" data-id="{esc(eid)}" disabled>Save note</button>
          <button type="button" class="btn ghost clear" data-id="{esc(eid)}" disabled>Clear answer</button>
          <a class="reg" href="{AUDIT_URL}#{esc(eid)}" target="_blank" rel="noopener">Register entry</a>
        </div>
      </div>
    </article>"""


def build(brief: dict) -> str:
    by_id = {i["id"]: i for i in build_audit.REGISTER}
    topics = {r["item"]["id"]: r["topic"] for r in build_audit.blocked()}
    chapters = build_audit.chapters()
    entries = brief["entries"]
    quick = set(brief.get("quick", []))
    cards = []
    for n, eid in enumerate(brief["order"], 1):
        item = by_id[eid]
        top = item["refs"][0].split(".")[0] if item.get("refs") else ""
        topic = topics.get(eid) or chapters.get(top, "Across the document")
        cards.append(entry_html(n, eid, entries[eid], item, f"§{top} {topic}" if top else topic,
                                eid in quick))
    tiers = {}
    for eid in entries:
        t = by_id[eid]["severity"]
        tiers[t] = tiers.get(t, 0) + 1
    tier_line = " &middot; ".join(f"{tiers[t]} {TIERS[t].lower()}" for t in TIERS if t in tiers)

    groups = "".join(
        f'<li><strong>{esc(g["title"])}</strong> '
        + ", ".join(f'<a href="#{esc(i)}">{esc(i)}</a>' for i in g["ids"])
        + f'<span class="gn">{esc(g["note"])}</span></li>' for g in brief.get("groups", []))
    conflicts = "".join(
        f'<li>' + ", ".join(f'<a href="#{esc(i)}">{esc(i)}</a>' for i in c["ids"])
        + f'<span class="gn">{esc(c["problem"])}</span>'
        f'<span class="gr"><span class="lab">Resolved as</span> {esc(c["resolution"])}</span></li>'
        for c in brief.get("conflicts", []))
    quick_rows = "".join(
        f'<li><a href="#{esc(q)}">{esc(q)}</a> {esc(entries[q]["question"])}</li>'
        for q in brief.get("order", []) if q in quick)
    chips = "".join(
        f'<button type="button" class="chip" data-filter="{k}" aria-pressed="{"true" if k == "all" else "false"}">'
        f'{label}<span class="n" id="cn-{k}"></span></button>'
        for k, label in (("all", "All"), ("open", "Unanswered"), ("design", "Design"),
                         ("significant", "Significant"), ("minor", "Minor")))

    return f"""<title>Ruleborn Decisions</title>
<meta name="description" content="The owner's decisions on the Ruleborn design, each with its options, numbers and a recommendation.">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Marcellus&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap">
<style>
  /* The audit register's palette and faces (tools/build_audit.py), so the
     two pages read as one set. */
  :root {{
    --ground: #FCFBFF; --raised: #FFFFFF; --ink: #221C3A; --muted: #6E6685;
    --faint: #958CAD; --rule: #E6E2EE; --rule-strong: #D3CCE3;
    --blk: #C0304A; --dsg: #7A46C8; --sig: #A77410; --min: #6E6685;
    --chg: #1F6F83; --cho: #2E7D5B; --accent: #7A46C8; --accent-wash: #F1EAFB;
    color-scheme: light;
  }}
  @media (prefers-color-scheme: dark) {{
    :root:not([data-theme="light"]) {{
      --ground: #17122C; --raised: #1E1839; --ink: #EDE9F8; --muted: #A79FC4;
      --faint: #7E76A0; --rule: #2E2650; --rule-strong: #3D3466;
      --blk: #E2536B; --dsg: #B18CF5; --sig: #F2B43C; --min: #A79FC4;
      --chg: #3CC6D8; --cho: #5CC46A; --accent: #B18CF5; --accent-wash: #2A2150;
      color-scheme: dark;
    }}
  }}
  :root[data-theme="dark"] {{
    --ground: #17122C; --raised: #1E1839; --ink: #EDE9F8; --muted: #A79FC4;
    --faint: #7E76A0; --rule: #2E2650; --rule-strong: #3D3466;
    --blk: #E2536B; --dsg: #B18CF5; --sig: #F2B43C; --min: #A79FC4;
    --chg: #3CC6D8; --cho: #5CC46A; --accent: #B18CF5; --accent-wash: #2A2150;
    color-scheme: dark;
  }}
  body {{
    margin: 0; background: var(--ground); color: var(--ink);
    font-family: "IBM Plex Sans", system-ui, -apple-system, sans-serif;
    font-size: 15.5px; line-height: 1.6; -webkit-font-smoothing: antialiased;
  }}
  .wrap {{ max-width: 780px; margin: 0 auto; padding-inline: 20px; padding-block: 36px 72px; }}
  h1, h2 {{ font-family: Marcellus, Georgia, serif; font-weight: 400; text-wrap: balance; margin: 0; }}
  h1 {{ font-size: clamp(30px, 7vw, 40px); line-height: 1.1; }}
  h2 {{ font-size: 21px; margin-bottom: 6px; }}
  p {{ margin: 0; }}
  a {{ color: var(--accent); }}
  .eyebrow {{ font-family: "IBM Plex Mono", monospace; text-transform: uppercase;
    letter-spacing: 0.16em; font-size: 11px; color: var(--accent); margin-bottom: 10px; }}
  .lede {{ color: var(--muted); font-size: 16px; max-width: 64ch; margin-top: 14px; }}
  .lab {{ font-family: "IBM Plex Mono", monospace; font-size: 10.5px; letter-spacing: 0.07em;
    text-transform: uppercase; color: var(--muted); }}

  .summary {{ display: flex; flex-wrap: wrap; margin-top: 26px; border-block: 1px solid var(--rule);
    padding-block: 12px; }}
  .summary div {{ flex: 1 1 120px; padding-right: 14px; }}
  .summary .n {{ font-family: "IBM Plex Mono", monospace; font-size: 23px; font-weight: 500;
    font-variant-numeric: tabular-nums; display: block; line-height: 1.2; }}
  .summary .k {{ font-size: 12.5px; color: var(--muted); }}
  .bar {{ height: 6px; background: var(--rule); border-radius: 999px; overflow: hidden; margin-top: 10px; }}
  .bar span {{ display: block; height: 100%; width: 0; background: var(--cho); transition: width .3s; }}

  .notice {{ margin-top: 18px; padding: 10px 14px; border-radius: 8px; font-size: 14px;
    border: 1px solid var(--rule-strong); background: var(--raised); color: var(--muted); }}
  .notice.warn {{ border-color: var(--sig); color: var(--ink); }}

  .panelbox {{ margin-top: 22px; padding: 16px 18px; border: 1px solid var(--rule-strong);
    border-radius: 10px; background: var(--raised); }}
  .panelbox .blurb {{ color: var(--muted); font-size: 14px; max-width: 64ch; margin-bottom: 10px; }}
  .fold > summary {{ list-style: none; cursor: pointer; }}
  .fold > summary::-webkit-details-marker {{ display: none; }}
  .fold > summary h2 {{ display: inline; margin: 0; }}
  .fold > summary::after {{ content: "Show"; float: right; font-size: 13px; color: var(--accent); margin-top: 6px; }}
  .fold[open] > summary::after {{ content: "Hide"; }}
  .fold[open] > summary {{ margin-bottom: 8px; }}
  .fc {{ font-family: "IBM Plex Mono", monospace; font-size: 14px; color: var(--muted); margin-left: 6px; }}
  .plist {{ list-style: none; margin: 0; padding: 0; }}
  .plist li {{ padding: 8px 0; border-top: 1px solid var(--rule); font-size: 14px; }}
  .plist li:first-child {{ border-top: 0; }}
  .gn, .gr {{ display: block; color: var(--muted); font-size: 13px; margin-top: 3px; line-height: 1.45; }}
  .gr {{ color: var(--ink); }}

  .filters {{ position: sticky; top: env(safe-area-inset-top, 0px); z-index: 5; background: var(--ground);
    display: flex; flex-wrap: wrap; gap: 7px; align-items: center; padding-block: 12px;
    margin-top: 22px; border-bottom: 1px solid var(--rule); }}
  .chip {{ font: inherit; font-size: 13px; font-weight: 500; color: var(--muted); background: transparent;
    border: 1px solid var(--rule-strong); border-radius: 999px; padding: 5px 12px; min-height: 34px;
    cursor: pointer; display: inline-flex; gap: 7px; align-items: center; }}
  .chip[aria-pressed="true"] {{ color: var(--ground); background: var(--ink); border-color: var(--ink); }}
  .chip .n {{ font-family: "IBM Plex Mono", monospace; font-size: 11.5px; opacity: .7; }}
  .chip:focus-visible, .btn:focus-visible, .opt:focus-within {{ outline: 2px solid var(--accent); outline-offset: 2px; }}
  .answered {{ margin-left: auto; font-family: "IBM Plex Mono", monospace; font-size: 12.5px;
    color: var(--muted); font-variant-numeric: tabular-nums; }}

  .decision {{ margin-top: 18px; padding: 18px 18px 16px; border: 1px solid var(--rule-strong);
    border-radius: 10px; background: var(--raised); border-left: 4px solid var(--min);
    display: grid; gap: 10px; scroll-margin-top: 70px; }}
  .decision[data-tier="design"] {{ border-left-color: var(--dsg); }}
  .decision[data-tier="significant"] {{ border-left-color: var(--sig); }}
  .decision[data-tier="blocking"] {{ border-left-color: var(--blk); }}
  .decision[data-answered="yes"] {{ border-left-color: var(--cho); }}
  .dh {{ display: flex; flex-wrap: wrap; align-items: baseline; gap: 6px 10px; font-size: 12.5px; }}
  .step {{ font-family: "IBM Plex Mono", monospace; color: var(--faint); font-variant-numeric: tabular-nums; }}
  .did {{ font-family: "IBM Plex Mono", monospace; font-weight: 500; }}
  .tier {{ font-family: "IBM Plex Mono", monospace; font-size: 10.5px; letter-spacing: .06em;
    text-transform: uppercase; padding: 1px 6px; border-radius: 4px; border: 1px solid currentColor; }}
  .t-design {{ color: var(--dsg); }} .t-significant {{ color: var(--sig); }}
  .t-minor {{ color: var(--min); }} .t-blocking {{ color: var(--blk); }}
  .topic {{ color: var(--muted); }}
  .state {{ margin-left: auto; font-family: "IBM Plex Mono", monospace; font-size: 11.5px; color: var(--muted); }}
  .decision[data-answered="yes"] .state {{ color: var(--cho); }}
  .q {{ font-family: "IBM Plex Sans", sans-serif; font-size: 17.5px; font-weight: 600; line-height: 1.35;
    margin: 0; text-wrap: balance; }}
  .why {{ color: var(--muted); font-size: 14.5px; max-width: 66ch; }}
  details > summary {{ cursor: pointer; font-size: 13.5px; color: var(--accent); }}
  .today p, .quotes ul {{ margin-top: 6px; font-size: 14px; color: var(--muted); }}

  .opts {{ border: 0; margin: 0; padding: 0; display: grid; gap: 8px; min-width: 0; }}
  .opt {{ display: grid; grid-template-columns: auto 1fr; gap: 10px; align-items: start;
    border: 1px solid var(--rule-strong); border-radius: 9px; padding: 10px 12px; cursor: pointer;
    background: var(--ground); }}
  .opt input {{ margin-top: 5px; accent-color: var(--accent); }}
  .opt.is-rec {{ border-style: dashed; border-color: var(--accent); }}
  .opt:has(input:checked) {{ border-style: solid; border-color: var(--accent); background: var(--accent-wash); }}
  .ob {{ display: grid; gap: 3px; min-width: 0; }}
  .oh {{ display: flex; flex-wrap: wrap; gap: 4px 8px; align-items: baseline; }}
  .ok {{ font-family: "IBM Plex Mono", monospace; font-weight: 500; }}
  .ol {{ font-weight: 600; }}
  .rec-tag {{ font-family: "IBM Plex Mono", monospace; font-size: 10px; letter-spacing: .06em;
    text-transform: uppercase; color: var(--accent); }}
  .om {{ font-size: 14.5px; }}
  .oc {{ font-size: 13.5px; color: var(--muted); }}
  .omore dl {{ margin: 6px 0 0; display: grid; gap: 6px; }}
  .od dt {{ font-family: "IBM Plex Mono", monospace; font-size: 10.5px; text-transform: uppercase;
    letter-spacing: .07em; color: var(--muted); }}
  .od dd {{ margin: 0; font-size: 13.5px; }}

  .recbox {{ border-top: 1px solid var(--rule); padding-top: 10px; display: grid; gap: 4px; }}
  .recbox .lab {{ color: var(--accent); }}
  .conf {{ font-size: 12px; color: var(--muted); margin-left: 8px; }}
  .c-high {{ color: var(--cho); }} .c-low {{ color: var(--sig); }}
  .rr {{ font-size: 14.5px; max-width: 66ch; }}
  .panel ul {{ list-style: none; padding: 0; margin: 6px 0 0; display: grid; gap: 8px; }}
  .panel li {{ font-size: 13.5px; }}
  .pl {{ font-family: "IBM Plex Mono", monospace; font-size: 10.5px; text-transform: uppercase;
    letter-spacing: .07em; color: var(--muted); margin-right: 6px; }}
  .pr {{ display: block; color: var(--muted); margin-top: 2px; }}
  .also, .inter {{ font-size: 13.5px; }}
  .quotes ul {{ padding-left: 18px; }}
  .qs {{ font-family: "IBM Plex Mono", monospace; font-size: 12px; }}
  q {{ font-style: italic; }}

  .notebox {{ display: grid; gap: 6px; border-top: 1px solid var(--rule); padding-top: 10px; }}
  .notebox label {{ font-size: 12.5px; color: var(--muted); }}
  textarea {{ font: inherit; font-size: 14px; color: var(--ink); background: var(--ground); width: 100%;
    box-sizing: border-box; border: 1px solid var(--rule-strong); border-radius: 8px; padding: 8px 10px;
    resize: vertical; }}
  .nb {{ display: flex; flex-wrap: wrap; gap: 8px; align-items: center; }}
  .btn {{ font: inherit; font-size: 13px; font-weight: 500; border-radius: 7px; padding: 6px 12px;
    min-height: 34px; cursor: pointer; border: 1px solid var(--accent); background: var(--accent);
    color: var(--raised); }}
  .btn.ghost {{ background: transparent; color: var(--muted); border-color: var(--rule-strong); }}
  .btn:disabled, textarea:disabled {{ opacity: .5; cursor: default; }}
  .reg {{ margin-left: auto; font-size: 13px; }}
  .empty {{ margin-top: 20px; color: var(--muted); }}
  footer {{ margin-top: 40px; color: var(--muted); font-size: 13.5px; display: grid; gap: 8px; max-width: 66ch; }}
  @media (prefers-reduced-motion: reduce) {{ * {{ transition: none !important; }} }}
</style>

<div class="wrap">
  <header>
    <p class="eyebrow">Ruleborn &middot; the owner&rsquo;s decisions</p>
    <h1>Decisions waiting on you</h1>
    <p class="lede">{esc(brief['summary'])}</p>
    <div class="summary">
      <div><span class="n">{len(entries)}</span><span class="k">decisions</span></div>
      <div><span class="n" id="n-answered">0</span><span class="k">answered</span></div>
      <div><span class="n">{len(quick)}</span><span class="k">safe to accept as recommended</span></div>
      <div><span class="n">{len(brief.get('conflicts', []))}</span><span class="k">places two answers collide</span></div>
    </div>
    <div class="bar" aria-hidden="true"><span id="bar"></span></div>
    <p class="notice" id="notice">{tier_line}. Each card below is one register item, in the order to decide
      them. Pick an option and it is saved at once; add a note where the option needs a number or a
      condition. The register itself does not change until Claude reads your answers back.</p>
  </header>

  <section class="panelbox" aria-labelledby="quick-h">
    <h2 id="quick-h">Safe to accept as recommended</h2>
    <p class="blurb">Where the recommendation is to keep what the build already does, with high
      confidence. Accepting records the recommended option for each one you have not answered yet.</p>
    <ul class="plist">{quick_rows}</ul>
    <div class="nb" style="margin-top:10px">
      <button type="button" class="btn" id="accept-quick" disabled>Accept these recommendations</button>
      <span class="lab" id="accept-state"></span>
    </div>
  </section>

  {f'''<details class="panelbox fold">
    <summary><h2>Where two answers collide <span class="fc">{len(brief.get('conflicts', []))}</span></h2></summary>
    <p class="blurb">Answering one of these changes the other. Each says how the brief resolved it.</p>
    <ul class="plist">{conflicts}</ul>
  </details>''' if conflicts else ''}

  {f'''<details class="panelbox fold">
    <summary><h2>Answer these together <span class="fc">{len(brief.get('groups', []))}</span></h2></summary>
    <p class="blurb">Each group turns on one underlying choice.</p>
    <ul class="plist">{groups}</ul>
  </details>''' if groups else ''}

  <nav class="filters" aria-label="Filter the decisions">{chips}
    <span class="answered" id="answered-line"></span>
  </nav>

  <main id="list">{''.join(cards)}
    <p class="empty" id="empty" hidden>Nothing in that filter.</p>
  </main>

  <footer>
    <p>Written by <code>tools/build_brief.py</code> from <code>docs/decisions/brief.json</code>. The
      brief was drafted from the register and the design document, every quote and number checked
      against its source, and merged; <code>tools/check_all.sh</code> fails if a quote stops matching
      the document or an open decision has no card.</p>
    <p>Your answers are kept in this page&rsquo;s own store, one per decision, and only you and
      editors can record them. Claude reads them back and makes each one a register, document or
      build change.</p>
  </footer>
</div>

<script>
(function () {{
  var cards = Array.prototype.slice.call(document.querySelectorAll(".decision"));
  var answers = {{}};
  var db = null, readOnly = false, queues = {{}};
  var notice = document.getElementById("notice");
  var filter = "all";
  try {{ filter = localStorage.getItem("brief-filter") || "all"; }} catch (e) {{}}

  function say(text, warn) {{
    notice.textContent = text;
    notice.className = "notice" + (warn ? " warn" : "");
  }}
  function controls(on) {{
    document.querySelectorAll(".decision input, .decision textarea, .decision button, #accept-quick")
      .forEach(function (el) {{ el.disabled = !on; }});
  }}
  function when(ms) {{
    try {{ return new Date(ms).toLocaleString([], {{ dateStyle: "medium", timeStyle: "short" }}); }}
    catch (e) {{ return ""; }}
  }}
  function paint() {{
    var done = 0;
    cards.forEach(function (card) {{
      var id = card.dataset.id, a = answers[id];
      card.dataset.answered = a && a.option ? "yes" : "no";
      if (a && a.option) done++;
      card.querySelectorAll('input[type="radio"]').forEach(function (r) {{
        r.checked = !!(a && a.option === r.value);
      }});
      var note = document.getElementById("n-" + id);
      if (note && document.activeElement !== note && !note.dataset.dirty) note.value = (a && a.note) || "";
      var st = document.getElementById("st-" + id);
      if (st && !st.dataset.busy) st.textContent = a && a.option
        ? "Answered " + a.option + (a.at ? " · " + when(a.at) : "") : "Not answered";
    }});
    document.getElementById("n-answered").textContent = done;
    document.getElementById("bar").style.width = (100 * done / cards.length) + "%";
    document.getElementById("answered-line").textContent = done + " of " + cards.length + " answered";
    apply();
  }}
  function matches(card, f) {{
    if (f === "all") return true;
    if (f === "open") return card.dataset.answered !== "yes";
    return card.dataset.tier === f;
  }}
  function apply() {{
    var shown = 0;
    cards.forEach(function (card) {{ var ok = matches(card, filter); card.hidden = !ok; if (ok) shown++; }});
    document.getElementById("empty").hidden = shown > 0;
    document.querySelectorAll(".chip").forEach(function (c) {{
      c.setAttribute("aria-pressed", c.dataset.filter === filter ? "true" : "false");
      var n = cards.filter(function (card) {{ return matches(card, c.dataset.filter); }}).length;
      document.getElementById("cn-" + c.dataset.filter).textContent = n;
    }});
  }}
  document.querySelectorAll(".chip").forEach(function (c) {{
    c.addEventListener("click", function () {{
      filter = c.dataset.filter;
      try {{ localStorage.setItem("brief-filter", filter); }} catch (e) {{}}
      apply();
    }});
  }});

  function refuse(e) {{
    if (e && e.code === "invalid_argument") {{
      readOnly = true;
      controls(false);
      say("You can read this brief. Only its owner and editors record answers.", true);
    }} else {{
      say("An answer could not be saved just now. Try it again in a moment.", true);
    }}
  }}
  // One write at a time per decision, in the order they were made.
  function write(id, body) {{
    var st = document.getElementById("st-" + id);
    if (st) {{ st.dataset.busy = "1"; st.textContent = "Saving…"; }}
    var ref = db.doc("answers/" + id);
    queues[id] = (queues[id] || Promise.resolve()).then(function () {{
      return body ? ref.set(body) : ref.delete();
    }}).then(function () {{
      if (st) delete st.dataset.busy;
      if (body) answers[id] = body; else delete answers[id];
      paint();
    }}, function (e) {{
      if (st) delete st.dataset.busy;
      paint();
      refuse(e);
    }});
    return queues[id];
  }}
  function current(id) {{
    var a = answers[id] || {{}};
    return {{ option: a.option || null, note: a.note || "", how: a.how || "picked" }};
  }}

  cards.forEach(function (card) {{
    var id = card.dataset.id;
    card.querySelectorAll('input[type="radio"]').forEach(function (r) {{
      r.addEventListener("change", function () {{
        if (!db || readOnly || !r.checked) return;
        var note = document.getElementById("n-" + id);
        write(id, {{ option: r.value, note: note ? note.value.trim() : "", how: "picked",
                     recommended: card.dataset.rec, at: Date.now() }});
      }});
    }});
    var note = document.getElementById("n-" + id);
    note.addEventListener("input", function () {{ note.dataset.dirty = "1"; }});
    card.querySelector(".save-note").addEventListener("click", function () {{
      if (!db || readOnly) return;
      var a = current(id);
      delete note.dataset.dirty;
      write(id, {{ option: a.option, note: note.value.trim(), how: a.how,
                   recommended: card.dataset.rec, at: Date.now() }});
    }});
    card.querySelector(".clear").addEventListener("click", function () {{
      if (!db || readOnly) return;
      note.value = "";
      delete note.dataset.dirty;
      write(id, null);
    }});
  }});

  var accept = document.getElementById("accept-quick");
  var armed = false;
  accept.addEventListener("click", function () {{
    if (!db || readOnly) return;
    var todo = cards.filter(function (c) {{ return c.dataset.quick === "yes" && !(answers[c.dataset.id] || {{}}).option; }});
    if (!todo.length) {{ document.getElementById("accept-state").textContent = "All already answered"; return; }}
    if (!armed) {{
      armed = true;
      accept.textContent = "Confirm: accept " + todo.length;
      return;
    }}
    armed = false;
    accept.disabled = true;
    var chain = Promise.resolve();
    todo.forEach(function (c) {{
      chain = chain.then(function () {{
        return write(c.dataset.id, {{ option: c.dataset.rec, note: "", how: "accepted as recommended",
                                      recommended: c.dataset.rec, at: Date.now() }});
      }});
    }});
    chain.then(function () {{
      accept.textContent = "Accept these recommendations";
      accept.disabled = readOnly;
      document.getElementById("accept-state").textContent = "Accepted " + todo.length;
    }});
  }});

  paint();
  var claude = window.claude;
  if (!claude || typeof claude.use !== "function") {{
    say("This copy of the brief is read-only: answers are saved only in the published page.", true);
    return;
  }}
  claude.use("db").then(function (store) {{
    if (!store) {{
      say("Answers cannot be saved in this view. The brief still reads in full.", true);
      return;
    }}
    db = store;
    controls(true);
    db.collection("answers").onSnapshot(function (snap) {{
      var next = {{}};
      snap.docs.forEach(function (d) {{ if (d.exists) next[d.id] = Object.assign({{}}, d.data()); }});
      answers = next;
      paint();
    }}, function () {{
      say("Saved answers cannot be shown right now. Reload the page to try again.", true);
    }});
  }});
}})();
</script>
"""


def main() -> int:
    brief = load()
    found = problems(brief)
    if "--check" in sys.argv:
        for p in found:
            print(f"  {p}")
        if found:
            print(f"docs/decisions/brief.json: {len(found)} problem(s)")
            return 1
        n = sum(len(e.get("quotes", [])) for e in brief["entries"].values())
        print(f"  decision brief: {len(brief['entries'])} entries, every open decision covered, "
              f"{n} quotes all in the document")
        return 0
    if found:
        for p in found:
            print(f"  {p}")
        raise SystemExit("the brief has problems; fix docs/decisions/brief.json first")
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(build(brief), encoding="utf-8")
    print(f"{OUT} — {len(brief['entries'])} decisions")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
