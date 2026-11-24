// FX2-6's audit (docs/security/audit-2026-11/server-b.md): a finding proven
// but not fixed here, because its code is outside the task's files. `proof`
// holds what the design asks for and fails on main; the test that wraps it
// passes while it fails, and fails once the finding is fixed, so whoever fixes
// it turns the wrapper back into the plain proof. Nothing is skipped: the proof
// runs on every test run.

import assert from "node:assert/strict";

export async function stillOpen(id, proof) {
  let failed = null;
  try {
    await proof();
  } catch (e) {
    failed = e;
  }
  if (failed && !(failed instanceof assert.AssertionError)) throw failed;
  assert.ok(failed, `${id} no longer fails: it is fixed, so run its proof as a plain test`);
}
