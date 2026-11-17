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

## Screens with more than one state

A screen item's still is rendered with its shot script and
`bash tools/render/shoot.sh <script> <still>`, with the item's settings in the
environment. Where a screen has two states the player sees, each state is its
own still, and the gate judges the item in both.

**The result screen** (`client/tests/shots/screen_result.gd`, P3-AD-preview-1
for S1-R40) shows the reward in two states. Both read the golden clean heist,
`client/goldens/planned-clean.rbh`: without the goldens (`bash client/build.sh`
in a fresh worktree, or `client/goldens/` copied in) every still renders as
"refused (malformed)", which is a missing file, not the screen's fault.

| State | When the player sees it | Environment | Still |
|---|---|---|---|
| Offline (the script's default) | the phone's own check, a rehearsal or a play: no server has paid the heist yet | no `SERVER` | `result_off_100` |
| Offline, high contrast | the same, with high contrast on | `CONTRAST=1` | `result_off_hc` |
| Server | the server's settle answer has come back with the totals and the crew's split | `SERVER=1` | `result_srv_100` |
| Server, high contrast | the same, with high contrast on | `SERVER=1 CONTRAST=1` | `result_srv_hc` |

The items "result at 100% text" and "result in high contrast" take both rows
of their setting; "result at 200% text, pt_BR" adds `TEXT=200 LOCALE=pt_BR` to
both. Add `FIT=1` to every run: a still whose run does not print "fit ok" is
not judged. `tools/ui_bake/guard.sh`'s budget shots use the offline state.

**High contrast's variable differs by script.** `screen_result.gd` and
`screen_heist.gd` read `CONTRAST=1`; the character's script and the other
screen scripts (`screen_character.gd`, `screen_roster.gd`, `screen_first.gd`,
`screen_forms.gd`, `screen_hatch.gd`, `screen_settings.gd` and the rest) read
`HC=1`. A script ignores the other name, so a still rendered with it is the
100% still: check the script's `OS.get_environment` lines before a run.

**The character screen offline** (`screen_character.gd`, P3-S3-character-5)
shows the roster's cream notice above its scroll. Its stills add `OFFLINE=1`
to the item's settings: `OFFLINE=1`, `OFFLINE=1 HC=1` and
`OFFLINE=1 TEXT=200 LOCALE=pt_BR` (board `boards/preview-1.md`).

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
