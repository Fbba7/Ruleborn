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
                    "against the bands until this is done (F35).<br><br>"
                    "<strong>F55 settled by v3.7</strong>, which took its "
                    "brief's recommended option (D), so the balance pass this "
                    "measurement asked for is the document's: realm levels 1 to "
                    "3 keep 8, 8 and 6 wards on 1, 1 and 2 posts with their "
                    "guards tuned by the realm's watch (suspicion at 0.6 at "
                    "level 1, sight 0.75 and 0.7 as far at levels 2 and 3), and "
                    "levels 4 and 5 take one post with 2 wards and none (§5.2, "
                    "§12.17, §13.2). The build follows it: the budget in "
                    "<code>design_facts</code>, the watch in <code>sim/</code> "
                    "and the harness (rules “v3.7”, "
                    "<code>a_realms_watch_tunes_its_guards_by_realm_level</code>). "
                    "The re-measure at n = 800 with §12.17's alarm ladder on is "
                    "TD.69's, and the check over every ward kit TD.71's.",
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
                    "supersedes. §26.8's missing rows are in: v3.7 costs the home "
                    "economy, the interface screens and the art pass as phases "
                    "4a, 4b and 4c (G42, G66), and completion reading them is "
                    "TD.47's.",
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
                    "fallback targets (TD.16), universes of several realms, which "
                    "v3.7's \u00a726.8 now puts in phase 6 (D71), and \u00a718.9's "
                    "Island Fund, paid from purchase records (D62).",
             evidence="node --no-warnings --test server/test/*.test.mjs; "
                      "bash sim/run_spike.sh",
             register=["G17", "D58", "G20", "G21", "G26", "D62", "C43", "F40", "G27", "D63", "F41", "F42", "G28", "D64", "G29", "D65", "F43", "F44", "F45", "G30", "D66", "G31", "F46", "G32", "D67", "F47", "G33", "G34", "D68", "F48", "G35", "F49", "G36", "D69", "G37", "F50", "G38", "G39", "D70", "G44", "G74"]),
        dict(id="T3.4", owner="claude", status="doing",
             title="The client's half: the simulation inside Godot, and a "
                   "replay on screen",
             detail="\u00a724.7: the simulation is <em>\u201cwritten once and "
                    "compiled for every target it runs on\u201d</em>, as a Rust "
                    "GDExtension. <strong>Built for the desktop.</strong> "
                    "<code>client/</code> is a Godot 4.7.2 project (TD.1) in \u00a721.1's "
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
                    "launch screen exists: ten of \u00a723.2's 29 do today, and "
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
                    "change, and v3.7's \u00a726.8 now builds the home economy "
                    "as phase 4a: buildings, workers and production (\u00a79.3, "
                    "\u00a75.8), spending, the Spire, the roster and births, the "
                    "Codex's restorations, and \u00a714.2's experience from each, "
                    "with the device's offline building, weaving and assigning "
                    "confirmed on reconnection (G42). The economy model already "
                    "runs all of it; the server "
                    "side is the work, slice by slice, with F54's gate on the "
                    "Keeper bar once spending is the only experience left. "
                    "Built: realms and buildings (server/src/universe.mjs) "
                    "\u2014 outer realms opened and raised, buildings built and "
                    "raised at \u00a710.2's costs and needs, paid from the "
                    "ledger with \u00a714.2's experience for spending, islands "
                    "held to what is built \u2014 and the client's universe "
                    "screen; and the roster, workers and production "
                    "(server/src/home.mjs): \u00a715.6's three who wake and the "
                    "first heist's two strays, the Spire's and the Hearths' "
                    "places, births at a Nursery at \u00a79.5's price, drawn "
                    "from the realm's school, levels in Essence up to the home's "
                    "top, work at producers and Guardian Posts from five minutes "
                    "after assignment, production at \u00a79.3's rate with the "
                    "staffing, the realm's school and the workers' bonuses, held "
                    "12 hours, collected into a ledger that now carries Aether, "
                    "the roster's keep taken from the Essence (G82); and the "
                    "Codex (server/src/codex.mjs): the starting laws at tier I, "
                    "a page for each law met, a page for each pylon broken "
                    "(read from the re-simulation), one study a heist, the "
                    "eighth heist's page, restorations at \u00a77.6's page costs "
                    "with chapter 2 from Keeper level 6 and \u00a714.2's "
                    "experience, and tiers II and III for pages, Aether and the "
                    "Spire (G83); and what the device built and assigned "
                    "offline, confirmed on reconnection "
                    "(server/src/offline.mjs, <code>POST /v1/offline</code>): "
                    "made in order by the online rules, each confirmed or "
                    "refused on its own, a repeat confirmed and paid once, the "
                    "work counted from the server's confirmation; the device "
                    "keeps a build the network does not reach in its outbox "
                    "and shows it as confirming; and weaving "
                    "(server/src/weaving.mjs): §5.6's slots in each realm and "
                    "the crown's by the Spire, a restored law woven at its "
                    "Codex tier for 40 Aether a point of its own cost, working "
                    "after 10 minutes, 40 or 2 hours, a slot resting an hour "
                    "once emptied, crowned or in realms but never both; "
                    "production's law term (§9.3) and births drawn by the "
                    "laws woven (§11.5) read it, and it is confirmed offline "
                    "too. The terms that depend on a realm's other laws are "
                    "TD.14's, strain and upkeep TD.37's, and the load run does "
                    "not weave yet. Next: the builder publishing to the player's own "
                    "realms, with the wards, posts and pylons an island places "
                    "held to those built (today only its realm, realm level "
                    "and Vault are), the Keeper choosing which wards publish "
                    "when over the limit (G43), the builder locking the Heart at "
                    "realm level 3 as the server already does (G19), and the "
                    "Vault level and exposed loot derived from the owner's "
                    "ledger and buildings rather than read from the bundle, a "
                    "bundle that disagrees either way refused (D60); then workers "
                    "and production (\u00a79.3, \u00a75.8), "
                    "the roster (\u00a711.5), and the Codex's restorations."
                    "<br><br><strong>Screens v3 makes this the critical path</strong> "
                    "for six of stage SD's screen groups, in this order: the "
                    "builder publishing to the player's own realms (closes D60); "
                    "workers and production with an Aether ledger and storage caps; "
                    "the roster (characters, homes, rest, assign and recall, levels, "
                    "the starting five); pages and the Codex with restoration and "
                    "study, so a season tier grants pages rather than recording "
                    "them (D64); and weaving state per slot. There is no Insight "
                    "since v3.7 (\u00a79.1). The screens need "
                    "these slices as well: links at \u00a75.3's prices and limits; "
                    "births at a Nursery, paid in Essence (\u00a711.5), which the "
                    "Forms album reads; the Sage routes (the Sages, their roles, "
                    "and each Sage's level as the Keeper's, \u00a711.7); the "
                    "Lab's service (start, collect, "
                    "an outcome drawn from a stored seed, a <code>lab</code> "
                    "notification); and the defence log's routes (raids on the "
                    "player since a time, one raid, marking them seen), which the "
                    "shell's raid badge reads. Faults come with TD.37 and each "
                    "building's tile with TD.36.",
             gate="each slice named above on the server with its server tests: "
                  "the builder publishing to the player's realms, workers and "
                  "production with the Aether ledger and caps, the roster, pages "
                  "and the Codex, weaving state, links, births, the Sage "
                  "routes, the Lab's service and the defence log's routes; a "
                  "bundle whose Vault level or exposed loot disagrees with the "
                  "ledger refused; each slice moves completion's phase 4a row "
                  "it proves",
             evidence="server/test/universe.test.mjs; client/tests/universe_tests.gd, "
                      "through python3 client/status.py",
             register=["G42", "F56", "G43", "D60", "G45", "G19", "G82", "G83"]),
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
                    "phone can measure: \u00a721.3's frame budgets and \u00a724's one "
                    "frame-rate rule, as v3.7 writes C52's recommended option (60 "
                    "a second on the reference device and anything faster, never "
                    "below 30 on the oldest supported phone), and the 25 ms drag "
                    "budget measured touch to picture on the reference device "
                    "with a high-speed camera, one or two frames of prediction "
                    "allowed, touches read unbatched and late and the 3D frame "
                    "under about 8 ms; VoiceOver and TalkBack over the new "
                    "screens, local notifications and asking permission after the "
                    "third session (D68), the share clip's video encoder (TD.46), "
                    "and the platforms' age signals.",
             gate="+5.46 frontend points when the client runs on the device "
                  "matrix with \u00a724's frame rate and drag budget met as measured "
                  "above (a miss blocks release), and +5.46 when the launch fixes "
                  "are closed",
             blocked_by=["TC.3", "TD.48", "TD.28", "TD.30", "TD.18", "TD.19",
                         "TD.20", "TD.21", "TD.22", "TD.23", "TD.24", "TD.25",
                         "TD.26", "TD.41", "TD.43", "TD.44", "TD.45", "TD.46",
                         "TD.62", "TD.63", "TD.64", "TD.65", "TD.66", "TD.74"],
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
          "the rest.<br><br>"
          "<strong>v3.7 closed every decision this stage waited on</strong>, by "
          "rule rather than by asking: each item that waited on a choice takes the "
          "option its brief recommended, written where it belongs. So the owner's "
          "decision tasks (TD.29, TD.50 to TD.61 and TD.68) are done, no task here "
          "waits on an answer, and a task that was to build a pending value with "
          "the other one token away now builds the one v3.7 wrote. §23.5 lists every "
          "remaining departure of the designs with the rule the build follows.<br><br>"
          "<strong>§26.8 now plans this stage's work.</strong> v3.7 gives the home "
          "economy, the interface screens and the art pass phases of their own "
          "(4a, 4b and 4c): 4a is TC.12's server work, 4b is track D's screens and "
          "4c is track B's export and art. Its phase 1 names the crew as ruleborn "
          "from the manifest, with abilities, Sage powers and casts as commands, "
          "and the event log (TD.12, TD.13, TD.34); phase 4 all 39 features with "
          "moss and the buildings on their footprints (TD.15, TD.38, TD.36); phase "
          "5 the paradox-born, the visitors and every card's rule sheet (TD.33); "
          "and phase 6 the reference crews and the generator inside the simulation "
          "and universes of several realms (TD.16, T3.3). Track C also carries "
          "§12.17's alarm ladder and the measurements that rest on it (TD.69 to "
          "TD.71), the economy re-run's figures for the document (TD.72, then "
          "TD.73 for the owner), and the device's half of notifications and "
          "session telemetry (TD.74).<br><br>"
          "<strong>The screen gate</strong>, which every screen task below names: "
          "each §23.2 must-show for its rows present in every variant, with a test "
          "by name in <code>python3 client/status.py</code>; §21.1's sizes, "
          "§21.8's contrast and the layout check at 100%, 150% and 200% text, in "
          "both languages (<code>a11y_tests.gd</code>); every control named for a "
          "screen reader; and <code>tools/client_contract.py</code> clean.<br><br>"
          "<strong>Every screen and art task moves the frontend figure</strong>: "
          "completion reads §26.8's phases 4a, 4b and 4c (TD.47), each of the 21 "
          "phase 4b screens a deliverable that counts when its screen gate passes, "
          "and phase 4c's six art deliverables by TD.7's manifest. The figures "
          "fell once, when TD.47 added the phases: backend 89.24% to 62.36%, "
          "frontend 75.41% to 42.91%. Every task below keeps the client's tests "
          "passing, so no figure falls again.",
    tasks=[
        # -- Track A: the foundation ------------------------------------------
        dict(id="TD.1", owner="claude", status="done",
             title="Move the client to Godot 4.7.2 and godot-rust's 4.7 API",
             detail="v3.5 pinned Godot 4.7.2-stable with godot-rust v0.5.5 built "
                    "for the 4.7 API (§24, brief 39), and v3.7's §26.8 puts the "
                    "move in phase 0. <strong>Done.</strong> "
                    "<code>project.godot</code>'s feature is 4.7, "
                    "<code>build.sh</code> fetches 4.7.2-stable, "
                    "<code>compatibility_minimum</code> is 4.7, the extension "
                    "builds with <code>api-4-7</code>, and <code>export.sh</code> "
                    "takes the 4.7.2 templates. The one code change: 4.7 moved the "
                    "screen-reader live-region constants to "
                    "<code>AccessibilityServer</code>, so <code>ui.gd</code> names "
                    "it. Asked of 4.7.2's own class database, the contrast and "
                    "reduced-animation queries <code>settings.gd</code> makes are "
                    "still <code>DisplayServer</code>'s, so they stay. Android's "
                    "target SDK is left to the template: 4.7.2 passes "
                    "<code>gradle_build/target_sdk</code> only to a Gradle build, "
                    "which this preset does not use, so the API level 36 Play asks "
                    "for is the template's to meet and TC.3's to check on the "
                    "first APK. The documents that named 4.5 as the engine now say "
                    "4.7.2.",
             gate="100 of 100 client tests on 4.7.2, the five goldens agreeing at "
                  "every second, <code>export.sh check</code> compiling both phones, "
                  "gdlint clean, and none of the files above still naming 4.5 as "
                  "the engine",
             evidence="python3 client/status.py (100 of 100 on 4.7.2.stable); "
                      "bash client/export.sh check",
             register=["D76"]),
        dict(id="TD.2", owner="claude", status="ready",
             title="The tokens, §21.8's typefaces and surfaces, and the licence "
                   "ledger",
             detail="Screens v3 keeps its look in inline styles (852 colours, 402 "
                    "shadows), but underneath it is ten materials, one outline, "
                    "one hard drop shadow and a press that sinks 2 to 3 points. "
                    "<code>client/ui/tokens.json</code> takes them, each with its "
                    "source. v3.7 wrote the design's look into the document by "
                    "the recommended options of D89, D90, D91, D97 and D98, so "
                    "each token carries one value, the document's, and none sits "
                    "one token from another: §21.2's colours (which the design "
                    "matches exactly) with §21.8's two surface families (TD.3), "
                    "§21.8's 13-point floor, contrast and motion, and §21.8's "
                    "typefaces, which are now the design's: Manrope for labels, "
                    "body text and numbers, with tabular figures on every number "
                    "that changes; Lilita One, which has none, for large numbers "
                    "that do not change and some titles; Marcellus for titles and "
                    "law names; a weight of 900 drawn at 800. All three are SIL "
                    "OFL; §21.11's licence ledger, with the three faces as its "
                    "first entries and their licence texts on Settings' legal "
                    "page, does not exist yet and is written here. The frame "
                    "stays at 360 points and the 390-point design is reflowed "
                    "onto it, never scaled down, as v3.7's §21.1 now says (D98): "
                    "scaled, it would draw 13-pt text at 12 real points on 360-dp "
                    "phones. Each school's tokens are §21.2's main colour and "
                    "shadow tint, which the design's school table matches "
                    "(screens_main.js:2-8); the handoff's four-stop ramps "
                    "(README.md:109-114) stay inside the icon export (TD.5). The "
                    "notes get a token set of their own from §8.1's wheel, which "
                    "Weaving and the Harmony view both read in place of the "
                    "designs' two palettes (screens_meta.js:431, "
                    "screens_main.js:367; D97).",
             gate="every client test passes unchanged; the tokens validator "
                  "refuses a value with no source; the layout checks pass in "
                  "Manrope, Lilita One and Marcellus at 100%, 150% and 200% "
                  "text in both languages; every number that changes is set "
                  "with tabular figures (a test); the licence ledger lists each "
                  "shipped face with its licence",
             blocked_by=["TD.1"],
             register=["D90", "D91", "D97", "D98"]),
        dict(id="TD.3", owner="claude", status="blocked",
             title="Materials and components, and checks that read what words sit on",
             detail="Gold, leather, red, green, violet secondary and round "
                    "buttons, sheets, chips, pills, segmented controls, portrait "
                    "tiles, banners and cards (the handoff's SCREENS.md:179 adds "
                    "the violet button, the segmented control and the pill), "
                    "drawn by one rounded-box "
                    "shader (gradients, rims and hard drops are beyond "
                    "StyleBoxFlat) under the names <code>scripts/ui.gd</code> "
                    "already gives, so screens change in one place. They move "
                    "with TD.4's helper and draw TD.5's icons, so both come first "
                    "and every screen inherits them. The surfaces are v3.7's "
                    "§21.8, D89's recommended option: a dark family (a violet card "
                    "from #261A4C to #1A1134, dark glass at 78% for pills over the "
                    "world, leather for buttons, light text #F3EEFF) and a "
                    "parchment family (#FFFBF0 to #F1E3C4 with brown ink "
                    "#2A1A10), each outlined in ink #1A0C14; menus on the night "
                    "backdrop; and a high-contrast variant with opaque cards, "
                    "3-point outlines, secondary text raised to primary and no "
                    "glass. <code>UI.panel</code>'s 85% paper panel goes. 28% of "
                    "the design's 1,049 text runs fail §21.8's 4.5:1 or the "
                    "perceptual check, mostly white numbers on light badges and "
                    "violet secondary text; the components keep the look and fix "
                    "the words by §21.8's rules as v3.7 wrote them (G59's "
                    "recommended option): a word with an ink outline all round, "
                    "at least 1.5 points or 12% of its size wide, is measured "
                    "against the outline and a drop shadow never counts; other "
                    "words against the worst point behind them; secondary and "
                    "tertiary text on dark no darker than #B8A8D8, tertiary bold, "
                    "no opacity on words, and a law's title on a light school "
                    "colour on a plate. G59 measured #B8A8D8 at Lc 57 to 59, so "
                    "where the perceptual check fails at 13 points the token is "
                    "lifted toward #D8CCF2, which “no darker than” allows. On "
                    "dark, red words are #FF9AAA and success words #3FBF7F, both "
                    "bold; on parchment they are #9A1B32 and #155A38, bold; alarm "
                    "text sits on #B3203A (F58, D72). The accessibility checks learn "
                    "the colour each word actually sits on, gradients and "
                    "outlines included.",
             gate="§21.1's sizes and §21.8's 4.5:1 and perceptual checks at 100%, "
                  "150% and 200% text, in both languages, on both surface "
                  "families and the high-contrast variant, with the HUD over the "
                  "day, dusk and night skies; an outlined word measured against "
                  "its outline and a drop shadow never counted "
                  "(<code>a11y_tests.gd</code>)",
             blocked_by=["TD.2", "TD.4", "TD.5"],
             register=["D72", "G59", "F58", "D89", "D91"]),
        dict(id="TD.4", owner="claude", status="blocked",
             title="Motion, with reduced motion that reaches everything",
             detail="The design has 86 keyframe animations, eight of them named "
                    "twice, running 300 to 550 ms with overshoot, and its "
                    "reduced-motion switch is read by nothing. v3.7's §21.8 keeps "
                    "the designs' movements and times them to 150 to 250 ms, "
                    "easing out, without overshoot (D91's recommended option). "
                    "One helper plays every movement at those timings and "
                    "<code>UI.motion_ms</code>'s rule applies to all of it; "
                    "reduced motion gives every animation a reduced form and keeps "
                    "one particle, a reward landing in its counter (§20.8); a "
                    "notice that carries information is a banner that stays until "
                    "dismissed when the player chooses, never a toast that clears "
                    "itself (§21.8); and a lint rule refuses a tween made anywhere "
                    "else.",
             gate="the lint rule finds no tween outside the helper; with reduced "
                  "motion on, every animation plays its reduced form and the only "
                  "particle left is a reward landing in its counter (a test); "
                  "every interface movement inside §21.8's 150 to 250 ms with no "
                  "overshoot (a test)",
             blocked_by=["TD.2"],
             register=["D91"]),
        dict(id="TD.5", owner="claude", status="ready",
             title="The icons: 393 designed, exported once, imported on 4.7.2",
             detail="Four sources: <code>icons_rbi.js</code> (360 in 31 groups), "
                    "the school and law icons, the diorama's marks, and inline "
                    "ones, exported as 444 SVGs (done once already, in the "
                    "analysis). v3.7's §21.8 takes the designs' finish (D91's "
                    "recommended option): rounded shapes with a 2-point outline on "
                    "a 24-point grid, finished with a three-stop gradient, a gloss "
                    "and a soft drop shadow. So the glossed set is the one "
                    "exported, and the flat one (DS-3) is dropped. It uses masks, "
                    "filters and system-font text Godot's importer may not handle, "
                    "so it is rasterised in Chromium at the sizes used, with a "
                    "manifest, <code>UI.icon()</code> and a test that every name a "
                    "screen uses exists. The school marks keep Matter's cube "
                    "edges. One set of seven school marks, the design's six "
                    "(<code>RBIcons.school</code>) and the Heart's circle (§5.2), "
                    "draws every school mark: law cards, the icon sheet, pylons "
                    "and portrait rings (the analysis's design-system.md, section "
                    "4.4), in one set of school colours with no palette switch "
                    "(§20.8). A law icon's frame is its school's shape and never "
                    "another (§21.8): 21 of the 48 law icons are framed in a shape "
                    "that is not their school's and are re-framed in it on export. "
                    "§21.9 now counts about 390 icons and 29 screens, the Hatch "
                    "screen among them (C11); the manifest counts what the screens "
                    "use.",
             gate="every icon name a screen uses exists (the test); every icon "
                  "on the 24-point grid with its 2-point outline, read from the "
                  "exported SVGs; every law icon framed in its school's shape, "
                  "and every school-coloured mark a screen draws from the "
                  "seven-mark set (checks)",
             blocked_by=["TD.1"],
             register=["D91", "C11"]),
        dict(id="TD.6", owner="claude", status="blocked",
             title="The shell: one persistent scene, its chrome, the HUD and the world",
             detail="Today the router swaps whole scenes, so no chrome and no 3D "
                    "world can persist between screens. The shell keeps the World, "
                    "the content, the chrome (top HUD, side alerts, tab bar, back "
                    "header) and the overlay, configured per route; headless "
                    "presenters give the HUD's bars from the server's caps "
                    "(TC.12), the badges from real state (the raid badge from "
                    "TC.12's defence-log route) and the nearest goal (§14.8). The "
                    "chrome is the designs' arrangement held to §21.1's measured "
                    "rules, as v3.7's §21.8 writes it (C44's recommended option): "
                    "Keeper level and Renown at the top left, strain at the top "
                    "right, resources with storage bars beneath, side buttons down "
                    "both edges, and the nearest goal above five tabs with the "
                    "Heist in the centre; building, weaving and terrain open from "
                    "the realm view. The design's chrome sits in the top band and "
                    "the corners, where §21.1's reach rule and the layout check "
                    "fail it, so its controls grow to 48-point hit areas (the "
                    "design's 44 px side buttons and 36 px hub tabs), the "
                    "five tabs sit inside the safe area and clear of the corners, "
                    "a sub-screen's back control moves to the lower band at 48 "
                    "points (not the design's 44 px or the handoff's 40 by 40 top "
                    "left), and nothing interactive sits in a corner. The layout "
                    "check splits frequent controls from the rest, as §21.1 now "
                    "does (<code>client/tests/run.gd</code>). Portrait only, as "
                    "every screen but the heist and its result: their landscape is "
                    "TD.28's. One World "
                    "sits under the shell in a SubViewport behind the content, "
                    "switched by mode (universe, plan, realm, heist, scout) and "
                    "never rebuilt, and taps the interface does not take pass to "
                    "it; it serves 14 screens (the analysis's numbering): 01 "
                    "Universe map, 02 Heist, 04 Realm view, 06 Heist planner, 07 "
                    "Heist result, 09 Scout report, 15 Defence curation, 16 "
                    "Rehearsal and defence log, 18 Shop, 21 First launch, 22 "
                    "Terrain editor, 23 Landing picker, 24 Harmony view and 27 "
                    "Share sheet, not the handoff's SubViewport per screen "
                    "(SCREENS.md:178). The tabs open their route groups, and the "
                    "Crew and Laws hubs are a segmented control whose segments are "
                    "§21.1's primary controls (SCREENS.md:5). The shell's state "
                    "lives in TC.1's store, not in autoloads (README.md:161). "
                    "Screen changes play through TD.4's helper, not at the "
                    "handoff's 0.3 s (D91). A banner or toast never covers a live "
                    "control: the design's raid banner on home covers Collect.",
             gate="a flow test per route; the layout check in portrait, in both "
                  "languages, at 100%, 150% and 200% text, with every frequent "
                  "control at 48 points, inside the safe area and out of the "
                  "corners; each badge read from a store slice, with a "
                  "presenter test; the same World across every route change (a "
                  "test); the layout check fails any control whose centre a "
                  "banner or toast covers",
             blocked_by=["TD.3", "TC.12"],
             register=["C44", "D91"]),
        dict(id="TD.67", owner="claude", status="blocked",
             title="Sound and haptics on §21.8",
             detail="The client plays no sound. TC.4 built §21.8's four haptic "
                    "patterns (<code>client/app/haptics.gd</code>) and the three "
                    "volumes, and nothing plays through them yet. One audio "
                    "service on buses for music, effects and alerts, at TC.4's "
                    "volumes, with music and ambience players; the design's ten "
                    "interface cues (tap, tick, select, collect, place, rotate, "
                    "whoosh, error, pick, open; realm-diorama.js's "
                    "<code>SFX</code>) as placeholders, with the "
                    "<code>levelup</code> it calls and never defines "
                    "(RulebornMeta.dc.html:907) added; and one cue table, "
                    "following §21.8's school instruments and signatures, that "
                    "names each cue's sound, its haptic pattern and its visual "
                    "form, as the handoff asks (README.md:151). §21.9's audio rows "
                    "stay counted by TD.7's manifest and TD.32's gate.",
             gate="every cue and alarm in the table has a haptic and a visual "
                  "form (§20.8), and a test fails one without either; each of "
                  "§21.8's four patterns plays from its cue by name; with "
                  "haptics off no pattern plays, and a volume at zero silences "
                  "its bus (tests)",
             blocked_by=["TD.3", "TC.4"],
             register=[]),
        # -- Track B: the 3D world ---------------------------------------------
        dict(id="TD.7", owner="claude", status="ready",
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
                    "<code>EXT_mesh_gpu_instancing</code>, which 4.5 refused. "
                    "The clips are named by each module's <code>CLIPS</code> keys, "
                    "listed per kind in the manifest, and the clip check maps "
                    "§21.6's animation set onto them (the kit's <code>ko</code> is "
                    "knocked out; the Archivist has a set of its own, "
                    "archivist-rig.js:90); each <code>EXPR</code> pose exports as "
                    "a one-frame clip named <code>expr_&lt;key&gt;</code>. Sampling "
                    "at 30 fps bakes every moving node's position, rotation and "
                    "scale (the analysis's 3d-pipeline.md, section 4.1). The handoff's "
                    "export notes are wrong in three places (CHARACTERS.md:83-98): "
                    "<code>apply(clipName, t)</code> does not exist (the rig has "
                    "<code>play</code> and <code>set</code>), no module has morph "
                    "targets, and <code>play(\"caught\")</code> names an "
                    "expression. Its six .bin files are body-only meshing caches "
                    "and are never imported; the harness's first check meshes "
                    "Featherkin at .0078, Mossbear at .009 and the Archivist's hero "
                    "at .0072 and reproduces their 80,828, 134,174 and 164,298 "
                    "triangles. Skyskipper's game mesh differs from its code "
                    "(65,054 triangles against 66,668), and the code is the source. "
                    "Each kind is imported at §21.6's height, one tile to the metre "
                    "(§21.1), not at the handoff's “about 1.2 grid tiles” "
                    "(CHARACTERS.md:100) or the Rig pages' scales. The budgets "
                    "are v3.7's §21.3 (D93's recommended option): characters "
                    "3,000 to 6,000 triangles, the Character screen using the same "
                    "model; buildings 2,000 to 8,000; a realm 25,000 to 40,000 on "
                    "the home camera and up to about 60,000 in a heist; under 150 "
                    "draw calls; each held in the export with capped segments, a "
                    "sculpt step per kind and accessories merged into the skin. "
                    "The manifest lists every handoff image with its fate: the "
                    "portraits, land/, scout/ and obs/ are re-rendered in "
                    "§21.3's one toon look (TD.8; TD.11 for the portraits); the "
                    "six top-level world/*.png are screenshots of earlier screens "
                    "and are not imported. v3.7's §26.8 costs this harness and "
                    "what its manifest lists as phase 4c, the art pass (G61).",
             gate="every asset inside v3.7's §21.3 budgets, a heist's realm with "
                  "its crew, a guard on every post and a worker at every producer "
                  "under about 60,000 triangles; every asset with a stated height (§21.6's "
                  "eighteen kinds from TD.33's tables, §21.1's Sages at about "
                  "1.5) within 5% of it, the rest listed in the manifest as "
                  "unbudgeted; re-exported byte for byte; the first check "
                  "reproduces the three bins' triangle counts; every clip named "
                  "by its module's key, and every handoff image listed with its "
                  "fate",
             blocked_by=["TD.1", "TD.33"],
             register=["G61", "D93", "D92"]),
        dict(id="TD.8", owner="claude", status="blocked",
             title="One toon look for everything",
             detail="The diorama is a four-step toon with world-space hulls; the "
                    "characters are physically based with clearcoat, sheen and "
                    "transmission under ACES, and the portraits are renders of "
                    "that. v3.7's §21.3 writes one toon look for everything, "
                    "characters included (D92's recommended option): the designs' "
                    "diorama ramp of four steps with its 10% extra saturation, "
                    "shadows tinted toward violet, a soft rim light, and 1.5-pixel "
                    "ink outlines (#1A0C14) drawn in screen space, so a far line "
                    "is as thick as a near one; no physically based material, and "
                    "portraits rendered from the imported models in this look. "
                    "One shader kit on that rule: the screen-space outline, water "
                    "and lava, sky by local time in every realm and on the "
                    "universe map (§21.2), glows, the ghost, and the Hush, Spark "
                    "and Echo variants, assigned to every imported model on "
                    "import. The handoff's outline-off characters "
                    "(CHARACTERS.md:99) and the world-space shells are not built.",
             gate="every imported model carries the kit's material, checked on "
                  "import; a still of each variant against a golden on a GPU "
                  "runner; an outline measured 1.5 pixels at the near and the far "
                  "edge of a view (a test)",
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
                    "the roster with the crew (TD.34). v3.7's §24.8 writes it: "
                    "each posted guard's kind, form and level ride in the bundle, "
                    "checked against the owner's roster, and outfits travel beside "
                    "it as view data; the crew's outfits beside the replay, which "
                    "§24.8 does not name, are kept as view data the same way "
                    "(G60).",
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
                    "readers and as the fallback. One island generator serves "
                    "every mode (the handoff's README.md:176). Models load on a "
                    "worker thread and are instanced a few a frame behind a "
                    "loading state, so filling a view drops no frame "
                    "(README.md:152; TC.8 measures it on the reference device). "
                    "Animation choice calls TD.7's clip keys. The camera is "
                    "§21.1's, which v3.7 makes a rule and not a look the designs "
                    "replace (D75's recommended option): orthographic at a 35° "
                    "pitch, turned in 90° steps, with three zoom levels; the "
                    "designs' round rock stays as art around §5.2's square grid.",
             gate="every actor's world position equals its tile; a still of each "
                  "mode against a golden on a GPU runner; no frame over §24's "
                  "60-a-second budget on the GPU runner while a view fills",
             blocked_by=["TD.8", "TD.9", "TD.31", "TD.36"],
             register=["G45", "D74", "D75"]),
        dict(id="TD.11", owner="claude", status="blocked",
             title="Characters in full: forms, guards, role accessories",
             detail="No model has the guard form the sheets label (its sash and "
                    "lantern are a caption), and a form changes colour and glow "
                    "only, which §21.6 calls a failed form. Each note gets an "
                    "accessory and a pattern per size band; guards get the sash "
                    "and lantern and §21.6's role accessories so a guard's role "
                    "reads at a glance (§12.8); the guard form is the sash and "
                    "lantern on the kind's own body; a form changes pattern, glow "
                    "and accessory; the knockout draws dizzy stars; facets, beaks "
                    "and manes have rounded tips; an illusion vanishes when "
                    "touched; and a Swarmling takes its source guard's role and "
                    "accessory (§23.5's rows, D94). Springs; portraits re-rendered "
                    "in TD.8's look. The sheets' variants for visitors, anomalies "
                    "and law creatures are kept, if at all, as a tint that changes "
                    "nothing (§23.5, D95). Every kind gets a socket for the "
                    "visiting Stray's bundle on a stick (§11.8, §21.6). The "
                    "Sparkwright's lenses and the shared work loops are TD.62's. "
                    "With the character artist (§26.3).",
             gate="every form and guard in TD.7's manifest carries its accessory "
                  "and pattern, read by a test; each guard role tells apart under "
                  "§21.10's grayscale test; every kind has the bundle socket; "
                  "every portrait rendered from an imported model",
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
                    "loop where §21.6 asks for three (the Star Well, the Aether "
                    "Spring and the Garden: TD.62), and no knock-out "
                    "petals. Verdant's sheet is the Flock's puffball with two bees "
                    "(puffbee.js; the handoff's CHARACTERS.md:78), and §5.7 gives "
                    "puffballs to the Flock alone, so Verdant keeps the bees, "
                    "drops the puffball and gains butterflies. Wildlife is drawn "
                    "in its realm as §5.7 lists it; the owner's removal of "
                    "jellyfish, kites and the compass (README.md:181) applies to "
                    "the universe map's background only. The "
                    "Chronicler's and the Lamplighter's looks and the wildlife's "
                    "counts and ranges are the sheets', adopted under §23.5's "
                    "rule (G65). With the character artist (§26.3), once TD.30 "
                    "has settled the style, as §26.2 orders it.",
             gate="TD.7's manifest lists no §21.9 row as still to make",
             blocked_by=["TD.30"],
             register=["C24", "G65"]),
        dict(id="TD.62", owner="claude", status="blocked",
             title="The Sparkwright's lenses and satchel, and three work loops",
             detail="§11.11, §21.6 and §23.5 disagreed on the Sparkwright's "
                    "goggles and on how many animations each kind has (C54). v3.7 "
                    "settled it by the recommended option: round copper tinker's "
                    "lenses, never a Scout's strapped goggles, and a Mender's "
                    "satchel of leaves wound with copper coils (§11.11, §21.6); "
                    "and seventeen animations for every kind, fourteen shared "
                    "clips and a work loop at each of the Star Well, the Aether "
                    "Spring and the Garden, the three buildings that take workers "
                    "(§21.6, §23.5). TD.7's export and TD.11's characters take "
                    "it: the satchel node on the Sparkwright in place of the "
                    "sheet's goggles and tool belt, and the three loops in the "
                    "export's shared clip set.",
             gate="the clip check counts seventeen clips for every kind; the "
                  "Sparkwright exported with the lenses and the satchel, inside "
                  "§21.3's budget",
             blocked_by=["TD.11"],
             register=["C54"]),
        # -- Track C: what the screens stand on ----------------------------
        dict(id="TD.33", owner="claude", status="done",
             title="Content the screens and the 3D read: paradox-born, visitors, "
                   "§11.11's rule sheet and §21.6's heights",
             detail="<strong>Done.</strong> <code>tools/extract_content.py</code> "
                    "now writes <code>content/paradox_born.json</code> from §11.8's "
                    "two tables (no forms, G62; the Twinned's 120 health and 80 "
                    "carry one body's shared pools, C53) and "
                    "<code>content/visitors.json</code> (the Stray one of the "
                    "eighteen kinds, never a nineteenth); every card in "
                    "<code>ruleborn.json</code> carries §11.11's rule sheet and "
                    "§21.6's body, height, colours and signature, so §23.5's "
                    "“every card carries all of 11.11, word for word” is generated; "
                    "<code>sages.json</code> carries §11.7's table of what each "
                    "launch Sage gains at every fifth level (G52), which the old "
                    "extractor had swallowed into the last Sage's text; and every "
                    "launch law in <code>laws.json</code> its Codex chapter, §7.6's "
                    "twelve of chapter 1, two of each school with the three "
                    "starting laws among them (G49). Re-extracting also brought "
                    "<code>eras.json</code> up to v3.7's “On the sheet” rules, which "
                    "it had missed. <code>tools/validate_content.py</code> checks "
                    "them all (no nineteenth kind, forms still 54, no paradox-born "
                    "better than a role in every number, the chapters), and "
                    "<code>tools/check_document.py</code> now counts §26.1's "
                    "“Visitors, paradox-born, anomalies” row as 3, 3, none. "
                    "<code>tools/compare_module.py</code> compares the prototype's "
                    "data module with content/ as text, after checking its hash: "
                    "its only differences are the three role healths §23.5 already "
                    "lists, and it holds no realms, links, crew or Sages "
                    "(<code>docs/analysis/screens-v3/handoff/module.md</code>). "
                    "What could not be done: §23.5 adopts the paradox-born's "
                    "personality, home habit, best at and signature and the "
                    "visitors' and anomalies' sizes from the sheets, and no section "
                    "writes them, so content/ cannot carry them; the edits are "
                    "drafted (G79, TD.75).",
             gate="<code>python3 tools/validate_content.py</code> passes with the "
                  "new tables; re-extraction reproduces them byte for byte; "
                  "<code>tools/check_document.py</code> counts the paradox-born and "
                  "visitors; <code>tools/compare_module.py</code> lists every "
                  "difference as a §23.5 row or a register item",
             register=["G63", "G65", "G79"]),
        dict(id="TD.12", owner="claude", status="doing",
             title="Abilities, Sage powers and casts in the simulation",
             detail="<strong>Built so far:</strong> §12.5's crew manifest in the "
                    "replay (<code>RBH3</code>: each member's kind, form, level "
                    "and traits, the Sage and the casts), recorded and "
                    "re-simulated by the server; each member played by its kind's "
                    "role, size band and ability, so Density's small band plays "
                    "for a small kind (G23); the Ability command with §12.6's two "
                    "uses, ten-second lockout and four-ready rule; and fifteen of "
                    "the eighteen abilities, each tested, their numbers held to "
                    "<code>content/ruleborn.json</code> by "
                    "<code>sim/content_gate.py</code>: the Stormhound's sprint, the "
                    "Skyskipper's satchel, the Tidewalker unhindered, the "
                    "Quarryback's pound, the Emberling's burst, the Hourkeeper's "
                    "rewind, the Stillwatch's freeze, the Mossbear's root, the "
                    "Bloomling's heal, the Echoplate standing over the crew and "
                    "the Soulmender's link, the Sparkwright's cut to the Sage's "
                    "cooldown, and, over §6.2's gaps, the Featherkin's glide, the "
                    "Rambler's charge (breaking the first hedge, boulder or "
                    "Crystal Wall) and the Rootrunner's root bridge; the Glass "
                    "golem's wall, which stops feet and not eyes, a walk meeting it "
                    "waiting at it; and the Lantern wisp's reveal, drawn and not "
                    "simulated (§7.3). The Sage "
                    "comes with the manifest: the Sage command (13 on the wire), "
                    "each power's uses, the one twenty-second cooldown, and ten "
                    "of §11.7's twelve powers — Suspend, Reveal, Recall, Invert "
                    "(a law's factors turned over, the rest of it off), Jam, "
                    "Plank, Vine bridge (the two banks of a gap), Renew, Decoy and "
                    "Tailwind. Completion's row reads 29 of its 33 parts. What the "
                    "document leaves open about them is G77 and G81. "
                    "<strong>Left:</strong> the Prism mite's split, which needs a "
                    "crew member that can be two; Copy and casts, which need a "
                    "law that applies around a place rather than over the realm; "
                    "Rift, on universes of several realms (D71); casts paid by "
                    "the server only if used; the harness's decision count."
                    "<br><br>"
                    "The simulation had twelve command kinds and none was an "
                    "ability, a Sage power or a cast, and its crew were five roles "
                    "with no characters (G67, TD.47). v3.7 wrote G47's and G51's recommended options, "
                    "and §26.8's phase 1 now names this work: crews as ruleborn "
                    "from the manifest, with the eighteen abilities, Sage powers "
                    "and casts as commands (§12.5, §12.7). The work: Ability, Sage "
                    "and Cast commands in the free values, each carrying its "
                    "target tile or entity (a cast's circle centre, Suspend's "
                    "law), since §12.7 lets each be aimed; a crew stat not keyed "
                    "by role (G63), with each member's size its kind's (§11.2, "
                    "§12.21) and not its role's, which today makes the Warden the "
                    "only large character so Density's small band never plays "
                    "(<code>Role::size</code>, G23); §12.5's crew manifest in the "
                    "lease and the replay (each member's kind, form, level and "
                    "traits, the Sage and the casts carried), played here by kind "
                    "and form; the eighteen abilities as named-parameter changes "
                    "with two uses and the ten-second lockout; the four Sages' "
                    "powers at level 1; casts as four-tile circles, debited by the "
                    "server at validation only if used (§12.5, §24.12), with §13's "
                    "page to the defender for a law cast in a foiled heist (G31); "
                    "and §12.6's four-ready rule. Levels, traits, rest and the "
                    "server's roster check are TD.34's, and the paradox-born "
                    "TD.35's. The goldens are regenerated and the harness's "
                    "decision count re-measured.",
             gate="the harness's median run at the matched depth carries 15 to 25 "
                  "decisions, abilities, Sage powers and casts counted (§12.6, "
                  "§19.27); if it does not, §12.6's fallback is applied and "
                  "recorded (each ability to one use, then the matchmaker's depth "
                  "centre down one realm at a time); a Density test in which a "
                  "small kind takes the small band whatever its role; a cast "
                  "carried and not used costs nothing (a server test); the "
                  "goldens regenerated and agreeing",
             register=["G47", "G63", "G67", "G23", "G77"]),
        dict(id="TD.34", owner="claude", status="blocked",
             title="The crew's levels, traits and rest, checked against the roster",
             detail="The manifest's levels and traits, each member's rest after a "
                    "heist (§12.9), and the server checking the manifest and the "
                    "posted guards (TD.9) against the roster it holds, each "
                    "posted guard's level carried in the island bundle beside "
                    "its kind and form (§24.8). v3.7 wrote G51's recommended "
                    "option, so a server-checked heist models them, by §11.4 to "
                    "§11.6's rules: each level adds 8% health and power and 5% "
                    "carry, compounding, and grows an ability's duration, or its "
                    "reach where it has none (§11.4); a character's highest level "
                    "is twice its home Hearth's, the Spire's three places counting "
                    "as a home at the Spire's level, with moves between free "
                    "places at no cost (§11.4); rest multiplies the outcome's rest "
                    "by (1 − 0.05 × Hearth level) and each trait's factor, the "
                    "server setting it (§11.6); and one-tap reassign sends a "
                    "character to the first unstaffed producer in §14.1's order. "
                    "A Sage's level is the Keeper's, every fifth level improving "
                    "one power as §11.7's table names, never the 20-second "
                    "cooldown (G52, C49). v3.7 leaves one thing unclear: a Spire "
                    "home at level 6 to 10 would allow levels 12 to 20, past the "
                    "10 that §9.5 prices and the Hearth's top row gives, and what "
                    "it cuts from rest is unstated. That is the register's (G51); "
                    "the build holds a level to 10 until the document says. It needs TC.12's "
                    "roster. The Roster's and Character's numbers are shown as the "
                    "heist's only once this lands.",
             # Built, the server's half: a heist names its crew from the
             # roster at submission, checked against the manifest's kinds,
             # levels and traits and refused for one not held or resting;
             # each rests by its own outcome (the verdict's out mask), its
             # Hearth and its traits, off work meanwhile, and wakes early for
             # Essence. Left: the simulation playing levels and traits, the
             # posted guards against the roster, and the Sage's levels.
             gate="a lease refused for a crew member the roster does not hold or "
                  "one still resting (server tests); one simulation test each "
                  "for growth, the level cap, rest and a Sage's fifth-level "
                  "improvement; the goldens agreeing",
             blocked_by=["TD.12", "TC.12"],
             register=["G51", "G60", "G52"]),
        dict(id="TD.35", owner="claude", status="blocked",
             title="Paradox-born in the simulation",
             detail="A paradox-born has no role (§11.8), and the simulation keys "
                    "every crew stat to one. On TD.12's stat type and TD.33's "
                    "table, the Reverser's and the Unmade's gifts join a crew by "
                    "their rule-sheet lines (§11.8). v3.7 wrote C53's and G62's "
                    "recommended options: the Twinned is one character in the "
                    "simulation, with one position and the shared 120 health and "
                    "80 carry, and every hit it lands and every load it takes "
                    "counts twice (Damage ×2 and Loot load rate ×2, for itself, "
                    "always), its crew's abilities once; its second silhouette is "
                    "drawn only. Paradox-born never stand on a Guardian Post and "
                    "have no forms: the server refuses one on a post and the guard "
                    "picker leaves them out.",
             gate="a simulation test for each paradox-born gift as §11.8 writes "
                  "it; a bundle with a paradox-born on a post refused (a server "
                  "test); the goldens agreeing",
             blocked_by=["TD.12", "TD.33"],
             register=["C53", "G62"]),
        dict(id="TD.13", owner="claude", status="done",
             title="The simulation's event log",
             detail="<strong>Done.</strong> <code>sim/src/events.rs</code> keeps "
                    "the log beside the replay and outside the checksum, the five "
                    "goldens unchanged with it on: every guard state change with "
                    "its cause (the crew member seen, a Glare, a sound, a spread "
                    "alert, a lure, the alarm, the table), knockouts on both sides "
                    "with what did them, every way back up, captures by knockdown "
                    "and by the clock, boardings with their loot, alarm levels "
                    "with their cause, level 5's Warden, wards fired, pylons, the "
                    "Vault, a law suspended, abilities and Sage powers used, and "
                    "every crew member's position once a second; sixteen tests, "
                    "one for each kind. §12.13's decisive moment is chosen from it "
                    "by rule (<code>Log::moment</code>), and every golden heist "
                    "has one. Bells, the defender's guardian Sage and faults are "
                    "logged once they exist (TD.15, TD.21, TD.37); the server's "
                    "heatmaps and the result screen read it in D65's and TD.17's "
                    "work.<br><br>"
                    "Outside the checksum, kept beside the replay (§24.10): guard "
                    "state changes with their cause (sightings and alerts), "
                    "knockouts and revivals, captures, escapes and boarding, alarm "
                    "levels and their cause, wards fired, bells rung, guardian "
                    "Sage powers, pylons, the Vault opening, law blinks, and every "
                    "crew member's position once a second, which §24.3's route, "
                    "detection and failure heatmaps read (D65). The result's "
                    "decisive moment, chosen by §12.13's rule now that v3.7 wrote "
                    "G48's recommended option, the heist's haptics and words, "
                    "§13.2's report facts (denied, held, seen, fired: G57), "
                    "Profile's facts and the share clip all read it. §26.8's "
                    "phase 1 names it.",
             gate="a named simulation test for each event kind; positions logged "
                  "once a second for every crew member; the five goldens' "
                  "checksums unchanged with the log on",
             register=["D65", "G48", "G57"]),
        dict(id="TD.36", owner="claude", status="doing",
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
                    "(§24.11). v3.7's §26.8 puts it in phase 4, the island "
                    "builder. <strong>Built:</strong> the island's buildings list "
                    "after its laws (none written for none, so every earlier "
                    "island keeps its hash), the Spire 3 by 3 and the rest 2 by "
                    "2, blocking feet and eyes on every footprint tile; the "
                    "table in the rules version and the goldens re-recorded; the "
                    "extension placing and reading them; the server storing each "
                    "building's tile, moving it free, and refusing an island "
                    "whose buildings are not the realm's placed ones on their "
                    "tiles. <strong>Left:</strong> the Vault's 3 by 3, which "
                    "moves every heist and the hold table measured on its one "
                    "tile, and the builder's and realm view's screens drawing "
                    "them (TD.31, TD.19).",
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
                    "carried in each realm's bundle (D61): each law's cost, the "
                    "universe's capacity and strain, and harmonies and clashes "
                    "within a realm. v3.7 wrote C48's recommended option, so one "
                    "reading is built and no switch: a harmony counts once per "
                    "shared note, so three laws on one note each pay 0.85 once and "
                    "two laws sharing two notes pay it twice, and a crown law is "
                    "priced once, by the Heart's laws and its own crowning (§5.5, "
                    "§8.2). An era's discounts are priced in the same function: "
                    "Heavy Stars' 30% off Motion laws and High Tide's free Slow "
                    "rivers (§18.3, D69). Upkeep, Breaking, faults and the server's "
                    "refusal are TD.37's. Strain and its seven bands (§5.5) belong "
                    "to the universe, not four bands to each realm as the "
                    "handoff's state has them (README.md:163).",
             gate="the client's and the server's prices equal the simulation's for "
                  "every launch law alone and in every pair in one realm, and with "
                  "each era's discount (a test on each side); a harmony counted "
                  "once per shared note (a test)",
             register=["D61", "C48"]),
        dict(id="TD.37", owner="claude", status="blocked",
             title="Stability's rules: upkeep, Breaking, tier rises, recommendations and faults",
             detail="v3.7 wrote C48's and G46's recommended options, so each rule "
                    "is now the document's. Upkeep is a share of each realm's own "
                    "hourly Aether production: 25% when the universe's capacity is "
                    "fully used, in proportion to the share used (the woven laws' "
                    "cost ÷ capacity, chord draws not charged), with no stability "
                    "budget of a realm's own (§5.6, §29.1). A weave that would take "
                    "strain into Breaking is refused, a tier rise re-prices a woven "
                    "law in place, and Weaving ranks its two or three recommended "
                    "laws with their comparison (C48). Faults: a fault joins an "
                    "outer realm to the Heart, the first from the outer realm whose "
                    "shortest route to the Heart is longest, ties by the order the "
                    "realms opened; one at Strained, two from 110%, three from "
                    "118%, and at Breaking four, or one per outer realm if fewer "
                    "(§5.4, §5.5); a target's strain and open faults are free "
                    "facts (§12.4) and the landing picker offers each fault "
                    "(TD.18). Each rule is built in TD.14's function and on the "
                    "server, which also refuses to publish a chord the universe's "
                    "stability cannot pay (D61), from the weaving state TC.12 holds; "
                    "home's fault marker is drawn on TD.19's view.",
             gate="a test for each rule as §5.4 to §5.6 state it, the same on the "
                  "client and the server; the faults a universe opens worked out "
                  "from the universe alone; an unpayable chord refused at "
                  "publishing (a server test)",
             blocked_by=["TD.14", "TC.12"],
             register=["C48", "G46", "D61"]),
        dict(id="TD.15", owner="claude", status="doing",
             title="Terrain in the simulation: the missing features, moss, heights",
             detail="<strong>Built so far:</strong> all thirty-nine of §6.2's "
                    "features and moss, each with a test and its numbers "
                    "held to <code>content/terrain.json</code> by "
                    "<code>sim/content_gate.py</code>. The first slice: the hedge (cut "
                    "through in 3 s), tree, boulder (a Breaker smashes it in 6 s), "
                    "statue, crystal outcrop, lava crack, stream, gravel path, "
                    "thicket, shade canopy, bush, hot spring, lantern post, scree, "
                    "ember vent and static stone beside the first five and raised "
                    "ground. The second: the cliff edge's hidden foot, the arch "
                    "(hides whoever is under it from above), the marsh (40% slower, "
                    "footprints), the flower meadow (footprints), the ice sheet (a "
                    "tile to stop), the pond (gone round), the bell post (the realm "
                    "alarm up a level, late under Delay), stepping stones (a road "
                    "under Half gravity), the bounce mushroom (3 tiles, 5 under Half "
                    "gravity, heard 4 away), the updraft vent (a level up, two under "
                    "Half gravity) and the pit (a level down, a climb out). The "
                    "third, TD.38's: the six with a direction. A "
                    "feature's code rides in the island's two spare flag bits, so "
                    "every island written before keeps its bytes; the builder offers "
                    "every feature built, and moss. Completion counts features by their tests. "
                    "What §6.2 leaves unmeasured or open is G78 and G80. "
                    "<strong>Left:</strong> swimmers across a pond and flyers two "
                    "levels up an updraft, which wait on traits and flight being "
                    "played; moss on every bare tile; and §6.1's terrain points at "
                    "publishing."
                    "<br><br>"
                    "The simulation had 5 of §6.2's 39 features (rock pillar, "
                    "ruin wall, fence, fog bank, tall grass); the terrain editor, "
                    "the realm view and the curation screens need the rest. "
                    "Completion's Terrain editing row reads done on one test (G67). "
                    "v3.7's §26.8 puts all 39 and moss in phase 4, and wrote G56's "
                    "recommended option: each feature with no direction; moss on "
                    "every tile that carries no feature, cleared at a terrain point "
                    "a tile (§6.1; the simulation and extension write bare ground "
                    "as plain today); heights 0 to 3 with a level at half a tile "
                    "(the design's ratio, adopted under §23.5's rule: G65); and "
                    "§6.1's terrain points checked at publishing in the simulation, "
                    "the extension and the server, the server supplying the Spire "
                    "level for the Heart's, with the Workshop sandbox held to the "
                    "island's realm-level budget (§6.1, §18.6). A bell post's "
                    "ring raises the realm alarm by one (§12.17). The six that "
                    "need a direction or two ends are "
                    "TD.38's. Each is a rules-version change (§24.11).",
             gate="a named simulation test for each feature built and for moss; a "
                  "realm over §6.1's terrain points refused alike by the "
                  "simulation, the extension and the server, the Heart's at its "
                  "Spire level and a Workshop island at its realm level's",
             register=["G56", "G67", "G65", "G78", "G80"]),
        dict(id="TD.38", owner="claude", status="done",
             title="Directional features and tunnels",
             detail="<strong>Built.</strong> Each of the five that face one "
                    "of four ways carries its facing in two more of a tile's flag "
                    "bits; a tunnel is its own list after the buildings, its "
                    "mouths 2 to 6 tiles apart by the walk; a post's facing rides "
                    "in its role byte, north (0) as every post faced before, so "
                    "every island written before keeps its bytes and only the "
                    "rules version moved (the goldens re-pinned on it alone, every "
                    "checksum the same). A ramp, stairs (20% faster, a ramp being "
                    "the ground's pace) and vines climb a level going the way they "
                    "face, a guard seeing down a ramp but not past vines to a "
                    "cliff's foot; a waterfall is walked along its ledge, never "
                    "through the fall, and hides whoever is behind it; rapids push "
                    "anyone, crew and guards, a tile downstream on each whole "
                    "second; a tunnel is walked by the crew as long as it is, "
                    "nobody seeing into it, guards keeping to the surface. The "
                    "generator's default facing, toward the nearest tile on a "
                    "shortest route from a landing edge, is "
                    "<code>Island::default_facing</code>, and a post the builder "
                    "places takes it until a second tap turns it. The builder "
                    "lays the six, turning one with a second tap and digging a "
                    "tunnel mouth by mouth, and the realm view draws each facing "
                    "and tunnel. The readings §6.2 leaves open are named in "
                    "<code>sim/content_gate.py</code> under G56. Left to TD.22: "
                    "the designs' terrain editor and four-way facing dial."
                    "<br><br>"
                    "Ramps, stairs and vines need an up side, a waterfall a ledge "
                    "side, rapids a downstream and a tunnel two ends, and a held "
                    "guard a facing (G56). v3.7 wrote G56's recommended option: "
                    "the owner sets each, and the generator places them by §7.10's "
                    "rule against the shortest route; a held post faces one of "
                    "four directions its owner sets, the generator facing it toward "
                    "the nearest shortest route from a landing edge (§13.3, "
                    "§12.17), in place of the simulation's fixed 270°. The bundle "
                    "carries them, a rules-version change (§24.11); the terrain "
                    "editor places the six and curation's four-way facing dial "
                    "turns a post (both TD.22). A Workshop island is one realm.",
             gate="a named simulation test for each of the six and for a post's "
                  "facing; the generator's default facing toward the nearest "
                  "shortest route (a test); all 39 of §6.2's features in the "
                  "simulation",
             # It waited on TD.15's thirty-three; what TD.15 has left (moss on
             # every bare tile, terrain points, swimmers) is not under it.
             register=["G56"]),
        dict(id="TD.16", owner="claude", status="ready",
             title="The generator: ruins, reference crews, fallbacks",
             detail="D66: the reference crews and the generator inside the "
                    "simulation, as v3.7's §26.8 now plans in phase 6, so the "
                    "server rates a new island from the simulator's prior and "
                    "makes generated fallback targets itself (§12.22); drifting "
                    "ruins at three labelled difficulties (§12.12), the tutorial "
                    "two paying a successful heist's experience with no fee, "
                    "outside the twenty paid raids, their Essence counted only "
                    "toward the backstop (§12.10, §9.6, F37); and the server's "
                    "hold measurement that §13.3 now describes and G55's "
                    "recommended option chose: 800 raids of the competent "
                    "reference crew, queued and cached by the island's digest, "
                    "shown as “measuring…” until it lands, with featuring and ruin "
                    "entry gated on the authored band (D62). The Observatory's "
                    "ruins, Slower ruins, curation's hold figure and the first "
                    "session's tutorial ruin wait for it. The rehearsal crews and "
                    "the defence report's recorder are TD.39's.",
             gate="ruins at the three labelled difficulties ordered by the "
                  "reference crew's success over the harness's runs; a fallback "
                  "target offered when the list is thin (a server test); the "
                  "queue's hold for an island equal to the harness's at 800 "
                  "raids, and served from the cache for an unchanged digest; a "
                  "tutorial ruin charging no fee and counting no paid raid (a "
                  "server test)",
             register=["D66", "D62", "G55", "F37"]),
        dict(id="TD.39", owner="claude", status="blocked",
             title="Rehearsal crews and the defence report's facts",
             detail="v3.7 wrote G57's recommended option. §13's rehearsal crews "
                    "have rules, as settings of D66's reference crew: cautious "
                    "waits whenever a guard could see its next tile and never "
                    "runs; greedy loads until the bag is full, whatever the clock; "
                    "fast takes the shortest route and runs. §13.2's report is "
                    "defined for one raid: denied is the clean haul a full bag "
                    "would make on this island, priced as §9.4 prices a crew's "
                    "unbanked load, less what the raider banked; held is the "
                    "seconds from the first landing to the last crew member's "
                    "escape or capture; seen is each place a guard reached "
                    "Alerted, named by the nearest building or feature; fired is "
                    "each ward set off, bell rung and guardian Sage power used. "
                    "They are recorded from TD.13's event log and the server "
                    "writes them into the heist's row at settlement, whether or "
                    "not that raid was re-simulated, with the facts the Profile's "
                    "records read, so the defence log (TD.66) and the Profile "
                    "(TD.24) read one record; a row outlives its replay and says "
                    "when the replay is gone. Two of §23.2's ten records, “most "
                    "guards slept past” and “minutes played a day”, and “the "
                    "favourite law” have no fact behind them yet, and a raid not "
                    "re-simulated has its facts from a log nothing checks: those "
                    "are the register's (G57).",
             gate="a test for each crew's rule and each fact as §13 and §13.2 "
                  "define them; a settled raid's facts, re-simulated from its "
                  "replay, equal what was written",
             blocked_by=["TD.13", "TD.16"],
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
                    "answer), under §20.3's caps, with at least one goal a day "
                    "that needs no heist, its pages routed to the law the player "
                    "marked, and a claim carried over for three days (F37's "
                    "answer, §14.6); the streak with its saver, "
                    "repair and cosmetic. Client: the repository, state and "
                    "presenters that TD.23's Season screen and TD.26's first "
                    "session draw. The design's quests and star chests are not "
                    "these, and stay refused.",
             gate="server tests for three picked of six, one swap, each claim "
                  "once and carried three days, a goal every day that needs no "
                  "heist, and the streak's saver and repair; presenter tests for "
                  "both in both languages",
             blocked_by=["TC.12"],
             register=["F42", "F37"]),
        dict(id="TD.69", owner="claude", status="done",
             title="§12.17's alarm ladder, levels 1 to 4 and 6, with the Glare's "
                   "reach following it",
             detail="<strong>Done.</strong> §12.17's realm alarm climbs from 0 to 6, "
                    "once every 30 seconds and once per body found, and each level "
                    "keeps those below it. <code>sim/</code> builds every level: "
                    "suspicion empties at half rate from 1; every noise carries a "
                    "metre further from 2, except a crouched step on moss; an "
                    "Investigating guard searches 20 s from 3; the alarm and a "
                    "Lantern Glare reach 8 m from 4 (§10.3); a Warden arrives at 5; "
                    "and every guard not chasing enters Searching at 6, with a test "
                    "for each. The golden replays first move at seconds 35, 46 and "
                    "49, after level 1 arrives at 30, and are re-recorded under the "
                    "new rules version, which now also fingerprints the realm's "
                    "watch the goldens cannot see. The harness keeps a realm alarm "
                    "per realm and carries levels 1, 3, 4, 5 and 6; it has no "
                    "footstep noise and no alert spread, so level 2 and level 4's "
                    "spread are the simulation's alone. A bell post's ring waits for "
                    "the bell post (TD.15). Re-measured at n = 800 on §5.2's v3.7 "
                    "budget with the watch: 33.5, 46.4, 37.0, 38.5 and 37.8% held at "
                    "realm levels 1 to 5 (32.6, 44.2, 36.6, 38.0 and 36.9% with the "
                    "ladder off), so realm level 2 leaves §13.2's band; 0.7 as far "
                    "brings it to 38.8% (F62, drafted for TD.75). The Heart's own "
                    "hold waits for its watch to be stated (G71).",
             gate="a sim test per level, the goldens re-recorded and verifying on "
                  "native and WebAssembly, the harness's ladder test, and §13.2's "
                  "table re-measured at n = 800",
             evidence="cargo test (sim/tests.rs from_alarm_level_*); "
                      "python3 -m tools.heist_harness.test_harness",
             blocked_by=[],
             register=["F33", "F55", "F59"]),
        dict(id="TD.70", owner="claude", status="ready",
             title="A ward ignores its disarmer from the moment it sets out",
             detail="v3.7's §10.3 makes a ward's sensor ignore the crew member "
                    "disarming it from the moment it sets out, G18's generous "
                    "reading. <code>sim/</code>'s <code>wards_act()</code> still "
                    "ignores only a raider already on the ward's tile, so a Well "
                    "or a Glare fires on a disarmer walking in, and the harness's "
                    "<code>disarm_approach</code> defaults to off. Both ignore a "
                    "crew member from when it is sent to disarm a known ward, the "
                    "test that pins a Glare firing on a disarmer walking in is "
                    "inverted, and the harness defaults to the rule. A "
                    "rules-version change (§24.11); TD.71 measures what it does to "
                    "the bands.",
             gate="the inverted <code>sim/</code> test passes; the harness's "
                  "default is the rule (a harness test); the goldens re-recorded "
                  "and agreeing",
             evidence="cargo test in sim/; python3 -m tools.heist_harness.test_harness",
             register=["G18"]),
        dict(id="TD.71", owner="claude", status="blocked",
             title="§13.2's two-band check over every ward kit a Keeper can build",
             detail="§13.2 asks for a build-blocking check (§31.5) that at every "
                    "realm level one setting inside the ward budget meets both the "
                    "hold band and §12.6's decision band, run over every kit of "
                    "ward kinds a Keeper can build within the budget, so a budget "
                    "spent on one kind (two Lantern Glares, say) cannot be "
                    "certified by the kits that miss the band; §5.2 says its "
                    "counts ship until this check moves them. No check runs over "
                    "kits: the harness takes one only as <code>ward_kinds</code>, "
                    "and §13.2's holds are measured on the generator's kit (F33). "
                    "It runs on the ladder and the disarm rule as they ship "
                    "(TD.69, TD.70). §18.3's eras, which the harness does not "
                    "model, are measured against the same bands (D69). A level the "
                    "check fails moves its band by §13.2's rule, which is the "
                    "document's: the failure is recorded for the owner, not tuned "
                    "away here. Whether one passing setting may certify a level "
                    "whose Glare-heavy kit misses the band, v3.7 does not make "
                    "plain; that is the register's.",
             gate="a harness check, run by <code>tools/check_all.sh</code>, that "
                  "measures every ward kit within §5.2's budget at each realm "
                  "level against both bands with the alarm ladder on, reports "
                  "each kit's hold and decisions, and fails when no setting at a "
                  "level meets both (§31.5); each of §18.3's eras measured "
                  "against the same bands",
             blocked_by=["TD.69", "TD.70"],
             register=["F33", "D69", "F60"]),
        dict(id="TD.72", owner="claude", status="ready",
             title="Regenerate §14's tables at v3.7's rules, and send the owner "
                   "the replacement figures",
             detail="v3.7 quotes the full re-run in sentences and still prints "
                    "the earlier run's tables. The sentences say Keeper 40 on day "
                    "349 to 357 and everything built on day 754 to 782 (§14.2, "
                    "§9.5 and its opening note), where "
                    "<code>docs/design/generated/pacing.md</code>, with every "
                    "recorded answer built, gives day 307 to 321 and day 586 to "
                    "618; 754 to 782 is F38's option B run alone. §14.1's "
                    "consequence figures are the run before the answers (C19, "
                    "F38, F56). And v3.7 changed rules the model does not run yet: "
                    "upkeep is a share of each realm's Aether production by the "
                    "universe's share of capacity (§5.6, §29.1), where the model "
                    "charges §9.5's old flat 0.5 an hour a point; and a Sage's "
                    "level is the Keeper's, with no Insight (§11.7, §9.1), so "
                    "§14.3's Sage rows follow Keeper levels. §5.2's posts and wards "
                    "at realm levels 4 and 5 changed too, which the model reads "
                    "from <code>design_facts</code> and has not been re-run on. The "
                    "model takes them, the re-run is regenerated, and a sheet "
                    "of replacement figures is written for the owner: §9.3's "
                    "production table, §10.2's build-day and income-hour columns, "
                    "§14.2's Keeper table and chart, §14.3's milestone rows, "
                    "§14.4, §5.2's Engaged column and §5.5's capacities, each at "
                    "both edges of §9.6's band, and every sentence that quotes a "
                    "run (§14.1, §14.2, §9.5, §27.2, §32.9 and the opening note) "
                    "with the figure that replaces it. A check then compares the "
                    "document's tables with pacing.md, so C19 reads open until "
                    "they agree. TD.73 takes them into the document.",
             gate="the model runs v3.7's upkeep and Sage rules (a model test "
                  "each) and pacing.md is regenerated from it; the sheet gives "
                  "every table and sentence above with its regenerated figure at "
                  "both edges of §9.6's band; a check compares the document's "
                  "§9.3, §10.2, §14.2 and §14.3 tables with pacing.md and reports "
                  "C19 open while they differ",
             evidence="python3 -m tools.economy_model rerun; "
                      "docs/design/generated/pacing.md",
             register=["C19", "F38", "F56", "C58", "F61"]),
        dict(id="TD.73", owner="you", status="blocked",
             title="Take the regenerated tables and figures into the document",
             detail="§14.2 says the generated tables replace the earlier run whole "
                    "when they are next printed, and are never filled by hand. "
                    "TD.72's sheet gives each table, and each sentence that quotes "
                    "a run, with its replacement; this is printing them in the "
                    "next version of the document.",
             gate="TD.72's check finds the document's tables equal to pacing.md's, "
                  "and no sentence that quotes a run disagrees with it",
             evidence="docs/design/generated/pacing.md",
             blocked_by=["TD.72"],
             register=["C19", "C58"]),
        dict(id="TD.75", owner="you", status="yours",
             title="Take the drafted edits into the document",
             detail="Reading v3.7 against itself and the build left sentences that "
                    "still disagree: a figure stated two ways, a rule left half-written "
                    "beside one v3.7 settled, a citation to the wrong section. Each "
                    "item here carries its edit, drafted against v3.7's own words "
                    "(tools/audit_register.py EDITS; tools/check_edits.py checks "
                    "every find string against the document). Taking them is printing "
                    "the next version; none needs a new decision, and where one item "
                    "had two readings the edit takes the one v3.7's rule picks (the "
                    "option its brief recommended). The re-run's figures are TD.73's.",
             gate="the next version's check_edits run finds every one of these "
                  "edits applied, and check_document passes on it",
             evidence="tools/audit_register.py EDITS; tools/check_edits.py",
             blocked_by=[],
             register=["G71", "C59", "G72", "C60", "C61", "C62", "C63", "G73", "C64", "C65", "C66", "C67", "C68", "C69", "C70", "C71", "G75", "C72", "C73", "G76", "C55", "F38", "F47", "F55", "F56", "G23", "G26", "G51", "G57", "F62", "G77", "G78", "G79", "G80", "G81", "G82", "G83"]),
        dict(id="TD.74", owner="claude", status="doing",
             title="Notifications and session telemetry on the device",
             detail="The server sends §14.6's notifications, keeps the night "
                    "(§20.2) and says when the survey is due, and the client does "
                    "none of its half: the four notification strings in the app's "
                    "native string tables in English and Brazilian Portuguese; "
                    "the device's own timers for storage full, a character rested "
                    "and an experiment finished; and the push permission asked "
                    "after the third session, never before (§25.2, D68). Nor does "
                    "it send <code>session_start</code> and "
                    "<code>session_end</code>, or ask the survey when "
                    "<code>GET /v1/survey</code> says it is the player's turn "
                    "(G29). v3.7's §26.8 lists the strings, the timers and the "
                    "permission in phases 10 to 13. The timers read production, "
                    "the roster and the Lab from TC.12. TC.8 measures them on "
                    "phones; this builds them. <strong>Built:</strong> "
                    "<code>client/platform/notifications.csv</code> holds the "
                    "twelve keys — every one <code>push.mjs</code> sends and a "
                    "title and body for each of §14.6's four kinds — and "
                    "<code>tools/native_strings.py</code> writes iOS's "
                    "<code>Localizable.strings</code> and Android's "
                    "<code>strings.xml</code> from it and checks them in "
                    "<code>check_all.sh</code>. The home view says when each "
                    "producer fills (<code>full_at</code>) and the night the "
                    "player keeps, and the device sets its storage-full timer "
                    "from it, moved to the night's end "
                    "(<code>DeviceNotices</code>). The permission is asked at "
                    "the start of the third session, once. Sessions are kept on "
                    "the phone and sent, a killed one ended at the next launch "
                    "as crashed, and the device reports its time zone and push "
                    "token (G34); and the rested timer, from the first rest the "
                    "home names to end. <strong>Left:</strong> the "
                    "experiment timer, once the server keeps the Lab (TD.22); "
                    "the survey when <code>GET /v1/survey</code> "
                    "says so (G29); and, on a phone, the tables bundled into "
                    "both exports and the platforms' notification plugins "
                    "behind <code>LocalNotifier</code> (TC.3).",
             gate="the four strings in both languages in the native string "
                  "tables (a check); each timer set from the server's state and "
                  "moved when it changes (tests on a fake clock); the permission "
                  "asked at the start of the third session and not before (a "
                  "test); session events sent, and the survey shown only when the "
                  "server says (tests against the fake server)",
             blocked_by=[],
             register=["D68", "G29"]),
        dict(id="TD.76", owner="claude", status="doing",
             title="The owner's six languages: English (UK and US), Portuguese "
                   "(Brazil and Portugal), German and French",
             detail="§20.6 launches in English and Brazilian Portuguese; the owner "
                    "asked for European Portuguese, German and French, and English "
                    "in UK and US forms (D99). <strong>Built:</strong> the "
                    "client's catalogue, one column a language, with British "
                    "English as the document writes it and US English written from "
                    "it by <code>tools/english_us.py</code>'s spelling table; the "
                    "European Portuguese, German and French drafted and held by "
                    "test to every key and placeholder; a new player starting in "
                    "the phone's language; the picker naming each language in "
                    "itself; the phones' notification tables in all six; the "
                    "server's island names in each language's order and gender; "
                    "every screen laid out at 150% and 200% in all six, the "
                    "builder's status scrolling in its place. <strong>Left:"
                    "</strong> the coined names in each language, the owner's "
                    "after §26.9's read-aloud; a native speaker's read of the "
                    "drafted languages; the document's §20.6, §26.3 and §26.4 "
                    "(drafted).",
             gate="every string in every language with the same placeholders "
                  "(the catalogue test); a new player in the phone's language (a "
                  "test); every screen's layout at large text in every language "
                  "(the accessibility tests); the notification tables and the US "
                  "English checked in check_all.sh",
             blocked_by=[],
             register=["D99"]),
        # -- Track D: the screens, the slice's first -------------------------
        dict(id="TD.17", owner="claude", status="blocked",
             title="Heist and result on the design, on the flat view",
             detail="The heist's HUD and controls on the flat view (the design's "
                    "portraits with pips and lockout, Get out and the skiff, the "
                    "alarm with its newest effect in words, the Vault and load "
                    "target, the Sage dial); the 3D view is TD.42. The controls are "
                    "the ones v3.7 wrote from G47's recommended option: no crawl, "
                    "no gait button and no stop or drop button (§12.18), so the "
                    "build's gait, Halt and Drop-half buttons go "
                    "(<code>heist_screen.gd:304</code>); a held tap on a crew "
                    "member offers Stop, Drop half and Drop all, on the Vault the "
                    "load target, on a law chip its law card; wheels and held-tap "
                    "menus are modal, so the eight-control cap holds (§12.7); the "
                    "load target is set in the planner, 50 to 100% in tens, the "
                    "last used by default (§12.5), where "
                    "<code>heist_controller.gd:94</code> always loads 100; a tap on "
                    "the clock pauses a drifting ruin or a rehearsal, and a heist "
                    "against a player pauses only when the phone leaves the app, "
                    "resuming on a three-second count (§24.12). Not ported from "
                    "the design: stamina and hearts (the handoff's README.md:165), "
                    "the unused three-star objectives, the REVENGE tag, a grace at "
                    "the start or slow motion at an alert (tick 0 follows the "
                    "entry card), and the crack ring and its “heard within 5 m” "
                    "hint (realm-diorama.js:208), since no guard hears the Vault "
                    "(§12.17). The result to "
                    "§23.2's rewritten row: outcome and multipliers, the decisive "
                    "moment with a three-second replay and one thing to try, loot "
                    "kept, the fee by target kind (none on a Trace), the law to "
                    "study, Renown, rest per crew member, and “worth your time?”. "
                    "The settle answer gains what the result shows, from TC.12's "
                    "pages and roster (crossed, studyPages, pylonPages, firstMet, "
                    "floorPage, rest, strays, targetKind; no Insight, which v3.7 "
                    "removes, §9.1), and "
                    "<code>POST /v1/heists/:token/study</code> takes the study. "
                    "What waited on answers is now v3.7's: the worth "
                    "question is asked once a session, on a heist result, as one "
                    "row of five one-tap points, never required, and its only reply "
                    "is “Thanks.” (§20.3, §19.5, C47); the heist says “Seen: this "
                    "heist is Loud now” when a guard is Alerted and the result "
                    "shows the alarm ladder's true peak (§12.9); and the HUD's "
                    "“Left” shows the rough estimate, or “?”, until the Vault "
                    "opens (<code>heist_hud.gd:51</code> shows the exact figure "
                    "from the start). The moment is chosen by §12.13's rule from "
                    "TD.13's log: for a Foiled or Partial heist the first capture, "
                    "traced to the tick its captor became Alerted; for a Loud one "
                    "the first guard Alerted and why; for a Clean one the closest "
                    "call; the replay is the three seconds ending on that tick, "
                    "and the tip, from a content table keyed by the moment's "
                    "cause, sits in the result's own “Try this” row (G48). A "
                    "Foiled result offers §12.14's new route or another target, "
                    "and an easier version only of a ruin. The design's heist adds "
                    "mechanics (a Sage wheel's extra powers, heist-wide casts) "
                    "that are refused (D79).",
             gate="the screen gate for §23.2's Heist and Heist result rows, the "
                  "result in each kind of target's variant; no more than §12.7's "
                  "eight controls live at once (a test); the heist and result "
                  "tests kept by name (completion reads them); the moment picker "
                  "tested on the five goldens; a presenter test for each of "
                  "these: §21.8's Heist layout and Ability uses rows (pips with "
                  "the number, the lockout ring, the pause mark, the Sage dial); "
                  "§12.6's always-on list (awareness of the guards the crew can "
                  "see, uses left, the Vault's progress); Regroup in Get out's "
                  "place while the crew is split (§12.7); a portrait, a power "
                  "and a cast aimed by drag, with two taps as §20.8's "
                  "alternative; a held Get out choosing the skiff's edge; health "
                  "bars with §12.20's down timer and revive; the clock turning "
                  "red as §12.6 says; the skiff's arrival time (§5.4); controls "
                  "mirrored for left-handed play; the selected guard's vision "
                  "cone and every other visible guard's facing and awareness "
                  "(§21.12, §12.6, C57's recommended option); the worth question "
                  "at most once a session; “Left” shown as the estimate or “?” "
                  "until the Vault opens; a held tap on a crew member, the Vault "
                  "and a law chip each opening its modal menu; “Raid again” only while a crew of three can be "
                  "formed from characters idle or pulled off work (§11.5, "
                  "§12.5), else “Pick a crew”; and a Partial or Foiled result "
                  "listing what was kept (§12.14, §20.3)",
             blocked_by=["TD.3", "TD.12", "TD.13", "TC.12"],
             register=["C47", "D79", "D80", "G48", "G47", "C57"]),
        dict(id="TD.41", owner="claude", status="blocked",
             title="The landing picker on one island",
             detail="Stage A of the landing picker, on the one-island heist that "
                    "exists: <code>landing_heard</code> and "
                    "<code>landing_reach</code> in the simulation and the "
                    "extension, the leased island's edge with what guards would "
                    "hear (§5.4), each edge spot marked covered or open from the "
                    "terrain alone, since the scout shows nothing placed (§12.4, "
                    "D77's recommended option), and the chosen tile as the "
                    "replay's first command; the seed's "
                    "<code>default_landing()</code> stays for offline only. The "
                    "clock is set in Manrope with tabular figures, not Lilita One "
                    "(§21.8). It closes T3.4's “Not yet: §21's landing picker”. "
                    "Every outer realm's edge, and each fault, comes with "
                    "universes of several realms (TD.18).",
             gate="the screen gate for the Landing picker row on one island; the "
                  "chosen tile is the replay's first command, and each spot's "
                  "mark is the same whatever guards and wards the island places "
                  "(tests)",
             blocked_by=["TD.3"]),
        dict(id="TD.18", owner="claude", status="blocked",
             title="Observatory, scout report and planner",
             detail="They draw universes of several realms (T3.3), and each piece "
                    "stands on work below it: the Observatory's refresh and casts "
                    "cost Aether, and the planner's crew needs the "
                    "roster and rest (TC.12); its Sage and casts rows bind to the "
                    "simulation's (TD.12); law chips open the law card (TD.20); "
                    "ruins come from the generator (TD.16); the planner's Entry "
                    "row opens the landing picker (TD.41), the only place a landing "
                    "is chosen. The offer stops sending the "
                    "internal rating to the device and starts sending why each "
                    "target was offered and its depth (§12.15, §12.22). v3.7 "
                    "wrote every answer and recommendation these screens waited "
                    "on (C45, C46, D77), and the screens draw the server's values: "
                    "the entry fee, 2% of B(V) at the target's Vault level and "
                    "returned by outcome (§9.4), and the Keeper window, 2 below to "
                    "3 above (§12.3), with no scout lock, not the design's 2% of "
                    "holdings, “Keepers 21-27” or “Scout · 100 Aether”. Scouting "
                    "is free and is the target card (§12.4): the realm's laws, "
                    "guards by role, ward counts, one rough loot estimate, the "
                    "universe's strain and open faults, and the realm's watch "
                    "(§5.2, §12.17), and nothing placed; its 3D view draws the "
                    "ground, terrain, buildings, Vault, links and the wards §10.3 "
                    "marks always seen, with no reach discs, post or ward pins, "
                    "patrol notes, route or loot by realm, and positions come only "
                    "from a Cartographer's map, a Lantern Wisp or Reveal (D77). "
                    "The Observatory offers three to six universes, one more while "
                    "the Wanderer is at home; a Trace is shown apart from the list "
                    "and pinned first; each card prints “up to N realms to the "
                    "Heart” and names from word lists (§12.3, §12.22, C46), and "
                    "the server sends them so. Generated targets are labelled with "
                    "their band, ruins at three labelled difficulties with rewards "
                    "and a recommendation, landing on any edge tile or fault, no "
                    "Carrier required and crews of 3, 4 or 5 by Keeper level "
                    "(D78). "
                    "The scout report's Plan opens the planner without setting an "
                    "entry (not the analysis's landing-realm preset), and any crew "
                    "it suggests, or member it says to leave, is carried into the "
                    "planner or not shown (the handoff's screen-review.md:124, "
                    ":228, :316). Each realm page opens on its law cards, with "
                    "guards, wards and matchups after them (§23.2). Matchups are "
                    "generated from each kind's ability and resistance (§11.2), its "
                    "size and flight (§12.21) and the realm's laws (D78). While "
                    "the player is protected, the first player target's card and "
                    "the planner's Start say that raiding a player ends the "
                    "protection (§12.3, §16's day 2).",
             gate="the screen gate for the Observatory, Scout report and Heist "
                  "planner rows, and for the Landing picker row on universes of "
                  "several realms; an offer test that no rating reaches the device; "
                  "every fee shown equal to the lease's; every matchup line names "
                  "only the kind's own ability and the realm's own laws (a test); "
                  "the planner's crew and entry after Plan equal what the scout "
                  "report showed, and the protected state says what a raid ends "
                  "(presenter tests); every target card shows the realm's watch, "
                  "strain and open faults and no position, and the landing picker "
                  "offers each fault (presenter tests); up to six targets with the "
                  "Wanderer home and a Trace pinned outside them (server tests)",
             blocked_by=["TD.3", "T3.3", "TD.12", "TD.16", "TD.20", "TD.37", "TD.41",
                         "TC.12"],
             register=["F46", "F51", "D77", "C46", "D78", "C45", "F55"]),
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
                    "and are refused: the trays list §10.2's buildings at their "
                    "counts and prices (Storehouses in outer realms only, fully "
                    "exposed), §10.3's six wards and one Guardian Post kind, and "
                    "§6.2's features with §6.1's budget; upgrades are instant; one "
                    "Star Well, Aether Spring, Garden and Hearth a realm, with 1, 2 "
                    "and 3 worker slots; §12.3's protection is in words on the "
                    "defence screen (D73). The tray's ward-linking “Pylon” goes "
                    "(D74). Home's layout is the shell's (TD.6, C44). "
                    "The dive from home into a realm eases out (about 1.2 s in the "
                    "handoff's README.md:149) and moving between realms is a "
                    "lateral slide; each is a cut under reduced motion (§20.8). "
                    "Rotate and zoom are v3.7's §21.1 (D75's recommended option): "
                    "pinch to zoom and twist to rotate with no buttons on screen, "
                    "the three zoom levels also reached by taps (an island to "
                    "enter it, a building for its close-up, the map control to "
                    "leave), and a Settings switch that shows rotate and zoom "
                    "buttons, so no action needs two fingers (§20.8). All four of "
                    "§5.3's links are drawn, the Rift with its closing, where the "
                    "handoff names three (README.md:179).",
             gate="the screen gate for the Universe map and Realm view rows; every "
                  "building drawn on its stored tile (a test against TD.36's "
                  "island); with reduced motion on the camera moves in one frame "
                  "(a test); every zoom level reached by taps, and rotation by "
                  "the Settings switch's buttons, with one finger (flow tests); "
                  "each of §5.3's four links drawn",
             blocked_by=["TD.6", "TD.10", "TD.14", "TD.36", "TD.37", "TC.12"],
             register=["D73", "D75", "G46", "D74", "D91"]),
        dict(id="TD.42", owner="claude", status="blocked",
             title="The heist in 3D",
             detail="TD.17's heist on TD.10's world: actors interpolated between "
                    "ticks, the selected guard's cone and every visible guard's "
                    "facing as TD.17 draws them (§21.12, C57), the overlays, "
                    "§12.6's camera, and TD.11's characters. The flat view stays "
                    "for screen readers and as the fallback.",
             gate="every actor drawn at its tile at every tick of the five goldens "
                  "(TD.10's check); the heist tests passing with either view",
             blocked_by=["TD.17", "TD.10", "TD.11"],
             register=["C57"]),
        dict(id="TD.20", owner="claude", status="blocked",
             title="Weaving and the law card",
             detail="Weaving shows the big card with its looping preview, cost, "
                    "strain and ready time, the seven bands and every harmony and "
                    "clash it makes, and the two or three recommended laws §23.2 "
                    "asks for, which the design omits, ranked with their "
                    "comparison (C48); a weave that would reach Breaking is "
                    "refused; Weave has a tap path beside the held one, with an "
                    "adjustable hold (D81). Every price is read from TD.14's "
                    "function, as v3.7's §5.5 to §5.6 price it. The law card "
                    "carries the school's shape and a looping preview, never a "
                    "pause sign, notes as symbols with their pages, and on its "
                    "back §7.7's one weakness rather than the design's counters; "
                    "an unknown law shows “?” with no lead (D79). Pylons in the "
                    "realm view are joined by threads, jagged lines and triangles "
                    "for harmonies, clashes and chords (D81). Effect words come "
                    "from content (G23, G25). Aether and weaving state live on "
                    "the server first (TC.12). The Codex and the Harmony view are "
                    "TD.44. The Heart shows its two realm slots and no third, not "
                    "the design's Locked third slot (D75's Heart row), and the "
                    "Spire the crown slots the server reports, opened as §5.1 "
                    "says. The second epoch's extra slot comes after launch, and "
                    "v3.7 makes it a third law slot in the Heart (§18.4, §14.9, "
                    "C56's recommended option). Each crown law is priced by TD.14.",
             gate="the screen gate for the Weaving and Law card rows; every price "
                  "shown equal to the server's for the same weave (a test); the "
                  "Heart's and the Spire's slots at Spire levels 1, 2, 5 and 6 (a "
                  "presenter test); a weave into Breaking refused, and the "
                  "recommended laws in the server's order (flow tests)",
             blocked_by=["TD.3", "TD.14", "TD.37", "TC.12"],
             register=["G23", "G25", "D81", "D79", "C56", "D75", "C48"]),
        dict(id="TD.21", owner="claude", status="blocked",
             title="Roster, Character and Sage hall",
             detail="The roster on the server comes first (TC.12), and the cards "
                    "read TD.33's tables. The character screen shows §11.11's card "
                    "word for word and §11.1's role numbers, not the sheets' own; "
                    "the design's stealth and grit stats, its role-keyed abilities "
                    "and its work bonuses are refused, and so are the sheets' "
                    "variants for visitors and anomalies (D95). Each kind's "
                    "ability, rule-sheet line and resistance, the role numbers "
                    "and §9.2's bonuses are read from content and the server; "
                    "each character has two traits, works only at a producer, and "
                    "shows its state as a symbol and a word; the tab is named "
                    "Roster (D82). The Sage hall lists the four launch Sages with "
                    "their powers from TC.12's Sage routes; v3.7 wrote G52's "
                    "recommended option, so a Sage's level is the Keeper's, from "
                    "1 to 40, there is no Insight, and the hall shows the Keeper's "
                    "level and what each fifth level adds (§11.7, §9.1); a level "
                    "never shortens the 20-second cooldown (C49); while the "
                    "Archivist is the only Sage it goes or guards, the player's "
                    "choice. Hatching, naming and a visiting Stray are TD.63's. "
                    "Paradox-born join the roster with TD.35, the Twinned shown as "
                    "one 120 health and 80 carry and each carrying its paradox's "
                    "mark where a ruleborn carries its school's (§11.8); the Forms "
                    "album is TD.45. A character is in one of §11.6's five states, "
                    "never “asleep”, and levels on Essence (§11.4) with no XP, "
                    "where the handoff's state has both (README.md:164).",
             gate="the screen gate for the Roster, Character and Sage hall rows; "
                  "every card's words generated from TD.33's content, all "
                  "eighteen held to it (a test); each Sage's level equal to the "
                  "Keeper's (a presenter test)",
             blocked_by=["TD.3", "TD.12", "TD.33", "TC.12"],
             register=["D82", "G52", "C53", "G62", "G63", "D94", "D95", "G65"]),
        dict(id="TD.43", owner="claude", status="blocked",
             title="Rehearsal",
             detail="A rehearsal sends one of TD.39's three crews against the "
                    "universe as it stands and replays its route; pause stays in "
                    "rehearsals (§20.8), and the slower speed is for ruins only "
                    "(TD.27). §26.2's slice has rehearsals and no heists against "
                    "players, so the defence log, the other half of §23.2's row, "
                    "is TD.66's, outside the slice. The route replays on the "
                    "realm's own view, <code>RealmView</code> tick by tick (the "
                    "analysis's lab report, section 4.9), and on TD.42's 3D view once it "
                    "lands, never on a separate 2D map (the handoff's "
                    "screen-review.md:271).",
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
                    "prices them. v3.7 wrote G49's recommended option: chapter 1 "
                    "is twelve laws, two of each school, the ten launch commons "
                    "with Aurora and Echoes, the three starting laws among them; "
                    "meeting a law is a heist or ruin route entering a realm "
                    "running it, and a scout or target card shows its name and "
                    "rank but gives no page (§7.6); a school's mastery track is "
                    "three steps for each of its laws in play (woven, crossed in a "
                    "successful heist, raised to tier III), with a title at a "
                    "third and at all of them and the school's new style at two "
                    "thirds (§18.5); a Codex note is kept from the heist rows; an "
                    "unnamed resonance or chord shows as a line priced in the "
                    "player's own realm, and a crossing hints the partner's school; "
                    "the Lab's “hinted” state is G53's (TD.65). The Harmony view's "
                    "“RESONANCE FOUND” discovery is not built: discovery is the "
                    "Lab's (§8.4). With the chapters, matchmaking offers only "
                    "universes running laws from open chapters (§7.6), a change "
                    "to <code>matchmaking.mjs</code>.",
             gate="the screen gate for the Law Codex and Harmony view rows; an "
                  "offer test that no target runs a law from a closed chapter; a "
                  "law met by a route and not by a scout, and a mastery step for "
                  "each of the three acts (server tests)",
             blocked_by=["TD.20", "TC.12"],
             register=["G49"]),
        dict(id="TD.45", owner="claude", status="blocked",
             title="The Forms album",
             detail="The 54 forms by kind, each drawn with its accessory and "
                    "pattern (TD.11), filled by births at a Nursery from TC.12's "
                    "hatch route, with the sail, quirks, note symbols and “Show "
                    "mine”, not the design's USE THIS LOOK (D82, G50). Paradox-born "
                    "have no forms (§11.8, G62's recommended option), so the album "
                    "is the 54.",
             gate="the screen gate for the Forms album row; every form in it "
                  "drawn from TD.7's manifest",
             blocked_by=["TD.21", "TD.11", "TC.12"]),
        dict(id="TD.66", owner="claude", status="blocked",
             title="The defence log",
             detail="The raids on the player from TC.12's defence routes, each "
                    "with its report (§23.2: the haul denied, how long the defence "
                    "held, where the crew was seen, what fired) from TD.39's "
                    "record, its haul denied priced as §9.4 prices a crew's "
                    "unbanked load (G31). Each report names its outcome as v3.7 "
                    "writes G69's recommended option: held when the raid was "
                    "Foiled, as §13.4's hold rate counts it, and leaked on Clean, "
                    "Loud and Partial, with Partial its own count (§12.9); "
                    "offers Watch replay while the replay is kept (§13, T3.3), and "
                    "says when it is gone; keeps the season's rows; "
                    "shows the island with where the crew was seen and what fired; "
                    "and names the guards that caught anyone. Trace, as §12.3 "
                    "offers it, is offered for each raid the server's "
                    "<code>traceable()</code> returns: not foiled, and not past "
                    "the raider's twenty paid raids that week, which carries out "
                    "G20's answer (<code>server/test/service.test.mjs:325</code>), "
                    "and is the rule v3.7's §12.3 now writes (G70's recommended "
                    "option); a raid that took nothing opens nothing. A raid "
                    "shows only once it has ended (D83). "
                    "§26.2 brings heists against players in phase 3, so the slice "
                    "(T6.1) does not wait on it.",
             gate="the screen gate for the Rehearsal and defence log row's other "
                  "half: raids on you, each with its report, and Trace; the raid "
                  "badge clears once the log is seen (a flow test); a flow test "
                  "for the outcome, the replay, the island and the catching "
                  "guards, and one that a foiled raid offers no Trace",
             blocked_by=["TD.3", "TD.6", "TD.39", "TC.12"],
             register=["G31", "G57", "G69", "G70", "D83"]),
        dict(id="TD.63", owner="claude", status="blocked",
             title="Hatching, naming and the visiting Stray",
             detail="Births had no screen and naming no rule (G50), and no realm "
                    "decided a visiting Stray's kind and form (G64). v3.7 wrote "
                    "both recommended options. The Hatch screen is §23.2's 29th "
                    "row: ready births and the Nursery's three places, the Essence "
                    "price, the kind's odds by §11.9's weights, the form and its "
                    "odds on a tie, the two traits rolled, and naming from word "
                    "lists, offered the first time one hatches with a free outfit; "
                    "a ruleborn's name is seen only by its owner and can be "
                    "changed (§20.2). A stray found in a heist is offered there at "
                    "the next birth's price (§11.5, F38's answer), its kind and "
                    "form drawn from one of the laws the crew crossed. The "
                    "visiting Stray's kind is drawn as a birth's, with the Heart "
                    "standing for the Nursery's realm, and its form by §11.10's "
                    "tie rule (§11.8, §11.9); the server grants none until it "
                    "draws one. The client draws them on TD.21's roster: the hatch "
                    "sheet, names, and the Stray at the Dock with its bundle.",
             gate="server tests for a birth's kind and form, a found stray's "
                  "price and draw, a name from the word lists, and the visiting "
                  "Stray's draw; the screen gate for the Hatch row and what it "
                  "adds to the Roster and Character rows",
             blocked_by=["TD.21"],
             register=["G50", "G64", "F38"]),
        dict(id="TD.64", owner="claude", status="done",
             title="Presence and pings among friends, and the Open Vault league",
             detail="Which of the design's friend features ship (D86: none, "
                    "pings, or presence and activity for 16 and over) and whether "
                    "§9.4's Open Vault league ships at launch (C50) were to change "
                    "the server and TD.23's Friends and League screens, and an "
                    "answer that shipped neither was to close this task with "
                    "nothing built.<br><br><strong>Closed with nothing built.</strong> "
                    "v3.7 settled both by their briefs' recommended options and "
                    "ships neither at launch: Friends is the list, invites, the "
                    "feed and friendly heists, with no presence, last-seen time, "
                    "activity or pings (§17.6, §23.2), and the Open Vault league "
                    "comes after launch, its rules written before it is scheduled "
                    "(§9.4, §26.1, §19.21). TD.23 leaves those parts of the design "
                    "out of the Friends and Share sheet screens.",
             gate="the decisions ship either feature, or neither and nothing is "
                  "built: v3.7 ships neither (§17.6, §9.4)",
             evidence="v3.7 §17.6, §9.4, §26.1",
             register=["D86", "C50"]),
        dict(id="TD.65", owner="claude", status="blocked",
             title="The Lab's hints, curation's swaps and the hold figure",
             detail="v3.7 wrote the three recommended options, built on TD.22's "
                    "screens and the server. The Lab (G53): after three empty "
                    "experiments that included the same law it hints one "
                    "undiscovered resonance of that law, in the Codex's one "
                    "“hinted” state, and no screen hints sooner (§8.6); from Lab "
                    "level 3 its third sphere names, once a day and free, the "
                    "first chord in §8.5's table the player has woven or crossed "
                    "and not named; a failure gives 3 pages of the law the player "
                    "marked if it is in either placed law's school, else of the "
                    "first placed, and only restored laws go on the pedestals "
                    "(§7.6); while a universe holds a paradox an unstable pair "
                    "runs as an ordinary experiment and the warning says so; a "
                    "discovery pays pages and nothing else; no stir hint, and one "
                    "time per Lab level. Curation (G54): a swap previews at once "
                    "and free and applying it weaves the new law at §5.6's price "
                    "and time, shown on its button; re-placing a choice law stays "
                    "free; the generator never unweaves, and weaves only into empty "
                    "slots (§13.3). The hold figure (G55): the stealth-path count "
                    "at once for every edit, the hold from TD.16's server "
                    "measurement shown as “measuring…” until it lands, a defence "
                    "outside its band saved with a warning and judged against its "
                    "origin's band, and a curated defence turning authored once "
                    "its terrain is edited (§13.3).",
             gate="the Resonance Lab row's hints as §8.6 writes them, with the "
                  "hint after the third empty experiment and not the second (a "
                  "server test); a curation swap charged §5.6's price and time and "
                  "a choice law re-placed free (server tests); the hold figure "
                  "equal to TD.16's measurement, and “measuring…” until it lands "
                  "(a presenter test)",
             blocked_by=["TD.22", "TD.16"],
             register=["G53", "G54", "G55"]),
        dict(id="TD.22", owner="claude", status="blocked",
             title="Lab, defence curation, terrain editor and Workshop",
             detail="The Lab at §10.2's times (5 h at level 3, not the design's "
                    "5 h 30) on TC.12's Lab service; curation over the generator's "
                    "alternatives, changing laws at TD.14's weaving prices; the "
                    "terrain editor on the simulation's features and §6.1's "
                    "budgets (not the design's 80 points, or its Hill and Grove), "
                    "placing the six directional features TD.38 built (the "
                    "prototype builder already lays and turns them); and "
                    "the Workshop on the design, keeping remix and withdraw. Every "
                    "resonance, feature, law and ladder text is read from content; "
                    "one Lab chamber a slot with its price and the Archivist-cut "
                    "time; one guard's sight, hard-edged, in curation and the "
                    "editor (§21.12); moss by default with a Clear moss tool; "
                    "“turn a post” on the designs' four-way facing dial (§13.3), "
                    "the facing TD.38 carries; a raid shown only once it "
                    "has ended; publishing once "
                    "the checks pass (D83). The Lab's hints, chord naming and "
                    "payouts (G53), curation's swaps as weaves (G54) and the hold "
                    "figure (G55), as v3.7 wrote them, are TD.65's.",
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
                    "and season-end reward, the season's end shown as a date and "
                    "never as a running count of days or hours (§18.8's “No "
                    "countdown pressure”, which the owner's fix brief echoes, "
                    "screen-review.md:423), the week's era "
                    "from <code>GET /v1/era</code>, claiming through a tier in one "
                    "call, and TD.40's goals and streak. Shop: an authored "
                    "catalogue (D64), and the band's cap and approval words before "
                    "every purchase; its previews on your universe are TD.46's. "
                    "Share sheet: the challenge to chosen friends, the invite gift "
                    "on a friend's first heist, and deep links for both; the clip "
                    "is TD.46's, and there is no posting to the Beacon and no "
                    "grading of moments, sharing as §20.7 sets it by band (D86). "
                    "Friends: each friend's free facts and the friendly-heist "
                    "score, and <code>POST /v1/reports</code> for players (§20.4: "
                    "report and block from any name), with no presence, last-seen "
                    "time, activity pills or pings and no status naming a raid's "
                    "target (§17.6, D86's recommended option, so TD.64 built "
                    "nothing). Prices are money at each store's local price with "
                    "no ✦ lines, F41's answer, which v3.7 writes (§22.1, F57); a "
                    "gift picks a friend, is paid as a store purchase and is "
                    "capped at three sent a calendar month at every age, with "
                    "approval words for minors only (§22.4), which needs a "
                    "monthly gift count on the server "
                    "(<code>server/src/shop.mjs</code> has none). The Season "
                    "header carries the week's era with its rule and end, and no "
                    "era gates anything (D85). The mechanics the design adds are "
                    "refused: a Starpass that adds 20% stars or ×1.2 and its "
                    "pass-only quest (§18.8), season and event quests and star "
                    "chests, a Sage on the free track, league rewards for everyone "
                    "(a realm skin for Star, Nova and Paradox only, as the server "
                    "grants), live “raiding” status (§17.8) (D84, D85). The Open "
                    "Vault league comes after launch (§9.4).",
             gate="the screen gate for the Season and Friends rows, the Shop row "
                  "but its previews and the Share sheet row but its clip (both "
                  "TD.46's); claiming through a tier is one call (a flow test); the "
                  "season's end shown as a date (a presenter test); a fourth gift "
                  "in a calendar month refused (a server test); the "
                  "shop, track and social tests kept by name (completion reads "
                  "them)",
             blocked_by=["TD.3", "TD.40"],
             register=["G28", "F41", "D84", "D85", "F57", "D86", "D64"]),
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
                    "the rating; heists by outcome, each by its own name with "
                    "Partial counted apart; defences held (Foiled) and leaked "
                    "(Clean, Loud and Partial), as v3.7 writes G69's recommended "
                    "option; the designs' ten records, each computed from the "
                    "heist rows and §13.2's facts; the battle log with replays "
                    "while they are kept; collection and §18.5's nine badges, "
                    "paying nothing, graded gold, silver and bronze at the "
                    "designs' marks, with nine counters on the server; titles "
                    "from mastery only; private for 13 to 15 and private by "
                    "default for 16 and 17 (§20.2), with the visibility switch in "
                    "Settings (TD.25). The server writes each heist's facts at "
                    "settlement from TD.39's record and answers "
                    "<code>GET /v1/profile</code> from heists, leases, Renown rows "
                    "and season results. A record or badge whose fact is not on "
                    "the server yet (pages, resonances and paradoxes, found in the "
                    "Lab) shows once it is; two records and the favourite law have "
                    "no fact the document defines yet, the register's (G57). "
                    "Profile opens from the "
                    "player's portrait on the universe map and from the star after "
                    "a heist, as the handoff has it (SCREENS.md:125); v3.6 is "
                    "silent, so the design is adopted.",
             gate="the screen gate for the Profile and stats row; a 13-to-15 "
                  "profile never served to another account, and a 16-to-17 one "
                  "only once its switch is on (server tests); a Foiled raid "
                  "counted held and a Partial one leaked and apart, and each "
                  "badge's grade at its mark (server tests)",
             blocked_by=["TD.3", "TD.13", "TD.25", "TD.39"],
             register=["G69", "D85"]),
        dict(id="TD.25", owner="claude", status="blocked",
             title="Settings and wellbeing in four tabs",
             detail="Protections the band fixes shown locked (§23.2, §20.2), "
                    "read from <code>content/protections.json</code>, generated "
                    "from the design facts the server's night hours and caps come "
                    "from; the band's cap, this month's spending and the adult "
                    "summary, shown here and before every purchase; deletion with "
                    "“withdraw my islands too” (D70, F43); notifications of "
                    "§14.6's four kinds only (storage full, crew rested, "
                    "experiment finished, you were raided), and a daily reminder "
                    "that starts at Off (D88) and whose picker offers no time "
                    "inside the night (G34); hold time and moving controls "
                    "(§20.8); help, "
                    "a ticket form and the contact (§20.10); the profile row by "
                    "band (D87). v3.7 wrote G58's recommended option, so one rule "
                    "and no switch: the band only tightens from the device, and a "
                    "looser band comes only from the platform's age service "
                    "(§20.1), so <code>PUT /v1/age</code> refuses any other "
                    "loosening; the play-time reminder is every 60 minutes, fixed, "
                    "for 13 to 15, every 60 or 90 (90 by default, never off) for "
                    "16 and 17, and off by default for adults, counting continuous "
                    "play in one session and shown when a heist ends, with no daily "
                    "limit drawn (§20.2). The server gains what the screen reads: "
                    "<code>GET /v1/notifications</code> and a raided opt-out, the "
                    "device's time zone with the push token and on every launch "
                    "(G34), and profile visibility stored and enforced wherever a "
                    "profile is read (§20.2: private for 13 to 15, private by "
                    "default for 16 and 17, the player's choice from 18). The "
                    "design's age-band preview changes the player's band and is "
                    "refused; the other bands show as a read-only comparison.",
             gate="the screen gate for the Settings and wellbeing row; every "
                  "protection §20.2 fixes shown locked for each of the three "
                  "bands (a presenter test); a loosening not from the platform "
                  "refused, and the reminder's interval by band with 16 and 17 "
                  "unable to turn it off (server and presenter tests)",
             blocked_by=["TD.3"],
             register=["D70", "F43", "G34", "D87", "D88", "G58"]),
        dict(id="TD.26", owner="claude", status="blocked",
             title="First launch in §23.5's order",
             detail="Title, the age step (the built check, restyled, with nothing "
                    "pre-selected and no way back from under 13), a summary of the "
                    "protections the band sets, the Keeper's name and face, then "
                    "§16's beats, each on its own screen with no skip and finished "
                    "by a real event: three ruleborn wake, the first heist on a "
                    "tutorial ruin and its result, two strays put to work at the "
                    "Star Well and the Garden, a law woven, the first five-minute "
                    "experiment, two more ruins to choose from, and three daily "
                    "goals, Keeper level 1 at the end. v3.7 wrote G58's and C51's "
                    "recommended options: the name is picked from word lists at "
                    "every age, as C43's answer gives islands, and raiders see it "
                    "as §12.4's free fact; it stays on the phone until the account "
                    "is made after the first heist, when the terms are accepted, "
                    "before friends, the Workshop or a purchase (§20.5, §25.2); "
                    "the first heist starts at 2:00, unguided, in a drifting ruin "
                    "that runs Slow rivers (§16, §15.2); and the first session's "
                    "weaves are instant and its first experiment free, §5.6's "
                    "times and §9.5's price starting after it (§16, C49). So it "
                    "lands last, on the screens and on the server's pieces: a ruin "
                    "lease mode and the tutorial set, the first session's grants, "
                    "the Keeper's name and face, the account made after the first "
                    "heist, and a first-session-complete flag. Whether the "
                    "starting universe holds the Lab §16 uses at 6:30 is the "
                    "register's (F56).",
             gate="§16's moments each finished by a real event in a flow test from "
                  "title to done; nothing but the age check before the first "
                  "heist, and no account made and no terms asked until it ends "
                  "(§25.2); a killed app resumes at the same beat; the "
                  "screen gate for the First launch row",
             blocked_by=["TD.16", "TD.17", "TD.18", "TD.19", "TD.20", "TD.21",
                         "TD.22", "TD.25", "TD.40", "TC.12"],
             register=["F56", "C51", "D87", "G58"]),
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
             title="Landscape for the heist and its result",
             detail="Screens v3 designs portrait only (§23.5), and v3.6 disagreed "
                    "with itself on where landscape ships (C55). v3.7 wrote the "
                    "recommended option, heists only: at launch only the heist "
                    "and its result can be turned to landscape, the choice "
                    "remembered per device, never rotating mid-heist, with the "
                    "same information in both; every other screen stays portrait, "
                    "and the rest of the interface gains landscape with tablets "
                    "(§23.3, §21.1, §12.7, §24, §27.2). So this task is those two, "
                    "the HUD a right column, on TD.17's flat view and TD.42's 3D; "
                    "<code>client/project.godot</code> is portrait only today. "
                    "What a tablet shows at launch, given that sentence, is not "
                    "stated; that is the register's (C55).",
             gate="the layout check in landscape for the heist and its result, in "
                  "both languages, at 100%, 150% and 200% text; every other "
                  "screen held in portrait, and the choice remembered across a "
                  "restart (tests)",
             blocked_by=["TD.6", "TD.17", "TD.42"],
             register=["C55"]),
        # -- Measuring it -----------------------------------------------------
        dict(id="TD.47", owner="claude", status="done",
             title="Completion's proofs: the store builds, crews, terrain, and "
                   "§26.8's phases 4a to 4c",
             detail="<strong>Done.</strong> Completion reads all 15 of v3.7's "
                    "build phases, 4a, 4b and 4c included, and 100 deliverables "
                    "where it read 47. Backend 89.24% to 62.36% and frontend "
                    "75.41% to 42.91%, from: phase 4a (22 runs: three of nine "
                    "built, experience two parts of three), 4b (32 runs, 21 "
                    "screens, none at its gate) and 4c (20 runs, none); the "
                    "abilities, Sage powers and casts and the event log in phase "
                    "1; terrain at 5 of 39 features and moss, the builder scaled "
                    "by it; buildings on the grid; the paradox-born, visitors and "
                    "rule sheets; reference crews, the generator and linked "
                    "universes; the launch cosmetic sets and the Island Fund; the "
                    "device's notifications and the edge purge; the edge load run "
                    "and store notifications pointed at the server; and phase 0's "
                    "store builds (none) and engine pin (2 of 3). Project "
                    "structure now reads the client's architecture tests. "
                    "<br><br>Three places where completion read something other than "
                    "what is built. The store builds: v3.7's §26.8 counts them in "
                    "phase 0, “here and nowhere else”, where completion counts "
                    "them in phase 2 with a proof that reads nothing; one proof "
                    "reads a recorded build (engine version, SDK levels, the "
                    "upload) for each store, in phase 0, and phase 2's Project "
                    "structure proof stops counting them (G68). Crews reads done "
                    "without abilities, Sage powers or casts, and Terrain editing "
                    "with five of 39 features and no moss: each proof gains the "
                    "missing system, so the figure reads what is built (G67). And "
                    "v3.7's §26.8 now costs the home economy, the interface "
                    "screens and the art pass as phases 4a, 4b and 4c (G42, G66), "
                    "which completion cannot see: it reads a phase by its number "
                    "alone, so a letter after it drops the row. It reads them, "
                    "and gives each the deliverables §26.8's notes name, each "
                    "through a passing proof: 4a TC.12's server slices, 4b each "
                    "screen's gate in track D, 4c TD.7's manifest. The figure "
                    "falls once, when the new phases join what it weighs, and "
                    "says so in the change.",
             gate="Crews and Terrain editing read their missing systems as not "
                  "built until TD.12, and TD.15 and TD.38, land; the store builds "
                  "count only in phase 0, from a recorded build; "
                  "<code>python3 tools/completion.py --self-test</code> reads §26.8's "
                  "phases 4a, 4b and 4c, and every one has deliverables with "
                  "proofs that exist",
             register=["G66", "G67", "G68", "G42"]),
        # -- The owner's ------------------------------------------------------
        dict(id="TD.29", owner="you", status="done",
             title="Settle what the designs leave open, and take your answers into the document",
             detail="<strong>Done by v3.7.</strong> It writes every one of the 47 "
                    "answers you recorded on 25 and 26 September where it belongs, "
                    "each in its own option's words and listed in §32.8, so the "
                    "order the build followed (a recorded answer first, then the "
                    "document, then the design: C45) is now the document's own "
                    "sentence. And it closes every decision listed here by rule "
                    "rather than by asking: each takes the option its brief "
                    "recommended. The visual language: the designs' surfaces (D89 "
                    "B) and typefaces (D90 B), their icon finish with §21.8's "
                    "motion timings (D91 C), one toon look with screen-space "
                    "outlines (D92 C), outlined words measured against the outline "
                    "(G59 B), §21.3's budgets with a heist's realm at about 60,000 "
                    "triangles (D93 B), the designs' home arrangement held to "
                    "§21.1's measured rules (C44 B), the 390-point design reflowed "
                    "onto 360 (D98 A) and §21.1's camera kept as a rule (D75 B), "
                    "in §21, §20.8 and §23.5. The heist: held taps and modal menus "
                    "(G47 A; §12.5, §12.7, §12.18), the decisive moment and its tip "
                    "by rule (G48 A; §12.13), the worth question once a session, "
                    "“Loud” in words and “Left” as an estimate (C47 A; §20.3, "
                    "§12.9), and one guard's cone at a time (C57 A; §12.6, "
                    "§21.12). The rest: what a scout shows (D77 A; §12.4), three "
                    "to six targets with a Trace apart (C46 A; §12.3, §12.22), a "
                    "Sage's level as the Keeper's with no Insight (G52 B; §11.7), "
                    "a fixed 20-second Sage cooldown and a free first experiment "
                    "(C49 A), money prices and three gifts a month (F57 B; §22.1, "
                    "§22.4), one frame-rate rule and a drag budget measured by "
                    "camera (C52 C; §24), a third law slot in the Heart at the "
                    "second epoch (C56 A; §14.9), and a Trace only after a raid "
                    "that was not foiled and not past the twentieth (G70 A; "
                    "§12.3). Every task above that was to build a pending value "
                    "one token from another now builds the one written. Where your "
                    "fix brief to the designer differed from v3.6, the document "
                    "won and v3.7 keeps it so: primary controls of 48 points and "
                    "none in a corner (§21.1), and crew selected in the world "
                    "(§12.7, §12.18).",
             gate="every decision listed here settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document: "
                  "v3.7 writes each one's recommended option (its opening note)",
             evidence="design document v3.7 (What changed in "
                      "version 3.7; §32.8)",
             register=["C44", "C45", "D77", "C46", "G47", "G48", "C47", "G52",
                       "C49", "F57", "D89", "D90", "D91", "D92", "G59", "D93",
                       "C52", "D98", "D75", "C56", "G70", "C57"]),
        dict(id="TD.50", owner="you", status="done",
             title="Answer G51: what a server-checked heist knows of the crew",
             detail="<strong>Done by v3.7</strong>, which settled G51 by taking "
                    "its brief's recommended option (A): the lease and the replay "
                    "carry a crew manifest checked against the roster (§12.5), "
                    "growth compounds, the Spire's three places count as a home at "
                    "the Spire's level, and rest modifiers multiply (§11.4 to "
                    "§11.6). TD.34 builds it; where a Spire home caps a level is "
                    "the register's.",
             gate="G51 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §12.5, §11.4 to §11.6)",
             evidence="design document v3.7 §12.5, §11.4, §11.6",
             register=["G51"]),
        dict(id="TD.51", owner="you", status="done",
             title="Answer C53 and G62: the paradox-born",
             detail="<strong>Done by v3.7</strong>, which settled both by their "
                    "briefs' recommended options (A and A), in §11.8: the "
                    "Twinned's every hit and load counts twice (Damage ×2 and Loot "
                    "load rate ×2, for itself), its crew's abilities once, as one "
                    "body with the shared 120 health and 80 carry; and "
                    "paradox-born never stand on a Guardian Post and have no "
                    "forms. TD.35 builds it.",
             gate="C53 and G62 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §11.8)",
             evidence="design document v3.7 §11.8",
             register=["C53", "G62"]),
        dict(id="TD.52", owner="you", status="done",
             title="Answer C48 and G46: stability's open rules and faults",
             detail="<strong>Done by v3.7</strong>, which settled both by their "
                    "briefs' recommended options (A and A): upkeep on the "
                    "universe's share of capacity, a harmony once per shared note, "
                    "a crown law priced once by the Heart, Breaking refused and a "
                    "tier rise in place (§5.5, §5.6, §8.2, §29.1); and faults "
                    "opening from the deepest outer realm, one to four by band, "
                    "free facts for a raider and offered in the landing picker "
                    "(§5.4, §5.5, §12.4). TD.14 and TD.37 build them.",
             gate="C48 and G46 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §5.4 to §5.6)",
             evidence="design document v3.7 §5.4, §5.5, §5.6",
             register=["C48", "G46"]),
        dict(id="TD.53", owner="you", status="done",
             title="Answer G56: who sets a feature's direction",
             detail="<strong>Done by v3.7</strong>, which settled G56 by its "
                    "brief's recommended option (B): the owner sets each "
                    "direction and a held post's facing, the generator defaults "
                    "toward the nearest shortest route, the Workshop sandbox keeps "
                    "§6.1's budget at the island's realm level, and a Workshop "
                    "island is one realm (§6.1, §13.3, §12.17, §18.6). TD.15, "
                    "TD.38 and TD.22 build it.",
             gate="G56 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §6.1, §13.3)",
             evidence="design document v3.7 §6.1, §13.3",
             register=["G56"]),
        dict(id="TD.54", owner="you", status="done",
             title="Answer G57: the rehearsal crews and a raid's report",
             detail="<strong>Done by v3.7</strong>, which settled G57 by its "
                    "brief's recommended option (B): §13.2 defines denied, held, "
                    "seen and fired for one raid, written into the heist's row at "
                    "settlement, and §13 gives the cautious, greedy and fast crews "
                    "their rules. TD.39 builds them; the two Profile records with "
                    "no fact behind them are the register's.",
             gate="G57 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §13, §13.2)",
             evidence="design document v3.7 §13, §13.2",
             register=["G57"]),
        dict(id="TD.55", owner="you", status="done",
             title="Answer G69: held and leaked, records and badges",
             detail="<strong>Done by v3.7</strong>, which settled G69 by its "
                    "brief's recommended option (B): held is Foiled, leaked is "
                    "Clean, Loud and Partial with Partial counted apart (§12.9, "
                    "§23.2), and the designs' ten records and §18.5's nine badges, "
                    "paying nothing, ship. TD.24 and TD.66 build them.",
             gate="G69 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §12.9, §18.5, §23.2)",
             evidence="design document v3.7 §12.9, §18.5, §23.2",
             register=["G69"]),
        dict(id="TD.56", owner="you", status="done",
             title="Answer G49: the Codex's first chapter, meeting a law and mastery",
             detail="<strong>Done by v3.7</strong>, which settled G49 by its "
                    "brief's recommended option (A): chapter 1's twelve laws, two "
                    "of each school, and meeting a law by a route (§7.6), "
                    "§18.5's mastery tracks, and Codex notes from the heist rows. "
                    "TD.44 builds them.",
             gate="G49 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §7.6, §18.5)",
             evidence="design document v3.7 §7.6, §18.5",
             register=["G49"]),
        dict(id="TD.57", owner="you", status="done",
             title="Answer G58 and C51: minors' protections, every Keeper's name, and "
                   "the first session",
             detail="<strong>Done by v3.7</strong>, which settled both by their "
                    "briefs' recommended options (B and A): the band only tightens "
                    "from the device (§20.1), the play-time reminder by band "
                    "(§20.2), every Keeper's name from word lists (§20.2, §12.4), "
                    "and the terms taken when the account is made after the first "
                    "heist (§20.5); the first heist at 2:00, unguided, after the "
                    "title, the age check, the protections and the name (§16, "
                    "§15.2, §25.2). TD.25 and TD.26 build them.",
             gate="G58 and C51 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §16, §20.1, §20.2)",
             evidence="design document v3.7 §16, §20.1, §20.2, §25.2",
             register=["G58", "C51"]),
        dict(id="TD.58", owner="you", status="done",
             title="Answer C54: the Sparkwright's goggles and each kind's animations",
             detail="<strong>Done by v3.7</strong>, which settled C54 by its "
                    "brief's recommended option (A): round copper tinker's lenses "
                    "and a Mender's satchel of leaves (§11.11, §21.6), and "
                    "seventeen animations a kind, three of them work loops (§21.6, "
                    "§23.5). TD.62 builds it.",
             gate="C54 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §11.11, §21.6)",
             evidence="design document v3.7 §11.11, §21.6",
             register=["C54"]),
        dict(id="TD.59", owner="you", status="done",
             title="Answer G50 and G64: hatching and naming, and the visiting Stray",
             detail="<strong>Done by v3.7</strong>, which settled both by their "
                    "briefs' recommended options (A and A): the Hatch screen with "
                    "word-list names (§23.2, §20.2), a found stray's kind and form "
                    "from a law the crew crossed (§11.5), and the visiting Stray "
                    "drawn as a birth's with the Heart standing for the Nursery's "
                    "realm (§11.8, §11.9). TD.63 builds them.",
             gate="G50 and G64 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §11.5, §11.8, §23.2)",
             evidence="design document v3.7 §11.5, §11.8, §23.2",
             register=["G50", "G64"]),
        dict(id="TD.60", owner="you", status="done",
             title="Answer D86 and C50: friends' presence and the Open Vault league",
             detail="<strong>Done by v3.7</strong>, which settled both by their "
                    "briefs' recommended options (A and A): no presence, last-seen "
                    "time, activity or pings at launch (§17.6, §23.2), and the "
                    "Open Vault league after launch (§9.4, §26.1). TD.64 closes "
                    "with nothing built.",
             gate="D86 and C50 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §17.6, §9.4)",
             evidence="design document v3.7 §17.6, §9.4, §26.1",
             register=["D86", "C50"]),
        dict(id="TD.61", owner="you", status="done",
             title="Answer G53, G54 and G55: the Lab's rules, curation's swaps and the"
                   " hold figure",
             detail="<strong>Done by v3.7</strong>, which settled all three by "
                    "their briefs' recommended options (C, A and B): the Lab's "
                    "hint after three empty experiments, free chord naming from "
                    "level 3 and a failure's pages to the marked law (§8.5, §8.6, "
                    "§7.6); a swap applied as a weave at §5.6's price, the "
                    "generator never unweaving (§13.3); and the stealth-path count "
                    "at once with the hold measured on the server (§13.3). TD.65 "
                    "builds them, on TD.16's measurement.",
             gate="G53, G54 and G55 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §8.5, §8.6, §13.3)",
             evidence="design document v3.7 §8.5, §8.6, §13.3",
             register=["G53", "G54", "G55"]),
        dict(id="TD.68", owner="you", status="done",
             title="Answer C55: landscape at launch",
             detail="<strong>Done by v3.7</strong>, which settled C55 by its "
                    "brief's recommended option (A): only the heist and its result "
                    "turn to landscape at launch (§23.3, §21.1, §12.7, §24, "
                    "§27.2). TD.28 builds it; what a tablet shows at launch is the "
                    "register's.",
             gate="C55 settled, by an answer in "
                  "<code>docs/decisions/answers.json</code> or in the document "
                  "(v3.7 §23.3)",
             evidence="design document v3.7 §23.3, §21.1",
             register=["C55"]),
        dict(id="TD.48", owner="you", status="blocked",
             title="Target phones in hand, running TC.3's builds",
             detail="§26.2's art-style test reads on target devices, and TC.8 "
                    "measures on them: §24's reference device (a mid-range 4 GB "
                    "Android at 60 Hz), and the oldest supported iPhone and a 3 GB "
                    "Android, on which v3.7's §24 sets one floor of 30 frames a "
                    "second (C52's recommended option), each named in TC.3's "
                    "export presets and the store listing. This is having them and installing TC.3's "
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
                    "v3.7 settled (TD.37).",
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
                     "ship from the economy model's earlier run (C19). The "
                     "re-run is done (T2.6) and v3.7 quotes it in sentences, "
                     "not all of them its figures; the regenerated tables are "
                     "TD.72's to send and the owner's to print (TD.73). v3.3 "
                     "settled the other eight \u2014 the ward budget, the post "
                     "ladder, the hold band, what the generator weaves, the "
                     "authored laws, ward levels and pylons \u2014 and v3.7 "
                     "re-set the budget and the guards by realm level."),
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
