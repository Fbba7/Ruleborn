# DT1 data track: progress

- Status: Green: full checks pass on `6f1b5513`; 3D0-DT1-data-spec is
  ready again after its resync.
- Progress: 0 of 1 tasks merged; 3D0-DT1-data-spec in resync after the
  verifier of cycle 197.
- Done: `guards()` adds `near`, `mid`, `peripheral` and `suspicion`, with a
  byte-for-byte replay test; a heist shot with a Suspicious guard; the data
  spec ([`docs/art/3d-quality/data-spec.md`](../art/3d-quality/data-spec.md)),
  section 3 now rebuilt from the sim source.
- Next: the verifier reviews the diff; then the lead merges.
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| `guards()`: near, mid, peripheral, suspicion; the replay test | 1.0 | done | `81706999` |
| The shot of a Suspicious guard | 1.0 | done | `fdf380a0` |
| The data spec | 1.5 | done | `docs/art/3d-quality/data-spec.md` |

## Handoff

- **Resync, cycle 197.** The verifier passed the extension work and failed
  section 3 of the spec (the guard states). Main merged at `b4e0075`
  (clean), and again at `6f1b5513`: the pre-check on `d9022669` failed
  `owners.py`'s self-test only because the branch's copy of the backlog
  still had 3D0-M1-budget-split live (`client/tests/shots/**`); it is
  merged on main. Full checks pass on `6f1b5513` (the ready_sha). The
  fixes, all from the source:
  - Section 3 is rebuilt from `phase_states`, `enter`, `lure` and `land`:
    the rank rule; a table of how each state is entered and left (Searching
    at alarm level 6; Returning after Investigating's search and after
    Searching's 600 ticks; Investigating by a spread and a lure; Alerted
    only by the meter); the three ways into Investigating that are not the
    meter; Delay; the meter's fill (summed over the crew, Scree ×5/4,
    Glare), fall, the 15-tick hold and the landing's 250 (Suspicious, not
    Investigating).
  - "A meter can skip Suspicious" is gone: at the base rates a tick adds
    at most 351, so the meter alone never crosses 200 and 600 at once.
  - Section 6: Wild hunt is a `continue` in `phase_noise`, not a reach of
    0 (`noise::field` with reach 0 still reaches the source tile).
  - Section 7: `route()` leaves out the start tile, as `path::Route` does;
    `route_for` takes `&self` and returns whether it crossed a wall, and
    `MoveTo` spends the wall pass itself.
  - The comment in `client/tests/shots/heist_suspicious.gd`: a near
    sighting passes through Suspicious, for a few ticks.
- **The status file at the ready_sha.** The pre-check runs on a commit,
  and its result is recorded in a later commit, so `DT1.json` at the
  ready_sha reads `working`. The branch head after it differs only in
  `docs/progress/` (protocol: the candidate may differ from the ready_sha
  only there); the head is the one to merge.
- **Earlier work, unchanged:** `81706999` (`guards()` and the replay test,
  golden 697 bytes, SHA-256 `afc82a08…d4e179a8`), `fdf380a0` (the shot:
  guard 0 Suspicious at tick 69, meter 204).
- **DT1-R1** stands with its default: the lead adds the shot's `.uid` at
  merge.

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

- **2026-11-25, cycle 197: the first section 3 was written from the
  states' names, not the code.** It had a landing put a guard in
  Investigating, a near rush skip Suspicious and a spread make a guard
  Alerted; the verifier found all three wrong. The entry above, "A meter
  can skip Suspicious", is wrong in the same way for the landing and the
  rush: the (2, 8) target's straight jump to Investigating was hearing.
  Section 3 is now read off `phase_states`, `enter`, `lure` and `land`.

## Requests

- **DT1-R1** (to the lead, not blocking): Godot writes
  `client/tests/shots/heist_suspicious.gd.uid` on the first run. It is
  outside DT1's files and left untracked; every other shot's `.uid` is
  tracked. Default: the lead adds it at merge.
