class_name SkiffBuilder
extends RefCounted
## §5.4's skiff, "a small flying boat", as the universe map flies it along
## the links (the design's `makeSkiff` and `skiffs`, realm_diorama.js
## :1196–1223): a turned hull with a gold rail, a deck and cabin, a mast and
## a curved sail with the school's stripe, feathered fins, and a lantern at
## the bow. One mesh; the map gives it a glowing wake.
##
## Built facing +x, its keel at y = 0, about four metres long.

const HULL := Color("#4A2A38")
const TRIM := Color("#F2B43C")
const DECK := Color("#C89A68")
const SAIL := Color("#F6EEDC")
const FIN := Color("#C9B6FF")


## The skiff in `stripe`'s colour (its school's).
static func mesh(stripe: Color) -> ArrayMesh:
	var g := Geo.new()
	_hull(g)
	g.box(Geo.place(Vector3(0, 0.62, 0)), Vector3(3.2, 0.1, 1.15), DECK)
	g.box(Geo.place(Vector3(-0.9, 0.95, 0)), Vector3(0.9, 0.6, 0.9), Color("#5A3448"))
	g.prism(Transform3D(Basis(Vector3.UP, PI / 4.0), Vector3(-0.9, 1.25, 0)), 4, 0.72, 0.0, 0.4, stripe.darkened(0.2))
	for z: float in [-0.46, 0.46]:
		g.box(Geo.place(Vector3(-0.9, 1.0, z)), Vector3(0.22, 0.2, 0.02), Color("#FFD27A", 0.2))
	g.prism(Geo.place(Vector3(0.25, 0.6, 0)), 6, 0.07, 0.05, 3.2, Color("#2A1A20"))
	_sail(g, stripe)
	g.tri(Vector3(0.25, 3.75, 0), Vector3(0.25, 3.55, 0), Vector3(1.05, 3.68, 0.04), stripe)
	g.tri(Vector3(0.25, 3.55, 0), Vector3(0.25, 3.75, 0), Vector3(1.05, 3.68, -0.04), stripe)
	_fins(g)
	g.prism(Transform3D(Basis(Vector3.BACK, -PI / 2.0 - 0.35), Vector3(2.0, 0.55, 0)), 8, 0.18, 0.0, 0.9, TRIM)
	g.ball(Geo.place(Vector3(2.1, 0.95, 0)), 0.16, Color("#FF8A6A", 0.1), 2, 6)
	return g.mesh()


## A turned hull: rings along its length, each the lower half of an ellipse,
## pointed at the bow and blunt at the stern, with a gold rail at the top.
static func _hull(g: Geo) -> void:
	var rings := 10
	var around := 6
	var section := func(i: int, j: int) -> Vector3:
		var u := i / float(rings)
		var x := -1.7 + u * 3.9
		var w := sin(clampf(u * 1.05, 0.0, 1.0) * PI) * 0.62 + (0.18 if u < 0.2 else 0.0) * (1.0 - u / 0.2)
		var a := PI * j / around
		return Vector3(x, 0.62 - sin(a) * (0.5 + w * 0.3), cos(a) * w)
	for i in rings:
		for j in around:
			var shade := HULL.lightened(0.05 * (j % 2))
			g.quad(section.call(i, j), section.call(i, j + 1), section.call(i + 1, j + 1), section.call(i + 1, j), shade)
	for side: int in [0, around]:
		for i in rings:
			var a: Vector3 = section.call(i, side)
			var b: Vector3 = section.call(i + 1, side)
			var mid := (a + b) / 2.0
			var d := b - a
			g.box(Transform3D(Basis(Vector3.UP, atan2(-d.z, d.x)), mid + Vector3(0, 0.04, 0)),
				Vector3(d.length() + 0.04, 0.1, 0.08), TRIM)


## The sail: a grid bent as if full of wind, drawn on both sides, with the
## school's stripe across it.
static func _sail(g: Geo, stripe: Color) -> void:
	var cols := 4
	var rows := 5
	var p := func(i: int, j: int) -> Vector3:
		var u := i / float(cols)
		var v := j / float(rows)
		var belly := sin(u * PI) * sin(v * PI) * 0.45
		return Vector3(0.32 + u * 1.5 * (1.0 - v * 0.35), 1.0 + v * 2.4, belly)
	for i in cols:
		for j in rows:
			var col := stripe if j == 2 else SAIL.darkened(0.03 * (i % 2))
			var a: Vector3 = p.call(i, j)
			var b: Vector3 = p.call(i + 1, j)
			var c: Vector3 = p.call(i + 1, j + 1)
			var d: Vector3 = p.call(i, j + 1)
			g.quad(a, b, c, d, col)
			g.quad(d, c, b, a, col.darkened(0.12))


## Feathered fins either side of the hull, swept back.
static func _fins(g: Geo) -> void:
	for s: float in [-1.0, 1.0]:
		for f in 3:
			var root := Vector3(-0.2 - f * 0.45, 0.5, s * 0.6)
			var tip := root + Vector3(-0.5 - f * 0.1, 0.25 - f * 0.08, s * (1.1 - f * 0.25))
			var back := root + Vector3(-0.45, 0, 0)
			var col := FIN.darkened(0.08 * f)
			g.tri(root, tip, back, col)
			g.tri(root, back, tip, col.darkened(0.15))
