"""Quantise the exported icon PNGs to 256 colours with alpha, in place, and
ask Godot for mipmaps on each, so an icon drawn smaller than its 48 points
stays clean.

    python3 tools/ui/pack_icons.py client/ui/icons/png

The mipmap switch is in each PNG's .import file, which Godot writes on its
first import: run this again after `godot --headless --path client --import`
for icons that are new, then import once more.

Run by export_icons.mjs after it writes them: a palette PNG of an icon is a
fifth of the size and indistinguishable from the full-colour one at the sizes
the screens draw (checked side by side when the set was first exported).
"""
import pathlib
import sys

from PIL import Image


def main(folder: str) -> None:
    before = after = 0
    for f in sorted(pathlib.Path(folder).rglob("*.png")):
        before += f.stat().st_size
        im = Image.open(f).convert("RGBA")
        im.quantize(colors=256, method=Image.Quantize.FASTOCTREE).save(f, optimize=True)
        after += f.stat().st_size
        imp = f.with_name(f.name + ".import")
        if imp.exists():
            text = imp.read_text()
            if "mipmaps/generate=false" in text:
                imp.write_text(text.replace("mipmaps/generate=false", "mipmaps/generate=true"))
    print(f"packed {folder}: {before // 1024} KB -> {after // 1024} KB")


if __name__ == "__main__":
    main(sys.argv[1])
