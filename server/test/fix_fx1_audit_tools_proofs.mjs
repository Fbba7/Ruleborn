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
export function copyIn(dir, rel) {
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


// Every finding of tools.md is now fixed, and its proof is a plain test:
// FX1-9-tools-gate, FX1-10-tools-contract, FX1-11-tools-docs and
// FX1-12-tools-ui (fix_fx1_tools_gate, _contract, _docs and _ui.test.mjs).
// A new finding's proof goes here, wrapped in stillOpen, until it is fixed.
export const PROOFS = [];
