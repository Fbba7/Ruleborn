// FX1-12-tools-ui: the UI tools' findings of docs/security/audit-2026-11/tools.md
// (FX1-T-06, 07, 13, 14, 15, 16, 18 and 19), each moved out of the stillOpen
// list in fix_fx1_audit_tools_proofs.mjs into a plain test.
//
// Like the proofs, every test runs the repository's own tool as it is on disk,
// against a planted input in a temporary folder. Nothing is written inside the
// repository: a tool that writes is pointed at a copy.

import assert from "node:assert/strict";
import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { join } from "node:path";
import { test } from "node:test";

import { REPO, TOOLS, copyIn, py, run, scratch } from "./fix_fx1_audit_tools_proofs.mjs";

test("FX1-T-06: build_tokens.mjs --check fails on a stale tokens.css under a path with a space", () => {
  const dir = scratch({}, "fx1 tools ui ");
  copyIn(dir, "art/ui/board/build_tokens.mjs");
  copyIn(dir, "client/ui/tokens.json");
  writeFileSync(join(dir, "art/ui/board/tokens.css"), "junk\n");
  const tool = join(dir, "art/ui/board/build_tokens.mjs");
  const stale = run("node", [tool, "--check"], dir);
  assert.notEqual(stale.code, 0, `--check passed a junk tokens.css:\n${stale.out}`);
  // And it still builds there, and then passes its own check.
  const build = run("node", [tool], dir);
  assert.equal(build.code, 0, build.out);
  assert.notEqual(readFileSync(join(dir, "art/ui/board/tokens.css"), "utf8"), "junk\n", "no tokens.css was written");
  assert.equal(run("node", [tool, "--check"], dir).code, 0, "--check refused the file it built");
});

test("FX1-T-07: check_screens.py counts a texture loaded with single quotes or an upper-case extension", () => {
  const r = py(`
import check_screens as c
print(json.dumps([len(c.count_file_text(t)["texture"]) for t in (
  "var t = load('res://world/a.png')\\n", 'var t = preload("res://world/a.PNG")\\n',
  "var t = load('res://world/a.JPeG')\\n", 'var s = load("res://scripts/a.gd")\\n',
  "var t = load('res://world/a.png\\")\\n")]))`, ["tools/ui_bake"]);
  // The last line's quotes do not match: no load of a texture.
  assert.deepEqual(r.value, [1, 1, 1, 0, 0], `texture counts: ${r.out}`);
});

test("FX1-T-13: bake.js paginate keeps every page within MAX_SIDE", () => {
  const require = createRequire(import.meta.url);
  const bake = require(join(TOOLS, "ui_bake", "bake.js"));
  const pieces = [{ name: "a", w: 2000, h: 1021 }, { name: "b", w: 2000, h: 1020 }, { name: "c", w: 2000, h: 100 }];
  const pages = bake.paginate(pieces, 1024);
  const heights = pages.map((p) => p.height);
  assert.ok(heights.every((h) => h <= 2048), `page heights ${JSON.stringify(heights)}`);
  for (const p of pieces) {
    const at = pages.flatMap((pg) => (pg.places[p.name] ? [[pg, pg.places[p.name]]] : []));
    assert.equal(at.length, 1, `${p.name} placed ${at.length} times`);
    const [pg, place] = at[0];
    assert.ok(place.y + p.h <= pg.height && place.x + p.w <= pg.width, `${p.name} runs off its page`);
  }
});

test("FX1-T-14: check_screens.py --root fails on a folder with no screens in it", () => {
  const r = py(`
import io, contextlib, os, tempfile, check_screens as c
with contextlib.redirect_stdout(io.StringIO()):
    empty = c.main(["--root", tempfile.mkdtemp()])
    gone = c.main(["--root", "/nonexistent/fx1-t-14"])
print(json.dumps([empty, gone]))`, ["tools/ui_bake"]);
  assert.deepEqual(r.value, [1, 1], `[an empty --root, a missing --root]: ${r.out}`);
});

test("FX1-T-15: check_screens.py counts a fill that is cleared only on one branch", () => {
  const r = py(`
import check_screens as c
branch = "func f():\\n\\tvar box := StyleBoxFlat.new()\\n\\tif flag:\\n\\t\\tbox.draw_center = false\\n"
plain = "func f():\\n\\tvar box := StyleBoxFlat.new()\\n\\tbox.bg_color = Color.RED\\n\\n\\tbox.draw_center = false\\n"
print(json.dumps([len(c.count_file_text(t)["fill"]) for t in (branch, plain)]))`, ["tools/ui_bake"]);
  // The second clears it on every path: still excused.
  assert.deepEqual(r.value, [1, 0], `[cleared in an if, cleared after]: ${r.out}`);
});

/** budget_shots.main(argv) with Godot faked: `home` recorded at
 *  `homeRecorded` draw calls, a new screen with none, every shot measured at
 *  40. [exit code, whether newscreen's figures were written]. */
function budgetShots(argv, homeRecorded) {
  return py(`
import io, contextlib, budget_shots as b
data = {"shots": {"limits": {"draw_calls_below": 150, "texture_bytes_max": 25165824, "contrast_floor": 4.5},
        "screens": {"home": {"script": "client/tests/shots/home.gd"}, "newscreen": {"script": "client/tests/shots/new.gd"}},
        "recorded": {f"home/{m}": {"draw_calls": ${homeRecorded}, "texture_bytes": 100, "words_below": 0} for m in b.MODES}}}
b.load_budgets = lambda: data
written = []
b.write_budgets = lambda d: written.append(json.loads(json.dumps(d)))
b.subprocess.run = lambda *a, **k: None
got = {"draw_calls": 40, "texture_bytes": 100, "words_below": 0, "words": 10, "font_cache_bytes": 0, "worst_ratio": 7.0, "below": []}
b.shoot = lambda key, *a: (dict(got), "log")
with contextlib.redirect_stdout(io.StringIO()) as out:
    rc = b.main(${JSON.stringify(argv)})
print(out.getvalue(), file=sys.stderr)
print(json.dumps([rc, bool(written) and any(k.startswith("newscreen/") for k in written[-1]["shots"]["recorded"])]))`, ["tools/ui_bake"]);
}

test("FX1-T-16: budget_shots.py --record records a screen that has no figures yet", () => {
  const r = budgetShots(["--record"], 50);
  assert.deepEqual(r.value, [0, true], `--record refused a new screen: ${r.out}`);
  // Without --record the new screen still fails, and --record still refuses a
  // rise on a recorded screen.
  assert.deepEqual(budgetShots([], 50).value, [1, false], "a screen with no figures passed");
  assert.deepEqual(budgetShots(["--record"], 30).value, [1, false], "--record raised home's figures");
});

test("FX1-T-18: golden.py fails when labels-blind.md is missing", () => {
  const r = py(`
import io, contextlib, pathlib, golden as g
def rc_of(f):
    try:
        with contextlib.redirect_stdout(io.StringIO()):
            rc = f()
    except SystemExit as e:
        rc = e.code
    return rc if isinstance(rc, int) else (0 if rc is None else 1)
here = rc_of(g.check)
g.BLIND = pathlib.Path("/nonexistent/labels-blind.md")
print(json.dumps([here, rc_of(g.check)]))`, ["tools/ui_gate"]);
  assert.deepEqual(r.value, [0, 1], `[the real golden set, labels-blind.md missing]: ${r.out}`);
});

test("FX1-T-19: sheet.py crops writes one crop per name, a name with a slash included", () => {
  const out = scratch();
  const shot = join(REPO, "art/ui/board/board.shot.json");
  const r = run("python3", ["-B", "-I", join(TOOLS, "ui_gate", "sheet.py"), "crops", shot, out], out);
  assert.equal(r.code, 0, `crops failed:\n${r.out.slice(-600)}`);
  const names = new Set(JSON.parse(readFileSync(shot, "utf8")).controls.map((c) => c.name));
  assert.ok([...names].some((n) => n.includes("/")), "the shot has no name with a slash any more");
  const files = readdirSync(out);
  assert.equal(files.length, names.size, `${files.length} files for ${names.size} names: ${files.join(", ")}`);
  assert.ok(files.every((f) => f.endsWith(".png")), files.join(", "));
});
