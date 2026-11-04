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

Who labels: at O3, AD labels every row here. A fresh subagent, given only
gate/rubric.md and the held-out images, labels the held-out third (the items
with `third` 3 in items.json) blind, in labels-blind.md. The two sets of labels
are then compared row by row. Where they disagree on a held-out row, the label
here becomes `fail`, and the critique says what each labeller saw.
P0-AD-calibrate uses the agreement on the held-out third to calibrate the
judge.
