// FX1-7: the proofs of docs/security/audit-2026-11/tools.md, one test per
// finding. Each runs the repository's own tool, as it is on disk, against a
// planted input in a temporary folder, and never writes inside the
// repository.
//
// Every tool here is outside this task's files, so each proof is wrapped in
// stillOpen (fix_fx2_open.mjs): the proof holds what should happen and fails
// on main; the wrapper passes while it fails, and fails once the finding is
// fixed. Whoever fixes a finding turns its wrapper back into the plain proof.

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { copyFileSync, mkdirSync, mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";

import { stillOpen } from "./fix_fx2_open.mjs";

const REPO = join(dirname(fileURLToPath(import.meta.url)), "..", "..");

/** A fresh temporary folder, with `files` ({relative path: text}) written. */
function scratch(files = {}) {
  const dir = mkdtempSync(join(tmpdir(), "fx1-audit-tools-"));
  for (const [rel, text] of Object.entries(files)) {
    mkdirSync(dirname(join(dir, rel)), { recursive: true });
    writeFileSync(join(dir, rel), text);
  }
  return dir;
}

/** Copy the repository's `rel` into `dir` at the same relative path. */
function copyIn(dir, rel) {
  mkdirSync(dirname(join(dir, rel)), { recursive: true });
  copyFileSync(join(REPO, rel), join(dir, rel));
}

/** Run a tool. NODE_TEST_CONTEXT is dropped: inherited from this runner, it
 *  would make a nested `node --test` report to us instead of printing TAP. */
function run(cmd, args, cwd, env = {}) {
  const base = { ...process.env };
  delete base.NODE_TEST_CONTEXT;
  const r = spawnSync(cmd, args, { cwd, encoding: "utf8", env: { ...base, ...env } });
  return { code: r.status, out: (r.stdout ?? "") + (r.stderr ?? "") };
}

const NODE_TEST = 'import test from "node:test";\nimport assert from "node:assert/strict";\n';

test("FX1-T-01: server/status.py fails when a failing test shares its name with a passing one", async () => {
  // FX1-T-01, open: server/status.py keys results by test name and ignores
  // node's exit code, so the later "ok" overwrites the earlier "not ok".
  await stillOpen("FX1-T-01", () => {
    const dir = scratch({
      "server/test/a.test.mjs": NODE_TEST + 'test("same name", () => assert.equal(1, 2));\n',
      "server/test/b.test.mjs": NODE_TEST + 'test("same name", () => {});\n',
    });
    copyIn(dir, "server/status.py");
    const r = run("python3", ["server/status.py"], dir);
    assert.notEqual(r.code, 0, `status.py passed a failing test:\n${r.out}`);
  });
});

test("FX1-T-02: server/status.py does not record a skipped test as passed", async () => {
  // FX1-T-02, open: the TAP line "ok N - name # SKIP" matches as "ok", so a
  // skipped test reads "passed" in server/status.json and passes the gate.
  await stillOpen("FX1-T-02", () => {
    const dir = scratch({
      "server/test/a.test.mjs": NODE_TEST + 'test("never run", { skip: true }, () => assert.fail("x"));\n',
    });
    copyIn(dir, "server/status.py");
    const r = run("python3", ["server/status.py"], dir);
    assert.notEqual(r.code, 0, `status.py passed a skipped test:\n${r.out}`);
  });
});
