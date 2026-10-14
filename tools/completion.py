#!/usr/bin/env python3
"""How close the app is to built, backend and frontend, as two percentages.

    python3 tools/completion.py              # the two numbers and every deliverable
    python3 tools/completion.py --self-test  # the gate check_all.sh runs

Computed, never typed, the way the audit page's "What is built" band is:

* **The weights are the document's.** §26.8 costs the build phase by phase in
  agent runs ("0. Determinism and mobile spike | 6 to 14", ...), and each
  phase weighs its midpoint, lettered phases (4a, 4b, 4c) included. They are
  read from the built document every time, so if §26.8 re-costs a phase the
  percentages move with it, and a phase it adds fails the self-test until it
  has deliverables here. The
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

Judgement is confined to three places, each stated beside the data: which
side a deliverable belongs to; equal shares inside a phase, and inside a
deliverable §26.8 names as several things (``parts``); and terrain editing,
which can lay only what the simulation has, scaled by it (``times``).
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


def crew_powers():
    """§26.8's phase 1: "crews as ruleborn from the manifest with the eighteen
    abilities, Sage powers and casts as commands (12.5, 12.7)". Its parts,
    each counted once and equally: the crew manifest, §12.6's rules for using
    an ability, each of §11.11's eighteen abilities, each of §11.7's twelve
    launch Sage powers, and casts — each through the sim/ system that proves
    it, every test passed. An ability or a power counts when sim/systems.json
    maps it to a test that passed; one not mapped is not built."""
    def proof():
        manifest, status = _sim_status()
        results = status.get("tests", {})
        whole = lambda name: name in manifest and all(
            results.get(t) == "passed" for t in manifest[name]["tests"])
        kinds = [k["id"] for k in json.loads((CONTENT / "ruleborn.json").read_text(encoding="utf-8"))]
        powers = [f"{s['id']}:{name.strip().lower()}"
                  for s in json.loads((CONTENT / "sages.json").read_text(encoding="utf-8"))
                  for name in re.findall(r"(?:^|\. )([A-Z][a-z]+(?: [a-z]+)?):", s["heist_powers"])]
        mapped = {**manifest.get("Abilities", {}).get("abilities", {}),
                  **manifest.get("Sage powers", {}).get("powers", {})}
        parts = {"the crew manifest": whole("Crew manifest"),
                 "the ability rules": whole("Ability rules"),
                 **{k: results.get(mapped.get(k, "")) == "passed" for k in kinds},
                 **{p: results.get(mapped.get(p, "")) == "passed" for p in powers},
                 "casts": whole("Casts")}
        missing = [t for t in mapped.values() if t not in results]
        n = sum(parts.values())
        got = lambda keys: sum(parts[k] for k in keys)
        return (n / len(parts),
                f"{n} of {len(parts)}: the manifest {'built' if parts['the crew manifest'] else 'not'}"
                f", §12.6's rules {'built' if parts['the ability rules'] else 'not'}"
                f", {got(kinds)} of {len(kinds)} abilities, {got(powers)} of {len(powers)} Sage "
                f"powers, casts {'built' if parts['casts'] else 'not'}", missing)
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


def engine_pin():
    """§26.8's phase 0: the client on Godot 4.7.2 and godot-rust v0.5.5 built
    for the 4.7 API, with the Android target SDK at 36 — three pins, each read
    from the file that sets it (TD.1)."""
    def proof():
        build = (CLIENT / "build.sh").read_text(encoding="utf-8")
        cargo = (CLIENT / "ext" / "Cargo.toml").read_text(encoding="utf-8")
        presets = (CLIENT / "export_presets.cfg").read_text(encoding="utf-8")
        pins = {
            "Godot 4.7.2": 'version="4.7.2-stable"' in build,
            "godot-rust v0.5.5 on api-4-7": bool(re.search(
                r'godot = \{ version = "=0\.5\.5", features = \["api-4-7"\] \}', cargo)),
            # 4.7.2 passes the preset's value only to a Gradle build, so until
            # it is set there the level is the template's, unread (D76).
            "Android target SDK 36, set or read off the first APK (TC.3)":
                bool(re.search(r'target_sdk="?36"?', presets)),
        }
        held = [k for k, v in pins.items() if v]
        unset = [k for k, v in pins.items() if not v]
        return (len(held) / len(pins), f"{len(held)} of {len(pins)} pins set"
                + (f"; not yet: {', '.join(unset)}" if unset else ""), [])
    return proof


def sim_terrain():
    """§6.2's 39 features and moss in the simulation: each counts once
    sim/systems.json's "Terrain features" maps it to a test that passed."""
    def proof():
        manifest, status = _sim_status()
        results = status.get("tests", {})
        mapped = manifest.get("Terrain features", {}).get("features", {})
        ids = [r["id"] for r in json.loads((CONTENT / "terrain.json").read_text(encoding="utf-8"))]
        have = [i for i in ids if results.get(mapped.get(i, "")) == "passed"]
        moss = results.get(mapped.get("moss", "")) == "passed"
        missing = [t for t in mapped.values() if t not in results]
        return ((len(have) + moss) / (len(ids) + 1), f"{len(have)} of {len(ids)} features"
                f"{' and moss' if moss else ', no moss'} in sim/, each by its test", missing)
    return proof


def builder_terrain():
    """What the builder can lay of §6.2's 39 features and moss: those the
    client's island editor offers (client/ext/src/island.rs `GROUND`) that the
    simulation has built, each by its test. The cliff edge comes with raised
    ground."""
    def proof():
        manifest, status = _sim_status()
        results = status.get("tests", {})
        mapped = manifest.get("Terrain features", {}).get("features", {})
        ext = (CLIENT / "ext" / "src" / "island.rs").read_text(encoding="utf-8")
        body = re.search(r"pub const GROUND: \[&str; \d+\] = \[(.*?)\];", ext, re.S)
        offered = set(re.findall(r'"(\w+)"', body.group(1))) if body else set()
        # §6.2: a cliff edge is "Free (made by height)" — laid with raised
        # ground, never on its own.
        if "raised_ground" in offered:
            offered.add("cliff_edge")
        ids = [r["id"] for r in json.loads((CONTENT / "terrain.json").read_text(encoding="utf-8"))]
        both = [i for i in ids if i in offered and results.get(mapped.get(i, "")) == "passed"]
        moss = "moss" in offered and results.get(mapped.get("moss", "")) == "passed"
        return ((len(both) + moss) / (len(ids) + 1),
                f"{len(both)} of {len(ids)} features{' and moss' if moss else ', no moss,'} in the builder", [])
    return proof


def native_strings():
    """§14.6's notification strings in the phones' own tables, both
    languages, every key the server pushes (tools/native_strings.py)."""
    def proof():
        import native_strings as ns
        found = ns.problems()
        return (0.0 if found else 1.0,
                f"{len(ns.rows())} notification strings in both phones' tables"
                + (f", {len(found)} problems" if found else ""), [])
    return proof


def parts(*proofs):
    """A deliverable §26.8 names as several things, each an equal part: the
    average of their proofs, every part's evidence shown."""
    def proof():
        got = [p() for p in proofs]
        return (sum(g[0] for g in got) / len(got), "; ".join(g[1] for g in got),
                [n for g in got for n in g[2]])
    return proof


def times(scope, proof_):
    """A screen that can only do what the simulation under it does: its own
    proof, scaled by how much of that the simulation has."""
    def proof():
        a, b = scope(), proof_()
        return a[0] * b[0], f"{b[1]}, over {a[1]}", a[2] + b[2]
    return proof


def not_started(what_counts: str):
    def proof():
        return 0.0, f"not started — counts when {what_counts}", []
    return proof


# -- the deliverables, phase by phase (§26.8) -----------------------------------
# (phase number as §26.8 writes it, name, side, proof)

DELIVERABLES = [
    ("0", "Same checksums on native, WebAssembly, iPhone and Android", BACKEND, targets()),
    # §26.8: "Done when a recorded build — engine version, SDK levels, the
    # upload — exists for each store, counted here and nowhere else" (G68).
    # The fallback decision (§24.7) is the same evidence: a build that loads
    # the Rust library on both phones, or the move to C#.
    ("0", "A recorded store build for each store", FRONTEND, not_started(
        "a recorded build — engine version, SDK levels, the upload to TestFlight and "
        "the Play internal track — exists for each store (TC.3, G68)")),
    ("0", "The engine pinned: Godot 4.7.2, godot-rust's api-4-7, Android target SDK 36",
     FRONTEND, engine_pin()),

    ("1", "Tick loop", BACKEND, systems(
        "Fixed-point arithmetic", "Angles and trigonometry", "Seeded randomness",
        "The tick and its checksum")),
    ("1", "Crews", BACKEND, systems(
        "Tile grid", "Pathfinding", "Crew control", "Roles and gaits", "The Vault and loading",
        "Fights, knockouts and capture", "The skiff, the clock and the outcome", "Landing",
        "Height")),
    # §26.8: "crews as ruleborn from the manifest with the eighteen abilities,
    # Sage powers and casts as commands (12.5, 12.7)" — the simulation has none
    # yet (G67), so they are their own deliverable, not a tenth of Crews.
    ("1", "The eighteen abilities, Sage powers and casts as commands", BACKEND, crew_powers()),
    ("1", "Stealth", BACKEND, systems(
        "Line of sight", "Noise", "Guard states", "Realm alarm", "Detection modifiers", "Wards")),
    ("1", "The law engine", BACKEND, launch_laws_simulated()),
    ("1", "Resonances and chords", BACKEND, launch_combos()),
    ("1", "The event log", BACKEND, systems("Event log")),
    ("1", "Golden harness", BACKEND, systems("Replay format", "Golden replays")),

    # The client's architecture (TC.1). The store builds are phase 0's (G68).
    ("2", "Project structure", FRONTEND, client_tests(
        "the router shows a route's scene, and the screen history is in the store and its log",
        "the store changes a slice only through an action its reducer owns, tells who listens, and logs every action")),
    ("2", "Localisation", FRONTEND, client_tests(
        "every string a screen asks for is in the catalogue, in each of the game's languages, with the same placeholders",
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
        "a replay whose last checksum was altered is refused, as the server would refuse it",
        "the crew lands together on the open edge tile the player chose, recorded at tick 0 (5.4)")),
    ("3", "Show a result", FRONTEND, client_tests(
        "the result screen shows the validator's verdict: the re-simulation's grade, or nothing paid when refused",
        "a heist leased from the server, played on the heist screen and submitted is re-simulated and paid by the server")),

    # §26.8: "Terrain with all 39 of 6.2's features and moss" (G67). The
    # builder can lay only what the simulation has, so its row is scaled by it.
    ("4", "Terrain: §6.2's 39 features and moss in the simulation", BACKEND, sim_terrain()),
    ("4", "Terrain editing", FRONTEND, times(builder_terrain(), client_tests(
        "the builder lays §6.2's ground on the realm's grid, and the island it writes reads back the same",
        "the builder lays the six with a direction, turns them with a second tap, digs a tunnel mouth by "
        "mouth, and the island it writes carries both (6.2, G56)"))),
    ("4", "Buildings on the grid with their footprints (§10.1)", BACKEND, parts(
        systems("Buildings on the grid"),
        server_tests(
            "a building keeps the tile it is put on, moves free and at once, and stays on the grid and off the others (10.1)",
            "a published island carries the realm's placed buildings on their tiles, and no others (10.1)"),
        client_tests(
            "the island the builder edits places §10.1's buildings on their footprints, and its bundle carries them"),
        not_started("the Vault on §10.1's 3 by 3, which moves every heist and the hold table measured "
                    "on its one tile (G45)"))),
    ("4", "Laws on the island", FRONTEND, client_tests(
        "the builder weaves laws and places their pylons, holds the realm to its law slots, and names what the laws make together (§8.6)")),
    ("4", "Bundle serialisation", BACKEND, systems("Island bundles", "Publishing rules")),
    ("4", "Testing your own defence", FRONTEND, client_tests(
        "a player can raid their own island from the builder: the heist plays it, the server's check judges it, and the result leads back")),

    # §26.8's phase 4a: "The server is authoritative for every resource change
    # (24): buildings and production, workers, spending, the Spire, the roster
    # and births, the Codex's restorations, and 14.2's experience from each.
    # The device may build, weave and assign work offline, confirmed on
    # reconnection" (TC.12, G42).
    ("4a", "Buildings", BACKEND, server_tests(
        "a new universe is the Heart with its start, and says what each next level costs and needs (10.2, F56)",
        "a realm holds §5.2's count of each kind, where §10.2 places it",
        "what a building needs is checked before anything is paid: its Keeper and Spire levels, the Starlight, the next level only",
        "the universe over HTTP: read, bought, and refused with the reason (5.2, 10.2)")),
    # §9.3's formula: what the server keeps state for (the table rate, the
    # staffing, the realm's school, the workers' bonuses, the hold, the
    # keep), and the terms that wait on weaving and stability being kept.
    ("4a", "Production", BACKEND, parts(
        server_tests(
            "a producer runs at the share of its slots filled, from five minutes after assignment, and holds twelve hours (5.8, 9.3, 11.6)",
            "a worker of the resource's schools earns 15% more, and a work trait its share (9.2, 11.3)",
            "a realm of the resource's school produces 10% more (5.2, 9.3)",
            "collecting pays what a producer made into the ledger, a Garden's less the roster's 25% keep (9.3, 9.5)",
            "a producer raised a level is paid at the old level for the time before (9.3, 10.2)"),
        server_tests(
            "a law of a producer's school adds 10% to it in its realm, a crowned one 5% in every realm, from when its weaving ends (9.3)"),
        not_started("§9.3's stability-band and fault terms, once the server keeps the universe's "
                    "stability and its faults (TD.37)"))),
    ("4a", "Workers", BACKEND, parts(
        server_tests(
            "a worker goes only into a free slot or Guardian Post, and what it made where it was is kept when it moves (5.8)",
            "the home over HTTP: read, set to work, collected, and refused with the reason (9.3, 11.5)"),
        server_tests(
            "a heist names its crew from the roster, and each rests by its own outcome, off work until it is back (11.6, 12.9, TD.34)",
            "a crew the roster does not hold, or that is not the replay's, does not record (TD.34)"))),
    ("4a", "Spending", BACKEND, server_tests(
        "a building is bought with Starlight from the ledger, once, however often the purchase is sent (10.2, 24.12)")),
    ("4a", "The Spire", BACKEND, server_tests(
        "outer realms open at §5.2's Keeper levels, each of a type not yet owned, and rise at its Spire levels")),
    ("4a", "The roster and births", BACKEND, parts(
        server_tests(
            "the roster starts with the three who wake, two traits each, and the first heist brings two strays home free (11.5, 15.6)",
            "the roster lives in the Spire's three places and each Hearth's homes, and a birth needs a free one (11.4, 11.5)",
            "a character rises a level for 150 × 1.55^(level − 2) Essence, no higher than its home allows (9.5, 11.4)"),
        server_tests(
            "a birth at a Nursery costs 100 × 1.3455^owned Essence, waits for a ready birth, and is of the realm's school (9.5, 10.2, 11.5)"),
        server_tests(
            "a birth's school is drawn 3 for each law woven in its realm, 2 for the realm's own and 1 for each crown law, and a law's traits three times as likely there (11.3, 11.5)"))),
    ("4a", "The Codex's restorations", BACKEND, server_tests(
        "the Codex starts with Half gravity, Slow rivers and Bloom restored at tier I (7.6)",
        "a heist meets the island's laws, a page each, and a broken pylon gives a page of its law (7.6)",
        "a heist allows one study of a law it crossed: 3 pages if clean, 1 if foiled, 2 otherwise (7.6)",
        "every eighth paying heist gives a page of the law worked on (7.6)",
        "restoring a law costs its rank's pages, waits for its chapter, and pays 60 + 10 × level experience (7.6, 14.2)",
        "tiers II and III cost their pages, their Aether and a Spire level (7.6)",
        "the Codex over HTTP: read, worked on, restored, and refused with the reason (7.6)")),
    # "14.2's experience from each": from heists and from spending so far, as
    # equal parts with what the unbuilt sources will add.
    ("4a", "§14.2's experience from each", BACKEND, parts(
        server_tests(
            "a heist earns §14.2's experience: 30 + 6 × level for a success, 10 + 2 × level foiled",
            "a raid's experience is the raider's, settled with its haul, once, and it levels them up (14.2)",
            "experience climbs §14.2's table level by level, and stops counting at level 40"),
        server_tests(
            "spending earns §14.2's experience, 1 for every 40 Starlight, with nothing lost between purchases"),
        # §14.2 pays nothing for production or births: "successful heists …,
        # foiled heists …, spending … and restoring laws".
        server_tests(
            "restoring a law costs its rank's pages, waits for its chapter, and pays 60 + 10 × level experience (7.6, 14.2)"))),
    ("4a", "Offline building, weaving and assigning, confirmed on reconnection", BACKEND, parts(
        server_tests(
            "the device's offline queue is made in order, each action confirmed or refused on its own, by the online rules (24)",
            "a queue sent twice, its answer lost on the way back, is confirmed again and pays nothing twice (24.12)",
            "the offline queue over HTTP, and a queue that is not one refused whole (24)"),
        client_tests(
            "a build the network does not reach waits in the outbox, shown as confirming; sent on reconnection, "
            "each is confirmed or refused by the server, and the screen says which and why (24)"),
        server_tests(
            "weaving offline is confirmed on reconnection, once, and over HTTP (24, 5.6)"))),

    # §26.8's phase 4b: the §23.2 screens no other phase builds, "ported from
    # the designs to this document's rules (23.5)". Each counts when its
    # screen gate (stage SD) passes, by client tests kept by name.
    ("4b", "Universe map", FRONTEND, not_started("TD.19's screen gate passes for it")),
    ("4b", "Law card", FRONTEND, not_started("TD.20's screen gate passes for it")),
    ("4b", "Realm view", FRONTEND, not_started("TD.19's screen gate passes for it")),
    ("4b", "Weaving", FRONTEND, client_tests(
        "Weaving shows the universe's stability as a bar of §5.5's seven bands, the current one marked in "
        "words with its effect, and strain against capacity (5.5, 23.2)",
        "Weaving recommends two or three laws for a realm, ranked: one that harmonises first, one that "
        "clashes last, then the cheapest, each compared by its points, the band after weaving and its "
        "harmonies and clashes (23.2, C48)",
        "Weaving shows the harmonies, clashes and resonances every law would make before it is woven "
        "(8.2, 8.3, 8.4, 23.2)",
        "Weaving puts each weave's Aether price and weaving time on its button, the server's price for that "
        "weave, into the realm's first free slot (5.6, 23.2)",
        "a weave that would take strain into Breaking waits and says why (5.5)",
        "Weaving shows each realm's slots and the crown's: a law woven with its tier, a free slot, a resting "
        "one and when it frees (5.1, 5.6)",
        "Weaving shows the Heart's two slots and no third, and the crown's slots the Spire has opened, none "
        "at Spire level 1, one at 2, two at 5 and 6, with the level that opens the next (5.1, TD.20)",
        "a weave sends the realm, slot and law and shows the view the server answers; a refusal keeps the "
        "view on show and says why; taking a law out rests the slot (5.5, 5.6)",
        "a weave with no network waits in the outbox, shown as confirming, and is confirmed on "
        "reconnection with what is woven after it, or said refused and why (24, 5.6)",
        "the Weaving screen draws the seven bands with the current one marked, each law's comparison and its "
        "button; a weave into Breaking waits, and Aether is spent on a second tap (5.5, 5.6, 23.2)",
        "a Weave held for the hold time weaves and one let go sooner does not; a tap path is beside it, the "
        "screen says both, and the hold time is the player's to change (20.8, 23.5)",
        "against the server: Weaving offers the starting laws at the simulation's prices, recommends them, "
        "and charges for a weave the price it showed (5.5, 5.6, TD.14)",
        "every screen works with text at 150% and 200%: nothing wider than the phone, every control in reach "
        "(§20.8, §21.1)",
        "every control a screen reader reaches has a name in words, and a realm is read in words (§20.8)")),
    ("4b", "Planner", FRONTEND, not_started("TD.18's screen gate passes for it")),
    ("4b", "Observatory", FRONTEND, parts(client_tests(
        "the Observatory labels each target — a player's universe, an echo, the game's own island with its "
        "band — and pins a Trace apart, with no fee (12.3, 12.22)",
        "each target card shows §12.4's free facts — realms, Renown, a rough loot estimate, strain and open "
        "faults — the lease's fee and why it was offered (12.4, 12.15)",
        "a refresh says its price, and waits with why when the Aether is short; a protected new Keeper is told "
        "raiding a player ends it (12.3)",
        "the Observatory is fetched and refreshed from the server; a card opens its scout report, and raiding "
        "it leases that island, a Trace as a Trace (12.3, 24.12)",
        "the Observatory screen draws the Trace first and apart, then each target, and a refresh that waits "
        "while the Aether is short (12.3, 23.2)",
        "against the server: a new Keeper's Observatory lists targets as cards with no rating and a fee, "
        "and a refresh it cannot pay for is refused at 50 Aether (12.3, 12.4)",
        "every screen works with text at 150% and 200%: nothing wider than the phone, every control in reach "
        "(§20.8, §21.1)",
        "every control a screen reader reaches has a name in words, and a realm is read in words (§20.8)"),
        server_tests(
        "the Observatory's cards carry §12.4's free facts, counted from the bundle, the lease's own fee and why "
        "each was offered, and no rating, deviation or position reaches the device (12.4, 12.22, TD.18)",
        "the Observatory offers 3 targets, 4 from level 3 and 5 at level 5, and a new player is told raiding a "
        "player ends their protection (12.3, 10.2)",
        "a refresh costs 50 Aether, doubling with each refresh in the same hour, and buys a list without the "
        "targets on show (12.3)",
        "a Trace is shown apart from the list and first, with no fee, and only while it can be answered (12.3)",
        "the Observatory and its refresh are served over HTTP (12.3)"),
        not_started("universes of several realms give each card its depth, \"up to N realms to the Heart\", "
                    "and its faults' places; visitors give the Wanderer's extra target; the first launch "
                    "gives the Keeper's name (T3.3, §11.7, G58)"))),
    ("4b", "Scout report", FRONTEND, parts(client_tests(
        "the scout report reads a target realm by realm — its laws, guards by role, wards by kind, its watch — "
        "and says nothing placed is shown (12.4)",
        "each target card shows §12.4's free facts — realms, Renown, a rough loot estimate, strain and open "
        "faults — the lease's fee and why it was offered (12.4, 12.15)",
        "the Observatory is fetched and refreshed from the server; a card opens its scout report, and raiding "
        "it leases that island, a Trace as a Trace (12.3, 24.12)",
        "every screen works with text at 150% and 200%: nothing wider than the phone, every control in reach "
        "(§20.8, §21.1)",
        "every control a screen reader reaches has a name in words, and a realm is read in words (§20.8)"),
        server_tests(
        "the Observatory's cards carry §12.4's free facts, counted from the bundle, the lease's own fee and why "
        "each was offered, and no rating, deviation or position reaches the device (12.4, 12.22, TD.18)",
        "open faults follow §5.5's strain, never more than the outer realms, and a loot estimate is rough "
        "(5.5, 12.4)"),
        not_started("matchups worked out from each kind's ability and the realm's laws, and each realm's page "
                    "opening on its law cards, realm by realm across a universe (TD.18, TD.20)"))),
    ("4b", "Roster", FRONTEND, client_tests(
        "the Roster shows every character's state as a symbol and a word as well as a colour, each "
        "state's symbol and colour its own (23.2, 20.8)",
        "the Roster shows each rest's time left, by the minute begun (11.6, 23.2)",
        "the Roster's one tap sends a character to the first producer with a free slot in 14.1's order: "
        "the Heart's first, then each outer realm's as they opened, a resting worker's slot still held; "
        "with none free it waits and says why (14.1, 23.2)",
        "the Roster screen draws each state's colour beside its symbol and word, and its one tap sends the "
        "character to the producer it names; a name opens the character, whose Essence is spent on a "
        "second tap (20.8, 23.2)",
        "against the server: the roster is §15.6's three, idle, and one tap sends the first to the "
        "Heart's first producer with a free slot (14.1, 15.6, 23.2)",
        # The screen gate's checks over every screen, the Roster among them.
        "every screen works with text at 150% and 200%: nothing wider than the phone, every control "
        "in reach (§20.8, §21.1)",
        "every control a screen reader reaches has a name in words, and a realm is read in words (§20.8)")),
    ("4b", "Character screen", FRONTEND, client_tests(
        "the Character screen shows school, role, ability, traits, level and best work, from the "
        "character's card (11.11, 23.2)",
        "the Character screen spends Essence at the server's price: the next level, held back in words "
        "when its home allows no higher, none past the top, and waking from a rest (11.4, 11.6)",
        "the Roster screen draws each state's colour beside its symbol and word, and its one tap sends the "
        "character to the producer it names; a name opens the character, whose Essence is spent on a "
        "second tap (20.8, 23.2)",
        "every screen works with text at 150% and 200%: nothing wider than the phone, every control "
        "in reach (§20.8, §21.1)",
        "every control a screen reader reaches has a name in words, and a realm is read in words (§20.8)")),
    ("4b", "Sage hall", FRONTEND, client_tests(
        "the Sage hall shows each Sage's powers and what each fifth level adds, those the Keeper's level "
        "has reached marked in words (11.7, 23.2)",
        "the Sage hall shows the Sages' level, which is the Keeper's, and when each locked Sage unlocks "
        "(11.7, 23.2)",
        "the Sage hall's guardian choice puts one unlocked Sage on guard at the Heart, in another's place, "
        "takes it off again, and a locked one waits and says until when (11.7, 23.2)",
        "the Sage hall screen draws the level, each Sage's gains reached, the one on guard and the "
        "choice; a choice the server does not hear is said not to be made (11.7, 23.2)",
        "against the server: a new Keeper's hall has the Archivist alone unlocked and none on guard; the "
        "Archivist goes on guard, and a locked Sage is refused in words (11.7)",
        "every screen works with text at 150% and 200%: nothing wider than the phone, every control "
        "in reach (§20.8, §21.1)",
        "every control a screen reader reaches has a name in words, and a realm is read in words (§20.8)")),
    ("4b", "Codex", FRONTEND, parts(client_tests(
        "the Codex shows each school's album by its shape and name, its laws in chapter order, a law not met "
        "a ? that names nothing, and when a closed chapter opens (7.6, 21.2, D79)",
        "the Codex shows each album's restored count and its three milestones, and each school's mastery "
        "track with its marks: a title at a third, the style at two thirds, a title at all (7.6, 18.5)",
        "each law met says its next step with its price on the button, and why it waits: too few pages, a "
        "closed chapter, or the Spire a tier needs (7.6)",
        "the Codex names the law worked on, which every eighth heist pages, and any law met can be marked "
        "worked on in one tap (7.6)",
        "restoring sends the law and shows the Codex and the Keeper's experience the server answers; a "
        "refused tier keeps the Codex on show and says why; marking a law worked on shows it (7.6, 14.2)",
        "the Codex screen draws the six albums by their marks, each law's step with its price, a step that "
        "waits disabled with why, and spends pages on a second tap (7.6, 23.2)",
        "against the server: a new Keeper's Codex holds six albums of four launch laws, the starting "
        "three restored and the rest a ?, mastery tracks of twelve steps, and a law marked worked on (7.6, 18.5)",
        "every screen works with text at 150% and 200%: nothing wider than the phone, every control in reach "
        "(§20.8, §21.1)",
        "every control a screen reader reaches has a name in words, and a realm is read in words (§20.8)"),
        server_tests(
        "matchmaking shows only universes running laws from the raider's open chapters, whatever else it "
        "widens (7.6)",
        "a law is met by a heist's route into a realm running it, never by the offer or the lease that "
        "scouts it (7.6)",
        "a school's mastery track takes a step for each law woven, crossed in a successful heist and raised "
        "to tier III, with marks at a third, two thirds and all (18.5)",
        "each school's album holds its launch laws in chapter order, one not met a ? that names nothing, "
        "with its milestones and the level that opens chapter 2 (7.6, D79)"))),
    ("4b", "Lab", FRONTEND, not_started("TD.22's screen gate passes for it")),
    ("4b", "Curation", FRONTEND, not_started("TD.22's screen gate passes for it")),
    ("4b", "Defence log", FRONTEND, not_started("TD.66's screen gate passes for it")),
    ("4b", "First launch", FRONTEND, not_started("TD.26's screen gate passes for it")),
    ("4b", "Landing picker", FRONTEND, not_started("TD.41's screen gate passes for it")),
    ("4b", "Harmony view", FRONTEND, parts(client_tests(
        "the Harmony view shows every law working in a realm with its notes, a crown law among them as "
        "crowned, and the universe's strain (8.1, 5.1, 23.2)",
        "the Harmony view shows each realm's harmonies and clashes, and its resonances and chords, a "
        "named one by its name and one not yet named as an unnamed line, each with what it does to its "
        "laws' cost (8.2, 8.3, 8.4, 8.6, 5.5)",
        "a realm with no laws working says so (23.2)",
        "the Harmony view is fetched from the server, and a failed fetch keeps the last view on show and "
        "says why (23.2)",
        "the Harmony screen draws each realm and every combination its laws make, in words (23.2, 20.8)",
        "against the server: the Harmony view shows a new universe's Heart running nothing yet (23.2)",
        "every screen works with text at 150% and 200%: nothing wider than the phone, every control in reach "
        "(§20.8, §21.1)",
        "every control a screen reader reaches has a name in words, and a realm is read in words (§20.8)"),
        server_tests(
        "the Harmony view shows each realm's laws with their notes, the crown's among them, and the "
        "harmonies, clashes, resonances and chords they make, each with its factor, a resonance or chord "
        "unnamed until the Lab names it (8.2, 8.3, 8.4, 8.6, 23.2)",
        "the Harmony view is served over HTTP (23.2)"),
        not_started("the Lab keeps the resonances and chords it discovers, so the Harmony view names them "
                    "(§8.4, §8.6; TD.65)"))),
    ("4b", "Forms album", FRONTEND, client_tests(
        "the Forms album shows the forms by kind and note, which the player has, and each form's quirk "
        "(11.10, 23.2)",
        "the Forms album says how to hatch each note's forms: the launch laws that carry it, woven in a "
        "Nursery's realm, with the note's look and symbol (11.10, 23.2)",
        "the Forms album shows the outfit each kind's three forms unlock and the skiff sail each note "
        "across every kind unlocks, and how far each is (11.10, 23.2)",
        "the Forms album's Show mine keeps only the forms the player has, and Show all brings the rest "
        "back; a failure keeps the album on show (23.2)",
        "the Forms album screen draws each note, each kind's forms and the sails, and its Show mine button "
        "filters them (23.2)",
        "against the server: the album holds the 54 forms, starts with the player's own three, and names "
        "the launch laws that hatch each note (11.10, 23.2)",
        "every screen works with text at 150% and 200%: nothing wider than the phone, every control "
        "in reach (§20.8, §21.1)",
        "every control a screen reader reaches has a name in words, and a realm is read in words (§20.8)")),
    ("4b", "Share sheet", FRONTEND, not_started("TD.23's screen gate passes for it")),
    ("4b", "Profile", FRONTEND, not_started("TD.24's screen gate passes for it")),
    ("4b", "Hatch", FRONTEND, client_tests(
        "Hatch shows each Nursery's ready births of the three it holds, when the next comes, and the price "
        "(10.2, 9.5, 23.2)",
        "Hatch shows each kind's odds by 11.9's weights and the form's odds on a tie, as the server works "
        "them out, and says why a birth waits (11.9, 11.10, 23.2)",
        "Hatch shows the two traits a birth rolled, its form, and the free outfit with the first hatch, and "
        "offers a name from the word lists (11.3, 19.20, 23.2)",
        "Hatch offers a heist's stray at a birth's price, with the law it was born under, its traits and "
        "its form's odds, to take in or let go (11.5, 23.2)",
        "a hatch names the roster size it leads to, a stray is taken or let go, and a name is sent as the "
        "word lists' indices; a refusal says why (11.5, 19.20)",
        "the Hatch screen draws each Nursery, the strays and the newborn's card; a word changes with a tap, "
        "and a birth is spent on a second tap (23.2)",
        "against the server: with no Nursery yet Hatch says to build one, and a ruleborn is named from "
        "the word lists, the Roster then calling it by its name (19.20, 23.2)",
        "every screen works with text at 150% and 200%: nothing wider than the phone, every control "
        "in reach (§20.8, §21.1)",
        "every control a screen reader reaches has a name in words, and a realm is read in words (§20.8)")),

    # §26.8's phase 4c: "The designs' models exported into Godot within 21.3's
    # budgets, by a harness whose manifest lists 21.9 row by row as exported,
    # made or the contractor's: the nine buildings the designs lack, the four
    # looks of every building, the law signatures they lack, the guard form,
    # forms and work loops (21.6)".
    ("4c", "The export harness and its manifest of §21.9", FRONTEND, not_started(
        "the designs' models are exported into Godot within §21.3's budgets, every "
        "§21.9 row marked exported, made or the contractor's (TD.7)")),
    ("4c", "The nine buildings the designs lack", FRONTEND, not_started(
        "the manifest marks all nine made (TD.32)")),
    ("4c", "The four looks of every building", FRONTEND, not_started(
        "every building has its four looks in the manifest (TD.32)")),
    ("4c", "The law signatures the designs lack", FRONTEND, not_started(
        "every launch law has its signature and a pylon per school (TD.31, TD.32)")),
    ("4c", "The guard form", FRONTEND, not_started("the guard form is in the manifest (TD.32)")),
    ("4c", "Forms and work loops", FRONTEND, not_started(
        "§21.6's forms and work loops are in the manifest (TD.11, TD.62)")),

    ("5", "24 laws as validated data", BACKEND, content_count(
        "laws.json", 24, lambda rows: [r for r in rows if r.get("launch")])),
    ("5", "54 forms as validated data", BACKEND, content_count("forms.json", 54)),
    ("5", "39 terrain features as validated data", BACKEND, content_count("terrain.json", 39)),
    ("5", "The paradox-born from §11.8's tables", BACKEND, content_count("paradox_born.json", 3)),
    ("5", "The visitors", BACKEND, content_count("visitors.json", 3)),
    ("5", "Every card's rule sheet, height, colours and signature", BACKEND, content_count(
        "ruleborn.json", 18, lambda rows: [r for r in rows if all(
            r.get(f) for f in ("rule_sheet", "body", "height_m", "colours", "signature"))])),

    ("6", "Schema", BACKEND, server_tests("snapshots and the ledger cannot be edited")),
    ("6", "Identity: session tokens", BACKEND, server_tests(
        "a session is a signed token, and a forged one is refused")),
    ("6", "Identity: platform sign-in", BACKEND, server_tests(
        "a Game Center identity is Apple's: its key from apple.com, this app, a fresh timestamp, a true signature (24.8)",
        "sign-in over HTTP with a Game Center credential",
        "a Google ID token proves its account only as Google signed it, for this app, in date (24.8)",
        "signing in with Google over HTTP makes an account, and the same token finds it again (24.8)")),
    ("6", "Publishing", BACKEND, server_tests(
        "publishing is content-addressed and idempotent",
        "an island §5.2 or §6.1 forbids is refused, with the rule named")),
    ("6", "The validator", BACKEND, server_tests(
        "a planned clean heist is re-simulated, and its haul minted with the fee returned",
        "a replay that does not reproduce pays nothing, takes nothing, and is flagged (§24.12)",
        "a replay must be the heist its lease allowed: the snapshot, the seed, the clock",
        "a crew that never lands is refused and pays nothing (5.4)")),
    ("6", "Target lists", BACKEND, server_tests(
        "target lists are files, one a band, holding every island's current snapshot (§24.8)",
        "an unchanged band regenerates to the same file, so the edge keeps its cache")),
    ("6", "Rate limits", BACKEND, server_tests(
        "the per-raid cap is 1.98 times the base, derived from richness and difficulty (§9.6)",
        "a day's ceiling is half again above the whole fatigue curve; a week's is five days of it",
        "a haul is capped by what the raider was already paid today (§9.6, §24.12)",
        "past 20 paid raids a week, a raid costs nothing and pays nothing, and the lease says so (9.6, G20)")),
    ("6", "Reference crews and the generator inside the simulation", BACKEND, parts(
        parts(systems("Generator"), server_tests(
            "each day the generator publishes one island a realm level from that day's seed, "
            "the same on every server (12.22)",
            "a thin list reaches for the game's generated islands after echoes and before widening "
            "any filter (12.22)")),
        not_started("the simulation's reference crews rate a new island: §13.3's 800 raids of "
                    "the competent crew, queued and cached by the island's digest (TD.16)"))),
    ("6", "Universes of several realms joined by links", BACKEND, not_started(
        "the server holds universes of several realms joined by links, with the Heart's "
        "winds and §5.4's clock by links (D71)")),

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
    ("7", "Workshop screens", FRONTEND, client_tests(
        "the Workshop reducers keep the list on show when a call fails and name the failure, keep the island played for rating, and a new call clears what the last one said",
        "a Workshop card reads the island's name in the player's language, its realm level, completions (a quarter from the creator's constellation), remixes and ratings, and who made it; a deleted creator is no one (F43), a withdrawn or removed island says so and offers nothing; a 13-to-15 sees only the featured list and their own; the creator's level shows on their own list (§18.6, §18.7, §20.7)",
        "a rehearsal may be published only once it clears the island — loot banked and out, as the server judges — and only once; a raid is never offered; the name is made from the word lists (§18.6)",
        "a Workshop play's answer reads as cleared and counted, or already counted, by the server; one still waiting shows the phone's own check as confirming; a play the server did not accept names why (§18.7, §24.12)",
        "a player aged 13 to 15, refused the top list, is shown the featured list and offered only it and their own islands, with no failure shown (§20.7)",
        "a remixed island becomes the builder's draft, the player's own island kept to swap back, never overwritten; publishing it names the original once; after, the draft is its own island, the rehearsal is not offered again, and the player's own list shows (§18.6)",
        "a remix whose original was removed since is published as the player's own island, not refused for ever (§18.6)",
        "only the list asked for last is shown: tapping one list and then another ends on the second",
        "against the server: a creator rehearses an island on the heist screen, clears it and publishes it named from the word lists; another player finds it among the new islands, plays it on the heist screen, clears it, sees the clear counted and rates it; the creator withdraws it and it leaves the lists (§18.6, §18.7)")),

    ("8", "Currencies", BACKEND, server_tests(
        "a planned clean heist is re-simulated, and its haul minted with the fee returned",
        "the second raid of the day pays 0.85 of the first, and the fee is 2% (§9.4, §9.6)",
        "a pair's second foil of the day keeps the fee with the game (9.4, G37)")),
    ("8", "Cosmetics", BACKEND, server_tests(
        "a cosmetic is bought at its money price, owned once, and worn in its slot (22.1, F41)",
        "a defender's worn cosmetics travel with the lease, so the raider sees them")),
    # Apple's side; Google Play's needs Google's API (D67).
    ("8", "Purchases and receipts", BACKEND, server_tests(
        "a StoreKit 2 transaction counts only with its chain and signature intact, for this app (22.1)",
        "a premium track bought through the App Store is granted from its signed transaction, once (22.1, F41)",
        "a Play purchase counts only as the app's licence key signed it, for this app, bought and paid (22.1)",
        "a Play purchase is granted once, to the account whose intent it carries (20.2, 22.1)",
        "a Play purchase is looked up and acknowledged with Google — a gift consumed — before it is granted, and a test or unpaid one is not (22.1, D67, F41)",
        "a purchase is granted once per store transaction, from a verified receipt (22.1, F41)",
        "a minor's month is capped, €25 at 13 to 15 and €50 at 16 and 17, and an adult gets a summary (20.2)",
        "a refund takes the item back from whoever received it, off wherever it was worn, once (G32)",
        "Apple's refund, posted to the server, takes the purchase back once, and a later receipt for it is refused (G32)",
        "what Google voided is taken back once a day, across its pages, and never twice (G32)")),
    ("8", "Gifts", BACKEND, server_tests(
        "a gift is the same item bought for a friend, and goes to them (F41)",
        "a gift's receipt after its intent is gone is refused before the store settles it, never given to the buyer (F41, G38)")),
    ("8", "The season track", BACKEND, server_tests(
        "a heist earns season stars: the raider by its grade, the defender by what it held (18.2)",
        "the track's first tier is free on day one, and each after costs a tier's stars, in order (18.2)",
        "a player joining late climbs a track scaled to the time remaining (18.8)",
        "stars reset each season, and an unclaimed tier stays claimable later at the same cost (18.8)",
        "the premium track is a store product and adds only cosmetics, for tiers already claimed too (18.2, F41)",
        "the track, the shop and the wardrobe over HTTP")),
    ("8", "The launch cosmetic sets, authored", BACKEND, not_started(
        "server/src/cosmetics.json lists §22.1's launch sets, priced (D64)")),
    ("8", "The Island Fund, paid from purchase records (§18.9)", BACKEND, not_started(
        "the server pays §18.9's Island Fund from its purchase records (D62)")),
    # The screens' data side, headless and against the real server
    # (client/tests/shop_tests.gd); the screens are also in every layout,
    # catalogue and accessibility check. Drawn with placeholder components
    # until the design lands (TC.7).
    ("8", "Shop, track and wallet screens", FRONTEND, client_tests(
        "the shop lists what is for sale, and everything owned, bought or earned, to wear where it is worn: an earned outfit by a crew role, an emote used rather than worn; gifts go to a friend (§22.1, F41, G28)",
        "a purchase asks the server first, then the store with the server's intent, then sends the store's receipt through the outbox; a gift names its friend (F41, §20.2, §24.12)",
        "a purchase over a minor's monthly cap never reaches the store, and the player is told why (§20.2)",
        "a receipt the network cannot carry, or that the server cannot check with the store yet, waits in the outbox and is sent later, never lost (§24.12, D67)",
        "against the server: the track shows this season, its first tier is claimed free and pays its Essence into the wallet, and the premium track is offered at its price; the store's receipt is checked by the server (§18.2, §22.1)",
        "money and numbers are written the player's way: €6.00 and 11,250 in English, €6,00 and 11.250 in Portuguese, and the store's own price before the server's (§19.12)",
        "the track shows the season, the stars in hand, the next tier and its price, and each tier's rewards from both tracks, claimed or not, in every language (§18.2)",
        "the track, shop and wallet reducers change only their own slice, keep what they had when a call fails, and name the failure")),

    ("9", "Leagues", BACKEND, server_tests(
        "a clean heist moves §12.9's Renown to the raider, and Dust's floor mints what it stops",
        "above its floor, the defender loses the mirror amount (12.9)",
        "a foiled heist costs the raider a flat 8, and the defender gains what the raider lost (12.9)",
        "Ember, once reached, is a floor: nobody drops out of Dust or Ember (18.1)",
        "a Renown's league and division: three divisions a league, none in Paradox (18.1)",
        "a raider's first ten heists of the week move Renown, and later ones pay only the haul (12.9, F40)")),
    ("9", "Crews (clans)", BACKEND, server_tests(
        "a constellation: the Beacon from Keeper level 6, thirty Keepers, a founder and four elders (17.1)",
        "a crew is four to eight, joined by its invite, and survives its founder leaving (17.7)",
        "leagues, constellations and crews over HTTP")),
    ("9", "Season rollover", BACKEND, server_tests(
        "a season closes once: results and rewards by league, and the next opens pulled halfway back (18.1)",
        "the constellation league ranks by members' combined Renown at the season's close (17.5)")),
    # client/tests/social_tests.gd, and every screen check, as the shop's.
    ("9", "Social screens", FRONTEND, client_tests(
        "a name from the word lists reads in the player's language, as the server makes it: \"Quiet Harbour\", and in Portuguese the noun first with the adjective agreeing, \"Porto Silencioso\", \"Horta Silenciosa\" (D63)",
        "a refusal is shown in the player's words: founding below Keeper 6, an invite that does not exist; an invite code is sent without its spaces (§17.1, §17.6)",
        "against the server, two players: one invites and the other accepts, and each lists the other; one starts a crew and the other joins it by its invite; the league shows this season (§12.11, §17.6, §17.7, §18.1)",
        "the league shows the place, the division in numerals, Renown and the way to the next league; groups name their members and roles, the player as \"you\"; the feed says who raided whom (§17, §18.1)",
        "the league, groups and friends reducers keep what they had when a call fails, name the failure, read a null group as none, and the friends screen shows the latest outcome, not an older one")),

    # §26.9: the coined names are the owner's to translate, after a native
    # speaker's read-aloud; a name invented here is a translation nobody
    # decided on (tools/client_strings.py).
    # The languages: §20.6's English and Brazilian Portuguese, and the four
    # the owner added (D99): US English, European Portuguese, German, French.
    ("10 to 13", "Localisation: English and Brazilian Portuguese", FRONTEND, parts(
        client_tests(
            "every string a screen asks for is in the catalogue, in each of the game's languages, with the same placeholders"),
        client_tests(
            "a new player starts in the phone's language: Portuguese and English by region, German and French, "
            "British English otherwise, and the picker names each language in itself"),
        not_started("phase 4b's screens are built, their words in every language"),
        not_started("every coined name in content.csv has each language's name, the owner's (§26.9)"),
        not_started("a native speaker has read every coined name aloud, in each language (§26.9)"),
        not_started("a native speaker has read the European Portuguese, German and French interface "
                    "strings, which were drafted here, not commissioned (D99)"))),
    # §20.8's table, area by area, and §21.8's and §21.10's checks, on every
    # screen (client/tests/a11y_tests.gd). VoiceOver and TalkBack on a phone
    # are the device matrix's.
    ("10 to 13", "Notifications on the device: four strings, its own timers, the push permission",
     FRONTEND, parts(
        native_strings(),
        client_tests(
            "the storage-full notice is set for the first producer to fill, moved out of the night to its end, and taken away when nothing will fill (14.6, 20.2)",
            "on coming to the foreground the device tells the server its time zone and, once it may notify, its push token, sends its session events — those kept offline too — and sets its storage-full timer from the home (G34, 14.6, 24)"),
        client_tests(
            "the push permission is asked at the start of the third session, once, and kept across launches (TD.74)"),
        client_tests(
            "the rested notice is set for the first character whose rest ends, moved out of the night, "
            "and taken away once nobody rests (14.6, 11.6)"),
        not_started("the Lab's experiments have a timer to set, once the server keeps them (TD.22)"),
        not_started("on a phone: the tables bundled into both exports, and the platforms' "
                    "notification plugins behind LocalNotifier (TC.3)"))),
    ("10 to 13", "Accessibility", FRONTEND, client_tests(
        "a banner leads with its glyph, is announced, goes by itself, or stays until dismissed when the player asks (§20.8)",
        "a rehearsal can be paused at any time and run at 75%; a raid cannot be paused (§20.8)",
        "every colour the client puts words in reads at 4.5:1 and at APCA's level for its size and weight, the realm's marks on their halo included, in both contrast modes (§21.8, §20.8)",
        "every control a screen reader reaches has a name in words, and a realm is read in words (§20.8)",
        "every screen works with text at 150% and 200%: nothing wider than the phone, every control in reach (§20.8, §21.1)",
        "haptics: a light tap on a button, a warning as the alarm rises, a pulse as a ward or a pylon goes down, nothing when switched off (§21.8, §20.8)",
        "high contrast and reduced motion start as the phone says; text size, contrast, left-handed controls, rehearsal pace, banners, hold time and motion are saved and restored, and take effect (§20.8)",
        "left-handed play mirrors the heist's controls: Get out moves to the other hand (§20.8)",
        "nothing is carried by colour alone: wards by their school's shape, guards by a mark, crew by their role's letters, a status by its glyph (§20.8)",
        "on every screen, every word reads against what is behind it, in every state a control is drawn in and faded as it is, in both contrast modes (§21.8, §21.10)",
        "the island keeps its figures by value: every feature that changes a route, each guard and the outlines of wards, the Vault and the crew stand 3:1 from every ground, and water's ripples from water, in both contrast modes (§21.10)",
        "the six schools stay apart for the three common forms of colour blindness, and each has a shape of its own (§20.8, §21.2)")),
    ("10 to 13", "Compliance: store declarations", BACKEND, not_started(
        "the age, privacy and store declarations are filed; drafted from the schema in "
        "server/declarations.md, checked by server/test/privacy.test.mjs")),
    ("10 to 13", "The edge purged of an under-13 player's bundles on deletion", BACKEND, parts(
        server_tests(
            "an under-13 deletion asks the edge to purge every bundle it erased, until the edge confirms (20.11, D70)",
            "with an edge that answers, the purge is asked as the deletion is made, and a deletion asked for keeps the edge's copy (20.5, 20.11)",
            "purges go to the edge a batch at a time, each refused batch waiting longer, and none given up (D70)"),
        server_tests(
            "Cloudflare's purge by URL is asked with the zone's token for each URL, and its refusals are named (D70)"),
        not_started("the deployed server holds the zone's purge token (RULEBORN_CF_ZONE, "
                    "RULEBORN_CF_PURGE_TOKEN, RULEBORN_PUBLIC_ORIGIN) and one purge is seen to "
                    "empty the edge's copy (§20.11, D70)"))),
    ("10 to 13", "Telemetry", BACKEND, server_tests(
        "the server records sign-ins, heists and purchases under a pseudonym, never the account (24, 20.5)",
        "a device's batch is checked whole: known events, known fields, no positions, sensible times (24.3)",
        "the launch gates' figures: players, crash-free sessions, heists, worth-your-time, buyers (22.2, 25.3)",
        "retention by cohort, day 1, 7, 30 and 60, outlives the raw events discarded after 90 days (24.3, G29)",
        "telemetry over HTTP: a batch from the device, and the report for analysts only")),

    # "Load testing on the edge platform itself (24.1)": measured here, an
    # equal part with the same run on the edge.
    ("14", "Load testing", BACKEND, parts(load_measured(), not_started(
        "the same load runs on the edge platform itself (§24.1)"))),
    ("14", "Real-device matrix", FRONTEND, not_started("the client runs on the device matrix")),
    ("14", "Balance pass", BACKEND, not_started("the launch balance pass is signed off")),
    ("14", "Fix buffer", FRONTEND, not_started("launch fixes are closed")),
    # The server's receivers are built and counted in phase 8; pointing the
    # stores at them is the console work this row is.
    ("14", "Store notifications pointed at the server", BACKEND, not_started(
        "App Store Server Notifications and Play's voided purchases are pointed at the "
        "server in each store's console before soft launch (§22.1)")),
]


def phases() -> dict[str, tuple[str, float]]:
    """§26.8's build phases, read from the document: number -> (name, midpoint runs)."""
    text = TEXT.read_text(encoding="utf-8")
    start = text.index("\n26.8 ")
    table = text[start:text.index("\n26.9 ", start)]
    out = {}
    for num, name, lo, hi in re.findall(
            r"^\| (\d+[a-z]?(?: to \d+)?)\. ([^\n]+)\n\| (\d+) to (\d+)$", table, re.M):
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
            (f"§26.8's build phases are read from the document ({len(build)})", len(build) >= 15),
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
