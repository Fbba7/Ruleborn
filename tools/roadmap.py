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
    subtitle="\u00a719.27, rewritten in v3.0, unchanged in v3.1 \u2014 and the critical path",
    blurb="v3.0 removed both pre-code player tests and replaced them with "
          "harnesses, stating the cost plainly: simulation can prove a system is "
          "legible, balanced and decision-dense, and cannot prove a game is "
          "enjoyable. Each harness below is buildable here, needs no engine, and "
          "has a threshold \u00a719.27 sets for itself.<br><br>v3.1 left this "
          "decision alone. Its companion section moved — "
          "<em>How we will actually find out</em> is \u00a725.4 now, not "
          "\u00a725.5 — because v3.1 closed four numbering holes v3.0 "
          "had left (\u00a75.8, \u00a77.8, \u00a710.4, \u00a725.3 were all "
          "missing). Every in-document citation was moved with them: 243 "
          "sections, no dangling reference. That is the kind of thing "
          "v3.1 is — a consistency release, not a design one.",
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
                    "because only four of the nineteen laws a rule sheet can "
                    "express help the defender (five, until F31 found one "
                    "counted on a comment about another law). A generator that reads the sign "
                    "of each law recovers it (F11). Writing all 48 laws out "
                    "against the rule sheet also settled \u00a712.21's rule: 16 "
                    "are parameter changes, 32 need an engine feature (F10), and "
                    "8 need a choice from the owner that a generator now has to "
                    "make (F12).",
             evidence="python3 tools/law_effects.py",
             register=["F9", "F10", "F11", "F12"],
             gate="a generated island at every realm level holds 30\u201345% "
                  "against a competent crew (\u00a713.2) \u2014 <strong>and "
                  "this gate cannot be met</strong>, which T0.10 measured "
                  "and F26 records"),
        dict(id="T0.10", owner="claude", status="done",
             title="Sweep the generator against both bands, and find one "
                   "of them unreachable",
             detail="T0.6 was marked done against a gate nobody had tested "
                    "as a whole: <em>a generated island at every realm "
                    "level holds 30\u201345%</em>. Swept across every "
                    "setting \u00a710.2 and \u00a75.2 permit \u2014 one to "
                    "three guard posts, nought to two geometry bands, "
                    "Guardian Post levels 1 to 5 \u2014 at the depths "
                    "\u00a712.6\u2019s own decision band implies. "
                    "<strong>At realm 1 none of the 24 combinations "
                    "reaches it.</strong> The strongest island on one post "
                    "holds 24.2% and the weakest on two holds 62.4%, so "
                    "\u00a713.2\u2019s 15-point band sits inside a "
                    "38-point gap (F26).<br><br>This is C29\u2019s pattern "
                    "turned on this roadmap: <strong>a gate that cannot be "
                    "passed as written</strong>, on a task already marked "
                    "done. T0.6\u2019s work was real \u2014 the generator "
                    "does weave laws and is measured \u2014 but its gate "
                    "was never checkable at realm 1 and nothing said so."
                    "<br><br>The ladder was the obvious fix and it fails "
                    "its collateral check: twice \u00a710.2\u2019s slope "
                    "is needed to reach the band at realm 1 \u2014 five "
                    "times, before the harness's peripheral vision was "
                    "corrected (D55) \u2014 and at that slope a maxed post "
                    "carries all four upper realms out of the top of it "
                    "(F27).",
             evidence="python3 -m tools.generator_settings",
             register=["F26", "F27"],
             gate="every realm/depth pair either satisfies both bands or "
                  "is recorded as unable to"),
        dict(id="T0.11", owner="claude", status="done",
             title="Give the harness a crew that clears the Heart before it "
                   "cracks",
             gate="a harness crew that takes guards down from behind before "
                  "the Vault, measured against \u00a713.2's bands and "
                  "\u00a719.27's gates with v3.3's crack noise on",
             detail="v3.3's crack noise calls every guard in the Heart to "
                    "the Vault five seconds into cracking, and no ordinary "
                    "crack is shorter. The harness's crews never take a guard "
                    "down, so with the rule ported an optimal crew succeeds "
                    "7.5% of the time against 65% without it, and every band "
                    "is overshot (F32). <code>sim/</code>'s planned heist shows "
                    "the other game: four guards down from the moss behind "
                    "them, a crack in 4.2 seconds, and the noise never sounds. "
                    "Until a harness crew plays that game, nothing measured "
                    "here says whether v3.3's Heart is fair.<br><br><strong>"
                    "Built.</strong> The clearing crew waits beside a "
                    "guard's path, as \u00a712.8 describes, and takes each "
                    "Heart guard down in two seconds before anyone cracks. "
                    "In the Heart alone at realm 3 with no wards it succeeds "
                    "65.0% against the optimal crew's 20.0% with the noise "
                    "on (n=80), and the two are level without it. On the "
                    "full island the Lantern Glares decide first (F33), so "
                    "the bands wait on T0.12.",
             evidence="python3 -m tools.heist_harness.test_harness "
                      "(test_a_crew_that_clears_the_heart_first_survives_the_crack_noise)",
             register=["F32"]),
        dict(id="T0.12", owner="claude", status="ready",
             title="Measure F33's Glare options, then re-run \u00a713.2's "
                   "table at \u00a75.2's posts",
             gate="\u00a713.2's table re-measured at the posts \u00a75.2 "
                  "gives, with v3.3's wards and the crack noise on, against "
                  "both the optimal and the clearing crew",
             detail="On v3.3's rules one Lantern Glare takes realm 3 from "
                    "42.5% held to 71.2%, and two to 97.5%, while \u00a75.2's "
                    "six wards there without one hold 46.2% (F33). And "
                    "\u00a713.2's table was measured at one guard post in "
                    "every realm: at \u00a75.2's posts realms 3 to 5 hold "
                    "91 to 99.5% (F34). Each Glare option F33 names is one "
                    "constant or flag here, so each is measured before the "
                    "owner picks; then the table is re-run as it states "
                    "itself.<br><br>v3.4 answered neither (both were "
                    "registered after its snapshot), and its brief 37 sweep "
                    "needs them: every realm level holds above its band with "
                    "no crack call at all, so the reach cannot be sized "
                    "against the bands until this is done (F35).",
             evidence="python3 -m tools.heist_harness.test_harness "
                      "(test_one_lantern_glare_outweighs_a_realm_of_other_wards, "
                      "test_13_2s_hold_table_was_measured_at_one_guard_post)",
             register=["F33", "F34"]),
        dict(id="T0.13", owner="claude", status="done",
             title="Port v3.4's two heist rules, and run brief 37's sweep",
             gate="the crack's reach and the disarmer rule in sim/ and the "
                  "harness, and \u00a732.9's sweep command runnable",
             detail="v3.4 gave the crack's call a reach \u2014 the guards within "
                    "5 m of the Vault by the walking path \u2014 and made a "
                    "ward's sensor ignore the crew member disarming it (briefs "
                    "37, F32 and G16). <strong>Ported:</strong> "
                    "<code>sim/</code>'s <code>path::steps_to</code> counts the "
                    "walk backwards from the Vault, and two goldens diverged "
                    "(seconds 15 and 43) and were re-recorded; the harness "
                    "takes rules \u201cv3.4\u201d by default, with v3.3 kept "
                    "so earlier numbers reproduce. Porting found that the "
                    "harness's optimal crew had been disarming what v3.3 made "
                    "a fifteen-second job and playing below the competent crew "
                    "(D59, fixed), and that the sensor rule covers the tile "
                    "and not the walk to it (G18).<br><br><strong>The "
                    "sweep</strong> (<code>depth --sweep crack_reach</code>) "
                    "cannot choose a reach: with no call at all the depth gate "
                    "fails from two realms up and every realm level holds far "
                    "above its band, and against the no-call baseline the 5 m "
                    "shipped costs the optimal crew 38 points of lead (F35).",
             evidence="python3 -m tools.heist_harness depth --sweep crack_reach; "
                      "cargo test in sim/",
             register=["F32", "G16", "G18", "D59", "F35"]),
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
                    "version after v3.0 had fixed them.<br><br>The same "
                    "discipline run in the other direction against v3.1: "
                    "\u00a731.9 publishes its own list of eight closed "
                    "items, and all eight verify — but checking rather "
                    "than believing it is what produced <strong>F24</strong> "
                    "and <strong>F25</strong>, neither of which that list "
                    "mentions.",
             register_severity=["significant", "minor"]),
        dict(id="T1.4", owner="you", status="yours",
             title="Sign off, or overrule, each drafted resolution",
             detail="Most of this happened in v3.0, which adopted "
                    "<code>movement.md</code>, <code>fights.md</code> and "
                    "<code>vault.md</code> close to whole. What is left is the "
                    "spec files v3.0 did not take up \u2014 <code>wards.md</code>, "
                    "<code>economy.md</code>'s production peg, "
                    "<code>first-build.md</code> \u2014 and the "
                    "resolutions for the six items v3.0 introduced."
                    "<br><br><strong>v3.1 adopted none of them.</strong> "
                    "\u00a710.3 (wards), \u00a79.6 (the <code>B(V)</code> "
                    "production term) and \u00a713.3 (the guided build) open "
                    "word for word as they did in v3.0. This queue did not "
                    "move, and it is the one that gates T1.6 and T1.8.",
             evidence="docs/design/spec/README.md",
             blocked_by=["T1.2"]),
        dict(id="T1.5", owner="you", status="done",
             title="Make the decisions that are genuinely yours",
             detail="<strong>Done in v3.3</strong>, which decided the last "
                    "of them: four ranks at 18/12/12/6 (Q3), the launch cut "
                    "(Q5), and every open question in \u00a727.3 (Q7). No "
                    "decision item is open in the register.<br><br>Four of the eight are settled: v3.0\u2019s \u00a75.9 \u2014 \u00a75.8 in v3.1 \u2014 answered "
                    "character scarcity, the raid-versus-build trade-off and one "
                    "producer per realm, and \u00a713.4 answered how many ruleborn "
                    "stand at a post \u2014 \u201cone\u201d, with the "
                    "acknowledgement that it was the missing conversion between "
                    "two tables.<br><br>Four remain, and two of them now have "
                    "numbers they did not have: <strong>Q6</strong>, where "
                    "\u00a727.3\u2019s 1,019 days becomes about 1,343 under "
                    "\u00a75.8\u2019s rules and the casual curve slips nearly "
                    "twice as far as the others; and <strong>Q3</strong>, where "
                    "the page economy it was argued on has been overtaken by the "
                    "Library \u2014 the rank split moves the Codex total by 11% "
                    "and the Library moves the time to gather it by five times."
                    "<br><br><strong>v3.1 settled none of the four.</strong> "
                    "It is the release that made the document check itself; "
                    "the four questions left are the ones no checker can "
                    "answer, which is why they are here.",
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
                    "Veil 7, Hush 6 \u2014 identical to v2.3, and unchanged again "
                    "in v3.0 and v3.1 (C25). Hush is "
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
        dict(id="T1.10", owner="you", status="done",
             title="Decide whether the ten playtesters exist",
             detail="<strong>Decided in v3.3: they do not.</strong> Phases 2 "
                    "and 3 exit on the harness gates in \u00a719.27, and no "
                    "phase before soft launch needs a player other than the "
                    "developer (C29).<br><br>\u00a725.4 rules them out \u2014 <em>\u201cNo recruited "
                    "panels, no paid playtesters, no thirty people in a "
                    "room\u201d</em> \u2014 and \u00a719.27 moves every "
                    "human instrument to soft launch. \u00a726.2 then exits "
                    "phase 2 on <em>seven of ten outside playtesters asking "
                    "for a second session</em> and phase 3 on <em>20% of "
                    "testers still playing after a week</em>, both two phases "
                    "earlier.<br><br>This is not a number disagreeing with a "
                    "number. It is <strong>10 to 12 weeks of work whose exit "
                    "test cannot be met as written</strong>, and the first "
                    "testing venue named anywhere in the document is "
                    "TestFlight, in phase 4.<br><br>Either the exit tests are "
                    "rewritten against the harness \u2014 and phase 2 is then "
                    "owed a gate it can actually pass \u2014 or the testers "
                    "are real and the plan owes a recruitment route, a "
                    "delivery channel, and a consent and privacy position. "
                    "Worth weighing before deleting it: <em>would they come "
                    "back unprompted</em> is the one question \u00a719.27 "
                    "concedes simulation cannot answer.",
             register=["C29"]),
        dict(id="T1.11", owner="claude", status="done",
             title="Merge the two checkers into one",
             detail="v3.1 ships its own build checker, and it is good: it pins "
                    "canonical constants in <code>data/</code>, recounts "
                    "\u00a726.1 from the tables, re-derives each creature\u2019s "
                    "size band from its head count rather than trusting the "
                    "column, and hashes generated blocks so a hand edit fails "
                    "the build.<br><br>There are now two checkers over one "
                    "document and they catch different things. This "
                    "repository\u2019s found the three-rank sentence v3.1\u2019s "
                    "missed (F24) and the six facts with two homes (F25); "
                    "v3.1\u2019s catches numbering holes, dangling citations "
                    "and generated-block edits that this one never looked "
                    "for.<br><br><strong>Two checkers over one artefact is the "
                    "fault the register is about, applied to the tools.</strong> "
                    "Merge them, keep every check from both, and make the "
                    "banned-phrasing checks derive from <code>data/</code> "
                    "rather than from a hand-written list \u2014 which is "
                    "\u00a731.4\u2019s own rule pointed at the checks."
                    "<br><br><strong>Done: <code>tools/check_document.py</code>.</strong> "
                    "69 checks over one artefact \u2014 it takes the HTML and "
                    "derives the text from it, so the two halves cannot read "
                    "different versions, which two checkers pointed at two paths "
                    "always could.<br><br>The merge needed a verdict neither had. "
                    "v3.1\u2019s checker exits non-zero on any failure, because it "
                    "is a gate; this repository\u2019s always exits zero, because "
                    "most of what it reports is an open register item. So every "
                    "check now declares which it is, and there are four outcomes "
                    "rather than two: <strong>PASS</strong>, <strong>OPEN</strong> "
                    "(failing, and its register item is open \u2014 expected), "
                    "<strong>RETIRED</strong> (a tracked check that now passes: "
                    "close the item) and <strong>BREAK</strong>. On v3.1: 56 pass, "
                    "13 open and tracked, nothing broken \u2014 <strong>so the "
                    "document checks can be a build gate for the first time</strong>."
                    "<br><br>BREAK includes one case neither checker could reach: "
                    "<strong>a check failing while the register calls its item "
                    "fixed</strong>. That is the register lying about the document, "
                    "which is exactly what C21\u2013C24 were, and it now fails the "
                    "build.<br><br><strong>Three checks were rewritten rather than "
                    "copied</strong>, and that is what made the merge worth doing. "
                    "The page costs are no longer guarded by a banned phrase but "
                    "derived: read the rank table, read all 48 sheets, then check "
                    "every rank-to-pages claim in the document in each of its three "
                    "grammatical forms. <code>--self-test</code> plants \u00a77.6\u2019s "
                    "sentence in a clean document and shows the phrase ban report "
                    "green on it (F24). <code>--coverage</code> keeps the superset "
                    "claim honest: it names all 28 of v3.1\u2019s checks and fails "
                    "if one stops being covered.",
             evidence="python3 tools/check_document.py --coverage",
             register=["F24", "F25"]),
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
             detail="<strong>Unblocked by v3.0.</strong> \u00a75.9 \u2014 renumbered \u00a75.8 in v3.1 \u2014 settles the "
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
                    "published figures are up to twice what \u00a75.8's rules "
                    "produce, and Keeper 40 arrives 94 days late.",
             evidence="docs/design/generated/pacing.md",
             register=["C19", "C27"]),
        dict(id="T2.6", owner="claude", status="done",
             title="Port \u00a79.6's raid pay to the economy model, then run "
                   "\u00a732.9's full re-run",
             gate="the model mints from design_facts' B(V) on the target's "
                  "Vault level, and regenerates \u00a714.2, \u00a714.3 and "
                  "\u00a710.2's day columns at both edges of \u00a79.6's band",
             detail="v3.4 moved every pacing sentence to what is measured and "
                    "left one number open: <em>\u201cthe full economy re-run "
                    "that regenerates 14.2, 14.3 and 10.2's day columns "
                    "(32.9)\u201d</em>.<br><br><strong>Done.</strong> D58 "
                    "first: <code>Config.document()</code> mints from "
                    "\u00a79.6's 2,400 and band on the target's Vault level, and "
                    "reads \u00a710.2 from <code>content/</code>, with births "
                    "bought in Essence, the roster's keep and \u00a77.6's pages "
                    "and chapters. Then the re-run, in \u00a79.5's order: the "
                    "raid-worth check keeps 2,400 on the document's reading "
                    "(3,200 on every day, F36), the birth rate moves to 1.3488, "
                    "and every table is printed at both edges.<br><br>Then an "
                    "adversarial review: each claim attacked by one agent and "
                    "re-checked by an independent judge (17 agents). Every number "
                    "reproduced; several rested on choices the document does not "
                    "make. The run was rebuilt on the review \u2014 storage, the "
                    "entry fee, strays, school-only bonuses, the Codex's launch "
                    "chapters, the Spire saved for first \u2014 and prints what "
                    "each open choice moves. An engaged player reaches Keeper 40 "
                    "on day 349\u2013357 and has everything built on day "
                    "699\u2013719. It found G22 (three choices \u00a714.1 does not "
                    "state, each worth months), F38 (strays leave the birth rule "
                    "nothing to set), F39 (the fee outweighs raids while saving), "
                    "C41 and C42, and reframed F36 and F37. The tables are the "
                    "document's to take once G22 and F38 are decided (C19).",
             evidence="docs/design/generated/pacing.md; python3 -m tools.economy_model rerun",
             register=["D58", "C19", "C35", "F36", "F37", "G19", "F38", "F39", "G22"]),
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
        dict(id="T3.1", owner="claude", status="doing",
             title="One function, the same checksum on four targets",
             detail="Desktop, server (WebAssembly), a cheap Android and an "
                    "iPhone. <strong>Put the server Wasm build in the first "
                    "round</strong> rather than deferring it — the whole "
                    "architecture rests on the same code running in both "
                    "places.<br><br><strong>Two of the four are done.</strong> "
                    "<code>sim/</code> is the Rust crate: fixed point "
                    "throughout, a committed sine table, xoshiro256++ per "
                    "subsystem, vectors rather than maps, and \u00a724.10's six "
                    "phases in order. <code>bash sim/run_spike.sh</code> builds "
                    "it for native x86-64 and WebAssembly and runs a full "
                    "240-second heist at five seeds under both: <strong>every "
                    "digest agrees</strong>. Different instruction sets and "
                    "different compiler backends, which is what makes it "
                    "evidence rather than a tautology.<br><br>The two that "
                    "remain are a real iPhone and a real Android, and they need "
                    "devices. Until then the fallback in \u00a724.7 is not "
                    "triggered and not ruled out.",
             gate="identical checksums on all four, or take the C# fallback "
                  "without renegotiating (\u00a724.7)",
             blocked_by=["T0.2"]),
        dict(id="T3.2", owner="claude", status="doing",
             title="Fixed-point module and golden replays, portable from day one",
             detail="Written so that switching to the fallback costs the spike and nothing else. The tick rate has to be settled first (C7), because the replays encode it \u2014 and C7 is closed.<br><br><strong>Built.</strong> <code>sim/replay.rs</code> is \u00a724.10's \u201ccommands, never state\u201d: a header pinning \u00a724.11's four things, a varint-delta command log, and one checksum a second. <code>sim/golden/*.rbh</code> are four heists encoded by a build that is now history; a test decodes each, re-simulates it and names the second any divergence starts at. Checked against a real regression rather than assumed: changing suspicion decay by one a tick fails at second 4 of 150.<br><br>Building it settled a number \u00a724.10 leaves open. Its own budget \u2014 120 bytes of header, 300 to 700 of commands, a checksum a second, under 2 KB \u2014 does not close at eight bytes a checksum: a 240-second heist would be 2,740. The stored sum is therefore the low four bytes and a full-length heist measures 1,215.",
             blocked_by=["T3.1", "T1.4"]),
        dict(id="T3.3", owner="claude", status="doing",
             title="The server's half: island bundles, the validator and the "
                   "ledger",
             detail="\u00a724.1: <em>\u201cthe server only re-simulates to "
                    "check.\u201d</em> Until this, a replay's header named its "
                    "island with a placeholder and every heist ran on one fixture "
                    "realm. <strong>Built.</strong> An island is a bundle with "
                    "one canonical encoding, addressed by its SHA-256 and "
                    "refused if it breaks \u00a75.2's budgets or \u00a76.1's "
                    "route; the rules version is a hash of the law table and "
                    "the build's behaviour on the golden heists, so it moves by "
                    "itself; the validator re-simulates a replay on the island "
                    "and rules its header names. Native and WebAssembly agree on "
                    "all of it, and the goldens' command and checksum bytes did "
                    "not move. <code>server/</code> is \u00a724.12's lease, "
                    "validate and grant as edge functions over \u00a724.8's "
                    "tables in SQLite: one lease per target (a unique index), "
                    "the entry fee and the haul settled in one transaction, an "
                    "append-only ledger held by triggers, retries that pay "
                    "nothing twice. Building it found G17 and D58. \u00a79.6's "
                    "three caps are enforced at grant \u2014 1.98 times the base "
                    "a raid, half again above the fatigue curve a day, five "
                    "days of it a week \u2014 and building them found G20. "
                    "Target lists are \u00a724.8's static files, one a band, "
                    "content-addressed so an unchanged band keeps its cache (G21)."
                    "<br><br>The Island Workshop runs on it too (\u00a718.6): "
                    "publishing only what its creator has cleared, by a replay "
                    "the server re-simulates; browsing, with 13-to-15s on the "
                    "curated list; completions once a player on \u00a718.7's "
                    "ladder; ratings, reports a person resolves inside 24 hours, "
                    "bans that take a player's islands out everywhere, and "
                    "one-tap remixes. Building it found G26, D62 and C43."
                    "<br><br>Renown, leagues and seasons (\u00a712.9, "
                    "\u00a718.1) are booked with each grant: \u00a712.9's "
                    "formula, the defender's mirror, Dust and Ember as floors, "
                    "and an eight-week rollover that writes results, grants "
                    "Star-and-up cosmetics and pulls Renown halfway back. The "
                    "league boundaries are fitted to \u00a714.7's shares by a "
                    "population model (G27), which shows those shares and "
                    "\u00a714.7's arrival times cannot both hold under a "
                    "zero-sum Renown (F40). Constellations (thirty Keepers "
                    "from level 6, a founder and four elders, a league by "
                    "combined Renown) and crews of four to eight are built; "
                    "chat, votes and anomalies are not (D63)."
                    "<br><br><strong>Not yet:</strong> platform sign-in (needs "
                    "the stores), crossing realms, \u00a712.22's ratings and "
                    "fallback targets, and a landing command in the replay.",
             evidence="node --no-warnings --test server/test/*.test.mjs; "
                      "bash sim/run_spike.sh",
             register=["G17", "D58", "G20", "G21", "G26", "D62", "C43",
                       "F40", "G27", "D63"]),
        dict(id="T3.4", owner="claude", status="doing",
             title="The client's half: the simulation inside Godot, and a "
                   "replay on screen",
             detail="\u00a724.7: the simulation is <em>\u201cwritten once and "
                    "compiled for every target it runs on\u201d</em>, as a Rust "
                    "GDExtension. <strong>Built for the desktop.</strong> "
                    "<code>client/</code> is a Godot 4.5 project in \u00a721.1's "
                    "9:19.5 portrait frame with <code>sim/</code> linked in: the "
                    "replay screen re-simulates a golden replay one tick at a "
                    "time and draws it, and every second compares its own "
                    "checksum with the replay's, so a phone that drifted from "
                    "the server would say so on screen. All five goldens agree "
                    "at every second. A guard's cone is drawn tile by tile from "
                    "the simulation's own sight rule (\u00a721.12), and every "
                    "control is checked against \u00a721.1's size, reach, corner "
                    "and safe-area rules. The drawing is flat and top-down; the "
                    "diorama is the art pass.<br><br>A heist can be played too: "
                    "each tap is a command stamped with the tick it was made, "
                    "the log is recorded as the replay a device queues, and the "
                    "result screen shows the check's verdict. The planned heist's "
                    "commands given live record the golden replay byte for "
                    "byte. And the whole of \u00a724.12 runs end to end: the "
                    "client signs in to <code>server/</code>, takes a target "
                    "from \u00a724.8's lists, leases it, plays it, and submits; "
                    "the server re-simulates the replay and pays.<br><br>"
                    "Every word on screen comes from one catalogue, in English "
                    "and Brazilian Portuguese (\u00a720.6); a pseudo-locale test "
                    "fails any word typed into a script, and the layout rules "
                    "are checked in both languages. A settings screen keeps "
                    "the language, three volumes, reduced motion and haptics, "
                    "saved as they change and restored on the next launch. The "
                    "Portuguese is a working draft: \u00a726.9's read-aloud of "
                    "the coined words comes before the launch translation.<br><br>"
                    "The island builder is in too (\u00a713): ground on the "
                    "grid, guards, wards, woven laws and their pylons, the "
                    "Vault, through the simulation's own island, so the rules "
                    "a builder is held to are the server's publishing rules; "
                    "what the laws make together is named as they are woven, "
                    "and Raid it plays the island and leads back.<br><br>"
                    "<strong>Not yet:</strong> the phone half of \u00a724.7's "
                    "spike \u2014 the extension building and loading on a real "
                    "iPhone and Android, whose failure \u00a724.7 says moves the "
                    "simulation to C# \u2014 platform sign-in and \u00a712.22's "
                    "target choice. Every one of \u00a724.10's eleven command "
                    "kinds has a control: a tap is read by what is on the tile.",
             evidence="python3 client/status.py"),
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
        dict(id="T4.1", owner="you", status="done",
             title="Decide launch content against the team that exists",
             detail="<strong>Decided in v3.3</strong> (\u00a726.1, \u00a77.10): "
                    "24 laws chosen by engine cost, 54 forms, 12 signature "
                    "resonances, two ward levels, two languages, constellations "
                    "to v1.1, and the Workshop kept. The proposal it answered: A ~40% cut is priced that preserves everything "
                    "distinctively Ruleborn: 24 laws rather than 48, 3 form-notes "
                    "rather than 8, ~20 resonances, 2–3 languages (§20.6 "
                    "already says this), constellations to v1.1, wards at 2 "
                    "levels. <strong>The Island Workshop is the one thing not to "
                    "cut</strong> — it is the only credible answer to the "
                    "content treadmill at this team size.",
             evidence="docs/analysis/06-build-readiness.md"),
        dict(id="T4.2", owner="you", status="done",
             title="Budget the iteration that finds the fun",
             detail="<strong>Budgeted in v3.3</strong> at 1\u00d7 the build as "
                    "a floor: 229 to 405 runs, about 640 in all (\u00a726.8). "
                    "The proposal it answered: §26.8 estimates ~270 agent runs and then says plainly that "
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
                    "<code>content/detection.json</code>. Built ahead of the "
                    "sign-off in <code>sim/</code>: noise along the walkable path, "
                    "the six guard states, the realm alarm and every modifier "
                    "one level allows, with no dice anywhere, as §12.17 promises. "
                    "<code>sim/content_gate.py</code> checks 64 values against the "
                    "content files and fails on any number it neither compares nor "
                    "names. Locking still waits on T1.4.",
             blocked_by=["T1.4"]),
        dict(id="T5.3", owner="claude", status="blocked",
             title="Lock the law schema (§7, §8.7)",
             detail="Unblocked by C3 and the note rebalance.<br><br><strong>The "
                    "rule sheet is built ahead of the lock.</strong> "
                    "<code>sim/</code> carries all 48 laws as exact ratios "
                    "generated from <code>content/law_effects.json</code>, and "
                    "reads 31 of the sheet's 34 parameters each tick from the "
                    "laws whose pylons stand, so all 24 launch laws apply "
                    "(\u00a77.10), each proved by a test. v3.4's rows for "
                    "contact, size, time, bands, jumps, stuns and revival are "
                    "parameters here, named for the rule and not the law. "
                    "Breaking a pylon switches its law off from the next tick. "
                    "The gate names the other three \u2014 lantern light and two "
                    "no law sets \u2014 so the schema's gaps are listed rather "
                    "than hidden. Building it split two health parameters that "
                    "each meant two rules (F31), and found nine sheets that "
                    "stop short of a rule (G23) and a regrowth row holding "
                    "three (G24).<br><br>\u00a78 is built on it: every harmony, "
                    "dissonance and chord and the twelve launch resonances, "
                    "worked out each tick from the standing laws and each "
                    "proved by a test. Most rows are one line and needed a "
                    "reading (G25); a chord's draw and crown laws wait for the "
                    "economy on the server (D61).",
             register=["F31", "G23", "G24", "G25", "D61"],
             blocked_by=["T1.4", "T1.9"]),
        dict(id="T5.4", owner="claude", status="blocked",
             title="Lock saves, bundles and versions (§24.11)",
             blocked_by=["T5.1"]),
        dict(id="T5.5", owner="claude", status="doing",
             title="Specify pathfinding and crew control before building it",
             detail="The largest gap and the system most likely to fail "
                    "\u00a730.7's premise 3 \u2014 that delegated control "
                    "still feels like agency. Drafted in "
                    "<code>spec/movement.md</code>; make felt control a gate "
                    "on the slice, not a polish item.<br><br><strong>The "
                    "buildable half is built.</strong> <code>sim/path.rs</code> "
                    "is \u00a712.18's pathfinder: breadth-first, four "
                    "neighbours in a fixed north-east-south-west order, ties "
                    "by tile index. Breadth-first rather than A* because A*'s "
                    "answer depends on the heuristic and on how a priority "
                    "queue returns equal keys \u2014 two places correct "
                    "implementations differ. Terrain slows the walk and cannot "
                    "bend the route, which is the spec's rule: a pathfinder "
                    "that went round mud would be choosing for the "
                    "player.<br><br>\u00a712.18's four behavioural clauses are "
                    "tests rather than prose \u2014 no re-routing, no picking "
                    "a different door, crew pass through one another, the "
                    "command and never the path.<br><br><strong>A whole heist "
                    "now runs.</strong> The Vault, loading, fights, ambushes, "
                    "knockouts, capture, the skiff and \u00a712.9's grades are in "
                    "<code>sim/</code>, and a heist planned the way a player would "
                    "play it ends Clean with every bag full. It is committed as "
                    "a golden replay. Building it found that \u00a712.6's crack "
                    "noise is erased by \u00a712.17's decay before it can matter, "
                    "and that on plain ground \u00a712.8's ambush cannot be "
                    "reached: the last crouched step behind a guard is heard. "
                    "What is left is the half a measurement cannot settle: "
                    "whether it <em>feels</em> like agency, which is "
                    "\u00a730.8's 70% gate and needs people.",
             gate="\u2265 70% felt control (\u00a730.8)",
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
    ("Realm design", "One gate left, and it is a table rather than a rule: "
                     "the day and income columns a realm is paced by still "
                     "ship from the economy model's earlier run (C19), and "
                     "v3.4 hands that re-run to this repository (T2.6). v3.3 "
                     "settled the other eight \u2014 the ward budget, the post "
                     "ladder, the hold band, what the generator weaves, the "
                     "authored laws, ward levels and pylons."),
    ("Character art", "Nothing in the register blocks it since v3.3 \u2014 one "
                      "card per ruleborn and 54 forms \u2014 but \u00a726.2 "
                      "puts the art-style test on target devices first, so the "
                      "style is settled before the quantity is drawn."),
    ("Detailed screen design", "Nothing in the register blocks it since v3.4, "
                               "which settled the last question: the scout "
                               "report shows no patrol positions (brief 38). "
                               "v3.3 settled the roster the character screens "
                               "read, the ranks the Codex shows and the "
                               "Library's place on the build screen. "
                               "\u00a726.2's art-style test still comes first, "
                               "as it does for the characters."),
    ("Localisation", "Two launch languages with a named owner since v3.3, but "
                     "the coined vocabulary gets its native-speaker read-aloud "
                     "(\u00a726.9) before anything is translated."),
    ("Claiming the name publicly", "§26.9 makes trademark clearance a gate, and "
                                   "it has not been done."),
]
