# The golden set's labels

The labelling form for the golden set (README.md beside this file). There is
one row for each item and each quality its class is judged on (gate/rubric.md,
"The method at a glance"). The images are in images/, named by item id.

How to fill it in:

- **Label:** `pass`, `fail` or `n/a`. Use `n/a` only when the quality has
  nothing to judge in that image, for example quality 9 on a crop with no
  character. A blank row means it has not been labelled yet.
- **Critique:** one line saying what you see that decides the label, in the
  rubric's words where you can. For example: "gold plate flat, no bevel or
  gloss; reads as a fill".
- Judge the image as it is, at 1x first and then zoomed in. Do not look at
  items.json's `expected` or `why` before labelling. It is the builder's guess,
  and the labels are meant to test that guess.
- Do not change the Item or Quality columns. `python3 tools/ui_gate/golden.py
  check` fails if the rows no longer match items.json.

Who labels: at O3, AD labels every row. At P0-AD-calibrate, the set is split
into thirds and a second labeller labels the held-out third blind. That
labeller is a fresh subagent given only rubric.md and the held-out images. The
two sets of labels are then compared row by row.

| Item | Quality | Label | Critique |
|---|---|---|---|
| today-home | 1. Layered materials |  |  |
| today-home | 2. Display type |  |  |
| today-home | 3. Painted or rendered icons |  |  |
| today-home | 6. Hierarchy |  |  |
| today-home | 8. Colour roles and value |  |  |
| today-home | 9. Character presence |  |  |
| today-home | 13. Light behind UI |  |  |
| today-home | 14. One art-direction idea |  |  |
| today-heist | 1. Layered materials |  |  |
| today-heist | 2. Display type |  |  |
| today-heist | 3. Painted or rendered icons |  |  |
| today-heist | 6. Hierarchy |  |  |
| today-heist | 8. Colour roles and value |  |  |
| today-heist | 9. Character presence |  |  |
| today-heist | 13. Light behind UI |  |  |
| today-heist | 14. One art-direction idea |  |  |
| today-result | 1. Layered materials |  |  |
| today-result | 2. Display type |  |  |
| today-result | 3. Painted or rendered icons |  |  |
| today-result | 6. Hierarchy |  |  |
| today-result | 8. Colour roles and value |  |  |
| today-result | 9. Character presence |  |  |
| today-result | 13. Light behind UI |  |  |
| today-result | 14. One art-direction idea |  |  |
| today-character | 1. Layered materials |  |  |
| today-character | 2. Display type |  |  |
| today-character | 3. Painted or rendered icons |  |  |
| today-character | 6. Hierarchy |  |  |
| today-character | 8. Colour roles and value |  |  |
| today-character | 9. Character presence |  |  |
| today-character | 13. Light behind UI |  |  |
| today-character | 14. One art-direction idea |  |  |
| today-settings | 1. Layered materials |  |  |
| today-settings | 2. Display type |  |  |
| today-settings | 3. Painted or rendered icons |  |  |
| today-settings | 6. Hierarchy |  |  |
| today-settings | 8. Colour roles and value |  |  |
| today-settings | 13. Light behind UI |  |  |
| today-settings | 14. One art-direction idea |  |  |
| v3-home | 1. Layered materials |  |  |
| v3-home | 2. Display type |  |  |
| v3-home | 3. Painted or rendered icons |  |  |
| v3-home | 6. Hierarchy |  |  |
| v3-home | 8. Colour roles and value |  |  |
| v3-home | 9. Character presence |  |  |
| v3-home | 13. Light behind UI |  |  |
| v3-home | 14. One art-direction idea |  |  |
| v3-heist | 1. Layered materials |  |  |
| v3-heist | 2. Display type |  |  |
| v3-heist | 3. Painted or rendered icons |  |  |
| v3-heist | 6. Hierarchy |  |  |
| v3-heist | 8. Colour roles and value |  |  |
| v3-heist | 9. Character presence |  |  |
| v3-heist | 13. Light behind UI |  |  |
| v3-heist | 14. One art-direction idea |  |  |
| v3-result | 1. Layered materials |  |  |
| v3-result | 2. Display type |  |  |
| v3-result | 3. Painted or rendered icons |  |  |
| v3-result | 6. Hierarchy |  |  |
| v3-result | 8. Colour roles and value |  |  |
| v3-result | 9. Character presence |  |  |
| v3-result | 13. Light behind UI |  |  |
| v3-result | 14. One art-direction idea |  |  |
| v3-character | 1. Layered materials |  |  |
| v3-character | 2. Display type |  |  |
| v3-character | 3. Painted or rendered icons |  |  |
| v3-character | 6. Hierarchy |  |  |
| v3-character | 8. Colour roles and value |  |  |
| v3-character | 9. Character presence |  |  |
| v3-character | 13. Light behind UI |  |  |
| v3-character | 14. One art-direction idea |  |  |
| v3-settings | 1. Layered materials |  |  |
| v3-settings | 2. Display type |  |  |
| v3-settings | 3. Painted or rendered icons |  |  |
| v3-settings | 6. Hierarchy |  |  |
| v3-settings | 8. Colour roles and value |  |  |
| v3-settings | 13. Light behind UI |  |  |
| v3-settings | 14. One art-direction idea |  |  |
| t14-heist | 1. Layered materials |  |  |
| t14-heist | 2. Display type |  |  |
| t14-heist | 3. Painted or rendered icons |  |  |
| t14-heist | 6. Hierarchy |  |  |
| t14-heist | 8. Colour roles and value |  |  |
| t14-heist | 9. Character presence |  |  |
| t14-heist | 13. Light behind UI |  |  |
| t14-heist | 14. One art-direction idea |  |  |
| t14-heist-hc | 1. Layered materials |  |  |
| t14-heist-hc | 2. Display type |  |  |
| t14-heist-hc | 3. Painted or rendered icons |  |  |
| t14-heist-hc | 6. Hierarchy |  |  |
| t14-heist-hc | 8. Colour roles and value |  |  |
| t14-heist-hc | 9. Character presence |  |  |
| t14-heist-hc | 13. Light behind UI |  |  |
| t14-heist-hc | 14. One art-direction idea |  |  |
| t14-hud-top | 1. Layered materials |  |  |
| t14-hud-top | 2. Display type |  |  |
| t14-hud-top | 8. Colour roles and value |  |  |
| t14-hud-top | 13. Light behind UI |  |  |
| t14-hud-bottom | 1. Layered materials |  |  |
| t14-hud-bottom | 2. Display type |  |  |
| t14-hud-bottom | 8. Colour roles and value |  |  |
| t14-hud-bottom | 13. Light behind UI |  |  |
| today-hud-top | 1. Layered materials |  |  |
| today-hud-top | 2. Display type |  |  |
| today-hud-top | 8. Colour roles and value |  |  |
| today-hud-top | 13. Light behind UI |  |  |
| today-hud-bottom | 1. Layered materials |  |  |
| today-hud-bottom | 2. Display type |  |  |
| today-hud-bottom | 8. Colour roles and value |  |  |
| today-hud-bottom | 13. Light behind UI |  |  |
| board-enamel | 1. Layered materials |  |  |
| board-enamel | 2. Display type |  |  |
| board-enamel | 8. Colour roles and value |  |  |
| board-enamel | 13. Light behind UI |  |  |
| board-gold | 1. Layered materials |  |  |
| board-gold | 2. Display type |  |  |
| board-gold | 8. Colour roles and value |  |  |
| board-gold | 13. Light behind UI |  |  |
| board-wood | 1. Layered materials |  |  |
| board-wood | 2. Display type |  |  |
| board-wood | 8. Colour roles and value |  |  |
| board-wood | 13. Light behind UI |  |  |
| board-glass | 1. Layered materials |  |  |
| board-glass | 2. Display type |  |  |
| board-glass | 8. Colour roles and value |  |  |
| board-glass | 13. Light behind UI |  |  |
| board-parchment | 1. Layered materials |  |  |
| board-parchment | 2. Display type |  |  |
| board-parchment | 8. Colour roles and value |  |  |
| board-parchment | 13. Light behind UI |  |  |
| board-type | 1. Layered materials |  |  |
| board-type | 2. Display type |  |  |
| board-type | 8. Colour roles and value |  |  |
| board-type | 13. Light behind UI |  |  |
| board-light | 1. Layered materials |  |  |
| board-light | 2. Display type |  |  |
| board-light | 8. Colour roles and value |  |  |
| board-light | 13. Light behind UI |  |  |
| board-icons | 1. Layered materials |  |  |
| board-icons | 3. Painted or rendered icons |  |  |
| board-icons | 8. Colour roles and value |  |  |
| board-icons | 13. Light behind UI |  |  |
| board-hc | 1. Layered materials |  |  |
| board-hc | 2. Display type |  |  |
| board-hc | 8. Colour roles and value |  |  |
| board-hc | 13. Light behind UI |  |  |
| board-hc-enamel | 1. Layered materials |  |  |
| board-hc-enamel | 2. Display type |  |  |
| board-hc-enamel | 8. Colour roles and value |  |  |
| board-hc-enamel | 13. Light behind UI |  |  |
| board-hc-gold | 1. Layered materials |  |  |
| board-hc-gold | 2. Display type |  |  |
| board-hc-gold | 8. Colour roles and value |  |  |
| board-hc-gold | 13. Light behind UI |  |  |
| ai-starlight | 1. Layered materials |  |  |
| ai-starlight | 3. Painted or rendered icons |  |  |
| ai-starlight | 8. Colour roles and value |  |  |
| ai-starlight | 13. Light behind UI |  |  |
| ai-essence | 1. Layered materials |  |  |
| ai-essence | 3. Painted or rendered icons |  |  |
| ai-essence | 8. Colour roles and value |  |  |
| ai-essence | 13. Light behind UI |  |  |
| ai-renown | 1. Layered materials |  |  |
| ai-renown | 3. Painted or rendered icons |  |  |
| ai-renown | 8. Colour roles and value |  |  |
| ai-renown | 13. Light behind UI |  |  |
| ai-chest | 1. Layered materials |  |  |
| ai-chest | 3. Painted or rendered icons |  |  |
| ai-chest | 8. Colour roles and value |  |  |
| ai-chest | 13. Light behind UI |  |  |
| ai-pip | 1. Layered materials |  |  |
| ai-pip | 3. Painted or rendered icons |  |  |
| ai-pip | 8. Colour roles and value |  |  |
| ai-pip | 13. Light behind UI |  |  |
| today-icon-starlight | 1. Layered materials |  |  |
| today-icon-starlight | 3. Painted or rendered icons |  |  |
| today-icon-starlight | 8. Colour roles and value |  |  |
| today-icon-starlight | 13. Light behind UI |  |  |
| today-icon-essence | 1. Layered materials |  |  |
| today-icon-essence | 3. Painted or rendered icons |  |  |
| today-icon-essence | 8. Colour roles and value |  |  |
| today-icon-essence | 13. Light behind UI |  |  |
| today-icon-renown | 1. Layered materials |  |  |
| today-icon-renown | 3. Painted or rendered icons |  |  |
| today-icon-renown | 8. Colour roles and value |  |  |
| today-icon-renown | 13. Light behind UI |  |  |
| today-icon-loot | 1. Layered materials |  |  |
| today-icon-loot | 3. Painted or rendered icons |  |  |
| today-icon-loot | 8. Colour roles and value |  |  |
| today-icon-loot | 13. Light behind UI |  |  |
| plant-gold-flat | 1. Layered materials |  |  |
| plant-gold-flat | 2. Display type |  |  |
| plant-gold-flat | 8. Colour roles and value |  |  |
| plant-gold-flat | 13. Light behind UI |  |  |
| plant-enamel-flat | 1. Layered materials |  |  |
| plant-enamel-flat | 2. Display type |  |  |
| plant-enamel-flat | 8. Colour roles and value |  |  |
| plant-enamel-flat | 13. Light behind UI |  |  |
| plant-hud-top-flat | 1. Layered materials |  |  |
| plant-hud-top-flat | 2. Display type |  |  |
| plant-hud-top-flat | 8. Colour roles and value |  |  |
| plant-hud-top-flat | 13. Light behind UI |  |  |
| plant-starlight-flat | 1. Layered materials |  |  |
| plant-starlight-flat | 3. Painted or rendered icons |  |  |
| plant-starlight-flat | 8. Colour roles and value |  |  |
| plant-starlight-flat | 13. Light behind UI |  |  |
| plant-essence-flat | 1. Layered materials |  |  |
| plant-essence-flat | 3. Painted or rendered icons |  |  |
| plant-essence-flat | 8. Colour roles and value |  |  |
| plant-essence-flat | 13. Light behind UI |  |  |
| plant-heist-one-step | 1. Layered materials |  |  |
| plant-heist-one-step | 2. Display type |  |  |
| plant-heist-one-step | 3. Painted or rendered icons |  |  |
| plant-heist-one-step | 6. Hierarchy |  |  |
| plant-heist-one-step | 8. Colour roles and value |  |  |
| plant-heist-one-step | 9. Character presence |  |  |
| plant-heist-one-step | 13. Light behind UI |  |  |
| plant-heist-one-step | 14. One art-direction idea |  |  |
| plant-heist-dim | 1. Layered materials |  |  |
| plant-heist-dim | 2. Display type |  |  |
| plant-heist-dim | 3. Painted or rendered icons |  |  |
| plant-heist-dim | 6. Hierarchy |  |  |
| plant-heist-dim | 8. Colour roles and value |  |  |
| plant-heist-dim | 9. Character presence |  |  |
| plant-heist-dim | 13. Light behind UI |  |  |
| plant-heist-dim | 14. One art-direction idea |  |  |
| plant-heist-unstroked | 1. Layered materials |  |  |
| plant-heist-unstroked | 2. Display type |  |  |
| plant-heist-unstroked | 3. Painted or rendered icons |  |  |
| plant-heist-unstroked | 6. Hierarchy |  |  |
| plant-heist-unstroked | 8. Colour roles and value |  |  |
| plant-heist-unstroked | 9. Character presence |  |  |
| plant-heist-unstroked | 13. Light behind UI |  |  |
| plant-heist-unstroked | 14. One art-direction idea |  |  |
| plant-type-hue | 1. Layered materials |  |  |
| plant-type-hue | 2. Display type |  |  |
| plant-type-hue | 8. Colour roles and value |  |  |
| plant-type-hue | 13. Light behind UI |  |  |
