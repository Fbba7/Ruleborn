"""Tests of run.py and table.py, with no Godot run (3D0-M1-baseline).

    python3 -m unittest discover -s docs/art/3d-quality/baseline -p 'test_*.py'

Each test points run.py at a temporary work folder, data folder and output
file, so the repository's baseline.md and baseline/data/ are never touched.
"""
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import run  # noqa: E402
import table  # noqa: E402

HEIST_BUDGET = ("budget: heist: 85446 triangles (56480 mesh + 28966 outline passes); 0 triangles in shadows; "
                "70 draw calls, shadow passes included; 7287 triangles and 50 draw calls in other views; "
                "frame 92733 triangles, 120 draw calls")


def fake_shot(work: Path, name: str, *, budget=HEIST_BUDGET, still=True, measure=None, mask_error=False):
    """A work folder as tools/render/mask.py leaves it."""
    out = work / name
    out.mkdir(parents=True)
    lines = ["Godot Engine v4.7.2", budget]
    if mask_error:
        lines += ["SCRIPT ERROR: Invalid access to property 'size' on a base object of type 'Node'.",
                  "          at: _frame (res://../tools/render/mask_pass.gd:194)"]
    if still:
        lines.append("wrote")
        (out / "shot.png").write_bytes(b"png")
    (out / "godot.log").write_text("\n".join(lines) + "\n")
    if measure is not None:
        (out / "measure.json").write_text(json.dumps(measure))
    return out


class Sandbox(unittest.TestCase):
    """run.WORK, run.DATA and run.OUT in a temporary folder."""

    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.work = self.tmp / "work"
        self.data = self.tmp / "data"
        self.out = self.tmp / "baseline.md"
        self.work.mkdir()
        self.data.mkdir()
        self.saved = run.WORK, run.DATA, run.OUT, run.run_one
        run.WORK, run.DATA, run.OUT = self.work, self.data, self.out

    def tearDown(self):
        run.WORK, run.DATA, run.OUT, run.run_one = self.saved
        shutil.rmtree(self.tmp)


class NoRender(Sandbox):
    def test_no_render_keeps_the_data_with_no_work_folder(self):
        """The verifier's case: a fresh checkout has baseline/data/ but no work folder."""
        for f in (HERE / "data").glob("*.json"):
            shutil.copy(f, self.data / f.name)
        before = {f.name: f.read_bytes() for f in self.data.glob("*.json")}
        self.assertTrue(before)
        code = run.main(["--no-render"])
        self.assertEqual(code, 0)
        after = {f.name: f.read_bytes() for f in self.data.glob("*.json")}
        self.assertEqual(after, before)
        text = self.out.read_text()
        self.assertIn("| `screen_heist` | 56,480 |", text)

    def test_no_render_writes_the_table_the_data_gives(self):
        for f in (HERE / "data").glob("*.json"):
            shutil.copy(f, self.data / f.name)
        run.main(["--no-render"])
        expected = self.tmp / "expected.md"
        table.write(expected, self.data)
        self.assertEqual(self.out.read_text(), expected.read_text())


class Rendering(Sandbox):
    def test_a_shot_with_no_work_folder_writes_no_record_and_fails(self):
        old = {"name": "screen_heist", "budget": HEIST_BUDGET, "measure": None, "verdict": "ok", "why": "kept"}
        (self.data / "screen_heist.json").write_text(json.dumps(old))
        run.run_one = lambda name: {"name": name, "returncode": 1, "stdout": ""}
        code = run.main(["--only", "screen_heist"])
        self.assertEqual(code, 1)
        self.assertEqual(json.loads((self.data / "screen_heist.json").read_text()), old)

    def test_a_failed_shot_keeps_its_old_record(self):
        """An injected shot's work folder exists (its script copy) though mask.py wrote nothing."""
        old = {"name": "screen_laws", "budget": HEIST_BUDGET, "measure": None, "verdict": "ok", "why": "kept"}
        (self.data / "screen_laws.json").write_text(json.dumps(old))
        (self.work / "screen_laws" / "src").mkdir(parents=True)
        run.run_one = lambda name: {"name": name, "returncode": 1, "stdout": ""}
        self.assertEqual(run.main(["--only", "screen_laws"]), 1)
        self.assertEqual(json.loads((self.data / "screen_laws.json").read_text()), old)

    def test_the_record_keeps_the_verdict(self):
        fake_shot(self.work, "screen_realm", mask_error=True)
        rec = run.collect("screen_realm")
        self.assertEqual(rec["verdict"], "mask limit")
        self.assertIn("mask_pass.gd", rec["why"])
        self.assertEqual(rec["budget"], HEIST_BUDGET)

    def test_a_measured_shot_is_ok_in_its_record(self):
        measure = json.loads((HERE / "data/screen_heist.json").read_text())["measure"]
        fake_shot(self.work, "screen_heist", measure=measure)
        run.run_one = lambda name: {"name": name, "returncode": 0, "stdout": ""}
        self.assertEqual(run.main(["--only", "screen_heist"]), 0)
        rec = json.loads((self.data / "screen_heist.json").read_text())
        self.assertEqual(rec["verdict"], "ok")
        self.assertEqual(rec["measure"], measure)


class MustMeasure(Sandbox):
    def test_an_error_in_the_mask_tool_fails_a_heist_shot(self):
        for name in ("screen_heist", "screen_replay", "screen_result", "screen_laws"):
            fake_shot(self.work, name, mask_error=True)
            state, why = run.verdict(name)
            self.assertEqual(state, "failed", name)
            self.assertIn("must be measured", why)

    def test_an_error_in_the_mask_tool_is_the_known_limit_elsewhere(self):
        fake_shot(self.work, "screen_realm", mask_error=True)
        self.assertEqual(run.verdict("screen_realm")[0], "mask limit")

    def test_must_measure_names_real_shots(self):
        self.assertTrue(run.MUST_MEASURE <= set(run.SHOTS))


class Table(unittest.TestCase):
    def test_the_frame_draw_calls_have_their_own_column(self):
        rec = {"name": "screen_heist", "budget": HEIST_BUDGET, "measure": None}
        row = table.budget(rec)
        head = table.HEAD
        self.assertEqual(row[head.index("View draw calls") - 1], "70")
        self.assertEqual(row[head.index("Frame draw calls") - 1], "120")

    def test_a_frame_only_shot_has_no_view_draw_calls(self):
        rec = {"name": "screen_character", "budget": "draw calls 93, primitives 13752", "measure": None}
        row = table.budget(rec)
        self.assertEqual(row[table.HEAD.index("View draw calls") - 1], "-")
        self.assertEqual(row[table.HEAD.index("Frame draw calls") - 1], "93*")

    def test_the_observatory_row_has_its_note(self):
        self.assertIn("screen_observatory", table.NOTES)

    def test_the_published_table_is_what_the_data_gives(self):
        """baseline.md is table.py's output from baseline/data/, byte for byte."""
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "baseline.md"
            table.write(out, HERE / "data")
            self.assertEqual(out.read_text(), (HERE.parent / "baseline.md").read_text())


if __name__ == "__main__":
    unittest.main()
