# The Vault, loading and what a full bag is worth — proposed specification

**Status: proposed.** This fills G4 and depends on `economy.md`, which sets what
a raid is worth in total. This spec sets what fraction of it the crew leaves
with, which is the part §12.6 calls the heist's core decision and does not
specify.

Report: `python3 tools/decision_support.py vault`.

---

## What exists today

| Where | What it gives |
| --- | --- |
| §12.6 | Vault health 1,500 per level; Breakers double damage; cracking adds 10% awareness per 5 s to Heart guards; each Carrier loads 150 loot/s "until full or until the exposed share is gone"; the phase lasts "about 30 s"; its decisions are "who cracks, who loads, when to stop loading" |
| §9.4 | A heist takes up to 25% of the Vault's exposed amount and 50% of each Storehouse, **"capped by the crew's carrying capacity"** |
| §9.6 | The haul is minted from a formula. Carrying capacity is not in it |
| §11.1 | Carry per role: Scout 60, Breaker 60, Carrier 300, Warden 80, Mender 60 |

**§9.6 dropped the carry cap and nothing replaced it.** That is the whole gap:
the document still describes a loading phase, still calls stopping-or-continuing
its core decision, and no longer has any mechanism by which loading more is worth
more.

---

## The finding: the phase is 25 seconds of cracking and 2 seconds of loading

### Cracking works, and validates the combat model

Vault health is 1,500 per level; a reference crew of one of each role deals 126
damage per volley at level 1 (§11.1, Breaker doubled), at one volley per 0.8 s
(`fights.md`):

| Crew level | Vault level | Health | Damage/s | Time | Awareness added to Heart guards |
| --- | --- | --- | --- | --- | --- |
| 1 | 1 | 1,500 | 158 | 9.5 s | 19% |
| 5 | 2 | 3,000 | 214 | 14.0 s | 28% |
| 8 | 4 | 6,000 | 270 | 22.2 s | 44% |
| 12 | 6 | 9,000 | 367 | 24.5 s | **49%** |
| 18 | 8 | 12,000 | 583 | 20.6 s | 41% |
| 25 | 10 | 15,000 | 999 | 15.0 s | 30% |

Ten to twenty-five seconds across the whole game, against a budget of "about 30 s"
that §12.6 set in a different section from the one that set Vault health, which
is different again from the one that set Power. **They agree.** That is the best
evidence available that one hit per 0.8 s for Power damage is the model §12.8's
wind-up was written for, and it is why `fights.md` adopts it.

It also means cracking is a *good* pressure device: half the way to an alarm, on
a meter the player is watching, with nothing random in it.

### Loading does not work

| | As written |
| --- | --- |
| Crew carry capacity | 560 loot |
| Reachable capacity | **300** — only Carriers load, and only into themselves |
| Time to fill a Carrier at 150/s | **2.0 s** |
| Decisions available in those 2 seconds | none |

So 260 of the crew's 560 units of capacity cannot be filled by any means the
document describes, and the phase the document calls a decision is two seconds
long with one option. The thirty seconds is cracking, and cracking is a progress
bar.

---

## Proposal

### 1. Everyone loads, and loading takes one decision's worth of time

| Role | Carry | Rate | Time to fill |
| --- | --- | --- | --- |
| Carrier | 300 | **30/s** | 10.0 s |
| Warden | 80 | **8/s** | 10.0 s |
| Scout | 60 | 8/s | 7.5 s |
| Breaker | 60 | 8/s | 7.5 s |
| Mender | 60 | 8/s | 7.5 s |

The rate scales with character level at **+5% per level, the same as Carry**
(§11.4), so time-to-fill stays at ten seconds for the whole game. Ten seconds is
not a guess: §12.6 sets its own target of one decision every 8–12 seconds, and a
loading window shorter than one decision cannot contain a decision.

This is a **5× cut to the stated rate**, which is a large change to a published
number and should be flagged as such at sign-off. The alternative — raising carry
capacity fivefold — breaks §9.4's exposure percentages instead.

Whole phase: ~25 s cracking + ~10 s loading ≈ 35 s, against §12.6's "about 30 s".

### 2. What a full bag is worth

`economy.md` sets the value of a raid:

```
H = P × 0.20 × grade × difficulty × richness × fatigue
```

This spec adds the term §9.6 deleted, in the only form that does not touch the
faucet's ceiling:

```
banked = H × (loot units carried out ÷ crew carry capacity)
```

A crew that fills every bag and gets out is worth exactly `H`, so the inflation
dial in `economy.md` is unchanged and still single. A crew that leaves at 60% is
worth 0.6 × H. **Loading longer earns more, linearly, up to a cap the crew's own
roster sets** — which is the answer G4 asks for, and it restores §9.4's
"capped by the crew's carrying capacity" without restoring §9.4's
percentage-of-holdings model that §9.6 rightly rejected.

Two consequences worth noting because they are free:

- **§12.6's escape decision is now priced.** "Whether to drop loot to run faster"
  costs exactly the fraction dropped. A Carrier is 15% slower when loaded
  (§11.1), so dumping half a bag to outrun a guard Carrier is a bet the player
  can actually evaluate.
- **Crew composition becomes a real choice.** A second Carrier raises capacity
  from 560 to 860 and costs a Warden's 420 health. Today that trade does nothing.

### 3. Exposure sets richness, not the fill fraction

§9.6's `richness` term already handles how much the target has, clamped to
0.7–1.3, with the explicit promise that "a clean raid on a fully sealed island
still pays 0.7". If exposure *also* capped the fill fraction, a poor target would
be punished twice and the promise would break.

So: **the exposed pool presented at the Vault is never smaller than the crew's
capacity.** How rich the target really is moves `richness`; how long the crew
stands there moves the fraction. The two terms stay orthogonal, which is what
makes either of them tunable.

§9.4's "25% of the Vault's exposed amount and 50% of each Storehouse" becomes a
statement about what the player *sees* — how the loot is distributed across the
realm, and therefore what the route is worth — not about what they are paid.

### 4. The open Vault keeps making noise

Cracking adds 10% awareness per 5 s to Heart guards (§12.6). An open Vault with
someone loading from it does the same. So a full 10-second load adds 20% on top
of the ~49% cracking already added, and the player watches a meter climb toward
the alarm while the bags fill.

### 5. The decision, and where its breakeven sits

Stop at fraction `f` and stay clean, or fill up and risk going Loud:

| | Value |
| --- | --- |
| Leave now, clean | `H × f × 1.0` |
| Fill up, go Loud | `H × 1.0 × 0.7` |

Pushing on pays iff **`f < 0.7`** — the Loud grade multiplier itself, with
everything else cancelling. Above 70% full, greed is a losing bet; below it, a
winning one. Three things follow:

- The breakeven is **one number, already in §12.9**, and tuning the tension of
  the game's emotional peak means moving the Loud grade and nothing else.
- It is **learnable**. A player who never does the arithmetic will still feel,
  after a dozen heists, that the last third of the bags is not worth it — which
  is exactly the shape a good rule of thumb has.
- Getting caught rather than merely seen drops the grade to Partial (0.4) *and*
  loses that crew member's units on the ground, so the downside is steeper than
  the Loud case and the bet is not symmetrical.

### 6. Storehouses

Same rules, no cracking gate worth the name: a Storehouse has a tenth of a
Vault's health per level and no sealed share (§9.4). They are the reason a route
matters, since loot taken on the way in is loot already in the bag when the Vault
alarm starts climbing — and under the fraction model, a crew that filled up at
two Storehouses can crack the Vault and leave almost immediately, taking the
awareness hit of cracking without the hit of loading.

That is a genuine strategy the current rules cannot express, and it costs nothing
to allow.

---

## What this forces elsewhere

| Section | Change |
| --- | --- |
| **§12.6** | Loading rates per role, not per Carrier. The open-Vault noise rule. Say the phase is ~35 s |
| **§9.4** | Reframe the exposure percentages as what the raider *sees*. Keep "capped by the crew's carrying capacity" — it is correct again |
| **§9.6** | Add the fill-fraction term. It is the only term that reintroduces player agency into a formula that is otherwise entirely about the raider's account state |
| **§11.1** | Carry is now load-bearing rather than decorative. It should be as prominent as Power |
| **§12.9** | The Loud multiplier is now the tuning dial for the heist's central decision, and should be labelled as such |

---

## Still open

- **The 30/8 loading rates** are derived from a decision cadence, not playtested.
  They should be the second thing soft launch watches, after `economy.md`'s 0.20.
- **What "loot units" are made of.** This spec treats the pool as undifferentiated.
  A later layer could make stacks distinguishable — Starlight, Essence, a law
  page, a stray — so that *what* to load becomes a decision as well as *how
  much*. That is more content and more UI, and it is not needed to close G4.
- **Whether the fill fraction should be shown as a number.** §12.6 already puts
  carried loot on the HUD. A percentage makes the 70% rule discoverable; a bar
  keeps it felt rather than calculated. This is a taste question and it changes
  how the whole phase reads.
- **Vault health per level is flat at 1,500** while crew power compounds at 1.08.
  The cracking table above is well-behaved only because Vault level and crew
  level rise together; if matchmaking ever pairs a level-25 crew with a level-2
  Vault, cracking is 3 seconds. §12.15's bands probably prevent it. Worth
  checking rather than assuming.
