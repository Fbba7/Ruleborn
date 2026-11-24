// FX1-9-tools-gate: the fixed findings of docs/security/audit-2026-11/tools.md
// (FX1-T-03, 04, 05, 08, 09 and 22), each moved out of the stillOpen list in
// fix_fx1_audit_tools_proofs.mjs into a plain test, and FX2-R4: the proofs'
// py() helper reads its JSON from stdout only.
//
// Like the proofs, every test runs the repository's own tool as it is on disk,
// against a planted input in a temporary folder, and writes nothing inside the
// repository.

import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { test } from "node:test";

import { TOOLS, checkRun, py } from "./fix_fx1_audit_tools_proofs.mjs";

const GATE = JSON.stringify(join(TOOLS, "check_all.sh"));

test("FX1-T-03: run_checks.sh record does not write exit 0 for a failed run", () => {
  // The run exits 0 but never prints "All checks passed.": result says
  // FAIL, and record must not hand the lead a precheck it reuses.
  const c = checkRun("echo '== gdlint =='; echo skipped");
  assert.equal(c.result.state, "FAIL", JSON.stringify(c.result));
  c.sh("record", c.sha, "FX1");
  const status = JSON.parse(readFileSync(join(c.repo, "docs/progress/status/FX1.json"), "utf8"));
  assert.equal(status.precheck.state, "FAIL", `record wrote a FAIL as ${JSON.stringify(status.precheck)}`);
  assert.notEqual(status.precheck.exit, 0, `record wrote a FAIL as ${JSON.stringify(status.precheck)}`);
});

test("FX1-T-03: run_checks.sh record writes a passed run's state PASS and exit 0", () => {
  const c = checkRun("echo 'All checks passed.'");
  assert.equal(c.result.state, "PASS", JSON.stringify(c.result));
  c.sh("record", c.sha, "FX1");
  const status = JSON.parse(readFileSync(join(c.repo, "docs/progress/status/FX1.json"), "utf8"));
  assert.equal(status.precheck.state, "PASS", JSON.stringify(status.precheck));
  assert.equal(status.precheck.exit, 0, JSON.stringify(status.precheck));
  assert.equal(status.precheck.summary, "All checks passed.", JSON.stringify(status.precheck));
});

test("FX1-T-04: run_checks.sh does not read a failed run as PASS when a leftover child writes after it", () => {
  // The check fails (exit 101); a background child it left behind writes
  // "All checks passed." and a DONE exit=0 line after the outer shell's own
  // DONE line.
  const cmd = "(sleep 1; printf 'All checks passed.\\n%070d\\nDONE exit=0\\n' 0) & " +
    "echo '== cargo test =='; echo 'test failed'; exit 101";
  const c = checkRun(cmd, 2500);
  assert.notEqual(c.result.state, "PASS", `a run that exited 101 reads ${JSON.stringify(c.result)}`);
  assert.equal(c.result.exit, 101, JSON.stringify(c.result));
});

test("FX1-T-05: owners.py finds the overlap of ?/[..] globs and of exclusions", () => {
  const r = py(`
import owners
print(json.dumps([
  owners.overlap("client/ui/icon_?.svg", "client/ui/icon_a*"),
  owners.overlap("client/[ab]x.gd", "client/a*"),
  bool(owners.files_overlap(["client/ui/**", "!client/ui/art/**", "client/ui/art/x.gd"], ["client/ui/art/**"])),
]))`, ["tools/coord"]);
  assert.deepEqual(r.value, [true, true, true], `overlaps missed: ${r.out}`);
});

test("FX1-T-05: owners.py still keeps disjoint globs and an exclusion apart", () => {
  const r = py(`
import owners
print(json.dumps([
  owners.overlap("client/ui/icon_?.svg", "client/ui/logo_*"),
  owners.overlap("client/[ab]x.gd", "server/a*"),
  bool(owners.files_overlap(["client/ui/**", "!client/ui/art/**"], ["client/ui/art/**"])),
]))`, ["tools/coord"]);
  assert.deepEqual(r.value, [false, false, false], `false overlaps: ${r.out}`);
});

test("FX1-T-08: check_ci.py refuses wider permissions and a commented-out required command", () => {
  const r = py(`
import check_ci as c
good = c.WORKFLOW.read_text()
wide = good.replace("permissions:\\n  contents: read\\n", "permissions:\\n  contents: read\\n  actions: write\\n")
cmt = good.replace("npm test", "# npm test", 1)
print(json.dumps([wide != good, cmt != good, bool(c.problems(wide)), bool(c.problems(cmt)), c.problems(good)]))`);
  assert.deepEqual(r.value?.slice(0, 2), [true, true], `plant did not apply: ${r.out}`);
  assert.deepEqual(r.value.slice(2, 4), [true, true], `[wide permissions, commented command] passed: ${r.out}`);
  assert.deepEqual(r.value[4], [], `the committed workflow fails: ${r.out}`);
});

test("FX1-T-09: the gate fails when docs/design/dependencies.md is stale", () => {
  // Run every check_dependencies.py command check_all.sh runs, with the
  // committed file replaced by a stale one (in a copy).
  const r = py(`
import pathlib, re, tempfile, check_dependencies as c
dst = pathlib.Path(tempfile.mkdtemp()) / "docs" / "design" / "dependencies.md"
dst.parent.mkdir(parents=True); dst.write_text("stale\\n")
c.ROOT, c.OUT = dst.parent.parent.parent, dst
gate = pathlib.Path(${GATE}).read_text()
codes = []
for line in re.findall(r"^python3 tools/check_dependencies.py(.*)$", gate, re.M):
    sys.argv = ["check_dependencies.py"] + line.split()
    codes.append(c.main())
print(json.dumps([codes, dst.read_text() == "stale\\n"]))`);
  assert.ok(Array.isArray(r.value?.[0]) && r.value[0].length > 0, `no command ran: ${r.out}`);
  assert.ok(r.value[0].some((x) => x !== 0), `every gate command passed a stale file: ${JSON.stringify(r.value)}`);
  assert.equal(r.value[1], true, "the gate rewrote the file it should check");
});

test("FX1-T-22: the gate's build_stamp.py commands fail on a page with escaped markup", () => {
  const r = py(`
import pathlib, re, tempfile, io, contextlib, build_stamp as b
root = pathlib.Path(tempfile.mkdtemp())
for _, rel, _ in b.ARTIFACTS:
    p = root / rel; p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text("<html><body>\\n<p>&lt;strong&gt;C6&lt;/strong&gt; leaked</p>\\n"
                 "<!-- ruleborn-build 0000000000000000 -->\\n</body></html>\\n")
b.ROOT = root
gate = pathlib.Path(${GATE}).read_text()
codes = []
for line in re.findall(r"^python3 tools/build_stamp.py(.*)$", gate, re.M):
    sys.argv = ["build_stamp.py"] + line.split()
    with contextlib.redirect_stdout(io.StringIO()):
        codes.append(b.main())
print(json.dumps(codes))`);
  assert.ok(Array.isArray(r.value) && r.value.length > 0, `no command ran: ${r.out}`);
  assert.ok(r.value.some((x) => x !== 0), `every gate command passed escaped markup: ${JSON.stringify(r.value)}`);
});

test("FX1-T-22: the gate's page check runs after the pages it checks are built", () => {
  const gate = readFileSync(join(TOOLS, "check_all.sh"), "utf8").split("\n");
  const at = (re) => gate.findIndex((l) => re.test(l));
  const stamp = gate.findLastIndex((l) => /^python3 tools\/build_stamp\.py\s*$/.test(l));
  assert.ok(stamp > 0, "check_all.sh has no plain build_stamp.py line");
  assert.ok(stamp > at(/^python3 tools\/build_audit\.py/), "build_stamp.py runs before build_audit.py");
  assert.ok(stamp > at(/^python3 tools\/build_roadmap\.py/), "build_stamp.py runs before build_roadmap.py");
});

test("FX2-R4: py() reads its JSON from stdout, not from a warning on stderr", () => {
  const r = py(`print(json.dumps([1, 2])); print("SyntaxWarning: planted", file=sys.stderr)`);
  assert.deepEqual(r.value, [1, 2], `py() read ${JSON.stringify(r.value)} from: ${r.out}`);
});

test("FX2-R4: py() reads a tool's JSON in a tree with no cached .pyc", () => {
  // fresh: Python finds no tools/__pycache__, so it compiles check_document.py
  // afresh and, while its docstring holds an invalid escape, prints a
  // SyntaxWarning to stderr: the case FX2-R4 found.
  const r = py(`import check_document\nprint(json.dumps("imported"))`, [], { fresh: true });
  assert.equal(r.value, "imported", `py() read ${JSON.stringify(r.value)} from: ${r.out}`);
});
