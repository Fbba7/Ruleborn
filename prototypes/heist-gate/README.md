# Heist prototype — the two pre-code gates

**Live link:** https://claude.ai/artifact/3jW7Zg1rTrzR6CF3cEVp2E

A throwaway, single-file browser build that runs the two tests the design
document puts before any code is written. It is not a slice of the real game and
should never become one — the real client is Godot with a Rust simulation core
(§24.7), and this exists only to answer two questions cheaply.

## Why this replaces the paper prototype

§26.7 schedules a paper heist (§19.27) and a build-willingness test (§13.3)
before any code. Both are right, and both as written assume about thirty people
in a room. That cohort does not exist for this project, so the method changed
while the questions did not: **a link can be sent to strangers, a room cannot.**

It also answers a third question the paper version could not. §30.7's premise 3 —
whether a delegated crew feels like *playing* or *watching* — cannot be tested on
a board where a human moves the pieces, and it is the failure mode most likely to
sink the design.

## What it tests

| Gate | Question | Measured by |
| --- | --- | --- |
| 1 (§19.27) | Does a no-loss heist feel tense? | Two 4-item scales, plus **play-again clicks**, which is behaviour rather than opinion |
| 1b (§30.7 premise 3) | Playing, or watching? | One 5-point item, and orders given per heist |
| 2 (§13.3) | Will anyone build a second island unprompted? | Whether they click "Build another island" after being told they may stop |

The second gate is the one that matters most. It is ranked risk #1, and §26.7
calls it "the single decision that changes the most". The page is deliberately
written to make stopping easy and attractive at that moment — "That is the end of
the test. You can stop here… closing the page now is a perfectly good outcome" —
because a prompted second build measures nothing.

## Thresholds

Unchanged from the document.

**Gate 1** passes on: median tension ≥ 3 of 4, median enjoyment ≥ 6 of 10, and
**≥ 60% choosing to play again**. Felt control ≥ 70% at 4 or 5 of 5 (§30.8).

**Gate 2** branches three ways (§13.3):

| Second island built, unprompted | What it means |
| --- | --- |
| ≥ 30% | Authorship works as designed; build the creator ladder in §18.7 |
| 15–30% | It works with help: templates, guided build, the raid replayed back, early recognition |
| < 15% | Pivot: islands are largely generated and the player curates, tunes and names one. Every other system survives intact |

## Running it

**Sample sizes that are actually reachable.** §25.4 asks for three rounds of 5–8
testers rather than one round of five; §19.27 notes that ten to twenty people can
show a large effect but not measure a small one. These gates look for large
effects, so:

- 15–30 sessions for gate 1
- 15–20 completed builds for gate 2 — enough to tell 15% from 30%, not enough to
  tell 28% from 32%

**Where to find people.** A paid panel (§25.5 already budgets for one, and notes
an indie tier exists), a hobbyist community, a subreddit, a Discord. The artifact
is private until you share it from the page's share menu.

**What to say when you send it.** As little as possible, and nothing about what
you hope to find:

> Four minutes, on a phone or a laptop. There are no instructions beyond what's
> on screen. When you get to the end it'll show you a code — send that back.

Do not mention that building is being measured. Do not ask whether they will
build again; §13.3 is explicit that stated willingness is close to worthless
here, because the gap between intending and doing runs at about 46%.

**Silent observation, then questions** (§25.5). Thinking aloud during a timed
stealth run changes the run. If you watch someone, stay quiet and ask afterwards.

## Reading the results

Each tester finishes with a one-line JSON code. Collect them one per line in a
file and run:

```bash
python3 tools/parse_gate_results.py results.txt
```

It prints both gates against their thresholds and says which branch of §13.3 the
build rate falls into.

The code carries no names, no accounts and nothing typed. Its fields:

| Field | Meaning |
| --- | --- |
| `heists` | one entry per heist: `[n, outcome, loot, seconds, orders, caught]` |
| `again` | times they chose to play another heist — the behavioural tension measure |
| `survey` | `tense` and `pressure` (1–4), `control` (1–5), `enjoy` (1–10) |
| `built` | islands built |
| `second` | 1 if they built a second island unprompted — **gate 2** |
| `mins` | minutes in the session |

## What it is not

- **Not a balance test.** The island is hand-built, the vault is softened to 600
  health so cracking takes about eight seconds, and there are two guards. None of
  these numbers should be carried into the real build.
- **Not a determinism spike.** It uses a fixed 30 Hz tick, 1/256-tile integer
  positions and a seeded integer RNG to preview the §24.10 contract, but it has
  no golden replays and no cross-architecture check. That spike is still the
  gate on all gameplay code (§24.2).
- **Not a control scheme.** Tap-to-move with per-member selection is one guess at
  the gap §04's G1 records. If testers say "watching", the answer may be a
  different scheme rather than a different game.

## Notes on the build

- Detection follows §12.17: three vision zones inside a cone (45°/40° by role)
  plus weak peripheral vision, a 0–1000 suspicion meter filling in ~0.5 s near,
  ~1 s mid and ~3 s far, decaying more slowly than it fills, a half-second floor
  before a state falls back, and noise that travels along the walkable path so a
  wall genuinely muffles direction.
- Vision is drawn under §21.12: one cone at a time (the guard with the highest
  suspicion), sharp edges rather than gradients, the fill travelling from the
  guard's eyes toward the crew, and every other guard showing only its facing.
- Being caught takes 1.6 seconds of contact and only one crew member at a time.
  The first build caught all three instantly, which read as unfair rather than
  tense and would have produced a false negative on gate 1.
- Palette and typefaces are the document's own (§21.2, §21.8); the HUD is
  §21.8's heist layout.
- **No runtime capabilities are declared.** Declaring `db` would make the
  artifact organisation-internal and unshareable publicly, which would defeat the
  whole point. Results are local, and the tester copies a code back.
