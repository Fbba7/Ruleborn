# What the generator has to hit — proposed specification

**Status: proposed.** This resolves F9, F11 and F13, which are one chain: §13.3
makes a generated island every player's defence, F9 measured that those islands
miss §13.2's hold band, F11 measured that weaving the player's laws naively makes
them worse still, and F13 is the consequence — §12.22 promises a median target in
a band the pool does not contain.

It also records **F22**, which came out of building the fix: at realms 1 and 2 the
band is unreachable by any generator, because §5.2 allows one guard post there.

Reports: `python3 -m tools.heist_harness defence`, and the grid below is
`tools/heist_harness/island.py` with `shaped=` and `posts=`.

All figures: a competent crew — the crew §13.2's band is about — sign-aware laws,
two realms crossed, **n = 400 a cell**, ± one standard error.

---

## The two knobs are nearly orthogonal, and that is the specification

The generator has exactly two things it can move that reach a threshold:
how many switchback bands it lays (`shaped`), and how many guard posts it
fills (`posts`). Measured across realms 1 and 2:

| realm | posts | bands | hold rate | decisions | run |
|---|---|---|---|---|---|
| 1 | 1 | 0 | 5.5% ± 1.1 | 6 | 25s |
| 1 | 1 | 1 | 12.0% ± 1.6 | 13 | 41s |
| 1 | 1 | 2 | 16.5% ± 1.9 | 15 | 42s |
| 1 | 2 | 0 | 15.5% ± 1.8 | 8 | 30s |
| 1 | 2 | 1 | **44.8% ± 2.5** ✓ | 13 | 48s |
| 1 | 2 | 2 | 51.5% ± 2.5 | 15 | 51s |
| 2 | 1 | 0 | 13.0% ± 1.7 | 6 | 37s |
| 2 | 1 | 1 | 17.5% ± 1.9 | 15 | 52s |
| 2 | 1 | 2 | 21.5% ± 2.1 | 18 | 57s |
| 2 | 2 | 0 | **30.2% ± 2.3** ✓ | 9 | 46s |
| 2 | 2 | 1 | 56.8% ± 2.5 | 14 | 61s |
| 2 | 2 | 2 | 68.8% ± 2.3 | 14 | 57s |

✓ inside §13.2's 30–45% band.

**Bands drive the decision count; posts drive the hold rate.** At realm 1 adding
a post moves decisions by 0 to 2 and adding bands moves them by 7 to 9. The hold
rate needs both. So the generator has two targets and very nearly two independent
knobs for them:

> **Lay bands until §19.27's decision count is in 15–25. Then fill posts until
> §13.2's hold rate is in 30–45%.** In that order, because the first barely
> disturbs the second.

That is the rule §13.3 is missing. It currently says a generated island must be
"legal, coherent, and never empty", and every island measured here is all three.
**Effective is a different requirement and is not stated** — which was F9's point
and is still true.

---

## F22 — §5.2's guard posts put the band out of reach at realms 1 and 2

§5.2 gives a realm `1 + (level − 1) // 2` guard posts, so realms 1 and 2 get
**one**. Read the `posts = 1` rows above: realm 1 tops out at **16.5%** and realm
2 at **21.5%**, across every geometry tried, against a band that starts at 30%.

**No generator can fix this.** Geometry is worth 11 points at realm 1 and 8.5 at
realm 2; the gap to the band is 14 and 9 points *after* geometry has done
everything it can. The second post is worth 35 points at realm 1 — more than
every other lever combined.

The mechanism is F15's, and this is the second finding to land on it: guards are
half of the island's only detect-and-act chain. Geometry, wards and laws work by
**delay**, and delay reaches an outcome only through §5.4's clock, which has four
times the slack any delay needs. One guard is almost no detection, so there is
very little for the delay to convert into.

This matters more than the arithmetic suggests. **Realms 1 and 2 are where every
new player starts**, and F13 is exactly this seen from the matchmaker: §12.22
promises the median offered target sits in a 55–70% raider-success band, and at
realms 1 and 2 the pool runs at 78–95%. Step 4's widening cannot produce a target
that is not there.

**Recommendation: two posts at realms 1 and 2** — `2 + (level − 1) // 3`, or
simply a floor of two. It is one line in §5.2 and it is the only change measured
here that moves realms 1 and 2 into reach at all.

---

## The dial has to be a dial

With geometry as an on/off choice, realm 1 at two posts can be **15.5%** or
**51.5%** and nothing between — the band is stepped straight over. One band lands
at 44.8%.

This is not a detail about this generator. A realm's defence has very few
discrete settings early: the posts are integers and there are one or two of them,
the wards are `3 + level`, and the laws are whatever the player owns. **A layer
offered as a switch cannot be balanced against a 15-point band.** Whatever ships,
the geometry needs a strength the generator can turn, and §13.3 should say what
it is turned against.

---

## What weaving laws should do

F11 stands and is unchanged by any of this. Of the nineteen laws a rule sheet can
express, five help the defender and fourteen help the raider or cut both ways,
because laws apply to everyone in the realm (§7.3). Every figure above is with
sign-aware weaving, which is the best of the three generators F11 measured.

§13.3's "generated from their realm, their laws and their ruleborn" has at least
three meanings and two of them are worse than weaving nothing. **Say which.**

---

## Sections this forces a change to

| Section | Change |
|---|---|
| §5.2 | Guard posts: a floor of two, so realms 1 and 2 can reach §13.2's band (F22) |
| §13.3 | State what the generator targets — §13.2's hold band and §19.27's decision band — and that it weaves laws by sign |
| §13.2 | The 30–45% band applies to generated islands, not only designed ones (F9 asked for this) |
| §12.22 | Say what the matchmaker does when the band is empty rather than sparse (F13; edit already drafted) |

---

## What this does not fix

Stated because the grid measures it and it would be easy to leave out.

**The clock still decides nothing.** The last ten seconds decided 0–1% of runs in
every cell above, against §19.27's target of a quarter. Shaping the geometry
lengthens a run from 25s to 51s against a clock of 165s and does not bring it
close. F8 stands untouched.

**Near-captures saturate.** They run at 73% at the plainest setting and **100%**
at every shaped one, against a threshold of "at least 50%". F8 already noted that
a close call so common cannot register as one; shaping makes that worse, not
better. A threshold with no upper bound is why this passes while getting worse.
