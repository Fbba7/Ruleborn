# Detection — reconciled specification

**Status: proposed.** This resolves contradiction C1 by making §12.17 authoritative
and retiring the older model. It needs sign-off before the numbers are locked
(§26.7). Nothing here is new design — it is §12.17, stated once, with the
consequences for the sections that still carry the older model spelled out.

Data: [`content/detection.json`](../../../content/detection.json).
Reference implementation: [`prototypes/heist-gate/`](../../../prototypes/heist-gate/README.md).

---

## Why this file exists

The design document specifies detection twice. §12.8 came first: one 120° cone at
six tiles, awareness in percent per second, two guard states. §12.17 came later,
out of review 11, and is complete: three range zones inside a narrow cone plus
weak peripheral vision, a 0–1000 suspicion meter, six states, and noise that
travels along walkable paths.

§12.17 presents itself as the fix — "the most important system in the game, and
until now the least specified" — but §12.8 was never retired. So three other
places still carry the old model, and one of them is the formulas appendix.

**This is the single most blocking item in the register.** Guard behaviour, every
stealth balance number, and the HUD that draws vision cones all wait on it.

---

## The model

A guard's perception is **deterministic**. There is no probability anywhere in
detection: a player who scouts an island can predict exactly what will happen.
That is a design rule as much as a technical one, and it is required regardless,
since the server re-simulates every result (§24.2).

### Vision: three zones inside a cone, plus the corner of the eye

Not one cone. A single cone gives either absurd long-range vision or blind close
range, which is why shipped stealth games converge on nested zones.

| Guard | Cone | Near | Mid | Far | Corner of the eye | Turn |
| --- | --- | --- | --- | --- | --- | --- |
| Scout | 45° | 0–2 m | 2–4 m | 4–6 m | 110° | 6°/tick |
| Warden | 40° | 0–1.5 m | 1.5–3 m | 3–4.5 m | 90° | 3°/tick |
| Breaker | 35° | 0–1.5 m | 1.5–2.5 m | 2.5–3.5 m | 70° | 8°/tick |
| Carrier | 30° | 0–1 m | 1–2 m | 2–3 m | 60° | 4°/tick |
| Mender | 40° | 0–1.5 m | 1.5–2.5 m | — | 100° | 4°/tick |

One tile is one metre (§21.1). A guard standing a level higher sees a metre
further; one standing below loses its far zone entirely.

### Being noticed takes time

Each guard carries a suspicion value from 0 to 1000. At 30 ticks a second
(§24.10):

| Zone | Fills in | Per tick |
| --- | --- | --- |
| Near | ~0.5 s | 67 |
| Mid | ~1.0 s | 33 |
| Far | ~2.8 s | 12 |
| *Decay* | *~1.7 s* | *20* |

It empties more slowly than it fills, which is what creates the tail after a
close call. **A state cannot fall back for half a second once reached** (15
ticks), so nothing flickers at the edge of a zone.

| State | At | What the guard does |
| --- | --- | --- |
| Unaware | under 200 | Patrols or holds its post |
| Suspicious | 200–599 | Stops, turns toward it, stays on route |
| Investigating | 600, or on hearing something | Walks to the spot and searches nearby for ten seconds |
| Alerted | 1000 | Calls out, converges, raises the alarm. **Never lethal** — the crew is knocked out and sent home |
| Searching | after losing sight | Twenty seconds of wider, faster searching |
| Returning | after giving up | Walks home, still easily re-alerted |

### Modifiers on the fill rate

| Condition | Effect |
| --- | --- |
| Crouched | × 0.5 |
| Running | × 1.75 |
| Unlit tile | × 0.5 |
| Inside the peripheral arc, outside the cone | × 0.5 |
| Standing still in tall grass | **invisible** until a guard walks into the tile |

### Noise travels the way a crew walks

Sound follows the walkable path rather than passing through walls, so a wall
genuinely muffles direction: a guard turns toward the way around, not toward you.

| Action | Heard within | Action | Heard within |
| --- | --- | --- | --- |
| Crawling | silent | Landing from one level | 2 m |
| Crouched walk | 1 m | Landing from three | 4 m |
| Walking | 2.5 m | Breaking something | 5 m |
| Running | 4.5 m | | |

Gravel and water are louder (× 1.25), moss quieter (× 0.75). Guards far off
screen hear at half strength, so nothing is lost to something the player could
not have seen.

### The alarm

Spreads by distance, not everywhere at once: guards within 4 m start
investigating half a second later. The realm alarm climbs 0 → 6, one step every
thirty seconds and one per knocked-out guard discovered. At 5, another Warden
arrives at an entrance. Rising pressure with no dice in it.

### Ambush

The one part of §12.8 that survives, because §12.17 does not cover it:

- The first hit on a guard that has not noticed the crew stuns it for 2 seconds
  and deals triple damage. Two ambush hits knock out a guard of equal level.
- Every guard attack shows a 0.8-second wind-up. A stun or freeze during it
  cancels the attack and dazes the guard for a second.
- A level advantage counts for at most 3 levels, so a well-played crew can rob a
  stronger universe and a careless strong crew can still be caught.

---

## What this supersedes

Adopting this means four edits elsewhere. None is optional — leaving any of them
is how the contradiction survived to v2.3.

| Section | Currently says | Must become |
| --- | --- | --- |
| **§12.8** | One 120° cone at 6 tiles (8 for Scouts); awareness fills 50%/s in sight, 75%/s within 3 tiles; investigate at 50%, alarm at 100% | Behavioural description only — what each guard *role* does and how it is beaten. Every number moves here |
| **§5.4** | "Guards within 6 tiles of the landing spot start at 25% awareness" | Restate in suspicion units: **250 of 1000**, within 6 m, unless the spot is in fog, darkness or tall grass |
| **§29.1** | The formulas appendix carries the old awareness row verbatim | Regenerate from this file. The appendix encoding a superseded model is the worst case, because it is where an implementer looks for the number |
| **§21.12** | Already correct | No change. It describes drawing *this* model: one cone at a time, sharp edges, the fill travelling from the guard's eyes toward the crew |

Units: §12.8 uses tiles, §12.17 uses metres. They reconcile at one tile per metre
(§21.1), but the document should pick one and use it throughout — that is C15.

---

## What the prototype confirmed

The browser prototype implements this model at 30 Hz with integer positions, and
it plays. Three things worth recording before the numbers are locked:

**The zone model is readable on a phone.** Drawing one cone at a time with sharp
edges and a fill that travels from the eyes, per §21.12, produces a guard whose
attention you can read at a glance. Five overlapping cones would not.

**The half-second near-zone fill is fast but fair.** Walking into a guard's face
gets you caught in about a second, which is correct — but it made the *first*
build feel unfair for a different reason, below.

**Instant capture is the problem, not detection.** In the first build an alerted
guard caught every crew member within a tile, instantly. That read as unfair
rather than tense and would have produced a false negative on the tension gate.
The prototype now requires **1.6 seconds of contact** and catches **one crew
member at a time**, leaving room to run.

That change is not in the design document, and it should be. §12.14 sets the rule
that failure stays temporary and that no effect removes control for more than two
seconds; instantaneous total capture sits badly with both. **Recommend adopting
a contact time into §12.8's surviving behavioural section.** See G2 — what
happens when a guard catches you is otherwise unspecified.

---

## Settled since this was written

All three of this spec's open questions were answered, two by v3.0 and one by
v3.1. They are kept here with what answered them, because a spec that silently
drops a question reads as if it never asked one.

- **G2 — combat resolution.** §12.20: one hit every 0.8 seconds for damage
  equal to Power, on both sides; the crew may fight at any moment, but hitting
  a guard that has not been ambushed sends its suspicion straight to 1000.
  §12.8 was rewritten around it.
- **G1 — pathfinding and the world model.** §12.18, adopting the reading in
  [`movement.md`](movement.md): tiles for terrain and building, continuous
  millitile position and facing, breadth-first pathfinding with a fixed
  neighbour order. The numbers below are on that model.
- **C7 — the tick rate.** 30 steps a second, stated once in §24.10, with §7.3's
  conflicting 20 gone. v3.1 pins it in `data/constants.json` beside the section
  that owns it, and `tools/check_document.py` fails the build if a second copy
  disagrees. **The golden replays can be written.**

## Still open

- **Height and detection.** §12.17 gives a guard a metre more sight from above
  and no far zone from below. What that does to the zone boundaries at each of
  §6.2's four height levels is not stated, and this spec assumes the flat case.
