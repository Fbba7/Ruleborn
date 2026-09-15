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
         "duplicate."),

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

# ===========================================================================
# Blocking — these prevent content authoring or core code
# ===========================================================================

dict(id="C1", kind="contradiction", severity="blocking", status="open",
     title="Two incompatible detection models",
     refs=["12.8", "12.17", "5.4", "29.1"],
     body="§12.17 specifies three vision zones inside a 30–45° cone plus "
          "peripheral vision, a 0–1000 suspicion meter, six guard states and "
          "noise travelling along walkable paths. §12.8 specifies one 120° cone "
          "at 6 tiles, awareness in percent per second, and two states. §12.17 "
          "presents itself as the fix, but §12.8 is left intact, §5.4's landing rule "
          "is written in the old percentage model, and <strong>§29.1, the formulas "
          "appendix, encodes the old model</strong>.",
     rec="§12.17 is authoritative. Rewrite §12.8 as behavioural description only, "
         "restate §5.4's landing noise in suspicion units, and regenerate §29.1 "
         "from §12.17. Blocks guard AI, all stealth balance, and the HUD."),

dict(id="C2", kind="contradiction", severity="blocking", status="open",
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

dict(id="C4", kind="contradiction", severity="blocking", status="open",
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

dict(id="C5", kind="contradiction", severity="blocking", status="open",
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

dict(id="C6", kind="contradiction", severity="blocking", status="open",
     title="Two ruleborn rosters, disagreeing on three roles and most abilities",
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

# ===========================================================================
# Significant
# ===========================================================================

dict(id="C7", kind="contradiction", severity="significant", status="open",
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

dict(id="C18", kind="contradiction", severity="significant", status="open",
     title="Aether storage: formula or table?",
     refs=["9.1", "10.2"],
     body="§9.1 gives the Aether cap as 5,000 per Spire level plus 3,000. §10.2's "
          "Spire table gives a flat 5,000 × level — 5,000 at level 1, "
          "50,000 at level 10. The formula would give 8,000 and 53,000.",
     rec="Small, but Aether is the weaving and upkeep currency, so the cap gates how "
         "much law a player can re-weave in one session."),

dict(id="C13", kind="contradiction", severity="significant", status="open",
     title="Matchmaking cannot reach its own worst difficulty tier",
     refs=["12.3", "9.6"],
     body="§12.3 offers targets within 3 Keeper levels. §9.6's difficulty multiplier "
          "has a tier for targets “three or more below” paying 0.25×. "
          "If the Observatory never offers such targets, that tier is unreachable in "
          "normal play.",
     rec="Either widen the offered band, or state that the 0.25 tier exists only for "
         "challenge links, friendly heists and Trace targets."),

dict(id="C14", kind="contradiction", severity="significant", status="open",
     title="Renown for a foiled heist is undefined",
     refs=["12.9"],
     body="The outcomes table gives Renown as a percentage — 100% / 80% / 50% / "
          "−50% — while the formula below it produces an absolute value of "
          "8 to 40. “−50%” of a gain the raider did not make has no "
          "meaning.",
     rec="Express all four outcomes as multipliers on the formula's output, and "
         "state the sign convention explicitly."),

dict(id="C9", kind="contradiction", severity="significant", status="open",
     title="The Codex screen says 36 laws; there are 48",
     refs=["23.2", "7", "26.1"],
     body="The Law Codex screen spec says “36 laws by school and rank”. "
          "36 is the size of Codex chapter 3 (§7.6), so this is probably a stale "
          "number rather than a disagreement about the collection."),

dict(id="C10", kind="contradiction", severity="significant", status="open",
     title="Trait count: 30, 31 or 32?",
     refs=["11.3", "17.3", "26.1", "11.5"],
     body="§11.3 enumerates 31 traits (6 body, 5 heist, 11 law-linked, 9 home). "
          "§26.1's launch table says 30. §17.3 references “the rare Starborn "
          "trait”, which appears in no list. §11.5 also says strays arrive with "
          "three traits while §11.3 says every ruleborn is born with two."),

dict(id="C11", kind="contradiction", severity="significant", status="open",
     title="Screen count: 23 or 27?",
     refs=["21.9", "23.2"],
     body="§23.2 lists 27 screens to design; §21.9's asset list says 23. The "
          "difference is four screens of interface work and their icons."),

dict(id="C12", kind="contradiction", severity="significant", status="open",
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

dict(id="C15", kind="contradiction", severity="minor", status="open",
     title="Guard vision is given in tiles in one place and metres in another",
     refs=["12.8", "12.17", "21.1"],
     body="§21.1 establishes that one tile is one metre, so the two reconcile — "
          "but the document should pick one unit and use it throughout."),

dict(id="C16", kind="contradiction", severity="minor", status="open",
     title="“Three-minute heist” against a 150–240 second clock",
     refs=["12", "12.2", "5.4", "14.1"],
     body="§12's opening calls a heist “a three-minute run”; the clock is "
          "150–240 seconds and §12.2 correctly says 2.5–4 minutes. Harmless, "
          "but the marketing line and the spec should not disagree."),

dict(id="C17", kind="contradiction", severity="minor", status="open",
     title="The game lists itself as its own fallback name",
     refs=["27.2", "26.9"],
     body="§27.2 says “Fallbacks are Lawkeep and Ruleborn” — but "
          "Ruleborn <em>is</em> the chosen name. Almost certainly a leftover from "
          "the v2.2 rename."),

# ===========================================================================
# Specified nowhere
# ===========================================================================

dict(id="G1", kind="gap", severity="blocking", status="open",
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
     rec="<strong>The largest gap, and the one most likely to fail §30.7's premise "
         "3.</strong> Specify it before the vertical slice and make felt control a "
         "gate rather than a polish item. Pikmin is cited as the model in §2.2; make "
         "that concrete."),

dict(id="G2", kind="gap", severity="significant", status="open",
     title="What happens when a guard catches you",
     refs=["12.8", "12.17", "11.1", "13"],
     body="§12.8 gives ambush rules and a level cap, and §12.17 says an alerted "
          "guard converges and is never lethal. But there is no combat resolution: "
          "roles have Power (6–40) and Health (130–420) and attacks have a "
          "0.8s wind-up, yet there is no attack rate, damage formula or range. Nor "
          "is it stated whether the crew can choose to fight, or what happens to "
          "loot carried by someone knocked out mid-run (§13 and §12.6 cover the "
          "clock-end and post-capture cases only)."),

dict(id="G3", kind="gap", severity="significant", status="open",
     title="Ward placement, triggering and disarming",
     refs=["10.3", "12.5", "11.1", "21.9"],
     body="§10.3 lists six wards with level-1 effects and reset timers. The Tinker "
          "trait “disarms wards 30% faster”, implying a disarm action that "
          "is never specified — who, how long, whether it makes noise. Also "
          "missing: what triggers a ward; levels 2–5, which the asset list and "
          "building table both assume; and ward health, given that Breakers deal "
          "double damage to them."),

dict(id="G4", kind="gap", severity="significant", status="open",
     title="The Vault's loading loop has no relationship to the payout",
     refs=["12.6", "9.6", "9.4"],
     body="§12.6 gives Vault health, Breaker double damage, cracking noise and a "
          "150-per-second load rate, and names “when to stop loading” as "
          "the Vault phase's core tension. But if §9.6's minted haul is "
          "authoritative (C2), loading longer earns nothing — so the phase's "
          "central decision currently has no mechanism behind it.",
     rec="Decide whether loading time scales the haul, or is purely a time-pressure "
         "device. Either is defensible; neither is stated."),

dict(id="G5", kind="gap", severity="minor", status="open",
     title="Law pylons have no count, health or placement rule",
     refs=["12.6", "5.7", "10.2", "5.1"],
     body="Breaking a pylon switches its law off for the rest of a heist and yields a "
          "page, and the Spire's light going out when one breaks is the Heart's "
          "signature moment. §10.2 lists Law Pylon as a building with ten levels and "
          "health, but the relationship between pylons and the law slots they "
          "presumably represent is never stated."),

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

dict(id="G9", kind="gap", severity="significant", status="open",
     title="The 60-second guided build is the top risk's mitigation and is unspecified",
     refs=["13.1", "27.2", "16"],
     body="§13.1 makes “a 60-second guided build before the first player "
          "heist” the primary mitigation for the design's number-one risk, and "
          "§27.2 confirms it as a decision. What three terrain features, which guard, "
          "which law, what the player is told, and — critically — whether "
          "the island they build then becomes their actual defence, are all unstated.",
     rec="Give it the treatment §16 gives the first session. It is the mitigation "
         "for the highest-ranked risk in the document."),

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
     rec="Decide which lever moves: raise the roster, cut permitted buildings, or "
         "make partial staffing genuinely worthwhile."),

dict(id="Q2", kind="decision", severity="choice", status="open",
     title="Should the raid-versus-build trade-off be made real, or dropped?",
     refs=["4", "11.6", "12.9"],
     body="F3 shows it is worth about 2% of production. It can be made real by "
          "making crew membership exclude work the way guarding does, or the claim "
          "can be removed from §4 and §11.6. What it cannot do is stay as written."),

dict(id="Q3", kind="decision", severity="choice", status="open",
     title="Three law ranks or five?",
     refs=["7.4", "7.10"],
     body="C3. Both work; the reasoning in §7.10 survives either. Choosing five means "
          "re-tagging 14 laws and re-deriving the page economy."),

dict(id="Q4", kind="decision", severity="choice", status="open",
     title="One producer per realm, or two?",
     refs=["5.2", "9.3"],
     body="F2. Two doubles income against every published pacing date; one matches "
          "the tables but contradicts §5.2. Interacts with Q1."),

dict(id="Q5", kind="decision", severity="choice", status="open",
     title="Accept the launch-scope cut?",
     refs=["26.1", "26.5"],
     body="D6. Roughly 40% less launch content, protecting the Island Workshop."),

dict(id="Q6", kind="decision", severity="choice", status="open",
     title="Casual pacing: leave it, or add the catch-up discount?",
     refs=["27.3", "14", "27.5"],
     body="Open in the document since v0.3. At one session a day, finishing "
          "everything takes about 1,019 days. §27.5 settles on a visible, openly "
          "labelled catch-up discount, but it is not specified."),

dict(id="Q7", kind="decision", severity="choice", status="open",
     title="The document's own open list",
     refs=["27.3"],
     body="Final names and the trade-mark check; whether the Island Fund survives its "
          "six-month test; whether to strengthen performative and emotional challenge "
          "after launch; Law Clash rules; soft-launch countries; whether the interface "
          "says “universe” or “your sky”; whether constellations "
          "later get a competitive mode."),
]
