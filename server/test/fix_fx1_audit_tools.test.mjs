// FX1-7: the proofs of docs/security/audit-2026-11/tools.md, one test per
// finding. The proofs themselves are in fix_fx1_audit_tools_proofs.mjs: each
// runs the repository's own tool, as it is on disk, against a planted input
// in a temporary folder, and never writes inside the repository.
//
// Every tool here is outside this task's files, so each proof is wrapped in
// stillOpen (fix_fx2_open.mjs): the proof holds what should happen and fails
// on main; the wrapper passes while it fails, and fails once the finding is
// fixed. Whoever fixes a finding moves its proof out of the list and into a
// plain test of its own.

import { test } from "node:test";

import { stillOpen } from "./fix_fx2_open.mjs";
import { PROOFS } from "./fix_fx1_audit_tools_proofs.mjs";

for (const { id, title, proof } of PROOFS) {
  test(`${id}: ${title}`, async () => {
    await stillOpen(id, proof);
  });
}
