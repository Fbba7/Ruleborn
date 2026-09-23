#!/usr/bin/env python3
"""How close the app is to built, backend and frontend, as two percentages.

    python3 tools/completion.py              # the two numbers and every deliverable
    python3 tools/completion.py --self-test  # the gate check_all.sh runs

Computed, never typed, the way the audit page's "What is built" band is:

* **The weights are the document's.** §26.8 costs the build phase by phase in
  agent runs ("0. Determinism and mobile spike | 6 to 14", ...), and each
  phase weighs its midpoint. They are read from the built document every
  time, so if §26.8 re-costs a phase the percentages move with it. The
  fix-up line is a third of every phase and so moves nothing; phase 15,
  finding the fun, comes after the build and is not in it.
* **The deliverables are §26.8's own list.** Each phase's notes name what it
  builds ("Tick loop, crews, stealth, the law engine, ..."), and each named
  thing is one deliverable here, sharing its phase's weight equally, on the
  side of the app it lives on. Where a phase has both halves, it is split into
  a backend and a frontend deliverable.
* **Done is read from results.** A deliverable counts only through its proof:
  sim/ systems whose every test passed (sim/status.json), server tests by name
  (server/status.json), the checksum targets that agree, or a count read from
  content/. A proof that names a test or system that no longer exists fails
  the gate rather than reading as done. A deliverable with no proof is not
  started, and says what would count.

Judgement is confined to two places, both stated beside the data: which side
a deliverable belongs to, and equal shares inside a phase.
"""

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from design_doc import TEXT  # noqa: E402

SIM = ROOT / "sim"
CLIENT = ROOT / "client"
SERVER = ROOT / "server"
CONTENT = ROOT / "content"

BACKEND, FRONTEND = "backend", "frontend"


# -- proofs -------------------------------------------------------------------
# Each returns (fraction done, one line of evidence, names that did not resolve).

def _sim_status() -> tuple[dict, dict]:
    manifest = json.loads((SIM / "systems.json").read_text(encoding="utf-8"))
    status = json.loads((SIM / "status.json").read_text(encoding="utf-8"))
    return {s["name"]: s for s in manifest["systems"]}, status


def systems(*names: str):
    """sim/ systems, each built only if every test proving it passed."""
    def proof():
        manifest, status = _sim_status()
        results = status.get("tests", {})
        missing = [n for n in names if n not in manifest]
        built = [n for n in names if n in manifest
                 and all(results.get(t) == "passed" for t in manifest[n]["tests"])]
        return (len(built) / len(names), f"{len(built)} of {len(names)} sim/ systems built",
                missing)
    return proof


def server_tests(*names: str):
    """Server tests by name, from the last run of server/status.py."""
    def proof():
        path = SERVER / "status.json"
        results = json.loads(path.read_text(encoding="utf-8"))["tests"] if path.exists() else {}
        missing = [n for n in names if n not in results]
        passed = [n for n in names if results.get(n) == "passed"]
        return (len(passed) / len(names), f"{len(passed)} of {len(names)} server tests pass",
                missing)
    return proof


def client_tests(*names: str):
    """Client tests by name, from the last headless run of client/status.py."""
    def proof():
        path = CLIENT / "status.json"
        results = json.loads(path.read_text(encoding="utf-8"))["tests"] if path.exists() else {}
        missing = [n for n in names if n not in results]
        passed = [n for n in names if results.get(n) == "passed"]
        return (len(passed) / len(names), f"{len(passed)} of {len(names)} client tests pass",
                missing)
    return proof


def targets():
    """§24.7's four targets: the same checksums, native and WebAssembly run
    here; a phone is a target only once it has run the same seeds."""
    def proof():
        _, status = _sim_status()
        runs = status.get("cross_target", [])
        here = 2 if runs and all(r.get("agree") for r in runs) else 0
        return here / 4, f"{here} of 4 targets agree on every seed", []
    return proof


def launch_laws_simulated():
    """The law engine, measured on §7.10's 24 launch laws: how many sim/
    applies (laws_table.rs `simulated`), with the pylon system built."""
    def proof():
        laws = json.loads((CONTENT / "laws.json").read_text(encoding="utf-8"))
        launch = {l["id"] for l in laws if l.get("launch")}
        table = (SIM / "src" / "laws_table.rs").read_text(encoding="utf-8")
        simulated = set(re.findall(r'id: "(\w+)", name: "[^"]*", simulated: true', table))
        pylons, _, missing = systems("Laws and pylons")()
        n = len(launch & simulated) if pylons == 1 else 0
        return (n / len(launch) if launch else 0.0,
                f"{n} of {len(launch)} launch laws simulated", missing)
    return proof


def content_count(file: str, want: int, where=lambda rows: rows):
    """A content table extracted from the document, validated by
    validate_content.py in check_all.sh, holding the count §26.1 ships."""
    def proof():
        path = CONTENT / file
        rows = where(json.loads(path.read_text(encoding="utf-8"))) if path.exists() else []
        have = len(rows)
        return (1.0 if have == want else min(have, want) / want,
                f"content/{file}: {have} of {want}", [])
    return proof


def not_started(what_counts: str):
    def proof():
        return 0.0, f"not started — counts when {what_counts}", []
    return proof


# -- the deliverables, phase by phase (§26.8) -----------------------------------
# (phase number as §26.8 writes it, name, side, proof)

DELIVERABLES = [
    ("0", "Same checksums on native, WebAssembly, iPhone and Android", BACKEND, targets()),

    ("1", "Tick loop", BACKEND, systems(
        "Fixed-point arithmetic", "Angles and trigonometry", "Seeded randomness",
        "The tick and its checksum")),
    ("1", "Crews", BACKEND, systems(
        "Tile grid", "Pathfinding", "Crew control", "Roles and gaits", "The Vault and loading",
        "Fights, knockouts and capture", "The skiff, the clock and the outcome", "Height")),
    ("1", "Stealth", BACKEND, systems(
        "Line of sight", "Noise", "Guard states", "Realm alarm", "Detection modifiers", "Wards")),
    ("1", "The law engine", BACKEND, launch_laws_simulated()),
    ("1", "Resonances and chords", BACKEND, not_started(
        "sim/ applies §8's resonances and chords, each proved by a test")),
    ("1", "Golden harness", BACKEND, systems("Replay format", "Golden replays")),

    ("2", "Project structure", FRONTEND, not_started("a client project builds on both stores' targets")),
    ("2", "Localisation", FRONTEND, not_started("the client loads its strings from a catalogue")),
    ("2", "Portrait interface", FRONTEND, client_tests(
        "every control is 48 points or more, in the lower two-thirds, clear of corners and safe areas (§21.1), at 9:19.5",
        "every control is 48 points or more, in the lower two-thirds, clear of corners and safe areas (§21.1), at 9:16",
        "no text is smaller than 13 points (§21.8)")),
    ("2", "Save and settings", FRONTEND, not_started("the client saves and restores its settings")),

    ("3", "Render a replay", FRONTEND, client_tests(
        "the client's simulation is the rules version every golden replay names",
        "every golden replay re-simulates in the client, every second agreeing with its checksums",
        "the replay screen plays a golden to its end and shows its grade")),
    ("3", "Capture input", FRONTEND, not_started("taps become sim/ commands in a replay")),
    ("3", "Show a result", FRONTEND, not_started("the result screen reads the validator's verdict")),

    ("4", "Terrain editing", FRONTEND, not_started("the builder places §6.2's features on a grid")),
    ("4", "Laws on the island", FRONTEND, not_started("the builder weaves laws and places pylons")),
    ("4", "Bundle serialisation", BACKEND, systems("Island bundles", "Publishing rules")),
    ("4", "Testing your own defence", FRONTEND, not_started(
        "a player can raid their own island from the builder")),

    ("5", "24 laws as validated data", BACKEND, content_count(
        "laws.json", 24, lambda rows: [r for r in rows if r.get("launch")])),
    ("5", "54 forms as validated data", BACKEND, content_count("forms.json", 54)),
    ("5", "39 terrain features as validated data", BACKEND, content_count("terrain.json", 39)),

    ("6", "Schema", BACKEND, server_tests("snapshots and the ledger cannot be edited")),
    ("6", "Identity: session tokens", BACKEND, server_tests(
        "a session is a signed token, and a forged one is refused")),
    ("6", "Identity: platform sign-in", BACKEND, not_started(
        "a Game Center or Play Games credential is verified with the store")),
    ("6", "Publishing", BACKEND, server_tests(
        "publishing is content-addressed and idempotent",
        "an island §5.2 or §6.1 forbids is refused, with the rule named")),
    ("6", "The validator", BACKEND, server_tests(
        "a planned clean heist is re-simulated, and its haul minted with the fee returned",
        "a replay that does not reproduce pays nothing, takes nothing, and is flagged (§24.12)",
        "a replay must be the heist its lease allowed: the snapshot, the seed, the clock")),
    ("6", "Target lists", BACKEND, server_tests(
        "target lists are files, one a band, holding every island's current snapshot (§24.8)",
        "an unchanged band regenerates to the same file, so the edge keeps its cache")),
    ("6", "Rate limits", BACKEND, server_tests(
        "the per-raid cap is 1.98 times the base, derived from richness and difficulty (§9.6)",
        "a day's ceiling is half again above the whole fatigue curve; a week's is five days of it",
        "a haul is capped by what the raider was already paid today (§9.6, §24.12)")),

    ("7", "Workshop services: publish, browse, moderate, remix", BACKEND, not_started(
        "the server stores, lists, moderates and forks shared islands")),
    ("7", "Workshop screens", FRONTEND, not_started("the Workshop's screens exist in the client")),

    ("8", "Currencies", BACKEND, server_tests(
        "a planned clean heist is re-simulated, and its haul minted with the fee returned",
        "the second raid of the day pays 0.85 of the first, and the fee is 2% (§9.4, §9.6)")),
    ("8", "Cosmetics", BACKEND, not_started("cosmetic items are owned and applied server-side")),
    ("8", "Purchases and receipts", BACKEND, not_started("store receipts are verified and granted")),
    ("8", "The season track", BACKEND, not_started("the season track's tiers are granted")),
    ("8", "Shop, track and wallet screens", FRONTEND, not_started("those screens exist in the client")),

    ("9", "Leagues", BACKEND, not_started("league placement and rewards run on the server")),
    ("9", "Crews (clans)", BACKEND, not_started("crews are stored and joinable")),
    ("9", "Season rollover", BACKEND, not_started("a season closes and the next opens")),
    ("9", "Social screens", FRONTEND, not_started("the league and crew screens exist in the client")),

    ("10 to 13", "Localisation: English and Brazilian Portuguese", FRONTEND, not_started(
        "every string ships in both languages")),
    ("10 to 13", "Accessibility", FRONTEND, not_started("§21's accessibility set is in the client")),
    ("10 to 13", "Compliance: store declarations", BACKEND, not_started(
        "the age, privacy and store declarations are filed")),
    ("10 to 13", "Telemetry", BACKEND, not_started("§24's events are logged and queryable")),

    ("14", "Load testing", BACKEND, not_started("the server holds its target load")),
    ("14", "Real-device matrix", FRONTEND, not_started("the client runs on the device matrix")),
    ("14", "Balance pass", BACKEND, not_started("the launch balance pass is signed off")),
    ("14", "Fix buffer", FRONTEND, not_started("launch fixes are closed")),
]


def phases() -> dict[str, tuple[str, float]]:
    """§26.8's build phases, read from the document: number -> (name, midpoint runs)."""
    text = TEXT.read_text(encoding="utf-8")
    start = text.index("\n26.8 ")
    table = text[start:text.index("\n26.9 ", start)]
    out = {}
    for num, name, lo, hi in re.findall(
            r"^\| (\d+(?: to \d+)?)\. ([^\n]+)\n\| (\d+) to (\d+)$", table, re.M):
        out[num] = (name.strip(), (int(lo) + int(hi)) / 2)
    return out


def compute() -> dict:
    ph = phases()
    by_phase = {}
    for num, name, side, proof in DELIVERABLES:
        by_phase.setdefault(num, []).append((name, side, proof))
    rows, missing = [], []
    totals = {BACKEND: [0.0, 0.0], FRONTEND: [0.0, 0.0]}
    for num, items in by_phase.items():
        phase_name, runs = ph[num]
        share = runs / len(items)
        for name, side, proof in items:
            done, evidence, lost = proof()
            missing += [f"{name}: {n}" for n in lost]
            totals[side][0] += share * done
            totals[side][1] += share
            rows.append(dict(phase=num, phase_name=phase_name, name=name, side=side,
                             weight=share, done=done, evidence=evidence))
    pct = {side: 100 * got / of if of else 0.0 for side, (got, of) in totals.items()}
    runs = {side: of for side, (_, of) in totals.items()}
    return dict(percent=pct, runs=runs, rows=rows, missing=missing, phases=ph)


def self_test() -> int:
    ok = True
    ph = phases()
    named = {d[0] for d in DELIVERABLES}
    # Every build phase §26.8 costs has deliverables here, and no deliverable
    # names a phase §26.8 does not have — so a phase added to the document
    # fails this rather than silently weighing nothing.
    build = {n for n in ph if n != "15"}
    for label, good in (
            (f"§26.8's build phases are read from the document ({len(build)})", len(build) >= 12),
            ("every build phase has deliverables here", build <= named),
            ("every deliverable names a phase §26.8 costs", named <= build)):
        print(f"  [{'PASS' if good else 'FAIL'}] {label}")
        ok = ok and good
    result = compute()
    good = not result["missing"]
    print(f"  [{'PASS' if good else 'FAIL'}] every proof names a test or system that exists"
          + ("" if good else ": " + "; ".join(result["missing"])))
    ok = ok and good
    # A planted proof that names nothing must not read as done.
    done, _, lost = systems("A system nobody built")()
    good = done == 0 and lost == ["A system nobody built"]
    print(f"  [{'PASS' if good else 'FAIL'}] a proof naming a missing system counts nothing "
          "and is reported")
    ok = ok and good
    return 0 if ok else 1


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    result = compute()
    for side in (BACKEND, FRONTEND):
        print(f"{side:<9} {result['percent'][side]:6.2f}%   of {result['runs'][side]:.1f} "
              f"agent runs (§26.8 midpoints)")
    print()
    for r in result["rows"]:
        print(f"  {r['phase']:>8}  {r['side']:<8} {100 * r['done']:6.2f}%  {r['name']}"
              f" — {r['evidence']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
