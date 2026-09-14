# Recommended next steps

Ordered. Everything in stage 0 and 1 costs essentially nothing and can start
immediately; nothing after stage 2 should start before it.

---

## Stage 0 — the two free tests (start now, run in parallel)

Both are already designed in the document. Neither needs an engine, art, or a
line of code.

### 0a. The paper heist (§19.27, gate 1)

An 8×8 board, face-down tiles, a guard deck, a metronome at one beat per four
seconds for the clock. Eight to twelve people, two heists each.

**Passes if:** median tension ≥ 3/4, median enjoyment ≥ 6/10, and **at least 60%
choose to play again** — the only behavioural measure in the set, and the one that
matters.

**Decides:** whether a no-loss, delegated-control stealth heist is fun at all.
This is the premise the whole game rests on and no published research covers it
(§30.8).

*One addition to the document's protocol:* also record whether players feel they
are **playing or watching**. §30.7 premise 3 is only conditionally supported and
§04's G1 shows the system that decides it is unspecified. A paper prototype is
the cheapest place to find out that delegated crews feel passive.

### 0b. The build-willingness test (§13.3)

Fifteen to twenty people. Everyone builds one island under guidance, watches a
raid run against it, and is then told they may stop. **Whether they build a
second, unprompted, is the whole measurement.**

**Decides:** the three-way branch in §13.3 — ≥30% authorship as designed;
15–30% authorship with heavy scaffolding; <15% pivot to generated islands the
player curates.

This is ranked risk #1 and §26.7 calls it "the single decision that changes the
most". The document schedules it after the paper heist; I would run it first or
alongside, because it changes *what game is being built*, not just whether to
build it.

---

## Stage 1 — reconcile the document (days of designer time)

Work `03-contradiction-register.md` top to bottom. The five blocking decisions,
each of which is a choice rather than new design work:

| Decide | Between | Recommendation |
| --- | --- | --- |
| **C1** Detection model | §12.8 vs §12.17 | §12.17. Regenerate §29.1 from it; rewrite §5.4's landing noise in suspicion units |
| **C2** Raid payout | §9.4/§12.9 vs §9.6 | §9.6 — then rewrite §9.4's and §12.1's resource-share claims to match reality, and decide what Carrier capacity now means |
| **C3** Law rarity | three ranks vs five | Either, but regenerate §7.4, §7.7, §7.6, §9.5, §14.4 and the glossary from one table |
| **C4** What `L` is in `B(L)` | realm level (caps at 5) vs Vault level (caps at 10) | Almost certainly Vault level or a composite target-strength score. This is the master inflation dial and it currently references a level range that does not exist |
| **C6** Ruleborn roster | §11.2 vs §11.11 | §11.11, reduced to one data table; §11.2 becomes a generated index |

Then C5 (defence budgets), C7 (tick rate) and C8 (the Library), then the minor
ones.

**While doing this, split the document.** It is currently a specification and a
research archive in one file, and §19, §28 and §30 are roughly 40% of the text.
Both halves are valuable; keeping them together means the spec cannot be read,
diffed or implemented without the archive.

```
docs/design/spec/        the buildable specification, one file per system
docs/design/research/    §19, §28, §30 — the evidence, the reviews, the reasoning
```

The spec should carry decisions; the archive should carry why. Cross-reference,
don't duplicate.

**Also do the two content-balance passes** from `05-quantitative-findings.md`:

- Rebalance notes toward ~8–9 laws each (currently Glow 12, Hush 6) before the
  law data table is authored, since notes are frozen at eight and every future
  season must stay balanced too.
- Decide whether chords require three *laws* or three *notes* — as written, all
  twelve are reachable with two laws, several with two commons.

---

## Stage 2 — rebuild the economy model (a few coding sessions)

§24 describes a Python model that generated §10.2, §14.2 and §14.3. It is not in
the document, and it is the source of roughly a quarter of the document's numbers
(G7).

Rebuilding it is the ideal first coding task:

- No engine, no art, no device, no network
- Validates the economy independently of the simulation spike
- It is the tool that resolves C2 and C4 — you cannot pick a value for `B(L)`
  without being able to see what it does to the curve
- It produces the regression tests for every balance change thereafter
- It is exactly the kind of work §26.8 lists as "safe to hand over"

Target: re-derive §10.2's building tables and §14's day-by-day milestones from
first principles, and confirm they match the published figures. Where they don't,
that is another finding.

---

## Stage 3 — the determinism spike (6–14 sessions, per §26.8)

Exactly as §24.2 and §26.7 specify, with one addition:

Prove that **one function returns the same checksum on four targets** — desktop,
server (WebAssembly), a cheap Android, an iPhone. The document specifies desktop,
server, Android and iPhone; make sure the *server Wasm build* is in the first
round and not deferred, because the entire architecture rests on the same code
running in both places.

Time-box it to ten working sessions as §24.7 already commits. If Rust extensions
will not build and load on real devices in that window, take the C# fallback
without renegotiating. Write the fixed-point module and the golden replays to be
portable from day one, so the switch costs the spike and nothing else.

**Do not write gameplay code before this passes.** Anti-cheat, replay validation,
free analytics, rehearsals, balance bots and the whole cost model all fail
together if it doesn't.

---

## Stage 4 — the scope conversation (one decision)

Before the vertical slice, decide §26.1's launch content against §26.5's own rule
that "scope is the lever, not headcount".

`06-build-readiness.md` proposes a ~40% cut that preserves everything
distinctively Ruleborn: 24 laws instead of 48, 3 form-notes instead of 8, ~20
resonances instead of 44, 2–3 languages instead of 12, constellations moved to
v1.1, wards at 2 levels instead of 5.

The Island Workshop is the one thing not to cut.

---

## Stage 5 — specification locks, then the vertical slice

Then §26.7's remaining sequence, unchanged:

1. Lock the simulation contract (§24.10)
2. Lock the detection numbers (§12.17) — unblocked by C1
3. Lock the law schema (§7, §8.7) — unblocked by C3 and the note rebalance
4. Lock saves, bundles and versions (§24.11)
5. Vertical slice (§26.2 phase 2), with §19.5's fun gate as the exit test

**Specify pathfinding and crew control before the slice** (G1). It is the largest
gap, and it is the system most likely to fail §30.7's premise 3. Write it down
before building it, and make felt control (§30.8's 70% threshold) a gate on the
slice rather than a polish item.

---

## What this repository should become

Suggested shape as work proceeds:

```
docs/
  design/
    ruleborn-game-design-v2.3.html   the source of truth as delivered (preserved)
    ruleborn-game-design-v2.3.txt    greppable extract, regenerated by tools/
    spec/                            the reconciled, buildable specification
    research/                        §19, §28, §30 — evidence and reviews
  analysis/                          this analysis
  decisions/                         one file per resolved contradiction, dated
tools/
  extract_design_doc.py              HTML → text
  check_design_consistency.py        the machine checks behind this analysis
  economy_model/                     stage 2
sim/                                 the deterministic core (stage 3 onward)
```

Two conventions worth adopting now:

- **Every contradiction resolved gets a dated decision record** in
  `docs/decisions/`, naming the sections it supersedes. The document reached v2.3
  with four systems specified twice precisely because superseded text was never
  retired; a decision log is the cheapest way to stop that recurring.
- **`tools/check_design_consistency.py` runs in CI once there is CI.** Every
  finding in this analysis that could be mechanised is asserted there, so the
  same class of drift is caught automatically next time.

---

## What not to do yet

- Don't write gameplay code (stage 3 gates it).
- Don't commission character art (the forms decision in stage 4 changes the
  quantity by 3×).
- Don't design screens in detail (C1, C5 and C6 change what several of them show).
- Don't start localisation.
- Don't claim the game's name publicly — §26.9 makes clearance a gate, and it has
  not been done.
