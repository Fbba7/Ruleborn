class_name ActorBuilder
extends RefCounted
## The heist's figures as the designs' diorama draws them (Screens v3's
## `makeChar0`): a round, chibi body with big eyes, feet and arms, and a top
## that says who it is. The crew is drawn by its role until the replay names
## each kind (TD.9); a guard wears §21.6's sash and lantern ("As guards,
## ruleborn add a sash and a small lantern") and a cone helmet, the same
## shapes for every guard (§21.12). Forward is −Z. Meshes are made once a
## look and shared.

static var _cache := {}


## The mesh for a crew member of `role`, or a guard when `role` is "guard".
static func mesh(role: String) -> ArrayMesh:
	if _cache.has(role):
		return _cache[role]
	var g := Geo.new()
	var body: Color = Palette.ROLE.get(role, Palette.STONE) if role != "guard" else Color("#C9D3E6")
	var ink := Palette.INK
	# Feet, body and belly.
	for x: float in [-0.12, 0.12]:
		g.ball(Geo.place(Vector3(x, 0.06, -0.02), 0.0, Vector3(1.0, 0.6, 1.3)), 0.09, body.darkened(0.35), 3, 6)
	g.ball(Geo.place(Vector3(0, 0.36, 0), 0.0, Vector3(1.0, 1.05, 0.95)), 0.28, body, 5, 10)
	g.ball(Geo.place(Vector3(0, 0.3, -0.16), 0.0, Vector3(1.0, 1.1, 0.5)), 0.17, body.lightened(0.35), 4, 8)
	# Arms.
	for x: float in [-0.3, 0.3]:
		g.ball(Geo.place(Vector3(x, 0.32, 0), 0.0, Vector3(0.8, 1.2, 0.8)), 0.09, body.darkened(0.1), 3, 6)
	# Eyes: white, with an ink pupil and a catch-light.
	for x: float in [-0.1, 0.1]:
		g.ball(Geo.place(Vector3(x, 0.46, -0.22)), 0.075, Palette.PAPER, 3, 7)
		g.ball(Geo.place(Vector3(x, 0.46, -0.28)), 0.04, ink, 3, 6)
		g.ball(Geo.place(Vector3(x + 0.015, 0.48, -0.31)), 0.012, Palette.PAPER, 2, 4)
	match role:
		"guard":
			# The cone helmet, the sash across the body, the lantern held out.
			g.prism(Geo.place(Vector3(0, 0.58, 0)), 8, 0.24, 0.0, 0.32, Palette.MATTER, true)
			g.box(Transform3D(Basis(Vector3.FORWARD, 0.6), Vector3(0, 0.34, -0.02)), Vector3(0.6, 0.07, 0.6),
				Palette.ALARM.darkened(0.1))
			g.prism(Geo.place(Vector3(0.36, 0.18, -0.12)), 6, 0.07, 0.07, 0.14, Color(Palette.MOTION.lightened(0.3), 0.0))
		"Scout":
			for x: float in [-0.15, 0.15]:
				g.prism(Transform3D(Basis(Vector3.FORWARD, -x * 2.5), Vector3(x, 0.58, 0)), 4, 0.07, 0.0, 0.28,
					body.darkened(0.15))
		"Breaker":
			g.prism(Geo.place(Vector3(0, 0.6, -0.06)), 6, 0.08, 0.0, 0.26, Palette.PAPER.darkened(0.1))
			g.box(Geo.place(Vector3(0.36, 0.3, -0.05)), Vector3(0.1, 0.36, 0.1), Palette.WOOD)
		"Carrier":
			g.ball(Geo.place(Vector3(0, 0.38, 0.27), 0.0, Vector3(1.0, 1.0, 0.8)), 0.21, Palette.WOOD.lightened(0.15), 3, 7)
		"Warden":
			g.ball(Geo.place(Vector3(0, 0.56, 0), 0.0, Vector3(1.05, 0.6, 1.05)), 0.24, Palette.STONE.darkened(0.2), 3, 8)
		"Mender":
			g.prism(Transform3D(Basis(Vector3.FORWARD, 0.5), Vector3(0.05, 0.6, 0)), 5, 0.08, 0.0, 0.24, Palette.LIFE)
		_:
			g.ball(Geo.place(Vector3(0, 0.66, 0)), 0.07, body.lightened(0.3), 3, 6)
	var m := g.mesh()
	_cache[role] = m
	return m


## A bag of loot on the back, its size by how full it is (§12.19).
static func sack() -> ArrayMesh:
	if _cache.has("sack"):
		return _cache["sack"]
	var g := Geo.new()
	g.ball(Geo.place(Vector3(0, 0, 0), 0.0, Vector3(1.0, 0.9, 1.0)), 0.16, Palette.MOTION, 3, 8)
	g.prism(Geo.place(Vector3(0, 0.12, 0)), 6, 0.05, 0.03, 0.08, Palette.MOTION_SHADOW)
	var m := g.mesh()
	_cache["sack"] = m
	return m
