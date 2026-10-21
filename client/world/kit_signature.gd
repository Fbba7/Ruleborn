class_name KitSignature
extends RefCounted
## Each realm's signature round its home, as the design's `kingdom` sets it
## (realm-diorama.js :672–678) and §21.4's "how it grows with level": two
## windmills in Skyfield, great crystals in Crystalline, a great tree in
## Verdant, a ring of lanterns and a floating lantern festival in Lantern
## Vale, smoking vents grown into chimneys in Emberreach, and the Heart's
## walls (KitCitadel). Off the grid, on the island just past its corners, so
## never where the simulation has a tile; drawn where the Keeper's Spire
## stands, the realm's home.


## The diagonal corners past the grid: on a portrait screen the corners
## toward the camera and away from it always show, the side ones do not, so
## two adjacent corners keep one in view at every quarter turn.
const CORNERS := [PI / 4.0, 3.0 * PI / 4.0, 5.0 * PI / 4.0, 7.0 * PI / 4.0]


## The signature of `realm` round a ring of `radius` into `g` (inked) and
## `fine`, grown by `grow` (0 at a realm's first level, 1 from its fifth,
## §21.4's "how it grows with level"): one windmill, then two; crystals
## that grow larger; a young tree, then the great tree; four lanterns, then
## eight and the floating festival; vents that grow into chimneys.
static func build(g: Geo, fine: Geo, realm: String, radius: float, palette: Dictionary, grow := 1.0) -> void:
	var base := -0.1
	var at := func(a: float) -> Vector3: return Vector3(cos(a) * radius, base, sin(a) * radius)
	var size := 0.6 + 0.4 * grow
	match realm:
		"heart":
			KitCitadel.walls(g, fine, radius, palette)
		"skyfield":
			for a: float in ([CORNERS[0], CORNERS[1]] if grow >= 0.5 else [CORNERS[0]]):
				_grown(g, fine, at.call(a), size, func(tg: Geo, tf: Geo) -> void:
					_windmill(tg, tf, Vector3.ZERO, palette))
		"crystalline":
			for a: float in CORNERS:
				_grown(g, fine, at.call(a), 0.5 + 0.6 * grow, func(tg: Geo, _tf: Geo) -> void:
					_crystals(tg, Vector3.ZERO, a))
		"verdant":
			var a: float = CORNERS[2]
			_grown(g, fine, at.call(a), 0.45 + 0.55 * grow, func(tg: Geo, tf: Geo) -> void:
				_great_tree(tg, tf, Vector3.ZERO, palette))
		"lanternvale":
			var n := 4 if grow < 0.5 else 8
			for k in n:
				var a := TAU * k / n + 0.2
				_lantern(g, fine, at.call(a))
			for k in (6 if grow >= 1.0 else 0):
				var a := TAU * k / 6.0 + 0.5
				var p := Vector3(cos(a) * radius * 0.55, 2.6 + 0.5 * Geo._hash01(k * 7), sin(a) * radius * 0.55)
				fine.moving(Geo.Anim.BOB, p)
				fine.cyl(Geo.place(p), 0.11, 0.13, 0.22, Color(Color("#FFC870"), 0.2), 8)
				fine.cyl(Geo.place(p + Vector3(0, 0.22, 0)), 0.06, 0.06, 0.03, KitStyle.WOOD_DARK, 6)
				fine.moving(Geo.Anim.NONE, Vector3.ZERO)
		"emberreach":
			for a: float in [CORNERS[0], CORNERS[1]]:
				_grown(g, fine, at.call(a), 0.45 + 0.55 * grow, func(tg: Geo, tf: Geo) -> void:
					_chimney(tg, tf, Vector3.ZERO, palette))


## A piece drawn by `draw` at the origin, then set at `p` scaled by `size`.
static func _grown(g: Geo, fine: Geo, p: Vector3, size: float, draw: Callable) -> void:
	var tg := Geo.new()
	var tf := Geo.new()
	tg.skip_down = g.skip_down
	tf.skip_down = fine.skip_down
	tg.coarse = g.coarse
	tf.coarse = fine.coarse
	draw.call(tg, tf)
	var xf := Transform3D(Basis().scaled(Vector3.ONE * size), p)
	g.absorb(tg, xf)
	fine.absorb(tf, xf)


static func _windmill(g: Geo, fine: Geo, p: Vector3, palette: Dictionary) -> void:
	var style := KitStyle.of(KitStyle.realm_of(palette))
	g.cyl(Geo.place(p), 0.36, 0.26, 1.5, style["wall"], 10)
	fine.cyl(Geo.place(p + Vector3(0, 0.5, 0)), 0.32, 0.32, 0.04, style["stone2"], 10)
	g.prism(Geo.place(p + Vector3(0, 1.5, 0), PI / 10.0), 10, 0.32, 0.0, 0.4, style["roof"])
	fine.box(Geo.place(p + Vector3(0, 0.2, 0.33)), Vector3(0.16, 0.28, 0.02), KitStyle.WOOD)
	fine.box(Geo.place(p + Vector3(0, 0.95, 0.29)), Vector3(0.1, 0.12, 0.02), KitStyle.lit(KitStyle.WINDOW, 0.5))
	var hub := p + Vector3(0, 1.45, 0.34)
	fine.moving(Geo.Anim.SPIN_Z, hub)
	for k in 4:
		var a := TAU * k / 4.0
		var dir := Vector3(cos(a), sin(a), 0)
		var mid := hub + dir * 0.45
		var basis := Basis(Vector3.BACK, a)
		fine.box(Transform3D(basis, mid), Vector3(0.8, 0.03, 0.03), KitStyle.WOOD_DARK)
		fine.box(Transform3D(basis, mid + Vector3(0, 0, 0.01) + dir.cross(Vector3.BACK) * 0.07),
			Vector3(0.7, 0.13, 0.01), Color("#F4EEDF"))
	fine.moving(Geo.Anim.NONE, Vector3.ZERO)
	fine.ball(Geo.place(hub), 0.05, KitStyle.WOOD_DARK, 2, 6)


static func _crystals(g: Geo, p: Vector3, turn: float) -> void:
	var colour := Palette.MATTER.lightened(0.3)
	var spots := [[0.0, 0.0, 0.32, 1.2], [0.3, 0.15, 0.2, 0.75], [-0.25, 0.2, 0.18, 0.6], [0.1, -0.3, 0.15, 0.5]]
	for k in spots.size():
		var s: Array = spots[k]
		var o := Vector3(s[0], 0, s[1]).rotated(Vector3.UP, turn)
		var lean := Basis(Vector3(o.z, 0, -o.x).normalized() if o.length() > 0.01 else Vector3.RIGHT, o.length() * 0.8)
		var tall: float = s[3]
		g.gem(Transform3D(lean, p + o + Vector3(0, tall * 0.8, 0)), s[2], tall, Color(colour.darkened(0.06 * k), 0.7), 6)
	g.rock(Geo.place(p + Vector3(0, 0.05, 0), turn, Vector3(1.4, 0.4, 1.4)), 0.3, Color("#4F4C86"), int(turn * 10))


static func _great_tree(g: Geo, fine: Geo, p: Vector3, palette: Dictionary) -> void:
	var plant: Color = palette["plant"]
	var bark := KitStyle.WOOD.lightened(0.05)
	g.cyl(Geo.place(p), 0.34, 0.2, 1.6, bark, 9)
	for k in 4:
		var a := TAU * k / 4.0 + 0.4
		fine.prism(Transform3D(Basis(Vector3(cos(a), 0, sin(a)).cross(Vector3.UP), -0.9), p + Vector3(cos(a), 0, sin(a))
			* 0.22), 5, 0.1, 0.02, 0.5, bark.darkened(0.1))
	g.moving(Geo.Anim.SWAY, p)
	g.ball(Geo.place(p + Vector3(0, 2.0, 0), 0.0, Vector3(1.0, 0.8, 1.0)), 1.1, plant.darkened(0.08), 5, 12)
	g.ball(Geo.place(p + Vector3(0.6, 2.4, 0.2)), 0.7, plant, 4, 10)
	g.ball(Geo.place(p + Vector3(-0.55, 2.5, -0.25)), 0.65, plant.lightened(0.05), 4, 10)
	g.ball(Geo.place(p + Vector3(0.1, 2.9, -0.1)), 0.55, plant.lightened(0.1), 4, 10)
	g.moving(Geo.Anim.NONE, Vector3.ZERO)


static func _lantern(g: Geo, fine: Geo, p: Vector3) -> void:
	g.cyl(Geo.place(p), 0.05, 0.035, 1.0, KitStyle.IRON, 6)
	fine.box(Geo.place(p + Vector3(0.12, 0.98, 0)), Vector3(0.28, 0.03, 0.03), KitStyle.IRON)
	fine.moving(Geo.Anim.SWING, p + Vector3(0.22, 0.96, 0))
	fine.rbox(Geo.place(p + Vector3(0.22, 0.84, 0)), Vector3(0.13, 0.17, 0.13), Color(Color("#FFD27A"), 0.15), 0.02)
	fine.prism(Geo.place(p + Vector3(0.22, 0.925, 0), PI / 4.0), 4, 0.1, 0.0, 0.06, KitStyle.IRON)
	fine.moving(Geo.Anim.NONE, Vector3.ZERO)


static func _chimney(g: Geo, fine: Geo, p: Vector3, palette: Dictionary) -> void:
	var rock: Color = palette["rock"]
	g.prism(Geo.place(p, 0.3), 7, 0.5, 0.18, 1.3, rock, false, rock.darkened(0.3))
	g.rock(Geo.place(p + Vector3(0.35, 0.1, 0.2)), 0.18, rock.lightened(0.1), 3)
	fine.ring(Geo.place(p + Vector3(0, 1.305, 0)), 0.0, 0.15, Color(Palette.ENERGY.lightened(0.2), 0.1), 8)
	for k in 3:
		var q := p + Vector3(0.04 * k, 1.5 + 0.28 * k, 0)
		fine.moving(Geo.Anim.RISE, q + Vector3(k * 3.0, 0, 0))
		fine.ball(Geo.place(q), 0.12 + 0.07 * k, Color("#6A5A5E").lightened(0.15 * k), 3, 7)
	fine.moving(Geo.Anim.NONE, Vector3.ZERO)
