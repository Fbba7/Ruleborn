// FX1-11-tools-docs: the document-check findings of
// docs/security/audit-2026-11/tools.md (FX1-T-10, FX1-T-17, FX1-T-11 and
// FX1-T-12), each moved out of the stillOpen list in
// fix_fx1_audit_tools_proofs.mjs into plain tests, and FX1-R26's second half
// (check_document.py compiles with no SyntaxWarning).
//
// Like the proofs, every test runs the repository's own tool as it is on disk,
// against a planted input in a temporary folder. Nothing is written inside the
// repository: a tool that writes is pointed at a copy.

import assert from "node:assert/strict";
import { cpSync, mkdirSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { test } from "node:test";

import { REPO, TOOLS, py, run, scratch } from "./fix_fx1_audit_tools_proofs.mjs";

/** Copy the repository's `rel` (a file or a folder) into `dir`. */
function copyIn(dir, rel) {
  mkdirSync(dirname(join(dir, rel)), { recursive: true });
  cpSync(join(REPO, rel), join(dir, rel), { recursive: true });
}

test("FX1-T-10: three-digit ids are read as ids (check_findings_fresh, check_docs_consistency)", () => {
  const r = py(`
import pathlib, tempfile
import check_findings_fresh as f, check_docs_consistency as d
p = pathlib.Path(tempfile.mkdtemp()) / "check_x.py"
p.write_text('\\ndef f():\\n    """D100. pins it."""\\n    return 0\\n')
f.check_files = lambda: [p]
print(json.dumps(["D100" in str(f.pinned_by_a_check()),
                  "D100" in str(d.spec_open_claims("- **D100** cap\\n- **D9** x\\n"))]))`);
  assert.deepEqual(r.value, [true, true], `[pinned_by_a_check, spec_open_claims] missed D100: ${r.out}`);
});

test("FX1-T-17: a self-test killed mid-run leaves the committed file it plants into unchanged", () => {
  // Two self-tests used to write a plant into a committed file and restore it
  // only in `finally`; a kill in between left the plant. Each runs here
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
});

test("FX1-T-11: check_document.py fails a check that tracks an id the register does not hold", () => {
  const r = py(`
import io, contextlib, check_document as c
codes = []
for ok in (False, True):
    L = c.Ledger(quiet=True)
    with contextlib.redirect_stdout(io.StringIO()):
        L.check("x", ok, "boom", tracks="C999")
        codes.append(L.report())
print(json.dumps(codes))`);
  assert.deepEqual(r.value, [1, 1], `a check tracking an unknown id passed [failing, passing]: ${r.out}`);
});

test("FX1-T-12: check_one_fact_home finds a design fact restated by an annotated assignment", () => {
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
});

test("FX1-R26: check_document.py compiles with no SyntaxWarning", () => {
  // -W error turns the warning into a SyntaxError; compile() reads the source
  // afresh, so no cached .pyc hides it.
  const path = join(TOOLS, "check_document.py");
  const r = run("python3", ["-W", "error", "-B", "-I", "-c",
    `import sys\nwith open(sys.argv[1], encoding="utf-8") as f: src = f.read()\ncompile(src, sys.argv[1], "exec")`,
    path], scratch());
  assert.equal(r.code, 0, `check_document.py does not compile cleanly:\n${r.out.slice(-600)}`);
});
