class_name KitMap
extends RefCounted
## §10.1's buildings for the universe map, as the design's `makeB` draws its
## lighter map versions (realm-diorama.js :756–880): each kind its §21.5
## silhouette in a handful of solids, 80–250 triangles, so seven realms of
## buildings stay inside §21.3's budget. They read by kind from far away (a
## cottage with a chimney, a barn, a well under its roof, a domed strongbox,
## a tower in rings) and by §21.5's look: thatch and rough stone at levels
## 1–3, the realm's roof with a band of its colour at 4–6, white walls, lilac
## roofs and a gold finial at 7–9, a glowing crown at 10; a flag from level 3.
## Reached through `BuildingKit.build_map`.

var g: Geo
var origin := Vector3.ZERO
var unit := 1.8
var level := 1
var wall := Color.WHITE
var roof := Color.WHITE
var trim := Color.WHITE
var stone := Color.WHITE
var accent := Color.WHITE
## How tall the building stands, in units, for its finial and crown.
var top := 1.0


## `kind` on `mid`, `size` metres across, at `lvl`, in `look`'s colours
## (wall, roof, trim: BuildingKit's).
static func build(geo: Geo, kind: String, mid: Vector3, size: float, lvl: int, colours: Dictionary,
		look: Array[Color]) -> void:
	var m := KitMap.new()
	m.g = geo
	m.origin = mid
	m.unit = size
	m.level = lvl
	m.wall = look[0]
	m.roof = look[1]
	m.trim = look[2]
	var style := KitStyle.of(KitStyle.realm_of(colours))
	m.stone = Color("#F2EEF8") if lvl >= 7 else (style["stone"] as Color)
	if lvl < 4:
		m.stone = (colours["rock"] as Color).lerp(m.stone, 0.55)
	m.accent = style["accent"]
	m._kind(kind)
	m._look_marks(kind)


func _at(x: float, y: float, z: float) -> Vector3:
	return origin + Vector3(x, y, z) * unit


func _box(w: float, h: float, d: float, col: Color, x: float, y: float, z: float, yaw := 0.0) -> void:
	g.box(Geo.place(_at(x, y + h / 2.0, z), yaw), Vector3(w, h, d) * unit, col)


func _cyl(r0: float, r1: float, h: float, col: Color, x: float, y: float, z: float, sides := 8) -> void:
	g.prism(Geo.place(_at(x, y, z), PI / sides), sides, r0 * unit, r1 * unit, h * unit, col)


## A gable roof `w` wide, `d` deep, on eaves at `y`, rising `rise`: two
## slopes and the end walls in the house's plaster.
func _gable(w: float, d: float, y: float, rise: float, yaw := 0.0) -> void:
	var turn := Basis(Vector3.UP, yaw)
	var hw := (w / 2.0 + 0.06) * unit
	var hd := (d / 2.0 + 0.06) * unit
	var o := _at(0, y, 0)
	var r := Vector3(0, rise * unit, 0)
	var p := func(x: float, z: float) -> Vector3: return o + turn * Vector3(x, 0, z)
	var ridge0: Vector3 = o + turn * Vector3(0, 0, -hd) + r
	var ridge1: Vector3 = o + turn * Vector3(0, 0, hd) + r
	g.quad(p.call(-hw, hd), ridge1, ridge0, p.call(-hw, -hd), roof)
	g.quad(p.call(hw, -hd), ridge0, ridge1, p.call(hw, hd), roof.darkened(0.12))
	g.gable(Transform3D(turn, o), w * unit, rise * unit, d * unit, wall)


## The kind's own silhouette.
func _kind(kind: String) -> void:
	match kind:
		"keeper_s_spire":
			_cyl(0.5, 0.52, 0.12, stone.darkened(0.1), 0, 0, 0, 8)
			_cyl(0.3, 0.24, 1.4, wall.lightened(0.1), 0, 0.12, 0, 8)
			_cyl(0.34, 0.3, 0.08, roof, 0, 0.8, 0, 8)
			_cyl(0.3, 0.0, 0.7, roof, 0, 1.52, 0, 8)
			g.torus(Geo.place(_at(0, 1.0, 0)), 0.4 * unit, 0.02 * unit, KitStyle.GOLD, 10, 3)
			top = 2.2
		"vault":
			_box(0.86, 0.38, 0.72, stone, 0, 0, 0)
			_box(0.9, 0.04, 0.76, KitStyle.GOLD, 0, 0.38, 0)
			g.ball(Geo.place(_at(0, 0.42, 0), 0.0, Vector3(1, 0.8, 0.9)), 0.34 * unit, roof, 3, 8, true)
			_box(0.2, 0.24, 0.02, KitStyle.GOLD, 0, 0.06, 0.37)
			top = 0.75
		"anchor_stone":
			_cyl(0.4, 0.42, 0.05, stone.darkened(0.15), 0, 0, 0, 6)
			g.prism(Geo.place(_at(0, 0.05, 0), 0.3), 5, 0.2 * unit, 0.12 * unit, 1.0 * unit, Color("#9C98A8"))
			g.prism(Geo.place(_at(0, 1.05, 0), 0.3), 5, 0.12 * unit, 0.0, 0.16 * unit, Color("#ACA8B8"))
			_box(0.12, 0.12, 0.02, KitStyle.lit(accent.lightened(0.2), 0.3), 0, 0.45, 0.17)
			top = 1.2
		"star_well":
			_cyl(0.4, 0.42, 0.34, stone, 0, 0, 0, 8)
			_cyl(0.32, 0.32, 0.02, KitStyle.lit(Color("#FFE08F"), 0.3), 0, 0.34, 0, 8)
			for x: float in [-0.34, 0.34]:
				_box(0.06, 0.7, 0.06, KitStyle.WOOD, x, 0.34, 0)
			_gable(0.62, 0.36, 1.0, 0.26, PI / 2.0)
			top = 1.3
		"aether_spring":
			var teal := Color("#4E8E94")
			_cyl(0.48, 0.5, 0.16, teal.darkened(0.1), 0, 0, 0, 8)
			_cyl(0.42, 0.42, 0.01, KitStyle.lit(Color("#5FE6F0"), 0.6), 0, 0.16, 0, 8)
			_cyl(0.08, 0.1, 0.5, teal, 0, 0.16, 0, 6)
			_cyl(0.18, 0.26, 0.08, teal, 0, 0.62, 0, 8)
			g.ball(Geo.place(_at(0, 0.82, 0)), 0.08 * unit, KitStyle.lit(Color("#5FE6F0"), 0.6), 2, 6)
			top = 0.95
		"garden":
			_box(0.86, 0.14, 0.62, KitStyle.WOOD.lightened(0.15), 0, 0, 0)
			for i in 3:
				_cyl(0.06, 0.0, 0.18, Color("#4FAF55"), -0.26 + 0.26 * i, 0.14, 0, 5)
			if level >= 4:
				_box(0.82, 0.3, 0.58, Color(Color("#D8F4EC"), 0.85), 0, 0.14, 0)
				_gable(0.82, 0.58, 0.44, 0.2)
			top = 0.7
		"storehouse":
			_box(0.92, 0.5, 0.72, KitStyle.WOOD.lightened(0.28) if level < 4 else wall, 0, 0, 0)
			_gable(0.92, 0.72, 0.5, 0.36)
			_box(0.34, 0.36, 0.02, KitStyle.WOOD, 0, 0, 0.37)
			top = 0.9
		"law_pylon":
			g.prism(Geo.place(_at(0, 0, 0), PI / 4.0), 4, 0.3 * unit, 0.26 * unit, 0.14 * unit, stone.darkened(0.15))
			g.prism(Geo.place(_at(0, 0.14, 0), PI / 4.0), 4, 0.15 * unit, 0.08 * unit, 0.9 * unit, stone)
			g.gem(Geo.place(_at(0, 1.2, 0)), 0.1 * unit, 0.14 * unit, KitStyle.lit(accent, 0.3), 4)
			top = 1.35
		"nursery":
			_cyl(0.42, 0.42, 0.1, Color("#C49A5A"), 0, 0, 0, 8)
			g.ball(Geo.place(_at(0, 0.1, 0), 0.0, Vector3(1, 1.35, 1)), 0.4 * unit, Color(Color("#E2F6F0"), 0.85), 3, 8,
				true)
			top = 0.7
		"guardian_post":
			_cyl(0.36, 0.4, 0.12, stone.darkened(0.1), 0, 0, 0, 6)
			_cyl(0.26, 0.2, 0.95, stone if level >= 4 else KitStyle.WOOD.lightened(0.2), 0, 0.12, 0, 6)
			_cyl(0.36, 0.32, 0.06, KitStyle.WOOD, 0, 1.07, 0, 6)
			_cyl(0.42, 0.0, 0.42, roof, 0, 1.13, 0, 6)
			_box(0.08, 0.1, 0.08, KitStyle.lit(Color("#FFD27A"), 0.3), 0.34, 0.95, 0.1)
			top = 1.55
		"ward":
			_cyl(0.4, 0.4, 0.04, Color("#2A2350"), 0, 0, 0, 8)
			g.gem(Geo.place(_at(0, 0.36, 0)), 0.1 * unit, 0.14 * unit, KitStyle.lit(accent.lightened(0.3), 0.4), 4)
			top = 0.6
		"library":
			_cyl(0.44, 0.42, 0.5, stone if level < 4 else wall, 0, 0, 0, 8)
			_cyl(0.42, 0.3, 0.06, roof, 0, 0.5, 0, 8)
			_cyl(0.28, 0.18, 0.2, KitStyle.lit(Color("#DDF4FF"), 0.45), 0, 0.56, 0, 8)
			_cyl(0.22, 0.0, 0.22, roof, 0, 0.76, 0, 8)
			top = 1.0
		"resonance_lab":
			_box(0.7, 0.42, 0.56, stone if level < 4 else wall, -0.1, 0, -0.06)
			_gable(0.7, 0.56, 0.42, 0.26)
			for z: float in [0.22, -0.26]:
				g.ball(Geo.place(_at(0.36, 0.4, z)), 0.12 * unit, Color(Color("#DDF4FF"), 0.6), 2, 6)
			top = 0.8
		"observatory":
			_cyl(0.42, 0.42, 0.5, stone, 0, 0, 0, 8)
			g.ball(Geo.place(_at(0, 0.5, 0)), 0.4 * unit, Color("#5E6A7A") if level < 7 else Color("#B9A6F2"), 3, 8, true)
			g.box(Transform3D(Basis(Vector3.RIGHT, -0.9), _at(0, 0.8, -0.1)), Vector3(0.12, 0.12, 0.5) * unit,
				Color("#C87A4A") if level < 7 else KitStyle.GOLD)
			top = 0.95
		"beacon":
			_cyl(0.3, 0.26, 0.5, stone, 0, 0, 0, 6)
			_cyl(0.14, 0.08, 1.0, KitStyle.IRON if level < 7 else KitStyle.GOLD, 0, 0.5, 0, 4)
			_box(0.2, 0.2, 0.2, KitStyle.lit(Color("#FFE7A8"), 0.15), 0, 1.5, 0)
			_cyl(0.18, 0.0, 0.16, roof, 0, 1.7, 0, 4)
			top = 1.9
		"visitor_s_dock":
			_box(0.9, 0.04, 0.5, KitStyle.WOOD.lightened(0.3), 0, 0.16, 0.1)
			_box(0.32, 0.26, 0.26, KitStyle.WOOD.lightened(0.15) if level < 4 else wall, -0.26, 0, -0.26)
			_gable(0.32, 0.26, 0.26, 0.14)
			var mast := _at(0.25, 0.2, 0.25)
			g.tri(mast + Vector3(0, 0.5, 0) * unit, mast + Vector3(0, 0.05, 0.2) * unit, mast, Color("#F4EEDF"))
			g.tri(mast + Vector3(0, 0.5, 0) * unit, mast, mast + Vector3(0, 0.05, 0.2) * unit, Color("#E4DECF"))
			top = 0.7
		_:
			# The Hearth: a cottage, its roof and chimney.
			_box(0.82, 0.4, 0.66, stone if level < 4 else wall, 0, 0, 0)
			if level >= 4:
				_box(0.86, 0.04, 0.7, KitStyle.WOOD, 0, 0.4, 0)
				_box(0.86, 0.3, 0.7, wall, 0, 0.44, 0)
			var eave := 0.74 if level >= 4 else 0.4
			_gable(0.86, 0.7, eave, 0.4)
			_box(0.13, 0.36, 0.13, stone.darkened(0.2), 0.24, eave, -0.16)
			_box(0.14, 0.18, 0.02, KitStyle.WOOD, 0, 0, 0.335)
			top = eave + 0.4


## §21.5's look on top: a band of the realm's colour from level 4, a gold
## finial from 7, a glowing crown at 10, a flag from 3.
func _look_marks(kind: String) -> void:
	if level >= 4 and level < 7:
		_cyl(0.08, 0.0, 0.14, accent, 0, top, 0, 4)
	if level >= 7:
		g.gem(Geo.place(_at(0, top + 0.08, 0)), 0.05 * unit, 0.1 * unit, KitStyle.GOLD, 4)
	if level >= 10:
		g.gem(Geo.place(_at(0, top + 0.36, 0)), 0.1 * unit, 0.14 * unit, KitStyle.lit(Color("#FFF1C4"), 0.3), 4)
	if level >= 3 and not kind in ["ward", "law_pylon", "anchor_stone", "keeper_s_spire"]:
		var pole := _at(-0.36, 0, -0.26)
		g.box(Geo.place(pole + Vector3(0, top * 0.5, 0) * unit), Vector3(0.02, top, 0.02) * unit, KitStyle.IRON)
		var tip := pole + Vector3(0, top, 0) * unit
		g.tri(tip, tip + Vector3(0.24, -0.06, 0) * unit, tip + Vector3(0, -0.14, 0) * unit, accent)
		g.tri(tip, tip + Vector3(0, -0.14, 0) * unit, tip + Vector3(0.24, -0.06, 0) * unit, accent.darkened(0.1))
