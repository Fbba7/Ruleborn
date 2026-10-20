class_name KitCitadel
extends RefCounted
## The Heart's walls (the design's `walls`, realm-diorama.js :665–671): a
## crenellated ring round the realm just past its grid, towers at every
## eighth with the realm's roofs, and a gate between two taller towers with
## a banner. Kept low (§21.1's cameras look over it at 35° and 50°), and off
## the grid, so it never stands where the simulation has a tile. Drawn when
## the Keeper's Spire stands in a Heart realm: its citadel.

## Segments in the ring, and towers round it.
const SEGMENTS := 44
const TOWERS := 8
const WALL_H := 0.4


## The ring of `radius` round the origin into `g` (inked) and `fine`; the
## gate faces +Z, toward the first camera.
static func walls(g: Geo, fine: Geo, radius: float, palette: Dictionary) -> void:
	var style := KitStyle.of(KitStyle.realm_of(palette))
	var stone: Color = style["stone"]
	var stone2: Color = style["stone2"]
	var roof: Color = style["roof"]
	var base := -0.12
	var gate := PI / 2.0
	var seg_len := TAU * radius / SEGMENTS * 1.04
	for i in SEGMENTS:
		var a := TAU * (i + 0.5) / SEGMENTS
		if absf(angle_difference(a, gate)) < 0.12:
			continue
		var p := Vector3(cos(a) * radius, base, sin(a) * radius)
		var yaw := -a + PI / 2.0
		g.rbox(Geo.place(p + Vector3(0, (WALL_H + 0.12) / 2.0, 0), yaw), Vector3(seg_len, WALL_H + 0.12, 0.2),
			stone.darkened(0.04 * (i % 2)), 0.02)
		fine.box(Geo.place(p + Vector3(0, WALL_H + 0.13, 0), yaw), Vector3(seg_len, 0.04, 0.26), stone2)
		for u: float in [-0.25, 0.25]:
			var m := p + Vector3(cos(yaw), 0, -sin(yaw)) * u * seg_len
			g.box(Geo.place(m + Vector3(0, WALL_H + 0.22, 0), yaw), Vector3(0.11, 0.12, 0.2), stone2)
	for k in TOWERS:
		var a := gate + PI / TOWERS + TAU * k / TOWERS
		if absf(angle_difference(a, gate)) < 0.3:
			continue
		_tower(g, fine, Vector3(cos(a) * radius, base, sin(a) * radius), 0.24, 0.85, stone, stone2, roof)
	for s: float in [-1.0, 1.0]:
		var a := gate + s * 0.15
		_tower(g, fine, Vector3(cos(a) * radius, base, sin(a) * radius), 0.3, 1.05, stone, stone2, roof)
	# The gatehouse over the way in, and its banner.
	var gp := Vector3(cos(gate) * radius, base, sin(gate) * radius)
	var gy := -gate + PI / 2.0
	g.rbox(Geo.place(gp + Vector3(0, 0.78, 0), gy), Vector3(0.95, 0.22, 0.28), stone, 0.02)
	fine.box(Geo.place(gp + Vector3(0, 0.9, 0), gy), Vector3(1.0, 0.04, 0.32), stone2)
	fine.moving(Geo.Anim.SWAY, gp + Vector3(0, 0.78, 0))
	fine.box(Geo.place(gp + Vector3(0, 0.56, 0.15), gy), Vector3(0.24, 0.36, 0.012), style["accent"])
	fine.still()


static func _tower(g: Geo, fine: Geo, p: Vector3, r: float, h: float, stone: Color, stone2: Color,
		roof: Color) -> void:
	g.cyl(Geo.place(p), r * 1.08, r, h, stone, 10)
	fine.cyl(Geo.place(p + Vector3(0, h * 0.55, 0)), r * 1.02, r * 1.02, 0.03, stone2, 10)
	g.cyl(Geo.place(p + Vector3(0, h, 0)), r * 1.15, r * 1.2, 0.08, stone2, 10)
	for k in 7:
		var a := TAU * k / 7.0
		fine.box(Geo.place(p + Vector3(cos(a) * r * 1.12, h + 0.13, sin(a) * r * 1.12), -a), Vector3(0.07, 0.09, 0.07),
			stone2)
	g.prism(Geo.place(p + Vector3(0, h + 0.08, 0), PI / 10.0), 10, r * 1.22, 0.0, r * 2.2, roof)
	fine.ball(Geo.place(p + Vector3(0, h + 0.1 + r * 2.2, 0)), 0.03, KitStyle.GOLD, 2, 5)
	fine.box(Geo.place(p + Vector3(r, h * 0.6, 0) * Vector3(1, 1, 1)), Vector3(0.02, 0.12, 0.06),
		KitStyle.lit(KitStyle.WINDOW, 0.5))
