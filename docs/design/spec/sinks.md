# Aether and Essence sinks — proposed specification

**Status: proposed.** This resolves F17, and it starts by correcting the finding
that produced it. F17 said the two resources have no sinks. That is true, but the
reason it gave — that the prices are too small — is wrong, and the right reason
changes what the fix has to be.

Reports: `python3 -m tools.economy_model sinks` and
`python3 -m tools.economy_model scaling`.

---

## First, a correction to the finding

F17 totalled §9.5's prices and found them small: every Essence sink in the
document is five days of income, every Aether sink but upkeep is under three
hours. Both figures are right. But a total is the wrong shape of measurement,
because a faucet runs every day and almost every price in §9.5 is paid once.

Totalled properly, over a whole account to day 301:

| | produced | every price there is | |
| --- | ---: | ---: | --- |
| Aether | 14,674,532 | 2,968,032 | the faucet is **5×** the sink |
| Essence | 6,660,571 | 658,501 | the faucet is **10×** the sink |

And those ratios are the *best* case. They are measured at day 301, by which
point every Essence price in the document is finished — the roster is at its cap,
every character is at level 10 — while the Gardens keep running. By day 600 the
ratio is 20×.

F17 also missed something, and it is the most interesting price in §9.5.

---

## §9.5 has exactly one recurring price, and the roster cap makes it unreachable

§11.6 rests a crew — 45 minutes after a clean escape, 60 after a loud one, 180 if
caught — and §9.5 charges **2 Essence per character level per minute of rest
left** to wake them early. That is the only price in the whole document a player
pays again every session. F17's audit did not count it, because the audit totalled
account-level purchases and this one is per-action.

Counted properly it is still nothing, for a much better reason: **it only falls
due when the player has nobody rested left to send.**

| roster | crews inside one rest window | heists a day before anyone must be woken |
| ---: | ---: | ---: |
| 5 | 1 | 28 |
| 10 | 2 | 57 |
| 20 | 4 | 114 |
| 38 | 7 | **199** |

§14.2's engaged archetype raids **four** times a day. The price falls due at 199.
It is charged at 2% of the rate anyone would have to play to meet it — and the
gap widens as the player grows, because the roster cap rises and the raiding rate
does not.

This is worth stating on its own, because it is the same shape as C19 and F1: two
numbers written in different sections, each reasonable, never multiplied together.
§11.5 set the roster cap; §11.6 set the rest window. Nobody divided one by the
other.

---

## The rule that explains all of it

Every price in §9.5 and every faucet in §9.3, measured from day 2 to day 301:

| | price | travels | |
| --- | --- | ---: | --- |
| Starlight | a Star Well level, 1 to 10 | **×1,478** | |
| Starlight | realm levels 2 to 5 | ×23 | faucet ×122 |
| Aether | weaving, at 40 a point (51 → 516 points) | ×10 | |
| Aether | upkeep a day, same sheet | ×10 | |
| Aether | a Lab experiment, Lab 1 to 10 | ×10 | |
| Aether | scouting a realm | **×1** | faucet ×240 |
| Essence | the next birth, 5th to 38th | ×88 | |
| Essence | a character level, 2 to 10 | ×33 | |
| Essence | waking one character, level 1 to 10 | ×10 | faucet ×251 |

Read the last column against the third:

- **Starlight's biggest sink outruns its faucet 12×.**
- **Aether's falls behind its faucet 24×.**
- **Essence's falls behind 3×.**

That is the whole of F17 in one line, and it is arithmetic rather than judgement.
Starlight is permanently scarce because §10.2's building curve is geometric and
never ends: there is always a level 11 and it always costs 1.35× the last one.
Nothing in the document points a geometric curve at Aether or Essence. Every
price aimed at them is either flat (scouting), linear (the Lab, waking) or capped
(births at 38, character levels at 10), and a bounded price against an unbounded
faucet loses by however long the game runs.

**So the prices are not mistuned. They are on the wrong kind of curve.** Raising
them raises the day the problem appears and changes nothing else — which is why
the edit F17 originally proposed (upkeep from 0.5 to 15 Aether an hour) is not in
this spec. It would have made the early game unplayable to postpone the late-game
problem by about forty days.

---

## Aether: price upkeep off the faucet that pays it

Upkeep is the right place to act, because it is the only price in the Aether list
that recurs and the only one attached to something players keep wanting more of.
The change is not its size but what it is a function of.

**Proposed: upkeep costs 0.05% of the player's own hourly Aether production, per
point of stability held.** The same principle `economy.md` adopted for the haul —
peg the number to the quantity it has to stay in proportion with, and the
proportion holds by construction instead of by re-tuning.

| day | Aether a day | points held | flat, as §9.5 prices it | pegged |
| ---: | ---: | ---: | ---: | ---: |
| 2 | 800 | 40 | 480 (**60.0%**) | 16 (2.0%) |
| 31 | 13,000 | 113 | 1,356 (10.4%) | 734 (5.7%) |
| 91 | 70,600 | 285 | 3,420 (4.8%) | 10,060 (14.2%) |
| 181 | 114,600 | 446 | 5,352 (4.7%) | 25,556 (22.3%) |
| 301 | 192,100 | 516 | 6,192 (**3.2%**) | 49,562 (25.8%) |

Look at the flat column before the pegged one. **§9.5's 0.5 an hour a point is
60% of a day's Aether on day 2 and 3.2% on day 301.** It is not a price that is
too low; it is one number doing two completely different jobs, because production
moved 240× underneath it while it stayed still. On day 2 it is close to
prohibitive — a new player who weaves their third law is spending most of what
they make to hold it — and by day 301 it has vanished.

Pegged, the same number means the same thing throughout: **holding a full sheet
costs about a quarter of your Aether**, at every stage of the game, and holding a
third of a sheet costs about a twelfth. Weaving becomes a decision with a
recurring price attached, which is what §5.5's strain mechanic already assumes it
is.

### It also repairs §9.1's cap without touching it

§9.1 caps banked Aether at 5,000 per Spire level plus 3,000 — 53,000 at Spire 10.
F17 recorded that as a cap so far below production (192,100 a day) that it is a
deletion rather than a cap. Under flat upkeep it holds 8.5 days of upkeep, which
is a buffer that never binds. Under the peg it holds **1.07 days** of upkeep.

That is a coherent design statement: *you can bank about a day's running costs.*
It makes going away for a week a real thing to plan around, which is what §9.5's
"paused after 24 hours away" clause exists to soften. One change, two of F17's
three complaints.

---

## What the peg does not fix, and what does

It does not fix the size. Pegging upkeep raises the share of a lifetime's Aether
the document has a price for from **12.3% to 18.5%**. It cannot do much more, and
the reason is the rule above: a sheet grows ×10 across the curve and Aether grows
×240, so even charging a full sheet's worth of hourly income leaves most of the
faucet unspent.

The other half has to come off the faucet. §10.2 sells ten levels of each
producer, and the ladders run far past anything to spend the output on:

| | the level that already covers every price in the document | levels §10.2 sells above it |
| --- | --- | --- |
| Aether Spring | **level 5** — 1.1× every Aether price there is | 5 more, up to 5× |
| Garden | **level 3** — 1.2× every Essence price there is | 7 more, up to 10× |

A Garden above level 3 and an Aether Spring above level 5 cost Starlight and
return a resource with nothing to buy. They are not weak upgrades; they are
upgrades with a return of zero, sold at §10.2's full geometric price — 591,200
Starlight for the tenth level of each.

**Cutting them is cheap**, which is the part worth noticing. Removing a producer
ladder deletes a Starlight sink, and Starlight is the one currency whose sink
already outruns its faucet 12×. The economy can afford to lose two ladders far
more easily than it can afford two dead currencies.

---

## Essence: the peg cannot be applied, and that is the finding

Aether has a recurring price to peg. **Essence has none at all**, and this is not
an oversight that a number fixes:

- **Births** end. §11.5 caps the roster at 38 homes, and §5.8 makes that cap the
  scarcity the whole design now rests on. Births *should* end.
- **Character levels** end. §9.5 caps them at 10.
- **Waking** is avoidable by rotation, as measured above, and rotation gets
  easier exactly as the roster grows.

So Essence prices the *acquisition* of the roster and nothing about *keeping* it.
Once the roster is full, Essence has finished its job and the Gardens have 250
more days to run.

Two ways out, and they are not equivalent.

**1. Give Essence a recurring price: characters cost Essence to keep.** Pegged
the same way — about 0.65% of Essence income per character per day puts a full
roster at roughly a quarter of income, matching the Aether proposal. It works,
and it is a mechanic this design has good reason to refuse: §1.2 promises
"nothing is wasted" and §1.3 is explicitly aimed at players "tired of
pay-to-win and endless timers". A roster that starves while you are away is the
thing those two lines rule out. Recorded as the alternative, not the
recommendation.

**2. Cut the faucet, per the table above.** Gardens stop at level 3, or their
curve flattens after it. Essence then does exactly the job §4 gives it — pacing
how fast the roster fills — and stops pretending to be a currency with a late
game.

**Recommended: 2.** §4 names *stability* and *character time* as the two scarce
things in the design, and Essence is neither. A resource the design does not
intend to be scarce should not be produced in quantities that make its scarcity a
question at all.

---

## What this forces elsewhere

| Section | Change |
| --- | --- |
| **§9.5** | Upkeep becomes "0.05% of your hourly Aether production per point held", not "0.5 Aether an hour per point" |
| **§9.1** | The Aether cap stays as written. Say what it is *for* — about a day's upkeep — because that is now true and was not before |
| **§10.2** | Aether Spring stops at level 5 and Garden at level 3, or both curves flatten there. Their Starlight costs above that come out with them |
| **§9.3** | The published production table is generated from §10.2's curve, so it changes with it. §30.18's own rule applies: generate it, do not re-author it |
| **§5.5** | Strain and upkeep now both scale with the sheet. Check they do not compound into a wall — see below |
| **§11.6** | Waking is priced but unreachable. Either say it is a first-week mechanic and let it fade, or delete it |
| **§14.2** | The archetype curves were computed with Essence unspent. Births are now the binding constraint for longer under either proposal |

---

## Still open

- **0.05% a point is fitted, not derived.** It was chosen to put a full sheet at
  about a quarter of Aether income, because that is the share that makes weaving
  a decision without making it a tax. The share is the thing to playtest; the
  peg is the thing to keep whatever share wins.
- **Strain and upkeep now move together.** §5.5 already penalises a sheet near
  capacity; a pegged upkeep charges for it too. Two costs on one axis can
  compound into a wall that neither was meant to be. This wants a pass through
  §5.5's own numbers before either is locked.
- **Cutting a producer ladder changes §14.2's whole curve**, because the model's
  purchase policy buys producers first. The archetype day-counts in §14.2 and the
  1,019-day figure in §27.3 are both downstream of it.
- **Whether the Aether cap should bind at all.** Making it mean "about a day's
  upkeep" is coherent, but it also means a player who is away for three days
  loses Aether they would otherwise have banked. §9.5's pause clause covers 24
  hours. Whether it should cover more is a retention question, not an economy one.
