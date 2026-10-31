#!/usr/bin/env python3
"""Calibrating the gate's judge on the golden set (section 3.5 of
docs/art/ui-quality/report.md, "Calibration"; gate/calibration.md).

    calibrate.py split
        The thirds as golden.py split dealt them (items.json's "third"): per
        third, the items by class, and per judged quality the labels AD gave
        at O3 (labels.md). Third 1 trains (the anchors come from it), third 2
        tunes, third 3 is held out.
    calibrate.py anchors
        The PASS and FAIL ANCHOR chosen for each asset class and quality, from
        the training third only.
    calibrate.py plan --third N --model NAME --run RUN [--samples 3]
        Writes gate/calibration/runs/RUN/plan.jsonl: one line per judge call
        (item, quality, sample) for every labelled row of third N, with its
        anchors, its shuffled picture order and the blind code that stands
        for each picture. The judge never sees an item's id, only its code.
    calibrate.py extra --run RUN RESULTS
        Appends samples 4-6 to the run's plan for every row whose first three
        samples split (the D-06 rule).
    calibrate.py render --run RUN --out DIR
        For the launcher: DIR/<code>.png for every picture and
        DIR/calls/<call>.md, each call's prompt filled in from gate/prompts/,
        with the pictures' paths in DIR. DIR must be outside the repository.
    calibrate.py score --run RUN RESULTS [--markdown]
        Joins the judge's answers (RESULTS: one JSON object per line,
        {"call", "answer", "region", "reason"}) with the plan and labels.md,
        applies the sampling rule, and prints per quality the catch rate, the
        false-block rate and the share sent to exceptions, as counts, against
        the target (catch >= 80%, false blocks <= 20%, exceptions <= 30%).
    calibrate.py audit VERDICTS... [--seed S] [--passes 15] [--fails 4]
        The blind audit's sample (O6): from verdict files, 10-20 items the
        gate passed, spread over the classes, mixed with 3-5 it failed, in a
        shuffled order, as the golden set's form without the verdicts.
    calibrate.py --self-test
        The tests: the sampling rule, the rates, the target, the anchors
        drawn only from training, the blind codes, the audit's draw.
"""
import argparse
import hashlib
import json
import pathlib
import random
import shutil
import sys
from collections import Counter, defaultdict

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import golden  # noqa: E402

ROOT = golden.ROOT
GATE = ROOT / "docs/art/ui-quality/gate"
PROMPTS = GATE / "prompts"
RUNS = GATE / "calibration/runs"
TRAIN, DEV, HELD_OUT = 1, 2, golden.HELD_OUT
TARGET = {"catch": 0.80, "false_block": 0.20, "exceptions": 0.30}
PROMPT_FILES = {
    1: "01-layered-materials.md", 2: "02-display-type.md", 3: "03-icons.md",
    6: "06-hierarchy.md", 8: "08-colour-value.md", 9: "09-character.md",
    13: "13-light.md", 14: "14-one-idea.md",
}


# ---------------------------------------------------------------- inputs

def labelled(data=None, text=None):
    """{(item id, quality): (label, critique)} from labels.md."""
    text = golden.LABELS.read_text() if text is None else text
    return {(i, q): (lab, crit) for i, q, lab, crit in golden.read_labels(text)}


def code(item_id, salt):
    """The blind name a picture goes by in one run."""
    return "g" + hashlib.sha256(f"{salt}:{item_id}".encode()).hexdigest()[:8]


# ---------------------------------------------------------------- the split

def split_table(data, labels):
    out = ["| Third | Use | Items | Screens | Kit art | Icons | Expected fails | Borderline | Plants |",
           "|---|---|---:|---:|---:|---:|---:|---:|---:|"]
    use = {TRAIN: "training: the anchors, and AD reads it to write the prompts",
           DEV: "development: both models run here; prompts are tuned here",
           HELD_OUT: "held out: measured once per rubric version"}
    for t in (TRAIN, DEV, HELD_OUT):
        its = [it for it in data["items"] if it.get("third") == t]
        c = Counter(it["class"] for it in its)
        out.append(f"| {t} | {use[t]} | {len(its)} | {c['screen']} | {c['kit art']} | {c['icon']} | "
                   f"{sum(it['expected'] == 'fail' for it in its)} | "
                   f"{sum(bool(it['borderline']) for it in its)} | "
                   f"{sum(it['origin'] == 'planted' for it in its)} |")
    out += ["", "AD's labels at O3 (labels.md), per quality and third, as fails / passes:", "",
            "| Quality | Third 1 | Third 2 | Third 3 |", "|---|---|---|---|"]
    third = {it["id"]: it.get("third") for it in data["items"]}
    for q, name in golden.QUALITY_NAMES.items():
        cells = []
        for t in (TRAIN, DEV, HELD_OUT):
            labs = [lab for (i, qq), (lab, _) in labels.items() if qq == q and third.get(i) == t]
            cells.append(f"{labs.count('fail')} / {labs.count('pass')}")
        out.append(f"| {q}. {name} | " + " | ".join(cells) + " |")
    return "\n".join(out)


# ---------------------------------------------------------------- anchors

def anchors(data, labels):
    """{(class, quality): {"pass": id, "fail": id}} from the training third.

    The PASS ANCHOR is the weakest item labelled pass: a borderline natural
    item first, then a borderline plant, then any pass. The FAIL ANCHOR is the
    strongest item labelled fail: a borderline natural item first, then a
    plant (built one quality away from a pass), then any fail. Ties go to the
    first in items.json, so the choice is the same on every run.
    """
    out = {}
    train = [it for it in data["items"] if it.get("third") == TRAIN]
    for cls, qs in golden.CLASSES.items():
        for q in qs:
            pick = {}
            for want, rank in (("pass", lambda it: (not it["borderline"], it["origin"] != "natural")),
                               ("fail", lambda it: (not it["borderline"] or it["origin"] != "natural",
                                                    it["origin"] != "planted"))):
                pool = [it for it in train if it["class"] == cls
                        and labels.get((it["id"], q), ("",))[0] == want]
                if pool:
                    pick[want] = min(enumerate(pool), key=lambda p: (rank(p[1]), p[0]))[1]["id"]
            out[(cls, q)] = pick
    return out


# ---------------------------------------------------------------- the plan

def plan(data, labels, third, model, run, samples=3, start=1):
    assert third != TRAIN, "the training third holds the anchors; it is not measured"
    anc = anchors(data, labels)
    rng = random.Random(f"{run}:{start}")
    calls = []
    for it in data["items"]:
        if it.get("third") != third:
            continue
        for q in it["qualities"]:
            lab = labels.get((it["id"], q), ("",))[0]
            if lab not in ("pass", "fail"):
                continue  # n/a and unlabelled rows are not measured
            a = anc[(it["class"], q)]
            pics = [(it["id"], "CANDIDATE")]
            pics += [(a[k], f"{k.upper()} ANCHOR") for k in ("pass", "fail") if k in a]
            for s in range(start, start + samples):
                order = pics[:]
                rng.shuffle(order)
                calls.append({
                    "call": f"{run}-{it['id']}-q{q}-s{s}", "run": run, "model": model,
                    "third": third, "item": it["id"], "class": it["class"], "quality": q,
                    "sample": s, "label": lab,
                    "pictures": [{"id": i, "code": code(i, run), "role": r} for i, r in order],
                })
    return calls


def write_plan(calls, run, append=False):
    d = RUNS / run
    d.mkdir(parents=True, exist_ok=True)
    with open(d / "plan.jsonl", "a" if append else "w") as f:
        for c in calls:
            f.write(json.dumps(c, ensure_ascii=False) + "\n")
    return d / "plan.jsonl"


def read_jsonl(path):
    return [json.loads(line) for line in pathlib.Path(path).read_text().splitlines() if line.strip()]


def fill(call, pic_dir):
    text = (PROMPTS / PROMPT_FILES[call["quality"]]).read_text()
    body = text.split("\n---\n", 1)[1].lstrip("\n")
    pics = "\n".join(f"- `{pic_dir}/{p['code']}.png`: {p['role']}" for p in call["pictures"])
    cand = next(p["code"] for p in call["pictures"] if p["role"] == "CANDIDATE")
    return (body.replace("{{item}}", cand).replace("{{class}}", call["class"])
            .replace("{{pictures}}", pics))


def render(run, out):
    out = pathlib.Path(out).resolve()
    if out == ROOT or ROOT in out.parents:
        sys.exit("render: DIR must be outside the repository, so the judge cannot find the labels beside it")
    data = golden.by_id(golden.load())
    calls = read_jsonl(RUNS / run / "plan.jsonl")
    (out / "calls").mkdir(parents=True, exist_ok=True)
    seen = set()
    for c in calls:
        for p in c["pictures"]:
            if p["code"] not in seen:
                seen.add(p["code"])
                shutil.copyfile(golden.GOLDEN / data[p["id"]]["image"], out / f"{p['code']}.png")
        (out / "calls" / f"{c['call']}.md").write_text(fill(c, out))
    print(f"{len(calls)} calls, {len(seen)} pictures in {out}")


# ---------------------------------------------------------------- scoring

def decide(answers):
    """The D-06 rule on one row's samples, in order: pass, fail, split (three
    more needed), or unknown (any UNKNOWN goes to exceptions)."""
    a = [x.lower() for x in answers]
    if "unknown" in a:
        return "unknown"
    if len(a) < 3:
        return "incomplete"
    first = a[:3]
    if first.count("fail") == 3:
        return "fail"
    if first.count("pass") == 3:
        return "pass"
    if len(a) < 6:
        return "split"
    return "fail" if a[:6].count("fail") >= 4 else "pass"


def rows_of(calls, results):
    ans = {r["call"]: r for r in results}
    rows = defaultdict(list)
    meta = {}
    for c in sorted(calls, key=lambda c: c["sample"]):
        key = (c["item"], c["quality"])
        meta[key] = c
        if c["call"] in ans:
            rows[key].append(ans[c["call"]]["answer"])
    return {k: (meta[k], decide(rows.get(k, []))) for k in meta}


def score(calls, results):
    """Per quality: counts and whether the target holds."""
    keys = ("rows", "fails", "passs", "caught", "blocked", "exceptions", "open")
    per = defaultdict(lambda: Counter(dict.fromkeys(keys, 0)))
    for (item, q), (c, verdict) in rows_of(calls, results).items():
        n = per[q]
        n["rows"] += 1
        n[c["label"] + "s"] += 1
        if verdict in ("split", "incomplete"):
            n["open"] += 1
        elif verdict == "unknown":
            n["exceptions"] += 1
        elif c["label"] == "fail" and verdict == "fail":
            n["caught"] += 1
        elif c["label"] == "pass" and verdict == "fail":
            n["blocked"] += 1
    out = {}
    for q, n in sorted(per.items()):
        catch = n["caught"] / n["fails"] if n["fails"] else None
        fb = n["blocked"] / n["passs"] if n["passs"] else None
        ex = n["exceptions"] / n["rows"]
        ok = (n["open"] == 0 and catch is not None and catch >= TARGET["catch"]
              and (fb is None or fb <= TARGET["false_block"]) and ex <= TARGET["exceptions"])
        out[q] = dict(n, catch=catch, false_block=fb, exception_share=ex,
                      meets=ok if n["open"] == 0 else None)
    return out


def score_markdown(s, model, third):
    lines = [f"Judge {model}, third {third}.", "",
             "| Quality | Fails caught | False blocks | Sent to exceptions | Still open | Target |",
             "|---|---|---|---|---|---|"]
    for q, n in s.items():
        meets = {True: "met", False: "missed", None: "open"}[n["meets"]]
        lines.append(f"| {q}. {golden.QUALITY_NAMES[q]} | {n['caught']} of {n['fails']} | "
                     f"{n['blocked']} of {n['passs']} | {n['exceptions']} of {n['rows']} | "
                     f"{n['open']} | {meets} |")
    return "\n".join(lines)


def extra(run, results):
    calls = read_jsonl(RUNS / run / "plan.jsonl")
    more = []
    data, labels = golden.load(), labelled()
    for (item, q), (c, verdict) in rows_of(calls, results).items():
        if verdict == "split" and max(x["sample"] for x in calls
                                      if (x["item"], x["quality"]) == (item, q)) < 6:
            sub = {"items": [it for it in data["items"] if it["id"] == item or it.get("third") == TRAIN]}
            for x in plan(sub, labels, c["third"], c["model"], run, samples=3, start=4):
                if x["quality"] == q and x["item"] == item:
                    more.append(x)
    write_plan(more, run, append=True)
    print(f"{len(more)} more calls for {len(more) // 3} split rows")


# ---------------------------------------------------------------- the audit

def audit(verdicts, seed, passes=15, fails=4):
    """Items (task, sha, item) the gate passed on every quality, and items it
    failed on any, drawn by class in turn; returns the shuffled form rows."""
    passes, fails = max(10, min(20, passes)), max(3, min(5, fails))
    items = defaultdict(list)
    for v in verdicts:
        items[(v["task_id"], v["sha"], v["item"])].append(v)
    passed = defaultdict(list)
    failed = []
    for key, vs in sorted(items.items()):
        if all(v["result"] == "pass" for v in vs):
            passed[vs[0].get("class", "screen")].append(key)
        elif any(v["result"] == "fail" for v in vs):
            failed.append(key)
    rng = random.Random(seed)
    for pool in passed.values():
        rng.shuffle(pool)
    pick = []
    classes = sorted(passed)
    while len(pick) < passes and any(passed.values()):
        for cls in classes:
            if passed[cls] and len(pick) < passes:
                pick.append(passed[cls].pop())
    rng.shuffle(failed)
    pick += failed[:fails]
    rng.shuffle(pick)
    form = []
    for key in pick:
        for v in sorted(items[key], key=lambda v: v["quality"]):
            form.append({"task_id": key[0], "sha": key[1], "item": key[2], "quality": v["quality"]})
    return form


# ---------------------------------------------------------------- self-test

def self_test():
    assert decide(["pass"] * 3) == "pass" and decide(["fail"] * 3) == "fail"
    assert decide(["fail", "pass", "fail"]) == "split"
    assert decide(["fail", "pass", "fail", "fail", "pass", "pass"]) == "pass"
    assert decide(["fail", "pass", "fail", "fail", "pass", "fail"]) == "fail"
    assert decide(["pass", "UNKNOWN", "pass"]) == "unknown"
    assert decide(["pass"]) == "incomplete"

    def it(i, cls, third, bl=False, origin="natural"):
        return {"id": i, "class": cls, "third": third, "borderline": bl,
                "origin": origin, "qualities": [3], "expected": "pass", "image": "x"}
    data = {"items": [it("a", "icon", 1), it("b", "icon", 1, bl=True), it("c", "icon", 1, bl=True),
                      it("d", "icon", 1, origin="planted"), it("e", "icon", 2), it("f", "icon", 3),
                      it("g", "icon", 3, bl=True)]}
    labs = {("a", 3): ("pass", ""), ("b", 3): ("pass", ""), ("c", 3): ("fail", ""),
            ("d", 3): ("fail", ""), ("e", 3): ("fail", ""), ("f", 3): ("pass", ""),
            ("g", 3): ("fail", "")}
    a = anchors(data, labs)[("icon", 3)]
    assert a == {"pass": "b", "fail": "c"}, a  # borderline natural first, training only
    calls = plan(data, labs, HELD_OUT, "M", "t")
    assert len(calls) == 6 and {c["item"] for c in calls} == {"f", "g"}
    assert all(p["id"] in "bcfg" for c in calls for p in c["pictures"])
    assert code("f", "t") != code("f", "u") and code("f", "t").startswith("g")
    try:
        plan(data, labs, TRAIN, "M", "t")
        raise AssertionError("the training third must not be measured")
    except AssertionError as e:
        assert "training" in str(e)

    # f is a pass the judge fails once of three then passes 2 of 3 more (pass);
    # g is a fail caught three of three.
    res = [{"call": c["call"], "answer": "fail" if c["item"] == "g" or c["sample"] == 1 else "pass"}
           for c in calls]
    s = score(calls, res)[3]
    assert s["open"] == 1 and s["meets"] is None  # f split, needs three more
    more = [dict(c, sample=c["sample"] + 3, call=c["call"] + "x") for c in calls if c["item"] == "f"]
    res += [{"call": c["call"], "answer": "pass"} for c in more]
    s = score(calls + more, res)[3]
    assert (s["caught"], s["fails"], s["blocked"], s["passs"], s["open"]) == (1, 1, 0, 1, 0)
    assert s["meets"] is True
    res = [{"call": c["call"], "answer": "pass"} for c in calls]  # a judge that passes all
    s = score(calls, res)[3]
    assert s["catch"] == 0 and s["meets"] is False

    vs = []
    for n in range(30):
        cls = ["screen", "icon", "kit art"][n % 3]
        for q in (1, 8):
            vs.append({"task_id": "T", "sha": "s", "item": f"i{n}", "class": cls, "quality": q,
                       "result": "fail" if n % 5 == 0 and q == 8 else "pass"})
    form = audit(vs, seed=1)
    items = {(r["item"]) for r in form}
    failed = {f"i{n}" for n in range(30) if n % 5 == 0}
    assert len(items) == 19 and len(items & failed) == 4
    assert all("result" not in r for r in form)
    kinds = Counter(["screen", "icon", "kit art"][int(i[1:]) % 3] for i in items - failed)
    assert max(kinds.values()) - min(kinds.values()) <= 1, kinds
    print("ui_gate calibrate self-test: ok")


# ---------------------------------------------------------------- main

def main(argv):
    if argv[:1] == ["--self-test"]:
        self_test()
        return 0
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("split")
    sub.add_parser("anchors")
    a = sub.add_parser("plan")
    a.add_argument("--third", type=int, required=True)
    a.add_argument("--model", required=True)
    a.add_argument("--run", required=True)
    a.add_argument("--samples", type=int, default=3)
    a = sub.add_parser("extra")
    a.add_argument("--run", required=True)
    a.add_argument("results")
    a = sub.add_parser("render")
    a.add_argument("--run", required=True)
    a.add_argument("--out", required=True)
    a = sub.add_parser("score")
    a.add_argument("--run", required=True)
    a.add_argument("results")
    a.add_argument("--markdown", action="store_true")
    a = sub.add_parser("audit")
    a.add_argument("verdicts", nargs="+")
    a.add_argument("--seed", default="audit")
    a.add_argument("--passes", type=int, default=15)
    a.add_argument("--fails", type=int, default=4)
    args = p.parse_args(argv)
    data, labels = golden.load(), labelled()
    if args.cmd == "split":
        print(split_table(data, labels))
    elif args.cmd == "anchors":
        for (cls, q), a in anchors(data, labels).items():
            print(f"{cls:8} {q:2}  pass {a.get('pass', '-'):24} fail {a.get('fail', '-')}")
    elif args.cmd == "plan":
        calls = plan(data, labels, args.third, args.model, args.run, args.samples)
        print(f"{write_plan(calls, args.run)}: {len(calls)} calls")
    elif args.cmd == "extra":
        extra(args.run, read_jsonl(args.results))
    elif args.cmd == "render":
        render(args.run, args.out)
    elif args.cmd == "score":
        calls = read_jsonl(RUNS / args.run / "plan.jsonl")
        s = score(calls, read_jsonl(args.results))
        print(score_markdown(s, calls[0]["model"], calls[0]["third"]) if args.markdown
              else json.dumps({str(k): v for k, v in s.items()}, indent=1))
    elif args.cmd == "audit":
        vs = []
        for f in args.verdicts:
            v = json.loads(pathlib.Path(f).read_text())
            vs += v if isinstance(v, list) else [v]
        for r in audit(vs, args.seed, args.passes, args.fails):
            print(f"| {r['task_id']} | {r['sha']} | {r['item']} | {r['quality']} |  |  |")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
