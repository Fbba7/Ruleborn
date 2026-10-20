class_name PieceKit
extends RefCounted
## The heist's pieces that change as it goes, each its own mesh: the Vault
## shut and open, a pylon standing and broken, a ward live and spent. The
## Vault is §21.5's "round domed strongbox" (iron, brass, star rivets; the
## design's map vault, realm-diorama.js :847–866), a pylon its "obelisk
## topped with the school's shape", and the six wards §21.5's "low props that
## read as traps" — a grate, crystal shards, a rune circle, a coil, roots, a
## lantern — each at §21.9's two levels, the second with gold inlay. Every
## piece stands on its tile's centre, one tile wide at most.

const GOLD := Color("#E9B65C")
const BRASS := Color("#EBC25A")
const IRON := Color("#3A3440")


static func vault(open: bool) -> ArrayMesh:
	var g := Geo.new()
	g.skip_down = true
	_vault_into(g, open)
	# Drawn a fifth larger than its parts, the heist's prize reads first.
	var arrays := g.st.commit_to_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] *= 1.2
	arrays[Mesh.ARRAY_VERTEX] = verts
	var customs: PackedFloat32Array = arrays[Mesh.ARRAY_CUSTOM0]
	for i in range(0, customs.size(), 4):
		for k in 3:
			customs[i + k] *= 1.2
	arrays[Mesh.ARRAY_CUSTOM0] = customs
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {},
		Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
	return m


static func _vault_into(g: Geo, open: bool) -> void:
	var stone := Color("#E6DCCB")
	var stone2 := Color("#B9AE9C")
	g.rbox(Geo.place(Vector3(0, 0.04, 0)), Vector3(0.9, 0.08, 0.8), stone2, 0.02)
	g.rbox(Geo.place(Vector3(0, 0.27, 0)), Vector3(0.72, 0.38, 0.62), stone, 0.03)
	for x: float in [-0.36, 0.36]:
		for z: float in [-0.31, 0.31]:
			g.rbox(Geo.place(Vector3(x, 0.25, z)), Vector3(0.1, 0.42, 0.1), stone2, 0.02)
	g.rbox(Geo.place(Vector3(0, 0.47, 0)), Vector3(0.76, 0.04, 0.66), Color("#B9AE9C"), 0.015)
	# Star rivets round the drum.
	for k in 10:
		var a := TAU * k / 10.0
		g.ball(Geo.place(Vector3(cos(a) * 0.37, 0.36, sin(a) * 0.32)), 0.022, Color(Color("#FFF1C4"), 0.6), 2, 4)
	if open:
		# The dome swung back on its hinge, and the hoard glowing within.
		var hinge := Transform3D(Basis(Vector3.RIGHT, -1.25), Vector3(0, 0.49, -0.3))
		g.ball(hinge * Transform3D(Basis().scaled(Vector3(1, 0.8, 0.9)), Vector3(0, 0, 0.3)), 0.32, BRASS, 4, 12, true)
		for k in 7:
			var a := TAU * k / 7.0
			g.cyl(Geo.place(Vector3(cos(a) * 0.14, 0.49 + 0.02 * (k % 3), sin(a) * 0.12)), 0.05, 0.05, 0.02,
				Color(GOLD.lightened(0.2), 0.5), 8)
		g.ball(Geo.place(Vector3(0, 0.56, 0)), 0.16, Color(GOLD.lightened(0.35), 0.1), 3, 8)
	else:
		g.ball(Geo.place(Vector3(0, 0.49, 0), 0.0, Vector3(1, 0.8, 0.9)), 0.32, BRASS, 4, 12, true)
		g.ball(Geo.place(Vector3(0, 0.76, 0)), 0.04, GOLD, 2, 6)
		g.prism(Geo.place(Vector3(0, 0.78, 0)), 6, 0.02, 0.0, 0.12, GOLD)
		# The sealed door with its dial, breathing.
		g.cyl(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.27, 0.31)), 0.13, 0.13, 0.03, GOLD, 14)
		g.torus(Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.27, 0.345)), 0.07, 0.014,
			Color(Color("#FFF1C4"), 0.5), 12, 4)
	for x: float in [-0.3, 0.3]:
		g.cyl(Geo.place(Vector3(x, 0.08, 0.42)), 0.03, 0.04, 0.14, stone2, 6)
		g.ball(Geo.place(Vector3(x, 0.25, 0.42)), 0.03, Color(Color("#FFD27A"), 0.2), 2, 5)


## A law pylon: a stone obelisk on its plinth, crowned by its school's
## shape (§21.2), which turns and glows.
static func pylon(school := "matter") -> ArrayMesh:
	var g := Geo.new()
	g.skip_down = true
	var stone := Palette.STONE
	var colour: Color = Palette.SCHOOL.get(school, Palette.MATTER)
	g.rbox(Geo.place(Vector3(0, 0.06, 0), PI / 4.0), Vector3(0.6, 0.12, 0.6), stone.darkened(0.2), 0.03)
	g.rbox(Geo.place(Vector3(0, 0.16, 0), PI / 4.0), Vector3(0.44, 0.08, 0.44), stone.darkened(0.1), 0.02)
	# The school's colour inlaid round the step.
	g.torus(Geo.place(Vector3(0, 0.2, 0)), 0.21, 0.012, Color(colour.lightened(0.2), 0.4), 16, 3)
	g.prism(Geo.place(Vector3(0, 0.2, 0), PI / 4.0), 4, 0.16, 0.09, 1.1, stone)
	g.prism(Geo.place(Vector3(0, 1.3, 0), PI / 4.0), 4, 0.09, 0.0, 0.14, stone.lightened(0.1))
	# Runes up each face in the school's colour, breathing.
	for f in 4:
		var yaw := PI / 2.0 * f
		var out := Vector3(0, 0, 1).rotated(Vector3.UP, yaw)
		for k in 3:
			var y := 0.45 + 0.25 * k
			g.box(Geo.place(Vector3(0, y, 0) + out * (0.128 - 0.024 * k), yaw), Vector3(0.06, 0.07, 0.008),
				Color(colour, 0.4))
	g.moving(Geo.Anim.SPIN_Y, Vector3(0, 1.66, 0))
	_shape(g, school, Vector3(0, 1.66, 0), 0.13, Color(colour.lightened(0.15), 0.35))
	g.moving(Geo.Anim.NONE, Vector3.ZERO)
	return g.mesh()


static func broken_pylon() -> ArrayMesh:
	var g := Geo.new()
	g.skip_down = true
	var stone := Palette.STONE.darkened(0.2)
	g.prism(Geo.place(Vector3.ZERO, PI / 4.0), 4, 0.32, 0.28, 0.12, stone.darkened(0.1))
	g.prism(Geo.place(Vector3(0, 0.12, 0), PI / 4.0), 4, 0.24, 0.22, 0.08, stone)
	g.prism(Geo.place(Vector3(0, 0.2, 0), PI / 4.0), 4, 0.16, 0.14, 0.3, stone)
	# Its runes gone dark, a crack up the stump; the top fallen beside it.
	g.box(Geo.place(Vector3(0.03, 0.36, 0.152), 0.3), Vector3(0.02, 0.22, 0.01), Palette.INK)
	g.prism(Transform3D(Basis(Vector3.BACK, 1.4), Vector3(0.38, 0.09, 0.1)), 4, 0.12, 0.09, 0.6, stone.lightened(0.05))
	for k in 4:
		g.rock(Geo.place(Vector3(-0.25 + 0.15 * k, 0.03, 0.25 - 0.08 * k)), 0.05, stone, k)
	return g.mesh()


## A ward at its level (1 or 2): §21.5's low trap props, in its school's
## colour (§10.3), live.
static func ward(kind: String, level := 1) -> ArrayMesh:
	var g := Geo.new()
	g.skip_down = true
	var colour: Color = Palette.WARD.get(kind, Palette.INK)
	var school := str(Palette.WARD_SCHOOL.get(kind, "motion"))
	var lit := Color(colour.lightened(0.2), 0.4)
	var stone := Palette.STONE.lerp(colour, 0.12)
	# A worn stone ring set in the ground, a darker well inside, and the
	# rune circle glowing faintly in the school's colour (a telltale).
	g.cyl(Geo.place(Vector3.ZERO), 0.4, 0.42, 0.05, stone.darkened(0.1), 14, stone)
	g.cyl(Geo.place(Vector3(0, 0.05, 0)), 0.27, 0.27, 0.005, colour.darkened(0.55), 14)
	g.torus(Geo.place(Vector3(0, 0.055, 0)), 0.33, 0.014, Color(colour.lightened(0.3), 0.3), 20, 3)
	for i in 8:
		var q := i * PI / 4.0 + PI / 8.0
		g.box(Geo.place(Vector3(cos(q) * 0.36, 0.055, sin(q) * 0.36), -q + PI / 2.0), Vector3(0.05, 0.01, 0.025), lit)
	match school:
		"motion":
			# A gravity well: an iron grate over a swirling pit.
			g.ring(Geo.place(Vector3(0, 0.05, 0)), 0.0, 0.22, Color(colour.darkened(0.3), 0.5), 12)
			for k in 5:
				g.box(Geo.place(Vector3(0, 0.07, -0.16 + 0.08 * k)), Vector3(0.4, 0.03, 0.025), IRON)
			g.moving(Geo.Anim.SPIN_Y, Vector3(0, 0.05, 0))
			for k in 3:
				var a := TAU * k / 3.0
				g.gem(Geo.place(Vector3(cos(a) * 0.14, 0.12, sin(a) * 0.14)), 0.03, 0.03, lit, 4)
			g.moving(Geo.Anim.NONE, Vector3.ZERO)
		"matter":
			# A crystal wall: shards breaking from the ground.
			for k in 4:
				var a := TAU * k / 4.0 + 0.3
				var tilt := Basis(Vector3(cos(a), 0, sin(a)).cross(Vector3.UP), 0.3)
				g.gem(Transform3D(tilt, Vector3(cos(a) * 0.12, 0.2, sin(a) * 0.12)), 0.07, 0.2 - 0.03 * k,
					Color(colour.lightened(0.3), 0.6), 5)
		"time":
			# A time snare: a clock face of runes, its hand turning.
			g.cyl(Geo.place(Vector3(0, 0.04, 0)), 0.22, 0.22, 0.03, colour.darkened(0.2), 16)
			for i in 12:
				var q := TAU * i / 12.0
				g.box(Geo.place(Vector3(cos(q) * 0.18, 0.075, sin(q) * 0.18), -q), Vector3(0.04, 0.01, 0.015), lit)
			g.moving(Geo.Anim.SPIN_Y, Vector3(0, 0.08, 0))
			g.box(Geo.place(Vector3(0.07, 0.085, 0)), Vector3(0.15, 0.015, 0.025), GOLD)
			g.moving(Geo.Anim.NONE, Vector3.ZERO)
		"energy":
			# A static coil: a copper coil on a post, sparking.
			g.cyl(Geo.place(Vector3(0, 0.05, 0)), 0.06, 0.05, 0.5, IRON, 6)
			for k in 5:
				g.torus(Geo.place(Vector3(0, 0.12 + 0.075 * k, 0)), 0.12 - 0.008 * k, 0.02, Color("#C87A4A"), 12, 4)
			g.moving(Geo.Anim.BOB, Vector3(0, 0.62, 0))
			g.ball(Geo.place(Vector3(0, 0.62, 0)), 0.07, Color(Color("#FFE7A8"), 0.2), 3, 6)
			g.moving(Geo.Anim.NONE, Vector3.ZERO)
		"life":
			# A thorn hedge: roots curling up from the ground, thorned.
			for k in 5:
				var a := TAU * k / 5.0
				var p := Vector3(cos(a) * 0.15, 0.04, sin(a) * 0.15)
				var tilt := Basis(Vector3(cos(a), 0, sin(a)).cross(Vector3.UP), -0.5)
				g.moving(Geo.Anim.SHIVER, p)
				g.prism(Transform3D(tilt, p), 4, 0.04, 0.0, 0.3, Color("#5A3A2A").lerp(colour, 0.35))
				g.prism(Transform3D(tilt, p + Vector3(0, 0.12, 0)), 3, 0.02, 0.0, 0.08, colour.lightened(0.2))
			g.moving(Geo.Anim.NONE, Vector3.ZERO)
		_:
			# A lantern glare: a lantern on a crook, its light breathing.
			g.cyl(Geo.place(Vector3(0.14, 0.05, 0)), 0.035, 0.028, 0.62, KitStyle.WOOD_DARK, 5)
			g.box(Geo.place(Vector3(0.04, 0.66, 0)), Vector3(0.24, 0.035, 0.035), KitStyle.WOOD_DARK)
			g.moving(Geo.Anim.SWING, Vector3(-0.06, 0.65, 0))
			g.rbox(Geo.place(Vector3(-0.06, 0.53, 0)), Vector3(0.14, 0.17, 0.14), Color(Color("#FFE7A8"), 0.15), 0.02)
			g.prism(Geo.place(Vector3(-0.06, 0.615, 0), PI / 4.0), 4, 0.11, 0.0, 0.06, KitStyle.WOOD_DARK)
			g.moving(Geo.Anim.NONE, Vector3.ZERO)
			g.ring(Geo.place(Vector3(0, 0.058, 0)), 0.0, 0.26, Color(Color("#FFE7A8"), 0.5), 12)
	if level >= 2:
		# Gold inlay: a gold ring round the circle and studs on it.
		g.torus(Geo.place(Vector3(0, 0.045, 0)), 0.36, 0.012, GOLD, 20, 3)
		for i in 4:
			var q := i * PI / 2.0 + PI / 4.0
			g.ball(Geo.place(Vector3(cos(q) * 0.36, 0.05, sin(q) * 0.36)), 0.025, GOLD, 2, 5)
	return g.mesh()


static func dead_ward() -> ArrayMesh:
	var g := Geo.new()
	g.skip_down = true
	g.cyl(Geo.place(Vector3.ZERO), 0.38, 0.4, 0.04, Color("#3A3350"), 12)
	for k in 3:
		g.rock(Geo.place(Vector3(-0.12 + 0.12 * k, 0.05, 0.05 * (k - 1))), 0.04, Palette.STONE.darkened(0.35), k)
	return g.mesh()


## A school's shape (§21.2), centred on `at`.
static func _shape(g: Geo, school: String, at: Vector3, r: float, col: Color) -> void:
	match school:
		"matter":
			g.box(Transform3D(Basis(Vector3.UP, PI / 4.0) * Basis(Vector3.RIGHT, PI / 4.0), at), Vector3.ONE * r * 1.3, col)
		"time":
			g.prism(Geo.place(at - Vector3(0, r, 0)), 6, r, 0.02, r, col)
			g.prism(Geo.place(at + Vector3(0, r, 0)), 6, r, 0.02, -r, col)
		"energy":
			g.box(Transform3D(Basis(Vector3.BACK, 0.5), at), Vector3(r * 0.6, r * 2.2, r * 0.6), col)
		"life":
			g.ball(Geo.place(at, 0.0, Vector3(0.6, 1.2, 0.35)), r, col, 3, 7)
		"spirit":
			g.ball(Geo.place(at, 0.0, Vector3(1.3, 0.7, 0.6)), r, col, 3, 8)
		_:
			g.prism(Geo.place(at - Vector3(0, r, 0)), 3, r * 1.1, 0.0, r * 2.0, col)
