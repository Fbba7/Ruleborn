// FX1-10-tools-contract: the contract and status findings of
// docs/security/audit-2026-11/tools.md (FX1-T-20, FX1-T-21, FX1-T-01 and
// FX1-T-02), each moved out of the stillOpen list in
// fix_fx1_audit_tools_proofs.mjs into plain tests.
//
// Like the proofs, every test runs the repository's own tool as it is on disk,
// against a planted input in a temporary folder (or reads the repository
// without writing to it).

import assert from "node:assert/strict";
import { chmodSync, copyFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { test } from "node:test";

import { REPO, py, run, scratch } from "./fix_fx1_audit_tools_proofs.mjs";

const NODE_TEST = 'import test from "node:test";\nimport assert from "node:assert/strict";\n';

/** Copy the repository's file `rel` into the scratch folder `dir`. */
function copyIn(dir, rel) {
  mkdirSync(dirname(join(dir, rel)), { recursive: true });
  copyFileSync(join(REPO, rel), join(dir, rel));
}

/** server/status.py, run in a scratch folder holding `tests`. */
function serverStatus(tests) {
  const files = {};
  for (const [name, body] of Object.entries(tests)) files[`server/test/${name}`] = NODE_TEST + body;
  const dir = scratch(files);
  copyIn(dir, "server/status.py");
  return run("python3", ["-B", "server/status.py"], dir);
}

/** client/status.py, run in a scratch folder whose build.sh names a stand-in
 *  for Godot that prints `tap`, and whose server is a stand-in that only says
 *  it started. */
function clientStatus(tap) {
  const dir = scratch({
    "client/build.sh": `echo "$(dirname "$0")/fake_godot"\n`,
    "client/fake_godot": `#!/bin/sh\ncat <<'TAP'\n${tap}\nTAP\n`,
    "server/src/main.mjs": 'console.log("ruleborn server on stand-in");\nsetInterval(() => {}, 1000);\n',
  });
  chmodSync(join(dir, "client/fake_godot"), 0o755);
  copyIn(dir, "client/status.py");
  copyIn(dir, "server/status.py");
  return run("python3", ["-B", "client/status.py"], dir);
}

test("FX1-T-01: server/status.py fails when a failing test shares its name with a passing one", () => {
  const r = serverStatus({
    "a.test.mjs": 'test("same name", () => assert.equal(1, 2));\n',
    "b.test.mjs": 'test("same name", () => {});\n',
  });
  assert.notEqual(r.code, 0, `status.py passed a failing test:\n${r.out}`);
});

test("FX1-T-01: client/status.py fails when a failing test shares its name with a passing one", () => {
  const r = clientStatus("not ok 1 - same name\nok 2 - same name");
  assert.notEqual(r.code, 0, `client/status.py passed a failing test:\n${r.out}`);
});

test("FX1-T-02: server/status.py does not record a skipped test as passed", () => {
  const r = serverStatus({ "a.test.mjs": 'test("never run", { skip: true }, () => assert.fail("x"));\n' });
  assert.notEqual(r.code, 0, `status.py passed a skipped test:\n${r.out}`);
  const t = serverStatus({ "a.test.mjs": 'test("not yet", { todo: true }, () => assert.fail("x"));\n' });
  assert.notEqual(t.code, 0, `status.py passed a todo test:\n${t.out}`);
});

test("FX1-T-02: client/status.py does not record a skipped test as passed", () => {
  const r = clientStatus("ok 1 - never run # SKIP");
  assert.notEqual(r.code, 0, `client/status.py passed a skipped test:\n${r.out}`);
});

test("FX1-T-01, FX1-T-02: both status files still pass a run whose tests all pass", () => {
  const s = serverStatus({
    "a.test.mjs": 'test("one", () => {});\ntest("a name with # SKIP in it is not skipped", () => {});\n',
    "b.test.mjs": 'test("two", () => {});\n',
  });
  assert.equal(s.code, 0, s.out);
  assert.match(s.out, /tests: 3 of 3 passed/);
  const c = clientStatus("ok 1 - one\nok 2 - two");
  assert.equal(c.code, 0, c.out);
  assert.match(c.out, /tests: 2 of 2 passed/);
});

test("FX1-T-20: client_contract.py checks every failure code the server sends", () => {
  const r = py(`
import client_contract as c
have = c.server_reasons() | c.client_codes()
sent = ["gift_needs_a_friend", "not_a_gift", "island_malformed", "universe_malformed",
        "crew", "length", "log", "checksums", "landing"]
print(json.dumps([s for s in sent if s not in have]))`);
  assert.deepEqual(r.value, [], `codes the check never reads: ${r.out}`);
});

/** tools/client_contract.py in a scratch tree of `files`, with one route and
 *  a catalogue that has no ERR_ row at all. */
function contract(files, args = []) {
  const dir = scratch({
    "server/src/http.mjs": "//   POST /v1/thing {} → ok\n",
    "client/i18n/strings.csv": "key,en,de\n",
    ...files,
  });
  copyIn(dir, "tools/client_contract.py");
  return run("python3", ["-B", "tools/client_contract.py", ...args], dir);
}

test("FX1-T-20: client_contract.py reads a ternary's codes, the sim's code table and error in any object", () => {
  const r = contract({
    "server/src/a.mjs": [
      'throw new Refused(400, p.gift ? "plant_yes" : "plant_no");',
      'export const REFUSED = {\n  [-1]: "plant_table_one", [-2]: "plant_table_two",\n};',
      'if (bad) return { error: "plant_returned" };',
      'return { ok: false, error: "plant_object" };',
    ].join("\n"),
  }, ["--missing"]);
  const missing = r.stdout.trim().split("\n").sort();
  for (const k of ["PLANT_YES", "PLANT_NO", "PLANT_TABLE_ONE", "PLANT_TABLE_TWO", "PLANT_RETURNED", "PLANT_OBJECT"]) {
    assert.ok(missing.includes(`ERR_${k}`), `ERR_${k} is not asked for:\n${r.out}`);
  }
});

test("FX1-T-20: every code the server sends has words in every language", () => {
  const r = run("python3", ["-B", join(REPO, "tools/client_contract.py"), "--missing"], REPO);
  assert.equal(r.code, 0, r.out);
  assert.equal(r.stdout.trim(), "", `ERR_ rows missing from client/i18n/strings.csv:\n${r.out}`);
});

test("FX1-T-21: client_contract.py checks the client's call sites outside client/data", () => {
  const r = py(`
import client_contract as c
where = {w for _, _, w in c.client_calls()}
print(json.dumps([f for f in ("client/features/auth/auth_session.gd",
                               "client/features/weaving/weaving_controller.gd") if f not in where]))`);
  assert.deepEqual(r.value, [], `call sites never checked: ${r.out}`);
});

test("FX1-T-21: client_contract.py fails on a bad route in a feature folder", () => {
  for (const call of [
    'var r := await api.post_json("/v1/nope", {})',
    'services.outbox.put(key, "/v1/nope", body, true)',
    'return await _step_up("/v1/nope", which)',
  ]) {
    const r = contract({ "client/features/x/y.gd": `func f() -> void:\n\t${call}\n` });
    assert.notEqual(r.code, 0, `a call to /v1/nope passed:\n${call}\n${r.out}`);
    assert.match(r.out, /client\/features\/x\/y\.gd: POST \/v1\/nope/);
  }
  const ok = contract({ "client/features/x/y.gd": 'func f() -> void:\n\tapi.post_json("/v1/thing", {})\n' });
  assert.equal(ok.code, 0, ok.out);
});
