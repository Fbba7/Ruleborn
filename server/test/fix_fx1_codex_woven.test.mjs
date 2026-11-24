// FX1-13 (FX1-R25, FX1-A-17's residual): weaving.mjs records a law's woven
// step at the weave's finish time; the Codex's mastery tracks and the
// profile's titles count it only once that time has come (§18.5, §5.6).

import assert from "node:assert/strict";
import { test } from "node:test";

import { server } from "./setup.mjs";

const MINUTE = 60 * 1000;

test("FX1-A-17, FX1-R25: a weave still unfinished is no mastery step in the Codex or the profile (18.5, 5.6)", () => {
  const t = server({ strictUniverse: true });
  const me = t.service.session("gc:weaver").account;
  t.service.book(me, "aether", 10_000, "a test's grant");
  t.service.codex.ensure(me, t.service.now());
  // Three of Motion's twelve steps already earned, so the woven step is the
  // fourth: the school's first title (a third of its steps).
  t.service.db.prepare("UPDATE codex SET crossed_at = ? WHERE owner = ? AND law = 'half_gravity'")
    .run(t.service.now(), me);
  t.service.db.prepare(`INSERT INTO codex (owner, law, pages, tier, met_at, restored_at, crossed_at)
    VALUES (?, 'bounce', 0, 3, ?, ?, ?)`).run(me, t.service.now(), t.service.now(), t.service.now());
  const codexSteps = () => t.service.codex.show(me).mastery.find((m) => m.school === "Motion").steps;
  const profileTitle = () => t.service.profile.view(me).titles.find((m) => m.school === "Motion") ?? null;
  assert.equal(codexSteps(), 3);
  assert.equal(profileTitle(), null);

  // Tier I weaves in 10 minutes (§5.6).
  t.service.weaving.weave(me, { realm: "heart", slot: 1, law: "half_gravity" });
  assert.equal(codexSteps(), 3, "the Codex: the weave has just started");
  assert.equal(profileTitle(), null, "the profile: the weave has just started");
  t.clock.now += 9 * MINUTE;
  assert.equal(codexSteps(), 3, "the Codex: a minute of weaving is left");
  assert.equal(profileTitle(), null, "the profile: a minute of weaving is left");

  t.clock.now += MINUTE;
  assert.equal(codexSteps(), 4, "the Codex: the weave has finished");
  assert.deepEqual(profileTitle(), { school: "Motion", steps: 4, total: 12, titles: 1 },
    "the profile: the weave has finished");
});
