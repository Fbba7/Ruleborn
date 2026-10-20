class_name UniverseCitadel
extends RefCounted
## The Heart's citadel as the universe map draws it (the design's `castle`,
## realm_diorama.js :638–664, carried over in its own metres): a stepped
## stone base, a curtain wall with merlons and four corner towers under
## school-pink roofs, a gatehouse lit by two braziers, and in the middle the
## Keeper's Spire, tall, its windows lit and an orb glowing at its point —
## the one shape that says "home" from across the universe (§21.1: "every
## building … must read as a dark shape at 32 points tall").

const GOLD := Color("#E9B65C")
const LIT := Color("#FFD77A", 0.15)
const STONE := Color("#E6DCCB")
const STONE_DARK := Color("#B9AE9C")


## The citadel on the Heart at `at`, the Spire at `spire` level (§21.5: its
## looks grow with it), into the map's inked solids and glows.
static func build(g: Geo, glows: UniversePaint, at: Vector3, palette: Dictionary, spire: int) -> void:
	var roof: Color = palette.get("roof", Palette.SPIRIT)
	var accent: Color = palette.get("accent", Palette.SPIRIT)
	var wall: Color = palette.get("wall", STONE)
	g.prism(Geo.place(at), 8, 3.8, 3.5, 0.55, STONE_DARK)
	g.prism(Geo.place(at + Vector3(0, 0.55, 0)), 8, 3.4, 3.2, 0.45, STONE)
	for i in 3:
		g.box(Geo.place(at + Vector3(0, 0.09 + i * 0.18, 3.7 - i * 0.3)), Vector3(1.6 - i * 0.2, 0.18, 0.4), STONE_DARK)
	var s := 2.3
	for side: Array in [[0.0, -s, 0.0], [0.0, s, 0.0], [-s, 0.0, PI / 2.0], [s, 0.0, PI / 2.0]]:
		var turn: float = side[2]
		var mid := at + Vector3(side[0], 1.65, side[1])
		g.box(Geo.place(mid, turn), Vector3(4.6, 1.3, 0.42), STONE)
		g.box(Geo.place(mid + Vector3(0, 0.67, 0), turn), Vector3(4.7, 0.1, 0.5), STONE_DARK)
		for k in 7:
			var u := -2.0 + k * 0.66
			var o := Vector3(0, 0.84, u) if turn != 0.0 else Vector3(u, 0.84, 0)
			g.box(Geo.place(mid + o), Vector3(0.24, 0.24, 0.24), STONE_DARK)
	_keep(g, glows, at + Vector3(0, 1.0, -0.2), wall, roof, accent, spire)
	for t: Array in [[-s, -s, 0.62, 3.3, 1.7], [s, -s, 0.62, 3.3, 1.7], [-s, s, 0.58, 2.8, 1.5], [s, s, 0.58, 2.8, 1.5]]:
		_tower(g, glows, at + Vector3(t[0], 0, t[1]), t[2], t[3], t[4], roof)
	# The gatehouse, its arch, and a brazier either side.
	var gate := at + Vector3(0, 0, s + 0.1)
	g.box(Geo.place(gate + Vector3(0, 1.95, 0)), Vector3(1.5, 1.9, 0.7), STONE)
	g.prism(Transform3D(Basis(Vector3.UP, PI / 4.0), gate + Vector3(0, 2.9, 0)), 4, 1.15, 0.0, 0.7, roof)
	g.box(Geo.place(gate + Vector3(0, 1.3, 0.05)), Vector3(0.88, 0.9, 0.74), Color("#2A1A24"))
	g.box(Geo.place(gate + Vector3(0, 1.92, 0.37)), Vector3(1.0, 0.06, 0.06), GOLD)
	for x: float in [-0.95, 0.95]:
		g.prism(Geo.place(gate + Vector3(x, 1.25, 0.4)), 6, 0.09, 0.06, 0.3, STONE_DARK)
		g.ball(Geo.place(gate + Vector3(x, 1.62, 0.4)), 0.09, Color("#FFD27A", 0.0), 2, 5)
		glows.glow(gate + Vector3(x, 1.68, 0.4), 0.9, Color("#FF9A3C", 0.85))


## A corner tower: a plinth, its body banded twice, a crown of merlons, a
## tall roof, a gold finial, and two lit windows.
static func _tower(g: Geo, glows: UniversePaint, base: Vector3, r: float, h: float, roof_h: float,
		roof: Color) -> void:
	g.prism(Geo.place(base + Vector3(0, 1.0, 0)), 10, r * 1.2, r * 1.12, 0.3, STONE_DARK)
	g.prism(Geo.place(base + Vector3(0, 1.0, 0)), 10, r * 1.06, r, h, STONE, true)
	for y: float in [h * 0.35, h * 0.72]:
		g.prism(Geo.place(base + Vector3(0, 1.0 + y, 0)), 10, r * 1.04, r * 1.04, 0.07, STONE_DARK)
	var top := base + Vector3(0, 1.0 + h, 0)
	g.prism(Geo.place(top), 10, r * 1.05, r * 1.22, 0.22, STONE_DARK)
	for i in 8:
		var q := i / 8.0 * TAU
		g.box(Geo.place(top + Vector3(cos(q) * r * 1.14, 0.3, sin(q) * r * 1.14)), Vector3(0.14, 0.18, 0.14), STONE_DARK)
	g.prism(Geo.place(top + Vector3(0, 0.22, 0)), 10, r * 1.18, 0.0, roof_h, roof)
	g.prism(Geo.place(top + Vector3(0, 0.22 + roof_h, 0)), 6, 0.05, 0.0, 0.5, GOLD)
	for i in 2:
		var q := i * PI + 0.8
		var w := base + Vector3(cos(q) * r * 1.02, 1.0 + h * 0.55, sin(q) * r * 1.02)
		g.box(Geo.place(w, -q), Vector3(0.03, 0.26, 0.14), LIT)
		glows.glow(w, 0.45, Color("#FFB84A", 0.55))


## The keep, and on it the Keeper's Spire: taller with each Spire level.
static func _keep(g: Geo, glows: UniversePaint, base: Vector3, wall: Color, roof: Color, accent: Color,
		spire: int) -> void:
	g.box(Geo.place(base + Vector3(0, 1.3, 0)), Vector3(2.6, 2.6, 2.6), STONE)
	for y: float in [0.6, 1.6]:
		g.box(Geo.place(base + Vector3(0, y, 0)), Vector3(2.64, 0.08, 2.64), STONE_DARK)
	for i in 3:
		for y: float in [1.0, 1.95]:
			g.box(Geo.place(base + Vector3(-0.7 + i * 0.7, y, 1.31)), Vector3(0.2, 0.44, 0.03), LIT)
	g.box(Geo.place(base + Vector3(0, 2.68, 0)), Vector3(2.9, 0.18, 2.9), STONE_DARK)
	var tall := 2.0 + 0.45 * clampi(spire, 1, 10)
	g.prism(Geo.place(base + Vector3(0, 2.77, 0)), 10, 0.95, 0.8, tall, wall, true)
	for k in 3:
		g.prism(Geo.place(base + Vector3(0, 2.77 + tall * (0.3 + k * 0.3), 0)), 10, 0.86, 0.86, 0.08, GOLD)
	var top := base + Vector3(0, 2.77 + tall, 0)
	g.prism(Geo.place(top), 10, 0.84, 0.96, 0.2, STONE_DARK)
	g.prism(Geo.place(top + Vector3(0, 0.2, 0)), 10, 1.02, 0.0, 2.1, roof)
	for i in 4:
		var q := i * PI / 2.0
		var w := base + Vector3(cos(q) * 0.85, 2.77 + tall * 0.55, sin(q) * 0.85)
		g.box(Geo.place(w, -q), Vector3(0.04, 0.44, 0.2), LIT)
		glows.glow(w, 0.6, Color("#FFB84A", 0.6))
	g.prism(Geo.place(top + Vector3(0, 2.3, 0)), 6, 0.07, 0.0, 0.7, GOLD)
	g.ball(Geo.place(top + Vector3(0, 3.2, 0)), 0.26, Color(accent.lightened(0.5), 0.0), 3, 8)
	glows.glow(top + Vector3(0, 3.2, 0), 2.6, Color(accent, 0.8))
	# A gold halo round the point, as in the design's stills.
	for i in 12:
		var q := TAU * i / 12.0
		glows.glow(top + Vector3(cos(q) * 1.1, 2.6, sin(q) * 1.1), 0.35, Color(GOLD.lightened(0.3), 0.8))
