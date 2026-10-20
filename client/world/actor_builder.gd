class_name ActorBuilder
extends RefCounted
## The heist's figures as the designs' diorama draws them (Screens v3's
## `makeChar0`, realm-diorama.js:611, at its 2.2 scale): a round chibi body
## with a cream face patch, big eyes with a catch-light, pink cheeks, stubby
## arms and feet, and a top that says who it is — ears, round ears, bear
## ears, an antenna, a flame or a horn. The crew is drawn by its role until
## the replay names each kind (TD.9): a Scout has the sky kind's ears, a
## Breaker the glass kind's horn, a Carrier the moss kind's bear ears and a
## pack, a Warden the tide kind's round ears and a shield, a Mender the echo
## kind's glowing antenna and a satchel. A guard is the glass kind in §21.6's
## guard form ("As guards, ruleborn add a sash and a small lantern") with the
## diorama's cone helmet, the same shapes for every guard (§21.12). Forward
## is −Z. Each figure is one mesh, made once and shared, under 2,000
## triangles (§21.3 gives a character 3,000 to 6,000); `CreatureModel`
## replaces it as the "Body" under an actor's rig.

## Each figure's scale on the world: §21.1's ruleborn "stand 0.5 to 1.4
## metres", a Carrier broad and a Scout small; guards a head taller.
const HEIGHT := {"Scout": 1.15, "Breaker": 1.3, "Carrier": 1.35, "Warden": 1.25, "Mender": 1.15, "guard": 1.4}
## Each role's top, from the diorama's kinds.
const TOP := {"Scout": "ears", "Breaker": "horn", "Carrier": "bear", "Warden": "round", "Mender": "antenna",
	"guard": "helmet"}
const CREAM := Color("#FFF3DF")
const CHEEK := Color("#FF9AA8")
const PUPIL := Color("#1B1430")

static var _cache := {}


## The mesh for a crew member of `role`, or a guard when `role` is "guard".
static func mesh(role: String) -> ArrayMesh:
	if _cache.has(role):
		return _cache[role]
	var g := Geo.new()
	var body: Color = Palette.ROLE.get(role, Palette.STONE) if role != "guard" else Color("#A58BFF")
	var deep := body.darkened(0.35)
	# Feet, flattened and long; the body, a little taller than round; the
	# face patch low on the front.
	for x: float in [-0.121, 0.121]:
		g.ball(Geo.place(Vector3(x, 0.055, -0.02), 0.0, Vector3(1.0, 0.6, 1.3)), 0.084, deep, 4, 8)
	g.ball(Geo.place(Vector3(0, 0.44, 0), 0.0, Vector3(1.0, 1.12, 0.95)), 0.286, body, 8, 14)
	g.ball(Geo.place(Vector3(0, 0.374, -0.165), 0.0, Vector3(1.0, 1.0, 0.7)), 0.187, CREAM, 5, 10)
	# Arms, out to the sides.
	for x: float in [-0.275, 0.275]:
		g.ball(Geo.place(Vector3(x, 0.374, 0.0), 0.0, Vector3(0.9, 1.1, 0.9)), 0.073, body.darkened(0.08), 4, 8)
	# Eyes: white, an ink pupil, a catch-light; and the cheeks.
	for x: float in [-0.114, 0.114]:
		g.ball(Geo.place(Vector3(x, 0.583, -0.228)), 0.077, Color.WHITE, 4, 8)
		g.ball(Geo.place(Vector3(x, 0.583, -0.282)), 0.046, PUPIL, 3, 7)
		g.ball(Geo.place(Vector3(x + 0.016, 0.6, -0.322)), 0.016, Color.WHITE, 2, 4)
		g.ball(Geo.place(Vector3(x * 1.64, 0.495, -0.215), 0.0, Vector3(1.0, 0.7, 0.5)), 0.042, CHEEK, 2, 6)
	_top(g, str(TOP.get(role, "")), body)
	_kit(g, role, body)
	var m := g.mesh()
	_cache[role] = m
	return m


## The top of the head: the diorama's kinds' shapes, glowing where theirs do.
static func _top(g: Geo, top: String, body: Color) -> void:
	match top:
		"ears":
			for s: float in [-1.0, 1.0]:
				g.prism(Transform3D(Basis(Vector3.FORWARD, s * 0.35), Vector3(s * 0.132, 0.7, 0)), 6, 0.066, 0.0, 0.35,
					body)
				g.prism(Transform3D(Basis(Vector3.FORWARD, s * 0.35), Vector3(s * 0.132, 0.72, -0.02)), 6, 0.035, 0.0,
					0.24, CHEEK)
		"round":
			for s: float in [-1.0, 1.0]:
				g.ball(Geo.place(Vector3(s * 0.187, 0.726, 0)), 0.088, body, 4, 8)
		"bear":
			for s: float in [-1.0, 1.0]:
				g.ball(Geo.place(Vector3(s * 0.176, 0.726, 0)), 0.077, body.darkened(0.3), 4, 8)
		"antenna":
			g.prism(Geo.place(Vector3(0, 0.74, 0)), 5, 0.014, 0.014, 0.26, Color("#46103A"))
			g.ball(Geo.place(Vector3(0, 1.01, 0)), 0.062, Color(body.lightened(0.5), 0.0), 4, 8)
		"flame":
			g.prism(Geo.place(Vector3(0, 0.74, 0)), 6, 0.11, 0.0, 0.31, Color("#FFD27A", 0.0))
		"horn":
			g.prism(Geo.place(Vector3(0, 0.72, 0)), 4, 0.11, 0.0, 0.3, Color("#E6E0FF"))
			g.prism(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, 0.74, 0)), 4, 0.11, 0.0, 0.06, Color("#E6E0FF"))
		"helmet":
			g.prism(Geo.place(Vector3(0, 0.7, 0)), 8, 0.28, 0.0, 0.34, Color("#8C8CA8"))
			g.prism(Geo.place(Vector3(0, 0.68, 0)), 8, 0.3, 0.3, 0.05, Color("#6A6A88"))
			g.ball(Geo.place(Vector3(0, 1.05, 0)), 0.04, Palette.ALARM, 3, 6)


## What each role carries, and the guard form's sash and lantern (§21.6).
static func _kit(g: Geo, role: String, body: Color) -> void:
	match role:
		"guard":
			g.box(Transform3D(Basis(Vector3.FORWARD, 0.62), Vector3(0, 0.42, -0.02)), Vector3(0.66, 0.08, 0.62),
				Palette.ALARM.darkened(0.1))
			# The lantern on its pole, held out front: its glass glows.
			g.prism(Geo.place(Vector3(-0.31, 0.12, -0.16)), 4, 0.012, 0.012, 0.42, Color("#6A4A2A"))
			g.prism(Geo.place(Vector3(-0.31, 0.42, -0.16)), 6, 0.075, 0.075, 0.14, Color("#FFC36A", 0.0))
			g.prism(Geo.place(Vector3(-0.31, 0.56, -0.16)), 6, 0.085, 0.0, 0.07, Color("#4A3A2A"))
		"Breaker":
			# A mallet over the shoulder.
			g.prism(Transform3D(Basis(Vector3.FORWARD, -0.5), Vector3(0.3, 0.3, 0.05)), 4, 0.016, 0.016, 0.5,
				Palette.WOOD.darkened(0.2))
			g.box(Transform3D(Basis(Vector3.FORWARD, -0.5), Vector3(0.45, 0.7, 0.05)), Vector3(0.2, 0.12, 0.12),
				Color("#9A95AC"))
		"Carrier":
			g.ball(Geo.place(Vector3(0, 0.5, 0.27), 0.0, Vector3(1.05, 1.0, 0.8)), 0.2, Palette.WOOD.lightened(0.15), 4, 8)
			g.box(Geo.place(Vector3(0, 0.5, 0.06)), Vector3(0.6, 0.05, 0.05), Palette.WOOD.darkened(0.3))
		"Warden":
			g.ball(Geo.place(Vector3(-0.31, 0.38, -0.08), 0.0, Vector3(0.45, 1.0, 1.0)), 0.16, Color("#9FC7E8"), 4, 8)
			g.ball(Geo.place(Vector3(-0.35, 0.38, -0.08), 0.0, Vector3(0.3, 0.6, 0.6)), 0.16, Palette.MOTION, 3, 6)
		"Mender":
			g.box(Transform3D(Basis(Vector3.FORWARD, -0.6), Vector3(0, 0.42, -0.04)), Vector3(0.62, 0.05, 0.6),
				Palette.LIFE.darkened(0.2))
			g.ball(Geo.place(Vector3(0.25, 0.25, -0.12)), 0.09, CREAM, 3, 7)
			g.box(Geo.place(Vector3(0.25, 0.25, -0.21)), Vector3(0.08, 0.025, 0.02), Palette.ALARM)
			g.box(Geo.place(Vector3(0.25, 0.25, -0.21)), Vector3(0.025, 0.08, 0.02), Palette.ALARM)
		"Scout":
			g.box(Transform3D(Basis(Vector3.RIGHT, 0.2), Vector3(0, 0.5, 0.26)), Vector3(0.36, 0.2, 0.1),
				body.darkened(0.25))


## A bag of loot on the back, its size by how full it is (§12.19): the
## diorama's sack, with a tie and a coin peeking out.
static func sack() -> ArrayMesh:
	if _cache.has("sack"):
		return _cache["sack"]
	var g := Geo.new()
	g.ball(Geo.place(Vector3(0, 0, 0), 0.0, Vector3(1.0, 0.9, 1.0)), 0.165, Color("#C9A26A"), 5, 10)
	g.prism(Geo.place(Vector3(0, 0.12, 0)), 6, 0.06, 0.035, 0.08, Color("#8A6A3E"))
	g.prism(Geo.place(Vector3(0.03, 0.2, 0.0)), 8, 0.06, 0.06, 0.02, Color("#F2B43C"))
	var m := g.mesh()
	_cache["sack"] = m
	return m
