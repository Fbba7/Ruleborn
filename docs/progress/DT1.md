# DT1 data track: progress

- Status: Green. 3D0-DT1-data-spec: `guards()` adds the four fields, the
  suspicious shot renders, and the data spec is written.
- Progress: 1 task, this session's: 3D0-DT1-data-spec. Its ready_sha and
  pre-check are in `status/DT1.json`: ready at `0b77e805`, the full
  checks passed and the owners diff is clean.
- Done: the data spec ([`docs/art/3d-quality/data-spec.md`](../art/3d-quality/data-spec.md)).
  `guards()` returns `near`, `mid`, `peripheral` and `suspicion`, with a
  byte-for-byte replay test. A heist shot with a Suspicious guard.
- Next: the verifier reviews the diff; the lead merges. Phase 1's data
  task builds the additions of the spec's sections 5 to 7.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| `guards()`: near, mid, peripheral, suspicion; the replay test | 1.0 | done | `81706999` |
| The shot of a Suspicious guard | 1.0 | done | `fdf380a0` |
| The data spec | 1.5 | done | `docs/art/3d-quality/data-spec.md` |

## Handoff

- **Ready at `0b77e805`** (main merged at `1dd4958f`). The full checks
  passed on it at 17:35Z, and `owners.py diff` reports every changed path
  inside the task's files. Main has since moved only by the lead's
  progress files, which merge cleanly.
- **Pushes:** from 16:10Z to about 16:55Z the credential service refused
  every push with a 503. Nothing was lost; all commits are on
  `claude/3d-data`.
- **Commits, in order:**
  - `81706999`: `guards()` in `client/ext/src/lib.rs` gains the keys
    `near`, `mid`, `peripheral` and `suspicion`, through a `GuardView`
    struct.
    - The test is `reading_the_guards_every_tick_leaves_the_replay_byte_for_byte`.
      It records a heist while reading every guard every tick, and
      compares the replay with a golden pinned from main's code before the
      change (697 bytes, SHA-256 `afc82a08…d4e179a8`).
    - All seven tests of the extension pass.
  - `fdf380a0`: `client/tests/shots/heist_suspicious.gd`. Pip walks into
    guard 0's far zone. Guard 0 turns Suspicious at tick 69 (meter 204),
    and the shot renders that moment with each guard's state over its
    head. It fails if no guard is Suspicious within 900 ticks.
  - The data spec, then this file and the status file.
- **What the spec decides:**
  - Noise reaches the client from the simulation: a `sound_reach` moved
    out of `phase_noise`, and an extension `noise(x, y, gait)`. The
    client does not recompute it.
  - Order previews: `route()` moves the route choice out of `MoveTo`, and
    `foresee()` is a dry run on a clone of the world.
  - Per-tile sight zones and cover flags come from the simulation.
  - Every sim change is a move of existing code, with the golden replays
    unchanged. That work is complex: it spans `sim/` and `client/`.
- **Costs:** measured with a temporary release benchmark (not committed;
  it was outside this task's files) on the example island. They are in
  the spec's section 8.

## Tried and failed

- **`Island::example_open` has no guards.** The test and the shot use
  `Island::example` and the island fixture.
- **A meter can skip Suspicious.** Hearing jumps straight to
  Investigating, and so do a landing within earshot and a rush into the
  near zone. A first target at (2, 8) gave Investigating with no
  Suspicious tick. The shot walks into the far zone instead, where the
  meter fills by 12 a tick.
- **Orders given at tick 0 do nothing.** The shot gives its moves after
  the first step.
- **Too short a heist is refused.** A recording shorter than
  `sim::MIN_TICKS` gives a `Length` refusal; the test records
  `MIN_TICKS`.

## Requests

- **DT1-R1** (to the lead, not blocking): Godot writes
  `client/tests/shots/heist_suspicious.gd.uid` on the first run. It is
  outside DT1's files and left untracked; every other shot's `.uid` is
  tracked. Default: the lead adds it at merge.
