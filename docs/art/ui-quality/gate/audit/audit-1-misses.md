# Blind audit 1: the misses, on main

Follow-up to [audit-1.md](audit-1.md), done by AD under P3-AD-audit-1b on 17
November 2026, against rubric v3. Lead cycle 122 scored the audit: six
misses (AD fails, the gate passes) and two false blocks (the gate fails,
AD passes). This file does three things:

1. It renders each miss again on main's build as it stood at the task's
   start (integration branch at 04301148, merged into `claude/ui-ad` at
   00e3ec8f) and labels it there. A fault that still holds goes to the
   lead as a request with a default (AD-R56 to AD-R59).
2. It gives one line per row on what the judge's critique saw against what
   AD's label saw, for the next revision of `prompts/02-display-type.md`,
   `prompts/08-colour-value.md` and `prompts/09-character.md`. The prompts
   are not revised here.
3. It records how the audit's 19 items and 43 labels joined the golden set
   as version 2 ([../golden/README.md](../golden/README.md), "Version 2").

## How the misses were rendered

Each miss was shot with `tools/render/shoot.sh` from main's working tree
and that screen's shot script in `client/tests/shots/`, with the same
settings the audit used (`TEXT=200 LOCALE=pt_BR` for a 200% item and
`CONTRAST=1 HC=1` for a high-contrast one). Home and character were shot
at 540×1170, and heist and result at 1080×2340. Each still was judged at
phone size, in grayscale and in zoomed crops. ΔL* readings come from
CIELAB L* on sampled face and ground pixels.

**The audit and the gate shot two states of two screens.** This explains
rows 7, 25 and 33, and the audit form must be fixed so it never happens
again:

- **Result.** The gate shot `screen_result.gd` with `SERVER=1`: the server
  state, with a crew strip of three portraits and a Starlight tile carrying a
  portrait badge. The audit's rule ("render the item's still") gave no
  environment, so AD shot the offline state: one +508 Loot card, "Re-simulated as the
  server would", and no crew.
- **Heist pilot-1.** The gate shot `screen_heist.gd` with `MANIFEST=1`,
  with the five named crew (the judge names Hollow and Bramble). AD shot the
  default three crew (Scout, Breaker, Carrier).

**For audit 2:** the sampler (`calibrate.py audit`) or the lead writes each
item's shot script and environment into the form, read from the verdict's
still, and the labeller renders exactly that. AD labels both states where a
screen has two, and the gate shoots both.

## The six misses on main

| Row | Item | Quality | Task, commit | AD on main | Holds? | Request |
|---|---|---|---|---|---|---|
| 1 | heist, high contrast | 8. Colour roles and value | P1-S1-pilot-2 a4d87d18 | fail | **holds** | AD-R56 |
| 7 | result, 100% | 9. Character presence | P2-S1-result-6 b5843368 | server state pass; offline state fail | **holds** (offline) | AD-R57 |
| 14 | character, 200% pt_BR | 2. Display type | P2-S3-character-2 6b7e6b42 | fail | **holds** | AD-R58 |
| 16 | home, 200% pt_BR | 2. Display type | P2-S2-home-4 1697a6c6 | pass | fixed | none |
| 18 | home, high contrast | 8. Colour roles and value | P2-S2-home-1 977edd5b | fail | **holds** | AD-R59 |
| 33 | result, 100% | 9. Character presence | P2-S1-result-2 aed28321 | server state pass; offline state fail | **holds** (offline) | AD-R57 |

- **Row 1, heist in high contrast: fail, holds.** The hc plates are flat
  mauve with no rim. Get out's face reads L* 36.7, the same as the panel it
  sits on, and the Walk plate reads 36.7 against the world's 48.2. Neither
  control is a value step off its ground. Gold fill sits only on Cast, which
  is right, but the controls around it sink.
- **Rows 7 and 33, result: the server state passes; the offline state
  fails and the fault holds.** On main with `SERVER=1`, the crew strip
  holds three portraits at a readable size, and the top earner's Starlight
  tile carries a portrait badge, so quality 9 passes. With no server, the
  result is one +508 Loot card and a "Re-simulated as the server would"
  line, with no crew and no portrait: a reward screen with no character
  (key frame `kf-result` puts the crew on it).
- **Row 14, character at 200% pt_BR: fail, holds.** The headline,
  subtitle and level line now carry an outline. But on words about 38 px
  tall in the 540 still, the outline is about 2 px, about 5% of the size,
  against the rubric's 12%. `_ink_large` in `character_screen.gd` sizes the
  outline as `max(1.5 pt, size × 0.12)`, where `size` comes from
  `get_theme_font_size`. That looks like the size before the text scale and
  `_wrap_in`'s shrink are applied, so the stroke stays at its 100% width.
- **Row 16, home at 200% pt_BR: pass, fixed.** 'Guardião 24' is inked
  with a hard drop. The counts are gold-gradient, with outline and drop.
  The state word, now translated ('Vibrante' for 'Humming'), is outlined.
- **Row 18, home in high contrast: fail, holds.** The goal card's XP bar
  is pale gold (237, 195, 120), in high contrast as in the normal look, so
  gold appears on something other than the main action (Collect). The key
  frame's progress bar is green. The fill comes from `KitHud.goal`
  (`client/ui/kit_hud.gd`, line 61: `Tokens.color("gold")`), called by
  `home.gd` `_show_goal`.

## Requests to the lead

Each request is filed in `docs/progress/status/AD.json`, non-blocking,
with this default.

- **AD-R56, heist in high contrast** (row 1).
  - Files: `client/scripts/heist_hand.gd` (the Get out and Walk
    plates, `UI.dress`) and `client/scripts/heist_hud.gd`.
  - Owner: S1. The hc plate fill may come from the kit's `rb_box.gd`, which
    K1 owns.
  - Default: an S1 task gives the hc plates the key frame's near-black card
    (#140C2A) with a cream line, puts Get out on the red danger plate, and
    sets every control at least one value step (ΔL* 20) off its local
    ground.
- **AD-R57, result offline** (rows 7 and 33).
  - Files: `client/scripts/result_screen.gd` and
    `client/scripts/result_fit.gd`.
  - Owner: S1.
  - Default: the offline (no-server) result shows the crew strip and the top
    earner's portrait, as the server state does. The gate's result still
    is shot in both states.
- **AD-R58, character at 200%** (row 14).
  - File: `client/scripts/character_screen.gd` (`_ink_large`, `_wrap_in`).
  - Owner: S3.
  - Default: the outline is computed from the size the words render at,
    after the text scale and the wrap shrink, so the outward stroke is at
    least 12% of that size.
- **AD-R59, home's goal bar** (row 18).
  - File: `client/ui/kit_hud.gd` (`KitHud.goal`, line 61).
  - Owner: K1 (kit). The caller is `client/scripts/home.gd` `_show_goal`,
    which S2 owns under P3-S2-home-states.
  - Default: the goal card's progress uses the key frame's green progress
    fill in both looks. Gold stays on Collect.

## What the judge saw against what AD saw

One line per row, for the next prompt revision. "Judge" quotes or
paraphrases the critique in `gate/verdicts/<task>/<commit>.json`.

**02, Display type** (`prompts/02-display-type.md`)

- **Row 14 (miss).** Judge, pass 3/3: "the subtitle and level line now
  carry a dark outline, and the 200 headline has an ink outline and a hard
  drop". AD: the outline is there but about 5% of the word size at 200%,
  against 12%. *The prompt should make the judge measure the stroke
  against the word size at the size shown, not just note that it exists.*
- **Row 16 (miss).** Judge, pass on a split (3 of 6 samples fail, under the
  4 that make a fail). The failing samples saw the counts as a flat cream
  fill with no hard drop, 'Guardião 24' unoutlined and 'Humming' plain
  white. AD: the same faults, and fail. *The split was right; the prompt
  should make the drop and gradient check one concrete look (zoom on the
  largest count) so the samples agree.*
- **Row 23 (false block).** Judge, fail 3/3: the counts are flat gold
  fills on dark plates with no ink outline, drop or gradient, while 'Keeper
  24' is stroked, so the rank breaks. AD: pass. Zoomed, each count runs from
  cream (254, 241, 200) at the top to gold (242, 196, 92) at the bottom,
  with an ink outline that nearly matches the plate's value. *The prompt
  should say that an ink outline on a near-black plate merges with it, and
  that a two-stop gradient is checked top to bottom on one glyph, not
  judged flat at 1x.*

**08, Colour roles and value** (`prompts/08-colour-value.md`)

- **Row 1 (miss).** Judge, pass 3/3: "Gold fill only on Cast…; Get out is
  a neutral plum…; every control stands off the dark ground in grayscale".
  AD: Get out's face is L* 36.7 on a 36.7 panel, and Walk is 36.7 on
  48.2. *The prompt should make the judge measure each control against its
  local ground (the panel or world right behind it), not against the
  screen's darkest ground.*
- **Row 18 (miss).** Judge, pass 3/3: "gold fill only on Collect, red only
  on attention badges, resource bars in their resources' colours". AD: the
  goal card's XP bar is gold. *The prompt's gold check should cover every
  gold fill (bars, rings, strips), not only buttons, and name progress bars
  as the usual place gold leaks.*

**09, Character presence** (`prompts/09-character.md`)

- **Row 7 (miss).** Judge, pass 3/3: three crew portraits in the strip,
  two to three times kf-result's size, and a portrait badge on the
  Starlight tile. AD: fail, but on the offline still, which has no crew.
  *Not a prompt fault: the two looked at different states. The judge was
  right about the still it saw.*
- **Row 33 (miss).** Judge, pass 3/3: three crew portraits, 55–60 px at
  960 wide. AD: fail, on the offline still. *Same as row 7.*
- **Row 25 (false block).** Judge, fail 3/3: "Hollow merges with its ring,
  Bramble is low in contrast", on the `MANIFEST=1` still. AD: pass,
  borderline, on the three-crew still, where Scout (cream on a yellow ring)
  is the weakest but still reads. *Part state, part rule: the prompt should
  say a portrait fails only when its face (eyes and outline) cannot be
  read, not when its fur is close in value to its ring.*

## Golden set version 2

The audit's 19 items and 43 labels joined the golden set as version 2
(`../golden/items.json`, ids `audit1-*`, `golden_version` 2,
`joined_from` "audit-1"). The labels are AD's from `audit-1.md`, with its
critiques, and the stills are AD's audit renders at each item's commit
(`renders/`), halved to 540×1170 where they were shot at 1080×2340. The two
result items use the offline still AD labelled, not the gate's server still.

- **None goes into the held-out third.** Each is dealt to third 1 or 2.
  The held-out third keeps its 20 version 1 items, so that
  `held-opus` stays comparable, and `golden.py check` sizes the held-out
  third on version 1 items only.
- **The held-out re-run is due with the next prompt revision**
  ([../calibration.md](../calibration.md), "Where it stands"): when 02, 08
  and 09 are revised from the lines above, the held-out third is run once
  on that revision.
