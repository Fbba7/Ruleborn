"""The Ruleborn roadmap, as data.

`tools/build_roadmap.py` renders this to docs/roadmap/index.html, which is what
gets published. This file is the source of truth — never edit the generated HTML.

The point of the roadmap is to be checkable, so two rules govern it:

  * **Progress is computed, not claimed.** A task that maps onto register items
    takes its progress from `audit_register.py`. Nothing says "80% done" here;
    it says "7 of 9 drafted, 0 signed off", and the register decides.
  * **Drafted is not done.** Everything produced so far is a proposal in a side
    repository. The design document itself is untouched. A roadmap that scored
    those as finished would be measuring effort rather than progress.

Status vocabulary
-----------------
done      finished and verified
doing     under way now
ready     nothing blocks it; it can start today
blocked   waiting on another task in this roadmap
yours     waiting on the owner — a decision, a recruitment drive, a sign-off

Owner
-----
claude    can be done from here
you       cannot: it needs a person, a judgement or an account

Fields
------
id          stable handle (T0.1)
title       one line, an action
detail      what it actually involves
owner       claude | you
status      as above
evidence    what to look at to check it — a path, a URL, a command
blocked_by  task ids
register    register item ids whose progress this task tracks
gate        the threshold that decides it is finished, where one exists
"""

STAGES = [

# ===========================================================================
dict(
    id="S0",
    title="Validation without players",
    subtitle="\u00a719.27, rewritten in v3.0 \u2014 and now the critical path",
    blurb="v3.0 removed both pre-code player tests and replaced them with "
          "harnesses, stating the cost plainly: simulation can prove a system is "
          "legible, balanced and decision-dense, and cannot prove a game is "
          "enjoyable. Each harness below is buildable here, needs no engine, and "
          "has a threshold \u00a719.27 sets for itself.",
    tasks=[
        dict(id="T0.1", owner="claude", status="done",
             title="Build a browser prototype that runs the two old gates",
             detail="Superseded rather than wrong. \u00a719.27 no longer asks for "
                    "either test, so this is off the critical path \u2014 but it "
                    "stays published, because it is the only artefact here that "
                    "can answer the question \u00a719.27 says simulation cannot, "
                    "and sending a link to twenty strangers costs an afternoon "
                    "rather than a soft launch (D20).",
             evidence="https://claude.ai/artifact/3jW7Zg1rTrzR6CF3cEVp2E"),
        dict(id="T0.2", owner="claude", status="done",
             title="The heist harness \u2014 is it tense, and is there depth?",
             detail="Built. \u00a712.17's perception in full, \u00a712.18's "
                    "movement, \u00a712.19's loading, \u00a712.20's capture and "
                    "revive, \u00a75.4's clock, \u00a712.9's grades \u2014 every "
                    "run a function of its seed, in integer arithmetic. Three of "
                    "\u00a719.27's four thresholds pass; the fourth is F8. Two "
                    "findings came with it: <strong>F7</strong>, that the "
                    "15\u201325 band implies crossing two to three realms, which "
                    "\u00a712.22's matchmaker does not control; and "
                    "<strong>F8</strong>, that the clock decides nothing.",
             evidence="python3 -m tools.heist_harness depth",
             register=["F7", "F8"],
             gate="a median run carries 15\u201325 decisions; a near-capture in "
                  "half of runs; the last ten seconds decide a quarter; and the "
                  "optimal crew succeeds 35 points more often than the careless "
                  "one (\u00a719.27)"),
        dict(id="T0.3", owner="claude", status="done",
             title="The attribution check \u2014 does delegated control hold?",
             detail="\u00a719.27 does not ask whether it <em>felt</em> right; it "
                    "checks that \u00a712.18's rule holds, which is the honest "
                    "move. Every state change in a replay must trace to a player "
                    "command.",
             gate="no unattributed decisions in ten thousand replays",
             evidence="python3 -m tools.heist_harness control"),
        dict(id="T0.4", owner="claude", status="done",
             title="The ablation harness \u2014 is the defence fair?",
             detail="Built exactly as \u00a713.4 specifies: all 32 layer "
                    "combinations, credit divided by Shapley value. The hold rate "
                    "lands inside \u00a713.2's band (43.3%) and the shares do "
                    "not. <strong>Guards and Response measure identically because "
                    "they are the same layer</strong> \u2014 neither turns back a "
                    "single raid without the other, in any of the eight "
                    "coalitions \u2014 and together they are 68% of the defence "
                    "against a 25% ceiling (F15). Geometry, which \u00a713.2 "
                    "gives the largest share and calls the layer a thoughtful "
                    "designer wins with, measures 5.4% on a generated island "
                    "(F16).",
             evidence="python3 -m tools.heist_harness ablation",
             register=["F9", "F15", "F16"],
             gate="hold rate 30\u201345%, no layer above a quarter, design beating "
                  "progression 60/40 (\u00a713.4)"),
        dict(id="T0.6", owner="claude", status="done",
             title="Give the island generator laws, and measure it against the band",
             detail="Done, and it answered F9's caveat the other way. Adding laws "
                    "does not rescue the hold rate \u2014 <strong>weaving the "
                    "player's own laws at random makes the island weaker than "
                    "weaving none</strong> (0\u20137% against 3\u201333%), "
                    "because only five of the nineteen laws a rule sheet can "
                    "express help the defender. A generator that reads the sign "
                    "of each law recovers it (F11). Writing all 48 laws out "
                    "against the rule sheet also settled \u00a712.21's rule: 16 "
                    "are parameter changes, 32 need an engine feature (F10), and "
                    "8 need a choice from the owner that a generator now has to "
                    "make (F12).",
             evidence="python3 tools/law_effects.py",
             register=["F9", "F10", "F11", "F12"],
             gate="a generated island at every realm level holds 30\u201345% "
                  "against a competent crew (\u00a713.2)"),
        dict(id="T0.7", owner="claude", status="done",
             title="Specify the response layer \u2014 and report that the fix "
                   "did not work",
             detail="F15's recommendation was to give Response an effect that "
                    "works without a guard, using the two things \u00a713.2 "
                    "names and never defines: the Spire's reach and the guardian "
                    "Sage's single power. Both are specified in "
                    "<code>spec/response.md</code>, both were built into the "
                    "harness, and <strong>neither changes the shares</strong> "
                    "\u2014 guards and response still measure 34.4% each. Why is "
                    "the useful part: a crew already leaves 30% of the exposed "
                    "share behind, so taking loot off the floor costs it "
                    "nothing, and a run ends at 63 seconds of \u00a75.4's 165, "
                    "so a delay costs it nothing either. <strong>Guards and "
                    "response are the island's only detect-and-act chain</strong> "
                    "\u2014 the other three layers work by delay, and delay "
                    "reaches an outcome only through a clock with four times the "
                    "slack it would need. Re-measured against what \u00a79.6 "
                    "actually pays (grade \u00d7 fill), the identity breaks and "
                    "the 69% does not.<br><br><strong>Finished:</strong> both "
                    "effects are now specified and built, and they work \u2014 "
                    "separately they cost a raider 6% and 18% of the haul with "
                    "no guard involved, and the Spire\u2019s reach moves the "
                    "raider\u2019s break-even from 100% to 80% at no cost in "
                    "hold rate once \u00a79.6\u2019s own floor is applied to "
                    "it. Run through the 32 coalitions they still change nothing: "
                    "guards 39.0% \u2192 39.1%, response 34.7% \u2192 35.1%. "
                    "Both need the crew slowed by something else first, so the "
                    "layer is a complement by construction. <strong>The ceiling "
                    "breach is a fact about \u00a713.2\u2019s table, not about "
                    "the layer\u2019s contents.</strong>",
             evidence="python3 -m tools.heist_harness haul 120",
             register=["F15"],
             gate="the same 32 coalitions, on the metric \u00a79.6 pays on"),
        dict(id="T0.9", owner="claude", status="done",
             title="Design an island by hand, and settle whether F16 is about "
                   "the design or the generator",
             detail="F16 measures geometry at 5% of a generated defence against "
                    "\u00a713.2\u2019s 25% target, and always carried the "
                    "caveat that \u00a713.2\u2019s claim is about <em>designed"
                    "</em> islands. <code>heist_harness/designed.py</code> is "
                    "one, laid out against \u00a713.2\u2019s own list \u2014 "
                    "Vault in the middle of a spiral, one corridor in, a "
                    "switchback route, a decoy ring, no cover on the true path. "
                    "Same harness, same guards, same wards.<br><br>"
                    "<strong>Designed geometry is worth four to seven times "
                    "generated geometry</strong>: +82.0 points of hold rate "
                    "against +18.0, and +45.8 of haul denied against +6.6. So "
                    "\u00a713.2\u2019s claim survives and F16 is a finding "
                    "about the generator \u2014 which scatters tall grass that "
                    "<em>hides the raider</em>, anywhere, including on the "
                    "route.<br><br>Building it turned up D26: <code>Patrol.phase"
                    "</code> was computed by the generator and never read, so "
                    "every guard began every raid at waypoint zero. The designed "
                    "island has one layout, so that was its only source of "
                    "variation \u2014 and there was none.",
             evidence="python3 -m tools.heist_harness.test_harness",
             register=["F16", "D26"],
             gate="designed geometry worth at least 2.5\u00d7 generated, pinned "
                  "by a test"),
        dict(id="T0.5", owner="you", status="ready",
             title="Decide whether to send the prototype out anyway",
             detail="Not a disagreement with \u00a719.27, which argues its case "
                    "well and is your call. But the reason it gives \u2014 that "
                    "thirty people in a room do not exist \u2014 is the reason the "
                    "prototype was built as a link. It is published and it costs "
                    "nothing to leave up. Twenty sessions would move the one "
                    "question the harnesses cannot touch.",
             evidence="tools/parse_gate_results.py"),
    ],
),

dict(
    id="S1",
    title="Reconcile the document",
    subtitle="Days of desk time, and the cheapest work in the plan",
    blurb="Four systems are specified twice and the later spec never retired the "
          "earlier one. Nothing downstream can be locked while two answers exist. "
          "Most of this is drafted; none of it is signed off, and the design "
          "document itself is still untouched.",
    tasks=[
        dict(id="T1.1", owner="claude", status="done",
             title="Find and enumerate every conflict",
             detail="Every contradiction, gap and measured finding, each with the "
                    "sections involved and a recommended resolution.",
             evidence="docs/audit/index.html",
             register_kinds=["contradiction", "gap", "finding"]),
        dict(id="T1.2", owner="claude", status="doing",
             title="Draft a resolution for every blocking item",
             detail="One spec file per system, each stating the chosen reading "
                    "once and then listing every other section the choice forces "
                    "a change to. That last part is what stops the pattern "
                    "recurring.",
             evidence="docs/design/spec/",
             register_severity=["blocking"]),
        dict(id="T1.3", owner="claude", status="doing",
             title="Draft a resolution for the rest",
             detail="The significant and minor conflicts, and the gaps below the "
                    "blocking line. <strong>Every open conflict now carries a "
                    "drafted edit</strong> \u2014 the section, the sentence as it "
                    "stands, and what to put there \u2014 and "
                    "<code>check_edits.py</code> reports any that do not, because "
                    "an item without an edit is checked by nobody. That is how "
                    "six clerical items went on being reported open for a whole "
                    "version after v3.0 had fixed them.",
             register_severity=["significant", "minor"]),
        dict(id="T1.4", owner="you", status="yours",
             title="Sign off, or overrule, each drafted resolution",
             detail="Most of this happened in v3.0, which adopted "
                    "<code>movement.md</code>, <code>fights.md</code> and "
                    "<code>vault.md</code> close to whole. What is left is the "
                    "spec files v3.0 did not take up \u2014 <code>wards.md</code>, "
                    "<code>economy.md</code>'s production peg \u2014 and the "
                    "resolutions for the six items v3.0 introduced.",
             evidence="docs/design/spec/README.md",
             blocked_by=["T1.2"]),
        dict(id="T1.5", owner="you", status="yours",
             title="Make the decisions that are genuinely yours",
             detail="Four of the eight are settled: v3.0\u2019s \u00a75.9 answered "
                    "character scarcity, the raid-versus-build trade-off and one "
                    "producer per realm, and \u00a713.4 answered how many ruleborn "
                    "stand at a post \u2014 \u201cone\u201d, with the "
                    "acknowledgement that it was the missing conversion between "
                    "two tables.<br><br>Four remain, and two of them now have "
                    "numbers they did not have: <strong>Q6</strong>, where "
                    "\u00a727.3\u2019s 1,019 days becomes about 1,343 under "
                    "\u00a75.9\u2019s rules and the casual curve slips nearly "
                    "twice as far as the others; and <strong>Q3</strong>, where "
                    "the page economy it was argued on has been overtaken by the "
                    "Library \u2014 the rank split moves the Codex total by 11% "
                    "and the Library moves the time to gather it by five times.",
             evidence="python3 tools/decision_support.py",
             register_kinds=["decision"]),
        dict(id="T1.6", owner="claude", status="blocked",
             title="Apply the decisions back into the design document",
             detail="<strong>Nothing so far has touched the document.</strong> "
                    "Every resolution lives in a side repository, which is the "
                    "right place to draft but the wrong place to stop — a "
                    "second copy of the truth is how this started. Each applied "
                    "decision gets a dated record naming the sections it "
                    "supersedes.",
             blocked_by=["T1.4", "T1.5"]),
        dict(id="T1.7", owner="claude", status="done",
             title="Split the content out of the prose",
             detail="The laws, ruleborn, terrain, buildings, wards and detection "
                    "numbers are now data, validated, with every contradiction "
                    "recorded as both readings rather than silently resolved. "
                    "Summary tables are generated from it and drift fails the "
                    "build.",
             evidence="content/ and tools/generate_docs.py"),
        dict(id="T1.8", owner="claude", status="blocked",
             title="Split the document into a specification and a research archive",
             detail="§19, §28 and §30 are roughly 40% of the text and hold the "
                    "reasoning behind decisions recorded elsewhere. Both halves "
                    "are worth keeping; together they mean the spec cannot be "
                    "read, diffed or implemented without the archive (D10).",
             blocked_by=["T1.4"]),
        dict(id="T1.9", owner="claude", status="done",
             title="Carry out the note rebalance \u00a78.8 says is already done",
             detail="\u00a78.8 states in the past tense that \u201cthe table now "
                    "runs eight or nine laws per note\u201d. All 48 law sheets "
                    "give Glow 12, Flow 11, Echo 10, Weight 9, Spark 8, Bloom 8, "
                    "Veil 7, Hush 6 \u2014 identical to v2.3 (C25), and Hush is "
                    "the hiding note, so the imbalance runs against the side "
                    "paying for it.<br><br><strong>Now written out.</strong> Nine "
                    "edits reach nine laws for every note, each argued from "
                    "\u00a78.1's own definition rather than chosen to make the "
                    "arithmetic work, with every chord still reachable at "
                    "unchanged cost. The tool refuses a proposal that puts two "
                    "opposite notes on one law \u2014 which it caught in the first "
                    "draft. It does not fix D14: the cheapest chord still costs 33 "
                    "stability against a day-2 capacity of 51, which is a gating "
                    "question rather than a distribution one.",
             evidence="python3 tools/note_rebalance.py",
             register=["C25", "D13", "D14"]),
    ],
),

# ===========================================================================
dict(
    id="S2",
    title="The economy model",
    subtitle="Done, and it has already paid for itself",
    blurb="§24 says a Python model generated roughly a quarter of the document's "
          "numbers. That model is not in the document, so none of those numbers "
          "could be re-derived. Rebuilt from the published formulas, it "
          "reproduces the first month to within 10% and the Keeper curve to "
          "within three days.",
    tasks=[
        dict(id="T2.1", owner="claude", status="done",
             title="Rebuild and calibrate the model",
             detail="Every choice the document leaves open is a documented field "
                    "in <code>config.py</code>; <code>data.py</code> is "
                    "transcription only, so it can be checked line by line.",
             evidence="python3 -m tools.economy_model"),
        dict(id="T2.2", owner="claude", status="done",
             title="Assert the findings, so they are re-checked rather than re-read",
             detail="Twelve tests: that the model still reproduces the document "
                    "where the document is self-consistent, that findings F1–F3 "
                    "still hold, and that the payout peg behaves as its spec page "
                    "claims.",
             evidence="python3 -m tools.economy_model.test_economy_model"),
        dict(id="T2.3", owner="claude", status="done",
             title="Model Aether and Essence spending, and the Library",
             detail="Done, and the answer is that there is almost nothing to "
                    "model. \u00a79.5 prices every sink; totalled against "
                    "\u00a79.3's own published day-301 production, <strong>every "
                    "Essence sink in the document is five days of income</strong> "
                    "and every Aether sink but upkeep is under three hours. "
                    "Upkeep at a full sheet is 3% of a day. Two of the three "
                    "resources are decorative as priced (F17), and the two birth "
                    "formulas that disagree by eleven times at the roster ceiling "
                    "turn out not to bind either way (C28).",
             evidence="python3 -m tools.economy_model sinks",
             register=["F17", "C28", "C24"]),
        dict(id="T0.8", owner="claude", status="done",
             title="Fix the Vault phase and the clock, and re-measure everything "
                   "that stood on them",
             detail="Two faults in the harness, found one after the other, and "
                    "the second while writing up the first.<br><br><strong>D24:"
                    "</strong> the Vault phase ended the moment the "
                    "<em>smallest</em> bag filled \u2014 two seconds, the Carrier "
                    "leaving on 60 of 300 \u2014 so every crew banked 53% "
                    "whatever the island did. Fixed, \u00a712.19\u2019s \u201ca "
                    "full crew fills in about ten seconds\u201d reproduces "
                    "exactly.<br><br><strong>D25:</strong> no crew read "
                    "\u00a75.4\u2019s clock at all, so nothing priced in time "
                    "could be measured \u2014 including \u00a712.19\u2019s own "
                    "\u201cthe alarm clock is the price\u201d.<br><br>Of the "
                    "findings that came out, <strong>two were withdrawn on "
                    "re-measurement</strong> and are recorded as such (F18, and "
                    "the first version of F19). What holds: the best fixed "
                    "stopping rule is near 90% rather than \u00a712.19\u2019s "
                    "70%, and the best rule is not a fixed one at all (F20); "
                    "what a raid pays varies 1.5\u00d7 with how it is played "
                    "(F19); and <strong>outcomes polarise with skill</strong> "
                    "\u2014 70% of an ordinary crew\u2019s raids land in "
                    "\u00a713.2\u2019s middle against 16% of an informed "
                    "crew\u2019s (F21).",
             evidence="python3 -m tools.heist_harness breakeven",
             register=["D24", "D25", "F18", "F19", "F20", "F21", "F14"],
             gate="\u00a712.19\u2019s ten seconds reproduced by a run, not by "
                  "arithmetic about a table"),
        dict(id="T2.5", owner="claude", status="done",
             title="Specify the Aether and Essence sinks, and withdraw the first fix",
             detail="F17 said the prices were too small. "
                    "<code>spec/sinks.md</code> says they are on the wrong kind "
                    "of curve, which is a different fix. From day 2 to day 301 "
                    "the faucets multiply by 122, 240 and 251; the prices aimed "
                    "at them multiply by 1 to 88. <strong>Starlight's biggest "
                    "sink outruns its faucet 12\u00d7 because \u00a710.2's "
                    "building curve is geometric and never ends</strong>; nothing "
                    "points a geometric curve at the other two. The spec "
                    "withdraws F17's own first edit \u2014 raising upkeep to 15 "
                    "an hour a point \u2014 because \u00a79.5's flat 0.5 is "
                    "already 60% of a day's Aether on day 2 and 3.2% on day 301, "
                    "so raising it buys about forty days and costs the early "
                    "game. It also found the one recurring price in the document: "
                    "waking a rested character, which at the roster cap falls due "
                    "at 199 heists a day against the four an engaged player runs.",
             evidence="python3 -m tools.economy_model scaling",
             register=["F17", "C18"],
             gate="every price checked against the faucet that pays it"),
        dict(id="T2.4", owner="claude", status="done",
             title="Regenerate \u00a79.3, \u00a710.2, \u00a714.2 and \u00a714.3 from the model",
             detail="<strong>Unblocked by v3.0.</strong> \u00a75.9 settles the "
                    "building and roster rules \u2014 one producer of each kind "
                    "per realm, partial staffing paying pro-rata, a crew on a "
                    "heist withheld from work. The published tables were not "
                    "re-run against that decision: day 2 is still 2,100 Starlight "
                    "and day 8 still 6,200. This is C19, and it is now the "
                    "clearest instance of the thing the register exists to stop."
                    "<br><br><strong>Done.</strong> The re-run is generated at "
                    "<code>docs/design/generated/pacing.md</code>, beside the "
                    "published figures rather than replacing them \u2014 the delta "
                    "is the decision. The first month holds; from day 91 the "
                    "published figures are up to twice what \u00a75.9's rules "
                    "produce, and Keeper 40 arrives 94 days late.",
             evidence="docs/design/generated/pacing.md",
             register=["C19", "C27"]),
    ],
),

# ===========================================================================
dict(
    id="S3",
    title="The determinism spike",
    subtitle="6–14 sessions, time-boxed — and everything rests on it",
    blurb="One simulation written once and compiled twice buys "
          "server-authoritative anti-cheat, free replays, free analytics, "
          "rehearsals, balance bots, co-op and a $5–15/month infrastructure "
          "bill at a million players. If it fails they all fail together.",
    tasks=[
        dict(id="T3.1", owner="claude", status="blocked",
             title="One function, the same checksum on four targets",
             detail="Desktop, server (WebAssembly), a cheap Android and an "
                    "iPhone. <strong>Put the server Wasm build in the first "
                    "round</strong> rather than deferring it — the whole "
                    "architecture rests on the same code running in both places.",
             gate="identical checksums on all four, or take the C# fallback "
                  "without renegotiating (\u00a724.7)",
             blocked_by=["T0.2"]),
        dict(id="T3.2", owner="claude", status="blocked",
             title="Fixed-point module and golden replays, portable from day one",
             detail="Written so that switching to the fallback costs the spike "
                    "and nothing else. The tick rate has to be settled first "
                    "(C7), because the replays encode it.",
             blocked_by=["T3.1", "T1.4"]),
    ],
),

# ===========================================================================
dict(
    id="S4",
    title="The scope conversation",
    subtitle="One decision, and §26.5 already names it the lever",
    blurb="48 laws, 144 creature forms, 44 resonances, 39 terrain features, 16 "
          "buildings, 27 screens and 12 languages, from one designer, one coding "
          "agent and three contractors. §26.8's own estimate leaves the iteration "
          "needed to find the fun unbudgeted.",
    tasks=[
        dict(id="T4.1", owner="you", status="ready",
             title="Decide launch content against the team that exists",
             detail="A ~40% cut is priced that preserves everything "
                    "distinctively Ruleborn: 24 laws rather than 48, 3 form-notes "
                    "rather than 8, ~20 resonances, 2–3 languages (§20.6 "
                    "already says this), constellations to v1.1, wards at 2 "
                    "levels. <strong>The Island Workshop is the one thing not to "
                    "cut</strong> — it is the only credible answer to the "
                    "content treadmill at this team size.",
             evidence="docs/analysis/06-build-readiness.md"),
        dict(id="T4.2", owner="you", status="ready",
             title="Budget the iteration that finds the fun",
             detail="§26.8 estimates ~270 agent runs and then says plainly that "
                    "the iteration is unbudgeted. For a novel genre blend with no "
                    "reference implementation that iteration is normally most of "
                    "the work. Proposed: 1–1.5× the build estimate (D9)."),
    ],
),

# ===========================================================================
dict(
    id="S5",
    title="Specification locks",
    subtitle="§26.7's sequence, unchanged",
    blurb="Each lock assumes there is one specification to lock, which is why "
          "stage 1 comes first. Nothing here is hard; all of it is irreversible.",
    tasks=[
        dict(id="T5.1", owner="claude", status="blocked",
             title="Lock the simulation contract (§24.10)",
             blocked_by=["T3.1"]),
        dict(id="T5.2", owner="claude", status="blocked",
             title="Lock the detection numbers (§12.17)",
             detail="Unblocked by C1, and the numbers are already data in "
                    "<code>content/detection.json</code>.",
             blocked_by=["T1.4"]),
        dict(id="T5.3", owner="claude", status="blocked",
             title="Lock the law schema (§7, §8.7)",
             detail="Unblocked by C3 and the note rebalance.",
             blocked_by=["T1.4", "T1.9"]),
        dict(id="T5.4", owner="claude", status="blocked",
             title="Lock saves, bundles and versions (§24.11)",
             blocked_by=["T5.1"]),
        dict(id="T5.5", owner="claude", status="blocked",
             title="Specify pathfinding and crew control before building it",
             detail="The largest gap and the system most likely to fail §30.7's "
                    "premise 3 — that delegated control still feels like "
                    "agency. Drafted in <code>spec/movement.md</code>; make felt "
                    "control a gate on the slice, not a polish item.",
             gate="≥ 70% felt control (§30.8)",
             blocked_by=["T1.4"]),
    ],
),

# ===========================================================================
dict(
    id="S6",
    title="Vertical slice",
    subtitle="§26.2 phase 2 — 10 to 12 weeks",
    blurb="A Heart and two realms, 8 common laws, 6 ruleborn, 2 Sages, ruins "
          "only, rehearsals. The first build that can answer whether the game is "
          "fun, which is the one question none of the analysis can.",
    tasks=[
        dict(id="T6.1", owner="claude", status="blocked",
             title="Build the slice",
             gate="≥ 7 of 10 outside playtesters ask for a second session; "
                  "≥ 15 decisions per heist (§26.2)",
             blocked_by=["T5.1", "T5.2", "T5.3", "T5.4", "T5.5"]),
        dict(id="T6.2", owner="you", status="blocked",
             title="Run §19.5's fun gate",
             detail="The exit test, and the first honest answer to whether any of "
                    "this works.",
             blocked_by=["T6.1"]),
    ],
),

# ===========================================================================
dict(
    id="S7",
    title="Alpha to launch",
    subtitle="§26.2 phases 3–6",
    blurb="Out of scope for planning at this distance, and listed so the "
          "roadmap does not end at the slice. Each phase ends only when its exit "
          "test passes.",
    tasks=[
        dict(id="T7.1", owner="claude", status="blocked",
             title="Alpha — 18 laws, player heists, the server, balance bots",
             gate="no dominant law in bot runs; ≥ 20% of testers still "
                  "playing after a week (§26.2)",
             blocked_by=["T6.2"]),
        dict(id="T7.2", owner="claude", status="blocked",
             title="Beta on TestFlight — all launch content, age protections, moderation",
             gate="stable; privacy and legal review passed (§26.2)",
             blocked_by=["T7.1"]),
        dict(id="T7.3", owner="you", status="blocked",
             title="Soft launch in a few English- and Portuguese-speaking countries",
             gate="the launch gates in §22.2",
             blocked_by=["T7.2"]),
        dict(id="T7.4", owner="you", status="blocked",
             title="Global launch",
             blocked_by=["T7.3"]),
    ],
),
]


#: Things that are not blocked by anything, and should still not be started.
#: §26.9 and the analysis both name these; they belong on a roadmap precisely
#: because they look available.
NOT_YET = [
    ("Gameplay code", "The determinism spike gates it. Anti-cheat, replay "
                      "validation, free analytics, rehearsals, balance bots and "
                      "the whole cost model fail together if it does not pass."),
    ("Character art", "The form-notes decision in stage 4 changes the quantity "
                      "by 3× — 144 forms against 54."),
    ("Detailed screen design", "C1, C5 and C6 each change what several screens "
                               "show."),
    ("Localisation", "Twelve languages against a coined vocabulary is a large "
                     "translation problem with no owner in the team model, and "
                     "§20.6 already says two at launch (G11)."),
    ("Claiming the name publicly", "§26.9 makes trademark clearance a gate, and "
                                   "it has not been done."),
]
