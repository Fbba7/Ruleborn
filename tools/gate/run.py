#!/usr/bin/env python3
"""The gate's launcher and verdict writer (BT-05), on top of render.py.

For a task's gate_request {"sha", "items"} (agent-protocol.md, "The gate,
step by step"):

    run.py prepare --task <id> --request <file> --out <dir> --judge "<model>"
                   [--list <shots.json>] [--blocking]
        Render the items' stills at the request's sha from the shot list
        (render.py), then prepare one isolated judge call per sample: three
        samples per quality, each with its pictures in a new shuffled order.
        <file> is the maker's status file (its "gate_request") or the
        gate_request itself; <dir> must be outside the repository. In <dir>:
        pics/<code>.png (every picture, under a blind code), calls/<call>.md
        (the filled prompt of each call: the stills, the rubric's prompt and
        the anchors from the golden set, nothing else), calls.jsonl and
        plan.json. Exits 1, preparing no call, if a still is missing or its
        fit failed: such a still is not judged (gate/shots.md). "--judge" is
        the judge's model by its product name, as the caller runs it: the
        tool names no model of its own, and refuses Fable 5.1.
    run.py extra <dir> <results.jsonl>
        For each item and quality whose first three samples split, prepare
        samples 4 to 6 (step 4), appended to calls.jsonl and calls/.
    run.py write <dir> <results.jsonl> [--verdicts <folder>] [--attempts N]
                 [--at <time>] [--allow-split] [--replace]
        Decide each item and quality (step 4: three passes pass, three fails
        fail, a split takes three more samples and fails at 4 or more fails
        of 6; an UNKNOWN goes to the exceptions queue), write the verdict
        objects to <folder>/<task_id>/<sha>.json exactly as step 3 shows them,
        validate the file against docs/progress/schema/verdict.json, and
        report the task's attempts (step 5): each gate run with a fail adds 1.
        The attempts are reported, never written to the backlog. <folder>
        defaults to docs/art/ui-quality/gate/verdicts. The file is named by
        the sha's first 8 characters and holds the full sha.
    run.py validate [<verdict file>...]
        Validate verdict files (default: every file in the UI wave's
        verdicts folder) against the schema, and check what the schema
        cannot: the folder is the task_id, the name is the sha's prefix, and
        each result follows from its samples by step 4.
    run.py --self-test
        A stub renderer and a stub judge (no Godot, no network, no session):
        verdict files written to a temporary folder, validated, and the
        attempt count checked; then the repository's verdict files validated.

A results file is JSON lines, one per call, each the judge's final message
(the prompt's answer object) with the call's id added:
    {"call": "<call id>", "answer": "pass|fail|unknown", "region": "...", "reason": "..."}
"""
import argparse
import datetime
import hashlib
import json
import pathlib
import random
import re
import shutil
import sys
import tempfile
import zlib

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(ROOT / "tools" / "ui_gate"))

import render  # noqa: E402
import golden  # noqa: E402
import calibrate  # noqa: E402

SCHEMA = ROOT / "docs" / "progress" / "schema" / "verdict.json"
VERDICTS = ROOT / "docs" / "art" / "ui-quality" / "gate" / "verdicts"
BACKLOG = ROOT / "docs" / "progress" / "backlog.json"
PROMPTS = calibrate.PROMPTS
BY_NAME = {name: n for n, name in golden.QUALITY_NAMES.items()}
ANSWERS = ("pass", "fail", "unknown")
NEVER = re.compile(r"fable[\s_-]*5[\s._-]*1(?!\d)", re.I)  # CLAUDE.md order 2
JUDGE_RE = re.compile(r"^[A-Z][A-Za-z]+ [0-9]+(\.[0-9]+)?$")


class GateError(ValueError):
    pass


# ---------------------------------------------------------------- inputs

def check_judge(name):
    """The judge's product name, as its caller runs it; never Fable 5.1."""
    name = (name or "").strip()
    if NEVER.search(name):
        raise GateError("the judge is never Fable 5.1 (CLAUDE.md, order 2)")
    if not JUDGE_RE.match(name):
        raise GateError(f"--judge {name!r}: give the model's product name (for example the name "
                        "the session's model shows), not an API identifier")
    return name


def load_request(path):
    """(task_id or None, gate_request) from a status file or a gate_request."""
    data = json.loads(pathlib.Path(path).read_text())
    req = data.get("gate_request", data) if isinstance(data, dict) else None
    if not isinstance(req, dict) or not req.get("sha") or not req.get("items"):
        raise GateError(f"{path}: no gate_request with a sha and items")
    items = []
    for it in req["items"]:
        it = {"item": it} if isinstance(it, str) else dict(it)
        if not it.get("item"):
            raise GateError(f"{path}: an item without a name")
        items.append(it)
    return (data.get("task_id") if "gate_request" in data else None), {"sha": req["sha"], "items": items}


def qualities_of(item):
    cls = item.get("class", "screen")
    if cls not in golden.CLASSES:
        raise GateError(f"{item['item']}: unknown asset class {cls!r}")
    names = item.get("qualities") or [golden.QUALITY_NAMES[q] for q in golden.CLASSES[cls]]
    out = []
    for name in names:
        q = BY_NAME.get(name) if not isinstance(name, int) else name
        if q not in golden.QUALITY_NAMES:
            raise GateError(f"{item['item']}: unknown quality {name!r}")
        if q not in golden.CLASSES[cls]:
            raise GateError(f"{item['item']}: quality {golden.QUALITY_NAMES[q]!r} is not judged "
                            f"for the class {cls!r}")
        out.append(q)
    return cls, out


def rubric_version(q):
    text = (PROMPTS / calibrate.PROMPT_FILES[q]).read_text()
    m = re.search(r"Rubric version (\d+)", text)
    if not m:
        raise GateError(f"{calibrate.PROMPT_FILES[q]} names no rubric version")
    return int(m.group(1))


def outside_repo(out):
    out = pathlib.Path(out).resolve()
    if out == ROOT or ROOT in out.parents:
        raise GateError("the output folder must be outside the repository, so the judge "
                        "cannot find progress files or the maker's notes beside the pictures")
    return out


def code(salt, key):
    return "g" + hashlib.sha256(f"{salt}:{key}".encode()).hexdigest()[:8]


# ---------------------------------------------------------------- prepare

def candidate_pictures(manifest, item, out, salt):
    """The pictures of one item's stills: colour, grayscale and crops."""
    pics = []
    for s in manifest["stills"]:
        if s["item"] != item:
            continue
        src = out / "stills" / s["still"]
        pic = {"src": str(src), "code": code(salt, s["still"]), "role": "CANDIDATE",
               "note": s["name"], "crops": []}
        if s.get("gray"):
            pic["gray"] = {"src": str(out / "stills" / s["gray"]), "code": code(salt, s["gray"])}
        for c in s.get("crops", []):
            pic["crops"].append({"src": str(out / "stills" / c["file"]),
                                 "code": code(salt, c["file"]), "control": c["control"]})
        pics.append(pic)
    if not pics:
        raise GateError(f"{item}: the render made no still")
    return pics


def anchor_pictures(cls, q, anc, data, salt):
    out = []
    for k in ("pass", "fail"):
        i = anc.get((cls, q), {}).get(k)
        if i:
            out.append({"src": str(golden.GOLDEN / data[i]["image"]), "code": code(salt, "anchor:" + i),
                        "role": f"{k.upper()} ANCHOR", "crops": []})
    return out


def fill(call, pic_dir):
    text = (PROMPTS / calibrate.PROMPT_FILES[call["qnum"]]).read_text()
    body = text.split("\n---\n", 1)[1].lstrip("\n")
    lines = []
    for p in call["pictures"]:
        lines.append(f"- `{pic_dir}/{p['code']}.png`: {p['role']}")
        if p.get("gray"):
            lines.append(f"  - `{pic_dir}/{p['gray']['code']}.png`: the same, in grayscale at 960 px")
        for c in p.get("crops", []):
            lines.append(f"  - `{pic_dir}/{c['code']}.png`: crop at full resolution, {c['control']}")
    cand = next(p["code"] for p in call["pictures"] if p["role"] == "CANDIDATE")
    return (body.replace("{{item}}", cand).replace("{{class}}", call["class"])
            .replace("{{pictures}}", "\n".join(lines)))


def make_calls(row, samples, salt):
    calls = []
    for s in samples:
        order = [dict(p) for p in row["pictures"]]
        random.Random(f"{salt}:{row['row']}:s{s}").shuffle(order)
        calls.append({"call": f"{row['row']}-s{s}", "row": row["row"], "sample": s,
                      "qnum": row["qnum"], "class": row["class"], "pictures": order})
    return calls


def write_calls(out, calls, append=False):
    (out / "calls").mkdir(exist_ok=True)
    with open(out / "calls.jsonl", "a" if append else "w") as f:
        for c in calls:
            (out / "calls" / f"{c['call']}.md").write_text(fill(c, out / "pics"))
            f.write(json.dumps({k: v for k, v in c.items() if k != "pictures"}
                               | {"pictures": [p["code"] for p in c["pictures"]],
                                  "prompt": f"calls/{c['call']}.md"}, ensure_ascii=False) + "\n")


def prepare(task_id, request, out, judge, list_path=None, advisory=True, renderer=None):
    judge = check_judge(judge)
    out = outside_repo(out)
    if (out / "plan.json").exists():
        raise GateError(f"{out} already holds a plan: use a new folder per gate run")
    out.mkdir(parents=True, exist_ok=True)
    items = request["items"]
    rows_in = [(it, *qualities_of(it)) for it in items]
    renderer = renderer or (lambda names, sha, d: render.render(names, sha, d, list_path=list_path))
    manifest = renderer([it["item"] for it in items], request["sha"], out / "stills")
    if not manifest.get("ok"):
        bad = [s["name"] for s in manifest.get("stills", []) if s.get("exit") or s.get("fit") not in ("ok", "n/a")]
        raise GateError(f"a still is missing or its fit failed ({', '.join(bad) or 'see render.log'}): "
                        "it is not judged, and no call is prepared")
    sha = manifest["sha"]
    salt = f"{task_id}:{sha}"
    data = golden.load()
    anc = calibrate.anchors(data, calibrate.labelled(data))
    by_id = golden.by_id(data)
    (out / "pics").mkdir(exist_ok=True)
    rows, calls = [], []
    for n, (it, cls, qs) in enumerate(rows_in, 1):
        cand = candidate_pictures(manifest, it["item"], out, salt)
        for q in qs:
            pics = cand + anchor_pictures(cls, q, anc, by_id, salt)
            row = {"row": f"i{n}-q{q}", "item": it["item"], "class": cls, "qnum": q,
                   "quality": golden.QUALITY_NAMES[q], "rubric_version": rubric_version(q),
                   "pictures": [{k: v for k, v in p.items() if k not in ("src", "note")}
                                | ({"gray": {"code": p["gray"]["code"]}} if p.get("gray") else {})
                                | {"crops": [{"code": c["code"], "control": c["control"]} for c in p["crops"]]}
                                for p in pics]}
            for p in pics:
                for pic in [p] + ([p["gray"]] if p.get("gray") else []) + p["crops"]:
                    dst = out / "pics" / f"{pic['code']}.png"
                    if not dst.exists():
                        shutil.copyfile(pic["src"], dst)
            rows.append(row)
            calls += make_calls(row, (1, 2, 3), salt)
    plan = {"task_id": task_id, "sha": sha, "judge": judge, "advisory": advisory,
            "items": [it["item"] for it in items], "list": manifest.get("list"),
            "list_sha256": manifest.get("list_sha256"), "rows": rows}
    (out / "plan.json").write_text(json.dumps(plan, indent=1, ensure_ascii=False) + "\n")
    write_calls(out, calls)
    return plan, calls


# ---------------------------------------------------------------- results

def read_results(path, calls):
    known = {c["call"] for c in calls}
    got = {}
    for n, line in enumerate(pathlib.Path(path).read_text().splitlines(), 1):
        if not line.strip():
            continue
        r = json.loads(line)
        if r.get("call") not in known:
            raise GateError(f"{path}:{n}: unknown call {r.get('call')!r}")
        a = str(r.get("answer", "")).strip().lower()
        if a not in ANSWERS:
            raise GateError(f"{path}:{n}: answer {r.get('answer')!r} is not pass, fail or unknown")
        if r["call"] in got:
            raise GateError(f"{path}:{n}: a second answer for {r['call']}")
        got[r["call"]] = {**r, "answer": a}
    return got


def load_dir(d):
    d = pathlib.Path(d)
    plan = json.loads((d / "plan.json").read_text())
    calls = calibrate.read_jsonl(d / "calls.jsonl")
    return d.resolve(), plan, calls


def samples_of(row, calls, got):
    mine = sorted((c for c in calls if c["row"] == row["row"]), key=lambda c: c["sample"])
    return [(c, got.get(c["call"])) for c in mine]


def extra(d, results):
    d, plan, calls = load_dir(d)
    got = read_results(results, calls)
    salt = f"{plan['task_id']}:{plan['sha']}"
    new = []
    for row in plan["rows"]:
        ans = [g["answer"] for c, g in samples_of(row, calls, got) if g]
        if calibrate.decide(ans) == "split" and len(ans) == 3 and \
                not any(c["row"] == row["row"] and c["sample"] > 3 for c in calls):
            new += make_calls(row, (4, 5, 6), salt)
    write_calls(d, new, append=True)
    return new


def critique(result, answered):
    seen, parts = set(), []
    for c, g in answered:
        if g["answer"] != result:
            continue
        text = ": ".join(x for x in (str(g.get("region") or "").strip(), str(g.get("reason") or "").strip()) if x)
        if text and text not in seen:
            seen.add(text)
            parts.append(text)
    return "; ".join(parts[:3]) or f"{result}, with no reason given"


def verdicts(plan, calls, got, at, allow_split=False):
    objs, missing = [], []
    for row in plan["rows"]:
        answered = [(c, g) for c, g in samples_of(row, calls, got)]
        missing += [c["call"] for c, g in answered if g is None]
        answered = [(c, g) for c, g in answered if g]
        ans = [g["answer"] for c, g in answered]
        result = calibrate.decide(ans)
        if result == "incomplete":
            continue
        if result == "split" and not allow_split:
            raise GateError(f"{row['row']} ({row['item']}, {row['quality']}) split: run 'extra' and "
                            "judge samples 4 to 6 first (step 4)")
        objs.append({"task_id": plan["task_id"], "sha": plan["sha"], "rubric_version": row["rubric_version"],
                     "judge": plan["judge"], "advisory": plan["advisory"], "at": at,
                     "item": row["item"], "quality": row["quality"], "samples": ans,
                     "result": result, "critique": critique(result, answered)})
    if missing:
        raise GateError(f"no answer for {len(missing)} call(s): {', '.join(missing[:5])}")
    return objs


def attempts_now(task_id):
    try:
        tasks = json.loads(BACKLOG.read_text())["tasks"]
    except (OSError, ValueError, KeyError):
        return 0
    t = next((t for t in tasks if t.get("id") == task_id), None)
    return int((t or {}).get("attempts") or 0)


def report(objs, before):
    fails = [o for o in objs if o["result"] == "fail"]
    unknown = [o for o in objs if o["result"] == "unknown"]
    return {"task_id": objs[0]["task_id"] if objs else None, "sha": objs[0]["sha"] if objs else None,
            "checks": len(objs), "pass": sum(o["result"] == "pass" for o in objs),
            "fail": len(fails), "unknown": len(unknown),
            "failed": [f"{o['item']}: {o['quality']}" for o in fails],
            "exceptions_queue": [f"{o['item']}: {o['quality']}" for o in unknown],
            "attempts_before": before, "attempts_after": before + (1 if fails else 0)}


def write(d, results, folder=VERDICTS, attempts=None, at=None, allow_split=False, replace=False):
    d, plan, calls = load_dir(d)
    got = read_results(results, calls)
    at = at or datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    objs = verdicts(plan, calls, got, at, allow_split)
    if not objs:
        raise GateError("no item and quality has its three samples yet")
    errs = validate_objects(objs)
    if errs:
        raise GateError("the verdicts fail the schema: " + "; ".join(errs))
    path = pathlib.Path(folder) / plan["task_id"] / f"{plan['sha'][:8]}.json"
    if path.exists() and not replace:
        raise GateError(f"{path} exists: one file per gate run (use --replace to rewrite it)")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(objs, indent=1, ensure_ascii=False) + "\n")
    before = attempts_now(plan["task_id"]) if attempts is None else attempts
    return path, report(objs, before)


# ---------------------------------------------------------------- the schema

def _check(inst, s, root, where, errs):
    """The JSON Schema keywords verdict.json uses (no other dependency)."""
    if "$ref" in s:
        ref = s["$ref"]
        node = root
        for part in ref.lstrip("#/").split("/"):
            node = node[part]
        _check(inst, node, root, where, errs)
    t = s.get("type")
    kinds = {"array": list, "object": dict, "string": str, "boolean": bool}
    if t == "integer" and (not isinstance(inst, int) or isinstance(inst, bool)):
        errs.append(f"{where}: not an integer")
        return
    if t in kinds and not isinstance(inst, kinds[t]):
        errs.append(f"{where}: not a{'n' if t[0] in 'ao' else ''} {t}")
        return
    if "enum" in s and inst not in s["enum"]:
        errs.append(f"{where}: {inst!r} is not one of {s['enum']}")
    if "const" in s and inst != s["const"]:
        errs.append(f"{where}: {inst!r} is not {s['const']!r}")
    if isinstance(inst, str):
        if len(inst) < s.get("minLength", 0):
            errs.append(f"{where}: empty")
        if "pattern" in s and not re.search(s["pattern"], inst):
            errs.append(f"{where}: {inst!r} does not match {s['pattern']}")
    if isinstance(inst, int) and not isinstance(inst, bool) and inst < s.get("minimum", inst):
        errs.append(f"{where}: below {s['minimum']}")
    if isinstance(inst, list):
        if len(inst) < s.get("minItems", 0) or len(inst) > s.get("maxItems", len(inst)):
            errs.append(f"{where}: {len(inst)} entries")
        if "items" in s:
            for i, x in enumerate(inst):
                _check(x, s["items"], root, f"{where}[{i}]", errs)
        if "contains" in s and not any(not _errs(x, s["contains"], root) for x in inst):
            errs.append(f"{where}: contains no match")
    if isinstance(inst, dict):
        for k in s.get("required", []):
            if k not in inst:
                errs.append(f"{where}: no {k!r}")
        props = s.get("properties", {})
        for k, v in inst.items():
            if k in props:
                _check(v, props[k], root, f"{where}.{k}", errs)
            elif s.get("additionalProperties") is False:
                errs.append(f"{where}: unexpected key {k!r}")
    if "not" in s and not _errs(inst, s["not"], root):
        errs.append(f"{where}: matches what is not allowed ({s['not']})")
    for sub in s.get("allOf", []):
        if "if" in sub:
            if not _errs(inst, sub["if"], root) and "then" in sub:
                _check(inst, sub["then"], root, where, errs)
        else:
            _check(inst, sub, root, where, errs)


def _errs(inst, s, root):
    e = []
    _check(inst, s, root, "", e)
    return e


def schema():
    return json.loads(SCHEMA.read_text())


def validate_objects(objs, where="verdicts"):
    s = schema()
    errs = []
    _check(objs, s, s, where, errs)
    try:
        import jsonschema  # cross-check where it is installed
    except ImportError:
        jsonschema = None
    if jsonschema is not None:
        theirs = [f"{where}{''.join(f'[{p}]' if isinstance(p, int) else f'.{p}' for p in e.absolute_path)}: {e.message}"
                  for e in jsonschema.Draft202012Validator(s).iter_errors(objs)]
        if bool(theirs) != bool(errs):
            errs.append("the schema check and jsonschema disagree: " + "; ".join(theirs or ["jsonschema finds nothing"]))
    return errs


def validate_file(path):
    path = pathlib.Path(path)
    try:
        objs = json.loads(path.read_text())
    except ValueError as e:
        return [f"{path}: not JSON ({e})"]
    errs = validate_objects(objs, str(path.name))
    if errs or not isinstance(objs, list):
        return errs or [f"{path}: not a list"]
    for i, o in enumerate(objs):
        w = f"{path.name}[{i}]"
        if o["task_id"] != path.parent.name:
            errs.append(f"{w}: task_id {o['task_id']} is not the folder {path.parent.name}")
        n = min(len(o["sha"]), len(path.stem))
        if o["sha"][:n] != path.stem[:n]:
            errs.append(f"{w}: sha {o['sha']} does not match the file name")
        want = calibrate.decide(o["samples"])
        if want != o["result"]:
            errs.append(f"{w}: samples {o['samples']} decide {want}, not {o['result']}")
    return errs


def validate(paths=None):
    paths = [pathlib.Path(p) for p in paths] if paths else sorted(VERDICTS.glob("*/*.json"))
    bad = {}
    for p in paths:
        e = validate_file(p)
        if e:
            bad[str(p)] = e
    return paths, bad


# ---------------------------------------------------------------- self-test

def _png(path, w=4, h=4, rgb=(128, 64, 32)):
    raw = b"".join(b"\0" + bytes(rgb) * w for _ in range(h))

    def chunk(t, b):
        return len(b).to_bytes(4, "big") + t + b + zlib.crc32(t + b).to_bytes(4, "big")
    path.write_bytes(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", w.to_bytes(4, "big") + h.to_bytes(4, "big")
                     + bytes([8, 2, 0, 0, 0])) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


def stub_renderer(ok=True):
    def run(names, sha, out):
        out.mkdir(parents=True, exist_ok=True)
        stills = []
        for n, name in enumerate(names):
            s = f"shot{n}"
            _png(out / f"{s}.png")
            _png(out / f"{s}.gray.png", rgb=(90, 90, 90))
            rec = {"item": name, "name": s, "still": f"{s}.png", "gray": f"{s}.gray.png",
                   "fit": "ok" if ok or n else "failed", "exit": 0}
            if n == 0:
                (out / f"{s}.crops").mkdir(exist_ok=True)
                _png(out / f"{s}.crops" / "back.png")
                rec["crops"] = [{"crop": "back", "control": "back:Back", "file": f"{s}.crops/back.png"}]
            stills.append(rec)
        return {"items": names, "sha": sha.ljust(40, "0"), "list": "stub", "list_sha256": "0" * 64,
                "ok": ok, "stills": stills}
    return run


def stub_judge(script):
    """Answers per row: script[row] is the six answers its samples give."""
    def judge(call):
        a = script[call["row"]][call["sample"] - 1]
        return {"call": call["call"], "quality": golden.QUALITY_NAMES[call["qnum"]], "item": "stub",
                "answer": a, "region": f"region {call['row']}", "reason": f"stub {a}"}
    return judge


def _answer(d, judge, done=()):
    calls = calibrate.read_jsonl(d / "calls.jsonl")
    res = d / "results.jsonl"
    with open(res, "a") as f:
        for c in calls:
            if c["call"] not in done:
                f.write(json.dumps(judge(c)) + "\n")
    return res, calls


def self_test():
    fails = []

    def ok(cond, what):
        print(("ok   " if cond else "FAIL ") + what)
        if not cond:
            fails.append(what)

    def raises(fn, what):
        try:
            fn()
        except GateError:
            ok(True, what)
        else:
            ok(False, what)

    for bad in ("Fable 5.1", "fable-5-1", "Fable 5.1 (judge)", "claude-opus-5-5"):
        raises(lambda b=bad: check_judge(b), f"the judge {bad!r} is refused")
    ok(check_judge("Opus 5.5") == "Opus 5.5" and check_judge("Fable 5.2") == "Fable 5.2",
       "a product name other than Fable 5.1 is taken as given")
    ok(calibrate.decide(["pass", "fail", "pass", "fail", "fail", "pass"]) == "pass"
       and calibrate.decide(["fail", "pass", "fail", "fail", "pass", "fail"]) == "fail",
       "a split resolves at 4 fails of 6")

    with tempfile.TemporaryDirectory() as tmp:
        tmp = pathlib.Path(tmp)
        req = {"task_id": "P9-T1-stub", "gate_request": {"sha": "abcdef12", "items": [
            {"item": "home at 100% text", "qualities": ["Hierarchy", "Display type", "Colour roles and value"]},
            {"item": "result in high contrast", "qualities": ["Hierarchy", "Light behind UI"]}]}}
        (tmp / "status.json").write_text(json.dumps(req))
        task, request = load_request(tmp / "status.json")
        ok(task == "P9-T1-stub" and len(request["items"]) == 2, "a status file's gate_request is read")
        raises(lambda: prepare(task, request, ROOT / "x-gate", "Opus 5.5", renderer=stub_renderer()),
               "an output folder inside the repository is refused")
        raises(lambda: prepare(task, request, tmp / "bad", "Opus 5.5", renderer=stub_renderer(ok=False)),
               "a missing still or failed fit prepares no call")
        ok(not (tmp / "bad" / "calls.jsonl").exists(), "nothing is judged after a failed render")
        raises(lambda: prepare(task, {"sha": "abcdef12", "items": [{"item": "x", "class": "icon",
                                                                    "qualities": ["Hierarchy"]}]},
                               tmp / "cls", "Opus 5.5", renderer=stub_renderer()),
               "a quality the item's class does not judge is refused")

        d = tmp / "run1"
        plan, _ = prepare(task, request, d, "Opus 5.5", renderer=stub_renderer())
        calls = calibrate.read_jsonl(d / "calls.jsonl")
        ok(len(plan["rows"]) == 5 and len(calls) == 15, "three samples per item and quality")
        ok(plan["sha"] == "abcdef12".ljust(40, "0") and plan["judge"] == "Opus 5.5",
           "the plan holds the rendered sha and the caller's judge")
        orders = {}
        for c in calls:
            orders.setdefault(c["row"], set()).add(tuple(c["pictures"]))
        ok(any(len(v) > 1 for v in orders.values()), "the pictures are shuffled from sample to sample")
        prepare(task, request, tmp / "run1b", "Opus 5.5", renderer=stub_renderer())
        again = calibrate.read_jsonl(tmp / "run1b" / "calls.jsonl")
        ok([c["pictures"] for c in again] == [c["pictures"] for c in calls], "the shuffle is the same on every run")
        texts = [(d / "calls" / f"{c['call']}.md").read_text() for c in calls]
        ok(all("{{" not in t for t in texts), "every prompt is filled")
        ok(all("docs/progress" not in t and "handoff" not in t.lower() and "home at 100%" not in t for t in texts),
           "a prompt names no progress file, no note and not the item's name")
        ok(all(t.count("CANDIDATE\n") + t.count(": CANDIDATE") >= 1 and "PASS ANCHOR" in t for t in texts),
           "each prompt has the candidate and its anchors")
        ok("crop at full resolution, back:Back" in texts[0] and "grayscale at 960 px" in texts[0],
           "the crops and the grayscale go with the candidate")
        pics = {p.name for p in (d / "pics").iterdir()}
        ok(all(f"{c}.png" in pics for call in calls for c in call["pictures"]), "every picture is copied")
        ok(all(re.fullmatch(r"g[0-9a-f]{8}\.png", p) for p in pics), "the pictures carry blind codes only")

        rows = [r["row"] for r in plan["rows"]]
        script = {rows[0]: ["pass"] * 6,
                  rows[1]: ["fail"] * 6,
                  rows[2]: ["pass", "fail", "pass", "pass", "fail", "pass"],
                  rows[3]: ["fail", "fail", "pass", "fail", "pass", "fail"],
                  rows[4]: ["pass", "unknown", "pass", "pass", "pass", "pass"]}
        res, calls = _answer(d, stub_judge(script))
        raises(lambda: write(d, res, tmp / "verdicts", attempts=1), "a split is not written before samples 4 to 6")
        new = extra(d, res)
        ok(len(new) == 6 and {c["row"] for c in new} == {rows[2], rows[3]}, "a split takes three more samples")
        ok(extra(d, res) == [], "the extra samples are prepared once")
        res, calls = _answer(d, stub_judge(script), done={c["call"] for c in calls})
        path, rep = write(d, res, tmp / "verdicts", attempts=1, at="2026-11-25T01:02:03Z")
        ok(path == tmp / "verdicts" / "P9-T1-stub" / "abcdef12.json", "the file is <verdicts>/<task_id>/<sha>.json")
        objs = json.loads(path.read_text())
        ok([o["result"] for o in objs] == ["pass", "fail", "pass", "fail", "unknown"],
           "three passes pass, three fails fail, 4 fails of 6 fail, an UNKNOWN is unknown")
        ok([len(o["samples"]) for o in objs] == [3, 3, 6, 6, 3], "the samples are written as made")
        ok(all(list(o) == ["task_id", "sha", "rubric_version", "judge", "advisory", "at", "item", "quality",
                           "samples", "result", "critique"] for o in objs), "each object has step 3's keys")
        ok(objs[1]["critique"] == f"region {rows[1]}: stub fail", "the critique comes from the samples that decided")
        ok(validate_file(path) == [], "the written file validates")
        ok(rep["fail"] == 2 and rep["attempts_before"] == 1 and rep["attempts_after"] == 2,
           "a run with fails adds 1 to the attempts")
        ok(rep["exceptions_queue"] == ["result in high contrast: Light behind UI"], "an UNKNOWN goes to the exceptions queue")
        raises(lambda: write(d, res, tmp / "verdicts", attempts=1), "a verdict file is not overwritten")

        d2 = tmp / "run2"
        request2 = {"sha": "1234567", "items": [{"item": "home at 100% text", "qualities": ["Hierarchy"]}]}
        prepare(task, request2, d2, "Fable 5.2", advisory=False, renderer=stub_renderer())
        res2, _ = _answer(d2, stub_judge({"i1-q6": ["pass"] * 6}))
        path2, rep2 = write(d2, res2, tmp / "verdicts", attempts=2)
        ok(rep2["fail"] == 0 and rep2["attempts_after"] == 2, "an all-pass run adds nothing to the attempts")
        ok(json.loads(path2.read_text())[0]["advisory"] is False, "--blocking writes advisory false")

        broken = tmp / "verdicts" / "P9-T1-stub" / "deadbeef.json"
        for change, what in ((lambda o: o.update(judge="Fable 5.1"), "a Fable 5.1 judge"),
                             (lambda o: o.update(result="pass"), "a result the samples do not decide"),
                             (lambda o: o.update(samples=["pass"] * 4), "four samples"),
                             (lambda o: o.update(extra=1), "an unknown key"),
                             (lambda o: o.pop("critique"), "a missing critique"),
                             (lambda o: o.update(sha="abcdef12"), "a sha that is not the file's"),
                             (lambda o: o.update(quality="Sparkle"), "an unknown quality")):
            o = dict(objs[1], sha="deadbeef" + "0" * 32)
            change(o)
            broken.write_text(json.dumps([o]))
            ok(validate_file(broken) != [], f"the check catches {what}")
        broken.unlink()

    paths, bad = validate()
    ok(len(paths) > 0 and not bad, f"the repository's {len(paths)} verdict files validate"
       + ("" if not bad else ": " + "; ".join(f"{p}: {e[0]}" for p, e in bad.items())))
    print("self-test:", "FAILED " + str(len(fails)) if fails else "passed")
    return 1 if fails else 0


# ---------------------------------------------------------------- main

def main(argv):
    if argv == ["--self-test"]:
        return self_test()
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = ap.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("prepare")
    p.add_argument("--task")
    p.add_argument("--request", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--judge", required=True)
    p.add_argument("--list")
    p.add_argument("--blocking", action="store_true", help="the qualities are calibrated: advisory false")
    p = sub.add_parser("extra")
    p.add_argument("dir")
    p.add_argument("results")
    p = sub.add_parser("write")
    p.add_argument("dir")
    p.add_argument("results")
    p.add_argument("--verdicts", default=str(VERDICTS))
    p.add_argument("--attempts", type=int)
    p.add_argument("--at")
    p.add_argument("--allow-split", action="store_true")
    p.add_argument("--replace", action="store_true")
    p = sub.add_parser("validate")
    p.add_argument("files", nargs="*")
    a = ap.parse_args(argv)
    try:
        if a.cmd == "prepare":
            task, req = load_request(a.request)
            task = a.task or task
            if not task:
                raise GateError("--task: the request names no task")
            plan, calls = prepare(task, req, a.out, a.judge, a.list, advisory=not a.blocking)
            print(f"{len(calls)} calls for {len(plan['rows'])} checks at {plan['sha'][:8]} in {a.out}")
        elif a.cmd == "extra":
            print(f"{len(extra(a.dir, a.results))} extra calls")
        elif a.cmd == "write":
            path, rep = write(a.dir, a.results, a.verdicts, a.attempts, a.at, a.allow_split, a.replace)
            print(json.dumps({"file": str(path), **rep}, indent=1, ensure_ascii=False))
        else:
            paths, bad = validate(a.files)
            for p, errs in bad.items():
                for e in errs:
                    print(f"{p}: {e}")
            print(f"{len(paths) - len(bad)} of {len(paths)} verdict files valid")
            return 1 if bad else 0
    except (GateError, RuntimeError, render.ListError) as e:
        print(f"run.py: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
