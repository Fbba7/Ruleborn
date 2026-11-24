# SP-bt-05 the gate launcher and verdict writer: progress

- Status: Green: BT-05 ready at the ready_sha in the status file, its pre-check recorded there.
- Progress: 0 of 1 tasks merged; 0 items passed by the gate (BT-05 has no gate items).
- Done: tools/gate/run.py (prepare, extra, write, validate, --self-test) and docs/progress/schema/verdict.json.
- Next: the lead merges BT-05 and adds the self-test line to check_all.sh (SP-bt-05-R1).
- Blocked by: none.
- Owner decision needed: none.

| Deliverable | Weight (h) | Status | Evidence |
|---|---:|---|---|
| BT-05: gate launcher, verdict writer, verdict schema | 4 | ready | `python3 tools/gate/run.py --self-test` passes (43 checks); `run.py validate`: 70 of 70 verdict files valid; full pre-check in the status file |

## Handoff

- Last verified commit: the status file's ready_sha.
- **What exists.** `tools/gate/run.py`, built on `tools/gate/render.py`:
  - `prepare --task <id> --request <status file or gate_request> --out <dir outside the repo> --judge "<product name>" [--list] [--blocking]`
    renders the stills at the request's sha (render.py), refuses to
    prepare anything if a still is missing or its fit failed, and writes
    `pics/<blind code>.png`, `calls/<call>.md` (filled prompts),
    `calls.jsonl` and `plan.json`. Three samples per item and quality, the
    pictures shuffled per sample (seeded by task, sha, row and sample, so a
    re-run gives the same order). Anchors: `calibrate.anchors` on the
    golden set's training third, by the item's class (default `screen`;
    an item may carry `"class"` and `"qualities"`, by name).
  - `extra <dir> <results.jsonl>` adds samples 4 to 6 for each split.
  - `write <dir> <results.jsonl> [--verdicts] [--attempts N] [--at] [--allow-split] [--replace]`
    decides each check with `calibrate.decide`, writes
    `<verdicts>/<task_id>/<sha[:8]>.json` (full sha inside, step 3's keys
    in step 3's order), validates it, refuses to overwrite, and prints a
    report: pass / fail / unknown counts, the failed checks, the
    exceptions queue (UNKNOWN results), `attempts_before` (from
    `--attempts`, else the backlog) and `attempts_after`. Nothing is
    written to the backlog.
  - `validate [files]` checks the schema plus what it cannot: task_id is
    the folder, the name is the sha's prefix, result follows from samples.
- **Choices to know.**
  - Attempts: +1 per gate run with any fail (not per failing object),
    which is how the existing verdict history was counted (for example
    P1-S1-pilot-1: 11 fails in one file, one attempt).
  - The judge field is the caller's `--judge`, a product name; Fable 5.1
    and API identifiers are refused, by the tool and by the schema.
  - The schema allows `result: "split"` (the protocol's example shows one)
    and `advisory` as optional; no existing file needed a change.
  - The schema check runs without dependencies and is cross-checked with
    jsonschema where it is installed; a disagreement is an error.
- **How the lead runs a gate:** `prepare`, then one fresh ui-judge
  session per `calls/<call>.md`, appending
  `{"call": "<id>", ...the judge's answer object}` lines to a results
  file; `extra`, judge the new calls; `write`. A real `prepare` of
  "settings at 100% text" (fixture list) took 2.5 min, mostly the build.
- **Requests:** SP-bt-05-R1 (wire the self-test into check_all.sh).

## Tried and failed

- Nothing abandoned.
