# Key frames

Home, heist, result, character and settings at the phone's size (390 x 845 points, each still 1080 x 2340),
on the approved style board's tokens (`../board/tokens.css`), in the game's own
words. Each page has three forms, and each form comes in English and Brazilian
Portuguese.

| Page | As written | Text at 200% | High contrast |
|---|---|---|---|
| `01-home.html` | `01-home.png` | `01-home_text200.png` | `01-home_hc.png` |
| `02-heist.html` | `02-heist.png` | `02-heist_text200.png` | `02-heist_hc.png` |
| `03-result.html` | `03-result.png` | `03-result_text200.png` | `03-result_hc.png` |
| `04-character.html` | `04-character.png` | `04-character_text200.png` | `04-character_hc.png` |
| `05-settings.html` | `05-settings.png` | `05-settings_text200.png` | `05-settings_hc.png` |

Each still has a `_pt_BR` twin and a `.shot.json` beside it, which lists the
rectangle of every control for `tools/ui_gate/checks.py value-steps`.
`contact_sheet.png` lays all thirty stills on one sheet: a row for each page, a
column for each form and language.

## Files

- `01-home.html`, `02-heist.html`, `03-result.html`, `04-character.html` and `05-settings.html` are the pages. `?lang=pt_BR`, `?text=200` and `?hc=1`
  give the other forms.
- `kit.css` holds the shared parts: plates, pills, gold, glass, tabs, pins,
  the hand tray and the large-text changes. It uses token colours only.
- `kit.js` reads the mode from the address, fills in the words and numbers as the game writes
  them (`k:KEY:arg` gives a key its own argument, as in `SETTINGS_TEXT_SIZE`), adds the grain, and sets the realm pins clear of the interface.
- `words.js` is written by `build_words.mjs` from `client/i18n/strings.csv` and `content.csv`.
- `bg/` and `art/` hold the worlds behind the interface and the
  portraits, baked from the game by `bake.sh` (`bake_home.gd`, `bake_portraits.gd`).
- `shoot_keyframes.mjs` takes the 30 stills and their shots; give it a page name to take one page's six.
- `contact_sheet.py` makes `contact_sheet.png` from the stills (1882 x 3085).
- `check_keyframes.mjs` holds the scripted checks. Its header lists each check.

## Running it

```
bash art/ui/keyframes/bake.sh                          # worlds and portraits, when they change
node art/ui/keyframes/build_words.mjs                  # words.js, when the strings change
node art/ui/keyframes/shoot_keyframes.mjs              # the 30 stills and shots
python3 art/ui/keyframes/contact_sheet.py              # the contact sheet, after the stills
node art/ui/keyframes/check_keyframes.mjs              # the checks; --out report.json for rows
node art/ui/keyframes/check_keyframes.mjs --self-test  # each check fails what it should
```

## The forms

- **Text at 200%.** Every word doubles. Above 125%, the game's bars show icons only, so these changes apply:
  - only the chosen tab keeps its word;
  - the side buttons' names and the heist's chosen name, the Sage's plate and the button icons are hidden;
  - the hand lays its buttons out in rows;
  - a realm pin that cannot find room keeps only its level.
  - the result and character pages scroll, so their still is the top of the page: what waits below the fold (`.below`) is not drawn and not measured;
  - on the result, Home keeps its house and its spoken name, and the rewards stand in rows;
  - on the character, the open tab keeps its word and the others their icons, the health stands under the level's steps, and Level up stacks its word over its level and price.
  - on the settings, the open tab keeps its word and the others their icons, and only the text card is drawn: the sample is read at the large size, and the shapes and switches wait below the fold.
- **High contrast.** Every surface is opaque, with 3-point outlines, and the high-contrast world sits behind it.

## Settings

- The text-size buttons are gold, not the game's leather: leather on the enamel
  card is less than one value step (ΔL* 20) from it, and `value-steps` fails it.
- The switches stand in framed parchment rows, not the game's frameless card
  rows, for the same reason.
- The bottom dock holds only the back button. In Portuguese, whose switch
  rows take two lines, one switch is drawn and the rest wait below the fold.
