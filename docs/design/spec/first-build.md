# The first build — proposed specification

**Status: proposed, and partly new design.** This fills G9. Like `movement.md`,
it is not a reconciliation — the document commits to this feature in three places
and never specifies it.

---

## What exists today

Three sentences, across three sections:

> **Everyone builds once, briefly.** Before the first heist against a player, a
> 60-second guided build: place three terrain features, one guard and one law. It
> is short, it is not optional, and it is the moment most players discover they
> enjoy it. — §13.1

§27.2 records it as a decision taken. §25.4 sets its success gate: 15–20% of new
players publish an island in week one.

That is the entire specification of **the primary mitigation for the
highest-ranked risk in the document.** §30.8 ranks "nobody builds defences" as
risk #1; §30.7 marks premise 7 as "largely contradicted" by every comparable
game; §26.7 calls the build-willingness answer "the single decision that changes
the most". Everything rests on sixty seconds that nobody has designed.

---

## The decision the sentence hides

**Does the island they build become their actual defence?**

The document never says, and the two answers are different features.

If it does not, this is a tutorial: a sandbox that teaches three verbs and is
thrown away. Cheap, safe, and it will not move the number it exists to move —
§49's finding is that *people value what they built themselves, but only when
they finish it*, and a discarded exercise is not finished.

If it does, it is an act of authorship with consequences, and the player's first
raid arrives against something they made.

**Proposal: it becomes their real defence, immediately and permanently.** That is
the only version that tests premise 7 rather than rehearsing it, and it costs
nothing extra — every player owns a realm by Keeper level 3 (§5.2) and needs a
defence anyway. The alternative is to spend the design's most load-bearing sixty
seconds on something the player is told does not count.

---

## When it happens

§13.1 says "before the first heist against a player". Placed against §16's own
timeline, that is **the start of the second session on day 2**, not the first
session:

| Moment | §16 |
| --- | --- |
| 0:00–10:00, day 1 | First session: a heist into a ruin, two strays, first law woven |
| Day 1 | Keeper level 3, first outer realm, first birth |
| **Day 2** | **The first heist against another player's universe** |

So the build sits at the top of day 2, after the player has raided a ruin and
seen a defence from the *outside* once. That ordering matters: they have met a
vision cone, tall grass and a law before being asked to place any. §15.1's rule
is to teach in context, the first time it matters, by doing — and the context for
"why would I put a hedge there" is having just been caught behind one.

It also means the first session is untouched, which §25.2 requires: playing
within 30 seconds, no account creation, one meaningful action.

---

## What the sixty seconds contain

Three terrain features, one guard, one law — §13.1's own list. What they should
be is not arbitrary; the set has to make a guard's cone mean something, because
that is the whole vocabulary of defence.

| Step | Place | Why this one |
| --- | --- | --- |
| 1 | **A hedge** | Blocks sight (§6.2). The first thing that makes a cone bend |
| 2 | **Tall grass** | Hides anyone still inside it. The counter to the hedge — teaches that cover works for both sides |
| 3 | **A lantern** | Lights 3 tiles, and nothing hides inside the light. Teaches that the defender can *create* exposure, not only block it |
| 4 | **One of your own ruleborn, on a Guardian Post** | §13's guards are your own creatures. This is where the character-time trade-off becomes visible for the first time (§11.6) |
| 5 | **Slow rivers** | Of the three starting laws (§7.6), the only one that is spatial, visible and defensive. Half gravity helps the raider; Bloom's regrowth needs a hedge to have been cut first |

Each step shows its effect immediately — the guard's cone redraws when the hedge
goes down, the lit circle appears with the lantern. §15.3's law banner and card
already exist for this; the build screen reuses them rather than inventing a
tutorial voice.

**Nothing is placed for the player.** A guided build that places things while the
player watches is a cutscene, and it would measure nothing.

---

## What happens next, and what is measured

The player watches a raid against what they just built — §13.3 requires this, and
it is also the payoff. A scripted crew, not a real one: the first island is not
put in the target pool until the player has seen how it holds.

Then the measurement, and this is where the **test protocol and the shipped
feature differ** — a distinction the document does not currently draw:

| | In the §13.3 test | In the shipped game |
| --- | --- | --- |
| After the raid | The player is **told they may stop** | Nothing is said |
| Second island | Whether they build one unprompted is the whole measurement | Whether they build one unprompted is logged |
| Why | Stated willingness is worthless here — the intention-behaviour gap runs at ~46% [218] [219] | Telling a player they may stop is not a thing a game says |

So the shipped version does not prompt a second build, and does not discourage
one. It ends, returns the player to their sky, and records what they do next.
§25.4's gate reads that log: 15–20% publishing in week one, 40% changing their
defence weekly.

---

## "Not optional" against "no obligations"

§13.1 says the build "is not optional". §20.3 says "no obligations: missing
co-op events, donations or anomalies costs nothing". Those sit oddly together and
the document does not reconcile them.

They are reconcilable, but the reason should be written down rather than assumed:
**§20.3 is about recurring demands, not about onboarding.** A one-time sixty
seconds before a feature unlocks is the same shape as §16's guided first heist,
which nobody would call an obligation. What §20.3 forbids is a thing that comes
back — a daily build quota, a weekly defence chore, a penalty for a stale island.

The safeguard is the time bound. If the guided build routinely runs past sixty
seconds in playtests, it has stopped being onboarding and become a chore, and it
should be cut back rather than defended.

---

## Why sixty seconds might be the wrong number

Stated without evidence in §13.1, and it is doing a lot of work.

Five placements in sixty seconds is twelve seconds each, including reading what
each piece does. §15.6's one-new-word-at-a-time rule and §7.9's cap of four
interacting rules both suggest that is fast. Against that, §25.2's funnel wants
the player back in the game quickly, and a long build is exactly the friction
that loses them.

**Recommendation: treat sixty seconds as a target, not a constraint, and measure
the real distribution.** The number that matters is not the median duration but
the drop-off — how many players abandon partway. If that is above a few per cent,
the step is too long whatever the clock says.

---

## What the prototype already does

The browser prototype implements a version of this: place three terrain features,
one guard and one rule, then watch a scripted crew raid it. It exists to run the
§13.3 test, so it uses the *test* protocol — it tells the player they may stop.

Two things it is not: it does not make the island a real defence (there is no
persistent universe), and it does not teach in context, because there is no prior
heist to have been caught in. Both are deliberate for a throwaway build, and both
are the difference between the test and the shipped feature.

---

## Still open

- **Which realm.** The player owns the Heart and one outer realm by day 2. The
  build should probably be in the outer realm, since the Heart cannot be landed
  on (§5.4) and its defence works differently — but §13.1 does not say.
- **What happens if they place badly.** The route rule (§6.1) forbids sealing the
  last path to the Heart, so some placements must be refused. What the refusal
  says, and whether it teaches or just blocks, is unspecified.
- **Whether the guard placed here counts against the roster.** Under F1 the roster
  is the binding constraint; committing a character on day 2 is a real cost, and
  whether the player understands that is the first test of whether the
  character-time trade-off reads at all.
