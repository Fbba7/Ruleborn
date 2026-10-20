class_name LawFxCrown
extends RefCounted
## A pylon's crown (§21.2: each school's shape appears on "Pylon crowns"):
## Motion's chevron, Matter's cube, Time's hourglass, Energy's bolt, Life's
## leaf and Spirit's eye, in the school's colour with its shadow tint, lit
## from within so it reads by day and in Glowing dark's black. About half a
## metre across, so it reads as a dark shape at 32 points (§21.1). The pylon
## (PieceKit.pylon) stands 1.4 m; the crown floats just over it.
##
## `mesh` is static and needs nothing but the school, so PieceKit can crown
## its own pylons with it.

## Where the crown's middle floats over the pylon's foot.
const HEIGHT := 1.82
## How strongly the crown glows: a vertex alpha under 1 glows in its colour
## (toon.gdshader's and law_fx_solid's `glow_from_alpha`).
const GLOW := 0.35

static var _cache := {}


static func mesh(school: String) -> ArrayMesh:
	var key := school.to_lower()
	if not _cache.has(key):
		_cache[key] = _build(key)
	return _cache[key]


static func colours(school: String) -> Array[Color]:
	match school.to_lower():
		"matter":
			return [Palette.MATTER, Color("#5A3FB0")]
		"time":
			return [Palette.TIME, Color("#1F8499")]
		"energy":
			return [Palette.ENERGY, Color("#B04A1E")]
		"life":
			return [Palette.LIFE, Color("#2F8A45")]
		"spirit":
			return [Palette.SPIRIT, Color("#9C3380")]
	return [Palette.MOTION, Color("#B8741E")]


static func _build(school: String) -> ArrayMesh:
	var g := Geo.new()
	var pair := colours(school)
	var main := Color(pair[0].lightened(0.1), 1.0 - GLOW)
	var deep := Color(pair[1], 0.85)
	# A collar under every crown: the pylon's cap, ringed in the school.
	g.prism(Geo.place(Vector3(0, -0.3, 0)), 8, 0.13, 0.16, 0.05, deep)
	match school:
		"matter":
			# A cube on its corner.
			var b := Basis(Vector3.FORWARD, PI / 4.0) * Basis(Vector3.RIGHT, atan(1.0 / sqrt(2.0)))
			g.box(Transform3D(b, Vector3.ZERO), Vector3(0.34, 0.34, 0.34), main, Color(pair[0].lightened(0.35), 1.0 - GLOW))
		"time":
			# An hourglass: two cones point to point between two caps.
			g.prism(Geo.place(Vector3(0, -0.25, 0)), 8, 0.15, 0.15, 0.04, deep)
			g.prism(Geo.place(Vector3(0, -0.21, 0)), 8, 0.14, 0.025, 0.21, main, true)
			g.prism(Geo.place(Vector3(0, 0.21, 0)), 8, 0.14, 0.025, -0.21, main, true)
			g.prism(Geo.place(Vector3(0, 0.21, 0)), 8, 0.15, 0.15, 0.04, deep)
			for x: float in [-0.12, 0.12]:
				g.box(Geo.place(Vector3(x, 0, 0)), Vector3(0.025, 0.44, 0.025), deep)
		"energy":
			# A bolt: a zigzag struck down.
			extrude(g, PackedVector2Array([Vector2(-0.02, 0.3), Vector2(0.15, 0.3), Vector2(0.05, 0.07),
				Vector2(0.15, 0.07), Vector2(-0.1, -0.32), Vector2(-0.02, -0.05), Vector2(-0.13, -0.05)]), 0.1, main)
		"life":
			# A leaf: a pointed blade with its midrib, leaning.
			var lean := Basis(Vector3.FORWARD, 0.35)
			g.ball(Transform3D(lean.scaled(Vector3(0.62, 1.25, 0.28)), Vector3(0, 0.02, 0)), 0.22, main, 5, 8)
			g.box(Transform3D(lean, Vector3(0, 0.0, 0.05)), Vector3(0.03, 0.42, 0.03), deep)
		"spirit":
			# An eye: an almond with its dark pupil, looking both ways.
			g.ball(Geo.place(Vector3.ZERO, 0.0, Vector3(1.35, 0.72, 0.5)), 0.22, main, 5, 10)
			g.ball(Geo.place(Vector3(0, 0, 0.08)), 0.085, Palette.INK, 3, 8)
			g.ball(Geo.place(Vector3(0, 0, -0.08)), 0.085, Palette.INK, 3, 8)
			g.ball(Geo.place(Vector3(0.03, 0.03, 0.15)), 0.025, Color(1, 1, 1, 0.3), 2, 6)
		_:
			# Motion's chevron: a point, upward.
			extrude(g, PackedVector2Array([Vector2(0, 0.24), Vector2(0.26, -0.04), Vector2(0.26, -0.18),
				Vector2(0, 0.08), Vector2(-0.26, -0.18), Vector2(-0.26, -0.04)]), 0.12, main)
	return g.mesh()


## A flat outline `poly` (x right, y up) stood upright and given `depth`.
static func extrude(g: Geo, outline: PackedVector2Array, depth: float, col: Color) -> void:
	var poly := outline.duplicate()
	if Geometry2D.is_polygon_clockwise(poly):
		poly.reverse()
	var tris := Geometry2D.triangulate_polygon(poly)
	var z := depth / 2.0
	for k in range(0, tris.size(), 3):
		var a := poly[tris[k]]
		var b := poly[tris[k + 1]]
		var c := poly[tris[k + 2]]
		g.tri(Vector3(a.x, a.y, z), Vector3(b.x, b.y, z), Vector3(c.x, c.y, z), col, Vector3.BACK)
		g.tri(Vector3(a.x, a.y, -z), Vector3(c.x, c.y, -z), Vector3(b.x, b.y, -z), col, Vector3.FORWARD)
	var n := poly.size()
	for k in n:
		var a := poly[k]
		var b := poly[(k + 1) % n]
		var out := Vector3(b.y - a.y, a.x - b.x, 0).normalized()
		g.tri(Vector3(a.x, a.y, z), Vector3(a.x, a.y, -z), Vector3(b.x, b.y, -z), col.darkened(0.12), out)
		g.tri(Vector3(a.x, a.y, z), Vector3(b.x, b.y, -z), Vector3(b.x, b.y, z), col.darkened(0.12), out)
