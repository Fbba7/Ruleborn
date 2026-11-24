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
const TOOLS = join(REPO, "tools");

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
function run(cmd, args, cwd, env = {}) {
  const base = { ...process.env };
  delete base.NODE_TEST_CONTEXT;
  const r = spawnSync(cmd, args, { cwd, encoding: "utf8", env: { ...base, ...env }, timeout: 120_000 });
  return { code: r.status, signal: r.signal, out: (r.stdout ?? "") + (r.stderr ?? "") };
}

/** Run Python isolated (-I: no cwd or PYTHONPATH on the path; -B: no .pyc
 *  written into the repository), with tools/ and `extra` folders importable,
 *  from a scratch folder. The code prints one JSON line last; it is parsed. */
function py(code, extra = []) {
  const path = [TOOLS, ...extra.map((p) => join(REPO, p))];
  const head = `import sys, json\nsys.path[:0] = ${JSON.stringify(path)}\n`;
  const r = run("python3", ["-B", "-I", "-c", head + code], scratch());
  const last = r.out.trim().split("\n").pop();
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
function checkRun(cmd, settleMs = 0) {
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

const NODE_TEST = 'import test from "node:test";\nimport assert from "node:assert/strict";\n';

export const PROOFS = [
  {
    id: "FX1-T-01",
    title: "server/status.py fails when a failing test shares its name with a passing one",
    proof() {
      const dir = scratch({
        "server/test/a.test.mjs": NODE_TEST + 'test("same name", () => assert.equal(1, 2));\n',
        "server/test/b.test.mjs": NODE_TEST + 'test("same name", () => {});\n',
      });
      copyIn(dir, "server/status.py");
      const r = run("python3", ["-B", "server/status.py"], dir);
      assert.notEqual(r.code, 0, `status.py passed a failing test:\n${r.out}`);
    },
  },
  {
    id: "FX1-T-02",
    title: "server/status.py does not record a skipped test as passed",
    proof() {
      const dir = scratch({
        "server/test/a.test.mjs": NODE_TEST + 'test("never run", { skip: true }, () => assert.fail("x"));\n',
      });
      copyIn(dir, "server/status.py");
      const r = run("python3", ["-B", "server/status.py"], dir);
      assert.notEqual(r.code, 0, `status.py passed a skipped test:\n${r.out}`);
    },
  },
  {
    id: "FX1-T-03",
    title: "run_checks.sh record does not write exit 0 for a failed run",
    proof() {
      // The run exits 0 but never prints "All checks passed.": result says
      // FAIL, and record must not hand the lead a precheck it reuses.
      const c = checkRun("echo '== gdlint =='; echo skipped");
      assert.equal(c.result.state, "FAIL", JSON.stringify(c.result));
      c.sh("record", c.sha, "FX1");
      const status = JSON.parse(readFileSync(join(c.repo, "docs/progress/status/FX1.json"), "utf8"));
      assert.ok(status.precheck.exit !== 0 || status.precheck.state === "FAIL",
        `record wrote a FAIL as ${JSON.stringify(status.precheck)}`);
    },
  },
  {
    id: "FX1-T-04",
    title: "run_checks.sh does not read a failed run as PASS when a leftover child writes after it",
    proof() {
      // The check fails (exit 101); a background child it left behind
      // writes "All checks passed." and a DONE exit=0 line after the outer
      // shell's own DONE line.
      const cmd = "(sleep 1; printf 'All checks passed.\\n%070d\\nDONE exit=0\\n' 0) & " +
        "echo '== cargo test =='; echo 'test failed'; exit 101";
      const c = checkRun(cmd, 2500);
      assert.notEqual(c.result.state, "PASS", `a run that exited 101 reads ${JSON.stringify(c.result)}`);
    },
  },
  {
    id: "FX1-T-05",
    title: "owners.py finds the overlap of ?/[..] globs and of exclusions",
    proof() {
      const r = py(`
import owners
print(json.dumps([
  owners.overlap("client/ui/icon_?.svg", "client/ui/icon_a*"),
  owners.overlap("client/[ab]x.gd", "client/a*"),
  bool(owners.files_overlap(["client/ui/**", "!client/ui/art/**", "client/ui/art/x.gd"], ["client/ui/art/**"])),
]))`, ["tools/coord"]);
      assert.deepEqual(r.value, [true, true, true], `overlaps missed: ${r.out}`);
    },
  },
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
    id: "FX1-T-08",
    title: "check_ci.py refuses wider permissions and a commented-out required command",
    proof() {
      const r = py(`
import check_ci as c
good = c.WORKFLOW.read_text()
wide = good.replace("permissions:\\n  contents: read\\n", "permissions:\\n  contents: read\\n  actions: write\\n")
cmt = good.replace("npm test", "# npm test", 1)
print(json.dumps([wide != good, cmt != good, bool(c.problems(wide)), bool(c.problems(cmt))]))`);
      assert.deepEqual(r.value?.slice(0, 2), [true, true], `plant did not apply: ${r.out}`);
      assert.deepEqual(r.value.slice(2), [true, true], `[wide permissions, commented command] passed: ${r.out}`);
    },
  },
  {
    id: "FX1-T-09",
    title: "the gate fails when docs/design/dependencies.md is stale",
    proof() {
      // Run every check_dependencies.py command check_all.sh runs, with the
      // committed file replaced by a stale one (in a copy).
      const r = py(`
import pathlib, re, tempfile, check_dependencies as c
dst = pathlib.Path(tempfile.mkdtemp()) / "docs" / "design" / "dependencies.md"
dst.parent.mkdir(parents=True); dst.write_text("stale\\n")
c.ROOT, c.OUT = dst.parent.parent.parent, dst
gate = pathlib.Path(${JSON.stringify(join(TOOLS, "check_all.sh"))}).read_text()
codes = []
for line in re.findall(r"^python3 tools/check_dependencies.py(.*)$", gate, re.M):
    sys.argv = ["check_dependencies.py"] + line.split()
    codes.append(c.main())
print(json.dumps(codes))`);
      assert.ok(Array.isArray(r.value) && r.value.length > 0, `no command ran: ${r.out}`);
      assert.ok(r.value.some((x) => x !== 0), `every gate command passed a stale file: ${JSON.stringify(r.value)}`);
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
  {
    id: "FX1-T-20",
    title: "client_contract.py checks every failure code the server sends",
    proof() {
      const r = py(`
import client_contract as c
have = c.server_reasons() | c.client_codes()
sent = ["gift_needs_a_friend", "not_a_gift", "island_malformed", "universe_malformed",
        "crew", "length", "log", "checksums", "landing"]
print(json.dumps([s for s in sent if s not in have]))`);
      assert.deepEqual(r.value, [], `codes the check never reads: ${r.out}`);
    },
  },
  {
    id: "FX1-T-21",
    title: "client_contract.py checks the client's call sites outside client/data",
    proof() {
      const r = py(`
import client_contract as c
where = {w for _, _, w in c.client_calls()}
print(json.dumps([f for f in ("client/features/auth/auth_session.gd",
                               "client/features/weaving/weaving_controller.gd") if f not in where]))`);
      assert.deepEqual(r.value, [], `call sites never checked: ${r.out}`);
    },
  },
  {
    id: "FX1-T-22",
    title: "the gate's build_stamp.py commands fail on a page with escaped markup",
    proof() {
      const r = py(`
import pathlib, re, tempfile, io, contextlib, build_stamp as b
root = pathlib.Path(tempfile.mkdtemp())
for _, rel, _ in b.ARTIFACTS:
    p = root / rel; p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text("<html><body>\\n<p>&lt;strong&gt;C6&lt;/strong&gt; leaked</p>\\n"
                 "<!-- ruleborn-build 0000000000000000 -->\\n</body></html>\\n")
b.ROOT = root
gate = pathlib.Path(${JSON.stringify(join(TOOLS, "check_all.sh"))}).read_text()
codes = []
for line in re.findall(r"^python3 tools/build_stamp.py(.*)$", gate, re.M):
    sys.argv = ["build_stamp.py"] + line.split()
    with contextlib.redirect_stdout(io.StringIO()):
        codes.append(b.main())
print(json.dumps(codes))`);
      assert.ok(Array.isArray(r.value) && r.value.length > 0, `no command ran: ${r.out}`);
      assert.ok(r.value.some((x) => x !== 0), `every gate command passed escaped markup: ${JSON.stringify(r.value)}`);
    },
  },
];
