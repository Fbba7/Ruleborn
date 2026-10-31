"""Colour maths for the gate's sheets and image checks (P0-AD-sheet).

The gate's rubric (docs/art/ui-quality/gate/rubric.md, "Units") measures value
in CIELAB lightness L*, 0 to 100, and calls 10 units of L* one value step.
Everything here works on numpy arrays of sRGB in 0..255, shape (h, w, 3).

    lightness(rgb)        L* per pixel
    grayscale(rgb)        the grey of the same L*, as sRGB (the §21.10 squint)
    simulate(rgb, kind)   protanopia, deuteranopia or tritanopia
    lab(rgb)              full CIELAB, for the tests' colour differences
"""
import numpy as np

# D65 white; sRGB primaries (IEC 61966-2-1).
_TO_XYZ = np.array([
    [0.4124564, 0.3575761, 0.1804375],
    [0.2126729, 0.7151522, 0.0721750],
    [0.0193339, 0.1191920, 0.9503041],
])
_WHITE = _TO_XYZ.sum(axis=1)

# Machado, Oliveira and Fernandes (2009), severity 1.0, in linear RGB. Each
# row sums to 1, so white and greys are unchanged.
CVD = {
    "protanopia": np.array([
        [0.152286, 1.052583, -0.204868],
        [0.114503, 0.786281, 0.099216],
        [-0.003882, -0.048116, 1.051998],
    ]),
    "deuteranopia": np.array([
        [0.367322, 0.860646, -0.227968],
        [0.280085, 0.672501, 0.047413],
        [-0.011820, 0.042940, 0.968881],
    ]),
    "tritanopia": np.array([
        [1.255528, -0.076749, -0.178779],
        [-0.078411, 0.930809, 0.147602],
        [0.004733, 0.691367, 0.303900],
    ]),
}


def to_linear(rgb):
    c = np.asarray(rgb, dtype=np.float64) / 255.0
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def to_srgb(linear):
    c = np.clip(linear, 0.0, 1.0)
    c = np.where(c <= 0.0031308, c * 12.92, 1.055 * c ** (1 / 2.4) - 0.055)
    return np.round(c * 255.0).astype(np.uint8)


def _f(t):
    d = 6 / 29
    return np.where(t > d ** 3, np.cbrt(t), t / (3 * d * d) + 4 / 29)


def lightness(rgb):
    """CIELAB L* (0..100) of each pixel."""
    y = to_linear(rgb) @ _TO_XYZ[1]
    return 116 * _f(y) - 16


def lab(rgb):
    xyz = to_linear(rgb) @ _TO_XYZ.T / _WHITE
    fx, fy, fz = _f(xyz[..., 0]), _f(xyz[..., 1]), _f(xyz[..., 2])
    return np.stack([116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)], axis=-1)


def grayscale(rgb):
    """The grey with each pixel's own L*: luminance kept, colour removed."""
    y = to_linear(rgb) @ _TO_XYZ[1]
    g = to_srgb(y)
    return np.repeat(g[..., None], 3, axis=-1)


def simulate(rgb, kind):
    """How a viewer with the given dichromacy sees the image."""
    return to_srgb(to_linear(rgb) @ CVD[kind].T)


def self_test():
    assert abs(lightness(np.array([255, 255, 255])) - 100) < 0.01
    assert abs(lightness(np.array([0, 0, 0]))) < 0.01
    assert abs(lightness(np.array([119, 119, 119])) - 50) < 0.3
    for kind, m in CVD.items():
        assert np.allclose(m.sum(axis=1), 1, atol=1e-5), kind
        assert (simulate(np.array([[200, 200, 200]]), kind) == 200).all(), kind
    # Red and a green of the same luminance: far apart to a typical eye,
    # nearly one colour to a protanope or deuteranope.
    pair = np.array([[255, 0, 0], [0, 148, 0]])
    assert np.linalg.norm(lab(pair)[0] - lab(pair)[1]) > 100
    for kind in ("protanopia", "deuteranopia"):
        sim = lab(simulate(pair, kind))
        assert np.linalg.norm(sim[0] - sim[1]) < 25, kind
    # A tritanope still tells that pair apart.
    sim = lab(simulate(pair, "tritanopia"))
    assert np.linalg.norm(sim[0] - sim[1]) > 60
    g = grayscale(np.array([[[30, 160, 90]]]))
    assert g[0, 0, 0] == g[0, 0, 1] == g[0, 0, 2]
    assert abs(lightness(g) - lightness(np.array([30, 160, 90]))).max() < 0.5
