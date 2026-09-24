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


def load_measured():
    """Phase 14's load test: the server run under §14.1's three players and
    measured against §24.1's budget (server/load.mjs). What the measurement
    finds is the register's (F47); the deliverable is that it is taken."""
    def proof():
        path = SERVER / "load.json"
        runs = json.loads(path.read_text(encoding="utf-8")) if path.exists() else []
        done = {r.get("archetype") for r in runs if "writesPerPlayerDay" in r and "validationMs" in r}
        want = {"engaged", "regular", "casual"}
        return (len(done & want) / len(want),
                f"{len(done & want)} of 3 players measured against §24.1's budget", sorted(want - done))
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
    applies (laws_table.rs `simulated`) and reads every parameter of, with the
    pylon system built. The flag alone once counted Thorns and Bloom, whose
    parameters nothing in the simulation read."""
    def proof():
        laws = json.loads((CONTENT / "laws.json").read_text(encoding="utf-8"))
        launch = {l["id"] for l in laws if l.get("launch")}
        table = (SIM / "src" / "laws_table.rs").read_text(encoding="utf-8")
        lib = (SIM / "src" / "lib.rs").read_text(encoding="utf-8")
        rows = re.findall(r'id: "(\w+)", name: "[^"]*", simulated: true, params: &\[([^\]]*)\]',
                          table)
        simulated = {law for law, params in rows
                     if all(f"Param::{p}" in lib for p in re.findall(r"Param::(\w+)", params))}
        pylons, _, missing = systems("Laws and pylons")()
        n = len(launch & simulated) if pylons == 1 else 0
        return (n / len(launch) if launch else 0.0,
                f"{n} of {len(launch)} launch laws simulated", missing)
    return proof


def launch_combos():
    """§8 at launch: every harmony, every dissonance, every chord, and the
    signature resonances whose two laws both ship (§7.10) — each counted when
    the test sim/systems.json maps it to passed."""
    def proof():
        laws = json.loads((CONTENT / "laws.json").read_text(encoding="utf-8"))
        launch = {l["id"] for l in laws if l.get("launch")}
        notes = json.loads((CONTENT / "notes.json").read_text(encoding="utf-8"))
        pairs = {"_".join(sorted((n["id"], n["opposite"].lower()),
                                 key=lambda x: [m["id"] for m in notes].index(x))) for n in notes}
        want = ([f"harmony:{n['id']}" for n in notes]
                + [f"dissonance:{p}" for p in sorted(pairs)]
                + [f"resonance:{r['id']}" for r in
                   json.loads((CONTENT / "resonances.json").read_text(encoding="utf-8"))
                   if set(r["laws"]) <= launch]
                + [f"chord:{c['id']}" for c in
                   json.loads((CONTENT / "chords.json").read_text(encoding="utf-8"))])
        manifest, status = _sim_status()
        mapped = manifest.get("Resonances and chords", {}).get("combos", {})
        results = status.get("tests", {})
        built = [c for c in want if results.get(mapped.get(c, "")) == "passed"]
        missing = [c for c in want if c not in mapped]
        return (len(built) / len(want), f"{len(built)} of {len(want)} launch combinations "
                f"simulated", missing)
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
    ("1", "Resonances and chords", BACKEND, launch_combos()),
    ("1", "Golden harness", BACKEND, systems("Replay format", "Golden replays")),

    ("2", "Project structure", FRONTEND, not_started("a client project builds on both stores' targets")),
    ("2", "Localisation", FRONTEND, client_tests(
        "every string a screen asks for is in the catalogue, in English and Brazilian Portuguese, with the same placeholders",
        "no screen shows a word that is not from the catalogue")),
    ("2", "Portrait interface", FRONTEND, client_tests(
        "every control on every screen is 48 points or more, in the lower two-thirds, clear of corners and safe areas (§21.1), at 9:19.5",
        "every control on every screen is 48 points or more, in the lower two-thirds, clear of corners and safe areas (§21.1), at 9:16",
        "no text on any screen is smaller than 13 points (§21.8)")),
    ("2", "Save and settings", FRONTEND, client_tests(
        "settings changed on the settings screen are saved as they change and restored on the next launch: language, three volumes, reduced motion, haptics (§20.6)")),

    ("3", "Render a replay", FRONTEND, client_tests(
        "the client's simulation is the rules version every golden replay names",
        "every golden replay re-simulates in the client, every second agreeing with its checksums",
        "the replay screen plays a golden to its end and shows its grade")),
    ("3", "Capture input", FRONTEND, client_tests(
        "every tap on the heist screen makes the one command it names, stamped with the tick it was made",
        "a tap on a guard, the Vault, a pylon or a ward makes the command it calls for, and the gait button cycles walk, crouch, run",
        "a heist played live on the heist screen records the golden replay byte for byte, and the server's check grades it Clean",
        "a replay whose last checksum was altered is refused, as the server would refuse it")),
    ("3", "Show a result", FRONTEND, client_tests(
        "the result screen shows the validator's verdict: the re-simulation's grade, or nothing paid when refused",
        "a heist leased from the server, played on the heist screen and submitted is re-simulated and paid by the server")),

    ("4", "Terrain editing", FRONTEND, client_tests(
        "the builder lays §6.2's ground on the realm's grid, and the island it writes reads back the same")),
    ("4", "Laws on the island", FRONTEND, client_tests(
        "the builder weaves laws and places their pylons, holds the realm to its law slots, and names what the laws make together (§8.6)")),
    ("4", "Bundle serialisation", BACKEND, systems("Island bundles", "Publishing rules")),
    ("4", "Testing your own defence", FRONTEND, client_tests(
        "a player can raid their own island from the builder: the heist plays it, the server's check judges it, and the result leads back")),

    ("5", "24 laws as validated data", BACKEND, content_count(
        "laws.json", 24, lambda rows: [r for r in rows if r.get("launch")])),
    ("5", "54 forms as validated data", BACKEND, content_count("forms.json", 54)),
    ("5", "39 terrain features as validated data", BACKEND, content_count("terrain.json", 39)),

    ("6", "Schema", BACKEND, server_tests("snapshots and the ledger cannot be edited")),
    ("6", "Identity: session tokens", BACKEND, server_tests(
        "a session is a signed token, and a forged one is refused")),
    ("6", "Identity: platform sign-in", BACKEND, server_tests(
        "a Game Center identity is Apple's: its key from apple.com, this app, a fresh timestamp, a true signature (24.8)",
        "sign-in over HTTP with a Game Center credential")),
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

    ("7", "Workshop services: publish, browse, moderate, remix", BACKEND, server_tests(
        "an island reaches the Workshop only once its creator has cleared it (18.6)",
        "a creator holds five islands, eight once a Builder, and a withdrawn one frees its slot (20.12, 18.7)",
        "a completion counts once a player, never the creator's own, and climbs the ladder (18.7)",
        "a player aged 13 to 15 browses the curated list only (20.7)",
        "islands are rated for fun, cleverness and fairness by those who played them (18.6)",
        "reports wait for a person, a removal gives its reason, and a ban takes everything out (20.4, 20.12)",
        "remixing hands over the island, and publishing the remix names the original (25.1)",
        "a Workshop island is never edited or deleted (18.6)",
        "a sudden spike in completions is flagged for a person to review (18.7)",
        "the Workshop over HTTP: publish a cleared island, browse, play, rate, remix and report")),
    ("7", "Workshop screens", FRONTEND, not_started("the Workshop's screens exist in the client")),

    ("8", "Currencies", BACKEND, server_tests(
        "a planned clean heist is re-simulated, and its haul minted with the fee returned",
        "the second raid of the day pays 0.85 of the first, and the fee is 2% (§9.4, §9.6)")),
    ("8", "Cosmetics", BACKEND, server_tests(
        "a cosmetic is bought with Starglass at its euro price, owned once, and worn in its slot (22.1)",
        "a defender's worn cosmetics travel with the lease, so the raider sees them")),
    # Apple's side; Google Play's needs Google's API (D67).
    ("8", "Purchases and receipts", BACKEND, server_tests(
        "a StoreKit 2 transaction counts only with its chain and signature intact, for this app (22.1)",
        "a Starglass pack bought through the App Store is granted from its signed transaction, once (22.1)",
        "a Starglass purchase is granted once per store transaction, from a verified receipt (22.1)",
        "a minor's month is capped, €25 at 13 to 15 and €50 at 16 and 17, and an adult gets a summary (20.2)")),
    ("8", "The season track", BACKEND, server_tests(
        "a heist earns season stars: the raider by its grade, the defender by what it held (18.2)",
        "the track's first tier is free on day one, and each after costs a tier's stars, in order (18.2)",
        "a player joining late climbs a track scaled to the time remaining (18.8)",
        "stars reset each season, and an unclaimed tier stays claimable later at the same cost (18.8)",
        "the premium track is bought with Starglass and adds only cosmetics, for tiers already claimed too (18.2)",
        "the track, the shop and the wardrobe over HTTP")),
    ("8", "Shop, track and wallet screens", FRONTEND, not_started("those screens exist in the client")),

    ("9", "Leagues", BACKEND, server_tests(
        "a clean heist moves §12.9's Renown to the raider, and Dust's floor mints what it stops",
        "above its floor, the defender loses the mirror amount (12.9)",
        "a foiled heist costs the raider a flat 8, and the defender gains what the raider lost (12.9)",
        "Ember, once reached, is a floor: nobody drops out of Dust or Ember (18.1)",
        "a Renown's league and division: three divisions a league, none in Paradox (18.1)")),
    ("9", "Crews (clans)", BACKEND, server_tests(
        "a constellation: the Beacon from Keeper level 6, thirty Keepers, a founder and four elders (17.1)",
        "a crew is four to eight, joined by its invite, and survives its founder leaving (17.7)",
        "leagues, constellations and crews over HTTP")),
    ("9", "Season rollover", BACKEND, server_tests(
        "a season closes once: results and rewards by league, and the next opens pulled halfway back (18.1)",
        "the constellation league ranks by members' combined Renown at the season's close (17.5)")),
    ("9", "Social screens", FRONTEND, not_started("the league and crew screens exist in the client")),

    ("10 to 13", "Localisation: English and Brazilian Portuguese", FRONTEND, not_started(
        "every launch screen and content name ships in both languages, the Portuguese read by a native speaker")),
    ("10 to 13", "Accessibility", FRONTEND, not_started("§21's accessibility set is in the client")),
    ("10 to 13", "Compliance: store declarations", BACKEND, not_started(
        "the age, privacy and store declarations are filed")),
    ("10 to 13", "Telemetry", BACKEND, server_tests(
        "the server records sessions, heists and purchases under a pseudonym, never the account (24, 20.5)",
        "a device's batch is checked whole: known events, known fields, no positions, sensible times (24.3)",
        "the launch gates' figures: players, crash-free sessions, heists, worth-your-time, buyers (22.2, 25.3)",
        "retention by cohort, day 1, 7 and 30, outlives the raw events discarded after 90 days (24.3)",
        "telemetry over HTTP: a batch from the device, and the report for analysts only")),

    ("14", "Load testing", BACKEND, load_measured()),
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
