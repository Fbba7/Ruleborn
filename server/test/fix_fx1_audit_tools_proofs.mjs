// FX1-7: the proofs of docs/security/audit-2026-11/tools.md, one per
// finding. Each proof states what should happen and throws an AssertionError
// while the finding stands. fix_fx1_audit_tools.test.mjs wraps each in
// stillOpen; run one plain to see why it fails:
//
//   node -e 'import("./test/fix_fx1_audit_tools_proofs.mjs").then(async m => {
//     for (const p of m.PROOFS) try { await p.proof(); console.log("passes", p.id) }
//     catch (e) { console.log(p.id, e.message.split("\n")[0]) } })'
//
// Every proof runs the repository's own tool as it is on disk, against a
// planted input in a temporary folder. Nothing is written inside the
// repository: a tool that writes is pointed at a copy.

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { copyFileSync, cpSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

export const REPO = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
export const TOOLS = join(REPO, "tools");

/** A fresh temporary folder, with `files` ({relative path: text}) written. */
export function scratch(files = {}, prefix = "fx1-audit-tools-") {
  const dir = mkdtempSync(join(tmpdir(), prefix));
  for (const [rel, text] of Object.entries(files)) {
    mkdirSync(dirname(join(dir, rel)), { recursive: true });
    writeFileSync(join(dir, rel), text);
  }
  return dir;
}

/** Copy the repository's `rel` (a file or a folder) into `dir`. */
function copyIn(dir, rel) {
  mkdirSync(dirname(join(dir, rel)), { recursive: true });
  cpSync(join(REPO, rel), join(dir, rel), { recursive: true });
}

/** Run a command. NODE_TEST_CONTEXT is dropped: inherited from the test
 *  runner, it would make a nested `node --test` report to it instead of
 *  printing TAP. */
export function run(cmd, args, cwd, env = {}) {
  const base = { ...process.env };
  delete base.NODE_TEST_CONTEXT;
  const r = spawnSync(cmd, args, { cwd, encoding: "utf8", env: { ...base, ...env }, timeout: 120_000 });
  return { code: r.status, signal: r.signal, stdout: r.stdout ?? "", out: (r.stdout ?? "") + (r.stderr ?? "") };
}

/** Run Python isolated (-I: no cwd or PYTHONPATH on the path; -B: no .pyc
 *  written into the repository), with tools/ and `extra` folders importable,
 *  from a scratch folder. The code prints one JSON line last on stdout; it is
 *  parsed. */
export function py(code, extra = [], { fresh = false } = {}) {
  const path = [TOOLS, ...extra.map((p) => join(REPO, p))];
  const head = `import sys, json\nsys.path[:0] = ${JSON.stringify(path)}\n`;
  // fresh: look for no cached .pyc (as in a tree with no tools/__pycache__).
  const flags = fresh ? ["-X", `pycache_prefix=${scratch()}`] : [];
  const r = run("python3", ["-B", "-I", ...flags, "-c", head + code], scratch());
  // stdout only: a warning on stderr (FX2-R4) must not become the last line.
  const last = r.stdout.trim().split("\n").pop();
  let value;
  try { value = JSON.parse(last); } catch { value = undefined; }
  return { ...r, value };
}

const sleep = (ms) => Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);

/** A scratch git repository with tools/run_checks.sh, for its own runs. */
function checksRepo() {
  const dir = scratch();
  const repo = join(dir, "repo");
  const git = ["-c", "user.email=t@t", "-c", "user.name=t", "-c", "commit.gpgsign=false"];
  run("git", ["init", "--quiet", repo], dir);
  run("git", ["-C", repo, ...git, "commit", "--quiet", "--allow-empty", "-m", "one"], dir);
  mkdirSync(join(repo, "tools"), { recursive: true });
  copyFileSync(join(TOOLS, "run_checks.sh"), join(repo, "tools", "run_checks.sh"));
  const sha = run("git", ["-C", repo, "rev-parse", "HEAD"], dir).out.trim();
  mkdirSync(join(dir, "runs"));
  return { repo, sha, env: { CHECK_DIR: join(dir, "runs"), CHECK_UNSANDBOXED: "1", CHECK_BWRAP: "/nonexistent", CHECK_USER: "" } };
}

/** Start a run of `cmd` and poll `result` until it is no longer RUNNING. */
export function checkRun(cmd, settleMs = 0) {
  const c = checksRepo();
  const env = { ...c.env, CHECK_CMD: cmd };
  const sh = (...a) => run("bash", ["tools/run_checks.sh", ...a], c.repo, env);
  sh("start", c.sha);
  let out;
  for (let i = 0; i < 120; i++) {
    sleep(250);
    out = sh("result", c.sha).out;
    if (!out.includes('"state": "RUNNING"')) break;
  }
  if (settleMs) { sleep(settleMs); out = sh("result", c.sha).out; }
  return { ...c, sh, result: JSON.parse(out.trim().split("\n").pop()) };
}


export const PROOFS = [
  {
    id: "FX1-T-06",
    title: "build_tokens.mjs --check fails on a stale tokens.css under a path with a space",
    proof() {
      const dir = scratch({}, "fx1 audit tools ");
      copyIn(dir, "art/ui/board/build_tokens.mjs");
      copyIn(dir, "client/ui/tokens.json");
      writeFileSync(join(dir, "art/ui/board/tokens.css"), "junk\n");
      const r = run("node", [join(dir, "art/ui/board/build_tokens.mjs"), "--check"], dir);
      assert.notEqual(r.code, 0, `--check passed a junk tokens.css:\n${r.out}`);
    },
  },
  {
    id: "FX1-T-07",
    title: "check_screens.py counts a texture loaded with single quotes or an upper-case extension",
    proof() {
      const r = py(`
import check_screens as c
print(json.dumps([len(c.count_file_text(t)["texture"]) for t in (
  "var t = load('res://world/a.png')\\n", 'var t = preload("res://world/a.PNG")\\n')]))`, ["tools/ui_bake"]);
      assert.deepEqual(r.value, [1, 1], `textures uncounted: ${r.out}`);
    },
  },
  {
    id: "FX1-T-10",
    title: "three-digit ids are read as ids (check_findings_fresh, check_docs_consistency)",
    proof() {
      const r = py(`
import pathlib, tempfile
import check_findings_fresh as f, check_docs_consistency as d
p = pathlib.Path(tempfile.mkdtemp()) / "check_x.py"
p.write_text('\\ndef f():\\n    """D100. pins it."""\\n    return 0\\n')
f.check_files = lambda: [p]
print(json.dumps(["D100" in str(f.pinned_by_a_check()),
                  "D100" in str(d.spec_open_claims("- **D100** cap\\n- **D9** x\\n"))]))`);
      assert.deepEqual(r.value, [true, true], `[pinned_by_a_check, spec_open_claims] missed D100: ${r.out}`);
    },
  },
  {
    id: "FX1-T-11",
    title: "check_document.py fails a check that tracks an id the register does not hold",
    proof() {
      const r = py(`
import io, contextlib, check_document as c
L = c.Ledger(quiet=True)
with contextlib.redirect_stdout(io.StringIO()):
    L.check("x", False, "boom", tracks="C999")
    code = L.report()
print(json.dumps(code))`);
      assert.notEqual(r.value, 0, `a failed check tracking an unknown id passed: ${r.out}`);
    },
  },
  {
    id: "FX1-T-12",
    title: "check_one_fact_home finds a design fact restated by an annotated assignment",
    proof() {
      const r = py(`
import pathlib, tempfile, io, contextlib, check_docs_consistency as c
root = pathlib.Path(tempfile.mkdtemp())
(root / "tools").mkdir()
(root / "tools" / "zz_fact.py").write_text("HOLD_BAND: tuple = (30.0, 45.0)\\n")
c.ROOT = root
del c.problems[:]
with contextlib.redirect_stdout(io.StringIO()):
    c.check_one_fact_home()
print(json.dumps(any("HOLD_BAND" in str(p) for p in c.problems)))`);
      assert.equal(r.value, true, `an annotated restatement passed: ${r.out}`);
    },
  },
  {
    id: "FX1-T-13",
    title: "bake.js paginate keeps every page within MAX_SIDE",
    proof() {
      const require = createRequire(import.meta.url);
      const bake = require(join(TOOLS, "ui_bake", "bake.js"));
      const pages = bake.paginate([{ name: "a", w: 2000, h: 1021 }, { name: "b", w: 2000, h: 1020 },
        { name: "c", w: 2000, h: 100 }], 1024);
      const heights = pages.map((p) => p.height);
      assert.ok(heights.every((h) => h <= 2048), `page heights ${JSON.stringify(heights)}`);
    },
  },
  {
    id: "FX1-T-14",
    title: "check_screens.py --root fails on a folder with no screens in it",
    proof() {
      const r = py(`
import io, contextlib, tempfile, check_screens as c
with contextlib.redirect_stdout(io.StringIO()):
    code = c.main(["--root", tempfile.mkdtemp()])
print(json.dumps(code))`, ["tools/ui_bake"]);
      assert.notEqual(r.value, 0, `an empty --root passed: ${r.out}`);
    },
  },
  {
    id: "FX1-T-15",
    title: "check_screens.py counts a fill that is cleared only on one branch",
    proof() {
      const r = py(`
import check_screens as c
text = "func f():\\n\\tvar box := StyleBoxFlat.new()\\n\\tif flag:\\n\\t\\tbox.draw_center = false\\n"
print(json.dumps(len(c.count_file_text(text)["fill"])))`, ["tools/ui_bake"]);
      assert.equal(r.value, 1, `a fill cleared inside an if went uncounted: ${r.out}`);
    },
  },
  {
    id: "FX1-T-16",
    title: "budget_shots.py --record records a screen that has no figures yet",
    proof() {
      const r = py(`
import io, contextlib, budget_shots as b
data = {"shots": {"limits": {"draw_calls_below": 150, "texture_bytes_max": 25165824, "contrast_floor": 4.5},
        "screens": {"home": {"script": "client/tests/shots/home.gd"}, "newscreen": {"script": "client/tests/shots/new.gd"}},
        "recorded": {f"home/{m}": {"draw_calls": 50, "texture_bytes": 100, "words_below": 0} for m in b.MODES}}}
b.load_budgets = lambda: data
written = []
b.write_budgets = lambda d: written.append(json.loads(json.dumps(d)))
b.subprocess.run = lambda *a, **k: None
got = {"draw_calls": 40, "texture_bytes": 100, "words_below": 0, "words": 10, "font_cache_bytes": 0, "worst_ratio": 7.0, "below": []}
b.shoot = lambda key, *a: (dict(got), "log")
with contextlib.redirect_stdout(io.StringIO()) as out:
    rc = b.main(["--record"])
print(out.getvalue(), file=sys.stderr)
print(json.dumps([rc, bool(written) and any(k.startswith("newscreen/") for k in written[-1]["shots"]["recorded"])]))`, ["tools/ui_bake"]);
      assert.deepEqual(r.value, [0, true], `--record refused a new screen: ${r.out}`);
    },
  },
  {
    id: "FX1-T-17",
    title: "a self-test killed mid-run leaves the committed file it plants into unchanged",
    proof() {
      // Two self-tests write a plant into a committed file and restore it
      // only in `finally`; a kill in between leaves the plant. Each runs here
      // against a copy, killed at a step inside that window.
      const dir = scratch();
      copyIn(dir, "sim/status.json");
      copyIn(dir, "sim/systems.json");
      copyIn(dir, "content");
      const ui = py(`
import os, pathlib, build_audit, check_audit_ui
build_audit.SIM = pathlib.Path(${JSON.stringify(join(dir, "sim"))})
build_audit.built_systems = lambda *a, **k: os._exit(9)
check_audit_ui._self_test_built()`);
      const vc = py(`
import os, pathlib, validate_content as v
v.CONTENT = pathlib.Path(${JSON.stringify(join(dir, "content"))})
v.check_provenance = lambda *a, **k: os._exit(9)
v.self_test()`);
      assert.equal(ui.code, 9, `check_audit_ui did not reach the window: ${ui.out.slice(-400)}`);
      assert.equal(vc.code, 9, `validate_content did not reach the window: ${vc.out.slice(-400)}`);
      const changed = [];
      for (const rel of ["sim/status.json", "content/ruleborn.json"]) {
        if (readFileSync(join(dir, rel), "utf8") !== readFileSync(join(REPO, rel), "utf8")) changed.push(rel);
      }
      assert.deepEqual(changed, [], `a killed self-test left its plant in ${changed.join(", ")}`);
    },
  },
  {
    id: "FX1-T-18",
    title: "golden.py fails when labels-blind.md is missing",
    proof() {
      const r = py(`
import io, contextlib, pathlib, golden as g
g.BLIND = pathlib.Path("/nonexistent/labels-blind.md")
try:
    with contextlib.redirect_stdout(io.StringIO()):
        rc = g.check()
except SystemExit as e:
    rc = e.code
print(json.dumps(rc if isinstance(rc, int) else (0 if rc is None else 1)))`, ["tools/ui_gate"]);
      assert.notEqual(r.value, 0, `golden passed without labels-blind.md: ${r.out}`);
    },
  },
  {
    id: "FX1-T-19",
    title: "sheet.py crops writes a crop for a name with a slash in it",
    proof() {
      const out = scratch();
      const r = run("python3", ["-B", "-I", join(TOOLS, "ui_gate", "sheet.py"), "crops",
        join(REPO, "art/ui/board/board.shot.json"), out], out);
      assert.equal(r.code, 0, `crops failed:\n${r.out.slice(-600)}`);
    },
  },
];
