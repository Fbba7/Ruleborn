#!/usr/bin/env python3
"""Shrinks judging stills under the 400 KB the shots folder allows: a PNG over
the limit is quantised to 256 colours, then halved until it fits.

    python3 tools/art/shrink.py docs/art/shots/t1c/*.png
"""
import os
import sys

from PIL import Image

LIMIT = 400 * 1024

for path in sys.argv[1:]:
    while os.path.getsize(path) > LIMIT:
        im = Image.open(path).convert("RGB")
        if im.mode != "P" and not path.endswith(".q"):
            q = im.quantize(256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
            q.save(path, optimize=True)
            if os.path.getsize(path) <= LIMIT:
                break
            im = q.convert("RGB")
        im.resize((im.width * 3 // 4, im.height * 3 // 4), Image.LANCZOS).quantize(256).save(path, optimize=True)
    print(path, os.path.getsize(path) // 1024, "KB")
