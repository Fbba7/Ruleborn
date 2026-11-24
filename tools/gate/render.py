#!/usr/bin/env python3
"""The gate's stills, rendered from the shot list at a given commit (BT-04a).

    render.py still "<item>" --sha <sha> --out <dir> [--list <shots.json>]
        Export <sha>'s tree (git archive) into a temporary folder, build what
        the client needs there, and render each still of <item> the way the
        lead does by hand: FIT=1 <the item's settings> bash
        tools/render/shoot.sh <script> <png>, run from that folder. Beside each still goes its grayscale at
        960 px on the long edge (tools/ui_gate/sheet.py still --gray), and in
        <dir> a stills.json naming the sha, the list, each still's settings
        and whether its run printed "fit ok". Exits 1 if a still is missing
        or its fit failed: such a still is not judged (gate/shots.md).
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
- Every run adds FIT=1. A still is named <screen>_<state>_<setting>.png,
  for example result_srv_200_pt_BR.png, and its grayscale
  result_srv_200_pt_BR.gray.png.

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
    for it in data.get("items", []):
        if it.get("screen") not in screens:
            raise ListError(f"{path}: item {it.get('item')!r}: unknown screen {it.get('screen')!r}")
        _check_env(path, it.get("env", {}))
    return data


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


def plan(data, item):
    """The runs an item makes: [{"name", "script", "env"}]."""
    screens = data["screens"]
    explicit = [it for it in data.get("items", []) if it["item"] == item]
    if explicit:
        screen = explicit[0]["screen"]
        setting = dict(explicit[0].get("env", {}))
    else:
        m = TEXT_RE.match(item)
        c = CONTRAST_RE.match(item)
        if m and m["screen"] in screens:
            screen = m["screen"]
            setting = {} if m["n"] == "100" and not m["locale"] else {"TEXT": m["n"]}
            if m["locale"]:
                setting["LOCALE"] = m["locale"]
        elif c and c["screen"] in screens:
            screen = c["screen"]
            setting = {screens[screen]["contrast"]: "1"}
        else:
            raise ListError(f"no item {item!r} in the list, and it does not read as "
                            f"'<screen> at <n>% text[, <locale>]' or '<screen> in high contrast' "
                            f"for a listed screen ({', '.join(sorted(screens))})")
    s = screens[screen]
    states = s.get("states", [{"name": "main", "env": {}}])
    runs = []
    for st in states:
        env = {**st.get("env", {}), **setting}
        name = screen if len(states) == 1 else f"{screen}_{st['name']}"
        runs.append({"name": f"{name}_{_slug(setting)}", "script": s["script"],
                     "env": {"FIT": "1", **env}})
    return runs


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


def render(item, sha, out, list_path=None, keep=False):
    list_path = pathlib.Path(list_path or default_list()).resolve()
    data = load_list(list_path)
    runs = plan(data, item)
    why = godot_can_run()
    if why:
        raise RuntimeError(f"cannot render: {why}")
    full = git("rev-parse", "--verify", f"{sha}^{{commit}}")
    out = pathlib.Path(out).resolve()
    out.mkdir(parents=True, exist_ok=True)
    wt = pathlib.Path(tempfile.mkdtemp(prefix=f"gate-{full[:8]}-", dir=cache_dir()))
    stills, ok = [], True
    with open(out / "render.log", "w") as log:
        try:
            export(full, wt)
            key = build(wt, full, log)
            for run in runs:
                if not (wt / run["script"]).is_file():
                    raise RuntimeError(f"{run['script']} does not exist at {full[:8]}")
                png = out / f"{run['name']}.png"
                grey = out / f"{run['name']}.gray.png"
                for p in (png, grey):
                    p.unlink(missing_ok=True)
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
                if png.is_file() and png.stat().st_size:
                    subprocess.run([sys.executable, str(ROOT / "tools" / "ui_gate" / "sheet.py"), "still",
                                    str(png), str(grey), "--long", "960", "--gray"], check=True,
                                   capture_output=True)
                    rec["gray"] = grey.name
                else:
                    rec["still"] = None
                if rec["still"] is None or fit != "ok":
                    ok = False
                stills.append(rec)
        finally:
            if keep:
                print(f"render.py: kept the tree at {wt}", file=sys.stderr)
            else:
                shutil.rmtree(wt, ignore_errors=True)
    manifest = {"item": item, "sha": full, "list": str(list_path.relative_to(ROOT)) if list_path.is_relative_to(ROOT) else str(list_path),
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
    expect(r[0]["env"] == {"FIT": "1", "HC": "1"}, f"character reads HC: {r}")
    r = plan(data, "home at 100% text")
    expect(r == [{"name": "home_100", "script": "client/tests/shots/universe_home.gd", "env": {"FIT": "1"}}],
           f"home at 100%: {r}")
    r = plan(data, "heist at 200% text")
    expect(r[0]["env"] == {"FIT": "1", "TEXT": "200"} and r[0]["name"] == "heist_200", f"no locale: {r}")
    for bad in ("vault at 100% text", "heist at 200% text, pt_BR, no crew plan", "heist at big text"):
        try:
            plan(data, bad)
            expect(False, f"{bad!r} should be refused")
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
                              "states": [{"name": "x", "env": {"SHOT": "/tmp/x"}}]}}}, "SHOT")):
            p = pathlib.Path(d) / "l.json"
            p.write_text(json.dumps(broken))
            try:
                load_list(p)
                expect(False, f"a list with a bad {why} should be refused")
            except ListError:
                pass
    print(f"render.py: the shot list's parser, {'FAIL' if failures else 'ok'}")

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
    with tempfile.TemporaryDirectory() as d:
        m = render("settings at 200% text, pt_BR", sha, d, TEST_LIST)
        s = m["stills"][0]
        expect(m["sha"] == sha and len(m["stills"]) == 1, f"manifest: {m}")
        expect(s["env"] == {"FIT": "1", "TEXT": "200", "LOCALE": "pt_BR"}, f"run env: {s}")
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
        else:
            expect(False, f"no still: {s}")
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
                names += [f"{screen} at 100% text", f"{screen} at 200% text, pt_BR", f"{screen} in high contrast"]
            for n in names:
                print(n)
                for r in plan(data, n):
                    print("   ", " ".join(f"{k}={v}" for k, v in r["env"].items()), r["script"], f"{r['name']}.png")
            return 0
        if a.cmd == "plan":
            print(json.dumps(plan(load_list(path), a.item), indent=1))
            return 0
        m = render(a.item, a.sha, a.out, path, keep=a.keep)
    except (ListError, RuntimeError, subprocess.CalledProcessError) as e:
        print(f"render.py: {e}", file=sys.stderr)
        return 2
    for st in m["stills"]:
        print(f"{st['name']}: still {st['still']}, gray {st['gray']}, fit {st['fit']}")
    print(f"wrote {pathlib.Path(a.out) / 'stills.json'} ({'ok' if m['ok'] else 'FAIL'})")
    return 0 if m["ok"] else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
