class_name BuildingKit
extends RefCounted
## §10.1's buildings on their footprints, each kind with its own shape, in
## §21.5's four looks by level: "levels 1 to 3 in wood and rough stone, 4 to
## 6 in dressed stone with school-coloured trims, 7 to 9 in crystal and gold
## filigree, and a unique crown piece at level 10". Built in code from the
## designs' description until their models arrive (TD.7, TD.32); the
## footprint and the tile are the island's, so where a building stands is
## never the art's to decide.


## The materials of a level's look: walls, roof, trim.
static func look(level: int, palette: Dictionary) -> Array[Color]:
	if level >= 7:
		return [Color("#DCD2FF"), Color("#B9A6F2"), Palette.MOTION]
	if level >= 4:
		return [palette["stone"].lightened(0.12), palette["trim"].darkened(0.05), palette["trim"]]
	return [Palette.WOOD.lightened(0.25), Palette.WOOD.darkened(0.2), palette["rock"]]


## Building `kind` of `side` tiles a side, centred on `mid` on the ground.
static func build(g: Geo, kind: String, mid: Vector3, side: int, level: int, palette: Dictionary) -> void:
	var c := look(level, palette)
	var wall := c[0]
	var roof := c[1]
	var trim := c[2]
	var w := side - 0.32
	var glow := Color(palette["accent"], 0.0)
	match kind:
		"keeper_s_spire":
			g.prism(Geo.place(mid), 8, w * 0.48, w * 0.36, 0.6, wall.darkened(0.08))
			g.prism(Geo.place(mid + Vector3(0, 0.6, 0)), 8, w * 0.3, w * 0.22, 2.4, wall)
			g.prism(Geo.place(mid + Vector3(0, 3.0, 0)), 8, w * 0.28, 0.0, 1.4, roof)
			g.ball(Geo.place(mid + Vector3(0, 4.5, 0)), 0.2, glow, 3, 7)
		"vault":
			g.box(Geo.place(mid + Vector3(0, 0.5, 0)), Vector3(w, 1.0, w * 0.86), wall.darkened(0.1), trim)
			for x: float in [-0.33, 0.0, 0.33]:
				g.box(Geo.place(mid + Vector3(x * w, 0.5, 0)), Vector3(0.12, 1.02, w * 0.88), trim)
		"star_well":
			g.prism(Geo.place(mid), 10, w * 0.35, w * 0.35, 0.5, wall)
			g.ring(Geo.place(mid + Vector3(0, 0.51, 0)), 0.0, w * 0.28, Color(Palette.TIME.lightened(0.2), 0.0), 12)
			for x: float in [-1.0, 1.0]:
				g.box(Geo.place(mid + Vector3(x * w * 0.3, 0.9, 0)), Vector3(0.1, 0.9, 0.1), roof)
			g.box(Geo.place(mid + Vector3(0, 1.35, 0)), Vector3(w * 0.7, 0.08, 0.12), roof)
		"aether_spring":
			g.prism(Geo.place(mid), 8, w * 0.42, w * 0.36, 0.3, wall)
			g.prism(Geo.place(mid + Vector3(0, 0.3, 0)), 6, 0.14, 0.0, 1.0, Color(Palette.SPIRIT.lightened(0.3), 0.0))
		"garden":
			for k in 4:
				var o := Vector3((k % 2 - 0.5) * w * 0.5, 0, (k / 2 - 0.5) * w * 0.5)
				g.box(Geo.place(mid + o + Vector3(0, 0.15, 0)), Vector3(w * 0.4, 0.3, w * 0.4), roof, palette["soil"])
				g.ball(Geo.place(mid + o + Vector3(0, 0.42, 0)), 0.2, palette["plant"], 3, 6)
		"storehouse":
			g.box(Geo.place(mid + Vector3(0, 0.55, 0)), Vector3(w, 1.1, w * 0.8), wall)
			g.prism(Transform3D(Basis(Vector3.UP, PI / 4.0), mid + Vector3(0, 1.1, 0)), 4, w * 0.72, 0.0, 0.7, roof)
			g.box(Geo.place(mid + Vector3(0, 0.4, w * 0.4)), Vector3(w * 0.4, 0.7, 0.04), trim)
		"nursery":
			g.prism(Geo.place(mid), 10, w * 0.44, w * 0.4, 0.8, wall, true)
			g.ball(Geo.place(mid + Vector3(0, 0.8, 0), 0.0, Vector3(1.0, 0.7, 1.0)), w * 0.44, roof, 4, 10)
			g.ball(Geo.place(mid + Vector3(0, 1.4, 0), 0.0, Vector3(0.8, 1.0, 0.8)), 0.2, Palette.PAPER, 3, 7)
		"guardian_post":
			g.prism(Geo.place(mid), 6, w * 0.32, w * 0.26, 1.8, wall)
			g.prism(Geo.place(mid + Vector3(0, 1.8, 0)), 6, w * 0.38, 0.0, 0.7, roof)
			g.box(Geo.place(mid + Vector3(0, 1.3, -w * 0.3)), Vector3(0.24, 0.3, 0.06), glow)
		"library":
			g.box(Geo.place(mid + Vector3(0, 0.6, 0)), Vector3(w, 1.2, w * 0.75), wall)
			g.prism(Transform3D(Basis(Vector3.UP, PI / 4.0), mid + Vector3(0, 1.2, 0)), 4, w * 0.7, 0.0, 0.8, roof)
			for x: float in [-0.25, 0.25]:
				g.box(Geo.place(mid + Vector3(x * w, 0.75, w * 0.38)), Vector3(0.2, 0.3, 0.03), glow)
		"resonance_lab":
			g.prism(Geo.place(mid), 8, w * 0.42, w * 0.4, 0.9, wall)
			g.prism(Geo.place(mid + Vector3(0, 0.9, 0)), 4, 0.12, 0.0, 1.0, Palette.MATTER.lightened(0.2))
			g.ring(Geo.place(mid + Vector3(0, 1.3, 0)), w * 0.2, w * 0.26, trim, 14)
		"observatory":
			g.prism(Geo.place(mid), 10, w * 0.44, w * 0.42, 0.9, wall)
			g.ball(Geo.place(mid + Vector3(0, 0.9, 0), 0.0, Vector3(1.0, 0.8, 1.0)), w * 0.42, roof, 4, 10)
			g.box(Transform3D(Basis(Vector3.RIGHT, -0.7), mid + Vector3(0, 1.3, -0.2)), Vector3(0.18, 0.18, 0.9), trim)
		"beacon":
			g.prism(Geo.place(mid), 6, w * 0.3, w * 0.22, 2.2, wall)
			g.ball(Geo.place(mid + Vector3(0, 2.45, 0)), 0.32, Color(Palette.ENERGY.lightened(0.2), 0.0), 3, 8)
		"visitor_s_dock":
			g.box(Geo.place(mid + Vector3(0, 0.12, 0)), Vector3(w, 0.24, w * 0.5), roof)
			for x: float in [-0.4, 0.4]:
				g.box(Geo.place(mid + Vector3(x * w, 0.6, 0)), Vector3(0.1, 1.2, 0.1), roof.darkened(0.2))
			g.box(Geo.place(mid + Vector3(0, 1.0, 0)), Vector3(w * 0.4, 0.5, 0.04), trim.lightened(0.2))
		"anchor_stone":
			g.prism(Geo.place(mid, 0.3), 5, w * 0.24, w * 0.16, 1.5, palette["rock"].lightened(0.1))
			g.ring(Geo.place(mid + Vector3(0, 0.03, 0)), w * 0.3, w * 0.38, Color(Palette.MATTER, 0.0), 16)
		_:
			# The Hearth, and anything not drawn yet: a house with a chimney.
			g.box(Geo.place(mid + Vector3(0, 0.5, 0)), Vector3(w, 1.0, w * 0.8), wall)
			g.prism(Transform3D(Basis(Vector3.UP, PI / 4.0), mid + Vector3(0, 1.0, 0)), 4, w * 0.72, 0.0, 0.75, roof)
			g.box(Geo.place(mid + Vector3(w * 0.25, 1.3, 0)), Vector3(0.2, 0.6, 0.2), palette["rock"])
			g.box(Geo.place(mid + Vector3(0, 0.3, w * 0.4)), Vector3(0.28, 0.6, 0.04), trim)
			g.box(Geo.place(mid + Vector3(-w * 0.25, 0.6, w * 0.4)), Vector3(0.22, 0.2, 0.03), glow)
	# §21.5's crown piece at level 10.
	if level >= 10:
		var top := 2.2 if kind != "keeper_s_spire" else 4.8
		g.prism(Geo.place(mid + Vector3(0, top, 0)), 5, 0.28, 0.0, 0.32, Palette.MOTION)
