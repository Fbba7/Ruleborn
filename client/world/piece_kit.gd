class_name PieceKit
extends RefCounted
## The heist's pieces that change as it goes, each its own mesh: the Vault
## shut and open, a pylon standing and broken, a ward live and spent.


static func vault(open: bool) -> ArrayMesh:
	var g := Geo.new()
	var gold := Palette.MOTION
	g.box(Geo.place(Vector3(0, 0.3, 0)), Vector3(0.82, 0.6, 0.66), Palette.WOOD.darkened(0.15))
	for x: float in [-0.3, 0.0, 0.3]:
		g.box(Geo.place(Vector3(x, 0.3, 0)), Vector3(0.08, 0.62, 0.68), gold)
	if open:
		g.box(Transform3D(Basis(Vector3.RIGHT, -1.1), Vector3(0, 0.75, 0.36)), Vector3(0.84, 0.08, 0.66),
			Palette.WOOD.darkened(0.15))
		g.ball(Geo.place(Vector3(0, 0.62, 0)), 0.26, Color(gold.lightened(0.3), 0.0), 3, 8)
	else:
		g.box(Geo.place(Vector3(0, 0.66, 0)), Vector3(0.86, 0.14, 0.7), Palette.WOOD.darkened(0.05), gold)
		g.box(Geo.place(Vector3(0, 0.42, -0.34)), Vector3(0.16, 0.18, 0.04), gold.darkened(0.2))
	return g.mesh()


static func pylon() -> ArrayMesh:
	var g := Geo.new()
	g.prism(Geo.place(Vector3.ZERO, PI / 4.0), 4, 0.32, 0.26, 0.2, Palette.STONE.darkened(0.15))
	g.prism(Geo.place(Vector3(0, 0.2, 0), PI / 4.0), 4, 0.17, 0.09, 1.2, Palette.STONE)
	g.ball(Geo.place(Vector3(0, 1.55, 0)), 0.16, Color(Palette.MATTER.lightened(0.2), 0.0), 3, 7)
	return g.mesh()


static func broken_pylon() -> ArrayMesh:
	var g := Geo.new()
	g.prism(Geo.place(Vector3.ZERO, PI / 4.0), 4, 0.32, 0.26, 0.2, Palette.STONE.darkened(0.25))
	g.prism(Geo.place(Vector3(0, 0.2, 0), PI / 4.0), 4, 0.17, 0.14, 0.35, Palette.STONE.darkened(0.2))
	return g.mesh()


## A ward as a small totem in its school's colour, crowned by its school's
## shape (§21.2), as the flat view draws it.
static func ward(kind: String) -> ArrayMesh:
	var g := Geo.new()
	var colour: Color = Palette.WARD.get(kind, Palette.INK)
	g.prism(Geo.place(Vector3.ZERO), 6, 0.2, 0.16, 0.18, Palette.STONE.darkened(0.2))
	match str(Palette.WARD_SCHOOL.get(kind, "motion")):
		"matter":
			g.box(Geo.place(Vector3(0, 0.45, 0), PI / 4.0), Vector3(0.32, 0.32, 0.32), colour)
		"time":
			g.prism(Geo.place(Vector3(0, 0.18, 0)), 6, 0.18, 0.02, 0.24, colour)
			g.prism(Geo.place(Vector3(0, 0.66, 0)), 6, 0.18, 0.02, -0.24, colour)
		"energy":
			g.box(Transform3D(Basis(Vector3.FORWARD, 0.5), Vector3(0, 0.46, 0)), Vector3(0.12, 0.5, 0.12), colour)
		"life":
			g.ball(Geo.place(Vector3(0, 0.46, 0), 0.0, Vector3(0.6, 1.2, 0.3)), 0.2, colour, 3, 7)
		"spirit":
			g.ball(Geo.place(Vector3(0, 0.46, 0), 0.0, Vector3(1.3, 0.7, 0.6)), 0.18, colour, 3, 8)
			g.ball(Geo.place(Vector3(0, 0.46, -0.08)), 0.07, Palette.INK, 2, 6)
		_:
			g.prism(Geo.place(Vector3(0, 0.25, 0)), 3, 0.22, 0.0, 0.42, colour)
	return g.mesh()


static func dead_ward() -> ArrayMesh:
	var g := Geo.new()
	g.prism(Geo.place(Vector3.ZERO), 6, 0.2, 0.16, 0.18, Palette.STONE.darkened(0.35))
	return g.mesh()
