# Ruleborn

> Your islands. Your rules. Their treasure.

A strategy game about floating islands that each follow a magic rule. You collect
these rules, build your islands around them, and send a small crew of odd little
creatures to rob other players' islands by outsmarting theirs.

Native mobile (iPhone and Android), Godot 4.5, rated 13+, cosmetic-only
monetisation.

## Status

**Pre-production — design analysis complete, no code yet.**

The game is fully designed in `docs/design/`. The first step was a deep analysis
of that design, which is in `docs/analysis/`.

Nothing should be built until the stage 0–3 work in
[`docs/analysis/07-recommended-next-steps.md`](docs/analysis/07-recommended-next-steps.md)
is done. In short:

0. Two gates — does a no-loss heist feel tense, and will players build islands?
   **The prototype that runs both is built and published**
   ([`prototypes/heist-gate/`](prototypes/heist-gate/README.md)). What remains is
   sending the link to 15-30 people and reading the codes back
1. Reconcile 19 confirmed contradictions in the design document
2. ~~Rebuild the economy model~~ — **done**, `tools/economy_model/`
3. The determinism spike on real devices — this gates all gameplay code
4. A launch-scope decision

## Repository layout

```
docs/
  design/     the game design document, as delivered, plus a greppable extract
  analysis/   the deep analysis of that document — start here
prototypes/
  heist-gate/  a throwaway browser build that runs both pre-code gates
tools/
  extract_design_doc.py         HTML -> greppable text
  check_design_consistency.py   machine checks behind the analysis
  parse_gate_results.py         scores the gates from testers' result codes
  economy_model/                the day-by-day model §24 references but omits
```

## The design in one page

**Setting.** The Book of Laws burst open and its pages scattered across the sky.
Wherever a page landed, an island lifted into the air and began to follow what was
written on it. Keepers gather torn pages, restore them, and write the laws into
their own islands.

**Loops.** A heist is 2.5–4 minutes; a session is 5–9; a discovery takes 2–5 days;
a season is 8 weeks.

**The two scarce things.** *Stability* — how much law a universe can hold — and
*character time*, since a ruleborn can work, guard or raid but never two at once.
Almost every decision resolves to one of these.

**Content at launch (as designed).** 48 laws in 6 schools, carrying 8 notes that
produce harmonies, dissonances, 44 signature resonances and 12 chords; 39 terrain
features; 18 ruleborn in 144 law-shaped forms; 16 buildings; 7 realm types; 4
Sages.

**Architecture.** One deterministic, fixed-point simulation written without engine
types, compiled into the phone app and to WebAssembly on the server, so both run
the same code. A heist is a seed and an input log of under 2 KB. That single
decision buys server-authoritative anti-cheat, free replays and analytics,
rehearsals, balance bots, and an infrastructure bill of roughly $5–15 a month at a
million monthly players.

**Money.** Cosmetics and a season pass. No paid randomness, no power, no login
rewards, no engagement-tuned matchmaking — with the refusals written down so they
cannot creep back in.

Full detail: [`docs/design/ruleborn-game-design-v2.3.html`](docs/design/ruleborn-game-design-v2.3.html).

## Tools

```bash
# regenerate the greppable text extract from the HTML design document
python3 tools/extract_design_doc.py \
    docs/design/ruleborn-game-design-v2.3.html \
    docs/design/ruleborn-game-design-v2.3.txt

# machine-check the design document for the inconsistencies found in the analysis
python3 tools/check_design_consistency.py docs/design/ruleborn-game-design-v2.3.txt

# economy model: reports and tests
python3 -m tools.economy_model
python3 -m tools.economy_model.test_economy_model

# score the two pre-code gates from testers' result codes
python3 tools/parse_gate_results.py results.txt
```

## The prototype

A playable four-minute test of the two riskiest premises is published at
**https://claude.ai/artifact/3jW7Zg1rTrzR6CF3cEVp2E** — see
[`prototypes/heist-gate/README.md`](prototypes/heist-gate/README.md) for how to
run it, who to send it to, and how to read the results.
