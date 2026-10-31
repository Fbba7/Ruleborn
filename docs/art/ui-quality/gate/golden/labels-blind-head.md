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
