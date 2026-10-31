# Key frames

Home and heist at the phone's size (390 x 845 points, each still 1080 x 2340),
on the approved style board's tokens (`../board/tokens.css`), in the game's own
words. Each page has three forms, and each form comes in English and Brazilian
Portuguese.

| Page | As written | Text at 200% | High contrast |
|---|---|---|---|
| `01-home.html` | `01-home.png` | `01-home_text200.png` | `01-home_hc.png` |
| `02-heist.html` | `02-heist.png` | `02-heist_text200.png` | `02-heist_hc.png` |

Each still has a `_pt_BR` twin and a `.shot.json` beside it, which lists the
rectangle of every control for `tools/ui_gate/checks.py value-steps`.

## Files

- `01-home.html` and `02-heist.html` are the pages. `?lang=pt_BR`, `?text=200` and `?hc=1`
  give the other forms.
- `kit.css` holds the shared parts: plates, pills, gold, glass, tabs, pins,
  the hand tray and the large-text changes. It uses token colours only.
- `kit.js` reads the mode from the address, fills in the words and numbers as the game writes
  them, adds the grain, and sets the realm pins clear of the interface.
- `words.js` is written by `build_words.mjs` from `client/i18n/strings.csv` and `content.csv`.
- `bg/` and `art/` hold the worlds behind the interface and the
  portraits, baked from the game by `bake.sh` (`bake_home.gd`, `bake_portraits.gd`).
- `shoot_keyframes.mjs` takes the twelve stills and their shots.
- `check_keyframes.mjs` holds the scripted checks. Its header lists each check.

## Running it

```
bash art/ui/keyframes/bake.sh                          # worlds and portraits, when they change
node art/ui/keyframes/build_words.mjs                  # words.js, when the strings change
node art/ui/keyframes/shoot_keyframes.mjs              # the twelve stills and shots
node art/ui/keyframes/check_keyframes.mjs              # the checks; --out report.json for rows
node art/ui/keyframes/check_keyframes.mjs --self-test  # each check fails what it should
```

## The forms

- **Text at 200%.** Every word doubles. Above 125%, the game's bars show icons only, so these changes apply:
  - only the chosen tab keeps its word;
  - the side buttons' names and the heist's chosen name, the Sage's plate and the button icons are hidden;
  - the hand lays its buttons out in rows;
  - a realm pin that cannot find room keeps only its level.
- **High contrast.** Every surface is opaque, with 3-point outlines, and the high-contrast world sits behind it.
