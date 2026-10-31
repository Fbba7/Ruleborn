# Shots and the gate's scripts

A **shot** is one still and the rectangles of its controls. The gate's image
checks read shots, and its sheets are made from them (section 3.5 of
`report.md`). AD keeps the shot lists (`docs/guides/agent-protocol.md`, the
roster); the renderer that makes the stills from them is backlog task BT-04.
The scripts are in `tools/ui_gate/` (P0-AD-sheet); `calibrate.py`, the judge's
calibration on the golden set, is described in [calibration.md](calibration.md)
(P0-AD-calibrate).

## The format

```json
{
  "image": "home-100.png",
  "frame_pt": [390, 844],
  "text_scale": 1.0,
  "controls": [
    {"name": "heist", "rect": [24, 700, 342, 88], "role": "primary", "persistent": false},
    {"name": "shop", "rect": [300, 120, 66, 66], "role": "secondary"},
    {"name": "title", "rect": [24, 60, 200, 32], "interactive": false}
  ]
}
```

- `image`: the still, relative to the shot file.
- `frame_pt`: the design's frame in points, 390 × 844 by default (§21.1). The
  scale from points to pixels is the still's width over the frame's.
- `text_scale`: 1.0, 1.5 or 2.0; recorded, not read by the checks.
- `controls`: one entry per control, with `rect` as `[x, y, width, height]`
  in points from the frame's top left. `role` is `primary`, `secondary` or
  absent; `interactive` defaults to true; `persistent` is true for what stays
  on screen through a heist.

## The image checks

`python3 tools/ui_gate/checks.py <check> <shot.json>`, with `<check>` one of
`value-steps`, `hud-share`, `hierarchy` or `all`. Each prints one JSON line per
result and exits 1 on any FAIL.

| Check | Quality | Passes when |
|---|---|---|
| `value-steps` | 8, pass item 3 | Each interactive control is two value steps off its ground: the median L* of its rectangle against the median L* of a 4 pt ring around it, ΔL* ≥ 20. The ring leaves out other controls' rectangles and the still's edge; if under a quarter of the ring is left, the check fails, since the gate does not pass what it cannot measure. A transparent still is measured over black |
| `hud-share` | 12, pass item 1 | The union of the `persistent` rectangles, clipped to the frame, is at most 15% of it |
| `hierarchy` | 6, pass items 1 and 2 | Exactly one `primary`, 1.5 to 2 times the area of the next-largest interactive control; at most six `secondary` controls (the rubric's "about five"). A shot with no primary is not applicable to the ratio |

## The sheets

`python3 tools/ui_gate/sheet.py <sheet> ...`; `--help` lists the options.

| Sheet | What it makes | Who sees it |
|---|---|---|
| `still` | The still at 960 px on its long edge; `--gray` makes its grayscale, the same L* with the colour removed (§21.10) | the judge, for screens; quality 6 judges the grayscale beside the colour |
| `contact` | Each image at 48 and 96 pt at the phone's density (1080 px over 390 pt: 133 and 266 px), in colour and in grayscale, on one ground | the judge, for icons and kit art; board 2 |
| `strip` | Frames side by side at one height, numbered | the owner's boards, for presses, juice and motion |
| `crops` | Full-resolution crops of named controls, with a margin in points | the judge, where a quality asks for crops |
| `cvd` | The still beside its protanopia, deuteranopia and tritanopia simulations (Machado and others, 2009, at full severity) | the judge, for quality 8 |

`python3 tools/ui_gate/sheet.py --self-test` runs the tests of all three
files, including planted fails for each image check.
