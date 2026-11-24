#!/usr/bin/env python3
"""Screens add no chrome of their own (kit-spec.md sections 6.3 and 7).

    python3 tools/ui_bake/check_screens.py            # compare with budgets.json
    python3 tools/ui_bake/check_screens.py --record   # lower the recorded counts
    python3 tools/ui_bake/check_screens.py --self-test
    python3 tools/ui_bake/check_screens.py --root DIR  # another checkout's client/

Counts, per file in client/scripts/ and client/world/, three kinds of chrome
drawn outside the kit (client/ui/):

- draw: CanvasItem draw_* calls that put something on the canvas (not
  draw_set_transform*), RenderingServer canvas_item_add_* calls and FxPen
  calls;
- fill: StyleBoxFlat.new() boxes that draw a fill (not those whose
  draw_center is set false in the same function, like UI.clear_box);
- texture: TextureRect, NinePatchRect, StyleBoxTexture and
  GradientTexture2D made in code, and image files loaded by path.

Comments and words inside strings are not counted. The counts may not rise
above those recorded in tools/ui_bake/budgets.json ("screens"), and fall as
screens move onto the kit: --record writes the lower counts and never a
higher one (it writes today's counts only when none is recorded yet). A recorded count rises only by request to K1 with the lead's
approval, logged in the file's "raises". Files listed in "data_files" draw
data, not chrome (kit-spec.md section 4.5), and are reported, not limited.
"""
import json
import os
import re
import shutil
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
BUDGETS = os.path.join(HERE, "budgets.json")
SCOPE = ("client/scripts", "client/world")
KINDS = ("draw", "fill", "texture")

DRAW = re.compile(
    r"(?<![\w])(?:draw_(?!set_transform|animation_slice|end_animation)[a-z_]+"
    r"|canvas_item_add_[a-z_]+|FxPen\.[a-z_]+)\s*\(")
FUNC_DEF = re.compile(r"^\s*(?:static\s+)?func\s")
FILL_NEW = re.compile(r"(?:var\s+(\w+)\s*(?::=|:\s*StyleBoxFlat\s*=|=)\s*)?StyleBoxFlat\.new\s*\(")
TEXTURE = re.compile(r"\b(?:TextureRect|NinePatchRect|StyleBoxTexture|GradientTexture2D)\.new\s*\(")
# Either quote, the closing one matching the opening one, and any case of the
# extension: GDScript takes both quotes and Godot imports ".PNG" (FX1-T-07).
IMAGE_LOAD = re.compile(
    r"\b(?:pre)?load\(\s*([\"'])(?:(?!\1).)*\.(?i:png|svg|webp|jpe?g)\1")


def _code(line):
    """The line with its comment dropped and its strings emptied."""
    out = []
    quote = None
    i = 0
    while i < len(line):
        ch = line[i]
        if quote:
            if ch == "\\":
                i += 2
                continue
            if ch == quote:
                quote = None
                out.append(ch)
        elif ch in "\"'":
            quote = ch
            out.append(ch)
        elif ch == "#":
            break
        else:
            out.append(ch)
        i += 1
    return "".join(out)


def _without_comment(line):
    """The line with its comment dropped but its strings kept."""
    quote = None
    i = 0
    while i < len(line):
        ch = line[i]
        if quote:
            if ch == "\\":
                i += 2
                continue
            if ch == quote:
                quote = None
        elif ch in "\"'":
            quote = ch
        elif ch == "#":
            return line[:i]
        i += 1
    return line


def count_file(path):
    """{kind: [line numbers]} for one GDScript file."""
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")
    found = {k: [] for k in KINDS}
    codes = [_code(l) for l in lines]
    for n, code in enumerate(codes):
        line_no = n + 1
        for _ in DRAW.finditer(code):
            found["draw"].append(line_no)
        for _ in TEXTURE.finditer(code):
            found["texture"].append(line_no)
        for _ in IMAGE_LOAD.finditer(_without_comment(lines[n])):
            found["texture"].append(line_no)
        for m in FILL_NEW.finditer(code):
            name = m.group(1)
            if name and _clear_later(codes, n, name):
                continue
            found["fill"].append(line_no)
    return found


def _clear_later(codes, start, name):
    """Whether `name.draw_center = false` follows in the same function."""
    clear = re.compile(r"\b%s\.draw_center\s*=\s*false\b" % re.escape(name))
    for code in codes[start + 1:]:
        if FUNC_DEF.match(code):
            return False
        if clear.search(code):
            return True
    return False


def count_tree(root):
    """{relative path: {kind: [line numbers]}} for every .gd file in scope."""
    result = {}
    for top in SCOPE:
        base = os.path.join(root, top)
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames.sort()
            for name in sorted(filenames):
                if not name.endswith(".gd"):
                    continue
                full = os.path.join(dirpath, name)
                rel = os.path.relpath(full, root).replace(os.sep, "/")
                found = count_file(full)
                if any(found[k] for k in KINDS):
                    result[rel] = found
    return result


def load_budgets(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def write_budgets(path, budgets):
    with open(path, "w", encoding="utf-8") as f:
        f.write(json.dumps(budgets, indent=2, sort_keys=True) + "\n")


def compare(found, screens):
    """Lines of rises (failures) and falls (notes) against the recorded counts."""
    recorded = screens.get("counts", {})
    data = screens.get("data_files", {})
    rises, falls = [], []
    for rel in sorted(set(found) | set(recorded)):
        if rel in data:
            continue
        now = found.get(rel, {k: [] for k in KINDS})
        was = recorded.get(rel, {})
        for k in KINDS:
            n, limit = len(now[k]), was.get(k, 0)
            if n > limit:
                rises.append("%s: %d %s (recorded %d), at lines %s" % (
                    rel, n, k, limit, ", ".join(str(x) for x in now[k])))
            elif n < limit:
                falls.append("%s: %d %s (recorded %d)" % (rel, n, k, limit))
    return rises, falls


def totals(found, screens):
    data = screens.get("data_files", {})
    out = {"chrome": {k: 0 for k in KINDS}, "data": {k: 0 for k in KINDS}}
    for rel, kinds in found.items():
        part = "data" if rel in data else "chrome"
        for k in KINDS:
            out[part][k] += len(kinds[k])
    return out


def run(root, budgets_path, record):
    budgets = load_budgets(budgets_path)
    screens = budgets["screens"]
    found = count_tree(root)
    rises, falls = compare(found, screens)
    t = totals(found, screens)
    print("check_screens: chrome outside the kit: %d draw, %d fill, %d texture; "
          "data drawing (not limited): %d draw" % (
              t["chrome"]["draw"], t["chrome"]["fill"], t["chrome"]["texture"],
              t["data"]["draw"]))
    first = "counts" not in screens
    if record:
        if rises and not first:
            for line in rises:
                print("RISE " + line)
            print("check_screens: --record never raises a count; a rise needs a request "
                  "to K1 and the lead's approval (kit-spec.md section 6.8)")
            return 1
        counts = {}
        for rel, kinds in sorted(found.items()):
            if rel in screens.get("data_files", {}):
                continue
            counts[rel] = {k: len(kinds[k]) for k in KINDS}
        screens["counts"] = counts
        screens["totals"] = t["chrome"]
        write_budgets(budgets_path, budgets)
        print("check_screens: recorded %d files" % len(counts))
        return 0
    for line in rises:
        print("RISE " + line)
    for line in falls:
        print("fell " + line + ": run --record to lower the count")
    if rises:
        print("check_screens: FAIL, %d rises: draw this chrome through the kit "
              "(kit-spec.md section 6.5) or ask K1 for a component" % len(rises))
        return 1
    print("check_screens: OK")
    return 0


def self_test():
    """Plants each kind in a scratch tree and checks it is counted and refused."""
    problems = []

    def check(cond, what):
        if not cond:
            problems.append(what)

    sample = "\n".join([
        "extends Control",
        "# draw_rect(Rect2(), Color()) in a comment",
        "func _draw() -> void:",
        "\tdraw_rect(Rect2(0, 0, 4, 4), Color.RED)",
        "\tdraw_set_transform(Vector2.ZERO)",
        "\tvar s := \"draw_circle(Vector2(), 1, Color()) in words\"",
        "\tFxPen.box(self, Rect2(), null)",
        "\tRenderingServer.canvas_item_add_rect(get_canvas_item(), Rect2(), Color())",
        "func own_draw_helper() -> void:",
        "\tpass",
        "func boxes() -> void:",
        "\tvar clear := StyleBoxFlat.new()",
        "\tclear.draw_center = false",
        "\tvar fill := StyleBoxFlat.new()",
        "\tvar t := TextureRect.new()",
        "\tt.texture = load(\"res://world/a.svg\")",
        "\tvar ok := load(\"res://scripts/a.gd\")",
        "\tvar q := load('res://world/b.png')",
        "\tvar up := preload(\"res://world/c.PNG\")",
        "func later() -> void:",
        "\tfill.draw_center = false",
        "",
    ])
    found = count_file_text(sample)
    check(found["draw"] == [4, 7, 8], "draw lines %s, want [4, 7, 8]" % found["draw"])
    check(found["fill"] == [14], "fill lines %s, want [14]" % found["fill"])
    check(found["texture"] == [15, 16, 18, 19], "texture lines %s, want [15, 16, 18, 19]" % found["texture"])

    scratch = tempfile.mkdtemp(prefix="check_screens_")
    try:
        os.makedirs(os.path.join(scratch, "client", "scripts"))
        os.makedirs(os.path.join(scratch, "client", "world"))
        screen = os.path.join(scratch, "client", "scripts", "a_screen.gd")
        with open(screen, "w", encoding="utf-8") as f:
            f.write(sample)
        budgets = os.path.join(scratch, "budgets.json")
        quiet = open(os.devnull, "w")
        old = sys.stdout
        sys.stdout = quiet
        try:
            write_budgets(budgets, {"screens": {"data_files": {}}})
            check(run(scratch, budgets, True) == 0, "the first --record is refused")
            write_budgets(budgets, {"screens": {"counts": {}, "data_files": {}}})
            check(run(scratch, budgets, False) == 1, "a new file's chrome is not refused")
            check(run(scratch, budgets, True) == 1, "--record raised a count")
            write_budgets(budgets, {"screens": {"counts": {
                "client/scripts/a_screen.gd": {"draw": 3, "fill": 1, "texture": 4}},
                "data_files": {}}})
            check(run(scratch, budgets, False) == 0, "the recorded counts are refused")
            with open(screen, "a", encoding="utf-8") as f:
                f.write("func more() -> void:\n\tdraw_circle(Vector2(), 2.0, Color.RED)\n")
            check(run(scratch, budgets, False) == 1, "a planted draw call is not refused")
            with open(screen, "w", encoding="utf-8") as f:
                f.write("extends Control\n")
            check(run(scratch, budgets, False) == 0, "a fall is refused")
            check(run(scratch, budgets, True) == 0, "--record does not lower")
            check(load_budgets(budgets)["screens"]["counts"] == {}, "--record kept a file with none")
            write_budgets(budgets, {"screens": {"counts": {},
                "data_files": {"client/scripts/a_screen.gd": "a chart"}}})
            with open(screen, "w", encoding="utf-8") as f:
                f.write(sample)
            check(run(scratch, budgets, False) == 0, "a data file is limited")
        finally:
            sys.stdout = old
            quiet.close()
    finally:
        shutil.rmtree(scratch)
    for p in problems:
        print("self-test: " + p)
    print("check_screens self-test: %s" % ("FAIL" if problems else "OK"))
    return 1 if problems else 0


def count_file_text(text):
    fd, path = tempfile.mkstemp(suffix=".gd")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(text)
        return count_file(path)
    finally:
        os.unlink(path)


def main(argv):
    if "--self-test" in argv:
        return self_test()
    root = ROOT
    if "--root" in argv:
        root = os.path.abspath(argv[argv.index("--root") + 1])
    return run(root, BUDGETS, "--record" in argv)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
