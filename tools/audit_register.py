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

dict(id="C3", kind="contradiction", severity="blocking", status="open",
     title="Two law-rarity taxonomies, and one of them has no laws in it",
     refs=["7.4", "7.7", "7.9", "9.5", "14.4", "27.2", "29.2"],
     body="What is <em>authored</em> (§7.4, §7.7, verified by parsing all 48 law "
          "sheets): three ranks — 18 Common, 18 Rare, 12 Deep — at 15/30/60 "
          "pages. §14.4's 1,485-page total is computed from exactly that, and the "
          "glossary agrees. What is <em>described</em> (§7.9, §27.2): five ranks "
          "— 18/14/10/6 plus 3 paradoxes — at 10/20/35/60/120 pages. "
          "<strong>No law anywhere in the document is tagged Uncommon.</strong> The "
          "two totals differ by 345 pages, which moves the whole late-game curve.",
     rec="§7.9's reasoning survives either way — rarity should buy specificity, "
         "not strength. Decide the split, then regenerate §7.4, §7.7, §7.6, §9.5, "
         "§14.4 and the glossary from one table. Choosing five ranks means "
         "re-tagging 14 laws and re-deriving the page economy."),

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
     title="Two ruleborn rosters — and eleven are different creatures, not different wordings",
     refs=["11.2", "11.11", "11.5", "12.8"],
     body="The same 18 creatures are specified twice. Prism Mite is a Carrier in "
          "§11.2 and a Scout in §11.11; Stormhound is a Scout then a Carrier; "
          "Rootrunner a Carrier then a Scout. That changes the role distribution "
          "(3 Scout / 4 Carrier versus 4 Scout / 3 Carrier), and role drives crew "
          "composition, guard behaviour (§12.8) and the Nursery's "
          "fewest-roles-first rule (§11.5). Most of the other fifteen disagree on "
          "ability, cooldown or resistance — Featherkin 12s or 14s, Echoplate "
          "returns at 50% or 40%, Rootrunner ignores Spores or Heavy ground.",
     rec="§11.11 is the richer and later spec. Make it authoritative, reduce §11.2 "
         "to a generated index, and hold both in <strong>one creature data "
         "table</strong> — exactly the server-side content data §24 describes."),

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

dict(id="C8", kind="contradiction", severity="significant", status="open",
     title="The Library is load-bearing and specified nowhere",
     refs=["7.6", "12.1", "10.2", "26.1", "21.9", "30.15"],
     body="“A Library at the Heart produces about one page per realm every few "
          "hours” is the mitigation for the problem review 10 identified — "
          "that making pages raid-only punishes the large share of players who "
          "prefer building. It is referenced four times. It is <strong>not among the "
          "16 building types</strong> in §10.2, has no cost, no levels and no "
          "placement rule, and §26.1 confirms 16 types at launch."
          "<br><br>The count reaches further than the two sections first "
          "recorded here. §21.9’s launch asset budget prices "
          "<code>Building looks (16 types × 4)</code> at 64, so the "
          "art schedule is short four building looks as well — a "
          "third place the same fix did not land.",
     rec="Add it as a 17th building with a full level table, or fold the trickle "
         "into the Observatory or the Spire and rewrite the four references. Do not "
         "leave a load-bearing economic faucet unspecified."),

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
         "<br><br><strong>The second half is built; the first is still "
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
          "can build.",
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
     measured="re-run against harness 496955db53f8d3c4"),

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
          "carries.",
     rec="<strong>Fix the base, not the dial.</strong> State a starting defence "
         "per realm chosen so the ladder spans the band — realm 2 higher, "
         "realms 4 and 5 lower — rather than letting it fall out of "
         "<code>1 + (level−1)÷2</code>. The ladder itself is the "
         "right instrument and needs no change."
         "<br><br><strong>A steeper ladder is not the answer, and was measured "
         "rather than reasoned about.</strong> F26 first recommended doubling "
         "its effect to rescue realm 1. Doubling reaches 25.8% against a band "
         "starting at 30; it takes five times §10.2’s slope to reach "
         "32.0%, and at that slope a maxed post carries all four upper realms "
         "out of the top — 54.2%, 60.2%, 66.2%, 62.7%. <strong>The ladder "
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
     measured="re-run against harness 496955db53f8d3c4"),
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

dict(id="C23", kind="contradiction", severity="significant", status="open",
     title="Three sections still price laws in three ranks after the sheets moved to four",
     refs=["7.6", "7.7", "7.9", "14.4", "29.2"],
     body="v3.0 re-tagged twelve laws from Rare to Uncommon. §7.6 still says "
          "\u201cRestoring a law: 15 pages for a common law, 30 for a rare one, 60 for "
          "a deep one\u201d \u2014 three ranks, and no mention of the rank twelve laws "
          "now carry. §14.4 still totals the Codex as \u201c15 commons \u00d7 15 + 18 "
          "rares \u00d7 30 + 12 deep \u00d7 60 = 1,485 pages\u201d, arithmetic that "
          "describes a roster of laws that no longer exists. The glossary and the "
          "price list still say \u201c15, 30 or 60 pages by rank\u201d.<br><br>The "
          "change log states the new figure as 1,350 pages. That counts all 18 "
          "commons; §14.4\u2019s convention excludes the three free starting laws, so "
          "even the replacement figure is on a different basis from the number it "
          "replaces.",
     rec="This is C3\u2019s collateral list, and C3 is still open \u2014 the sheets "
         "say 18/12/6/12 and §7.9 says 18/14/10/6. Settle the split first, then "
         "regenerate every page total from the law table rather than restating it."),

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
          "pool now are.",
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
     measured="496955db53f8d3c4e13f7d1683dd4c47fb49a682f43301859cf1276e10b3c13d"),

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
          "\u00a713.2\u2019s separable shares are the right model here.",
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
     measured="496955db53f8d3c4e13f7d1683dd4c47fb49a682f43301859cf1276e10b3c13d"),

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
          "where most of the target pool sits early in a season.",
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
     measured="496955db53f8d3c4e13f7d1683dd4c47fb49a682f43301859cf1276e10b3c13d"),

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
     rec="Either the generator gets an explicit rule for each (slope away from "
         "the entry, streams across the approach), or these eight laws are "
         "marked as ones a generated realm cannot weave. The first is better "
         "design and more work; the second is one column in the law table. "
         "Deciding nothing means the generator picks arbitrarily, which is the "
         "current state."),

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
          "the numbers above are after D25.",
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
         "wrong; the mechanism that would have justified it was missing."),

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
          "everyone else copies.",
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
         "<br><br><code>python3 -m tools.heist_harness depth</code>."),
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
          "get worse, at 1.6% and 3.5%.",
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
     measured="496955db53f8d3c4e13f7d1683dd4c47fb49a682f43301859cf1276e10b3c13d"),

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
          "ways.",
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
     measured="496955db53f8d3c4e13f7d1683dd4c47fb49a682f43301859cf1276e10b3c13d"),
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
DESIGN_GATES = {
    "realms": dict(
        what="Terrain layout, what an island holds, how a realm is drawn",
        gates={
            "F26": "how many wards a realm holds \u2014 measured at "
                   "11, 8, 6, 7, 8 against \u00a75.2's 4, 5, 6, 7, 8, so "
                   "realms 1 and 2 are drawn with less than half the "
                   "objects they need, and no realm works at all "
                   "without geometry to hide them behind",
            "F27": "where each realm's defence starts, which \u00a75.2's post "
                   "formula sets and gets right at one realm in five",
            "F22": "whether realms 1 and 2 get one guard post or two, which is "
                   "one or two patrol routes to lay out",
            "F9":  "what hold rate a generated realm has to reach, which nothing "
                   "currently states",
            "F11": "what the generator optimises for \u2014 \u201cgenerated from "
                   "their laws\u201d has three meanings and two are worse than "
                   "weaving none",
            "F12": "eight laws whose effect is an act of authorship: a slope, a "
                   "wind direction, streams drawn on the grid",
            "G3":  "what a ward does at each level, so it can be placed and drawn",
            "G5":  "whether a raider can tell which law a pylon carries before "
                   "committing to the detour",
            "C19": "how many producers a realm holds, which is what stands on it",
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
        }),
    "screens": dict(
        what="The 27 screens in \u00a723, their contents and their counts",
        gates={
            "C6":  "which roster the character screens read from \u2014 the two "
                   "disagree about eleven creatures",
            "C3":  "how many law ranks the Codex has to display, three or four",
            "C8":  "whether the Library is a seventeenth building with a screen "
                   "of its own",
        },
        closed={
            "C11": "how many screens there are: 27, not 23",
            "C9":  "how many laws the Codex screen shows: 48, not 36",
            "C10": "how many traits a character screen lists: 31",
            "C24": "how many building types the build screen offers: 17",
        }),
    "characters": dict(
        what="The 18 ruleborn, their forms, and what the art has to show",
        gates={
            "C6":  "eleven of the eighteen are different creatures in the two "
                   "rosters, not different wordings",
            "D6":  "144 forms or 54 \u2014 the largest single art number in the "
                   "project, and a threefold difference",
            "Q5":  "accepting or refusing that cut is the decision underneath it",
        },
        closed={
            "C26": "size and flight are stated properties of every ruleborn, "
                   "so the art has a band to draw to",
            "G12": "the three laws that read those properties now have them",
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


EDITS = {

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
         replace="Say what happens to the eight laws whose effect is an act of "
                 "authorship rather than a number: Tilt slopes the realm “toward "
                 "a side the owner picks”, Current blows “one way, chosen by "
                 "the owner”, Slow rivers lets the owner “draw streams on the "
                 "realm’s grid”, and Lodestones, Heat bloom, Soul lanterns and "
                 "Shifting stones are placements. Either the generator gets a stated "
                 "rule for each — slope away from the entry, streams across the "
                 "approach — or they are marked as laws a generated realm cannot "
                 "weave, which is one column in the law table.",
         why="These were fine while authoring was the default. This section makes "
             "curation the default and authorship the deep end, so for most islands "
             "the generator now makes these choices — and a badly chosen slope or "
             "stream turns the defender’s law into the raider’s. Deciding "
             "nothing means the generator picks arbitrarily, which is the current "
             "state."),
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
             "learned the rank exists."),
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
         replace="Replace \u00a79.3\u2019s production table and \u00a714.2\u2019s "
                 "Keeper days with the re-run under \u00a75.8\u2019s rules. The "
                 "first month holds; from day 91 the published figures are up to "
                 "twice what the rules produce, and Keeper 40 arrives 94 days "
                 "late.",
         why="This item\u2019s own recommendation was to regenerate rather than "
             "hand-edit, because hand-editing is what produced it."),
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
         replace="| Uncommon\n| 12\n| Conditional, with a mild cost\n| 20",
         why="The sheets say 12. If the table is right instead, re-tag two laws "
             "\u2014 but one of the two has to move."),
    dict(section="7.9", action="replace",
         find="| Rare\n| 10\n| Strong inside a condition you have to build for\n| 35",
         replace="| Rare\n| 6\n| Strong inside a condition you have to build for\n| 35",
         why="The sheets say 6."),
    dict(section="7.9", action="replace",
         find="| Deep\n| 6\n| Changes how a realm works. Heavy stability cost and "
              "a real trade-off. One per school\n| 60",
         replace="| Deep\n| 12\n| Changes how a realm works. Heavy stability cost "
                 "and a real trade-off. Two per school\n| 60",
         why="The sheets say 12, which is two per school rather than one. This is "
             "the one to look at hardest: Deep doubled, and \u201cone per "
             "school\u201d was part of the argument for what Deep is."),
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
                 "for weaving none, because only five of the nineteen laws a rule "
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
                 "(F10).",
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
