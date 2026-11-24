#!/usr/bin/env python3
"""The gate's stills, strips and crops, rendered from the shot list at a given
commit (BT-04a: the list and the stills; BT-04b: strips, variants, crops).

    render.py still "<item>" --sha <sha> --out <dir> [--list <shots.json>]
        Export <sha>'s tree (git archive) into a temporary folder, build what
        the client needs there, and render each still of <item> the way the
        lead does by hand: FIT=1 <the item's settings> bash
        tools/render/shoot.sh <script> <png>, run from that folder. Beside each still goes its grayscale at
        960 px on the long edge (tools/ui_gate/sheet.py still --gray), and in
        <dir> a stills.json naming the sha, the list, each still's settings
        and whether its run printed "fit ok". Exits 1 if a still is missing
        or its fit failed: such a still is not judged (gate/shots.md).
    render.py variants [<screen>...] --sha <sha> --out <dir> [--list <shots.json>]
        Each listed screen's three variants, from one export and build: at
        100% text, at 200% text in pt_BR, and in high contrast (for a strip
        screen: its strip, and its strip in high contrast). No screen named
        means every screen in the list. One stills.json for them all.
    render.py list [--list <shots.json>]
        Every item the list names, and the runs each one makes.
    render.py plan "<item>" [--list <shots.json>]
        The runs one item makes, as JSON, without rendering anything.
    render.py --self-test
        The parser's tests, then a fixture item rendered at this checkout's
        HEAD; the render is skipped, saying so, where Godot cannot run.

The shot list (JSON; tools/gate/fixtures/shots.json is the example):

    {"version": 1,
     "screens": {"result": {"script": "client/tests/shots/screen_result.gd",
                            "contrast": "CONTRAST",
                            "states": [{"name": "off", "env": {}},
                                       {"name": "srv", "env": {"SERVER": "1"}}]}},
     "items": [{"item": "settings, signed in, at 200% text, pt_BR",
                "screen": "settings", "env": {"SIGNED": "1", "TEXT": "200"}}]}

- `screens`: one entry per screen. `script` is its shot script; `contrast`
  is the variable it reads for high contrast (`CONTRAST` or `HC`: the
  scripts differ, gate/shots.md); `states` lists the states the player sees,
  each its own still (default: one state, `main`, with no settings).
- An item names a screen and a setting, in the gate's words:
  "<screen> at <n>% text", "<screen> at <n>% text, <locale>" or
  "<screen> in high contrast". These need no entry in `items`: the renderer
  reads them as TEXT=<n> (and LOCALE=<locale>) or <contrast>=1.
- `items` lists the others explicitly, with the screen and the settings.
- Every still's run adds FIT=1. A still is named
  <screen>_<state>_<setting>.png, for example result_srv_200_pt_BR.png, and
  its grayscale result_srv_200_pt_BR.gray.png.

Named crops (BT-04b). A screen (or an item) may list `crops`, the controls
the judge sees at full resolution, and `record`, the variable that makes its
script write the still's shot record (<still>.shot.json, gate/shots.md;
`RECORD` for screen_settings.gd and screen_character.gd):

    "settings": {"script": "...", "contrast": "HC", "record": "RECORD",
                 "crops": ["back", "size-a"]}

A run with crops adds <record>=1, and each crop name picks the record's
controls whose whole name, kind (the words before the number: "back",
"switch-row") or label (the words after the colon) it equals. Each control
picked is cut at full resolution with an 8 pt margin (sheet.py crops) into
<still>.crops/<control>.png; a crop name that picks nothing fails the still,
as a missing still does. `still --crops a,b` adds names for one render.

Frame strips (BT-04b). A screen with `strip` is a motion shot
(client/tests/shots/motion_*.gd, which save every frame to FRAMES):

    "press": {"script": "client/tests/shots/motion_press.gd", "contrast": "HC",
              "states": [{"name": "full", "env": {"FORM": "full"}}],
              "strip": {"pick": "0:43:3", "height": 200}}

Its runs go under Godot's --fixed-fps 60, so frame k is k/60 s in; the
frames that `pick` (a python slice) selects are stamped "frame k  N ms" and
set side by side at `height` px (sheet.py strip) into <name>.strip.png (a
state may set its own `strip` pick or height), with
the shot's log beside it as <name>.frames.json. Its items read
"<screen> strip" and "<screen> strip in high contrast" too. A strip's run
has no FIT: its manifest entry says fit "n/a", and it fails if no frame was
saved.

Builds are cached under ~/.cache/ruleborn/gate (or $RULEBORN_GATE_CACHE):
the simulation's GDExtension by the git trees of sim/ and client/ext/, and
cargo's target directory is shared, so only a commit that changes the
simulation compiles anything. Where that folder cannot be created or written
(a read-only HOME, as under tools/run_checks.sh's sandbox), the cache goes to
<temp>/ruleborn-gate instead (TMPDIR, else the system's temporary folder),
and the render says so on stderr. Nothing is written to the repository's
.git: the commit is exported, not checked out as a worktree, so a read-only
.git renders too. Godot's import cache is seeded from this checkout's
client/.godot when it has one.
"""
import argparse
import hashlib
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[2]
HERE = pathlib.Path(__file__).resolve().parent
EXAMPLE_LIST = HERE / "fixtures" / "shots.json"
TEST_LIST = HERE / "fixtures" / "test_shots.json"
# AD keeps the shot lists (agent-protocol.md, the roster); this is where the
# renderer looks for AD's first, and it falls back to the example.
AD_LIST = ROOT / "docs" / "art" / "ui-quality" / "gate" / "shots.json"
GODOT_VERSION = "4.7.2-stable"

STRIP_RE = re.compile(r"^(?P<screen>[a-z][a-z_ ]*?) strip(?P<hc> in high contrast)?$")
TEXT_RE = re.compile(r"^(?P<screen>[a-z][a-z_ ]*?) at (?P<n>\d+)% text(?:, (?P<locale>[a-z]{2}(?:_[A-Z]{2})?))?$")
CONTRAST_RE = re.compile(r"^(?P<screen>[a-z][a-z_ ]*?) in high contrast$")


class ListError(ValueError):
    pass


def default_list():
    return AD_LIST if AD_LIST.exists() else EXAMPLE_LIST


def load_list(path):
    data = json.loads(pathlib.Path(path).read_text())
    if data.get("version") != 1:
        raise ListError(f"{path}: version {data.get('version')!r}, this renderer reads version 1")
    screens = data.get("screens")
    if not isinstance(screens, dict) or not screens:
        raise ListError(f"{path}: no screens")
    for name, s in screens.items():
        if not str(s.get("script", "")).startswith("client/") or not s["script"].endswith(".gd"):
            raise ListError(f"{path}: screen {name!r}: script must be a .gd under client/")
        if s.get("contrast") not in ("CONTRAST", "HC"):
            raise ListError(f"{path}: screen {name!r}: contrast must be CONTRAST or HC")
        seen = set()
        for st in s.get("states", [{"name": "main", "env": {}}]):
            if not re.fullmatch(r"[a-z0-9]+", st.get("name", "")) or st["name"] in seen:
                raise ListError(f"{path}: screen {name!r}: bad or repeated state name {st.get('name')!r}")
            seen.add(st["name"])
            _check_env(path, st.get("env", {}))
        _check_crops(path, name, s)
        if "strip" in s:
            for st in [{"strip": {}}, *s.get("states", [])]:
                if not isinstance(s["strip"], dict) or not isinstance(st.get("strip", {}), dict):
                    raise ListError(f"{path}: screen {name!r}: strip must be an object")
                st = {**s["strip"], **st.get("strip", {})}
                if not isinstance(st.get("height"), int) or not 32 <= st["height"] <= 2048:
                    raise ListError(f"{path}: screen {name!r}: strip needs a height in px, 32 to 2048")
                try:
                    _slice(st.get("pick", "::1"))
                except ValueError:
                    raise ListError(f"{path}: screen {name!r}: strip pick {st.get('pick')!r} is not a slice a:b:c")
            if s.get("crops"):
                raise ListError(f"{path}: screen {name!r}: a strip has no shot record to crop")
    for it in data.get("items", []):
        if it.get("screen") not in screens:
            raise ListError(f"{path}: item {it.get('item')!r}: unknown screen {it.get('screen')!r}")
        _check_env(path, it.get("env", {}))
        _check_crops(path, it.get("item"), {**it, "record": screens[it["screen"]].get("record")})
    return data


def _check_crops(path, name, s):
    crops = s.get("crops", [])
    if not isinstance(crops, list) or not all(isinstance(c, str) and c.strip() for c in crops):
        raise ListError(f"{path}: {name!r}: crops must be a list of control names")
    rec = s.get("record")
    if rec is not None and not re.fullmatch(r"[A-Z][A-Z0-9_]*", str(rec)):
        raise ListError(f"{path}: {name!r}: record must name a variable, as RECORD")
    if crops and not rec:
        raise ListError(f"{path}: {name!r}: crops need the screen's record variable")


def _slice(pick):
    """The python slice a:b:c, as a slice."""
    parts = str(pick).split(":")
    if len(parts) > 3 or not all(re.fullmatch(r"-?\d*", x) for x in parts):
        raise ValueError(pick)
    a, b, c = ([int(x) if x else None for x in parts] + [None, None])[:3]
    if c == 0:
        raise ValueError(pick)
    return slice(a, b, c)


def _check_env(path, env):
    for k, v in env.items():
        if not re.fullmatch(r"[A-Z][A-Z0-9_]*", k) or not isinstance(v, str):
            raise ListError(f"{path}: setting {k}={v!r}: names are upper case, values strings")
        if k in ("SHOT", "FIT"):
            raise ListError(f"{path}: setting {k} is the renderer's own")


def _slug(env):
    parts = []
    if "TEXT" in env:
        parts.append(env["TEXT"])
    if "LOCALE" in env:
        parts.append(env["LOCALE"])
    for k in sorted(env):
        if k in ("TEXT", "LOCALE"):
            continue
        if k in ("CONTRAST", "HC") and env[k] == "1":
            parts.append("hc")
        else:
            parts.append(f"{k.lower()}{'' if env[k] == '1' else env[k]}")
    s = "_".join(parts) or "100"
    return re.sub(r"[^A-Za-z0-9_]+", "-", s)


def plan(data, item, crops=()):
    """The runs an item makes: [{"name", "script", "env"[, "crops"][, "strip"]}];
    crops adds crop names to the list's own."""
    screens = data["screens"]
    explicit = [it for it in data.get("items", []) if it["item"] == item]
    extra = []
    if explicit:
        screen = explicit[0]["screen"]
        setting = dict(explicit[0].get("env", {}))
        extra = explicit[0].get("crops", [])
    else:
        m = TEXT_RE.match(item)
        c = CONTRAST_RE.match(item)
        st = STRIP_RE.match(item)
        if st and st["screen"] in screens and "strip" in screens[st["screen"]]:
            screen = st["screen"]
            setting = {screens[screen]["contrast"]: "1"} if st["hc"] else {}
        elif m and m["screen"] in screens:
            screen = m["screen"]
            setting = {} if m["n"] == "100" and not m["locale"] else {"TEXT": m["n"]}
            if m["locale"]:
                setting["LOCALE"] = m["locale"]
        elif c and c["screen"] in screens:
            screen = c["screen"]
            setting = {screens[screen]["contrast"]: "1"}
        else:
            raise ListError(f"no item {item!r} in the list, and it does not read as "
                            f"'<screen> at <n>% text[, <locale>]', '<screen> in high contrast' "
                            f"or '<strip screen> strip[ in high contrast]' "
                            f"for a listed screen ({', '.join(sorted(screens))})")
    s = screens[screen]
    states = s.get("states", [{"name": "main", "env": {}}])
    crops = list(dict.fromkeys([*s.get("crops", []), *extra, *crops]))
    if crops and "strip" in s:
        raise ListError(f"{item!r}: a strip has no shot record to crop")
    if crops and not s.get("record"):
        raise ListError(f"{item!r}: crops need the screen's record variable in the list")
    runs = []
    for st in states:
        env = {**st.get("env", {}), **setting}
        name = screen if len(states) == 1 else f"{screen}_{st['name']}"
        if "strip" in s:
            strip = {**s["strip"], **st.get("strip", {})}
            runs.append({"name": f"{name}_{_slug(setting)}", "script": s["script"], "env": env,
                         "strip": {"pick": strip.get("pick", "::1"), "height": strip["height"]}})
            continue
        run = {"name": f"{name}_{_slug(setting)}", "script": s["script"], "env": {"FIT": "1", **env}}
        if crops:
            run["env"][s["record"]] = "1"
            run["crops"] = crops
        runs.append(run)
    return runs


def variants(data, screen):
    """The gate's three variants of a screen, as item names."""
    if screen not in data["screens"]:
        raise ListError(f"no screen {screen!r} in the list ({', '.join(sorted(data['screens']))})")
    if "strip" in data["screens"][screen]:
        return [f"{screen} strip", f"{screen} strip in high contrast"]
    return [f"{screen} at 100% text", f"{screen} at 200% text, pt_BR", f"{screen} in high contrast"]


def pick_controls(record, names):
    """{crop name: [control names]} of a shot record: each name matches a
    control's whole name, its kind (before the number) or its label (after
    the colon)."""
    out = {}
    for want in names:
        hits = []
        for c in record.get("controls", []):
            full = c["name"]
            m = re.match(r"^(?P<kind>.*?) \d+: (?P<label>.*)$", full)
            if want == full or (m and want in (m["kind"], m["label"].strip())):
                hits.append(full)
        out[want] = hits
    return out


def _file_name(s):
    return re.sub(r"[^A-Za-z0-9_.-]+", "-", s).strip("-")[:80] or "control"


def _ui_gate():
    """tools/ui_gate/sheet.py and checks.py, imported from this checkout."""
    d = str(ROOT / "tools" / "ui_gate")
    if d not in sys.path:
        sys.path.insert(0, d)
    import checks
    import sheet
    return sheet, checks


def cut_crops(still, record_path, names, margin=8.0):
    """Each control the names pick, cut at full resolution into
    <still>.crops/; returns ([{"crop", "control", "file"}], [names that
    picked nothing])."""
    sheet, checks = _ui_gate()
    record = json.loads(pathlib.Path(record_path).read_text())
    picked = pick_controls(record, names)
    missing = [n for n, hits in picked.items() if not hits]
    want = list(dict.fromkeys(h for hits in picked.values() for h in hits))
    shot = checks.Shot(record, base=pathlib.Path(record_path).parent)
    cut = sheet.crops(shot, want, margin) if want else {}
    folder = pathlib.Path(still).with_suffix(".crops")
    shutil.rmtree(folder, ignore_errors=True)
    folder.mkdir()
    rows, used = [], set()
    for n, hits in picked.items():
        for h in hits:
            f = _file_name(h)
            while f in used:
                f += "_"
            used.add(f)
            cut[h].save(folder / f"{f}.png")
            rows.append({"crop": n, "control": h, "file": f"{folder.name}/{f}.png"})
    return rows, missing


def stamp(path, k, fps=60):
    """Frame k with a band along its top reading "frame k  N ms"."""
    from PIL import Image, ImageDraw, ImageFont
    im = Image.open(path).convert("RGB")
    band = 34
    out = Image.new("RGB", (im.width, im.height + band), (246, 244, 250))
    out.paste(im, (0, band))
    font = ImageFont.load_default()
    for f in ("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"):
        if pathlib.Path(f).exists():
            font = ImageFont.truetype(f, 24)
            break
    ImageDraw.Draw(out).text((10, 4), f"frame {k}   {k * 1000 / fps:.0f} ms", fill=(20, 18, 26), font=font)
    return out


def make_strip(frames_dir, pick, height, out_png):
    """The strip of the frames f000.png... in frames_dir that pick selects;
    returns the frame numbers shown."""
    sheet, _ = _ui_gate()
    frames = sorted(pathlib.Path(frames_dir).glob("f[0-9]*.png"))[_slice(pick)]
    if not frames:
        raise RuntimeError(f"no frames in {frames_dir} for pick {pick}")
    ks = [int(f.stem[1:]) for f in frames]
    sheet.strip([stamp(f, k) for f, k in zip(frames, ks)], height=height).save(out_png)
    return ks


def git(*args, cwd=ROOT, check=True):
    return subprocess.run(["git", *args], cwd=cwd, check=check, capture_output=True, text=True).stdout.strip()


_cache = None


def _writable(d):
    """None if folder d can be created and written, else why not."""
    try:
        d.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryFile(dir=d):
            pass
    except OSError as e:
        return e.strerror or str(e)
    return None


def cache_dir():
    """The build cache: $RULEBORN_GATE_CACHE or ~/.cache/ruleborn/gate, else <temp>/ruleborn-gate."""
    global _cache
    if _cache is None:
        want = pathlib.Path(os.environ.get("RULEBORN_GATE_CACHE")
                            or pathlib.Path.home() / ".cache" / "ruleborn" / "gate")
        why = _writable(want)
        if why is None:
            _cache = want
        else:
            alt = pathlib.Path(tempfile.gettempdir()) / "ruleborn-gate"
            alt_why = _writable(alt)
            if alt_why is not None:
                raise RuntimeError(f"no build cache: {want}: {why}; {alt}: {alt_why}")
            print(f"render.py: the build cache is {alt}: {want} cannot be written ({why})", file=sys.stderr)
            _cache = alt
    return _cache


def export(sha, dest):
    """<sha>'s tree into folder dest, reading the repository's objects only."""
    arc = subprocess.Popen(["git", "archive", "--format=tar", sha], cwd=ROOT,
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    tar = subprocess.run(["tar", "-x", "-C", str(dest)], stdin=arc.stdout, capture_output=True, text=True)
    arc.stdout.close()
    err = arc.stderr.read().decode(errors="replace")
    if arc.wait() or tar.returncode:
        raise RuntimeError(f"could not export {sha[:8]}: {(err + tar.stderr).strip()}")


def godot_path():
    return pathlib.Path(os.environ.get("RULEBORN_GODOT",
                                       pathlib.Path.home() / ".cache" / "ruleborn" / f"Godot_v{GODOT_VERSION}_linux.x86_64"))


def godot_can_run():
    """Why Godot cannot render here, or None."""
    if not godot_path().is_file():
        return f"no Godot at {godot_path()} (bash client/build.sh fetches it)"
    for tool in ("xvfb-run", "cargo"):
        if not shutil.which(tool):
            return f"no {tool} on PATH"
    return None


def build(wt, sha, log):
    """What client/build.sh makes, in the exported tree, from the caches."""
    trees = "\n".join(git("rev-parse", f"{sha}:{p}") for p in ("sim", "client/ext"))
    key = hashlib.sha256(trees.encode()).hexdigest()[:16]
    lib = cache_dir() / "lib" / f"{key}.so"
    if not lib.exists():
        lib.parent.mkdir(exist_ok=True)
        env = {**os.environ, "CARGO_TARGET_DIR": str(cache_dir() / "target")}
        log.write(f"building the simulation's GDExtension for trees {key}\n")
        r = subprocess.run(["cargo", "build", "--release", "--quiet"], cwd=wt / "client" / "ext",
                           env=env, capture_output=True, text=True)
        log.write(r.stdout + r.stderr)
        if r.returncode:
            raise RuntimeError(f"cargo build failed at {sha[:8]}; see {log.name}")
        tmp = lib.with_suffix(f".{os.getpid()}.tmp")
        shutil.copy2(cache_dir() / "target" / "release" / "libruleborn_godot.so", tmp)
        tmp.replace(lib)
    (wt / "client" / "bin").mkdir(exist_ok=True)
    shutil.copy2(lib, wt / "client" / "bin" / "libruleborn_godot.so")
    goldens = wt / "client" / "goldens"
    goldens.mkdir(exist_ok=True)
    for f in (wt / "sim" / "golden").glob("*.rbh"):
        shutil.copy2(f, goldens / f.name)
    seed = ROOT / "client" / ".godot"
    if seed.is_dir() and not (wt / "client" / ".godot").exists():
        shutil.copytree(seed, wt / "client" / ".godot", symlinks=True)
    return key


def _run_still(wt, run, out, log):
    png = out / f"{run['name']}.png"
    grey = out / f"{run['name']}.gray.png"
    record = out / f"{run['name']}.shot.json"
    for f in (png, grey, record):
        f.unlink(missing_ok=True)
    env = {**os.environ, **run["env"]}
    env.pop("SHOT", None)
    log.write(f"\n== {run['name']}: {' '.join(f'{k}={v}' for k, v in run['env'].items())} "
              f"bash tools/render/shoot.sh {run['script']} {png.name}\n")
    r = subprocess.run(["bash", "tools/render/shoot.sh", run["script"], str(png)],
                       cwd=wt, env=env, capture_output=True, text=True)
    said = r.stdout + r.stderr
    log.write(said)
    fit = "ok" if re.search(r"^fit ok$", said, re.M) else (
        "FAIL" if re.search(r"^fit FAIL", said, re.M) else "not printed")
    rec = {"name": run["name"], "script": run["script"], "env": run["env"],
           "still": png.name, "gray": None, "fit": fit, "exit": r.returncode}
    ok = True
    if png.is_file() and png.stat().st_size:
        subprocess.run([sys.executable, str(ROOT / "tools" / "ui_gate" / "sheet.py"), "still",
                        str(png), str(grey), "--long", "960", "--gray"], check=True,
                       capture_output=True)
        rec["gray"] = grey.name
        if run.get("crops"):
            if record.is_file():
                rec["record"] = record.name
                rec["crops"], rec["crops_missing"] = cut_crops(png, record, run["crops"])
                for n in rec["crops_missing"]:
                    log.write(f"crop {n!r}: no control of the record matches it\n")
            else:
                rec["record"], rec["crops"], rec["crops_missing"] = None, [], list(run["crops"])
                log.write(f"no shot record {record.name}: {run['script']} did not write one\n")
            ok = not rec["crops_missing"]
    else:
        rec["still"] = None
    return rec, ok and rec["still"] is not None and fit == "ok"


def _run_strip(wt, run, out, log):
    strip_png = out / f"{run['name']}.strip.png"
    frames_log = out / f"{run['name']}.frames.json"
    for f in (strip_png, frames_log):
        f.unlink(missing_ok=True)
    frames = pathlib.Path(tempfile.mkdtemp(prefix="frames-", dir=wt))
    env = {**os.environ, **run["env"], "FRAMES": str(frames)}
    env.pop("SHOT", None)
    rel = run["script"].removeprefix("client/")
    log.write(f"\n== {run['name']}: {' '.join(f'{k}={v}' for k, v in run['env'].items())} "
              f"godot --fixed-fps 60 -s res://{rel}, strip {run['strip']['pick']} at {run['strip']['height']} px\n")
    r = subprocess.run(["timeout", os.environ.get("SHOT_TIMEOUT", "300"), "xvfb-run", "-a", "-s",
                        "-screen 0 1280x1280x24", str(godot_path()), "--rendering-driver", "opengl3",
                        "--fixed-fps", "60", "--path", "client", "-s", f"res://{rel}"],
                       cwd=wt, env=env, capture_output=True, text=True)
    log.write("\n".join(x for x in (r.stdout + r.stderr).splitlines() if x)[-4000:] + "\n")
    rec = {"name": run["name"], "script": run["script"], "env": run["env"], "strip": None,
           "frames": None, "shown": [], "pick": run["strip"]["pick"], "height": run["strip"]["height"],
           "fit": "n/a", "exit": r.returncode}
    if (frames / "log.json").is_file() and list(frames.glob("f[0-9]*.png")):
        try:
            rec["shown"] = make_strip(frames, run["strip"]["pick"], run["strip"]["height"], strip_png)
            rec["strip"] = strip_png.name
        except RuntimeError as e:
            log.write(f"{e}\n")
        shutil.copy2(frames / "log.json", frames_log)
        rec["frames"] = frames_log.name
    else:
        log.write(f"no frames saved by {run['script']}\n")
    shutil.rmtree(frames, ignore_errors=True)
    return rec, rec["strip"] is not None


def render(items, sha, out, list_path=None, keep=False, crops=()):
    """Render each item (a name, or a list of names) at sha into out."""
    items = [items] if isinstance(items, str) else list(items)
    list_path = pathlib.Path(list_path or default_list()).resolve()
    data = load_list(list_path)
    runs = []
    for item in items:
        for run in plan(data, item, crops):
            if any(r["name"] == run["name"] for r in runs):
                continue
            runs.append({**run, "item": item})
    why = godot_can_run()
    if why:
        raise RuntimeError(f"cannot render: {why}")
    full = git("rev-parse", "--verify", f"{sha}^{{commit}}")
    out = pathlib.Path(out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    wt = pathlib.Path(tempfile.mkdtemp(prefix=f"gate-{full[:8]}-", dir=cache_dir()))
    stills, ok, key = [], True, None
    with open(out / "render.log", "w") as log:
        try:
            export(full, wt)
            key = build(wt, full, log)
            for run in runs:
                if not (wt / run["script"]).is_file():
                    raise RuntimeError(f"{run['script']} does not exist at {full[:8]}")
            if any("strip" in run for run in runs):
                subprocess.run([str(godot_path()), "--headless", "--path", "client", "--import"],
                               cwd=wt, capture_output=True)
            for run in runs:
                rec, good = (_run_strip if "strip" in run else _run_still)(wt, run, out, log)
                rec = {"item": run["item"], **rec}
                ok = ok and good
                stills.append(rec)
        finally:
            if keep:
                print(f"render.py: kept the tree at {wt}", file=sys.stderr)
            else:
                shutil.rmtree(wt, ignore_errors=True)
    manifest = {"item": items[0] if len(items) == 1 else None, "items": items, "sha": full,
                "list": str(list_path.relative_to(ROOT)) if list_path.is_relative_to(ROOT) else str(list_path),
                "list_sha256": hashlib.sha256(list_path.read_bytes()).hexdigest(),
                "build": key, "ok": ok, "stills": stills}
    (out / "stills.json").write_text(json.dumps(manifest, indent=1) + "\n")
    return manifest


def self_test():
    failures = []

    def expect(cond, what):
        if not cond:
            failures.append(what)
            print(f"FAIL {what}")

    data = load_list(EXAMPLE_LIST)
    r = plan(data, "heist at 200% text, pt_BR")
    expect(r == [{"name": "heist_200_pt_BR", "script": "client/tests/shots/screen_heist.gd",
                  "env": {"FIT": "1", "TEXT": "200", "LOCALE": "pt_BR"}}], f"heist at 200% pt_BR: {r}")
    r = plan(data, "result in high contrast")
    expect([x["name"] for x in r] == ["result_off_hc", "result_srv_hc"], f"result hc names: {r}")
    expect(r[1]["env"] == {"FIT": "1", "SERVER": "1", "CONTRAST": "1"}, f"result srv hc env: {r[1]}")
    r = plan(data, "character in high contrast")
    expect(r[0]["env"] == {"FIT": "1", "HC": "1", "RECORD": "1"} and r[0]["crops"] == ["back"],
           f"character reads HC, and records its controls for its crops: {r}")
    r = plan(data, "settings at 100% text")
    expect(r[0]["env"] == {"FIT": "1", "RECORD": "1"} and r[0]["crops"] == ["back", "size-a", "row"],
           f"settings' crops: {r}")
    r = plan(data, "home at 100% text", crops=())
    expect("crops" not in r[0] and "RECORD" not in r[0]["env"], f"no crops, no record: {r}")
    r = plan(data, "settings at 100% text", crops=["back", "sample"])
    expect(r[0]["crops"] == ["back", "size-a", "row", "sample"], f"asked crops join the list's: {r}")
    r = plan(data, "press strip")
    expect(r == [{"name": "press_full_100", "script": "client/tests/shots/motion_press.gd", "env": {"FORM": "full"},
                  "strip": {"pick": "0:43:3", "height": 200}},
                 {"name": "press_reduced_100", "script": "client/tests/shots/motion_press.gd",
                  "env": {"FORM": "reduced"}, "strip": {"pick": "0:43:3", "height": 200}}], f"press strip: {r}")
    r = plan(data, "press strip in high contrast")
    expect([x["env"] for x in r] == [{"FORM": "full", "HC": "1"}, {"FORM": "reduced", "HC": "1"}]
           and r[0]["name"] == "press_full_hc", f"press strip in high contrast: {r}")
    r = plan(data, "shine strip")
    expect([x["strip"]["pick"] for x in r] == ["42:66:2", "0:999:24"], f"a state's own pick: {r}")
    expect(variants(data, "settings") == ["settings at 100% text", "settings at 200% text, pt_BR",
                                          "settings in high contrast"], f"variants: {variants(data, 'settings')}")
    expect(variants(data, "press") == ["press strip", "press strip in high contrast"],
           f"strip variants: {variants(data, 'press')}")
    expect(_slice("0:43:3") == slice(0, 43, 3) and _slice("::1") == slice(None, None, 1), "slices")
    rec = {"controls": [{"name": "row 2: Jogo Acesso Conta"}, {"name": "size-a 4: Texto 200%: menor"},
                        {"name": "size-a 6: Texto 200%: maior"}, {"name": "back 9: Voltar"}]}
    r = pick_controls(rec, ["size-a", "Voltar", "back 9: Voltar", "vault"])
    expect(r == {"size-a": ["size-a 4: Texto 200%: menor", "size-a 6: Texto 200%: maior"],
                 "Voltar": ["back 9: Voltar"], "back 9: Voltar": ["back 9: Voltar"], "vault": []},
           f"pick_controls: {r}")
    r = plan(data, "home at 100% text")
    expect(r == [{"name": "home_100", "script": "client/tests/shots/universe_home.gd", "env": {"FIT": "1"}}],
           f"home at 100%: {r}")
    r = plan(data, "heist at 200% text")
    expect(r[0]["env"] == {"FIT": "1", "TEXT": "200"} and r[0]["name"] == "heist_200", f"no locale: {r}")
    for bad, crops in (("vault at 100% text", ()), ("heist at 200% text, pt_BR, no crew plan", ()),
                       ("heist at big text", ()), ("vault strip", ()), ("heist strip", ()),
                       ("home at 100% text", ("back",)), ("press strip", ("back",))):
        try:
            plan(data, bad, crops)
            expect(False, f"{bad!r} with crops {crops} should be refused")
        except ListError:
            pass
    for bad in ("vault", "press strip"):
        try:
            variants(data, bad)
            expect(False, f"variants of {bad!r} should be refused")
        except ListError:
            pass
    t = load_list(TEST_LIST)
    r = plan(t, "settings, signed in, at 200% text, pt_BR")
    expect(r[0]["name"] == "settings_200_pt_BR_signed" and r[0]["env"]["SIGNED"] == "1", f"explicit item: {r}")
    with tempfile.TemporaryDirectory() as d:
        for broken, why in (({"version": 2, "screens": {"a": {}}}, "version"),
                            ({"version": 1, "screens": {"a": {"script": "x.gd", "contrast": "HC"}}}, "script"),
                            ({"version": 1, "screens": {"a": {"script": "client/a.gd", "contrast": "HI"}}}, "contrast"),
                            ({"version": 1, "screens": {"a": {"script": "client/a.gd", "contrast": "HC",
                              "states": [{"name": "x", "env": {"SHOT": "/tmp/x"}}]}}}, "SHOT"),
                            ({"version": 1, "screens": {"a": {"script": "client/a.gd", "contrast": "HC",
                              "crops": ["back"]}}}, "crops without a record"),
                            ({"version": 1, "screens": {"a": {"script": "client/a.gd", "contrast": "HC",
                              "record": "RECORD", "crops": "back"}}}, "crops not a list"),
                            ({"version": 1, "screens": {"a": {"script": "client/a.gd", "contrast": "HC",
                              "record": "record", "crops": ["back"]}}}, "record variable"),
                            ({"version": 1, "screens": {"a": {"script": "client/a.gd", "contrast": "HC",
                              "strip": {"pick": "0:9:0", "height": 200}}}}, "strip step"),
                            ({"version": 1, "screens": {"a": {"script": "client/a.gd", "contrast": "HC",
                              "strip": {"pick": "0:9", "height": 8}}}}, "strip height"),
                            ({"version": 1, "screens": {"a": {"script": "client/a.gd", "contrast": "HC",
                              "states": [{"name": "x", "env": {}, "strip": {"pick": "a:b"}}],
                              "strip": {"height": 200}}}}, "state's strip pick"),
                            ({"version": 1, "screens": {"a": {"script": "client/a.gd", "contrast": "HC",
                              "record": "RECORD", "crops": ["back"], "strip": {"height": 200}}}},
                             "strip with crops")):
            p = pathlib.Path(d) / "l.json"
            p.write_text(json.dumps(broken))
            try:
                load_list(p)
                expect(False, f"a list with a bad {why} should be refused")
            except ListError:
                pass
    print(f"render.py: the shot list's parser, {'FAIL' if failures else 'ok'}")

    # A strip of synthetic frames: the pick's frames, each stamped, side by side.
    from PIL import Image
    with tempfile.TemporaryDirectory() as d:
        for k in range(10):
            Image.new("RGB", (60, 100), (k * 25, 90, 200 - k * 20)).save(pathlib.Path(d) / f"f{k:03d}.png")
        out = pathlib.Path(d) / "s.png"
        ks = make_strip(d, "0:10:3", 80, out)
        expect(ks == [0, 3, 6, 9], f"strip frames: {ks}")
        im = Image.open(out)
        tile = 60 * 80 / 134  # a 60 x 100 frame with its 34 px stamp, at 80 px
        expect(im.height >= 80 and im.width >= 4 * tile, f"strip size {im.size}: want four tiles of {tile:.0f} px")
        try:
            make_strip(d, "20:30:1", 80, out)
            expect(False, "a pick past the last frame should be refused")
        except RuntimeError:
            pass
    print(f"render.py: the strip of synthetic frames, {'FAIL' if failures else 'ok'}")

    # The build cache falls back to the temporary folder when its own cannot
    # be written (a read-only HOME under tools/run_checks.sh's sandbox).
    global _cache
    saved, saved_env = _cache, os.environ.get("RULEBORN_GATE_CACHE")
    with tempfile.NamedTemporaryFile() as f:
        try:
            _cache = None
            os.environ["RULEBORN_GATE_CACHE"] = str(pathlib.Path(f.name) / "gate")
            d = cache_dir()
            expect(d == pathlib.Path(tempfile.gettempdir()) / "ruleborn-gate" and _writable(d) is None,
                   f"an unwritable cache falls back to the temporary folder: {d}")
        except (OSError, RuntimeError) as e:
            expect(False, f"an unwritable cache should fall back to the temporary folder: {e}")
        finally:
            _cache = saved
            if saved_env is None:
                os.environ.pop("RULEBORN_GATE_CACHE", None)
            else:
                os.environ["RULEBORN_GATE_CACHE"] = saved_env
    print(f"render.py: the build cache's fallback, {'FAIL' if failures else 'ok'}")

    why = godot_can_run()
    if why:
        print(f"render.py: SKIPPED the fixture render: {why}")
        return 1 if failures else 0
    sha = git("rev-parse", "HEAD")
    import numpy as np
    with tempfile.TemporaryDirectory() as d:
        m = render(["settings at 200% text, pt_BR", "press strip"], sha, d, TEST_LIST)
        s = m["stills"][0]
        expect(m["sha"] == sha and len(m["stills"]) == 2 and m["ok"], f"manifest: {m}")
        expect(s["env"] == {"FIT": "1", "TEXT": "200", "LOCALE": "pt_BR", "RECORD": "1"}, f"run env: {s}")
        expect(s["fit"] == "ok", f"fit: {s['fit']}; see the log: {(pathlib.Path(d) / 'render.log').read_text()[-1500:]}")
        if s["still"] and s["gray"]:
            from PIL import Image
            big = Image.open(pathlib.Path(d) / s["still"])
            small = Image.open(pathlib.Path(d) / s["gray"])
            import numpy as np
            expect(min(big.size) >= 400, f"still size {big.size}")
            expect(max(small.size) == 960, f"gray size {small.size}")
            px = np.asarray(small.convert("RGB")).reshape(-1, 3)
            expect(bool((px[:, 0] == px[:, 1]).all() and (px[:, 1] == px[:, 2]).all()), "the copy is not gray")
            expect(len(np.unique(px[:, 0])) > 8, "the gray copy is blank")
            # The named crops, at full resolution, from the still's shot record.
            crops = s.get("crops") or []
            expect(not s.get("crops_missing") and [c["crop"] for c in crops] == ["back", "size-a", "size-a"],
                   f"crops: {crops}, missing {s.get('crops_missing')}")
            rec = json.loads((pathlib.Path(d) / s["record"]).read_text()) if s.get("record") else {}
            rects = {c["name"]: c["rect"] for c in rec.get("controls", [])}
            px_per_pt = big.width / rec.get("frame_pt", [big.width])[0]
            for c in crops:
                f = pathlib.Path(d) / c["file"]
                if not f.is_file():
                    expect(False, f"no crop file {c['file']}")
                    continue
                im = Image.open(f)
                lo, hi = rects[c["control"]][2] * px_per_pt, (rects[c["control"]][2] + 16) * px_per_pt
                expect(lo - 2 <= im.width <= hi + 2, f"crop {c['file']} is {im.size}: not the control at "
                       f"full resolution with its margin, {lo:.0f} to {hi:.0f} px wide")
                expect(len(np.unique(np.asarray(im.convert("L")))) > 8, f"crop {c['file']} is blank")
        else:
            expect(False, f"no still: {s}")
        # The fixture strip: every sixth frame of the press, stamped.
        t = m["stills"][1]
        expect(t["item"] == "press strip" and t["env"] == {"FORM": "full"} and t["fit"] == "n/a", f"strip run: {t}")
        expect(t["shown"] == list(range(0, 43, 6)), f"strip frames shown: {t['shown']}")
        if t["strip"] and t["frames"]:
            im = Image.open(pathlib.Path(d) / t["strip"])
            expect(im.height >= 120 and im.width > 4 * im.height, f"strip size {im.size}")
            expect(len(np.unique(np.asarray(im.convert("L")))) > 8, "the strip is blank")
            fl = json.loads((pathlib.Path(d) / t["frames"]).read_text())
            expect(bool(fl), "the frames' log is empty")
        else:
            expect(False, f"no strip: {t}; see the log: {(pathlib.Path(d) / 'render.log').read_text()[-1500:]}")
        expect(not list(cache_dir().glob(f"gate-{sha[:8]}-*")), "the exported tree was left behind")
    print(f"render.py: the fixture item at {sha[:8]}, {'FAIL' if failures else 'ok'}")
    return 1 if failures else 0


def main(argv):
    if argv == ["--self-test"]:
        return self_test()
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("still")
    s.add_argument("item")
    s.add_argument("--sha", required=True)
    s.add_argument("--out", required=True)
    s.add_argument("--list")
    s.add_argument("--keep", action="store_true", help="keep the exported tree, for debugging")
    s.add_argument("--crops", default="", help="crop names to add to the list's, comma separated")
    v = sub.add_parser("variants")
    v.add_argument("screens", nargs="*")
    v.add_argument("--sha", required=True)
    v.add_argument("--out", required=True)
    v.add_argument("--list")
    v.add_argument("--keep", action="store_true", help="keep the exported tree, for debugging")
    ls = sub.add_parser("list")
    ls.add_argument("--list")
    pl = sub.add_parser("plan")
    pl.add_argument("item")
    pl.add_argument("--list")
    a = p.parse_args(argv)
    path = a.list or default_list()
    try:
        if a.cmd == "list":
            data = load_list(path)
            print(f"# {path}")
            names = [it["item"] for it in data.get("items", [])]
            for screen in data["screens"]:
                names += variants(data, screen)
            for n in names:
                print(n)
                for r in plan(data, n):
                    out = (f"{r['name']}.strip.png (frames {r['strip']['pick']}, {r['strip']['height']} px)"
                           if "strip" in r else f"{r['name']}.png")
                    if r.get("crops"):
                        out += f", crops {', '.join(r['crops'])}"
                    print("   ", " ".join(f"{k}={v}" for k, v in r["env"].items()), r["script"], out)
            return 0
        if a.cmd == "plan":
            print(json.dumps(plan(load_list(path), a.item), indent=1))
            return 0
        if a.cmd == "variants":
            data = load_list(path)
            items = [n for screen in (a.screens or list(data["screens"])) for n in variants(data, screen)]
            m = render(items, a.sha, a.out, path, keep=a.keep)
        else:
            m = render(a.item, a.sha, a.out, path, keep=a.keep,
                       crops=[c.strip() for c in a.crops.split(",") if c.strip()])
    except (ListError, RuntimeError, subprocess.CalledProcessError) as e:
        print(f"render.py: {e}", file=sys.stderr)
        return 2
    for st in m["stills"]:
        if "strip" in st:
            print(f"{st['name']}: strip {st['strip']} (frames {', '.join(map(str, st['shown']))})")
            continue
        crops = ""
        if "crops" in st:
            crops = f", {len(st['crops'])} crops" + (f", MISSING {', '.join(st['crops_missing'])}"
                                                       if st["crops_missing"] else "")
        print(f"{st['name']}: still {st['still']}, gray {st['gray']}, fit {st['fit']}{crops}")
    print(f"wrote {pathlib.Path(a.out) / 'stills.json'} ({'ok' if m['ok'] else 'FAIL'})")
    return 0 if m["ok"] else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
