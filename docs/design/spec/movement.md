# Crew movement and control — proposed specification

**Status: proposed, and partly new design.** Unlike the other files here, this one
does not reconcile two readings — it fills G1, which the document leaves empty.
Everything below is a proposal, grounded where possible in the working prototype
and in the document's own constraints.

Reference implementation: [`prototypes/heist-gate/`](../../../prototypes/heist-gate/README.md).

---

## Why this is the most dangerous gap

The document specifies, in fine detail, what guards *perceive* (§12.17) and what
laws do to movement *parameters* (§7.3: speed, direction, jumping, friction).
It never says how a crew moves, or how a player makes it move.

That matters more than a missing system usually would, because §30.7 rates
premise 3 — *delegated control still feels like agency* — as only **conditionally
supported**, and names the failure mode precisely:

> Agency survives delegation when outcomes are predictable from inputs. The
> failure mode is "my units are stupid" and the tipping point where a game feels
> watched rather than played. — §30.7

So the system that decides whether Ruleborn feels like playing is the one that
was never written down. §19.4 compounds it: performative challenge is "almost
absent by design", which means the moment-to-moment pleasure has to come from
*deciding*, not from executing.

---

## The world model: tile topology, continuous position

This has to be settled first, because two parts of the document assume different
things.

- **§6 is written in tiles.** Terrain features occupy tiles, cost points per tile,
  and block or slow movement per tile.
- **§12.17 assumes continuous space.** Vision zones are 0–1.5 m, 1.5–3 m, 3–4.5 m,
  and guards turn at 3–8 degrees per tick. Neither is expressible on a tile grid.

**Proposal: the topology is a tile graph; positions and headings are continuous.**

| Quantity | Representation |
| --- | --- |
| Terrain, cover, lighting, building footprints | Per tile |
| Pathfinding, noise propagation | Over the tile graph |
| Entity position | Continuous, fixed point — 1/256 of a tile |
| Entity heading | Continuous, as a fraction of a turn (§24.7) |
| Vision zones, turn rates | Continuous, in metres and degrees |

One tile is one metre (§21.1), so the two coordinate systems are the same scale
and no conversion constant is needed. The prototype runs exactly this — a 10×10
tile graph with 1/256-tile integer positions — and §12.17's zones and turn rates
work unmodified on it.

This also satisfies §24.7: positions are integers, so nothing about a result
depends on floating point.

---

## How a player moves the crew

**Tap a tile: the whole crew goes there. Tap a crew portrait first: only that one
goes.** That is the entire locomotion vocabulary, and it sits underneath §12.7's
existing controls rather than replacing them — abilities still fire from the
portraits, the Sage wheel and the cast wheel are unchanged, and the eight-control
ceiling holds.

Why this shape:

- It is one finger and one tap, which §21.8 requires (thumb reach, 9 mm targets).
- It scales from a crew of three to five without new controls (§12.5).
- Splitting the crew — which §12.7 already names as a control ("drag onto a path
  at a fork to split the crew") — becomes selecting one member and sending them
  somewhere, rather than a separate gesture.

### The rule that protects premise 3

**The crew never makes a decision the player did not make.**

No auto-attack. No auto-avoid. No auto-retreat when hurt. No re-routing around a
guard the player walked them into. The *only* automation is pathfinding — finding
a walkable route to the tile the player chose — and even that is shown before it
is committed: the intended path draws as a dashed line from each crew member to
their destination.

This is the direct answer to "my units are stupid". A unit cannot look stupid for
a decision it never made. It can only look stupid for executing the player's
decision badly, which is a pathfinding-quality problem rather than an agency
problem, and it is fixable.

The cost is honest: a crew that walks into a guard will walk into that guard. The
prototype suggests that is correct — being caught felt unfair when it was
*instant* (see below), not when it was the player's own doing.

---

## Pathfinding

**Breadth-first search over the walkable tile graph, with a fixed neighbour
order.** Not A*, not flow fields — the grids are 10 to 14 tiles across (§21.1),
so a full BFS is trivial, and determinism matters more than speed.

Three rules, all from §24.10's ordering requirements:

1. **Fixed neighbour order.** Right, left, down, up, evaluated in that order every
   time. Nothing may depend on hash-map iteration order, which §24.10 names as one
   of the three classic causes of divergence.
2. **Commands are recorded, never paths.** The input log stores "crew member 2,
   move to tile (7, 3), tick 411". The path is re-derived by the simulation. This
   is §24.10's "commands, never state", and it is what keeps a heist under two
   kilobytes.
3. **Re-path on terrain change, deterministically.** Bloom regrows hedges, Shifting
   stones moves walls, Crystal growth seals a gap. When the graph changes under a
   crew member, their path is recomputed from the same stored command. The player
   sees the dashed line redraw, which is also the feedback that a law just changed
   their route.

Crew members do not collide with each other — they are small creatures, and
mutual avoidance is both a determinism risk and a source of exactly the stupidity
premise 3 fears. When the whole crew is sent to one tile, each takes a distinct
destination from a fixed spread pattern around it (the tile itself, then right,
left, down, up), so they arrive as a loose cluster rather than stacking.

---

## Speed, and what laws do to it

Movement speed comes from the role table (§11.1: 2.6 to 4.5 tiles/s), then passes
through the realm's rule sheet (§7.3) — the one place laws are allowed to change
it. In per-tick integer units at 30 Hz (§24.10):

```
speed_per_tick = round(role_speed × 256 ÷ 30)
```

then multiplied by, in the fixed school order §7.3 gives:

| Source | Effect |
| --- | --- |
| Terrain | Marsh ×0.6, stream wading ×0.8, gravel ×1.15, thicket ×0.7 (§6.2) |
| Laws | Haste, Tilt, Current, Slow rivers, Honeycomb, Wild paths, Inward pull |
| Carrying | ×0.85 while loaded (§11.1, Carrier) |
| Sneaking | see below |

**Sneak is a proposed addition.** §12.17 gives crouched movement a noise radius of
1 m against walking's 2.5 m, and halves the rate at which a guard notices you —
so crouching already exists in the detection model. It has no control. Making it
a toggle gives the player a real, repeated decision (slow and quiet against fast
and loud) at the rate §12.6 asks for — one every 8 to 12 seconds — and costs one
button of the eight.

---

## What the prototype changed

Building this surfaced one thing that belongs in the design document.

**Capture must take time, and take one crew member at a time.** The first build
let an alerted guard catch every crew member within a tile, instantly. It read as
unfair rather than tense, and would have produced a false negative on the tension
gate. Requiring **1.6 seconds of contact**, one member at a time, fixed it — the
player gets a warning, a chance to run, and a loss they can attribute to a
decision.

Instantaneous total capture also sits badly with §12.14, which says failure stays
temporary and that no effect may remove control for more than two seconds. A
guard that ends the run on touch is the strongest control-removal in the game and
is not covered by that rule.

---

## How this gets tested

§30.8 sets the threshold: **at least 70% agreeing they felt in control.** The
prototype asks it directly ("did that feel like playing, or like watching?", 1–5)
and also records orders given per heist, against §12.6's target of 15 to 25
decisions a run.

If it fails, the answer may be a different control scheme rather than a different
game — that is exactly what a throwaway prototype is for. Two alternatives worth
holding in reserve:

- **Drawn routes.** The player traces a path before the clock starts, and the run
  executes it with the option to interrupt. More planning, less moment-to-moment.
- **Leader and followers.** The player drives one crew member directly and the
  others follow at an offset — closer to the Pikmin reference in §2.2, but it
  reintroduces the automation premise 3 warns about.

---

## Settled since this was written

- **G2 — combat resolution.** This spec assumed the crew mostly cannot choose
  to fight, and said so was an assumption. §12.20 settles it the other way and
  prices it: one hit every 0.8 seconds for Power damage on both sides, fighting
  allowed at any moment, and an unambushed hit sending a guard's suspicion
  straight to 1000. An open fight is an alarm with a price rather than a
  forbidden move, so the assumption below about movement under threat holds for
  a different reason than the one given.

## Still open

- **Height.** §6.2 gives four height levels with one-way drops, and §12.17 gives
  guards a metre more sight from above and no far zone from below. Movement
  between levels — ramps, stairs, vines, leaps — is specified as terrain but not
  as movement: what a leap costs, how long it takes, whether it can be interrupted.
- **Whether the crew can be ordered mid-ability.** Abilities have cooldowns and
  durations; whether a move order cancels one is unstated.
