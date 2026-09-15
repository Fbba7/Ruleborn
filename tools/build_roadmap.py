#!/usr/bin/env python3
"""Render the roadmap to a static HTML page.

    python3 tools/build_roadmap.py

Reads tools/roadmap.py and tools/audit_register.py, and writes
docs/roadmap/index.html. Every task is present in the markup, so the page reads
correctly with no JavaScript; the script only filters.

Progress is computed from the register, never typed. A task that names register
kinds or severities reports how many of those items have moved past `open`, and
how many have been signed off — which are deliberately different numbers.
"""

import datetime
import html
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from audit_register import REGISTER, V3          # noqa: E402
from roadmap import NOT_YET, STAGES              # noqa: E402

OUT = pathlib.Path(__file__).resolve().parent.parent / "docs" / "roadmap" / "index.html"

STATUS = {
    "done":    ("Done",           "st-done"),
    "doing":   ("Under way",      "st-doing"),
    "ready":   ("Ready to start", "st-ready"),
    "blocked": ("Blocked",        "st-blocked"),
    "yours":   ("Waiting on you", "st-yours"),
}

OWNER = {"claude": "from here", "you": "needs you"}

#: A register item has moved past "recorded" once it has a drafted resolution.
DRAFTED = ("proposed", "adopted", "done", "fixed")
#: ...and is finished only once it is a decision in the design document itself.
SETTLED = ("adopted", "done", "fixed")


def status_of(item: dict) -> str:
    """An item's status, with what v3.0 did about it taking precedence."""
    return V3.get(item["id"], {}).get("status") or item.get("status", "open")


def esc(text: str) -> str:
    return html.escape(text, quote=False)


def anchor(task_id: str) -> str:
    """Task ids carry a dot, which is a class separator in a CSS selector.

    `id="T0.1"` is legal HTML and browsers resolve `#T0.1` for navigation, but
    `querySelector("#T0.1")` throws — so anything scripted against the page
    breaks silently. Anchors use a hyphen; the visible id keeps its dot.
    """
    return task_id.replace(".", "-")


def tracked(task: dict) -> list[dict]:
    """The register items whose progress this task reports."""
    kinds = task.get("register_kinds")
    severities = task.get("register_severity")
    ids = task.get("register")
    out = []
    for item in REGISTER:
        if ids and item["id"] in ids:
            out.append(item)
        elif kinds and item["kind"] in kinds:
            out.append(item)
        elif severities and item["severity"] in severities \
                and item["kind"] != "deviation":
            out.append(item)
    return out


def progress_html(task: dict) -> str:
    items = tracked(task)
    if not items:
        return ""
    total = len(items)
    drafted = sum(1 for i in items if status_of(i) in DRAFTED)
    settled = sum(1 for i in items if status_of(i) in SETTLED)
    pct = 100 * drafted / total
    settled_pct = 100 * settled / total
    ids = " ".join(sorted(i["id"] for i in items))
    return f"""
        <div class="prog" title="{esc(ids)}">
          <div class="bar">
            <span class="fill" style="width:{pct:.1f}%"></span>
            <span class="fill settled" style="width:{settled_pct:.1f}%"></span>
          </div>
          <p class="prog-n"><strong>{drafted} of {total}</strong> drafted &middot;
             <strong>{settled}</strong> signed off</p>
        </div>"""


def task_html(task: dict, by_id: dict) -> str:
    label, cls = STATUS[task["status"]]
    blocked_by = task.get("blocked_by") or []
    blockers = ""
    if blocked_by:
        names = ", ".join(
            f'<a href="#{anchor(b)}">{esc(b)}</a> '
            f'{esc(by_id[b]["title"].split(" — ")[0])}'
            for b in blocked_by
        )
        blockers = f'<p class="blockers">After {names}</p>'
    gate = task.get("gate")
    evidence = task.get("evidence")
    if evidence and evidence.startswith("http"):
        ev = f'<a href="{esc(evidence)}">{esc(evidence)}</a>'
    elif evidence:
        ev = f"<code>{esc(evidence)}</code>"
    else:
        ev = ""
    return f"""
      <article class="task {cls}" id="{anchor(task['id'])}"
               data-status="{task['status']}" data-owner="{task['owner']}">
        <header class="task-head">
          <span class="tid">{esc(task['id'])}</span>
          <h3>{esc(task['title'])}</h3>
          <span class="status {cls}">{label}</span>
          <span class="owner o-{task['owner']}">{OWNER[task['owner']]}</span>
        </header>
        {f'<p class="detail">{task["detail"]}</p>' if task.get("detail") else ''}
        {progress_html(task)}
        {f'<p class="gate"><span class="glabel">Passes when</span> {gate}</p>' if gate else ''}
        {f'<p class="evidence"><span class="glabel">Check it at</span> {ev}</p>' if ev else ''}
        {blockers}
      </article>"""


def validate(tasks: list[dict], by_id: dict) -> None:
    """A roadmap that contradicts itself is worse than none.

    Caught here rather than by reading the page: T1.8 was marked `ready` while
    listing a blocker, which is exactly the sort of thing a roadmap acquires as
    it is edited.
    """
    problems = []
    for task in tasks:
        blockers = task.get("blocked_by") or []
        for b in blockers:
            if b not in by_id:
                problems.append(f"{task['id']} is blocked by unknown task {b}")
                continue
            if by_id[b]["status"] != "done" and task["status"] in ("ready", "done"):
                problems.append(
                    f"{task['id']} is {task['status']!r} but waits on {b}, "
                    f"which is {by_id[b]['status']!r}")
        if task["status"] == "blocked" and not blockers:
            problems.append(f"{task['id']} is blocked by nothing")
        if task["status"] == "yours" and task["owner"] != "you":
            problems.append(f"{task['id']} is 'waiting on you' but owned by claude")
    if problems:
        raise SystemExit("roadmap is inconsistent:\n  " + "\n  ".join(problems))


def build() -> str:
    tasks = [t for s in STAGES for t in s["tasks"]]
    by_id = {t["id"]: t for t in tasks}
    validate(tasks, by_id)

    counts = {k: sum(1 for t in tasks if t["status"] == k) for k in STATUS}
    yours = [t for t in tasks if t["owner"] == "you"]
    yours_now = [t for t in yours if t["status"] in ("yours", "ready")]
    today = datetime.date.today().strftime("%d %B %Y")

    reg_total = len(REGISTER)
    reg_drafted = sum(1 for i in REGISTER if status_of(i) in DRAFTED)
    reg_settled = sum(1 for i in REGISTER if status_of(i) in SETTLED)

    stage_html = ""
    for stage in STAGES:
        st = stage["tasks"]
        done = sum(1 for t in st if t["status"] == "done")
        stage_html += f"""
      <section class="stage" id="{stage['id']}">
        <div class="stage-head">
          <span class="sid">{esc(stage['id'])}</span>
          <div>
            <h2>{esc(stage['title'])}</h2>
            <p class="sub">{stage['subtitle']}</p>
          </div>
          <span class="scount">{done}/{len(st)}</span>
        </div>
        <p class="blurb">{esc(stage['blurb'])}</p>
        {''.join(task_html(t, by_id) for t in st)}
      </section>"""

    chips = "".join(
        f'<button class="chip" data-filter="status:{k}">{esc(label)}'
        f'<span class="n">{counts[k]}</span></button>'
        for k, (label, _) in STATUS.items() if counts[k]
    )

    not_yet = "".join(
        f'<li><strong>{esc(t)}</strong> &mdash; {esc(why)}</li>' for t, why in NOT_YET
    )

    yours_list = "".join(
        f'<li><a href="#{anchor(t["id"])}">{esc(t["id"])}</a> '
        f'{esc(t["title"])}</li>'
        for t in yours_now
    )

    return f"""<title>Ruleborn Roadmap</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Marcellus&family=IBM+Plex+Sans:wght@400;500;600&family=IBM+Plex+Mono:wght@400;500&display=swap">

<style>
  /* Same palette and typefaces as the audit register: the two pages are one
     project and should read that way. */
  :root {{
    --ground: #FCFBFF; --raised: #FFFFFF;
    --ink: #221C3A; --muted: #6E6685; --faint: #958CAD;
    --rule: #E6E2EE; --rule-strong: #D3CCE3;
    --done: #2E7D5B; --doing: #1F6F83; --ready: #A77410;
    --blocked: #958CAD; --yours: #C0304A;
    --accent: #7A46C8;
    color-scheme: light;
  }}
  @media (prefers-color-scheme: dark) {{
    :root:not([data-theme="light"]) {{
      --ground: #17122C; --raised: #1E1839;
      --ink: #EDE9F8; --muted: #A79FC4; --faint: #7E76A0;
      --rule: #2E2650; --rule-strong: #3D3466;
      --done: #5CC46A; --doing: #3CC6D8; --ready: #F2B43C;
      --blocked: #7E76A0; --yours: #E2536B;
      --accent: #B18CF5;
      color-scheme: dark;
    }}
  }}
  :root[data-theme="dark"] {{
    --ground: #17122C; --raised: #1E1839;
    --ink: #EDE9F8; --muted: #A79FC4; --faint: #7E76A0;
    --rule: #2E2650; --rule-strong: #3D3466;
    --done: #5CC46A; --doing: #3CC6D8; --ready: #F2B43C;
    --blocked: #7E76A0; --yours: #E2536B;
    --accent: #B18CF5;
    color-scheme: dark;
  }}

  [hidden] {{ display: none !important; }}
  * {{ box-sizing: border-box; }}

  body {{
    margin: 0; background: var(--ground); color: var(--ink);
    font-family: "IBM Plex Sans", system-ui, -apple-system, sans-serif;
    font-size: 15.5px; line-height: 1.6; -webkit-font-smoothing: antialiased;
  }}
  .wrap {{ max-width: 800px; margin: 0 auto; padding: 40px 20px 72px; }}

  h1, h2 {{ font-family: Marcellus, Georgia, serif; font-weight: 400; text-wrap: balance; }}
  h1 {{ font-size: clamp(30px, 7vw, 42px); line-height: 1.1; margin: 0 0 6px; }}
  h2 {{ font-size: 22px; margin: 0; line-height: 1.25; }}
  h3 {{ font-family: inherit; font-size: 16px; font-weight: 600; margin: 0;
        line-height: 1.35; text-wrap: balance; }}
  p {{ margin: 0; }}
  a {{ color: var(--accent); }}

  .eyebrow {{ font-family: "IBM Plex Mono", monospace; text-transform: uppercase;
              letter-spacing: 0.16em; font-size: 11px; color: var(--accent); margin: 0 0 10px; }}
  .lede {{ color: var(--muted); font-size: 17px; max-width: 62ch; margin-top: 14px; }}

  .summary {{ display: flex; flex-wrap: wrap; margin: 30px 0 0;
              border-top: 1px solid var(--rule); border-bottom: 1px solid var(--rule);
              padding-block: 14px; }}
  .summary div {{ flex: 1 1 104px; padding-right: 14px; }}
  .summary .n {{ font-family: "IBM Plex Mono", monospace; font-size: 23px; font-weight: 500;
                 font-variant-numeric: tabular-nums; display: block; line-height: 1.2; }}
  .summary .k {{ font-size: 12.5px; color: var(--muted); }}

  .callout {{ border: 1px solid var(--yours); border-radius: 8px;
              padding: 16px 18px; margin-top: 28px; }}
  .callout h2 {{ font-size: 19px; color: var(--yours); }}
  .callout ul {{ margin: 10px 0 0; padding-left: 20px; }}
  .callout li {{ margin-bottom: 4px; }}
  .callout li a {{ font-family: "IBM Plex Mono", monospace; font-size: 12.5px;
                   margin-right: 6px; }}

  .filters {{ position: sticky; top: 0; background: var(--ground); z-index: 5;
              display: flex; flex-wrap: wrap; gap: 7px; padding-block: 14px;
              margin-bottom: 8px; border-bottom: 1px solid var(--rule); }}
  .chip {{ font: inherit; font-size: 13px; font-weight: 500; color: var(--muted);
           background: transparent; border: 1px solid var(--rule-strong);
           border-radius: 999px; padding: 6px 12px; cursor: pointer; min-height: 34px;
           display: inline-flex; align-items: center; gap: 7px; }}
  .chip:hover {{ color: var(--ink); border-color: var(--faint); }}
  .chip:focus-visible {{ outline: 2px solid var(--accent); outline-offset: 2px; }}
  .chip[aria-pressed="true"] {{ color: var(--ground); background: var(--ink);
                                border-color: var(--ink); }}
  .chip .n {{ font-family: "IBM Plex Mono", monospace; font-size: 11.5px;
              font-variant-numeric: tabular-nums; opacity: 0.65; }}

  .stage {{ margin-top: 46px; }}
  .stage-head {{ display: flex; align-items: flex-start; gap: 12px; margin-bottom: 8px; }}
  .stage-head > div {{ flex: 1 1 auto; }}
  .sid {{ font-family: "IBM Plex Mono", monospace; font-size: 12px; font-weight: 500;
          color: var(--ground); background: var(--ink); padding: 3px 8px;
          border-radius: 4px; margin-top: 3px; }}
  .sub {{ color: var(--muted); font-size: 14px; margin-top: 2px; }}
  .scount {{ font-family: "IBM Plex Mono", monospace; font-size: 13px;
             color: var(--faint); font-variant-numeric: tabular-nums; margin-top: 4px; }}
  .blurb {{ color: var(--muted); font-size: 14.5px; max-width: 62ch; margin-bottom: 20px; }}

  .task {{ border-left: 3px solid var(--blocked); padding-left: 18px; margin-bottom: 24px; }}
  .task.st-done {{ border-left-color: var(--done); }}
  .task.st-doing {{ border-left-color: var(--doing); }}
  .task.st-ready {{ border-left-color: var(--ready); }}
  .task.st-yours {{ border-left-color: var(--yours); }}

  .task-head {{ display: flex; align-items: baseline; gap: 9px; flex-wrap: wrap;
                margin-bottom: 7px; }}
  .task-head h3 {{ flex: 1 1 240px; }}
  .tid {{ font-family: "IBM Plex Mono", monospace; font-size: 11.5px; font-weight: 500;
          color: var(--ground); background: var(--blocked); padding: 2px 7px;
          border-radius: 4px; }}
  .st-done .tid {{ background: var(--done); }}
  .st-doing .tid {{ background: var(--doing); }}
  .st-ready .tid {{ background: var(--ready); }}
  .st-yours .tid {{ background: var(--yours); }}

  .status {{ font-family: "IBM Plex Mono", monospace; font-size: 11px;
             letter-spacing: 0.06em; text-transform: uppercase; white-space: nowrap;
             color: var(--faint); }}
  .status.st-done {{ color: var(--done); }}
  .status.st-doing {{ color: var(--doing); }}
  .status.st-ready {{ color: var(--ready); }}
  .status.st-yours {{ color: var(--yours); }}
  .owner {{ font-family: "IBM Plex Mono", monospace; font-size: 10.5px;
            letter-spacing: 0.05em; color: var(--faint);
            border: 1px solid var(--rule-strong); border-radius: 3px; padding: 0 5px;
            white-space: nowrap; }}
  .owner.o-you {{ color: var(--yours); border-color: var(--yours); }}

  .detail {{ max-width: 66ch; overflow-wrap: break-word; }}
  .task strong {{ font-weight: 600; }}
  .task em {{ font-style: italic; }}
  code {{ font-family: "IBM Plex Mono", monospace; font-size: 0.88em;
          background: var(--rule); padding: 1px 5px; border-radius: 3px;
          overflow-wrap: anywhere; }}

  .prog {{ margin-top: 11px; max-width: 420px; }}
  .bar {{ position: relative; height: 7px; border-radius: 4px; background: var(--rule);
          overflow: hidden; }}
  .fill {{ position: absolute; inset: 0 auto 0 0; background: var(--doing);
           border-radius: 4px; }}
  .fill.settled {{ background: var(--done); }}
  .prog-n {{ font-size: 12.5px; color: var(--muted); margin-top: 5px;
             font-variant-numeric: tabular-nums; }}

  .gate, .evidence, .blockers {{ font-size: 13.5px; color: var(--muted);
                                 margin-top: 8px; max-width: 66ch; }}
  .glabel {{ font-family: "IBM Plex Mono", monospace; font-size: 10.5px;
             text-transform: uppercase; letter-spacing: 0.07em; color: var(--faint);
             margin-right: 6px; }}
  .blockers {{ color: var(--faint); font-size: 13px; }}
  .blockers a {{ font-family: "IBM Plex Mono", monospace; font-size: 12px; }}

  .notyet {{ margin-top: 50px; border-top: 1px solid var(--rule); padding-top: 26px; }}
  .notyet ul {{ margin: 14px 0 0; padding-left: 20px; color: var(--muted);
                font-size: 14.5px; max-width: 64ch; }}
  .notyet li {{ margin-bottom: 8px; }}
  .notyet strong {{ color: var(--ink); }}

  .empty {{ color: var(--muted); font-size: 14.5px; padding: 26px 0; }}
  footer {{ margin-top: 52px; padding-top: 22px; border-top: 1px solid var(--rule);
            color: var(--muted); font-size: 13.5px; max-width: 64ch; }}
  footer p + p {{ margin-top: 10px; }}
  @media (prefers-reduced-motion: reduce) {{ * {{ transition: none !important; }} }}
</style>

<div class="wrap">
  <header>
    <p class="eyebrow">Ruleborn &middot; against design document v2.3</p>
    <h1>Roadmap</h1>
    <p class="lede">Every stage, what finishes it, and who it is waiting on.
      Progress against the register is computed rather than claimed &mdash; and
      <strong>drafted is not signed off</strong>, which is the distinction the
      two bars below keep separate.</p>
    <p class="lede">Read against <strong>design document v3.0</strong>, which
      took most of the audit and changed the plan underneath this page: both
      pre-code player tests are gone, replaced by the simulation harnesses in
      stage 0, and the build-willingness risk is designed out rather than
      measured (&sect;13.3, &sect;19.27).</p>

    <div class="summary">
      <div><span class="n">{counts['done']}</span><span class="k">tasks done</span></div>
      <div><span class="n">{counts['doing'] + counts['ready']}</span><span class="k">live now</span></div>
      <div><span class="n">{len(yours_now)}</span><span class="k">waiting on you</span></div>
      <div><span class="n">{reg_drafted}/{reg_total}</span><span class="k">register items drafted</span></div>
      <div><span class="n">{reg_settled}</span><span class="k">signed off</span></div>
      <div><span class="n">{today.split()[0]} {today.split()[1][:3]}</span><span class="k">last generated</span></div>
    </div>

    <div class="callout">
      <h2>What only you can do</h2>
      <ul>{yours_list}</ul>
    </div>
  </header>

  <nav class="filters" aria-label="Filter the roadmap">
    <button class="chip" data-filter="all" aria-pressed="true">Everything<span class="n">{len(tasks)}</span></button>
    <button class="chip" data-filter="owner:you">Yours<span class="n">{len(yours)}</span></button>
    {chips}
  </nav>

  <main id="list">{stage_html}</main>

  <p class="empty" id="empty" hidden>Nothing matches that filter.</p>

  <section class="notyet">
    <h2>Not blocked, and still not yet</h2>
    <p class="blurb">These look available. Starting any of them now spends work
      that a decision above will throw away.</p>
    <ul>{not_yet}</ul>
  </section>

  <footer>
    <p>Generated from <code>tools/roadmap.py</code> and
       <code>tools/audit_register.py</code> by
       <code>python3 tools/build_roadmap.py</code>. The repository is the source
       of truth; this page is a view of it.</p>
    <p>The register behind the progress bars is at the
       <a href="https://claude.ai/artifact/8m5MgpjWfFurnfwc6b76sN">audit register</a>,
       and the prototype the first stage depends on is
       <a href="https://claude.ai/artifact/3jW7Zg1rTrzR6CF3cEVp2E">here</a>.</p>
  </footer>
</div>

<script>
  (function () {{
    var chips = Array.prototype.slice.call(document.querySelectorAll(".chip"));
    var tasks = Array.prototype.slice.call(document.querySelectorAll(".task"));
    var stages = Array.prototype.slice.call(document.querySelectorAll(".stage"));
    var empty = document.getElementById("empty");
    var KEY = "ruleborn-roadmap-filter";

    function apply(filter) {{
      var shown = 0;
      tasks.forEach(function (t) {{
        var ok = filter === "all"
          || (filter.indexOf("status:") === 0 && t.dataset.status === filter.slice(7))
          || (filter.indexOf("owner:") === 0 && t.dataset.owner === filter.slice(6));
        t.hidden = !ok;
        if (ok) shown++;
      }});
      stages.forEach(function (s) {{
        var any = Array.prototype.slice.call(s.querySelectorAll(".task"))
          .some(function (t) {{ return !t.hidden; }});
        s.hidden = !any;
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
    tasks = [t for s in STAGES for t in s["tasks"]]
    counts = {}
    for t in tasks:
        counts[t["status"]] = counts.get(t["status"], 0) + 1
    print(f"{OUT} — {len(STAGES)} stages, {len(tasks)} tasks {counts}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
