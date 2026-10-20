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
const HEIGHT := 1.72
## How strongly the crown glows: a vertex alpha under 1 glows in its colour
## (toon.gdshader's and law_fx_solid's `glow_from_alpha`).
const GLOW := 0.6

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
	g.prism(Geo.place(Vector3(0, -0.34, 0)), 8, 0.2, 0.24, 0.07, deep)
	match school:
		"matter":
			# A cube on its corner.
			var b := Basis(Vector3.FORWARD, PI / 4.0) * Basis(Vector3.RIGHT, atan(1.0 / sqrt(2.0)))
			g.box(Transform3D(b, Vector3.ZERO), Vector3(0.34, 0.34, 0.34), main, Color(pair[0].lightened(0.35), 1.0 - GLOW))
		"time":
			# An hourglass: two cones point to point between two caps.
			g.prism(Geo.place(Vector3(0, -0.24, 0)), 8, 0.2, 0.2, 0.05, deep)
			g.prism(Geo.place(Vector3(0, -0.19, 0)), 8, 0.17, 0.03, 0.19, main, true)
			g.prism(Geo.place(Vector3(0, 0.19, 0)), 8, 0.17, 0.03, -0.19, main, true)
			g.prism(Geo.place(Vector3(0, 0.19, 0)), 8, 0.2, 0.2, 0.05, deep)
		"energy":
			# A bolt: three slanted bars in a zigzag.
			g.box(Transform3D(Basis(Vector3.FORWARD, -0.5), Vector3(0.05, 0.17, 0)), Vector3(0.11, 0.26, 0.1), main)
			g.box(Transform3D(Basis(Vector3.FORWARD, 1.05), Vector3(0.0, 0.0, 0)), Vector3(0.1, 0.24, 0.1), main)
			g.box(Transform3D(Basis(Vector3.FORWARD, -0.5), Vector3(-0.06, -0.17, 0)), Vector3(0.11, 0.26, 0.1), main)
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
			# Motion's chevron: two bars meeting in a point, upward.
			g.box(Transform3D(Basis(Vector3.FORWARD, -0.72), Vector3(-0.11, 0.0, 0)), Vector3(0.12, 0.36, 0.12), main)
			g.box(Transform3D(Basis(Vector3.FORWARD, 0.72), Vector3(0.11, 0.0, 0)), Vector3(0.12, 0.36, 0.12), main)
	return g.mesh()
