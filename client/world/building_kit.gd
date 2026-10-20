class_name BuildingKit
extends RefCounted
## §10.1's buildings on their footprints, each kind with §21.5's silhouette
## and §21.5's four looks by level: "levels 1 to 3 in wood and rough stone, 4
## to 6 in dressed stone with school-coloured trims, 7 to 9 in crystal and
## gold filigree, and a unique crown piece at level 10". Ported from the
## design's realm-view houses (Screens v3, realm-diorama.js `makeB2`/`makeB`,
## :691–880: timber frames, shingled roofs, shuttered windows, arched doors,
## the well's wheel, the loom's wheel, the greenhouse) and its `dress`
## (:981–987: a lamp post, a flag from level 3, banners and a finial from
## level 6), in its own units (a house about one unit across) scaled to the
## footprint. The footprint and the tile are the island's, so where a
## building stands is never the art's to decide.
##
## Parts that move carry their motion (Geo.Anim): wheels turn, flags
## flutter, smoke and crystals drift. Each kind's second half (the kinds
## that are not houses) is KitBuildings2's.

## §10.1's buildings, by content id (content/buildings.json).
const KINDS := ["keeper_s_spire", "vault", "anchor_stone", "star_well", "aether_spring", "garden", "storehouse",
	"law_pylon", "hearth", "nursery", "guardian_post", "ward", "library", "resonance_lab", "observatory", "beacon",
	"visitor_s_dock"]
## The level that opens each of §21.5's looks.
const LOOKS := [1, 4, 7, 10]

var g: Geo
## The fine parts — windows, frames, rings, flags — drawn without ink, so a
## thin part never turns to a black line at phone size.
var d: Geo
## Glass — a greenhouse, the Nursery's egg, the Lab's spheres — drawn
## see-through, so what grows inside shows.
var glass: Geo
## The building's place: its footprint's middle on the ground, and the
## design's unit in metres.
var origin := Vector3.ZERO
var unit := 1.8
var level := 1
## §21.5's look: 0 wood and rough stone, 1 dressed stone, 2 crystal and gold.
var tier := 0
var style: Dictionary = {}
var palette: Dictionary = {}
var wall := Color.WHITE
var roof_col := Color.WHITE
var roof_dark := Color.WHITE
var stone := Color.WHITE
var stone2 := Color.WHITE
var trim := Color.WHITE
## How tall the building stands, in units, for its dress.
var top := 1.0


## The materials of a level's look: walls, roof, trim.
static func look(lvl: int, colours: Dictionary) -> Array[Color]:
	var s := KitStyle.of(KitStyle.realm_of(colours))
	if lvl >= 7:
		return [Color("#ECE6FF"), (s["roof"] as Color).lerp(Color("#8C6CF0"), 0.35).lightened(0.1), KitStyle.GOLD]
	if lvl >= 4:
		return [s["wall"], s["roof"], s["accent"]]
	return [(s["wall"] as Color).lerp(Color("#E8D4B0"), 0.5), KitStyle.THATCH, KitStyle.WOOD]


## Building `kind` of `side` tiles a side, centred on `mid` on the ground,
## at `lvl` (1 to 10), its door turned `yaw` from +Z (quarter turns).
static func build(geo: Geo, kind: String, mid: Vector3, side: int, lvl: int, colours: Dictionary,
		details: Geo = null, panes: Geo = null, yaw := 0.0) -> void:
	if absf(yaw) > 0.01:
		var tg := Geo.new()
		var td := Geo.new()
		var tp := Geo.new()
		for t: Geo in [tg, td, tp]:
			t.skip_down = geo.skip_down
		build(tg, kind, Vector3.ZERO, side, lvl, colours, td, tp)
		var xf := Transform3D(Basis(Vector3.UP, yaw), mid)
		geo.absorb(tg, xf)
		(details if details != null else geo).absorb(td, xf)
		(panes if panes != null else (details if details != null else geo)).absorb(tp, xf)
		return
	var b := BuildingKit.new()
	b.g = geo
	b.d = details if details != null else geo
	b.glass = panes if panes != null else b.d
	for layer: Geo in [b.g, b.d, b.glass]:
		layer.standing(mid.y)
	b.origin = mid
	b.level = clampi(lvl, 1, 10)
	b.tier = 2 if b.level >= 7 else (1 if b.level >= 4 else 0)
	b.palette = colours
	b.style = KitStyle.of(KitStyle.realm_of(colours))
	b.unit = side * 0.92
	var c := look(b.level, colours)
	b.wall = c[0]
	b.roof_col = c[1]
	b.roof_dark = b.roof_col.darkened(0.22)
	b.trim = c[2]
	b.stone = b.style["stone"]
	b.stone2 = b.style["stone2"]
	if b.tier == 0:
		b.stone = (colours["rock"] as Color).lerp(b.stone, 0.55)
		b.stone2 = b.stone.darkened(0.18)
	elif b.tier == 2:
		b.stone = Color("#F2EEF8")
		b.stone2 = Color("#C9C0E6")
	if not kind in ["ward", "law_pylon", "anchor_stone", "keeper_s_spire", "visitor_s_dock"]:
		b._pad()
	match kind:
		"hearth":
			b._hearth()
		"storehouse":
			b._storehouse()
		"library":
			b._library()
		"star_well":
			b._star_well()
		"garden":
			b._garden()
		"guardian_post":
			b._guard()
		_:
			KitBuildings2.build(b, kind)
	b._dress(kind)


## Shapes drawn after this move by `kind` about `pivot`, inked or not.
func move(kind: Geo.Anim, pivot: Vector3) -> void:
	g.moving(kind, pivot)
	d.moving(kind, pivot)
	glass.moving(kind, pivot)


func stop() -> void:
	g.moving(Geo.Anim.NONE, Vector3.ZERO)
	d.moving(Geo.Anim.NONE, Vector3.ZERO)
	glass.moving(Geo.Anim.NONE, Vector3.ZERO)


## The light version of building `kind` for the universe map (the design's
## `makeB`, realm-diorama.js :756–880), 80–250 triangles, reading by kind
## and by §21.5's look from far away: KitMap's.
static func build_map(geo: Geo, kind: String, mid: Vector3, side: int, lvl: int, colours: Dictionary) -> void:
	var c := look(clampi(lvl, 1, 10), colours)
	KitMap.build(geo, kind, mid, side * 0.92, clampi(lvl, 1, 10), colours, c)


## A point in the building's units, placed in the world.
func at(x: float, y: float, z: float) -> Vector3:
	return origin + Vector3(x, y, z) * unit


func place(x: float, y: float, z: float, yaw := 0.0) -> Transform3D:
	return Geo.place(at(x, y, z), yaw)


## A box `w` × `h` × `depth` units with its middle at (x, y, z), its edges
## softened when it is big enough to show them.
func box(w: float, h: float, depth: float, col: Color, x: float, y: float, z: float, yaw := 0.0) -> void:
	var size := Vector3(w, h, depth) * unit
	if minf(size.x, minf(size.y, size.z)) > 0.1:
		g.rbox(place(x, y, z, yaw), size, col, minf(0.035, minf(size.x, minf(size.y, size.z)) * 0.25))
	else:
		d.box(place(x, y, z, yaw), size, col)


## A cylinder standing on (x, y, z).
func cyl(r0: float, r1: float, h: float, col: Color, x: float, y: float, z: float, sides := 10) -> void:
	(g if maxf(r0, r1) * unit > 0.06 else d).cyl(place(x, y, z), r0 * unit, r1 * unit, h * unit, col, sides)


func cone(r: float, h: float, col: Color, x: float, y: float, z: float, sides := 10) -> void:
	(g if r * unit > 0.08 else d).prism(place(x, y, z, PI / sides), sides, r * unit, 0.0, h * unit, col)


func ball(r: float, col: Color, x: float, y: float, z: float, squash := 1.0, rings := 4, segments := 8) -> void:
	(g if r * unit > 0.08 else d).ball(Geo.place(at(x, y, z), 0.0, Vector3(1, squash, 1)), r * unit, col, rings,
		segments)


## A flat pane `w` × `h` facing `at`'s +Z, un-inked: a window's glass, a
## shutter, a mullion — two triangles where a box would take twelve.
func _pane(xf: Transform3D, w: float, h: float, col: Color) -> void:
	d.quad(xf * Vector3(-w / 2.0, -h / 2.0, 0), xf * Vector3(w / 2.0, -h / 2.0, 0), xf * Vector3(w / 2.0, h / 2.0, 0),
		xf * Vector3(-w / 2.0, h / 2.0, 0), col)


## A ring lying flat at (x, y, z), un-inked: a collar, a mooring ring.
func _torus_at(r: float, t: float, col: Color, x: float, y: float, z: float) -> void:
	d.torus(place(x, y, z), r * unit, t * unit, col, 12, 3)


## A window on a wall facing `yaw`: a frame, warm glass, mullions, a sill
## and, by default, a pair of open shutters in the roof's colour.
func window(x: float, y: float, z: float, yaw: float, s := 1.0, shutters := true) -> void:
	var turn := Basis(Vector3.UP, yaw)
	var p := func(dx: float, dy: float, dz: float) -> Vector3: return at(x, y, z) + turn * Vector3(dx, dy, dz) * unit
	d.box(Transform3D(turn, p.call(0, 0, 0)), Vector3(0.15 * s, 0.19 * s, 0.03) * unit, KitStyle.WOOD_DARK)
	_pane(Transform3D(turn, p.call(0, 0, 0.016)), 0.11 * s * unit, 0.15 * s * unit, KitStyle.lit(KitStyle.WINDOW, 0.55))
	_pane(Transform3D(turn, p.call(0, 0, 0.018)), 0.014 * unit, 0.15 * s * unit, KitStyle.WOOD_DARK)
	_pane(Transform3D(turn, p.call(0, 0, 0.019)), 0.11 * s * unit, 0.014 * unit, KitStyle.WOOD_DARK)
	d.box(Transform3D(turn, p.call(0, -0.105 * s, 0.025)), Vector3(0.19 * s, 0.025, 0.06) * unit, stone2)
	if shutters:
		for sx: float in [-1.0, 1.0]:
			var b := turn * Basis(Vector3.UP, sx * 0.35)
			_pane(Transform3D(b, p.call(sx * 0.115 * s, 0, 0.03)), 0.06 * s * unit, 0.19 * s * unit,
				roof_col if tier > 0 else KitStyle.WOOD.lightened(0.2))


## An arched door on a wall facing `yaw`, with its stone surround and step.
func door(x: float, y: float, z: float, yaw: float, s := 1.0) -> void:
	var turn := Basis(Vector3.UP, yaw)
	var p := func(dx: float, dy: float, dz: float) -> Vector3: return at(x, y, z) + turn * Vector3(dx, dy, dz) * unit
	d.box(Transform3D(turn, p.call(0, 0.1 * s, 0)), Vector3(0.21 * s, 0.2 * s, 0.03) * unit, stone2)
	d.cyl(Transform3D(turn * Basis(Vector3.RIGHT, PI / 2.0), p.call(0, 0.2 * s, -0.015)), 0.105 * s * unit,
		0.105 * s * unit, 0.03 * unit, stone2, 8)
	var wood := KitStyle.WOOD if tier < 2 else KitStyle.WOOD.lerp(Color("#8C6CF0"), 0.3)
	_pane(Transform3D(turn, p.call(0, 0.085 * s, 0.017)), 0.15 * s * unit, 0.17 * s * unit, wood)
	d.cyl(Transform3D(turn * Basis(Vector3.RIGHT, PI / 2.0), p.call(0, 0.17 * s, 0.006)), 0.075 * s * unit,
		0.075 * s * unit, 0.012 * unit, wood, 8)
	for px: float in [-0.04, 0.04]:
		_pane(Transform3D(turn, p.call(px * s, 0.1 * s, 0.019)), 0.008 * unit, 0.2 * s * unit, KitStyle.WOOD_DARK)
	d.ball(Geo.place(p.call(0.045 * s, 0.09 * s, 0.03)), 0.014 * unit, KitStyle.GOLD, 2, 4)
	d.box(Transform3D(turn, p.call(0, 0.017, 0.06)), Vector3(0.26 * s, 0.035, 0.1) * unit, stone)


## A gable roof `w` across and `depth` deep, its eaves at `y0`, rising `rise`,
## laid in rows of shingles (thatch at the first look), a round ridge and
## plaster gable ends.
func roof(w: float, depth: float, y0: float, rise: float, over := 0.08, rows := 4, yaw := 0.0) -> float:
	var run := w / 2.0 + over
	var ang := atan2(rise, w / 2.0)
	var slant := run / cos(ang)
	var turn := Basis(Vector3.UP, yaw)
	for s: float in [-1.0, 1.0]:
		for i in rows:
			var t := (i + 0.5) / rows
			var col := roof_col if i % 2 == 1 else roof_col.darkened(0.07)
			var p := at(0, 0, 0) + turn * Vector3(s * t * run, y0 + rise - t * run * tan(ang), 0) * unit
			var basis := turn * Basis(Vector3.BACK, -s * ang)
			var thick := 0.05 if tier == 0 else 0.035
			g.rbox(Transform3D(basis, p), Vector3(slant / rows * 1.2, thick, depth + over * 2.0) * unit, col, 0.012)
	g.cyl(Transform3D(turn * Basis(Vector3.RIGHT, PI / 2.0), at(0, 0, 0) + turn * Vector3(0, y0 + rise + 0.015,
		-(depth / 2.0 + over + 0.01)) * unit), 0.03 * unit, 0.03 * unit, (depth + over * 2.0 + 0.02) * unit,
		KitStyle.GOLD if tier == 2 else roof_dark, 6)
	g.gable(Transform3D(turn, at(0, y0, 0)), w * unit, rise * unit, (depth - 0.01) * unit, wall)
	return y0 + rise


## A hip roof: four shingled slopes rising from eaves `w` × `depth` at
## `y0` to a short ridge, `rise` high; reads as a roof from every side.
func _hip_roof(w: float, depth: float, y0: float, rise: float) -> float:
	var rows := 3
	for i in rows:
		var t0 := float(i) / rows
		var t1 := float(i + 1) / rows
		var col := roof_col if i % 2 == 1 else roof_dark
		var hw0 := lerpf(w / 2.0 + 0.06, 0.04, t0)
		var hd0 := lerpf(depth / 2.0 + 0.06, 0.12, t0)
		var hw1 := lerpf(w / 2.0 + 0.06, 0.04, t1)
		var hd1 := lerpf(depth / 2.0 + 0.06, 0.12, t1)
		var ya := y0 + rise * t0
		var yb := y0 + rise * t1
		var lo: Array[Vector3] = [at(-hw0, ya, -hd0), at(hw0, ya, -hd0), at(hw0, ya, hd0), at(-hw0, ya, hd0)]
		var hi: Array[Vector3] = [at(-hw1, yb, -hd1), at(hw1, yb, -hd1), at(hw1, yb, hd1), at(-hw1, yb, hd1)]
		for k in 4:
			var n := (k + 1) % 4
			var a: Vector3 = lo[k]
			var b: Vector3 = lo[n]
			var c: Vector3 = hi[n]
			var e: Vector3 = hi[k]
			if (b - a).cross(e - a).y > 0:
				g.quad(a, b, c, e, col.darkened(0.04 * (k % 2)))
			else:
				g.quad(a, e, c, b, col.darkened(0.04 * (k % 2)))
	var ridge := at(0, y0 + rise, 0)
	g.box(Geo.place(ridge), Vector3(0.1, 0.035, 0.28) * unit, KitStyle.GOLD if tier == 2 else roof_dark)
	return y0 + rise


## Timber framing round a storey: corner posts, sills, a head beam and
## braces on the front, as the design's half-timbered houses.
func frame(w: float, h: float, depth: float, y0: float) -> void:
	var c := KitStyle.WOOD if tier < 2 else KitStyle.GOLD
	for p: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		fine(0.045, h, 0.045, c, p.x * w / 2.0, y0 + h / 2.0, p.y * depth / 2.0)
	for y: float in [y0 + 0.02, y0 + h - 0.02]:
		fine(w + 0.02, 0.04, 0.045, c, 0, y, depth / 2.0)
		fine(w + 0.02, 0.04, 0.045, c, 0, y, -depth / 2.0)
		fine(0.045, 0.04, depth + 0.02, c, w / 2.0, y, 0)
		fine(0.045, 0.04, depth + 0.02, c, -w / 2.0, y, 0)
	for sx: float in [-1.0, 1.0]:
		var span := sqrt(pow(w * 0.3, 2) + h * h) * 0.95
		var basis := Basis(Vector3.BACK, sx * atan2(w * 0.3, h))
		d.box(Transform3D(basis, at(sx * w * 0.32, y0 + h / 2.0, depth / 2.0 + 0.012)), Vector3(0.03, span, 0.02) * unit,
			c)


## A fine part: a plain box in the un-inked layer.
func fine(w: float, h: float, depth: float, col: Color, x: float, y: float, z: float, yaw := 0.0) -> void:
	d.box(place(x, y, z, yaw), Vector3(w, h, depth) * unit, col)


## Stone courses: lines across a stone storey.
func courses(w: float, depth: float, y0: float, y1: float, n: int) -> void:
	for i in range(1, n):
		var y := y0 + (y1 - y0) * i / n
		d.box(place(0, y, 0), Vector3(w + 0.012, 0.012, depth + 0.012) * unit, stone.darkened(0.14))


## A plinth under the building: rough stones at the first look, a dressed
## step after, crystal-white with a gold band at the third.
func plinth(w: float, depth: float, h := 0.08) -> void:
	box(w, h, depth, stone2, 0, h / 2.0, 0)
	if tier == 0:
		for k in 5:
			var a := TAU * k / 5.0 + 0.3
			d.rock(Geo.place(at(cos(a) * w * 0.5, 0.02, sin(a) * depth * 0.5), a, Vector3(1, 0.6, 1)), 0.05 * unit,
				stone.darkened(0.05 * (k % 2)), k)
	elif tier == 2:
		d.box(place(0, h, 0), Vector3(w + 0.01, 0.02, depth + 0.01) * unit, KitStyle.GOLD)


## Smoke rising from a chimney's top at (x, y, z), three soft puffs.
func _smoke(x: float, y: float, z: float) -> void:
	for k in 3:
		var p := at(x + 0.03 * k, y + 0.12 + 0.16 * k, z)
		move(Geo.Anim.BOB, p + Vector3(k * 2.0, 0, 0))
		d.ball(Geo.place(p), (0.05 + 0.03 * k) * unit, Color("#EEE8F4"), 3, 6)
	stop()


## A chimney standing from (x, y, z) to `h` units up, with smoke.
func chimney(x: float, y: float, z: float, h: float) -> void:
	box(0.17, h, 0.17, stone2 if tier > 0 else Color("#8A4A3A"), x, y + h / 2.0, z)
	box(0.21, 0.05, 0.21, stone.darkened(0.2), x, y + h, z)
	_smoke(x, y + h, z)


## A flag on a pole from (x, y, z), fluttering in the realm's accent.
func flag(x: float, y: float, z: float, h := 0.35, col := Color.BLACK) -> void:
	var c: Color = style["accent"] if col == Color.BLACK else col
	cyl(0.012, 0.01, h, KitStyle.IRON, x, y, z, 4)
	var pole := at(x, y + h, z)
	move(Geo.Anim.FLAG, pole)
	var w := 0.26 * unit
	var fh := 0.15 * unit
	var p0 := pole
	var p1 := pole + Vector3(w, -fh * 0.5, 0)
	var p2 := pole + Vector3(0, -fh, 0)
	d.tri(p0, p1, p2, c)
	d.tri(p0, p2, p1, c.darkened(0.1))
	stop()
	ball(0.022, KitStyle.GOLD, x, y + h + 0.01, z, 1.0, 2, 5)


## Every building's dress by level (the design's `dress`): a lamp post by
## the door, a flag from level 3, banners and a turning finial from level 6,
## gold filigree at the third look; and §21.5's crown at level 10.
func _dress(kind: String) -> void:
	if kind in ["ward", "law_pylon", "anchor_stone", "keeper_s_spire"]:
		if level >= 10:
			KitBuildings2.crown(self, kind)
		return
	# The lamp post at the footprint's front corner.
	var lx := 0.48
	var lz := 0.46
	cyl(0.018, 0.014, 0.4, KitStyle.WOOD_DARK, lx, 0, lz, 5)
	box(0.07, 0.08, 0.07, KitStyle.lit(Color("#FFD27A"), 0.75), lx, 0.44, lz)
	cone(0.06, 0.05, KitStyle.WOOD_DARK, lx, 0.48, lz, 4)
	# Warm light spilling onto the ground at the door and under the lamp.
	glass.ring(place(0, 0.012, 0.5), 0.0, 0.2 * unit, Color(Color("#FFB860"), 0.35), 12)
	glass.ring(place(lx, 0.014, lz), 0.0, 0.13 * unit, Color(Color("#FFB860"), 0.35), 10)
	_topper()
	if level >= 3:
		flag(-0.32, top * 0.82, -0.22, 0.42)
	if level >= 6:
		# Two banner poles at the front corners, the realm's colour hanging.
		for sx: float in [-1.0, 1.0]:
			var px := sx * 0.5
			cyl(0.014, 0.012, 0.62, KitStyle.WOOD_DARK, px, 0, 0.5, 4)
			fine(0.16, 0.02, 0.02, KitStyle.GOLD, px - sx * 0.06, 0.6, 0.5)
			move(Geo.Anim.SWAY, at(px, 0.6, 0.5))
			fine(0.11, 0.24, 0.012, style["accent"], px - sx * 0.06, 0.47, 0.5)
			d.prism(Transform3D(Basis(Vector3.RIGHT, PI), at(px - sx * 0.06, 0.35, 0.5)), 3, 0.055 * unit, 0.0,
				0.05 * unit, style["accent"])
			stop()
		ball(0.03, KitStyle.GOLD, -0.5, 0.64, 0.5, 1.0, 2, 5)
		ball(0.03, KitStyle.GOLD, 0.5, 0.64, 0.5, 1.0, 2, 5)
		move(Geo.Anim.SPIN_Y, at(0, top + 0.16, 0))
		d.gem(Geo.place(at(0, top + 0.16, 0)), 0.06 * unit, 0.1 * unit, KitStyle.lit(Color("#F9DE9C"), 0.4), 4)
		stop()
	if tier == 2:
		for k in 3:
			var a := TAU * k / 3.0 + 0.5
			move(Geo.Anim.SPIN_Y, at(0, top, 0))
			d.gem(Geo.place(at(cos(a) * 0.12, top + 0.05, sin(a) * 0.12)), 0.035 * unit, 0.09 * unit,
				KitStyle.lit(Color("#C8B8FF"), 0.5), 4)
		stop()
	if level >= 10:
		KitBuildings2.crown(self, kind)


## The realm's mark on every roof (the design's `topper`, :749–755): crystals
## in Crystalline, a pinwheel in Skyfield, a shell dome in Tidehold, a
## brazier in Emberreach, moss in Verdant, a lantern in Lantern Vale and
## flowers at the door in the Heart.
func _topper() -> void:
	var realm := KitStyle.realm_of(palette)
	match realm:
		"crystalline":
			move(Geo.Anim.SPIN_Y, at(0, top, 0))
			for i in 3:
				d.gem(Geo.place(at((i - 1) * 0.12, top + 0.06, (i % 2) * 0.07), i * 0.7), 0.045 * unit, 0.12 * unit,
					KitStyle.lit(Color("#C8B8FF"), 0.45), 4)
			stop()
		"skyfield":
			cyl(0.01, 0.01, 0.3, KitStyle.IRON, 0, top - 0.05, 0, 4)
			var hub := at(0, top + 0.25, 0.02)
			move(Geo.Anim.SPIN_Z, hub)
			for i in 4:
				var a := TAU * i / 4.0
				d.tri(hub, hub + Vector3(cos(a), sin(a), 0) * 0.12 * unit,
					hub + Vector3(cos(a + 0.6), sin(a + 0.6), 0) * 0.08 * unit, KitStyle.GOLD if i % 2 == 0 else Color.WHITE)
			stop()
		"tidehold":
			d.ball(Geo.place(at(0, top - 0.04, 0)), 0.12 * unit, Color("#5ED3E6"), 3, 8, true)
			for i in 4:
				var a := i * PI / 2.0 + 0.4
				cone(0.03, 0.09, Color("#FFF3E0"), cos(a) * 0.45, 0.0, sin(a) * 0.45, 5)
		"emberreach":
			cyl(0.05, 0.07, 0.06, KitStyle.IRON, 0, top - 0.04, 0, 6)
			move(Geo.Anim.BOB, at(0, top + 0.06, 0))
			ball(0.05, KitStyle.lit(Color("#FF8A3C"), 0.2), 0, top + 0.06, 0, 1.4, 2, 6)
			stop()
		"verdant":
			for i in 4:
				d.rock(Geo.place(at((Geo._hash01(i * 7 + level) - 0.5) * 0.4, top - 0.12 - 0.08 * (i % 2),
					(Geo._hash01(i * 3) - 0.5) * 0.3)), 0.06 * unit, Color("#4CA24C"), i)
		"lanternvale":
			var hook := at(0.3, 0.42, 0.44)
			fine(0.02, 0.02, 0.12, KitStyle.WOOD_DARK, 0.3, 0.44, 0.4)
			move(Geo.Anim.SWING, hook)
			d.rbox(Geo.place(hook + Vector3(0, -0.07, 0) * unit), Vector3(0.07, 0.09, 0.07) * unit,
				KitStyle.lit(Color("#FFD27A"), 0.15), 0.01)
			stop()
		_:
			var petals: Array[Color] = [Color("#F7A6DA"), Color.WHITE, Color("#FFE08F")]
			for i in 5:
				ball(0.025, petals[i % 3], -0.25 + 0.12 * i, 0.03, 0.46 + 0.04 * (i % 2), 1.0, 2, 5)


## The packed-earth pad a building stands on (the design's foundation disc,
## :981): an octagon of trodden earth and stone, wider than the house.
func _pad() -> void:
	var earth := KitGround.earth(palette).lerp(Color("#E8D8B8"), 0.35)
	d.prism(place(0, 0.0, 0, PI / 8.0), 8, 0.6 * unit, 0.57 * unit, 0.03 * unit, earth.darkened(0.08), false, earth)
	for k in 4:
		var a := TAU * k / 4.0 + 0.5
		d.rock(Geo.place(at(cos(a) * 0.6, 0.012, sin(a) * 0.6), a, Vector3(1, 0.5, 1)), 0.035 * unit,
			(palette["rock"] as Color).lightened(0.2), k)


## The Hearth: "a cottage with a round door and chimney", warm window light.
func _hearth() -> void:
	plinth(0.94, 0.82)
	var two := tier >= 1
	box(0.82, 0.36, 0.66, stone, 0, 0.26, 0)
	courses(0.82, 0.66, 0.08, 0.44, 3)
	var eave := 0.44
	if two:
		box(0.9, 0.34, 0.74, wall, 0, 0.61, 0)
		frame(0.9, 0.34, 0.74, 0.44)
		eave = 0.78
		window(-0.22, 0.62, 0.375, 0, 0.9)
		window(0.22, 0.62, 0.375, 0, 0.9)
		for z: float in [0.16, -0.16]:
			window(0.455, 0.62, z, PI / 2.0, 0.9, false)
			window(-0.455, 0.62, z, -PI / 2.0, 0.9, false)
		for x: float in [-0.22, 0.22]:
			window(x, 0.62, -0.375, PI, 0.9)
	var y := roof(0.9 if two else 0.86, 0.74 if two else 0.7, eave, 0.42, 0.1)
	door(0, 0.08, 0.335, 0)
	window(-0.25, 0.27, 0.335, 0)
	window(0.25, 0.27, 0.335, 0)
	window(0.415, 0.27, 0, PI / 2.0, 0.9, false)
	window(-0.415, 0.27, 0, -PI / 2.0, 0.9, false)
	window(-0.2, 0.27, -0.335, PI, 0.9)
	window(0.2, 0.27, -0.335, PI, 0.9)
	# The round window in the gable.
	g.cyl(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), at(0, eave + 0.15, 0.36)), 0.06 * unit, 0.06 * unit,
		0.03 * unit, KitStyle.lit(KitStyle.WINDOW, 0.5), 12)
	d.torus(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), at(0, eave + 0.15, 0.376)), 0.065 * unit, 0.014 * unit,
		KitStyle.WOOD_DARK, 12, 4)
	# Flower boxes under the windows.
	var flowers: Array[Color] = [Color("#F7A6DA"), Color("#FFE08F"), Color("#FFFFFF"), Color("#E2536B")]
	for x: float in [-0.25, 0.25]:
		box(0.2, 0.05, 0.06, KitStyle.WOOD, x, 0.17, 0.37)
		for k in 4:
			ball(0.024, flowers[k], x - 0.075 + k * 0.05, 0.21, 0.37, 1.0, 2, 5)
	chimney(0.27, y - 0.25, -0.16, 0.42)
	# A barrel and a crate by the door, and a lantern.
	cyl(0.07, 0.07, 0.18, KitStyle.WOOD.lightened(0.2), 0.36, 0, 0.42, 8)
	box(0.14, 0.14, 0.14, Color("#B88A5A"), -0.38, 0.07, 0.42, 0.4)
	ball(0.03, KitStyle.lit(Color("#FFE7A8"), 0.8), -0.13, 0.33, 0.37, 1.0, 2, 5)
	top = y + 0.05


## The Storehouse: "a barn with star-shaped locks", wood and tile.
func _storehouse() -> void:
	plinth(1.0, 0.84)
	box(0.92, 0.5, 0.72, KitStyle.WOOD.lightened(0.28) if tier == 0 else wall, 0, 0.33, 0)
	# Plank lines.
	for k in 6:
		d.box(place(-0.4 + 0.16 * k, 0.33, 0.362), Vector3(0.01, 0.48, 0.01) * unit, KitStyle.WOOD)
	frame(0.92, 0.5, 0.72, 0.08)
	# A barn's two-pitched roof: steep below, shallow above.
	var turn := 0.0
	var y := 0.58
	for s: float in [-1.0, 1.0]:
		for k in 3:
			var t := (k + 0.5) / 3.0
			g.rbox(Transform3D(Basis(Vector3.BACK, -s * 1.0), at(s * (0.5 - 0.17 * t), y + 0.2 * t, 0)),
				Vector3(0.1, 0.04, 0.86) * unit, roof_col if k % 2 == 0 else roof_dark, 0.01)
			g.rbox(Transform3D(Basis(Vector3.BACK, -s * 0.42), at(s * (0.3 - 0.27 * t), y + 0.2 + 0.11 * t, 0)),
				Vector3(0.12, 0.04, 0.86) * unit, roof_dark if k % 2 == 0 else roof_col, 0.01)
	g.gable(Transform3D(Basis(Vector3.UP, turn), at(0, y, 0)), 0.92 * unit, 0.3 * unit, 0.72 * unit, wall.darkened(0.05))
	# The great doors, with a star lock.
	for sx: float in [-1.0, 1.0]:
		box(0.17, 0.36, 0.03, KitStyle.WOOD, sx * 0.09, 0.26, 0.37)
		d.box(Transform3D(Basis(Vector3.BACK, sx * 0.9), at(sx * 0.09, 0.26, 0.39)), Vector3(0.02, 0.36, 0.01) * unit,
			KitStyle.WOOD_DARK)
	move(Geo.Anim.SPIN_Z, at(0, 0.3, 0.4))
	d.gem(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), at(0, 0.3, 0.4)), 0.05 * unit, 0.03 * unit,
		KitStyle.lit(KitStyle.GOLD, 0.3), 5)
	stop()
	for x: float in [-0.25, 0.25]:
		window(x, 0.34, -0.37, PI, 0.8, false)
	for z: float in [-0.15, 0.15]:
		window(0.47, 0.34, z, PI / 2.0, 0.8, false)
		window(-0.47, 0.34, z, -PI / 2.0, 0.8, false)
	# The hay loft.
	box(0.16, 0.14, 0.03, KitStyle.WOOD_DARK, 0, 0.7, 0.37)
	ball(0.05, KitStyle.THATCH, 0, 0.68, 0.39, 0.6, 2, 6)
	for k in 3:
		box(0.13, 0.13, 0.13, Color("#B88A5A"), 0.38 - 0.02 * k, 0.065 + 0.13 * (k / 2), 0.44 - 0.14 * (k % 2), k)
	top = 0.95


## The Library: "a round reading room under a glass lantern roof".
func _library() -> void:
	plinth(0.96, 0.96)
	cyl(0.44, 0.42, 0.5, stone if tier == 0 else wall, 0, 0.08, 0, 12)
	cyl(0.45, 0.45, 0.04, stone2, 0, 0.36, 0, 12)
	for k in 8:
		var a := TAU * (k + 0.5) / 8.0
		if a > 1.2 and a < 1.9:
			continue
		window(cos(a) * 0.43, 0.25, sin(a) * 0.43, PI / 2.0 - a, 0.85, false)
	door(0, 0.08, 0.43, 0, 0.95)
	cyl(0.4, 0.36, 0.2, wall.lightened(0.05), 0, 0.4, 0, 12)
	for k in 8:
		var a := TAU * k / 8.0
		box(0.04, 0.2, 0.04, KitStyle.WOOD_DARK if tier < 2 else KitStyle.GOLD, cos(a) * 0.38, 0.5, sin(a) * 0.38)
	# The glass lantern roof, lit from within.
	g.prism(place(0, 0.6, 0, PI / 8.0), 8, 0.42 * unit, 0.3 * unit, 0.06 * unit, roof_col)
	g.prism(place(0, 0.66, 0, PI / 8.0), 8, 0.28 * unit, 0.2 * unit, 0.22 * unit, KitStyle.lit(Color("#DDF4FF"), 0.45))
	for k in 8:
		var a := TAU * k / 8.0 + PI / 8.0
		d.box(Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.BACK, 0.35), at(cos(a) * 0.24, 0.77, sin(a) * 0.24)),
			Vector3(0.02, 0.24, 0.02) * unit, KitStyle.GOLD)
	cone(0.24, 0.24, roof_col, 0, 0.88, 0, 8)
	ball(0.04, KitStyle.GOLD, 0, 1.14, 0, 1.0, 3, 6)
	# Loose pages drifting round it.
	for k in 4:
		var a := TAU * k / 4.0
		move(Geo.Anim.SPIN_Y, at(0, 0.9, 0))
		d.box(Geo.place(at(cos(a) * 0.55, 0.75 + 0.1 * k, sin(a) * 0.55), a + 0.4), Vector3(0.08, 0.005, 0.06) * unit,
			Color("#FFF8E6"))
	stop()
	top = 1.15


## The Star Well: "a stone well with a star net above"; a worker cranks
## and stars drop into the bucket.
func _star_well() -> void:
	cyl(0.52, 0.56, 0.1, stone2, 0, 0, 0, 10)
	cyl(0.45, 0.47, 0.08, stone, 0, 0.1, 0, 10)
	for c in 2:
		for i in 12:
			var a := (i + c * 0.5) / 12.0 * TAU
			box(0.17, 0.12, 0.1, stone if (i + c) % 2 == 1 else stone.darkened(0.12), cos(a) * 0.33, 0.24 + c * 0.12,
				sin(a) * 0.33, PI / 2.0 - a)
	d.torus(place(0, 0.44, 0), 0.33 * unit, 0.05 * unit, stone2, 16, 5)
	g.cyl(place(0, 0.39, 0), 0.28 * unit, 0.28 * unit, 0.02 * unit, KitStyle.lit(Color("#FFE08F"), 0.25), 14)
	for x: float in [-0.36, 0.36]:
		box(0.1, 0.08, 0.1, stone2, x, 0.48, 0)
		box(0.06, 0.72, 0.06, KitStyle.WOOD, x, 0.88, 0)
	box(0.84, 0.06, 0.07, KitStyle.WOOD, 0, 1.22, 0)
	g.cyl(Transform3D(Basis(Vector3.BACK, PI / 2.0), at(0.35, 1.02, 0)), 0.025 * unit, 0.025 * unit, 0.7 * unit,
		KitStyle.WOOD_DARK, 6)
	# The crank wheel turns; the bucket rises and falls.
	var hub := at(0.42, 1.02, 0)
	move(Geo.Anim.SPIN_X, hub)
	d.torus(Transform3D(Basis(Vector3.BACK, PI / 2.0), hub), 0.09 * unit, 0.015 * unit, KitStyle.WOOD_DARK, 12, 4)
	for i in 4:
		d.box(Transform3D(Basis(Vector3.RIGHT, i * PI / 4.0), hub), Vector3(0.01, 0.18, 0.01) * unit, KitStyle.WOOD_DARK)
	move(Geo.Anim.BOB, at(0, 0.7, 0))
	cyl(0.055, 0.045, 0.08, KitStyle.WOOD, 0, 0.66, 0, 8)
	stop()
	cyl(0.004, 0.004, 0.36, Color("#D8C8A8"), 0, 0.82, 0, 3)
	# Its little roof, turned across the beam.
	var y := _hip_roof(0.62, 0.48, 1.25, 0.38)
	move(Geo.Anim.SPIN_Y, at(0, y + 0.3, 0))
	d.gem(Geo.place(at(0, y + 0.3, 0)), 0.15 * unit, 0.22 * unit, KitStyle.lit(Color("#FFE9A0"), 0.45), 4)
	stop()
	# The star net: a ring of little stars above it from the second look.
	if tier >= 1:
		move(Geo.Anim.SPIN_Y, at(0, y + 0.3, 0))
		for k in 5:
			var a := TAU * k / 5.0
			d.gem(Geo.place(at(cos(a) * 0.3, y + 0.3, sin(a) * 0.3)), 0.035 * unit, 0.035 * unit,
				KitStyle.lit(Color("#FFE7A8"), 0.6), 4)
		stop()
	box(0.13, 0.13, 0.13, Color("#B88A5A"), 0.42, 0.065, 0.42, 0.5)
	top = y + 0.1


## The Garden: "raised beds with glowing sprouts"; under a greenhouse from
## the second look.
func _garden() -> void:
	plinth(0.96, 0.8, 0.06)
	box(0.86, 0.14, 0.62, KitStyle.WOOD.lightened(0.15) if tier == 0 else stone, 0, 0.13, 0)
	box(0.8, 0.02, 0.56, palette["soil"], 0, 0.205, 0)
	for r in 3:
		for i in 5:
			var x := -0.3 + i * 0.15
			var z := -0.18 + r * 0.18
			if (i + r) % 3 == 0:
				move(Geo.Anim.BOB, at(x, 0.25, z))
				ball(0.045, KitStyle.lit(Color("#C8F7CE"), 0.4), x, 0.26, z, 1.3, 3, 6)
				stop()
			else:
				move(Geo.Anim.SHIVER, at(x, 0.21, z))
				cone(0.05, 0.14, Color("#4FAF55") if i % 2 == 0 else Color("#6CCB6A"), x, 0.21, z, 5)
				stop()
	if tier >= 1:
		# The greenhouse: white frame, pale glass.
		var pane := Color("#D8F4EC")
		for z: float in [-0.29, 0.29]:
			glass.box(place(0, 0.37, z), Vector3(0.82, 0.34, 0.01) * unit, pane)
			glass.gable(Transform3D(Basis(), at(0, 0.54, z)), 0.82 * unit, 0.26 * unit, 0.01 * unit, pane)
		for x: float in [-0.41, 0.41]:
			glass.box(place(x, 0.37, 0), Vector3(0.01, 0.34, 0.58) * unit, pane)
		var fr := Color("#F6F2E8") if tier == 1 else KitStyle.GOLD
		for i in 5:
			var x := -0.41 + i * 0.205
			for z: float in [-0.29, 0.29]:
				box(0.022, 0.34, 0.022, fr, x, 0.37, z)
		for z: float in [-0.29, 0.29]:
			box(0.84, 0.022, 0.022, fr, 0, 0.54, z)
		box(0.022, 0.022, 0.6, fr, 0, 0.8, 0)
		for s: float in [-1.0, 1.0]:
			glass.rbox(Transform3D(Basis(Vector3.BACK, -s * 0.56), at(s * 0.205, 0.67, 0)),
				Vector3(0.48, 0.015, 0.6) * unit, pane, 0.005)
			d.box(Transform3D(Basis(Vector3.BACK, -s * 0.56), at(s * 0.205, 0.68, 0.29)),
				Vector3(0.48, 0.024, 0.024) * unit, fr)
		top = 0.85
	else:
		top = 0.5
	# Planters in front and a water butt; a scarecrow at the back.
	for x: float in [-0.28, 0.12]:
		box(0.3, 0.08, 0.16, KitStyle.WOOD, x, 0.04, 0.52)
		for i in 4:
			move(Geo.Anim.SHIVER, at(x - 0.1 + i * 0.066, 0.08, 0.52))
			cone(0.03, 0.09, Color("#F2B43C") if i % 2 == 1 else Color("#5CC46A"), x - 0.1 + i * 0.066, 0.08, 0.52, 5)
		stop()
	cyl(0.07, 0.065, 0.16, KitStyle.WOOD, 0.4, 0, 0.46, 8)
	cyl(0.014, 0.014, 0.5, KitStyle.WOOD, -0.42, 0, -0.34, 4)
	box(0.3, 0.02, 0.02, KitStyle.WOOD, -0.42, 0.36, -0.34)
	box(0.1, 0.14, 0.06, roof_col if tier > 0 else Color("#C0502E"), -0.42, 0.33, -0.34)
	ball(0.05, Color("#E8D8B0"), -0.42, 0.47, -0.34, 1.0, 3, 6)
	cone(0.08, 0.08, KitStyle.WOOD_DARK, -0.42, 0.5, -0.34, 8)


## The Guardian Post: "a small watch platform with a lantern".
func _guard() -> void:
	cyl(0.36, 0.4, 0.14, stone2, 0, 0, 0, 8)
	var th := 0.9 + 0.15 * tier
	cyl(0.28, 0.22, th, stone if tier > 0 else KitStyle.WOOD.lightened(0.2), 0, 0.14, 0, 8)
	for y: float in [0.35, 0.14 + th * 0.7]:
		cyl(0.285, 0.285, 0.04, stone2, 0, y, 0, 8)
	door(0, 0.14, 0.25, 0, 0.8)
	var py := 0.14 + th
	cyl(0.38, 0.33, 0.08, KitStyle.WOOD, 0, py, 0, 8)
	for i in 8:
		var a := i * PI / 4.0
		box(0.03, 0.14, 0.03, KitStyle.WOOD_DARK, cos(a) * 0.34, py + 0.15, sin(a) * 0.34)
	d.torus(place(0, py + 0.22, 0), 0.34 * unit, 0.015 * unit, KitStyle.WOOD_DARK, 16, 4)
	for i in 4:
		var a := i * PI / 2.0 + PI / 4.0
		box(0.04, 0.3, 0.04, KitStyle.WOOD_DARK, cos(a) * 0.3, py + 0.26, sin(a) * 0.3)
	cone(0.44, 0.42, roof_col, 0, py + 0.41, 0, 8)
	# The lantern, swinging.
	var hook := at(0.36, py + 0.3, 0.1)
	move(Geo.Anim.SWING, hook)
	d.box(Geo.place(hook + Vector3(0, -0.1, 0) * unit), Vector3(0.07, 0.09, 0.07) * unit,
		KitStyle.lit(Color("#FFD27A"), 0.7))
	stop()
	# The school banner.
	d.box(place(0, 0.14 + th * 0.62, 0.27), Vector3(0.16, 0.34, 0.01) * unit, style["accent"])
	d.box(place(0, 0.14 + th * 0.62 + 0.18, 0.27), Vector3(0.2, 0.03, 0.03) * unit, KitStyle.GOLD)
	top = py + 0.9
