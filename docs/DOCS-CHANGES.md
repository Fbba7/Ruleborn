# Documentation changes (T15)

What the documentation pass of 28 October 2026 changed, and why. The goal:
someone new lands on the README and finds quickly what the game is, how the
repository is organised, how to build, run and test each part, how the agent
program works, and where every important document lives. No history was
deleted: track notes, decision records and the old README's narrative are all
kept, and made findable.

## Survey: what was wrong

- **The README was a status log.** About 180 of its 406 lines were the history
  of each design version, so the repository map, a quick start and the key
  links were missing or far down. There was no build or run command for the
  client, server or simulation at the top level.
- **No index of the documents**, no architecture overview, and no guide to the
  agent program (tracks, branches, progress files, deploys) beyond the 3D
  program's track table, which stopped at T12.
- **The client README was out of date** in a dozen places: "twelve screens"
  (there are 33), fonts "not added" (three ship), the landing picker and the
  law banner "not built" (both are), "the drawing is flat and top-down" (it is
  3D), settings that "change nothing yet" (they do), a Layout block missing
  `ui/`, `platform/`, `art/`, `prototypes/`, and twenty of the 25 feature
  folders.
- **The sim README** said three abilities, four Sage powers and island
  generation were not built; the code builds all of them.
- **The server README's** Layout lacked the three sign-in modules and five
  other files, and one line called the hold unmeasured though another section
  describes measuring it.
- **The analysis README** told readers to extract v2.3's HTML into v3.1's text
  file, and did not say it is an archive of the v2.3 reading.
- **The spec index** stops its adoption history at v3.1 without saying so.
- **The 3D program** still described the third wave as the latest and the
  second as still to come, and its track table lacked T13 and T14.
- **Track notes are hard to map**: file names mix numbers and subjects
  (`T6.md`, `kit.md`), T1's notes are split across three files, T11 to T14
  keep theirs outside `docs/art/tracks/`, and progress files cite stills by
  bare file name.
- **Generated files** (checked, left alone): `docs/audit/index.html`,
  `docs/decisions/index.html`, `docs/roadmap/index.html` (from
  `tools/build_audit.py`, `build_brief.py`, `build_roadmap.py`),
  `docs/design/dependencies.md` (`tools/check_dependencies.py`),
  `docs/design/generated/*.md` (`tools/generate_docs.py`),
  `server/declarations.md` (`server/src/privacy.mjs`), and the three
  `status.json` files. None of their sources needed a change for this pass.

## What changed

### New

| File | Why |
|---|---|
| [`docs/README.md`](README.md) | The index: every document, one line each, with who owns it |
| [`docs/architecture.md`](architecture.md) | The three parts, the shared simulation, a heist from lease to grant, what is authoritative where, pointers to security and cost |
| [`docs/status.md`](status.md) | A dated summary of where things stand, then the README's old status narrative, moved unchanged under "History, as written at each version", with the register, decisions, roadmap and prototype sections |
| [`docs/guides/checks.md`](guides/checks.md) | `check_all.sh` step by step, its prerequisites, and the rules `check_docs_consistency.py` enforces on Markdown |
| [`docs/guides/client.md`](guides/client.md) | Build, test, lint, store builds, rendering stills, strings and localisation, accessibility checks, budgets |
| [`docs/guides/server.md`](guides/server.md) | Run, test, load test, configuration variables, generated inputs |
| [`docs/guides/simulation.md`](guides/simulation.md) | Build, test, changing a rule, goldens, generated files, examples |
| [`docs/guides/design-tools.md`](guides/design-tools.md) | The design document, register, brief, roadmap, content and spec; the old README's tool commands |
| [`docs/guides/agent-program.md`](guides/agent-program.md) | Tracks with branch, notes, progress and stills folders; rules; progress-file format; waves and deploys |
| [`docs/progress/T15.md`](progress/T15.md) | This track's progress |
| [`docs/art/tracks/README.md`](art/tracks/README.md), [`docs/art/shots/README.md`](art/shots/README.md) | A map in each folder of which file or folder belongs to which track, where people look first |

### Rewritten

- **`README.md`**: a few lines on the game, a contents list, a one-line
  status with the checked "Can the drawing start?" table, a repository map, a
  quick start for each part, how `check_all.sh` works, the four live pages,
  key documents, the design in one page (kept), and the layout. The tools
  listing that `check_docs_consistency.py` checks is kept whole, now grouped
  by purpose with comment lines. The long narrative moved to `docs/status.md`.

### Corrected

- `client/README.md`: the screen count, the builder's ground (all 39
  features), the landing picker, target choice, settings, the three
  catalogues, the UI kit, the 3D drawing, the test runner's suites, the "Not
  yet" list (landing picker, fonts and law banner removed; sign-in updated),
  the Layout block; then, after a second sweep against the code, Home (the 3D
  universe with the designs' layout, not a Keeper bar over a list), the
  heist's controls (held taps for Stop and the drops, the gait menu, Get out
  in the hand), the Vault's load target, held controls and camera buttons,
  the guard marks, the replay's speeds, the phone's three notices, Settings'
  switches and tabs, and which catalogue is still English-only.
- `sim/README.md`: abilities, Sage powers and island generation are built
  (marked as later than the text around them); Layout gains `run_spike.sh`,
  `stability_cases.json`, `Cargo.toml`.
- `server/README.md`: Layout gains the sign-in modules, `status.py`,
  `package.json`, `ratings.json`, `web/terms.md`; the curation section no
  longer calls the hold unbuilt.
- `server/README.md`, after a sweep against the code: the one-lease rule is
  kept by the issuing transaction, not an index; balances, Renown and season
  stars are carried as running totals on the ledger since the cost work; the
  ledger holds Aether too; the load figure (about 62 billed rows for an
  engaged day, against a budget of 46); the privacy declaration's size (411
  columns in 61 tables); which sign-in routes are rate-limited and how
  sessions renew; `RULEBORN_TOKEN_KEYS`. Two code comments say the same old
  things (`server/src/db.mjs` on the leases table's "partial unique index",
  `server/src/limits.mjs` on keeping a session "for the hour"); they are
  code, so they are left for the server's owner.
- `docs/analysis/README.md`: marked as the v2.3 archive, with pointers; its
  extract command fixed; a bare `spec/economy.md` given its full path.
- `docs/design/spec/README.md`: says its adoption history stops at v3.1 and
  where the current state lives.
- `docs/art/3d-program.md`: the waves' prose brought up to date; T13 to T16
  added to the track table; a pointer to the agent-program guide.
- `prototypes/heist-gate/README.md`: a "Superseded" banner (v3.0 removed the
  pre-code tests); the page below it unchanged.
- Track notes `t1-characters.md`, `t1b-characters.md`, `t1c-characters.md`,
  `t8.md`: a one-paragraph banner on each saying which session it is, where
  the track continued, and (T8) where its files went. The notes themselves
  are unchanged.
- `docs/README.md` gains a "Words" table for the repository's own terms,
  pointing to the design document's glossary (§29.2) for the game's.
- `docs/progress/T10.md`: a doubled comma.
- Progress files: titles made one shape (`# T<n> <name>: progress`) in T1, T11,
  T12 and T13, and T4's table header capitalised like the others. The six-line
  header was already the same in all of them.

## Commands checked by running them

Every command the README and the guides give was run on this branch on 28
October 2026, in a Linux x86-64 container with Python 3.13, Node 22 and Rust
stable:

- `bash tools/check_all.sh`: "All checks passed", after installing what it
  needs and the guides now list (the `wasm32-unknown-unknown` and both phone
  targets, gdtoolkit 4, and Python Playwright for the prototype check; without
  Playwright the run fails at `check_prototype_conformance.py`).
- Simulation: `bash sim/run_spike.sh`; `cargo test --release <name>`; the
  three examples; `content_gate.py`; `build_laws.py --check`.
- Server: `node --no-warnings --test server/test/*.test.mjs` (482 pass);
  `npm test`; `server/status.py`; `main.mjs 8787 --example` with stubbed
  sign-in (serves a session), and without it (refuses to start, as
  documented); `load.mjs --players 20 --days 1`; `load.mjs --check`;
  `privacy.mjs`; `league_model.py --json` and `design_facts.py --json` (both
  identical to the committed JSON).
- Client: `client/build.sh`; `client/status.py`; `tests/run.gd` run directly
  against a local server (385 ok, none failed); `export.sh check`; gdlint;
  `tools/render/shoot.sh` with `heist_shot.gd`, and with `screen_meta.gd` at
  `SCREEN=settings TEXT=200 HC=1 LOCALE=de`; the older `tests/screenshot.gd`
  route.
- Design tools: `check_document.py`, `version_diff.py` (and `--items`),
  `decision_support.py`, `python3 -m tools.economy_model`,
  `python3 -m tools.heist_harness`, `privacy_manifest.py --check`.

Not run: `client/export.sh android` and `ios` (no Android SDK or Mac here),
`extract_content.py` and `extract_design_doc.py` (they rewrite committed
files; their outputs are checked by `check_all.sh`), and the golden replays'
`--write` (a deliberate decision each time, per its own docstring).

## Questions for the owner

1. **Deploys.** Tracks speak of "deploy 2" and "deploy 3"; the history shows
   integration branches `int14` to `int18`. How do the two numberings map,
   and does anything happen to main after a merge beyond the checks?
2. **Production.** Where and how will the server be deployed? Nothing in the
   repository describes it; `db-cost.md` measures against Cloudflare D1's
   billing, which suggests the target.
3. **T16's branch** is not recorded anywhere in the repository.
4. **Owners of single-commit files.** Many documents have one imported commit
   in their history; the owners in [`docs/README.md`](README.md) are inferred
   from their content.
5. **Register id D64** is used in `server/README.md` both for the season
   track's unbuilt part and for family approval; one of the two is probably
   another id. Not changed, since the register is not this track's.
6. **File ownership overlaps** in the track notes (`client/tests/shots/screen_*.gd`
   claimed by T6, T7 and T10; T8's notes still claiming screens the program
   table gives T10). The guide says the program table wins; is that right?
7. **Track notes naming.** Renaming the notes to one scheme (`docs/art/tracks/T<n>-<name>.md`)
   would help, but would break links in commits and register items. Left as
   is, with a map in the agent-program guide. Rename?
8. **T2 Look** has no progress file and its notes stop at a wave-3 round, with
   no "Stopped here" for that session. Is the track closed?
9. **`fe-base.log`** at the repository root is a tracked client test log
   (one line, "tests: 23 of 23 passed"), committed with a UI-kit change. It
   looks like a stray; delete it? Not touched, since it is not documentation.
10. **Reduced motion and flashing** (found while correcting the client
   README; a code matter, so not changed here): reduced motion stops the
   view's shake on a rising alarm, but not the screen edge's flash
   (`client/world/fx_anchors.gd`, the `flash` term is added whatever `calm`
   is), and Harmony's preview flashes up to twice a second
   (`client/world/law_fx_harmony.gd`). The client README used to say
   "nothing flashes or shakes". Worth a ticket for the heist track?

## Log

- 16:15 UTC: survey; three parallel read-only audits of the client, server and
  sim READMEs and of the docs tree.
- 16:30 UTC: guides, architecture, index, README, status page, corrections.
- 16:55 UTC: first push, check_all green.
- 17:10 UTC: every documented command run (above); Playwright prerequisite
  added; folder maps for track notes and stills; progress-file titles.
- 17:40 UTC: an independent newcomer's read of the new docs: three small
  errors fixed (the strings `--check` claim, a missing refused variable, the
  analysis steps' flags), the design sources' precedence said in the README,
  duplicate screenshot instructions folded into the client guide.
- 18:15 UTC: a second sweep of the client README against the code (nine
  statements corrected; one accessibility gap found, question 10).
- 18:50 UTC: a sweep of the server README against the code (eight
  statements corrected).
