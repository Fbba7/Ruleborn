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

import json as _json
from pathlib import Path as _Path

#: How many decisions the owner's brief holds, read from it so the roadmap
#: cannot go stale when an entry is added.
_BRIEF = len(_json.loads((_Path(__file__).resolve().parent.parent / "docs" / "decisions"
                          / "brief.json").read_text(encoding="utf-8"))["entries"])

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
        dict(id="T0.12", owner="claude", status="done",
             title="Measure F33's Glare options, then re-run \u00a713.2's "
                   "table at \u00a75.2's posts",
             gate="\u00a713.2's table re-measured at the posts \u00a75.2 "
                  "gives, with the owner's answers \u2014 no crack call "
                  "(F35), the Glare's reach (F33, F52) \u2014 against both "
                  "the optimal and the clearing crew",
             detail="On v3.3's rules one Lantern Glare takes realm 3 from "
                    "42.5% held to 71.2%, and two to 97.5%, while \u00a75.2's "
                    "six wards there without one hold 46.2% (F33). And "
                    "\u00a713.2's table was measured at one guard post in "
                    "every realm: at \u00a75.2's posts realms 3 to 5 hold "
                    "91 to 99.5% (F34). The owner has answered F33 (a Glare "
                    "reaches the alarm's 4 m) and F35 (no guard hears the "
                    "Vault), and both are built. Building F33 found that the "
                    "alarm's reach is realm-wide under Whispers, so two Glares "
                    "still held 91.5% there (F52); the owner answered F52 (a "
                    "fixed 4 m), built: two Glares now hold 72.5% against six "
                    "other wards' 37.0% (n=200), as the brief measured.<br><br>"
                    "<strong>Re-run.</strong> At §5.2's wards and posts with "
                    "every answer built (n=800), the competent crew is held "
                    "47.6, 60.8, 59.9, 90.6 and 95.5% at realm levels 1 to 5 "
                    "— every level above 30 to 45%, and from realm 4 the "
                    "guards alone. The optimal and clearing crews are held "
                    "more. What to do about it is the owner's: F55.<br><br>v3.4 answered neither (both were "
                    "registered after its snapshot), and its brief 37 sweep "
                    "needs them: every realm level holds above its band with "
                    "no crack call at all, so the reach cannot be sized "
                    "against the bands until this is done (F35).",
             evidence="python3 -m tools.heist_harness holds 800; "
                      "python3 -m tools.heist_harness.test_harness "
                      "(test_finding_5_2s_budget_holds_every_realm_level_above_13_2s_band, "
                      "test_one_lantern_glare_outweighs_a_realm_of_other_wards, "
                      "test_the_decided_glare_is_one_strong_pick_not_a_switch, "
                      "test_13_2s_hold_table_was_measured_at_one_guard_post)",
             register=["F33", "F34", "F35", "F52", "F55"]),
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
                    "supersedes. It includes §26.8's missing rows: a costed phase "
                    "for the home economy (G42) and for the interface and its art "
                    "(G66), which completion then reads (TD.47).",
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
        dict(id="T1.13", owner="you", status="done",
             title="Answer the decision brief",
             detail="<strong>Answered on 25 September 2026:</strong> five "
                    "picked on the brief's page, and the other 38 accepted as "
                    "recommended in one instruction. Every answer is on the "
                    "page and in <code>docs/decisions/answers.json</code>. Twelve "
                    "answers keep what the build already does; the rest are "
                    "T1.14. Building them found three new questions for the "
                    "owner \u2014 F52 (the Glare\u2019s reach under Whispers), "
                    "F53 (the base, 5,000) and F54 (a non-raider\u2019s last "
                    "level) \u2014 now in the brief.",
             evidence="docs/decisions/answers.json",
             register=["F33", "F35", "F37", "F39", "C41", "G17", "G20", "F38", "C42", "F36", "G37", "F40", "G27", "F41", "F42", "G28", "G22", "G23", "G25", "G24", "G36", "F49", "G26", "C43", "F43", "F50", "G39", "F46", "F47", "G33", "G21", "F48", "G30", "F44", "F45", "G31", "G19", "G32", "G29", "G38", "G35", "G34", "F51"]),
        dict(id="T1.14", owner="claude", status="done",
             title="Build what the answers decided",
             detail="Each answer names a build change — the server's "
                    "fee, weekly counts and friendly heists, the simulation's "
                    "alarm reach, Vault call, Delay and regrowth, the economy "
                    "model's base and pages, the shop without a currency, "
                    "refunds, deletion from the web — and a document edit. "
                    "Each was built, checked and reviewed in five batches; an "
                    "item now waits only on the document taking its edit. "
                    "What an answer still needs from outside the repository "
                    "(a store console, the deployment's bucket, a web client "
                    "id) or from the client is on its line in "
                    "<code>docs/decisions/answers.json</code>; G24's regrown "
                    "kind and F33's kit re-measure (waiting on F52) are the two "
                    "left to build here.",
             evidence="docs/decisions/answers.json",
             register=["F33", "F35", "F37", "F39", "C41", "G20", "F38", "F36", "G37", "F40", "F41", "G28", "G23", "G24", "G26", "F43", "F50", "G39", "F46", "G33", "G21", "F48", "G30", "F44", "G19", "G32", "G29", "G38", "G35", "G34", "F51"]),
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
                    "699\u2013719. Since the owner\u2019s answers (F36, F37, F38, "
                    "F39, C41, F46, G19, G28) the run ships a base of 5,000 "
                    "(F53) and a birth rate of 1.3455: Keeper 40 on day "
                    "307\u2013321, everything built on day 586\u2013618, and the "
                    "38th character with it. It found G22 (three choices \u00a714.1 does not "
                    "state, each worth months), F38 (strays leave the birth rule "
                    "nothing to set), F39 (the fee outweighs raids while saving), "
                    "C41 and C42, and reframed F36 and F37. G22 and F38 are "
                    "decided, so the tables are the document's to take, with "
                    "F53's base (C19).",
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
                    "the phones TD.48 brings. Until then the fallback in \u00a724.7 is not "
                    "triggered and not ruled out.",
             gate="identical checksums on all four, or take the C# fallback "
                  "without renegotiating (\u00a724.7)",
             blocked_by=["T0.2", "TD.48"]),
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
                    "<br><br>The season track (\u00a718.2) earns stars with "
                    "each heist, claims fifty tiers in order with a free first "
                    "tier and \u00a718.8's catch-up, and keeps past seasons' "
                    "tiers on offer; every item is priced in money (F41: no "
                    "currency), bought through an intent that holds "
                    "\u00a720.2's monthly cap for minors, a receipt granted "
                    "once, a gift bought for a friend and a refund taken back "
                    "(G32); cosmetics are owned and worn, the defender's set "
                    "travelling with the lease. The figures are G28's "
                    "readings; "
                    "F42 names the points; the stores and authored cosmetics "
                    "are D64. Telemetry logs \u00a724's events under a "
                    "pseudonym, takes the device's in checked batches with no "
                    "positions, keeps them \u00a724.3's 90 days and reports "
                    "the launch gates' figures and cohort retention (G29, D65). "
                    "An account can be deleted from inside the game, and one "
                    "under 13 is at once: the person goes and the records the "
                    "document never edits stay, keyed to nobody (F43). "
                    "Matchmaking rates raiders and islands with Glicko-2 at "
                    "\u00a712.22's constants, offers a list whose middle is "
                    "drawn from the raider-success band, counts echoes when "
                    "the band is thin, and holds \u00a712.3's new-player "
                    "protection and Trace (G30, D66); building it found F44 "
                    "and F45. A foiled heist now pays the defender \u00a79.4's "
                    "share of what the crew carried, which the simulation "
                    "reports, rising by \u00a713.1's rule each season (G31). "
                    "Game Center sign-in and App Store purchases are checked "
                    "against a pinned Apple root, without asking Apple (G32, "
                    "D67); reading \u00a712.4 for what the server must keep "
                    "back found F46. The load test plays \u00a714.1's players "
                    "through it and finds an engaged day writes at least 46 "
                    "rows against \u00a724.1's budget of five, and a "
                    "re-simulation over the free plan's CPU limit (F47, G33). "
                    "Replays are kept 90 days for both sides to watch, and the "
                    "defender's notification waits out \u00a720.2's night "
                    "(G34, D68). Friends, friendly heists that take nothing "
                    "from the friend, the friends' feed and challenge links "
                    "are built (F48, G35). \u00a718.3's eras run: the week's "
                    "era is on every lease, travels in the replay's header, is "
                    "first on the simulation's rule sheet and part of the rules "
                    "version (F49, G36, D69).<br><br>An adversarial review of "
                    "everything built since the leagues \u2014 102 agents, each "
                    "finding tried by two independent skeptics \u2014 confirmed 35 "
                    "defects, and all are fixed with a test each: a StoreKit "
                    "receipt accepted from any certificate under a pinned root; "
                    "foiled heists minting a colluding defender currency and "
                    "stars without end (G37); a malformed body crashing the "
                    "server; a banned player escaping by deleting their "
                    "account; a migration able to lose every balance; any realm "
                    "name taking unlimited islands into matchmaking; reminders "
                    "in a minor's night; and smaller ones in the shield, Trace, "
                    "offers, telemetry, constellations and deletion."
                    "<br><br>What the server stores is declared, column by "
                    "column \u2014 236 in 39 tables, each with its store data "
                    "type, purpose, time kept and what a deletion does \u2014 "
                    "and the App Privacy and Data safety answers are written "
                    "from it; a test fails on a column added undeclared and "
                    "does every deletion and time limit it states. The "
                    "inventory behind it (59 agents, each gap tried by a "
                    "skeptic) found and fixed: a key made afresh on every "
                    "restart, which left a deleted player\u2019s telemetry "
                    "behind; a ban that kept the whole account tied to the "
                    "identity; the outbox and closed invites and links kept "
                    "for good; old target lists naming players for good; an "
                    "under-13 deletion that only severed; a new account "
                    "trusted as an adult before its age check; and a deletion "
                    "a database restore would undo (F50, G38, G39, D70). A "
                    "review of that change (65 agents) confirmed 24 more, all "
                    "fixed with tests: bytes erased that another player\u2019s "
                    "raid still needed, an erased rating written back by a "
                    "raid leased before, files left for good by a crash after "
                    "the commit, a torn journal line swallowing the next, an "
                    "empty key accepted, the ban\u2019s exact time matching a "
                    "deleted account back, stray target lists never swept, "
                    "and eleven tests a broken line would have passed."
                    "<br><br>Google\u2019s side of the stores: \u201cSign in with "
                    "Google\u201d ID tokens are checked against the keys Google "
                    "publishes, and Play purchases against the app\u2019s licence "
                    "key, then looked up and consumed with the Play Developer API "
                    "before the grant \u2014 the review of this work found that "
                    "Play refunds a purchase nobody consumes after three days, and "
                    "that only Google can say which purchases were a tester\u2019s "
                    f"(D67). The {_BRIEF} decisions only the owner can make are a brief, "
                    "each with options, numbers and a recommendation, answered on "
                    "its own page. Push goes out through Firebase Cloud Messaging "
                    "as the project\u2019s service account; its review found that "
                    "FCM would hold a message for a phone that was off and show it "
                    "inside a minor\u2019s night, so each now expires when the "
                    "player\u2019s night begins (D68)."
                    "<br><br><strong>Not yet:</strong> Google Play's sign-in "
                    "and receipts (need Google's API), crossing realms, \u00a712.22's generated "
                    "fallback targets, and universes of several realms.",
             evidence="node --no-warnings --test server/test/*.test.mjs; "
                      "bash sim/run_spike.sh",
             register=["G17", "D58", "G20", "G21", "G26", "D62", "C43",
                       "F40", "G27", "D63", "F41", "F42", "G28", "D64",
                       "G29", "D65", "F43", "F44", "F45", "G30", "D66",
                       "G31", "F46", "G32", "D67", "F47", "G33",
                       "G34", "D68", "F48", "G35", "F49", "G36", "D69",
                       "G37", "F50", "G38", "G39", "D70", "G44"]),
        dict(id="T3.4", owner="claude", status="doing",
             title="The client's half: the simulation inside Godot, and a "
                   "replay on screen",
             detail="\u00a724.7: the simulation is <em>\u201cwritten once and "
                    "compiled for every target it runs on\u201d</em>, as a Rust "
                    "GDExtension. <strong>Built for the desktop.</strong> "
                    "<code>client/</code> is a Godot project (4.5 until TD.1 moves it "
                    "to 4.7.2) in \u00a721.1's "
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
                    "target choice, and \u00a721's landing picker (TD.41 builds it, "
                    "and TD.18 the rest of the raid's screens): the crew lands "
                    "on a spot chosen by the heist's seed. Every other of the "
                    "twelve command kinds has a control: a tap is read by what "
                    "is on the tile.",
             evidence="python3 client/status.py"),
    ],
),

# ===========================================================================
dict(
    id="SC",
    title="The client, built to be checked",
    subtitle="The frontend plan: architecture first, then what the percentage counts",
    blurb="\u00a724.7 puts the simulation in Rust and the shell in Godot GDScript "
          "(4.5 here until TD.1 moves it to v3.5's 4.7.2); online is the rule and "
          "offline the exception (G41's answer); \u00a724.9 asks for tests that "
          "assert behaviour; Screens v3, recorded in \u00a723.5, is the visual "
          "reference and stage SD builds it; \u00a726.8 calls interface screens, localisation and the Workshop "
          "safe to hand over and anything needing a real device not. The plan: "
          "put the architecture in first, so the design lands in one place and a "
          "defect names its layer, then build what moves the frontend figure, "
          "each task saying what it will move.",
    tasks=[
        dict(id="TC.1", owner="claude", status="done",
             title="Architecture: one-way data, typed layers, a design that lands in one place",
             detail="The market-standard shape for a mobile game client, in "
                    "Godot's own terms. <strong>Views</strong> (scenes) only draw "
                    "and send intents. <strong>Presenters</strong> are plain "
                    "GDScript classes that turn state into what a view shows, "
                    "with no nodes, so they are tested headless. "
                    "<strong>One store</strong> holds the app's state and changes "
                    "only through actions a reducer applies (unidirectional "
                    "data, as Redux and The Composable Architecture do it), and "
                    "keeps the last actions in a ring buffer, so a defect report "
                    "carries the steps that caused it. <strong>Repositories</strong> "
                    "are the only code that calls the server, one per area "
                    "(account, islands, heists, track, shop, Workshop, social), "
                    "returning typed results whose errors are the server's own "
                    "reason codes; <strong>\u00a724.12's queue</strong> keeps "
                    "a heist's submission and a purchase's receipt until the "
                    "server has them. <strong>Services</strong> (settings, "
                    "languages, audio, haptics, telemetry, push, store "
                    "purchases, platform sign-in) sit behind interfaces with a "
                    "fake for each, built in one container at start, so tests "
                    "run with fakes and nothing reaches a global. A "
                    "<strong>router</strong> owns the screen stack. The look lives "
                    "in <strong>design tokens</strong> (colours, type, spacing, "
                    "motion) read from one file into a Godot Theme, and "
                    "<strong>components</strong> built from them: what Claude "
                    "Design hands over replaces the tokens and the components, "
                    "and no screen. The screens built so far move onto it.",
             gate="no frontend figure moves (the screens are counted already); "
                  "every later task is cheaper and its defects easier to place",
             evidence="python3 client/status.py; bash tools/check_all.sh"),
        dict(id="TC.2", owner="claude", status="done",
             title="Defects kept out, and findable when they get in",
             detail="Checks in <code>tools/check_all.sh</code> from the first "
                    "commit: every GDScript variable and function typed, with "
                    "Godot's untyped and unsafe-access warnings made errors; "
                    "gdtoolkit's lint and format; a test for every reducer and "
                    "presenter; a flow test for every route; a contract check "
                    "that every route the client calls exists in "
                    "<code>server/src/http.mjs</code> and every reason the server "
                    "refuses with has a localised message, so a server change "
                    "cannot leave the client silent; the existing pseudo-locale, "
                    "layout and \u00a721.1 size checks on every new screen; and "
                    "\u00a726.8's dead-code and duplication audit every 20 to 30 "
                    "runs. In the running app: one error code a failure, shown to "
                    "the player in words and logged with the action trail, and a "
                    "debug overlay in development builds that shows the state and "
                    "the last actions. Each slice gets an adversarial review "
                    "before it is committed.",
             gate="no frontend figure moves; it is what keeps later figures honest",
             evidence="python3 tools/client_contract.py; gdlint; python3 client/status.py"),
        dict(id="TC.3", owner="claude", status="doing",
             title="Project structure on both stores' targets",
             detail="Done here: export presets for Android and iPhone "
                    "(client/export_presets.cfg), the extension's arm64 "
                    "libraries for both phones in ruleborn.gdextension, and "
                    "client/export.sh, which builds each store's app where its "
                    "tools are. <code>export.sh check</code> runs here: the "
                    "simulation and extension compile for iPhone and Android "
                    "arm64, and the project exports with the Android preset, "
                    "its pack holding every file the game reads by path \u2014 "
                    "which found that the word catalogues had been imported as "
                    "translations and would not have shipped, so every screen "
                    "would have shown keys (fixed: they ship as they are). "
                    "Left: the Android build needs the SDK and NDK, which come "
                    "only from dl.google.com, a host this environment's network "
                    "policy refuses; the iPhone build needs a Mac with Xcode and "
                    "the App Store team. Counted when a client builds on both "
                    "stores' targets.<br><br><strong>v3.6 raises the bar</strong> "
                    "(\u00a724, \u00a726.6): the store builds are on Godot 4.7.2 "
                    "(TD.1), Android at API level 36 and the iPhone in Xcode 26 "
                    "with the iOS 26 SDK, uploaded to the Play internal track and "
                    "TestFlight, and \u00a726.8 now counts them in the "
                    "determinism spike. The export check here ran on 4.5's "
                    "templates and is re-run on 4.7.2's.",
             gate="+4.86 frontend points when both build on 4.7.2 at the stores' "
                  "current levels: Android once dl.google.com is allowed (or on a "
                  "machine with the SDK), the iPhone on a Mac with Xcode 26",
             evidence="bash client/export.sh check; client/pack_check.py",
             blocked_by=["TD.1"]),
        dict(id="TC.4", owner="claude", status="done",
             title="Accessibility: \u00a720.8 and \u00a721.8 in full",
             detail="Text size, contrast checked against \u00a721.8's 4.5:1 "
                    "and a perceptual model, nothing carried by colour alone, "
                    "colour-blind-safe states, reduced motion, haptics and "
                    "separate volumes, screen-reader labels, and \u00a721.10's "
                    "grayscale test run on every screen. Applied through the "
                    "tokens and components, so the design inherits it.",
             gate="+8.80 frontend points when \u00a721's set is in the client",
             evidence="client/tests/a11y_tests.gd, through python3 client/status.py; D72"),
        dict(id="TC.5", owner="claude", status="ready",
             title="Localisation: every launch screen and name in both languages",
             detail="The catalogue already carries English and a working "
                    "Portuguese. Every new screen's words go into it as they are "
                    "made, plurals and numbers formatted per language. It counts "
                    "only once a native speaker has read the Portuguese "
                    "(\u00a726.9), which is yours to arrange, and once every "
                    "launch screen exists: ten of \u00a723.2's 28 do today, and "
                    "stage SD builds the rest.",
             gate="+8.80 frontend points after the native read"),
        dict(id="TC.6", owner="claude", status="done",
             title="Screens on the backend that exists: shop and track, Workshop, social",
             detail="The data side of each screen \u2014 repositories, "
                    "presenters, flows, error states, offline behaviour \u2014 "
                    "built and tested against the real server, drawn with the "
                    "placeholder components until the design lands. The shop "
                    "prices every item in money with gifts and refunds (F41, "
                    "G32); the Workshop browses, plays, rates, remixes and "
                    "reports; the social screens show the league, constellations, "
                    "crews, friends and the feed.",
             gate="+4.37 (shop, track, wallet), +8.50 (Workshop), +4.86 (social) "
                  "frontend points; only their look changes when the design lands",
             evidence="client/tests/shop_tests.gd, social_tests.gd, workshop_tests.gd, "
                      "through python3 client/status.py"),
        dict(id="TC.10", owner="claude", status="done",
             title="The age check on first launch (\u00a720.1)",
             detail="\u00a720.1's age check comes first on the device; until it "
                    "answered, the server held every new account to the most "
                    "protective band (\u00a720.2): the Workshop's featured list "
                    "only, off the feeds, a minor's spending cap. At first "
                    "launch the platform is asked, and when it cannot say the "
                    "player is asked, neutrally, once; the answer reaches the "
                    "server with the first sign-in (PUT /v1/age). Under 13 no "
                    "account is ever made and the question is not asked again.",
             gate="no frontend figure moves; without it the Workshop, feeds and "
                  "shop treat every player as 13 to 15",
             evidence="client/tests/age_tests.gd, through python3 client/status.py"),
        dict(id="TC.11", owner="claude", status="done",
             title="Keeper levels on the server, and the Keeper bar",
             detail="Nothing raised a Keeper level: the server settled heists "
                    "and every account stayed Keeper 1, so every Keeper gate "
                    "\u2014 the Beacon at Keeper 6, matchmaking's window \u2014 "
                    "read 1 (G42). A raid now earns its raider \u00a714.2's "
                    "experience in the transaction that settles its haul, levels "
                    "climb \u00a714.2's table (one home, "
                    "<code>design_facts.KEEPER_XP_TO_NEXT</code>, which the "
                    "economy model reads too), <code>GET /v1/keeper</code> gives "
                    "the bar, and the client shows it on Home with ten pips and "
                    "the numbers, and each raid's result says what it earned. "
                    "In Portuguese the Warden becomes Sentinela, since Keeper and "
                    "Warden had both been Guardi\u00e3o.",
             gate="no figure moves: \u00a726.8's plan has no row for it (G42)",
             evidence="server/test/keeper.test.mjs; client/tests/keeper_tests.gd",
             register=["G42", "F54"]),
        dict(id="TC.12", owner="claude", status="doing",
             title="The home economy on the server (G42)",
             detail="\u00a724 makes the server authoritative for every resource "
                    "change, and \u00a726.8 has no phase that builds the home "
                    "economy: buildings, workers and production (\u00a79.3, "
                    "\u00a75.8), spending, the Spire, the Codex's restorations, "
                    "and \u00a714.2's experience from spending and from restoring "
                    "laws. The economy model already runs all of it; the server "
                    "side is the work, slice by slice, with F54's gate on the "
                    "Keeper bar once spending is the only experience left. "
                    "Built: realms and buildings (server/src/universe.mjs) "
                    "\u2014 outer realms opened and raised, buildings built and "
                    "raised at \u00a710.2's costs and needs, paid from the "
                    "ledger with \u00a714.2's experience for spending, islands "
                    "held to what is built \u2014 and the client's universe "
                    "screen. Next: the builder publishing to the player's own "
                    "realms, with the wards, posts and pylons an island places "
                    "held to those built (today only its realm, realm level "
                    "and Vault are), then workers and production (\u00a79.3, \u00a75.8), "
                    "the roster (\u00a711.5), and the Codex's restorations."
                    "<br><br><strong>Screens v3 makes this the critical path</strong> "
                    "for six of stage SD's screen groups, in this order: the "
                    "builder publishing to the player's own realms (closes D60); "
                    "workers and production with an Aether ledger and storage caps; "
                    "the roster (characters, homes, rest, assign and recall, levels, "
                    "the starting five); pages and the Codex with restoration and "
                    "study; weaving state per slot; and Insight. The screens need "
                    "these slices as well: links at \u00a75.3's prices and limits; "
                    "births at a Nursery, paid in Essence (\u00a711.5), which the "
                    "Forms album reads; the Sage routes (the Sages, their roles, "
                    "levels paid in Insight); the Lab's service (start, collect, "
                    "an outcome drawn from a stored seed, a <code>lab</code> "
                    "notification); and the defence log's routes (raids on the "
                    "player since a time, one raid, marking them seen), which the "
                    "shell's raid badge reads. Faults come with TD.37 and each "
                    "building's tile with TD.36.",
             gate="each slice named above on the server with its server tests: "
                  "the builder publishing to the player's realms, workers and "
                  "production with the Aether ledger and caps, the roster, pages "
                  "and the Codex, weaving state, Insight, links, births, the Sage "
                  "routes, the Lab's service and the defence log's routes; no "
                  "figure moves until \u00a726.8's plan carries it",
             evidence="server/test/universe.test.mjs; client/tests/universe_tests.gd, "
                      "through python3 client/status.py",
             register=["G42", "F56", "G43", "D60", "G45"]),
        dict(id="TC.13", owner="claude", status="done",
             title="What the stores require of player-made content, and the declarations ready to file",
             detail="\u00a720.11 lists what the stores ask of a game where players "
                    "see each other's work; none of it was built. Now: blocking as "
                    "\u00a717.8 says it works (each hidden from the other, targets "
                    "untouched, and a crew or constellation with a member across "
                    "a block answering an outsider as one that does not exist), a terms-of-use gate before publishing, playing, "
                    "rating or remixing Workshop islands (never before a report), "
                    "and /terms, /privacy and /support served by the game's own "
                    "server, the policy written from server/privacy.json. The age "
                    "ratings are answered in server/ratings.json, each answer "
                    "quoting the sentence it rests on, and the iPhone build's "
                    "privacy manifest and export-compliance key are written from "
                    "the same files (tools/privacy_manifest.py). "
                    "server/declarations.md is the whole packet.",
             gate="the compliance row moves only when TC.14 is done",
             evidence="server/test/safety.test.mjs; client/tests/workshop_tests.gd; "
                      "node server/src/privacy.mjs --check; python3 tools/privacy_manifest.py --check"),
        dict(id="TC.14", owner="you", status="ready",
             title="File the store declarations and the age ratings",
             detail="Set RULEBORN_CONTACT=\"Name &lt;address&gt;\" on the server so "
                    "/support is served; read server/web/terms.md and give it a "
                    "final version on its Version line; then fill App Store "
                    "Connect's App Privacy and age rating, and Play's Data safety "
                    "and IARC questionnaire, from server/declarations.md, linking "
                    "/privacy and /support. Check each question's name against the "
                    "live form. On the first Mac build, read Xcode's privacy report "
                    "for the engine's required-reason APIs, which the manifest does "
                    "not yet declare. If it is filed before Profile, Settings and "
                    "first launch add stored data (TD.24 to TD.26), TD.49 "
                    "re-checks it.",
             blocked_by=["TC.13"]),
        dict(id="TC.9", owner="claude", status="done",
             title="Offline as the exception, as the owner answered G41",
             detail="Online is the rule and is recommended heavily; offline is "
                    "the exception (G41, level C). While online the heist "
                    "repository keeps a stock of three leases; starting a heist "
                    "offline shows a prompt that recommends going online first, "
                    "and lets the player carry on; every haul played offline "
                    "stays confirming until the server confirms it; and the "
                    "outbox sends by itself on reconnecting, with a banner that "
                    "says so. The §24.12 edit is drafted under G41.",
             gate="no frontend figure moves; it is §24.12 as the owner answered",
             evidence="client/tests/offline_tests.gd, through python3 client/status.py",
             register=["G41"]),
        dict(id="TC.7", owner="you", status="done",
             title="The design from Claude Design",
             detail="<strong>Delivered:</strong> Screens v3, 28 designed screens, "
                    "43 character and creature sheets with 3D models and 393 "
                    "icons, recorded in v3.6 \u00a723.5 as the visual reference, "
                    "with the document winning on every rule, number and piece of "
                    "text. It lands through stage SD, first in TC.1's token file "
                    "and component library (TD.2, TD.3), so screens change in one "
                    "place.",
             evidence="v3.6 \u00a723.5; docs/analysis/screens-v3/"),
        dict(id="TC.8", owner="you", status="blocked",
             title="Real devices, and the fix buffer",
             detail="\u00a726.8: anything needing a real device is not safe to "
                    "hand over. The phones themselves arrive in TD.48, early, "
                    "because \u00a726.2's art-style test (TD.30) reads on them; "
                    "this task is what is measured on them once the screens "
                    "exist; the iPhone and Android checksums are T3.1's, on "
                    "TD.48's phones, and wait for no screen. The device matrix "
                    "(+5.46) needs phones; the fix buffer (+5.46) is closed "
                    "after it. Screens v3 adds what only a "
                    "phone can measure: \u00a721.3's frame budgets and \u00a724's 60 "
                    "frames a second and 25 ms drag on the reference device, "
                    "measured as the owner's answer to C52 says, VoiceOver and "
                    "TalkBack over the new screens, local "
                    "notifications and asking permission after the third session "
                    "(D68), the share clip's video encoder (TD.46), and the "
                    "platforms' age signals.",
             blocked_by=["TC.3", "TD.48", "TD.28"],
             register=["C52"]),
    ],
),

# ===========================================================================
dict(
    id="SD",
    title="Screens v3, built on the document's rules",
    subtitle="The owner's designs (§23.5) as the base: four tracks, one order",
    blurb="Screens v3, made in Claude Design, holds 28 designed screens, 43 "
          "character and creature sheets with 3D models, and 393 icons, and v3.6 "
          "§23.5 records it: the designs carry the look, and the document wins "
          "wherever it states a rule, a number or a piece of text. Read screen by "
          "screen against v3.6 and the build (docs/analysis/screens-v3/), it is a "
          "very good base and a long way from a build: 18 of its 28 screens have "
          "no screen in the client yet, its 3D is three.js code rather than "
          "models, and in about 190 places it departs from a rule or the build "
          "(each checked by an adversarial reader, in the register as the v3.6 "
          "layer). The plan takes the look and refuses the mechanics: the engine "
          "first, then the design system so every screen lands once, the 3D "
          "world as its own track because it is the largest risk, the simulation "
          "and server pieces the screens stand on, and the screens in the order "
          "§26.2's vertical slice needs them (T6.1 waits on each of them), then "
          "the rest. A part that waits on an owner's answer waits on that "
          "decision's own task (TD.50 to TD.61), in a task of its own when the "
          "rest need not wait, or is built with the document's value and the "
          "other one token away.<br><br>"
          "<strong>The screen gate</strong>, which every screen task below names: "
          "each §23.2 must-show for its rows present in every variant, with a test "
          "by name in <code>python3 client/status.py</code>; §21.1's sizes, "
          "§21.8's contrast and the layout check at 100%, 150% and 200% text, in "
          "both languages (<code>a11y_tests.gd</code>); every control named for a "
          "screen reader; and <code>tools/client_contract.py</code> clean.<br><br>"
          "<strong>None of it moves the "
          "frontend figure</strong>: completion counts §26.8's list, which "
          "costs none of the twenty screens outside the heist, builder, Workshop, "
          "shop, social and settings, no design port and no 3D world (G66, TD.47). "
          "Every task below keeps the client's tests passing, so the figure cannot "
          "fall either.",
    tasks=[
        # -- Track A: the foundation ------------------------------------------
        dict(id="TD.1", owner="claude", status="ready",
             title="Move the client to Godot 4.7.2 and godot-rust's 4.7 API",
             detail="v3.5 pinned Godot 4.7.2-stable with godot-rust v0.5.5 built "
                    "for the 4.7 API (§24, brief 39). <strong>Measured in a "
                    "copy:</strong> the extension builds offline with "
                    "<code>api-4-7</code> (the crate is already 0.5.5), and on "
                    "4.7.2 the client passes 100 of 100 tests after one change: 4.7 "
                    "moved the screen-reader live-region constants to a new "
                    "<code>AccessibilityServer</code>, so <code>ui.gd:138</code> and "
                    "<code>:321</code> name it instead of <code>DisplayServer</code>. "
                    "The rest is pins: <code>project.godot</code>'s feature, "
                    "<code>build.sh</code>, <code>compatibility_minimum</code>, the "
                    "export templates (1.28 GB) and Android's "
                    "<code>target_sdk=36</code> set in the preset rather than left "
                    "to the engine's default. Two more steps: "
                    "<code>settings.gd:40</code> and <code>:42</code> still ask "
                    "<code>DisplayServer</code> for contrast and reduced animation, "
                    "and are checked against 4.7's class reference and moved with "
                    "the constants if 4.7 deprecates them; and the documentation "
                    "that names 4.5 as the engine (<code>README.md</code>, "
                    "<code>client/README.md</code>, T3.4 and stage SC here, "
                    "<code>tools/privacy_manifest.py</code>'s docstring) says 4.7.2. "
                    "v3.6's opening says no client code existed; it did, and the "
                    "move cost one change.",
             gate="100 of 100 client tests on 4.7.2, the five goldens agreeing at "
                  "every second, <code>export.sh check</code> on the 4.7.2 templates, "
                  "gdlint clean, and none of the files above still naming 4.5 as "
                  "the engine",
             evidence="python3 client/status.py; bash client/export.sh check",
             register=["D76"]),
        dict(id="TD.2", owner="claude", status="blocked",
             title="The tokens, §21.8's typefaces with the design's beside them, "
                   "and the licence ledger",
             detail="Screens v3 keeps its look in inline styles (852 colours, 402 "
                    "shadows), but underneath it is ten materials, one outline, "
                    "one hard drop shadow and a press that sinks 2 to 3 points. "
                    "<code>client/ui/tokens.json</code> takes them, each with its "
                    "source. Where the document states a value, the document's is "
                    "the token's value and the design's sits beside it, so an "
                    "owner's answer flips one token without blocking anything: "
                    "§21.2's colours (which the design matches exactly), §21.8's "
                    "13 pt floor, contrast and motion, and §21.8's typefaces, "
                    "Baloo 2 and Marcellus, with the design's Manrope and Lilita "
                    "One beside them until the owner answers D90. All four are SIL "
                    "OFL; §21.11's licence ledger does not exist yet and is "
                    "written here. The frame stays at 360 points: a 390-point base "
                    "would draw 13-pt text at 12 real points on 360-dp phones.",
             gate="every client test passes unchanged; the tokens validator "
                  "refuses a value with no source; with the typeface token set "
                  "to the design's faces the layout checks still pass",
             blocked_by=["TD.1"],
             register=["D90", "D91"]),
        dict(id="TD.3", owner="claude", status="blocked",
             title="Materials and components, and checks that read what words sit on",
             detail="Gold, leather, red, green and round buttons, sheets, chips, "
                    "portrait tiles, banners and cards, drawn by one rounded-box "
                    "shader (gradients, rims and hard drops are beyond "
                    "StyleBoxFlat) under the names <code>scripts/ui.gd</code> "
                    "already gives, so screens change in one place. They move "
                    "with TD.4's helper and draw TD.5's icons, so both come first "
                    "and every screen inherits them. The surface is §21.8's until "
                    "the owner answers D89: ink #221C3A on paper panels at 85% "
                    "opacity, with the design's dark cards, glass, leather and "
                    "parchment one token away. 28% of the design's 1,049 text runs "
                    "fail §21.8's 4.5:1 or the perceptual check, mostly white "
                    "numbers on light badges and violet secondary text; the "
                    "components keep the look and fix the words. The accessibility "
                    "checks learn the colour each word actually sits on; until the "
                    "owner answers G59 an outline does not count as a word's "
                    "background, the strictest reading, and the rule is one switch.",
             gate="§21.1's sizes and §21.8's 4.5:1 and perceptual checks at 100%, "
                  "150% and 200% text, in both languages, on the document's "
                  "surface and on the design's (<code>a11y_tests.gd</code>)",
             blocked_by=["TD.2", "TD.4", "TD.5"],
             register=["D72", "G59", "F58", "D89", "D91"]),
        dict(id="TD.4", owner="claude", status="blocked",
             title="Motion, with reduced motion that reaches everything",
             detail="The design has 86 keyframe animations, eight of them named "
                    "twice, running 300 to 550 ms with overshoot against "
                    "§21.8's 150 to 250 ms, easing out; its reduced-motion switch "
                    "is read by nothing. One helper plays every movement at the "
                    "document's timings, with the design's kept beside them as "
                    "one token until the owner answers D91; "
                    "<code>UI.motion_ms</code>'s rule applies to all of it, toasts "
                    "become banners that stay when the player asks (§20.8), "
                    "and a lint rule refuses a tween made anywhere else.",
             gate="the lint rule finds no tween outside the helper; with reduced "
                  "motion on, nothing moves that §20.8 does not keep (a test); "
                  "every interface movement inside §21.8's 150 to 250 ms while "
                  "the document's token holds",
             blocked_by=["TD.2"],
             register=["D91"]),
        dict(id="TD.5", owner="claude", status="blocked",
             title="The icons: 393 designed, exported once, imported on 4.7.2",
             detail="Four sources: <code>icons_rbi.js</code> (360 in 31 groups), "
                    "the school and law icons, the diorama's marks, and inline "
                    "ones, exported as 444 SVGs (done once already, in the "
                    "analysis). §21.8 asks for rounded shapes with a 2-point "
                    "outline and flat colour; the design glosses every fill with a "
                    "gradient, a mask and a specular spot, and skipping the gloss "
                    "exports them flat (DS-3). The flat set is the value and the "
                    "glossed set is kept beside it, one token apart, until the "
                    "owner answers D91. Both use masks, filters and system-font "
                    "text Godot's importer may not handle, so they are rasterised "
                    "in Chromium at the sizes used, with a manifest, "
                    "<code>UI.icon()</code> and a test that every name a screen "
                    "uses exists. The school marks keep Matter's cube edges.",
             gate="every icon name a screen uses exists in both sets (the test); "
                  "every flat icon is single colours with the 2-point outline, "
                  "read from the exported SVGs",
             blocked_by=["TD.1"],
             register=["D91"]),
        dict(id="TD.6", owner="claude", status="blocked",
             title="The shell: one persistent scene, its chrome, the HUD and the world",
             detail="Today the router swaps whole scenes, so no chrome and no 3D "
                    "world can persist between screens. The shell keeps the World, "
                    "the content, the chrome (top HUD, side alerts, tab bar, back "
                    "header) and the overlay, configured per route; headless "
                    "presenters give the HUD's bars from the server's caps "
                    "(TC.12), the badges from real state (the raid badge from "
                    "TC.12's defence-log route) and the nearest goal (§14.8). The "
                    "chrome is switchable until the owner answers C44: §21.8's "
                    "home arrangement, with no tab bar, is the value, and the "
                    "design's tab bar is one token away. The design's chrome sits "
                    "in the top band and the corners, where §21.1's reach rule and "
                    "the layout check fail it; the check splits frequent controls "
                    "from rare ones, as §21.1 does, and holds under both "
                    "arrangements. Portrait only: landscape is TD.28's.",
             gate="a flow test per route under each arrangement; the layout check "
                  "in portrait under each, in both languages, at 100%, 150% and "
                  "200% text; each badge read from a store slice, with a "
                  "presenter test",
             blocked_by=["TD.3", "TC.12"],
             register=["C44"]),
        # -- Track B: the 3D world ---------------------------------------------
        dict(id="TD.7", owner="claude", status="blocked",
             title="An export harness for the designs' 3D, held to the budgets",
             detail="The 43 creatures are signed-distance sculpts meshed in "
                    "three.js, auto-skinned, with 15 procedural animations each; "
                    "no .glb exists. <strong>Proved in the analysis:</strong> "
                    "Featherkin exported with its 15 clips baked (1.73 MB) and "
                    "imported into Godot with 24 bones and all 435 tracks "
                    "resolving. The harness runs the prototype's own modules, "
                    "unedited, in headless Chromium with three r184 from npm, "
                    "seeds their randomness, caps segments and picks each kind's "
                    "sculpt step to its budget (Featherkin 47,600 to 12,600 "
                    "triangles with no edit), bakes the clips with springs off, "
                    "and writes a manifest that lists §21.9 row by row with each "
                    "row's source (exported, to make, contractor), so what TD.31 "
                    "and TD.32 make is a counted gap. Today "
                    "every model is several times over §21.3's budgets (realm "
                    "views 163,000 to 219,000 triangles in over 1,100 draw calls; "
                    "characters 10,000 to 182,000), and a whole island needs "
                    "<code>EXT_mesh_gpu_instancing</code>, which 4.5 refused.",
             gate="every asset inside §21.3's budget (as written, until the owner "
                  "answers D93), and every asset with a stated height (§21.6's "
                  "eighteen kinds from TD.33's tables, §21.1's Sages at about "
                  "1.5) within 5% of it, the rest listed in the manifest as "
                  "unbudgeted; re-exported byte for byte",
             blocked_by=["TD.1", "TD.33"],
             register=["G61", "D93"]),
        dict(id="TD.8", owner="claude", status="blocked",
             title="One toon look for everything",
             detail="The diorama is a four-step toon with world-space hulls; the "
                    "characters are physically based with clearcoat, sheen and "
                    "transmission under ACES, and the portraits are renders of "
                    "that. §21.3 asks for one toon look: three steps, shadows "
                    "tinted toward violet, a rim and 1.5-pixel ink lines. One "
                    "shader kit on that rule, with the design's four-step ramp and "
                    "world-space shells kept as a variant one token away until the "
                    "owner answers D92: a clip-space outline, water and lava, sky "
                    "by local time (§21.2), glows, the ghost, and the Hush, Spark "
                    "and Echo variants, assigned to every imported model on import.",
             gate="every imported model carries the kit's material, checked on "
                  "import; a still of each variant in both looks against a golden "
                  "on a GPU runner",
             blocked_by=["TD.7"],
             register=["D92", "D91"]),
        dict(id="TD.9", owner="claude", status="blocked",
             title="Who the actors are: guards in the bundle, outfits beside the replay",
             detail="The 3D draws a kind, a form and an outfit; the replay gives "
                    "a role. Neither the simulation's crew and guards nor the "
                    "bundle's posts name a kind, so a replay cannot be drawn with "
                    "the right creatures, on the phone or in §24's clips. Kind and "
                    "form change what happens (§11.2's abilities and resistances, "
                    "§11.10's quirks), so they go inside §24.11's four inputs: the "
                    "crew's in TD.12's manifest, and each posted guard's kind and "
                    "form in the island bundle, here. Only the outfit is a look: "
                    "it is stored with the heist and the island beside the four "
                    "inputs and never inside them. The replay is returned with all "
                    "three for every actor; the server checks the guards against "
                    "the roster with the crew (TD.34).",
             gate="the five goldens re-recorded and agreeing; a replay the server "
                  "returns names each actor's kind, form and outfit (a server test "
                  "and a client test); changing an outfit changes no checksum",
             blocked_by=["TD.12"],
             register=["G60"]),
        dict(id="TD.10", owner="claude", status="blocked",
             title="The world drawn from the simulation",
             detail="The island base built around the simulation's square grid "
                    "(§5.2's 10 to 14 tiles, 1 tile = 1 m; the design's realm "
                    "is a 42-tile disc), its features and heights (a level is half "
                    "a tile, the design's ratio, which §23.5's rule adopts: G65), "
                    "the buildings on the footprints the island gives them (TD.36), "
                    "a pylon in every woven slot (§21.5, TD.31's design), actors interpolated "
                    "between ticks with deterministic animation choice, §21.12's "
                    "overlays, the orthographic camera in 90-degree steps, tile "
                    "picking. The flat <code>RealmView</code> stays for screen "
                    "readers and as the fallback.",
             gate="every actor's world position equals its tile; a still of each "
                  "mode against a golden on a GPU runner",
             blocked_by=["TD.8", "TD.9", "TD.31", "TD.36"],
             register=["G45", "D74"]),
        dict(id="TD.11", owner="claude", status="blocked",
             title="Characters in full: forms, guards, role accessories",
             detail="No model has the guard form the sheets label (its sash and "
                    "lantern are a caption), and a form changes colour and glow "
                    "only, which §21.6 calls a failed form. Each note gets an "
                    "accessory and a pattern per size band; guards get the sash "
                    "and lantern and §21.6's role accessories so a guard's role "
                    "reads at a glance (§12.8); springs; portraits re-rendered "
                    "in the toon look. The sheets' variants for visitors, "
                    "anomalies and law creatures change what a player earns or a "
                    "crew faces, so they carry no effect until the document gives "
                    "one (D95). The Sparkwright's goggles and the count of "
                    "animations wait on the owner's answer to C54, and are "
                    "TD.62's. With the character artist (§26.3).",
             gate="every form and guard in TD.7's manifest carries its accessory "
                  "and pattern, read by a test; each guard role tells apart under "
                  "§21.10's grayscale test; every portrait rendered from an "
                  "imported model",
             blocked_by=["TD.7", "TD.8"],
             register=["D94", "D95"]),
        dict(id="TD.31", owner="you", status="yours",
             title="Design a pylon per school, and any defensive marker the "
                   "art-style test needs",
             detail="Screens v3 draws no law pylon, in the realm view or the "
                    "heist (D74), though §10.2 puts one in every law slot, §21.5 "
                    "draws it as an obelisk topped with the school's shape, and "
                    "§12.6 makes breaking one a decision. TD.30's art-style test "
                    "reads six or seven kinds of defensive marker on target "
                    "devices, so the pylons, and any other marker the designs "
                    "lack, are made before it: in Claude Design, with the "
                    "character artist (§26.3), and brought in through TD.7.",
             gate="a pylon for each of the six schools, §21.5's obelisk with the "
                  "school's shape and colour and room for the law's glyph, "
                  "exported by TD.7 inside §21.3's budget",
             register=["D74"]),
        dict(id="TD.32", owner="you", status="blocked",
             title="Make the rest of the art Screens v3 lacks",
             detail="§21.9 lists 68 building looks, 24 law signatures and §8's "
                    "24 harmony, dissonance and chord effects. The design models 8 "
                    "building types at one look each: no Anchor Stone, "
                    "Storehouse, Nursery, Library (C24), Resonance Lab, "
                    "Observatory, Beacon or Visitor's Dock, no level 7 to 9 "
                    "crystal-and-gold or level-10 crown looks (§21.5), and 3D "
                    "effects for 9 of the 24 laws. Its characters have one work "
                    "loop where §21.6 asks for one per building, and no knock-out "
                    "petals; Verdant has no bees or butterflies (§5.7). The "
                    "Chronicler's and the Lamplighter's looks and the wildlife's "
                    "counts and ranges are the sheets', adopted under §23.5's "
                    "rule (G65). With the character artist (§26.3), once TD.30 "
                    "has settled the style, as §26.2 orders it.",
             gate="TD.7's manifest lists no §21.9 row as still to make",
             blocked_by=["TD.30"],
             register=["C24", "G65"]),
        dict(id="TD.62", owner="claude", status="blocked",
             title="The Sparkwright's goggles and the work loops, as C54 is answered",
             detail="§11.11, §21.6 and §23.5 disagree on the Sparkwright's "
                    "goggles and on how many animations each kind has (C54). Once "
                    "the owner answers, TD.7's export and TD.11's characters take "
                    "the answer: the Sparkwright's accessory node and the shared "
                    "clip set, with the clip check counting what the answer sets.",
             gate="the clip check counts the clips C54's answer sets for every "
                  "kind; the Sparkwright exported as the answer draws it, inside "
                  "§21.3's budget",
             blocked_by=["TD.11", "TD.58"],
             register=["C54"]),
        # -- Track C: what the screens stand on ----------------------------
        dict(id="TD.33", owner="claude", status="ready",
             title="Content the screens and the 3D read: paradox-born, visitors, "
                   "§11.11's rule sheet and §21.6's heights",
             detail="content/ has no paradox-born, no visitors and no §11.11 "
                    "rule-sheet line, and §21.6's heights, colours and signatures "
                    "are not extracted (G63). New "
                    "<code>content/paradox_born.json</code> from §11.8's two "
                    "tables, the Twinned's 120 health and 80 carry shared by its "
                    "two bodies; <code>content/visitors.json</code>, the Stray one "
                    "of the eighteen kinds and never a nineteenth; and "
                    "<code>ruleborn.json</code> gains the rule sheet and §21.6's "
                    "height, colours and signature, so §23.5's “every card "
                    "carries all of 11.11, word for word” is generated. The rows "
                    "§23.5's rule adopts from the sheets (the paradox-born's "
                    "personality, home habit, best at and signature, and the "
                    "visitors' and anomalies' sizes) are carried with their "
                    "source (G65). <code>content/README.md</code>'s stale "
                    "<code>conflict_severity</code> line goes.",
             gate="<code>python3 tools/validate_content.py</code> passes with the "
                  "new tables (no nineteenth kind, forms still 54); re-extraction "
                  "reproduces them byte for byte; "
                  "<code>tools/check_document.py</code> no longer reports "
                  "paradox-born and visitors as unenumerated",
             register=["G63", "G65"]),
        dict(id="TD.12", owner="claude", status="ready",
             title="Abilities, Sage powers and casts in the simulation",
             detail="The simulation has twelve command kinds and none is an "
                    "ability, a Sage power or a cast, and its crew are five roles "
                    "with no characters; completion's Crews row reads done all the "
                    "same (G67). Every answer the owner can give G47 adds these "
                    "commands, so they start now; one open answer would hold the "
                    "manifest back, G51's B, which keeps validated heists to the "
                    "five fixed roles for a stage. The work: Ability, Sage and Cast commands "
                    "in the free values; a crew stat not keyed by role (G63); a "
                    "crew manifest in the replay (each member's character, kind "
                    "and form; the Sage and its uses; the casts); the eighteen "
                    "abilities as named-parameter changes with two uses and the "
                    "ten-second lockout; the four Sages' powers; casts as "
                    "four-tile circles; and §12.6's four-ready rule. Levels, "
                    "traits and the server's roster check are TD.34's, and the "
                    "paradox-born TD.35's, because both wait on owners' answers. "
                    "The goldens are regenerated and the harness's decision count "
                    "re-measured.",
             gate="the harness's median run at the matched depth carries 15 to 25 "
                  "decisions, abilities, Sage powers and casts counted (§12.6, "
                  "§19.27); if it does not, §12.6's fallback is applied and "
                  "recorded (each ability to one use, then the matchmaker's depth "
                  "centre down one realm at a time); the goldens regenerated and "
                  "agreeing",
             register=["G47", "G63", "G67"]),
        dict(id="TD.34", owner="claude", status="blocked",
             title="The crew's levels, traits and rest, checked against the roster",
             detail="The manifest's levels and traits, each member's rest after a "
                    "heist (§12.9), and the server checking the manifest and the "
                    "posted guards (TD.9) against the roster it holds, each "
                    "posted guard's level carried in the island bundle beside "
                    "its kind and form. It needs "
                    "TC.12's roster, and it waits on the owner's answer to G51: "
                    "whether a server-checked heist models levels and traits at "
                    "all, and §11.4 to §11.6's rules for growth, a home and rest. "
                    "The Roster's and Character's numbers are shown as the "
                    "heist's only once this lands.",
             gate="a lease refused for a crew member the roster does not hold or "
                  "one still resting (server tests); one simulation test per rule "
                  "the answer writes; the goldens agreeing",
             blocked_by=["TD.12", "TC.12", "TD.50"],
             register=["G51"]),
        dict(id="TD.35", owner="claude", status="blocked",
             title="Paradox-born in the simulation",
             detail="A paradox-born has no role (§11.8), and the simulation keys "
                    "every crew stat to one. On TD.12's stat type and TD.33's "
                    "table, the Reverser's and the Unmade's gifts join a crew and "
                    "the Twinned is one body with its pools shared. It waits on "
                    "the owner's answers to C53 (what the Twinned's gift doubles, "
                    "or whether it ships at launch) and G62 (whether paradox-born "
                    "guard, and whether they take forms).",
             gate="a simulation test for each paradox-born gift as the answers "
                  "write it; the goldens agreeing",
             blocked_by=["TD.12", "TD.33", "TD.51"],
             register=["C53", "G62"]),
        dict(id="TD.13", owner="claude", status="ready",
             title="The simulation's event log",
             detail="Outside the checksum: guard state changes with their cause, "
                    "knockouts and revivals, captures and boarding, alarm levels "
                    "and their cause, wards, pylons, the Vault opening, law blinks. "
                    "The result's decisive moment and its one thing to try "
                    "(§12.13), the heist's haptics and words, the defence report's "
                    "facts, Profile's facts, the share clip and D65's heatmaps all "
                    "read it.",
             gate="a named simulation test for each event kind; the five goldens' "
                  "checksums unchanged with the log on",
             register=["D65", "G48"]),
        dict(id="TD.36", owner="claude", status="ready",
             title="Buildings on the grid, in the simulation, the island and the server",
             detail="§10.1: buildings sit on the realm grid and block movement and "
                    "sight, most 2 by 2 and the Spire and Vault 3 by 3. The "
                    "simulation's island has a one-tile Vault and no other "
                    "building, so a crew walks through every Star Well, Hearth and "
                    "Spire, and the server keeps no position (G45). The island "
                    "format and the simulation gain §10.1's buildings on their "
                    "footprints, blocking movement and sight; the extension reads "
                    "them; the server stores each building's tile, moves it free "
                    "and at once (§10.1), and refuses a published island whose "
                    "buildings disagree with those built. A rules-version change "
                    "(§24.11).",
             gate="a simulation test that no crew walks or sees through a "
                  "footprint; server tests for the stored tile, the move and the "
                  "refused island; the goldens regenerated and agreeing",
             register=["G45"]),
        dict(id="TD.14", owner="claude", status="ready",
             title="Stability and weaving prices, priced once for client and server",
             detail="Weaving and the Harmony view show strain, harmonies and "
                    "clashes as the player decides; the server must charge the "
                    "same. One function in the simulation (§5.5, §8), exported to "
                    "the client and the server's WebAssembly, with crown laws "
                    "carried in the bundle (D61): each law's cost, the universe's "
                    "capacity and strain, and harmonies and clashes within a realm. "
                    "Whether a harmony counts once a pair or once a note is open "
                    "(C48), so both readings are built and one switch picks. "
                    "Upkeep and the other rules C48 leaves open are TD.37's.",
             gate="the client's and the server's prices equal the simulation's for "
                  "every launch law alone and in every pair in one realm, under "
                  "both readings (a test on each side)",
             register=["D61", "C48"]),
        dict(id="TD.37", owner="claude", status="blocked",
             title="Stability's open rules: upkeep, crown laws, Breaking and faults",
             detail="§5.6 prices weaving's upkeep against a realm's stability "
                    "budget that §5.5 never gives, and C48 leaves more open: how a "
                    "crown law's harmonies and clashes count across realms, "
                    "whether a weave may take strain into Breaking, what a tier "
                    "rise does to a woven law, and how the recommended laws are "
                    "ranked. §5.5's faults have no pair and no count at Cracking, "
                    "and nothing says whether a raider sees them (G46). Each is "
                    "built in TD.14's function and on the server once the owner "
                    "answers C48 and G46, and home's fault marker is drawn on "
                    "TD.19's view.",
             gate="a test for each rule as the answers state it, the same on the "
                  "client and the server; the faults a universe opens worked out "
                  "from the universe alone",
             blocked_by=["TD.14", "TD.52"],
             register=["C48", "G46"]),
        dict(id="TD.15", owner="claude", status="ready",
             title="Terrain in the simulation: the missing features, moss, heights",
             detail="The simulation has 5 of §6.2's 39 features (rock pillar, "
                    "ruin wall, fence, fog bank, tall grass); the terrain editor, "
                    "the realm view and the curation screens need the rest. "
                    "Completion's Terrain editing row reads done on one test (G67). "
                    "Ready now, because every answer to G56 builds them: each "
                    "feature with no direction, moss as the default ground and "
                    "clearing it at a terrain point a tile, heights 0 to 3 with a "
                    "level at half a tile (the design's ratio, adopted under "
                    "§23.5's rule: G65), and §6.1's terrain points counted in the "
                    "simulation, the extension and the server. The six that need "
                    "a direction or two ends are TD.38's. Each is a rules-version "
                    "change (§24.11).",
             gate="a named simulation test for each feature built; a realm over "
                  "§6.1's terrain points refused alike by the simulation, the "
                  "extension and the server",
             register=["G56", "G67", "G65"]),
        dict(id="TD.38", owner="claude", status="blocked",
             title="Directional features and tunnels",
             detail="Ramps, stairs and vines need an up side, a waterfall a ledge "
                    "side, rapids a downstream and a tunnel two ends, and §6.2 "
                    "says who sets none of them; a held guard's facing is the "
                    "same question (G56). They wait on the owner's answer to G56: "
                    "who sets each, and what the generator picks. The bundle then "
                    "carries them, a rules-version change (§24.11), and the "
                    "terrain editor (TD.22) places them.",
             gate="a named simulation test for each of the six; all 39 of §6.2's "
                  "features in the simulation",
             blocked_by=["TD.15", "TD.53"],
             register=["G56"]),
        dict(id="TD.16", owner="claude", status="ready",
             title="The generator: ruins, reference crews, fallbacks",
             detail="D66: drifting ruins at three labelled difficulties "
                    "(§12.12), the reference crews the measurements use, "
                    "generated fallback targets (§12.22), and a server queue that "
                    "measures an island before it is offered, which also gives "
                    "D62's hold-band check. The Observatory's ruins, Slower ruins, "
                    "curation's hold figure and the first session's tutorial ruin "
                    "wait for it. The rehearsal crews and the defence report's "
                    "recorder wait on an owner's answer, and are TD.39's.",
             gate="ruins at the three labelled difficulties ordered by the "
                  "reference crew's success over the harness's runs; a fallback "
                  "target offered when the list is thin (a server test); the "
                  "queue's hold for an island equal to the harness's",
             register=["D66", "D62", "G55"]),
        dict(id="TD.39", owner="claude", status="blocked",
             title="Rehearsal crews and the defence report's facts",
             detail="§13's three rehearsal crews (cautious, greedy, fast) have "
                    "names and no rule, and §13.2's report (the haul denied, how "
                    "long the defence held, where the crew was seen, what fired) "
                    "has no measure for one raid; the simulation records none of "
                    "it (G57). It waits on the owner's answer to G57; then each "
                    "crew's rule joins the generator's crews, the facts are "
                    "recorded from TD.13's event log, and the server writes them "
                    "when it settles a raid, so the defence log (TD.66) and "
                    "Profile's records (TD.24) read one record.",
             gate="a test for each crew's rule and each fact as the answer defines "
                  "it; a settled raid's facts, re-simulated from its replay, equal "
                  "what was written",
             blocked_by=["TD.13", "TD.16", "TD.54"],
             register=["G57"]),
        dict(id="TD.40", owner="claude", status="blocked",
             title="Daily goals and the weekly streak (§14.6)",
             detail="§14.6: the player picks 3 of 6 offered goals with one free "
                    "swap, and playing on 4 days out of 7 keeps a weekly streak, "
                    "with one automatic saver a week, repair by playing two days "
                    "in a row, and cosmetic rewards. The streak is a Season "
                    "must-show (§23.2), and three goals appear at 10:00 in §16. "
                    "Nothing in the client or the server has either. Server: goals "
                    "offered, picked, swapped and claimed, counted from what the "
                    "server sees and paying pages (§9.1) and no stars (F42's "
                    "answer), under §20.3's caps; the streak with its saver, "
                    "repair and cosmetic. Client: the repository, state and "
                    "presenters that TD.23's Season screen and TD.26's first "
                    "session draw. The design's quests and star chests are not "
                    "these, and stay refused.",
             gate="server tests for three picked of six, one swap, each claim "
                  "once, and the streak's saver and repair; presenter tests for "
                  "both in both languages",
             blocked_by=["TC.12"],
             register=["F42"]),
        # -- Track D: the screens, the slice's first -------------------------
        dict(id="TD.17", owner="claude", status="blocked",
             title="Heist and result on the design, on the flat view",
             detail="The heist's HUD and controls on the flat view (the design's "
                    "portraits with pips and lockout, Get out and the skiff, the "
                    "alarm with its newest effect in words, the Vault and load "
                    "target, the Sage dial); the 3D view is TD.42. The result to "
                    "§23.2's rewritten row: outcome and multipliers, the decisive "
                    "moment with a three-second replay and one thing to try, loot "
                    "kept, the fee by target kind (none on a Trace), the law to "
                    "study, Renown, rest per crew member, and “worth your time?”. "
                    "The settle answer gains what the result shows, from TC.12's "
                    "pages and roster (crossed, studyPages, pylonPages, firstMet, "
                    "floorPage, rest, strays, insight, targetKind), and "
                    "<code>POST /v1/heists/:token/study</code> takes the study. "
                    "Two parts wait on owners' answers and are built switchable, "
                    "one token apart: the worth question on every result as "
                    "§23.2's row asks, or once a session as §20.3 and the server "
                    "read it (C47); and the moment picker's rule and its “Try "
                    "this” label, read from one table holding G48's drafted rule "
                    "(G48). The design's heist adds mechanics (a Sage wheel's "
                    "extra powers, heist-wide casts, a grace at the start, slow "
                    "motion at each alert) that are refused (D79).",
             gate="the screen gate for §23.2's Heist and Heist result rows, the "
                  "result in each kind of target's variant; no more than §12.7's "
                  "eight controls live at once (a test); the heist and result "
                  "tests kept by name (completion reads them); the moment picker "
                  "tested on the five goldens",
             blocked_by=["TD.3", "TD.12", "TD.13", "TC.12"],
             register=["C47", "D79", "D80", "G48"]),
        dict(id="TD.41", owner="claude", status="blocked",
             title="The landing picker on one island",
             detail="Stage A of the landing picker, on the one-island heist that "
                    "exists: <code>landing_heard</code> and "
                    "<code>landing_reach</code> in the simulation and the "
                    "extension, the leased island's edge with what guards would "
                    "hear (§5.4), and the chosen tile as the replay's first "
                    "command; the seed's <code>default_landing()</code> stays for "
                    "offline only. It closes T3.4's “Not yet: §21's landing "
                    "picker”. Every outer realm's edge comes with universes of "
                    "several realms (TD.18).",
             gate="the screen gate for the Landing picker row on one island; the "
                  "chosen tile is the replay's first command (a test)",
             blocked_by=["TD.3"]),
        dict(id="TD.18", owner="claude", status="blocked",
             title="Observatory, scout report and planner",
             detail="They draw universes of several realms (T3.3), and each piece "
                    "stands on work below it: the Observatory's refresh, a paid "
                    "scout and casts cost Aether, and the planner's crew needs the "
                    "roster and rest (TC.12); its Sage and casts rows bind to the "
                    "simulation's (TD.12); law chips open the law card (TD.20); "
                    "ruins come from the generator (TD.16); the planner starts from "
                    "the landing picker (TD.41). The offer stops sending the "
                    "internal rating to the device and starts sending why each "
                    "target was offered and its depth (§12.15, §12.22); the scout "
                    "draws no positions (brief 38). Where an owner's answer is "
                    "pending the screen draws the server's value and holds no rule "
                    "of its own: the fee and the window as the server charges them "
                    "(F39, C41, F44) and the free scout (F46), which stand while "
                    "the owner's answer to C45 keeps them; and how many targets "
                    "show and what a card says, from C46 and D77, the same way.",
             gate="the screen gate for the Observatory, Scout report and Heist "
                  "planner rows, and for the Landing picker row on universes of "
                  "several realms; an offer test that no rating reaches the device; "
                  "every fee shown equal to the lease's",
             blocked_by=["TD.3", "T3.3", "TD.12", "TD.16", "TD.20", "TD.41", "TC.12"],
             register=["F46", "F51", "D77", "C46", "D78"]),
        dict(id="TD.19", owner="claude", status="blocked",
             title="Home and the realm view on the world",
             detail="The Universe map and the realm view are the diorama with "
                    "the shell's chrome: realms with their realm and crown laws, "
                    "links, TD.10's pylon in every woven slot with its zone and "
                    "the law's chip over it (D74), the universe's one strain band "
                    "from TD.14, the faults TD.37 builds, ready amounts and the "
                    "heist button. "
                    "The server's universe gains laws, links, strain, production "
                    "and caps (TC.12's slices), and each building its tile "
                    "(TD.36). The buildings and looks the design lacks are TD.32's, "
                    "made after the style is settled; until each lands its "
                    "footprint is drawn plain, with its icon, so home and the "
                    "slice (T6.1) do not wait on all of §21.9's art, which "
                    "§26.2 puts in the beta. "
                    "The design's builders cap, upgrade timers, typed guard posts, "
                    "second Hearths and Storehouse in the Heart, and its shield "
                    "timer on home are mechanics §10 and §18.8 do not have, "
                    "and are refused. Home's layout is the shell's (TD.6, C44).",
             gate="the screen gate for the Universe map and Realm view rows; every "
                  "building drawn on its stored tile (a test against TD.36's "
                  "island)",
             blocked_by=["TD.6", "TD.10", "TD.14", "TD.36", "TD.37", "TC.12"],
             register=["D73", "D75", "G46", "D74"]),
        dict(id="TD.42", owner="claude", status="blocked",
             title="The heist in 3D",
             detail="TD.17's heist on TD.10's world: actors interpolated between "
                    "ticks, §21.12's cones and overlays, §12.6's camera, and "
                    "TD.11's characters. The flat view stays for screen readers "
                    "and as the fallback.",
             gate="every actor drawn at its tile at every tick of the five goldens "
                  "(TD.10's check); the heist tests passing with either view",
             blocked_by=["TD.17", "TD.10", "TD.11"]),
        dict(id="TD.20", owner="claude", status="blocked",
             title="Weaving and the law card",
             detail="Weaving shows the big card with its looping preview, cost, "
                    "strain and ready time, and the two or three recommended laws "
                    "§23.2 asks for, which the design omits; every price is read "
                    "from TD.14's function, so an owner's answer changes numbers "
                    "and not the screen. The law card carries the school's shape "
                    "and a looping preview, never a pause sign, and §7.7's one "
                    "weakness rather than the design's counters (D79). Effect words "
                    "come from content (G23, G25). Aether and weaving state live on "
                    "the server first (TC.12). The Codex and the Harmony view are "
                    "TD.44.",
             gate="the screen gate for the Weaving and Law card rows; every price "
                  "shown equal to the server's for the same weave (a test)",
             blocked_by=["TD.3", "TD.14", "TC.12"],
             register=["G23", "G25", "D81", "D79"]),
        dict(id="TD.21", owner="claude", status="blocked",
             title="Roster, Character and Sage hall",
             detail="The roster on the server comes first (TC.12), and the cards "
                    "read TD.33's tables. The character screen shows §11.11's card "
                    "word for word and §11.1's role numbers, not the sheets' own; "
                    "the design's stealth and grit stats, its role-keyed abilities "
                    "and its work bonuses are refused, and so are the sheets' "
                    "variants for visitors and anomalies (D95). The Sage hall "
                    "lists the four launch Sages with their powers and levels from "
                    "TC.12's Sage routes, and draws Insight as the server pays it, "
                    "so the owner's answer to G52 changes the server and not the "
                    "screen. Hatching and naming (G50) and a visiting Stray (G64) "
                    "wait on the owner's answers and are TD.63's; the server "
                    "grants none until then. Paradox-born join the roster with TD.35; the "
                    "Forms album is TD.45.",
             gate="the screen gate for the Roster, Character and Sage hall rows; "
                  "every card's words generated from TD.33's content (a test)",
             blocked_by=["TD.3", "TD.12", "TD.33", "TC.12"],
             register=["D82", "G52", "C53", "G62", "G63", "D94", "D95", "G65"]),
        dict(id="TD.43", owner="claude", status="blocked",
             title="Rehearsal",
             detail="A rehearsal sends one of TD.39's three crews against the "
                    "universe as it stands and replays its route; pause stays in "
                    "rehearsals (§20.8), and the slower speed is for ruins only "
                    "(TD.27). §26.2's slice has rehearsals and no heists against "
                    "players, so the defence log, the other half of §23.2's row, "
                    "is TD.66's, outside the slice.",
             gate="the screen gate for the Rehearsal and defence log row's "
                  "rehearsal half: the simulated crew's choice and the route "
                  "replay",
             blocked_by=["TD.3", "TD.39"]),
        # -- Track D, outside the slice ------------------------------------------
        dict(id="TD.44", owner="claude", status="blocked",
             title="The Codex and the Harmony view",
             detail="The Codex's chapters are unlock steps by Keeper level and its "
                    "schools are albums (§7.6), with restoration and study from "
                    "TC.12; Harmony shows harmonies, clashes and chords as TD.14 "
                    "prices them. Chapter 1's laws, meeting a law, mastery and the "
                    "Codex's notes wait on the owner's answer to G49. With the "
                    "chapters, matchmaking offers only universes running laws "
                    "from open chapters (§7.6), a change to "
                    "<code>matchmaking.mjs</code>.",
             gate="the screen gate for the Law Codex and Harmony view rows; an "
                  "offer test that no target runs a law from a closed chapter",
             blocked_by=["TD.20", "TC.12", "TD.56"],
             register=["G49"]),
        dict(id="TD.45", owner="claude", status="blocked",
             title="The Forms album",
             detail="The 54 forms by kind, each drawn with its accessory and "
                    "pattern (TD.11), filled by births at a Nursery from TC.12's "
                    "hatch route. Paradox-born forms, if the owner's answer to G62 "
                    "gives them any, sit outside the album's 54.",
             gate="the screen gate for the Forms album row; every form in it "
                  "drawn from TD.7's manifest",
             blocked_by=["TD.21", "TD.11", "TC.12"]),
        dict(id="TD.66", owner="claude", status="blocked",
             title="The defence log",
             detail="The raids on the player from TC.12's defence routes, each "
                    "with its report (§23.2: the haul denied, how long the defence "
                    "held, where the crew was seen, what fired) from TD.39's "
                    "record, whose haul G31 must price, and Trace from each. "
                    "§26.2 brings heists against players in phase 3, so the slice "
                    "(T6.1) does not wait on it.",
             gate="the screen gate for the Rehearsal and defence log row's other "
                  "half: raids on you, each with its report, and Trace; the raid "
                  "badge clears once the log is seen (a flow test)",
             blocked_by=["TD.3", "TD.6", "TD.39", "TC.12"],
             register=["G31"]),
        dict(id="TD.63", owner="claude", status="blocked",
             title="Hatching, naming and the visiting Stray",
             detail="Births have no screen and naming has no rule (G50), and no "
                    "realm decides a visiting Stray's kind and form (G64). Once "
                    "the owner answers both, the server grants births and the "
                    "Stray as the answers write them, and the client gains what "
                    "they draw on TD.21's roster: a hatch sheet, names, and the "
                    "Stray at the Dock.",
             gate="server tests for each rule the answers write (a birth's kind "
                  "and form, its name, the Stray's draw); the screen gate for "
                  "what the answers add to the Roster and Character rows",
             blocked_by=["TD.21", "TD.59"],
             register=["G50", "G64"]),
        dict(id="TD.64", owner="claude", status="blocked",
             title="Presence and pings among friends, and the Open Vault league",
             detail="Which of the design's friend features ship (D86: none, "
                    "pings, or presence and activity for 16 and over) and whether "
                    "§9.4's Open Vault league ships at launch (C50) each change "
                    "the server and TD.23's Friends and League screens. Built as "
                    "the owner's answers write them; an answer that ships neither "
                    "closes this task with nothing built.",
             gate="server tests for what the answers ship (a ping refused across "
                  "a block and past the cap; presence by band; the league's pool "
                  "and debit); the screen gate for what they add to the Friends "
                  "and Season rows",
             blocked_by=["TD.23", "TD.60"],
             register=["D86", "C50"]),
        dict(id="TD.65", owner="claude", status="blocked",
             title="The Lab's hints, curation's swaps and the hold figure",
             detail="The Lab's hints, chord naming and payouts (G53), whether a "
                    "curation swap is a weave at §5.6's price (G54), and where the "
                    "hold figure curation and the Workshop show comes from (G55), "
                    "built on TD.22's screens as the owner's answers write them.",
             gate="the Resonance Lab row's hints, as G53's answer writes them; a "
                  "curation swap charged as G54's answer says (a server test); "
                  "the hold figure shown equal to its source under G55's answer",
             blocked_by=["TD.22", "TD.61"],
             register=["G53", "G54", "G55"]),
        dict(id="TD.22", owner="claude", status="blocked",
             title="Lab, defence curation, terrain editor and Workshop",
             detail="The Lab at §10.2's times (5 h at level 3, not the design's "
                    "5 h 30) on TC.12's Lab service; curation over the generator's "
                    "alternatives, changing laws at TD.14's weaving prices; the "
                    "terrain editor on the simulation's features and §6.1's "
                    "budgets (not the design's 80 points, or its Hill and Grove), "
                    "placing the six directional features once TD.38 has them; and "
                    "the Workshop on the design, keeping remix and withdraw. The "
                    "Lab's hints, chord naming and payouts (G53), whether a "
                    "curation swap is a weave (G54) and the hold figure curation "
                    "and the Workshop show (G55) wait on the owner's answers and "
                    "are TD.65's; the rest of the task does not wait.",
             gate="the screen gate for the Resonance Lab row but its hints "
                  "(TD.65's), the Defence curation row, the Terrain editor row "
                  "with every feature the simulation has (TD.38's six join it "
                  "there) and the Island Workshop row; the Workshop's tests kept "
                  "by name (completion reads them)",
             blocked_by=["TD.3", "TD.14", "TD.15", "TD.16", "TC.12"],
             register=["D83"]),
        dict(id="TD.23", owner="claude", status="blocked",
             title="Season, Shop, Share sheet and Friends on the design",
             detail="TC.6 built them on the backend that existed; the design asks "
                    "for more than a new look, and each screen's server work is "
                    "named. Season: the league road with every league's bounds "
                    "and season-end reward, the season's end time, the week's era "
                    "from <code>GET /v1/era</code>, claiming through a tier in one "
                    "call, and TD.40's goals and streak. Shop: an authored "
                    "catalogue (D64), and the band's cap and approval words before "
                    "every purchase; its previews on your universe are TD.46's. "
                    "Share sheet: the challenge to chosen friends, the invite gift "
                    "on a friend's first heist, and deep links for both; the clip "
                    "is TD.46's. Friends: each friend's free facts and the "
                    "friendly-heist score, and <code>POST /v1/reports</code> for "
                    "players (§20.4: report and block from any name). Prices are "
                    "money as the server sells them, F41's answer, which stands "
                    "while the owner's answer to C45 keeps it; the screen draws "
                    "the server's price, so an answer changes the server and not "
                    "the screen. The mechanics the design adds are refused: a "
                    "Starpass that adds 20% stars (§18.8), quests and star chests, "
                    "league rewards for everyone, live “raiding” status (§17.8). "
                    "Presence and last seen (D86) and the Open Vault league (C50) "
                    "wait on the owner's answers and are TD.64's.",
             gate="the screen gate for the Season and Friends rows, the Shop row "
                  "but its previews and the Share sheet row but its clip (both "
                  "TD.46's); claiming through a tier is one call (a flow test); the "
                  "shop, track and social tests kept by name (completion reads "
                  "them)",
             blocked_by=["TD.3", "TD.40"],
             register=["G28", "F41", "D84", "D85", "F57"]),
        dict(id="TD.46", owner="claude", status="blocked",
             title="The share clip and the Shop's previews, on the 3D world",
             detail="Both draw the shared world off the main flow. The clip: the "
                    "moment TD.17's picker chooses from TD.13's event log, "
                    "re-rendered from the replay's window in the world in replay "
                    "mode, posted to friends as the window and never as a video "
                    "(<code>POST /v1/clips</code>), within the replay's retention "
                    "(§24.3); outside the game, for 16 and over as §20.7 allows, "
                    "through a platform encoder plugin measured on phones in TC.8. "
                    "The Shop's previews show a realm skin, sky or bridge on the "
                    "player's own universe and an outfit on their own ruleborn, "
                    "never saved.",
             gate="the screen gate for the Share sheet's clip and the Shop's "
                  "previews; a clip re-rendered from its window matches the "
                  "replay's checksums; a preview leaves the universe unchanged "
                  "(a test)",
             blocked_by=["TD.6", "TD.10", "TD.11", "TD.13", "TD.17", "TD.23"]),
        dict(id="TD.24", owner="claude", status="blocked",
             title="Profile and stats, with its server route",
             detail="v3.6's new §23.2 row: Renown and league over time, never "
                    "the rating; heists by outcome; defences held and leaked; "
                    "records; the battle log with replays while they are kept; "
                    "collection and badges; private for 13 to 15 and private by "
                    "default for 16 and 17 (§20.2), with the visibility switch in "
                    "Settings (TD.25). The server writes each heist's facts at "
                    "settlement from TD.39's record and answers "
                    "<code>GET /v1/profile</code>. “Leaked”, records and badges "
                    "wait on the owner's answer to G69.",
             gate="the screen gate for the Profile and stats row; a 13-to-15 "
                  "profile never served to another account, and a 16-to-17 one "
                  "only once its switch is on (server tests)",
             blocked_by=["TD.3", "TD.13", "TD.25", "TD.39", "TD.55"],
             register=["G69", "D85"]),
        dict(id="TD.25", owner="claude", status="blocked",
             title="Settings and wellbeing in four tabs",
             detail="Protections the band fixes shown locked (§23.2, §20.2), "
                    "read from <code>content/protections.json</code>, generated "
                    "from the design facts the server's night hours and caps come "
                    "from; deletion with “withdraw my islands too” (D70, F43); the "
                    "reminder picker offering no time inside the night (G34); "
                    "play-time reminders (§20.2's 60 and 90 minutes); hold time "
                    "and moving controls (§20.8); help and support (§20.10). The "
                    "server gains what the screen reads: "
                    "<code>GET /v1/notifications</code> and a raided opt-out, and "
                    "profile visibility stored and enforced wherever a profile is "
                    "read (§20.2: private for 13 to 15, private by default for 16 "
                    "and 17, the player's choice from 18). The design's age-band "
                    "preview changes the player's band and is refused. How a band "
                    "may change and whether 16 and 17 may switch the reminder off "
                    "wait on the owner's answer to G58; until then the stricter "
                    "reading holds, one switch away.",
             gate="the screen gate for the Settings and wellbeing row; every "
                  "protection §20.2 fixes shown locked for each of the three "
                  "bands (a presenter test)",
             blocked_by=["TD.3"],
             register=["D70", "F43", "G34", "D87", "D88", "G58"]),
        dict(id="TD.26", owner="claude", status="blocked",
             title="First launch in §23.5's order",
             detail="Title, the age step (the built check, restyled, with no way "
                    "back from under 13), a summary of the protections the band "
                    "sets, the Keeper's name and face, then §16's beats, each on "
                    "its own screen and finished by a real event: three ruleborn "
                    "wake, the first heist on a tutorial ruin and its result, two "
                    "strays put to work at the Star Well and the Garden, a law "
                    "woven, the first five-minute experiment, two more ruins to "
                    "choose from, and three daily goals. So it lands last, on the "
                    "screens and on the server's pieces: a ruin lease mode and the "
                    "tutorial set, the first session's grants, the Keeper's name "
                    "and face, and a first-session-complete flag. The name's rule "
                    "and who sees it wait on the owner's answer to G58 (its "
                    "recommendation: word lists at every age, as C43's answer gives "
                    "islands, seen by raiders as §12.4's free name), and the first "
                    "heist's time and what comes before it on C51.",
             gate="§16's moments each finished by a real event in a flow test from "
                  "title to done; a killed app resumes at the same beat; the "
                  "screen gate for the First launch row",
             blocked_by=["TD.16", "TD.17", "TD.18", "TD.19", "TD.20", "TD.21",
                         "TD.22", "TD.25", "TD.40", "TC.12", "TD.57"],
             register=["F56", "C51", "D87"]),
        dict(id="TD.27", owner="claude", status="blocked",
             title="Slower ruins, not slower rehearsals",
             detail="§23.5 adopts the design's 75% speed for drifting ruins "
                    "only, never a heist against a player and never Renown. The "
                    "client applies it to the builder's rehearsal and completion's "
                    "accessibility row names that test; the setting, the test and "
                    "the proof are renamed in one change, and the effect waits for "
                    "ruins.",
             gate="the setting slows drifting ruins and nothing else (a test), and "
                  "completion's accessibility row reads the renamed test",
             blocked_by=["TD.16"],
             register=["D96"]),
        dict(id="TD.28", owner="claude", status="blocked",
             title="Landscape for every screen",
             detail="§23.3 asks for portrait and landscape; Screens v3 designs "
                    "portrait only (§23.5). The shell first, under both of TD.6's "
                    "arrangements (the design's tab bar a left rail) and its HUD a "
                    "right column (TD.6 is portrait only), then "
                    "each screen once its portrait version is accepted.",
             gate="the layout check in landscape for every screen, in both "
                  "languages, at 100%, 150% and 200% text",
             blocked_by=["TD.30", "TD.17", "TD.18", "TD.19", "TD.20", "TD.21",
                         "TD.22", "TD.23", "TD.24", "TD.25", "TD.26", "TD.41",
                         "TD.42", "TD.43", "TD.44", "TD.45", "TD.46", "TD.62",
                         "TD.63", "TD.64", "TD.65", "TD.66"]),
        # -- Measuring it -----------------------------------------------------
        dict(id="TD.47", owner="claude", status="ready",
             title="Completion's proofs: the store builds, crews, terrain and stage SD",
             detail="Three places where completion reads something other than "
                    "what is built. §26.6 puts the store builds in the determinism "
                    "spike, and completion counts them in phase 2 with a proof "
                    "that reads nothing: one proof reads a recorded build (engine "
                    "version, SDK levels, the upload), counted in one place, with "
                    "the choice of phase stated (G68). Crews reads done without "
                    "abilities, Sage powers or casts, and Terrain editing with five "
                    "of 39 features: each proof gains the missing system, so the "
                    "figure reads what is built (G67). And §26.8 costs none of "
                    "stage SD's screens, design port or 3D world, so nothing here "
                    "moves the figure (G66): §26.8 has no row for the interface, "
                    "as it has none for the home economy (G42), and once the "
                    "document carries one (T1.6), completion reads it.",
             gate="Crews and Terrain editing read their missing systems as not "
                  "built until TD.12, and TD.15 and TD.38, land; the store builds count only "
                  "from a recorded build; <code>tools/completion.py</code> states "
                  "which phase holds them",
             register=["G66", "G67", "G68"]),
        # -- The owner's ------------------------------------------------------
        dict(id="TD.29", owner="you", status="yours",
             title="Settle what the designs leave open, and take your answers into the document",
             detail="v3.6 took part of one of the 47 answers you recorded on "
                    "25–26 September, G28's wording for §18.8 without ‘bought’, "
                    "with §14.4's free-lane row, and left the rest unwritten; §23.5 makes the document win over "
                    "the designs, so a screen can have three sources that disagree. "
                    "The build follows a recorded answer first, then the document, "
                    "then the design: that order is C45's recommendation, and it "
                    "holds only until you answer C45. The decisions listed here "
                    "hold no task up: the tasks above build each one's pending "
                    "value switchable by one token. A decision a task waits on has "
                    "a task of its own below (TD.50 to TD.61), so that task waits on "
                    "its decision and no other. All of them are in the brief, in "
                    "the order to decide them: the visual language (surfaces, "
                    "typefaces, icon finish, motion, shading), how outlined text "
                    "counts for contrast, the decisive moment, and the rest listed "
                    "there.",
             gate="every decision listed here has an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["C44", "C45", "D77", "C46", "G47", "G48", "C47", "G52",
                       "C49", "F57", "D89", "D90", "D91", "D92", "G59", "D93",
                       "C52"]),
        dict(id="TD.50", owner="you", status="yours",
             title="Answer G51: what a server-checked heist knows of the crew",
             detail="TD.34 waits on it: whether the heist models levels and traits, and"
                    " §11.4 to §11.6's rules for growth, a home and rest.",
             gate="G51 has an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["G51"]),
        dict(id="TD.51", owner="you", status="yours",
             title="Answer C53 and G62: the paradox-born",
             detail="TD.35 waits on both: what the Twinned's gift doubles, or whether "
                    "it ships, and whether paradox-born guard and take forms.",
             gate="C53 and G62 each have an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["C53", "G62"]),
        dict(id="TD.52", owner="you", status="yours",
             title="Answer C48 and G46: stability's open rules and faults",
             detail="TD.37 waits on both: upkeep, crown laws across realms, Breaking "
                    "and the recommended laws, and how §5.5's faults open and who sees "
                    "them.",
             gate="C48 and G46 each have an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["C48", "G46"]),
        dict(id="TD.53", owner="you", status="yours",
             title="Answer G56: who sets a feature's direction",
             detail="TD.38 waits on it: who sets the up side, the ledge side, "
                    "downstream and a tunnel's two ends, and what the generator picks.",
             gate="G56 has an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["G56"]),
        dict(id="TD.54", owner="you", status="yours",
             title="Answer G57: the rehearsal crews and a raid's report",
             detail="TD.39 waits on it: each rehearsal crew's rule and how one raid's "
                    "report is measured.",
             gate="G57 has an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["G57"]),
        dict(id="TD.55", owner="you", status="yours",
             title="Answer G69: held and leaked, records and badges",
             detail="TD.24 waits on it: what a defence held or leaked means on the "
                    "Profile, its records, and whether badges ship.",
             gate="G69 has an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["G69"]),
        dict(id="TD.56", owner="you", status="yours",
             title="Answer G49: the Codex's first chapter, meeting a law and mastery",
             detail="TD.44 waits on it: chapter 1's laws, meeting a law, mastery and "
                    "the Codex's notes.",
             gate="G49 has an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["G49"]),
        dict(id="TD.57", owner="you", status="yours",
             title="Answer G58 and C51: minors' protections, every Keeper's name, and "
                   "the first session",
             detail="TD.26 waits on both: how a band changes, the play-time reminder, "
                    "every Keeper's name and where the terms are taken (G58), and the "
                    "first heist's time and what comes before it (C51).",
             gate="G58 and C51 each have an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["G58", "C51"]),
        dict(id="TD.58", owner="you", status="yours",
             title="Answer C54: the Sparkwright's goggles and each kind's animations",
             detail="TD.62 waits on it; TD.11's other characters do not.",
             gate="C54 has an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["C54"]),
        dict(id="TD.59", owner="you", status="yours",
             title="Answer G50 and G64: hatching and naming, and the visiting Stray",
             detail="TD.63 waits on both; TD.21's roster does not.",
             gate="G50 and G64 each have an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["G50", "G64"]),
        dict(id="TD.60", owner="you", status="yours",
             title="Answer D86 and C50: friends' presence and the Open Vault league",
             detail="TD.64 waits on both; TD.23's screens do not.",
             gate="D86 and C50 each have an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["D86", "C50"]),
        dict(id="TD.61", owner="you", status="yours",
             title="Answer G53, G54 and G55: the Lab's rules, curation's swaps and the"
                   " hold figure",
             detail="TD.65 waits on all three; TD.22's screens do not.",
             gate="G53, G54 and G55 each have an answer in "
                  "<code>docs/decisions/answers.json</code>",
             evidence="docs/decisions/index.html",
             register=["G53", "G54", "G55"]),
        dict(id="TD.48", owner="you", status="blocked",
             title="Target phones in hand, running TC.3's builds",
             detail="§26.2's art-style test reads on target devices, and TC.8 "
                    "measures on them: §24's reference device (a mid-range 4 GB "
                    "Android at 60 Hz) and the phones §21.3 names (C52 decides how "
                    "the two rules meet). This is having them and installing TC.3's "
                    "builds; the measurements are TD.30's, T3.1's (the iPhone "
                    "and Android checksums, before any screen) and TC.8's.",
             gate="TC.3's build installs and launches on each phone",
             blocked_by=["TC.3"]),
        dict(id="TD.30", owner="you", status="blocked",
             title="§26.2's pre-production exit: screens approved, the art style read on devices",
             detail="Phase 1 ends when the screens are approved and the art-style "
                    "test shows eight wards and six or seven kinds of defensive "
                    "marker reading on target devices, checked under "
                    "colour-blindness simulation; if eight do not read the ward cap "
                    "drops one at a time (§26.2). The markers include guards with "
                    "TD.11's role accessories and TD.31's pylons, and the "
                    "harness's 15 to 25 decisions a run are measured after TD.12, "
                    "which changes them. No task held it before stage SD.",
             gate="§26.2 phase 1's exit test",
             blocked_by=["TD.10", "TD.11", "TD.12", "TD.31", "TD.48"]),
        dict(id="TD.49", owner="you", status="blocked",
             title="Re-check the store declarations when Profile, Settings and "
                   "first launch add data",
             detail="Profile writes each heist's facts at settlement (TD.24), "
                    "Settings stores profile visibility (TD.25), and first launch "
                    "the Keeper's name and face (TD.26). The column test in "
                    "<code>server/privacy.json</code> catches each new column; if "
                    "TC.14 filed App Privacy and Data safety before they landed, "
                    "both are answered again from server/declarations.md.",
             gate="<code>node server/src/privacy.mjs --check</code> passes with "
                  "the new columns, and the filed answers match "
                  "server/declarations.md",
             blocked_by=["TC.14", "TD.24", "TD.25", "TD.26"]),
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
             detail="Not before abilities, Sage powers and casts are in the "
                    "replay (TD.12), with the crew's levels and traits (TD.34) "
                    "and the paradox-born (TD.35), and the actors' appearance "
                    "rides beside it (TD.9); nor before the island holds its "
                    "buildings (TD.36), its terrain (TD.15, TD.38) and the "
                    "stability price (TD.14). Each changes what a heist or an "
                    "island records and is a rules-version change (\u00a724.11), "
                    "and a lock before them locks an incomplete contract.",
             blocked_by=["T3.1", "TD.12", "TD.9", "TD.14", "TD.15", "TD.34",
                         "TD.35", "TD.36", "TD.38"]),
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
             detail="After the simulation contract (T5.1), and after the "
                    "bundle carries crown laws (TD.14) and the stability rules "
                    "the owner settles (TD.37).",
             blocked_by=["T5.1", "TD.9", "TD.14", "TD.37"]),
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
                    "a golden replay. The crew lands where the raider "
                    "chooses: the landing is a command in the replay, the "
                    "whole crew on one open edge tile at tick 0, heard by "
                    "guards within six tiles unless the spot is in fog, "
                    "darkness or tall grass (\u00a75.4), and the server "
                    "refuses a heist that never lands. Building it found "
                    "that a Keeper can wall every edge tile but one, and so "
                    "choose the landing \u00a75.4 says a defender cannot "
                    "(F51). Its review (60 agents, each finding tried by two "
                    "skeptics) confirmed and fixed: Ghost tide still sent the "
                    "knocked-out to the old north-edge tiles, the landing was "
                    "heard through walls where \u00a712.17 has every sound "
                    "walk, pits and illusions still spared row 0 but not the "
                    "real landing, and the client\u2019s default landing, "
                    "first in row order, was one a Keeper could aim at a "
                    "closed pocket \u2014 it now picks by seed among the "
                    "landings that reach the Vault. Building the heist found that \u00a712.6's crack "
                    "noise is erased by \u00a712.17's decay before it can matter, "
                    "and that on plain ground \u00a712.8's ambush cannot be "
                    "reached: the last crouched step behind a guard is heard. "
                    "What is left is the half a measurement cannot settle: "
                    "whether it <em>feels</em> like agency, which is "
                    "\u00a730.8's 70% gate and needs people.",
             gate="\u2265 70% felt control (\u00a730.8)",
             register=["F51", "G40", "D71"],
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
             detail="Its content needs more than the locks: universes of several "
                    "realms (T3.3), the roster on the server (TC.12), abilities and "
                    "Sages (TD.12), ruins (TD.16), \u00a726.2's pre-production exit "
                    "(TD.30), and the slice's screens: the heist and result "
                    "(TD.17, TD.42), the landing picker, Observatory and planner "
                    "(TD.41, TD.18), home and the realm view (TD.19), weaving "
                    "(TD.20), the roster and the Sage hall (TD.21), and "
                    "rehearsal (TD.43). The defence log (TD.66) is not the "
                    "slice's: §26.2 brings heists against players in phase 3.",
             gate="\u00a719.27's harness gates: 15 to 25 meaningful decisions a "
                  "run, a near-capture in about a third of runs, the optimal crew "
                  "at least 35 points ahead of the careless one, hold rates and "
                  "pacing in band, commands explaining most of the outcome "
                  "variance. No outside player is involved (\u00a726.2)",
             blocked_by=["T5.1", "T5.2", "T5.3", "T5.4", "T5.5", "T3.3",
                         "TC.12", "TD.12", "TD.16", "TD.30", "TD.17", "TD.42",
                         "TD.41", "TD.18", "TD.19", "TD.20", "TD.21", "TD.43"]),
        dict(id="T6.2", owner="you", status="blocked",
             title="Play the slice yourself, against the harness's gates",
             detail="Since v3.3 \u00a726.2 needs no player but the developer before "
                    "soft launch: \u00a719.5's fun gate moved to soft launch (T7.3), "
                    "where there are players. The slice is still the first build "
                    "you can play end to end.",
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
             gate="no dominant law in bot runs, and the same harness gates as "
                  "the slice, on the full alpha content (\u00a726.2)",
             blocked_by=["T6.2"]),
        dict(id="T7.2", owner="claude", status="blocked",
             title="Beta on TestFlight — all launch content, age protections, moderation",
             gate="stable; privacy and legal review passed (§26.2)",
             blocked_by=["T7.1"]),
        dict(id="T7.3", owner="you", status="blocked",
             title="Soft launch in a few English- and Portuguese-speaking countries",
             gate="the launch gates in \u00a722.2, and the gates that need "
                  "players: \u00a725.1, the fun gate in \u00a719.5 and "
                  "comprehension in \u00a725.3 (\u00a726.2)",
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
    ("Character art", "Screens v3 has 43 sheets with 3D models, as code: they "
                      "are exported and held to \u00a721.3's budgets first (TD.7), "
                      "and \u00a726.2's art-style test on target devices (TD.30) "
                      "settles the style before the quantity is made."),
    ("Building past the design", "Screens v3 is the design (\u00a723.5). A "
                                 "screen is built from it with the document's "
                                 "rules, and nothing the design adds that changes "
                                 "what a player can do is built until the "
                                 "document says so; the places the designs depart "
                                 "are in the register's v3.6 layer."),
    ("Localisation", "Two launch languages with a named owner since v3.3, but "
                     "the coined vocabulary gets its native-speaker read-aloud "
                     "(\u00a726.9) before anything is translated."),
    ("Claiming the name publicly", "§26.9 makes trademark clearance a gate, and "
                                   "it has not been done."),
]
