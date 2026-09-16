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
     refs=["19.27", "26.7", "25.5"],
     body="Both pre-code gates as written assume about thirty people in a room — "
          "eight to twelve for the paper heist, fifteen to twenty for the build "
          "test. That cohort does not exist for this project. The questions did not "
          "change; the method did, because <strong>a link can be sent to strangers "
          "and a room cannot</strong>. §25.5 already budgets for recruited remote "
          "panels, so the route was costed.",
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
     refs=["13.3", "25.5"],
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
     refs=["7.4", "7.7", "7.10", "9.5", "14.4", "27.2", "29.2"],
     body="What is <em>authored</em> (§7.4, §7.7, verified by parsing all 48 law "
          "sheets): three ranks — 18 Common, 18 Rare, 12 Deep — at 15/30/60 "
          "pages. §14.4's 1,485-page total is computed from exactly that, and the "
          "glossary agrees. What is <em>described</em> (§7.10, §27.2): five ranks "
          "— 18/14/10/6 plus 3 paradoxes — at 10/20/35/60/120 pages. "
          "<strong>No law anywhere in the document is tagged Uncommon.</strong> The "
          "two totals differ by 345 pages, which moves the whole late-game curve.",
     rec="§7.10's reasoning survives either way — rarity should buy specificity, "
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
     refs=["7.6", "12.1", "10.2", "26.1", "30.15"],
     body="“A Library at the Heart produces about one page per realm every few "
          "hours” is the mitigation for the problem review 10 identified — "
          "that making pages raid-only punishes the large share of players who "
          "prefer building. It is referenced four times. It is <strong>not among the "
          "16 building types</strong> in §10.2, has no cost, no levels and no "
          "placement rule, and §26.1 confirms 16 types at launch.",
     rec="Add it as a 17th building with a full level table, or fold the trickle "
         "into the Observatory or the Spire and rewrite the four references. Do not "
         "leave a load-bearing economic faucet unspecified."),

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
         "away, and §49's finding is that people value what they built only when they "
         "finish it. The spec proposes it becomes the real defence, places it at the "
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
     refs=["7.4", "7.10"],
     body="C3. Both work; the reasoning in §7.10 survives either. Choosing five means "
          "re-tagging 14 laws and re-deriving the page economy.",
     rec="<strong>Blocks:</strong> all law content authoring, and §14.4's page "
         "economy.<br><strong>The numbers</strong> (<code>decision_support.py "
         "rarity</code>): five ranks completes the collection 23% cheaper \u2014 "
         "2,460 pages against 2,805 \u2014 pulling it in about a month at eleven "
         "pages a day. §14.4's own 1,485-page figure is the three-rank total, so "
         "three ranks is what generated the published curve.<br><strong>No "
         "recommendation.</strong> Five ranks needs fourteen Rares re-tagged, and "
         "the split is a judgement about complexity and excitement \u2014 §7.10 is "
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
     refs=["7.6", "7.7", "7.10", "14.4", "29.2"],
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
         "say 18/12/6/12 and §7.10 says 18/14/10/6. Settle the split first, then "
         "regenerate every page total from the law table rather than restating it."),

dict(id="C24", kind="contradiction", severity="minor", status="open",
     title="Seventeen building types, and §26.1 still says sixteen",
     refs=["10.5", "10.2", "26.1"],
     body="§10.5 adds the Library and calls it \u201ca building at the Heart, one per "
          "universe\u201d, which closes the faucet C8 was about. Two counts did not "
          "follow: §26.1\u2019s launch content table still says 16 building types, and "
          "§10.2 \u2014 headed <em>Every level of every building</em> \u2014 does not "
          "contain it. §10.5 also gives only levels 1, 5 and 10, where every other "
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
         "every load-rate sentence, §7.10\u2019s rank table, §7.6\u2019s restore costs "
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
         "it is finished."),

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
         "grows to fit each new law is not a vocabulary."),

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
         "<code>python3 -m tools.heist_harness defence</code>."),

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
         "the matchmaker does when the band is empty rather than merely sparse."),

dict(id="F14", kind="finding", severity="blocking", status="open",
     title="v3.0\u2019s fill term halves the number \u00a79.6 calls load-bearing, and it was not re-derived",
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
          "crew that gets out has filled about <strong>52%</strong> of its bags, "
          "because \u00a712.19\u2019s own break-even tells it to stop at 70% and "
          "interruptions take the rest. So an attempt is worth "
          "<strong>0.46 \u00d7 0.52 = 0.24</strong>, not 0.46.<br><br>Run through "
          "the economy model, that is a <strong>48% cut to the raid faucet</strong> "
          "(62% under the production peg), and \u00a79.6\u2019s own worked example "
          "becomes 105 attempts rather than 55. Every date in \u00a714 moves.",
     rec="Re-derive 0.46 against the fill term, or state that fill is already "
         "inside it \u2014 but not both, and not neither. "
         "<code>Config(apply_fill=True)</code> in the economy model applies the "
         "measured value, and a test asserts the size of the gap so it cannot "
         "close quietly. This is C19\u2019s pattern applied to the single number "
         "\u00a79.6 names as the one the curve rests on."),

dict(id="F15", kind="finding", severity="blocking", status="open",
     title="Guards and Response are not two layers; they are one, and it is 69% of the defence",
     refs=["13.2", "13.4"],
     body="\u00a713.2 lists five defence layers with target shares and one rule "
          "above them: <strong>no single layer above 25%</strong>, because "
          "\u201cif one layer decides outcomes, the other four are "
          "decoration\u201d. \u00a713.4 specifies exactly how to check it \u2014 "
          "all 32 combinations, credit divided \u201cthe way cooperative game "
          "theory does\u201d, which is the Shapley value. Run at 120 raids a "
          "combination (3,840 runs):<br><br>"
          "<code>geometry &nbsp;4.4% &nbsp;(target 25%)<br>"
          "guards &nbsp;&nbsp;34.5% &nbsp;(target 20%)<br>"
          "wards &nbsp;&nbsp;&nbsp;20.9% &nbsp;(target 20%)<br>"
          "laws &nbsp;&nbsp;&nbsp;&nbsp;5.7% &nbsp;(target 20%)<br>"
          "response &nbsp;34.5% &nbsp;(target 15%)</code><br><br>"
          "Guards and Response are equal to the last decimal, and that is a "
          "theorem rather than a coincidence. Checked directly: in <strong>every "
          "one of the eight coalitions</strong>, guards without response turn "
          "back 0% of raids and response without guards turns back 0%. They are "
          "symmetric players, so the Shapley value must give them identical "
          "shares.<br><br>The cause is \u00a713.2\u2019s own definition. Response "
          "is \u201cwhat turns being seen into being caught\u201d \u2014 which "
          "makes it <em>multiplicative</em> with guards, not additive. Two layers "
          "that multiply cannot have independent shares. Counted together they "
          "are <strong>69% of the defence</strong>, against a ceiling of 25% for "
          "any one layer.",
     rec="Either fold Response into Guards and accept one layer at 69% \u2014 "
         "which fails \u00a713.2\u2019s own rule and makes the other three "
         "decoration, exactly what the rule exists to prevent \u2014 or give "
         "Response something it can do <em>without</em> a guard. \u00a713.2 "
         "already names two candidates and specifies neither: <strong>the "
         "Spire\u2019s reach</strong> and <strong>the guardian Sage\u2019s single "
         "power</strong>. A ward that raises the alarm on its own is a third; "
         "Lantern Glare already does it. Any of them gives the layer a standalone "
         "contribution and the five shares a chance of summing the way \u00a713.2 "
         "wants. <code>python3 -m tools.heist_harness ablation</code>."),

dict(id="F16", kind="finding", severity="design", status="open",
     title="Geometry is 4% of a generated defence, against a 25% target",
     refs=["13.2", "13.3", "6"],
     body="\u00a713.2 gives Geometry the largest share of any layer, 25%, and the "
          "warmest description: \u201cfree, unlimited, and <em>the layer a "
          "thoughtful designer beats a richer player with</em>\u201d. It is the "
          "layer the whole authorship argument rests on.<br><br>Measured on "
          "<strong>generated</strong> islands it contributes <strong>4.4%</strong>. "
          "At a smaller sample it measured slightly negative \u2014 the hedges "
          "and tall grass a naive generator lays down block a guard\u2019s sight "
          "line as readily as a raider\u2019s, and tall grass is the "
          "raider\u2019s cover by definition (\u00a712.17).<br><br>Stated "
          "carefully, because the distinction is the finding: this measures "
          "<em>generated</em> geometry, not designed geometry. \u00a713.2\u2019s "
          "25% is a claim about an island someone thought about. v3.0\u2019s "
          "\u00a713.3 made generated islands the default, so the two are no "
          "longer the same population \u2014 and the layer that is supposed to "
          "let design beat progression is the one a generator is worst at.",
     rec="This is the sharpest argument for the creator ladder \u00a718.7 "
         "describes, and against treating generation as equivalent to design. If "
         "geometry is 25% when designed and 4% when generated, then "
         "\u00a713.2\u2019s \u201c60% from design rather than level\u201d is a "
         "property of hand-built islands only, and the target pool is mostly not "
         "those. Measure a hand-built island against the same harness before "
         "accepting either number."),

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
     title="Two rules for partial staffing: \u00a79.2's table and \u00a75.9's pro-rata share",
     refs=["9.2", "5.9", "9.3"],
     body="\u00a79.2: \u201c<strong>Staffing sets 60%, 85% or 100% output.</strong>"
          "\u201d \u00a75.9, added in v3.0: \u201cA producer runs at the "
          "<strong>share of its worker slots that are filled</strong>, so a "
          "half-staffed Well earns half.\u201d<br><br>Those are different numbers "
          "wherever the roster binds, and \u00a75.9 says it always binds: two of "
          "three slots is 85% under \u00a79.2 and 67% under \u00a75.9, one of "
          "three is 60% against 33%. \u00a79.2 is the more generous rule at every "
          "partial count.<br><br>Worth about 11% of late-game production, and "
          "nothing at all until the roster starts binding \u2014 which is why it "
          "hid.",
     rec="\u00a75.9 is the later and better-argued rule, and pro-rata is the one "
         "that makes partial staffing a real choice rather than a rounding. "
         "Delete \u00a79.2\u2019s sentence. This is the fourth instance of the "
         "same pattern in v3.0 (C21\u2013C23) and the cheapest to fix."),

dict(id="F17", kind="finding", severity="blocking", status="open",
     title="Aether and Essence have no sinks: every price in \u00a79.5 adds up to five days of income",
     refs=["9.5", "9.3", "9.1", "10.2"],
     body="\u00a79.1 runs the game on three resources. \u00a79.5 prices every sink "
          "for all three. Totalling \u00a79.5\u2019s prices against "
          "\u00a79.3\u2019s own published day-301 production \u2014 256,100 "
          "Starlight, 192,100 Aether, 125,300 Essence a day \u2014 gives:"
          "<br><br><code>"
          "every birth to the roster cap of 38 &nbsp;&nbsp;133,688 = 1.1 days<br>"
          "every character to level 10 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "524,813 = 4.2 days<br>"
          "weaving a full 516-point sheet &nbsp;&nbsp;&nbsp;&nbsp;20,640 = 2.6 "
          "hours<br>"
          "upkeep on that sheet, a day &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "&nbsp;6,192 = 46 minutes<br>"
          "a Lab experiment at level 3 &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"
          "&nbsp;1,200 = 9 minutes</code><br><br>"
          "<strong>Every Essence sink in the document, added together, is five "
          "days of income.</strong> Every Aether sink but upkeep is under three "
          "hours, and upkeep at a full sheet is 3% of a day. The other 97% has "
          "nowhere to go.<br><br>\u00a79.1 then caps Aether at 5,000 a Spire level "
          "plus 3,000 \u2014 53,000 at Spire 10, against 192,100 produced a day "
          "\u2014 so most of it is never banked. An Aether Spring above a certain "
          "level therefore buys nothing, and \u00a710.2\u2019s upgrade costs for "
          "it are a Starlight sink with no return.<br><br>Computed from "
          "\u00a79.3\u2019s published table rather than from the model, so it "
          "cannot be an artefact of how the model reads \u00a75.9.",
     rec="Two of the three resources are decorative as priced. The design reads "
         "as though it knows this \u2014 \u00a74 names <em>stability</em> and "
         "<em>character time</em> as the two scarce things, and neither is "
         "Aether or Essence.<br><br>Three ways out, and they are not "
         "exclusive.<br><br><strong>1. Make upkeep the sink.</strong> It is the "
         "only recurring price already in the document and it scales with the "
         "thing the design wants players to push on. At 0.5 Aether an hour a "
         "point it is 3% of income; at 15 it is most of it, and weaving a fuller "
         "sheet becomes a real decision rather than a free one.<br><br>"
         "<strong>2. Price the roster in Essence properly.</strong> \u00a75.9 "
         "makes the roster the scarcity the design is built on, and births cost "
         "one day of income to reach the cap. The Hearth cap does all the work "
         "and the price does none.<br><br><strong>3. Cut the faucets.</strong> If "
         "nothing needs 192,100 Aether a day, Aether Springs should not produce "
         "it, and \u00a710.2 has ten levels of upgrades selling capacity nobody "
         "can use. <code>python3 -m tools.economy_model sinks</code>."),

dict(id="C28", kind="contradiction", severity="minor", status="open",
     title="Births are priced twice: \u00a79.5\u2019s geometric curve and \u00a711.5\u2019s linear one",
     refs=["9.5", "11.5"],
     body="\u00a79.5: \u201cA new ruleborn: 100 \u00d7 1.15^(ruleborn owned) "
          "Essence (about 400 for the 10th, 1,600 for the 20th, 6,600 for the "
          "30th)\u201d. \u00a711.5: \u201cA birth costs 100 Essence plus 40 per "
          "character already owned.\u201d<br><br>Geometric against linear. At the "
          "10th character they are 405 and 500; at the roster ceiling of 38 they "
          "are <strong>17,612 and 1,580</strong>, eleven times apart. "
          "\u00a79.5 is the self-consistent one \u2014 its worked values match "
          "its own formula.<br><br><strong>It matters less than it looks, and "
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
    "§5.9 decides it: one producer of each kind per realm, partial staffing paying "
    "pro-rata, and \u201cthe roster can never fill everything \u2014 38 ruleborn "
    "against far more positions \u2014 and that is the scarcity the design is built "
    "on\u201d. Scarcity is now a feature by decision rather than by accident."),

"F2": dict(status="fixed", note=
    "§5.9: one, not two, with the model\u2019s reasoning quoted. The published tables "
    "in §9.3 were not regenerated against it \u2014 C19."),

"F3": dict(status="fixed", note=
    "§5.9: \u201cA crew on a heist is assigned to it, like a guard at a post, and "
    "does not work while assigned. Five of thirty-eight is a real choice.\u201d This "
    "is the mechanism the finding recommended, taken whole."),

"Q1": dict(status="fixed", note="Answered by §5.9: scarcity is a feature."),
"Q4": dict(status="fixed", note="Answered by §5.9: one producer of each kind per realm."),
"Q2": dict(status="fixed", note=
    "Answered by §5.9: crew membership excludes work, so the trade-off binds."),

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
    "so the sheets now read 18/12/6/12 \u2014 against §7.10\u2019s own table of "
    "18/14/10/6. Deep doubled from 6 to 12. And §7.6, §14.4 and the glossary still "
    "price three ranks at 15/30/60 pages (C23)."),

"C6": dict(note=
    "§30.18 records \u201c11.11 is the roster\u201d, but §11.2 is still a full "
    "hand-authored table and still disagrees with it about Prism Mite, Stormhound "
    "and Rootrunner, plus fifteen wording differences. The decision was taken and "
    "the second copy was not retired."),

"C8": dict(note=
    "The Library exists: §10.5 gives it a placement and three levels. Three, not ten "
    "\u2014 levels 1, 5 and 10, where every other building lists every level. And "
    "§26.1 still says 16 building types while there are now 17 (C24)."),

"C19": dict(note=
    "The decision is made (\u00a75.9) and the tables were not regenerated against "
    "it. Now measured, by re-running the model under \u00a75.9\u2019s three rules "
    "\u2014 one producer per realm, pro-rata staffing, the crew assigned rather "
    "than timed:<br><br><code>day &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;31 &nbsp;&nbsp;&nbsp;"
    "&nbsp;91 &nbsp;&nbsp;&nbsp;181 &nbsp;&nbsp;&nbsp;301<br>"
    "published &nbsp;17,300 &nbsp;94,100 &nbsp;152,800 &nbsp;256,100<br>"
    "under \u00a75.9 &nbsp;14,633 &nbsp;46,817 &nbsp;&nbsp;62,627 &nbsp;122,495<br>"
    "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-15% "
    "&nbsp;&nbsp;&nbsp;-50% &nbsp;&nbsp;&nbsp;&nbsp;-59% &nbsp;&nbsp;&nbsp;&nbsp;"
    "-52%</code><br><br>"
    "<strong>The first month holds and then the curve breaks.</strong> Keeper 5 "
    "to 20 land within two days of published, which is the evidence the model "
    "reads \u00a75.9 correctly; Keeper 28 is 18 days late and Keeper 40 is "
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

"C20": dict(status="fixed", note=
    "Fixed, and the fix is the honest one. \u00a721.8 no longer claims a signature "
    "per law: \u201cEvery school has a sound signature \u2014 six in all \u2014 so "
    "a player can hear which kind of rule is running.\u201d Six signatures for six "
    "schools is what the content actually holds, so the sentence now describes the "
    "game rather than an aspiration."),
"C10": dict(note="Untouched: 31 traits authored, 30 in §26.1, a 32nd named in §17.3."),
"C20": dict(note="Untouched: 48 laws still share 6 sound signatures."),
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

EDITS = {

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
         why="\u00a710.5 added the Library and the launch table did not follow."),
    dict(section="10.2", action="insert",
         find="10.5 The Library",
         replace="Move \u00a710.5\u2019s table into \u00a710.2, between Ward and "
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
                 "filled (5.9)",
         why="\u00a75.9 is the later rule and pro-rata is what makes partial "
             "staffing a choice rather than a rounding."),
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
                 "Keeper days with the re-run under \u00a75.9\u2019s rules. The "
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
         replace="Give the response layer one effect that works without a guard, "
                 "and specify it: the Spire\u2019s reach and the guardian "
                 "Sage\u2019s power are both named here and neither is defined. "
                 "Measured, guards and response contribute nothing whatsoever "
                 "without each other, in any of the eight coalitions \u2014 so as "
                 "written they are one layer at 69%, against this "
                 "section\u2019s own 25% ceiling.",
         why="\u201cWhat turns being seen into being caught\u201d makes the layer "
             "multiplicative with guards, and two layers that multiply cannot have "
             "independent shares."),
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
    dict(section="7.10", action="replace",
         find="| Uncommon\n| 14\n| Conditional, with a mild cost\n| 20",
         replace="| Uncommon\n| 12\n| Conditional, with a mild cost\n| 20",
         why="The sheets say 12. If the table is right instead, re-tag two laws "
             "\u2014 but one of the two has to move."),
    dict(section="7.10", action="replace",
         find="| Rare\n| 10\n| Strong inside a condition you have to build for\n| 35",
         replace="| Rare\n| 6\n| Strong inside a condition you have to build for\n| 35",
         why="The sheets say 6."),
    dict(section="7.10", action="replace",
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

"C28": [
    dict(section="11.5", action="replace",
         find="A birth costs 100 Essence plus 40 per character already owned.",
         replace="A birth costs 100 \u00d7 1.15 to the power of the characters "
                 "already owned, in Essence (9.5).",
         why="\u00a79.5 is the self-consistent one: its worked values \u2014 400 "
             "for the 10th, 1,600 for the 20th, 6,600 for the 30th \u2014 match "
             "its own formula."),
],

"F17": [
    dict(section="9.5", action="replace",
         find="| 0.5 Aether an hour per point, paused after 24 hours away",
         replace="| 15 Aether an hour per point, paused after 24 hours away",
         why="Upkeep is the only recurring Aether sink in the document and at 0.5 "
             "it is 3% of a day\u2019s income at a full sheet. At 15 it is most "
             "of it, and weaving a fuller sheet becomes a decision rather than a "
             "free upgrade. The figure is a starting point for tuning, not a "
             "derivation \u2014 what is not defensible is a recurring cost that "
             "rounds to nothing."),
    dict(section="9.1", action="insert",
         find="| 5,000 per Spire level + 3,000",
         replace="Either raise the cap to something a day\u2019s production can "
                 "reach, or cut what Aether Springs produce. 53,000 at Spire 10 "
                 "against 192,100 produced a day means most Aether is never "
                 "banked \u2014 which makes an Aether Spring above a certain "
                 "level a building that costs Starlight and returns nothing.",
         why="A cap this far below production is not a cap, it is a deletion."),
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
