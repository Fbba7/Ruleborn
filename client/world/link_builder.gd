class_name LinkBuilder
extends RefCounted
## §5.3's links between realms, as the universe map draws them, built to the
## gap they span (the design's `link`, realm_diorama.js :1167–1195): a stone
## bridge of arched blocks and parapets, lit at each end; a rope bridge of
## planks hung from rope rails, which sways; a chute, a wooden half-pipe with
## water running down it the one way it goes; and a rift, two portal rings in
## the far realm's school colour with a stream of light between them.
##
## A link is built in its own frame — x from one end (0) to the other (its
## length), y up, z across — and written into the map's layers through
## `xf`, so the static ones share the islands' draw calls and a rope bridge
## can be given a node of its own to sway on.

## The server's names for the four kinds (§5.3).
const KINDS := ["stone_bridge", "rope_bridge", "chute", "rift"]
## The deck's width, and the design's map scale carried to the client's
## metres (its island is 2.4 across the radius to the client's 10).
const W := 1.6
const K := 2.4
const STONE := Color("#E8E0D2")
const STONE_DARK := Color("#B5AA98")
const WOOD := Color("#8A5A3A")
const ROPE := Color("#D8C49A")
const POST := Color("#5A3A2A")
const LAMP := Color("#FFC36A")
const WATER := Color("#7FD8F0")

var kind := "stone_bridge"
var length := 1.0
var rise := 0.0
var colour := Palette.SPIRIT
var open := true
## Local to world.
var xf := Transform3D.IDENTITY


## A link of `kind` from `a` to `b`, in the far realm's school `tint`.
func _init(link_kind: String, a: Vector3, b: Vector3, tint: Color, is_open := true) -> void:
	kind = link_kind if link_kind in KINDS else "stone_bridge"
	var d := b - a
	length = Vector2(d.x, d.z).length()
	rise = d.y
	colour = tint
	open = is_open
	xf = frame(a, b)


## The link's frame: at `a`, its x axis toward `b` along the ground.
static func frame(a: Vector3, b: Vector3) -> Transform3D:
	var d := Vector3(b.x - a.x, 0, b.z - a.z)
	var yaw := atan2(-d.z, d.x)
	return Transform3D(Basis(Vector3.UP, yaw), a)


## The deck's height `u` of the way across, `sag` metres up at the middle
## (down when negative).
func y_at(u: float, sag: float) -> float:
	return rise * u + sin(u * PI) * sag


## The link into the layers: solids (inked), glows, and light.
func build(solid: Geo, glows: UniversePaint, flow: UniversePaint, light: UniversePaint) -> void:
	_pads(solid)
	match kind:
		"rope_bridge":
			_rope(solid)
		"chute":
			_chute(solid, flow, glows)
		"rift":
			_rift(solid, glows, light)
		_:
			_stone(solid, glows)


func _at(p: Vector3) -> Vector3:
	return xf * p


func _place(p: Vector3, yaw := 0.0, tilt := 0.0) -> Transform3D:
	var b := xf.basis * Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, tilt)
	return Transform3D(b, xf * p)


## A landing at each end, set into the rim.
func _pads(g: Geo) -> void:
	for u: float in [0.0, 1.0]:
		var p := Vector3(u * length, rise * u - 0.3, 0)
		g.prism(_place(p), 10, 0.62 * K, 0.55 * K, 0.3, Color("#CFC4DA"))
		g.prism(Transform3D(xf.basis * Basis(Vector3.RIGHT, PI), _at(p)), 8, 0.58 * K, 0.0, 0.9 * K,
			Color("#6A5C8C"))


func _stone(g: Geo, glows: UniversePaint) -> void:
	var sag := length * 0.06
	var n := maxi(8, roundi(length / (0.42 * K)))
	for k in n:
		var u := (k + 0.5) / n
		var slope := atan2(rise + cos(u * PI) * PI * sag, length)
		var p := Vector3(u * length, y_at(u, sag), 0)
		var block := STONE if k % 2 == 1 else STONE.darkened(0.07)
		g.box(_place(p, 0.0, slope), Vector3(length / n * 1.02, 0.18 * K, W), block)
		for s: float in [-1.0, 1.0]:
			g.box(_place(p + Vector3(0, 0.17 * K, s * W * 0.47), 0.0, slope),
				Vector3(length / n * 1.02, 0.16 * K, 0.1 * K), STONE_DARK)
	# The arch beneath: deeper toward the ends.
	var n2 := maxi(10, roundi(length / (0.35 * K)))
	for k in n2:
		var u := (k + 0.5) / n2
		var depth := (0.12 + pow(absf(u - 0.5) * 2.0, 2.4) * 0.55) * K
		var p := Vector3(u * length, y_at(u, sag) - 0.09 * K - depth / 2.0, 0)
		g.box(_place(p), Vector3(length / n2 * 1.02, depth, W * 0.8), STONE_DARK.darkened(0.04 * (k % 2)))
	for u: float in [0.0, 1.0]:
		var p := Vector3(u * length, y_at(u, 0.0) + 0.3 * K, W * 0.5)
		g.prism(_place(p - Vector3(0, 0.25 * K, 0)), 6, 0.09 * K, 0.07 * K, 0.5 * K, STONE_DARK)
		g.ball(_place(p + Vector3(0, 0.32 * K, 0)), 0.1 * K, Color(LAMP, 0.1), 2, 5)
		glows.glow(_at(p + Vector3(0, 0.32 * K, 0)), 0.9 * K, Color(LAMP, 0.8))


func _rope(g: Geo) -> void:
	var sag := -length * 0.07
	var n := maxi(10, roundi(length / (0.3 * K)))
	for k in n:
		var u := (k + 0.5) / n
		var slope := atan2(rise - cos(u * PI) * PI * sag, length)
		var p := Vector3(u * length, y_at(u, sag), 0)
		var plank := WOOD if k % 3 != 0 else WOOD.darkened(0.18)
		g.box(_place(p, (0.03 if k % 2 == 1 else -0.03), slope), Vector3(length / n * 0.72, 0.05 * K, W * 0.9), plank)
	for s: float in [-1.0, 1.0]:
		var rail: Array[Vector3] = []
		for k in 17:
			var u := k / 16.0
			rail.append(Vector3(u * length, y_at(u, sag) + 0.34 * K, s * W * 0.48))
		for k in 16:
			_rod(g, rail[k], rail[k + 1], 0.03 * K, ROPE)
		for k in range(1, 8):
			var u := k / 8.0
			var top := Vector3(u * length, y_at(u, sag) + 0.34 * K, s * W * 0.48)
			_rod(g, top, top - Vector3(0, 0.34 * K, 0), 0.012 * K, ROPE.darkened(0.1))
		for u: float in [0.0, 1.0]:
			var foot := Vector3(u * length, y_at(u, 0.0), s * W * 0.5)
			g.prism(_place(foot), 5, 0.06 * K, 0.05 * K, 0.6 * K, POST)


## A thin rod from `a` to `b` in the link's frame.
func _rod(g: Geo, a: Vector3, b: Vector3, r: float, col: Color) -> void:
	var d := b - a
	var span := d.length()
	if span < 0.001:
		return
	var up := d / span
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	var basis := Basis(side, up, side.cross(up))
	g.prism(Transform3D(xf.basis * basis, _at(a)), 4, r, r, span, col)


## A half-pipe on a curve: up a little, then down to the far end, with the
## water running the way the chute goes (§5.3: "Fast, one way").
func _chute(g: Geo, flow: UniversePaint, glows: UniversePaint) -> void:
	var segs := 14
	var around := 5
	var rad := W * 0.46
	var centre: Array[Vector3] = []
	for k in segs + 1:
		var u := k / float(segs)
		centre.append(Vector3(u * length, y_at(u, length * 0.1) - u * 0.6 * K + 0.35 * K, 0))
	var ring := func(k: int, m: int, r: float) -> Vector3:
		var an := m / float(around) * PI
		return centre[k] + Vector3(0, -sin(an) * r, cos(an) * r)
	for k in segs:
		for m in around:
			var shade := WOOD.darkened(0.06 * (m % 2)).lightened(0.05 * (k % 2))
			g.quad(_at(ring.call(k, m, rad)), _at(ring.call(k + 1, m, rad)), _at(ring.call(k + 1, m + 1, rad)),
				_at(ring.call(k, m + 1, rad)), shade)
			g.quad(_at(ring.call(k, m + 1, rad * 1.08)), _at(ring.call(k + 1, m + 1, rad * 1.08)),
				_at(ring.call(k + 1, m, rad * 1.08)), _at(ring.call(k, m, rad * 1.08)), shade.darkened(0.15))
		for s: float in [-1.0, 1.0]:
			var e0: Vector3 = centre[k] + Vector3(0, 0, s * rad)
			var e1: Vector3 = centre[k + 1] + Vector3(0, 0, s * rad)
			_rod(g, e0, e1, 0.06 * K, Color("#C89A68"))
		if k % 4 == 1:
			for m in around:
				_rod(g, ring.call(k, m, rad * 1.1), ring.call(k, m + 1, rad * 1.1), 0.035 * K, POST)
	for u: float in [0.33, 0.66]:
		var p: Vector3 = centre[roundi(u * segs)]
		var h := (1.4 + u) * K
		g.prism(_place(p - Vector3(0, rad + h, 0)), 5, 0.08 * K, 0.06 * K, h, POST)
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	for k in segs + 1:
		var c: Vector3 = centre[k] + Vector3(0, -rad * 0.72, 0)
		left.append(_at(c + Vector3(0, 0, -rad * 0.62)))
		right.append(_at(c + Vector3(0, 0, rad * 0.62)))
	flow.strip(left, right, Color(WATER, 0.9), length / 1.4, true)
	glows.glow(_at(centre[segs] + Vector3(0, -0.2, 0)), 1.2 * K, Color("#DFF8FF", 0.7))


## Two portal rings, each between standing stones, and the light in them.
func _rift(g: Geo, glows: UniversePaint, light: UniversePaint) -> void:
	var ring_col := colour.lerp(Color.WHITE, 0.3)
	for u: float in [0.0, 1.0]:
		var c := Vector3(u * length, y_at(u, 0.0) + 0.9 * K, 0)
		_torus(g, c, 0.62 * K, 0.08 * K, Color(ring_col, 0.5 if open else 1.0))
		for s: float in [-1.0, 1.0]:
			g.box(_place(c + Vector3(0, -0.1 * K, s * 0.72 * K)), Vector3(0.14 * K, 1.7 * K, 0.14 * K),
				Color("#3A2E5A"))
		if open:
			light.disc(_at(c), xf.basis * Vector3.RIGHT, 0.56 * K, Color(colour, 0.55))
			glows.glow(_at(c), 3.0 * K * 0.5, Color(colour, 0.6))


## A ring standing across the link (its axis along x), as quads.
func _torus(g: Geo, c: Vector3, r: float, tube: float, col: Color) -> void:
	var segs := 18
	var sides := 5
	var at := func(i: int, j: int) -> Vector3:
		var a := TAU * i / segs
		var b := TAU * j / sides
		var ring_dir := Vector3(0, cos(a), sin(a))
		return _at(c + ring_dir * (r + cos(b) * tube) + Vector3(sin(b) * tube, 0, 0))
	for i in segs:
		for j in sides:
			g.quad(at.call(i, j), at.call(i + 1, j), at.call(i + 1, j + 1), at.call(i, j + 1), col)


## The rift's stream: where its light runs, for the map to move each frame.
func stream() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for k in 25:
		var u := k / 24.0
		out.append(_at(Vector3(u * length, y_at(u, 1.6 * K) + 0.9 * K, 0)))
	return out
