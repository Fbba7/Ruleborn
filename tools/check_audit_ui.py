#!/usr/bin/env python3
"""Do the audit page's tabs and chips agree with the register behind them?

    python3 tools/check_audit_ui.py
    python3 tools/check_audit_ui.py --self-test

The page carries numbers in three places that a reader compares without
thinking: a tab's count, its progress bar, and the chip counts underneath it.
Nothing makes them agree — the tab totals come from ``side_progress``, the bar
widths from percentages computed beside them, the chip counts from a recount
in the browser, and the items themselves from ``data-`` attributes written
somewhere else again. Four sources for one set of numbers is exactly the shape
of a page that quietly starts lying after an edit.

So this reads the built HTML back and checks the four against each other, and
then runs the page's own script over a stubbed DOM to check that clicking a
tab shows what the tab says it will. The script is the part that cannot be
verified by reading: it computes the chip counts live, and a wrong side test
there would still render a page that looks entirely correct.

Node is used for that second half because the script is JavaScript. Where node
is missing the structural half still runs and the script half says so rather
than passing silently — D28's rule, that a check which cannot fail is worth
nothing when it passes.
"""

from __future__ import annotations

import json
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
PAGE = ROOT / "docs" / "audit" / "index.html"

ITEM = re.compile(r'<article class="item [^"]*" id="([^"]+)"([^>]*)>')
ATTR = re.compile(r'data-([a-z]+)="([^"]*)"')
TAB = re.compile(
    r'<button class="tab" data-side="([a-z]+)"[^>]*>.*?'
    r'<span class="tab-n">(\d+)</span>.*?'
    r'<span class="fill drafted" style="width:([\d.]+)%">.*?'
    r'<span class="fill settled" style="width:([\d.]+)%">.*?'
    r'<span class="tab-foot">(\d+) settled &middot;\s*(\d+) drafted &middot; (\d+) open',
    re.S)
CHIP = re.compile(r'<button class="chip[^"]*" data-filter="([^"]+)"[^>]*>'
                  r'(?:[^<]*)(?:<span class="n">(\d+)</span>)?')


def items(html: str) -> list[dict]:
    out = []
    for ident, rest in ITEM.findall(html):
        d = dict(ATTR.findall(rest))
        d["id"] = ident
        out.append(d)
    return out


def chips(html: str) -> list[tuple[str, int | None]]:
    nav = html[html.index('<nav class="filters"'):html.index("</nav>",
                          html.index('<nav class="filters"'))]
    return [(f, int(n) if n else None) for f, n in CHIP.findall(nav)]


def on_side(item: dict, side: str) -> bool:
    return side == "all" or item.get("side") in (side, "both")


def on_chip(item: dict, filt: str) -> bool:
    if filt == "all":
        return True
    key, _, value = filt.partition(":")
    return item.get(key) == value


def check(html: str) -> list[str]:
    bad = []
    rows = items(html)
    if not rows:
        return ["no items parsed out of the page — the markup changed shape"]

    tabs = TAB.findall(html)
    if len(tabs) != 3:
        bad.append(f"expected three tabs, found {len(tabs)}")
    seen = set()
    for side, total, drafted_w, settled_w, settled, drafted, open_ in tabs:
        seen.add(side)
        total, settled, drafted, open_ = (int(total), int(settled),
                                          int(drafted), int(open_))
        here = [i for i in rows if on_side(i, side)]
        if len(here) != total:
            bad.append(f"{side} tab counts {total} items, the page carries "
                       f"{len(here)} on that side")
        if settled + drafted + open_ != total:
            bad.append(f"{side} tab: {settled}+{drafted}+{open_} does not make "
                       f"its own total of {total}")
        # The bar is two stacked fills, so the paler one has to be the wider:
        # it is settled *plus* drafted, not drafted alone.
        if float(drafted_w) < float(settled_w) - 0.05:
            bad.append(f"{side} tab: the drafted fill ({drafted_w}%) is narrower "
                       f"than the settled one ({settled_w}%), so it would be "
                       f"painted over and never seen")
        for name, want, width in (("settled", settled, settled_w),
                                  ("drafted", settled + drafted, drafted_w)):
            expect = 100.0 * want / (total or 1)
            if abs(expect - float(width)) > 0.06:
                bad.append(f"{side} tab: the {name} fill is {width}% but "
                           f"{want} of {total} is {expect:.1f}%")
    if seen != {"all", "backend", "frontend"}:
        bad.append(f"the tabs cover {sorted(seen)}, not all/backend/frontend")

    for filt, count in chips(html):
        hits = sum(1 for i in rows if on_chip(i, filt))
        if count is not None and hits != count:
            bad.append(f'chip "{filt}" shows {count}, matches {hits} items')
        if hits == 0:
            bad.append(f'chip "{filt}" matches nothing at all')
        key = filt.partition(":")[0]
        if filt != "all" and not any(key in i for i in rows):
            bad.append(f'chip "{filt}" filters on data-{key}, which no item has')

    every = {k for i in rows for k in i if k != "id"}
    if "side" not in every:
        bad.append("no item carries data-side, so the tabs cannot filter")
    return bad


STUB = r"""
'use strict';
const fixture = FIXTURE;
function el(data) {
  return {dataset: data, hidden: false,
          setAttribute() {}, addEventListener(_, f) { this._click = f; }};
}
const items = fixture.items.map(el);
const tabs = fixture.tabs.map(function (s) { return el({side: s}); });
const chipEls = fixture.chips.map(function (f) {
  var e = el({filter: f});
  e._n = {textContent: ""};
  e.querySelector = function () { return e._n; };
  return e;
});
const doc = {
  querySelectorAll(sel) {
    if (sel === '.tab') return tabs;
    if (sel === '.chip') return chipEls;
    if (sel === '.item') return items;
    return [];
  },
  getElementById() { return {hidden: false}; },
};
globalThis.document = doc;
globalThis.localStorage = {getItem() { return null; }, setItem() {}};
SCRIPT
const out = [];
for (const t of tabs) {
  t._click();
  out.push({side: t.dataset.side,
            shown: items.filter(function (i) { return !i.hidden; })
                        .map(function (i) { return i.dataset.id; }),
            chips: chipEls.map(function (c) {
              return [c.dataset.filter, Number(c._n.textContent), !!c.disabled];
            })});
}
console.log(JSON.stringify(out));
"""


def check_script(html: str) -> list[str]:
    """Run the page's own script over a stub DOM and check what it shows."""
    node = shutil.which("node")
    if not node:
        return ["node is not installed, so the page's script was NOT checked "
                "— this is a skipped check, not a passing one"]
    rows = items(html)
    script = html[html.index("<script>") + 8:html.index("</script>")]
    # The script needs no .group elements: a group with nothing shown hides
    # itself, which changes nothing about which items are shown.
    fixture = dict(items=rows, tabs=["all", "backend", "frontend"],
                   chips=[f for f, _ in chips(html)])
    src = (STUB.replace("FIXTURE", json.dumps(fixture))
                .replace("SCRIPT", script))
    with tempfile.NamedTemporaryFile("w", suffix=".mjs", delete=False) as fh:
        fh.write(src)
        path = fh.name
    try:
        r = subprocess.run([node, path], capture_output=True, text=True)
    finally:
        pathlib.Path(path).unlink(missing_ok=True)
    if r.returncode:
        return [f"the page's script failed to run: {r.stderr.strip()[:400]}"]

    bad = []
    for got in json.loads(r.stdout):
        side = got["side"]
        want = sorted(i["id"] for i in rows if on_side(i, side))
        if sorted(got["shown"]) != want:
            missing = sorted(set(want) - set(got["shown"]))
            extra = sorted(set(got["shown"]) - set(want))
            bad.append(f"clicking the {side} tab shows {len(got['shown'])} items, "
                       f"not the {len(want)} on that side"
                       + (f" (missing {missing[:4]})" if missing else "")
                       + (f" (also shows {extra[:4]})" if extra else ""))
        for filt, shown, disabled in got["chips"]:
            hits = sum(1 for i in rows if on_side(i, side) and on_chip(i, filt))
            if shown != hits:
                bad.append(f"on the {side} tab, chip \"{filt}\" recounts to "
                           f"{shown}, not {hits}")
            if disabled != (hits == 0):
                bad.append(f"on the {side} tab, chip \"{filt}\" is "
                           f"{'disabled' if disabled else 'live'} with {hits} "
                           f"items behind it")
    return bad


def self_test() -> int:
    """The checks have to fail on a page that is wrong, or they mean nothing."""
    ok = True
    html = PAGE.read_text()

    if check(html):
        print("    FAIL: the built page does not pass its own structural check")
        ok = False
    else:
        print("  the built page passes the structural check")

    # A tab whose count is off by one.
    broken = re.sub(r'(<span class="tab-n">)(\d+)(</span>)',
                    lambda m: f"{m.group(1)}{int(m.group(2)) + 1}{m.group(3)}",
                    html, count=1)
    if any("tab counts" in b for b in check(broken)):
        print("  and a tab counting one item too many is caught")
    else:
        print("    FAIL: a wrong tab count went unnoticed")
        ok = False

    # A bar drawn at the wrong width.
    broken = html.replace('<span class="fill settled" style="width:',
                          '<span class="fill settled" style="width:9', 1)
    if any("fill is" in b for b in check(broken)):
        print("  and a progress bar drawn at the wrong width is caught")
    else:
        print("    FAIL: a mis-drawn progress bar went unnoticed")
        ok = False

    # An item that loses its side: the tabs stop covering the register.
    broken = html.replace('data-side="frontend"', 'data-side="backend"', 1)
    if any("tab counts" in b for b in check(broken)):
        print("  and an item moved to the wrong side is caught")
    else:
        print("    FAIL: an item on the wrong side went unnoticed")
        ok = False

    if shutil.which("node"):
        # The mistake this half exists for: a side test that forgets "both".
        broken = html.replace('el.dataset.side === "both"',
                              'el.dataset.side === "neither"', 1)
        if any("tab shows" in b for b in check_script(broken)):
            print("  and a script that drops the both-sides items is caught")
        else:
            print("    FAIL: a script that hides half the frontend went unnoticed")
            ok = False
        # And the counts specifically: a recount that ignores the chosen side
        # leaves every item correctly shown and every number beside it wrong,
        # which is the failure a reader would believe.
        broken = html.replace(
            "if (onSide(el, side) && onChip(el, c.dataset.filter)) hits++;",
            "if (onChip(el, c.dataset.filter)) hits++;", 1)
        found = check_script(broken)
        if any("recounts to" in b for b in found) and not any(
                "tab shows" in b for b in found):
            print("  and a chip recount that ignores the tab is caught, with "
                  "the items themselves still right")
        else:
            print("    FAIL: chip counts that ignore the chosen side went "
                  "unnoticed")
            ok = False

        if check_script(html):
            print("    FAIL: the built page's script does not pass its own check")
            ok = False
        else:
            print("  the built page's script shows what its tabs promise")
    else:
        print("  node is missing — the script half of this gate did not run")
    return 0 if ok else 1


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    if not PAGE.exists():
        print(f"{PAGE} has not been built")
        return 1
    html = PAGE.read_text()
    bad = check(html) + check_script(html)
    for b in bad:
        print(f"  {b}")
    rows = items(html)
    sides = {}
    for i in rows:
        sides[i.get("side", "?")] = sides.get(i.get("side", "?"), 0) + 1
    print(f"{len(rows)} items on the page: "
          + ", ".join(f"{n} {s}" for s, n in sorted(sides.items())))
    print("the tabs, their bars, the chip counts and the script agree"
          if not bad else f"{len(bad)} disagreement(s) above")
    return 1 if bad else 0


if __name__ == "__main__":
    raise SystemExit(main())
