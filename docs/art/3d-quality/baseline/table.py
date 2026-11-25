"""Builds baseline.md from baseline/data/*.json (written by run.py)."""
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent

# budget: <shot>: T triangles (M mesh + O outline passes); S triangles in shadows; D draw calls, ...
LINE = re.compile(
    r"budget: \S+: (\d+) triangles \((\d+) mesh \+ (\d+) outline passes\); (\d+) triangles in shadows; (\d+) draw calls"
    r".*?; (\d+) triangles and (\d+) draw calls in other views; frame (\d+) triangles, (\d+) draw calls")


def budget(rec: dict) -> list:
    text = rec.get("budget") or ""
    m = LINE.search(text)
    if not m:
        # The shots without BudgetSplit print the renderer's frame totals only.
        a = re.match(r"draw calls (\d+), primitives (\d+)", text)
        if a:
            return ["-", "-", "-", "-", f"{int(a.group(1))}*", f"{int(a.group(2)):,}*"]
        a = re.match(r"triangles (\d+) draw calls (\d+) frame (\d+) prims (\d+) calls", text)
        if a:
            return [f"{int(a.group(1)):,}*", "-", "-", "-", f"{int(a.group(2))}*", f"{int(a.group(3)):,}*"]
        a = re.match(r"triangles (\d+) drawn now (\d+) draw calls (\d+) rendered (\d+) prims", text)
        if a:
            return [f"{int(a.group(1)):,}*", "-", "-", "-", f"{int(a.group(3))}*", f"{int(a.group(4)):,}*"]
        return ["-"] * 6
    t, mesh, outl, shad, dc, _o, _od, frame, _c = (int(x) for x in m.groups()[:9])
    other = int(m.group(6))
    return [f"{mesh:,}", f"{outl:,}", f"{shad:,}", f"{other:,}", f"{dc}", f"{frame:,}"]


def pct(x):
    return "-" if x is None else f"{x:.0%}"


def q(rec: dict) -> list:
    r = rec.get("measure")
    if not r:
        return ["-"] * 8
    q11 = r["Q11"]
    rate = lambda k: q11.get(k, {}).get("rating", "-")  # noqa: E731
    q2c = r["Q2"]["crew_least"]
    q2g = r["Q2"]["guards_least"]
    return [
        pct(r["Q1"]["band"]),
        f"{q2c if q2c is not None else '-'} / {q2g if q2g is not None else '-'}",
        "-" if r["Q3"]["worst"] is None else pct(r["Q3"]["worst"]),
        "-" if r["Q4"]["worst"] is None else f"{r['Q4']['worst']:.0%}",
        f"{r['Q5']['decoration_on_walkable']:.1%}",
        str(r["Q6"]["most"]),
        f"{rate('chosen')}; {rate('nearest_guard')}; {q11['largest_figure_share']:.0%}",
        f"{r['Q12']['figures_with_shadow']}/{r['Q12']['figures']}",
    ]


def write(path: Path) -> None:
    rows = []
    for f in sorted((HERE / "data").glob("*.json")):
        rec = json.loads(f.read_text())
        rows.append([f"`{rec['name']}`"] + budget(rec) + q(rec))
    head = ["Shot", "Mesh tri", "Outline tri", "Shadow tri", "Other-view tri", "Draw calls", "Frame tri",
            "Q1 band", "Q2 crew / guard pt", "Q3 worst", "Q4 least seen", "Q5 deco", "Q6 most", "Q11 chosen; guard; tallest",
            "Q12 shadowed"]
    out = ["# The 3D baseline", "",
           "Every 3D screen shot in `client/tests/shots/`, rendered at 1080 × 2340 on the Compatibility renderer",
           "(llvmpipe) and measured with the mask tool ([`mask.md`](mask.md)). Written by 3D0-M1-baseline.", "",
           "## Reproduce", "", "```", "python3 docs/art/3d-quality/baseline/run.py --jobs 2", "```", "",
           "It renders each shot (about two minutes each) into `/tmp/ruleborn_baseline/<shot>/`, keeps each shot's",
           "`budget:` line and `measure.json` in `baseline/data/`, and rewrites this file. `--no-render` rebuilds",
           "the table from `baseline/data/`; `--only a,b` runs some shots. `screen_defences` is shot with `TAB=0`.", "",
           "Budget columns are the shots' `budget:` line: mesh triangles, outline-pass triangles, shadow-map",
           "triangles, other views' triangles and the world views' draw calls (shadow passes included); the frame",
           "total is their sum. A `-` means the quality does not apply to that shot (no figures, or no world",
           "view) or the shot printed no line. A `*` marks a shot that prints the renderer's frame totals only (no",
           "split; `universe_*` print their world triangles in the first column). The mask tool needs the heist's",
           "`WorldView`: on every other shot Q1 to Q6, Q11 and Q12 read `-` (request M1-R2).", "",
           "| " + " | ".join(head) + " |", "|" + "---|" * len(head)]
    for r in rows:
        out.append("| " + " | ".join(r) + " |")
    out += ["", "Q1 band is the clear band of the screen; Q2 is the least crew member / guard in points;",
            "Q3 the worst share of a figure's pixels within 18 gray levels of the ground; Q4 the least visible",
            "share of a head or marker; Q5 decoration's share of walkable ground; Q6 the most markers on one",
            "object; Q11 the chosen crew member's and nearest guard's framing and the tallest figure's share of",
            "the height; Q12 figures with a shadow. The targets are in `plan.md`, section 4.", ""]
    path.write_text("\n".join(out))
