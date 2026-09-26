class_name ColourCheck
## The arithmetic behind §20.8's "palettes checked by simulation for the three
## common forms of colour blindness" and §21.8's "Contrast meets 4.5:1,
## checked against a perceptual model as well, because the standard formula
## overstates contrast on dark backgrounds". Pure functions of colours, so
## the tests call them on every token pair and every label on every screen.

## WCAG 2's minimum for body text (§21.8).
const MIN_RATIO := 4.5
## APCA's lightness contrast (0.0.98G, its bronze levels): Lc 75 for body
## text at §21.8's 16 points; Lc 60 for short words 16 points bold or 24
## points normal — a button's label, a title; Lc 45 for text 36 points up.
const MIN_LC_BODY := 75.0
const MIN_LC_SHORT := 60.0
const MIN_LC_LARGE := 45.0
## ΔE (CIE76, in Lab) below which two colours read as one at a glance.
const DISTINCT_DELTA_E := 10.0

## Machado, Oliveira and Fernandes (2009), severity 1.0: linear-RGB matrices
## for the three common forms.
const SIMULATIONS := {
	"protanopia": [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216],
			[-0.003882, -0.048116, 1.051998]],
	"deuteranopia": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413],
			[-0.011820, 0.042940, 0.968881]],
	"tritanopia": [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602],
			[0.004733, 0.691367, 0.303900]],
}


static func _linear(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)


static func _gamma(c: float) -> float:
	c = clampf(c, 0.0, 1.0)
	return c * 12.92 if c <= 0.0031308 else 1.055 * pow(c, 1.0 / 2.4) - 0.055


## A colour over another: what the eye gets from a translucent panel.
static func over(top: Color, below: Color) -> Color:
	var a := top.a
	return Color(top.r * a + below.r * (1 - a), top.g * a + below.g * (1 - a), top.b * a + below.b * (1 - a), 1)


## WCAG 2's relative luminance.
static func luminance(c: Color) -> float:
	return 0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b)


## WCAG 2's contrast ratio, 1 to 21.
static func ratio(a: Color, b: Color) -> float:
	var la := luminance(a)
	var lb := luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## APCA 0.0.98G's lightness contrast (Lc) of text on a background, as a
## magnitude: the perceptual model §21.8 asks for beside the ratio.
static func apca(text: Color, background: Color) -> float:
	var y := func(c: Color) -> float:
		var v := 0.2126729 * pow(c.r, 2.4) + 0.7151522 * pow(c.g, 2.4) + 0.0721750 * pow(c.b, 2.4)
		return v if v > 0.022 else v + pow(0.022 - v, 1.414)
	var yt: float = y.call(text)
	var yb: float = y.call(background)
	if absf(yb - yt) < 0.0005:
		return 0.0
	var s: float
	if yb > yt:
		s = (pow(yb, 0.56) - pow(yt, 0.57)) * 1.14
		return 0.0 if s < 0.1 else (s - 0.027) * 100.0
	s = (pow(yb, 0.65) - pow(yt, 0.62)) * 1.14
	return 0.0 if s > -0.1 else absf((s + 0.027) * 100.0)


## The APCA level text of `points` needs, `bold` or not.
static func lc_needed(points: float, bold := false) -> float:
	if points >= 36:
		return MIN_LC_LARGE
	if points >= 24 or bold:
		return MIN_LC_SHORT
	return MIN_LC_BODY


## Whether text of `points` in `text` reads on `background` by both models.
static func readable(text: Color, background: Color, points: float, bold := false) -> bool:
	return ratio(text, background) >= MIN_RATIO and apca(text, background) >= lc_needed(points, bold)


## A colour as someone with `form` of colour blindness sees it.
static func simulate(c: Color, form: String) -> Color:
	var m: Array = SIMULATIONS[form]
	var lin := [_linear(c.r), _linear(c.g), _linear(c.b)]
	var out := []
	for row: Array in m:
		out.append(_gamma(row[0] * lin[0] + row[1] * lin[1] + row[2] * lin[2]))
	return Color(out[0], out[1], out[2], c.a)


## CIE76 ΔE between two colours, through Lab (D65).
static func delta_e(a: Color, b: Color) -> float:
	return _lab(a).distance_to(_lab(b))


## A colour with its hue taken away, as §21.10's grayscale test sees it.
static func gray(c: Color) -> Color:
	var v := _gamma(luminance(c))
	return Color(v, v, v, c.a)


static func _lab(c: Color) -> Vector3:
	var r := _linear(c.r)
	var g := _linear(c.g)
	var b := _linear(c.b)
	var x := (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
	var y := 0.2126 * r + 0.7152 * g + 0.0722 * b
	var z := (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
	var f := func(t: float) -> float: return pow(t, 1.0 / 3.0) if t > 0.008856 else 7.787 * t + 16.0 / 116.0
	var fx: float = f.call(x)
	var fy: float = f.call(y)
	var fz: float = f.call(z)
	return Vector3(116.0 * fy - 16.0, 500.0 * (fx - fy), 200.0 * (fy - fz))
