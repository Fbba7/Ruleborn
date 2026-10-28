# The agent program: tracks, branches, ownership, progress, deploys

Most of this repository was written by agents working in parallel, each on
one *track*: a piece of work with its own branch, its own files and its own
notes. This page is how that program is organised, for someone joining it or
reading what it produced. The plan the 3D and interface tracks work to (the
quality bar, the look, the shot rules) is
[`docs/art/3d-program.md`](../art/3d-program.md); this page does not repeat it.

## The shape

- **The main branch** is `claude/videogame-project-analysis-ewkkk2`. Only the
  *integrator* pushes to it.
- **A track** is one agent (sometimes several in turn) on one branch, named
  `claude/<something>`. It changes only the files its row below gives it.
- **The integrator** merges the tracks' green heads into main, swaps work
  between tracks where one needs another's (T1's creatures into T5's actors,
  for example), runs the checks, and keeps the audit register and the roadmap
  current. It owns every file no track owns.
- **The owner** is the person the game belongs to. Decisions that change a
  rule, a price or the plan are theirs; agents prepare them and say so in
  their progress file (see "Owner decision needed" below).

## Tracks

The table in [`docs/art/3d-program.md`](../art/3d-program.md#tracks) is the
authority for what each 3D and interface track owns, file by file. This one
adds the tracks that are not in it and says where each one's notes, progress
and stills are.

| Track | Branch | Notes (what was done, "Stopped here") | Progress | Stills |
|---|---|---|---|---|
| T1 Characters | `claude/3d-characters`, earlier `claude/3d-characters-2` | [`t1-characters.md`](../art/tracks/t1-characters.md), then [`t1b-`](../art/tracks/t1b-characters.md) and [`t1c-characters.md`](../art/tracks/t1c-characters.md) (sessions 3 to 5; the latest) | [`T1.md`](../progress/T1.md) | `docs/art/shots/t1-characters/`, `t1b/`, `t1c/`, `t1d/` (wave 5) |
| T2 Look | `claude/3d-look` | [`look.md`](../art/tracks/look.md) | none (stopped after wave 3) | `docs/art/shots/look/` |
| T3 Kit | `claude/3d-kit` | [`kit.md`](../art/tracks/kit.md) | [`T3.md`](../progress/T3.md) | `docs/art/shots/kit/` |
| T4 Universe | `claude/3d-universe` | [`universe.md`](../art/tracks/universe.md) | [`T4.md`](../progress/T4.md) | `docs/art/shots/universe/` |
| T5 Heist | `claude/3d-screens` | [`t5.md`](../art/tracks/t5.md) | [`T5.md`](../progress/T5.md) | `docs/art/shots/t5/` |
| T6 Realm screens | `claude/3d-screens-world` | [`T6.md`](../art/tracks/T6.md) | [`T6.md`](../progress/T6.md) | `docs/art/shots/T6/` |
| T7 Character screens | `claude/3d-character-screens` | [`t7.md`](../art/tracks/t7.md) | [`T7.md`](../progress/T7.md) | `docs/art/shots/t7/` |
| T8 Law effects (retired after wave 2; its files passed to T5) | `claude/3d-law-fx` | [`t8.md`](../art/tracks/t8.md) | none | `docs/art/shots/t8/` |
| T9 UI kit | `claude/ui-kit` | [`ui-kit.md`](../art/tracks/ui-kit.md) | [`T9.md`](../progress/T9.md) | `docs/art/shots/ui-kit/` |
| T10 Screens | `claude/ui-screens` | [`ui-screens.md`](../art/tracks/ui-screens.md) | [`T10.md`](../progress/T10.md) | `docs/art/shots/ui-screens/` |
| T11 Sign-in | `claude/auth` | [`docs/security/auth.md`](../security/auth.md) | [`T11.md`](../progress/T11.md) | `docs/art/shots/auth/` |
| T12 Security review | `claude/security-review` | [`docs/security/review.md`](../security/review.md) | [`T12.md`](../progress/T12.md) | none |
| T13 Database cost | `claude/db-cost` | [`docs/server/db-cost.md`](../server/db-cost.md) | [`T13.md`](../progress/T13.md) | none |
| T14 UI quality research | `claude/ui-research` | [`docs/art/ui-quality/report.md`](../art/ui-quality/report.md) | [`T14.md`](../progress/T14.md) | `docs/art/ui-quality/` |
| T15 Documentation | `claude/docs` | [`docs/DOCS-CHANGES.md`](../DOCS-CHANGES.md) | [`T15.md`](../progress/T15.md) | none |
| T16 UI plan review | not recorded in this repository | `docs/art/ui-quality/` | not recorded | `docs/art/ui-quality/` |
| Integrator | `claude/videogame-project-analysis-ewkkk2` | the audit register and roadmap | the roadmap page | none |

Two things to know when reading the notes:

- **File names are mixed.** Some notes are named by track number (`T6.md`,
  `t5.md`), some by subject (`kit.md`, `universe.md`). They are kept as they
  are because other notes, commits and register items link to them; the table
  above is the map.
- **Some ownership claims overlap.** `client/tests/shots/screen_*.gd` is
  claimed by T6, T7 and T10 in their notes, and T8's notes still claim the
  law, Weaving and Harmony screens that the program table gives to T10. The
  program table is the later statement. If an overlap matters to a change,
  ask the integrator.

## Waves

Work happens in *waves*: a stretch of hours in which a set of tracks runs in
parallel, ending at a time the owner sets. Each wave's work is headed by its
number in the notes ("Wave 5", "Fifth wave", "Session four (fifth wave)": the
wording varies by track). When a track stops, its notes get a **"Stopped
here"** section: what is pushed and green, what is half done, and what the
next agent should do first. Read that section before anything else when
picking a track up.

## Rules a track keeps

The full list is in [`docs/art/3d-program.md`](../art/3d-program.md#rules-every-track-keeps).
In short:

1. **Stay in your files.** If another track's file needs a change, make the
   smallest hook that does it and record it in your notes, so the integrator
   and the other track see it.
2. **Push only to your branch.** Never to main, never to another track's.
3. **Green before you push to be merged.** `bash tools/check_all.sh` must end
   with `All checks passed.` (see [checks.md](checks.md)). A commit whose title
   starts with `WIP` is a save point: the integrator does not merge it.
4. **Never loosen a check** to get green: no skipped, disabled or weakened
   test.
5. **Keep the notes and the progress file current** on every push.

## Progress files

Each running track keeps `docs/progress/<track>.md`. It opens with the same
six lines, so they can be read side by side:

```markdown
# T<n> <name>: progress

- Status: Green / Red, and what the last push contains.
- Progress: NN%, counting only work that is pushed and passes check_all.
- Done: what is finished.
- Next: what comes next.
- Blocked by: what stops it, or none.
- Owner decision needed: the decisions only the owner can make, or none.
```

Then a table of the track's deliverables, with their weight, their status
and the evidence (a test, a commit, a still):

```markdown
| Deliverable | Weight | Status | Evidence |
|---|---:|---|---|
```

The **Owner decision needed** lines across every progress file are the
quickest list of what is waiting on the owner. Larger decisions (anything in
the design) go through the decision brief instead; see
[design-tools.md](design-tools.md).

## Deploys: how a track reaches main

The integrator merges on a schedule (hourly in the latest waves). In the
history this shows as merge commits titled
`Merge remote-tracking branch 'origin/claude/<track>' into intNN`: each round
merges every green track head into a fresh integration branch `intNN`, runs
the checks on the result, and moves main to it. Tracks call a merged round a
*deploy* ("deploy 2 merged in"). Tracks in turn merge main back into their own
branch (`Merge ... 'origin/claude/videogame-project-analysis-ewkkk2' into
claude/<track>`) to pick up the others' work.

Not recorded anywhere in the repository: how deploy numbers map to `intNN`
numbers, and what (if anything) happens to main after a merge beyond the
checks. Both are listed as questions in
[`docs/DOCS-CHANGES.md`](../DOCS-CHANGES.md).

## Stills

The 3D and interface tracks judge their work by stills rendered from the real
client, compared side by side with the design's (see
[client.md](client.md#rendering-a-still)). Each track commits the stills it
judged by to `docs/art/shots/<folder>/`, the folder named in the table above,
as PNGs under 400 KB. Progress files often cite a still by its bare file name;
the folder is the track's row.
