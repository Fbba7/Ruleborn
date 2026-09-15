# Corrections — the clerical sweep

Thirteen register items that are not decisions. Each is a single edit with an
obvious right answer, and together they are one working session. Listed so they
can be swept in one pass rather than rediscovered one at a time.

Nothing here changes how the game plays. The items that do are in the other
files in this directory, or in the decision reports.

| # | Section | Says | Should say | Why |
| --- | --- | --- | --- | --- |
| **C7** | §7.3, §24 | "fixed 20 steps a second" | **30** | §24.10 is the later simulation contract and is self-consistent: it states a heist is 4,500–7,200 ticks, which is exactly 30 × 150–240 s. Settle it **before** the golden replays, which encode it |
| **C9** | §23.2 | Law Codex shows "36 laws by school and rank" | **48** | 36 is the size of Codex chapter 3 (§7.6). Stale number |
| **C10** | §26.1 | 30 traits at launch | **31**, and decide Starborn | §11.3 enumerates 31; §17.3 names a "rare Starborn trait" that appears in no list. Either add it (32) or drop the reference |
| **C11** | §21.9 | 23 screens | **27** | §23.2 lists 27. Four screens of interface work and their icons are unbudgeted |
| **C12** | §22.5 | "Every revenue figure in 22.2 assumes 15%" | Footnote the high scenario | Its €168,000 is computed at 30%, which is *correct* — €204,000/month crosses Apple's $1M threshold — but it makes the three scenarios non-comparable. Worth surfacing that revenue between roughly €70k and €85k a month is partly a dead zone |
| **C13** | §12.3 or §9.6 | Targets within 3 Keeper levels; a payout tier for "three or more below" | State that the 0.25 tier is reachable only via challenge links, friendly heists and Trace | Otherwise the tier is unreachable in normal play |
| **C14** | §12.9 | Renown as 100% / 80% / 50% / −50% | Multipliers on the formula's 8–40 output, with the sign convention stated | "−50%" of a gain the raider did not make has no meaning |
| **C15** | §12.8, §12.17 | Tiles in one place, metres in the other | Metres throughout | They reconcile at 1 tile = 1 m (§21.1), but one unit should be used |
| **C16** | §12 opening | "a three-minute run" | 2.5 to 4 minutes | §12.2 and §5.4 already say so. The marketing line and the spec should not disagree |
| **C17** | §27.2 | "Fallbacks are Lawkeep and Ruleborn" | Remove Ruleborn | It *is* the chosen name. Leftover from the v2.2 rename |
| **C18** | §9.1 | Aether cap = 5,000 per Spire level + 3,000 | **5,000 × level**, matching §10.2's table | Or change the table. Aether gates how much law can be re-woven in a session, so the cap matters |
| **C20** | §21.8 or §21.9 | "every law also has a sound signature" | Either say sounds are **per school**, or budget 48 law sounds | The 48 laws share 6 sounds, one per school, eight times each. §21.9's budget of 6 school stingers matches the content, not the claim |
| **C8** | §10.2, §26.1 | The Library is referenced four times and is not a building | Add it as a 17th building with a full level table, **or** fold the trickle into the Observatory or the Spire | It is the mitigation for "pages are raid-only", which review 10 flagged as punishing the building half of the audience. Not clerical in importance — only in effort |

## Three of these are worth doing first

**C7**, because the golden replays encode the tick rate and rewriting them later
is expensive.

**C8**, because it is the only one on this list that is load-bearing. A page
faucet that exists in four references and no table will be discovered by whoever
implements the page economy, at the worst moment.

**C20**, because it is the difference between budgeting 6 audio assets and 48,
and §26.8's estimate does not know which.

## What prevents the rest recurring

Most of these are a number written down twice. `tools/generate_docs.py` now emits
the tables that exist only to summarise something else — §11.2's roster, §7.4's
law summary, §29.1's formulas — from `content/`, and `--check` fails the build if
a generated file has been hand-edited. `./tools/check_all.sh` runs it.

That does not cover prose, which is where C9, C11, C16 and C17 live. For those
the answer is the split in D10: a specification that states each fact once, and a
research archive that cites it rather than restating it.
