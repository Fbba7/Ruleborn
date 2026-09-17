# What each phase is allowed to claim — proposed specification

**Status: proposed, and one half needs a decision that is not mine.** This
resolves C29: v3.0 rewrote how the project finds things out, and left two phase
gates standing that depend on the people the rewrite removed.

Reports: `python3 -m tools.heist_harness depth`, `defence`, `breakeven`.

---

## The contradiction, in three sentences the document already contains

§25.4 rules the panels out, in a sentence with no room in it:

> No recruited panels, no paid playtesters, no thirty people in a room.

§19.27 moves every instrument that needs a person to soft launch, and is
honest about the cost: *"nothing before soft launch tells us the game is fun.
The simulation tells us it is not broken, which is a different and smaller
claim."*

§26.2 then exits **phase 2** on *"At least 7 of 10 outside playtesters ask for a
second session"* and **phase 3** on *"at least 20% of testers still playing after
a week"*. Both sit two phases before soft launch, which is the earliest point the
other two sections allow a player to exist.

**This is not a number disagreeing with a number.** It is 10 to 12 weeks of work
whose exit test cannot be met as written, on the critical path, twice. The first
testing venue named anywhere in the document is TestFlight, in phase 4.

---

## The chosen reading

**§25.4 and §19.27 are right and §26.2 is stale.** Three reasons, in order of
weight.

1. **It is the supersession pattern, not a disagreement.** §19.27's own text says
   it replaced an earlier version that "asked for thirty people in a room". The
   validation strategy was rewritten; the phase table was not. That is C8, C10,
   C21–C23 and the detection model again — a fix landing in one section and not
   in the ones that depend on it.
2. **§26.2's gates predate the instruments that would meet them.** Phase 1's exit
   test already cites §19.27 by number. Phases 2 and 3 cite nothing and name
   people. They are older text.
3. **The panels were dropped for a stated reason that has not changed** — "that
   cohort does not exist for this project". Nothing in §26.2 supplies one.

**What this costs, stated plainly, because it is the larger half of the
decision.** §26.2's phase 2 gate — *would they come back unprompted* — is the
single most informative line in the whole phase table, and it is precisely the
question §19.27 concedes simulation cannot answer. Deleting it is cheap to type
and expensive to be wrong about. The replacement below is weaker and says so.

---

## What phase 2 exits on instead

A gate has to be passable, and "the harness thresholds" is not enough on its own
— phase 1 already exits on those. Phase 2 is the first build with *content* in
it: a Heart and two realms, 8 common laws, 6 ruleborn, 2 Sages. So the gate is
the phase-1 thresholds **re-measured against that content rather than against
the harness's own generated islands**, plus the one human instrument §19.27 does
offer:

> **The developer is the first player.** The honest test is whether the person
> who built it opens it without being paid to.

Written as an exit test:

| | Phase 2 exit test |
|---|---|
| **Structural** | On the slice's own two realms and eight laws, not on generated islands: 15–25 decisions a median run (§19.2); a near-capture in half of runs; hold rate 30–45% with no layer above a quarter (§13.2, §13.4) |
| **Human, weak, recorded as weak** | The developer opens the build unprompted on at least 10 of 14 consecutive days, logged by the build itself rather than remembered |

The second row is one person and it is weak evidence. It is written down as weak
evidence, which is §19.27's own convention, and it is the only thing in the plan
before soft launch that measures wanting to play rather than not being broken.

**Phase 3** loses its retention gate the same way and keeps the half that does
not need people: *"No dominant law in bot runs"* already stands on the ablation
in §13.4, and `defence` measures it.

---

## What the other reading would owe

If the ten testers are real — which is the owner's call, recorded as **T1.10** —
then §25.4's opening sentence is false and three things are missing, none of
which exist anywhere in the document:

- **A recruitment route.** §19.27 says the cohort does not exist. Ten is not
  thirty, and ten is reachable; nothing says from where.
- **A delivery channel.** TestFlight is phase 4. Phase 2 has no build anyone
  outside can install. The only artefact that has ever reached a stranger is the
  published prototype, and D12 records why it collects results as a copyable code
  rather than server-side.
- **A consent and privacy position.** §20 covers players of a shipped game under
  a rating. It does not cover ten recruited testers handling pre-release content.

This is not an argument against the branch. It is the bill, and it is small —
days, not weeks. The branch that looks free is the other one, and it is free
because it stops asking the question.

---

## Sections this forces a change to

The point of this file, per the pattern the register is about: a decision is not
finished until every section that restates it has been changed.

| Section | Change |
|---|---|
| §26.2 phase 2 | Exit test replaced — see the table above |
| §26.2 phase 3 | *"at least 20% of testers still playing after a week"* deleted; the law-dominance half stands |
| §25.4 | Either stands as written (chosen reading) or its opening sentence is corrected (other reading) |
| §19.27 | Unchanged either way; it is the section that is already right |
| §26.7 | Unchanged — it already says no step waits for other people |

Three drafted edits are in the register under C29, checked against the document
by `tools/check_edits.py`.
