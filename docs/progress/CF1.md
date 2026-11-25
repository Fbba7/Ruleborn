# CF1 Camera and framing: progress

- Status: Green. 3D0-CF1-style-frames ready at 4e6c51ee: pre-check PASS 2026-11-25T15:45:02Z, All checks passed (bwrap).
- Progress: 0 of 1 tasks merged; 3D0-CF1-style-frames ready (4e6c51ee).
- Done: the shot `client/tests/shots/style_frame_heist.gd`; four stills (today, a, b, c) at phone size and 2x, and two side-by-side sheets; `docs/art/3d-quality/style-frames.md`.
- Next: the verifier's review, then the owner's pick (a, b or c).
- Blocked by: none.
- Owner decision needed: which style frame, (a), (b) or (c) (`docs/art/3d-quality/style-frames.md`, last section). Default until answered: (a).

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| 3D0-CF1-style-frames: the same heist moment ("vault") three ways, at phone size and 2x; `style-frames.md` side by side, with costs and the owner's question; shot-only | 8 | Ready (4e6c51ee) | pre-check PASS 2026-11-25T15:45:02Z at 4e6c51ee, All checks passed (bwrap); `owners.py diff` passes; `STYLE=a\|b\|c CAST=1 MOMENT=vault bash tools/render/shoot.sh client/tests/shots/style_frame_heist.gd <out>.png`: each `budget:` line 119 draw calls (91,818 primitives at 15 tiles, 91,634 at 11); `HEIGHTS=1` crew 15.0–17.5 (today), 20.5–23.9 (a), 21.1–24.5 (b), 28.8–33.6 (c) points feet to head; quiet ground: 71 pieces gone, 1,099 kept, 2 meadows plain; gdlint and gdformat clean; no file outside the task's own changed (`owners.py diff`) |

## Handoff

- **What is there.** `client/tests/shots/style_frame_heist.gd` extends `screen_heist.gd` and overrides its `settle()`. `STYLE=a` sets the world view's zoom to 1.5, which is 11 tiles across. `STYLE=b` scales each crew and guard figure (`Rig/Figure`) and its `head` meta by `GROW` (1.4 by default). `STYLE=c` does both, then quiets the ground: it shrinks the scatter instances inside the tile grid to nothing, sets the meadow shader's `deco_scale` to 0 and hides the speech layer. With no `STYLE`, the shot is the heist shot unchanged. `HEIGHTS=1` prints each figure's feet-to-head height in points.
- **What it does not change.** The game's camera, its figure scale and its ground. Every change lives in the shot.
- **Honest limits** (also in `style-frames.md`).
  - (c) has no new markers, because direction D is not built.
  - The heights are feet-to-head lines. They are converted to the plan's measure by ratio, not measured as the plan measures them.
  - (b)'s scale goes on the figure node, not through `readable_scale`. Rings and marks stay at today's size.
- **The shot's `.uid`.** Godot generates `style_frame_heist.gd.uid` on the first run. The task's file list (`style_frame_*.gd`) does not cover it, so it is not committed. A later task on these files may add it, as the other shots have theirs.

## Tried and failed

- Writing back a scatter instance's origin in view space moved the pieces. The fix keeps the instance's own local origin.
- Setting the meadow's `deco` texture to null turned the meadow white. The fix sets `deco_scale` to 0.
- Measuring heights from projected mesh bounds counted held items and overestimated. The fix projects the feet and the `head` meta.
