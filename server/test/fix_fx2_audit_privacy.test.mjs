// FX2-6's audit, the privacy page (docs/security/audit-2026-11/server-b.md).

import assert from "node:assert/strict";
import { test } from "node:test";

import { privacyPage } from "../src/pages.mjs";
import { stillOpen } from "./fix_fx2_open.mjs";

const page = async () => {
  const p = privacyPage(undefined, { webDeletion: true });
  return typeof p === "string" ? p : await p.text();
};

// AUD-B-12: pages.mjs writes "${k.days} days" whatever the number.
test("AUD-B-12: the privacy page says '1 day', not '1 days'", async () => {
  const text = await page();
  assert.equal(text.match(/\b1 days\b/g), null);
  assert.match(text, /\b1 day\b/);
});

// AUD-B-13: open. server/privacy.json's texts name repository files and
// functions, and one phrase loses its noun when plain() strips the "§".
for (const leak of ["(docs/security/auth.md)", "(expireReplays)", "(snapshots)", "it is log"]) {
  test(`AUD-B-13: the privacy page reads as prose for a player: no "${leak}"`, async () => {
    await stillOpen("AUD-B-13", async () => {
      assert.equal((await page()).indexOf(leak), -1);
    });
  });
}
