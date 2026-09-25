"""The Ruleborn audit register, as data.

Two halves, as asked for: what changed about the original approach, and what
needs fixing in the design document itself. `tools/build_audit.py` renders this
to docs/audit/index.html, which is what gets published.

This file is the source of truth. When something is resolved, change its
`status` here and rebuild — never edit the generated HTML.

Fields
------
id        short stable handle (C1, G4, D2, F1)
kind      deviation | contradiction | gap | finding | decision
severity  blocking | design | significant | minor | change | choice
title     one line, specific
refs      design-document sections involved
body      what it actually is — the conflict, the change, the gap
rec       what to do about it
status    open | proposed | adopted | done
edits     the concrete changes to make in the design document (see below)

The `edits` field
-----------------
`rec` says what should happen. `edits` says what to type, and where. It exists
because a register that reads well and cannot be acted on is a diagnosis without
a prescription — the point is to sit beside the document and work through it.

Each edit is a dict:

    section   the section to open, as it appears in the contents ("9.2")
    action    replace | delete | insert | regenerate
    find      the text as it stands today, verbatim, so it can be searched for
    replace   the text to put there (omit for `delete`)
    why       one line, if the reason is not obvious from the item

**Every `find` string is checked against the design document by
`tools/check_edits.py`, which runs in `check_all.sh` and fails if one does not
appear verbatim.** That is the guard against the obvious failure mode: an edit
that tells you to replace a sentence the document does not contain.

`regenerate` edits have no `find`; they name a generated file to paste from.
"""

#: Items found by reading v3.0 itself, rather than carried over from the v2.3
#: audit. They need no "what v3.0 did" note, because v3.0 is where they come
#: from. Kept here because three different tools were each holding their own
#: copy of this list, which is the drift this register exists to complain about.
#: Found by reading v3.3 against itself, as the six v3.3 verification passes
#: went: each is a statement v3.3 makes twice, or a figure that did not move
#: with the one it was derived from.
FOUND_IN_V33 = frozenset({"C34", "C35", "C36", "C37", "C38", "C39", "D56",
                          "F32", "G16", "D57", "F33", "F34", "G17", "D58"})

#: Found by reading v3.4 against itself and running the sweep it names.
FOUND_IN_V34 = frozenset({"C40", "G18", "D59", "F35",
                          # found running the full re-run v3.4 hands over,
                          # and building the server's caps
                          "F36", "F37", "G19", "G20", "G21",
                          # and by the adversarial review of that re-run
                          "F38", "F39", "C41", "C42", "G22", "D60",
                          "G23", "G24", "G25", "D61", "G26", "D62", "C43",
                          "F40", "G27", "D63", "F41", "F42", "G28", "D64", "G29", "D65", "F43", "F44", "F45", "G30", "D66", "G31", "F46", "G32", "D67", "F47", "G33", "G34", "D68", "F48", "G35", "F49", "G36", "D69", "G37", "F50", "G38", "G39", "D70", "F51", "G40", "D71"})

FOUND_IN_V3 = frozenset({
    "C21", "C22", "C23", "C24", "C25", "C26", "C27", "C28",
    "D19", "D20", "D21", "D22", "D23",
    "F7", "F8", "F9", "F10", "F11", "F12", "F13", "F14", "F15", "F16", "F17",
    "F18", "F19", "F20", "F21", "D24", "D25", "D26", "D27", "D28",
    "C29", "F22", "F23", "F24", "F25",
})

REGISTER = [

# ===========================================================================
# What changed about the original approach
# ===========================================================================

dict(id="D1", kind="deviation", severity="change", status="adopted",
     title="The build-willingness test runs first, not second",
     refs=["26.7", "13.3", "30.8"],
     body="§26.7 schedules the paper heist first and the build-willingness test "
          "after it. But the build test is ranked risk #1, and §26.7 itself calls "
          "it “the single decision that changes the most”. The heist test "
          "decides whether the game is fun; the build test decides <em>what game "
          "is being built</em> — authorship, authorship-with-scaffolding, or a "
          "pivot to generated islands the player curates.",
     rec="Run both in parallel. Neither blocks the other, and the build test's "
         "answer changes what the rest of the plan is for."),

dict(id="D2", kind="deviation", severity="change", status="done",
     title="The paper prototype became a browser prototype",
     refs=["19.27", "26.7", "25.4"],
     body="Both pre-code gates as written assume about thirty people in a room — "
          "eight to twelve for the paper heist, fifteen to twenty for the build "
          "test. That cohort does not exist for this project. The questions did not "
          "change; the method did, because <strong>a link can be sent to strangers "
          "and a room cannot</strong>. v2.3’s §25.5 — renumbered §25.4 in v3.1 — "
          "budgeted for recruited remote panels, so the route was costed. "
          "<strong>That sentence is no longer in the document:</strong> v3.0 "
          "rewrote the section to rule panels out, which is what D20 and C29 "
          "are about.",
     rec="Built and published. It also answers a question paper could not: whether "
         "a delegated crew feels like playing or watching (§30.7 premise 3), which "
         "cannot be tested on a board where a human moves the pieces."),

dict(id="D3", kind="deviation", severity="change", status="adopted",
     title="The prototype sits ahead of the determinism spike on the critical path",
     refs=["26.7", "24.2", "26.5"],
     body="§26.7 puts the determinism spike immediately after the paper tests. "
          "Because the paper test became software, a few working sessions of "
          "engineering now precede the spike — exactly what the paper test was "
          "designed to avoid.",
     rec="Accepted: §26.5's own rule is that scope is the lever, and buying the two "
         "project-deciding answers cheaply is worth it. This does <strong>not</strong> "
         "relax the rule that gameplay code waits for the spike. The prototype is "
         "throwaway and written as such."),

dict(id="D4", kind="deviation", severity="change", status="open",
     title="A reconciliation step was inserted before the specification locks",
     refs=["26.7"],
     body="§26.7 goes spike → lock the simulation contract → lock detection "
          "→ lock the law schema → lock saves. Every one of those assumes "
          "there is one specification to lock. Four systems currently have two "
          "(C1, C2, C3, C6), and a fifth has two budgets (C5).",
     rec="Work the blocking half of this register before any lock. It is days of "
         "desk time and the cheapest work in the whole plan."),

dict(id="D5", kind="deviation", severity="change", status="done",
     title="The economy model was rebuilt from scratch",
     refs=["24", "10.2", "14.2", "14.3", "9.3"],
     body="§24 describes a Python model that generated roughly a quarter of the "
          "document's numbers. That model is not in the document, so none of those "
          "numbers could be re-derived or re-tuned (gap G7).",
     rec="Rebuilt at <code>tools/economy_model/</code>. It reproduces the first "
         "month to within 10% and the Keeper curve to within three days, and it "
         "produced findings F1, F2 and F3."),

dict(id="D6", kind="deviation", severity="change", status="proposed",
     title="A launch-scope cut of roughly 40% is proposed",
     refs=["26.1", "26.5", "26.8", "30.8"],
     body="§26.1's launch table asks for 48 laws, 144 creature forms, 44 "
          "resonances, 39 terrain features, 16 buildings, 27 screens and 12 "
          "languages, from one designer, one coding agent and three contractors. "
          "§26.5 says scope discipline is the main risk control and §30.8 ranks "
          "execution as risk #2 — but neither is applied to §26.1.",
     rec="Proposed: 24 laws rather than 48 (the Codex already gates in chapters); "
         "3 form-notes rather than 8; ~20 resonances rather than 44; 2–3 "
         "languages rather than 12 (§20.6 already says this); constellations to "
         "v1.1; wards at 2 levels rather than 5. <strong>The Island Workshop is the "
         "one thing not to cut</strong> — it is the only credible answer to the "
         "content treadmill at this team size."),

dict(id="D7", kind="deviation", severity="change", status="adopted",
     title="A risk was added: delegated control reading as watching",
     refs=["30.7", "30.8", "19.4"],
     body="§30.7 marks premise 3 — that delegated control still feels like "
          "agency — as only <em>conditionally</em> supported, names the failure "
          "mode (“my units are stupid”), and sets a 70% felt-control "
          "threshold. It does not appear in §30.8's ranked register. Meanwhile "
          "§19.4 concedes performative challenge is “almost absent by "
          "design”, and the system that decides it — pathfinding and crew "
          "control — is the largest specification gap (G1).",
     rec="Added at rank ~4. The prototype measures it directly."),

dict(id="D8", kind="deviation", severity="change", status="adopted",
     title="Two risks were re-ranked",
     refs=["30.8", "19.4", "20.10"],
     body="Trust and safety moved from 6 to 8: the design has already engineered "
          "most of that risk away — no free text for minors, no uploads, "
          "structured data only, preset chat. Complexity overwhelming new players "
          "moved from 7 to 6: §19.4 calls it “the biggest risk in the whole "
          "design” and the four-interacting-rules cap is untested.",
     rec="No action beyond ordering the mitigations accordingly."),

dict(id="D9", kind="deviation", severity="change", status="proposed",
     title="Iteration is given a budget",
     refs=["26.8", "19.17", "26.5"],
     body="§26.8 estimates ~270 agent runs (≈810 focused hours) and then states "
          "plainly that the iteration needed to <em>find the fun</em> is unbudgeted. "
          "For a novel genre blend with no reference implementation, that iteration "
          "is normally the majority of the work. §19.17 alone lists nine A/B "
          "experiments, each needing a playable build and a tuning pass.",
     rec="Budget iteration at 1–1.5× the build estimate (a further "
         "200–400 runs) and treat the total as the reference-class figure "
         "§26.5 asks for."),

dict(id="D10", kind="deviation", severity="change", status="proposed",
     title="The document should split into a specification and a research archive",
     refs=["19", "28", "30"],
     body="The document is a buildable spec and an evidence archive in one file, and "
          "§19, §28 and §30 are roughly 40% of the text. Both halves are valuable. "
          "Keeping them together means the spec cannot be read, diffed or "
          "implemented without the archive — and it is part of why four systems "
          "reached v2.3 specified twice.",
     rec="<code>docs/design/spec/</code> carries decisions, one file per system; "
         "<code>docs/design/research/</code> carries why. Cross-reference, never "
         "duplicate. <strong>Started:</strong> <code>spec/detection.md</code> is the "
         "first file, and the twelve content tables in <code>content/</code> are the "
         "data half of the same split."),

dict(id="D11", kind="deviation", severity="change", status="done",
     title="The prototype departs from the document's numbers on purpose",
     refs=["12.6", "12.8", "12.17", "5.4"],
     body="Vault health is 600 rather than 1,500 so cracking takes about eight "
          "seconds; being caught takes 1.6 seconds of contact and takes one crew "
          "member at a time; there are two guards; the island is hand-built. The "
          "first build caught all three crew instantly, which read as unfair rather "
          "than tense and would have produced a false negative on gate 1.",
     rec="<strong>Prototype-only. None of these numbers carries forward.</strong> "
         "The catch-takes-time change is worth considering for the real build, "
         "because instant total capture conflicts with §12.14's rule that failure "
         "stays temporary."),

dict(id="D12", kind="deviation", severity="change", status="adopted",
     title="The published prototype declares no runtime capabilities",
     refs=["13.3", "25.4"],
     body="Server-side result collection would have been convenient, but declaring "
          "the database capability makes an artifact organisation-internal and "
          "unshareable publicly — which defeats the entire point of recruiting "
          "by link.",
     rec="Results are collected in the browser and shown as a copyable code. "
         "<code>tools/parse_gate_results.py</code> scores them."),

dict(id="D13", kind="deviation", severity="change", status="proposed",
     title="The note distribution should be rebalanced before the law table is authored",
     refs=["8.1", "7.4", "24"],
     body="Parsed from all 48 law sheets: Glow is carried by 12 laws, its opposite "
          "Hush by 6. Hush is the <em>hiding</em> note — the raider-favouring "
          "one — and it is the scarcest, while the revealing note is the most "
          "abundant. Since laws are woven by the defender and apply symmetrically, "
          "defenders have both the least reason and the fewest options to weave "
          "Hush. Five of the twelve chords require it.",
     rec="Rebalance toward roughly 8–9 laws per note. §24 freezes the note "
         "count at eight and makes laws the expansion axis, so this is a one-time "
         "cost now and a permanent constraint on every future season's six laws."),

dict(id="D15", kind="deviation", severity="change", status="done",
     title="Summary tables are now generated, not authored",
     refs=["11.2", "7.4", "29.1", "24.9"],
     body="Four register items \u2014 C1, C3, C6 and C19 \u2014 have one cause: the "
          "same facts written down twice by hand, and one copy updated. The "
          "structural fix is that a table which exists only to summarise something "
          "else is never authored, only emitted.",
     rec="<code>tools/generate_docs.py</code> emits §11.2's roster index, §7.4's law "
         "summary and §29.1's formulas appendix from <code>content/</code>. "
         "<code>--check</code> fails the build if a generated file has been "
         "hand-edited, and <code>./tools/check_all.sh</code> runs it. This matters "
         "most for §29.1, which still carries the detection model §12.17 superseded "
         "\u2014 the worst place for a stale number, since it is where an implementer "
         "looks for it. It does not cover prose, which is what D10's split is for."),

dict(id="D14", kind="deviation", severity="change", status="proposed",
     title="Chords should require three laws, not three notes",
     refs=["8.5"],
     body="§8.5 calls chords “the late-game discovery” needing “three "
          "laws in play and a Lab of level 3”. Because 23 of the 48 laws carry "
          "two notes, <strong>all twelve chords are reachable with two laws</strong>, "
          "several with two commons. Slow rivers + Whispers gives Iron bell for 26 "
          "stability — inside a day-2 player's capacity of 51.",
     rec="Require three distinct laws. It is a one-line rule change and it "
         "preserves the stated design intent; the alternatives are to reposition "
         "chords as a mid-game discovery, or to reduce two-note laws (which also "
         "helps D13)."),

dict(id="D16", kind="deviation", severity="change", status="proposed",
     title="The Vault\u2019s load rate is cut fivefold, from 150 a second to 30",
     refs=["12.6", "11.1", "9.4"],
     body="§12.6\u2019s 150-loot-a-second is a published number and this changes it "
          "to 30 for Carriers and 8 for everyone else, with every role able to load "
          "rather than Carriers only. The reason is F5: at 150 a second the phase "
          "the document calls its central decision is two seconds long and has one "
          "option.<br><br>The replacement rate is not a guess. §12.6 sets its own "
          "target of <strong>one decision every 8\u201312 seconds</strong>, and a "
          "loading window shorter than one decision cannot contain a decision; 30 a "
          "second puts a full crew load at exactly ten. The rate scales with "
          "character level alongside Carry (§11.4), so the ten seconds holds for the "
          "whole game.",
     rec="Accepted in <code>docs/design/spec/vault.md</code>, flagged for sign-off "
         "because it is a large move on a published figure. The only alternative "
         "that preserves the decision is raising carry capacity fivefold, which "
         "breaks §9.4\u2019s exposure percentages and §11.1\u2019s role balance "
         "instead. Doing neither means deleting the sentence that calls the Vault "
         "phase a decision."),

dict(id="D17", kind="deviation", severity="change", status="proposed",
     title="Ambush damage gains a floor, so the document\u2019s own rule becomes true",
     refs=["12.8", "11.1"],
     body="§12.8\u2019s ambush is triple Power. F4 measures what that delivers: the "
          "same section\u2019s claim that two ambush hits drop an equal-level guard "
          "is true for three of twenty-five pairings. This adds a floor \u2014 an "
          "ambush deals triple Power <em>or</em> half the target\u2019s maximum "
          "health, whichever is greater \u2014 which changes a formula the document "
          "states in order to satisfy a rule the document also states.",
     rec="Where two of the document\u2019s own sentences cannot both hold, the one "
         "expressing <em>intent</em> wins over the one expressing a coefficient: "
         "\u201ctwo ambush hits knock out a guard\u201d is a design statement about "
         "how stealth pays off, and \u201ctriple damage\u201d is a number chosen to "
         "deliver it. Half is the value that makes the intent exactly true; a third "
         "would need three ambushers, which a crew of three (§12.5, before Keeper 8) "
         "cannot spare, quietly deleting the tactic for early players."),

dict(id="D18", kind="deviation", severity="change", status="done",
     title="Two recorded gaps were wrong, and the register now says so",
     refs=["10.2", "10.3", "12.6"],
     body="G3 recorded that ward levels 2\u20135 are unspecified and G5 that law "
          "pylons have no health and no stated relationship to law slots. Both are "
          "in §10.2\u2019s building tables \u2014 wards at effect +15/30/45/60% with "
          "resets 10\u21926 s, pylons at 600 health a level and \u201cone per law "
          "slot\u201d. G5\u2019s own text admitted the table had not been examined; "
          "G3\u2019s did not.<br><br>The cause is the one this whole register is "
          "about, turned on the analysis itself: <strong>a fact written in two "
          "places, and only one of them read</strong>. The design document specifies "
          "wards in §10.3 and prices them in §10.2, and reading either alone gives a "
          "wrong answer about the other.",
     rec="Both items are corrected in place rather than deleted, because what "
         "survives of each is real and because a register that quietly drops its "
         "mistakes is not an audit. <code>docs/design/spec/wards.md</code> opens "
         "with the correction. The general lesson is recorded here rather than "
         "absorbed: <strong>before recording something as unspecified, check "
         "whether it is specified in a table somewhere else</strong> \u2014 which "
         "is exactly the failure mode the document itself keeps exhibiting."),

# ===========================================================================
# Blocking — these prevent content authoring or core code
# ===========================================================================

dict(id="C1", kind="contradiction", severity="blocking", status="proposed",
     title="Two incompatible detection models",
     refs=["12.8", "12.17", "5.4", "29.1"],
     body="§12.17 specifies three vision zones inside a 30–45° cone plus "
          "peripheral vision, a 0–1000 suspicion meter, six guard states and "
          "noise travelling along walkable paths. §12.8 specifies one 120° cone "
          "at 6 tiles, awareness in percent per second, and two states. §12.17 "
          "presents itself as the fix, but §12.8 is left intact, §5.4's landing rule "
          "is written in the old percentage model, and <strong>§29.1, the formulas "
          "appendix, encodes the old model</strong>.",
     rec="<strong>Drafted.</strong> <code>docs/design/spec/detection.md</code> states "
         "§12.17 once, with the four edits it forces spelled out: §12.8 becomes "
         "behavioural description only, §5.4's landing noise is restated as 250 of "
         "1000 suspicion, §29.1 is regenerated, §21.12 is already correct. The "
         "numbers are data in <code>content/detection.json</code> and validated. "
         "Awaiting sign-off before the lock in §26.7."),

dict(id="C2", kind="contradiction", severity="blocking", status="proposed",
     title="Two incompatible raid-payout models, differing by 16–30×",
     refs=["9.4", "9.6", "12.1", "12.9"],
     body="§9.4 pays a percentage of what the defender holds; §9.6 replaces it with "
          "a haul minted from the raider's own level and says so explicitly — "
          "but §9.4's percentages and §12.9's multipliers remain. Run through the "
          "economy model, <strong>§9.4 delivers 32% of a player's income, "
          "reproducing its own stated “roughly a third” almost exactly, "
          "while §9.6 delivers 1–2%</strong>. Strong evidence that §9.4 "
          "generated the published progression tables and §9.6 was added afterwards "
          "without re-running them.",
     rec="§9.6 is the better-reasoned model — minting is right when loot is "
         "created rather than transferred. Then: delete §9.4's percentages and "
         "§12.9's loot column; say what Carrier capacity now means (probably time "
         "pressure, not a cap on value — see G4); rewrite §9.4's and §12.1's "
         "resource-share claims; and resolve C4 first, since the formula's level "
         "term is undefined."),

dict(id="C3", kind="contradiction", severity="significant", status="open",
     title="Two law-rarity taxonomies, and v3.1 already chose between them "
           "everywhere but two sentences",
     refs=["7.4", "7.6", "7.7", "7.9", "9.5", "14.4", "27.2", "29.2"],
     body="Against v2.3 and v3.0 this was a 345-page decision. <em>What is "
          "authored</em> \u2014 the 48 law sheets in \u00a77.7 \u2014 said "
          "three ranks at 15/30/60, \u00a714.4 totalled 1,485 pages from "
          "exactly that, and \u00a77.9 described five ranks at 10/20/35/60/120. "
          "<strong>v3.1 settled it and the register did not notice.</strong> The "
          "sheets carry 18 common, 12 uncommon, 6 rare and 12 deep; "
          "\u00a714.4 now computes <code>18 \u00d7 10 + 12 \u00d7 20 + 6 "
          "\u00d7 35 + 12 \u00d7 60 = 1,350</code> from that split; "
          "\u00a77.1\u2019s glossary and the change log say the same."
          "<br><br><strong>Two sentences in the whole document still "
          "disagree.</strong> \u00a77.6\u2019s restore line prices three ranks "
          "and never mentions Uncommon at all \u2014 that is F24\u2019s "
          "sentence and C23\u2019s one surviving edit. \u00a77.9\u2019s table "
          "still counts 18/14/10/6."
          "<br><br><code>tools/law_ranks.py</code> prices all three. The sheets\u2019 "
          "split costs nothing to adopt, because it is what the sheets are "
          "already tagged with and what \u00a714.4 already computes. "
          "\u00a77.9\u2019s would move six sheets and is the only one of the "
          "three that cannot give every school the same ladder \u2014 14 and 10 "
          "do not divide by six, and \u00a77.9\u2019s own table asserts the "
          "even spread for the two ranks that do (<em>\u201cThree per "
          "school\u201d</em>, <em>\u201cOne per school\u201d</em>) and says "
          "nothing about the two that do not. The sheets give every school "
          "3 / 2 / 1 / 2.",
     rec="Adopt the sheets: change four numbers in \u00a77.9\u2019s table and "
         "one sentence in \u00a77.6, both drafted below. Nothing is re-tagged "
         "and no total moves, because every other statement in the document is "
         "already on this split."
         "<br><br><strong>The Codex screen is no longer waiting on this.</strong> "
         "It shows 48 laws in four ranks at 10/20/35/60, which is what the "
         "sheets, \u00a714.4 and the glossary have said since v3.1 \u2014 so "
         "this is a document contradiction to close rather than a screen "
         "decision to make."
         "<br><br>What is still a decision is the rule underneath the counts, "
         "which \u00a77.9 exists to state and the sheets do not obey. That is "
         "D31, and it is separated out because re-costing 48 laws is a "
         "different job from correcting a table."),

dict(id="C4", kind="contradiction", severity="blocking", status="proposed",
     title="The master inflation dial is keyed to a level range that does not exist",
     refs=["5.2", "9.4", "9.6", "13.4"],
     body="§5.2's outer-realm table stops at level 5. §9.6's haul table quotes realm "
          "levels 2, 6 and 10, and attributes the 40%→71.5% sealed share to "
          "“realm level” — but §9.4 attributes that same share to the "
          "<em>Vault</em>, which does have ten levels. So §9.6 appears to have "
          "conflated the two and then built <code>B(L) = 100 × 1.5^(L−1)</code>, "
          "which §9.6 itself calls “the master inflation lever”, on top of "
          "the conflation. At L=10 that is 25× its value at L=5.",
     rec="Decide what L is — most likely Vault level or a composite "
         "target-strength score. If realms really cap at 5, the entire payout table "
         "is wrong by about 7×."),

dict(id="C5", kind="contradiction", severity="blocking", status="proposed",
     title="Two defence budget systems, with three different ward limits",
     refs=["5.2", "5.5", "13", "13.4", "10.2"],
     body="§5.5 has one universe-wide stability pool from the Spire and Anchor "
          "Stones, with laws costing 10–26. §13.4 introduces a <em>per-realm</em> "
          "pool of 100/336/1,504 with laws at a flat 30/40. Ward limits appear three "
          "times: §5.2 and §10.2 say 4–8 per realm (3 + realm level), §13 says "
          "“three to seven”, §13.4 says 2–9. Guard posts: §5.2 says "
          "1–3, §13.4 says 3–10 guards.",
     rec="§13.4's <em>mechanism</em> is right — slot limits per layer are what "
         "enforce the “no layer above a quarter” rule, and cost alone "
         "cannot. Keep the limits, drop the second pool, price the layers in an "
         "explicitly named budget (parallel to terrain points), and reconcile the "
         "ward and guard numbers into one table in §5.2."),

dict(id="C6", kind="contradiction", severity="blocking", status="proposed",
     title="Two ruleborn rosters \u2014 the roles agree now, and the abilities "
           "are two designs rather than two wordings",
     refs=["11.2", "11.11", "11.5", "12.5", "12.8"],
     body="The same 18 creatures are specified twice. Against v2.3 and v3.0 the "
          "two disagreed about what three of them <em>were</em>: Prism Mite a "
          "Carrier in \u00a711.2 and a Scout in \u00a711.11, Stormhound a Scout "
          "then a Carrier, Rootrunner a Carrier then a Scout \u2014 a different "
          "role distribution, and role drives crew composition, guard behaviour "
          "(\u00a712.8) and the Nursery\u2019s fewest-roles-first rule "
          "(\u00a711.5)."
          "<br><br><strong>v3.1 closed that half, and nothing said so.</strong> "
          "Both sections now give the same school and role for all 18, with the "
          "same distribution \u2014 3 Scout, 3 Breaker, 4 Carrier, 4 Warden, 4 "
          "Mender. The check that was watching this reported only role "
          "conflicts, so it went silent the moment they reconciled. A check that "
          "loses its subject reads exactly like a check that passes."
          "<br><br><strong>What is left was recorded as wording, and it is "
          "not.</strong> <code>tools/ability_text.py</code> reads the 18 pairs "
          "out of <code>content/ruleborn.json</code>:"
          "<br><br><strong>Cooldowns run one way.</strong> Fifteen pairs state "
          "one on both sides; \u00a711.2\u2019s is shorter in thirteen, equal "
          "in one, longer in one, with a median gap of four seconds. A "
          "difference that runs one way in thirteen of fifteen is two balance "
          "passes, not two people wording one number."
          "<br><br><strong>Twelve of the eighteen do a different thing.</strong> "
          "Mossbear takes 50% less damage in \u00a711.11 and heals 20% in "
          "\u00a711.2 \u2014 mitigation and healing are different resources. "
          "Prism Mite splits into copies with half the <em>health</em>, or into "
          "mites each carrying half the <em>loot</em>. Echoplate shields the "
          "whole crew and reflects at 40%, or shields one ally and reflects "
          "nothing. Quarryback, Tidewalker and Echoplate state no cooldown in "
          "\u00a711.11 at all, because there \u00a711.11 describes something "
          "continuous and \u00a711.2 an activated power. Even Sparkwright, the "
          "one pair whose numbers agree exactly, cuts <em>an ally\u2019s</em> "
          "cooldown in one and <em>the Sage\u2019s</em> in the other \u2014 "
          "and \u00a712.5 makes the Sage a separate slot from the crew.",
     rec="Design the eighteen abilities once, then give them one home."
         "<br><br><strong>\u00a711.11 is the home</strong> \u2014 it is the "
         "character bible and it already carries look, proportions, personality "
         "and habits, none of which \u00a711.2 has an opinion about. "
         "\u00a711.2 becomes a summary that cites it, which is \u00a731.2\u2019s "
         "rule and the same fix C27 and C28 need."
         "<br><br><strong>All eighteen are now drafted.</strong> "
         "<code>tools/ability_text.py</code> picks one text for each \u2014 "
         "seven from \u00a711.11, six from \u00a711.2, five that need both "
         "\u2014 and argues every pick from the creature\u2019s role or from "
         "a system the document already has, never from taste. Eighteen picks "
         "argued from taste is a redesign and needs a designer; eighteen argued "
         "from \u00a712.6, \u00a712.19 and \u00a711.11 is a reading of the "
         "document that can be disagreed with line by line. The table is in "
         "<code>docs/design/spec/ruleborn.md</code> and the reasons are printed "
         "in full by the tool."
         "<br><br><strong>The cooldowns are not picked, because they cannot be "
         "picked from a column.</strong> Both tables are two to three times "
         "over \u00a712.6\u2019s budget for the whole run, so either column "
         "takes its number from a table that does not fit the game around it. "
         "That is D32, it is one decision rather than eighteen, and every "
         "cooldown follows from it."
         "<br><br><strong>This holds the screens and not the art.</strong> A "
         "character screen shows the ability text, so it cannot be drawn; a "
         "character\u2019s portrait needs a look, a role and a school, and all "
         "three have been settled since v3.1."),

dict(id="C19", kind="contradiction", severity="blocking", status="open",
     title="The production tables describe a universe the build rules do not permit",
     refs=["9.3", "5.2", "11.5", "10.2", "14.2", "14.3"],
     body="§9.3's published production figures fit a universe with <strong>one</strong> "
          "producer of each kind per realm, fully staffed. §5.2 permits <strong>two</strong> "
          "from realm level 3. And §11.5's roster ceiling of 38 characters cannot "
          "fully staff even the one-producer version, which needs 63 worker slots. "
          "All three tables cannot be correct at once. See findings F1 and F2.",
     rec="Decide the building and roster rules, then regenerate §9.3, §10.2, §14.2 "
         "and §14.3 from the economy model rather than editing them by hand — "
         "hand-editing is what produced this."),

# ===========================================================================
# Design findings — not clerical; these change how the game plays
# ===========================================================================

dict(id="F1", kind="finding", severity="design", status="open",
     title="The roster cannot staff the universe the rules permit",
     refs=["5.2", "10.2", "11.5", "9.3", "4"],
     body="Pure arithmetic from three published tables. A finished universe has "
          "<strong>152 character positions</strong> — 126 producer worker slots "
          "(7 realms × 2 of each producer × 3 kinds × 3 slots), 21 guard "
          "posts, a crew of five — against a <strong>roster ceiling of 38</strong> "
          "(3 at the Spire plus 7 Hearths × 5 homes). That is 25% coverage; the "
          "roster would need to be four times larger. Even production alone at one "
          "producer per realm needs 63 workers, before a single guard is posted.",
     rec="This may be intentional — §4 names characters' time as one of two "
         "scarce resources. But three things follow that the document has not "
         "absorbed: §9.3's production figures are unstaffable; 25% coverage reads as "
         "“most of my buildings are idle” rather than as interesting "
         "scarcity; and the marginal Star Well becomes worthless, which removes a "
         "large part of §10.2's Starlight sink. Decide which lever moves: more "
         "Hearth homes, fewer permitted producers, or partial staffing made "
         "genuinely worthwhile."),

dict(id="F2", kind="finding", severity="design", status="open",
     title="Building the second producer doubles income and breaks every pacing date",
     refs=["9.3", "5.2", "14.2", "14.3"],
     body="Solving backwards from §9.3's day-301 figure implies about seven fully "
          "staffed Star Wells at level 9 — one per realm, not the fourteen §5.2 "
          "allows. Running the economy model under all four readings, only "
          "“one producer per realm, no binding roster cap” tracks the "
          "document (117% of published at day 301; Keeper 40 on day 171 against a "
          "published 181). Every other reading is out by 2–4×.",
     rec="A player who builds the second producer — a pure production gain, so "
         "everyone will — earns roughly <strong>twice</strong> what §14 "
         "predicts, and every “engaged player reaches this on day X” "
         "milestone becomes optimistic. Given F1, the second producer may be exactly "
         "the wrong thing to permit."),

dict(id="F3", kind="finding", severity="design", status="open",
     title="The core trade-off the design is built on does not bind",
     refs=["4", "11.6", "12.6", "12.9", "9.6"],
     body="§4 and §11.6 build the whole design on characters' time: “raiding "
          "more means earning less at home and defending worse”. A heist is 3 "
          "minutes and a clean escape rests the crew 45, so a crew of five raiding "
          "four times a day is withheld for 16 character-hours out of 744 — "
          "<strong>about 2% of production</strong>. With §9.6 returning 1–2%, "
          "the raid-versus-build tension is absent from the arithmetic entirely.",
     rec="The scarcity the design needs already exists in F1 — it is simply not "
         "connected to raiding. Make crew membership an assignment that excludes "
         "work, the way guarding does, so five of 38 are committed rather than 0.67. "
         "The alternative is to lengthen rest substantially, which §12.14's "
         "temporary-failure principle argues against. Doing neither means dropping "
         "the claim in §4 and §11.6."),

dict(id="F4", kind="finding", severity="design", status="open",
     title="§12.8\u2019s knockout rule is true for three of twenty-five role pairings",
     refs=["12.8", "11.1", "11.4"],
     body="\u201cTwo ambush hits knock out a guard of equal level\u201d is the only "
          "statement in the document about how a fight ends. Read with the one "
          "cadence the document gives \u2014 §12.8\u2019s own 0.8-second wind-up, "
          "one hit for damage equal to Power \u2014 it holds for <strong>three of "
          "twenty-five</strong> role pairings, or five under the most generous "
          "reading, and four of those five need a Breaker. A Mender attacking a "
          "Warden needs <strong>68 hits, or 54 seconds</strong>, against a guard the "
          "ambush stunned for two. The rule requires Power = Health \u00f7 4; the "
          "Breaker is 1.1\u00d7 short and the other four roles are 2.5\u00d7 to "
          "5.4\u00d7 short.<br><br>This is the same shape as C2 and F1: Power and "
          "Health were set for standing fights and home defence, where a Warden "
          "<em>should</em> take a long time to drop, and the ambush rule was written "
          "against them later without anyone multiplying the numbers together. "
          "<code>python3 tools/decision_support.py combat</code>.",
     rec="Fixed in <code>docs/design/spec/fights.md</code> by giving the ambush a "
         "floor: triple Power <em>or</em> half the target\u2019s maximum health, "
         "whichever is greater. Two ambushers then drop any equal-level guard in all "
         "25 pairings \u2014 the stated rule, true by construction \u2014 while the "
         "Breaker\u2019s one-shot on a Scout survives because the triple-Power term "
         "still wins there. The alternative, re-tuning Power or Health, moves home "
         "defence and every guard duel with it."),

dict(id="F5", kind="finding", severity="design", status="open",
     title="The Vault\u2019s loading phase lasts two seconds and 46% of crew capacity is unreachable",
     refs=["12.6", "11.1", "9.4"],
     body="§12.6 budgets the Vault phase at about 30 seconds and names "
          "\u201cwhen to stop loading\u201d as its central decision. Its own "
          "numbers say otherwise. A Carrier holds 300 loot and loads 150 a second, "
          "so loading takes <strong>2.0 seconds</strong>; and because §12.6 has only "
          "Carriers load, <strong>260 of a five-crew\u2019s 560 units of capacity "
          "cannot be filled by any means the document describes</strong>. The thirty "
          "seconds is cracking, and cracking is a progress bar with no decision in "
          "it.<br><br>The same arithmetic produced the one place the document\u2019s "
          "numbers <em>corroborate</em> each other: cracking takes 10\u201325 "
          "seconds across the whole game against a phase length written in a "
          "different section from Vault health, which was written in a different "
          "section again from role Power. "
          "<code>python3 tools/decision_support.py vault</code>.",
     rec="<code>docs/design/spec/vault.md</code> lets every role load, at a rate "
         "scaling with Carry, so the crew fills in ten seconds \u2014 one decision "
         "by §12.6\u2019s own 8\u201312 second cadence. That is a <strong>fivefold "
         "cut to a published rate</strong> and should be flagged as such at "
         "sign-off; the alternative, raising carry capacity fivefold, breaks "
         "§9.4\u2019s exposure percentages instead."),

dict(id="F6", kind="finding", severity="design", status="open",
     title="The Breaker is 63% of the crew's damage against every breakable object",
     refs=["11.1", "12.6", "10.2", "12.5"],
     body="§11.1 gives the Breaker double damage to wards, pylons and the Vault. "
          "Against all three its doubled Power of 80 is <strong>63% of a "
          "five-crew\u2019s 126</strong>, so adding four characters to a lone "
          "Breaker cuts the time by 37%. §12.6 lists \u201cwho cracks\u201d among "
          "the Vault phase\u2019s decisions; it has one answer, in every situation, "
          "at every level \u2014 and so do \u201cwho smashes the ward\u201d and "
          "\u201cwho breaks the pylon\u201d. A Scout needs 14 seconds on the "
          "cheapest ward a Breaker clears in two.<br><br>This is the same shape as "
          "F5, reached from the other end: a sub-phase named as a decision that "
          "contains none.",
     rec="Three defensible answers and the choice is a balance judgement: narrow "
         "the Power spread; give a second character on the same object a stacking "
         "bonus, so joining in is worth the exposure; or accept it as role identity "
         "and stop calling it a decision. What is not defensible is keeping the "
         "sentence while one role is two thirds of the answer. "
         "<code>python3 tools/decision_support.py wards</code>."),

# ===========================================================================
# Significant
# ===========================================================================

dict(id="C7", kind="contradiction", severity="significant", status="proposed",
     title="Tick rate: 20 Hz or 30 Hz?",
     refs=["7.3", "24", "24.10"],
     body="§7.3 and §24's engine table both say 20 steps a second. §24.10, the later "
          "simulation contract, says 30 and is self-consistent — it states a "
          "heist is 4,500–7,200 ticks, which is exactly 30 × 150–240 "
          "seconds. It also says “drop to 20” if a cheap phone cannot hold "
          "it, so 20 may be a pre-emptive fallback that leaked upward.",
     rec="30 Hz per §24.10; fix §7.3 and §24. Settle this <strong>before</strong> "
         "the golden replays are written, since they encode it and every duration "
         "expressed in ticks depends on it."),

dict(id="C8", kind="contradiction", severity="minor", status="open",
     title="The Library was specified in v3.1; the art schedule was not told",
     refs=["7.6", "10.2", "10.4", "12.1", "21.9", "26.1", "30.15"],
     body="\u201cA Library at the Heart produces about one page per realm every "
          "few hours\u201d is the mitigation for the problem review 10 "
          "identified \u2014 that making pages raid-only punishes the large "
          "share of players who prefer building. It was referenced four times "
          "and specified nowhere: not among \u00a710.2\u2019s sixteen building "
          "types, no cost, no levels, no placement rule, and \u00a726.1 "
          "confirmed sixteen types at launch."
          "<br><br><strong>v3.1 specified it.</strong> \u00a710.4 opens "
          "<em>\u201ca load-bearing faucet that four sections referenced and no "
          "table contained: the seventeenth building type, at the Heart, one per "
          "universe\u201d</em> and gives all ten levels, from 900 Starlight and "
          "3 pages a day at level 1. \u00a726.1 says seventeen. The build "
          "screen has a building to draw and the economy model has a curve to "
          "price \u2014 both of which it now does, at all ten levels rather "
          "than three (D30)."
          "<br><br><strong>Two places did not follow.</strong> \u00a710.2 is "
          "headed <em>Every level of every building</em> and still does not "
          "contain it, which is how this happened the first time. And "
          "\u00a721.9\u2019s launch asset budget still prices <code>Building "
          "looks (16 types \u00d7 4)</code> at 64, so the art schedule is four "
          "building looks short."
          "<br><br>The second is the one worth the check rather than the edit. "
          "\u00a721.9 is a budget for the content \u00a726.1 lists, so every "
          "row in it is a second home for a number specified elsewhere, and "
          "nothing compared the two \u2014 <code>16 \u00d7 4 = 64</code> is "
          "correct arithmetic about the wrong sixteen, so the check that "
          "multiplies out every inline product passes it. "
          "<code>tools/check_document.py</code> now derives the budget rows from "
          "the same inventory \u00a726.1 is checked against.",
     rec="Move \u00a710.4\u2019s table into \u00a710.2 between Ward and "
         "Resonance Lab, which C24 drafts, and raise \u00a721.9 to "
         "<code>17 types \u00d7 4</code> = 68."
         "<br><br><strong>The Library screen is no longer waiting on this.</strong> "
         "It is a building with ten levels, a cost curve and a place, which is "
         "everything a build-screen entry needs. What is left is where the table "
         "is printed and four looks in the art schedule."),

dict(id="C29", kind="contradiction", severity="blocking", status="open",
     title="v3.0 removed the playtesters and kept two phase gates that "
           "require them",
     refs=["25.4", "19.27", "26.2"],
     body="§25.4 opens by ruling the panels out, in a sentence with no "
          "room in it: <em>“No recruited panels, no paid playtesters, no "
          "thirty people in a room.”</em> §19.27 moves every "
          "instrument that needs a person to soft launch — <em>“all "
          "that once needed a room now waits for soft launch”</em> — "
          "and states the cost plainly: nothing before soft launch tells us "
          "the game is fun.<br><br>§26.2 then gates two phases on exactly "
          "those people. Phase 2, the vertical slice, exits on <em>“At "
          "least 7 of 10 outside playtesters ask for a second "
          "session”</em>. Phase 3, alpha, exits on <em>“at least 20% "
          "of testers still playing after a week”</em>. Both sit "
          "<strong>two phases before soft launch</strong>, which is the "
          "earliest point §19.27 and §25.4 allow a player to "
          "exist.<br><br>This is the supersession pattern the register already "
          "tracks in C8, C10 and the detection model — a fix landing in "
          "one section and not in the ones that depend on it — but it is "
          "worse in kind. The others are a number that disagrees with another "
          "number. <strong>This is a phase gate that cannot be passed as "
          "written</strong>, on the critical path, twice. Phase 2 is 10 to 12 "
          "weeks of work that by its own exit test cannot be exited, and no "
          "section names where the ten testers would come from, how they are "
          "recruited, or what they are given to play. The first testing venue "
          "named anywhere in the document is TestFlight, in phase 4.",
     rec="Drafted in <code>docs/design/spec/validation.md</code>, with the "
         "three edits it forces spelled out. Decide which document is "
         "true, and say so in both places. Either "
         "(a) §25.4 is right and §26.2’s phase 2 and 3 exit "
         "tests are rewritten against the harness and the developer-as-player "
         "— in which case say what phase 2 <em>does</em> exit on, because "
         "“no gate” is not an answer for 10 to 12 weeks of work; or "
         "(b) the ten testers are real, in which case §25.4’s "
         "opening sentence is false and the plan owes a recruitment route, a "
         "delivery channel and a consent and privacy position, none of which "
         "exist.<br><br>Worth noting which way the evidence leans: "
         "§26.2’s phase 2 gate — <em>would they come back "
         "unprompted</em> — is the single most informative thing in the "
         "whole phase table, and it is the one §19.27 admits simulation "
         "cannot replace. Deleting it is cheap and costs the most. This is "
         "flagged blocking for that reason, not for the wording."),

dict(id="F24", kind="finding", severity="blocking", status="open",
     title="v3.1\u2019s supersession check passes on a document that still "
           "contains the model it was written to ban",
     refs=["31.5", "31.9", "7.6", "9.5", "29.2"],
     body="v3.1 bans four superseded models by regular expression and reports "
          "all four absent. One of them is not.<br><br>The pattern for the "
          "retired three-rank page costs is <code>15, 30 or 60 pages</code>. "
          "\u00a79.5 and \u00a729.2 were both rewritten to the five-rank "
          "<code>10, 20, 35 or 60</code>, so the pattern finds nothing and the "
          "check goes green. <strong>\u00a77.6 still says it, in different "
          "words</strong>, in normative text:<br><br><code>Restoring a law: 15 "
          "pages for a common law, 30 for a rare one, 60 for a deep one.</code>"
          "<br><br>Same model, same three ranks, same numbers, one clause "
          "rearranged \u2014 and the check cannot see it. This register\u2019s "
          "own <code>check_edits.py</code> found it from the other side: of "
          "C23\u2019s four drafted edits, three no longer match the document "
          "because the sentences were fixed, and <strong>the fourth still "
          "matches exactly</strong>.<br><br>The general fault is not this "
          "regex. It is that <strong>a banned-phrasing check can only prove a "
          "phrasing absent, never a model</strong>, and it reports the stronger "
          "claim. \u00a731.5 calls these checks \u201ca string or an "
          "arithmetic comparison over the built artefact, so it cannot be "
          "argued with\u201d \u2014 true, and the thing it cannot be argued "
          "with about is narrower than the name on the check.",
     rec="Two changes, and the second is the one that generalises."
         "<br><br><strong>1. Fix \u00a77.6</strong>, which is C23\u2019s "
         "surviving edit and a one-line replacement."
         "<br><br><strong>2. Derive the ban from the data rather than from a "
         "phrase.</strong> The page costs live in one place; a check that "
         "recomputes every price in the document against that table catches any "
         "phrasing, including ones nobody thought of. The same applies to the "
         "other three bans: \u201cone 120\u00b0 cone\u201d does not cover "
         "every way to write a single-cone model.<br><br>This is "
         "\u00a731.4\u2019s own rule \u2014 generated, not authored \u2014 "
         "pointed at the checks instead of the tables. A hand-written list of "
         "forbidden strings is an authored artefact, and it drifts from the "
         "thing it describes exactly as C21 to C24 did."
         "<br><br><strong>Two of the four bans are now derived, and the "
         "second one closed a blocking item nobody had noticed was "
         "closed.</strong> The detection model is read out of \u00a712.17\u2019s "
         "own two tables rather than searched for: every guard row has a cone, "
         "at least two graded zones inside it and a corner-of-the-eye angle "
         "<em>wider than the cone</em> \u2014 a property a single-cone model "
         "cannot be given by rewording \u2014 and every guard-state threshold "
         "stated anywhere in the prose has to resolve against \u00a712.17\u2019s "
         "table, so <em>investigate at 50%</em> fails because 50 is not 600 "
         "rather than because of the percent sign. <code>--self-test</code> "
         "plants the retired model in other words and prints the ban green "
         "beside the derived check red."
         "<br><br>It also reads <code>content/detection.json</code> against the "
         "same two tables, which nothing did: the content file was checked for "
         "internal consistency and never against the section it was extracted "
         "from, which is D30\u2019s fault with the version pointer fixed and "
         "the numbers still unchecked."
         "<br><br><strong>All four bans are derived now (D38).</strong> The "
         "other two followed: retired names read case-insensitively with word "
         "boundaries, and every constant read by its <em>unit</em> rather than "
         "by the one sentence that defines it, so a second tick rate stated in "
         "any other words is compared against \u00a724.10 instead of against "
         "nothing. Six restatements of the four defects, in the wording a "
         "writer would reach for: the shipped gate catches none, this one "
         "catches all six."
         "<br><br>It is tracked to C21 and C1, both closed, so it reports PASS "
         "rather than silence \u2014 and if either model ever comes back in any "
         "wording, a tracked check failing on a closed item breaks the build "
         "instead of quietly reopening an argument."
         "<br><br><strong>The page-cost half is built; \u00a77.6 is still "
         "yours.</strong> <code>tools/check_document.py</code> derives the page "
         "costs rather than recognising them: it reads the rank table, reads all "
         "48 sheets, and then checks every rank-to-pages claim in the document "
         "in each of the three grammatical forms that carry one \u2014 the "
         "enumerated <em>\u201c10, 20, 35 or 60 pages by rank\u201d</em>, the "
         "arithmetic <em>\u201c18 common \u00d7 10 + \u2026\u201d</em>, and "
         "the prose form \u00a77.6 uses. It reports \u00a77.6. "
         "<code>--self-test</code> plants that sentence in an otherwise clean "
         "document and prints both verdicts side by side, so the gap is "
         "demonstrated rather than described.<br><br>v3.1\u2019s four phrase "
         "bans are <strong>kept</strong> alongside it, because a verbatim "
         "reintroduction is a real way for a deleted model to return and they "
         "catch it for nothing. What changed is that they are no longer the only "
         "guard on their models. <strong>This item stays open because \u00a77.6 "
         "still says it</strong> \u2014 the checking gap is closed, the document "
         "fault is not, and those were always two different things.",
     measured=None),

dict(id="F26", kind="finding", severity="blocking", status="open",
     title="§13.2’s hold band falls inside a gap the defence cannot "
           "enter at realm 1",
     refs=["13.2", "19.27", "10.2", "5.2", "12.6", "13.3"],
     body="§13.2 wants a defence to hold 30 to 45% of raids. §19.27 "
          "wants a median run to carry 15 to 25 decisions. The two are set in "
          "different sections and never checked against each other, and F7 "
          "already showed the second is a statement about <em>depth</em> — "
          "10 decisions across one realm, 17 across two, 24 across three. So "
          "the depth is fixed by §19.27 before the hold rate is measured "
          "at all.<br><br>Swept across every setting §10.2 and §5.2 "
          "permit — one to three guard posts, nought to two geometry "
          "bands, Guardian Post levels 1 to 5 — at the depths "
          "§12.6’s decision band implies. <strong>At realm 1, none of "
          "the 24 combinations reaches both bands.</strong> Not one.<br><br>"
          "At three realms crossed, with the decision count comfortably inside "
          "§19.27’s band:<br><br><code>strongest island on one post "
          "&nbsp;<strong>24.2% ± 1.5</strong> &nbsp;3.8 SE below the band<br>"
          "weakest island on two posts &nbsp;&nbsp;<strong>62.4% ± 1.7"
          "</strong> &nbsp;10.1 SE above it</code> "
          "<span style=\"opacity:.7\">(n=800 a cell)</span><br><br><strong>A "
          "38-point gap, and §13.2’s band is 15 points wide and sits "
          "entirely inside it.</strong> The smallest unit of defence the "
          "document has is one guard, and at realm 1 that unit is worth two and "
          "a half times the width of the band it has to land in. You cannot "
          "tune an integer.<br><br>§10.2’s Guardian Post ladder is the "
          "one dial finer than a whole guard, and it was built into the harness "
          "for this item rather than assumed away. It does not rescue realm 1: "
          "its entire range moves the hold rate 15.0% to 20.0% there. What it "
          "does elsewhere is F27.<br><br><strong>Realm 2 is the case that can "
          "be fixed, and the fix arrives late.</strong> One post and two bands "
          "holds 21.5% at post level 1 and <strong>31.5% at level 5</strong>, "
          "inside the band. But §10.2 prices a level-3 post at 4,060 "
          "Starlight and its own column says an engaged player builds one on "
          "<strong>day 36</strong>, while §5.2 opens realm 2 at Keeper 6 "
          "and §14.2 puts an engaged player there on <strong>day 5</strong>. "
          "<strong>Thirty-one days defending a realm that cannot reach the band "
          "the document sets for it</strong>, and longer for everyone slower: "
          "day 8 for a regular player, day 16 for a casual one.<br><br>"
          "<strong>Why it bites at realm 1 and not above.</strong> §5.2 "
          "gives posts by <code>1 + (level−1)÷2</code>, so the "
          "smallest increment available to the guard layer is a share of what "
          "is already there: +100% at realms 1 and 2, +50% at realms 3 and 4. "
          "Measured, that is what the jump looks like — adding the second "
          "post at realm 1 is worth <strong>+45.7 points</strong> of hold rate, "
          "while adding the third at realm 3 is worth <strong>+12.5</strong>. "
          "Part of the difference is the ceiling rather than the step, since "
          "realm 3 is already at 85% before the third post, so this is offered "
          "as the shape of the mechanism and not as a clean decomposition."
          "<br><br><strong>One thing that is <em>not</em> the mechanism, "
          "recorded because this item asserted it first.</strong> An earlier "
          "draft observed that §5.2 grows the grid every level while the "
          "post count does not, so coverage sawtooths — 100 tiles a guard "
          "at realm 1, 121 at realm 2, 72 at realm 3 — and said defence "
          "per tile therefore falls on the level a player has just reached. The "
          "arithmetic is right and it predicts nothing. With posts forced to one "
          "at every realm, so coverage falls monotonically from 100 to 196 tiles "
          "a guard, the hold rate <em>rises</em> monotonically:<br><br><code>"
          "realm &nbsp;tiles/guard &nbsp;wards &nbsp;&nbsp;&nbsp;hold<br>"
          "&nbsp;&nbsp;1 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;100 &nbsp;&nbsp;&nbsp;"
          "&nbsp;&nbsp;4 &nbsp;&nbsp;19.2% ± 2.0<br>"
          "&nbsp;&nbsp;3 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;144 &nbsp;&nbsp;&nbsp;"
          "&nbsp;&nbsp;6 &nbsp;&nbsp;26.2% ± 2.2<br>"
          "&nbsp;&nbsp;5 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;196 &nbsp;&nbsp;&nbsp;"
          "&nbsp;&nbsp;8 &nbsp;&nbsp;55.5% ± 2.5</code><br><br>Wards and "
          "route length dominate guard coverage, so tiles per guard is a real "
          "number about §5.2 and not a lever on §13.2."
          "<br><br><strong>Scope.</strong> All of this is measured on "
          "<em>generated</em> islands, which is the population §13.3 made "
          "the default and F16 measured at a fraction of a designed one. A "
          "designer can place geometry at a resolution the post count does not "
          "have — that is F16’s finding — so this is about the "
          "islands most players will defend and raid, not about what the editor "
          "can build."
          "<br><br><strong>Re-measured after D55, in part</strong> (generator sweep, same seeds and sample sizes): 3 of 10 realm/depth combinations have a setting inside both bands, as before, and the nearest misses are the same cells within a few points. The ward budget agrees on both harnesses: the recorded ward needs for realms 2–5 are confirmed. For realm 1 the recorded 10 did not land both bands on the D55 harness — 11 did — but with F31’s split on top it lands again: on the current harness every recorded need, realm 1’s 10 included, is confirmed.",
     rec="<strong>The lever is wards, and §5.2 allows 40% of what is "
         "needed.</strong> An earlier draft of this recommendation said realm 1 "
         "had no lever at the right scale, and listed wards, grid size and a "
         "relaxed band as untested candidates. Wards are now tested and they "
         "are the answer.<br><br>Realm 1, three realms crossed, one guard post, "
         "one geometry band, n=800 a cell:<br><br><code>wards &nbsp;&nbsp;hold "
         "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;decisions<br>"
         "&nbsp;&nbsp;&nbsp;4 &nbsp;&nbsp;19.2% ± 2.0 &nbsp;&nbsp;20 "
         "&nbsp;<strong>§5.2’s own limit</strong><br>"
         "&nbsp;&nbsp;&nbsp;8 &nbsp;&nbsp;27.6% ± 1.6 &nbsp;&nbsp;22<br>"
         "&nbsp;&nbsp;10 &nbsp;&nbsp;<strong>30.8% ± 1.6</strong> "
         "&nbsp;&nbsp;<strong>24</strong> &nbsp;<strong>inside both bands"
         "</strong><br>&nbsp;&nbsp;12 &nbsp;&nbsp;41.1% ± 1.7 &nbsp;&nbsp;26 "
         "&nbsp;one decision over</code><br><br><strong>§5.2 gives realm 1 "
         "four wards (<code>3 + realm level</code>) and it takes ten.</strong> "
         "The ward axis has the resolution the post count lacks — each ward "
         "is worth two to four points where a guard is worth forty-six — so "
         "the band is reachable there and nowhere else. The window is narrow: "
         "ten wards sits just inside the bottom of the hold band, and twelve is "
         "comfortably inside it but one decision past §19.27’s "
         "ceiling.<br><br><strong>Wards are not orthogonal to the decision "
         "count</strong>, which F22 assumed of the two knobs it swept: every "
         "ward adds decisions as well as hold, so both bands are spent from one "
         "budget. That is why nothing works at two geometry bands — seven "
         "wards reaches 33.4% and carries 26 decisions — and why the answer "
         "is one band with more wards rather than the reverse.<br><br>The post "
         "count is still not a candidate, and neither is the post ladder "
         "(F27).<br><br><strong>And the fix is per realm, because a flat "
         "ward count fails the same collateral check the post ladder "
         "did.</strong> Ten wards everywhere rescues realm 1 and "
         "<em>loses</em> both bands at realms 3 and 5 \u2014 34.4% to 53.6% "
         "and 39.8% to 47.2% \u2014 while sending realm 2 to 65.8%. Measured "
         "per realm at each one\u2019s best settings, n=500 a cell:<br><br>"
         "<code>realm &nbsp;\u00a75.2 gives &nbsp;needs &nbsp;&nbsp;&nbsp;hold &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;dec<br>"
         "&nbsp;&nbsp;1 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;4 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>10</strong> &nbsp;&nbsp;30.4% \u00b1 2.1 &nbsp;24<br>"
         "&nbsp;&nbsp;2 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;5 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<strong>8</strong> &nbsp;&nbsp;37.6% \u00b1 2.2 &nbsp;21<br>"
         "&nbsp;&nbsp;3 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;6 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;6 &nbsp;&nbsp;34.4% \u00b1 2.1 &nbsp;23 &nbsp;correct<br>"
         "&nbsp;&nbsp;4 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;7 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;7 &nbsp;&nbsp;40.4% \u00b1 2.2 &nbsp;17 &nbsp;correct<br>"
         "&nbsp;&nbsp;5 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;8 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;8 &nbsp;&nbsp;39.8% \u00b1 2.2 &nbsp;18 &nbsp;correct</code><br><br><strong>Every realm can satisfy both bands, "
         "and \u00a75.2\u2019s formula is right from realm 3 up and wrong "
         "below.</strong> <code>3 + realm level</code> gives 4, 5, 6, 7, 8; "
         "what is needed is <strong>11, 8, 6, 7, 8</strong> \u2014 ten at realm 1 in this table, eleven when the sweep is run as a whole, below. The formula "
         "increases with realm level and the need does not \u2014 realm 1 "
         "needs more wards than any other realm, and gets the fewest."
         "<br><br>That is not a paradox once the raider is looked at: the "
         "crew does not scale with realm level, so a low realm starts from "
         "further behind and needs more compensation, not less. Measured "
         "directly \u2014 posts forced to one at every realm \u2014 the hold "
         "rate rises from 19.2% at realm 1 to 55.5% at realm 5 on the same "
         "crew. <strong>\u00a75.2 scales the defence with the realm when it "
         "should be scaling it against the raider.</strong><br><br>Realm 1 "
         "is the one narrow window: ten wards sits at the bottom edge of the "
         "hold band and twelve is one decision past \u00a719.27\u2019s "
         "ceiling, so ten or eleven is the whole of it.<br><br><strong>Fix realm 2’s "
         "window.</strong> The fix exists and arrives 31 days after the realm "
         "does. Front-load the post ladder, open realm 2 later, or start a "
         "realm’s first post above level 1 — the last is closest to "
         "§13.3’s own promise that a generated defence is "
         "“never empty”, which is currently a claim about contents "
         "rather than about strength.<br><br><strong>This is not F22 "
         "restated.</strong> F22 found the band unreachable at §5.2’s "
         "one post and recommended a floor of two; measured at the depth "
         "§19.27’s decision band actually implies, two posts "
         "<em>overshoot</em>. The floor F22 asks for is the right direction and "
         "it does not land in the band either. Both items are the same "
         "quantisation seen from opposite sides.<br><br>"
         "<strong>Run as a table rather than a column, the budget is "
         "11, 8, 6, 7, 8.</strong> Everything above was measured one "
         "realm at a time. <code>tools/ward_budget.py</code> sweeps the "
         "ward count <em>and</em> the geometry band count at every "
         "realm and reports what each one needs; four of the five rows "
         "come back confirmed and realm 1 moves by one ward. At one "
         "band, n=400: ten wards holds "
         "<strong>29.5% \u00b1 2.3</strong> with 24 decisions \u2014 "
         "half a point under \u00a713.2\u2019s floor \u2014 and "
         "eleven holds <strong>32.5% \u00b1 2.3</strong> with 25. This "
         "item already said \u201cten or eleven is the whole of "
         "it\u201d; measured at four times the sample it is eleven, and "
         "the window is one ward wide.<br><br>"
         "<strong>Every realm is reachable, and none of them at nought "
         "geometry bands.</strong> Across 150 settings \u2014 five "
         "realms, three band counts, ten ward counts \u2014 every "
         "setting that satisfies both bands has one band or two, and "
         "at nought the ward count barely moves the defence at all: "
         "realm 1 runs 4.0% at three wards to 13.0% at twelve. "
         "<strong>A ward is worth almost nothing without geometry to "
         "hide it behind</strong>, which \u00a713.4\u2019s "
         "independent per-layer budget has no way to say \u2014 it "
         "prices the layers separately and one of them is conditional "
         "on another.<br><br>"
         "<strong>The window widens with realm level</strong>, which is "
         "the same fact as the budget running the other way to "
         "\u00a75.2\u2019s formula: realm 1 has one setting in 30, "
         "realm 2 has two, realm 4 has nine. The realms the formula "
         "gives fewest wards are the realms with least room to be "
         "wrong.<br><br><code>python3 -m tools.generator_settings</code> "
         "\u00b7 <code>python3 -m tools.ward_budget</code>",
     measured="re-run against harness ef4163da978cc0f0 (D55)"),

dict(id="F27", kind="finding", severity="significant", status="open",
     title="§10.2’s post ladder is the right size and starts in the "
           "wrong place, so the same upgrade is required, free or harmful",
     refs=["10.2", "13.2", "5.2"],
     body="Split out of F26, which measured the ladder while answering a "
          "different question and then had to keep amending itself.<br><br>"
          "§10.2 sells Guardian Posts at five levels, “+10% health "
          "and sight” each. Measured at that slope, what buying a post "
          "from level 1 to level 5 does, by realm:<br><br><code>realm &nbsp;"
          "level 1 &nbsp;level 5 &nbsp;span<br>"
          "&nbsp;&nbsp;1 &nbsp;&nbsp;&nbsp;15.0% &nbsp;&nbsp;24.2% &nbsp;&nbsp;"
          "9.2 &nbsp;entirely below the band<br>"
          "&nbsp;&nbsp;2 &nbsp;&nbsp;&nbsp;26.2% &nbsp;&nbsp;38.8% &nbsp;12.6 "
          "&nbsp;enters it only at the top<br>"
          "&nbsp;&nbsp;3 &nbsp;&nbsp;&nbsp;34.2% &nbsp;&nbsp;44.4% &nbsp;10.2 "
          "&nbsp;<strong>inside throughout</strong><br>"
          "&nbsp;&nbsp;4 &nbsp;&nbsp;&nbsp;40.0% &nbsp;&nbsp;52.7% &nbsp;12.7 "
          "&nbsp;leaves it at the top<br>"
          "&nbsp;&nbsp;5 &nbsp;&nbsp;&nbsp;40.0% &nbsp;&nbsp;55.3% &nbsp;15.3 "
          "&nbsp;leaves it at the top</code> <span style=\"opacity:.7\">"
          "(n=1,200 at realms 3 to 5)</span><br><br><strong>The ladder spans 12 "
          "points on average against a band 15 points wide</strong> — "
          "almost exactly the right size to be the tuning dial §13.2 "
          "needs. What is wrong is where each realm’s ladder begins, and "
          "§5.2’s post formula sets that. Of five realms it lands one "
          "inside the band.<br><br>So the same purchase does three different "
          "things depending where it is made: at realm 2 it is <em>required</em> "
          "to reach the band, at realm 3 it is free, and at realms 4 and 5 it "
          "<strong>carries the defence out of the band</strong> — 52.7% and "
          "55.3%, 5.3 and 7.2 standard errors past 45%. Nothing in §10.2 "
          "says so, and a player buying an upgrade is not told they are leaving "
          "the design’s own health band.<br><br>Realm 3 read as "
          "<em>over</em> at 400 raids and is inside at 1,200 — 44.4% "
          "± 1.4. Recorded because it is the fourth time in this register "
          "that a number near a boundary moved once the sample was earned, and "
          "the claim it would have supported — that the ladder takes every "
          "upper realm out of the band — is wider than the evidence "
          "carries."
          "<br><br><strong>Re-measured after D55</strong> (the harness now reads peripheral vision as the content file does; same seeds and sample sizes): <strong>one number changed and the verdict did not.</strong> Realm 1 needs <em>twice</em> §10.2’s slope to reach the band (20% a level: 33.2%), not five times — the corner of the eye now carries more of what sight buys, so a sight upgrade buys more. At that slope a maxed post still carries all four upper realms out of the top: 52.2%, 58.2%, 64.0%, 62.0%. So the ladder still does not close the gap; it moves it up the realm levels, at a smaller slope than recorded.",
     rec="<strong>Fix the base, not the dial.</strong> State a starting defence "
         "per realm chosen so the ladder spans the band — realm 2 higher, "
         "realms 4 and 5 lower — rather than letting it fall out of "
         "<code>1 + (level−1)÷2</code>. The ladder itself is the "
         "right instrument and needs no change."
         "<br><br><strong>A steeper ladder is not the answer, and was measured "
         "rather than reasoned about.</strong> F26 first recommended doubling "
         "its effect to rescue realm 1, and since D55 doubling does reach "
         "the band there — 20% a level holds 33.2% (before D55 it took five "
         "times §10.2’s slope). But at that slope a maxed post carries all "
         "four upper realms out of the top — 52.2%, 58.2%, 64.0%, 62.0%. <strong>The ladder "
         "does not close realm 1’s gap; it moves it up the realm "
         "levels.</strong> One slope has to serve every realm, and the realms "
         "that work sit near the top of the band already, so any upgrade large "
         "enough to matter at realm 1 carries them out of it. Withdrawn with "
         "the numbers, on the same principle as F17’s and F20’s "
         "withdrawn edits.<br><br><strong>Say what an upgrade is for.</strong> "
         "If §13.2’s band is the health metric, §10.2 currently "
         "sells four realms an upgrade that leaves it. Either the band is not "
         "meant to hold for an upgraded island — in which case say so — "
         "or the base moves.<br><br><code>python3 -m tools.post_ladder</code>",
     measured="re-run against harness ef4163da978cc0f0 (D55)"),
dict(id="F25", kind="finding", severity="blocking", status="open",
     title="\u00a731.2 states \u201cone fact, one home\u201d and six facts "
           "still have two homes",
     refs=["31.2", "31.9", "7.9", "14.4", "12.6", "9.2", "9.5", "11.5"],
     body="\u00a731.2\u2019s rule is the right one and is stated well: every "
          "fact has exactly one place it is stated, and every other appearance "
          "is a cross-reference or is generated. \u00a731.9 then lists eight "
          "items closed and says the remaining forty-five are design questions "
          "rather than bookkeeping.<br><br>Six of them are bookkeeping, and "
          "each is the rule\u2019s own failure mode. Checked against the built "
          "v3.1:<br><br><code>"
          "C3 &nbsp;the rank split &nbsp;&nbsp;7.9 says 18/14/10/6 &nbsp;"
          "&middot; the 48 sheets and 14.4 say 18/12/6/12<br>"
          "C23 the page costs &nbsp;&nbsp;7.6 says 15/30/60 &nbsp;&middot; "
          "9.5 and 29.2 say 10/20/35/60<br>"
          "C22 the load rate &nbsp;&nbsp;&nbsp;12.6 says 150 a second, Carriers "
          "&middot; 12.19 says 30, every role<br>"
          "C27 partial staffing &nbsp;9.2 <em>and 9.3</em> say 60/85/100% "
          "&nbsp;&middot; 5.8 says pro-rata<br>"
          "C28 a birth &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "9.5 is geometric &nbsp;&nbsp;&nbsp;&nbsp;&middot; 11.5 is linear<br>"
          "C25 the notes &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;8.8 "
          "says 8-9 a note &nbsp;&nbsp;&middot; the sheets say 12 to 6"
          "</code><br><br><strong>C3 is the one that costs something.</strong> "
          "\u00a77.9\u2019s table implies a Codex of 1,170 pages; the 48 "
          "authored sheets and \u00a714.4 both give <strong>1,350</strong>. "
          "v3.1 pins 1,350 as a canonical constant and checks \u00a714.4\u2019s "
          "arithmetic against itself, so the check passes \u2014 it never "
          "compares the rank counts the arithmetic uses against the rank counts "
          "\u00a77.9 publishes. The constant is guarded and the table it is "
          "derived from is not.",
     rec="Not a criticism of \u00a731 \u2014 it is what \u00a731 asks for, "
         "applied to the six it did not reach. Each is a one-line deletion or "
         "replacement, and all six now carry a drafted edit in this register "
         "\u2014 five did when this was written, which is the kind of sentence "
         "that goes quietly out of date and is why the count is stated rather "
         "than implied.<br><br><strong>All six are now checked as well.</strong> "
         "Four already were; C27 and C28 were the two nothing reached, and "
         "<code>check_document.py</code> now derives both rather than "
         "recognising a phrasing \u2014 it reads \u00a79.2\u2019s staffing "
         "steps and \u00a75.8\u2019s share as numbers and says how far apart "
         "they are at each staffing level, and it evaluates \u00a79.5\u2019s "
         "and \u00a711.5\u2019s birth curves rather than quoting them. Writing "
         "the second found a third fault inside \u00a79.5 and an arithmetic "
         "error in C28\u2019s own body: see C28.<br><br>"
         "The structural version: <code>data/constants.json</code> "
         "holds four constants, and this register can name at least ten facts "
         "that appear in more than one section. <strong>The constants file "
         "should be the list of every such fact</strong>, not of the four that "
         "were noticed. A practical test for what belongs in it: any figure "
         "this register has ever recorded as stated twice.",
     measured=None),

dict(id="C18", kind="contradiction", severity="significant", status="proposed",
     title="Aether storage: formula or table?",
     refs=["9.1", "10.2"],
     body="§9.1 gives the Aether cap as 5,000 per Spire level plus 3,000. §10.2's "
          "Spire table gives a flat 5,000 × level — 5,000 at level 1, "
          "50,000 at level 10. The formula would give 8,000 and 53,000.",
     rec="Small, but Aether is the weaving and upkeep currency, so the cap gates how "
         "much law a player can re-weave in one session."),

dict(id="C20", kind="contradiction", severity="significant", status="proposed",
     title="The 48 law sound signatures are six school sounds repeated",
     refs=["21.8", "7.9", "21.9"],
     body="§21.8 says \u201cevery law also has a sound signature, so a player can "
          "hear which rules are running with the screen half-watched\u201d. "
          "Extracting all 48 law sheets gives <strong>6 distinct sounds, one per "
          "school, each repeated eight times</strong> \u2014 Motion laws all sound "
          "like \u201ca rising whistle and a soft thump on landing\u201d, Matter "
          "laws all like \u201ca glassy chime and a low grind\u201d. A player can "
          "hear which <em>school</em> is running, not which law, and a realm can "
          "hold several laws of one school. §21.9's asset list budgets 6 school "
          "stingers, so the budget matches the content and not the claim.",
     rec="Either correct §21.8 to say sounds are per school \u2014 which is a "
         "reasonable design, and cheaper \u2014 or budget 48 law sounds in §21.9 "
         "and author them. The claim as written is not met by the content."),

dict(id="C13", kind="contradiction", severity="significant", status="proposed",
     title="Matchmaking cannot reach its own worst difficulty tier",
     refs=["12.3", "9.6"],
     body="§12.3 offers targets within 3 Keeper levels. §9.6's difficulty multiplier "
          "has a tier for targets “three or more below” paying 0.25×. "
          "If the Observatory never offers such targets, that tier is unreachable in "
          "normal play.",
     rec="Either widen the offered band, or state that the 0.25 tier exists only for "
         "challenge links, friendly heists and Trace targets."),

dict(id="C14", kind="contradiction", severity="significant", status="proposed",
     title="Renown for a foiled heist is undefined",
     refs=["12.9"],
     body="The outcomes table gives Renown as a percentage — 100% / 80% / 50% / "
          "−50% — while the formula below it produces an absolute value of "
          "8 to 40. “−50%” of a gain the raider did not make has no "
          "meaning.",
     rec="Express all four outcomes as multipliers on the formula's output, and "
         "state the sign convention explicitly."),

dict(id="C9", kind="contradiction", severity="significant", status="proposed",
     title="The Codex screen says 36 laws; there are 48",
     refs=["23.2", "7", "26.1"],
     body="The Law Codex screen spec says “36 laws by school and rank”. "
          "36 is the size of Codex chapter 3 (§7.6), so this is probably a stale "
          "number rather than a disagreement about the collection."),

dict(id="C10", kind="contradiction", severity="significant", status="proposed",
     title="Trait count: 30, 31 or 32?",
     refs=["11.3", "17.3", "26.1", "11.5"],
     body="§11.3 enumerates 31 traits (6 body, 5 heist, 11 law-linked, 9 home). "
          "§26.1's launch table says 30. §17.3 references “the rare Starborn "
          "trait”, which appears in no list. §11.5 also says strays arrive with "
          "three traits while §11.3 says every ruleborn is born with two."),

dict(id="C11", kind="contradiction", severity="significant", status="proposed",
     title="Screen count: 23 or 27?",
     refs=["21.9", "23.2"],
     body="§23.2 lists 27 screens to design; §21.9's asset list says 23. The "
          "difference is four screens of interface work and their icons."),

dict(id="C12", kind="contradiction", severity="significant", status="proposed",
     title="The high revenue scenario quietly uses a different commission rate",
     refs=["22.2", "22.5"],
     body="§22.5 says every figure in §22.2 assumes 15%. The low and base scenarios "
          "do — €2,720 and €25,500, both confirmed. The high "
          "scenario's €168,000 is computed at <strong>30%</strong>. That is "
          "arguably correct, since €204,000 a month crosses Apple's $1M "
          "small-business threshold — but it contradicts the stated assumption "
          "and makes the three scenarios non-comparable.",
     rec="Keep the 30% figure and footnote the threshold crossing. Worth surfacing "
         "that the discontinuity is a real business fact: revenue between roughly "
         "€70k and €85k a month is partly a dead zone."),

# ===========================================================================
# Minor
# ===========================================================================

dict(id="C15", kind="contradiction", severity="minor", status="proposed",
     title="Guard vision is given in tiles in one place and metres in another",
     refs=["12.8", "12.17", "21.1"],
     body="§21.1 establishes that one tile is one metre, so the two reconcile — "
          "but the document should pick one unit and use it throughout."),

dict(id="C16", kind="contradiction", severity="minor", status="proposed",
     title="“Three-minute heist” against a 150–240 second clock",
     refs=["12", "12.2", "5.4", "14.1"],
     body="§12's opening calls a heist “a three-minute run”; the clock is "
          "150–240 seconds and §12.2 correctly says 2.5–4 minutes. Harmless, "
          "but the marketing line and the spec should not disagree."),

dict(id="C17", kind="contradiction", severity="minor", status="proposed",
     title="The game lists itself as its own fallback name",
     refs=["27.2", "26.9"],
     body="§27.2 says “Fallbacks are Lawkeep and Ruleborn” — but "
          "Ruleborn <em>is</em> the chosen name. Almost certainly a leftover from "
          "the v2.2 rename."),

# ===========================================================================
# Specified nowhere
# ===========================================================================

dict(id="G1", kind="gap", severity="blocking", status="proposed",
     title="Pathfinding and crew movement",
     refs=["12.5", "12.6", "12.7", "6", "30.7"],
     body="The document specifies in detail what guards perceive and what laws do to "
          "movement parameters, but never how a crew actually moves. Unanswered: is "
          "the world a tile grid or continuous (§6 is in tiles, §12.17's sub-metre "
          "zones and degrees-per-tick imply continuous); how does a player order "
          "movement at all (§12.7 covers abilities, never locomotion); what happens "
          "at an unplanned fork; how do 3–5 crew avoid each other; does the "
          "§12.5 route planner produce a literal path or waypoints re-pathed at "
          "runtime — which have very different determinism properties.",
     rec="<strong>Drafted.</strong> <code>docs/design/spec/movement.md</code>, which "
         "unlike the other spec files is partly new design, since the document leaves "
         "this empty. It settles the world model first \u2014 <strong>tile topology, "
         "continuous position</strong>, which is the only reading that satisfies both "
         "§6's per-tile terrain and §12.17's sub-metre vision zones and "
         "degrees-per-tick turning \u2014 then proposes tap-to-move with per-member "
         "selection, deterministic breadth-first pathfinding with a fixed neighbour "
         "order, and commands rather than paths in the input log (§24.10).<br><br>"
         "The rule that protects premise 3 is stated explicitly: <strong>the crew "
         "never makes a decision the player did not make</strong>. No auto-attack, no "
         "auto-avoid, no auto-retreat, no re-routing around a guard the player walked "
         "them into. A unit cannot look stupid for a decision it never made. The "
         "prototype implements this and the felt-control question is measured "
         "directly against §30.8's 70% threshold."),

dict(id="G12", kind="gap", severity="significant", status="open",
     title="Three laws key off creature attributes that no creature has",
     refs=["7.4", "7.3", "11.1", "11.11", "11.10"],
     body="Checked across all 48 law sheets against the role and creature tables. "
          "<strong>Density</strong> reads \u201cBig characters get +30% health and "
          "\u221220% speed; small ones get +25% speed and \u221220% health\u201d "
          "\u2014 but there is <strong>no size or mass attribute anywhere</strong>. "
          "§11.1's role table carries health, speed, power and carry, nothing else; "
          "§11.11's proportions are in heads, which is art direction for the "
          "character artist; §11.10's forms add quirks, never a size. A rare law's "
          "entire tier-1 effect has nothing to resolve against.<br><br>"
          "<strong>Heavy ground</strong> grounds \u201cflyers\u201d, and flight "
          "exists only in §11.2's Featherkin passive \u2014 so under §11.11 (the "
          "spec C6 recommends adopting) half the law is inert and its stated "
          "weakness is false. <strong>Swarm birth</strong> is milder: \u201ctwo "
          "small guards with 30% of its strength\u201d describes what it creates "
          "rather than an attribute it reads, but 30% of <em>what</em> is undefined, "
          "and split guards have no role, so §12.17 gives them no perception profile.",
     rec="Either add the attributes (a size or mass band on each creature; flight as "
         "a stated property) or rewrite the three laws to key off role, which does "
         "exist. §7.3's rule is that laws change a realm's rule sheet and never "
         "contain special cases; a law reading a parameter that does not exist is "
         "the same failure from the other side. Enforce it in the law data table."),

dict(id="G2", kind="gap", severity="significant", status="proposed",
     title="What happens when a guard catches you",
     refs=["12.8", "12.17", "11.1", "13"],
     body="§12.8 gives ambush rules and a level cap, and §12.17 says an alerted "
          "guard converges and is never lethal. But there is no combat resolution: "
          "roles have Power (6–40) and Health (130–420) and attacks have a "
          "0.8s wind-up, yet there is no attack rate, damage formula or range. Nor "
          "is it stated whether the crew can choose to fight, or what happens to "
          "loot carried by someone knocked out mid-run (§13 and §12.6 cover the "
          "clock-end and post-capture cases only).",
     rec="<strong>Drafted.</strong> <code>docs/design/spec/fights.md</code>, which "
         "like <code>movement.md</code> is largely new design. It adopts the only "
         "cadence the document states \u2014 one hit per 0.8s for damage equal to "
         "Power \u2014 and that choice is corroborated rather than assumed: it is the "
         "reading under which Vault health, role Power and §12.6's stated phase "
         "length agree (see G4). It then answers the three open questions: the crew "
         "may fight at any time, but damaging a guard that has not been ambushed "
         "sends it straight to suspicion 1000, so an open fight is an alarm with a "
         "priced cost rather than a forbidden move; a downed crew member drops its "
         "loot on the tile and has ten seconds \u2014 one decision by §12.6's "
         "cadence \u2014 before capture, revivable by an adjacent ally in 3s, or 1.5s "
         "for a Mender.<br><br>It also repairs F4 by giving the ambush a floor of "
         "half the target\u2019s maximum health, which makes §12.8\u2019s own "
         "sentence true for all 25 pairings instead of three."),

dict(id="G3", kind="gap", severity="significant", status="proposed",
     title="Ward placement, triggering and disarming",
     refs=["10.3", "12.5", "11.1", "21.9"],
     body="§10.3 lists six wards with level-1 effects and reset timers. The Tinker "
          "trait “disarms wards 30% faster”, implying a disarm action that "
          "is never specified — who, how long, whether it makes noise. Also "
          "missing: what triggers a ward; levels 2–5, which the asset list and "
          "building table both assume; and ward health, given that Breakers deal "
          "double damage to them.",
     rec="<strong>Drafted, and smaller than recorded.</strong> Levels 2\u20135 do "
         "exist \u2014 §10.2\u2019s Ward row gives effect +15/30/45/60% and resets "
         "10\u21926 s. What is missing is the <em>key</em>: \u201ceffect +15%\u201d "
         "never says which number it scales, and three of the six wards have more "
         "than one candidate. <code>docs/design/spec/wards.md</code> supplies it "
         "under one rule \u2014 <strong>never scale a distance</strong>, because a "
         "ward whose radius grows on upgrade covers tiles it did not cover when it "
         "was placed, and the editor cannot then draw its footprint. It also gives "
         "Static Coil the damage it has never had, names the three trigger kinds "
         "(passive, aura, triggered) that the wording already implies, specifies "
         "the disarm action §12.5\u2019s Tinker trait presumes, and proposes ward "
         "health of 500 \u00d7 level \u2014 which puts the smash-or-disarm "
         "crossover at ward level 3, and at level 2 with a Tinker."),

dict(id="G4", kind="gap", severity="significant", status="proposed",
     title="The Vault's loading loop has no relationship to the payout",
     refs=["12.6", "9.6", "9.4"],
     body="§12.6 gives Vault health, Breaker double damage, cracking noise and a "
          "150-per-second load rate, and names “when to stop loading” as "
          "the Vault phase's core tension. But if §9.6's minted haul is "
          "authoritative (C2), loading longer earns nothing — so the phase's "
          "central decision currently has no mechanism behind it.",
     rec="<strong>Drafted.</strong> <code>docs/design/spec/vault.md</code>. It "
         "reinstates the clause §9.6 deleted \u2014 §9.4\u2019s "
         "\u201ccapped by the crew\u2019s carrying capacity\u201d \u2014 as a "
         "fill fraction on the formula in <code>economy.md</code>: what the crew "
         "banks is the raid\u2019s full value times the share of its bags it "
         "filled. The faucet ceiling is untouched, so the inflation dial stays "
         "single, and loading longer earns more. It also prices two decisions the "
         "document names and never costed: dropping loot to run faster costs "
         "exactly the fraction dropped, and the stop-or-continue breakeven sits at "
         "<strong>70% full \u2014 §12.9\u2019s Loud multiplier, with everything "
         "else cancelling</strong>. Tuning the tension of the game\u2019s "
         "emotional peak is then one number that already exists."),

dict(id="G5", kind="gap", severity="minor", status="proposed",
     title="Law pylons have no count, health or placement rule",
     refs=["12.6", "5.7", "10.2", "5.1"],
     body="Breaking a pylon switches its law off for the rest of a heist and yields a "
          "page, and the Spire's light going out when one breaks is the Heart's "
          "signature moment. §10.2 lists Law Pylon as a building with ten levels and "
          "health, but the relationship between pylons and the law slots they "
          "presumably represent is never stated.",
     rec="<strong>Mostly a false alarm, and that is the useful part.</strong> "
         "§10.2\u2019s Law Pylon row gives ten levels at 600 health each and states "
         "the relationship this item calls missing, in four words: <em>\u201cOne "
         "per law slot; per slot\u201d</em>. This item was recorded without reading "
         "that table \u2014 its own text admits as much \u2014 and the same "
         "oversight produced half of G3.<br><br>What survives is one sentence: "
         "nothing says a raider can tell <em>which law</em> a pylon carries before "
         "committing to the detour, which both §12.6 and §5.7 assume. "
         "<code>docs/design/spec/wards.md</code> proposes the pylon show its "
         "school colour and note glyphs, with §15.3\u2019s law banner naming it on "
         "approach, and prices the detour from §10.2\u2019s health: 1% of a heist "
         "at pylon level 1, 9% at level 10."),

dict(id="G6", kind="gap", severity="minor", status="open",
     title="How the matchmaking rating actually combines its inputs",
     refs=["12.15", "12.3"],
     body="§12.15 says skill and island difficulty use “a Bayesian rating with "
          "an explicit uncertainty term” and that a new island starts wide. "
          "§12.3 gives three filter bands. How Renown, Keeper level and the internal "
          "rating combine, how the “median target is winnable” guarantee is "
          "enforced, and what happens when all three filters return nothing, are not "
          "stated."),

dict(id="G7", kind="gap", severity="significant", status="done",
     title="The economy model itself was missing",
     refs=["24", "10.2", "14.2", "14.3"],
     body="§24 says a Python model “generated the tables in 10.2 and 14, and is "
          "re-run whenever a number changes”. That model was not in the "
          "document, and it is the source of roughly a quarter of its numbers.",
     rec="Rebuilt at <code>tools/economy_model/</code> (D5). It produced F1, F2 and "
         "F3, and measured C2."),

dict(id="G8", kind="gap", severity="minor", status="open",
     title="Two offline edge cases named but not resolved",
     refs=["24.12", "9.4"],
     body="§24.12 is otherwise excellent. Two gaps: the target lease is per snapshot, "
          "so two devices could hold two leases on the same target and nothing says "
          "what happens; and the entry fee (2% of Starlight, returned on a clean "
          "heist) has no stated debit point — lease, submission or validation "
          "— so an offline heist that is never submitted has an unclear fee "
          "state."),

dict(id="G9", kind="gap", severity="blocking", status="proposed",
     title="The 60-second guided build is the top risk's mitigation and is unspecified",
     refs=["13.1", "27.2", "16"],
     body="§13.1 makes “a 60-second guided build before the first player "
          "heist” the primary mitigation for the design's number-one risk, and "
          "§27.2 confirms it as a decision. What three terrain features, which guard, "
          "which law, what the player is told, and — critically — whether "
          "the island they build then becomes their actual defence, are all unstated.",
     rec="<strong>Drafted.</strong> <code>docs/design/spec/first-build.md</code>. The "
         "decision the sentence hides is whether the island becomes the player's "
         "<em>actual</em> defence \u2014 the document never says, and the two answers "
         "are different features. If it does not, this is a tutorial that is thrown "
         "away, against a finding the document itself cites: people value what they "
         "built themselves, but only when they finish it [49]. The spec proposes it "
         "becomes the real defence, places it at the "
         "top of day 2 (after the player has met a cone from the outside, per §15.1's "
         "teach-in-context rule), and names the five placements that make a guard's "
         "cone mean something.<br><br>It also draws a distinction the document does "
         "not: <strong>the §13.3 test protocol and the shipped feature differ</strong>. "
         "The test tells the player they may stop, because stated willingness is "
         "worthless here. The shipped game says nothing and logs what they do. And it "
         "flags that §13.1's \u201cnot optional\u201d sits oddly against §20.3's "
         "\u201cno obligations\u201d \u2014 reconcilable, since §20.3 is about "
         "recurring demands rather than onboarding, but the reason should be written "
         "down rather than assumed."),

dict(id="G10", kind="gap", severity="minor", status="open",
     title="Some law tier effects cannot be expressed as parameters",
     refs=["7.7", "7.3"],
     body="§7.3's best architectural decision is that laws change a realm's rule "
          "sheet and never contain special cases. But several tier values are "
          "qualitative rather than numeric — Glass at tier II “also reveals "
          "hidden wards” and at tier III “also shows guard vision "
          "cones” — so the principle is already bending. Density's "
          "“±40%/30%, ±50%/40%” needs a key.",
     rec="When the law data table is authored, every tier value must be expressible "
         "as a rule-sheet parameter change. Any that cannot is a design smell worth "
         "resolving then, not at implementation time."),

dict(id="G11", kind="gap", severity="minor", status="open",
     title="Localisation of a coined vocabulary has no owner",
     refs=["25.4", "26.9", "26.3", "20.6", "26.2"],
     body="§25.4 sets a 70% post-tutorial comprehension gate and §26.9 says every "
          "new name is said aloud in the twelve launch languages. Twelve languages "
          "across roughly 130 coined proper nouns — 48 law names, 44 resonances, "
          "12 chords, 18 creatures, 8 notes, 6 schools, 7 realms — is a large "
          "translation problem with no owner in §26.3's team. §20.6 also says "
          "launch is English and Portuguese, against §26.2's twelve.",
     rec="Related to D6: shipping 2–3 languages and translating store pages "
         "more widely is §26.4's own plan."),

# ===========================================================================
# Decisions that are the owner's, not clerical
# ===========================================================================

dict(id="Q1", kind="decision", severity="choice", status="open",
     title="Is character scarcity a feature or an accident?",
     refs=["4", "11.5", "5.2", "9.3"],
     body="F1 shows 152 positions against a roster of 38. §4 claims characters' time "
          "is one of the game's two scarce resources, which would make this "
          "deliberate. But 25% coverage is not an allocation puzzle, and §9.3's "
          "production figures assume staffing the roster cannot supply.",
     rec="<strong>Blocks:</strong> Q4, C19, the economy spec, and every pacing date "
         "in §14.<br><strong>The numbers</strong> (<code>decision_support.py "
         "staffing</code>): 152 positions against a roster of 38; only 12 characters "
         "free to work once guards and a crew are committed; no second or third "
         "worker slot is ever worth filling, though §10.2 grants them at building "
         "levels 4 and 7; and two independent caps \u2014 Hearth homes and §9.5's "
         "birth curve \u2014 both say 30\u201340 without referring to each other."
         "<br><strong>Depends on Q8:</strong> if a Guardian Post holds more than one "
         "ruleborn, defence alone consumes 42\u201363 characters and the shortage "
         "stops being severe and becomes absolute.<br><strong>No recommendation.</strong> "
         "This is a design choice about whether scarcity is the point. What is not a "
         "choice is leaving all three tables as they are."),

dict(id="Q2", kind="decision", severity="choice", status="open",
     title="Should the raid-versus-build trade-off be made real, or dropped?",
     refs=["4", "11.6", "12.9"],
     body="F3 shows it is worth about 2% of production. It can be made real by "
          "making crew membership exclude work the way guarding does, or the claim "
          "can be removed from §4 and §11.6. What it cannot do is stay as written.",
     rec="<strong>Blocks:</strong> nothing technical, but it decides whether §4's "
         "central claim survives.<br><strong>The numbers:</strong> a crew of five "
         "raiding four times a day is withheld from work for 16 character-hours out "
         "of 744 \u2014 about 2% of production.<br><strong>Leaning:</strong> make "
         "crew membership exclude work the way guarding does, so five of 38 are "
         "committed rather than 0.67. The scarcity needed already exists in F1; it "
         "is simply not connected to raiding. Lengthening rest instead runs against "
         "§12.14's rule that failure stays temporary."),

dict(id="Q3", kind="decision", severity="choice", status="open",
     title="Three law ranks or five?",
     refs=["7.4", "7.9"],
     body="C3. Both work; the reasoning in §7.9 survives either. Choosing five means "
          "re-tagging 14 laws and re-deriving the page economy.",
     rec="<strong>Blocks:</strong> all law content authoring, and §14.4's page "
         "economy.<br><strong>The numbers</strong> (<code>decision_support.py "
         "rarity</code>): five ranks completes the collection 23% cheaper \u2014 "
         "2,460 pages against 2,805 \u2014 pulling it in about a month at eleven "
         "pages a day. §14.4's own 1,485-page figure is the three-rank total, so "
         "three ranks is what generated the published curve.<br><strong>No "
         "recommendation.</strong> Five ranks needs fourteen Rares re-tagged, and "
         "the split is a judgement about complexity and excitement \u2014 §7.9 is "
         "explicit that rarity must not track power, which rules out the obvious "
         "cost-ordered answer."),

dict(id="Q4", kind="decision", severity="choice", status="open",
     title="One producer per realm, or two?",
     refs=["5.2", "9.3"],
     body="F2. Two doubles income against every published pacing date; one matches "
          "the tables but contradicts §5.2. Interacts with Q1.",
     rec="<strong>Blocks:</strong> §9.3, §10.2, §14.2 and §14.3 \u2014 every "
         "published pacing date.<br><strong>The numbers</strong> (F2): only "
         "\u201cone producer per realm, no binding roster cap\u201d reproduces the "
         "document (117% of published at day 301; Keeper 40 on day 171 against 181). "
         "Every other reading is out by 2\u20134\u00d7. A player who builds the "
         "second producer \u2014 a pure gain, so everyone will \u2014 earns roughly "
         "twice what §14 predicts.<br><strong>Leaning:</strong> one per realm, given "
         "Q1. Under a roster that cannot staff what already exists, the second "
         "producer is not a decision, it is dead Starlight."),

dict(id="Q5", kind="decision", severity="choice", status="open",
     title="Accept the launch-scope cut?",
     refs=["26.1", "26.5"],
     body="D6. Roughly 40% less launch content, protecting the Island Workshop.",
     rec="<strong>Blocks:</strong> the vertical slice's content budget, and the "
         "contractor brief.<br><strong>The proposal</strong> (D6): 24 laws rather "
         "than 48, 3 form-notes rather than 8, ~20 resonances rather than 44, "
         "2\u20133 languages rather than 12, constellations to v1.1, wards at 2 "
         "levels rather than 5 \u2014 roughly 40% less, protecting the Island "
         "Workshop.<br><strong>Leaning:</strong> take it. §26.5 says scope is the "
         "lever and §30.8 ranks execution as risk #2, but neither is applied to "
         "§26.1. The Codex already gates laws in chapters, so 24 laws is chapter 2, "
         "which an engaged player reaches on day 5."),

dict(id="Q6", kind="decision", severity="choice", status="open",
     title="Casual pacing: leave it, or add the catch-up discount?",
     refs=["27.3", "14", "27.5"],
     body="Open in the document since v0.3. At one session a day, finishing "
          "everything takes about 1,019 days. §27.5 settles on a visible, openly "
          "labelled catch-up discount, but it is not specified.",
     rec="<strong>Blocks:</strong> nothing, and it has been open since v0.3."
         "<br><strong>The numbers:</strong> at one session a day, finishing "
         "everything takes about 1,019 days. §27.5 already settles on a visible, "
         "openly labelled catch-up discount, citing [83] \u2014 disclosed assistance "
         "does not harm the experience \u2014 but never specifies it."
         "<br><strong>Leaning:</strong> specify the discount. The decision is already "
         "made; only the mechanism is missing."),

dict(id="Q8", kind="decision", severity="choice", status="open",
     title="How many ruleborn stand at one Guardian Post?",
     refs=["5.2", "13.4", "10.2", "9.2"],
     body="Never stated anywhere in the document, and it is the missing conversion "
          "between §5.2, which counts guard <em>posts</em>, and §13.4, which counts "
          "<em>guards</em> \u2014 one post against three guards at realm level 1, "
          "three posts against six at level 5, so no constant reconciles them. "
          "§10.2's Guardian Post entry gives the post's capability per level "
          "(\u201cguard +10% health and sight\u201d) but never a capacity.",
     rec="<strong>Blocks:</strong> C5, and it swings Q1 by a factor of three."
         "<br><strong>Leaning:</strong> one. It matches §9.2's phrasing, keeps §5.2's "
         "numbers intact, and keeps defence affordable against the roster. Anything "
         "higher means F1's arithmetic has to be redone first, because defence would "
         "then consume more characters than production.<br>A small question with a "
         "large blast radius \u2014 worth answering before Q1, not after."),

dict(id="Q7", kind="decision", severity="choice", status="open",
     title="The document's own open list",
     refs=["27.3"],
     body="Final names and the trade-mark check; whether the Island Fund survives its "
          "six-month test; whether to strengthen performative and emotional challenge "
          "after launch; Law Clash rules; soft-launch countries; whether the interface "
          "says “universe” or “your sky”; whether constellations "
          "later get a competitive mode.",
     rec="<strong>Blocks:</strong> the name clearance blocks any public use "
         "(§26.9), and the soft-launch countries block the launch plan. The rest can "
         "wait.<br><strong>Order:</strong> the trade-mark check first, since §26.9 "
         "makes it a gate and it costs nothing; then soft-launch countries; then the "
         "Island Fund test, which cannot start until the Workshop ships."),

# ===========================================================================
# Found in version 3.0 — fixes that were not finished, and claims that were
# not carried out
# ===========================================================================

dict(id="C21", kind="contradiction", severity="blocking", status="open",
     title="The formulas appendix still carries the detection model §12.8 deleted",
     refs=["29.1", "12.8", "12.17", "5.4"],
     body="§12.8 in v3.0 states the old perception rules are gone and that §12.17 "
          "wins everywhere. <strong>§29.1 still tabulates them</strong> \u2014 "
          "\u201cAwareness: +50% a second in sight, +75% within 3 tiles; investigate "
          "at 50%, alarm at 100%\u201d \u2014 and gives §12.8 as the source, which is "
          "the section that deleted them. Its ambush row is stale the same way: "
          "\u201cFirst unseen hit: 2 s stun and triple damage\u201d, without the "
          "health floor §12.8 added. §5.4\u2019s landing rule still starts guards at "
          "\u201c25% awareness\u201d, a unit that no longer exists.<br><br>This is "
          "the worst possible place for it: the formulas appendix is where an "
          "implementer looks for a number rather than a discussion.",
     rec="§29.1 should be generated, not authored \u2014 which is D15, already "
         "recorded and already built (<code>tools/generate_docs.py</code> emits it "
         "from <code>content/</code>). Adopting that is a one-line change to the "
         "build and it makes this class of item impossible rather than merely "
         "unlikely. §5.4 restates as 250 of 1000 suspicion, as "
         "<code>spec/detection.md</code> proposed."),

dict(id="C22", kind="contradiction", severity="significant", status="open",
     title="§12.6 still loads at 150 a second, five times §12.19's rate",
     refs=["12.6", "12.19", "9.6"],
     body="§12.19 opens by naming the problem \u2014 \u201c12.6 called the loading "
          "phase the heist\u2019s central decision, and its own numbers gave that "
          "decision two seconds and one option\u201d \u2014 and fixes it: every role "
          "loads, at 30 units a second. §12.6\u2019s own sentence was not changed. It "
          "still reads \u201ceach Carrier loads 150 loot a second until full\u201d, "
          "which is both the wrong rate and the wrong set of roles.",
     rec="Delete the sentence from §12.6 and point it at §12.19, the way §12.8 now "
         "points at §12.17. Both numbers are live in the file today, and the one in "
         "the moment-to-moment section is the one a reader meets first."),

dict(id="C23", kind="contradiction", severity="minor", status="open",
     title="One sentence still prices laws in three ranks, and it is the only "
           "one left",
     refs=["7.6", "7.7", "7.9", "14.4", "29.2"],
     body="This was C3\u2019s collateral list: v3.0 re-tagged twelve laws from "
          "Rare to Uncommon and four statements did not follow \u2014 "
          "\u00a77.6\u2019s restore line, \u00a714.4\u2019s "
          "<code>15 \u00d7 15 + 18 \u00d7 30 + 12 \u00d7 60 = 1,485</code>, "
          "the glossary and the price list."
          "<br><br><strong>v3.1 fixed three of the four.</strong> \u00a714.4 "
          "now totals 1,350 from the sheets\u2019 own split, \u00a77.1 says "
          "rank sets acquisition time rather than page cost, and \u00a729.2 "
          "carries the five-rank figures. What is left is one sentence in "
          "\u00a77.6:<br><br><code>Restoring a law: 15 pages for a common law, "
          "30 for a rare one, 60 for a deep one.</code><br><br>Three ranks, "
          "three prices, and no mention of the rank twelve laws have carried "
          "since v3.0. It is normative text \u2014 it is where a player is told "
          "what restoring costs \u2014 and it is the sentence F24 is about: "
          "v3.1\u2019s ban on the retired three-rank model searches for "
          "<code>15, 30 or 60 pages</code> and reports it absent, because this "
          "says the same thing with the clause rearranged.",
     rec="One replacement, drafted below, and it can be made without waiting on "
         "C3 \u2014 \u00a77.6 disagrees with \u00a77.9 and \u00a714.4 alike, "
         "so no reading of C3 leaves this sentence standing. "
         "<code>tools/check_document.py</code> derives every page price from the "
         "rank table rather than recognising a phrase, which is what caught it "
         "and what will keep catching the next rearrangement."),

dict(id="C24", kind="contradiction", severity="minor", status="open",
     title="Seventeen building types, and §26.1 still says sixteen",
     refs=["10.4", "10.2", "26.1"],
     body="§10.4 adds the Library and calls it \u201ca building at the Heart, one per "
          "universe\u201d, which closes the faucet C8 was about. Two counts did not "
          "follow: §26.1\u2019s launch content table still says 16 building types, and "
          "§10.2 \u2014 headed <em>Every level of every building</em> \u2014 does not "
          "contain it. §10.4 also gives only levels 1, 5 and 10, where every other "
          "building lists all ten.",
     rec="Move the Library into §10.2 with its full level table and raise §26.1 to "
         "17. The seven missing levels matter more than they look: the Library is "
         "the faucet that keeps non-raiders progressing, and the economy model "
         "cannot price a curve given three of its points."),

dict(id="C25", kind="contradiction", severity="significant", status="open",
     title="§8.8 states the note rebalance as done; the law sheets are unchanged",
     refs=["8.8", "7.7", "8.1"],
     body="§8.8 reads: \u201cThe table now runs eight or nine laws per note, and since "
          "the note count is frozen at eight and laws are the expansion axis, that "
          "balance is a permanent constraint on every future season.\u201d Parsing "
          "all 48 law sheets gives <strong>Glow 12, Flow 11, Echo 10, Weight 9, Spark "
          "8, Bloom 8, Veil 7, Hush 6</strong> \u2014 identical to v2.3. The "
          "rebalance is described in the past tense and has not happened.<br><br>The "
          "asymmetry still runs the wrong way for the same reason: Hush is the hiding "
          "note, it is the scarcest, and laws are woven by the defender.",
     rec="Retag or re-note about six laws to bring every pool to 8 or 9 \u2014 this "
         "is D13, which is still the right fix and is now also a correctness fix, "
         "since a section of the document asserts the result. "
         "<code>python3 tools/check_design_consistency.py</code> fails until the "
         "sheets match the claim."),

dict(id="C26", kind="contradiction", severity="significant", status="open",
     title="§12.21 declares size and flight as properties; no table carries them",
     refs=["12.21", "11.1", "11.2", "11.11", "7.7"],
     body="§12.21 is the right answer to G12, stated well: \u201cA law that reads a "
          "parameter which does not exist is the same failure as a law full of "
          "special cases, seen from the other side.\u201d It then says size is a band "
          "on every ruleborn and flight is a stated property rather than an "
          "implication of a passive.<br><br>Neither exists as a field. §11.1 has "
          "health, speed, power and carry. §11.11 has proportions, which are art "
          "direction. <strong>Featherkin\u2019s flight is still prose in a Passive "
          "column</strong> \u2014 \u201cFlies; grounded by Heavy ground\u201d \u2014 "
          "which is precisely the implication §12.21 says it must not be. Three laws "
          "(Density, Heavy ground, Swarm birth) still read attributes that no "
          "creature carries.",
     rec="Add <code>size</code> and <code>flies</code> to the creature table and "
         "derive nothing from prose. <code>content/ruleborn.json</code> is the place "
         "to do it once; <code>tools/validate_content.py</code> already fails on any "
         "law that reads an attribute no creature has, so the check exists and is "
         "waiting for the data."),

dict(id="D19", kind="deviation", severity="change", status="done",
     title="The checks were rewritten to read the document rather than remember it",
     refs=["29.1", "11.1", "12.6"],
     body="Four checks added while auditing v2.3 \u2014 the ambush rule, the load "
          "rate, crew capacity, the fight-length bound \u2014 hard-coded the role "
          "stats and the Vault rate instead of parsing them. Against v3.0 they "
          "reported exactly the same failures they had reported against v2.3, "
          "including for the two things v3.0 had fixed.<br><br>A check that cannot "
          "pass is not a check. It is a comment that runs.",
     rec="<code>check_design_consistency.py</code> now parses §11.1\u2019s role table, "
         "every load-rate sentence, §7.9\u2019s rank table, §7.6\u2019s restore costs "
         "and §12.8\u2019s ambush wording out of the document. Two findings retired on "
         "the first run against v3.0, which is what retirement is supposed to look "
         "like. The fight-length bound was <strong>deleted</strong> rather than "
         "re-based: it measured a lone Mender attacking a Warden, which is a player "
         "mistake rather than a specification fault, and the health floor had already "
         "halved it."),

dict(id="D20", kind="deviation", severity="change", status="open",
     title="Both pre-code player gates are gone, and the prototype with them",
     refs=["19.27", "13.3", "26.7", "30.8"],
     body="v3.0 removes both tests this analysis built a prototype for. §19.27 "
          "replaces them with simulation harnesses and states the cost plainly: "
          "\u201cSimulation can prove a system is legible, balanced and "
          "decision-dense. It cannot prove a game is enjoyable \u2014 nothing except "
          "a person playing can, and that evidence now arrives at soft launch rather "
          "than before code.\u201d §13.3 goes further and removes the build-"
          "willingness question itself: every player gets a generated defence, "
          "curation is the default creative act, and authoring becomes the deep end. "
          "<strong>Risk #1 is designed out rather than measured.</strong><br><br>Both "
          "are defensible and both are stated honestly. One premise is worth "
          "restating, because it is the premise the change rests on: §19.27 gives the "
          "reason as \u201cthat cohort does not exist for this project\u201d, meaning "
          "thirty people in a room. That was D2\u2019s finding too \u2014 and D2\u2019s "
          "answer was that a link is recruitable where a room is not. The prototype "
          "exists, it is published, and sending it to twenty strangers costs an "
          "afternoon rather than a soft launch.",
     rec="Not a disagreement with the decision, which is the owner\u2019s and is "
         "argued well. Two things follow from it regardless.<br><br><strong>The "
         "harnesses in §19.27 are now on the critical path</strong>, ahead of the "
         "vertical slice, and they are buildable here: thousands of scripted heists "
         "at three skill levels, measuring decisions per run, near-captures, and "
         "whether the last ten seconds decide the outcome. §19.27 sets the thresholds "
         "\u2014 15\u201325 decisions, a near-capture in half of runs, the optimal "
         "crew 35 points ahead of the careless one.<br><br><strong>The prototype "
         "stays published anyway.</strong> It costs nothing to leave up, and it is "
         "the only artefact in this repository that can answer the one question "
         "§19.27 says simulation cannot."),


dict(id="F7", kind="finding", severity="design", status="open",
     title="\u00a712.6\u2019s 15\u201325 decisions implies crossing two to three realms",
     refs=["12.6", "19.2", "12.22", "5.4"],
     body="\u00a712.6 budgets \u201croughly one decision every 8 to 12 seconds, or 15 "
          "to 25 in a run\u201d, and \u00a719.27 makes it a threshold. Simulated, the "
          "count is a function of how far in the target is:<br><br>"
          "<code>1 realm &rarr; 10 &nbsp; 2 &rarr; 17 &nbsp; 3 &rarr; 24 &nbsp; "
          "4 &rarr; 31</code> (optimal crew, median)<br><br>"
          "So the band is met at <strong>two to three realms crossed</strong>, "
          "fails below and overshoots above. That is a real design constraint "
          "hiding in a pacing sentence: it says how deep a heist has to go.<br><br>"
          "\u00a75.4 already prices the skiff by the number of links, so the "
          "document knows heists vary in depth. \u00a712.22, which chooses the "
          "target, filters on Renown, Keeper level and a difficulty rating, and "
          "<strong>says nothing about depth at all</strong>.",
     rec="Add depth to \u00a712.22\u2019s band, or accept that the decision count "
         "varies three-fold with a dimension the matchmaker does not control. "
         "<code>python3 -m tools.heist_harness depth</code>."),

dict(id="F8", kind="finding", severity="design", status="open",
     title="The clock is not a pressure device: runs finish with a third of it unused",
     refs=["19.27", "12.6", "5.4"],
     body="\u00a712.6 makes the clock the escape phase\u2019s tension \u2014 "
          "\u201cthe clock turns red for its last 30 seconds\u201d \u2014 and "
          "\u00a719.27 sets a threshold on it: the last ten seconds should decide "
          "the outcome in a quarter of runs. Simulated across four depths and "
          "three skill levels, it decides <strong>0%</strong>. A median run takes "
          "45 to 150 seconds against a clock of 150 to 195.<br><br>Near-captures, "
          "by contrast, happen in <strong>100%</strong> of runs against a "
          "threshold of 50 \u2014 so the tension is all in the guards and none in "
          "the clock, and a close call is so common it cannot register as one.",
     rec="Two dials, and they pull opposite ways. Shortening the clock makes it "
         "bite; it also makes \u00a712.6\u2019s crossing phase unaffordable at "
         "depth. The likelier answer is that the clock is not the pressure and "
         "should stop being described as it \u2014 the alarm is."),

dict(id="F9", kind="finding", severity="blocking", status="open",
     title="Generated defences hold 2% at realm level 1, against a target of 30\u201345%",
     refs=["13.3", "13.2", "13.4", "5.2"],
     body="v3.0\u2019s \u00a713.3 is the biggest design change in the version: the "
          "build-willingness risk is removed rather than measured, and every "
          "player gets a defence generated \u201cfrom their realm, their laws and "
          "their ruleborn \u2014 legal, coherent, and never empty\u201d.<br><br>"
          "Simulated against a competent crew, a generated island at realm level 1 "
          "holds <strong>2%</strong> of the time. Level 3 holds 28%. Only level 5 "
          "reaches \u00a713.2\u2019s 30\u201345% band. Legal, coherent and never "
          "empty are all true of these islands, and none of them is the same "
          "requirement as effective.<br><br>This matters more in v3.0 than it "
          "would have in v2.3, because the generator is no longer a fallback for "
          "players who will not build \u2014 it is what most islands in the target "
          "pool now are."
          "<br><br><strong>Re-measured after D55</strong> (the harness now reads peripheral vision as the content file does; same seeds and sample sizes): competent crew, no laws, 50 raids a cell, by realm: 2 → 8%, 10 → 12%, 48 → 45%, 32 → 38%, 50 → 48%. Realm 1 is still far below §13.2’s band, which is the finding. (Realm 3’s 28% above predates the current harness: it already read 48% before D55.)",
     rec="\u00a713.3 should carry the hold-rate band as a stated requirement on "
         "the generator, the way \u00a713.2 carries it for designed islands, and "
         "the generator should be measured against it before the Workshop is "
         "built. The harness does that: "
         "<code>python3 -m tools.heist_harness defence</code>. "
         "<br><br>Caveat, stated plainly: the generator in the harness is a first "
         "sketch \u2014 hedges, tall grass, one to three guards, four to eight "
         "wards, no laws. A generator that weaves laws would hold better. That is "
         "the point: nothing says how well it has to hold, so nothing says when "
         "it is finished."
         "<br><br><strong>Both halves now done, and the cause has moved.</strong> "
         "The generator weaves laws (F11) and the geometry it was missing is "
         "built \u2014 <code>island.generate(shaped=)</code>, specified in "
         "<code>docs/design/spec/generator.md</code>. Neither reaches "
         "\u00a713.2\u2019s band at realms 1 and 2, and F22 measures why: at "
         "\u00a75.2\u2019s one guard post the ceiling is 16.5% there, so no "
         "generator can reach 30%. This item\u2019s claim survives; its "
         "diagnosis does not."
         "<br><br><strong>And this item\u2019s own numbers have moved.</strong> Re-measured on the current harness \u2014 competent crew, no laws, two realms crossed, 150 raids a cell \u2014 a generated island holds <strong>9%</strong> at realm 1, <strong>32%</strong> at realm 3 and <strong>44%</strong> at realm 5, against the 2%, 28% and \u201conly level 5 reaches the band\u201d recorded above. Realm 3 now reaches it. The direction survives \u2014 realms 1 and 2 miss badly \u2014 but the sentence \u201conly level 5 reaches \u00a713.2\u2019s band\u201d is no longer true, and the headline 2% is a figure from a harness with three faults since fixed (D24, D25, D26).<br><br>That is the whole argument for <code>check_findings_fresh.py</code>: this number sat in the register\u2019s blocking section, unchallenged, through every one of those fixes.",
     measured="re-run against harness ef4163da978cc0f0 (D55)"),

dict(id="D21", kind="deviation", severity="change", status="done",
     title="\u00a719.27\u2019s harnesses were built, since they are now the critical path",
     refs=["19.27", "12.17", "12.18", "12.19", "12.20", "5.4"],
     body="v3.0 replaced both pre-code player tests with simulation (D20), which "
          "puts the harnesses on the critical path ahead of the vertical slice. "
          "<code>tools/heist_harness/</code> is three of them: tension and depth, "
          "defence balance, and the attribution check.<br><br>It implements "
          "\u00a712.17\u2019s perception in full, \u00a712.18\u2019s movement "
          "rules, \u00a712.19\u2019s loading and \u00a712.20\u2019s capture and "
          "revive, with \u00a75.4\u2019s clock and \u00a712.9\u2019s grades. "
          "Every run is a function of its seed: integer arithmetic throughout, "
          "no random source consulted inside the loop, and a SplitMix64 reference "
          "stream in the tests so a port can be checked against it "
          "(\u00a724.7).<br><br>It is not the engine and is not a step toward "
          "one. It answers questions, like the economy model, and \u00a726.7\u2019s "
          "rule that gameplay code waits for the determinism spike is untouched.",
     rec="Three findings on the first full run: F7, F8 and F9. The one that "
         "changes a decision is F9, because \u00a713.3 now rests on the generator "
         "and nothing states how well it has to hold."),

dict(id="F22", kind="finding", severity="blocking", status="proposed",
     title="\u00a75.2\u2019s one guard post puts \u00a713.2\u2019s band out of "
           "reach at realms 1 and 2, whatever the generator does",
     refs=["5.2", "13.2", "13.3", "12.22", "13.4"],
     body="Found while building the generator F16 argued for, which is the "
          "useful part: the fix worked and then stopped short of the band, and "
          "the reason it stopped is not the generator.<br><br>\u00a75.2 gives a "
          "realm <code>1 + (level \u2212 1) // 2</code> guard posts, so realms 1 "
          "and 2 get <strong>one</strong>. Competent crew, sign-aware laws, two "
          "realms crossed, 400 raids a cell:<br><br><code>"
          "realm 1, 1 post &nbsp;&nbsp;0 bands &nbsp;5.5% &nbsp;1 band 12.0% "
          "&nbsp;2 bands 16.5%<br>"
          "realm 1, 2 posts &nbsp;0 bands 15.5% &nbsp;1 band <strong>44.8%</strong> "
          "&nbsp;2 bands 51.5%<br>"
          "realm 2, 1 post &nbsp;&nbsp;0 bands 13.0% &nbsp;1 band 17.5% "
          "&nbsp;2 bands 21.5%<br>"
          "realm 2, 2 posts &nbsp;0 bands <strong>30.2%</strong> &nbsp;1 band 56.8% "
          "&nbsp;2 bands 68.8%</code><br><br>"
          "<strong>At one post the band is unreachable.</strong> Realm 1 tops out "
          "at 16.5% and realm 2 at 21.5%, against a band that starts at 30%. "
          "Geometry is worth 11 points at realm 1; the gap to the band is 14 "
          "points <em>after</em> geometry has done everything it can. The second "
          "post is worth 35 points \u2014 more than every other lever "
          "combined.<br><br>The mechanism is F15\u2019s, and this is the second "
          "finding to land on it: guards are half of the island\u2019s only "
          "detect-and-act chain. Geometry, wards and laws work by <em>delay</em>, "
          "and delay reaches an outcome only through \u00a75.4\u2019s clock, "
          "which has four times the slack any delay needs. One guard is almost no "
          "detection, so there is very little for the delay to convert "
          "into.<br><br><strong>Realms 1 and 2 are where every new player "
          "starts</strong>, and F13 is this seen from the matchmaker: "
          "\u00a712.22 promises a median target in a 55\u201370% raider-success "
          "band, and this pool runs at 78\u201395%.<br><br>One thing checked "
          "before it was claimed. The gain from geometry looks larger when a "
          "second post is present \u2014 +7 points at one post against +29 at "
          "two \u2014 which reads as the two layers multiplying. <strong>They do "
          "not.</strong> On the log-odds scale, which is the scale a bounded "
          "probability adds on, the interaction is +0.05 \u00b1 0.32 "
          "(t = 0.15): geometry and guards are independent, and the apparent "
          "synergy is the percentage scale compressing near zero. Unlike guards "
          "and response (F15), which really are multiplicative, "
          "\u00a713.2\u2019s separable shares are the right model here."
          "<br><br><strong>Re-measured after D55</strong> (generator sweep, same seeds and sample sizes): at one post realm 1 still peaks at 16.7% (was 15.0%) and realm 2 at 29.8% (was 26.2%), under §13.2’s 30% floor. Realm 1 with two posts and one band moved from 44.8% to 48.8%, now just over the band rather than inside it. The finding holds: one post cannot reach the band. With F31’s split on top it still holds — realm 1 peaks at 19.5%, realm 2 at 28.5%.",
     rec="Specified in <code>docs/design/spec/generator.md</code>. <strong>A "
         "floor of two posts at realms 1 and 2</strong> \u2014 one line, and "
         "the only change measured that brings those realms within reach at "
         "all. <strong>The line is in \u00a710.2, not \u00a75.2 as this item "
         "first said</strong>: \u00a75.2 carries no post count at all, and "
         "the rule lives in \u00a710.2\u2019s Guardian Post entry \u2014 "
         "<em>\u201cEvery realm; 1 to 3 by realm level\u201d</em>. Recorded "
         "rather than quietly corrected, because a recommendation that names "
         "the wrong section is the same fault as a citation that does, and "
         "this one survived until the edit was drafted against the document.<br><br>Two further things fall out of the same "
         "grid.<br><br><strong>The knobs are nearly orthogonal, which is the "
         "specification \u00a713.3 is missing.</strong> Bands drive the decision "
         "count (6 \u2192 13 \u2192 15 at realm 1) and barely touch the hold "
         "rate\u2019s driver; posts drive the hold rate and move decisions by 0 "
         "to 2. So: lay bands until \u00a719.27\u2019s 15\u201325 decisions is "
         "met, then fill posts until \u00a713.2\u2019s 30\u201345% is met, in "
         "that order.<br><br><strong>The geometry has to be a dial, not a "
         "switch.</strong> On or off, realm 1 at two posts gives 15.5% or 51.5% "
         "and steps straight over the band; one band lands at 44.8%. A realm has "
         "very few discrete settings early \u2014 integer posts, "
         "<code>3 + level</code> wards \u2014 and <strong>a layer offered as a "
         "switch cannot be balanced against a 15-point band</strong>.",
     measured="re-run against harness ef4163da978cc0f0 (D55)"),

dict(id="F10", kind="finding", severity="blocking", status="open",
     title="Sixteen of forty-eight laws are parameter changes; the rest need an engine feature",
     refs=["7.3", "12.21", "24", "26.1"],
     body="\u00a77.3 is the architectural claim the whole design rests on \u2014 "
          "laws change a realm\u2019s rule sheet rather than containing special "
          "cases \u2014 and v3.0\u2019s \u00a712.21 turns it into a rule: "
          "\u201cevery tier effect of every law must be expressible as a change "
          "to a named parameter\u201d. Written out for all 48 laws against a "
          "rule sheet of twenty named parameters:<br><br>"
          "<code>parameter 16 &nbsp; authored 4 &nbsp; attribute 2 &nbsp; "
          "entity 10 &nbsp; event 16</code><br><br>"
          "<strong>Sixteen are parameter changes and nothing else.</strong> Ten "
          "need the simulation to spawn and track an object it otherwise has no "
          "reason to know about \u2014 braziers, puffballs, afterimages, illusory "
          "guards. Sixteen need a periodic or conditional rule: Rewind restores "
          "world state from ten seconds ago, which \u00a724.10\u2019s input-log "
          "model keeps no snapshots for; Held breath advances time only while a "
          "crew member moves, which is not a parameter of the simulation but a "
          "different simulation.<br><br>This is not an argument against those "
          "laws. It is the engine budget \u00a726.1 does not contain: 32 of them "
          "are features, and they were costed as content.",
     rec="Two things follow. <strong>Tag every law with its kind before "
         "authoring resumes</strong> \u2014 <code>python3 tools/law_effects.py "
         "--write</code> emits the table \u2014 so a scope cut can drop the "
         "expensive ones rather than the unpopular ones; D6\u2019s proposed cut "
         "from 48 laws to 24 is a very different saving depending which 24. And "
         "<strong>state the rule sheet</strong>. \u00a77.3 asserts laws are "
         "parameters without ever listing the parameters, and a vocabulary that "
         "grows to fit each new law is not a vocabulary."
         "<br><br><strong>Both drafted</strong>, in "
         "<code>docs/design/spec/laws.md</code>: the twenty parameters are "
         "listed, and <code>tools/scope_cut.py</code> costs the cut this "
         "finding said would depend on <em>which</em> 24. It does. "
         "Weighting each kind by the engine work it needs, all 48 cost 84 "
         "points; a cost-aware 24 costs <strong>15</strong> and a 24 chosen "
         "by rank costs 39. <strong>Choosing which 24 by cost rather than by "
         "rank saves 62% of the cut\u2019s remaining engine work for exactly "
         "the same amount of content</strong>, keeps all sixteen free laws, "
         "and still fills \u00a77.7\u2019s six schools evenly at four each."
         "<br><br>The rank split is where the cost hides: of 18 Commons 9 "
         "are pure parameter changes, and of 12 Deep laws <strong>one</strong> "
         "is. Depth is bought with engine work \u2014 a reasonable design, "
         "and an unbudgeted one."),

dict(id="F11", kind="finding", severity="blocking", status="open",
     title="Weaving the player\u2019s own laws makes a generated defence worse, not better",
     refs=["13.3", "13.2", "7.3", "5.5"],
     body="v3.0\u2019s \u00a713.3 gives every player a defence generated "
          "\u201cfrom their realm, their laws and their ruleborn\u201d. Of the "
          "nineteen laws whose effect a rule sheet can express, <strong>five help "
          "the defender</strong> \u2014 Glass, Kinship, Thorns, Regrowth, "
          "Whispers \u2014 and fourteen help the raider or cut both ways. Laws "
          "apply to everyone in the realm (\u00a77.3), so that asymmetry is "
          "structural rather than accidental.<br><br>Simulated hold rate against "
          "a competent crew, by what the generator weaves:<br><br>"
          "<code>realm &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1 &nbsp;&nbsp;&nbsp;2 "
          "&nbsp;&nbsp;&nbsp;3 &nbsp;&nbsp;&nbsp;4 &nbsp;&nbsp;&nbsp;5<br>"
          "no laws &nbsp;&nbsp;&nbsp;7% &nbsp;&nbsp;7% &nbsp;29% &nbsp;35% "
          "&nbsp;43%<br>"
          "any laws &nbsp;&nbsp;2% &nbsp;&nbsp;3% &nbsp;&nbsp;9% &nbsp;&nbsp;6% "
          "&nbsp;&nbsp;4%<br>"
          "sign-aware 9% &nbsp;13% &nbsp;40% &nbsp;44% &nbsp;54%</code> "
          "<span style=\"opacity:.7\">(150 runs a cell)</span>"
          "<br><br><strong>A generator that weaves the player\u2019s laws "
          "naively produces a weaker island than one that weaves none</strong> \u2014 "
          "2 to 9% against 7 to 43%, at every realm level. Reading the sign of "
          "each law recovers it and then some. This is the "
          "same shape as D13\u2019s note imbalance: the law pool leans toward the "
          "side that is not paying for it.<br><br>Note the first two rows as "
          "well: <strong>no generator reaches \u00a713.2\u2019s band at realm "
          "level 1 or 2</strong>, which is where every new player starts and "
          "where most of the target pool sits early in a season."
          "<br><br><strong>Re-measured after D55</strong> (the harness now reads peripheral vision as the content file does; same seeds and sample sizes): random laws still weaken the defence against none at every realm, and sign-aware laws still recover it (realm 3: 10% random, 48% sign-aware; realm 5: 5% and 58%). The finding holds. (The count of defender-helping laws is F31’s question, not D55’s.)",
     rec="\u00a713.3 should say what the generator optimises for, because "
         "\u201cgenerated from their laws\u201d has at least three meanings and "
         "two of them are worse than nothing. And \u00a713.2\u2019s 30\u201345% "
         "band should be a stated requirement on the generator, not only on "
         "designed islands \u2014 F9 asked for that and this is why it matters. "
         "<code>python3 -m tools.heist_harness defence</code>."
         "<br><br><strong>Re-measured on the current harness</strong>: the "
         "no-laws row now reads 9/9/32/29/44 across realms 1 to 5 against "
         "the 7/7/29/35/43 recorded here, every cell within about one "
         "standard error at 150 raids a cell. The table stands."
         "<br><br>Specified in <code>docs/design/spec/generator.md</code>, "
         "which weaves by sign throughout and says what the generator "
         "targets. The sign fix stands and is not enough on its own: with "
         "sign-aware laws <em>and</em> the shaped geometry, realms 1 and 2 "
         "still miss the band at \u00a75.2\u2019s one guard post (F22).",
     measured="re-run against harness ef4163da978cc0f0 (D55)"),

dict(id="F12", kind="finding", severity="design", status="open",
     title="Eight laws need a decision from the owner that a generator has to make",
     refs=["13.3", "7.7", "5.5"],
     body="Tilt slopes the realm \u201ctoward a side the owner picks\u201d. "
          "Current blows \u201cone way, chosen by the owner\u201d. Slow rivers "
          "lets \u201cthe owner draw streams on the realm\u2019s grid\u201d. "
          "Lodestones, Heat bloom and Soul lanterns are placements; Shifting "
          "stones is a loop the owner draws; Inward pull assumes a direction that "
          "is well defined for a realm with one Heart link and not for one with "
          "two.<br><br>Eight of forty-eight laws therefore carry a parameter that "
          "is not a number in a table but an act of authorship. That was fine "
          "while authorship was the default. <strong>\u00a713.3 made curation the "
          "default and authorship the deep end</strong>, so for most islands the "
          "generator now makes these choices \u2014 and a badly chosen slope or "
          "stream turns the defender\u2019s law into the raider\u2019s.",
     rec="<strong>Drafted \u2014 one rule, and the eight are instances of "
         "it.</strong> <em>Place every authored parameter against the shortest "
         "route from the landing edge to the Heart: along it for what costs a "
         "crosser to pass, across it for what costs a crosser to cross, and "
         "never so that the route is sealed.</em>"
         "<br><br>Three things the document already states make that the cheap "
         "rule rather than a new system. \u00a76.1 forbids sealing the route, "
         "so the generator <em>already computes it</em> \u2014 this needs no "
         "machinery it does not have. \u00a712.5 has the raider enter at an "
         "edge and move inward, so \u201ctoward the Heart\u201d and "
         "\u201cagainst the raider\u201d are the same direction. And "
         "\u00a712.7 makes the loaded escape the tense half, so anything that "
         "costs speed is worth more pointed at the way out than the way in "
         "\u2014 which is what decides Tilt and Current, the two F12 names "
         "first."
         "<br><br>Lodestones is the only one placed <em>off</em> the route: a "
         "pull on the route drags a crew along it, so it has to flank one, and "
         "the clearance keeps \u00a76.1 true by construction rather than by a "
         "check afterwards. <code>tools/law_effects.py</code> prints all eight "
         "with the argument for each, and its self-test fails if a law moves "
         "in or out of the authored set without a rule moving with it."
         "<br><br>The alternative F12 originally offered \u2014 marking these "
         "eight as laws a generated realm cannot weave \u2014 is still open "
         "and is one column in the law table. It costs a sixth of the law "
         "pool on every curated island, which is why the rule is worth the "
         "page it takes."),

dict(id="D22", kind="deviation", severity="change", status="done",
     title="Law effects became a classified table, not prose to be read twice",
     refs=["7.3", "12.21", "7.7"],
     body="\u00a77.3 claims laws are parameters and \u00a712.21 makes it a rule, "
          "but the 48 law sheets state their effects in prose and nothing maps "
          "them onto anything. So the claim could not be checked, and was not.",
     rec="<code>tools/law_effects.py</code> classifies every law against a "
         "twenty-parameter rule sheet and emits "
         "<code>content/law_effects.json</code>. It refuses to run if a law names "
         "a parameter outside the sheet, or if a law has no classification at all "
         "\u2014 so a new law in a future season cannot be added without saying "
         "what kind of thing it is. The harness weaves the nineteen it can apply, "
         "which is how F11 was measured."),

dict(id="F13", kind="finding", severity="blocking", status="open",
     title="\u00a712.22\u2019s matchmaking guarantee has no targets to draw from early",
     refs=["12.22", "13.2", "13.3"],
     body="\u00a712.22 step 3 is a promise: \u201cthe list is built so the median "
          "offered target is winnable at the player\u2019s chosen difficulty: "
          "candidates are sorted by predicted success and the middle of the list "
          "is drawn from the 55 to 70% band\u201d. That band is \u00a713.2\u2019s "
          "30\u201345% hold rate, seen from the raider\u2019s side.<br><br>"
          "Measured, a generated island at realm level 1 or 2 holds 2\u201313% "
          "under every generator tried \u2014 <strong>a raider success rate of 87 "
          "to 98%</strong>. There is no band to draw the middle of the list from, "
          "because every candidate is far easier than the band\u2019s easy end. "
          "\u00a712.22\u2019s step 4 does not help: it widens the bands when "
          "nothing matches, and widening cannot produce a target that is not "
          "there.<br><br>The chain is short and each link is the document\u2019s "
          "own: \u00a713.3 makes most islands generated, F11 measures what "
          "generated islands hold, and \u00a712.22 promises a median drawn from a "
          "band those islands do not reach.",
     rec="This is F11\u2019s consequence rather than a separate defect, and it is "
         "why F11 is blocking. Fix the generator and this resolves; leave it and "
         "\u00a712.22 promises something the target pool cannot supply, most "
         "visibly to new players. Worth stating in \u00a712.22 either way: what "
         "the matchmaker does when the band is empty rather than merely sparse."
         "<br><br><strong>\u201cFix the generator\u201d turns out not to be "
         "enough.</strong> The generator is fixed \u2014 sign-aware laws and "
         "the shaped geometry, in <code>spec/generator.md</code> \u2014 and "
         "realms 1 and 2 still run at 78\u201395% raider success, because "
         "\u00a75.2 allows one guard post there and the ceiling without a "
         "second is 16.5% (F22). This item resolves when \u00a75.2 changes, "
         "not when the generator does."),

dict(id="F14", kind="finding", severity="blocking", status="open",
     title="v3.0\u2019s fill term cuts the number \u00a79.6 calls load-bearing by three fifths, and it was not re-derived",
     refs=["9.6", "12.19", "14.4", "14.2"],
     body="\u00a79.6 states its own key figure and says why it matters: \u201can "
          "attempt is worth about 46% of a clean same-level haul, <em>which is the "
          "number the progression curve is built on</em>: an upgrade costing 25 "
          "clean raids takes about 55 attempts, or nine days at six a day, at "
          "every level.\u201d That 0.46 is E[grade] over all attempts, and it "
          "reconciles exactly: 62.5% succeed, split 35/40/25 clean/loud/partial, "
          "giving 0.456.<br><br>v3.0 then added <code>fill</code> to the same "
          "formula \u2014 \u201cthe share of the crew\u2019s bags actually "
          "loaded\u201d \u2014 and left 0.46 alone. Measured in the harness, a "
          "crew playing to \u00a712.19\u2019s own 70% break-even gets out with "
          "<strong>40%</strong> of its bags filled: it reaches the break-even on "
          "37% of successful runs and is interrupted before it on the rest. So an "
          "attempt is worth <strong>0.46 \u00d7 0.40 = 0.18</strong>, not 0.46."
          "<br><br>Measured end to end rather than as a product \u2014 "
          "E[grade \u00d7 fill] straight off the runs \u2014 it is "
          "<strong>0.127</strong>, lower again, because the harness also "
          "disagrees with \u00a79.6\u2019s assumed grade mix: 56.7% of attempts "
          "succeed against \u00a79.6\u2019s 62.5%, and fewer of those are "
          "clean. 0.18 is the charitable figure and 0.127 is the measured one."
          "<br><br>Run through the economy model, that is a <strong>60% cut to "
          "the raid faucet</strong>, and \u00a79.6\u2019s own worked example "
          "becomes <strong>136 attempts</strong> \u2014 197 at the measured "
          "0.127 \u2014 rather than 55. Every date in "
          "\u00a714 moves.<br><br>The measured figure was 52% until D24 was "
          "fixed, and the correction matters in both directions: the cut is "
          "larger than reported, and \u2014 more importantly \u2014 the 52% was "
          "a constant where the truth is a spread. See F19.",
     rec="Re-derive 0.46 against the fill term, or state that fill is already "
         "inside it \u2014 but not both, and not neither. "
         "<code>Config(apply_fill=True)</code> in the economy model applies the "
         "measured value, and a test asserts the size of the gap so it cannot "
         "close quietly. This is C19\u2019s pattern applied to the single number "
         "\u00a79.6 names as the one the curve rests on.<br><br>Re-deriving it "
         "as a single number is not enough on its own: F19 shows the same term "
         "moves the haul 2.2\u00d7 with how well the raid is played, so whatever "
         "0.46 becomes is the centre of a band rather than a value."
         "<br><br><strong>Re-measured on the current harness</strong>, 1,200 "
         "seeds: an attempt is worth <strong>0.122 \u00b1 0.006</strong> of a "
         "clean same-level haul against the 0.127 recorded here, and mean fill "
         "on a successful run is 40.8%. The finding reproduces.<br><br>F19\u2019s "
         "multiplier in the sentence above is now <strong>1.39\u00d7</strong>, "
         "not 2.2\u00d7: that item has been re-measured twice and the correction "
         "belongs here too. <code>test_the_fill_term_cuts_9_6s_load_bearing_"
         "number_by_most_of_it</code> now pins this, so it cannot drift again "
         "without the build going red.",
     measured="496955db53f8d3c4e13f7d1683dd4c47fb49a682f43301859cf1276e10b3c13d"),
dict(id="F20", kind="finding", severity="significant", status="proposed",
     title="The best fixed stopping rule is about 90% full, not \u00a712.19\u2019s 70%",
     refs=["12.19", "9.6", "5.4", "12.17"],
     body="\u00a712.19 makes the most falsifiable claim in the document and says "
          "it is load-bearing: \u201cThe break-even sits at about 70% full \u2014 "
          "at that point the extra load is worth exactly what a loud exit costs. "
          "<em>That single number is the dial for the game\u2019s emotional "
          "peak.</em>\u201d<br><br>\u00a79.6 says what a raid is worth, and a "
          "stopping rule moves two of its terms, so the quantity to maximise is "
          "E[grade \u00d7 fill]. Hold everything else about a competent crew "
          "fixed and vary only where it stops. 300 raids a "
          "row:<br><br><code>"
          "stops at &nbsp;50% &nbsp;E = 0.1022 \u00b1 0.0089<br>"
          "stops at &nbsp;60% &nbsp;E = 0.1113 \u00b1 0.0103<br>"
          "stops at &nbsp;70% &nbsp;E = 0.1271 \u00b1 0.0116 &nbsp;\u2190 "
          "12.19\u2019s<br>"
          "stops at &nbsp;80% &nbsp;E = 0.1315 \u00b1 0.0128<br>"
          "stops at &nbsp;90% &nbsp;E = 0.1646 \u00b1 0.0157 &nbsp;\u2190 peak<br>"
          "stops at 100% &nbsp;E = 0.1589 \u00b1 0.0161</code><br><br>"
          "<strong>Loading past 70% is worth about 30% more an attempt and costs "
          "nothing measurable in success rate</strong> (56.7% at 70%, 54.7% at "
          "90%). A break-even exists, as \u00a712.19 says; it sits about twenty "
          "points above where \u00a712.19 puts it, which makes the region the "
          "document calls the decision a slope.<br><br>And no fixed rule is the "
          "best rule. A crew that reads \u00a712.17\u2019s visible suspicion "
          "and varies its threshold gets <strong>0.187</strong>, beating the "
          "best fixed threshold by 13% (F19). The decision \u00a712.6 asks for "
          "is real \u2014 it is just not the decision \u00a712.19 "
          "describes.<br><br><strong>Settled at \u00a713.4\u2019s own sample "
          "size.</strong> The sweeps above read a peak off an argmax, which is a "
          "noisy statistic; paired over the same seeds at <strong>700 raids a "
          "threshold</strong> the comparison is decisive:<br><br><code>"
          "stops at &nbsp;70% &nbsp;E = 0.1231 &nbsp;success 53.3%<br>"
          "stops at &nbsp;80% &nbsp;E = 0.1370 &nbsp;+0.0139 \u00b1 0.0077 "
          "&nbsp;t = 1.8<br>"
          "stops at &nbsp;90% &nbsp;E = 0.1595 &nbsp;<strong>+0.0364 \u00b1 "
          "0.0080 &nbsp;t = 4.5</strong> &nbsp;success 52.0%</code><br><br>"
          "<strong>+30% an attempt for 1.3 points of success rate.</strong> That "
          "matters because at the sweeps\u2019 own sample sizes the same "
          "comparison is only t \u2248 2.3, and it had been run several times "
          "\u2014 marginal evidence, repeated, which is how the two findings "
          "withdrawn beside this one happened. It is not marginal at 700."
          "<br><br>Measured twice more than it should have needed besides: at "
          "150 raids a row the curve rose all the way to 100%, which would have "
          "meant no break-even at all, and that did not survive a larger sample; "
          "the numbers above are after D25."
          "<br><br><strong>Re-measured after D55</strong> (the harness now reads peripheral vision as the content file does; same seeds and sample sizes): the best fixed stopping point is still 95% (E 0.1760 → 0.1805), and stopping at 70% still costs about a third: +37% at the peak against +33%. The finding holds.",
     rec="Specified in <code>docs/design/spec/loading.md</code>.<br><br>"
         "<strong>1. Re-derive the number rather than asserting it.</strong> "
         "<code>python3 -m tools.heist_harness breakeven</code> prints the curve "
         "and the break-even is where it turns over. 70% is not where it turns "
         "over.<br><br><strong>2. Say that the rule should vary.</strong> "
         "\u00a712.19 describes a single threshold; the measurement says a "
         "crew reading the guards beats every single threshold. That is the "
         "decision \u00a712.6 wants and \u00a712.17 already provides the "
         "information for, and the document does not connect them.<br><br>"
         "<strong>3. Give staying a price that is not the clock.</strong> "
         "\u00a712.19 names one \u2014 \u201cthe alarm clock is the "
         "price\u201d \u2014 and cutting \u00a75.4\u2019s clock to 55% of "
         "its length moves the stopping decision not at all: a tighter clock "
         "kills crews on the way <em>in</em>. A cost priced in loot does bite "
         "where a cost priced in time does not, which is the best argument for "
         "the Spire\u2019s reach in <code>spec/response.md</code>.<br><br>"
         "<strong>Measured, and it works.</strong> With the Spire\u2019s reach "
         "re-sealing 8 units a second the peak moves from 100% to 90%; at 15 a "
         "second it moves to 60%. The rate is a dial on where the raider\u2019s "
         "break-even sits, and \u00a712.19\u2019s stated 70% falls between the "
         "two \u2014 so the document\u2019s number is not wrong, it is "
         "<em>unimplemented</em>. \u00a712.19 describes the game as it would be "
         "with a mechanism \u00a713.2 names and never specifies.<br><br>The "
         "cost, and the rule in \u00a79.6 that removes it: raising the rate "
         "raises the hold rate too (45.0% \u2192 48.5% \u2192 53.0%) against "
         "\u00a713.2\u2019s 30\u201345% band, because a fast re-seal empties "
         "the Vault before a slow crew loads anything and the raid is foiled. "
         "\u00a79.6 already forbids that outcome \u2014 \u201ca clean raid on "
         "a fully sealed island still pays 0.7; nobody ever leaves with "
         "nothing\u201d. With that floor applied to the re-seal, <strong>20 a "
         "second stopping at 45% moves the break-even from 100% to 80% and "
         "leaves the hold rate at 44.5%</strong>, inside the band and within "
         "noise of the 45.0% baseline.<br><br>So two things the document names "
         "and never specifies \u2014 \u00a713.2\u2019s \u201cthe Spire\u2019s "
         "reach\u201d and \u00a79.6\u2019s floor \u2014 combine to make "
         "\u00a712.19\u2019s sentence very nearly true. The number was not "
         "wrong; the mechanism that would have justified it was missing.",
     measured="re-run against harness ef4163da978cc0f0 (D55)"),

dict(id="F21", kind="finding", severity="blocking", status="open",
     title="Outcomes polarise with skill: the better a crew plays, the more it "
           "sweeps or comes home empty",
     refs=["13.2", "12.17", "12.19"],
     body="\u00a713.2 is unusually explicit about the health signal, and it is "
          "not the average: \u201cA game where raids either sweep or fail "
          "completely, with nothing in between, is a polarised one even if the "
          "mean looks right\u2026 We watch the spread of clean runs, partial "
          "hauls and foiled raids, and treat a <strong>populated middle</strong> "
          "as the goal.\u201d<br><br>Fill on every successful raid, 300 raids a "
          "crew, same islands and seeds \u2014 the only difference is how well "
          "the crew plays:<br><br><code>"
          "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "&nbsp;&nbsp;&nbsp;competent &nbsp;&nbsp;&nbsp;optimal<br>"
          "&nbsp;&nbsp;0\u201319% &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;30.0% &nbsp;"
          "&nbsp;&nbsp;&nbsp;<strong>58.0%</strong><br>"
          "&nbsp;20\u201339% &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;16.5% &nbsp;&nbsp;"
          "&nbsp;&nbsp;&nbsp;0.6%<br>"
          "&nbsp;40\u201359% &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;23.5% &nbsp;&nbsp;"
          "&nbsp;&nbsp;&nbsp;2.4%<br>"
          "&nbsp;60\u201379% &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;30.0% &nbsp;&nbsp;"
          "&nbsp;&nbsp;13.0%<br>"
          "80\u2013100% &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;0.0% &nbsp;&nbsp;"
          "&nbsp;&nbsp;<strong>26.0%</strong><br><br>"
          "middle (20\u201379%) &nbsp;<strong>70.0%</strong> &nbsp;&nbsp;&nbsp;"
          "<strong>16.0%</strong></code><br><br>A competent crew has exactly the "
          "populated middle \u00a713.2 asks for. A crew that reads "
          "\u00a712.17\u2019s guards has <strong>16%</strong> in the middle: "
          "it sweeps on a quarter of its successful raids and comes home with "
          "almost nothing on more than half.<br><br>The mechanism is the "
          "information, not the greed. Reading a guard\u2019s suspicion turns "
          "every raid into an early yes-or-no: commit and take everything, or "
          "abandon at 35% and walk. There is no reason left to take a middling "
          "haul once you can tell which run you are in.<br><br>So "
          "\u00a713.2\u2019s warning is tripped, and it is tripped "
          "<em>specifically for the players who read the game best</em> \u2014 "
          "the ones most likely to be visible, to post replays and to set what "
          "everyone else copies."
          "<br><br><strong>Re-measured after D55</strong> (the harness now reads peripheral vision as the content file does; same seeds and sample sizes): measured with <code>test_skill_polarises_outcomes</code>’s setup (realm 3, one link, sign-aware laws, 300 raids), which does not reproduce the 30.0% and 58.0% above exactly. On it the polarisation holds on both harnesses: successful raids filling 20–79% are 74% → 70% of a competent crew’s and 9% → 9% of an optimal one’s.",
     rec="This is \u00a713.2\u2019s own health metric failing on its own terms, "
         "and the population it fails for is the worst one to fail for. It is "
         "also not fixable by tuning the break-even: F20 moves the threshold and "
         "the polarisation moves with it.<br><br>What would populate the middle "
         "is a reason to leave at a fill the crew did not choose in "
         "advance:<br><br><strong>1. The Spire\u2019s reach</strong> "
         "(<code>spec/response.md</code>) \u2014 a Vault that re-seals while it "
         "is being robbed sets the fill from outside the crew\u2019s rule "
         "entirely.<br><br><strong>2. A flatter Carry spread</strong> "
         "(\u00a711.1) \u2014 the Carrier is 300 of a crew\u2019s 560, so "
         "\u201cthe Carrier filled\u201d is very nearly the whole "
         "distribution. Five similar bags turn one binary into five small "
         "decisions.<br><br><strong>3. Make abandoning cost something.</strong> "
         "Leaving at 35% currently counts as a success and pays almost nothing, "
         "which is why it is free to do it often. \u00a712.9\u2019s grades "
         "have no band between \u201cpartial\u201d and nothing."
         "<br><br><code>python3 -m tools.heist_harness depth</code>.",
     measured="re-run against harness ef4163da978cc0f0 (D55)"),

dict(id="D27", kind="deviation", severity="change", status="done",
     title="The check for D26\u2019s fault found four more, and one of them is "
           "the design\u2019s own joke",
     refs=["9.5", "14.2", "5.4"],
     body="D26\u2019s recommendation said a check for fields that are computed "
          "and never read \u201cwould have caught all three\u201d of this "
          "session\u2019s harness faults. <strong>That was wrong and is "
          "corrected.</strong> D25\u2019s <code>heist.clock</code> was read in "
          "four places in <code>sim.py</code>; what was missing was that no "
          "<em>policy</em> read it. D24 was a wrong condition, not an unread "
          "field. The check catches D26\u2019s class and no more, and its "
          "docstring now says so.<br><br>Built anyway, because that class is "
          "real, it immediately found four more:<br><br><code>"
          "Result.lost_to<br>"
          "State.aether<br>"
          "State.essence<br>"
          "Archetype.lab_experiments_per_day</code><br><br>"
          "<strong><code>Result.lost_to</code> was the useful one.</strong> It "
          "records whether a foiled raid died to \u00a75.4\u2019s clock or to "
          "a guard, and nothing read it. Surfaced in the depth report it says "
          "the clock finding more sharply than anything else has: <strong>at "
          "most 5% of raids fail to the clock</strong>, and for the crews that "
          "play best it is 0%. Every other failure is a capture. The evidence "
          "for \u201cthe clock is not a price\u201d was sitting in a field "
          "nobody consumed.<br><br><strong>And the joke.</strong> "
          "<code>State.aether</code> and <code>State.essence</code> accumulate "
          "every day of every run and are never read, and "
          "<code>Archetype.lab_experiments_per_day</code> is defined per "
          "archetype and never spent. The economy model has two currency "
          "balances with no readers, which is precisely the fault F17 records in "
          "the design \u2014 two currencies with no sinks. The model reproduced "
          "the thing it was built to measure.",
     rec="<code>lost_to</code> is now a column in the depth report. The three "
         "economy fields are recorded in the check\u2019s "
         "<code>KNOWN_UNREAD</code> table with a reason each rather than "
         "quietly allowed: making the model pay \u00a79.5\u2019s prices is a "
         "feature, not a fix, and <strong>F17\u2019s numbers do not depend on "
         "it</strong> \u2014 they come from \u00a79.3\u2019s published table "
         "and the daily log, not from these balances. An entry in that table is "
         "a debt that has been looked at.<br><br>The check is a build gate and "
         "has a <code>--self-test</code>, on the same principle as "
         "<code>check_docs_consistency.py</code>: a checker that cannot "
         "demonstrate a failure has never been shown to work."
         "<br><br>What no script catches, stated plainly because two of the "
         "three faults are in it: <strong>when the document states a number "
         "about behaviour, the test has to run the behaviour.</strong> D24 "
         "survived a test asserting <code>Carrier.carry / 30 == 10</code> while "
         "\u00a712.19\u2019s claim was about what a crew does."),

dict(id="D28", kind="deviation", severity="change", status="done",
     title="The job that keeps the playable build current ran, reported "
           "success, and published nothing",
     refs=["30.18", "26.7", "19.27"],
     body="The prototype is the only artefact anyone outside this repository "
          "can actually touch, so an hourly Routine republishes it when the "
          "branch moves. It fired, took fifty-eight seconds, and was recorded "
          "<code>SUCCEEDED</code>. The published page did not change. "
          "<strong>Two faults, either one fatal on its own.</strong>"
          "<br><br><strong>It could not tell new from old.</strong> The job "
          "compared the prototype’s last commit date against the "
          "artifact’s publish date, and <code>Artifact action: "
          "\"list\"</code> reports only a calendar day. A commit and a publish "
          "on the same day are indistinguishable — so from the first day "
          "the two coincided, which was the day it was written, the job would "
          "have answered <em>already current</em> for ever."
          "<br><br><strong>It could not publish.</strong> "
          "<code>Artifact action: \"read\"</code> saves the live page to a "
          "file and counts the version as viewed only once every line of it "
          "has been read. The prompt said to read it; it did not say that a "
          "partial read does not count. So the read was partial, the publish "
          "was refused, and the turn ended without error."
          "<br><br>The second is the same shape as D24–D26 wearing "
          "different clothes, and it is the one worth keeping: <strong>a job "
          "that cannot fail cannot be trusted when it passes.</strong> Nothing "
          "threw, so nothing was reported, so the artifact sat a day behind "
          "the code while the dashboard read green.",
     rec="Both fixed. The page now carries a <code>BUILD</code> stamp — a "
         "digest of itself with that line removed — so the job compares "
         "the published page against the current page instead of comparing two "
         "dates: <em>is the published page this page?</em> "
         "<code>build_prototype.py --stamp</code> prints it, "
         "<code>--self-test</code> proves it still moves when the page moves, "
         "and both are build gates. The prompt now spells out the full-read "
         "requirement, and a final step requires the publish to report a new "
         "version number before the run may claim to have worked."
         "<br><br>Generalised since: <code>tools/build_stamp.py</code> stamps "
         "<strong>all three</strong> published pages — the prototype, this "
         "register and the roadmap — and holds each one’s path and "
         "artifact URL, so the job reads what to publish rather than carrying "
         "a hard-coded list. The prototype keeps its stamp as a JavaScript "
         "constant because it shows it on screen; the two generated pages "
         "carry an HTML comment. One digest function strips either form, "
         "because two implementations of a stamp would be the very fault this "
         "register exists to record."
         "<br><br>The general rule, alongside D27’s: <strong>an automated "
         "job needs a check that its work landed, not just that it ran.</strong>"),

dict(id="D30", kind="deviation", severity="change", status="done",
     title="The content tables were extracted from v3.0, and the check that "
           "guards them read v3.0 too",
     refs=["31.2", "31.4", "11.2", "10.4", "26.1"],
     body="<code>content/*.json</code> is the data half of \u00a731.2\u2019s "
          "split, and <code>tools/extract_content.py</code> built it from "
          "<code>ruleborn-game-design-v3.0.txt</code>. "
          "<code>tools/validate_content.py</code> validated it against the same "
          "file. So the tables described the previous version of the document "
          "and the gate compared them with the previous version of the "
          "document, and the pair agreed."
          "<br><br><strong>Three things v3.1 did that nothing here could "
          "see.</strong>"
          "<br><br><strong>1. \u00a711.2 gained Size and Flies</strong>, which "
          "is C26\u2019s fix. The reader took the summary table by column "
          "offset \u2014 school at +1, role at +2, ability at +3 \u2014 so two "
          "new columns made every creature\u2019s ability read "
          "<code>standard</code> and every passive <code>yes</code> or "
          "<code>no</code>. That would have gone into the tables as fact, and "
          "nothing would have caught it: C6 compares \u00a711.2 against "
          "\u00a711.11\u2019s character bible, so a shifted read makes "
          "eighteen creatures disagree about their ability \u2014 which is what "
          "C6 says they do. <strong>A fault that produces the symptom the "
          "register is already expecting is the hardest kind to see.</strong>"
          "<br><br><strong>2. The Library moved from \u00a710.5 to "
          "\u00a710.4</strong> and gained all ten levels. Two markers named the "
          "number, so pointing the reader at v3.1 dropped the Library out of "
          "<code>buildings.json</code> altogether and fed its level table to "
          "the ward reader as ninety-nine wards named \u201c1\u201d, "
          "\u201c2\u201d and \u201c900 Starlight\u201d."
          "<br><br><strong>3. The economy model was still interpolating the "
          "seven levels v3.1 states.</strong> v3.0 gave 1, 5 and 10 and the "
          "model fitted a geometric curve through them, honestly labelled. "
          "v3.1\u2019s own figures are flatter early and the fit ran low at "
          "every level in between: <strong>3.7 against 5 at level 2, 4.5 "
          "against 6 at level 3, 5.5 against 8 at level 4</strong> \u2014 up to "
          "47% understated, and 16.5% summed across the ladder. The Library is "
          "the non-raiding page source, so that is a faucet understated for as "
          "long as the fit stood: a Codex on a level-3 Library alone was "
          "modelled at 295 days against the document\u2019s own 220.",
     rec="All three fixed, and the fourth fault \u2014 the one that let the "
         "other three stand \u2014 fixed with them."
         "<br><br><strong>The markers are titles now.</strong> "
         "<code>heading()</code> finds a section by its title and reads its "
         "number, so a renumbering cannot silently move a table out from under "
         "a reader. <strong>The summary table is read by column heading</strong> "
         "and refuses to guess: an unrecognised header stops the extraction "
         "rather than shifting the row. <strong>The Library curve is the "
         "document\u2019s</strong>, all ten levels, and a level outside the "
         "table raises rather than interpolating \u2014 a fallback that is "
         "never exercised is a second implementation nobody checks."
         "<br><br><strong>And <code>validate_content.py</code> now has the "
         "four-state verdict <code>check_document.py</code> has had since the "
         "merge.</strong> It was reporting G12, C10 and D14 as open "
         "contradictions against a register that had all three closed, and "
         "nothing compared the two \u2014 which is C21 to C24 exactly, a fix "
         "that landed in one place and a copy nobody retired. A report about a "
         "closed item now fails the build and says the checker is the thing "
         "out of date."
         "<br><br>Two of its constants were the copies: <strong>30 traits and "
         "16 building types</strong>, both of which v3.1 recounted to 31 and 17. "
         "\u00a726.1\u2019s launch table is read now. G12 closed on its own "
         "once the size band and the flight flag were in the data, and its "
         "check \u2014 which asked whether \u201cbig\u201d was the <em>name</em> "
         "of a creature, and so could never have gone green \u2014 asks whether "
         "any creature carries a value the word picks out. D14\u2019s three "
         "numbers are pinned to its own note instead of reported as an open "
         "item, so if the content moves them the note is what the build calls "
         "stale."),

dict(id="D32", kind="deviation", severity="significant", status="open",
     title="Both ability tables hand a crew two to three times the decisions "
           "\u00a712.6 budgets for the whole run",
     refs=["12.6", "12.5", "11.2", "11.11"],
     body="\u00a712.6 sets the game\u2019s pace in its own words: <em>\u201ca "
          "string of small, tense decisions: roughly one every 8 to 12 seconds, "
          "or 15 to 25 in a run\u2026 never about tapping faster\u201d</em>, "
          "and it names <em>\u201cwhen to use abilities and casts\u201d</em> "
          "as one of the decisions it is counting."
          "<br><br>An ability comes off cooldown every <em>c</em> seconds per "
          "character, so a crew of <em>n</em> over a clock of <em>t</em> gets "
          "<code>t\u00d7n/c</code> windows. \u00a712.5 puts the crew at 3, 4 "
          "from Keeper 8 and 5 from Keeper 16, and the clock at 150 to 240 "
          "seconds. Against \u00a711.11\u2019s median 18-second cooldowns that "
          "is <strong>25 windows at the smallest and 67 at the largest</strong>; "
          "against \u00a711.2\u2019s median 14, <strong>31 and 83</strong>."
          "<br><br>So the smallest case in the document \u2014 a crew of three "
          "on a short route \u2014 exactly reaches the top of \u00a712.6\u2019s "
          "budget, and every case above it overruns. <strong>The overrun is not "
          "a tuning miss; it grows with the player.</strong> The crew goes 3 to "
          "5 and the clock 150 to 240 as Keeper levels rise, so the game gets "
          "roughly two and a half times more frantic between Keeper 1 and "
          "Keeper 16, and \u00a712.6 describes the first of those and not the "
          "second."
          "<br><br>For one ability to come off cooldown at \u00a712.6\u2019s "
          "own 8-to-12-second cadence, cooldowns would have to be 24\u201336 "
          "seconds at a crew of three and 40\u201360 at a crew of five. Both "
          "tables are 8\u201324.",
     rec="Answer one question and all eighteen cooldowns follow from it: "
         "<strong>is using an ability one of the decisions \u00a712.6 is "
         "counting, or is it texture between them?</strong>"
         "<br><br><strong>A decision.</strong> Cooldowns go to roughly 24 to 60 "
         "seconds and scale with crew size, so a character\u2019s ability fires "
         "once or twice in a heist and choosing the moment is the point. "
         "\u00a712.6\u2019s count stands as written. This is the reading its "
         "own words support."
         "<br><br><strong>Texture.</strong> Keep the short cooldowns and rewrite "
         "\u00a712.6\u2019s count to be about routes, pylons and greed, with "
         "abilities explicitly outside it. Then say what stops the phone "
         "becoming a tapping game, which \u00a712.6 currently rules out in the "
         "same paragraph."
         "<br><br>Either way the number is one decision rather than eighteen, "
         "which is why C6\u2019s drafted abilities settle the effects and leave "
         "the cooldowns here. <code>tools/ability_text.py --self-test</code> "
         "pins the overrun, so a re-cost that brings a table inside the budget "
         "fails the build and sends someone back to this item."),

dict(id="D54", kind="deviation", severity="significant", status="done",
     title="v3.2 rewrote §13.2 at length and moved no number the realm "
           "findings are measured against",
     refs=["13.2", "5.2", "10.2", "10.3", "12.17", "6.1"],
     body="Six of the nine open realm gates — F9, F11, F16, F22, F26, "
          "F27 — are measurements, not readings. v3.2 rewrote "
          "§13.2, which is where F26 and F9 are aimed, so the question "
          "is whether the measurements moved."
          "<br><br><strong>They cannot have.</strong> Every input is "
          "byte-identical between v3.1 and v3.2:"
          "<br><code>§5.2 &nbsp;ward and guard-post counts &nbsp;unchanged<br>"
          "§10.2 the Guardian Post ladder &nbsp;&nbsp;&nbsp;unchanged<br>"
          "§10.3 ward effects &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;unchanged<br>"
          "§6.1 &nbsp;terrain points &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;unchanged<br>"
          "§12.17 guard vision &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;unchanged<br>"
          "§13.2 the 30–45% hold band &nbsp;&nbsp;<strong>rewritten, "
          "band unchanged</strong></code>"
          "<br><br>Re-running <code>tools/post_ladder.py</code> against v3.2 "
          "reproduces F27's figures to the digit — 26.2%, 34.2%, 40.0%, "
          "40.0% at realm level 1 — which is the empirical half of the "
          "same answer."
          "<br><br><strong>What §13.2 gained is real and it is about "
          "something else.</strong> It now says the health signal is the "
          "shape of the outcomes rather than the average, cites Supercell on "
          "polarisation, and then reports that applied to a single crew the "
          "signal inverts — a crew reading suspicion and vision cones "
          "puts 16% of its runs in the middle bands against a fixed "
          "threshold's 70%. That is F21, answered, and F21 is closed. It says "
          "nothing about whether a realm can reach the band, which is what "
          "the other six are about.",
     rec="Recorded so it does not have to be re-derived next version. "
         "<code>python3 tools/version_diff.py --facts</code> reads every "
         "constant in <code>design_facts.py</code> against the section that "
         "owns it, in both versions, and prints which moved. Eight facts, "
         "none moved."
         "<br><br><strong>The distinction is worth keeping.</strong> "
         "<code>--items</code> diffs at the section and put all six of these "
         "on the worklist because §13.2 moved; <code>--facts</code> "
         "diffs at the number and takes them off it. A finding survives a "
         "version unless the number it was measured against moved, and "
         "reading the new prose would not have established that faster or "
         "more surely."
         "<br><br>So <strong>Realms is exactly where it was</strong>: nine "
         "gates, none cleared by v3.2, and all nine waiting on a decision "
         "rather than on more measurement."),

dict(id="F28", kind="finding", severity="significant", status="open",
     title="§12.6’s crack noise is erased by §12.17’s decay before it can move "
           "a guard",
     refs=["12.6", "12.17"],
     body="§12.6: “Cracking is loud: every 5 seconds adds 100 suspicion to "
          "every guard in the Heart.” §12.17 empties suspicion at 20 a tick "
          "whenever a guard sees nothing, so an unaware guard’s 100 is gone "
          "in five ticks — a sixth of a second — and never reaches Suspicious "
          "at 200. Twelve seconds of cracking leave every guard that cannot "
          "see the Vault exactly where it was.<br><br>Found by building it, "
          "not by reading: the simulation in <code>sim/</code> applies both "
          "rules as written, and "
          "<code>the_crack_noise_empties_before_it_can_matter</code> measures a "
          "guard 20 tiles away through twenty seconds of cracking. Peak "
          "suspicion 100; state never leaves Unaware.<br><br>What does make "
          "cracking loud is §12.17’s own noise table — “Breaking something, "
          "5 m” — which the simulation applies to every hit on the Vault. So "
          "the Vault is loud to guards within five walkable metres and silent "
          "to the rest of the Heart, which is not what §12.6 says it is.",
     rec="Make the crack noise a sound rather than a number: every hit is heard "
         "within 5 m as breaking something already is, and every 5 seconds "
         "every guard in the Heart hears the Vault and starts investigating it "
         "— §12.17’s “600, or on hearing something”. That keeps §12.6’s "
         "intent, rising pressure through the perception system, and gives it "
         "an effect. Adding more suspicion does not work at any size below "
         "600: it drains at the same 20 a tick.",
     measured="sim/: the_crack_noise_empties_before_it_can_matter"),
dict(id="F29", kind="finding", severity="significant", status="open",
     title="On plain ground §12.8’s ambush cannot be reached: the last "
           "crouched step behind a guard is heard",
     refs=["12.8", "12.17"],
     body="§12.8: “the first hit on a guard that has not noticed the crew "
          "stuns it for 2 seconds and deals triple Power” — the rule that "
          "lets clever beat strong, and how Scouts are beaten (“a quick "
          "ambush”). To hit, the crew stands beside the guard; the tile "
          "beside it is 1 m away. §12.17’s noise table: a crouched walk is "
          "heard within 1 m. So the step that arrives is heard, the guard "
          "investigates, and it is no longer a guard that has not noticed the "
          "crew.<br><br>The only silent gait, crawling, has no control and no "
          "speed anywhere in the document. The only other way in is a quiet "
          "surface: moss carries a crouched walk three quarters of a metre, "
          "under a step. Measured in <code>sim/</code>: "
          "<code>a_crouched_step_up_behind_a_guard_is_heard_unless_it_is_on_moss</code>. "
          "The planned heist that ends Clean does so only because the fixture "
          "puts moss behind two posts.",
     rec="Say the crouched walk’s 1 m is the tile it is made on, so the tile "
         "beside a guard can be reached unheard and the ambush has a way in. "
         "The alternatives are a crawl control (a ninth button against "
         "§12.7’s eight) or accepting that ambushes need a quiet surface — "
         "which would make moss a defensive decision, and should then be "
         "said.",
     measured="sim/: a_crouched_step_up_behind_a_guard_is_heard_unless_it_is_on_moss"),
dict(id="F30", kind="finding", severity="minor", status="open",
     title="“Cracking is 10 to 25 seconds” holds only with a Breaker in the "
           "crew",
     refs=["12.19", "12.6", "11.1"],
     body="At Vault level 1 (1,500 health, §12.6), one hit every 0.8 s for "
          "Power (§12.20), Breakers double: a Breaker alone opens it in 15.2 s "
          "and Scout, Breaker and Carrier in 12 s — inside §12.19’s band. A "
          "full crew takes 9.6 s, just under it. Four crew without a Breaker "
          "take 26.4 s, and a lone Scout 100 s.<br><br>So the band is a claim "
          "about crews that bring a Breaker, and §12.19 states it as a fact "
          "about cracking.",
     rec="State the assumption: 10 to 25 seconds with a Breaker in the crew. "
         "If a crew without one is meant to be able to crack at all, that is "
         "the number to decide.",
     measured="sim/: cracking_takes_ten_to_twenty_five_seconds_only_with_a_breaker"),
dict(id="G13", kind="gap", severity="significant", status="open",
     title="No speed for crouching or running, so crouching is free",
     refs=["12.17", "11.1", "12.18"],
     body="§12.17 prices both gaits for eyes and ears — crouched halves the "
          "rate you are noticed at and carries 1 m, running adds three "
          "quarters and carries 4.5 m — and no section gives either a speed. "
          "§11.1 gives one speed per role. Without a speed cost crouching is "
          "strictly better than walking and running strictly worse, and the "
          "choice <code>spec/movement.md</code> proposes (“slow and quiet "
          "against fast and loud”) does not exist.<br><br>Two implementations "
          "in this repository have now filled it differently: the Python "
          "harness crouches at §11.1’s speed and runs at double; "
          "<code>sim/</code> crouches at half and runs at double.",
     rec="State both against §11.1’s speed. Half and double is what "
         "<code>sim/</code> uses, and the audit page lists it as the "
         "simulation’s reading until this is signed off.",
     measured="sim/: CROUCH_PACE, RUN_PACE"),
dict(id="G14", kind="gap", severity="minor", status="open",
     title="A revived crew member comes back with no stated health",
     refs=["12.20"],
     body="§12.20: “An ally standing adjacent revives it in 3 seconds, a Mender "
          "in 1.5.” With what health is not said. At full health a revive is a "
          "free reset and an Alerted guard knocks the same member down again "
          "at no cost to the crew’s tempo; at one point it is a formality.",
     rec="A quarter of the role’s health, which is what <code>sim/</code> "
         "uses: enough to walk to the skiff, not enough to stand in a fight.",
     measured="sim/: REVIVE_HEALTH"),
dict(id="G15", kind="gap", severity="significant", status="open",
     title="Bags are measured in Carry and the Vault in Starlight, and nothing "
           "converts one to the other",
     refs=["12.6", "12.19", "9.6", "11.1"],
     body="§12.6: loading stops when “the target fill is reached, the bags are "
          "full, or the exposed share is gone”. Bags hold §11.1’s Carry — 60 "
          "to 300 units. The exposed share is §9.6’s, in Starlight and "
          "Essence. To know whether a crew empties a Vault before its bags "
          "fill, the two have to be the same unit, and no section says how "
          "many Starlight one unit of Carry is.<br><br><code>sim/</code> "
          "holds 560 units in its fixture’s Vault — a five-crew’s Carry — "
          "and says so on the audit page rather than presenting it as the "
          "document’s.",
     rec="Either state the exposed share in bag units, or state the "
         "conversion. It is a pricing decision, so it is yours to make.",
     measured="sim/: FIXTURE_EXPOSED"),
dict(id="C33", kind="contradiction", severity="significant", status="open",
     title="§6.2’s terrain table restates three detection rules and gets all "
           "three different from §12.17",
     refs=["6.2", "12.17", "12.8"],
     body="§12.8: “where any other section still describes perception, 12.17 "
          "wins.” §6.2’s terrain table still describes it, three times, and "
          "each time says something else:<br><br><code>"
          "Raised ground &nbsp;§6.2 &nbsp;“see 2 tiles further per level”<br>"
          "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "§12.17 “sees a metre further”<br>"
          "Tall grass &nbsp;&nbsp;&nbsp;§6.2 &nbsp;“hides anyone inside from guards "
          "more than 2 tiles away”<br>"
          "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "§12.17 “standing still … invisible until a guard walks into the tile”<br>"
          "Gravel path &nbsp;&nbsp;§6.2 &nbsp;“footsteps carry 1 tile further”<br>"
          "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "§12.17 louder ×1.25 — 0.6 m on a walk</code><br><br>"
          "The tall-grass pair is the sharpest: §6.2 hides a <em>moving</em> "
          "crew member from anything beyond two tiles, §12.17 hides only a "
          "<em>still</em> one, from everything outside the tile. A level "
          "designer reading §6.2 places grass as cover for a route; one reading "
          "§12.17 places it as a place to stop.<br><br>Found while building "
          "height in <code>sim/</code>, which follows §12.17 on all three, as "
          "§12.8 says it must. §6.2’s stairs (“footsteps carry 1 tile "
          "further”) have no §12.17 counterpart at all.",
     rec="Let §6.2’s cells point at §12.17 rather than restate it — the one "
         "home the document already names. Three edits, drafted.",
     measured=""),
dict(id="C32", kind="contradiction", severity="minor", status="open",
     title="Two reset times for the same ward at level 1",
     refs=["10.2", "10.3"],
     body="§10.2’s Ward row: level 1 “resets 10 s”, falling a second a level to 6. "
          "§10.3’s own table, in a column headed <em>Resets after</em>: Gravity "
          "Well 10 s, Time Snare <strong>12 s</strong>, Lantern Glare <strong>20 "
          "s</strong>. Two sections give the same fact for two of the three "
          "triggered wards, and they disagree. <code>spec/wards.md</code> took "
          "§10.2’s column without noticing §10.3’s.<br><br>Found building wards "
          "in <code>sim/</code>, which has to pick one: it takes §10.3’s, each "
          "ward’s own section, and says so.",
     rec="Keep §10.3’s per-ward times as each ward’s level-1 reset, and make "
         "§10.2’s column a reduction by level — 0, 10, 20, 30, 40% — so an "
         "upgrade still shortens every window and a Lantern Glare stays the "
         "slowest to come back. One home for the base, one for the scaling.",
     measured="sim/: heist.rs ward resets"),
dict(id="C31", kind="contradiction", severity="minor", status="open",
     title="Patrols that “shift slightly each run” against “nothing here is "
           "random”",
     refs=["12.12", "12.17"],
     body="§12.12: “guards’ patrols shift slightly each run”. §12.17: "
          "“nothing here is random: a player who scouts an island can predict "
          "exactly what will happen.” Both can hold only if the shift is drawn "
          "once, from the heist’s seed, when it starts, and is what a scout "
          "then sees. Read the other way — varying during a run — a scout "
          "cannot predict it and §12.17’s promise is false.",
     rec="Say the shift is drawn once at the start of a heist, from its "
         "seed. That is also the only form the server can re-simulate "
         "(§24.10).",
     measured=""),
dict(id="F31", kind="finding", severity="significant", status="proposed",
     title="One rule-sheet parameter for four different rules: who heals, who "
           "is hurt, and when",
     refs=["12.21", "7.3", "13.3"],
     body="§12.21: “every tier effect of every law must be expressible as a "
          "change to a named parameter.” Four laws meet that to the letter and "
          "not in substance, because the parameter they set does not say whom "
          "it changes:<br><br><code>Kinship &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "health_regen 1.5%/s &nbsp;characters next to an ally<br>"
          "Regrowth &nbsp;&nbsp;&nbsp;&nbsp;health_regen 2%/s &nbsp;&nbsp;"
          "buildings, wards and guards<br>"
          "Thorns &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;health_drain 5% &nbsp;"
          "&nbsp;&nbsp;&nbsp;per touch of a wall or hedge<br>"
          "Soul lanterns health_drain 1%/s &nbsp;&nbsp;everyone outside "
          "lantern light</code><br><br>Two numbers with one name, each meaning "
          "two rules. A simulation reading the sheet cannot apply either "
          "without knowing which law set it — which is a law containing a "
          "special case, the thing §7.3 rules out.<br><br>It has already "
          "cost a measurement. The harness decides which side a law helps from "
          "its parameters, and scores <code>health_regen</code> for the "
          "defender because “Regrowth heals guards too”. Kinship inherits "
          "that score, though what it heals is whoever stands beside an ally "
          "— most often a crew that moves together. F11’s “5 of the 19 "
          "laws help the defender” counts it on the strength of a sentence "
          "about a different law.<br><br>Found while building the law engine "
          "in <code>sim/</code>, which reads 13 of the sheet’s 20 "
          "parameters and cannot honestly read these two.",
     rec="Split each into parameters whose names carry their subject: "
         "<code>ally_regen</code> (Kinship), <code>structure_regen</code> "
         "(Regrowth), <code>touch_damage</code> (Thorns) and "
         "<code>unlit_drain</code> (Soul lanterns). The vocabulary grows by two, "
         "and each new name is a rule rather than a law, so it stays a "
         "vocabulary. Then re-score Kinship for the generator, which moves "
         "F11’s count."
         "<br><br><strong>Split in this repository.</strong> "
         "<code>tools/law_effects.py</code> now carries <code>ally_regen</code>, "
         "<code>structure_regen</code>, <code>touch_damage</code> and "
         "<code>unlit_drain</code>, same values and classifications, so F10’s "
         "counts do not move. The harness scores Kinship as cutting both ways, "
         "and F11’s count is <strong>4 of 19</strong> — exact, not sampled; the "
         "drafted §13.3 edit and T0.6 say so. <code>sim/</code> applies Kinship "
         "and Regrowth once a second. The document’s §12.21 still needs G10’s "
         "edit.<br><br><strong>Measured, against the D55 harness with and without "
         "the split:</strong> the sign-aware generator by realm holds 12 → 10%, "
         "20 → 18%, 48 → 45%, 35 → 45%, 58 → 55% — no longer weaving Kinship "
         "as a defender’s law puts realms 3 and 4 inside §13.2’s band, where "
         "before only realm 4 was. The ablation’s shares and F21’s polarisation "
         "move within noise. The generator sweep finds 4 of 10 realm/depth "
         "combinations with a setting inside both bands, up from 3 — realm 3 "
         "with two realms crossed reaches 31.8% ±2.3, one standard error in — "
         "and the ward budget confirms every need F26 records.",
     measured="sim/: laws_table.rs; tools/heist_harness/laws.py _helps_defender"),
dict(id="D55", kind="deviation", severity="significant", status="done",
     title="The Python harness and the content file read peripheral vision "
           "differently",
     refs=["12.17"],
     body="§12.17 says only “weak peripheral awareness”. The content file, from "
          "<code>spec/detection.md</code>, reads it as the zone’s rate "
          "halved: 33 a tick at near distance. The harness’s "
          "<code>detect.zone</code> returns the far zone’s rate at any "
          "distance: 12. Every harness measurement that involves a guard "
          "glimpsing a crew out of the corner of its eye — F9, F15, F16, F21, "
          "F26, F27 — was taken with the second reading.<br><br>Found while "
          "checking <code>sim/</code> against the content file, which it "
          "follows. The two implementations also disagree on crouched speed "
          "(G13).",
     rec="Align the harness with the content file and re-run the findings it "
         "carries, or record why the harness should keep its own reading. "
         "Either way one reading, not two."
         "<br><br><strong>Done.</strong> <code>detect.zone</code> now answers the zone by distance inside the corner of the eye and <code>fill_rate</code> halves it, with the factor read from the content file. Every harness-pinned finding was measured twice — the harness before and after, same seeds, same sample sizes, in separate worktrees — and <strong>one number changed a claim</strong>: realm 1 needs twice §10.2’s ladder slope to reach the band, not five times (F27, corrected in place). Its conclusion holds. F9, F11, F15, F16, F20 and F21 moved within sampling noise and every verdict held. F19 is not re-measured, because no report runs its two crews; F22 and F26 have since been re-measured on the generator sweep and the ward budget and hold. Harness fingerprint 496955db → ef4163da.",
     measured="harness ef4163da978cc0f0"),
dict(id="D53", kind="contradiction", severity="significant", status="open",
     title="§13.4 names §5.2 as the home of the law slots and then "
           "gives different ones",
     refs=["13.4", "5.2", "31.2", "32.3"],
     body="v3.2 added a limits table to §13.4 — what a realm may hold "
          "at each level — and wrote the contradiction into the section "
          "itself:"
          "<br><br><em>“Law slots do not yet agree — 5.2 gives "
          "1/1/2/2/3 across realm levels 1 to 5 and the table below gives "
          "1/3/5, and <strong>5.2 is the home</strong>.”</em>"
          "<br><br>Read off both tables: wards agree at 4, 6 and 8, guard "
          "posts agree at 1, 2 and 3, and <strong>law slots differ at realms "
          "3 and 5</strong> — two against three, and three against five. "
          "The agreement of the other two columns is what makes this a "
          "disagreement rather than two tables written to different purposes."
          "<br><br><strong>It is the honest form of the fault and it is still "
          "the fault.</strong> Naming which table is the home is §31.2 "
          "done properly, and better than every other instance this register "
          "records, because a reader who hits the contradiction is told how "
          "to resolve it. Leaving the other table wrong is §32.3's "
          "category — decided, not applied — appearing inside a "
          "table rather than in the list of four the document keeps for "
          "exactly that."
          "<br><br>It is not cosmetic. Law slots decide how many laws a realm "
          "can weave, which is what a generated defence is built from: at "
          "realm 5 the difference is three laws against five, and F11 is the "
          "finding that weaving the player's own laws makes a generated "
          "defence <em>worse</em>. Whichever number is right changes what "
          "that measurement is measuring.",
     rec="Take §5.2's, which §13.4 already says is the home: 1, 3 "
         "and 5 become 1, 2 and 3. Drafted below."
         "<br><br><code>check_document.check_realm_budgets()</code> compares "
         "the two tables column by column, so the next edit to either is "
         "checked against the other. Both parse; §13.4's rows are ragged "
         "— only the first carries the price cell — so it is read "
         "as runs of four numbers rather than by a fixed width, which is what "
         "a first attempt got wrong."),

dict(id="D51", kind="deviation", severity="minor", status="open",
     title="v3.2 invented the home marker the audit had been asking for, and "
           "one of its six points at the wrong section",
     refs=["31.2", "9.2", "9.3", "9.5", "9.6", "12.6", "7.6", "10.2"],
     body="v3.2 writes <code>(12.19 owns this rate)</code>, <code>(7.6 owns "
          "this)</code>, <code>(5.8 owns this rule)</code>. Six of them; v3.1 "
          "had none. §7.6 goes further and says it in words: "
          "<em>“This is the home of the page costs”</em>."
          "<br><br><strong>That is §31.2’s rule stated at the "
          "restatement rather than once in §31</strong>, and it is worth "
          "more than a convention, because it makes the restatement "
          "<em>checkable</em>. D47 measured what the absence costs: applied to "
          "every sentence carrying a number and a citation the rule fails on "
          "73%, and to every table cell on 36% — not findings but noise, "
          "because a citation marks one clause and nothing says which. "
          "<strong>A marker says which.</strong>"
          "<br><br><strong>Five of the six hold. One does not.</strong> "
          "§9.6 marks §9.4 as owning the sealed share and then "
          "states a slope §9.4 does not carry: <em>“rises by "
          "<strong>3.5 points a level</strong>”</em>. §9.4 gives the "
          "two ends — 40% at Vault level 1, 71.5% at level 10 — and "
          "never the step. The section that does carry it is §10.2, whose "
          "Vault ladder tabulates all ten rows at 3.5-point intervals."
          "<br><br>That is the residue of C4, which v3.2 closed: the drafted "
          "edit fixed <em>which level</em> and kept the citation pointing at "
          "§9.4. The observation that §10.2 is the only one of the "
          "four homes that tabulates the rule rather than restating it was "
          "recorded in D43 at the time and offered rather than applied. This "
          "is what it looks like a version later.",
     rec="One citation: §9.6’s marker becomes "
         "<code>(10.2 owns this)</code>, drafted below. §10.2 states the "
         "40%, the 71.5% and every step between, so the marker then points at "
         "the only section that can answer a reader who asks what the slope "
         "is."
         "<br><br><code>check_document.check_home_markers()</code> reads every "
         "marker against the section it names. The scope is the marker’s "
         "own clause, which had to be measured rather than assumed: reading "
         "the whole line reported §9.3 and §12.6 as faults, and both "
         "were the line carrying a second fact — §12.6 writes "
         "“1,500 health per Vault level; … loads at 30 a second "
         "(12.19 owns this rate)” and §12.19 owns the rate, not the "
         "health. Scoped to the clause, five pass and the sixth is real."
         "<br><br><strong>A marker is a promise, and a promise nothing checks "
         "is how §29.1 became C21.</strong> This is the check that makes "
         "it cost something — and it is the answer to F25 that F25 did "
         "not propose, because it needs the document to volunteer which "
         "sentences are single claims, and now it does."),

dict(id="D52", kind="deviation", severity="significant", status="open",
     title="v3.2 says it answers all fifty-two; twenty-two of them sit on "
           "sections it did not touch",
     refs=["32.1", "32.3", "31.9"],
     body="v3.2’s changelog: <em>“An updated audit of version 3.1 "
          "left fifty-two open items. Version 3.2 <strong>answers all "
          "fifty-two and applies most of them</strong>.”</em>"
          "<br><br><code>tools/version_diff.py</code> compares the two "
          "versions section by section. <strong>v3.2 changed 21 of "
          "v3.1’s 243 sections and added 7.</strong> Mapping the open "
          "register onto that list: 30 items cite a section that moved, and "
          "<strong>22 cite nothing that moved at all</strong> — D6, C6, "
          "C25, D13, F10, F12, F23, D31, D39, D40, D44, D47, D48, C12, C18, "
          "G3, G10, G11, D9, D17, Q3 and Q5."
          "<br><br>The claim is not false, and the distinction matters: "
          "<em>answered</em> and <em>applied</em> are different words and "
          "§32.3 is explicit about four mechanisms that are the first "
          "without the second. §32 is new, so an item answered there has "
          "its answer in a section its own refs never pointed at. What this "
          "measures is narrower and harder to argue with: <strong>for "
          "twenty-two open items, the sections the item is about still say "
          "exactly what they said.</strong>"
          "<br><br>Some of those are the largest items in the register. C6 is "
          "the eighteen abilities — §31.9 names it as deliberately "
          "left. D6 and Q5 are the launch scope cut, which §32.5 decides "
          "and D49 is about. C3, C25 and D13 are the law table, and "
          "<strong>not one row of any content table changed</strong>: the 48 "
          "laws, 18 ruleborn, 31 traits, 39 terrain features and 17 buildings "
          "re-extract byte-identical to v3.1.",
     rec="Nothing to fix in the document — this is a reading aid and a "
         "guard against the next version being taken at its word."
         "<br><br><code>python3 tools/version_diff.py --items</code> prints "
         "the worklist: which open items sit on ground that moved, and which "
         "do not. Reading twenty-one sections is a morning; reading 250 is "
         "not, and reading none and believing the changelog is how C21 to C24 "
         "survived v3.0."
         "<br><br>It cannot say a changed section <em>fixed</em> the item, "
         "and two of v3.2’s twenty-one moved for reasons unrelated to "
         "the items citing them. The output is a worklist, not a verdict. "
         "What it removes is the other 222 sections."),

dict(id="D49", kind="contradiction", severity="blocking", status="open",
     title="The scope cut is decided in §32.5 and the document still says "
           "144 forms in nine places",
     refs=["32.5", "32.3", "11.10", "26.1", "23.2", "2.6", "19.13", "21.6",
           "26.8", "30.6", "30.11"],
     body="§32.5, in the table of questions nobody has answered, records a "
          "decision: <em>“Absent it, <strong>54 ships</strong> because it "
          "is the reversible direction: forms can be added, a shipped 144 "
          "cannot be withdrawn.”</em> That is D6’s launch-scope cut "
          "and Q5’s decision, taken."
          "<br><br><strong>Nine sections still say 144.</strong> §2.6, "
          "§11.10, §19.13, §21.6, §23.2, §26.1, "
          "§26.8, §30.6 and §30.11 — and §30.8 adds "
          "“whether the 144-form collection sustains a chase” as a "
          "thing to playtest. §11.10 is the home and it derives the old "
          "number from its own rule: <em>“Eighteen kinds and eight notes "
          "make 144 forms”</em>, with a table of all eight notes beneath "
          "it. 54 is eighteen kinds by three notes, and no section says which "
          "three."
          "<br><br><strong>§32.3 is the list of decided-but-unpropagated "
          "mechanisms, and this is not on it.</strong> That section names four "
          "— rewind cut, guards and response as one layer, the guaranteed "
          "ambush, doubled cooldowns — and says <em>“these four are "
          "the largest design consequences of the research”</em>. A cut "
          "that removes <strong>90 of 144 creature forms</strong> is the "
          "largest single art number in the project and a 2.7× reduction "
          "in the collection the endgame is built on. It is recorded under an "
          "unanswered <em>question</em> instead, which is the one place a "
          "reader looking for decisions would not check."
          "<br><br>This is the defect §32.3 opens by naming: "
          "<em>“writing the conclusion in this section and letting the "
          "rest of the document go on describing the old mechanism — "
          "precisely the defect this revision exists to remove”</em>. The "
          "revision found it in four places and this is a fifth.",
     rec="Either propagate it or move it. Both are cheap and only one is "
         "correct, and which one is the owner’s call:"
         "<br><br><strong>If 54 ships</strong>, nine sections change and "
         "§11.10 needs a new rule, because 54 is not eighteen kinds by "
         "eight notes. Three notes per kind is the obvious reading and the "
         "document does not say it. <code>python3 "
         "tools/inventory_homes.py</code> prints the nine sections; "
         "<code>content/</code> needs no change, because forms are derived "
         "from the ruleborn and note tables rather than stored, so fixing "
         "§11.10’s rule fixes the count everywhere the tools read it."
         "<br><br><strong>If 54 is provisional</strong>, it belongs in "
         "§32.3’s table beside the other four, where the document "
         "already has a place for a decision it has not applied — and a "
         "check that fails while it stays there, which §32.3 says exists "
         "for the other four."
         "<br><br>D45 predicted this shape one version early, which is worth "
         "recording only because it says the check was aimed at something "
         "real: <em>“An edit made by finding §26.1’s launch "
         "table — the obvious place to look — would leave eight "
         "sections stating the old one.”</em> What happened is the same "
         "fault one step further back: the decision never reached "
         "§26.1 either."),

dict(id="D50", kind="deviation", severity="minor", status="open",
     title="v3.2’s two new meta-sections reintroduce the two things its "
           "own conventions exist to stop",
     refs=["31.5", "32.5", "26.9", "31.2"],
     body="Both are small, and both are the document’s own rules failing "
          "in the sections written to explain those rules."
          "<br><br><strong>1. §31.5 quotes a retired model without the "
          "marker it invented for quoting retired models.</strong> Its new "
          "<em>“What it would have caught”</em> column says: "
          "<em>“F24 — the retired three-rank costs restated as "
          "‘<strong>15 pages for a common law, 30 for a rare "
          "one</strong>’, which the phrase ban could not see”</em>. "
          "That sentence is the defect, in normative text. The document "
          "already has a convention for this — the rename tables are "
          "wrapped in <code>&lt;!--allow-retired--&gt;</code> so a checker "
          "reads them as quotation — and this column is not. The derived "
          "page-cost check read it as a live price claim, which is correct "
          "behaviour: it cannot tell a quotation from a claim, and that is "
          "exactly why the marker exists."
          "<br><br><strong>2. §32.5 calls the Island Fund “the "
          "creator fund”.</strong> §26.9 records the rename — "
          "<em>“the Creator Fund became the Island Fund”</em> "
          "— and both rename tables are correctly marked. §32.5 "
          "then writes <em>“The creator fund therefore ships with a "
          "stated review date”</em>, which is this project’s fund "
          "under its retired name, lower-cased. The earlier clause in the same "
          "sentence — <em>“criteria by which comparable programmes "
          "decide to continue a creator fund”</em> — is generic "
          "industry usage and defensible; the second is not."
          "<br><br>D38 is why the second one is visible at all: v3.1’s own "
          "ban counts <code>“Creator Fund”</code> case-sensitively, "
          "and prose lower-cases a proper noun the moment it stops being one. "
          "A case-sensitive ban would have reported this green.",
     rec="Two edits, drafted below: wrap §31.5’s quoting column in "
         "the marker the document already uses, and give §32.5 the "
         "current name."
         "<br><br>Until the first is made, <code>check_document.Doc</code> "
         "excludes that column from normative text by its "
         "<code>data-label</code>, with the reason recorded beside it. That is "
         "a workaround in the right direction — the column <em>is</em> "
         "quotation — but it is the checker knowing a fact about the "
         "document’s prose that the document should be stating itself, "
         "which is the thing §31.4 is against."),

dict(id="D48", kind="gap", severity="significant", status="open",
     title="§23.2 tells a designer to draw a co-op lobby, for a mode that "
           "ships in 1.1 in the form §30.8 rejected",
     refs=["23.2", "26.1", "12.11", "30.5", "30.8"],
     body="§23.2 <em>Every screen to design</em> is the frontend’s "
          "brief: 27 screens, each with its job and what it must show. Taking "
          "it seriously as a specification means asking, of all "
          "<strong>129 must-show items</strong>, whether the document "
          "specifies each one. One does not survive."
          "<br><br><strong>The Friends screen must show a “co-op "
          "lobby”.</strong> §26.1 puts co-op heists under "
          "<em>after launch</em>. §12.11 says “Co-op heists "
          "(version 1.1)” and §27.2 says “friendly heists, "
          "sharing and the Island Workshop at launch; co-op heists in version "
          "1.1”. Of §26.1’s four after-launch modes — "
          "co-op heists, epochs, watching live, Law Clash — <strong>this "
          "is the only one with a screen in §23.2</strong>. The other "
          "three appear nowhere in it, which is the evidence that §23.2 "
          "is a launch list and this row is the exception rather than the rule."
          "<br><br><strong>And a lobby is the wrong object anyway.</strong> "
          "§30.8’s decision table rejects “real-time co-op as "
          "scoped” — <em>“full netcode cost for a mode outside "
          "the core loop”</em> — and decides "
          "<em>“asynchronous co-op first; real-time only if playtests "
          "demand it”</em>. §12.11 carries that: “asynchronous "
          "first: the first version is turn-based”. A lobby is where "
          "players gather at the same moment. An asynchronous turn-based mode "
          "has an invitation and a queue, and no lobby at all. <strong>The "
          "screen list still carries a control from the design the review "
          "threw out.</strong>"
          "<br><br>§23.2 was updated for §30.8’s other "
          "interface-visible decisions, which is what makes this one a miss "
          "rather than an oversight of the whole table: free chat for minors "
          "became “chat (preset for 13 to 15)”, teaching the 44 "
          "resonances became “discovered resonances”, and "
          "virtual-currency obfuscation became “Sets with real "
          "prices”. Three of four followed. This is the fourth.",
     rec="Two words. The Friends row becomes “Friends’ feed, "
         "friendly heists, invitations, gifts”, and the co-op screen is "
         "listed under 1.1 with the rest of the mode — as an "
         "<em>invitation and turn queue</em>, not a lobby, so the screen the "
         "designer eventually draws matches the mode that will exist. Drafted "
         "below."
         "<br><br><strong>The other 128 items are specified, and two of them "
         "nearly were not.</strong> A scan for must-show terms the document "
         "never uses elsewhere reported six gaps. Reading them found four "
         "were the scan’s fault, and two are worth recording because "
         "they are F24’s lesson in the mirror. §23.2’s Scout "
         "report must show <strong>matchups</strong>, a word that appears "
         "nowhere else — but §11.5 specifies it under another name: "
         "<em>“each resists exactly one law family, so crew choice "
         "against a scouted island is a real decision (12.4)”</em>, and "
         "<code>ruleborn.json</code> carries a <code>resists</code> field for "
         "all eighteen. <strong>Spotlights</strong> read as absent because "
         "the scan looked for the plural; §18.6 specifies it."
         "<br><br>F24 is that a banned phrase can prove a phrasing absent, "
         "never a model. <strong>The mirror image is that a missing phrase "
         "proves a phrasing absent, never a gap</strong>, and it is the more "
         "dangerous of the two, because a false gap sends someone to design "
         "something that already exists. Both faults were caught by reading "
         "the hits rather than counting them, which is the only method that "
         "works on either."),

dict(id="D47", kind="deviation", severity="significant", status="open",
     title="§19.2 reports its own citation wrongly, and §30.4 "
           "corrected a rule §12.7 never stated",
     refs=["19.2", "12.7", "24.8", "21.8", "30.4", "30.8"],
     body="§19.2’s fun-variables table says what Ruleborn does about "
          "each variable and cites where it is specified. For "
          "<em>control that feels immediate</em> it says:"
          "<br><br><code>At most eight controls, <strong>44-point "
          "targets</strong>, no reflex requirements, one-finger play (12.7, "
          "24.8)</code>"
          "<br><br><strong>§12.7 says something else.</strong> "
          "<em>“Never more than eight things to tap at once, each at "
          "least 9 mm across, which is roughly 48 points, and none in a "
          "screen corner (21.8).”</em> Not 44 points, and with a corner "
          "rule §19.2 drops."
          "<br><br><strong>And §24.8 is <em>What the database "
          "holds</em></strong> — accounts, islands, snapshots, heists. It "
          "has nothing to do with controls, and it has been §24.8 since "
          "v2.3, so this is not a renumbering. The interface home is "
          "§21.8. Nothing caught it because the citation "
          "<em>resolves</em>: §24.8 exists, and a check that a reference "
          "points at a real section cannot tell that it points at the wrong "
          "one."
          "<br><br><strong>Then §30.4 reviewed it.</strong> R3 concluded "
          "<em>“a 44-point touch minimum is below the evidence. Primary "
          "heist controls should be 9 to 10 mm, and kept off screen "
          "corners”</em>, and §30.8 lists it among the decisions the "
          "evidence says are wrong. But §12.7 <em>already said</em> 9 mm "
          "and already said corners. The review corrected a rule the "
          "document’s home never held — and did not reach "
          "§19.2, the one section that holds it. Both sentences have "
          "stood unchanged since v2.3, through three versions and six "
          "reviews.",
     rec="One replacement, drafted below: §19.2’s cell states "
         "§12.7’s own rule and cites §12.7 and §21.8."
         "<br><br><code>check_document.check_evidence_cells()</code> applies "
         "D43’s rule to the other table with §29.1’s shape: a "
         "cell that is one claim plus the section it came from, so a number "
         "in it that the cited section does not carry is a restatement that "
         "has drifted."
         "<br><br><strong>It does not generalise further, and that was "
         "measured rather than assumed.</strong> Applied to every sentence in "
         "the document carrying a number and a citation the rule fails on "
         "<strong>73%</strong>; applied to every table cell, on "
         "<strong>36%</strong>. Those are false-positive rates, not findings. "
         "In prose a citation marks one clause and the sentence’s other "
         "numbers belong to other clauses — §21.1’s "
         "“a closer follow camera at 50° pitch showing about 12 "
         "tiles across (12.6)” cites §12.6 for the tiles, not the "
         "pitch. Only where a cell <em>is</em> one claim does the citation "
         "cover everything in it. That is §29.1 and §19’s four "
         "evidence tables, and the list is written out rather than detected, "
         "because detecting “is this cell one claim?” is the part "
         "that cannot be done by pattern."
         "<br><br>Worth recording as a negative result in its own right: the "
         "obvious generalisation of a check that works is usually a check "
         "that reports noise, and the way to find out is to run it and count "
         "before shipping it."),

dict(id="D46", kind="deviation", severity="blocking", status="done",
     title="Four sections were read as fragments of each other, and every "
           "scan over them reported nothing",
     refs=["31.2", "12.6", "12.19", "13.2", "13.4"],
     body="Every tool here that needs the document by section built its own "
          "index by splitting on lines that look like a heading: "
          "<code>re.split(r\"\\n(?=\\d+\\.\\d+ )\")</code>. A section that "
          "revises another opens by naming it, at the start of a line. "
          "\u00a712.19 \u2014 the section v3.0 added to fix the loading phase "
          "\u2014 begins:"
          "<br><br><code>12.6 called the loading phase the heist\u2019s central "
          "decision, and its own numbers gave that decision two seconds and "
          "one option. Both are fixed here.</code>"
          "<br><br>So the split does two things at once. It <strong>cuts "
          "\u00a712.19 off at its first paragraph</strong>, leaving 42 "
          "characters where there are 1,002, and it <strong>replaces the real "
          "\u00a712.6</strong> with the remainder. \u00a713.4 and \u00a713.2 "
          "are the same pair for the same reason: \u00a713.4 opens "
          "\u201c13.2 sets targets for how much each layer should "
          "contribute\u201d."
          "<br><br><strong>Four sections, two truncated to their heading and "
          "two replaced</strong> \u2014 and they are not arbitrary. The "
          "sections this breaks are exactly the ones the document has already "
          "had to fix once, because fixing one is what makes another open by "
          "naming it."
          "<br><br><strong>What was lost.</strong> \u00a712.6 is 1,912 "
          "characters and the tools were reading 958 characters of "
          "\u00a712.19. The real \u00a712.6 owns the decision cadence "
          "\u2014 <em>\u201cone every 8 to 12 seconds, or 15 to 25 in a "
          "run\u201d</em>, restated in \u00a719.16, \u00a719.27, "
          "\u00a724.13 and \u00a726.2 \u2014 the Vault\u2019s 1,500 health "
          "per level, the 150-loot-a-second load rate that <em>is</em> C22, "
          "and the skiff timings. <code>twice_stated.py</code> exists to find "
          "facts with two homes and had never read the section that has the "
          "most of them."
          "<br><br><strong>It reported nothing, which is the whole "
          "problem.</strong> A section that shrinks to a fragment produces no "
          "error, no empty result and no warning: the scan runs, finds fewer "
          "pairs, and prints a clean list. This is D41\u2019s unbounded law "
          "sheet and D42\u2019s creature block again, in the code that reads "
          "the document rather than the code that extracts it \u2014 the "
          "third time this session that a check lost its subject and read "
          "exactly like a check that passes."
          "<br><br>Fixing it surfaced a restatement immediately: \u00a712.6 "
          "and \u00a75.4 both give the skiff\u2019s flight times, 5 seconds "
          "to an outer realm and 20 to the Heart. They agree \u2014 and had "
          "been invisible.",
     rec="One index, in one place. "
         "<code>check_document.section_spans()</code> is now the only one, and "
         "<code>section_index</code>, <code>section_at</code>, "
         "<code>twice_stated</code> and <code>inventory_homes</code> all read "
         "it. Three private copies are gone, which is \u00a731.2 applied to "
         "the tools rather than to the document."
         "<br><br><strong>The rule that fixes it is one the document already "
         "guarantees and the build already checks: section numbers "
         "ascend.</strong> A line-start number lower than the last heading is "
         "a reference, not a heading. It rejects exactly the two false "
         "headings and keeps 243 real ones."
         "<br><br><code>check_section_index()</code> compares that 243 against "
         "the count of <code>&lt;h3&gt;</code> headings in the HTML \u2014 a "
         "different route to the same number, which is the only evidence here "
         "that either is right \u2014 and names \u00a712.6 and \u00a713.2 "
         "by their titles, so the specific regression cannot come back "
         "quietly. The self-test runs the old method beside the new one on the "
         "committed document and prints the four disagreements, because a bug "
         "that raised nothing leaves no other evidence."
         "<br><br>D43\u2019s formula-appendix check used the broken index too. "
         "It happened to be unaffected \u2014 no \u00a729.1 row cites any of "
         "the four \u2014 which is worth stating plainly: it was correct by "
         "luck, and is now correct by construction."
         "<br><br>The first account of this item said two sections and named "
         "\u00a731\u2019s change log as the source. Both were wrong, and the "
         "self-test is what said so: it was written to assert the two, and "
         "reported four."),

dict(id="D45", kind="deviation", severity="significant", status="done",
     title="The launch inventory has fifteen homes for one number, and three "
           "of thirteen rows were checked",
     refs=["26.1", "23.2", "19.13", "26.8", "27.2", "30.6", "30.8", "30.11",
           "11.10", "2.6"],
     body="§26.1 is the project’s own statement of scope — what "
          "gets built, counted. Thirteen rows, and <strong>three were "
          "checked</strong>: laws, ruleborn and building types. Two of the "
          "register’s closed items are rows of that same table: C24 was "
          "<em>Building types</em>, which said 16 against a table of 17, and "
          "C10 was <em>Traits</em>, which said 30 against a table of 31. Both "
          "were found by reading."
          "<br><br><strong>Nine of the thirteen rows can be counted from "
          "<code>content/</code></strong>, which is extracted from the "
          "document and checked back against it, so the comparison is the "
          "document against itself. The four that cannot are named rather "
          "than dropped: realms, paradoxes, the three visitor kinds, and "
          "modes, which is a list of names."
          "<br><br><strong>And §26.1 is not where the numbers live.</strong> "
          "Counted across the built document:"
          "<br><code>laws = 48 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;15 homes<br>"
          "forms = 144 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;9 homes<br>"
          "resonances = 44 &nbsp;&nbsp;4 homes<br>"
          "chords = 12 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;4 homes<br>"
          "terrain = 39 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;4 homes<br>"
          "traits, Sages, eras &nbsp;1 home each</code>"
          "<br><br>Every one of them agrees today, which is why nobody has "
          "looked. That is F25’s whole argument: a fact with two homes is "
          "found by reading only <em>after</em> it has diverged, and these "
          "have not yet."
          "<br><br><strong>It matters now, not later.</strong> D6 proposes "
          "cutting the forms from 144 to 54 and Q5 is the decision under it. "
          "That number has nine homes. An edit made by finding §26.1’s "
          "launch table — the obvious place to look — would leave "
          "eight sections stating the old one, including §23.2, which is "
          "what tells a designer how many forms to draw.",
     rec="Four checks and a report, all deriving rather than recognising."
          "<br><br><code>check_launch_inventory</code> reads every countable "
          "row of §26.1 against its table and names the four it cannot. "
          "<code>check_screen_counts</code> reads §23.2’s must-show "
          "cells, where <em>must show</em> means all of them, so every count "
          "there is a total. <code>check_inventory_summaries</code> takes the "
          "structural rule that <strong>a line naming two or more kinds at "
          "once is summarising the inventory</strong> — a partial claim "
          "is about one kind — with §14.2 and §26.2 named as "
          "staged rather than total."
          "<br><br><strong>The fourth is the one that took a reading.</strong> "
          "Those three left sixteen sections stating a total that nothing "
          "read, and the reason was that a bare “12 laws” is "
          "§7.6’s Codex opening in chapters, not a stale 48. So "
          "<code>tools/inventory_homes.py</code> printed every mention in the "
          "document and they were read one at a time: <strong>there are "
          "thirteen partials in the whole document</strong>, and with those "
          "declared the strong rule holds — every number beside a "
          "content table’s own noun is that table’s length or a "
          "named partial. Two of the thirteen were only visible once the "
          "strong rule ran, because §14.2 and §14.3 state the total "
          "<em>and</em> the milestones, so a per-section rule had counted "
          "them clean."
          "<br><br>The price is that a genuine new partial fails the build "
          "until it is named. That is intended: a partial and a stale total "
          "are the same shape, and the difference is a reading."
          "<br><br>The self-test does D6’s cut to §26.1 alone and "
          "shows the other eight homes still saying 144 — the plant "
          "derived from <code>content/</code>, so if the forms are ever "
          "really cut the test moves with them instead of testing a number "
          "nobody has checked since."
          "<br><br>This answers the structural half of F25 for this class, "
          "and not the way F25 proposed. F25 asks for "
          "<code>constants.json</code> to list every twice-homed fact; an "
          "inventory count needs no entry, because <strong>the table is the "
          "home</strong> and its length is the fact. Declaration is for the "
          "constants a table cannot supply."),

dict(id="D43", kind="deviation", severity="significant", status="open",
     title="Twenty formulas name their own source, and four name a section "
           "that does not carry them",
     refs=["29.1", "9.4", "9.6", "10.2", "7.6", "12.17"],
     body="§29.1 is the one table in the document that cites itself: a "
          "third column giving the section each formula was copied from. That "
          "column is what makes the appendix checkable, and C21 is what makes "
          "it worth checking — a row that had outlived the section it "
          "cited, <em>citing the very section that deleted it</em>. C21 was "
          "fixed by deleting the row. Nothing was built that would find the "
          "next one."
          "<br><br><strong>Four of the twenty rows fail the weakest possible "
          "test — every number in a formula must appear in the section "
          "the formula says it came from — and they fail it in four "
          "different ways, only one of which is dangerous today.</strong>"
          "<br><br><strong>1. The fact was deleted from its home and left in "
          "the index.</strong> <em>Heist take</em> still prices a raid at "
          "“up to 25% of the Vault’s exposed amount and 50% of each "
          "Storehouse passed” and gives §9.4 as its source. "
          "§9.4 now reads: <em>“The percentages this paragraph used "
          "to carry are gone: they described a world where the loot left the "
          "defender, and it does not.”</em> The real home is §9.6’s "
          "minted haul, which the row does not mention. <strong>This is C21 "
          "repeating, in the same table, and it is C2’s fix seen from the "
          "other side</strong> — the edit removed the fact from its home "
          "and the index still points at the home to prove it."
          "<br><br><strong>2. A right formula with a wrong address.</strong> "
          "<em>Vault</em> gives <code>8,000 × 1.85<sup>level−1</sup></code> "
          "and cites §9.4, which says nothing about capacity. Its home is "
          "§10.2’s building ladder, which tabulates every level: "
          "8,000 at level 1 to 2,030,700 at level 10, and 14,800 ÷ 8,000 "
          "is 1.85 exactly. Nothing is wrong but the citation, which is "
          "precisely why it survived — a wrong address is invisible from "
          "either end."
          "<br><br><strong>3. The index is more precise than the section it "
          "indexes.</strong> <em>Suspicion</em> says the far zone fills in "
          "<strong>2.8 s</strong>. §12.17 says “just under three” "
          "and gives no figure. <code>content/detection.json</code> and the "
          "simulation carry 2.8, and 12 suspicion a tick at 30 ticks a second "
          "is 2.78, so the appendix is right and it is the only prose in the "
          "document that says so. <strong>§29.1 is normative for that one "
          "number and an index for the rest, and nothing in the table says "
          "which row is which.</strong>"
          "<br><br><strong>4. The home is the stale one.</strong> "
          "<em>Restoring a law</em> cites §7.6, which still prices laws "
          "in three ranks. That is C23, reached from the other end: two "
          "independent checks now fail on that one sentence."

          "<br><br>Reading the four rows against their homes turned up a fifth "
          "fault the check itself cannot see, because it is a word rather than a "
          "number: §9.6 keys the Vault’s sealed share to <em>realm</em> "
          "level and then runs it “to 71.5% at level 10”, and realm levels "
          "stop at five. <strong>That is already C4’s drafted edit</strong> "
          "— it was written up here as a new item and withdrawn on finding it. "
          "Worth recording as a small confirmation that the drafted edits are aimed "
          "at real things, and as the reason a register is read before an item is "
          "added.",
     rec="The check is built and the edits are drafted below. "
         "<code>check_document.check_formula_appendix()</code> applies the "
         "weakest rule that would have caught C21, and it cannot tell a right "
         "formula from a wrong one — only an index entry from an orphan. "
         "That turns out to be enough, because all four faults are faults of "
         "address rather than of arithmetic."
         "<br><br>The digits-to-words table (“half a second” for 0.5) "
         "is a translation, not a loosener: every entry was read in both "
         "places before it was added, and anything outside it is reported."
         "<br><br>One refinement to C4’s drafted edit, offered rather than "
         "applied: it keeps the citation “(9.4)”, and §10.2 is the "
         "only one of that rule’s four homes that tabulates it level by level "
         "instead of restating it. §9.4, §9.6 and §29.1 could all "
         "cite §10.2 and stop carrying the numbers."
         "<br><br>D15’s generated appendix would make all four impossible "
         "rather than merely caught, and <code>tools/generate_docs.py</code> "
         "already emits one. Until the build adopts it, this check is what "
         "stands between §29.1 and the next C21."),

dict(id="D44", kind="deviation", severity="minor", status="proposed",
     title="Eleven surviving restatements, read one at a time: three small "
           "faults, four honest second homes and one left live",
     refs=["31.2", "5.4", "12.5", "19.2", "19.11", "2.7", "25.1", "5.1", "7.1"],
     body="<code>tools/twice_stated.py</code> found 89 restated sentences and "
          "exempted 77 with reasons, leaving twelve in eleven section pairs "
          "that nothing had examined. Each was read against its two sections. "
          "The residue is the point: an unexamined list is a list nobody is "
          "responsible for."
          "<br><br><strong>Three are faults.</strong>"
          "<br><br>• <strong>The heist clock has three homes and only one "
          "of them knows about Haste.</strong> §5.4, §12.5 and "
          "§29.1 all give “150 s + 15 s per link, up to 240 s”. "
          "Only §12.5 adds <em>“Haste makes the clock run 25% faster "
          "while the crew is in its realm”</em>. A player pricing a route "
          "from §5.4 or from the appendix is wrong by a quarter in any "
          "realm running Haste, and both copies look complete."
          "<br><br>• <strong>Two cells cite §14.8 and have already "
          "drifted apart.</strong> §19.2: “Albums start partly "
          "filled and show what’s left (14.8)”. §19.11: "
          "“Albums <em>and tracks</em> start partly filled and show "
          "what’s left (14.8)”. §14.8 settles it — "
          "“the season track’s first tier is complete on day "
          "one” — so §19.2 is the stale one. A small drift, and "
          "the exact shape the scan was written to find: two summaries of one "
          "home, both citing it, no longer saying the same thing."
          "<br><br>• <strong>§2.7’s “plain arithmetic” "
          "rounds outward.</strong> $5.5 m a day at 30 and 15 cents is 18.3 m "
          "and 36.7 m daily players; at §25.1’s gate of a third of "
          "monthly players a day that is <strong>55 to 110 million "
          "monthly</strong>, and the paragraph says 60 to 120. Round numbers "
          "— but the passage’s whole claim is that the forecast is "
          "earned by arithmetic, and the last step is not the arithmetic. It "
          "also leans on §25.1’s gate without citing it, so moving "
          "the gate leaves the derivation stale in silence."
          "<br><br><strong>Four are honest second homes, now exempt with "
          "reasons rather than left live.</strong> §28.3 is the sources "
          "list, where an annotated entry states what its source found and the "
          "body cites it by number. §19.8 is “claims we don’t "
          "rely on”, and naming a rejected claim requires stating what "
          "replaces it. The two §19 evidence tables summarise a rule in "
          "an “In Ruleborn” column and cite its home in the same "
          "cell — <em>which C21 proves is not safety</em>, only "
          "checkability, and the albums drift above is what it looks like when "
          "nobody checks."
          "<br><br><strong>Four were already covered and said so badly.</strong> "
          "§11.10/§18.3 is D40, §21.7/§7.7 is one of "
          "D39’s 48 movement signatures, and the two §29.1 pairs are "
          "D43, which now compares every appendix row to its cited home."
          "<br><br><strong>One stays live, and should.</strong> §5.1 and "
          "§7.1 both price the economy of a law — “a crown law "
          "adds 5% to its school’s resource in every realm; a realm law "
          "adds 10% in its own” against “a realm law adds 10% to its "
          "school’s resource in its realm; a crown law adds 5% "
          "everywhere” — the same rule with the clauses reversed, "
          "agreeing today and guarded by nothing. It is the only row on the "
          "list that is neither a register item nor an exemption, which is "
          "what a curated list is for: <strong>one pair left, and it is a real "
          "one.</strong>",
     rec="The three faults are one-line edits, drafted below. The clock keeps "
         "its home in §5.4 and gains the Haste clause, because how a "
         "clock runs belongs with the clock; §12.5’s copy becomes a "
         "citation. §19.2 gains “and tracks”. §2.7 states "
         "55 to 110 million and names the gate it divides by."
         "<br><br>The exemptions live in <code>twice_stated.py</code> with the "
         "reason beside each, in the same form as the logs. The scan’s "
         "live list is now curated: every row on it is a register item, an "
         "exemption with a reason, or a fault awaiting an edit — so a new "
         "row appearing means something new was written twice."),

dict(id="D42", kind="deviation", severity="significant", status="done",
     title="The guard written for D41 found the same bug in a second "
           "extractor, on its first run",
     refs=["31.2", "31.4", "11.7", "11.11"],
     body="D41 was a law sheet whose block ran to the end of the document, so "
          "a column heading from \u00a721.7 landed in \u00a77.7\u2019s content. "
          "The fix was one line of bounding; the interesting question was what "
          "else that shape had done."
          "<br><br><strong>A general guard for it: every extracted value has "
          "to be inside the section it was read from.</strong> That is "
          "independent of how the extractor pairs cells, which is the part "
          "that keeps going wrong \u2014 <code>fields()</code> and "
          "<code>table()</code> both zip by position, so one stray cell shifts "
          "every row after it, and a shifted value almost always comes from "
          "outside its own section."
          "<br><br><strong>It found a second one immediately.</strong> "
          "<code>content/ruleborn.json</code> gave Soulmender a look of "
          "<strong><code>\u201cThe Archivist\u201d</code></strong> \u2014 a "
          "Sage\u2019s name from \u00a711.7. \u00a711.11 says <em>\u201cHooded "
          "moth-like spirit\u201d</em>. Same cause exactly: Soulmender is the "
          "eighteenth and last creature in the bible, its block was unbounded, "
          "and a later <code>| Look</code> pair overwrote it."
          "<br><br>Two extractors, the same last-block bug, one field wrong in "
          "each. Both files are read by every tool in this repository and both "
          "were wrong for as long as the extraction has existed."
          "<br><br><strong>The two guards catch different things, which is why "
          "there are two.</strong> D41\u2019s bad value was the label "
          "<em>\u201cHow characters move\u201d</em>, which <em>is</em> inside "
          "\u00a77.7 \u2014 provenance would have passed it, and the "
          "label check catches it. D42\u2019s was a sentence from another "
          "section \u2014 the label check passes it, and provenance catches "
          "it. Neither is the whole net.",
     rec="Fixed. Both extractors bound their last block at the next section "
         "heading, and re-extracting changes exactly one field in each: Mirror "
         "images\u2019 world signature and Soulmender\u2019s look, both to what "
         "the document says."
         "<br><br><code>validate_content.check_provenance()</code> declares "
         "where each of the twelve content files is read from and refuses a "
         "value that is not there. Two kinds of exception are named rather "
         "than filtered: the keys this repository <em>adds</em> to the "
         "document\u2019s content \u2014 which register item a row waits on, "
         "what the document does not state about it \u2014 and the files with "
         "two sources, which are <code>ruleborn.json</code> "
         "(\u00a711.11\u2019s bible plus the columns \u00a711.2 adds) and "
         "<code>buildings.json</code>, where the Library is in \u00a710.4 "
         "instead of \u00a710.2 and being outside \u00a710.2 is C8."
         "<br><br>Ten of the twelve files came back clean on the first run, "
         "which is the useful half of the result: the extraction is sound "
         "apart from a bug that only ever bites the last row, and now there is "
         "something that would say so."),

dict(id="D41", kind="deviation", severity="significant", status="done",
     title="One law sheet\u2019s block ran to the end of the document, and a "
           "field label became a field value",
     refs=["31.2", "31.4", "7.7", "21.7"],
     body="<code>content/laws.json</code> gave Mirror images a world signature "
          "of <strong><code>\u201cHow characters move\u201d</code></strong> "
          "\u2014 a column heading, sitting where a sentence belongs, in the "
          "content file every tool in this repository reads."
          "<br><br><strong>The cause.</strong> "
          "<code>extract_content.fields()</code> pairs a table\u2019s cells by "
          "position, and <code>extract_laws</code> bounded each sheet at the "
          "next sheet \u2014 with the last one running to the end of the "
          "document. Mirror images is the last of the 48. Its block was "
          "<strong>10,616 lines instead of 28</strong>, so every table in "
          "\u00a77.8 onward was re-paired into it and the last cell following "
          "a matching label won. \u00a721.7\u2019s column header <em>\u201cHow "
          "the realm looks\u201d</em> is one of those labels, and the cell "
          "after it is <em>\u201cHow characters move\u201d</em>."
          "<br><br>One field of one law of forty-eight. The other seven "
          "survived by luck rather than by design: any table after \u00a77.8 "
          "containing a cell equal to one of the eight labels would have "
          "overwritten its field too."
          "<br><br><strong>How it surfaced.</strong> Not from the content side "
          "\u2014 <code>validate_content</code> checked that every required "
          "field was present and never that a value was a value. It came from "
          "<code>twice_stated.py</code>: \u00a721.7 restates every law\u2019s "
          "look and movement, so it is a third home for facts \u00a77.7 owns "
          "(D39 found the second, \u00a77.4), and comparing the two homes is "
          "what showed one of them was a label. <strong>The argument for "
          "comparing second homes, demonstrated by a second home finding a "
          "real error.</strong>",
     rec="Fixed, three ways, because the fault had three chances to be caught "
         "and took none."
         "<br><br><strong>The bug.</strong> The last sheet is now bounded at "
         "the next section heading. Re-extracting changes exactly one field, "
         "and it changes it to what \u00a77.7 and \u00a721.7 both say."
         "<br><br><strong>The class.</strong> "
         "<code>validate_content</code> now refuses any extracted value equal "
         "to one of the labels the extractor keys on. That is cheap and "
         "general: a mis-paired table almost always leaves a heading where a "
         "sentence should be."
         "<br><br><strong>The third home.</strong> "
         "<code>check_document</code> now compares \u00a721.7\u2019s movement "
         "signature against \u00a77.7\u2019s for all 48 laws, beside "
         "D39\u2019s \u00a77.4 comparison. Between them the law content has "
         "three homes and 336 facts, and all three are now read against each "
         "other on every build \u2014 which is the weaker answer, as D39 says. "
         "\u00a77.4 and \u00a721.7 should both be generated from "
         "\u00a77.7."),

dict(id="D40", kind="deviation", severity="significant", status="open",
     title="\u201cReturns once at N%\u201d is granted by four systems at three "
           "values, and the rule sheet has no parameter for it",
     refs=["7.3", "11.2", "11.3", "11.10", "11.11", "18.3"],
     body="The same clause appears five times, from four different systems:"
          "<br><br>\u2022 <strong>\u00a711.10</strong>, the Echo law-shaped "
          "form: <em>\u201cReturns once at 20% after being knocked out\u201d</em>"
          "<br>\u2022 <strong>\u00a718.3</strong>, the Echoing Skies era: "
          "<em>\u201cEveryone returns once at 40% after being knocked "
          "out\u201d</em>"
          "<br>\u2022 <strong>\u00a711.11</strong>, Echoplate\u2019s ability: "
          "<em>\u201cShield flare, blocking one hit for the crew; returns once "
          "at 40%\u201d</em>"
          "<br>\u2022 <strong>\u00a711.2</strong>, Echoplate\u2019s passive: "
          "<em>\u201cComes back once at 50% after being knocked out\u201d</em>"
          "<br>\u2022 <strong>\u00a711.3</strong>, the Echo-touched trait: "
          "<em>\u201creturns once at 50% even without Echoes\u201d</em>"
          "<br><br><strong>Three values for one mechanic, and two of them are "
          "the same creature.</strong> Echoplate returns at 40% in "
          "\u00a711.11 and 50% in \u00a711.2, which is C6\u2019s "
          "contradiction reaching a field nobody had compared."
          "<br><br><strong>\u00a77.3\u2019s rule sheet has no parameter for "
          "it.</strong> The sheet is the vocabulary a law may change \u2014 "
          "speed, jumping, friction, sight, trails, damage, healing, time "
          "\u2014 and returning after a knockout is none of them. That is "
          "F10 and G10\u2019s class exactly: an effect stated in prose that "
          "the architecture has nowhere to put."
          "<br><br><strong>And \u00a77.3\u2019s combination rules do not "
          "settle it.</strong> <em>\u201cMultipliers multiply; on/off rules "
          "take the last value applied.\u201d</em> A return-at-40% is neither "
          "a multiplier nor on/off, so a character with the Echo form (20%) "
          "inside an Echoing Skies era (40%) has no stated answer \u2014 nor "
          "does the question of whether it returns once or twice. "
          "\u00a77.3\u2019s <em>\u201capply each character\u2019s own traits "
          "and immunities last\u201d</em> settles the trait against the rest "
          "and nothing else."
          "<br><br><strong>It also has two meanings.</strong> "
          "<code>tools/ability_text.py</code> read \u00a711.11\u2019s clause "
          "as a <em>reflect</em> \u2014 the shield returning 40% of the blow "
          "\u2014 and argued from there that it was damage and belonged to "
          "the Breaker. Four other uses of the identical phrase mean revive, "
          "so that reading is probably wrong, and C6\u2019s drafted pick for "
          "Echoplate has been corrected to say so.",
     rec="Decide one number and one home, then give the rule sheet the "
         "parameter."
         "<br><br><strong>One home.</strong> The revive threshold is a "
         "character property, so \u00a711.1\u2019s role table or "
         "\u00a711.11\u2019s bible is where it belongs; a form, an era and a "
         "trait then modify it rather than each restating it. That is the same "
         "fix C22 needed for the load rate."
         "<br><br><strong>One parameter.</strong> \u00a77.3\u2019s sheet "
         "needs a row \u2014 <em>returns after knockout: no / once at N%</em> "
         "\u2014 or the effect cannot be expressed as a parameter change, "
         "which \u00a712.21 forbids outright."
         "<br><br><strong>One rule for stacking.</strong> \u00a77.3 covers "
         "multipliers and on/off rules; this is a third shape and needs a "
         "sentence. The cheapest is the one the document already uses "
         "elsewhere: the highest applies, once."
         "<br><br><strong>And say which meaning \u00a711.11 intends</strong>, "
         "because \u201creturns once at 40%\u201d reads as a revive in four "
         "places and as a reflect in the fifth, and C6\u2019s pick for "
         "Echoplate turns on it."
         "<br><br>Found by <code>tools/twice_stated.py</code>, which is the "
         "method D39 came out of, now standing: every numeric sentence in the "
         "document, paired across sections by word overlap."),

dict(id="D39", kind="deviation", severity="significant", status="open",
     title="\u00a77.4 and \u00a77.7 state 240 facts twice, and they all agree "
           "\u2014 which is why nobody found them",
     refs=["31.2", "31.4", "7.4", "7.7"],
     body="\u00a77.4 <em>The 48 laws</em> gives each law\u2019s rank, stability "
          "cost, notes, tier I effect, tiers II and III, and how characters "
          "move. \u00a77.7 <em>Every law in full</em> gives all six again, word "
          "for word, and adds five more fields. <strong>\u00a77.4 is a subset of "
          "\u00a77.7</strong>, so forty-eight laws by five compared fields is "
          "<strong>240 facts with two homes</strong>, every one of them agreeing "
          "today and guarded by nothing."
          "<br><br><strong>F25 lists six twice-stated facts. It missed these "
          "because they agree.</strong> All six of F25\u2019s were found by "
          "reading for contradictions, so all six had already diverged \u2014 "
          "the rank split, the page costs, the load rate, partial staffing, the "
          "birth cost, the notes. \u00a731.2\u2019s rule is about <em>one "
          "home</em>, not about agreement, and a fact stated twice that agrees "
          "today is the next C3 rather than a fact that is fine. The load rate, "
          "the rank split and the two rosters all agreed until one copy was "
          "edited."
          "<br><br><code>extract_content.py</code> reads \u00a77.7 and its own "
          "comment calls it <em>\u201cthe richest of the three places laws "
          "appear\u201d</em> \u2014 so whoever wrote the extractor knew, chose "
          "one, and nothing compared the other two."
          "<br><br><strong>How it was found.</strong> Not by reading. The same "
          "method that found D37\u2019s eleven duplicated constants in the "
          "tooling, pointed at the document: every numeric sentence, paired "
          "across sections by word overlap. The \u00a77.4/\u00a77.7 pair came "
          "back with forty near-identical sentences, more than every other pair "
          "in the document put together. The eight other pairs it surfaced are "
          "research citations restated in \u00a730\u2019s evidence log, which is "
          "what an evidence log is for, and one small genuine one: \u00a75.1 and "
          "\u00a77.1 both price a crown law at 5% and a realm law at 10%, with "
          "the clauses in opposite order.",
     rec="<strong>\u00a77.4 should be generated from \u00a77.7, which is "
         "D15\u2019s fix applied to the largest summary table in the "
         "document.</strong> \u00a731.4\u2019s rule is already \u2018generated, "
         "not authored\u2019, and \u00a77.4 is six columns of pure summary: "
         "every one of them is in \u00a77.7 and none is anywhere else."
         "<br><br><strong>Until then the divergence is checked rather than "
         "prevented.</strong> <code>check_law_table_against_sheets</code> reads "
         "both sections out of the document and compares all 240 facts on every "
         "build, so the two cannot drift apart silently the way C3, C6 and C22 "
         "did. It reads both sides from the document on purpose: comparing "
         "\u00a77.4 against <code>content/laws.json</code> would be comparing "
         "the document against an extraction of \u00a77.7, which is one side "
         "twice \u2014 the trap D37 records."
         "<br><br>Worth saying plainly: <strong>the check is the weaker "
         "answer.</strong> It catches a divergence after someone writes it, "
         "where generating \u00a77.4 would make writing one impossible. It is "
         "here because the edit is the owner\u2019s and the guard is not."),

dict(id="D38", kind="deviation", severity="significant", status="done",
     title="\u00a731.5\u2019s fifteen breakages all pass, and six restatements "
           "of the same defects all survive",
     refs=["31.5", "31.6", "7.6", "12.17", "24.10"],
     body="\u00a731.5 makes a checkable claim about v3.1\u2019s own gate: "
          "<em>\u201cFifteen checks, and fifteen deliberate breakages that "
          "each one must catch.\u201d</em> Nobody here had ever run it. The "
          "vendor README keeps <code>tools/vendor/</code> unmodified so the "
          "claim can be re-run rather than believed, and "
          "<code>tools/mutation_gate.py</code> now re-runs it against v3.1 "
          "rather than the v3.0 paths it shipped with."
          "<br><br><strong>It passes. All fifteen.</strong> The shipped gate "
          "has real teeth against the defects it names, and that is now "
          "re-checked on every build rather than taken on trust."
          "<br><br><strong>Then the same six defects, said in other "
          "words.</strong> Not wordings invented to dodge a regular expression "
          "\u2014 the wording a writer would actually reach for:"
          "<br><br>\u2022 <em>\u201cThe guard investigates at 50% and raises "
          "the alarm at 100%\u201d</em> \u2014 the retired detection model\u2019s "
          "own sentence, from \u00a729.1 before v3.1 rewrote it. The ban wants "
          "the word \u2018awareness\u2019 beside the number."
          "<br>\u2022 <em>\u201cthree commons, three rares and two deeps\u201d</em> "
          "\u2014 the plural. The ban lists three phrasings, all singular."
          "<br>\u2022 <em>\u201cThe lawbound era is over\u201d</em> \u2014 a "
          "retired name in lower case, which <code>count(\u201cLawbound\u201d)</code> "
          "cannot see. Prose lower-cases a proper noun the moment it becomes "
          "an adjective."
          "<br>\u2022 <em>\u201cThe simulation advances 20 steps a "
          "second\u201d</em> \u2014 C7 reintroduced. The constant is found by "
          "<code>fixed (\\d+) steps a second</code>, so a second value without "
          "the word \u2018fixed\u2019 is compared against nothing."
          "<br>\u2022 <em>\u201ca single 120-degree cone\u201d</em> \u2014 the "
          "ban is the literal string with the degree sign."
          "<br>\u2022 <em>\u201c15 pages for a common law, 30 for a rare "
          "one\u2026\u201d</em> \u2014 F24\u2019s own example, and the sentence "
          "\u00a77.6 still contains."
          "<br><br><strong>The shipped gate catches none of the six. This "
          "repository\u2019s catches two</strong> \u2014 and the two are "
          "exactly the bans that have already been replaced with a check "
          "derived from the document\u2019s own tables: the page costs (F24) "
          "and the detection model. The other four are still phrase bans in "
          "both checkers."
          "<br><br>So a mutation suite measures a check against the defect it "
          "was written for, and nothing else. <strong>Fifteen of fifteen and "
          "zero of six are the same gate on the same day.</strong>",
     rec="<strong>Done \u2014 all four are derived, and the restatement suite "
         "now catches six of six.</strong>"
         "<br><br><strong>Retired names</strong> are read case-insensitively "
         "with word boundaries and an optional plural or possessive; the "
         "rename tables stay exempt, because quoting a retired name to say it "
         "is retired is the one place it belongs."
         "<br><br><strong>The constants</strong> are read by their <em>unit</em> "
         "rather than by the one sentence that defines them. "
         "<code>constants.json</code>\u2019s declared pattern finds the home; "
         "<code>CONSTANT_UNITS</code> finds every other mention, which is "
         "where a second value hides. That is exactly how "
         "<code>check_page_economy</code> reads page prices, applied to the "
         "other four."
         "<br><br><strong>The three-rank scheme</strong> is a number per rank "
         "and the 48 sheets state it, so a sentence saying what each school "
         "has is compared against 3/2/1/2 rather than matched against a list "
         "of phrasings."
         "<br><br><strong>The single cone</strong> is any sentence asserting "
         "one, which is not the same as a sentence saying the model is gone "
         "\u2014 \u00a712.8 says <em>\u201cthe older single-cone\u2026 rules "
         "are gone\u201d</em> and \u00a712.17 opens <em>\u201cVision is not "
         "one cone but three zones\u201d</em>, and a check that cannot tell an "
         "assertion from a burial reports the fix as the fault."
         "<br><br><strong>Two things the derivations found that the bans could "
         "not have.</strong> \u00a731\u2019s own table of what went wrong "
         "quotes C7 \u2014 <em>\u201cThe simulation ran at 20 steps a second "
         "in 7.3\u201d</em> \u2014 so the constants check has to tell the "
         "document\u2019s audit history from a live second value, and does it "
         "on the past tense. And the per-school check is deliberately "
         "<em>untracked</em>: tracking it to C3 made it report a retirement, "
         "because it passes while C3 stays open on \u00a77.9\u2019s table and "
         "\u00a77.6\u2019s restore line, which it does not cover."
         "<br><br><code>tools/mutation_gate.py</code> pins six of six, so the "
         "next ban to weaken says so."),



dict(id="D37", kind="deviation", severity="change", status="done",
     title="\u00a731.4 pins four constants in the document; eleven more were "
           "written down two to four times in the tools",
     refs=["31.2", "31.4"],
     body="\u00a731.4 pins tick rate, law count, crew size and page total in "
          "the document\u2019s own data, and the build checker verifies each "
          "against the prose. <strong>That rule stops at the document.</strong> "
          "One level out, in the tools that check it, eleven more of the "
          "document\u2019s facts were each written down two to four times."
          "<br><br><strong>Three of the sets disagreed.</strong> "
          "<code>SETTLED</code> had four homes and <code>build_roadmap</code>\u2019s "
          "was missing <code>withdrawn</code>, so a withdrawn item counted as "
          "open on the roadmap and settled everywhere else. "
          "<code>HOLD_BAND</code> had four, <code>(30, 45)</code> in one and "
          "<code>(30.0, 45.0)</code> in three. And <code>CREW</code> meant the "
          "range 3-to-5 in one tool and the number 5 in another \u2014 "
          "<strong>one name for two facts, which is worse than one fact in two "
          "places</strong>, because nothing about the name says which you have. "
          "<code>ROLES</code> was the same: a tuple of five names here and the "
          "full stats table in the harness."
          "<br><br><strong>Four of the repeats restated data already "
          "extracted.</strong> <code>content/notes.json</code> carries the "
          "eight notes and their oppositions and <code>content/roles.json</code> "
          "carries the five roles \u2014 and four tools typed out the notes "
          "again and four typed out the roles.",
     rec="Fixed. <code>tools/design_facts.py</code> derives what "
         "<code>content/</code> already holds and declares the rest with the "
         "section that owns it, and "
         "<code>check_docs_consistency.check_one_fact_home()</code> refuses a "
         "second copy. Writing the check found three more the sweep had missed, "
         "including one in a file written two days ago."
         "<br><br><strong>The exceptions are the interesting part, and they are "
         "named with reasons rather than left to be rediscovered.</strong> "
         "<code>extract_content</code> produces <code>content/*.json</code>, so "
         "it needs a vocabulary to recognise the document\u2019s tables before "
         "that content exists. <code>check_design_consistency</code> parses the "
         "document directly and needs the same bootstrap. And "
         "<code>validate_content</code> keeps its own list on purpose: it "
         "verifies the content against the document, and <code>design_facts</code> "
         "derives the notes and roles <em>from</em> that content, so importing "
         "them there would turn the check into <code>x == x</code>. <strong>A "
         "verifier that imports the thing it verifies has written a check that "
         "cannot fail</strong>, which is the fault this register exists to "
         "record."),

dict(id="D36", kind="deviation", severity="change", status="done",
     title="Nine copies of \u201cwhich version are we on\u201d, and D30 is what "
           "happens when two of them disagree",
     refs=["31.2", "31.4"],
     body="The design document\u2019s filename carries its version, so every "
          "tool that opens it holds a copy of which version this repository "
          "reads. There were <strong>nine, across six files</strong>, and "
          "nothing compared them."
          "<br><br><strong>D30 is that fault, already suffered.</strong> "
          "<code>extract_content.py</code> built the content tables from v3.0 "
          "and <code>validate_content.py</code> validated them against v3.0, so "
          "the pair agreed and three of v3.1\u2019s improvements were invisible "
          "\u2014 one of which had the economy model understating the Library "
          "faucet by up to 47%. <strong>D30 was fixed by editing the two "
          "filenames</strong>, which left the other seven for the next version "
          "to find."
          "<br><br><code>check_document_version</code> could not help, and it "
          "is worth being exact about why: it reads <em>prose</em> naming a "
          "version \u2014 \u201cthe design document at v3.0\u201d \u2014 and "
          "these are paths. A path is not prose, so a file pinned to an old "
          "document passes every check in the repository and disagrees with "
          "every other file silently.",
     rec="Fixed. <code>tools/design_doc.py</code> declares the version once and "
         "derives both filenames from it; the six tools import them. Moving to "
         "v3.2 is one line."
         "<br><br><code>check_docs_consistency.check_one_document_home()</code> "
         "refuses a version-pinned document filename anywhere else, with two "
         "exceptions that are honest: <code>extract_design_doc</code> converts "
         "one version\u2019s HTML into its own text and shows both in its usage "
         "line, and <code>tools/vendor/</code> is the document\u2019s own "
         "shipped checker, which belongs to the document and is right to pin "
         "itself to the version it shipped with."
         "<br><br>It also reports a <em>newer</em> document sitting in "
         "<code>docs/design/</code> that nothing reads. The version is a "
         "declared constant rather than \u201cthe newest file present\u201d on "
         "purpose: reading the newest would never go stale and would also "
         "repoint every gate the moment a draft landed, before anyone decided "
         "it was the one to read. The constant keeps that a decision and makes "
         "forgetting it a build message rather than a silence."),

dict(id="D35", kind="deviation", severity="significant", status="done",
     title="An item\u2019s status was worked out in twelve places, and four of "
           "them had never heard of v3.1",
     refs=["31.2", "31.4"],
     body="A register item carries three opinions about itself: the "
          "<code>status</code> written when it was found, what "
          "<code>V3</code> records v3.0 did about it, and what <code>V31</code> "
          "records v3.1 did. The effective status is the latest of the three "
          "that has an opinion, and that expression \u2014 three lines of "
          "<code>or</code> \u2014 <strong>existed twelve times across seven "
          "files</strong>."
          "<br><br><strong>Four of the copies were written before "
          "<code>V31</code> existed and never learned about it.</strong> "
          "<code>build_audit._status_of</code>, "
          "<code>build_roadmap.status_of</code>, "
          "<code>check_dependencies.status_of</code> and "
          "<code>check_edits</code>\u2019s coverage report each read v3.0\u2019s "
          "answer and stopped, so the nine items v3.1 closed \u2014 C7, C10, "
          "C17, C21, C24, C26, D4, D10, G12 \u2014 read as open in all four."
          "<br><br><strong>The audit page said two different things about "
          "itself.</strong> Its header counted with the v3.1-aware copy; its "
          "<em>Where to start</em> section counted with the v3.0-only one and "
          "reported <strong>60 items open and 30 workable against a true 51 "
          "and 25</strong>. Nine settled items were listed as work to do, and "
          "F10 was shown blocked by something already fixed. Two functions in "
          "one file, answering one question two ways, on the page the project "
          "is read through."
          "<br><br><code>SETTLED</code> had four homes as well, twice in "
          "<code>build_audit.py</code> alone \u2014 once as a set and once as "
          "a tuple with the same members.",
     rec="Fixed. <code>audit_register.status()</code> and "
         "<code>is_open()</code> are the home, beside the data rather than in "
         "any one reader, and all twelve call sites import them."
         "<br><br><code>check_docs_consistency.check_one_status_home()</code> "
         "refuses a second copy: a <code>V31.get(\u2026)[\u2018status\u2019]</code> "
         "chained to a fallback, anywhere but the register, fails the build. "
         "Counting what one particular version fixed is a different question "
         "and still allowed, which is why the check looks for the chain rather "
         "than the lookup. <code>--self-test</code> plants the exact expression "
         "that was in the four files."
         "<br><br>Two labels on the page were true only because of the bug and "
         "are corrected with it: the header\u2019s <em>open</em> now reads "
         "<em>open, none drafted</em>, since it excludes drafted items where "
         "<em>Where to start</em> includes them; and <em>fixed in v3.0</em> "
         "now reads <em>fixed in the document</em>, because the count it "
         "labels stopped being v3.0-only the moment this was fixed."
         "<br><br>This is \u00a731.2 \u2014 one fact, one home \u2014 broken "
         "by the tool that reports it, on the page it reports it on. It was "
         "found by making the same mistake by hand: reading an item\u2019s raw "
         "<code>status</code> field, concluding C21 had been closed without "
         "anyone noticing, and being wrong because V31 had said so all along."),

dict(id="D34", kind="deviation", severity="significant", status="open",
     title="The clock D25 made readable reaches one crew of three, and for "
           "that one it is a wall rather than a price",
     refs=["5.4", "12.19", "12.6", "13.2"],
     body="D25 found that no policy in <code>tools/heist_harness/</code> read "
          "<code>heist.clock</code>, so shortening \u00a75.4\u2019s clock "
          "could kill a crew outright but never change what one chose to do "
          "\u2014 and nothing priced in time could be measured at all. The "
          "reading was added. <strong>Nothing checked what reading it "
          "did.</strong>"
          "<br><br>Re-running D25\u2019s own experiment against the fix: a "
          "competent crew with <code>watches_clock</code> on banks "
          "<strong>exactly what the same crew with it off banks</strong>, at "
          "every clock length tested \u2014 24.1, 22.4 and 22.4 at 100%, 70% "
          "and 55%, the same mean to the decimal. <code>_out_of_time</code> "
          "needs the inbound journey to be long against what is left, and a "
          "crew that does not hold at checkpoints never gets there. <strong>A "
          "value that is read and changes nothing is indistinguishable from "
          "one that is not read</strong>, which is D25\u2019s own lesson and "
          "D26\u2019s."
          "<br><br>The one crew it reaches is the optimal one, which holds for "
          "cones, arrives late, and then aborts loading altogether: 20.9 mean "
          "fill at the full clock, <strong>1.1 at 70% and 0.0 at 55%</strong>. "
          "Not less loot for less time \u2014 none."
          "<br><br>\u00a712.19 asks for a dial: <em>\u201cloading longer "
          "earns more and the alarm clock is the price\u201d</em>, with the "
          "break-even at about 70% full <em>\u201cthe dial for the "
          "game\u2019s emotional peak\u201d</em>. A no-op is not a price and "
          "a cliff is not a price. So the number that sentence rests on is "
          "still not measurable, two fixes after D25 said so.",
     rec="The stopping rule has to trade fill against time rather than switch "
         "on it. <code>_out_of_time</code> is a boolean \u2014 leave now if "
         "the way home is longer than what is left \u2014 and a boolean can "
         "only ever produce all or nothing."
         "<br><br><strong>Make it a target rather than a trigger.</strong> The "
         "crew loads to whatever fill the remaining clock affords, at "
         "\u00a712.19\u2019s 30 units a second, and leaves with that. Then "
         "cutting the clock cuts the haul smoothly, \u00a712.19\u2019s "
         "sentence becomes true of the model, and the 70% break-even becomes "
         "something a sweep can find rather than a number the document asserts."
         "<br><br>Until then, treat every result computed across clock lengths "
         "as measuring a wall. <code>test_the_clock_reaches_only_the_crew_that_"
         "cannot_use_it</code> pins both halves, so neither can be fixed "
         "quietly or broken quietly."
         "<br><br><strong>F8 is not affected, and that is worth saying.</strong> "
         "Its claim \u2014 runs finish with a third of the clock unused "
         "\u2014 holds under the competent crew (0.36 of the clock used) more "
         "strongly than under the optimal one (0.61), so it is not an artefact "
         "of a crew that gives up. F21 is not affected either: the optimal "
         "crew coming home empty is the polarisation F21 records and its test "
         "already asserts."),

dict(id="D33", kind="deviation", severity="change", status="done",
     title="Four spec files send a contributor to settle work that v3.0 and "
           "v3.1 finished",
     refs=["31.2", "31.4"],
     body="Each file in <code>docs/design/spec/</code> ends with a "
          "<em>Still open</em> list, and those lists are what a contributor "
          "reads to find out what to do. They were hand-written and nothing "
          "compared them with the register, so seven entries across four files "
          "named items the register has fixed."
          "<br><br><code>spec/detection.md</code> was the worst of them: three "
          "of three, including <em>\u201cSettle the tick rate before writing "
          "the golden replays, which encode it\u201d</em> \u2014 against a "
          "register that has C7 fixed, a document that states 30 steps a second "
          "once, and a build check that fails if a second copy disagrees. "
          "<code>spec/economy.md</code> asked for crew membership to exclude "
          "work, which \u00a75.8 does. <code>spec/movement.md</code> and "
          "<code>spec/ruleborn.md</code> each named one more."
          "<br><br><strong>The citation check could not see it.</strong> Every "
          "section these files cite still exists; what went stale is the claim "
          "about an item\u2019s state. That is C21 to C24 in this "
          "repository\u2019s own documents rather than the design "
          "document\u2019s, and it is the reason \u00a731.4\u2019s rule "
          "\u2014 generated, not authored \u2014 has to reach the prose that "
          "describes the data and not only the data.",
     rec="Fixed, and checked. Each file now carries a <em>Settled since this "
         "was written</em> section naming what answered each question, because "
         "a spec that silently drops a question reads as if it never asked one. "
         "<code>check_docs_consistency.check_spec_status()</code> compares "
         "every <em>Still open</em> list against the register on each build."
         "<br><br>It reads only the <strong>subject</strong> of each bullet. A "
         "bullet may cite a settled item as context for a question that is "
         "genuinely open \u2014 <code>first-build.md</code> explains an open "
         "question with \u201cUnder F1 the roster is the binding "
         "constraint\u201d and <code>vault.md</code> notes a refinement "
         "\u201cis not needed to close G4\u201d \u2014 and flagging those "
         "would send someone to correct a file that is right. "
         "<code>check_spec_index</code>\u2019s own docstring records what that "
         "costs, which is why the rule here is narrow."),

dict(id="D31", kind="deviation", severity="significant", status="open",
     title="\u00a77.9\u2019s two dials are one dial, measured across all 48 "
           "law sheets",
     refs=["7.1", "7.9", "7.7", "12.4", "12.5"],
     body="\u00a77.9 is titled <em>Rarity buys specificity, not strength</em> "
          "and states the rule the whole rank system exists to enforce: "
          "<em>\u201crarity governs how long a law takes to get, while "
          "stability cost and conditions govern how strong it is. These are two "
          "dials, and the earlier version tied them together.\u201d</em> "
          "\u00a77.1 restates it as a property of every law: <em>\u201cRank "
          "sets how long a law takes to acquire \u2014 not how strong it "
          "is.\u201d</em>"
          "<br><br><strong>Across the 48 sheets, rank predicts stability cost "
          "at r = +0.80.</strong> In 732 of 828 cross-rank pairs (88%) the rarer "
          "law costs more. The medians climb with the ladder: common 14, "
          "uncommon 17, rare 17, deep 22. Rank predicts conditions \u2014 the "
          "other dial \u00a77.9 names \u2014 at r = \u22120.04, which is "
          "nothing, and common laws carry marginally <em>more</em> conditional "
          "text than rare ones. So v2.0 split the ranks and the sheets tied them "
          "back together."
          "<br><br><strong>\u00a77.9\u2019s own remedy makes it "
          "worse.</strong> <em>\u201cIf playtests show rare and deep laws still "
          "producing materially higher defence rates than common ones, the "
          "answer is more stability cost or a tighter condition, not a smaller "
          "number.\u201d</em> Raising a rare law\u2019s stability cost raises "
          "the correlation that is the fault."
          "<br><br><strong>And the mechanism it names as the primary reason the "
          "split is fair does not discriminate by rank.</strong> \u00a77.9 says "
          "<em>\u201cevery rare and deep law appears in the scout report "
          "(12.5)\u201d</em> and charges that visibility against the law\u2019s "
          "strength. The scout report is \u00a712.4, not \u00a712.5; what it "
          "shows, for 20 Aether a realm and fifteen minutes, is "
          "<em>\u201ceach realm\u2019s laws\u201d</em> \u2014 every rank "
          "alike. Visibility cannot be charged against a deep law\u2019s "
          "strength when a common law pays the same price for it.",
     rec="Two dials or one, and say which. Either is defensible; what is not is "
         "stating the separation and authoring the coupling."
         "<br><br><strong>Keep the separation.</strong> Re-cost the sheets so "
         "stability cost stops tracking rank \u2014 the deep laws are the "
         "expensive ones and the change is theirs to absorb \u2014 and give "
         "rarity its own currency, which \u00a77.6 already has in pages. Then "
         "the rare laws have to earn their rank on specificity, and r = "
         "\u22120.04 says they currently do not."
         "<br><br><strong>Or drop it.</strong> Rewrite \u00a77.9 to say rank is "
         "a strength ladder paid for in pages, which is what the sheets "
         "describe and what \u00a77.9\u2019s own counter-evidence "
         "[208] says every shipped game does anyway. \u00a77.1\u2019s "
         "glossary line goes with it."
         "<br><br>The scout-report paragraph is wrong either way and is drafted "
         "below. <code>tools/law_ranks.py</code> runs the measurement and "
         "<code>tools/validate_content.py</code> reports it on every build, so "
         "whichever way this goes the sheets cannot drift back without saying "
         "so."),

dict(id="D29", kind="deviation", severity="change", status="done",
     title="This repository cited 41 sections v3.1 had renumbered away",
     refs=["31.2", "25.4", "5.8", "7.9", "10.4"],
     body="v3.1 filled four holes v3.0\u2019s deletions had left \u2014 "
          "\u00a75.8, \u00a77.8, \u00a710.4 and \u00a725.3 were all missing "
          "\u2014 which shifted the section after each of them down by one: "
          "5.9\u21925.8, 7.10\u21927.9, 10.5\u219210.4, 25.5\u219225.4."
          "<br><br>The register\u2019s own citations were checked when that was "
          "found: <code>check_edits.py</code> caught 37 of them and its "
          "docstring records that a renumbering is never only clerical. The "
          "sentence was right and the check was too narrow. It read the "
          "register; it did not read the twenty-nine spec files, the generated "
          "analyses or the tools\u2019 own docstrings, which is most of the "
          "prose here and all of the prose a contributor reads first. There "
          "were <strong>67 more</strong>, and after excluding the ones whose "
          "text says they are historical, <strong>41 that a reader would "
          "follow and find nothing</strong>."
          "<br><br>The worst of them is not a number. "
          "<code>docs/design/spec/validation.md</code> argues about "
          "\u00a725.5 for four paragraphs \u2014 what it rules out, whether "
          "its opening sentence is false, what would have to change \u2014 "
          "and \u00a725.5 has not existed since v3.1. The argument is "
          "sound and it is filed under a number nobody can look up."
          "<br><br><code>docs/design/spec/wards.md</code> is the other kind: "
          "it cited \u00a713.5 for \u201cwatch a raid on your island\u201d, "
          "and \u00a713 ends at 13.4 in v3.1 \u2014 no renumbering explains "
          "it, and no section of v3.1 carries that sentence. The feature the "
          "line needed is the replay allowance, which is in \u00a710.2\u2019s "
          "building table, so that reference was not only dead but pointing at "
          "the wrong kind of section.",
     rec="All 41 fixed and the check generalised. "
         "<code>check_docs_consistency.py</code> now reads every <code>.md</code> "
         "under <code>docs/</code>, every <code>.py</code> under "
         "<code>tools/</code> and the README, and fails on a "
         "\u00a7N.M that v3.1 does not have."
         "<br><br>Three ways a stale number is allowed, and each is a claim "
         "rather than a silence. <strong>The file is an archive of an earlier "
         "version</strong> \u2014 <code>docs/analysis/</code> was written "
         "against v2.3 and renumbering it would make it describe a document it "
         "never read, so it is listed as exempt rather than skipped quietly. "
         "<strong>The text around the number says it is historical</strong>, "
         "which is how this repository already writes such references: "
         "\u201cv3.0\u2019s \u00a75.9, renumbered \u00a75.8 in v3.1\u201d. "
         "<strong>Nothing else.</strong> A number no version has ever had is "
         "reported as the harder problem it is."
         "<br><br>The generated documents were fixed at their generator and "
         "regenerated, because \u00a731.4\u2019s rule is that a generated file "
         "is never edited by hand \u2014 and two of the 41 were in "
         "<code>docs/design/generated/</code>, where a hand fix would have been "
         "undone by the next build."),

dict(id="D26", kind="deviation", severity="change", status="done",
     title="Every guard began every raid at the same point of its patrol",
     refs=["12.17", "13.2", "13.4"],
     body="<code>Patrol.phase</code> exists, is documented as where a guard is "
          "on its loop, and is computed by the island generator for every "
          "patrol. <strong>The simulation never read it.</strong> Guards were "
          "placed at <code>waypoints[0]</code> on every run, so the defence was "
          "always caught at the same moment of its cycle.<br><br>It was found "
          "while building a hand-designed island for F16: that island has one "
          "layout, so its only source of variation between raids is where the "
          "guards are \u2014 and there was none. Every run in a batch of 120 "
          "was the same run, every coalition value was 0 or 100, and the Shapley "
          "shares came back as the signature of a degenerate game: geometry "
          "0.0%, three layers on exactly 33.3%.<br><br>Third of its kind this "
          "session, and the family is now clear enough to name: <strong>a field "
          "that is computed and never consumed</strong>. D24 was a phase that "
          "ended on the wrong condition, D25 a clock nobody read, this a "
          "starting position nobody applied. None of them failed a test, because "
          "the tests assert bands and a band absorbs a systematic "
          "simplification.",
     rec="Fixed: a guard now starts at the waypoint its phase implies. It "
         "changes the baseline \u2014 generated islands vary by layout as well, "
         "so it was masked there rather than absent \u2014 and the fingerprint "
         "test caught the change on the next build and had its digest updated "
         "deliberately, which is what that test is for.<br><br>The general "
         "guard is now a build gate, <code>tools/check_unread_fields.py</code>, "
         "which reports any dataclass field that is assigned and never loaded."
         "<br><br><strong>It catches this fault and not the other two</strong>, "
         "and an earlier version of this sentence claimed otherwise. "
         "<code>heist.clock</code> was read in four places in "
         "<code>sim.py</code> \u2014 what was missing was that no <em>policy</em> "
         "read it \u2014 and D24 was a wrong condition rather than an unread "
         "field. That correction, and the four further unread fields the check "
         "found on its first run, are D27."),

dict(id="D25", kind="deviation", severity="change", status="done",
     title="No crew in the harness could see \u00a75.4\u2019s clock, so nothing "
           "priced in time could be measured at all",
     refs=["5.4", "12.19", "12.6"],
     body="Chasing the clock \u2014 the dial F15, F16, F18 and F20 all point at "
          "\u2014 the first experiment was to shorten \u00a75.4\u2019s clock "
          "and watch the stopping decision move. It did not move. Cutting the "
          "clock to 55% of its published length changed E[grade \u00d7 fill] by "
          "under 4% at every stopping threshold and left the peak exactly where "
          "it was.<br><br>That looked like a finding: <em>the clock is not a "
          "lever</em>. It was not. <strong>No policy in the harness read "
          "<code>heist.clock</code>.</strong> The crew used the tick counter to "
          "rate-limit its own decisions and to time the crack cadence, and never "
          "once compared the time left against the walk home. A clock-blind crew "
          "not responding to the clock is a fact about the harness, not about "
          "Ruleborn.<br><br>\u00a712.19 states the requirement in the sentence "
          "the whole break-even rests on \u2014 \u201cloading longer earns more "
          "and <em>the alarm clock is the price</em>\u201d. A price nobody can "
          "see is not a price, and a model where nobody can see it cannot test "
          "the claim.<br><br>Caught before publishing, unlike D24, and by the "
          "same habit: ask what the model would have to be doing for the result "
          "to mean what it appears to mean.",
     rec="Competent and Optimal crews now leave when the time left no longer "
         "covers the walk home, estimated the way a player would estimate it "
         "\u2014 the way out is the way in, so what it cost to reach the Vault "
         "is what it will cost to leave, plus 15%. Careless still ignores it, "
         "which is what makes it careless.<br><br>The margin is chosen, not "
         "derived, and it is the one number here to playtest rather than to "
         "trust. It is also biased in a known direction: the way in is crouched "
         "and routed around cones, the way out is a run, so estimating the walk "
         "home from the inbound time makes crews leave earlier than they need "
         "to. That is the conservative direction for everything measured "
         "through it.<br><br><strong>The structural guard is a fingerprint.</strong> "
         "Both of this session\u2019s harness faults were found by reading the "
         "model, not by anything going red, because every other test in the "
         "suite asserts a band rather than a value \u2014 which is right for a "
         "finding and useless for a silent change. "
         "<code>test_the_harness_gives_the_same_answers_as_when_it_was_last_read"
         "</code> hashes the grade, length, fill, decision count and alarm of 40 "
         "runs. A deliberate model change updates the digest and says what moved; "
         "anything else is a change nobody meant.<br><br>It moves the baseline: mean fill on a successful run "
         "falls from 40% to 37% at the published clock, because crews that "
         "reached the Vault late now abort instead of loading into a clock they "
         "cannot beat \u2014 which is correct behaviour and was not being "
         "modelled. F14, F18, F19 and F20 were all re-measured through it."),

dict(id="F18", kind="finding", severity="minor", status="withdrawn",
     title="Withdrawn: \u00a713.2\u2019s populated middle holds for an ordinary "
           "crew \u2014 it is skilled play that breaks it (F21)",
     refs=["13.2", "12.19"],
     body="<strong>This finding is withdrawn, and the check it ran is a pass.</strong>"
          "<br><br>What it claimed: fill on successful raids is bimodal \u2014 "
          "two peaks and a thin middle \u2014 which is the shape \u00a713.2 "
          "names as its own warning sign.<br><br>What was wrong: it was measured "
          "before D25, with crews that could not see \u00a75.4\u2019s clock. "
          "Re-measured over 300 raids with a crew that leaves when the walk home "
          "no longer fits, the competent distribution "
          "is:<br><br><code>"
          "&nbsp;&nbsp;0\u201319% &nbsp;30.0%<br>"
          "&nbsp;20\u201339% &nbsp;16.5%<br>"
          "&nbsp;40\u201359% &nbsp;23.5%<br>"
          "&nbsp;60\u201379% &nbsp;30.0%<br>"
          "80\u2013100% &nbsp;&nbsp;0.0%</code><br><br>"
          "<strong>70% of successful raids land in the middle.</strong> That is "
          "the populated middle \u00a713.2 asks for, not a polarised one. The "
          "metric passes.<br><br>Two things it turned up survive elsewhere: the "
          "empty 80\u2013100% band, which is \u00a712.19\u2019s stopping rule "
          "acting as a ceiling (F20); and the fact that the same measurement "
          "run against a crew that reads the guards gives 16% in the middle "
          "rather than 70% (F21). The polarisation is real. It is a property of "
          "skill, not of the break-even, and that is a different finding with a "
          "different fix.",
     rec="Nothing to do. Recorded rather than deleted because a check that was "
         "run and passed is worth as much in this register as one that failed, "
         "and because the route from the wrong version to the right one is the "
         "useful part: the first measurement conditioned on a model that did not "
         "implement \u00a712.19\u2019s own stated price."),
dict(id="F23", kind="finding", severity="significant", status="proposed",
     title="Four laws reach all twelve chords, so the law table does not gate "
           "the \u201clate-game discovery\u201d at all",
     refs=["8.5", "8.8", "7.7", "26.1"],
     body="Found while costing D6\u2019s scope cut, which is the useful part: a "
          "check built to <em>limit</em> the cut found that the constraint does "
          "not exist.<br><br>\u00a78.5 calls chords \u201cthe late-game "
          "discovery\u201d. Owning <strong>four</strong> well-chosen laws makes "
          "every one of the twelve reachable, and there are <strong>42</strong> "
          "different four-law sets that do it. The cheapest is Haste, Thorns, "
          "Whispers and Borrowed Face, 70 stability together.<br><br>Four is the "
          "floor rather than a search artefact: no law carries more than two "
          "notes and the wheel has eight, so three laws can never cover it. "
          "<strong>The whole chord table is reachable from one twelfth of the "
          "launch set.</strong><br><br>This is D14 again and harder. D14 found "
          "\u00a78.8\u2019s fix \u2014 three <em>distinct laws</em> rather than "
          "three notes \u2014 made \u00a78.5\u2019s sentence true without "
          "making chords late-game, because 23 of the 48 laws carry two notes. "
          "This puts a number on it: nothing in the collection is the gate.",
     rec="A cut to 24 laws cannot break chords, which is what this check was "
         "built to find out \u2014 and it cannot fix them either. If chords are "
         "meant to be a late-game discovery, <strong>the gate has to be stated "
         "somewhere other than the size of the law table</strong>. Two "
         "candidates already exist and neither is leaned on: the Lab at level 3 "
         "(Spire 5, about day 42), which \u00a78.5 mentions and \u00a78.8 does "
         "not, and the stability to weave three at once \u2014 the cheapest "
         "triple from the four above costs 49 against a day-2 capacity of 51."
         "<br><br><code>python3 tools/scope_cut.py</code>."),

dict(id="F19", kind="finding", severity="significant", status="open",
     title="What a raid pays varies 1.4\u00d7 with how well it is played, and "
           "\u00a79.6 prices it as a constant",
     refs=["9.6", "12.19", "12.17", "14.2"],
     body="\u00a79.6: <code>Haul = B(V) \u00d7 grade \u00d7 difficulty \u00d7 "
          "richness \u00d7 fatigue \u00d7 fill</code>, and it calls 0.46 "
          "\u2014 E[grade] over all attempts \u2014 \u201cthe number the "
          "progression curve is built on\u201d. Two of those terms move with "
          "how a raid is played, so the quantity to measure is E[grade \u00d7 "
          "fill] per attempt. Same islands, same seeds, 300 raids "
          "each:<br><br><code>"
          "stops at 12.19\u2019s break-even &nbsp;&nbsp;E = 0.127 an "
          "attempt<br>"
          "reads the guards, then decides &nbsp;E = 0.187 an attempt</code>"
          "<br><br><strong>1.47\u00d7</strong>, and both are far below "
          "\u00a79.6\u2019s 0.46 \u2014 which is E[grade] alone and takes no "
          "account of the fill term v3.0 added beside it (F14).<br><br>The "
          "second crew is not braver. It uses what \u00a712.17 already shows "
          "the player \u2014 a guard\u2019s suspicion and the path of its cone "
          "\u2014 to push to 95% when nothing has noticed and leave at 35% when "
          "something has. <strong>Its mean fill on a successful run is "
          "<em>lower</em></strong>, 35% against 39%: it wins by converting more "
          "attempts into clean, full ones and abandoning the rest early, not by "
          "carrying more when it succeeds.<br><br>That distinction is the reason "
          "this finding was briefly withdrawn and then reinstated. Measured as "
          "\u201cfill on a successful run\u201d the effect reverses sign; "
          "measured as what \u00a79.6 actually pays per attempt it is "
          "1.47\u00d7. The first statistic is the wrong one, because it "
          "conditions on the outcome the skill is changing.<br><br>An earlier "
          "version of this item claimed 2.2\u00d7, measured before D25 with "
          "crews that could not see the clock.",
     rec="Either accept that the faucet is skill-dependent and say so \u2014 in "
         "which case \u00a714.2 needs a band rather than a curve, because the "
         "gap compounds over hundreds of raids \u2014 or narrow it. "
         "<br><br>Narrowing it is the same question as F21: the informed crew "
         "earns more <em>by being more polarised</em>, taking 80\u2013100% on a "
         "quarter of its runs and under 20% on more than half. Anything that "
         "populates the middle also narrows this spread.<br><br>What is not "
         "defensible is \u00a79.6 naming one number as the one the progression "
         "curve is built on while two of its own terms move it by half as much "
         "again. <code>python3 -m tools.heist_harness depth</code>."
         "<br><br><strong>Re-measured, and it needed four times the sample it "
         "was first given.</strong> Paired over the same islands at 1,200 "
         "seeds: 0.1222 at \u00a712.19\u2019s 70% rule against 0.1698 reading "
         "the guards, a difference of <strong>+0.0476 \u00b1 0.0108, "
         "t = 4.4</strong>. The finding stands and the number moves: "
         "<strong>1.39\u00d7, not 1.47\u00d7</strong>.<br><br>How it was "
         "reached is worth more than the revision. At 400 seeds the same "
         "comparison gives <strong>t = 1.9</strong> \u2014 indistinguishable "
         "from noise. The per-seed standard deviation of the paired difference "
         "is 0.375 against an effect of 0.048, so about 560 seeds are needed "
         "for t = 3 and 990 for t = 4, and the 1.47\u00d7 above was measured "
         "at 300. <strong>The effect was real and the precision was never "
         "earned</strong> \u2014 the same fault that withdrew this "
         "item\u2019s first 2.2\u00d7 and F18 beside it. Three times now in "
         "one register, which is a habit rather than an accident."
         "<br><br>No test pins this one, deliberately: 560 seeds is about 1,100 "
         "heists and would roughly triple the suite. It is the case "
         "<code>measured=</code> exists for.",
     measured="496955db53f8d3c4e13f7d1683dd4c47fb49a682f43301859cf1276e10b3c13d"),
dict(id="D24", kind="deviation", severity="change", status="done",
     title="The Vault phase in the harness was two seconds long, and every "
           "number was measured through it",
     refs=["12.19", "12.6", "13.4"],
     body="\u00a712.19 fixed \u00a712.6\u2019s Vault phase: \u201cevery role "
          "can load, at 30 units a second\u2026 a full crew fills in about ten "
          "seconds, which is one decision at the eight-to-twelve second cadence "
          "12.6 sets for itself.\u201d<br><br>The harness\u2019s crew policy "
          "ended the phase the moment <em>any</em> member\u2019s bag filled. A "
          "Scout holds 60 and fills in two seconds, so the whole crew left after "
          "two \u2014 with the Carrier, which is 300 of the crew\u2019s 560, "
          "walking out on 60. <strong>Every crew banked 53% whatever the island "
          "did</strong>, and every fill, ablation and haul number this harness "
          "has produced was measured through it.<br><br>It is exactly the fault "
          "\u00a712.6 was criticised for \u2014 \u201ctwo seconds and one "
          "option\u201d \u2014 reintroduced by the policy rather than by the "
          "spec, three sections after the spec fixed it.<br><br>The test that "
          "should have caught it is the reason it survived: "
          "<code>test_a_full_crew_loads_in_ten_seconds</code> asserted "
          "<code>Carrier carry / 30 == 10</code>, which is arithmetic about the "
          "content table. It was true throughout. A test that checks a constant "
          "when the claim is about behaviour is the same failure as D19\u2019s "
          "hard-coded checks, one level in.",
     rec="Fixed: a member who can carry no more now waits, and the phase ends "
         "when every bag is full, the exposed share is gone, or the crew\u2019s "
         "own stop rule fires. Three things fell out of the fix that are worth "
         "more than the fix.<br><br><strong>\u00a712.19\u2019s ten seconds now "
         "reproduces exactly</strong> \u2014 a crew told to take everything "
         "spends 10.0 seconds loading and ends at 100% fill, from the role Carry "
         "values and the stated rate, unasserted. The document\u2019s number "
         "falls out of the model instead of being quoted at it.<br><br><strong>A "
         "competent crew now stops at \u00a712.19\u2019s own 70% break-even "
         "instead of 53%</strong>, which is what the policy was written to do "
         "and had never once done.<br><br><strong>Skill separates on haul, which "
         "it could not before.</strong> Competent banks 40% of capacity on a "
         "successful run, optimal 89% \u2014 see F19. Both were pinned near 53% "
         "by the bug, so the harness was reporting that how well you play does "
         "not affect what you carry.<br><br>The test now runs a heist and checks "
         "the behaviour. <code>python3 -m tools.heist_harness.test_harness</code>."),

dict(id="F15", kind="finding", severity="blocking", status="proposed",
     title="Guards and Response are not two layers; they are one, and three more have no path to the metric",
     refs=["13.2", "13.4", "5.4", "9.6"],
     body="\u00a713.2 lists five defence layers with target shares and one rule "
          "above them: <strong>no single layer above 25%</strong>, because "
          "\u201cif one layer decides outcomes, the other four are "
          "decoration\u201d. \u00a713.4 specifies exactly how to check it \u2014 "
          "all 32 combinations, credit divided \u201cthe way cooperative game "
          "theory does\u201d, which is the Shapley value. At 120 raids a "
          "combination:<br><br><code>"
          "geometry &nbsp;4.4% &nbsp;(target 25%)<br>"
          "guards &nbsp;&nbsp;34.5% &nbsp;(target 20%)<br>"
          "wards &nbsp;&nbsp;&nbsp;20.9% &nbsp;(target 20%)<br>"
          "laws &nbsp;&nbsp;&nbsp;&nbsp;5.7% &nbsp;(target 20%)<br>"
          "response &nbsp;34.5% &nbsp;(target 15%)</code><br><br>"
          "Guards and Response are equal to the decimal, and that is a theorem "
          "rather than a coincidence: in <strong>every one of the eight "
          "coalitions</strong>, guards without response turn back 0% of raids and "
          "response without guards turns back 0%. Symmetric players must take "
          "identical shares.<br><br><strong>The cause is not that Response lacks "
          "an effect of its own.</strong> That was this item\u2019s first "
          "recommendation; it was specified, built and measured, and it failed "
          "\u2014 see <code>docs/design/spec/response.md</code>. The real cause "
          "is that <strong>guards-and-response is the island\u2019s only "
          "detect-and-act chain</strong>. Geometry, wards and laws all work by "
          "<em>delay</em>, and delay reaches an outcome only through the clock "
          "\u2014 which has four times the slack any delay would need, since a "
          "run ends at about 40 seconds of \u00a75.4\u2019s 165. So the island "
          "has exactly one way to turn back a raid, it needs both halves, and "
          "\u00a713.4\u2019s metric can see nothing else.<br><br><strong>The "
          "metric is half the fault.</strong> \u00a713.4 measures the hold rate. "
          "\u00a712.9 grades a raid clean, loud, partial or foiled and "
          "\u00a79.6 pays 1.0, 0.7, 0.4 and 0 \u2014 so a defence that turns "
          "every clean run into a partial one takes 60% of the raider\u2019s "
          "income and scores <em>zero</em>. Re-measured against grade \u00d7 "
          "fill, the identity breaks (guards 38.7%, response 35.4%) and the 69% "
          "does not: together they deny 74% of the haul, and geometry and laws "
          "get worse, at 1.6% and 3.5%."
          "<br><br><strong>Re-measured after D55</strong> (the harness now reads peripheral vision as the content file does; same seeds and sample sizes): Guards and Response still measure identically — 32.5% each by hold rate (was 30.9%), 40.7% and 35.5% by haul (was 39.6% and 35.3%) — and both stay over §13.2’s 25% ceiling. The generated defence holds 42.5% (was 47.5%), inside the band at 120 raids a coalition. The finding holds.",
     rec="Three changes, in order, specified in "
         "<code>docs/design/spec/response.md</code>.<br><br><strong>1. "
         "\u00a713.4: measure against what \u00a79.6 pays, not the hold "
         "rate.</strong> One sentence, and it is the difference between a "
         "measurement that can see four of the five layers and one that cannot. "
         "It is strictly more information \u2014 the hold rate is the special "
         "case where grade \u00d7 fill is zero.<br><br><strong>2. \u00a75.4: "
         "the clock is why three layers are decoration.</strong> Either tighten "
         "it until delay converts to outcomes \u2014 which is also what "
         "\u00a719.27\u2019s \u201ca quarter of runs decided in the last ten "
         "seconds\u201d asks for and does not get \u2014 or accept that "
         "geometry, wards and laws shape the haul rather than the outcome, and "
         "rewrite \u00a713.2\u2019s shares to say which layers do "
         "which.<br><br><strong>3. \u00a713.2: specify the Spire\u2019s reach "
         "and the guardian Sage\u2019s power</strong> \u2014 both are named "
         "there and neither is defined, and a layer whose two named components "
         "have no rules is not a layer. But stop claiming Response is independent "
         "of Guards. \u201cDetection and response, 35%\u201d is a layer; "
         "\u201cGuards 20%, Response 15%\u201d is one layer counted twice, and "
         "that is what breaks the ceiling on paper as well as in the harness."
         "<br><br><strong>Settled by measurement, not by argument.</strong> The "
         "Spire\u2019s reach and the Sage\u2019s power are now specified and "
         "built (spec/response.md), and they work: separately they cost a raider "
         "6% and 18% of the haul with no guard involved. Run through "
         "\u00a713.4\u2019s 32 coalitions they still change nothing \u2014 "
         "guards 39.0% \u2192 39.1%, response 34.7% \u2192 35.1%, and response "
         "alone against a bare island stays at 0.0%. Both effects need the crew "
         "to have been slowed by something else first: on an undefended island "
         "there is nothing for a re-seal to race and nothing for a slow to eat "
         "into. <strong>The layer is a complement by construction, and "
         "specifying it does not change that</strong> \u2014 so the ceiling "
         "breach is a fact about \u00a713.2\u2019s table rather than about the "
         "layer\u2019s contents, and change 3 is the operative one."
         "<br><br><code>python3 -m tools.heist_harness ablation 120</code> and "
         "<code>python3 -m tools.heist_harness haul 120</code>."
         "<br><br><strong>Re-measured on the current harness, and against "
         "the generator F16 asked for</strong> (80 raids a coalition, realm "
         "3):<br><br><code>"
         "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
         "&nbsp;&nbsp;plain &nbsp;shaped &nbsp;target<br>"
         "geometry &nbsp;&nbsp;8.5% &nbsp;<strong>16.0%</strong> &nbsp;&nbsp;25%<br>"
         "guards &nbsp;&nbsp;&nbsp;31.5% &nbsp;&nbsp;28.8% &nbsp;&nbsp;20%<br>"
         "wards &nbsp;&nbsp;&nbsp;&nbsp;22.5% &nbsp;&nbsp;18.2% &nbsp;&nbsp;20%<br>"
         "laws &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;6.1% &nbsp;&nbsp;&nbsp;8.2% &nbsp;&nbsp;20%<br>"
         "response &nbsp;31.5% &nbsp;&nbsp;28.8% &nbsp;&nbsp;15%</code>"
         "<br><br>Three things, and the first is the one that matters."
         "<br><br><strong>Guards and response are identical to the decimal "
         "under both generators.</strong> 31.5/31.5 and 28.8/28.8. The "
         "symmetry is a theorem about the coalitions, not an artefact of "
         "the island it was first measured on, and changing the island "
         "wholesale does not disturb it by a tenth of a point."
         "<br><br><strong>Geometry\u2019s share nearly doubles</strong> "
         "\u2014 8.5% to 16.0% on the hold rate, 0.4% to 7.7% on the haul "
         "\u2014 which is F16\u2019s claim measured through \u00a713.4\u2019s "
         "own method. A good part of what this item recorded as a fact about "
         "the layer was a fact about the generator.<br><br><strong>The "
         "ceiling breach shrinks and does not close.</strong> Guards and "
         "response fall from 34.5% to 28.8%, still over \u00a713.2\u2019s "
         "25%, and geometry rises to 16% against its 25% target. So this "
         "item\u2019s conclusion stands \u2014 the breach is about "
         "\u00a713.2\u2019s table \u2014 with one correction: it is "
         "<em>partly</em> about the generator, and the earlier 4.4% "
         "understated the layer.",
     measured="re-run against harness ef4163da978cc0f0 (D55)"),

dict(id="F16", kind="finding", severity="significant", status="proposed",
     title="Geometry is 5% of a generated defence \u2014 and designed, it is worth four times as much",
     refs=["13.2", "13.3", "13.4", "18.7"],
     body="\u00a713.2 gives Geometry the largest share of any layer, 25%, and "
          "the warmest description: \u201cfree, unlimited, and <em>the layer a "
          "thoughtful designer beats a richer player with</em>\u201d. It is the "
          "layer the whole authorship argument rests on.<br><br>Measured on "
          "<strong>generated</strong> islands it contributes <strong>5.4%</strong> "
          "of the defence, and <strong>0.2%</strong> of the haul denied. At a "
          "smaller sample it measured slightly negative.<br><br><strong>The "
          "cause is the generator, not the design.</strong> This item always "
          "said the distinction was the finding \u2014 \u201cthis measures "
          "<em>generated</em> geometry, not designed geometry\u201d \u2014 and "
          "it has now been tested. <code>tools/heist_harness/designed.py</code> "
          "is one island laid out by hand against \u00a713.2\u2019s own list: "
          "the Vault in the middle of a spiral, one corridor in, a switchback "
          "route, a decoy ring, and no cover on the true path. Same harness, "
          "same guards, same wards, geometry turned off and "
          "on:<br><br><code>"
          "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;off &nbsp;&nbsp;&nbsp;&nbsp;on "
          "&nbsp;&nbsp;&nbsp;contribution<br>"
          "generated &nbsp;30.7% &nbsp;48.7% &nbsp;<strong>+18.0</strong><br>"
          "designed &nbsp;&nbsp;18.0% &nbsp;<strong>100.0%</strong> &nbsp;"
          "<strong>+82.0</strong></code><br><br>On the haul metric it is +6.6 "
          "against <strong>+45.8</strong>. <strong>Designed geometry is worth "
          "four to seven times generated geometry</strong>, and "
          "\u00a713.2\u2019s claim about the layer survives \u2014 what fails "
          "is the generator.<br><br>Two things fall out. The designed island "
          "turns back <strong>every</strong> raid, which is well above "
          "\u00a713.2\u2019s 30\u201345% band: free, unlimited terrain in "
          "thoughtful hands is strong enough to break the band on its own. And "
          "its <em>geometry-off</em> hold rate is 18.0%, <em>below</em> the "
          "generated island\u2019s 30.7%, because guards posted at chokepoints "
          "are badly placed once the chokepoints are gone. Design cuts both "
          "ways."
          "<br><br><strong>Re-measured after D55</strong> (the harness now reads peripheral vision as the content file does; same seeds and sample sizes): generated geometry 25.3% off, 33.3% on (+8.0, unchanged); designed 8.7% off, 97.3% on (+88.7, unchanged). Designed geometry is still worth eleven times generated. The designed island now holds 97.3% rather than every raid."
          "<br><br><strong>Re-measured after D56</strong> (v3.3's half-speed crouch; the crack noise off, because with it on it decides the answer itself, F32; n=40 a cell, all layers against all but geometry): generated geometry is worth \u22127.5 points, which is zero inside the noise, and designed geometry 57.5. With the noise on, \u221230.0 and 30.0. The finding holds in the form that matters \u2014 the generator's geometry adds nothing and a designed island's adds a great deal \u2014 and the ratio the test used to assert has become a difference, since a ratio to zero is not a claim.",
     rec="This is the sharpest argument for the creator ladder \u00a718.7 "
         "describes, and against treating generation as equivalent to design. "
         "\u00a713.2\u2019s \u201c60% from design rather than level\u201d is "
         "a property of hand-built islands, and v3.0\u2019s \u00a713.3 made "
         "generated ones the default \u2014 so the two populations are no "
         "longer the same, and the shipping one is the weak one.<br><br>"
         "<strong>The generator is the thing to fix, and cheaply.</strong> It "
         "lays one hedge band with a gap, then scatters three to five clumps of "
         "tall grass \u2014 and tall grass <em>hides the raider</em> "
         "(\u00a712.17), anywhere it lands, including on the route. A good part "
         "of what it calls geometry is cover handed to the attacker. A generator "
         "that placed the Vault away from the entry, kept one route long, and "
         "put cover off the path rather than on it would close most of the gap "
         "without any new mechanic.<br><br>Then re-check the band: a designed "
         "island holding 100% is as much a problem as a generated one holding "
         "5%. <code>python3 -m tools.heist_harness.test_harness</code>."
         "<br><br><strong>Re-measured on the current harness</strong> \u2014 competent crew, no laws, two realms crossed, 150 raids a cell:<br><br><code>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;off &nbsp;&nbsp;&nbsp;&nbsp;on &nbsp;&nbsp;contribution<br>generated &nbsp;24.0% &nbsp;&nbsp;32.0% &nbsp;&nbsp;&nbsp;<strong>+8.0</strong><br>designed &nbsp;&nbsp;11.3% &nbsp;<strong>100.0%</strong> &nbsp;&nbsp;<strong>+88.7</strong></code><br><br>The finding holds and grows. Designed geometry is worth <strong>eleven times</strong> generated geometry, against the four to seven times first recorded. The designed island still turns back every raid, and its geometry-off hold rate is still <em>below</em> the generated one \u2014 guards posted at chokepoints are badly placed once the chokepoints are gone."
         "<br><br>\u00a713.4\u2019s own method agrees: across all 32 coalitions, generated geometry takes 8.5% of the credit and the shaped generator this finding argued for takes 16.0% (F15).",
     measured="re-run against harness 30af740ce1811dbd (D57)"),
dict(id="D23", kind="deviation", severity="change", status="done",
     title="\u00a713.4's ablation was built exactly as specified, Shapley included",
     refs=["13.4", "13.2"],
     body="\u00a713.4 is the most precisely specified test in the document: "
          "\u201crun the same thousand raids against the island with that layer "
          "switched off\u2026 do it for every combination of the five layers "
          "\u2014 there are only thirty-two \u2014 and divide the credit the way "
          "cooperative game theory does.\u201d",
     rec="<code>tools/heist_harness/ablation.py</code> does that, with the "
         "Shapley value computed in full rather than sampled (five players is "
         "120 orderings) and checked against two cases with known answers. "
         "Building it turned up a confound worth recording: the ward count was "
         "derived from the route length, so turning geometry off removed a ward "
         "too and the geometry share absorbed the ward\u2019s. An ablation that "
         "moves two things at once measures neither, and a test now pins it."
         "<br><br>One number in \u00a713.4 does not survive contact: it says "
         "12,800 runs is something \u201ca deterministic simulation does in "
         "seconds\u201d. In Python it is about twenty minutes. That is an "
         "argument for the Rust core, not against the method."),

dict(id="C27", kind="contradiction", severity="significant", status="open",
     title="Two rules for partial staffing: \u00a79.2's table and \u00a75.8's pro-rata share",
     refs=["9.2", "5.8", "9.3"],
     body="\u00a79.2: \u201c<strong>Staffing sets 60%, 85% or 100% output.</strong>"
          "\u201d \u00a75.8, added in v3.0: \u201cA producer runs at the "
          "<strong>share of its worker slots that are filled</strong>, so a "
          "half-staffed Well earns half.\u201d<br><br>Those are different numbers "
          "wherever the roster binds, and \u00a75.8 says it always binds: two of "
          "three slots is 85% under \u00a79.2 and 67% under \u00a75.8, one of "
          "three is 60% against 33%. \u00a79.2 is the more generous rule at every "
          "partial count.<br><br><strong>There are three homes, not two, and the "
          "third is the one that computes.</strong> \u00a79.3\u2019s production "
          "formula multiplies by \u201cstaffing "
          "<strong>(0.6, 0.85 or 1.0)</strong>\u201d, so the stepped rule is "
          "stated once as a caption and once as a coefficient. This item was "
          "recorded as two homes and its drafted edit was written for two: it "
          "deleted \u00a79.2\u2019s sentence and left \u00a79.3\u2019s "
          "multiplier standing, which would have fixed the caption and changed "
          "nothing a reader computes. Both edits are drafted now, and "
          "<code>check_document.py</code> reports the homes it finds rather than "
          "the two this item remembered.<br><br>\u00a727.2 and \u00a730.18 also "
          "say \u201cpartial staffing pays pro-rata\u201d, and both cite "
          "\u00a75.8 \u2014 which is what \u00a731.2 asks for and not a fourth "
          "home. The check tells the two apart, because a version that did not "
          "would have reported five homes and been wrong about two of "
          "them.<br><br>Worth about 11% of late-game production, and "
          "nothing at all until the roster starts binding \u2014 which is why it "
          "hid.",
     rec="\u00a75.8 is the later and better-argued rule, and pro-rata is the one "
         "that makes partial staffing a real choice rather than a rounding. "
         "Delete \u00a79.2\u2019s sentence <em>and</em> the coefficient in "
         "\u00a79.3\u2019s formula; deleting only the first leaves the game "
         "computing the rule it just deleted. This is the fourth instance of the "
         "same pattern in v3.0 (C21\u2013C23) and the cheapest to fix. "
         "<code>tools/economy_model</code> already switches between the two "
         "\u2014 <code>Config.staffing_rule</code> \u2014 so the cost of the "
         "change can be measured before it is made."),

dict(id="F17", kind="finding", severity="blocking", status="proposed",
     title="Aether and Essence have no sinks, because every price in \u00a79.5 is on the wrong kind of curve",
     refs=["9.5", "9.3", "9.1", "10.2", "11.6"],
     body="\u00a79.1 runs the game on three resources and \u00a79.5 prices every "
          "sink for all three. A total understates the problem, because a faucet "
          "runs every day and almost every price in \u00a79.5 is paid once. "
          "Totalled over a whole account to day 301:<br><br><code>"
          "Aether &nbsp;&nbsp;produced 14,674,532 &nbsp;every price there is "
          "2,968,032 &nbsp;faucet is &nbsp;5x the sink<br>"
          "Essence &nbsp;produced &nbsp;6,660,571 &nbsp;every price there is "
          "&nbsp;&nbsp;658,501 &nbsp;faucet is 10x the sink</code><br><br>"
          "And that is the best case: at day 301 every Essence price is finished "
          "\u2014 the roster is capped, every character is level 10 \u2014 while "
          "the Gardens keep running.<br><br><strong>The cause is not the size of "
          "the prices but their shape.</strong> From day 2 to day 301 the faucets "
          "multiply by 122, 240 and 251. The prices aimed at them multiply "
          "by:<br><br><code>"
          "Starlight &nbsp;a Star Well level &nbsp;&nbsp;&nbsp;&nbsp;x1,478 "
          "&nbsp;&nbsp;faucet x122 &nbsp;\u2192 outruns it 12x<br>"
          "Aether &nbsp;&nbsp;&nbsp;&nbsp;weaving, upkeep, the Lab &nbsp;&nbsp;"
          "&nbsp;&nbsp;&nbsp;x10 &nbsp;&nbsp;faucet x240 &nbsp;\u2192 behind it "
          "24x<br>"
          "Essence &nbsp;&nbsp;&nbsp;the next birth &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;x88 &nbsp;&nbsp;faucet x251 &nbsp;"
          "\u2192 behind it 3x</code><br><br>"
          "Starlight is permanently scarce because \u00a710.2\u2019s building "
          "curve is geometric and never ends. Nothing points a geometric curve at "
          "the other two: every price aimed at them is flat (scouting), linear "
          "(the Lab, waking) or capped (births at 38, levels at 10), and a "
          "bounded price against an unbounded faucet loses by however long the "
          "game runs.<br><br><strong>\u00a79.5 has exactly one recurring price "
          "and the roster cap makes it unreachable.</strong> \u00a711.6 rests a "
          "crew 45 minutes and \u00a79.5 charges 2 Essence a level a minute to "
          "wake them early \u2014 the only price a player pays again every "
          "session. It falls due only when nobody rested is left to send, which "
          "at the roster cap of 38 is <strong>199 heists a day</strong>. "
          "\u00a714.2\u2019s engaged player raids four times. Same shape as C19 "
          "and F1: \u00a711.5 set the cap, \u00a711.6 set the rest window, "
          "nobody divided one by the other.<br><br>Computed from \u00a79.3\u2019s "
          "published table as well as from the model, so it cannot be an artefact "
          "of how the model reads \u00a75.8.",
     rec="Specified in <code>docs/design/spec/sinks.md</code>. Two changes, and "
         "the second is the one that matters.<br><br><strong>1. Price upkeep off "
         "the faucet that pays it.</strong> Not 15 Aether an hour a point, which "
         "is what this finding first proposed and what the spec withdraws: "
         "\u00a79.5\u2019s flat 0.5 is <strong>60% of a day\u2019s Aether on "
         "day 2 and 3.2% on day 301</strong>, so raising it postpones the "
         "late-game problem by about forty days and makes the early game "
         "unplayable. Charge 0.05% of the player\u2019s own hourly Aether "
         "production per point held, and a full sheet costs about a quarter of "
         "income at every stage. It also repairs \u00a79.1\u2019s cap without "
         "touching it: \u00a710.2\u2019s 50,000 at Spire 10 becomes about one "
         "day\u2019s upkeep, where under the flat rate it was 8.5 days and never "
         "bound (C18).<br><br><strong>2. Cut the faucets \u2014 this is the "
         "fix.</strong> Pegging upkeep moves the share of a lifetime\u2019s "
         "Aether the document can absorb from 12.3% to 18.5% and can do no more, "
         "because a sheet grows x10 while Aether grows x240. Measured against "
         "every price there is, an <strong>Aether Spring at level 5</strong> and "
         "a <strong>Garden at level 3</strong> already produce more than the game "
         "can spend; \u00a710.2 sells five and seven more levels above them, up "
         "to 5x and 10x. Those upgrades cost Starlight and return a resource with "
         "nothing to buy. Cutting them is cheap, because it deletes a Starlight "
         "sink and Starlight is the one currency whose sink already outruns its "
         "faucet.<br><br>A recurring Essence price (characters cost Essence to "
         "keep) is the alternative to cutting the Garden ladder, and the spec "
         "argues against it: \u00a71.2\u2019s \u201cnothing is wasted\u201d and "
         "\u00a71.3\u2019s \u201ctired of endless timers\u201d rule out a "
         "roster that starves while you are away. "
         "<code>python3 -m tools.economy_model scaling</code>."),

dict(id="C28", kind="contradiction", severity="minor", status="open",
     title="Births are priced twice: \u00a79.5\u2019s geometric curve and \u00a711.5\u2019s linear one",
     refs=["9.5", "11.5"],
     body="\u00a79.5: \u201cA new ruleborn: 100 \u00d7 1.15^(ruleborn owned) "
          "Essence (about 400 for the 10th, 1,600 for the 20th, 6,600 for the "
          "30th)\u201d. \u00a711.5: \u201cA birth costs 100 Essence plus 40 per "
          "character already owned.\u201d<br><br>Geometric against linear. Both "
          "say <em>owned</em>, so the nth birth is priced at n\u2009\u2212\u20091: "
          "at the 10th they are 352 and 460, and at the roster ceiling of 38 they "
          "are <strong>17,612 and 1,580</strong>, eleven times apart.<br><br>"
          "<strong>\u00a79.5 is not the self-consistent one, which this item "
          "said until it was checked.</strong> Its three worked examples \u2014 "
          "400, 1,600 and 6,600 \u2014 are 405, 1,637 and 6,621: one whole step "
          "of the curve above what its own formula gives. The two rows either "
          "side of it in the same table write their offsets out, as "
          "<code>level \u2212 2</code> and <code>level \u2212 1</code>; the "
          "birth row is the only one in \u00a79.5 that leaves the reader to "
          "infer one, and its examples and its formula infer differently. So "
          "adopting \u00a79.5 means deciding which of the two is meant, and "
          "this item is that decision as much as it is the deletion.<br><br>"
          "<strong>It matters less than it looks, and "
          "that is the finding.</strong> Modelled, the roster fills to the Hearth "
          "cap of 38 by day 31 under <em>either</em> formula, because Essence "
          "income outruns both (F17). A price that cannot bind is not really a "
          "price, so this is a tidy-up rather than a balance question \u2014 "
          "until F17 is fixed, at which point it becomes one.",
     rec="Take \u00a79.5\u2019s, delete \u00a711.5\u2019s sentence, and revisit "
         "the growth rate when F17 is settled. If Essence is ever made scarce, "
         "the difference between 1,580 and 17,612 at the ceiling is the "
         "difference between a roster the player fills and one they build."),

# ===========================================================================
# Found reading v3.3
# ===========================================================================

dict(id="C34", kind="contradiction", severity="significant", status="open",
     title="§10.3 gives a ward’s health as 500 a level, then as 550",
     refs=["10.3", "11.1", "12.20"],
     body="§10.3 opens: <em>“Health is 500 a level for every ward except "
          "Crystal Wall.”</em> The same section closes: <em>“Every ward has "
          "550 health a level”</em>, and explains the move: at 500 a level-2 "
          "ward fell to a Breaker in 10.4 seconds and beat a Tinker’s "
          "disarm, so the coefficient became 550, <em>“the smallest multiple "
          "of 50 at which the crossover lands there”</em>. The smash timings "
          "and the measurement ledger use 550. The first sentence is the one "
          "the edit did not reach.<br><br>It is G3’s own subject, which v3.3 "
          "otherwise closed, and it decides whether smashing or disarming is "
          "the quicker answer to a level-2 ward.",
     rec="Delete the number from the opening sentence and let it point at the "
         "paragraph that derives 550.",
     measured="check_document: a ward's health is stated once (10.3)"),

dict(id="C35", kind="contradiction", severity="significant", status="open",
     title="An engaged player completes the Codex on about day 69 (§14.4) "
           "and about day 234 (§14.3)",
     refs=["14.3", "14.4", "7.6"],
     body="§14.4 works it out: 1,170 pages at 16 a day for 60 days and 23 a "
          "day after, <em>“about 69 days”</em>, and the measurement ledger "
          "repeats it. §14.3: an engaged player owns <em>“all 48 by about day "
          "234”</em>. Chapter gating does not reconcile them: the last "
          "chapter opens at Keeper level 24, which an engaged player passes "
          "before day 90.<br><br>v3.2 had the same pair at 76 and 234. v3.3 "
          "re-derived §14.4 and left §14.3, whose milestone rows ship at the "
          "earlier run (C19). The Codex is the collection the game is paced "
          "around, so the two numbers are two different games.",
     rec="Generate §14.3’s row from the same model run as §14.4, or say what "
         "§14.3 counts that §14.4 does not.",
     measured="check_document: 14.3 and 14.4 give an engaged player's full "
              "Codex the same day"),

dict(id="C36", kind="contradiction", severity="significant", status="open",
     title="Upgrade pacing assumes six heists a day; the engaged player makes "
           "four",
     refs=["9.6", "14.2", "29.1"],
     body="§9.6 prices an upgrade costing 25 clean raids at <em>“213 to 296 "
          "attempts, or 35 to 49 days at six a day”</em>, and the opening "
          "summary and the measurement ledger repeat it. §14.2’s engaged "
          "player makes <em>“5 sessions and 4 heists a day”</em>, and §29.1’s "
          "raid-worth check uses four. At four a day the same attempts take "
          "53 to 74 days. With §9.6’s own fatigue term, which the sentence "
          "says it must carry, six raids a day are worth 4.15 and four are "
          "worth 3.19, so the upgrade takes about 51 to 71 days at six and "
          "67 to 93 at four. Neither is the 35 to 49 printed.",
     rec="Price the pacing at §14.2’s four, or say why the upgrade pacing "
         "assumes a player who raids more than the engaged one.",
     measured="check_document: 9.6's upgrade pacing uses 14.2's engaged "
              "heists a day"),

dict(id="C37", kind="contradiction", severity="minor", status="open",
     title="§12.12 says the scout sees the shifted patrol; §12.4’s scout "
           "shows no patrols",
     refs=["12.12", "12.4", "12.5"],
     body="C31’s fix: the patrol shift is drawn from the heist’s seed when "
          "the target is chosen, <em>“the scout sees the shifted patrol”</em>. "
          "§12.4 lists what a paid scout shows: each realm’s laws, the number "
          "and roles of its guards, and how many wards of each type. No "
          "patrols, and no positions. Either the scout shows more than "
          "§12.4 says, and the scouting screen in §23.2 is drawn short, or "
          "the sentence promises something nothing delivers.",
     rec="Decide whether a scout shows patrol routes. If it does, add them to "
         "§12.4 and to the scout-report screen.",
     measured="check_document: what 12.12 says a scout sees is something "
              "12.4's scout shows"),

dict(id="C38", kind="contradiction", severity="minor", status="open",
     title="§18.9’s Island Fund still quotes the high scenario C12 replaced",
     refs=["18.9", "22.2"],
     body="§18.9: 10% of revenue is <em>“roughly €2,500 a month”</em> at the "
          "base scenario and <em>“about €16,800”</em> at the high one. The "
          "second is 10% of the €168,000 that C12 corrected; §22.2 now gives "
          "about €182,000, so the fund is about €18,200.",
     rec="Derive §18.9’s figures from §22.2’s table, or drop them for the "
         "percentage.",
     measured="check_document: 18.9's Island Fund is 10% of 22.2's scenarios"),

dict(id="C39", kind="contradiction", severity="minor", status="open",
     title="Five sentences v3.3’s own edits left behind",
     refs=["12.11", "12.19", "12.21", "10.4", "31.9", "13.2"],
     body="Each is small, and each was checked against the text:"
          "<br><br>· §12.11 says <em>“In either form”</em> after v3.3 "
          "removed the second form (D48)."
          "<br>· §12.19’s fallback deletes <em>“the break-even sentence "
          "above”</em>, which v3.3 already withdrew (D34)."
          "<br>· §12.21: <em>“Three laws read properties no creature "
          "had”</em>, then names two."
          "<br>· §12.19: cracking takes <em>“about 8 to 25 seconds … with a "
          "Breaker in the crew”</em>. The lower figures re-derive; nothing "
          "gives 25 (a Breaker alone takes 15 seconds at Vault level 1 and "
          "30 at level 2)."
          "<br>· §10.4’s Library formula is <em>“rounded to three "
          "figures”</em> and does not reproduce §10.2’s table: 3,560 against "
          "3,550 at level 3, 153,000 against 150,000 at level 10. Within 2%, "
          "so the curve check passes; exact, it does not."
          "<br><br>And one claim in §31.9: F9 is listed as answered by "
          "<em>“generated hold rates re-measured on the aligned "
          "harness”</em>, while §13.2 says they were measured before it.",
     rec="Six one-line edits. None changes a rule."),

dict(id="D56", kind="deviation", severity="significant", status="done",
     title="sim/ and the harness run five rules v3.3 replaced",
     refs=["12.8", "12.6", "12.17", "10.3"],
     body="v3.3 changed rules this repository had already built. Brought "
          "across with the document: role Carry (104, 104, 300, 138, 104), "
          "revive health (30%), the fixture Vault in bag units (750, G15), "
          "and the Static Coil’s damage, which is now the document’s rather "
          "than a proposal. <strong>Not yet brought across</strong>:"
          "<br><br>· <strong>The ambush</strong> is a knockout keyed to the "
          "guard’s remaining health, with a 2-second takedown and a body a "
          "guard can find (§12.8). The simulation and the harness still "
          "triple Power with a half-health floor and a 2-second stun."
          "<br>· <strong>Cracking</strong> is a heard event: every hit heard "
          "within 5 m, and every five seconds every guard in the Heart starts "
          "Investigating (§12.6, §12.17). The simulation adds 100 suspicion."
          "<br>· <strong>Disarming</strong> is 15 seconds standing on the "
          "ward’s tile, restarting if the disarmer steps off (§10.3). The "
          "simulation takes 3 seconds plus one a level, kept for 5 seconds."
          "<br>· <strong>Lantern Glare</strong> triggers within 2 tiles "
          "(§10.3). The simulation triggers it on its own tile."
          "<br>· <strong>Crouching</strong> is half a role’s speed (§12.17, "
          "G13). The simulation already moved at half; the Python harness "
          "crouches at full speed and runs at double, so every harness "
          "measurement since F1 prices a crouched approach twice as fast "
          "as the document now does."
          "<br><br><code>tools/design_facts.py</code> now checks every fact "
          "it declares against the section it names, and reports these as "
          "behind the document under this item rather than as agreeing.",
     rec="Port the five rules to <code>sim/</code> and the harness, re-record "
         "the goldens, and re-measure what reads the ambush or the crouch."
         "<br><br><strong>Done.</strong> <code>sim/</code>: the takedown is "
         "two seconds and a knockout keyed to the guard's remaining health, "
         "landing only if the guard is still Unaware (§29.1 orders it: "
         "\u201ca knockout \u2026 after a 2 s takedown\u201d), and a build "
         "test runs all 25 role pairings; a body is seen as a still crew "
         "member lying on its tile, and can be dragged at crouching speed; "
         "five seconds of cracking send every guard in the Heart to "
         "investigate the Vault; disarming is fifteen seconds on the ward's "
         "tile and restarts when the disarmer steps off; Lantern Glare fires "
         "within 2 tiles. v3.3's new assist bonus is in too. The planned "
         "golden heist had to be replanned rather than retimed: it now takes "
         "four guards down from the moss behind them and cracks in under five "
         "seconds, so the noise never sounds. The harness crouches at half "
         "speed and hears the crack; it had imported v3.2's 100-suspicion "
         "crack noise and never applied it. <code>design_facts</code> now "
         "reads every declared fact back from its home section, and nothing "
         "is behind. Harness fingerprint 392187af \u2192 8e73e394. Hearing "
         "the crack turned out to decide nearly every raid the harness plays; "
         "that is F32.",
     measured="harness 8e73e394d1cdb9a0"),

dict(id="F32", kind="finding", severity="design", status="open",
     title="Five seconds of cracking calls every guard in the Heart to the "
           "crew, and no ordinary crack is shorter than five seconds",
     refs=["12.6", "12.17", "12.19", "13.2", "19.27"],
     body="§12.6 (v3.3): <em>\u201cevery 5 seconds of cracking every guard in "
          "the Heart hears the Vault and starts Investigating it\u201d</em>. "
          "§12.19: cracking a level-1 Vault takes 15 seconds for a Breaker alone "
          "and 8 for a full crew with the assist bonus. So the noise sounds "
          "before any ordinary Vault opens, and every guard in the Heart walks "
          "to the one place the crew has to stand for the next 10 seconds of "
          "loading.<br><br>With the rule ported (D56), the harness measures what "
          "that does. Same seeds, same crews, noise off against on:<br><br><code>"
          "optimal crew succeeds, realm 3, two realms        65.0% \u2192 7.5%<br>"
          "careless crew succeeds, the same                   0.0% \u2192 0.0%<br>"
          "held, realm 1, one post at level 5, three realms  43.6% \u2192 70.4%<br>"
          "held, realm 3, \u00a75.2's six wards, three realms   50.5% \u2192 78.0%<br>"
          "competent crew's banked fill, realm 3, no laws    21.5% \u2192 2.7%</code>"
          "<br><br>(On v3.2's wards, after D57's fixes; before them 42.0, 48.0 "
          "and 23.7% rose to 67.6, 80.0 and 4.0%.)"
          "<br><br>§19.27's depth gate asks the optimal crew to beat the careless "
          "one by 35 points. With the noise it beats it by 4 to 8 points at "
          "every depth from one realm to four (<code>python3 -m "
          "tools.heist_harness depth</code>, against 58 to 82 before; that was "
          "on v3.2's wards, and on v3.3's the report reads \u221220 to 0, F33), so the "
          "gate phases 2 and 3 exit on fails, and §13.2's bands are overshot "
          "by 20 to 50 points from realm level 2 up. And the economy stands on it: "
          "what an attempt is worth, grade times fill, falls from 0.137 to 0.027 "
          "for a crew stopping at 70% and from 0.170 to 0.044 for one that "
          "fills (<code>breakeven</code>, on v3.2's wards; on v3.3's, 0.003 "
          "and 0.005), where §9.6 publishes 0.122 to 0.170 "
          "\u2014 so §9.6's band, and the 35 to 49 days of upgrade pacing built "
          "on it (C36), are numbers for a game without the rule. v3.3's own hold table (§13.2, 34.4% at realm 3) "
          "reads like this harness without the noise, which suggests it was "
          "measured before the rule arrived \u2014 and at one guard post, F34 "
          "found.<br><br><strong>What this does not "
          "show.</strong> When this was found no harness crew took a guard down "
          "first (one does now; see below), and the "
          "harness prices a Vault at its realm level, so a realm-3 Vault holds "
          "4,500 and takes three times §12.19's example to crack. A crew that "
          "clears the Heart first is not caught this way: <code>sim/</code>'s "
          "planned heist takes four of five guards down from the moss behind "
          "them and cracks in 4.2 seconds with Brittle stone and the assist "
          "bonus, so the noise never sounds. So the rule does not make raiding "
          "impossible. It makes it a different game, in which the Heart is "
          "cleared before the Vault is touched, and nothing in §13.2, §19.27 or "
          "this harness has been measured for that game yet.",
     rec="Yours: decide whether the Heart is meant to be cleared before "
         "every crack. If it is, keep the rule, and the next build step is a "
         "harness crew that ambushes first \u2014 then §13.2's bands and "
         "§19.27's gates are re-measured against it. If it is not, the noise "
         "needs a reach (every hit is already heard within 5 m) or an interval "
         "a full crew beats at Vault level 1 (8 s, so 10 s would do), and "
         "either can be measured here with one constant."
         "<br><br><strong>The crew that clears first is built</strong> "
         "(T0.11). In the Heart alone at realm 3, with no wards, it succeeds "
         "65.0% of the time with the noise on against the optimal crew\u2019s "
         "20.0% (n=80), knocking out 1.27 of the two guards a raid, and a "
         "guard finds a body in about one raid in four; without the noise the "
         "two are level, 92.5% and 88.8%. So clearing the Heart is a game the "
         "rule leaves open, and it pays. On the full island with v3.3\u2019s "
         "wards it succeeds 8.3% against 1.7% (n=60): the Glares decide "
         "first (F33), so §13.2\u2019s bands cannot be re-measured against "
         "this crew until F33 is settled.",
     measured="harness 30af740ce1811dbd; test_the_crack_noise_decides_nearly_every_raid; "
              "test_a_crew_that_clears_the_heart_first_survives_the_crack_noise"),

dict(id="G16", kind="gap", severity="minor", status="open",
     title="A disarmer stands on the ward it is disarming, and nothing says "
           "whether the ward fires at it",
     refs=["10.3"],
     body="§10.3 (v3.3): the disarmer \u201cstands on the ward's tile for 15 "
          "seconds\u201d. Three of the four triggered wards fire on exactly "
          "that: Time Snare on its tile, Gravity Well within 3 tiles and "
          "Lantern Glare within 2. §10.3 does not say that disarming switches "
          "the sensor off, so read literally a Time Snare freezes its own "
          "disarmer, re-arms after 12 seconds and freezes it again \u2014 20 "
          "seconds for a 15-second job \u2014 and a Lantern Glare shows the "
          "crew to every guard in the realm the moment anyone steps up to "
          "disarm it. <code>sim/</code> takes that reading, says so, and pins "
          "it with a test.",
     rec="One sentence in §10.3: whether a ward's sensor ignores the crew "
         "member disarming it. If it does, the Glare stays disarmable; if it "
         "does not, say that the Glare can only be smashed.",
     measured="sim/: a_time_snare_freezes_its_own_disarmer_and_the_disarm_waits"),

dict(id="D57", kind="deviation", severity="significant", status="done",
     title="The harness ran v3.2\u2019s wards and budgets, and its crews stood "
           "still wherever a ward had no way round",
     refs=["10.3", "5.2", "10.2", "11.1", "13.3"],
     body="D56 ported v3.3\u2019s rules to <code>sim/</code> and the harness\u2019s "
          "crouch and crack. The harness\u2019s wards were still v3.2\u2019s: every "
          "ward fired on its own tile, disarmed in 3 s plus 1 s a level from "
          "beside it, reset in 10 s less one a level, and §5.2\u2019s budgets were "
          "<code>3 + realm level</code> wards and 1, 1, 2, 2 and 3 posts. v3.3 "
          "gives the Gravity Well a 3-tile sensor and the Lantern Glare a "
          "2-tile one, a 15-second disarm standing on the ward, resets of 10, "
          "12 and 20 s, a measured budget of 8, 8, 6, 7 and 8 wards and 1, 1, "
          "2, 3 and 3 posts, and a 25% assist bonus.<br><br>Porting them "
          "exposed two faults in the crews, both older than v3.3. <strong>A "
          "crew that found no way round a live ward stood in front of it</strong>: "
          "it recorded \u201cthrough\u201d, stopped for the tick, and asked "
          "again the next, counting a crew decision every other second while "
          "it did. <strong>A member beside a crossing realm\u2019s link "
          "re-planned to another tile beside it</strong>, and where the tiles "
          "between were covered the nearest was the long way round, so the "
          "crew was never beside the link at once. On-tile wards rarely left "
          "no way round; a Glare two tiles from a Vault always does, and with "
          "v3.3\u2019s sensors every raid on a wards-only realm ran out its "
          "clock in the first realm.<br><br>What the fixes moved on v3.2\u2019s "
          "wards, same seeds, 180 raids across realms 1, 3 and 5, three "
          "realms crossed: held 64.4% \u2192 68.3%, median crew decisions 21 "
          "\u2192 19. The decision count moved most where wards are dense: "
          "realm 1 on eleven wards went from 33 to 26 decisions (n=200). And "
          "what an attempt is worth at realm 3, stopping at 70%, fell from "
          "0.111 to 0.059 (n=300): standing still in front of a ward is also "
          "never walking into it, so the old crews were kept out of the "
          "Glares they could not go round, by the fault.<br><br>Walking "
          "through exposed a third: a crew stopped to crack wherever it first "
          "stood beside the Vault, so three members could stand on a Glare "
          "there and re-light it at every reset until the clock ran out. A "
          "crew that goes round wards now moves to a tile beside the Vault no "
          "ward reaches, where there is one.",
     rec="<strong>Done.</strong> The harness builds v3.3\u2019s wards and "
         "budgets by default, reading sensor reach and resets from "
         "<code>content/wards.json</code> and the budgets from "
         "<code>design_facts</code>, and plays the assist bonus. "
         "<code>generate(rules=\"v3.2\")</code> builds the islands every "
         "earlier ward and budget number was measured on, and the tests "
         "that pin another layer\u2019s finding use it, as they switch the "
         "crack noise off for F32 \u2014 because v3.3\u2019s Glares decide "
         "nearly every raid the generator\u2019s islands hold (F33). The two "
         "faults are fixed and pinned. Re-measured after the fixes (crack "
         "noise off, v3.2\u2019s wards): F22\u2019s cell 66.0% \u2192 70.0%; "
         "F26\u2019s realm 1 at one post and level 5, 42.0% \u2192 43.6%, "
         "and two posts 80.0% \u2192 81.2%; realm 3 on six wards 48.0% "
         "\u2192 50.5%, on ten 68.0% \u2192 74.5%; designed geometry "
         "about three times the generator\u2019s (F16). "
         "T0.11\u2019s crew that clears the Heart first is in as well "
         "(F32).",
     measured="harness 30af740ce1811dbd; test_a_crew_with_no_way_round_a_ward_walks_through_it"),

dict(id="F33", kind="finding", severity="design", status="open",
     title="One Lantern Glare outweighs a realm of other wards, so a ward "
           "count is not the dial §5.2 budgets",
     refs=["10.3", "5.2", "13.2", "13.3", "12.17"],
     body="§10.3: the Lantern Glare <em>\u201cshows the crew to every guard "
          "in the realm for 5 seconds\u201d</em>. At §12.17\u2019s near-zone "
          "fill that is every guard Alerted in half a second: the response "
          "layer, set off by a ward. §5.2 budgets wards by count and lets a "
          "Keeper choose the kinds. Measured with v3.3\u2019s rules (D57) at "
          "realm 3 on §5.2\u2019s two posts, one geometry band, three realms "
          "crossed, crack noise off, n=80 a cell:<br><br><code>"
          "wards &nbsp;&nbsp;Glares only &nbsp;&nbsp;no Glare &nbsp;&nbsp;the "
          "generator\u2019s mix<br>"
          "&nbsp;&nbsp;0 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;42.5% &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;42.5% &nbsp;&nbsp;&nbsp;42.5%<br>"
          "&nbsp;&nbsp;1 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;71.2% &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;41.2% &nbsp;&nbsp;&nbsp;41.2%<br>"
          "&nbsp;&nbsp;2 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;97.5% &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;43.8% &nbsp;&nbsp;&nbsp;43.8%<br>"
          "&nbsp;&nbsp;3 &nbsp;&nbsp;&nbsp;&nbsp;100.0% &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;67.5% &nbsp;&nbsp;&nbsp;92.5% "
          "&nbsp;the first Glare<br>"
          "&nbsp;&nbsp;6 &nbsp;&nbsp;&nbsp;&nbsp;100.0% &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;46.2% &nbsp;&nbsp;&nbsp;96.2% "
          "&nbsp;§5.2\u2019s budget<br>"
          "&nbsp;&nbsp;8 &nbsp;&nbsp;&nbsp;&nbsp;100.0% &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;96.2% &nbsp;&nbsp;100.0%</code>"
          "<br><br>Without a Glare, one to seven wards hold realm 3 at 41 to "
          "68%, not monotonically \u2014 six, §5.2\u2019s whole budget there, "
          "hold 46% \u2014 and only the eighth closes it; with one Glare the "
          "realm is at 71%, and with two it is shut. At realm 1 (one post) no "
          "Glare-free kit holds more than 26% at any count, and Glares alone "
          "reach 66%. v3.2\u2019s on-tile sensors show the same switch, a "
          "little weaker: one Glare 60.0%, two 88.8%. So the resolution F26 "
          "credited to the ward axis \u2014 two to four points a ward \u2014 "
          "was a Glare arriving every third ward in the generator\u2019s "
          "order. A defence budget counted in wards is a budget a Keeper "
          "spends on Glares.<br><br><strong>What this does not show.</strong> "
          "The harness\u2019s crews know where every ward is, and v3.3\u2019s "
          "are hidden until revealed or fired, so a real crew does worse; "
          "and the generator places wards along the shortest route, as "
          "§13.3 says, which is where a Glare\u2019s two tiles reach the "
          "most tiles a crew must cross.<br><br><strong>What it does to "
          "skill.</strong> At \u00a75.2's own settings, with the crack noise "
          "on, no harness crew succeeds more than one raid in seven at realm "
          "3, and the optimal crew does no better than the careless one "
          "whatever its answer to each kind \u2014 disarm, walk through, or go "
          "round: <code>python3 -m tools.heist_harness depth</code> reads "
          "\u00a719.27's skill gap at \u221220, \u221212, \u22122 and 0 "
          "points from one realm to four, against the 35 it asks for.",
     rec="Yours: the Glare is either budgeted apart \u2014 at most one a "
         "realm, or a cost that counts it as several wards \u2014 or made "
         "a dial: shown to the guards whose cones or hearing cover the spot "
         "rather than to every guard, or raising them to Investigating the "
         "spot rather than to Alerted. §13.2\u2019s build-blocking check "
         "(31.5) then has to run over the kits a Keeper can build, not only "
         "the counts, or it certifies a budget a Keeper can spend on a "
         "switch. Each option is one constant or one flag in the harness "
         "and can be measured before it is chosen.",
     measured="harness 30af740ce1811dbd; test_one_lantern_glare_outweighs_a_realm_of_other_wards"),

dict(id="F34", kind="finding", severity="significant", status="open",
     title="§13.2\u2019s hold table was measured at one guard post, and at "
           "§5.2\u2019s posts no realm from 3 up is near its band",
     refs=["13.2", "5.2", "10.2", "31.5"],
     body="§13.2 (v3.3) tabulates generated islands <em>\u201cat one geometry "
          "band and 5.2\u2019s wards and posts\u201d</em>: realm 3 on six wards "
          "and two posts holds 34.4%, realm 4 on seven and three 40.4% "
          "(<em>\u201cmeasured at two guard posts rather than 5.2\u2019s "
          "three\u201d</em>), realm 5 on eight and three 39.8%. Those are "
          "F26\u2019s per-realm numbers, and F26\u2019s sweep held the post "
          "count at one in every realm, with realms 4 and 5 two realms deep "
          "rather than three (<code>ward_budget.SETTINGS</code>). On the "
          "harness they were measured on, before v3.3 (crack noise off, "
          "v3.2\u2019s wards, n=200): realm 3 on one post 42.0% and on two "
          "86.0%; realm 4 on one post 38.0%, on two 85.0%, on three 94.0%; "
          "realm 5 on one post 39.5% and on three 96.0%. The table\u2019s "
          "holds are one-post holds; its posts column is §5.2\u2019s.<br><br>"
          "Re-run as the table states it, on this harness now (v3.3\u2019s "
          "wards and crouch, crack noise off, three realms, n=200):<br><br>"
          "<code>realm &nbsp;wards &nbsp;posts &nbsp;&nbsp;held &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;one post<br>"
          "&nbsp;&nbsp;1 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;8 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1 &nbsp;&nbsp;62.5% \u00b1 3.4 &nbsp;&nbsp;\u2014<br>"
          "&nbsp;&nbsp;2 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;8 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1 &nbsp;&nbsp;71.0% \u00b1 3.2 &nbsp;&nbsp;\u2014<br>"
          "&nbsp;&nbsp;3 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;6 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2 &nbsp;&nbsp;91.0% \u00b1 2.0 &nbsp;&nbsp;47.0%<br>"
          "&nbsp;&nbsp;4 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;7 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3 &nbsp;&nbsp;99.0% \u00b1 0.7 &nbsp;&nbsp;53.5%<br>"
          "&nbsp;&nbsp;5 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;8 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3 &nbsp;&nbsp;99.5% \u00b1 0.5 &nbsp;&nbsp;72.5%</code><br><br>"
          "No realm is inside its band, and from realm 3 up the defence "
          "holds nearly every raid. On v3.2\u2019s wards the same cells read "
          "56.0, 65.0, 94.5, 100 and 100%. With the crack noise on (F32) "
          "every number rises.",
     rec="Re-run §13.2\u2019s table at the posts §5.2 gives, which the "
         "aligned re-run §13.2 already schedules (32) can do in one pass, "
         "and state the depth each row was measured at. On this "
         "harness\u2019s numbers that re-run moves realms 3 to 5 far above "
         "30\u201345%, and §13.2\u2019s rule then moves their bands; before "
         "it does, F33 says why: the posts and the Glares multiply, and "
         "§5.2 budgets neither against the other.",
     measured="harness 30af740ce1811dbd; test_13_2s_hold_table_was_measured_at_one_guard_post"),

dict(id="G17", kind="gap", severity="minor", status="open",
     title="Four things a server needs to settle a raid that the document "
           "leaves open",
     refs=["9.6", "9.4", "24.12", "32.9"],
     body="Building §24.12's Validate and Grant (the server, T3.3) needs every "
          "term of what a raid settles as a number. Four are not stated:"
          "<br><br>\u00b7 <strong>Difficulty.</strong> §9.6: <em>\u201cLevel "
          "or above 1.0 to 1.2\u201d</em>. Nothing says where in the range a "
          "target above the raider falls, though §9.6's own per-raid cap "
          "(1.65 \u00d7 1.2 = 1.98) needs 1.2 to be reachable."
          "<br>\u00b7 <strong>What a haul is minted in.</strong> §9.6 gives one "
          "number. Only §32.9's measurement ledger says, deriving the birth "
          "curve from <em>\u201craid Essence at base 2,400 (half of each "
          "haul)\u201d</em>."
          "<br>\u00b7 <strong>A fee below its floor.</strong> §9.4: "
          "<em>\u201c2% of the raider's Starlight, from 100 to 25,000\u201d</em>. "
          "A raider holding less than 100 owes more than it has."
          "<br>\u00b7 <strong>The grace submission.</strong> §24.12: an expired "
          "lease gets <em>\u201cNo reward, with one grace submission "
          "allowed\u201d</em> \u2014 one per lease, per player, per day, or per "
          "season is not said.",
     rec="One clause each in §9.6, §9.4 and §24.12. The server takes, and names "
         "in <code>server/src/economy.mjs</code> and <code>service.mjs</code>: "
         "0.1 a Keeper level above, capped at 1.2; half of each haul Essence, "
         "the rest Starlight; a fee of whatever the raider holds, never a "
         "negative balance; and one expired submission honoured a day. Each is "
         "a one-line change once the document decides.",
     measured="server/test: economy.test.mjs, service.test.mjs"),

dict(id="D58", kind="deviation", severity="significant", status="done",
     title="The economy model mints raids from v3.2's base of 100, keyed to "
           "the raider, where v3.3 mints from 2,400 keyed to the target",
     refs=["9.6", "32.9"],
     body="§9.6 (v3.3): <em>\u201cB(V), the base \u2014 2,400 \u00d7 "
          "1.5<sup>(V\u22121)</sup> \u2026 V is the target's Vault level\u201d</em>, "
          "raised from 100 because <em>\u201cthe old base of 100 failed it at "
          "every level\u201d</em> of the raid-worth check. "
          "<code>tools/economy_model</code> still mints from 100, and keys the "
          "base with <code>Config.haul_level</code> from the raider's own "
          "Vault, realm or Keeper level. Every economy figure this repository "
          "publishes from the model \u2014 days to upgrade, the birth curve, "
          "what a heist is worth against a day's production \u2014 is therefore "
          "a v3.2 figure; §32.9's ledger, which does use 2,400, was not "
          "computed with this model. Found building the server (T3.3), which "
          "mints from the document's base.<br><br>Not silent any more: the "
          "document's base is <code>design_facts.HAUL_BASE</code>, read back "
          "from §9.6, and the model's is named <code>MODEL_HAUL_BASE</code> "
          "beside a pointer here, so the difference is visible where it is "
          "used.",
     rec="Port §9.6's B(V) to the model \u2014 the base from "
         "<code>design_facts</code>, keyed to the target's Vault level through "
         "the matchmaker's level spread (§12.22) \u2014 and re-run its checks, "
         "pacing and the raid-worth criterion first. Then compare the pacing it "
         "prints with §9.6's 46 to 64 days (v3.4; 35 to 49 in v3.3). v3.4 makes this the gate on C19: §32.9's one open command is the full re-run, and this is the model it runs."
         "<br><br><strong>Done.</strong> <code>Config.document()</code> mints "
         "from <code>design_facts.HAUL_BASE</code> and "
         "<code>ATTEMPT_BAND</code> (0.1222 and 0.1698, both read back from "
         "§9.6), with fatigue, and half of each haul in Essence (G17); an "
         "adversarial review reproduced the arithmetic exactly over 400 days at "
         "both edges. V is the raider\u2019s own Vault level, difficulty and "
         "richness 1.0: the \u201cclean same-level haul\u201d §9.6\u2019s table "
         "and raid-worth check are indexed by. That is the same arithmetic as the "
         "old raider-keyed reading, and it is §9.6\u2019s convention, not "
         "something §12.22 gives \u2014 §12.22 matches on Keeper level, so the "
         "matchmaker\u2019s spread this item\u2019s recommendation asked for has no "
         "Vault-level form to take. Porting found the transcription behind the "
         "text in three places, now read from <code>content/</code>: the Aether "
         "Spring stops at level 5, wards and posts are counted by realm level, "
         "and the Library is a building. The raid-worth check is "
         "<code>python3 -m tools.economy_model raidworth</code> (F36)."),

# Found reading v3.4

dict(id="C40", kind="contradiction", severity="minor", status="open",
     title="§31.3 makes four table-shaped facts constants, and its next "
           "sentence says they are guarded by recomputation instead",
     refs=["31.3", "10.4", "7.9"],
     body="§31.3 (v3.4) adds four rows to the constants table and says so: "
          "<em>\u201cand the rank split, the page costs, the load rate and the "
          "birth rate in version 3.4\u201d</em>. The paragraph\u2019s next "
          "sentence is v3.3\u2019s, unchanged: <em>\u201cThe facts the register "
          "recorded twice that are tables or curves rather than one figure "
          "\u2014 the rank split and page costs, the load rate, partial "
          "staffing, the birth curve and the notes each law carries \u2014 are "
          "guarded by recomputation instead (31.5)\u201d</em>. Three of the "
          "five it names are rows of the table above it.<br><br>And the "
          "table homes the rank split in §10.4, whose sentence cites §7.9 for "
          "it (<em>\u201c18 common, 12 uncommon, 12 rare and 6 deep laws, "
          "\u2026 (7.9)\u201d</em>); §7.9 is where the split is decided and "
          "tabulated.",
     rec="Two small edits, drafted: the second sentence keeps only what is "
         "still recomputed rather than pinned (partial staffing, the birth "
         "curve and the notes each law carries), and the rank split\u2019s "
         "home becomes §7.9."),

dict(id="G18", kind="gap", severity="minor", status="open",
     title="A ward ignores its disarmer only on its tile, so a Well or a "
           "Glare still fires on the walk there",
     refs=["10.3", "12.4"],
     body="§10.3 (v3.4, brief 37): <em>\u201cWhile it disarms, the ward\u2019s "
          "sensor ignores that crew member, so every known ward can be "
          "disarmed; it still fires on anyone else in reach.\u201d</em> The "
          "disarmer <em>\u201cstands on the ward's tile\u201d</em>. A Time "
          "Snare\u2019s sensor is its tile, so for it the sentence is whole. A "
          "Gravity Well senses <em>\u201cwithin 3 tiles\u201d</em> and a Lantern "
          "Glare <em>\u201cwithin 2\u201d</em>, so the walk to the tile crosses "
          "the sensor first, and nothing says it is ignored there: a Glare "
          "shows the crew to every guard before its disarmer arrives. Smashing "
          "has the same shape, from beside the ward. Read as written, "
          "<em>\u201cevery known ward can be disarmed\u201d</em> holds for one "
          "kind in three.<br><br>Both readings are built: <code>sim/</code> and "
          "the harness take the text (a test pins that a Glare fires on a "
          "disarmer walking in), and the harness takes the generous one as "
          "<code>disarm_approach=True</code>. On the balance numbers here it "
          "moves little, because going round beats a fifteen-second disarm "
          "anyway (D59): at realm 3 with the crack noise off the optimal crew "
          "succeeds 52.5% on the text and 40.0% on the generous reading, "
          "which disarms a Glare it cannot go round (n=40, inside the noise).",
     rec="One clause in §10.3, either way: the sensor ignores a crew member "
         "from when it starts toward a known ward to disarm it, stepping aside "
         "ending that; or a Glare and a Well can only be gone round or set "
         "off, and brief 37\u2019s <em>\u201cevery known ward\u201d</em> becomes "
         "<em>\u201ca known Time Snare\u201d</em>. The first is brief 37\u2019s "
         "stated intent.",
     measured="harness 4838533026da80b5; test_a_ward_ignores_its_disarmer_on_the_tile_and_not_on_the_way; "
              "sim: a_glare_still_fires_on_a_disarmer_walking_to_it"),

dict(id="D59", kind="deviation", severity="significant", status="done",
     title="The harness\u2019s optimal crew disarmed what v3.3 made a "
           "fifteen-second job, and played below the competent crew",
     refs=["10.3", "19.27", "12.6"],
     body="The optimal crew disarmed Time Snares and Gravity Wells and went "
          "round Glares. Those answers were set when a disarm took three "
          "seconds and one a level from beside the ward (v3.2), and D57 kept "
          "them for v3.3\u2019s fifteen seconds on the tile. At realm 3 with the "
          "crack noise off (n=40): the optimal crew succeeded 10.0% of the "
          "time, the competent crew 45.0%, and the same optimal crew going "
          "round every ward 52.5%. So every depth figure measured against the "
          "optimal crew on v3.3\u2019s wards \u2014 the <em>\u201c\u221220 to "
          "0\u201d</em> F32 and F33 quote \u2014 compared the careless crew with "
          "a crew playing below competent. F33\u2019s hold numbers are the "
          "competent crew\u2019s and do not move.",
     rec="<strong>Done.</strong> On a v3.4 island the optimal crew goes round "
         "every ward (<code>ward_answer_v34</code>), walking through one only "
         "where there is no way round; v3.3\u2019s answers are kept for v3.3 "
         "islands so D57\u2019s numbers reproduce. A test pins the 25-point "
         "difference. The same measurement is the case against a "
         "fifteen-second disarm on these islands, which is the design\u2019s to "
         "weigh: disarming exists for the ward with no way round it.",
     measured="harness 4838533026da80b5; test_the_optimal_crew_goes_round_what_takes_fifteen_seconds_to_disarm"),

dict(id="F35", kind="finding", severity="design", status="open",
     title="Brief 37\u2019s rule cannot size the crack\u2019s reach, and the 5 m "
           "v3.4 ships removes the depth it was meant to keep",
     refs=["12.6", "12.17", "32.9", "19.27", "13.2"],
     body="§32.9 (v3.4), brief 37: the reach is <em>\u201cthe smallest whole "
          "number of metres at which the optimal crew beats the careless one by "
          "at least 35 points and hold rates sit inside every realm level\u2019s "
          "band (13.2). If none up to the Heart\u2019s width does both, the whole "
          "Heart is called every 10 seconds with a countdown on the Vault; if "
          "that fails, the timed call is deleted.\u201d</em> §12.17 ships 5 m, "
          "<em>\u201cthe per-hit distance, which the harness measured as the "
          "noise-off case (the optimal crew beats the careless one by 58 to 82 "
          "points)\u201d</em>.<br><br>Built and run as written "
          "(<code>python3 -m tools.heist_harness depth --sweep crack_reach</code>, "
          "n=40 a cell, every reach from 1 m to the Heart\u2019s 12, then both "
          "whole-Heart calls): <strong>no setting passes either test, including "
          "no call at all.</strong> With no call the optimal crew leads by +44 "
          "points in one realm and +12, +5 and +2 across two to four, and realm "
          "levels 1 to 5 hold 72, 78, 92, 100 and 100% against bands of 25\u201340 "
          "and 30\u201345. So the rule ends at <em>\u201cthe timed call is "
          "deleted\u201d</em> on evidence that says nothing about the call: the "
          "holds are F33\u2019s and F34\u2019s, and the multi-realm depth fails "
          "before the crack is considered.<br><br>Read against the no-call "
          "baseline instead, which is the question brief 37 asks, the call "
          "costs depth at every metre. Re-run at n=200, realm 3:<br><br>"
          "<code>call &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;optimal &nbsp;careless &nbsp;lead, 1 realm &nbsp;lead, 2 &nbsp;ambush-first<br>"
          "none &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;50.0% &nbsp;&nbsp;&nbsp;8.0% &nbsp;&nbsp;&nbsp;+42.0 \u00b1 4.0 &nbsp;&nbsp;&nbsp;+24.5 &nbsp;&nbsp;45.0%<br>"
          "3 m &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;22.5% &nbsp;&nbsp;&nbsp;7.0% &nbsp;&nbsp;&nbsp;+15.5 \u00b1 3.5 &nbsp;&nbsp;&nbsp;+11.0 &nbsp;&nbsp;24.0%<br>"
          "5 m (v3.4) &nbsp;14.5% &nbsp;&nbsp;10.5% &nbsp;&nbsp;&nbsp;&nbsp;+4.0 \u00b1 3.3 &nbsp;&nbsp;&nbsp;&nbsp;+3.0 &nbsp;&nbsp;16.0%<br>"
          "Heart, 5 s &nbsp;&nbsp;6.0% &nbsp;&nbsp;11.5% &nbsp;&nbsp;&nbsp;\u22125.5 \u00b1 2.9 &nbsp;&nbsp;&nbsp;\u22123.0 &nbsp;&nbsp;11.5%</code><br><br>"
          "The 5 m call costs the optimal crew 38 points of lead against no "
          "call (t \u2248 7). It is better than v3.3\u2019s whole Heart, and it does "
          "not keep the depth.<br><br><strong>Why v3.4 expected otherwise.</strong> "
          "The 58 to 82 it cites was measured on v3.2\u2019s wards, on a harness "
          "with no hearing at all: the crack was either the whole-Heart call or "
          "silent, and every hit was silent. The design hears every hit within "
          "5 m (§12.17, and <code>sim/</code> models it), so the design\u2019s "
          "no-call case is this harness\u2019s 5 m row, not its first. A crew "
          "cracking beside a Vault is heard by any guard whose route passes "
          "within 5 m of it, and on these islands the Heart\u2019s posts do. "
          "The harness\u2019s missing per-hit hearing makes its no-call row kinder "
          "than the design, which is why it is the baseline and not the target. "
          "And the brief\u2019s ambush-first crew, the one F32 found the "
          "whole-Heart call rewarded, is worse off at every reach than with no "
          "call, because it too cracks in earshot of any guard it has not "
          "reached.",
     rec="Yours, in two parts. <strong>The rule:</strong> the reach cannot be "
         "sized against §13.2\u2019s hold bands while F33 and F34 put every realm "
         "level above them with no call at all; either settle those first, or "
         "size the reach against the no-call baseline alone (the largest reach "
         "whose depth loss is inside the noise), which on these numbers is under "
         "3 m. <strong>The premise:</strong> 5 m is the per-hit distance, so "
         "any reach up to 5 m adds almost nothing to what §12.17 already "
         "makes heard, and the choice brief 37 made is really about whether a "
         "hit on the Vault is heard at 5 m. If it is, depth at the Vault has "
         "to come from somewhere else \u2014 a quieter crack for a crew "
         "working together, or a Vault guarded from further off. The sweep "
         "re-runs in five minutes once any of it moves.",
     measured="harness 4838533026da80b5; depth --sweep crack_reach (n=40); n=200 re-run of the four rows; "
              "test_every_metre_of_the_cracks_reach_costs_the_optimal_crew_depth"),

# Found running the full re-run (T2.6)

dict(id="F36", kind="finding", severity="significant", status="open",
     title="Run on the model\u2019s roster, the raid-worth check fails 2,400, "
           "and the base it needs depends on choices the document does not make",
     refs=["9.6", "32.9", "10.2", "14.1", "9.2"],
     body="§9.6: <em>\u201cat every Vault level, an average attempt pays at "
          "least what the same characters would have produced working over the "
          "heist and its rest\u201d</em>, and §32.9 hands the re-check to the "
          "economy model: <em>\u201cif an attempt fails at any level, the base "
          "rises until it passes\u201d</em>. The document\u2019s own derivation is "
          "sound on its own terms: \u201cabout 109 an hour a worker\u201d is the "
          "three level-3 producers\u2019 mean, (146 + 109 + 73) / 3, and at a "
          "crew of four 2,400 passes by a hair where 2,300 fails.<br><br>Run on "
          "the roster the model actually staffs "
          "(<code>python3 -m tools.economy_model raidworth</code>), 2,400 fails "
          "at Vault levels 1 and 2: the smallest passing hundred is 2,900 on the "
          "day each level arrives and 4,600 on every day at a level, binding at "
          "Vault level 1 (0.52\u00d7 on day 15), because the player opens realms "
          "and grows producers before the Vault. An adversarial review showed "
          "both numbers move with choices §14.1 does not make: which producer a "
          "worker staffs, when the Vault is bought, whether posts are staffed, "
          "and whether the crew\u2019s cost is an average or a margin. Under the "
          "alternatives the first re-run tried, the base came out anywhere from "
          "2,500 to 3,700. Every one of them fails 2,400, so the direction holds "
          "and the value does not.",
     rec="Say what the check is computed against: which roster (the one §10.2\u2019s "
         "build days imply, or the one the model staffs), which staffing order, "
         "and whether a posted guard counts as working. Until then the re-run "
         "publishes at 2,400 and prints the alternatives beside it; §32.9\u2019s "
         "rule cannot set a value while its inputs are choices.",
     measured="test_finding_on_this_models_roster_the_raid_worth_check_fails_2400; "
              "test_the_documents_own_raid_worth_arithmetic_sets_2400"),

dict(id="F37", kind="finding", severity="design", status="open",
     title="A player who never raids stops levelling below Keeper 12, so never "
           "reaches the full Codex §14.4 prices for them",
     refs=["14.4", "14.2", "10.4", "13.3", "7.6", "12.10"],
     body="§14.4: <em>\u201cA player who never raids earns the Library alone, "
          "which is the floor the whole design rests on (13.3)\u201d</em> \u2014 "
          "about 195 days to the full Codex, 80 to the launch 24. §14.2 gives "
          "Keeper experience four sources: successful heists, foiled heists, "
          "spending (1 for every 40 Starlight) and restoring laws. A player who "
          "never raids has the last two, and both are gated: spending by the "
          "Spire, whose levels need Keeper levels, and restoring by pages, which "
          "\u2014 on §14.4\u2019s premise \u2014 come from a Library that opens at "
          "Keeper 4 and needs Keeper 10 and Spire 3 for the 6 a day §14.4 "
          "averages. So the player plateaus. Where depends on things the "
          "document leaves open: the Library alone gives Keeper 1 or 2 (on "
          "whether the Lab, Observatory and Beacon come built); the tutorial\u2019s "
          "two Drifting-ruin heists, if ruins pay §14.2\u2019s heist experience, "
          "give Keeper 10; any page trickle of about 2 a day, Keeper 8. Every "
          "reading stays below Keeper 12, where chapter 3 opens, so the full "
          "Codex (Keeper 24) is never reached and §14.4\u2019s 195 days cannot "
          "be.<br><br>And §14.4\u2019s arithmetic fails a second way. §10.4\u2019s "
          "Library gives pages only for schools the player already has laws in, "
          "which reaches 12 of the launch 24 and 24 of the 48 \u2014 so the 80 "
          "and 195 days fail on schools as well as on experience. The document "
          "also lists page sources a non-raider can reach (the Lab, daily goals, "
          "the free season track, friendly heists), which §14.4\u2019s "
          "\u201cthe Library alone\u201d excludes.",
     rec="Decide where a non-raider\u2019s experience comes from: say that a "
         "foiled heist\u2019s experience is the defender\u2019s and give the rate an "
         "island is raided at; say whether ruin heists (the tutorial\u2019s "
         "included) pay §14.2\u2019s heist experience; and say whether an empty "
         "Lab pairing can be re-run for pages. Then recompute §14.4\u2019s "
         "never-raids figures with §10.4\u2019s school rule and the Keeper gates "
         "on the Library and the Codex.",
     measured="test_finding_a_player_who_never_raids_stops_levelling"),

dict(id="G19", kind="gap", severity="minor", status="open",
     title="Wards and guard posts are counted by realm level, and the Heart "
           "has no realm level",
     refs=["5.2", "10.2", "13.2"],
     body="§10.2: the Ward is <em>\u201cEvery realm; 8, 8, 6, 7 and 8 by "
          "realm level\u201d</em> and the Guardian Post <em>\u201cEvery realm; "
          "1, 1, 2, 3 and 3 by realm level\u201d</em>. §5.2 gives the Heart two "
          "law slots, its own terrain budget and four link sockets, and no "
          "realm level, so neither count covers it. The economy model gives "
          "the Heart level 1\u2019s counts, eight wards and one post, as it did "
          "before v3.4; level 5\u2019s moves no re-run milestone by more than "
          "two days. What the Heart can hold matters more to its defence than "
          "to its economy.",
     rec="One clause in each row: the Heart\u2019s own count, or the realm "
         "level it counts as."),

dict(id="G20", kind="gap", severity="significant", status="open",
     title="§9.6\u2019s day and week caps do not say whose base they are in, "
           "or what \u201cfive days\u2019 worth\u201d is five days of",
     refs=["9.6", "24.12"],
     body="§9.6: <em>\u201cPer day: the fatigue curve, plus a hard ceiling half "
          "again above it for players punching up. Per week: five days\u2019 "
          "worth, not seven\u201d</em>. Enforcing them (the server, "
          "<code>capHaul</code>) needs three things the sentence leaves out. "
          "The fatigue curve is in B(V), and V is the <em>target\u2019s</em> "
          "Vault level, which changes raid to raid; a day\u2019s ceiling needs "
          "one base. <em>\u201cFive days\u2019 worth\u201d</em> is five days of "
          "either the curve or the ceiling, and only the curve makes "
          "<em>\u201cgrinding every day gains little\u201d</em> true: at five "
          "of the ceiling, a player raiding every day at the curve never meets "
          "the week\u2019s cap. And nothing says when a week starts.",
     rec="Say which unit each cap is in. The server reads the ceilings in the "
         "raider\u2019s own Vault level\u2019s base, the week as five days of the "
         "whole fatigue curve, and the week from Monday, UTC. An adversarial "
         "review showed that under that reading no player §14.1 models reaches "
         "either cap (four raids are 3.19 first raids, the curve is 6.67), so "
         "<em>\u201cmissing two days a week costs nothing\u201d</em> is false for "
         "them: two days missed cost two sevenths. §9.6\u2019s own \u201cA full "
         "day, four raids\u201d column would make it true, but in that unit the "
         "day\u2019s ceiling would cap a single clean raid.",
     measured="server/test: economy.test.mjs (the three caps; five days against "
              "seven), service.test.mjs (a haul capped by the day)"),

dict(id="G21", kind="gap", severity="minor", status="open",
     title="§24.8\u2019s target lists are \u201cper difficulty band\u201d and "
           "\u201cgenerated periodically\u201d, and neither is defined",
     refs=["24.8", "12.22", "13.2"],
     body="§24.8: <em>\u201cTarget selection is a file, not a query. Candidate "
          "lists per difficulty band are generated periodically as static "
          "objects\u201d</em>. §12.22 filters by Renown, Keeper level, a "
          "Glicko-2 difficulty rating and depth, and draws the middle of the "
          "list <em>\u201cfrom the raider-success band for the target\u2019s realm "
          "level\u201d</em>, but never says which of those a list is cut by; and "
          "how often a list is regenerated decides how long a republished island "
          "stays a target. The server (<code>Service.targetLists</code>) cuts a "
          "list per realm level, the unit of §12.22\u2019s guarantee, with each "
          "entry\u2019s rating on it so the device can filter by rating itself, "
          "and regenerates every fifteen minutes; each list is "
          "content-addressed, so an unchanged band keeps its edge cache.",
     rec="One sentence in §24.8: what a band is (the realm level, or a rating "
         "band inside it) and how often the lists are rebuilt. The review of the "
         "server found three faults in how this build does it, now fixed: a band "
         "every island had left kept serving its last list; two players who "
         "publish the same bytes share one snapshot, so the list named the first "
         "owner twice and the second could lease their own island; and a lease "
         "on a superseded snapshot was granted, letting a raider pick an older, "
         "richer version.",
     measured="server/test: service.test.mjs (target lists)"),

# Found by the adversarial review of the full re-run (T2.6)

dict(id="F38", kind="finding", severity="significant", status="open",
     title="Strays fill the roster as fast as homes are built, so §9.5\u2019s rule "
           "has no birth rate to set",
     refs=["9.5", "11.5", "18.2", "14.3", "32.9"],
     body="§9.5: <em>\u201cThe growth rate in the birth row is the one at which "
          "an engaged player\u2019s 38th character arrives on the day every "
          "building reaches its top level\u201d</em>. §11.5: <em>\u201cAbout one "
          "heist in eight finds a stray in the target universe; carrying it out "
          "adds it to the roster\u201d</em>; §18.2\u2019s free season track "
          "<em>\u201cgives pages, Essence and a stray\u201d</em>. An engaged player "
          "carries out about 0.3 strays a day, more than enough to fill each "
          "home as it is built. In the re-run the 38th character arrives on day "
          "244\u2013249 \u2014 with the last Hearth level \u2014 at a birth rate of "
          "1.3265 and at 5.0 alike, while every building tops out on day "
          "699\u2013719. No rate moves the 38th, so the rule cannot be met. Left "
          "without strays the rule sets 1.3455 and the 38th arrives on day 548. "
          "§9.5\u2019s own derivation of the shipped rate prices every character "
          "as a birth, which is the model it was derived on.",
     rec="Either tune the birth rate against the roster net of strays (births "
         "are then a small share of the roster, and the rate matters little), or "
         "make strays wait for an empty Nursery slot rather than a free home, or "
         "state the horizon for the roster rather than for its births. The last "
         "is one sentence: the roster fills around day 250 for an engaged "
         "player, and births matter for the characters strays do not bring.",
     measured="test_finding_strays_fill_the_roster_whatever_a_birth_costs"),

dict(id="F39", kind="finding", severity="significant", status="open",
     title="The entry fee is charged on what a player holds, so a player saving "
           "for the Spire as §14.1 says pays more in fees than raids bring",
     refs=["9.4", "14.1", "9.6", "10.2"],
     body="§9.4: <em>\u201cEntry fee: 2% of the raider\u2019s Starlight, from 100 "
          "to 25,000, returned in full after a clean heist\u201d</em>. §14.1\u2019s "
          "player <em>\u201csave[s] for the next Spire level first\u201d</em>, and "
          "the late Spire levels cost 250,000 to 1.2 million. In the re-run an "
          "engaged player on day 301 holds about 706,000 Starlight, so each "
          "raid\u2019s fee is about 14,000, kept unless the heist is clean "
          "\u2014 about 44,600 a day \u2014 while the raids bring about 5,300 "
          "Starlight. Raiding while saving loses money eightfold. Left out, the "
          "fee would put Keeper 40 on day 318 rather than 357 and everything "
          "built on day 611 rather than 719. §9.6\u2019s raid-worth check does "
          "not count the fee at all.",
     rec="Key the fee to something a saver does not pile up \u2014 the raider\u2019s "
         "production, or B(V) at the target\u2019s level \u2014 or cap it far "
         "below 25,000, or exempt Starlight set aside for the Spire. Then add the "
         "fee to the raid-worth check, which prices a raid against staying "
         "home and today leaves the fee out of the raid.",
     measured="test_finding_the_entry_fee_outweighs_what_raids_pay_while_saving"),

dict(id="C41", kind="contradiction", severity="minor", status="open",
     title="§9.4 returns the entry fee after a clean heist only; §12.9 returns "
           "it after a loud one and half after a partial",
     refs=["9.4", "12.9"],
     body="§9.4: <em>\u201creturned in full after a clean heist\u201d</em>. "
          "§12.9\u2019s outcome table returns it after a loud heist as well and "
          "half of it after a partial. The server and the economy model take "
          "§9.4; under §12.9 an engaged player keeps about half as much of it "
          "(F39\u2019s losses roughly halve).",
     rec="One home for the fee\u2019s return, and the other section cites it."),

dict(id="C42", kind="contradiction", severity="minor", status="open",
     title="§11.5 finds a stray on one heist in eight; §14.6 gives one heist in "
           "eight a stray or a bonus page",
     refs=["11.5", "14.6"],
     body="§11.5: <em>\u201cAbout one heist in eight finds a stray\u201d</em>. "
          "§14.6: <em>\u201cany heist has about a one-in-eight chance of a stray "
          "or a bonus page\u201d</em>, which makes a stray rarer than one in "
          "eight. The re-run takes §11.5; at one in sixteen nothing it publishes "
          "moves, because homes, not strays, limit the roster (F38).",
     rec="One rate, in one place."),

dict(id="G22", kind="gap", severity="significant", status="open",
     title="§14.1 names neither a staffing order nor a realm order, and each "
           "moves the regenerated tables by months",
     refs=["14.1", "9.2", "5.2", "13.2", "14.2"],
     body="§14.1 lists what the economy model assumes, and §14.2 says the "
          "tables are its output. The adversarial review of the re-run found "
          "three things the tables turn on that §14.1 never states. Which "
          "producer a new worker staffs: §9.2 says <em>\u201cchoosing which "
          "producer goes short is the decision\u201d</em>; filling the Heart "
          "first puts Keeper 40 on day 357, one worker to each producer in turn "
          "on day 424. Which realm types open first: §5.2 leaves it to the "
          "player; across all 90 orders Keeper 40 falls between day 337 and 385 "
          "and everything built between 667 and 788 (Starlight realms first is "
          "fastest). And whether posts are staffed: §13.2\u2019s posts "
          "<em>\u201chold stability only while staffed\u201d</em>, and one "
          "ruleborn at every post built pushes Keeper 40 past day 1,100. "
          "<code>docs/design/generated/pacing.md</code> prints each.",
     rec="Add the model\u2019s choices to §14.1\u2019s list, as sentences: how "
         "workers are assigned, which realm types open first, and whether posts "
         "are staffed. Each is a design position, not a model detail, since the "
         "published tables are its consequence."),

dict(id="D60", kind="deviation", severity="significant", status="open",
     title="The server takes a bundle\u2019s Vault level and exposed loot on the "
           "client\u2019s word",
     refs=["24.12", "9.6", "24.8"],
     body="A published island is a bundle the simulation checks against §5.2 "
          "and §6.1 \u2014 terrain, wards, posts, laws \u2014 but its Vault level "
          "and exposed amount are two bytes the client writes. The target\u2019s "
          "B(V) and richness come from them, and so do the raider\u2019s day and "
          "week ceilings (G20). Until the server holds each player\u2019s "
          "buildings and currencies, a client can publish a Vault level it has "
          "not bought. Found reviewing the server\u2019s caps.",
     rec="When the economy moves server-side, derive both from the player\u2019s "
         "own ledger and buildings, and refuse a bundle that disagrees. Until "
         "then it is a known limit of this build, not of the design."),

dict(id="G23", kind="gap", severity="significant", status="open",
     title="Nine launch laws leave the simulation a rule to choose, and the "
           "choice is the rule every replay is checked by",
     refs=["7.4", "7.3", "7.10", "11.2", "12.21", "24.7"],
     body="v3.4 makes every launch law a row on §7.3\u2019s sheet, and "
          "<code>sim/</code> now applies all 24. Building them needed a "
          "reading wherever a sheet\u2019s sentence stops short, and because the "
          "server re-simulates every heist, each reading is the rule. "
          "<strong>Frictionless</strong>: <em>\u201canything moving keeps "
          "sliding\u201d</em>, but its +20% is crew speed; the crew slides, "
          "guards do not, a Halt still stops, and the realm\u2019s edge ends a "
          "slide. <strong>Bounce</strong>: <em>\u201cincluding "
          "characters\u201d</em>, yet nothing walks into a wall except a slide, "
          "and a slide needs Frictionless, which with Bounce is always Pinball "
          "\u2014 so a character\u2019s rebound is Pinball\u2019s, off every wall, "
          "and Bounce alone only returns half a blow on a ward to the striker; "
          "Wardens absorb both. "
          "<strong>Density</strong>: size is a ruleborn\u2019s (§11.2) and the "
          "crew and guards are roles, so the Warden is large, the rest standard "
          "and nobody small. <strong>Delay</strong>: <em>\u201cwards and "
          "abilities\u201d</em> \u2014 no abilities exist yet, and "
          "<em>\u201cyour own guards react late too\u201d</em> names no rule, so "
          "guards react on time. <strong>Aurora</strong>: how deep a band is "
          "and how many cross at once are not given; one band two rows deep "
          "crosses north to south each period. <strong>Chain "
          "lightning</strong>: <em>\u201ca second target\u201d</em> is read as "
          "the nearest on the struck one\u2019s side; a jump does not jump "
          "again, and a blow on a structure does not jump. "
          "<strong>Static</strong>: a touch is sharing a tile or a side; one "
          "charge stuns the nearest one touched, ally or not. "
          "<strong>Echoes</strong>: the return is at once, where it fell, loot "
          "already dropped. <strong>Soul swap</strong>: once per character, as "
          "every Revival source is; the one who swaps takes none of the blow; "
          "only a hit sets it off, not a ward. <strong>Thorns</strong>: a "
          "touch is standing on or beside a wall or a live hedge, charged once "
          "a second; the Vault and pylons are structures, not walls. Found "
          "building the launch set; each is named in <code>sim/src/lib.rs</code> "
          "beside the rule it chose and held by a test.",
     rec="Write each reading, or its replacement, into the law\u2019s sheet in "
         "§7.4 as the rule, in the sheet\u2019s own words. §24.7 re-simulates "
         "heists on the server, so a sentence a player reads and a rule the "
         "server applies cannot be allowed to differ; a sheet that stops short "
         "is a rule the build writes instead of the designer."),

dict(id="G25", kind="gap", severity="significant", status="open",
     title="§8\u2019s thirty-six launch combinations are one line each, and "
           "the simulation had to finish most of them",
     refs=["8.2", "8.3", "8.4", "8.5", "8.7", "24.7"],
     body="<code>sim/</code> now plays every harmony, dissonance and chord and "
          "the twelve signature resonances that ship at launch, each worked out "
          "each tick from the laws whose pylons stand. Almost every row needed "
          "a reading, and each is the rule the server replays. "
          "<strong>Harmonies</strong>: <em>\u201c25% stronger\u201d</em> is read "
          "as the change made a quarter larger (Haste\u2019s 1.25 becomes "
          "1.3125), on the parameters the two harmonising laws themselves set, "
          "once a note; Glow\u2019s <em>\u201c2 tiles longer\u201d</em> can only "
          "lengthen Aurora\u2019s band, the one light a launch law has; Hush\u2019s "
          "<em>\u201c1 tile closer\u201d</em> treats whoever is looked at as a "
          "tile further off; and Veil lengthens nothing, because neither launch "
          "Veil law, Delay or Soul swap, is an illusion or a disguise. "
          "<strong>Dissonances</strong>: <em>\u201c±20% at random\u201d</em> and "
          "<em>\u201cbright or dark\u201d</em> are read as a coin each time; "
          "Wildfire\u2019s <em>\u201cany spark effect\u201d</em> as a chain\u2019s "
          "jump, a static stun or a Brittle-stone hit on a hedge, and its hurt, "
          "unstated, as 5% a second; déjà vu\u2019s <em>\u201conce per "
          "heist\u201d</em> as a random second in the minute after it first "
          "sounds. <strong>Resonances</strong>: a bank is a tile beside water; "
          "Night runners\u2019 darkness is the whole realm, since Glowing dark "
          "makes it dark; Storm grid\u2019s three targets jump each from the last "
          "at the jump\u2019s share of the hit; Briar maze grows the extra hedge "
          "on the first bare side; Shattered glass\u2019s glass wall is the "
          "Crystal Wall, the one wall that breaks; Honey trap sticks on stepping "
          "beside a regrown hedge; Cracked gardens\u2019 Essence has no amount, so "
          "only the count is kept. <strong>Chords</strong>: Deep sleep\u2019s "
          "doze is a stun and its muffling a step less; Ghost tide\u2019s drift "
          "ends on the landing tile at the revive health; Fair lights has no "
          "cadence, so it takes its neighbours\u2019 twenty seconds; Mirage shows "
          "a moving character on the tile it just left; Clockwork fires every "
          "triggered ward whoever is near it; Hidden garden spreads to every "
          "bare tile beside grass; Quicksand\u2019s <em>\u201ca few\u201d</em> is "
          "three and a pit costs a landing\u2019s noise and a second; Rebound "
          "bounces within a chain\u2019s three tiles; and Lantern festival\u2019s "
          "lanterns do not exist without Soul lanterns, which is not a launch "
          "law, so only its return plays. The figures that are readings are "
          "listed by <code>sim/content_gate.py</code>; every rule is named "
          "beside its code and held by a test.",
     rec="Give each §8 row its rule in the row: what is strengthened and by "
         "how much, what a random draw draws, what an unstated amount is, and "
         "what an effect needs that the launch set lacks (lanterns, a Veil "
         "illusion). §8.7 fixes the order effects apply in, which only helps "
         "once each effect is a rule rather than a sentence."),

dict(id="D61", kind="deviation", severity="minor", status="open",
     title="The simulation sounds a chord without asking whether the universe "
           "can pay its draw, and plays no crown laws",
     refs=["8.5", "8.6", "5.1", "24.8"],
     body="§8.6: a chord <em>\u201csounds whenever three distinct laws in one "
          "realm carry its notes and the universe can pay its draw\u201d</em>. "
          "The draw is the universe\u2019s stability, which the server does not "
          "hold yet (D60), so an island bundle with three laws that make a chord "
          "plays it. And <em>\u201ccrown laws count in every realm\u201d</em> "
          "(§8.2), but a bundle carries only its realm\u2019s own laws, so a "
          "harmony or a chord made with a crown law is not played. Found "
          "building §8\u2019s combinations.",
     rec="When the economy moves server-side, check a published realm\u2019s "
         "chords against its universe\u2019s stability, and carry the crown laws "
         "in the bundle (or beside it) so the realm plays what its owner wove. "
         "Until then it is a limit of this build, not of the design."),

dict(id="G26", kind="gap", severity="significant", status="open",
     title="§18.6 and §20.12 describe the Workshop\u2019s rules without the "
           "figures and lists a server has to enforce them by",
     refs=["18.6", "18.7", "20.4", "20.7", "20.12"],
     body="The server now runs the Workshop: publish, browse, play, rate, "
          "report, moderate and remix. Each needed something the document "
          "names and does not give. <em>\u201cIsland names come from word "
          "lists\u201d</em> \u2014 no lists, so the server carries sixteen "
          "adjectives and sixteen nouns in both launch languages. "
          "<em>\u201cBetween five and ten published islands per account\u201d</em> "
          "with <em>\u201c3 extra island slots\u201d</em> for a Builder \u2014 read as "
          "five, and eight for a Builder. <em>\u201ca storage quota per "
          "account\u201d</em> with no size \u2014 64 KiB, counting everything ever "
          "published, since nothing is deleted. <em>\u201ccleared by its "
          "creator\u201d</em> \u2014 read as a heist that banks loot, every grade "
          "but foiled. <em>\u201cevery island can be reported\u201d</em>, for no "
          "stated reasons \u2014 five. <em>\u201csudden spikes are reviewed by a "
          "person\u201d</em>, with no measure of sudden \u2014 a day of fifty "
          "completions or more, above five times the week before\u2019s daily "
          "mean. And a remix names its original, which §18.7 neither credits nor "
          "rules out. Each figure is a named constant in "
          "<code>server/src/workshop.mjs</code>, and each rule a test.",
     rec="State the word lists (or where they live), the slot count and quota, "
         "what clearing an island means, the report reasons, what counts as a "
         "spike, and whether a remix earns its original anything."),

dict(id="D62", kind="deviation", severity="significant", status="open",
     title="The Workshop publishes without the authored hold-band check, and "
           "pays no Island Fund",
     refs=["13.2", "18.6", "18.7", "18.9", "20.5"],
     body="Two of the Workshop\u2019s rules wait on systems this build does not "
          "have. §18.7: <em>\u201cA published island is checked against the "
          "authored hold band before the Workshop lets it out\u201d</em> \u2014 a "
          "hold rate is measured over hundreds of raids (13.4), which only the "
          "harness can run, and not per publish; the server checks the rules "
          "and the creator\u2019s clear. §18.9\u2019s Island Fund needs revenue "
          "and the stores. And the age band a player browses by is declared, not "
          "verified, as §20.5\u2019s neutral gate allows. Found building the "
          "Workshop. <em>\u201ccompletions from a creator's own constellation "
          "count at a quarter\u201d</em> was a third, until constellations were "
          "built: a completion by a player in the creator\u2019s constellation "
          "now counts at a quarter.",
     rec="Run the hold-band measurement when an island is submitted (a queue, "
         "not the request), and build the fund with purchases. Until then these "
         "are limits of this build."),

dict(id="C43", kind="contradiction", severity="minor", status="open",
     title="§18.6 gives every island a word-list name; §20.7 gives one only to "
           "players aged 13 to 15",
     refs=["18.6", "20.7", "20.4"],
     body="§18.6: <em>\u201cisland names come from word lists\u201d</em>, for "
          "everyone. §20.7\u2019s table: publishing is <em>\u201cYes, names from "
          "word lists\u201d</em> for 13 to 15 and a plain <em>\u201cYes\u201d</em> "
          "for 16 and over, which reads as free names for older players \u2014 "
          "and §20.4\u2019s word filter covers chat, player names and "
          "constellation names, not island names. The server takes §18.6: every "
          "name is from the lists, so none needs filtering.",
     rec="One rule. If older players may type names, add island names to "
         "§20.4\u2019s filter and the 24-hour review; if not, §20.7\u2019s row "
         "says word lists for everyone."),

dict(id="F40", kind="finding", severity="significant", status="open",
     title="Renown only moves between players, so the leagues rest on what the "
           "floors mint, and §14.7\u2019s arrival times and shares cannot both "
           "hold",
     refs=["12.9", "14.7", "18.1", "14.1", "14.5"],
     body="§12.9: <em>\u201cThe defender gains or loses the mirror "
          "amount\u201d</em>. A raid adds to the raider what it takes from the "
          "defender, and a foiled one the reverse, so no raid makes Renown; the "
          "only Renown in the game is what §18.1\u2019s floors mint, when a "
          "defender at Dust\u2019s or Ember\u2019s floor cannot lose and the "
          "raider gains anyway. <code>tools/league_model.py</code> plays the rules "
          "forward over four seasons, with §14.1\u2019s three kinds of player and "
          "§14.5\u2019s success arc. Fitted to §14.7\u2019s season-end shares, "
          "the leagues start at Ember 128, Tide 184, Star 300, Nova 644 and "
          "Paradox 1,160 (each within 15% under the three alternatives it tries), "
          "and an engaged player then reaches Ember on day 2, Tide on day 4, "
          "Star on day 8 and Nova on day 57 \u2014 against §14.7\u2019s first "
          "week, week 3, month 2 and month 3. Set Ember late enough for the first "
          "week instead, and at season end half the population is still in Dust "
          "and Ember holds 2% against 30%. The two targets pull opposite ways: "
          "§18.1\u2019s halfway pull-back packs the season-end population close "
          "together, so boundaries that divide it by share are close together, "
          "and an engaged player crosses several in days. And the shares alone "
          "cannot place Ember at all: once reached it is a floor, so players "
          "pile up on it whatever its value.",
     rec="Choose which target §14.7 means: if the shares, accept faster "
         "arrivals (or widen the spread with a smaller pull-back); if the "
         "arrival times, accept a heavier Dust and Ember at season end. And "
         "decide whether Renown should be made as well as moved \u2014 a small "
         "grant per clean heist would decouple the leagues from the floors\u2019 "
         "leak."),

dict(id="G27", kind="gap", severity="significant", status="open",
     title="§18.1 places players in six leagues and never says how much Renown "
           "each starts at",
     refs=["18.1", "14.7", "12.9", "18.5"],
     body="The server needs a boundary for every league and division to place a "
          "player, and the document gives none \u2014 §14.7 gives targets the "
          "boundaries should meet, not the boundaries. <code>server/src/leagues.json</code> "
          "holds the ones <code>tools/league_model.py</code> fits to §14.7\u2019s "
          "shares (F40 for what that costs), divisions as thirds of each league, "
          "and <code>check_all</code> refits them. Four more readings were needed. "
          "Renown is whole points, each amount rounded to the nearest. "
          "<em>\u201cRewards are given by league\u201d</em>, and the only reward "
          "named is §18.5\u2019s <em>\u201cStar, Nova and Paradox leagues with "
          "season-end cosmetics\u201d</em>, so those three earn a cosmetic of "
          "their league and season and the other three nothing. The floor a "
          "season pulls back toward is the lower boundary of the league the "
          "player ended in. And seasons run back to back from a start the server "
          "is given.",
     rec="Give the boundaries in Renown, or say they are set each season from "
         "the shares; say what Dust, Ember and Tide earn at season end; and say "
         "whether Renown is kept in whole points."),

dict(id="D63", kind="deviation", severity="minor", status="open",
     title="Constellations and crews are stored and joinable, and none of what "
           "they do together is built",
     refs=["17.1", "17.2", "17.3", "17.4", "17.5", "17.7", "20.4"],
     body="The server keeps §17.1\u2019s constellations \u2014 the Beacon\u2019s "
          "Keeper-level gate, thirty Keepers, a founder and four elders \u2014 and "
          "§17.7\u2019s crews of four to eight that survive their founder, and "
          "ranks constellations each season by combined Renown. Not built: chat "
          "and its preset form for 13 to 15, the Grand Law vote, anomalies (so "
          "§17.5\u2019s league ranks by Renown alone), page requests and borrowed "
          "crew. Readings taken where §17 is silent: a constellation is joined "
          "without approval while there is room; its name is from the Workshop\u2019s "
          "word lists, since §20.4\u2019s filter for constellation names implies "
          "free text and no filter exists; a founder who leaves hands on to the "
          "longest-standing elder, else member; a crew is joined by an invite and "
          "counts as a crew from four. Found building them. The backend review "
          "added: an empty constellation is closed; a ban leaves constellation "
          "and crew and voids challenge links; §18.7\u2019s quarter applies to any "
          "membership the creator and the player shared during the item\u2019s "
          "life \u2014 which a creator can still step around by leaving before "
          "publishing and rejoining after, since joining costs nothing.",
     rec="Build the Grand Law and anomalies with version 1.1 (§26.1), and state "
         "how a constellation is joined and how a crew is found."),

dict(id="F41", kind="finding", severity="significant", status="open",
     title="Starglass is a wrapper for gifts and the pass, and also a currency "
           "sold in packs, earned free, and 1:1 with no named money",
     refs=["9.1", "9.5", "19.12", "22.1", "20.6"],
     body="§19.12 refuses money illusion: <em>\u201cStarglass exists only as a "
          "gift and season-pass wrapper, always at a visible 1:1 rate\u201d</em>. "
          "Everywhere else it is a general currency. §9.1 earns it from "
          "<em>\u201cPurchases; small amounts from the free season track\u201d</em> "
          "and spends it on <em>\u201cCosmetics and the premium track only\u201d</em>; "
          "§9.5 prices cosmetics in it (<em>\u201cStarglass only\u201d</em>); and "
          "§22.1 sells <em>\u201cStarglass, in packs from about €1 to €50\u201d</em> "
          "beside the cosmetics. So it is not only a wrapper. Two more gaps sit "
          "under the 1:1: Starglass the free track gives has no money behind it, "
          "so its 1:1 is to nothing; and the rate is 1:1 to euros in every price "
          "the document writes, while the game launches in Brazilian Portuguese "
          "(§20.6), where the stores charge reais at their own price tiers, so a "
          "single Starglass cannot be 1:1 with both. The server holds Starglass "
          "as euros in hundredths, sells §22.1\u2019s packs, and spends it on "
          "cosmetics and the premium track. Found building purchases.",
     rec="Choose one: Starglass as a real currency sold in packs (and drop "
         "§19.12\u2019s \u201conly as a wrapper\u201d), or cosmetics and the "
         "pass priced in money with Starglass only as a gift token. Then name "
         "what 1:1 is to in each store country, and whether the free track "
         "gives Starglass at all."),

dict(id="F42", kind="finding", severity="minor", status="open",
     title="The season track is climbed with \u201cseason points\u201d in "
           "§18.2 and \u201cseason stars\u201d in §9.1, from different sources",
     refs=["9.1", "18.2"],
     body="§18.2: <em>\u201cFifty tiers, climbed with season points from "
          "heists, defences and discoveries\u201d</em>. §9.1\u2019s currency table "
          "calls the same thing Season stars, earned from <em>\u201cHeists, "
          "defences, discoveries, goals\u201d</em>. One of them has goals and the "
          "other does not, and a reader cannot tell whether points and stars "
          "are one currency. The server calls them season stars and earns them "
          "from heists and defences (D64). Found building the track.",
     rec="Use one name, and give §18.2 the same list of sources as §9.1."),

dict(id="G28", kind="gap", severity="significant", status="open",
     title="The season track and the shop have no numbers: stars, tier price, "
           "rewards, packs, or what catch-up scales",
     refs=["9.1", "14.8", "18.2", "18.8", "20.2", "22.1", "24.8"],
     body="§18.2 gives fifty tiers and what each track holds in kind; §18.8 "
          "says <em>\u201cUnclaimed tiers stay claimable in a later season at "
          "the same cost\u201d</em> and <em>\u201cThe track scales to the time "
          "remaining\u201d</em>; §22.1 gives a premium track at about €6 and "
          "packs from €1 to €50. Nothing says how many stars a heist or a "
          "defence earns, what a tier costs, what each tier gives, which packs "
          "exist between €1 and €50, or what a cosmetic costs. The server\u2019s "
          "readings, each a named constant in <code>track.mjs</code> and "
          "<code>shop.mjs</code>: a heist earns the raider ten stars times "
          "§12.9\u2019s Renown outcome and the defender the rest of ten, so a "
          "foiled heist is ten to the defence; a tier costs twenty, a §14.1 "
          "regular player\u2019s day of clean raids, and tier 1 costs nothing "
          "(§14.8: <em>\u201cthe season track's first tier is complete on day "
          "one\u201d</em>); a player first seen in a season pays that price "
          "scaled to the time left; stars are spent, not a threshold, so a past "
          "season\u2019s unclaimed tiers are bought with this season\u2019s stars at "
          "that season\u2019s price; the free track gives a stray at tier 50, a "
          "quarter Starglass every tenth tier (one a season), five pages every "
          "other fifth and 500 Essence otherwise; the premium track gives a "
          "cosmetic every fifth tier through §18.2\u2019s six kinds, and a season\u2019s "
          "premium track can be bought later at the same price. Packs are €1, "
          "5, 10, 20 and 50. A league\u2019s season-end cosmetic is a realm skin. "
          "An outfit is worn by a crew role and a law visual by a law. And "
          "§24.8\u2019s accounts hold a season pass expiry, which §18.8\u2019s "
          "<em>\u201cNothing expires forever\u201d</em> leaves nothing to put in: "
          "the server records a premium track per season instead. The free "
          "track\u2019s Essence and pages are not in the economy model. Found "
          "building the track and the shop.",
     rec="State the stars a heist, defence, discovery and goal earns, a "
         "tier\u2019s price and how catch-up scales it, the free and premium "
         "rewards tier by tier, the packs, and cosmetic prices; then run the "
         "economy model with the free track\u2019s Essence and pages in it."),

dict(id="D64", kind="deviation", severity="minor", status="open",
     title="The track, Starglass and cosmetics are built on the server, without "
           "the stores, discoveries, or an authored cosmetic",
     refs=["9.1", "18.2", "20.2", "22.1", "24.8"],
     body="The server earns season stars from heists and defences, claims tiers "
          "in order, sells the premium track for Starglass, sells §22.1\u2019s "
          "packs through a purchase intent that holds §20.2\u2019s monthly cap "
          "for minors before the store is asked, grants a receipt once per "
          "store transaction, gives adults the monthly spending summary, and "
          "sells, owns and applies cosmetics, the defender\u2019s worn set "
          "travelling with each lease. Not built: verifying a receipt with the "
          "App Store and Google Play (a seam, as platform sign-in is); stars "
          "from discoveries and goals, which happen on the device and which the "
          "server cannot yet check; pages and strays, which the device holds, "
          "so a claimed tier is their only record; family approval for 13 to "
          "15; and any cosmetic to sell \u2014 the catalogue is empty until a set "
          "is authored. Found building them.",
     rec="Wire the stores\u2019 receipt services with platform sign-in; move "
         "pages and the roster to the server before the track ships, so a tier "
         "is granted rather than recorded; author the launch cosmetic sets."),

dict(id="G29", kind="gap", severity="minor", status="open",
     title="Telemetry is named event by event, and nothing says what a session "
           "is, how long raw events stay inside 30 to 90 days, or how often a "
           "player is surveyed",
     refs=["20.3", "20.5", "24", "24.1", "24.3", "25.3", "25.4"],
     body="§24 lists the events and §24.3 the rules: first-party, pseudonymous, "
          "no coordinates, raw logs <em>\u201ckept 30 to 90 days, long enough "
          "for validation and analysis, then aggregated and discarded\u201d</em>. "
          "The server\u2019s readings, each a named constant in "
          "<code>telemetry.mjs</code>: a session is a sign-in; raw events stay "
          "the full 90 days; a cohort\u2019s day-1, day-7 and day-30 returns and "
          "each day\u2019s counts are what stay; a pseudonym is an HMAC of the "
          "account; a batch is at most 100 events, dated no more than seven "
          "days back; the eleven-item inventory is answered on a seven-point "
          "scale. And §24 names <em>\u201cthe monthly survey in 25\u201d</em>, "
          "while §25.4 says surveys come <em>\u201cnever more than once a "
          "quarter per player\u201d</em>: read as a survey sent every month to a "
          "rotating sample, which the server holds to once a quarter a player. "
          "Found building telemetry. The backend review added: a rating for "
          "each session, up to 24 a day like session ends, each player weighed "
          "once in the report by their own average; a survey\u2019s quarter runs "
          "from when the server received it.",
     rec="Define a session, choose the retention inside 30 to 90 days, give the "
         "survey\u2019s scale, and say whether the monthly survey is a monthly "
         "sample or a monthly ask."),

dict(id="D65", kind="deviation", severity="minor", status="open",
     title="Telemetry logs and reports on the server, without §24.3\u2019s heatmaps "
           "or an error reporter",
     refs=["24", "24.3", "25.2", "25.3"],
     body="The server records sessions, heists (outcome, laws crossed, crew) and "
          "purchases itself, takes the device\u2019s weaving, births, session ends, "
          "\u201cworth your time\u201d ratings and surveys in batches it checks "
          "whole, and reports the launch gates\u2019 figures and §25.3\u2019s "
          "recency of absence to analysts. Not built: §24.3\u2019s route, "
          "detection and failure heatmaps from re-simulated replays (the "
          "simulation does not yet report positions over a heist); the free-tier "
          "error reporter, so crash-free sessions are counted from the "
          "device\u2019s own session-end flag; and §25.2\u2019s funnel. Found "
          "building telemetry.",
     rec="Add a per-tick position export to the simulation for sampled "
         "re-simulation, and choose the error reporter."),

dict(id="F43", kind="finding", severity="significant", status="open",
     title="Deletion is required, and the records that hold a player are "
           "never deleted or edited, with no word on how the two meet",
     refs=["19.11", "20.5", "20.11", "24.8", "24.12"],
     body="§20.5 promises <em>\u201cAccount and data deletion from inside the "
          "game.\u201d</em>, §20.11 lists the stores\u2019 <em>\u201caccount deletion "
          "inside the app\u201d</em> and the law\u2019s <em>\u201cimmediate deletion of "
          "anything collected from someone who turns out to be younger\u201d</em>. "
          "The same document keeps a player in records built never to change: "
          "the ledger is append-only (§24.12), a snapshot is never edited "
          "(§24.8), and §19.11 says <em>\u201cplayer creations are never deleted "
          "or overwritten (18.6)\u201d</em>. Nothing says what deletion does to "
          "a ledger row, a Renown event, a heist a raider played against the "
          "deleted player, or a Workshop island that others have remixed. The "
          "server\u2019s reading: what identifies the person goes \u2014 the platform "
          "identity, their telemetry, their islands from matchmaking, their "
          "places in constellations and crews \u2014 and the records about "
          "heists, money and islands stay under an id that leads to nobody; "
          "Workshop islands are withdrawn, not deleted, so a remix still names "
          "its original; a raid already leased on them still settles. A player "
          "who declares an age under 13 is deleted further: the replays they "
          "played, their islands\u2019 bytes unless another player\u2019s are "
          "the same, their ratings, their Workshop plays, ratings, completions "
          "and remixes, and their open leases go at once, and the target lists "
          "are remade without them; the ledger, Renown, season stars and "
          "purchases, which are append-only, are severed. A ban keeps only the "
          "platform identity, in a table of its own, so a banned player\u2019s "
          "deletion severs the rest like anyone\u2019s. Found building "
          "deletion; the under-13 reading and the ban by the privacy inventory.",
     rec="State what deletion removes and what it keeps as anonymous records, "
         "and whether a deleted player\u2019s Workshop islands stay playable. "
         "Say what \u201canything collected\u201d covers for an under-13 player."),

dict(id="F44", kind="finding", severity="minor", status="open",
     title="The 0.25 tier §12.22 calls unreachable is reached at exactly three "
           "levels below",
     refs=["9.6", "12.3", "12.22"],
     body="C13 was closed by §12.22\u2019s fifth step: <em>\u201cThe 0.25 payout for "
          "targets three or more levels below is unreachable through normal "
          "matchmaking by design.\u201d</em> But the same section\u2019s band admits "
          "<em>\u201cKeeper level within 3\u201d</em>, and §9.6 pays <em>\u201cthree or "
          "more below 0.25\u201d</em>. A target exactly three levels below is inside "
          "the window and in the 0.25 tier, so normal matchmaking reaches it. "
          "The server filters by §12.22\u2019s window and pays by §9.6\u2019s table, so "
          "it offers such targets. Found building matchmaking.",
     rec="Make the window \u201cwithin 2\u201d, or the tier \u201cfour or more "
         "below\u201d."),

dict(id="F45", kind="finding", severity="minor", status="open",
     title="§12.3 and §12.22 filter targets differently",
     refs=["12.3", "12.22"],
     body="§12.3 offers targets <em>\u201cwithin 150 Renown of yours, within 3 "
          "Keeper levels, and within 20% of your universe's strength (stability "
          "capacity plus the levels of your five best characters)\u201d</em>. "
          "§12.22, which calls itself the home of the steps, filters by "
          "<em>\u201cRenown within 150, Keeper level within 3, an island "
          "difficulty rating within one band of the raider's recent success "
          "rate\u201d</em> and depth, and says nothing of strength. The server "
          "follows §12.22 and has no strength filter; stability and characters "
          "are the device\u2019s. Found building matchmaking.",
     rec="Drop the strength filter from §12.3 and point it at §12.22, or add "
         "strength to §12.22\u2019s band."),

dict(id="G30", kind="gap", severity="minor", status="open",
     title="§12.22 names Glicko-2 and the bands, and not how wide a band is, "
           "what \u201crecent\u201d is, or what a heist scores",
     refs=["12.3", "12.22", "13.2"],
     body="The server\u2019s readings, each a named constant in "
          "<code>matchmaking.mjs</code>: a band is 15 points of success rate, "
          "the width of §13.2\u2019s; a raider\u2019s recent success rate is their "
          "last twenty validated heists, and a new raider\u2019s is the middle of "
          "the authored band; a heist scores 1 for the raider unless foiled, and "
          "is its own rating period; an island is rated by owner and realm, and "
          "republishing keeps its mean and widens it back to 350; §12.22\u2019s "
          "figures are the generated islands\u2019 band, so an authored island is "
          "judged against what §13.2\u2019s authored hold band leaves the raider; "
          "the middle of the list is the in-band candidate nearest the band\u2019s "
          "middle, with one easier and one harder beside it; an echo moves no "
          "Renown, earns its owner nothing and rates nothing; the new-player "
          "protection covers echoes too, and not §13.1\u2019s seeded islands, "
          "which are the game\u2019s own. Found building matchmaking.",
     rec="State a band\u2019s width, the window of \u201crecent\u201d, the score of a "
         "partial heist, and whether echoes move Renown."),

dict(id="D66", kind="deviation", severity="significant", status="open",
     title="Matchmaking rates, filters and guarantees on the server, without "
           "the simulator\u2019s prior, depth or generated fallbacks",
     refs=["12.3", "12.10", "12.22", "13.3", "13.4"],
     body="The server keeps §12.22\u2019s Glicko-2 ratings for raiders and islands, "
          "updated by every validated heist; target lists carry each island\u2019s "
          "rating, deviation, Renown and origin; <code>offer</code> filters, "
          "sorts by predicted success, draws the middle from the band, counts "
          "echoes when the band is thin and widens in §12.22\u2019s order; §12.3\u2019s "
          "new-player protection and Trace hold at the lease. Not built: the "
          "prior from the defence simulator \u2014 the reference crews are the "
          "Python harness\u2019s, not the simulation\u2019s, so a new island starts at "
          "its band\u2019s middle; depth, since crossing realms is not built; the "
          "generated fallback targets, whose generator is also the harness\u2019s; "
          "ruins (12.10); and the complexity budget on unfamiliar laws. So the "
          "list can come back short, and says when it widened. Found building "
          "matchmaking.",
     rec="Port the reference crews and the generator into the simulation, so "
         "the server can rate a new island and make fallbacks itself."),

dict(id="G31", kind="gap", severity="minor", status="open",
     title="The defence reward is a share of \u201cwhat the crew was carrying\u201d, "
           "with no price on it, and §13.1\u2019s measure is two measures",
     refs=["9.4", "12.20", "13.1"],
     body="§9.4: <em>\u201ca foiled heist gives the defender the entry fee plus 5% "
          "of what the crew was carrying, a share that rises by 13.1's "
          "rule\u201d</em>. A crew carries bag units, not currency, and nothing "
          "says what they are worth. §13.1 measures the <em>\u201cShare of active "
          "players who changed their defence in the last 7 days, and who "
          "published a defence of their own in their first week\u201d</em> \u2014 two "
          "shares \u2014 and then says <em>\u201cBelow 15%\u201d</em> of one. The "
          "readings: the simulation now reports what a crew took and did not "
          "bank (dropped, or held by whoever was caught), and the server values "
          "it as the clean haul it would have been, before the raider\u2019s fatigue "
          "and caps, and pays the share of that half in Essence; the measure is "
          "the first share, taken over each season\u2019s last seven days, with a "
          "session as activity and a publish as a change, seeded accounts left "
          "out; the rule sets the next season\u2019s share at each close. The page "
          "a defender gets when a raider cast a law during a foiled heist waits "
          "on casting, which the simulation does not have. Found building the "
          "defence reward.",
     rec="Price what a crew carries, say which share §13.1\u2019s 15% reads, and "
         "when in a season it is measured."),

dict(id="F46", kind="finding", severity="significant", status="open",
     title="Every island\u2019s layout is public before any scout, so §12.4\u2019s "
           "paid scout sells what a download gives free",
     refs=["12.4", "24.1", "24.8"],
     body="§12.4: a paid scout shows a realm\u2019s laws, guards and ward counts "
          "<em>\u201cbut not where they are. Ward positions come from a Lantern "
          "Wisp during the heist, the Archivist's Reveal, or the Cartographer's "
          "maps.\u201d</em> §24.1 serves islands as <em>\u201cImmutable, "
          "content-addressed island bundles on zero-egress object storage, "
          "cached at the edge for a year\u201d</em>, and §24.8 lists every target "
          "by its bundle\u2019s hash (<em>\u201cTarget selection is a file, not a "
          "query\u201d</em>). So anyone can fetch any listed island, ward positions "
          "and guard posts included, before paying for a scout or taking a lease "
          "\u2014 and the device must hold the whole island to simulate the heist "
          "anyway (§24.1). What §12.4 sells is hidden only by the client "
          "choosing not to show it, which a modified client will not do. The "
          "server serves bundles by hash, as §24.1 says. Found building the "
          "Apple proofs, reading §12.4 for what the server must keep back.",
     rec="Either accept that scouting is a client courtesy and price it as "
         "one, or serve a target\u2019s bundle only with its lease \u2014 giving up "
         "the year-long edge cache for targets \u2014 and keep ward positions out "
         "of what the list and the free scout reveal."),

dict(id="G32", kind="gap", severity="minor", status="open",
     title="Platform sign-in and receipts are named, and nothing says how "
           "fresh a proof must be or how a refund lands",
     refs=["20.2", "22.1", "24.8"],
     body="§24.8 exchanges platform identity for a token and §22.1 sells "
          "Starglass; neither says how a proof is checked. The server\u2019s "
          "readings, in <code>stores.mjs</code>: a Game Center identity is "
          "Apple\u2019s signature over the player, the app, a timestamp and a salt, "
          "with the key fetched only from apple.com over HTTPS and checked to a "
          "pinned root, and the signature at most five minutes old; an App "
          "Store purchase is a StoreKit 2 signed transaction checked to the same "
          "root, for this app, not revoked, and the purchase intent rides it as "
          "its appAccountToken, so an intent\u2019s id is a UUID; the pinned roots "
          "and the app\u2019s bundle ID are the operator\u2019s configuration. Nothing "
          "says what a refund after a grant does to Starglass already spent. "
          "Found building the Apple proofs. The backend review tightened them: "
          "StoreKit and Game Center have their own pinned roots; a StoreKit leaf "
          "carries Apple\u2019s marker OID and a P-256 key, under an intermediate "
          "with its own; only Production transactions pay unless the operator "
          "allows Sandbox; a Game Center key is issued to Apple Inc. and fetched "
          "only from its key hosts and names, an unseen name at most once a "
          "second; and a server that takes money refuses to start with sign-in "
          "stubbed.",
     rec="Say how a refunded purchase is taken back, and whether Starglass "
         "can go below nothing."),

dict(id="D67", kind="deviation", severity="minor", status="open",
     title="The stores\u2019 proofs are checked on the server; refunds, and a "
           "Play Games player, are not",
     refs=["20.2", "22.1", "24.8"],
     body="Game Center sign-in and App Store purchases are verified against a "
          "pinned Apple root; Google sign-in against the keys Google publishes, "
          "and Play purchases against the app\u2019s licence key; a purchase is "
          "granted once per transaction. The Android sign-in is \u201cSign in "
          "with Google\u201d: its ID token proves a Google account, while "
          "§24.8 names Play Games, whose server flow is a code exchanged with "
          "Google on every sign-in. A Play purchase is also looked up and "
          "consumed by the server with the Play Developer API before it is "
          "granted: Play refunds a purchase nobody consumes after three days, "
          "and only Google says whether it was a licence tester\u2019s (found by "
          "the review of this work). Not built: refunds a player asks for after "
          "a grant (App Store Server Notifications, Play\u2019s voided "
          "purchases); and the real roots, keys and service account, which are "
          "configuration the operator supplies. Found building the stores\u2019 "
          "proofs.",
     rec="Say whether the Android identity is the Google account or the Play "
         "Games player; wire the refund notifications before soft launch."),

dict(id="F47", kind="finding", severity="significant", status="open",
     title="§24.1\u2019s budget of five writes a player a day cannot hold one "
           "heist, and a re-simulation is over the free plan\u2019s CPU limit",
     refs=["9.4", "12.9", "12.22", "13", "18.2", "24.1", "24.12", "28.3"],
     body="§24.1: <em>\u201cBudget: about 100 to 200 kilobytes and five writes per "
          "active player per day. That is the design constraint\u201d</em>. Its cost "
          "table puts 1,000 and 10,000 monthly players at €0 on free plans, and "
          "says the paid plan\u2019s 50 million row writes a month are "
          "<em>\u201cseveral times what a million players generate\u201d</em>. The "
          "load test (<code>server/load.mjs</code>, recorded in "
          "<code>server/load.json</code>) plays §14.1\u2019s players through the "
          "server as built: an engaged player writes at least 46 rows a day, "
          "9.2 times the budget; a regular one 24 and a casual one 11. A clean "
          "heist in steady state writes about 14 \u2014 the lease issued and "
          "settled, the heist, up to four ledger lines, Renown on both sides, "
          "stars, two ratings, an event batch, the defender\u2019s notification "
          "\u2014 each of which §24.12, §12.9, §18.2, §12.22 or §13 asks for. "
          "So five writes cannot carry one heist, let "
          "alone four. A million monthly players, a third of them playing on a "
          "day as §25.1\u2019s gate has it, write about 460 million rows a month "
          "if engaged and 105 million if casual \u2014 9 and 2 times the 50 "
          "million included; at the paid price in §28.3 that is about $415 and "
          "$60 a month, not $5 to $15. And a re-simulation takes "
          "about 15 ms of CPU (22 ms at the 95th percentile) where §28.3\u2019s free "
          "plan allows <em>\u201c10 milliseconds\u201d</em> a request, so the free plan "
          "cannot validate a heist at all: the €0 columns need the $5 plan from "
          "the first heist. Found by the load test. Re-measured when the "
          "landing entered the replay (§5.4): the drawn test player now lands "
          "on a drawn edge tile, so a few of its heists end differently, and "
          "a heist\u2019s rows moved by 0.01 a player-day; none of the "
          "figures above changed.",
     rec="Re-derive §24.1\u2019s budget and cost table from measured writes: state "
         "a share of monthly players active on a day, price the writes a heist "
         "must make, and drop the free-plan columns for validation. Or cut "
         "the writes: settle a heist in one row that holds its ledger lines, "
         "Renown and stars, at the price of querying them from JSON."),

dict(id="G33", kind="gap", severity="minor", status="open",
     title="The load test measures a lower bound on one machine, and nothing "
           "budgets rows read",
     refs=["24.1", "25.1", "28.3"],
     body="The load test prices monthly players by §25.1\u2019s gate \u2014 <em>\u201ca "
          "third of monthly players play on a given day\u201d</em> \u2014 which §24.1\u2019s "
          "cost table does not cite. Its readings: rows written are SQLite\u2019s "
          "changes, which do not count the index writes D1 also bills, so they "
          "are low; its raiders hold no Starlight, so no fee is booked, and its "
          "drawn raids are foiled, so no haul \u2014 a lower bound on a real day\u2019s "
          "writes; CPU is this machine\u2019s Node, not an edge isolate; and rows "
          "read are not measured, though §28.3\u2019s plans bill them too. Found by "
          "the load test; corrected when building eras, where an earlier reading "
          "priced every monthly player as playing every day.",
     rec="Budget rows read beside rows written, and re-run the load test on the "
         "edge platform itself."),

dict(id="G34", kind="gap", severity="minor", status="open",
     title="Notifications have a night and a list, and no word on gathering, "
           "a reminder set at night, or whose clock it is",
     refs=["13", "14.6", "20.2"],
     body="§14.6 names what may be sent and §20.2 the nights. The server\u2019s "
          "readings, in <code>notifications.mjs</code>: the night is the "
          "player\u2019s own clock, which the device reports as an offset from UTC; "
          "raids that land before a notification is sent are gathered into it, "
          "so a night of raids is one message in the morning; a reminder the "
          "player sets inside their night comes when the night ends; the server "
          "sends a kind and its data, and the device words it in the player\u2019s "
          "language; an adult\u2019s night is quiet until they open it, and a "
          "minor\u2019s cannot be opened. Found building notifications.",
     rec="Say whether raids are gathered, and whether a reminder may be set "
         "inside the night."),

dict(id="D68", kind="deviation", severity="minor", status="open",
     title="Notifications are queued, timed and pushed by the server; the "
           "device\u2019s own are not built",
     refs=["14.6", "20.2", "24.1"],
     body="The server keeps replays for both sides to watch, queues the "
          "defender\u2019s notification and the chosen daily reminder, holds them "
          "through the night by age band, and pushes what is due through "
          "Firebase Cloud Messaging (§24.1\u2019s push row) as the project\u2019s "
          "service account: localisation keys the device shows in its own "
          "language, a token FCM no longer knows cleared, a busy FCM tried "
          "again. Not built: the four keys in the app\u2019s native string "
          "tables; the device\u2019s own timers (storage full, a character "
          "rested, an experiment finished); and asking permission after the "
          "third session (§25.2), which are the client\u2019s; and the "
          "operator\u2019s key. Found building notifications.",
     rec="Add the four notification strings to the app in both launch "
         "languages, and supply the FCM key before the beta."),

dict(id="F48", kind="finding", severity="minor", status="open",
     title="A friendly heist is \u201cfor fun\u201d, and §12.22 gives it a payout tier",
     refs=["12.11", "12.22", "17.6", "9.6"],
     body="§12.11: <em>\u201crob a friend's island for fun. The friend loses nothing, "
          "both see the replay, and the friend earns a page for every raider "
          "their guards catch.\u201d</em> §12.22\u2019s fifth step says the 0.25 payout "
          "<em>\u201cexists for challenge links, friendly heists and Trace "
          "targets\u201d</em> \u2014 so a friendly heist pays. Nothing says whether it "
          "costs an entry fee, moves Renown, earns season stars, rates the "
          "island or counts toward §9.6\u2019s daily caps. The server\u2019s reading: "
          "it pays the raider a haul like any heist, within the caps, and costs "
          "no fee; it moves no Renown, earns no stars and rates nothing, since "
          "a game among friends is not a contest the leagues should count; and "
          "a challenge link\u2019s play is the same, once a player. Found building "
          "friends.",
     rec="Say whether friendly heists and challenges pay, and what they cost "
         "and count toward."),

dict(id="G35", kind="gap", severity="minor", status="open",
     title="Friends are used in four places and made in none",
     refs=["12.11", "17.6", "20.2"],
     body="Friendly heists, the friends\u2019 feed, challenge links and page gifts "
          "all need friends, and nothing says how two players become friends. "
          "The server\u2019s readings, in <code>friends.mjs</code>: one shares an "
          "invite and the other accepts it, open seven days; either can end "
          "it; the feed shows friends\u2019 heists from the last seven days and "
          "names nobody \u2014 the device knows its friends by their platform "
          "names; a challenge link is open seven days and plays once a player; "
          "a new player\u2019s protection does not stop a friend. §20.2 keeps a "
          "13-to-15\u2019s profile private, and the feed shows a friend\u2019s heists "
          "to friends only. Found building friends.",
     rec="Say how friends are made (platform friends, invites, or both), and "
         "whether a 13-to-15\u2019s heists appear in friends\u2019 feeds."),

dict(id="G37", kind="gap", severity="significant", status="open",
     title="What a defender earns from foiled heists has no cap, and §20.3 "
           "says every repeatable reward has one",
     refs=["9.4", "9.6", "12.9", "13.1", "18.2", "20.3"],
     body="§9.4 gives the defender of a foiled heist <em>\u201cthe entry fee plus "
          "5% of what the crew was carrying\u201d</em>; §12.9 the mirror of the "
          "raider\u2019s Renown; §18.2 season stars for defences. None is capped, "
          "while §9.6 caps the raider\u2019s hauls by the day and the week and "
          "§20.3 says repeatable rewards have daily and weekly caps. The backend "
          "review showed what that allows: a second account with no Starlight "
          "pays no fee (G17), is foiled on purpose again and again, and mints "
          "its partner 270 a heist at Vault level 1 with no end, and ten stars "
          "each time. The server\u2019s reading: the defence share counts toward "
          "the defender\u2019s own §9.6 day and week caps, at their own Vault "
          "level, sharing one total with their hauls; and a raider and a "
          "defender move Renown, season stars and the defence share only on "
          "their first raid of the UTC day \u2014 later raids that day still pay "
          "the raider\u2019s haul within the raider\u2019s caps. Found by the backend "
          "review.",
     rec="Cap what a defender earns from defences, and say whether one pair of "
         "players can move Renown and stars more than once a day."),

dict(id="F49", kind="finding", severity="minor", status="open",
     title="Quiet Week\u2019s longer heists run past the longest heist §5.4 and "
           "§24.10 allow",
     refs=["5.4", "18.3", "24.10"],
     body="§18.3\u2019s Quiet Week: <em>\u201cHeists are 30 seconds longer\u201d</em>. "
          "§5.4 caps the clock at <em>\u201cup to 240 seconds\u201d</em>, and §24.10 "
          "gives the heist\u2019s shape: <em>\u201cA heist is 4,500 to 7,200 "
          "ticks\u201d</em>. A heist across six links is already 240 seconds, so "
          "in Quiet Week it is 270, or 8,100 ticks, which neither allows; nor "
          "does either say whether the 30 seconds come before the cap or after "
          "it. The simulation\u2019s validator refused anything past 7,200 ticks. "
          "Now it allows 900 more ticks in Quiet Week, the server adds 30 seconds "
          "to the lease\u2019s clock after the cap, and a 270-second replay still "
          "fits §24.10\u2019s 2 kilobytes (1,080 bytes of checksums). Found building "
          "eras.",
     rec="Say that Quiet Week\u2019s 30 seconds come after §5.4\u2019s cap, and widen "
         "§24.10\u2019s range to 8,100 ticks, or cap Quiet Week at 240 seconds."),

dict(id="G36", kind="gap", severity="minor", status="open",
     title="Eras are eight rules and a week, and nothing says which week has "
           "which, what \u201cstronger\u201d means, or which heists they cover",
     refs=["7.3", "10.3", "18.3", "18.6"],
     body="§18.3 lists the eight and §7.3 applies the era first on the sheet. The "
          "readings, in <code>sim/src/era.rs</code> and "
          "<code>server/src/eras.mjs</code>: the eight take turns in the content "
          "file\u2019s order, a week each from the first season\u2019s first day, so "
          "each comes once a season; the era is the one the week had when the "
          "heist was leased, and every heist against a universe \u2014 raid, echo, "
          "Trace, friendly heist, challenge \u2014 is in it, while the Workshop is "
          "not, so an island cleared once stays solvable every week; "
          "Wildgrowth\u2019s \u201c25% stronger\u201d reads by the line: a time comes a "
          "quarter sooner, a rate or share is a quarter larger, a multiplier "
          "moves a quarter further from 1, an on/off rule is unchanged, and the "
          "era applies before a harmony does; The Long Night\u2019s vision is the "
          "guards\u2019, the only sight the simulation has; Heavy Stars\u2019 "
          "\u201cgravity can't be set lower\u201d holds Half gravity\u2019s line off, its "
          "notes still sounding; the only Energy ward is the Static Coil, and "
          "\u201cstronger\u201d is what its upgrade scales, the shock; Echoing Skies is "
          "one Revival source, and §7.3\u2019s highest N decides. Found building "
          "eras.",
     rec="Give the eras\u2019 order, say which heists an era covers, and write "
         "each strengthening as a line on the sheet."),

dict(id="D69", kind="deviation", severity="minor", status="open",
     title="Eras run in the simulation and the server, without their costs, "
           "the harness, or a screen",
     refs=["18.3", "5.5", "19.27"],
     body="The week\u2019s era is on every lease, travels in the replay\u2019s header "
          "(<code>RBH2</code>, one byte; a heist with none is <code>RBH1</code>, "
          "byte for byte as before), is part of the rules version, and is "
          "applied by the simulation first on the sheet; a replay that names "
          "another era than its lease pays nothing. Not built: the two halves "
          "that change what laws cost \u2014 Heavy Stars\u2019 Motion laws 30% cheaper "
          "and High Tide\u2019s free Slow rivers \u2014 which are the device\u2019s "
          "stability economy; the Python harness, whose hold rates and bands are "
          "measured with no era, so no era\u2019s effect on §13.2\u2019s bands is "
          "known; and the client\u2019s showing the week\u2019s era. Found building "
          "eras.",
     rec="Model eras in the harness and measure each against §13.2\u2019s bands "
         "before launch; price the two cost eras in the economy model."),

dict(id="F50", kind="finding", severity="significant", status="open",
     title="A deletion is undone by the only backup the plan has, and nothing "
           "says how \u201cbackups included\u201d is met",
     refs=["20.12", "24.1"],
     body="§20.12: <em>\u201cErasure completes within thirty days, backups "
          "included, with a log kept\u201d</em>. §24.1\u2019s one backup is the "
          "database\u2019s own point-in-time restore to any minute of the last "
          "30 days. Restoring to a minute before a deletion brings the account "
          "back \u2014 identity, push token, telemetry, friends \u2014 and takes the "
          "log of the deletion with it, since the log is a column of the row it "
          "deleted. Nothing in the document says a restore re-applies what it "
          "undid. The server\u2019s reading: every deletion is written first to "
          "a journal outside the database (an account id, a reason, a time; "
          "nothing that names a person), and every deletion in it is made again "
          "when the server starts, before anyone can sign in. The journal must "
          "live where a restore of the database does not reach. Found by the "
          "privacy inventory.",
     rec="Say in §20.12 or §24.1 that a restore re-applies every deletion made "
         "since the moment restored to, and where the deletion log lives."),

dict(id="G38", kind="gap", severity="minor", status="open",
     title="No time limit for what names a player and is not a raw log",
     refs=["20.5", "24.3"],
     body="§24.3 limits <em>\u201cRaw replays and logs\u201d</em> to 30 to 90 "
          "days and §20.5 says <em>\u201cCollect only what\u2019s "
          "needed\u201d</em>; nothing gives a limit for the rest a player "
          "leaves behind: notifications already sent, friend invites used or "
          "lapsed, challenge links past their week, and target lists, which "
          "are public objects naming every candidate\u2019s account and are "
          "remade every fifteen minutes. Kept as written, each grows for good. "
          "The server\u2019s reading: a sent notification is kept a week (the "
          "reminder check reads three days back), an invite goes once used or "
          "after its seven days and a link after its seven, and a band keeps "
          "its current list and the one before, the older deleted; each by a "
          "daily job, stated in <code>server/privacy.json</code> and tested. "
          "Found by the privacy inventory.",
     rec="Give each a limit, or one rule: what serves no purpose once closed "
         "is deleted within a stated time."),

dict(id="G39", kind="gap", severity="significant", status="open",
     title="Google Play asks for a web link to request deletion, and the "
           "document offers deletion only inside the game",
     refs=["20.5", "20.11"],
     body="§20.5: <em>\u201cAccount and data deletion from inside the "
          "game\u201d</em>; §20.11 lists Apple\u2019s <em>\u201caccount "
          "deletion inside the app\u201d</em>. Google Play\u2019s Data safety "
          "form also asks for a link where a player can ask for their account "
          "and data to be deleted without the app \u2014 someone who has "
          "uninstalled it, or lost the device \u2014 and an app that makes "
          "accounts must give one. No such route exists, and a request "
          "arriving by a web form has to be tied to an account without the "
          "platform sign-in that proves it in the game. "
          "<code>server/declarations.md</code> answers every other question "
          "the two forms ask from what the server stores; this one it answers "
          "\u201cnone yet\u201d. Found by the privacy inventory.",
     rec="Add the web route to §20.5 and §20.11: a page that takes a request, "
         "how the requester is shown to own the account, and the thirty days "
         "§20.12 gives."),

dict(id="D70", kind="deviation", severity="minor", status="open",
     title="The store declarations are drafted from the schema and checked, "
           "not filed, and the client has neither the age check nor deletion "
           "on a screen",
     refs=["20.1", "20.5", "20.10", "20.11"],
     body="<code>server/privacy.json</code> declares every column the server "
          "stores \u2014 236 in 39 tables \u2014 with the store data type it is, "
          "why it is kept, how long, and what a deletion does to it. A test "
          "fails when a column is added undeclared, and does each deletion and "
          "time limit it states; <code>server/declarations.md</code>, the App "
          "Privacy and Data safety answers, is written from it. Filing is the "
          "owner\u2019s, in each store\u2019s console. Until the device\u2019s "
          "age check answers, an account holds the most protective band, "
          "13 to 15, not an adult\u2019s; the check itself and the deletion "
          "button are the client\u2019s, and not built (the screens are being "
          "designed apart). A deleted island\u2019s bytes leave the server at "
          "once, but the edge caches a bundle for a year by its hash, and "
          "purging it is the operator\u2019s. Found by the privacy inventory.",
     rec="File both declarations from server/declarations.md; build the age "
         "check and the deletion button; purge the edge on an under-13 "
         "deletion."),

dict(id="F51", kind="finding", severity="significant", status="open",
     title="A Keeper can close every edge tile but one, and so choose where "
           "the crew lands",
     refs=["5.4", "6.1"],
     body="§5.4: <em>\u201cDefenders can\u2019t choose where raiders come "
          "from; they can only make every edge a puzzle\u201d</em>, and "
          "<em>\u201cnot one guarded gate\u201d</em>. §6.1\u2019s only guard "
          "on the edge is the route rule: <em>\u201cterrain can lengthen "
          "routes but never close the last route from the edges to the "
          "Heart\u201d</em>. Nothing keeps edge tiles open, so a realm ringed "
          "in rock pillars, cliffs or Crystal Walls with one gap publishes, "
          "and its one open tile is the landing every crew must take: a gate, "
          "chosen by the defender, with the guards and wards beside it. The "
          "simulation now takes the landing from the input log and "
          "<code>check</code> requires one open edge tile and a route from "
          "some open edge tile to the Vault, which is all the document asks. "
          "Found building the landing.",
     rec="Give §5.4 or §6.1 a floor on open edge: for example, no blocking "
         "feature or Crystal Wall on an edge tile, or at least half of each "
         "side open, checked when an island is published."),

dict(id="G40", kind="gap", severity="minor", status="open",
     title="§5.4 names one landing spot but not how a crew stands on it, "
           "what darkness is, or how the noise meets suspicion already there",
     refs=["5.4", "12.17"],
     body="The simulation reads §5.4 as follows, where it is silent. The "
          "whole crew lands on the one tile the raider picks, together, at "
          "tick 0, before any other command of that tick (<em>\u201cthe "
          "landing spot\u201d</em> is one spot). <em>\u201cDarkness\u201d</em> "
          "is §12.17\u2019s unlit modifier on that tile, the same test "
          "perception uses; a realm Glowing dark makes dark does not hide it, "
          "though Night runners reads the same word as that whole realm "
          "(<code>in_darkness</code>), so the one word is read two ways. "
          "Fog and tall grass are the fog bank and tall grass features on the "
          "tile itself, not beside it. <em>\u201cStart at 250\u201d</em> "
          "raises a guard to 250 and never lowers one already higher, and a "
          "guard asleep at the start does not hear it. The six tiles are "
          "walked, as §12.17 says every sound travels (<em>\u201cSound "
          "follows the walkable path rather than passing through "
          "walls\u201d</em>), and a law\u2019s noise radius stretches them. "
          "A knocked-out crew member Ghost tide sends back to "
          "<em>\u201cwhere they entered the realm\u201d</em> goes to the "
          "landing spot. The crew\u2019s old convention \u2014 one member a tile "
          "along the north edge, unheard \u2014 is gone: the server refuses "
          "a heist that never lands (<code>Refusal::Landing</code>).",
     rec="State these readings in §5.4, or the ones that should differ."),

dict(id="D71", kind="deviation", severity="minor", status="open",
     title="The Heart is landed on, because a heist is still one island",
     refs=["5.3", "5.4"],
     body="§5.4: <em>\u201cThe Heart is ringed by strong winds, so skiffs "
          "can\u2019t land there\u201d</em>, and the clock is <em>\u201c150 "
          "seconds plus 15 seconds for each link on the shortest route from "
          "the landing realm to the Heart\u201d</em>. A heist is played on "
          "one island, and the fixture and the server\u2019s example are "
          "Hearts, so the crew lands on the island it raids whatever it is, "
          "and the clock is the lease\u2019s. Universes of several realms "
          "joined by §5.3\u2019s links are the next stage of crossing realms; "
          "the Heart rule and the clock by links come with them.",
     rec="None for the document; build universes of several realms, the "
         "crossing realms T3.3 lists as not yet built."),

dict(id="G24", kind="gap", severity="minor", status="open",
     title="§7.3\u2019s Structure regrowth row holds three different rules, "
           "and its combining rule has no case for a time",
     refs=["7.3", "7.4"],
     body="The row lists Regrowth, Bloom, Crystal growth and Tidemark. Regrowth "
          "heals what is standing, 2% a second; Bloom regrows <em>\u201ccut "
          "hedges\u201d</em> after 10 seconds; Crystal growth regrows "
          "<em>\u201cbroken walls and hedges\u201d</em> after 8, as crystal "
          "that does not block sight. That is F31\u2019s fault again \u2014 one "
          "name, several rules \u2014 which v3.4 fixed for health and drain and "
          "not here. And §7.3 combines by kind: <em>\u201cmultipliers multiply; "
          "on/off rules take the last value applied\u201d</em>. A regrowth time "
          "is neither, so Bloom and Crystal growth together have no stated "
          "time. <code>sim/</code> keeps the heal as "
          "<code>structure_regrowth</code> and the time as "
          "<code>regrow_seconds</code>, applied to broken Thorn Hedges, which "
          "is Bloom and half of Crystal growth.",
     rec="Split the row as v3.4 split Health: a heal-while-standing row and a "
         "regrow-after row, with what regrows named. Say that times take the "
         "shortest value applied (or the last), so two laws that set one have "
         "an answer."),

]

# ===========================================================================
# What version 3.0 did about each of these
# ===========================================================================
#
# The register above records what was found against v2.3. This records what the
# next version of the design document did about it, as a separate layer rather
# than by editing sixty-four entries — so "what was found" and "what was done"
# stay two different things, and the second can be re-derived when v3.1 arrives.
#
# `status` overrides the item's own. `fixed` means the design document itself
# resolved it, as distinct from `done`, which means this repository did.
# `note` says what v3.0 did, including where it stopped short.

# ===========================================================================
# What version 3.1 did
# ===========================================================================
#
# A second layer over V3, not a replacement: v3.0's note stays, and this says
# what happened next. Each entry is verified against the built document rather
# than taken from §31.9's own summary — v3.0 also published a list of things it
# had fixed, and C21 to C24 are what that list missed.
#
# `status="fixed"` here means the check that tracked the item now passes against
# `docs/design/ruleborn-game-design-v3.1.txt`.

V32 = {

# What version 3.2 did, verified here against the built document rather than
# taken from its own list. Each entry is a check that RETIRED when v3.2 was
# read: it passed while the item was still open, which is the ledger's way of
# saying the document has moved past the register.

"F8": dict(status="fixed", note=
    "Closed, by naming a different device rather than retuning this one. "
    "\u00a712.6 now says the realm alarm <em>\u201cis the pressure device "
    "here\u201d</em> and gives it a 0\u20136 climb \u2014 once every thirty "
    "seconds and once per knocked-out guard discovered. The finding was that "
    "runs finish with a third of the clock unused, so the clock is not the "
    "tension; the answer is that something else is."),

"F21": dict(status="fixed", note=
    "Closed with a measurement and a reframing. \u00a713.2: <em>\u201cthe "
    "health signal is the shape of the outcomes, not the average\u201d</em>, "
    "and a polarised game is named as the failure. Measured over 300 raids on "
    "identical seeds, a crew following a fixed stopping threshold puts 70% of "
    "its runs in one bucket \u2014 which is the finding, stated as a property "
    "of the design rather than a defect in it."),

"C8": dict(status="open", note=
    "<strong>Half closed.</strong> \u00a77.6 now gives the Library a passive "
    "page rate from its own table \u2014 <em>\u201c3 a day at level "
    "1\u201d</em> \u2014 so the economy half is specified. The art half is "
    "not: \u00a721.9 still budgets 16 building looks against the 17 "
    "\u00a710.2 and \u00a710.4 hold, and the check still fails on it."),

"C2": dict(status="open", note=
    "<strong>Acted on, not closed.</strong> v3.2 fixed the derivation half "
    "(F14) and \u00a79.4 was rewritten, but the share-of-income claim still "
    "does not reconcile: run through the economy model, \u00a79.6's formula "
    "yields 3\u20138% of a player's resources against the \u201croughly a "
    "third\u201d \u00a79.4 states and the 40% of mid-game growth "
    "\u00a712.1 states. The check that says so is the same one, unchanged, "
    "and it still fails."),

"Q6": dict(status="adopted", note=
    "Answered. \u00a727.3: <em>\u201cThe curve is cut, and a catch-up "
    "discount ships as well. The discount is keyed to the median player's "
    "progress rather than to calendar time or to the player's own rate\u201d"
    "</em>. Both branches of the question taken, and the keying is the part "
    "the item said was never specified."),

"F17": dict(status="open", note=
    "<strong>Half closed, and it is the half the spec argued for.</strong> "
    "<code>sinks.md</code> said the prices were on the wrong kind of curve and "
    "proposed pegging upkeep to production before cutting faucets. "
    "\u00a75.6 and \u00a79.5 now do the peg: upkeep is "
    "<em>\u201c15% of hourly Aether production at a full stability budget, "
    "pro-rata below it\u201d</em> rather than a flat 0.5 an hour per point."
    "<br><br>Whether the sinks now hold is a question for the economy model, "
    "not for a string comparison, and it has not been re-run against v3.2."),

"F14": dict(status="fixed", note=
    "Closed, and the document states the cause in the audit's own terms. "
    "\u00a79.6: <em>\u201cAn earlier version of this section put the figure "
    "at 46%, which is the expected grade alone\u201d</em> \u2014 a fill term "
    "was added beside grade in the same formula and the number was never "
    "re-derived. Measured, it is 13% to 19%, so an upgrade takes 32 to 46 days "
    "rather than nine."
    "<br><br>\u00a731.5 now carries a check for it by name \u2014 "
    "<em>\u201cPacing re-derives from its band\u201d</em>, credited to "
    "<strong>C2 and F14</strong>."),

"D43": dict(status="open", note=
    "<strong>Half closed.</strong> Two of the four appendix rows were fixed as "
    "drafted. <em>Heist take</em> now reads <code>Haul = B(V) \u00d7 grade "
    "\u00d7 difficulty \u00d7 richness \u00d7 fatigue \u00d7 fill</code> and "
    "cites \u00a79.6 instead of the \u00a79.4 that had deleted it \u2014 "
    "C21's second instance, gone. <em>Restoring a law</em> passes because "
    "\u00a77.6 was fixed (C23)."
    "<br><br>Two remain, and they are the two that were never a contradiction: "
    "<em>Vault</em> still cites \u00a79.4 for a capacity curve that lives in "
    "\u00a710.2's ladder, and <em>Suspicion</em>'s 2.8 s still appears nowhere "
    "but the appendix. A wrong address and a number with no home are the "
    "quieter half, and they are what is left."),

"C4": dict(status="fixed", note=
    "Closed, and the drafted edit was taken almost word for word. \u00a79.6 now "
    "reads <em>\u201cthe sealed share runs 40% at <strong>Vault level</strong> "
    "1 and rises by 3.5 points a level to 71.5% at Vault level 10 "
    "(9.4 owns this)\u201d</em>. The parenthesis is \u00a731.2's rule stated "
    "where the restatement is rather than only in \u00a731, which is more than "
    "the edit asked for."),

"F20": dict(status="fixed", note=
    "Closed. \u00a712.19 now states <em>\u201cthe curve peaks at about 90% "
    "full and turns over after it\u201d</em>, measured over 300 raids with "
    "only the stopping point varying. \u00a732.1 adds why the old figure was "
    "wrong in a way worth keeping: 70% is close to the threshold the one "
    "peer-reviewed study of this exact decision names as the rule "
    "<em>first-time players</em> intuitively choose, and trained agents beat "
    "it."),

"C22": dict(status="fixed", note=
    "Closed, and it was the last of the four v3.0 fixes that left a stale copy "
    "standing. The document now states one loading rate: <code>"
    "check_document</code>'s two independent checks — that the rate is "
    "stated once, and that §12.19 owns it — both passed while this "
    "item was still open, which is what a retirement is."),

"C23": dict(status="fixed", note=
    "Closed. §7.6 now reads <em>“Restoring a law: 10 pages for a "
    "common law, 20 for an uncommon, 35 for a rare and 60 for a deep "
    "one”</em> — and adds <em>“This is the home of the page "
    "costs”</em>, which is §31.2's rule stated in the section it "
    "governs rather than only in §31."
    "<br><br>The derived page-cost check retired on it: every price claim in "
    "the document, in all three grammatical forms, now agrees with the rank "
    "table. F24's programme reached the sentence it was written for."),

"C27": dict(status="fixed", note=
    "Closed. A producer's partial output is stated once, in §5.8, and "
    "§9.2's competing 60/85/100% steps are gone — including the "
    "coefficient in §9.3's formula, which the item warned would otherwise "
    "leave the game computing the rule it had just deleted."),

}


# ===========================================================================
# What version 3.3 did
# ===========================================================================
#
# A fourth layer, for the same reason as the others. v3.3's §31.9 lists 62
# items as answered and applied; each was read against the built document by
# section and line, and the checks that tracked them were re-run. 55 of the
# 64 items open against v3.2 close here. Nine do not: two v3.3 never claimed
# (C33, F31, both registered after its snapshot), and seven it claimed and
# only partly did (C19, C32, D43, F16, F17, F19, F25). Where v3.3 decided
# differently from the recommendation, the note says so: a closed item is one
# the document settled, not one it settled our way.

V33 = {

"D6": dict(status="fixed", note=
    "<strong>Decided: the cut is taken.</strong> §26.1 ships 24 laws "
    "<em>“chosen by engine cost”</em>, 54 forms, 12 signature "
    "resonances, two ward levels and two languages, with constellations in "
    "version 1.1 and the Workshop kept. The 24 are a rule rather than a "
    "choice (§7.10), and <code>check_document</code> now re-derives "
    "them from the 48 sheets: the rule, the badges, the table and the "
    "engine-point totals (78, 14, and 36 for a 24 chosen by rank) all agree."),

"Q5": dict(status="fixed", note=
    "Decided with D6. The cut differs from D6's proposal in detail — 12 "
    "resonances rather than about 20, two languages — and is recorded in "
    "§26.1 with its rule."),

"F10": dict(status="fixed", note=
    "Every sheet in §7.7 now carries an <em>Effect kind</em> tag, and "
    "§7.10 is the ladder they sit on: 16 parameter, 6 placement or "
    "attribute, 16 conditional, 10 spawned, none on the rewind rung. "
    "Tidemark replaces Rewind as a checkpoint return. The extraction keeps "
    "the tag as data (<code>content/laws.json</code>: "
    "<code>engine_rung</code>, <code>launch</code>)."),

"C3": dict(status="fixed", note=
    "<strong>Closed a different way.</strong> v3.3 kept four ranks at "
    "18/12/12/6 by moving each school’s cheaper deep law to rare, "
    "rather than the 18/12/6/12 proposed. The 48 sheets count 18/12/12/6, "
    "every school is 3/2/2/1, and every statement of the split agrees at "
    "1,200 pages."),

"Q3": dict(status="fixed", note="Decided with C3: four ranks, 18/12/12/6."),

"D31": dict(status="fixed", note=
    "<strong>Decided by withdrawing the claim.</strong> §7.9 is now "
    "<em>“Rank is a strength ladder, paid for in pages”</em> and "
    "says the earlier claim is withdrawn rather than enforced. Its figures "
    "check against the sheets: r = +0.79, medians 13.5, 17, 19 and 22.5."),

"F24": dict(status="fixed", note=
    "§7.6 prices all four ranks at 10, 20, 35 and 60 pages. The retired "
    "phrasing survives only as the quotation in §31.5’s check "
    "table, which is marked to be allowed."),

"G3": dict(status="fixed", note=
    "Every ward now has a sensor, what an upgrade scales, and a rule that a "
    "level never scales a distance; Static Coil has damage; disarming is "
    "specified. <strong>One contradiction came with it</strong>: §10.3 "
    "gives ward health as 500 a level in its first paragraph and 550 in its "
    "last. That is C34, not a reason to keep this open."),

"Q7": dict(status="fixed", note=
    "§27.3: <em>“Nothing in this section is open.”</em> Each "
    "question is answered in the section that owns it. Soft-launch markets "
    "are settled as a rule for choosing three, not as named countries, "
    "which is enough for everything the document plans before them."),

"F29": dict(status="fixed", note=
    "Decided by the quiet-surface route rather than the drafted §12.17 "
    "edit: the crouched step stays heard at 1 m and only moss, at 0.75 m, "
    "lets a crew member arrive unheard. §6.1 and §12.8 name "
    "clearing moss as a defensive choice, which turns the finding into a "
    "decision on both sides of the board."),

"D49": dict(status="fixed", note=
    "§11.10: <em>“Eighteen kinds and three notes make 54 "
    "forms”</em> — Hush, Spark and Echo, the three the launch 24 "
    "carry most, by a stated tie-break that re-derives. No count of 144 "
    "forms is left, and the check reads the three notes from the table."),

"D40": dict(status="fixed", note=
    "§7.3 has a Revival row with three shapes and a rule that the "
    "highest N applies, once. Echoplate reads 40% in both §11.2 and "
    "§11.11."),

"F15": dict(status="fixed", note=
    "<strong>Changed rather than tuned.</strong> Detection and response are "
    "one layer at 35%, the 25% ceiling became a rule that no layer decides "
    "an outcome alone, and §13.4 measures haul denied across all 16 "
    "combinations of four layers. Geometry at 25% and laws at 20% remain "
    "targets for the measurement ledger (§32)."),

"D9": dict(status="fixed", note=
    "§26.8 budgets iteration as its own line at 1× the build, a "
    "floor: 229 to 405 runs, plan total 458 to 810, about 640. The "
    "arithmetic re-derives."),

"C6": dict(status="fixed", note=
    "§11.2 is generated from the §11.11 cards. All 18 rows agree "
    "on school, role, ability and resist, and the extraction reports no "
    "conflicts. Cooldowns are gone: two uses a heist (D32)."),

"F26": dict(status="fixed", note=
    "<strong>Decided.</strong> The ward limit is eight at most, set per "
    "level by the hold band (8, 8, 6, 7, 8), and generated islands at realm "
    "level 1 get their own band, 25 to 40%, by a stated rule. The holds are "
    "measured before the peripheral-vision alignment, and realm level 4 at "
    "two posts rather than three; §13.2 says both and defers them to "
    "the re-run.<br><br><strong>Re-measured under v3.3's rules</strong> (D56, "
    "crack noise off): realm 3 on its six wards holds 48.0%, three points "
    "over the band, and a flat ten 68.0%. With the noise on, 80.0% and "
    "90.0% (F32). After D57's fixes, 50.5% and 74.5%, and 78.0% and 93.0% "
    "with the noise. All of that is at one post and on v3.2's wards: the "
    "table \u00a713.2 quotes was measured at one post in every realm (F34), "
    "and on v3.3's wards a count is not the dial (F33)."),

"F22": dict(status="fixed", note=
    "<strong>Closed another way.</strong> Not a second post: realm levels 1 "
    "and 2 get eight wards, realm 2 measures 37.6% at one post, and realm 1 "
    "keeps one post under its own band."
    "<br><br><strong>Re-measured under v3.3's rules</strong> (D56, crack "
    "noise off): at realm 1 across three realms, one post at level 5 holds "
    "42.0% and two posts 80.0% \u2014 the same 38-point gap, with the "
    "half-speed crouch lifting one post into the band. With the noise on, "
    "67.6% and 92.8% (F32). The cell F22 was first measured in \u2014 two "
    "posts, two realms \u2014 reads 66.0%, against 44.8% under v3.2's "
    "rules; <code>generator_settings --self-test</code> pins the new value."
    "<br><br>After D57's fixes, on v3.2's wards: one post at level 5 43.6% "
    "and two posts 81.2% (70.4% and 92.8% with the noise), and F22's cell "
    "70.0%."),

"G5": dict(status="fixed", note=
    "A pylon shows its law’s glyph and a tag names it on first sight "
    "(§12.6, §15.3), and the detour is priced: about 1% of a heist "
    "at pylon level 1, 9% at level 10."),

"C25": dict(status="fixed", note=
    "§8.8’s note counts are generated from the sheets and match "
    "them: Echo and Hush 10, Flow, Glow and Weight 9, the rest 8. The band "
    "is 8 to 10 rather than the 8 to 9 proposed; what matters is that the "
    "sentence is now true."),

"D13": dict(status="fixed", note=
    "Nine laws were re-noted. Opposite pairs are within two laws of each "
    "other, no law carries a note and its opposite, and every chord stays "
    "reachable."),

"F11": dict(status="fixed", note=
    "§13.3: the generator weaves only the laws that help the defender "
    "and must hold its realm level’s band."),

"F30": dict(status="fixed", note=
    "§12.19 now says <em>“with a Breaker in the crew”</em> "
    "and prices the crews without one (about 26 seconds, 22 with the assist "
    "bonus). The lower figures re-derive; the upper end of "
    "<em>“8 to 25 seconds”</em> has no case that gives it, which "
    "C39 records."),

"C31": dict(status="fixed", note=
    "The patrol shift is drawn once from the heist’s seed as it starts; "
    "nothing moves at random during a run. The same sentence says the scout "
    "sees the shifted patrol, which §12.4’s scout does not show: "
    "C37."),

"D50": dict(status="fixed", note=
    "All 33 cells of §31.5’s last column are marked as allowed "
    "quotation, and §32.5 says Island Fund."),

"D39": dict(status="fixed", note=
    "§7.4 is generated from §7.7. The two differ in none of the "
    "shared fields; the only difference is the <em>Launch</em> badge after "
    "24 names in §7.4, which the check now reads as a badge."),

"D20": dict(status="fixed", note=
    "Decided: the harnesses are on the critical path and built before the "
    "vertical slice; the browser prototype stays up and nobody is recruited "
    "to it (§19.27, §26.7)."),

"F12": dict(status="fixed", note=
    "One placement rule for all eight authored choices (§7.10): against "
    "the shortest route to the Heart, never sealing it. Each sheet states "
    "its instance, and Inward pull’s choice is fixed."),

"G13": dict(status="fixed", note=
    "§12.17: crouched is half a role’s speed and running double. "
    "<code>sim/</code> had read exactly that and now matches a stated "
    "figure."),

"G10": dict(status="fixed", note=
    "§7.3 has exactly twenty parameters and every law appears in one; "
    "Glass is the named view-layer exception."),

"F27": dict(status="fixed", note=
    "The Guardian Post ladder keeps one slope and sets its start per realm "
    "level, so each level’s midpoint sits in its band. The starts for "
    "realm levels 1 and 2 are computed until the aligned re-run."),

"D48": dict(status="fixed", note=
    "Co-op is asynchronous and turn-based, in version 1.1, with no lobby "
    "(§12.11, §23.2)."),

"D34": dict(status="fixed", note=
    "Decided in the text: the harness crew loads to a target, and the clock "
    "experiment passes only if mean fill falls as the clock shortens, with "
    "stated fallbacks. The measurement has not run; §32.9 carries it."),

"D16": dict(status="fixed", note=
    "<strong>Decided differently.</strong> Every role loads at 30 a second, "
    "not 30 for the Carrier and 8 for the rest; bags are 104, 104, 300, 138 "
    "and 104, which sum to 750. <code>sim/</code> follows."),

"F6": dict(status="fixed", note=
    "<strong>Decided with an assist bonus</strong>: while two or more work "
    "one object every hit deals 25% more. The decision is who helps, and it "
    "is real: the weakest helper still cuts a Breaker’s time by more "
    "than a quarter, which the check now computes. §11.1 also writes "
    "the fallback if the harness cannot size it."),

"G11": dict(status="fixed", note=
    "Two languages at launch, English and Brazilian Portuguese, with a named "
    "owner for translation (§20.6, §26.3)."),

"F7": dict(status="fixed", note=
    "The matchmaker controls depth, and depth sets the decision count "
    "(§12.22, §12.6)."),

"F13": dict(status="fixed", note=
    "§12.22 says what happens when a band is empty, and the ward budget "
    "that emptied it changed (F26). The holds are pre-alignment and "
    "disclosed as such."),

"G14": dict(status="fixed", note=
    "A revived crew member returns at 30% of its role’s health "
    "(§12.20), rather than the 25% proposed. <code>sim/</code> "
    "follows."),

"D53": dict(status="fixed", note=
    "§13.4’s limits now follow §5.2."),

"D47": dict(status="fixed", note=
    "§19.2 cites 12.7 and 21.8 and states 9 mm. The 44-point figure "
    "survives only in the evidence log’s review records."),

"C28": dict(status="fixed", note=
    "One birth price, §9.5’s, with the offset written out and "
    "examples that match it; §11.5 defers."),

"D17": dict(status="fixed", note=
    "<strong>Changed rather than repaired.</strong> The ambush is a "
    "guaranteed knockout keyed to the guard’s remaining health, so no "
    "Power, level or trait can break it; triple Power and the floor are "
    "gone, and its cost is an unseen, unheard approach and a body. "
    "<code>sim/</code> and the harness still run the old rule: D56."),

"C8": dict(status="fixed", note=
    "The Library’s ten levels are in §10.2 with every other "
    "building, and §21.9 budgets 17 types × 4 = 68."),

"C18": dict(status="fixed", note=
    "Aether storage is one day of production at the Spire’s level, "
    "stated in §10.2 and cited by §9.1."),

"F9": dict(status="fixed", note=
    "The hold band is a stated requirement on the generator (§13.3), "
    "per realm level. v3.3’s own list says the holds were re-measured "
    "on the aligned harness; §13.2 says they were measured before it. "
    "The requirement is what F9 asked for, so this closes, and the claim is "
    "C39."),

"D32": dict(status="fixed", note=
    "Decided by uses rather than longer cooldowns: two a heist, a ten-second "
    "lockout, six to ten ability choices a crew whatever the clock."),

"G15": dict(status="fixed", note=
    "§9.6: exposed share in bag units = a full five-crew’s carry "
    "× the richness ratio, so 750 at the level median. "
    "<code>sim/</code>’s fixture Vault now holds that, and it is "
    "compared rather than read."),

"D51": dict(status="fixed", note=
    "§9.6 defers to §10.2, which lists every 3.5-point step."),

"F23": dict(status="fixed", note=
    "The gate is the chord’s own stability draw, 192, derived in "
    "§8.5 from the cheapest chord on day 41. The derivation checks."),

"C2": dict(status="fixed", note=
    "<strong>Closed by withdrawing the target.</strong> §9.4 sets no "
    "share of income for raiding; what a heist comes to is an output of "
    "the economy model. B(V) is keyed to the target’s Vault level, and "
    "a raid-worth criterion raised its base from 100 to 2,400."),

"C29": dict(status="fixed", note=
    "No phase before soft launch needs a player other than the developer; "
    "the exit tests are harness gates."),

"C12": dict(status="fixed", note=
    "§22.2 prices each scenario by store and year; the high scenario "
    "re-derives at about €182,000 a month. §18.9 still quotes the "
    "old figure: C38."),

"F28": dict(status="fixed", note=
    "Cracking is a heard event: every five seconds every guard in the Heart "
    "starts Investigating the Vault, instead of 100 suspicion that drains."),

"D52": dict(status="fixed", note=
    "§31.9 keeps answered and applied apart, and a build check "
    "enforces it."),

"D44": dict(status="fixed", note=
    "The heist clock, the albums and the monthly-player figure each have "
    "one home."),

# Still open.

"C32": dict(status="open", note=
    "<strong>Half done.</strong> §10.3 adds the reconciling rule "
    "— each level takes a tenth of the level-1 reset off — but "
    "§10.2’s Ward row still reads <em>“resets 10 s”</em> "
    "with nothing saying it is only the ten-second case."),

"C19": dict(status="open", note=
    "<strong>Rules fixed, tables not.</strong> One producer of each kind "
    "per realm, and §9.3 is regenerated. §14.2, §14.3 and "
    "§10.2’s day and income columns ship at the earlier run, as "
    "§14.2 says, so the Keeper-40 sentence (day 181) stands against "
    "the partial re-run’s day 275, §10.2’s Spire-10 income "
    "hours imply about 2.4× §9.3’s production, and "
    "§5.8 still claims the old curve within 10%."),

"D43": dict(status="open", note=
    "All four rows named are repaired. One number is left by the check’s "
    "own rule: the Vault row’s <em>“8,000 × "
    "1.85<sup>level − 1</sup>”</em> cites §10.2, whose "
    "table implies 1.85 and never states it."),

"F16": dict(status="open", note=
    "The generator fix is in, and hold bands are split by origin. The layer "
    "shares are not: geometry 25% and about 60% from design are still "
    "stated for every island, authored or generated."
    "<br><br><strong>Re-measured after D57</strong> (crack noise off, "
    "v3.2's wards, n=160): turning geometry on adds 14.4 points to the "
    "generator's island and 44.4 to the designed one \u2014 about three "
    "times, which is \u00a713.3's <em>\u201cseveral times\u201d</em>. At the "
    "n=40 the test runs, 15.0 against 62.5, where it read \u22127.5 against "
    "57.5 before D57."),

"F17": dict(status="open", note=
    "Upkeep is a share of production and Essence gained a recurring keep. "
    "The waking price is unchanged and still never falls due at a full "
    "roster, and by §9.5’s own figures the Aether ladder’s "
    "fallback looks unavoidable while §32.9 ships none."),

"F19": dict(status="open", note=
    "§9.6 publishes a band with its n and error. §14.2 still "
    "states one target curve with no allowance for skill."),

"F25": dict(status="open", note=
    "All six facts named have one home now. The new claim is the problem: "
    "§31.3 says <em>“every single figure the audit register has "
    "ever recorded as stated twice is on it”</em>, and its table "
    "holds the page total and none of the other five."),

"F31": dict(status="open", note=
    "Not claimed by v3.3. §7.3 still has one Drain and one Healing "
    "parameter for two subjects each, and now also says the list of twenty "
    "is closed, so the split needs that decision."),

"D14": dict(status="fixed", note=
    "v3.3 re-noted nine laws (D13), and its \u00a78.8 reads the chord rule "
    "less strictly than this repository\u2019s validator did: a law may carry "
    "a note opposite to one in the chord, so long as each law contributes one "
    "of its three. By the document\u2019s reading the cheapest chord costs 32 "
    "(Bloom, Brittle stone and Tilt, as \u00a78.8 says) and 8 of the 12 can "
    "be completed by three commons. What makes chords late now is \u00a78.5\u2019s "
    "draw of 192 stability (F23), not the table."),

"C33": dict(status="open", note=
    "Not claimed by v3.3. The three §6.2 cells are unchanged, and the "
    "stairs row has no §12.17 counterpart at all."),

}


# ===========================================================================
# What version 3.4 did
# ===========================================================================
#
# A fifth layer. v3.4's §31.9 answers the seventeen items open against v3.3,
# one row each, two of them by briefs 37 and 38. Each was read against the
# built document by section and line, and every check that tracked one was
# re-run: fifteen close, two do not (C19 and C35, both the same unfinished
# re-run). The four items registered after v3.4's snapshot (F33, F34, G17,
# D58) are not in its list and get no note here.

V34 = {

"C19": dict(status="open", note=
    "<strong>Sentences moved; tables not, as v3.4 says.</strong> §5.8 now "
    "says its 10% was against the curve published before v3.3, and states "
    "the re-run’s shortfall under all three of its rules (15%, 50%, 59% "
    "and 52% at days 31, 91, 181 and 301). §14.3’s Keeper sentence "
    "quotes the partial re-run (28 on day 108, 40 on day 275), and §14.2 "
    "adds that the full re-run publishes every milestone twice, at both "
    "edges of §9.6’s band. The tables themselves — §14.2, §14.3 "
    "and §10.2’s day columns — still ship the earlier run, and "
    "§32.9 makes the full re-run its one open command.<br><br>That command "
    "is this repository’s to run: <code>tools/economy_model</code> is "
    "the model, and it still mints raids from v3.2’s base (D58). So "
    "C19 waits on D58, and both are mine.<br><br><strong>The re-run is "
    "done</strong> (D58 first), at "
    "<code>docs/design/generated/pacing.md</code>: §9.3, §10.2\u2019s two day "
    "columns, §14.2 for all 40 levels and §14.3\u2019s rows, each at both "
    "edges of §9.6\u2019s band, in §9.5\u2019s order (the base, then the "
    "sinks at their shipped quarter, then the birth rate, which the rule "
    "moves from 1.3265 to 1.3488). The curve is much slower than the tables "
    "it replaces: an engaged player reaches Keeper 28 on day 140\u2013144 "
    "and 40 on day 332\u2013343, against §14.2\u2019s target curve of 89 "
    "and 179 and the partial re-run\u2019s 108 and 275, and has everything "
    "built on day 621\u2013641 rather than 378.<br><br><strong>Then an "
    "adversarial review</strong> attacked every claim of the run, each "
    "attack re-checked by an independent judge. Every number reproduced; "
    "several rested on choices the document does not make. The run is "
    "rebuilt on what it found: §9.1\u2019s storage, §9.4\u2019s entry fee, "
    "§11.5\u2019s and §18.2\u2019s strays, §9.3\u2019s bonuses to the matching "
    "school only, the Codex\u2019s launch chapters, the Spire saved for "
    "first (§14.1), the first realm on day 3 (§16 says day 1), every "
    "character levelled, and no free buildings when a realm opens. It now "
    "puts Keeper 40 on day 349\u2013357 and everything built on day "
    "699\u2013719, adds §5.2\u2019s realm levels and §5.5\u2019s capacities, "
    "and prints what each open choice moves: the staffing order, the realm "
    "order (Keeper 40 anywhere from 337 to 385) and staffed posts (G22). "
    "The review also found F38 (strays leave §9.5\u2019s birth rule nothing "
    "to set), F39 (the entry fee outweighs raids for a player saving for "
    "the Spire), C41 and C42, and reframed F36 and F37. §14.2\u2019s rule is "
    "that the pacing sentences move, never the table; what is left is the "
    "document\u2019s: decide G22 and F38, take the tables, and move the "
    "sentences."),

"C32": dict(status="fixed", note=
    "Closed as recommended. §10.2’s Ward row reads <em>“effect "
    "+0%, its own reset (10.3)”</em>, then 10%, 20%, 30% and 40% "
    "shorter; §10.3 keeps each ward’s level-1 reset and says the "
    "table shows the ten-second case. One home for the base, one for the "
    "scaling."),

"C33": dict(status="fixed", note=
    "Closed as drafted. §6.2’s three cells defer to §12.17 "
    "(<em>“see further”</em>, <em>“standing still in it "
    "until a guard walks into the tile”</em>, <em>“louder "
    "underfoot”</em>), and §12.17 carries all three; the stairs row, "
    "which had no §12.17 counterpart, is a dash. "
    "<code>content/terrain.json</code> re-extracted."),

"C34": dict(status="fixed", note=
    "Closed. §10.3’s caption gives no number and points at the "
    "derivation, which keeps 550. The check retires, and 550 is now a "
    "declared fact (<code>design_facts.WARD_HEALTH_PER_LEVEL</code>) that "
    "<code>sim/</code>’s constant is compared against, instead of a "
    "reading the simulation took on its own."),

"C35": dict(status="open", note=
    "<strong>The sentence moved; the row did not.</strong> §14.3’s prose "
    "now quotes §14.4 — all 48 in about 69 days engaged, 195 for a "
    "player who never raids — and names §14.4 the Codex’s one home. "
    "The milestone table directly above it still reads <em>“48 laws "
    "owned — Day 235”</em> for the engaged player, and the prose "
    "under it says <em>“the 36- and 48-law rows are the full "
    "table’s”</em>. The table is the earlier run, so this closes "
    "with C19’s re-run; until then §14.3 states both. The check read "
    "v3.3’s sentence and went silent when it moved; it reads the row "
    "now, and a missing anchor fails instead of skipping.<br><br><strong>The "
    "re-run gives one number</strong>, and it is neither. An engaged player "
    "restores the launch 24 on day 31 (§14.4 says 30) and all 48 on day 92: "
    "pages alone would cover 1,200 by day 68, but the last chapter opens at "
    "Keeper level 24 (7.6), which the run reaches on day 92. The review "
    "added the condition that makes a 48-law day meaningful at all: laws 25 "
    "to 48 ship six a season (26.1), so the day is for a player who starts "
    "once they have. Pages are one pool in the model where the document "
    "keeps them per law, so both days are lower bounds. The edits are "
    "drafted, and land with C19\u2019s regeneration, not before."),

"C36": dict(status="fixed", note=
    "Closed as recommended: priced at §14.2’s four a day, with fatigue. "
    "Re-derived here: four raids are worth 3.19, so 25 clean raids take "
    "25 ÷ (0.1698 × 3.187) = 46.2 to 25 ÷ (0.1222 × "
    "3.187) = 64.2 days, 185 to 257 attempts; every cell of §9.6’s "
    "new four-raid column (1,402 to 49,928) reproduces. The summary and "
    "§32.9 agree."),

"C37": dict(status="fixed", note=
    "<strong>Decided by brief 38: the scout shows no positions.</strong> "
    "§12.12 now says patrols are learned in the heist, and what the crew "
    "sees of one is exactly what it does, because the shift is fixed "
    "from the seed before the heist starts. §12.4 and the scout-report "
    "screen need nothing added. This was the screens’ last open gate."),

"C38": dict(status="fixed", note=
    "Closed: §18.9 derives both from §22.2’s table, about €2,550 and "
    "€18,200 — 10% of €25,500 and €182,000. The check "
    "re-reads the new wording."),

"C39": dict(status="fixed", note=
    "All six closed: §12.11’s <em>“In either form”</em> is gone; "
    "§12.19’s fallback no longer deletes a withdrawn sentence; §12.21 "
    "says two laws; cracking is <em>“about 8 to 15 seconds … at "
    "Vault level 1”</em>; §10.4’s curve is <em>“a fit within "
    "2% of 10.2’s table, and the table governs”</em>; §31.9’s "
    "brief 5 row says the holds were measured before the alignment."),

"D43": dict(status="fixed", note=
    "Closed. §10.2’s Vault row states <em>“Capacity 8,000 of each "
    "of Starlight and Essence at level 1, × 1.85 a level”</em>, so "
    "every number in §29.1 is now stated in the section it cites, and the "
    "check retires."),

"F16": dict(status="fixed", note=
    "<strong>Closed by stating shares by origin.</strong> §13.2’s "
    "<em>“about 60%”</em> and §27.2’s geometry 25% are now "
    "targets for authored islands; a generated island’s shares are "
    "measured by §13.4’s ablation (geometry <em>“about 16% of the "
    "credit on the shaped generator”</em>). The claim this item was "
    "about — that a generated island’s geometry is worth what a "
    "designed one’s is — is no longer made."),

"F17": dict(status="fixed", note=
    "<strong>Closed by the ladder rule, as the spec argued.</strong> The "
    "Aether Spring stops at level 5 (§10.2), because by §9.5’s own "
    "figures the Aether share fails at one half; the Spire’s storage "
    "follows (29,000 at level 6, 34,000 from 7 — re-derived here from "
    "the level-5 Spring’s 199 an hour and the realms open at each Keeper "
    "level), and §9.3, §9.5, §29.1, §31.3 and §32.9 with it. Waking is "
    "<em>“a convenience, not a sink”</em>. The Garden keeps ten "
    "levels, because Essence has its keep. Whether one cut is enough is the "
    "re-run’s to say; §10.2 names level 5 as next if not. "
    "<code>content/buildings.json</code> re-extracted."),

"F19": dict(status="fixed", note=
    "Closed: §14.2 says pacing is a band, and the full re-run publishes "
    "every milestone at the bottom and the top of §9.6’s 1.39× "
    "band, with the sentences quoting the band. The numbers wait on "
    "C19’s re-run."),

"F25": dict(status="fixed", note=
    "Closed: §31.3 adds the rank split, the page costs, the load rate and "
    "the birth rate, and says partial staffing is a rule with one home "
    "(§5.8). All four read back from their declared homes "
    "(<code>content/upstream/constants.json</code>; "
    "<code>check_constants</code> now compares a table-shaped constant by "
    "its figures, so “18 / 12 / 12 / 6” and “18 common, 12 "
    "uncommon, 12 rare and 6 deep” are the same fact). The same "
    "paragraph kept one sentence the change made false (C40)."),

"F31": dict(status="fixed", note=
    "<strong>Closed: rule sheet version 2.</strong> §7.3 has twenty-two "
    "parameters: Touch damage, Unlit drain, Ally healing and Structure "
    "regrowth replace Drain and Healing and regrowth, and §7.7 and §11.11 "
    "name them. That is the split this repository had made; its two names "
    "that differed now follow the document (<code>ally_healing</code>, "
    "<code>structure_regrowth</code>). No parameter’s position moved, "
    "so the rules version and the goldens did not."),

"F32": dict(status="fixed", note=
    "<strong>Decided by brief 37: a reach, drawn as a ring.</strong> Every "
    "five seconds of cracking calls the guards within 5 m of the Vault by "
    "the walking path, and §32.9 sizes the reach by a sweep "
    "(<code>python3 -m tools.heist_harness depth --sweep "
    "crack_reach</code>). Ported to <code>sim/</code> "
    "(<code>path::steps_to</code>; two goldens diverge, at seconds 15 and "
    "43, and were re-recorded) and to the harness, whose rules default is "
    "now v3.4. The sweep is built and run: see F35."),

"G16": dict(status="fixed", note=
    "<strong>Decided by brief 37: the sensor ignores its disarmer.</strong> "
    "Ported: in <code>sim/</code> a raider standing on the tile it was sent "
    "to disarm no longer trips it, and the test that pinned the literal "
    "reading now pins this one; the harness does the same. It covers the "
    "disarmer <em>“while it disarms”</em>, and a disarmer stands on "
    "the tile, so the walk into a Well’s or a Glare’s reach is not "
    "covered: see G18."),

}


V31 = {

# -- closed, and independently verified ------------------------------------

"C7": dict(status="fixed", note=
    "Closed. <code>fixed 30 steps a second</code> appears once in the whole "
    "document, in \u00a724.10, and \u00a77.3\u2019s 20 is gone. v3.1 also "
    "pins it in <code>data/constants.json</code> with the section that owns it, "
    "so a second copy fails the build rather than waiting for an audit."),

"C10": dict(status="fixed", note=
    "Closed. \u00a726.1 now says 31 traits, recounted from \u00a711.3, and "
    "v3.1\u2019s checker recounts it from the table on every build."),

"C17": dict(status="fixed", note=
    "Closed, and better than the drafted edit. \u00a727.2 now reads "
    "\u201cFallbacks, if clearance fails, are Lawkeep and Isleborn \u2014 the "
    "name in use is never its own fallback\u201d. The rule is stated, not just "
    "the correction."),

"C21": dict(status="fixed", note=
    "Closed. \u00a729.1\u2019s detection row is now a suspicion meter and its "
    "ambush row carries \u00a712.8\u2019s health floor. The percent-awareness "
    "phrasing is banned by a build check, so the deleted model cannot leak back "
    "in by hand. All three of this item\u2019s drafted edits now fail to match "
    "the document, which is what retirement looks like."),

"C24": dict(status="fixed", note=
    "Closed. 17 building types in \u00a726.1, and the Library moved into "
    "\u00a710.4 with all ten levels and a stated cost curve \u2014 the seven "
    "missing points this item said the economy model could not price. It is now "
    "a line in \u00a714.4\u2019s page economy as well."),

"C26": dict(status="fixed", note=
    "Closed, and closed the way this item asked. <code>Size</code> and "
    "<code>Flies</code> are columns in \u00a711.2 for all eighteen ruleborn, "
    "held in <code>data/creatures.json</code>, and v3.1\u2019s checker "
    "re-derives the size band from each creature\u2019s own head count rather "
    "than trusting the column. G12\u2019s three laws now read attributes that "
    "exist."),

"G12": dict(status="fixed", note=
    "Closed with C26: Density, Heavy ground and Swarm birth now read "
    "<code>size</code> and <code>flies</code>, which \u00a711.2 carries."),

"D4": dict(status="fixed", note=
    "Closed. \u00a731.8 schedules reconciliation ahead of \u00a726.7\u2019s "
    "locks and calls it a gate rather than a milestone \u2014 which is what "
    "this item asked for, in the document\u2019s own voice."),

"D10": dict(status="fixed", note=
    "Closed. \u00a731.2 splits the repository four ways \u2014 "
    "<code>/spec</code> for decisions, <code>/data</code> for numbers, "
    "<code>/archive</code> for reasoning, <code>/build</code> for output that "
    "nobody edits \u2014 which is this item\u2019s proposal with a fourth "
    "compartment it did not think of: the generated one."),

# -- half closed -----------------------------------------------------------

"C23": dict(note=
    "<strong>Three of four copies fixed; the fourth survives, and the check "
    "written to catch it cannot see it.</strong> \u00a714.4 now derives the "
    "Codex from the five-rank split, and \u00a79.5 and \u00a729.2 both price "
    "<code>10, 20, 35 or 60 pages by rank</code> \u2014 all three of this "
    "item\u2019s edits for those sections no longer match, which is what "
    "retirement looks like.<br><br>\u00a77.6 still reads <em>\u201cRestoring "
    "a law: 15 pages for a common law, 30 for a rare one, 60 for a deep "
    "one.\u201d</em> v3.1 bans the retired scheme by the phrase "
    "<code>15, 30 or 60 pages</code>, which this sentence does not use, so the "
    "build reports the model absent. See F24."),


"C6": dict(note=
    "<strong>Half closed, and the half left open is left open on purpose.</strong> "
    "\u00a711.2 and \u00a711.11 now agree on every ruleborn\u2019s role \u2014 "
    "the check that failed since v2.3 passes \u2014 and v3.1 binds them with a "
    "build check. The ability wordings and cooldowns still differ for all "
    "eighteen, and \u00a731.9 says why: picking one set silently would be a "
    "design decision disguised as a tidy-up. That is the right call, and it is "
    "the first time this register\u2019s open half has been open by decision "
    "rather than by oversight."),

}


V3 = {

# -- resolved in the document ----------------------------------------------

"C1": dict(status="fixed", note=
    "§12.8 now says sight and awareness are \u201cspecified once, in 12.17\u201d and "
    "that the older single-cone, percent-per-second rules are gone. The residue is "
    "tracked as C21: §29.1 still tabulates the deleted model, and cites §12.8 for it."),

"C4": dict(status="fixed", note=
    "§9.6\u2019s base is now <code>B(V)</code> with V stated as \u201cthe target\u2019s "
    "Vault level, one to ten \u2014 not the realm level, which stops at five\u201d. "
    "One paragraph deeper, §9.6\u2019s <em>what is exposed</em> still says the sealed "
    "share runs \u201c40% at realm level 1\u201d while §9.4 says Vault level 1."),

"C5": dict(status="fixed", note=
    "§13.4 keeps the slot limits and drops the second pool in as many words: "
    "\u201cThe older per-realm pool is gone, and these numbers now match 5.2 and "
    "10.2 rather than competing with them.\u201d"),

"G1": dict(status="fixed", note=
    "§12.18 settles it, and adopts the reading in <code>spec/movement.md</code>: tiles "
    "for terrain and building, continuous millitile position and facing, "
    "breadth-first pathfinding with a fixed neighbour order, the command recorded "
    "rather than the path, and crew passing through one another. The rule that "
    "protects premise 3 is stated as a heading: <strong>the crew never makes a "
    "decision the player did not make</strong>."),

"G2": dict(status="fixed", note=
    "§12.20, with §12.8 rewritten around it. One hit per 0.8 s for Power damage on "
    "both sides; fighting allowed but an unambushed hit sends suspicion straight to "
    "1000; ten seconds down, revived in 3 s or 1.5 s by a Mender; loot dropped on "
    "the tile. §29.1 was not updated \u2014 C21."),

"G4": dict(status="fixed", note=
    "§12.19, adopting <code>spec/vault.md</code> whole: every role loads at 30 units "
    "a second, a crew fills in ten seconds, the haul is multiplied by the share of "
    "bags filled, and the break-even sits at 70%. §9.6 carries the new "
    "<code>fill</code> term. §12.6 still says 150 a second \u2014 C22."),

"G6": dict(status="fixed", note=
    "§12.22 gives the five steps: the band, the Bayesian rating with its uncertainty "
    "term, the guarantee that the median offered target sits in the 55\u201370% band, "
    "the widening order when nothing matches, and why the 0.25 payout tier is "
    "unreachable through normal matchmaking."),

"G8": dict(status="fixed", note=
    "§24.13 answers both: one lease per target per player, so a second device is "
    "handed the lease the first holds; and the entry fee is debited at validation "
    "rather than at lease, so an offline heist never submitted costs nothing."),

"F4": dict(status="fixed", note=
    "§12.8 now reads \u201ctriple Power, or half the guard\u2019s full health, "
    "whichever is greater\u201d, and says why: the rule below it was true for three "
    "of twenty-five pairings without it. Verified \u2014 25 of 25 now. §29.1 still "
    "gives triple damage with no floor (C21)."),

"F5": dict(status="fixed", note=
    "§12.19. Loading is ten seconds, every role loads, and the fill fraction is a "
    "term in §9.6\u2019s formula. The check retires \u2014 all 560 units of crew "
    "capacity are now reachable."),

"F1": dict(status="fixed", note=
    "§5.8 decides it: one producer of each kind per realm, partial staffing paying "
    "pro-rata, and \u201cthe roster can never fill everything \u2014 38 ruleborn "
    "against far more positions \u2014 and that is the scarcity the design is built "
    "on\u201d. Scarcity is now a feature by decision rather than by accident."),

"F2": dict(status="fixed", note=
    "§5.8: one, not two, with the model\u2019s reasoning quoted. The published tables "
    "in §9.3 were not regenerated against it \u2014 C19."),

"F3": dict(status="fixed", note=
    "§5.8: \u201cA crew on a heist is assigned to it, like a guard at a post, and "
    "does not work while assigned. Five of thirty-eight is a real choice.\u201d This "
    "is the mechanism the finding recommended, taken whole."),

"Q1": dict(status="fixed", note="Answered by §5.8: scarcity is a feature."),
"Q4": dict(status="fixed", note="Answered by §5.8: one producer of each kind per realm."),
"Q2": dict(status="fixed", note=
    "Answered by §5.8: crew membership excludes work, so the trade-off binds."),

"D14": dict(status="fixed", note=
    "§8.8 changes the rule to three <em>distinct laws</em>, which makes §8.5 true. "
    "It did not achieve what it argued for: the cheapest chord now costs 33 "
    "stability against a day-2 capacity of 51, up from 26, and seven of twelve are "
    "still three commons. The gate that actually makes a chord late-game is the Lab "
    "level 3 at Spire 5, about day 42 \u2014 which §8.5 mentions and §8.8 does not "
    "lean on."),

# -- moved rather than resolved ---------------------------------------------

"C2": dict(note=
    "Half resolved. §9.4\u2019s percentages are deleted \u2014 \u201cthe percentages "
    "this paragraph used to carry are gone\u201d \u2014 and §9.6 is the one formula, "
    "now with a <code>fill</code> term. But §9.6 keeps <code>B(V)</code> rather than "
    "pegging to production, so the faucet still delivers 1\u20132% of income, while "
    "§9.4\u2019s balance target (\u201ca fifth of a day\u2019s production\u2026 "
    "roughly a third\u201d) and §12.1\u2019s 40% are unchanged. The two-model "
    "contradiction is gone; the model-versus-target one is not."),

"C3": dict(note=
    "Changed shape, not resolved. Twelve laws were re-tagged from Rare to Uncommon, "
    "so the sheets now read 18/12/6/12 \u2014 against §7.9\u2019s own table of "
    "18/14/10/6. Deep doubled from 6 to 12. And §7.6, §14.4 and the glossary still "
    "price three ranks at 15/30/60 pages (C23)."),

"C6": dict(note=
    "§30.18 records \u201c11.11 is the roster\u201d, but §11.2 is still a full "
    "hand-authored table and still disagrees with it about Prism Mite, Stormhound "
    "and Rootrunner, plus fifteen wording differences. The decision was taken and "
    "the second copy was not retired."),

"C19": dict(note=
    "The decision is made (\u00a75.8) and the tables were not regenerated against "
    "it. Now measured, by re-running the model under \u00a75.8\u2019s three rules "
    "\u2014 one producer per realm, pro-rata staffing, the crew assigned rather "
    "than timed:<br><br><code>day &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;31 &nbsp;&nbsp;&nbsp;"
    "&nbsp;91 &nbsp;&nbsp;&nbsp;181 &nbsp;&nbsp;&nbsp;301<br>"
    "published &nbsp;17,300 &nbsp;94,100 &nbsp;152,800 &nbsp;256,100<br>"
    "under \u00a75.8 &nbsp;14,633 &nbsp;46,817 &nbsp;&nbsp;62,627 &nbsp;122,495<br>"
    "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-15% "
    "&nbsp;&nbsp;&nbsp;-50% &nbsp;&nbsp;&nbsp;&nbsp;-59% &nbsp;&nbsp;&nbsp;&nbsp;"
    "-52%</code><br><br>"
    "<strong>The first month holds and then the curve breaks.</strong> Keeper 5 "
    "to 20 land within two days of published, which is the evidence the model "
    "reads \u00a75.8 correctly; Keeper 28 is 18 days late and Keeper 40 is "
    "<strong>94 days late</strong> \u2014 half a year becomes nine months. Of the "
    "three rules, assigning the crew costs 27\u201335% from the first week and "
    "pro-rata staffing costs nothing until the roster binds. The re-run is "
    "generated at <code>docs/design/generated/pacing.md</code>."),

"G3": dict(note="Untouched. §10.3 still gives level-1 effects only, with no key for "
                "what §10.2\u2019s \u201ceffect +15%\u201d scales."),

"G5": dict(note="Untouched. §12.6\u2019s pylon sentence is unchanged, so a raider "
                "still cannot tell which law a pylon carries before committing."),

"G10": dict(note=
    "§12.21 states the rule this gap asked for \u2014 \u201cevery tier effect of "
    "every law must be expressible as a change to a named parameter\u201d \u2014 and "
    "names the three parameters that were missing. It does not apply it: no table "
    "carries size or flight (C26)."),

"G12": dict(note=
    "Same as G10. §12.21 declares size a band on every ruleborn and flight a stated "
    "property; §11.1 and §11.11 carry neither, and Featherkin\u2019s flight is still "
    "prose in a Passive column."),

"G9": dict(status="fixed", note=
    "Resolved by removal rather than specification. §13.3 is now \u201cNobody has to "
    "build\u201d: every player has a generated defence from the first minute, "
    "curation is the default creative act and authoring is the deep end. The "
    "60-second guided build is no longer the mitigation for risk #1, because the "
    "risk is designed out instead of tested. See D20."),

"D2": dict(note=
    "Overtaken. §19.27 now answers every pre-code question by simulation rather than "
    "by people, so the published prototype is no longer on the critical path. It "
    "still runs, and it is still the only artefact that can answer the one question "
    "§19.27 says simulation cannot. See D20."),

"D13": dict(status="proposed", note=
    "<strong>Claimed, not done \u2014 and now written out.</strong> \u00a78.8 "
    "states \u201cThe table now runs eight or nine laws per note\u201d. Parsing "
    "all 48 law sheets gives Glow 12, Flow 11, Echo 10, Weight 9, Spark 8, Bloom "
    "8, Veil 7, Hush 6 \u2014 unchanged from v2.3 (C25).<br><br>"
    "<code>tools/note_rebalance.py</code> is the change that paragraph describes, "
    "law by law: <strong>nine edits reach nine laws for every note</strong>, each "
    "argued from \u00a78.1\u2019s own definition rather than chosen to make the "
    "arithmetic work. Flock and Crystal growth give up Glow for Veil because "
    "neither lights up and both transform; Aurora gives up Flow because it moves "
    "nothing; Day and night gains Hush because the light-and-dark law carried "
    "neither Glow nor Hush.<br><br>The tool refuses to emit a proposal that puts "
    "two opposite notes on one law \u2014 which it caught in the first draft, "
    "where Aurora would have carried Glow and Hush \u2014 and checks that every "
    "chord stays reachable afterwards. All twelve do, at unchanged cost."),

"D15": dict(note=
    "Vindicated in the worst way. §30.18 draws exactly this conclusion \u2014 "
    "\u201ca table that exists only to summarise something else should be generated, "
    "never authored\u201d \u2014 and then v3.0 fixed six systems and left stale copies "
    "of four of them (C21\u2013C23, C6). §29.1 is the sharpest case: it is the "
    "formulas appendix, it carries the detection model §12.8 deleted, and it cites "
    "§12.8 as its source."),

"C7": dict(note="Untouched: 20 steps a second and 30 both still appear."),

# -- the clerical sweep, re-checked -------------------------------------
#
# These six were missed on the first pass over v3.0: the six blocking items were
# checked against the new document and this batch was not, so the register went
# on reporting them open for a version. Worth recording as a process note rather
# than quietly correcting — an audit that does not audit itself is the thing
# this register exists to complain about.

"C9": dict(status="fixed", note=
    "Fixed. \u00a723.2\u2019s Law Codex screen now reads \u201call 48 laws by "
    "school and rank\u201d; the stale 36 \u2014 which was the size of Codex "
    "chapter 3 \u2014 is gone."),

"C11": dict(status="fixed", note=
    "Fixed. \u00a721.9\u2019s asset list now says 27 screens, matching "
    "\u00a723.2. The four screens of interface work and their icons are budgeted."),

"C13": dict(status="fixed", note=
    "Fixed, and better than proposed. \u00a712.22\u2019s fifth step states it "
    "outright: \u201cThe 0.25 payout for targets three or more levels below is "
    "unreachable through normal matchmaking by design. It exists for challenge "
    "links, friendly heists and Trace targets.\u201d An unreachable tier that "
    "says why it is unreachable is no longer a contradiction."),

"C14": dict(status="fixed", note=
    "Fixed exactly as drafted. \u00a712.9\u2019s Renown column is now "
    "multipliers \u2014 \u00d71.0, \u00d70.8, \u00d70.5 \u2014 on the "
    "formula\u2019s 8 to 40, and a foiled heist is a flat \u22128 with the "
    "reason stated: \u201crather than a share of a gain that was never "
    "made\u201d. The Haul column was given the same treatment."),

"C15": dict(status="fixed", note=
    "Fixed by C1\u2019s fix. \u00a712.8 no longer gives sight in tiles; it "
    "points at \u00a712.17, which is in metres throughout, and \u00a721.1 "
    "establishes one tile as one metre."),

"C16": dict(status="fixed", note=
    "Fixed. \u00a712 no longer calls a heist \u201ca three-minute run\u201d, so "
    "the opening line and \u00a712.2\u2019s 2.5 to 4 minutes no longer "
    "disagree."),

"C17": dict(note="Untouched: \u00a727.2 still reads \u201cFallbacks are Lawkeep "
                 "and Ruleborn\u201d, and Ruleborn is the chosen name."),

"C12": dict(note="Untouched: \u00a722.5 still says every figure in \u00a722.2 "
                 "assumes 15%, and the high scenario is still computed at 30%."),

"C18": dict(note="Untouched: \u00a79.1 still gives the Aether cap as 5,000 a "
                 "Spire level plus 3,000 against \u00a710.2\u2019s flat "
                 "5,000 \u00d7 level. F17 makes the question larger rather than "
                 "smaller \u2014 either figure is far below what a day produces."),

"Q8": dict(status="fixed", note=
    "Answered, and the document says so in the same breath: \u201c<strong>One "
    "ruleborn stands at one Guardian Post.</strong> That was never stated "
    "anywhere, and it is the missing conversion between counting posts and "
    "counting guards \u2014 without it the two tables could not be reconciled and "
    "defence could have consumed more characters than production.\u201d "
    "\u00a713.4. That is exactly what this decision asked for, including why it "
    "mattered."),

"Q3": dict(note=
    "Still open, the ground has moved under it, and <strong>the argument it was "
    "being decided on has stopped mattering</strong>.<br><br>v3.0 re-tagged twelve "
    "laws from Rare to Uncommon, so the sheets read 18/12/6/12 while "
    "\u00a77.9\u2019s table still says 18/14/10/6 and three other sections "
    "still price three ranks (C3, C23). The question is no longer \u201cthree or "
    "five\u201d but \u201cwhich four\u201d, and it is half-made.<br><br>It was "
    "argued partly on the page economy. The rank split moves the Codex total by "
    "11% \u2014 1,485 pages against 1,320. v3.0\u2019s Library moves the time to "
    "gather it by <strong>five times</strong>: 371 days at no Library, 114 at "
    "level 5, 68 at level 10. A building now decides the page economy, which "
    "frees this decision to be made on what \u00a77.9 says it is about \u2014 "
    "rarity buying specificity rather than strength."),

"Q5": dict(note=
    "Not a question for the document \u2014 it is a proposal to it (D6) \u2014 "
    "but v3.0 changed what the cut would save. F10 classifies the 48 laws: 16 are "
    "parameter changes and 32 need an engine feature, so cutting to 24 laws saves "
    "very different amounts depending which 24. The same is true of "
    "\u00a711.10\u2019s 144 forms, which is the largest single art number in the "
    "project."),

"Q6": dict(note=
    "Still open, still listed in \u00a727.3, and <strong>the number it rests on "
    "is now wrong in the harder direction</strong>. \u00a727.5 settles the shape "
    "\u2014 \u201ca visible, openly labelled catch-up discount on levels the "
    "median player passed long ago\u201d \u2014 and nothing specifies it. The "
    "1,019 days was computed before \u00a75.8. Re-run under \u00a75.8\u2019s "
    "rules, Keeper 40 moves from day 181 to 275 for an engaged player, 274 to 368 "
    "for a regular one, and <strong>556 to 733 for a casual one</strong>. The "
    "casual curve slips 177 days against 94 for the other two, because a flat "
    "five characters withheld for a crew is a larger share of a smaller roster "
    "and partial staffing bites sooner when there is less of everything.<br><br>"
    "Scaling \u00a727.3\u2019s own figure by that drift puts finishing "
    "everything at roughly <strong>1,343 days</strong> \u2014 three years and "
    "nine months. <code>python3 tools/decision_support.py pacing</code>."),

"Q7": dict(note=
    "Unchanged. \u00a727.3 still lists eight decisions under \u201cDecisions for "
    "Francisco\u201d: casual pacing, final names and the trade-mark check, "
    "whether the Island Fund survives its own test, whether the two weak "
    "variables in \u00a719.4 are worth strengthening, \u201cuniverse\u201d or "
    "\u201cyour sky\u201d, Law Clash rules, soft-launch countries, and whether "
    "constellations get a competitive mode."),

"C8": dict(note=
    "Half fixed, and the other half is a fifth supersession. \u00a710.4 gives the "
    "Library a placement and a table \u2014 3 pages a day at level 1, 9 at 5, 18 "
    "at 10, \u201cacross the universe\u201d. \u00a77.6 still says it produces "
    "\u201cabout one page per realm every few hours\u201d, which across seven "
    "realms is roughly 40 a day. The two differ by about four times, and "
    "\u00a77.6\u2019s is the sentence a reader meets first.<br><br>"
    "\u00a710.4 also gives three of the ten levels \u2014 1, 5 and 10 \u2014 "
    "where every other building in \u00a710.2 lists every one, and \u00a726.1 "
    "still counts 16 building types where there are now 17 (C24)."),


"C20": dict(status="fixed", note=
    "Fixed, and the fix is the honest one. \u00a721.8 no longer claims a signature "
    "per law: \u201cEvery school has a sound signature \u2014 six in all \u2014 so "
    "a player can hear which kind of rule is running.\u201d Six signatures for six "
    "schools is what the content actually holds, so the sentence now describes the "
    "game rather than an aspiration."),
"C10": dict(note="Untouched: 31 traits authored, 30 in §26.1, a 32nd named in §17.3."),
"F6": dict(note="Untouched. The Breaker is still 63% of the crew\u2019s damage against "
                "every breakable object."),
"G11": dict(note="Untouched: §20.6 still says English and Portuguese at launch, §26.2 "
                 "still says twelve languages."),
}


# ===========================================================================
# What to type, and where
# ===========================================================================
#
# `rec` above says what should happen. This says what to type. It is a separate
# object for the same reason V3 is: "what was found" and "what to do about it"
# change on different schedules, and an edit list wants to be read sitting beside
# the document with both open.
#
# Each edit is a dict:
#
#   section   the section to open, as the contents lists it
#   action    replace | delete | insert | regenerate | retag
#   find      the text as it stands today, verbatim
#   replace   what to put there (omit for `delete`)
#   why       one line, where the reason is not obvious from the item
#
# `regenerate` names a file in docs/design/generated/ to paste from.
# `retag` is a change to a content value rather than a sentence — a law's notes,
# a creature's role — and names the law or creature in `target`.
#
# tools/check_edits.py verifies every `find` against the document (and every
# `retag` against content/), and fails the build on a miss or an ambiguity.

# ===========================================================================
# What cannot be settled from inside this repository
# ===========================================================================
#
# Most of the register is arithmetic against the document, or a measurement the
# harness can make. These are the items that are not: they need a number from
# the outside world, and no amount of re-reading §26.1 will produce it.
#
# Each entry is the question to take away, written so it stands alone.

# ---------------------------------------------------------------------------
# Backend or frontend
# ---------------------------------------------------------------------------
#
# The split exists to answer one question: when can the design of realms,
# screens and characters start? So the rule is about *who does the work*, not
# about which chapter the item lives in.
#
#   backend   resolved by changing a rule, a number, a formula or simulation
#             code. An engineer or a systems designer does it, and nothing is
#             drawn.
#   frontend  resolved by drawing, writing, laying out, recording or building a
#             screen. An artist, a level designer or a UI designer does it.
#   both      genuinely needs each. Nine items, and each is listed with why —
#             a count that is also an art budget, a roster whose rows are both
#             stats and creatures.
#
# Most items are backend, so only the exceptions are listed. `check_sides()` in
# check_edits.py fails if an id here is not in the register.
#
# Being on the backend side does not mean an item is irrelevant to design. Most
# of what gates the design work is backend, which is the point of DESIGN_GATES
# below: the question is not which side an item is on but what it holds up.
FRONTEND = {
    "C9":  "the Codex screen's own text — fixed by editing a screen spec",
    "C11": "how many screens there are to draw",
    "C20": "author 48 law sounds, or correct the claim to six school sounds",
    "C17": "the game's public name and its fallback",
    "G9":  "the 60-second guided build: an onboarding flow and its screens",
    "G11": "localising a coined vocabulary into twelve languages",
}

BOTH = {
    "C6":  "roles are stats; eleven of the eighteen are different creatures, "
           "which is character art",
    "C8":  "the Library is an economic faucet and a seventeenth building to draw",
    "C10": "a trait count in the data, and a line in \u00a726.1's launch content",
    "C24": "seventeen building types: a count, and four building looks "
           "\u00a721.9 does not budget",
    "C26": "size and flight as columns, and as properties the art must show",
    "G12": "the same, seen from the three laws that read those attributes",
    "G3":  "ward rules and levels, and the ward art \u00a721.9 budgets",
    "D6":  "the scope cut halves the laws (backend) and the forms, resonances "
           "and languages (frontend)",
    "Q5":  "accepting that cut is one decision over both",
    "F16": "designed geometry beats generated eleven to one, which is a "
           "statement about level design as much as about the generator",
    "F12": "eight laws need an act of authorship from whoever lays out a realm",
}


def side_of(item_id: str) -> str:
    if item_id in FRONTEND:
        return "frontend"
    if item_id in BOTH:
        return "both"
    return "backend"


# ---------------------------------------------------------------------------
# What the design work is waiting on
# ---------------------------------------------------------------------------
#
# The two-part split says where an item's work happens. This says when the
# design of each thing can start, which is the question the split was asked
# for. Each entry names the open items that decide something a designer would
# otherwise have to guess, and what each one changes about the drawing.
#
# An area with nothing open is one where design can start now.
#: Who has to move next on each gate, so an area can say whether the drawing
#: can start rather than only how far along it is.
#:
#: The question this answers is "when do I hand realms, screens or characters
#: to someone who will draw them", and the useful answer is not a percentage.
#: It is one of three things:
#:
#:   yours    Everything that can be measured has been, the edit is drafted,
#:            and what is left is a decision only the owner of the project can
#:            make. Nothing here moves without an answer.
#:   mine     There is still analysis or drafting in it. It is not a clean
#:            choice yet, and presenting it as one would be asking the owner
#:            to decide something nobody has laid out.
#:   outside  It needs something this repository cannot produce: a playtest, or
#:            evidence about what other games shipped.
#:
#: An area is ready to hand over when it has no open gates at all. Until then
#: the verdict says who is holding it, which is the thing worth knowing: an
#: area waiting only on `yours` is one conversation from starting, and an area
#: with a `mine` in it is not, however few gates it has left.
#:
#: Keyed by item rather than by (area, item), because the owner is a property
#: of the question. C6 gates the screens and partly gates the characters, and
#: who has to answer it does not change between them.
GATE_OWNER = {
    # -- realms ---------------------------------------------------------------
    "C19": "yours",    # the re-run is done (pacing.md); the tables are the document's to take
}

#: The three verdicts an area can carry, worst first. `ready` is the only one
#: that means the drawing can start.
HANDOFF = ("mine", "yours", "ready")

DESIGN_GATES = {
    "realms": dict(
        what="Terrain layout, what an island holds, how a realm is drawn",
        gates={
            "C19": "how many producers a realm holds is stated \u2014 one "
                   "of each \u2014 but the day and income columns a realm is "
                   "paced by still ship from the earlier run; the full re-run "
                   "is generated and waits on the document taking it",
        },
        closed={
            "C5":  "how many wards and posts a realm may hold \u2014 three "
                   "different limits, now one",
            "Q8":  "how many ruleborn stand at one Guardian Post: one",
            "C1":  "one detection model, so a guard's sight cone is a shape "
                   "that can be drawn",
            "C15": "guard vision in tiles rather than metres, which is the "
                   "unit a layout is drawn in",
            "G1":  "how a crew moves through a realm, which decides what a "
                   "route has to look like",
            "F26": "how many wards a realm holds: 8, 8, 6, 7 and 8, set by "
                   "the hold band (v3.3)",
            "F27": "where each realm's defence starts: one post slope, a start "
                   "per realm level (v3.3)",
            "F22": "one guard post at realms 1 and 2, with eight wards (v3.3)",
            "F9":  "the hold band a generated realm must reach, stated per "
                   "realm level (v3.3)",
            "F11": "the generator weaves only laws that help the defender "
                   "(v3.3)",
            "F12": "one placement rule for the eight authored law choices "
                   "(v3.3)",
            "G3":  "what a ward senses, what a level scales, and that a "
                   "footprint never grows (v3.3)",
            "G5":  "a pylon shows its law before the detour (v3.3)",
        }),
    "screens": dict(
        what="The 27 screens in \u00a723, their contents and their counts",
        gates={},
        closed={
            "C37": "what the scout report shows: no patrol positions; "
                   "patrols are learned in the heist (v3.4, brief 38)",
            "C11": "how many screens there are: 27, not 23",
            "C9":  "how many laws the Codex screen shows: 48, not 36",
            "C10": "how many traits a character screen lists: 31",
            "C24": "how many building types the build screen offers: 17",
            "C6":  "which ability text a character screen shows: \u00a711.2 "
                   "is generated from the \u00a711.11 cards (v3.3)",
            "C8":  "the Library is in \u00a710.2 with every other building "
                   "(v3.3)",
            "C3":  "four ranks at 10/20/35/60, stated one way everywhere "
                   "(v3.3)",
        }),
    "characters": dict(
        what="The 18 ruleborn, their forms, and what the art has to show",
        gates={},
        closed={
            "C26": "size and flight are stated properties of every ruleborn, "
                   "so the art has a band to draw to",
            "G12": "the three laws that read those properties now have them",
            "D6":  "54 forms: three notes for every kind (v3.3)",
            "Q5":  "the cut is taken (v3.3)",
            "C6":  "what each of the eighteen is, and its ability, from one "
                   "card (v3.3)",
        }),
}

RESEARCH = {
    "Q5": "How much content do comparable mobile builders actually ship at "
          "launch, counted the way \u00a726.1 counts \u2014 distinct rules, "
          "creature forms, building types, languages \u2014 and how much did "
          "they add per season afterwards? \u00a726.1 asks a team of one "
          "designer, one coding agent and three contractors for 48 laws, 144 "
          "creature forms, 39 terrain features and 12 languages.",
    "D6": "Which of a launch content set actually drives retention in this "
          "genre: breadth of distinct rules, or depth in a few? The proposed "
          "cut halves the laws and keeps the Island Workshop, and nothing "
          "outside this repository has been consulted about that trade.",
    "D9": "What is the reference-class ratio of iteration work to first-build "
          "work for a novel genre blend with no reference implementation? "
          "\u00a726.8 estimates ~270 agent runs to build and then states that "
          "the iteration needed to find the fun is unbudgeted.",
    "F10": "What does each kind of law effect really cost to build \u2014 a "
           "parameter change against a spawned entity against a periodic rule "
           "\u2014 on a deterministic fixed-tick mobile simulation? "
           "`scope_cut.py` weights them 0 / 3 / 2 by judgement, and "
           "the ordering is what the conclusion rests on.",
    "C12": "What are the current Apple and Google commission tiers and the "
           "revenue thresholds that move a developer between them, and what "
           "does that do to a revenue band either side of the boundary? "
           "\u00a722.2\u2019s high scenario is computed at a different rate "
           "from the other two and \u00a722.5 does not say so.",
    "G11": "What does it cost to localise a coined vocabulary \u2014 roughly "
           "130 invented proper nouns \u2014 into twelve languages, and who "
           "normally owns that work on a team of this size? \u00a726.3 "
           "assigns nobody.",
    "C29": "How do small teams recruit ten to twenty playtesters for a "
           "pre-release mobile build, what does it cost, and what consent and "
           "privacy position does handling pre-release content with outside "
           "testers require? \u00a726.2 gates two phases on those people and "
           "\u00a725.4 says they do not exist.",
    "C20": "What does a per-school sound set cost against a per-law one, and "
           "do players in comparable games actually distinguish audio cues at "
           "that granularity? \u00a721.8 now claims six school signatures "
           "where it once claimed 48.",
    "Q6": "How do comparable games handle a player who is years behind the "
          "curve, and does a visible, openly labelled catch-up discount hold "
          "up in practice? \u00a727.5 settles on one and never specifies it, "
          "against a finishing time of roughly 1,343 days.",
    "Q7": "Trade-mark clearance for the name, in the launch territories. "
          "\u00a726.9 makes it a gate on any public use and it costs nothing "
          "to start.",
    "F13": "How do comparable games fill a matchmaking band when the candidate "
           "pool cannot supply it \u2014 bots, staged targets, widening, or "
           "something else? \u00a712.22 promises a median target in a band "
           "that does not exist early.",
}


# ===========================================================================
# What has to be settled before what
# ===========================================================================
#
# `DEPENDS[x] = [y, ...]` means **x cannot be finished until y is**. Kept here
# rather than as a field on a hundred dicts, for the same reason EDITS is: one
# table is reviewable, a hundred scattered lines are not.
#
# Three kinds of edge, all of them the same shape for the reader:
#
#   * a **decision** gates the work that rests on it (Q3 before C3);
#   * a **measurement** gates the item it explains (F22 before F11, because the
#     generator cannot reach the band until §5.2 allows a second guard post);
#   * a **supersession** gates its own residue (C1 before C21, because §29.1
#     cannot be regenerated until the model it restates is settled).
#
# Every edge below is argued in the item's own text. `tools/check_dependencies.py`
# rejects an id that does not exist and a cycle, and `docs/design/dependencies.md`
# is generated from it.

DEPENDS = {
    # -- detection: one model, and the copies that still carry the old one
    "C21": ["C1", "D15"],
    "C15": ["C1"],

    # -- the raid payout, which is one chain from the level term outward
    "C2": ["C4"],               # §9.6's L is undefined until C4 says what it is
    "F14": ["C2", "D16"],       # the fill term hangs off §9.6's formula and the load rate
    "F19": ["F14", "F21"],      # what an attempt pays, and how far skill moves it
    "G4": ["C2", "D16"],

    # -- sinks and storage
    "C18": ["F17"],             # the cap only means something under a pegged upkeep
    "C28": ["F17"],             # births only bind once Essence is scarce

    # -- the economy tables, and the decisions §5.8 took
    "Q1": ["Q8"],               # posts-to-guards is the missing conversion
    "Q4": ["Q1"],
    "C19": ["Q1", "Q4"],
    "C27": ["Q1"],
    "Q6": ["C19"],              # the 1,019 days predates §5.8's re-run

    # -- law rarity, and the building that now decides the page economy
    "C24": ["C8"],
    "Q3": ["C8"],
    "C3": ["Q3"],
    "C23": ["C3"],

    # -- the roster, and the attributes three laws read
    "C6": ["D15"],              # §11.2 becomes a generated index
    "G12": ["C26"],

    # -- the generator: the chain this session measured end to end
    "F22": ["C5", "Q8"],
    "F26": ["F22", "F7"],
    "F27": ["F26"],        # §5.2's post count is inside C5's budget question
    "F11": ["F22"],
    "F9": ["F22", "F11"],
    "F13": ["F11"],
    "F12": ["F11"],
    "F16": ["F9"],

    # -- defence balance
    "F15": ["F16", "F8", "C5"],
    "F20": ["D25", "F15"],      # the Spire's reach is what makes 70% nearly true
    "F21": ["F20"],

    # -- the Vault phase
    "D16": ["F5"],
    "C22": ["D16"],
    "D17": ["F4"],
    "G2": ["F4"],

    # -- wards and pylons
    "G3": ["C5"],
    "G5": ["G3"],

    # -- laws as engine features
    "G10": ["F10"],             # F10 supplies the classification this gap asked for
    "F10": ["C26"],             # three laws read attributes no table carries
    "F23": ["D14"],
    "D14": ["D13"],
    "C25": ["D13"],

    # -- scope, which everything about size runs through
    "D6": ["F10"],
    "Q5": ["D6", "F10", "F23"],
    "G11": ["Q5"],

    # -- validating without players
    "C29": ["D20"],
    "G9": ["D20"],
    "D4": ["C1", "C2", "C3", "C5", "C6"],   # nothing locks while a system has two specs
}


#: An item's effective status, and the one place it is worked out.
#:
#: A register item carries a `status` written when it was found, and V3 and V31
#: record what each version of the document did about it. The effective status
#: is the latest of the three that has an opinion — v3.1 first, then v3.0, then
#: the item's own field.
#:
#: **This existed twelve times.** Every tool that needed it wrote the three-line
#: expression again, and four of those copies were written before V31 existed
#: and never learned about it: `build_audit._status_of`, `build_roadmap.status_of`,
#: `check_dependencies.status_of` and `check_edits`'s coverage report each read
#: v3.0's answer and stopped. The nine items v3.1 closed therefore read as open
#: in all four — which is why the audit page's own "Where to start" section
#: said sixty items were open under a header that said thirty-four, and listed
#: nine settled items as work to do.
#:
#: That is §31.2's rule — one fact, one home — broken by the tool that reports
#: it, on the page it reports it on. So it lives here, beside the data, and
#: `check_docs_consistency.check_one_status_home` refuses a second copy.
SETTLED = frozenset({"fixed", "done", "adopted", "withdrawn"})

#: Resolved on paper and waiting for sign-off: not settled, not untouched.
DRAFTED = frozenset({"proposed"})


def status(item) -> str:
    """The effective status of a register item, by id or by the item itself."""
    item_id = item if isinstance(item, str) else item["id"]
    own = {} if isinstance(item, str) else item
    return (V34.get(item_id, {}).get("status")
            or V33.get(item_id, {}).get("status")
            or V32.get(item_id, {}).get("status")
            or V31.get(item_id, {}).get("status")
            or V3.get(item_id, {}).get("status")
            or own.get("status")
            or next((i.get("status", "open") for i in REGISTER
                     if i["id"] == item_id), "open"))


def status_before_v33(item_id: str) -> str:
    """What an item's status was before v3.3's layer, for counting what it did."""
    own = next((i for i in REGISTER if i["id"] == item_id), {})
    return (V32.get(item_id, {}).get("status")
            or V31.get(item_id, {}).get("status")
            or V3.get(item_id, {}).get("status")
            or own.get("status", "open"))


def status_before_v34(item_id: str) -> str:
    """What an item's status was before v3.4's layer, for counting what it did."""
    own = next((i for i in REGISTER if i["id"] == item_id), {})
    return (V33.get(item_id, {}).get("status")
            or V32.get(item_id, {}).get("status")
            or V31.get(item_id, {}).get("status")
            or V3.get(item_id, {}).get("status")
            or own.get("status", "open"))


def is_open(item) -> bool:
    """Whether there is still work in it — drafted but unsigned counts as open."""
    return status(item) not in SETTLED



EDITS = {
"G40": [
    dict(section="5.4", action="insert",
         find="unless the spot is in fog, darkness or tall grass.",
         replace="The whole crew lands together on the one spot, before anything "
                 "else it does. The six tiles are walked, as every sound travels "
                 "(12.17); a guard already above 250 keeps what it has. Fog, "
                 "darkness and tall grass are on the spot itself, and darkness is "
                 "the unlit ground 12.17 sees by.",
         why="Each is a reading the simulation had to make; stated, "
             "the landing picker can show exactly what a guard would hear."),
],


"C40": [
    dict(section="31.3", action="replace",
         find="The facts the register recorded twice that are tables or curves "
              "rather than one figure \u2014 the rank split and page costs, the "
              "load rate, partial staffing, the birth curve and the notes each "
              "law carries \u2014 are guarded by recomputation instead (31.5)",
         replace="The facts the register recorded twice that are rules or curves "
                 "rather than one figure \u2014 partial staffing, the birth curve "
                 "and the notes each law carries \u2014 are guarded by "
                 "recomputation instead (31.5)",
         why="The rank split, the page costs and the load rate are rows of the "
             "table above as of v3.4. C40."),
    dict(section="31.3", action="regenerate",
         replace="In data/constants.json, set rank_split's home to "
                 "\u201c7.9 Rank is a strength ladder, paid for in pages\u201d "
                 "and regenerate the table: \u00a710.4 cites \u00a77.9 for the split.",
         why="A declared home should not defer to another section. C40."),
],

"G18": [
    dict(section="10.3", action="replace",
         find="While it disarms, the ward\u2019s sensor ignores that crew member, "
              "so every known ward can be disarmed",
         replace="From the moment a crew member sets out to disarm a known ward "
                 "until it finishes or turns aside, the ward\u2019s sensor "
                 "ignores it, so every known ward can be disarmed",
         why="A disarmer stands on the tile; a Well senses 3 tiles out and a "
             "Glare 2, so the walk there crosses the sensor. G18."),
],

"C34": [
    dict(section="10.3", action="replace",
         find="Health is 500 a level for every ward except Crystal Wall, whose "
              "health is its effect; disarming is below.",
         replace="Every ward except Crystal Wall has health, set below with "
                 "smashing and disarming; Crystal Wall's health is its effect.",
         why="\u00a710.3's last paragraph derives 550 and moved it from 500 on "
             "purpose; the opening sentence is the copy the edit missed. C34."),
],

"C38": [
    dict(section="18.9", action="replace",
         find="at the high scenario about \u20ac16,800",
         replace="at the high scenario about \u20ac18,200",
         why="10% of \u00a722.2's high scenario, about \u20ac182,000 since C12. "
             "C38."),
],

"C39": [
    dict(section="12.11", action="replace",
         find="In either form, two or three friends",
         replace="Two or three friends",
         why="Only the asynchronous form is left (D48). C39."),
    dict(section="12.21", action="replace",
         find="Three laws read properties no creature had",
         replace="Two laws read properties no creature had",
         why="The sentence names two, Density and Heavy ground. C39."),
    dict(section="31.9", action="replace",
         find="Brief 5: generated hold rates re-measured on the aligned harness",
         replace="Brief 5: generated hold rates as a band the generator must "
                 "hold; the aligned re-measurement is pending (13.2)",
         why="\u00a713.2 says the holds were measured before the alignment. "
             "C39."),
],

"C33": [
    dict(section="6.2", action="replace",
         find="Guards on higher ground see 2 tiles further per level",
         replace="Guards on higher ground see further (12.17 owns how far)",
         why="\u00a712.17: \"a level higher sees a metre further\". C33."),
    dict(section="6.2", action="replace",
         find="Hides anyone inside from guards more than 2 tiles away",
         replace="Hides anyone standing still inside (12.17 owns the rule)",
         why="\u00a712.17 hides only a still crew member, from everything outside "
             "the tile. C33."),
    dict(section="6.2", action="replace",
         find="Crunchy: footsteps carry 1 tile further",
         replace="Crunchy: louder underfoot (12.17 owns how much)",
         why="\u00a712.17 makes gravel \u00d71.25, not a tile further. C33."),
],

"C32": [
    dict(section="10.2", action="replace",
         find="effect +0%, resets 10 s",
         replace="effect +0%, resets as 10.3 gives each ward",
         why="\u00a710.3 gives Time Snare 12 s and Lantern Glare 20 s at level 1; "
             "this row gives every ward 10 s. The later rows become a reduction "
             "by level (\u221210, \u221220, \u221230, \u221240%). C32."),
],

"F28": [
    dict(section="12.6", action="replace",
         find="every 5 seconds adds 100 suspicion to every guard in the Heart",
         replace="every hit is heard within 5 m, as breaking something is, and "
                 "every 5 seconds every guard in the Heart hears the Vault and "
                 "starts investigating it",
         why="Suspicion added to an unaware guard drains at 20 a tick "
             "(\u00a712.17), so 100 is gone in five ticks and never moves "
             "it. A sound moves it: \u00a712.17's \"600, or on hearing "
             "something\". F28."),
],

"F29": [
    dict(section="12.17", action="replace",
         find="Guards far off screen hear at half strength",
         replace="A crouched walk is heard only on the tile it is made on, so a "
                 "crew can step up beside a guard unheard \u2014 the way into "
                 "12.8's ambush. Guards far off screen hear at half strength",
         why="The tile beside a guard is 1 m away and a crouched walk carries "
             "1 m, so the last step of every approach is heard and the ambush "
             "cannot be reached on plain ground. F29."),
],

"F30": [
    dict(section="12.19", action="replace",
         find="Cracking is 10 to 25 seconds of pressure with no decision in it",
         replace="Cracking takes 10 to 25 seconds with a Breaker in the crew "
                 "\u2014 without one it takes 26 or more \u2014 and it is "
                 "pressure with no decision in it",
         why="Measured against 12.6's 1,500 health and 12.20's cadence: the "
             "band holds only for crews with a Breaker. F30."),
],

"G13": [
    dict(section="12.17", action="replace",
         find="Being crouched halves how fast you are noticed, running raises it "
              "by three quarters",
         replace="Being crouched halves how fast you are noticed and halves your "
                 "speed, running raises it by three quarters and doubles your "
                 "speed",
         why="Neither gait has a speed anywhere, so crouching is free and the "
             "slow-and-quiet choice does not exist. G13."),
],

"G14": [
    dict(section="12.20", action="replace",
         find="An ally standing adjacent revives it in 3 seconds, a Mender in 1.5",
         replace="An ally standing adjacent revives it in 3 seconds, a Mender in "
                 "1.5, at a quarter of its health",
         why="The revive's health is unstated. G14."),
],

"C31": [
    dict(section="12.12", action="replace",
         find="guards' patrols shift slightly each run",
         replace="guards' patrols shift slightly each run \u2014 drawn once from "
                 "the heist's seed as it starts, so a scout still sees exactly "
                 "what will happen (12.17)",
         why="Otherwise \u00a712.17's \"nothing here is random\" is false. C31."),
],

"D53": [
    dict(section="13.4", action="replace",
         find="Wards follow the rule already in 5.2: three plus the realm "
              "level.",
         replace="Wards follow the rule already in 5.2: three plus the realm "
                 "level. Law slots follow 5.2 too \u2014 one at realm levels "
                 "1 and 2, two at 3 and 4, three at 5 \u2014 so the column "
                 "above reads 1, 2, 3 at the levels it shows.",
         why="\u00a713.4 says \u00a75.2 is the home of the law slots and "
             "then tabulates 1/3/5 where \u00a75.2 gives 1/2/3 at the same "
             "levels. Wards and guard posts already agree; this is the one "
             "column that does not. D53."),
],

"D51": [
    dict(section="9.6", action="replace",
         find="rises by 3.5 points a level to 71.5% at Vault level 10 "
              "(9.4 owns this)",
         replace="rises by 3.5 points a level to 71.5% at Vault level 10 "
                 "(10.2 owns this)",
         why="\u00a79.4 gives the two ends and never the step, so a reader "
             "sent there cannot check the 3.5. \u00a710.2's Vault ladder "
             "tabulates all ten rows at 3.5-point intervals and is the only "
             "one of the rule's homes that does. D51."),
],

"D49": [
    dict(section="11.10", action="replace",
         find="Eighteen kinds and eight notes make 144 forms.",
         replace="Eighteen kinds and three notes make 54 forms, the launch "
                 "figure 32.5 settles. Say which three, because the table "
                 "below still lists eight and the note a form takes is what "
                 "decides its look and its quirk.",
         why="\u00a732.5 decides that 54 ships and nine sections still say "
             "144. This is the home and the only one that <em>derives</em> "
             "the number, so it is the one that has to change first \u2014 "
             "and 54 is not eighteen by eight, so the rule has to change with "
             "it. If 54 is provisional rather than settled, the row belongs "
             "in 32.3 instead, with the other four decided-not-applied "
             "mechanisms. D49."),
],

"D50": [
    dict(section="32.5", action="replace",
         find="The creator fund therefore ships with a stated review date",
         replace="The Island Fund therefore ships with a stated review date",
         why="\u00a726.9 records that the Creator Fund became the Island "
             "Fund, and both rename tables are marked as quotation. This "
             "sentence is the project's own fund under its retired name. "
             "D50."),
    dict(section="31.5", action="insert",
         find="which the phrase ban could not see",
         replace="Wrap this column in the "
                 "<code>&lt;!--allow-retired--&gt;</code> marker the rename "
                 "tables use. It quotes retired models in order to say they "
                 "are banned, which is the one place they belong and exactly "
                 "what the marker is for \u2014 without it a checker reads "
                 "the quotation as the claim, and one did.",
         why="The column is quotation and nothing says so, so the derived "
             "page-cost check reported \u00a731.5 as carrying the retired "
             "three-rank costs. It cannot tell a quotation from a claim; the "
             "marker is how the document tells it. D50."),
],

"D47": [
    dict(section="19.2", action="replace",
         find="At most eight controls, 44-point targets, no reflex "
              "requirements, one-finger play (12.7, 24.8)",
         replace="At most eight controls, each at least 9 mm across and none "
                 "in a screen corner, no reflex requirements, one-finger play "
                 "(12.7, 21.8)",
         why="\u00a712.7 says \u201ceach at least 9 mm across, which is "
             "roughly 48 points, and none in a screen corner\u201d, and this "
             "cell claims to report \u00a712.7. \u00a730.4 rejected the "
             "44-point minimum, so this is the one sentence in the document "
             "its correction was aimed at. \u00a724.8 is the database schema; "
             "the interface home is \u00a721.8, which \u00a712.7 itself "
             "cites. D47."),
],

"D48": [
    dict(section="23.2", action="replace",
         find="Friends' feed, friendly heists, co-op lobby, gifts",
         replace="Friends' feed, friendly heists, invitations, gifts",
         why="Co-op heists ship in version 1.1 (12.11, 26.1, 27.2) and "
             "\u00a723.2 is the launch screen list \u2014 none of the other "
             "three after-launch modes appears in it. A lobby is also the "
             "wrong object: \u00a730.8 rejected real-time co-op and "
             "\u00a712.11 makes the first version asynchronous and "
             "turn-based, which has an invitation and a queue. D48."),
    dict(section="12.11", action="insert",
         find="two or three friends raid one universe together, sharing one "
              "clock and splitting the loot evenly",
         replace="Say which screens 1.1 adds, since 23.2 lists only the ones "
                 "built at launch: an <b>invitation</b> on the Friends screen "
                 "and a <b>turn queue</b> showing whose move it is and what "
                 "the crew has done so far. Naming them here keeps the "
                 "asynchronous decision (30.8) attached to the interface it "
                 "implies, which is what the word \u201clobby\u201d in 23.2 "
                 "lost.",
         why="The screen and the mode were specified in different sections "
             "and only the mode was updated when the design moved from "
             "real-time to asynchronous. D48."),
],

"D43": [
    dict(section="29.1", action="replace",
         find="Up to 25% of the Vault's exposed amount and 50% of each "
              "Storehouse passed, capped by carrying capacity, plus 10% and a "
              "league bonus",
         replace="B(V) × grade × difficulty × richness × "
                 "fatigue × fill, where B(V) = 100 × "
                 "1.5<sup>V−1</sup> on the target's Vault level",
         why="§9.4 says in so many words that the percentages this row "
             "copies are gone, and this row cites §9.4. The live model is "
             "§9.6's minted haul. The Section column changes to 9.6 with "
             "it. D43, C2, C21."),
    dict(section="29.1", action="replace",
         find="8,000 × 1.85level − 1 each of Starlight and Essence; "
              "sealed share 40% + 3.5 points per level above 1",
         replace="8,000 × 1.85<sup>level − 1</sup> each of Starlight "
                 "and Essence, sealed share 40% + 3.5 points per <b>Vault</b> "
                 "level above 1; every level is listed in 10.2",
         why="The formula is right and the address is wrong: the Vault's "
             "capacity ladder is tabulated in §10.2, level by level, from "
             "8,000 to 2,030,700, and §9.4 says nothing about capacity, "
             "so the Section column becomes 10.2. A wrong address is invisible "
             "from either end, which is why this one survived. The row then "
             "follows the form the <em>Building cost</em> row in the same table "
             "already uses — “every level is listed in 10.2” — "
             "and naming the Vault level settles C4’s question in the fourth "
             "place that rule is stated. D43."),
    dict(section="12.17", action="replace",
         find="the far zone in just under three",
         replace="the far zone in 2.8 seconds",
         why="§29.1 gives 2.8 s and §12.17 gives a phrase, so the "
             "appendix is the only prose in the document carrying a number "
             "the simulation reads every tick — 12 suspicion a tick at 30 "
             "ticks a second, which content/detection.json already stores as "
             "2.8. The precise value belongs in the section that specifies "
             "the model. D43."),
],

"D44": [
    dict(section="5.4", action="replace",
         find="150 seconds plus 15 seconds for each link on the shortest "
              "route from the landing realm to the Heart, up to 240 seconds.",
         replace="150 seconds plus 15 seconds for each link on the shortest "
                 "route from the landing realm to the Heart, up to 240 "
                 "seconds. Haste makes the clock run 25% faster while the crew "
                 "is in its realm.",
         why="The clock's home is here and the Haste clause is only in "
             "§12.5, so a player pricing a route from this row is wrong "
             "by a quarter in any realm running Haste. How a clock runs "
             "belongs with the clock. D44."),
    dict(section="12.5", action="replace",
         find="Heist clock = 150 seconds + 15 seconds × links on the "
              "shortest route from the landing realm to the Heart, up to 240 "
              "seconds. Haste makes the clock run 25% faster while the crew "
              "is in its realm.",
         replace="The heist clock is set at landing and depends on the route "
                 "chosen here (5.4).",
         why="The second of the clock's three homes. Once §5.4 carries "
             "the Haste clause this paragraph adds nothing but a copy to keep "
             "in step. §31.2. D44."),
    dict(section="19.2", action="replace",
         find="Albums start partly filled and show what's left (14.8)",
         replace="Albums and tracks start partly filled and show what's left "
                 "(14.8)",
         why="§19.11 says “albums and tracks” and §14.8 "
             "settles it — “the season track's first tier is "
             "complete on day one”. Two cells citing one home and no "
             "longer agreeing. D44."),
    dict(section="2.7", action="replace",
         find="With a third of monthly players playing on a given day, that "
              "means 60 to 120 million monthly players.",
         replace="With a third of monthly players playing on a given day "
                 "— 25.1's gate — that means 55 to 110 million "
                 "monthly players.",
         why="18.3 m and 36.7 m daily players divided by a third is 55 m and "
             "110 m. The paragraph's claim is that the forecast is earned by "
             "arithmetic, so the last step should be the arithmetic, and the "
             "gate it divides by should be named where it is used. D44."),
],

"D31": [
    dict(section="7.9", action="replace",
         find="A deep law is more dramatic, not more efficient - and every rare "
              "and deep law appears in the scout report (12.5). Raiders can see "
              "it coming and plan around it. This visibility is charged against "
              "the law's strength the way range is charged against a "
              "character's kit, and it is the primary reason a rare law can be "
              "exciting without being unfair.",
         replace="A deep law is more dramatic, not more efficient. Every law in "
                 "a realm appears in the paid scout (12.4), at 20 Aether per "
                 "realm and valid for fifteen minutes, so raiders can see one "
                 "coming and plan around it - but they see a common law "
                 "coming on the same terms, which means visibility cannot be "
                 "what pays for a deep law's strength. What pays for it is "
                 "stability cost, and that is the dial this section separates "
                 "from rarity.",
         why="\u00a712.5 is Planning; the scout report is \u00a712.4, and it "
             "shows every rank alike. The paragraph names this as the primary "
             "reason the split is fair, so a mechanism that does not "
             "discriminate by rank cannot be left standing as one. D31."),
],

"F26": [
    dict(section="13.2", action="insert",
         find="Below a quarter, defenders feel helpless and stop designing. "
              "Above half, raiding feels futile",
         replace="Say where this band applies. Measured across every setting "
                 "10.2 and 5.2 permit \u2014 one to three guard posts, nought to "
                 "two geometry bands, Guardian Post levels 1 to 5 \u2014 at the "
                 "depths 12.6\u2019s decision target implies, <b>a generated "
                 "island at realm 1 cannot reach it</b>: the strongest on one "
                 "post holds 24.2% and the weakest on two holds 62.4%, so this "
                 "15-point band sits inside a 38-point gap. Realm 2 reaches it "
                 "only with a Guardian Post at level 3, which 10.2 says an "
                 "engaged player builds on day 36, against a realm that opens on "
                 "day 5. The lever that reaches it is wards: at one guard "
                 "post and one geometry band, realm 1 holds 30.8% with ten "
                 "wards and 19.2% with the four 5.2 allows. Either raise "
                 "5.2’s ward count at realm 1, or say this band is a "
                 "target for realms 3 and up.",
         why="\u00a713.2 sets the number and nothing checks a realm against it. "
             "The band is not merely missed at realm 1 \u2014 it is unreachable, "
             "which is a different kind of problem from a tuning miss and has a "
             "different fix. F26."),
],

"F27": [
    dict(section="10.2", action="insert",
         find="guard +10% health and sight",
         replace="Say what a Guardian Post upgrade is for, because measured "
                 "against 13.2\u2019s 30\u201345% hold band it does three "
                 "different things depending on the realm. The ladder moves a "
                 "defence about 12 points from level 1 to level 5, which is "
                 "well matched to a 15-point band \u2014 but 5.2\u2019s post "
                 "formula decides where each realm starts, and of five realms it "
                 "lands one inside. At realm 2 the ladder is <b>required</b> to "
                 "reach the band (26.2% to 38.8%); at realm 3 it is free (34.2% "
                 "to 44.4%); at realms 4 and 5 it <b>carries the defence out of "
                 "the band</b> (40.0% to 52.7% and 55.3%). A player buying an "
                 "upgrade is not told they are leaving the design\u2019s own "
                 "health metric.",
         why="The ladder is the right instrument and the base is misaligned, so "
             "the fix is 5.2\u2019s starting defence per realm rather than "
             "10.2\u2019s slope \u2014 a steeper slope was measured and it moves "
             "the problem up the realm levels instead of solving it. Either way "
             "this row should say what the upgrade does to the band. F27."),
],

"F22": [
    dict(section="10.2", action="replace",
         find="Every realm; 1 to 3 by realm level.",
         replace="Every realm; 2 to 3 by realm level.",
         why="The one change measured that brings realms 1 and 2 within reach of "
             "§13.2’s 30–45% band at all. At one post the ceiling is "
             "16.5% at realm 1 and 21.5% at realm 2, against a band that starts at "
             "30% — so no generator can get there, whatever it does. The second "
             "post is worth 35 points, more than every other lever combined. It "
             "costs one ruleborn per realm against a roster of 38 (§13.4: one "
             "ruleborn stands at one post), and realms 1 and 2 are where every new "
             "player starts."),
],

"F6": [
    dict(section="12.6", action="replace",
         find="Who cracks, who loads, when to stop loading",
         replace="Who loads, and when to stop loading",
         why="“Who cracks” has one answer in every situation at every "
             "level: the Breaker, whose doubled Power of 80 is 63% of a five-crew’s "
             "126 against wards, pylons and the Vault. Adding four characters to a "
             "lone Breaker cuts the time by 37%. Either drop it from the list of "
             "decisions, or give a second character on the same object a stacking "
             "bonus so joining in is worth the exposure — what is not defensible "
             "is calling it a decision while one role is two thirds of the answer."),
],

"F20": [
    dict(section="12.19", action="replace",
         find="The break-even sits at about 70% full — at that point the extra "
              "load is worth exactly what a loud exit costs.",
         replace="The break-even sits at about 70% full once the Spire’s reach "
                 "is re-sealing the Vault as the crew loads (13.2); with nothing "
                 "re-sealing it, the best fixed rule is nearer 90%.",
         why="Measured over 700 paired raids a threshold, stopping at 90% beats "
             "§12.19’s 70% by +0.0364 ± 0.0080 an attempt (t = 4.5) "
             "for 1.3 points of success rate. So the number is not wrong — it is "
             "<em>unimplemented</em>: it describes the game as it would be with a "
             "mechanism §13.2 names and never specifies. At a re-seal of 20 a "
             "second with §9.6’s own floor applied, the peak moves to 80% "
             "and the hold rate stays at 44.5%, inside the band."),
],

"F21": [
    dict(section="13.2", action="insert",
         find="We watch the spread of clean runs, partial hauls and foiled raids, "
              "and treat a populated middle as the goal.",
         replace="Say which population. An ordinary crew has exactly the populated "
                 "middle this asks for — 70% of its successful raids land "
                 "between 20% and 80% full. A crew that reads §12.17’s "
                 "suspicion meters has <b>16%</b> in the middle: it sweeps on a "
                 "quarter of its raids and comes home with almost nothing on more "
                 "than half. The warning sign is tripped, and it is tripped for the "
                 "players who read the game best — the ones who post replays and "
                 "set what everyone else copies.",
         why="The metric fails on its own terms, for the worst possible population, "
             "and tuning the break-even does not fix it: F20 moves the threshold and "
             "the polarisation moves with it. What would populate the middle is a "
             "reason to leave at a fill the crew did not choose in advance — the "
             "Spire’s reach, a flatter Carry spread, or a price on abandoning."),
],

"F12": [
    dict(section="13.3", action="insert",
         find="Swap a law, move a post, pick a different generated layout, name it.",
         replace="State one rule for the eight laws whose effect is an act of "
                 "authorship rather than a number: <b>place every authored "
                 "parameter against the shortest route from the landing edge "
                 "to the Heart \u2014 along it for what costs a crosser to "
                 "pass, across it for what costs a crosser to cross, and never "
                 "so that the route is sealed.</b> \u00a76.1 already makes the "
                 "generator compute that route, so this needs no machinery it "
                 "does not have; \u00a712.5 makes \u201ctoward the "
                 "Heart\u201d and \u201cagainst the raider\u201d the same "
                 "direction; and \u00a712.7 makes the loaded escape the half "
                 "worth spending on. The eight: Current blowing toward the Heart; Heat bloom braziers on the route, at the Vault approach; Inward pull the shortest-path direction to the Heart, per tile; Lodestones flanking the route, two tiles clear of it; Shifting stones a loop crossing the route at right angles; Slow rivers streams across the route, in the inner third; Soul lanterns lanterns on the route, covering each Guardian Post’s approach; Tilt downhill toward the Heart. Lodestones "
                 "is the only one placed off the route \u2014 a pull on the "
                 "route drags a crew along it rather than off it \u2014 and "
                 "its clearance is what keeps \u00a76.1 true without a second "
                 "check.",
         why="These were fine while authoring was the default. \u00a713.3 "
             "makes curation the default and authorship the deep end, so for "
             "most islands the generator now makes these choices \u2014 and a "
             "badly chosen slope or stream turns the defender\u2019s law into "
             "the raider\u2019s. Each of the eight is argued from the document "
             "by <code>python3 tools/law_effects.py</code>."),
],

"C21": [
    dict(section="29.1", action="replace",
         find="+50% a second in sight, +75% within 3 tiles; investigate at 50%, "
              "alarm at 100%",
         replace="Suspicion 0\u20131000, filling 67 a tick in the near zone, 33 in "
                 "the mid and 12 in the far, draining 20 a tick. Suspicious at 200, "
                 "investigating at 600, alerted at 1000. A state cannot fall back "
                 "for 15 ticks.",
         why="\u00a712.8 says the percent-per-second rules are gone; the formulas "
             "appendix is where an implementer looks for them."),
    dict(section="29.1", action="replace",
         find="First unseen hit: 2 s stun and triple damage; a level advantage "
              "counts for at most 3 levels",
         replace="First unseen hit: 2 s stun, and triple Power or half the "
                 "target\u2019s full health, whichever is greater. A level "
                 "advantage counts for at most 3 levels.",
         why="\u00a712.8 added the floor and \u00a729.1 did not follow."),
    dict(section="5.4", action="replace",
         find="guards within 6 tiles of the landing spot start at 25% awareness",
         replace="guards within 6 tiles of the landing spot start at 250 suspicion",
         why="25% is a unit \u00a712.17 replaced. 250 of 1000 is the same fraction "
             "in the unit that survives."),
],

"C22": [
    dict(section="12.6", action="replace",
         find="Once open, each Carrier loads 150 loot a second until full or until "
              "the exposed share is gone.",
         replace="Once open, every role loads 30 units a second until full or until "
                 "the exposed share is gone, so a crew fills in about ten seconds "
                 "(12.19).",
         why="\u00a712.19 fixed the rate and the set of roles; \u00a712.6 still "
             "carries the sentence \u00a712.19 was written to correct."),
],

"C23": [
    dict(section="7.6", action="replace",
         find="Restoring a law: 15 pages for a common law, 30 for a rare one, 60 "
              "for a deep one.",
         replace="Restoring a law: 10 pages for a common law, 20 for an uncommon "
                 "one, 35 for a rare one, 60 for a deep one.",
         why="Twelve laws were re-tagged to Uncommon and this sentence never "
             "learned the rank exists. The last three-rank statement left in "
             "the document, and the one v3.1\u2019s banned-phrase check cannot "
             "see, because it says the same thing with the clause rearranged "
             "(F24)."),
    dict(section="14.4", action="replace",
         find="Restoring all 48 laws: 15 commons \u00d7 15 + 18 rares \u00d7 30 + "
              "12 deep \u00d7 60 = 1,485 pages (the three starting laws are free)",
         replace="Restoring all 48 laws: 15 commons \u00d7 10 + 12 uncommons "
                 "\u00d7 20 + 6 rares \u00d7 35 + 12 deep \u00d7 60 = 1,320 pages "
                 "(the three starting laws are free)",
         why="The change log gives 1,350, which counts all 18 commons; "
             "\u00a714.4\u2019s own convention excludes the three free ones, so "
             "the figure on that convention is 1,320."),
    dict(section="9.5", action="replace",
         find="| 15, 30 or 60 pages by rank\n\n| Tier II, tier III",
         replace="| 10, 20, 35 or 60 pages by rank\n\n| Tier II, tier III",
         why="The price list. Quoted with the row after it, because the same "
             "cell also appears in \u00a729.2\u2019s glossary and the two have "
             "to be found separately."),
    dict(section="29.2", action="replace",
         find="| 15, 30 or 60 pages by rank; tier II +20 pages and 2,000 Aether; "
              "tier III +40 pages and 8,000 Aether",
         replace="| 10, 20, 35 or 60 pages by rank; tier II +20 pages and 2,000 "
                 "Aether; tier III +40 pages and 8,000 Aether",
         why="The glossary, which carries the same figure a third time."),
],

"C24": [
    dict(section="26.1", action="replace",
         find="| Building types\n| 16",
         replace="| Building types\n| 17",
         why="\u00a710.4 added the Library and the launch table did not follow."),
    dict(section="10.2", action="insert",
         find="10.5 The Library",
         replace="Move \u00a710.4\u2019s table into \u00a710.2, between Ward and "
                 "Resonance Lab, and give it all ten levels rather than 1, 5 and "
                 "10. \u00a710.2 is headed \u201cEvery level of every "
                 "building\u201d and the economy model cannot price a faucet from "
                 "three of its points.",
         why="A building outside the building table is how C8 happened the first "
             "time."),
],

"C25": [
    dict(section="7.7", action="retag", target="Flock",
         find="Bloom Glow", replace="Bloom Veil",
         why="Six puffballs that wander, block paths and make guards react are "
             "deception. Nothing about Flock lights up."),
    dict(section="7.7", action="retag", target="Crystal growth",
         find="Bloom Glow", replace="Bloom Veil",
         why="Stone regrowing as crystal is a transformation, which is Veil\u2019s "
             "own word."),
    dict(section="7.7", action="retag", target="Leapfrog",
         find="Flow Glow", replace="Flow Spark",
         why="Nothing lights up; the second clause is a noisy landing, and an "
             "impact is a burst."),
    dict(section="7.7", action="retag", target="Soul swap",
         find="Veil Flow", replace="Veil Hush",
         why="The swap is a disappearance at the instant of a knockout, not a "
             "change to how anyone moves."),
    dict(section="7.7", action="retag", target="Aurora",
         find="Glow Flow", replace="Glow",
         why="Aurora moves nothing. It cannot take Hush instead \u2014 that is "
             "Glow\u2019s opposite \u2014 so it becomes a one-note law, as 25 of "
             "the 48 already are."),
    dict(section="7.7", action="retag", target="Lodestones",
         find="Weight Echo", replace="Weight",
         why="Nothing in Lodestones returns, repeats or rewinds."),
    dict(section="7.7", action="retag", target="Day and night",
         find="Echo", replace="Echo Hush",
         why="The light-and-dark law carries neither Glow nor Hush. "
             "\u201cVision halves in the dark\u201d is Hush exactly."),
    dict(section="7.7", action="retag", target="Honeycomb",
         find="Weight", replace="Weight Hush",
         why="Sticky ground is quieter; \u00a712.17\u2019s noise table has moss "
             "quieter and water louder, which is why Slow rivers is not the "
             "candidate."),
    dict(section="7.7", action="retag", target="Rewind",
         find="Echo", replace="Echo Bloom",
         why="Restoring broken things is healing as much as repeating."),
    dict(section="8.1", action="replace",
         find="The number shows how many of the 48 laws carry each note.",
         replace="The number shows how many of the 48 laws carry each note: nine "
                 "of each, which is the balance 8.8 requires of every future "
                 "season.",
         why="The figure in the diagram has to move with the sheets."),
],

"C26": [
    dict(section="11.1", action="insert",
         find="| Job in a heist",
         replace="Add two columns to the role table, or two rows to every entry in "
                 "11.11: <b>Size</b> (small / standard / large, derived from the "
                 "proportions already given) and <b>Flies</b> (yes / no). 12.21 "
                 "says both are stated properties; today flight is prose in "
                 "11.2\u2019s Passive column, which is exactly the implication "
                 "12.21 says it must not be.",
         why="Density, Heavy ground and Swarm birth read attributes no character "
             "carries."),
],

"C27": [
    dict(section="9.2", action="replace",
         find="| Staffing sets 60%, 85% or 100% output",
         replace="| A producer runs at the share of its worker slots that are "
                 "filled (5.8)",
         why="\u00a75.8 is the later rule and pro-rata is what makes partial "
             "staffing a choice rather than a rounding."),
    dict(section="9.3", action="replace",
         find="staffing (0.6, 0.85 or 1.0)",
         replace="staffing (the share of the worker slots that are filled)",
         why="The caption in \u00a79.2 and this coefficient are the same rule "
             "twice, and this is the half that computes. Deleting only the "
             "caption leaves every production figure in the document derived "
             "from the rule the caption was deleted for."),
],

"C7": [
    dict(section="7.3", action="replace",
         find="The simulation runs at a fixed 20 steps a second so heists replay "
              "identically on the server.",
         replace="The simulation runs at a fixed 30 steps a second so heists replay "
                 "identically on the server (24.10).",
         why="\u00a724.10 is the simulation contract and is self-consistent: it "
             "gives a heist as 4,500\u20137,200 ticks, which is 30 \u00d7 "
             "150\u2013240 seconds. Settle it before the golden replays, which "
             "encode it."),
],

"C6": [
    dict(section="11.2", action="retag", target="Prism Mite",
         find="Carrier", replace="Scout",
         why="\u00a711.11 is the authoritative roster per \u00a730.18, and gives "
             "Prism Mite as a Scout."),
    dict(section="11.2", action="retag", target="Stormhound",
         find="Scout", replace="Carrier"),
    dict(section="11.2", action="retag", target="Rootrunner",
         find="Carrier", replace="Scout"),
    dict(section="11.2", action="regenerate", from_="roster.md",
         replace="Replace \u00a711.2\u2019s whole table with the generated roster "
                 "index, which is emitted from the same data \u00a711.11 "
                 "describes. Fifteen further rows differ on ability wording, "
                 "cooldown or resistance; regenerating fixes all of them at once "
                 "and stops the pair drifting again."),
],

"C19": [
    dict(section="9.3", action="regenerate", from_="pacing.md",
         replace="Replace \u00a79.3\u2019s production table, \u00a710.2\u2019s "
                 "\u201cEngaged player builds it\u201d and \u201cIncome hours to "
                 "afford\u201d columns, \u00a714.2\u2019s Keeper days and "
                 "\u00a714.3\u2019s milestone rows with the full re-run, each "
                 "cell a band across \u00a79.6\u2019s two edges, and \u00a75.2\u2019s "
                 "realm-level column and \u00a75.5\u2019s capacities with the same "
                 "run. Then move every pacing sentence the tables break: Keeper 40 "
                 "is day 349\u2013357, not 275; everything is built on day "
                 "699\u2013719, not 378. First decide G22\u2019s three choices, "
                 "since the tables are their consequence, and F38, since "
                 "\u00a79.5\u2019s birth rule has no rate to set until it is.",
         why="This item\u2019s own recommendation was to regenerate rather than "
             "hand-edit, because hand-editing is what produced it."),
],

"C35": [
    dict(section="14.4", action="replace",
         find="Engaged: 60 days \u00d7 16 = 960, then 210 \u00f7 23 = 9 more \u2014 "
              "about 69 days",
         replace="Engaged: 60 days \u00d7 16 = 960, then 210 \u00f7 23 = 9 more "
                 "\u2014 about 69 days of pages (68 in the re-run); but the last "
                 "chapter opens at Keeper level 24 (7.6), so a player who starts "
                 "once all 48 have shipped restores them no earlier than the day "
                 "that level arrives, day 92 in the re-run (14.2)",
         why="The full re-run gives one day for both \u00a714.3 and \u00a714.4, "
             "and it is the chapter gate\u2019s, not the pages\u2019. It reads right "
             "only beside C19\u2019s regenerated \u00a714.2, whose Keeper 24 is day "
             "92; land the two together."),
    dict(section="14.3", action="replace",
         find="all 48 in about 69 days for an engaged player and about 195 for "
              "one who never raids, the launch 24 in about 30 and 80.",
         replace="the launch 24 on day 31 for an engaged player, and all 48 \u2014 "
                 "for one who starts once every season\u2019s laws have shipped "
                 "(26.1) \u2014 no earlier than Keeper level 24, day 92. A player "
                 "who never raids does not reach Keeper level 12 on these rules "
                 "(14.2), so their figures wait on where such a player\u2019s "
                 "experience comes from.",
         why="The headline is the launch set, which a player at launch can "
             "restore; the full Codex is published with its condition. The "
             "never-raids figures cannot be computed until F37 is decided, and "
             "a sentence should not quote a number no rule reaches."),
],

"F14": [
    dict(section="9.6", action="replace",
         find="An attempt is worth about 46% of a clean same-level haul, which is "
              "the number the progression curve is built on: an upgrade costing 25 "
              "clean raids takes about 55 attempts, or nine days at six a day, at "
              "every level.",
         replace="An attempt is worth about 24% of a clean same-level haul \u2014 "
                 "46% from the grade split, times the roughly half a crew fills its "
                 "bags before leaving (12.19) \u2014 which is the number the "
                 "progression curve is built on: an upgrade costing 25 clean raids "
                 "takes about 105 attempts, or seventeen days at six a day, at "
                 "every level.",
         why="The fill term was added to the same formula and 0.46 was not "
             "re-derived against it. Either this, or state that fill is already "
             "inside 0.46 \u2014 but not both, and not neither."),
],

"F15": [
    dict(section="13.2", action="insert",
         find="| Bells, alarms, the Spire\u2019s reach, and the guardian "
              "Sage\u2019s single power. What turns being seen into being caught",
         replace="Measured across all 32 combinations, guards and response "
                 "contribute nothing whatsoever without each other, in any of the "
                 "eight coalitions \u2014 so they are one layer at 69%, against "
                 "this section\u2019s own 25% ceiling. Either merge them into one "
                 "row (\u201cdetection and response\u201d) or say what the "
                 "Spire\u2019s reach and the Sage\u2019s single power actually "
                 "do; both are named here and neither is defined.",
         why="\u201cWhat turns being seen into being caught\u201d makes the layer "
             "multiplicative with guards, and two layers that multiply cannot have "
             "independent shares. Giving response a standalone effect was tried "
             "and measured and does not change the shares (spec/response.md)."),
    dict(section="13.2", action="insert",
         find="| Where the Vault sits, which routes exist, what can be seen from "
              "where, chutes that force a choice, bridges that drop on alarm.",
         replace="Geometry measures 4.4% of the defence, and wards and laws fare "
                 "no better at 20.9% and 5.7%, because all three work by delay and "
                 "delay reaches an outcome only through the clock \u2014 which "
                 "ends a run at about 40 seconds of \u00a75.4\u2019s 165. Say "
                 "which layers are meant to decide outcomes and which are meant to "
                 "shape the haul; as written every share is a share of the same "
                 "thing and three of them cannot reach it.",
         why="The 25% ceiling is unreachable while three of the five layers have "
             "no path to the quantity \u00a713.4 measures."),
    dict(section="13.4", action="replace",
         find="It means this, exactly: run the same thousand raids against the "
              "island with that layer switched off, and see how much the hold "
              "rate falls.",
         replace="It means this, exactly: run the same thousand raids against the "
                 "island with that layer switched off, and see how much of the "
                 "haul it denies \u2014 grade \u00d7 fill, the two terms of "
                 "9.6\u2019s formula a defence can move.",
         why="The hold rate cannot see a defence that costs the raider loot "
             "rather than the raid. A defence that turns every clean run into a "
             "partial one takes 60% of the raider\u2019s income (9.6) and scores "
             "zero. Measured this way the guards/response identity breaks; "
             "measured by hold rate it cannot."),
],

"C4": [
    dict(section="9.6", action="replace",
         find="the sealed share runs 40% at realm level 1 and rises by 3.5 points "
              "a level to 71.5% at level 10 (9.4)",
         replace="the sealed share runs 40% at Vault level 1 and rises by 3.5 "
                 "points a level to 71.5% at Vault level 10 (9.4)",
         why="One paragraph below the table that fixed this. \u00a79.4 already "
             "says Vault level; the curve has ten steps and realms stop at five."),
],

"C3": [
    dict(section="7.9", action="replace",
         find="| Uncommon\n| 14\n| Conditional, with a mild cost\n| 20",
         replace="| Uncommon\n| 12\n| Conditional, with a mild cost. Two per "
                 "school\n| 20",
         why="The sheets say 12, and 14 cannot divide by six schools \u2014 so "
             "the table\u2019s own \u201cThree per school\u201d and \u201cOne "
             "per school\u201d cannot both be honoured at 14. The per-school "
             "cell is added because the two ranks that carry one are the two "
             "that already divided evenly, which is how the other two went four "
             "versions without anyone noticing they could not."),
    dict(section="7.9", action="replace",
         find="| Rare\n| 10\n| Strong inside a condition you have to build for\n| 35",
         replace="| Rare\n| 6\n| Strong inside a condition you have to build "
                 "for. One per school\n| 35",
         why="The sheets say 6. 10 does not divide by six either."),
    dict(section="7.9", action="replace",
         find="| Deep\n| 6\n| Changes how a realm works. Heavy stability cost and "
              "a real trade-off. One per school\n| 60",
         replace="| Deep\n| 12\n| Changes how a realm works. Heavy stability cost "
                 "and a real trade-off. Two per school\n| 60",
         why="The sheets say 12, which is two per school rather than one. This "
             "is the one to look at hardest: Deep doubled, and \u201cone per "
             "school\u201d was part of the argument for what Deep is. "
             "\u00a714.4\u2019s 1,350 is computed from 12, so the page economy "
             "has already been written on the sheets\u2019 reading."),
],

"C10": [
    dict(section="26.1", action="replace",
         find="| Traits\n| 30\n| +5 each season",
         replace="| Traits\n| 31\n| +5 each season",
         why="\u00a711.3 enumerates 31. \u00a717.3 also names a \u201crare "
             "Starborn trait\u201d that appears in neither, so either add it to "
             "\u00a711.3 and make this 32, or cut the reference."),
],

"G3": [
    dict(section="10.3", action="insert",
         find="A rope bridge can carry a Snap instead of a ward",
         replace="Add a column saying which number \u00a710.2\u2019s \u201ceffect "
                 "+15%\u201d scales, under one rule: <b>never a distance</b>, "
                 "because a ward whose radius grows on upgrade covers tiles it did "
                 "not cover when it was placed. Gravity Well scales its hold, "
                 "Crystal Wall its health, Time Snare its freeze, Thorn Hedge and "
                 "Static Coil their damage, Lantern Glare its reveal. Static Coil "
                 "has no damage value at all and needs one \u2014 8% of maximum "
                 "health a shock, following Thorn Hedge\u2019s units. Also state "
                 "the three trigger kinds the wording already implies: passive "
                 "(Crystal Wall, Thorn Hedge), aura (Static Coil), triggered "
                 "(Gravity Well, Time Snare, Lantern Glare).",
         why="Drafted in full at docs/design/spec/wards.md, with ward health and "
             "the disarm action \u00a712.5\u2019s Tinker trait presumes."),
],

"F8": [
    dict(section="12.6", action="replace",
         find="| The clock turns red for its last 30 seconds",
         replace="| The alarm meter, which is what actually rises. The clock turns "
                 "red for its last 30 seconds, and rarely decides anything",
         why="Simulated across four depths and three skill levels, the last ten "
             "seconds decide 0% of runs \u2014 a median run finishes in 45 to 150 "
             "seconds against a clock of 150 to 195. Near-captures happen in 100%. "
             "The tension is in the guards and this sentence points at the clock."),
],

"F13": [
    dict(section="12.22", action="insert",
         find="the middle of the list is drawn from the 55 to 70% band (13.2)",
         replace="Say what the matchmaker does when the band is <b>empty</b> rather "
                 "than merely sparse. Measured, a generated island at realm level 1 "
                 "or 2 holds 2\u201313% \u2014 a raider success rate of 87 to 98% "
                 "\u2014 so there is no 55 to 70% candidate to draw a median from, "
                 "and step 4\u2019s widening cannot produce a target that is not "
                 "there.",
         why="The promise depends on \u00a713.3\u2019s generator reaching "
             "\u00a713.2\u2019s band, and F11 measures that it does not."),
],

"F11": [
    dict(section="13.3", action="insert",
         find="Generated from their realm, their laws and their ruleborn \u2014 "
              "legal, coherent, and never empty",
         replace="Add what the generator optimises for, and the band it must hit. "
                 "\u201cGenerated from their laws\u201d has at least three "
                 "meanings and two are worse than nothing: weaving the "
                 "player\u2019s laws at random holds 2\u20139% against 7\u201343% "
                 "for weaving none, because only four of the nineteen laws a rule "
                 "sheet can express help the defender and laws apply to everyone in "
                 "the realm (7.3). Reading the sign of each law recovers it "
                 "(9\u201354%). And \u00a713.2\u2019s 30\u201345% hold rate "
                 "should be a stated requirement on the generator, not only on "
                 "designed islands.",
         why="\u201cLegal, coherent and never empty\u201d are all true of these "
             "islands. Effective is a different requirement and is not stated."),
],

"D14": [
    dict(section="8.5", action="replace",
         find="Chords are the late-game discovery: they need three distinct laws in "
              "play and a Lab of level 3 to identify.",
         replace="Chords are the late-game discovery: they need three distinct laws "
                 "in play and a Lab of level 3 to identify, which is the gate that "
                 "makes them late \u2014 a Lab of level 3 needs a Spire of 5, about "
                 "day 42.",
         why="The three-distinct-laws rule fixed the sentence and not the outcome: "
             "the cheapest chord costs 33 stability against a day-2 capacity of 51, "
             "and seven of twelve are still three commons. The Lab is doing the "
             "gating and \u00a78.8 does not lean on it."),
],

"C2": [
    dict(section="9.4", action="replace",
         find="Balance target: a successful heist against an even match brings "
              "about a fifth of a day's production, so heists supply roughly a "
              "third of an active player's resources.",
         replace="Balance target: a successful heist against an even match brings "
                 "a few per cent of a day's production, so heists supply well "
                 "under a tenth of an active player's resources. Raiding is a "
                 "page faucet and a Renown faucet; it is not how a player gets "
                 "rich.",
         why="\u00a79.6\u2019s formula is the one that pays, and it delivers "
             "1\u20132% of income \u2014 half that again once v3.0\u2019s fill "
             "term is applied (F14). Either this sentence changes or the formula "
             "does; the register\u2019s own recommendation is the production peg "
             "in docs/design/spec/economy.md, which would let it stand as "
             "written."),
    dict(section="12.1", action="replace",
         find="| About 40% of mid-game growth",
         replace="| A few per cent of mid-game growth, and most of the pages",
         why="The same figure stated a third time, and the largest of the three."),
],

"G5": [
    dict(section="12.6", action="replace",
         find="Pylons: breaking one switches its law off for the rest of the heist "
              "and gives a page of it. It's often worth a detour.",
         replace="Pylons: breaking one switches its law off for the rest of the "
                 "heist and gives a page of it. A pylon shows its law\u2019s "
                 "school colour and note glyphs, and the law banner names it on "
                 "approach (15.3), so the detour is a choice rather than a "
                 "gamble. It costs about 1% of a heist at pylon level 1 and 9% at "
                 "level 10.",
         why="\u00a712.6 and \u00a75.7 both assume the raider knows what they "
             "are breaking before committing, and nothing says they can. The "
             "level table and health are already in \u00a710.2."),
],

"C29": [
    dict(section="26.2", action="replace",
         find="At least 7 of 10 outside playtesters ask for a second session; "
              "15 or more decisions per heist",
         replace="On the slice\u2019s own two realms and eight laws rather than "
                 "generated islands: 15 to 25 decisions a median run, a "
                 "near-capture in half of runs, and a hold rate of 30 to 45% "
                 "with no layer above a quarter (19.27, 13.4). And the one "
                 "human instrument 19.27 offers: the developer opens the build "
                 "unprompted on at least 10 of 14 consecutive days, logged by "
                 "the build rather than remembered \u2014 one person, weak "
                 "evidence, recorded as weak.",
         why="\u00a725.4 rules out recruited playtesters and \u00a719.27 moves "
             "every human instrument to soft launch, two phases later. As "
             "written this gate cannot be met, so 10 to 12 weeks of work has no "
             "exit. The replacement is weaker and says so: <em>would they come "
             "back unprompted</em> is the question \u00a719.27 concedes "
             "simulation cannot answer. Depends on T1.10. Drafted in full at "
             "docs/design/spec/validation.md."),
    dict(section="26.2", action="replace",
         find="No dominant law in bot runs; at least 20% of testers still "
              "playing after a week",
         replace="No dominant law in bot runs (13.4)",
         why="The first half already stands on the ablation and needs nobody. "
             "The second needs recruited testers a phase before 19.27 allows a "
             "player to exist."),
    dict(section="25.4", action="insert",
         find="No recruited panels, no paid playtesters, no thirty people in a "
              "room.",
         replace="If this sentence stands, say so in 26.2 as well, whose phase "
                 "2 and phase 3 exit tests still require ten outside "
                 "playtesters and a week of retention. If it does not stand, "
                 "this sentence is the one to change \u2014 and the plan then "
                 "owes a recruitment route, a delivery channel (TestFlight is "
                 "phase 4) and a consent position for pre-release content, none "
                 "of which the document contains.",
         why="One of the two sections is stale and nothing says which. This is "
             "the owner\u2019s decision, not a clerical fix \u2014 T1.10."),
],

"G11": [
    dict(section="26.2", action="insert",
         find="Languages at launch: English and Portuguese (Portugal and Brazil).",
         replace="Reconcile with \u00a726.2\u2019s global launch line, which "
                 "still promises twelve languages. Two at launch and twelve at "
                 "global are compatible if the document says so; as written they "
                 "read as a contradiction, and twelve languages against a coined "
                 "vocabulary \u2014 48 law names, 44 resonances, 12 chords, 18 "
                 "creatures \u2014 has no owner in \u00a726.3\u2019s team.",
         why="The scope decision in stage 4 turns on this: languages are the "
             "single largest line in \u00a726.1 that nobody is assigned to."),
],

"G10": [
    dict(section="12.21", action="insert",
         find="The rule: every tier effect of every law must be expressible as a "
              "change to a named parameter.",
         replace="Then list the parameters. \u00a77.3 asserts laws are parameters "
                 "and the document never says what the parameters are, so the "
                 "rule cannot be applied while authoring \u2014 which is when it "
                 "says it should be. Written out against a twenty-word rule "
                 "sheet, 16 of the 48 laws are parameter changes and nothing "
                 "else; 10 need an object the simulation must spawn, 16 need a "
                 "periodic or conditional rule, and 8 need a choice from the "
                 "realm\u2019s owner. Tag each law with which, so a scope cut can "
                 "drop the expensive ones rather than the unpopular ones "
                 "(F10). And let each parameter's name say whom it changes: "
                 "healing allies who stand together and healing structures and "
                 "guards are two parameters, not one (F31).",
         why="A vocabulary that grows to fit each new law is not a vocabulary. "
             "The classification is at tools/law_effects.py and the table at "
             "content/law_effects.json."),
],

"G12": [
    dict(section="11.11", action="insert",
         find="Size is a band on every ruleborn: small, standard or large, derived "
              "from its proportions rather than invented separately.",
         replace="Then put it in the table. \u00a712.21 states size and flight as "
                 "properties and no entry in \u00a711.1 or \u00a711.11 carries "
                 "either, so Density, Heavy ground and Swarm birth still read "
                 "attributes that do not exist. Two columns close it. Same edit "
                 "as C26.",
         why="A law reading a parameter that is not in any table is the failure "
             "\u00a712.21 describes, still present in the section that "
             "describes it."),
],

"C8": [
    dict(section="21.9", action="replace",
         find="| Building looks (16 types x 4) | 64",
         replace="| Building looks (17 types x 4) | 68",
         why="\u00a726.1 and \u00a710.4 both say seventeen. The art schedule "
             "is the third place the Library did not reach, and the only one "
             "that costs money. \u201c16 \u00d7 4 = 64\u201d is correct "
             "arithmetic about the wrong sixteen, which is why the check that "
             "multiplies out every inline product never saw it."),
    dict(section="7.6", action="replace",
         find="A Library at the Heart produces about one page per realm every few "
              "hours",
         replace="A Library at the Heart produces 3 pages a day at level 1, rising "
                 "to 18 at level 10 (10.4)",
         why="\u00a710.4 gives the table; this sentence predates it and reads "
             "about four times higher across seven realms."),
],

"C12": [
    dict(section="22.5", action="replace",
         find="Every revenue figure in 22.2 assumes 15%.",
         replace="Every revenue figure in 22.2 assumes 15%, except the high "
                 "scenario, which is computed at 30% because \u20ac204,000 a "
                 "month crosses the $1M threshold. The three are therefore not "
                 "directly comparable, and revenue between roughly \u20ac70,000 "
                 "and \u20ac85,000 a month is partly a dead zone.",
         why="The high scenario\u2019s \u20ac168,000 is arithmetically right at "
             "30% and wrong at the 15% this sentence promises. Surfacing the "
             "threshold is more useful than hiding it."),
],

"C17": [
    dict(section="27.2", action="replace",
         find="Fallbacks are Lawkeep and Ruleborn",
         replace="The fallback is Lawkeep",
         why="Ruleborn is the chosen name. A leftover from the v2.2 rename."),
],

"C18": [
    dict(section="9.1", action="replace",
         find="| 5,000 per Spire level + 3,000",
         replace="| 5,000 per Spire level",
         why="\u00a710.2\u2019s Spire table gives a flat 5,000 \u00d7 level. "
             "Either this or the table, and the table is the one every other "
             "building follows. F17 settles which: under a pegged upkeep "
             "(spec/sinks.md) 50,000 is about one day\u2019s running costs, "
             "which is a cap that means something. Under the flat rate either "
             "figure was 8.5 days and never bound."),
],

"C28": [
    dict(section="11.5", action="replace",
         find="A birth costs 100 Essence plus 40 per character already owned.",
         replace="A birth costs 100 \u00d7 1.15 to the power of the characters "
                 "already owned, in Essence (9.5).",
         why="One curve, stated where the prices are. \u00a79.5 is the version "
             "to keep because the price list is where a reader looks for a "
             "price \u2014 not because it is self-consistent, which this "
             "field claimed until it was checked: its worked examples sit one "
             "step of the curve above its own formula. This wording takes the "
             "formula, so \u00a79.5\u2019s examples need the second edit "
             "below."),
    dict(section="9.5", action="replace",
         find="(about 400 for the 10th, 1,600 for the 20th, 6,600 for the 30th)",
         replace="(about 350 for the 10th, 1,400 for the 20th, 5,750 for the "
                 "30th)",
         why="The examples are 405, 1,637 and 6,621 \u2014 one step of the "
             "curve above 100 \u00d7 1.15 to the power of the characters "
             "already owned, which is what the cell beside them says. The "
             "formula is the normative half and the two rows either side of "
             "it write their offsets out, so the examples are the half to "
             "move."),
],

"F17": [
    dict(section="9.5", action="replace",
         find="| 0.5 Aether an hour per point, paused after 24 hours away",
         replace="| 0.05% of your hourly Aether production per point held, paused "
                 "after 24 hours away",
         why="A flat rate set once cannot stay a price against a faucet that "
             "multiplies 240x. The same 0.5 is 60% of a day\u2019s Aether on day "
             "2 and 3.2% on day 301 \u2014 one number doing two different jobs. "
             "Pegged, a full sheet costs about a quarter of income at every "
             "stage, and \u00a79.1\u2019s cap becomes about a day\u2019s "
             "upkeep instead of 8.5 days. Withdraws this item\u2019s earlier "
             "proposal of a flat 15, which would have made the early game "
             "unplayable to postpone the late-game problem. See spec/sinks.md."),
    dict(section="10.2", action="insert",
         find="| 199 Aether an hour; 2 worker slots; holds 12 h",
         replace="Stop the Aether Spring ladder here or flatten it. Level 5 "
                 "already produces more Aether than every price in the document "
                 "combined; levels 6 to 10 sell up to five times that, for a "
                 "resource with nothing to buy, at 23,100 to 591,200 Starlight a "
                 "level.",
         why="An upgrade whose return is zero is not a weak upgrade. Cutting it "
             "also deletes a Starlight sink, and Starlight is the one currency "
             "whose sink already outruns its faucet twelvefold."),
    dict(section="10.2", action="insert",
         find="| 73 Essence an hour; 1 worker slot; holds 12 h",
         replace="Stop the Garden ladder here or flatten it. Level 3 already "
                 "produces more Essence than every price in the document "
                 "combined \u2014 births to the roster cap and every character "
                 "to level 10 \u2014 and both of those finish for good.",
         why="Essence prices acquiring the roster and nothing about keeping it, "
             "so once the roster is full the Gardens have 250 more days to run "
             "with nothing to pay for."),
    dict(section="11.6", action="insert",
         find="| After a heist: 45 minutes after a clean escape, 60 after a loud "
              "one, 180 if caught. Hearths shorten rest 5% per level. Waking "
              "early costs 2 Essence per level per minute left.",
         replace="Waking is the only price in the document a player pays again "
                 "every session, and at the roster cap of 38 it falls due at 199 "
                 "heists a day against the four an engaged player runs. Either "
                 "say it is a first-week mechanic and let it fade, or delete it.",
         why="A price charged at 2% of the rate anyone would have to play to meet "
             "it is not a sink. \u00a711.5 set the cap and this section set the "
             "rest window; nobody divided one by the other."),
],

"F7": [
    dict(section="12.22", action="insert",
         find="| Renown within 150, Keeper level within 3, and an island difficulty "
              "rating within one band of the raider\u2019s recent success rate",
         replace="Add depth to the band: the number of links between the landing "
                 "realm and the Heart. Simulated, a heist carries 10 decisions "
                 "across one realm, 17 across two, 24 across three and 31 across "
                 "four \u2014 so 12.6\u2019s \u201c15 to 25 in a run\u201d is "
                 "met at two to three realms and nowhere else.",
         why="\u00a75.4 already prices the skiff by the number of links, so the "
             "document knows depth varies; the matchmaker does not control it."),
],

}
