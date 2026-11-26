"""Builds baseline.md from baseline/data/*.json (written by run.py)."""
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent

# budget: <shot>: T triangles (M mesh + O outline passes); S triangles in shadows; D draw calls, ...
LINE = re.compile(
    r"budget: \S+: (\d+) triangles \((\d+) mesh \+ (\d+) outline passes\); (\d+) triangles in shadows; (\d+) draw calls"
    r".*?; (\d+) triangles and (\d+) draw calls in other views; frame (\d+) triangles, (\d+) draw calls")


# The table's columns. "View draw calls" is the world view's own figure (shadow
# passes included); "Frame draw calls" is the whole frame's, plan Q14's figure.
HEAD = ["Shot", "Mesh tri", "Outline tri", "Shadow tri", "Other-view tri", "View draw calls", "Frame tri",
        "Frame draw calls", "Q1 band", "Q2 crew / guard pt", "Q3 worst", "Q4 least seen", "Q5 deco", "Q6 most",
        "Q11 chosen; guard; tallest", "Q12 shadowed"]


def budget(rec: dict) -> list:
    """The budget columns of HEAD, from the shot's budget line."""
    text = rec.get("budget") or ""
    m = LINE.search(text)
    if not m:
        # The shots without BudgetSplit print the renderer's frame totals only.
        a = re.match(r"draw calls (\d+), primitives (\d+)", text)
        if a:
            return ["-", "-", "-", "-", "-", f"{int(a.group(2)):,}*", f"{int(a.group(1))}*"]
        a = re.match(r"triangles (\d+) draw calls (\d+) frame (\d+) prims (\d+) calls", text)
        if a:
            return [f"{int(a.group(1)):,}*", "-", "-", "-", f"{int(a.group(2))}*", f"{int(a.group(3)):,}*",
                    f"{int(a.group(4))}*"]
        a = re.match(r"triangles (\d+) drawn now (\d+) draw calls (\d+) rendered (\d+) prims (\d+) calls", text)
        if a:
            return [f"{int(a.group(1)):,}*", "-", "-", "-", f"{int(a.group(3))}*", f"{int(a.group(4)):,}*",
                    f"{int(a.group(5))}*"]
        return ["-"] * 7
    _t, mesh, outl, shad, dc, other, _od, frame, fdc = (int(x) for x in m.groups())
    return [f"{mesh:,}", f"{outl:,}", f"{shad:,}", f"{other:,}", f"{dc}", f"{frame:,}", f"{fdc}"]


def pct(x):
    return "-" if x is None else f"{x:.0%}"


NOT_MEASURED = "n/m"

# Footnotes on measured values that come from the screen, not from the figures.
NOTES = {
    "screen_replay": "a",
    "screen_result": "b",
    "screen_observatory": "c",
}


def yn(x):
    return "-" if x is None else ("yes" if x else "no")


def q(rec: dict) -> list:
    r = rec.get("measure")
    if not r:
        return [NOT_MEASURED] * 8
    app = lambda k: r[k].get("applies", True)  # noqa: E731
    nm = lambda k, f: f(r[k]) if app(k) else NOT_MEASURED  # noqa: E731

    def q2(e):
        parts = [(e.get(k + "_least")) for k in ("crew", "guards")]
        if e.get("characters_least") is not None:
            return f"{e['characters_least']} (character)"
        return " / ".join("-" if p is None else str(p) for p in parts)

    def q5(e):
        n = e.get("buildings", 0)
        link = "-" if not n else yn(e.get("path_links_every_building"))
        return f"{e['decoration_on_walkable']:.1%}; links every building: {link}"

    def q11(e):
        rate = lambda k: e.get(k, {}).get("rating", "-")  # noqa: E731
        if "island" in e:
            return f"island {e['island']['rating']}"
        if "character" in e:
            return f"{e['character']['rating']}; tallest {e['largest_figure_share']:.0%}"
        return f"{rate('chosen')}; {rate('nearest_guard')}; {e['largest_figure_share']:.0%}"

    def q12(e):
        f = e.get("figures_with_shadow")
        figs = "-" if f is None else f"{f}/{e['figures']}"
        nb = len(e.get("building_foot_luma_ratio") or [])
        bld = "-" if e.get("buildings_with_shadow") is None else f"{e['buildings_with_shadow']}/{nb}"
        return f"figures {figs}; buildings {bld}; cliffs darker: {yn(e.get('cliffs_darker'))}"

    return [
        pct(r["Q1"]["band"]),
        nm("Q2", q2),
        nm("Q3", lambda e: "-" if e["worst"] is None else pct(e["worst"])),
        nm("Q4", lambda e: "-" if e["worst"] is None else f"{e['worst']:.0%}"),
        nm("Q5", q5),
        nm("Q6", lambda e: str(e["most"])),
        nm("Q11", q11),
        nm("Q12", q12),
    ]


def write(path: Path, data: Path = HERE / "data") -> None:
    rows = []
    for f in sorted(data.glob("*.json")):
        rec = json.loads(f.read_text())
        note = NOTES.get(rec["name"])
        name = f"`{rec['name']}`" + (f" ({note})" if note else "")
        rows.append([name] + budget(rec) + q(rec))
    head = HEAD
    out = ["# The 3D baseline", "",
           "Every 3D screen shot in `client/tests/shots/` (the list below), rendered on the Compatibility",
           "renderer (llvmpipe) and measured with the mask tool ([`mask.md`](mask.md)). Written by",
           "3D0-M1-baseline. The project's frame is 1080 × 2340; `screen_heist`, `screen_replay`,",
           "`screen_result` and `screen_laws` save their stills at that size, the others at the project",
           "window's half size, 540 × 1170. Triangle and draw-call counts do not depend on the size.", "",
           "## Reproduce", "",
           "In a fresh container, first set up the tools (`docs/guides/agent-brief.md`, \"Starting a session\") and",
           "build the client with `bash client/build.sh`; then:", "",
           "```", "python3 docs/art/3d-quality/baseline/run.py --jobs 2", "```", "",
           "It renders each shot (about two minutes each) into `/tmp/ruleborn_baseline/<shot>/` (or",
           "`$BASELINE_WORK/<shot>/`), keeps each shot's budget line and `measure.json` in `baseline/data/`, and",
           "rewrites this file. `--no-render` renders nothing and writes no data: it only rebuilds this file",
           "from `baseline/data/` (it exits 1 if that folder has no data file). `--only a,b` runs some shots. `screen_defences` is shot with `TAB=0`; `universe_map` and `universe_screen` are",
           "`universe_screens.gd` with `SCREEN=map` and `SCREEN=universe`. `screen_laws`, `universe_map` and",
           "`universe_screen` print no budget line of their own: `run.py` adds one to a copy of the script",
           "(`BudgetSplit.line` for the laws heist, the universe view's count for the other two), and leaves",
           "the script in `client/` as it is. It exits 1 if a shot fails (no work folder, no still, no budget",
           "line, a script error in the shot, a renderer shader that failed to start, a timeout, or the mask",
           "tool measured nothing for no known reason), and then keeps that shot's old data file. The mask",
           "tool's known limit (a shot it still cannot measure; none today) is reported, not a failure, except",
           "that every shot of the table is one the tool measures today, so on each of them the limit is a",
           "failure too. Each data file keeps its shot's verdict (`verdict`, `why`).",
           "`run.py`'s own tests, with no render:", "",
           "```", "python3 -m unittest discover -s docs/art/3d-quality/baseline -p 'test_*.py'", "```", "",
           "Two full runs in the same container agree on every figure but a few: `screen_laws` and",
           "`screen_replay` moved by a few dozen outline-pass triangles (48 and 32, under 0.1% of the frame),",
           "`screen_laws`' Q3 by 2 points (27% and 29%), and `screen_heist`'s shadow pixels by a few (Q12 the",
           "same). `screen_heist`'s cliff luma, in its data file only, moved by about 110 to 115 (110 in one run, 115",
           "in the other); its top luma is 115, so `cliffs_darker` there can read either way. Compare a rerun",
           "against this table at that tolerance.", "",
           "**The shader cache race.** Shots rendered side by side on a fresh shader cache (the first run in",
           "a container) can race to make the cache's folders; Godot then leaves a shader unstarted",
           "(`ShaderGLES3::initialize` errors in the log; the \"never freed\" notice at exit is not one)",
           "and the shot draws wrong, its ground black:",
           "a `screen_replay` rendered so read Q3 87%, against 40% alone. Which shot loses the race changes",
           "from run to run. `run.py` fails such a shot and renders it again alone, once the cache is made; a",
           "second failure fails the run.", "",
           "## Which shots count as 3D", "",
           "A row is a screen of the game that draws a 3D world: a `WorldView` (heist, replay, result, laws,",
           "realm, builder, curation, planner, scout, observatory, landing, defences), a character stage",
           "(character, roster, sage hall, forms, hatch, first) or the universe view (home, zoom, map,",
           "universe). Left out:", "",
           "- **Variants of `screen_heist`** (the same heist screen, island and camera): `heist_shot`,",
           "  `heist_budget`, `law_heist`, `law_heist_screen`, `style_frame_heist`, `uiq_heist_hud`,",
           "  `world_shot`. `screen_laws` is kept as a row: it weaves three laws into the island, so its",
           "  world differs.",
           "- **Sheets** (a model or a look on its own, not a screen): `creature_busts`, `creature_colour`,",
           "  `creature_forms`, `creature_heist`, `creature_lineup`, `creature_turntable`, `kit_buildings`,",
           "  `kit_features`, `kit_probe`, `kit_realm`, `look_backdrop`, `look_budget`, `look_realms`,",
           "  `law_crowns`, `law_gaits`, `law_signatures`, `icon_portraits`, `screen_portraits`, `screen_stage`.",
           "- **Motion and transitions** (clips or a wipe over another screen): `motion_*`, `uiq_motion`,",
           "  `universe_wipe`.",
           "- **Interface screens with a small 3D preview** (no world view): `law_card`, `law_weaving`.",
           "- **No 3D at all**: `auth_panel`, `law_a11y_only`, `screen_meta`, `screen_settings`, `ui_*`.",
           "- **Helpers and tests**, not shots: `budget_split`, `budget_split_tests`, `law_run_tests`,",
           "  `motion_rig`, `screen_shots`, `shot_data`, `shot_kit`, `stage_fixtures`, `universe_sample`.", "",
           "## The table", "",
           "Budget columns are the shots' `budget:` line: mesh triangles, outline-pass triangles, shadow-map",
           "triangles, other views' triangles and the world view's draw calls (shadow passes included); the frame",
           "triangles are their sum, and the frame draw calls are the whole frame's, the panels' and other",
           "views' included: plan Q14's figure (at most 120). A `*` marks a shot that prints the renderer's frame",
           "totals only (no split; `universe_*` print their universe view's triangles, in the first column, and",
           "its draw calls, in View draw calls); a `-` in a budget column is a figure that shot does not print.", "",
           f"**`{NOT_MEASURED}` means not measured**, and only where the mask tool says the screen cannot be",
           "([`mask.md`](mask.md), \"Each kind of screen\"; the reason is in each shot's `measure.json`):",
           "",
           "- **Realm screens** (`screen_realm`, `screen_planner`, `screen_scout`) draw no figures or markers,",
           "  so Q2, Q3, Q4 and Q6 are `n/m`; Q5, Q11 and Q12 are measured.",
           "- **Character stages** (`screen_character`, `screen_roster`, `screen_sage_hall`, `screen_forms`,",
           "  `screen_hatch`, `screen_first`) stand a figure on a plinth, with no ground, paths or world",
           "  markers: Q5 and Q6 are `n/m`; Q2 (the character's head), Q3, Q4, Q11 and Q12's figures are",
           "  measured.",
           "- **The universe view** (`universe_*`) draws islands, not figures or markers, and its islands float",
           "  over the sky with no ground to cast on: only Q1 and Q11 (the island) are measured.",
           "- **`screen_observatory`** draws no 3D world view on show: only Q1 is measured.",
           "",
           "In a measured row, a `-` means the shot has nothing to measure for that quality (Q3 with no figure",
           "in the clear; Q12's buildings with no building on ground in frame).", "",
           "| " + " | ".join(head) + " |", "|" + "---|" * len(head)]
    for r in rows:
        out.append("| " + " | ".join(r) + " |")
    out += ["",
            "(a) `screen_replay`: the replay's edge vignette is counted as cover. Its dark left and right edges",
            "(110 to 144 px each, of 1080) cover a fifth or more of every row, so Q1's band reads 0% (62% of the",
            "pixels read as cover, panels and vignette together); Q1 measures the vignette, not the world. Q4's",
            "0% is real: crew member `c1`'s head (rows 1463 to 1484) lies under the \"Golden replay\" panel.",
            "",
            "(b) `screen_result`: the result screen draws a full-screen backdrop over the world, so the mask tool",
            "reads every pixel as cover (`panels_share` 1.0). Q1 0%, Q3's `-`, Q4 0%, Q5 0.0% and Q11's",
            "\"under panel\" all come from that backdrop (the still shows the world only faintly through it);",
            "Q12 is read from each figure's own mask, not from the still.",
            "",
            "(c) `screen_observatory`: the screen has no world view on show (0 triangles, 0 draw calls in it).",
            "`StageThumbs` draws the cards' universes earlier, in a hidden offscreen `StageView`, and shows them",
            "as pictures, so the measured frame is the panels only, all under other views.",
            "",
            "Q1 band is the clear band of the screen; Q2 is the least crew member / guard in points;",
            "Q3 the worst share of a figure's pixels within 18 gray levels of the ground; Q4 the least visible",
            "share of a head or marker; Q5 decoration's share of walkable ground; Q6 the most markers on one",
            "object; Q11 the chosen crew member's and nearest guard's framing and the tallest figure's share of",
            "the height (the island's framing on a realm or universe screen, the character's on a stage). Q5 reads",
            "decoration's share, then `links every building` (`yes` when one path reaches every building, `no`",
            "when one does not, `-` with no building in frame). Q12 reads `figures` and `buildings` as shadowed",
            "over measured (a building is measured when its foot has ground in frame) and `cliffs darker` as",
            "`yes` when the cliff faces are darker than the island's top. The targets are in `plan.md`,",
            "section 4.", ""]
    path.write_text("\n".join(out))
