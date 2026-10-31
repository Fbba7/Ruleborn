# The golden set's held-out labels

The blind labelling form for one third of the golden set. You are labelling
images of a mobile game's interface against the rubric. Read
docs/art/ui-quality/gate/rubric.md first; it is the only guide you need. Do not
open items.json, labels.md, README.md or anything else in this folder except
the images named below. They hold another labeller's guesses, and these labels
are meant to test them.

There is one row for each item and each quality its class is judged on (the
rubric's "The method at a glance"). The images are in images/, named by item
id: the row `board-glass | 1. Layered materials` is about images/board-glass.png.

How to fill it in:

- **Label:** `pass`, `fail` or `n/a`. Use `n/a` only when the quality has
  nothing to judge in that image, for example quality 9 on a crop with no
  character. Leave no row blank.
- **Critique:** one line saying what you see that decides the label, in the
  rubric's words where you can. For example: "gold plate flat, no bevel or
  gloss; reads as a fill".
- Judge each image as it is, at 1x first and then zoomed in. Judge each row on
  its own quality; a fail on one quality does not make the others fail.
- Do not change the Item or Quality columns. `python3 tools/ui_gate/golden.py
  check` fails if the rows no longer match the held-out items.

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
| today-character | 1. Layered materials |  |  |
| today-character | 2. Display type |  |  |
| today-character | 3. Painted or rendered icons |  |  |
| today-character | 6. Hierarchy |  |  |
| today-character | 8. Colour roles and value |  |  |
| today-character | 9. Character presence |  |  |
| today-character | 13. Light behind UI |  |  |
| today-character | 14. One art-direction idea |  |  |
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
| t14-heist-hc | 1. Layered materials |  |  |
| t14-heist-hc | 2. Display type |  |  |
| t14-heist-hc | 3. Painted or rendered icons |  |  |
| t14-heist-hc | 6. Hierarchy |  |  |
| t14-heist-hc | 8. Colour roles and value |  |  |
| t14-heist-hc | 9. Character presence |  |  |
| t14-heist-hc | 13. Light behind UI |  |  |
| t14-heist-hc | 14. One art-direction idea |  |  |
| t14-hud-bottom | 1. Layered materials |  |  |
| t14-hud-bottom | 2. Display type |  |  |
| t14-hud-bottom | 8. Colour roles and value |  |  |
| t14-hud-bottom | 13. Light behind UI |  |  |
| today-hud-bottom | 1. Layered materials |  |  |
| today-hud-bottom | 2. Display type |  |  |
| today-hud-bottom | 8. Colour roles and value |  |  |
| today-hud-bottom | 13. Light behind UI |  |  |
| board-glass | 1. Layered materials |  |  |
| board-glass | 2. Display type |  |  |
| board-glass | 8. Colour roles and value |  |  |
| board-glass | 13. Light behind UI |  |  |
| board-parchment | 1. Layered materials |  |  |
| board-parchment | 2. Display type |  |  |
| board-parchment | 8. Colour roles and value |  |  |
| board-parchment | 13. Light behind UI |  |  |
| board-light | 1. Layered materials |  |  |
| board-light | 2. Display type |  |  |
| board-light | 8. Colour roles and value |  |  |
| board-light | 13. Light behind UI |  |  |
| ai-starlight | 1. Layered materials |  |  |
| ai-starlight | 3. Painted or rendered icons |  |  |
| ai-starlight | 8. Colour roles and value |  |  |
| ai-starlight | 13. Light behind UI |  |  |
| today-icon-starlight | 1. Layered materials |  |  |
| today-icon-starlight | 3. Painted or rendered icons |  |  |
| today-icon-starlight | 8. Colour roles and value |  |  |
| today-icon-starlight | 13. Light behind UI |  |  |
| plant-gold-flat | 1. Layered materials |  |  |
| plant-gold-flat | 2. Display type |  |  |
| plant-gold-flat | 8. Colour roles and value |  |  |
| plant-gold-flat | 13. Light behind UI |  |  |
| plant-heist-one-step | 1. Layered materials |  |  |
| plant-heist-one-step | 2. Display type |  |  |
| plant-heist-one-step | 3. Painted or rendered icons |  |  |
| plant-heist-one-step | 6. Hierarchy |  |  |
| plant-heist-one-step | 8. Colour roles and value |  |  |
| plant-heist-one-step | 9. Character presence |  |  |
| plant-heist-one-step | 13. Light behind UI |  |  |
| plant-heist-one-step | 14. One art-direction idea |  |  |
| kf-home-hc | 1. Layered materials |  |  |
| kf-home-hc | 2. Display type |  |  |
| kf-home-hc | 3. Painted or rendered icons |  |  |
| kf-home-hc | 6. Hierarchy |  |  |
| kf-home-hc | 8. Colour roles and value |  |  |
| kf-home-hc | 9. Character presence |  |  |
| kf-home-hc | 13. Light behind UI |  |  |
| kf-home-hc | 14. One art-direction idea |  |  |
| kf-result-text200 | 1. Layered materials |  |  |
| kf-result-text200 | 2. Display type |  |  |
| kf-result-text200 | 3. Painted or rendered icons |  |  |
| kf-result-text200 | 6. Hierarchy |  |  |
| kf-result-text200 | 8. Colour roles and value |  |  |
| kf-result-text200 | 9. Character presence |  |  |
| kf-result-text200 | 13. Light behind UI |  |  |
| kf-result-text200 | 14. One art-direction idea |  |  |
| kf-character-hc | 1. Layered materials |  |  |
| kf-character-hc | 2. Display type |  |  |
| kf-character-hc | 3. Painted or rendered icons |  |  |
| kf-character-hc | 6. Hierarchy |  |  |
| kf-character-hc | 8. Colour roles and value |  |  |
| kf-character-hc | 9. Character presence |  |  |
| kf-character-hc | 13. Light behind UI |  |  |
| kf-character-hc | 14. One art-direction idea |  |  |
| kf-settings | 1. Layered materials |  |  |
| kf-settings | 2. Display type |  |  |
| kf-settings | 3. Painted or rendered icons |  |  |
| kf-settings | 6. Hierarchy |  |  |
| kf-settings | 8. Colour roles and value |  |  |
| kf-settings | 13. Light behind UI |  |  |
| kf-settings | 14. One art-direction idea |  |  |
| plant-kf-home-unstroked | 1. Layered materials |  |  |
| plant-kf-home-unstroked | 2. Display type |  |  |
| plant-kf-home-unstroked | 3. Painted or rendered icons |  |  |
| plant-kf-home-unstroked | 6. Hierarchy |  |  |
| plant-kf-home-unstroked | 8. Colour roles and value |  |  |
| plant-kf-home-unstroked | 9. Character presence |  |  |
| plant-kf-home-unstroked | 13. Light behind UI |  |  |
| plant-kf-home-unstroked | 14. One art-direction idea |  |  |
| plant-kf-heist-icon-flat | 1. Layered materials |  |  |
| plant-kf-heist-icon-flat | 3. Painted or rendered icons |  |  |
| plant-kf-heist-icon-flat | 8. Colour roles and value |  |  |
| plant-kf-heist-icon-flat | 13. Light behind UI |  |  |
